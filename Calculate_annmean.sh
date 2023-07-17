#!/bin/bash

module load nco/5.0.6

# Prompt the user for the variable to process
read -p "Please enter the variable to process: " var

# Infer the domain from the first netCDF file in the directory
domain=$(ls ${var}_* | head -n 1 | cut -d '_' -f 2)

# Adjust the output domain tag based on input domain
if [[ $domain == "Omon" ]]; then
    out_domain="Oann"
elif [[ $domain == "Amon" ]]; then
    out_domain="Aann"
elif [[ $domain == "SImon" ]]; then
    out_domain="SIann"
else
    echo "Unsupported domain detected."
    exit 1
fi

# Get a list of all unique model names and experiment labels based on the file names
# Here, we use awk command to split the file name by underscores and get the model and experiment names
files_info=$(ls ${var}_${domain}_* | awk -F'_' '{print $3, $4}' | sort | uniq)

# Convert the list to an array
info_array=($files_info)

# Prompt the user for the models to process
read -p "Please enter the models to process (or type 'all' to process all models): " input

# If 'all' is entered, process all models; otherwise, process the entered models
if [[ $input == "all" ]]; then
    process_models=("${info_array[@]}")
else
    process_models=($input)
fi

# Loop over each model and experiment
for (( i=0; i<${#process_models[@]}; i+=2 ))
do
    model=${process_models[i]}
    experiment=${process_models[i+1]}
    echo "Processing $model for experiment $experiment"

    # Calculate annual means for each file of this model and experiment
    for file in $(ls ${var}_${domain}_${model}_${experiment}_*)
    do
        echo "Calculating annual mean for $file"
        ncks -O -u --mk_rec_dmn time $file $file # Promote the time dimension to record dimension if it's not
        ncra --mro -O -d time,,,12,12 $file ${file%.nc}_annual_mean.nc # Calculate annual mean
    done

    # Concatenate the annual mean files of this model and experiment
    echo "Concatenating annual mean files for $model and experiment $experiment"
    ncrcat -O ${var}_${domain}_${model}_${experiment}_*_annual_mean.nc ${var}_${out_domain}_${model}_${experiment}.nc

    # Remove the individual annual mean files
    echo "Removing individual annual mean files for $model and experiment $experiment"
    rm ${var}_${domain}_${model}_${experiment}_*_annual_mean.nc

done
