% Water layer thickness
addpath('/datasets/work/oa-alantis/work/EA_model/Physics/Creating_Hydro')
layerdepth = [0  20 50 100 200 300 400 750 1000 2000 5000]; %% This structure is related with
dlev       = [0 diff(layerdepth)]
sum(dlev)
numLayers = get_numLayers('/datasets/work/oa-alantis/work/EA_model/Physics/EAA29_ll_v2.bgm', dlev)

numLayers
nc=netcdf('JFRE_2000temp_Bec.nc')

ncdump(nc)