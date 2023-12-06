#!/bin/bash
#!/bin/bash
#SBATCH --account=OD-232538
#SBATCH --time=1-00:00
#SBATCH --mem=50g
#SBATCH --cpus-per-task=2
#SBATCH --job-name='sampling files'
#SBATCH --array=0-11

module load python
files=(
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-u-1-daily-mean-ym_1999_01.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-u-1-daily-mean-ym_1999_02.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-u-1-daily-mean-ym_1999_03.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-u-1-daily-mean-ym_1999_04.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-u-1-daily-mean-ym_1999_05.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-u-1-daily-mean-ym_1999_06.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-u-1-daily-mean-ym_1999_07.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-u-1-daily-mean-ym_1999_08.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-u-1-daily-mean-ym_1999_09.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-u-1-daily-mean-ym_1999_10.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-u-1-daily-mean-ym_1999_11.nc"
"/datasets/work/oa-alantis/work/Hydro_EAA/ocean-3d-u-1-daily-mean-ym_1999_12.nc"
)

(( task_id = SLURM_ARRAY_TASK_ID ))

python sample_netcdf.py ${files[task_id]} 'u'

