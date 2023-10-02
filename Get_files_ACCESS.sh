# Path: Get_files_ACCESS.sh
#!/bin/bash
conda activate GBR_env
cd /temporal_raw/
year=1998
folder=163
for month in {0..11};do
    if (($month % 3 == 0)); then
        folder=$((folder + 1))
        echo $folder
    fi
    if (($month % 12 == 0)); then
        year=$((year + 1))
        echo $year
    fi
    filemonth=$((month + 1))
    if (($filemonth < 10)); then
        filemonth=0$filemonth
    fi
    url_u="https://dapds00.nci.org.au/thredds/dodsC/cj50/access-om2/raw-output/access-om2-01/01deg_jra55v140_iaf/output${folder}/ocean/ocean-3d-u-1-daily-mean-ym_${year}_${filemonth}.nc"
    echo $url_u
    python get_section.py "$url_u" "u"
    url_v="https://dapds00.nci.org.au/thredds/dodsC/cj50/access-om2/raw-output/access-om2-01/01deg_jra55v140_iaf/output${folder}/ocean/ocean-3d-v-1-daily-mean-ym_${year}_${filemonth}.nc"
    python get_section.py "$url_v" "v"
done
