import configparser
import numpy
import json
import psycopg2
import sys
import os


def insert_records(commands):
    '''
    Insert grid points into the database
    '''
    # Read in configuration file

    config = configparser.ConfigParser()
    config.read('../setup.cfg')

    postgres_url = 'postgresql://'\
                   + config["postgres"]["user"] + ':' + config["postgres"]["password"]\
                   + '@localhost:' + config["postgres"]["port"] + '/' + config["postgres"]["db"]

    conn = None
    try:
        # connect to the PostgreSQL server
        conn = psycopg2.connect(postgres_url)
        cur = conn.cursor()
        # create table one by one
        print("got connection")
        for command in commands:
            cur.execute(command)
        # close communication with the PostgreSQL database server
        cur.close()
        print("closed the cursor")
        # commit the changes
        conn.commit()
        print("committed the connection")
    except (Exception) as error:
        print(error)
        raise error
    finally:
        if conn is not None:
            conn.close()
            print("closed the connection")


def main():

    # File from which to read json
    fname = 'grid.json'

    # Open the json file and read it into a dictionary
    with open(fname, 'r') as f:
        raw_json = f.readline()

    GRID = json.loads(raw_json)

    commands = []

    for grid in GRID:
        grid_id = grid["id"]
        longitude = grid["lon"]
        latitude = grid["lat"]
        commands.append(
        """
        INSERT INTO grid (grid_id, longitude, latitude, location) VALUES ({grid_id}, {longitude}, {latitude}, ST_GeogFromText('POINT({longitude} {latitude})') );
        """.format(**locals())
        )
    insert_records(commands)


if __name__ == '__main__':
    main()
