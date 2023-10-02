import numpy as np
import xarray as xr
from scipy.interpolate import griddata
import os

def transport_SS(vert, pt1, pt2, dlev, dinc, rimn, fnm, fll, f):
    # Global Variables
    warning('off', 'all')
    nc = xr.open_dataset(fnm)
    ncll = xr.open_dataset(fll)
    dint = np.diff(dlev)
    nlay = len(dint)
    tims = nc['time'].values
    ntm = len(tims)
    rimx = 400
    if rimn is None:
        rimn = 3
    if dinc is None:
        dinc = 0.1

    file1 = 'SS_first_Step.mat'
    if not os.path.exists(file1):
        print(f'Using hydro file {fnm}')
        lon = ncll['glamu'].transpose('lon', 'lat').values
        lat = ncll['gphiu'].transpose('lon', 'lat').values
        zc = -nc['depth'].values
        gridDepth = ncll['mbathy'].values

        # Polygons Faces
        ndps = len(zc)
        nfc = pt1.shape[0]
        T = np.full((nfc, ntm, nlay), np.nan)

        # Prepare the integration grid for each face
        ngrd = 0
        for ifc in range(nfc):
            x = [pt1[ifc, 0], pt2[ifc, 0]]
            y = [pt1[ifc, 1], pt2[ifc, 1]]
            yd = y[1] - y[0]
            xd = x[1] - x[0]
            if abs(xd) > 0.00001:
                lcor = np.cos(np.radians(np.mean(y)))
                xd = lcor * xd
            else:
                lcor = 1

            rdist = 111.191 * np.sqrt(yd ** 2 + xd ** 2)  # distance in kilometers
            dirn = np.arctan2(xd, yd)  # cartesian to polar (cylindrical) coordinates gives the angle
            rinc = np.ceil(rdist / dinc)  # To cope with Large domain
            rinc = min(max(rinc, rimn), rimx)

            yi = yd / rinc
            Y = np.arange(y[0] + (yi / 2), y[1] - (yi / 2), yi)
            xi = xd / (lcor * rinc)
            X = np.arange(x[0] + (xi / 2), x[1] - (xi / 2), xi)
            ninc = len(Y)
            if ninc == 0:
                ninc = len(X)
                Y = np.full_like(X, np.mean(y))
            elif len(X) == 0 or ninc > 2:
                lenX = X[-1] - X[0]
                xi = xd / rinc
                xn = xi / np.cos(np.radians(Y[0]))
                X[0] = x[0] + xn / 2
                for gg in range(1, ninc):
                    X[gg] = X[gg-1] + xi / np.cos(np.radians(Y[gg]))
                lenXnew = X[-1] - X[0]
                tmp = X - X[0]
                X = X[0] + tmp * lenX / lenXnew

            ii = np.arange(ngrd, ngrd + ninc)
            ngrd += ninc
            idx = {ifc: ii}
            flo = np.zeros_like(X)
            fla = np.zeros_like(Y)
            flo[ii] = X
            fla[ii] = Y

            # In this data, all levels are above the bottom.
            abovebot = np.ones((ndps, ninc))
            # Need to take into account all levels.
            mxdp = np.full(nfc, nlay)
            # Volume interval is distance (changed to m 10^6 so transport in Sv)
            # by depth intervals. (The distance needs to be changed from km to m)
            vint = {ifc: dint * rdist * 1000 for lvs in range(nlay)}

        np.savez(file1, vint=vint, abovebot=abovebot, idx=idx, flo=flo, fla=fla,
                 ngrd=ngrd, dirn=dirn, lon=lon, lat=lat, zc=zc, nfc=nfc)
        nc.close()
        ncll.close()
    else:
        print(f'Using existing data - {file1}')
        data = np.load(file1)
        vint, abovebot, idx, flo, fla, ngrd, dirn, lon, lat, zc, nfc = data['vint'], data['abovebot'], data['idx'], data['flo'], data['fla'], data['ngrd'], data['dirn'], data['lon'], data['lat'], data['zc'], data['nfc']

    # Creation of the Final File
    if f < 10:
        numtx = f'00{f}'
    elif f < 100:
        numtx = f'0{f}'
    else:
        numtx = str(f)

    file2 = f'{numtx}SS_second_Step.mat'
    if not os.path.exists(file2):
        nc = xr.open_dataset(fnm, decode_times=False)
        print(f'Creating new file - {file2}')
        # Read steps inside the document
        for id in range(ntm):
            # Some clarifications:
            # Because of memory issues, I decide to slice the reading by time step
            # The original dimension arrange is [Lon Lat Lev Time], so I re-arrange
            # the dimension by [Time Lev Lat Lon]
            u = nc['uVelocity'][id, ::-1, :, :].values
            v = nc['vVelocity'][id, ::-1, :, :].values
            U = np.zeros((nlay, ngrd))
            V = np.zeros((nlay, ngrd))
            u[u >= 1.0000e+20] = np.nan
            v[v >= 1.0000e+20] = np.nan
            udata = u
            vdata = v

            # Interpolation by layers
            imodxy = np.where((~np.isnan(lon)) & (lon != 0))
            xlon = lon[imodxy]
            ylat = lat[imodxy]
            print(f'Analyzing Time step {id}')
            for layer in range(nlay):
                layer_u_data = np.nanmean(udata[(zc <= -dlev[layer]) & (zc >= -dlev[layer+1])], axis=0)
                layer_v_data = np.nanmean(vdata[(zc <= -dlev[layer]) & (zc >= -dlev[layer+1])], axis=0)
                # Removing Nans
                valid_u = layer_u_data[imodxy]
                valid_v = layer_v_data[imodxy]

                # Creating the array (griddata)
                U[layer, :] = griddata((xlon, ylat), valid_u, (flo, fla), method='linear')
                V[layer, :] = griddata((xlon, ylat), valid_v, (flo, fla), method='linear')

            dir2, spd = np.arctan2(U, V), np.sqrt(U**2 + V**2)

            # U and V along each face
            for jj in range(nfc):
                ii = idx[jj]
                tt = spd[:, ii] * np.sin(dir2[:, ii] - dirn[jj])
                # For each layer
                for lvs in range(nlay):
                    value = np.nanmean(tt[lvs, :], axis=0)
                    T[jj, id, lvs] = vint[jj][lvs] * value

        np.savez(file2, T=T, tims=tims)
    else:
        print(f'Using previous {file2}')
        data = np.load(file2)
        T, tims = data['T'], data['tims']

    print('Done')


# Usage Example
vert = None  # Provide appropriate input for vert
pt1 = None  # Provide appropriate input for pt1
pt2 = None  # Provide appropriate input for pt2
dlev = None  # Provide appropriate input for dlev
dinc = None  # Provide appropriate input for dinc
rimn = None  # Provide appropriate input for rimn
fnm = 'path/to/netcdf_file.nc'  # Replace with the actual path to the netCDF file
fll = 'path/to/another_netCDF_file.nc'  # Replace with the actual path to another netCDF file
f = 1  # Replace with the actual value of f

transport_SS(vert, pt1, pt2, dlev, dinc, rimn, fnm, fll, f)

