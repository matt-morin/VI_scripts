#!/bin/bash
# ./inspect_vilog.sh | awk '{ print $NF,$0 }' | sort -k1,1 -n | cut -f2- -d' '

#set -x

index_min=1    #18 12 28 40
index_max=1000 #12 30 35 60 1000

cd /gpfs/f5/gfdl_w/proj-shared/Matthew.Morin/SHiELD_INPUT_DATA/global.v202311/C1536 || exit 1

#for DATE in 20240629.18Z 20240701.12Z 20240817.00Z 20240817.06Z 20240827.06Z 20240927.06Z 20241004.12Z 20241004.18Z 20241009.12Z 20241009.18Z 20241010.00Z
#do

  for vilog in 2025????.??Z_IC/submit_vi_SHiELD.out #*FIX2*.out #*vi*.out
  #for vilog in ${DATE}_IC/submit_vi_SHiELD.out #*FIX2*.out #*vi*.out
  do

    # Step 1: Extract vilogstr from the current vilog
    vilogstr=$(grep 'find_good_tc =  True' "$vilog" | awk -F: '{print $1}')

    #echo "vilogstr=${vilogstr}"

    # Only proceed if we found a string
    if [[ -n "$vilogstr" ]]; then
      # Step 2 & 3: Search for vilogstr in this vilog and filter with awk
      grep "${vilogstr}" ${vilog} /dev/null | grep 'min(de.,dw.,ds.,dn.)' | awk '{if ($NF>='${index_min}' && $NF<'${index_max}') print $0}'
    fi

  done # End of vilog loop

#done # End of DATE loop
