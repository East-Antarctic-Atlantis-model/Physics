import xarray as xr
import numpy as np
import dask.array as da
from dask.distributed import Client

# Define the minimum and maximum longitude and latitude
# These values are used to create a rectangle to zoom in on the region of interest (the EAAM)
min_lon = 45
min_lat = -73
max_lon = 117
max_lat = -51

# Open the netCDF file using xarray
# ds = xr.open_dataset(
#    'temporal_input/ocean-3d-u-1-daily-mean-ym_1999_01.nc', chunks={'time': -1}, engine='h5netcdf')
ds = xr.open_dataset('/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-u-1-daily-mean-ym_1999_01.nc',
                     chunks={'time': 10, 'st_ocean': 50,
                             'xu_ocean': 100, 'yu_ocean': 100},
                     engine='netcdf4')
ds = ds.chunk({'time': 'auto', 'st_ocean': 'auto',
              'xu_ocean': 'auto', 'yu_ocean': 'auto'})
if __name__ == '__main__':
    # Extract the latitude and longitude arrays using numpy
    lat = np.array(ds['yu_ocean'])
    lon = np.array(ds['xu_ocean'])
    # change the longitude of the netcdf to be between 0 and 360
    temp_lon = np.where(lon < 180, lon + 360, lon)
    new_lon = np.where(temp_lon > 180, temp_lon - 360, temp_lon)
    # Get the sorted indices of the new_lon array
    sorted_indices = np.argsort(new_lon)
    # Create a new array for the sorted longitudes and the corresponding u values
    new_lon_sorted = new_lon[sorted_indices]

    u = ds['u'].load()  # Load the 'u' variable into memory
    u_dask = u.data  # Create the Dask array
    # Create a Dask array for the sorted indices
    sorted_indices_dask = da.from_array(
        sorted_indices, chunks=sorted_indices.shape)
    # Sort the u array along the longitude dimension using Dask
    u_sorted_dask = u_dask[:, :, :, sorted_indices_dask]
    # Convert the sorted Dask array back to an xarray DataArray
    u_sorted = xr.DataArray(u_sorted_dask, dims=ds['u'].dims, coords={
                            'time': ds['time'], 'st_ocean': ds['st_ocean'], 'xu_ocean': new_lon_sorted, 'yu_ocean': ds['yu_ocean']})
    # Select a slice of the data using the sel method
    u_sorted_reduced = u_sorted.sel(xu_ocean=slice(
        min_lon, max_lon), yu_ocean=slice(min_lat, max_lat))
    # num_non_empty = u_sorted_reduced.count().values
    # print(num_non_empty)
    # Dimensions of the u_sorted_reduced array
    new_lon = new_lon_sorted[(new_lon_sorted >= min_lon)
                             & (new_lon_sorted <= max_lon)]
    new_lat = lat[(lat >= min_lat) & (lat <= max_lat)]
    # Create a new xarray.DataArray with the sorted u array and the new coordinates
    new_u = xr.DataArray(u_sorted_reduced, dims=ds['u'].dims, coords={
                         'time': ds['time'], 'st_ocean': ds['st_ocean'], 'xu_ocean': new_lon, 'yu_ocean': new_lat})
    # Create a new xarray.Dataset with the new_u DataArray
    new_ds = xr.Dataset({'u': new_u})
    # Save the new Dataset to a netCDF file
    to_netcdf_delayed = new_ds.to_netcdf(
        'new_u.nc', engine='h5netcdf', compute=False)
    # Start a Dask client to manage the computation

# from dask.distributed import Client
# client = Client('scheduler-address:8786')

if __name__ == '__main__':
    with Client() as client:
        # Compute the result and save it to the netCDF file
        client.compute(to_netcdf_delayed)
