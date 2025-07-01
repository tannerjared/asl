#!/bin/bash
#SBATCH --job-name=asl_merge     # Job name
#SBATCH --mail-type=END,FAIL         # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=jjtanner@ufl.edu # Where to send mail
#SBATCH --ntasks=1                   # Run on 1 CPU core
#SBATCH --mem=72gb                    # Job memory request
#SBATCH --time=2:00:00              # Time limit hrs:min:sec
#SBATCH --output=asl_merge_%j.log # Standard output/error log
#SBATCH --account=jjtanner
#SBATCH --qos=jjtanner-b

date;hostname;pwd

module load fsl

# Directory containing the NIfTI files
input_dir="/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/processed/asl2mniSmAvg"
output_dir="/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/processed/stats"
sub_output_dir="/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/processed/asl2mniSmAvgSub"
sub_out_dir="/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/processed/asl2mniSmAvgSubTaskRest"

# Ensure output directories exist
mkdir -p "$output_dir"
mkdir -p "$sub_output_dir"
mkdir -p "$sub_out_dir"

# Temporary arrays for task-rest and task-pain lists
rest_files=()
pain_files=()
valid_subjects=()

# Read files from the input directory and categorize them
for file in "$input_dir"/*.nii.gz; do
    if [[ "$file" == *"task-rest"* ]]; then
        rest_files+=("$file")
    elif [[ "$file" == *"task-pain"* ]]; then
        pain_files+=("$file")
    fi
done

# Find valid subjects who have both task-rest and task-pain files
for rest in "${rest_files[@]}"; do
    sub_id=$(echo "$rest" | grep -oP "sub-\d+")
    for pain in "${pain_files[@]}"; do
        if [[ "$pain" == *"$sub_id"* ]]; then
            valid_subjects+=("$sub_id")
            break
        fi
    done
done

# Remove duplicates from valid_subjects
valid_subjects=($(echo "${valid_subjects[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

# Create lists of valid files for task-rest and task-pain
valid_rest_files=()
valid_pain_files=()

for sub_id in "${valid_subjects[@]}"; do
    for rest in "${rest_files[@]}"; do
        if [[ "$rest" == *"$sub_id"* ]]; then
            valid_rest_files+=("$rest")
        fi
    done
    for pain in "${pain_files[@]}"; do
        if [[ "$pain" == *"$sub_id"* ]]; then
            valid_pain_files+=("$pain")
        fi
    done
done

# Merge valid files for task-rest and task-pain
#fslmerge -t "$output_dir/all_ses-pre_task-rest.nii.gz" "${valid_rest_files[@]}"
#fslmerge -t "$output_dir/all_ses-pre_task-pain.nii.gz" "${valid_pain_files[@]}"
#fslmerge -t "$output_dir/all_ses-pre_task-rest-pain.nii.gz" "${valid_rest_files[@]}" "${valid_pain_files[@]}"
#fslmaths "$output_dir/all_ses-pre_task-rest-pain.nii.gz" -mas "$output_dir/tpl-MNI152NLin2009cAsym_res-01_desc-brain_T1w_mask.nii.gz" "$output_dir/all_ses-pre_task-rest-pain_masked.nii.gz"

# Perform subtraction (task-pain - task-rest) for each subject
subtraction_files=()
for ((i = 0; i < ${#valid_subjects[@]}; i++)); do
    sub_id="${valid_subjects[$i]}"
    rest_file="${valid_rest_files[$i]}"
    pain_file="${valid_pain_files[$i]}"
    output_file="$sub_output_dir/${sub_id}_task-pain-minus-task-rest.nii.gz"

    if [[ -f "$rest_file" && -f "$pain_file" ]]; then
        fslmaths "$pain_file" -sub "$rest_file" "$output_file"
        subtraction_files+=("$output_file")
    else
        echo "Missing files for subject $sub_id. Skipping subtraction."
    fi
done

# Perform subtraction (task-rest - task-pain) for each subject
subtraction_files_restpain=()
for ((i = 0; i < ${#valid_subjects[@]}; i++)); do
    sub_id="${valid_subjects[$i]}"
    rest_file="${valid_rest_files[$i]}"
    pain_file="${valid_pain_files[$i]}"
    output_file="$sub_out_dir/${sub_id}_task-rest-minus-task-pain.nii.gz"

    if [[ -f "$rest_file" && -f "$pain_file" ]]; then
        fslmaths "$rest_file" -sub "$pain_file" "$output_file"
        subtraction_files+=("$output_file")
    else
        echo "Missing files for subject $sub_id. Skipping subtraction."
    fi
done

# Merge all pain - rest subtraction files into one
fslmerge -t "$output_dir/all_ses-pre_task-pain-rest_sub.nii.gz" "${subtraction_files[@]}"

fslmaths "$output_dir/all_ses-pre_task-pain-rest_sub.nii.gz" -mas "$output_dir/tpl-MNI152NLin2009cAsym_res-01_desc-brain_T1w_mask.nii.gz" "$output_dir/all_ses-pre_task-pain-rest_sub_masked.nii.gz"

# Merge all rest - pain subtraction files into one
fslmerge -t "$output_dir/all_ses-pre_task-rest-pain_sub.nii.gz" "${subtraction_files_restpain[@]}"

fslmaths "$output_dir/all_ses-pre_task-rest-pain_sub.nii.gz" -mas "$output_dir/tpl-MNI152NLin2009cAsym_res-01_desc-brain_T1w_mask.nii.gz" "$output_dir/all_ses-pre_task-rest-pain_sub_masked.nii.gz"

# Save the list of merged files to a text file
merged_files_list="$output_dir/merged_files_list.txt"
{
    echo "Merged Task-Rest Files:"
    printf "%s\n" "${valid_rest_files[@]}"
    echo ""
    echo "Merged Task-Pain Files:"
    printf "%s\n" "${valid_pain_files[@]}"
    echo ""
    echo "Pain - Rest Subtraction Files:"
    printf "%s\n" "${subtraction_files[@]}"
    echo ""
    echo "Rest - Pain Subtraction Files:"
    printf "%s\n" "${subtraction_files_restpain[@]}"
} > "$merged_files_list"

# Save the count of valid subjects to a separate text file
valid_subject_count="$output_dir/valid_subject_count.txt"
echo "${#valid_subjects[@]}" > "$valid_subject_count"

echo "Merging and subtraction complete for ${#valid_subjects[@]} valid subjects."
echo "File list saved to $merged_files_list"
echo "Count saved to $valid_subject_count"

date