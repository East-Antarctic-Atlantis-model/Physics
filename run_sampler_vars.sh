#!/bin/bash
#!/bin/bash
#SBATCH --account=OD-232538
#SBATCH --time=1-00:00
#SBATCH --mem=50g
#SBATCH --cpus-per-task=2
#SBATCH --job-name='sampling files'
#SBATCH --array=0-11

module load python
files_salt=(
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-salt-1-daily-mean-ym_1999_01.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-salt-1-daily-mean-ym_1999_02.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-salt-1-daily-mean-ym_1999_03.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-salt-1-daily-mean-ym_1999_04.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-salt-1-daily-mean-ym_1999_05.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-salt-1-daily-mean-ym_1999_06.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-salt-1-daily-mean-ym_1999_07.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-salt-1-daily-mean-ym_1999_08.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-salt-1-daily-mean-ym_1999_09.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-salt-1-daily-mean-ym_1999_10.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-salt-1-daily-mean-ym_1999_11.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-salt-1-daily-mean-ym_1999_12.nc"
)




files_temp=(
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-temp-1-daily-mean-ym_1999_01.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-temp-1-daily-mean-ym_1999_02.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-temp-1-daily-mean-ym_1999_03.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-temp-1-daily-mean-ym_1999_04.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-temp-1-daily-mean-ym_1999_05.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-temp-1-daily-mean-ym_1999_06.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-temp-1-daily-mean-ym_1999_07.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-temp-1-daily-mean-ym_1999_08.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-temp-1-daily-mean-ym_1999_09.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-temp-1-daily-mean-ym_1999_10.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-temp-1-daily-mean-ym_1999_11.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-temp-1-daily-mean-ym_1999_12.nc"
)




files_wt=(
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-wt-1-daily-mean-ym_1999_01.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-wt-1-daily-mean-ym_1999_02.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-wt-1-daily-mean-ym_1999_03.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-wt-1-daily-mean-ym_1999_04.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-wt-1-daily-mean-ym_1999_05.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-wt-1-daily-mean-ym_1999_06.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-wt-1-daily-mean-ym_1999_07.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-wt-1-daily-mean-ym_1999_08.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-wt-1-daily-mean-ym_1999_09.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-wt-1-daily-mean-ym_1999_10.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-wt-1-daily-mean-ym_1999_11.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-wt-1-daily-mean-ym_1999_12.nc"
)

/home/por07g/Documents/Projects/Supervision/Ilaria/tools/Physics/sample_netcdf_variables.py
(( task_id = SLURM_ARRAY_TASK_ID ))
echo "Doing salt"
python sample_netcdf_variables.py ${files_salt[task_id]} 'salt'
echo 'Doing temperature'
python sample_netcdf_variables.py ${files_temp[task_id]} 'temp'
echp "Doing vertical velocity"
python sample_netcdf_variables.py ${files_wt[task_id]} 'wt'


echo "done!"
