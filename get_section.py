import xarray as xr
import netCDF4
import sys


# Define the URL of the OPeNDAP server and the name of the variable to extract
url = sys.argv[0]
var_name = sys.argv[1]
# print(name_nc_out)
# Open the netCDF file using xarray
ds = xr.open_dataset(url)
filename = 'section_' + ds.filename
print(filename)
lat_min = -72
lat_max = -53.5
lon_min = -280
lon_max = 80
print('Step 01 reading url done!')
# Extract the section of the data
data = ds[var_name].sel(yu_ocean=slice(lat_min, lat_max),
                        xu_ocean=slice(lon_min, lon_max))
# dimensions:
new_lat = ds.yu_ocean.sel(yu_ocean=slice(lat_min, lat_max)).values
new_lon = ds.xu_ocean.sel(xu_ocean=slice(lon_min, lon_max)).values
time_num = netCDF4.date2num(
    ds['time'], units='days since 1900-01-01 00:00:00', calendar=ds['time'].calendar_type)
print('Step 02 extracting data done!')

# Create a new netCDF file
new_file = netCDF4.Dataset('new_file.nc', 'w', format='NETCDF4')
# Define the dimensions of the new file
new_file.createDimension('time', None)
new_file.createDimension('yu_ocean', len(new_lat))
new_file.createDimension('xu_ocean', len(new_lon))
new_file.createDimension('st_ocean', data.shape[1])
print('Step 03 creating new file done!')

# Define the variables of the new file
time_var = new_file.createVariable('time', 'f8', ('time',))
time_var.calendar = ds.time.calendar_type
lat_var = new_file.createVariable('yu_ocean', 'f4', ('yu_ocean'))
lon_var = new_file.createVariable('xu_ocean', 'f4', ('xu_ocean'))
st_ocean = new_file.createVariable('st_ocean', 'f4', ('st_ocean'))
data_var = new_file.createVariable(
    var_name, 'f4', ('time', 'st_ocean', 'yu_ocean', 'xu_ocean'))

print('Step 04 creating variables done!')
# Copy the data to the new file
lat_var[:] = new_lat
lon_var[:] = new_lon
st_ocean[:] = ds.st_ocean[:]
time_var[:] = time_num
data_var[:, :, :, :] = data

# Set the attributes of the variables
time_var.units = ds.time.units
lat_var.units = ds.yu_ocean.units
lon_var.units = ds.xu_ocean.units
data_var.units = 'days since 1900-01-01 00:00:00'
print('Step 05 copying data done!')
# Close the netCDF files
ds.close()
new_file.close()

# Close the netCDF file
print('Step 06 creating new file done!')
