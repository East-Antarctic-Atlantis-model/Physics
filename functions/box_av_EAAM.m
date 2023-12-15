% BOX_AV_JFRE  Calculate average props profile for modelling polygons
%%      Modified by:  (Javier Porobic)  %%
%%      Based on Jeff Dunn code '2009'  %%

% clear
% close all
% addpath('/datasets/work/oa-alantis/work/EA_model/Physics/functions/')
% 
% %%%       GLOBAL VARIABLES    %%%
% % Get the boxes  %%
% % Read the BMG file to get the value of the parameter from the polygons
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
% varn = {'salt';  'temp';  'wt'; 'iceh'}
% 
% fnm = '/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-salt-1-daily-mean-ym_1999_01.nc'
% fnm='/datasets/work/oa-alantis/work/Hydro_EAA/iceh.1999-01-daily.nc'
% %  fll = '/home/por07g/Documents/2019/Oil_spill/Hidro_Data/Raw_data/Original/mesh.nc'
% 
% varn = 'iceh'
% % %
% fln=1
function [av,nav] = box_av_SS(vert, varn, dlev, fnm, fln)
 %% Global Variables  %%
%  ncdisp(fnm)
    nc   = netcdf.open(fnm);
    dint = diff(dlev);
    nlay = length(dint);
    lon_vec  = netcdf.getVar(nc, netcdf.inqVarID(nc, 'xu_ocean'), 'double');
    lat_vec  = netcdf.getVar(nc, netcdf.inqVarID(nc, 'yu_ocean'),'double');
    [lon, lat]=meshgrid(lon_vec,lat_vec);
    %if biol
    tims = netcdf.getVar(nc, netcdf.inqVarID(nc, 'time'));
    zc   =  -netcdf.getVar(nc, netcdf.inqVarID(nc, 'st_ocean'), 'double');
    ntm  = length(tims);
    nbox = length(vert);
    %% just for the file name
    if fln < 10
        fln = (['00', num2str(fln)]);
    elseif(fln < 100) 
        fln = ['0', num2str(fln)]; 
    else
        fln = num2str(fln);
    end


file1=([fln, varn, '_SS_First_Step.mat']);
if ~exist(file1, 'file') % This part need to be run only ones. its related
                         % with the general model configuration.
    barea = zeros(nbox);
    ngrd  = 0;
    for ibx = 1 : nbox  % Prepare the integration grid for all faces
        x          = vert{ibx}(:, 1);
        y          = vert{ibx}(:, 2);
        ig         = find(inpolygon(lon, lat, x, y)); % cell by polygon
        nav(ibx)   = length(ig);
        ii         = ngrd + (1 : nav(ibx));
        ngrd       = ngrd + nav(ibx);
        idx{ibx}   = ii;
        flo(ii)    = lon(ig);
        fla(ii)    = lat(ig);
        [tix, tiy] = find(inpolygon(lon,lat,x,y));
        ix{ibx}    = tix;
        iy{ibx}    = tiy;
        %% the area of the plygon is only important for production %%
        if strcmp(varn,'wt')
            % this pas lat, lon to x, y.
            % in that way its easy and fast to calculate the area
            xx         = (x - mean(x)) .* latcor(y) * 111119;
            yy         = y * 111119;
            barea(ibx) = polyarea(xx, yy) ./ 1000000;
        else
            barea(ibx) = 1.0;
        end
    end
    save(file1, 'zc', 'idx', 'flo', 'fla', 'nav', 'iy', 'ix', 'barea')
else
    disp(['loading  - ', file1]);
    load(file1)
end

if ~(strcmp( varn, 'SG_N') || strcmp( varn, 'EpiPAR'))
    Var_avg = repmat(nan,[nbox ntm nlay]);
else
    Var_avg = repmat(nan,[nbox ntm]);
end

file2   = [fln, varn, '_SS_Second_step.mat'];
if ~exist(file2, 'file') % This part need to be run only ones. its related
    for id = 0 : (ntm - 1)
        disp(['Analysing time step ', num2str(id)])
        if strcmp( varn, 'SG_N') || strcmp( varn, 'EpiPAR') %% ICE?
            varData = permute(netcdf.getVar(nc, netcdf.inqVarID(nc, varn), [0, 0, 0, id],[719, 458, 75, 1],'double'), [2 1]);
        else
            varData = permute(netcdf.getVar(nc, netcdf.inqVarID(nc, varn), [0, 0, 0, id],[719, 458, 75, 1],'double'), [3 2 1]);
        end
        imodxy = find(~isnan(lon));
        xlon   = lon(imodxy);
        ylat   = lat(imodxy);
        varData(varData >= 1.0e+16) = nan;
        if ~(strcmp( varn, 'SG_N') || strcmp( varn, 'EpiPAR'))
             for layer = 1 : nlay
                 layer_var_data = squeeze(mean(varData(zc <= -dlev(layer) & zc >= -dlev(layer+1), :, :), 1, 'double','omitnan'));
                 %% removing Nans
                 valid_data = layer_var_data(imodxy);
                 %% creating the array (griddata)
                 interpolatedVarData(layer, :) = griddata(xlon, ylat, valid_data, flo, fla);
             end
         else
             valid_data          = varData(imodxy);
             interpolatedVarData = griddata(xlon, ylat, valid_data, flo, fla);
         end
        for jj = 1 : nbox  %% By box
            if ~(strcmp( varn, 'SG_N') || strcmp( varn, 'EpiPAR'))
                tmp = zeros(nlay, nav(jj));
                %                for ij = 1 : nav(jj)  % For each grid cell in this box.
                for lvs = 1 : nlay  % by layer
                    for ij = 1 : nav(jj)  % For each grid cell in this box.
                                          %Average by box by grid cell by layer
                        tmp(lvs, ij) = barea(jj) .* mean(interpolatedVarData(lvs, idx{jj}(ij)), 1, 'double', 'omitnan');
                    end
                    Var_avg(jj,(id + 1), lvs) = mean(tmp(lvs,:), 'double', 'omitnan');
                end

            else
                for ij = 1 : nav(jj)  % For each grid cell in this box.
                    tmp(ij) = barea(jj) .* mean(interpolatedVarData(idx{jj}(ij)), 1, 'double', 'omitnan');
                    Var_avg(jj,(id + 1)) = mean(tmp(:), 'double', 'omitnan');
                end
            end
        end
    end
    save(file2, 'Var_avg', 'tims')
else
    disp(['loading  - ', file2]);
    load(file2)
end


