import configparser
import psycopg2
import sys
import os


def create_tables():
    '''
    Create tables in the PostgreSQL database
    '''
    commands = (
        """
        DROP TABLE IF EXISTS grid CASCADE;
        DROP TABLE IF EXISTS measurements_monthly;
        """,
        """
        CREATE TABLE IF NOT EXISTS grid (
            grid_id INT PRIMARY KEY,
            longitude float4 NOT NULL,
            latitude float4 NOT NULL,
            location geography(POINT) NOT NULL);
        """,
        """
        CREATE TABLE IF NOT EXISTS measurements_monthly (
            grid_id INT NOT NULL REFERENCES grid (grid_id) ON DELETE CASCADE,
            time TIMESTAMP NOT NULL,
            parameter INT NOT NULL,
            C REAL,
            PRIMARY KEY (grid_id, time, parameter) );
        CREATE RULE "measurements_monthly_on_duplicate_ignore" AS ON INSERT TO "measurements_monthly"
            WHERE EXISTS(SELECT 1 FROM measurements_monthly
                WHERE (grid_id, time, parameter)=(NEW.grid_id, NEW.time, NEW.parameter))
            DO INSTEAD NOTHING;
        """
    )

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
            print("executed command")
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


if __name__ == '__main__':
    create_tables()
