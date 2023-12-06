import xarray as xr
import numpy as np
import geopandas as gpd
import sys

# getting the file name from the command line
filename = sys.argv[1]
variable = sys.argv[2]
out_name = filename[-7:]
# Now you can use the filename to open the dataset
ds = xr.open_dataset(filename)

# Open the netCDF file using xarray
# ds = xr.open_dataset('temporal_input/ocean-3d-u-1-daily-mean-ym_1999_01.nc')

# Define the minimum and maximum longitude and latitude
# These values are used to create a rectangle to zoom in on the region of interest (the EAAM)
min_lon = 45.0
min_lat = -73.0
max_lon = 117.0
max_lat = -51.0


# Extract the latitude and longitude arrays using numpy
lat = np.array(ds['yu_ocean'])
lon = np.array(ds['xu_ocean'])
print(lon)
# change the longitude of the shapefile to be between 0 and 360
temp_lon = np.where(lon < 180, lon + 360, lon)
new_lon = np.where(temp_lon > 180, temp_lon - 360, temp_lon)

# Get the sorted indices of the new_lon array
sorted_indices = np.argsort(new_lon)
# Create a new array for the sorted longitudes and the corresponding u values
new_lon_sorted = new_lon[sorted_indices]
print(new_lon_sorted)
u_sorted_reduced_list = []
# Loop through all time and st_ocean values
for t in range(ds.dims['time']):
    for d in range(ds.dims['st_ocean']):
        # Extract one time step and one depth of the u array using isel
        u = ds['u'].isel(time=t, st_ocean=d)
        # Sort the u array based on the sorted indices of the longitude array
        u_sorted = u[:, sorted_indices]
        # print(u_sorted['xu_ocean'])
        # Reduce the size of the u_sorted array based on the minimum and maximum longitude and latitude
        u_sorted_reduced = u_sorted.sel(xu_ocean=slice(
            min_lon, max_lon), yu_ocean=slice(min_lat, max_lat))
        # Add the sorted and reduced u array to the list
        # u_sorted_reduced_list[t * ds.dims['st_ocean'] + d] = u_sorted_reduced
        u_sorted_reduced_list.append(u_sorted_reduced)

# Convert the list of sorted and reduced u arrays to a 3D numpy array
u_sorted_reduced_array = np.array(u_sorted_reduced_list)

# Create a new xarray.DataArray with the same dimensions and coordinates as the original u array
new_u = xr.DataArray(u_sorted_reduced_array,
                     dims=ds['u'].dims, coords=ds['u'].coords)

# Create a new xarray.Dataset with the new_u DataArray and the new coordinates
new_ds = xr.Dataset({'u': new_u}, coords={
                    'time': ds['time'], 'st_ocean': ds['st_ocean'], 'xu_ocean': new_lon_sorted, 'yu_ocean': ds['yu_ocean']})

# Save the new Dataset to a netCDF file
new_ds.to_netcdf('temporal_input/' + variable + out_name, engine='h5netcdf')
