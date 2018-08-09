import os
import configparser

# Read in configuration file

config = configparser.ConfigParser()
config.read('../setup.cfg')

#postgres_url = 'postgresql://'\
#               + config["postgres"]["user"] + ':' + config["postgres"]["password"]\
#               + '@localhost:' + config["postgres"]["port"] + '/' + config["postgres"]["db"]

postgres_url = 'postgresql://'\
               + config["postgres"]["user"] + ':' + config["postgres"]["password"]\
               + '@' + config["postgres"]["dns"] + ':' + config["postgres"]["port"]\
               + '/' + config["postgres"]["db"]

secret_key = config["flask"]["secret_key"]
GoogleMapsKey = config["flask"]["GoogleMapsKey"]
GoogleMapsJSKey = config["flask"]["GoogleMapsJSKey"]

# todo: add back in after base devops pipeline is created
# CassandraNode = config["cassandra"]["dns"]

basedir = os.path.abspath(os.path.dirname(__file__))


class Config(object):
    DEBUG = False
    TESTING = False
    CSRF_ENABLED = True
    SECRET_KEY = secret_key
    SQLALCHEMY_DATABASE_URI = postgres_url
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_POOL_SIZE = 0
    SQLALCHEMY_MAX_OVERFLOW = -1
    GOOGLEMAPSKEY = GoogleMapsKey
    GOOGLEMAPSJSKEY = GoogleMapsJSKey
#    CASSANDRA_NODES = CassandraNode


class ProductionConfig(Config):
    DEBUG = False


class StagingConfig(Config):
    DEVELOPMENT = True
    DEBUG = True


class DevelopmentConfig(Config):
    DEVELOPMENT = True
    DEBUG = True


class TestingConfig(Config):
    TESTING = True
