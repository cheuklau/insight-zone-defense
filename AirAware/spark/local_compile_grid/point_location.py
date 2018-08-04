from shapely.geometry import MultiPoint, Point, Polygon
import shapefile


def get_us_border_polygon():
    '''
    
    Returns a polygon for each state as a dictionary.
    Requires files in states directory.

    '''

    sf = shapefile.Reader("./states/cb_2017_us_state_20m")
    shapes = sf.shapes()
    fields = sf.fields
    records = sf.records()
    state_polygons = {}
    for i, record in enumerate(records):
        state = record[5]
        points = shapes[i].points
        poly = Polygon(points)
        state_polygons[state] = poly

    return state_polygons


# Store polygon for each state.
state_polygons = get_us_border_polygon()


def in_us(lat, lon):
    '''

    Returns true if the latitude and longitude provided is in United States,
    otherwise false.

    '''


    p = Point(lon, lat)
    for state, poly in state_polygons.items():
        if poly.contains(p):
            return state
    return None
