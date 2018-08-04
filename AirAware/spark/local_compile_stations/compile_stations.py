from __future__ import print_function
import csv
import json
from dateutil import parser
from StringIO import StringIO
from math import radians, sin, cos, sqrt, asin
import configparser
from pyspark import SparkConf, SparkContext


def valid_nonzero_float(string):
    '''
    True for a string that represents a nonzero float or integer

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
        if number != 0.:
            return number
        else:
            return None
    except ValueError:
        return None


def parse_station_record(station_record):
    '''
    This function splits station record efficiently using csv package

    Input
    -----
    station_record : str
                One line containing air monitor reading

    Returns
    -------
    tuple
                Tuple characterizing station (station_id, latitude, longitude)
    '''


    # Preliminaries
    f = StringIO(station_record.encode('ascii', 'ignore'))
    reader = csv.reader(f, delimiter=',')
    record = reader.next()
    state_id = record[0]

    # Filter out header, Canada, Mexico, US Virgin Islands, or Guam
    if state_id in ['State Code', 'CC', '80', '78', '66']:
        return None

    # Define station ID
    county_id = record[1]
    site_number = record[2]
    station_id = '|'.join([state_id, county_id, site_number])

    # Make sure latitude and longitude is valid
    latitude = valid_nonzero_float(record[3])
    longitude = valid_nonzero_float(record[4])
    if not latitude or not longitude:
        return None

    # Make sure geo-spatial coordinates are valid
    datum = record[5]
    if datum not in ['WGS84', 'NAD83']:
        return None

    # Make sure stations are not closed before 1/1/1980
    closed = record[10]
    if closed:
        closed_date = parser.parse(closed)
        history_span = parser.parse('1980-01-01')
        if closed_date < history_span:
            return None

    # If all checks are passed then return record for station
    return (station_id, latitude, longitude)


def calc_distance(lat1, lon1, lat2, lon2):
    '''
    Compute distance between two geographical points
    Source: https://rosettacode.org/wiki/Haversine_formula#Python

    Parameters
    ----------
    lat1 : float
    lon1 : float
            Latitude and longitude of the first geographical point

    lat2 : float
    lon2 : float
            Latitude and longitude of the second geographical point


    Returns
    -------
    float
            Distance between two points in kilometers
    '''


    R = 3959.  # Earth's radius in miles
    delta_lat = radians(lat2 - lat1)
    delta_lon = radians(lon2 - lon1)
    lat1 = radians(lat1)
    lat2 = radians(lat2)
    a = sin(delta_lat / 2.0) ** 2 + \
        cos(lat1) * cos(lat2) * sin(delta_lon / 2.0) ** 2
    c = 2 * asin(sqrt(a))
    return R * c


def determine_grid_point_neighbors(rdd):
    '''
    Determine the list of stations within 30 miles of the current station

    Parameters
    ----------
    rdd : RDD
                RDD of air monitors readings

    Returns
    -------
    RDD
                RDDs of air monitors reading transformed to nearest grid points
    '''


    # Set options
    d_cutoff = 30. # 30 mile cut-off
    precision = 1  # Store one decimal place for distance in miles

    # Retrieve station ID, latitude and longitude
    station_id = rdd[0]
    station_latitude = rdd[1]
    station_longitude = rdd[2]

    # Determine adjacent grid points (< 30 miles away)
    adjacent_grid_points = {}
    for grid in GRID:
        grid_id = grid["id"]
        grid_longitude = grid["lon"]
        grid_latitude = grid["lat"]
        d = calc_distance(grid_latitude, grid_longitude,
                          station_latitude, station_longitude)
        if d < d_cutoff:
            adjacent_grid_points[grid_id] = round(d, precision)
    return (station_id, adjacent_grid_points)


def main():

    ##################################################
    # Create spark session
    ##################################################

    conf = SparkConf().setMaster("local[*]").setAppName("compile_stations")

    sc = SparkContext(conf = conf)

    ##################################################
    # Read in JSON grid file and store as global GRID
    ##################################################

    with open('grid.json', 'r') as f:
        raw_json = f.readline()
    global GRID
    GRID = json.loads(raw_json)

    ##################################################
    # Determine station adjacency list
    ##################################################

    # Link to data file containing station data
    raw = 'file:////Users/cheuklau/Documents/GitHub/insight_devops_project/AirAware/spark/local_compile_stations/aqs_sites.csv'

    # Define RDD reading in station data
    data_rdd = sc.textFile(raw, 3)

    # Generate list of stations and list of grid points within 30 miles of them
    stations = data_rdd.map(parse_station_record)\
                       .filter(lambda line: line is not None)\
                       .map(determine_grid_point_neighbors)\
                       .collectAsMap()

    ##################################################
    # Write station adjacency list to file
    ##################################################

    with open('stations.json', 'w') as f:
        json.dump(stations, f)


if __name__ == '__main__':
    main()
