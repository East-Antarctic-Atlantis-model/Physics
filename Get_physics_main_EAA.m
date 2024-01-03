%% Getting the main fluxes and variables for the EA model

% This function retrieves the main fluxes and variables required for the EAmodel from input data files. The function performs the following steps:
% Step 1: Reading the box information
% The function reads the box information from a BGM (Bathymetric Geographic Model) file, including the number of boxes, faces, box IDs, centroids, areas, vertices, and interfaces.
% Step 2: Setting up global variables
% The function assigns values to various global variables used throughout the code, such as face IDs, neighboring layers, face points, and depth levels.
% Step 3: Running the model and saving results
% The function runs the model and saves the transport data for each year. It iterates over the input files containing U and V velocities and calculates the transport between layers using the provided parameters. The results are stored in temporary files.
% Step 4: Combining transport data
% The function loads the temporary transport data files for each year and combines them into a single matrix, along with the corresponding time information.
% Step 5: Writing transport data to a NetCDF file
% The function writes the combined transport data to a NetCDF file, including the box connectivity, transport values, and time information.
% Step 6: Retrieving variable data by layer
% The function retrieves variable data (such as water velocity, salinity, and temperature) from input files, calculates averages by layer, and stores the results in temporary files.
% Step 7: Combining variable data
% The function loads the temporary variable data files for each variable and combines them into a single matrix, along with the corresponding time information.
% Step 8: Writing variable data to a NetCDF file
% The function writes the combined variable data to a NetCDF file, including the box IDs, variable values, and time information.
% Note: The specific file paths and iteration details in this code are provided as examples and may need to be adjusted for your specific use case.
%% Example Usage:
% Modify the file paths and iteration details according to your data.
%% Input:
% There are no input parameters for this function. However, it relies on the following files and variables: 

% - BGM_JFR_ll: Bathymetric Geographic Model (BGM) file path
% - vert: Vertex information matrix
% - pt1: Face 1 information matrix
% - pt2: Face 2 information matrix
% - dlev: Depth level array
% - dinc: Face integration step size
% - rimn: Rim parameter
% - fnm: Input transport data file path
% - fll: Mesh file path
% - avname: Variable name (e.g., 'wVelocity', 'salinity', 'temperature')
% - nfile: Variable data file index
% - guard: Output NetCDF file path
%% Output:
% The function does not return any outputs directly. However, it generates NetCDF files containing the main fluxes (transport)
%  and variables (water velocity, salinity, temperature) required for the SAM model.

% - NetCDF files:
%   - Transport_2016.nc: Contains the transport data
%   - Variables_2016.nc: Contains the variable data (water velocity, salinity, temperature)
% Note: it can be one file containing everything

clear
close all
addpath('/datasets/work/oa-alantis/work/EA_model/Physics/functions/')

%%%       GLOBAL VARIABLES    %%%
% Get the boxes  %%
% Read the BMG file to get the value of the parameter from the polygons
BGM_JFR_ll = '/datasets/work/oa-alantis/work/EA_model/Physics/EAA29_ll_v2.bgm';
[nbox,nface,bid,cent,b_area,vert, iface, botz] = read_boxes(BGM_JFR_ll);
[nulr,nupt1,nupt2] = read_faces2(nbox, nface, bid, vert, iface, BGM_JFR_ll);
iface      = iface;  %% Id of the faces
lr         = nulr;   %% Neightbourn Layers
pt1        = nupt1;  %% Face 1
pt2        = nupt2;  %% Face 2
irealfaces = find(~isnan(nupt1(:,1)));  % (ie those ref'd in box definitions)
fcid       = (irealfaces-1);
rimn       = 10;    % default 3 is probably too few
dinc       = 1;      %% 0.1; default 10km is probably ok, but for large boxes
                      % May want to reduce the face integration step 'dinc' for
                      % models with small or narrow boxes. Because the small boxes
                      % don't have problems of hiperdifusion
dlev = [0  20 50 100 200 300 400 750 1000 2000 5000]; %% This structure is related with the biology                                 %% and with the maximum deph in the BMG model


%% Running the model - saving by years %%
% Transport between layers
direc = (['/datasets/work/oa-alantis/work/Hydro_EAA/sampled_outputs/']);
%direc = (['/home/por07g/Documents/2019/Oil_spill/Hidro_Data/first_hidro/']);
filesu = dir([direc, 'u_*.nc']); %% U and V in teh same file
filesv = dir([direc, 'v_*.nc']); %% U and V in teh same file
cd("/datasets/work/oa-alantis/work/EA_model/Output_temporal/")
%% for year = 2015 : ????
for f  =  1 : length(filesu)
        fnmu         = [direc, filesu(f).name];
        fnmv         = [direc, filesv(f).name];
        transport_EAAM(vert, pt1, pt2, dlev, dinc, rimn, fnmu, fnmv, f);
end
look = dir(['*EAAM_second_Step.mat']);
for f = 1 : length(look)
    load(look(f).name)
    if f == 1
        Tfinal = T;
        nctime = tims;
    else
        Tfinal = cat(2, Tfinal, T);
        nctime = cat(1, nctime, tims);
    end
end

%% save('Tfinal.mat', 'Tfinal', 'nctime'); %% no need this bit, used just in case you
%% don´t do the transformation
guard = (['/datasets/work/oa-alantis/work/EA_model/Final_raw_netcdf_EAAM/EAAM_Transport.nc']);
write_trans_file_EAAM(pt1, pt2, lr, nctime, Tfinal, fcid, guard)
plot(Tfinal(:,3,2),'r')
image(squeeze(Tfinal(:,300,:)))
%% variables by layer
%% Variables
%% for y = 2015:????
varn = {'salt';  'temp';  'wt'}
direc = (['/datasets/work/oa-alantis/work/Hydro_EAA/sampled_outputs/']);
cd (['/datasets/work/oa-alantis/work/EA_model/Variable_raw/']); %% temporal foldet to store the temporal files
for v  =  1 : length(varn)
    avname  = char(varn(v));
    
    if~(strcmp(avname,'iceh'))
        files=dir([direc, avname,'*.nc']);
    else
        files = dir([direc,'iceh.*.nc']);
    end

    for nfile = 1 : length(files)
        fnm   = [direc, files(nfile).name];
        box_av_EAAM(vert, avname, dlev, fnm, nfile)
    end
    t_files = dir(['*', avname, '_SS_Second_step.mat']);
    for f = 1 : length(t_files)
        load(t_files(f).name)
        if f == 1
            Av_final = Var_avg;
            nctime   = tims;
        else
            Av_final = cat(2, Av_final, Var_avg);
            nctime   = cat(1, nctime, tims);
        end
    end
    file.save = (['Av_', avname, '.mat'])
    save(file.save, 'Av_final', 'nctime')
    % writing the NETCDF file
    %write_av_var(nctime, bid, avname, Av_final, guard)
end
%% end
% put all the variables together
temp = load(['/datasets/work/oa-alantis/work/EA_model/Variable_raw/Av_temp.mat']);
salt = load(['/datasets/work/oa-alantis/work/EA_model/Variable_raw/Av_salt.mat']);
vert = load(['/datasets/work/oa-alantis/work/EA_model/Variable_raw/Av_wt.mat']);

%% Writing variables
temperature = temp.Av_final;
salinity    = salt.Av_final;
vertical    = vert.Av_final;
%% Saving the netdf file
nctime      = temp.nctime;
guard = (['/datasets/work/oa-alantis/work/EA_model/Final_raw_netcdf_EAAM/EAAM_Variables_1999.nc']);
write_av_var_new(nctime, bid, temperature, salinity,  vertical, guard);
