import xarray as xr
import numpy as np
import sys

# getting the file name from the command line
# filename = sys.argv[1]
filename = '/home/por07g/Documents/Projects/Supervision/Ilaria/tools/temporal_input/ocean-3d-v-1-daily-mean-ym_1999_01.nc'
# variable = sys.argv[2]
out_name = filename[-7:]
# Now you can use the filename to open the dataset
ds = xr.open_dataset(filename)

# Open the netCDF file using xarray
# ds = xr.open_dataset(
#    '/home/por07g/Documents/Projects/Supervision/Ilaria/tools/temporal_input/ocean-3d-u-1-daily-mean-ym_1999_01.nc')
# out_name = filename[-7:]
variable = 'v'
# Define the minimum and maximum longitude and latitude
# These values are used to create a rectangle to zoom in on the region of interest (the EAAM)
min_lon = 45.0
min_lat = -73.0
max_lon = 117.0
max_lat = -51.0
# Extract the latitude and longitude arrays using numpy
lat = np.array(ds['yu_ocean'])
lon = np.array(ds['xu_ocean'])
# change the longitude of the shapefile to be between 0 and 360
temp_lon = np.where(lon < 180, lon + 360, lon)
new_lon = np.where(temp_lon > 180, temp_lon - 360, temp_lon)

# Get the sorted indices of the new_lon array
sorted_indices = np.argsort(new_lon)
# Create a new array for the sorted longitudes and the corresponding u values
new_lon_sorted = new_lon[sorted_indices]

count_lon = np.count_nonzero(
    (new_lon_sorted > min_lon) & (new_lon_sorted < max_lon))
count_lat = np.count_nonzero((lat > min_lat) & (lat < max_lat))
u_sorted_reduced_array = np.empty(
    (len(ds['time']), len(ds['st_ocean']), count_lat, count_lon))
print(u_sorted_reduced_array.shape)
# Loop through all time and st_ocean values
for t in range(ds.dims['time']):
    for d in range(ds.dims['st_ocean']):
        # Extract one time step and one depth of the u array
        u_sorted = ds[variable].isel(
            time=t, st_ocean=d, xu_ocean=sorted_indices)
        # Replace the 'xu_ocean' values in 'u_sorted' with 'new_lon_sorted'
        u_sorted['xu_ocean'] = new_lon_sorted
        # Reduce the size of the u_sorted array based on the minimum and maximum longitude and latitude
        u_sorted_reduced = u_sorted.sel(xu_ocean=slice(
            min_lon, max_lon), yu_ocean=slice(min_lat, max_lat))
        u_sorted_reduced_np = u_sorted_reduced.values
        u_sorted_reduced_array[t, d, :, :] = u_sorted_reduced_np

# Convert the list of sorted and reduced u arrays to a 3D numpy array
# u_sorted_reduced_array = np.array(u_sorted_reduced_list)
# print out the dimension fo u_sorted_reduced_array
print(u_sorted_reduced_array.shape)

# Create a new 'xu_ocean' coordinate that matches the size of the 'xu_ocean' dimension in 'u_sorted_reduced_array'
new_xu_ocean = new_lon_sorted[:u_sorted_reduced_array.shape[3]]
new_yu_ocean = ds['yu_ocean'].sel(yu_ocean=slice(min_lat, max_lat))

# Create a new xarray.DataArray with the new_u DataArray and the new coordinates
# Create a new xarray.DataArray with the new_u DataArray and the new coordinates
new_u = xr.DataArray(u_sorted_reduced_array, dims=ds[variable].dims, coords={
                     'time': ds['time'], 'st_ocean': ds['st_ocean'], 'xu_ocean': new_xu_ocean, 'yu_ocean': new_yu_ocean})
# Create a new xarray.DataArray with the same dimensions and coordinates as the original u array
# new_u = xr.DataArray(u_sorted_reduced_array,
#                    dims=ds['u'].dims, coords=ds['u'].coords)

# Create a new xarray.Dataset with the new_u DataArray and the new coordinates
new_ds = xr.Dataset({variable: new_u}, coords={
                    'time': ds['time'], 'st_ocean': ds['st_ocean'], 'xu_ocean': new_xu_ocean, 'yu_ocean': new_yu_ocean})

# Save the new Dataset to a netCDF file
# new_ds.to_netcdf('/datasets/work/oa-alantis/work/Hydro_EAA/sampled_outputs/' +
#                 variable + out_name, engine='h5netcdf')

new_ds.to_netcdf('/home/por07g/Documents/Projects/Supervision/Ilaria/tools/temporal_input/' +
                 variable + out_name, engine='h5netcdf')
