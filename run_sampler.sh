#!/bin/bash
module load python

# read files inside the folder input using bash. and run the code sample_netcdf.py on each file
for file in input/ocean-3d-u-1-daily-mean-ym_*.nc
do
    sbatch -t 05:01:00 -N 1 -m 40G --wrap="python sample_netcdf.py $file"
done

