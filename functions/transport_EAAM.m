% Transport_GBR  Calculate transports through defined faces, from
%      GBR Model
%
%%      Modified by:  (Javier Porobic)  %%
% clear
% close all
% addpath('/datasets/work/oa-alantis/work/EA_model/Physics/functions/')
% 
% %%%       GLOBAL VARIABLES    %%%
% %% Get the boxes  %%
% %% Read the BMG file to get the value of the parameter from the polygons
% 
% BGM_JFR_ll = '/datasets/work/oa-alantis/work/EA_model/Physics/EAA29_ll_v2.bgm';
% [nbox,nface,bid,cent,b_area,vert, iface, botz] = read_boxes(BGM_JFR_ll);
% [nulr,nupt1,nupt2] = read_faces2(nbox, nface, bid, vert, iface, BGM_JFR_ll);
% iface      = iface;  %% Id of the faces
% lr         = nulr;   %% Neightbourn Layers
% pt1        = nupt1;  %% Face 1
% pt2        = nupt2;  %% Face 2
% irealfaces = find(~isnan(nupt1(:,1)));  % (ie those ref'd in box definitions)
% fcid       = (irealfaces-1);
% rimn       = 10;    % default 3 is probably too few
% dinc       = 1;      %% 0.1; default 10km is probably ok, but for large boxes
%                       % May want to reduce the face integration step 'dinc' for
%                       % models with small or narrow boxes. Because the small boxes
%                       % don't have problems of hiperdifusion
% dlev = [0  20 50 100 200 300 400 750 1000 2000 5000]; %% This structure is related with the biology                                 %% and with the maximum deph in the BMG model
% 
% 
% %% Running the model - saving by years %%
% % Transport between layers
% direc = (['/datasets/work/oa-alantis/work/Hydro_EAA/sampled_outputs/']);
% %direc = (['/home/por07g/Documents/2019/Oil_spill/Hidro_Data/first_hidro/']);
% filesu = dir([direc, 'u_*.nc']); %% U and V in teh same file
% filesv = dir([direc, 'v_*.nc']); %% U and V in teh same file
% fnmu= [direc, filesu(1).name]
% fnmv= [direc, filesv(1).name]
% f=1
function [T, tims] = transport_EAAM(vert, pt1, pt2, dlev, dinc, rimn, fnmu, fnmv, f);
    %% Global Variables  %%
    warning('off','all');
    nc   = netcdf.open(fnmu);
    dint = diff(dlev);
    nlay = length(dint);
    tims = netcdf.getVar(nc, netcdf.inqVarID(nc, 'time'));
    ntm  = length(tims);
    rimx = 400;
    if nargin<5 | isempty(rimn)
        rimn = 3;
    end
    % standard number of integration steps per face
    if nargin < 4 | isempty(dinc)
        dinc = 0.1;
    end
    file1 = (['EAAM_first_Step.mat']);
    if ~exist(file1, 'file')  % This part need to be run only ones. its related
                              % with the general model configuration.
        disp(['Using hydro file ' fnmu]);
        nc   = netcdf.open(fnmu);
        dint = diff(dlev);
        nlay = length(dint);
        tims = netcdf.getVar(nc, netcdf.inqVarID(nc, 'time'));
        lon_vec  = netcdf.getVar(nc, netcdf.inqVarID(nc, 'xu_ocean'), 'double');
        lat_vec  = netcdf.getVar(nc, netcdf.inqVarID(nc, 'yu_ocean'),'double');
        % Create a grid for latitudes and longitudes
        % Doing this to speed up calculation and seatching for nans
        [lon, lat] = meshgrid(lon_vec, lat_vec);

        zc   = -netcdf.getVar(nc, netcdf.inqVarID(nc, 'st_ocean'));
        %% this model doesn't use the Rho-grid
        %% Polygons Faces %%
        ndps  = length(zc);
        nfc   = size(pt1, 1);
        T     = repmat(nan, [nfc ntm nlay]);
        % Prepare the integration grid for each face
        ngrd = 0;
        for ifc = 1:nfc  % Number of faces
            x  = [pt1(ifc,1) pt2(ifc,1)];
            y  = [pt1(ifc,2) pt2(ifc,2)];
            yd = y(2) - y(1); %% Distance between points
            xd = x(2) - x(1);
            if abs(xd) > .00001
                lcor = cosd(mean(y));
                xd   = lcor * xd;
            else
                lcor = 1;
            end
            rdist     = 111.191 * sqrt(yd .^ 2 + xd .^ 2);  % distance in kilometres
            dirn(ifc) = cart2pol(xd, yd);                   % cartesian to polar (cilindrical) coordinates gives th angle
            rinc      = ceil(rdist / dinc);                 % To cope with Large domain:
            if rinc < rimn
                rinc = rimn;
            end
            if rinc > rimx
                rinc = rimx;
            end
            yi   = yd / rinc;
            Y    = (y(1) + (yi / 2)) : yi : (y(2) - (yi / 2));
            total_length = length(Y);
            xi   = xd / (lcor * rinc);
            X = linspace((x(1) + (xi / 2)), (x(2) - (xi / 2)), total_length);
            ninc = length(Y);
            if ninc==0
                ninc = length(X);
                Y = repmat(mean(y), size(X));
            else
                if isempty(X)
                    X = repmat(mean(x), size(Y));
                elseif ninc > 2
                    % Adjustment for lat correction variation along face
                    lenX = X(end) - X(1);
                    xi   = xd / rinc;
                    xn   = xi / cosd(Y(1));
                    X(1) = x(1) + xn / 2;
                    for gg = 2:ninc
                        X(gg) = X(gg-1) + xi / cosd(Y(gg));
                    end
                    % Correcting the last X
                    lenXnew = X(end) - X(1);
                    tmp     = X - X(1);
                    X       = X(1) + tmp * lenX / lenXnew;
                end
            end
            % savind result in a list
            ii       = ngrd + (1:ninc);
            ngrd     = ngrd + ninc;
            idx{ifc} = ii;
            flo(ii)  = X;
            fla(ii)  = Y;
            % In this data all levels are above the bottom.
            abovebot(:, ii) = ones(ndps, ninc);
            % Need to take into account all levels.
            mxdp(ifc) = nfc;
            % Volume interval is distance (changed to m 10^6 so transport in Sv)
            % by depth intervals. (The distan need to be changed from km to m)
            vint{ifc} = dint .* rdist * 1000;
        end
        save(file1, 'vint', 'abovebot', 'idx', 'flo', 'fla', 'ngrd', 'dirn', 'lon','lat',  'zc', 'nfc', 'nlay');
             netcdf.close(nc);
    else
        disp(['using exiting data - ', file1])
        load(file1)
    end

    %% Creation of the Final File %%
    if(f < 10) 
        numtx = ['00', num2str(f)];
    elseif(f < 100) 
        numtx = ['0', num2str(f)]; 
    else
        numtx = num2str(f);
    end 
        
    file2 = ([numtx, 'EAAM_second_Step.mat']);
    if ~exist(file2, 'file')
        ncu     = netcdf.open(fnmu, 'NC_NOWRITE');
        ncv     = netcdf.open(fnmv, 'NC_NOWRITE');
        disp(['Creating new file -', file2])
        %% read steps inside the document  %%
        %%uini = netcdf.getVar(nc, netcdf.inqVarID(nc,'u'));
        for id = 0 : (ntm - 1)
            %% Some clarifications:
            %% Because of memory issues I decide to slice the reading by time step
            %% The original dimension arrange is [Lon Lat Lev Time], so I re
            %% arrange the dimension by [Time Lev(z) Lat Lon]
            u  = permute(netcdf.getVar(ncu, netcdf.inqVarID(ncu,'u'),[0,0,0,id],[719, 458, 75, 1],'double'), [3 2 1]);
            v  = permute(netcdf.getVar(ncv, netcdf.inqVarID(ncv,'v'),[0,0,0,id],[719, 458, 75, 1],'double'), [3 2 1]);
            U  = zeros(nlay, ngrd);
            V  = zeros(nlay, ngrd);
            u(u>=1.0000e+20) = nan;
            v(v>=1.0000e+20) = nan;
            udata = u;
            vdata = v;
            %% This output is not using sigma level niether rho coordinates##
            % interpolation by layers
            imodxy = find(~isnan(lon) & ~(lon == 0));
            xlon = lon(imodxy);
            ylat = lat(imodxy);
            disp(['Analysing Time step ', num2str(id)])
            for layer = 1:nlay
                layer_u_data = mean(udata(zc <= -dlev(layer) & zc >= -dlev(layer+1), ...
                                                  :, :), 1, 'double','omitnan');
                layer_v_data = mean(vdata(zc <= -dlev(layer) & zc >= -dlev(layer+1), ...
                                                  :, :), 1, 'omitnan','double');
                %% removing Nans
                valid_u = layer_u_data(imodxy);
                valid_v = layer_v_data(imodxy);

                %% creating the array (griddata)
                U(layer, :) = griddata(xlon, ylat, valid_u, flo, fla);
                V(layer, :) = griddata(xlon, ylat, valid_v, flo, fla);
            end
            [dir2,spd] = cart2pol(U,V);
            %% U and V along each face
            for jj = 1 : nfc
                ii = idx{jj};
                tt = spd(:, ii) .* sin(dir2(:, ii) - dirn(jj));
                % For each layer
                for lvs = 1:nlay
                    for index = 1:size(ii, 2)
                        value(index) =  mean(tt(lvs, index));
                    end
                    T(jj, id+1, lvs) = vint{jj}(lvs) .* mean(value);
                end
            end
       end
        save(file2, 'T', 'tims')
    else
        disp(['Using previous', file2])
        load(file2)
    end
    fprintf('\r');
    disp('Done       ')
end
