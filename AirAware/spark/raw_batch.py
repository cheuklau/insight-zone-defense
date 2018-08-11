from __future__ import print_function

import sys
import csv
import json
from datetime import datetime
from StringIO import StringIO
import configparser

from pyspark import SparkContext, SparkConf
from pyspark.storagelevel import StorageLevel
from pyspark.sql import SparkSession, SQLContext
from pyspark.sql.types import (StructType, StructField, FloatType,
                               TimestampType, IntegerType)

from boto.s3.connection import S3Connection


def file_year(fname):
    '''
    Given string of the format word_word_year.extension, return integer year
    This works for files supplied by EPA but strictly, should be generalized
    '''
    try:
        basename = fname.split('.')[0]
        parameter = basename.split('_')[1]
        year_string = basename.split('_')[2]
    except (ValueError, IndexError):
        return None
    if parameter not in ['44201', '88101', '88502']:
        return None
    year = convert_to_int(year_string)
    if not year:
        return None
    return year


def get_grid_from_file(filename):
    '''
    Load a text file with one line of JSON containing all grid points

    Parameters
    ----------
    filename : str
                    Name of the json file

    Returns
    -------
    dict
                    Dictionary of grid points with lon and lat
    '''
    with open(filename) as f:
        raw_json = f.readline()
    return json.loads(raw_json)


def convert_to_int(string):
    '''
    Returns an integer if it can or returns None otherwise

    Parameters
    ----------
    string : string, required
                String representing the property value

    Returns
    -------
    int
            If string can be represented as a valid integer
    None
            Otherwise
    '''
    try:
        number = int(string)
    except ValueError:
        return None
    return number


def convert_to_float(string):
    '''
    Returns a float if it can or returns None otherwise

    Parameters
    ----------
    string : string, required
                String representing the property value

    Returns
    -------
    float
            If string can be represented as a valid nonzero float
    None
            Otherwise
    '''
    try:
        number = float(string)
        return number
    except ValueError:
        return None


def get_file_list(bucket_name):
    '''
    Given the S3 bucket, return a list of files sorted in
    reverse chronological order
    '''
    file_list = []

    conn = S3Connection()
    bucket = conn.get_bucket(bucket_name)
    for bucket_object in bucket.get_all_keys():
        fname = bucket_object.key
        if not fname.startswith('hourly'):
            continue
        year = file_year(fname)
        if not year:
            continue
        file_list.append((fname, year))

    file_list.sort(key=lambda x: x[1], reverse=True)

    return [f[0] for f in file_list]


def parse_measurement_record(measurement_record):
    '''
    This function ...

    Input
    -----
    line : str
                One line containing air monitor reading

    Returns
    -------
    list
                List of fields in the air monitor reading
    '''


    f = StringIO(measurement_record.encode('ascii', 'ignore'))
    reader = csv.reader(f, delimiter=',')
    record = reader.next()

    parameter = convert_to_int(record[3])
    if parameter not in [44201, 88101, 88502]:
        # Ignore records other than ozone (44201) or PM2.5 (88101)
        return None

    state_id = record[0]
    # Filter out header, Canada, Mexico, US Virgin Islands, or Guam
    if state_id in ['State Code', 'CC', '80', '78', '66']:
        return None

    county_id = record[1]
    site_number = record[2]
    site_id = '|'.join([state_id, county_id, site_number])

    # Check if this is in the station lookup table to avoid issues downstream
    grid = STATIONS.get(site_id, None)
    if not grid:
        return None

    # Carve out the GMT timestamp
    date = record[11]
    time = record[12]
    timestamp = datetime.strptime(date + time, '%Y-%m-%d%H:%M')

    C = convert_to_float(record[13])
    mdl = convert_to_float(record[15])
    if not C or not mdl:
        return None

    # Filter out malformed records with negative concentration
    if C < 0.:
        return None

    # Measured concentration is below detection limit
    if C < mdl:
        C = 0.

    return (site_id, parameter, C, timestamp)


def station_to_grid(rdd):
    '''
    Takes RDD with air quality stations' readings and and returns
    RDDs for readings transformed to nearest grid points

    Parameters
    ----------
    rdd : RDD
                RDD of air monitors readings

    Returns
    -------
    RDD
                RDDs of air monitors reading transformed to nearest grid points
    '''

    
    site_id = rdd[0]
    parameter = rdd[1]
    C = rdd[2]
    timestamp = rdd[3]
    # Since we made sure upstream that site_id is in dictionary, can extract it
    grid = STATIONS[site_id]
    measurements = []
    for grid_id in grid:
        distance = grid[grid_id]
        weight = 1. / (distance ** 2)
        weight_C_prod = C * weight
        measurements.append(((int(grid_id), timestamp, parameter),
                            (weight_C_prod, weight)))
    return measurements


def sum_weight_and_prods(val1, val2):
    '''
    Little custom map function to compute weighted averages

    Parameters
    ----------
    val1: RDD
                Value of first RDD
    val2: RDD
                Value of second RDD

    Returns
    -------
    RDD
                RDD with tuples reduced based on weights and weight*C
    '''
    return (val1[0] + val2[0], val1[1] + val2[1])


def calc_weighted_average_grid(rdd):
    '''
    Compute the weighted average over the entire grid

    Parameters
    ----------
    rdd: RDD
            RDD containing weights and weighted pollution levels

    Returns
    -------
    RDD
            RDD with value as a weighted average pollution level
    '''
    grid_id = rdd[0][0]
    timestamp = rdd[0][1]
    parameter = rdd[0][2]
    weighted_avg = rdd[1][0] / float(rdd[1][1])
    return (grid_id, parameter, timestamp, weighted_avg)


def group_by_month(rdd):
    '''
    Given an rdd containing weighted average air pollution level at grid point,
    determine the month and year for it, and prepare for averaging
    '''
    grid_id = rdd[0]
    parameter = rdd[1]
    timestamp = rdd[2]
    C = rdd[3]
    month_year = datetime.strftime(timestamp, '%m%Y')
    return ((grid_id, month_year, parameter), (C, 1))


def average_over_month(rdd):
    '''
    Given rdd containing sum of air pollution level at grid point over month,
    compute the average pollution in a month for a given compound
    '''
    grid_id = rdd[0][0]
    month_year = rdd[0][1]
    timestamp = datetime.strptime(month_year, '%m%Y')
    parameter = rdd[0][2]
    C = rdd[1][0] / float(rdd[1][1])
    return (grid_id, timestamp, parameter, C)


def main(argv):

    ###################################################
    # Read in data from the configuration file
    ###################################################

    config = configparser.ConfigParser()
    config.read('../setup.cfg')

    ##################################################
    # Set up links to servers
    ###################################################

    # s3 bucket containing the raw EPA data
    bucket_name = config["s3"]["bucket"]
    s3 = 's3a://' + bucket_name + '/'

    # spark server
    spark_url = 'spark://' + config["spark"]["dns"]

    # postgresql server on both subnets
    postgres_url_1 = 'jdbc:postgresql://' + config["postgres"]["dns-1"] + '/'\
                   + config["postgres"]["db"] + '?ssl=require'
    postgres_url_2 = 'jdbc:postgresql://' + config["postgres"]["dns-2"] + '/'\
                   + config["postgres"]["db"] + '?ssl=require'                   
    postgres_credentials = {
        'user': config["postgres"]["user"],
        'password': config["postgres"]["password"]
    }

    # postgreSQL and cassandra keywords
    table_monthly = "measurements_monthly"

    ###################################################
    # Retrieve adjancy list (grid points within 30 miles) of each station
    ##################################################

    global STATIONS
    STATIONS = get_grid_from_file("stations.json")

    ###################################################
    # Ensure data file name is provided
    ###################################################

    # Return an error if no filename is given
    if len(argv) < 1:
        raise AssertionError("Usage: raw_batch.sh <data_file>")

    # Argument should be the name of the datafile in s3
    data_fname = argv[1]
    print('Processing file {}\n'.format(data_fname))

    ###################################################
    # Create Spark session and context
    ###################################################
    
    sc = SparkContext(spark_url, data_fname)
    spark = SparkSession(sc)
    sqlContext = SQLContext(sc)

    ###################################################
    # Schemas for converting RDDs to DataFrames & writing to databases
    ###################################################

    schema_monthly = StructType([
        StructField("grid_id", IntegerType(), False),
        StructField("time", TimestampType(), False),
        StructField("parameter", IntegerType(), False),
        StructField("c", FloatType(), False)
    ])

    ###################################################
    # Define RDD reading in hourly data
    ###################################################

    raw = s3 + data_fname
    data_rdd = sc.textFile(raw)

    ###################################################
    # Compute hourly pollution levels on the grid
    ###################################################

    data_hourly = data_rdd\
        .map(parse_measurement_record)\
        .filter(lambda line: line is not None)\
        .flatMap(station_to_grid)\
        .reduceByKey(sum_weight_and_prods)\
        .map(calc_weighted_average_grid)\
        .persist(StorageLevel.MEMORY_AND_DISK)

    ###################################################
    # Average pollution levels for each month
    ###################################################

    data_monthly = data_hourly\
        .map(group_by_month)\
        .reduceByKey(sum_weight_and_prods)\
        .map(average_over_month)\
        .persist(StorageLevel.MEMORY_AND_DISK)

    ###################################################
    # Write monthly data to Postgres database in both subnets
    ###################################################

    data_monthly_df = spark.createDataFrame(data_monthly, schema_monthly)
    data_monthly_df.write.jdbc(
        url=postgres_url_1, table=table_monthly,
        mode='append', properties=postgres_credentials
    )
        data_monthly_df.write.jdbc(
        url=postgres_url_2, table=table_monthly,
        mode='append', properties=postgres_credentials
    )

if __name__ == '__main__':
    main(sys.argv)
