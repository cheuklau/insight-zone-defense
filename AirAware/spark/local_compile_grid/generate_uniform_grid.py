# Import libaries
import json
import shapefile
from point_location import in_us

# Absolute maximum and minimum latitude and longitude values
N = 72.
S = 18.
W = -178.
E = -65.

# Number of discretizations in latitude and longitude domains
N_lat = 430
N_lon = 860

# Width of latitude and longitude discretizations
d_lat = (N-S)/float(N_lat)
d_lon = (E-W)/float(N_lon)

# Define grid
# We are looping through all of the latitude and longitude discretization
# points and appending the current value of each to the grid. 
# Note that the total number of points we check is 369,800 but not all the 
# points live in the United States. We filter those out with in_us function. 
grid = []
grid_id = 0
precision = 3
for ilat in range(0, N_lat):
    for ilon in range(0, N_lon):
        lat = S + d_lat*ilat
        lon = W + d_lon*ilon
        if in_us(lat, lon):
            grid_id += 1
            grid.append({"id": grid_id, "lat": round(lat, precision), "lon": round(lon, precision)})

# Display number of grid points for verification
print(grid_id)
with open('grid.json', 'w') as f:
    json.dump(grid, f)
