#!/bin/bash

module load fsl

# Set the output directory
output_dir="/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/processed"

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Process files matching the first pattern
find /blue/jjtanner/shared/proact/dcm2bids/derivatives/asl -type f -name "meanCBF_0_sub-*_GMWM2ASL_mcf_brain.nii" | while read file; do
    # Extract the directory path
    dirpath=$(dirname "$file")

    # Find the ses-* directory in the path
    parent_ses_dir=$(echo "$dirpath" | tr '/' '\n' | grep '^ses-' | tail -n 1)

    # Construct the output filename by appending _thr-130 before the .nii extension
    base_name="$(basename "${file%.nii}_thr-130_${parent_ses_dir}.nii")"
    output_file="$output_dir/$base_name"

    # Run fslmaths command
    fslmaths "$file" -thr -85 -uthr 130 "$output_file"

    echo "Processed: $file -> $output_file"
done

# Process files matching the second pattern
find /blue/jjtanner/shared/proact/dcm2bids/derivatives/asl -type f -name "meanCBF_0_sub-*_GMWM2ASL_mcf_brain_resliced.nii" | while read file; do
    # Extract the directory path
    dirpath=$(dirname "$file")

    # Find the ses-* directory in the path
    parent_ses_dir=$(echo "$dirpath" | tr '/' '\n' | grep '^ses-' | tail -n 1)

    # Remove _resliced from the filename
    no_resliced="${file/_resliced/}"

    # Construct the output filename by appending _thr-130 before the .nii extension
    base_name="$(basename "${no_resliced%.nii}_thr-130_${parent_ses_dir}.nii")"
    output_file="$output_dir/$base_name"

    # Run fslmaths command
    fslmaths "$file" -thr -85 -uthr 130 "$output_file"

    echo "Processed: $file -> $output_file"
done