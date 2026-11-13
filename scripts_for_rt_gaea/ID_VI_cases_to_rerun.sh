#!/bin/bash

shopt -s nullglob

rundir=${HOME}/NGGPS/VI/VI_scripts/scripts_for_rt_gaea
tcvit_dir=${rundir}/tc_vitals/SHiELD/processed
log_file=/gpfs/f5/gfdl_w/scratch/${USER}/NGGPS/SHiELD_rt2024/VIck_C1536.RT2024b_wVI_runs_FIXED.log
count_file=${rundir}/nTCs_wVI.txt

# Clear/initialize the count file
> "$count_file"

echo "Checking for discrepancies in $log_file against subfolders in $tcvit_dir..."

# Read CSV columns: col1=dt, col2=y1, col3=old_count, col4=y2
while IFS=, read -r dt y1 old_count y2 || [[ -n "$dt" ]]; do
  # Skip blank lines or header lines
  [[ -z "$dt" || "$dt" =~ [a-zA-Z]{4,} ]] && continue

  # Clean carriage returns and spaces from old_count
  old_count="${old_count//$'\r'/}"
  old_count="${old_count// /}"

  # Strip '.' and 'Z' to get directory format (e.g. 2024080206)
  d="${dt//[.Z$'\r']/}"

  # Count matching subdirectories
  folders=("${tcvit_dir}/${d}"/???_tile?/)
  actual_count=${#folders[@]}

  # 1. Append actual count to the count file
  echo "$actual_count" >> "$count_file"

  # 2. Compare old count vs actual directory count
  if (( old_count != actual_count )); then
    echo "$dt"
    # To inspect while debugging, uncomment the line below:
    # echo "$dt | Old: $old_count != Found: $actual_count"
  fi
done < "$log_file" | sort
