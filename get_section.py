import xarray as xr
import netCDF4
import datetime
import sys


# Define the URL of the OPeNDAP server and the name of the variable to extract
url = sys.argv[1]
# url = 'https://dapds00.nci.org.au/thredds/dodsC/cj50/access-om2/raw-output/access-om2-01/01deg_jra55v140_iaf/output165/ocean/ocean-3d-u-1-daily-mean-ym_1999_05.nc'
print('print url', url)
var_name = str(sys.argv[2])
print('var_name', var_name)
# var_name = 'u'
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
# convert ds['time'] to datetime.datetime object
time_str = str(ds['time'].values[0])
# remove trailing zeros from microseconds field
time_str = time_str[:-3] + time_str[-3:].rstrip('0')
dt = datetime.datetime.strptime(time_str, '%Y-%m-%dT%H:%M:%S.%f')
# convert datetime.datetime object to netCDF4 time number
time_num = netCDF4.date2num(
    dt, units='days since 1900-01-01 00:00:00', calendar=ds['time'].calendar_type)

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
