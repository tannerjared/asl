#!/bin/bash
#SBATCH --job-name=aslAvg    # Job name
#SBATCH --mail-type=END,FAIL          # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=jjtanner@ufl.edu     # Where to send mail	
#SBATCH --ntasks=1                    # Run on a single CPU
#SBATCH --mem=4gb                     # Job memory request
#SBATCH --time=10:00:00               # Time limit hrs:min:sec
#SBATCH --output=aslAvg_%j.log   # Standard output and error log

pwd; hostname; date

module load fsl

# Define input, output, and log directories
input_dir="/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/processed/asl2mniSmoothed"
output_dir="/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/processed/asl2mniSmAvg"
log_dir="/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/processed/logs"
log_file="${log_dir}/averaged_files_log.csv"

# Ensure output and log directories exist
mkdir -p "$output_dir"
mkdir -p "$log_dir"

# Initialize the log file with headers
echo "Subject,Session,Task,Averaged_Files" > "$log_file"

# Get a list of unique subject IDs
subjects=$(ls "$input_dir" | grep -oP 'sub-\d+' | sort -u)

# Loop over each subject
for sub in $subjects; do
    # Define tasks and session
    tasks=("task-rest" "task-pain")
    session="ses-pre"

    # Loop over each task
    for task in "${tasks[@]}"; do
        # Initialize an empty list to hold valid run files
        run_files=()

        # Loop over each run
        for run in {01..04}; do
            # Construct the filename pattern
            file_pattern="meanCBF_*_${sub}_*_${session}_${task}_run-${run}_*.nii.gz"

            # Find the file matching the pattern
            file=$(find "$input_dir" -type f -name "$file_pattern")

            # Check if the file exists
            if [[ -f "$file" ]]; then
                run_files+=("$file")
            fi
        done

        # Check if we have at least one run file
        if [[ ${#run_files[@]} -gt 0 ]]; then
            # Merge the run files into a 4D NIfTI file
            merged_file="${output_dir}/${sub}_${session}_${task}_merged.nii.gz"
            fslmerge -t "$merged_file" "${run_files[@]}"

            # Calculate the mean across the 4D time dimension
            mean_file="${output_dir}/meanCBF_${sub}_ASL_thr-0-160_${session}_${task}_mni_smooth_mean.nii.gz"
            fslmaths "$merged_file" -Tmean "$mean_file"

            # Remove the merged 4D file
            rm "$merged_file"

            # Log the subject, session, task, and averaged files
            echo "${sub},${session},${task},\"${run_files[*]}\"" >> "$log_file"

            echo "Averaged ${#run_files[@]} runs for ${sub} ${session} ${task}."
        else
            echo "No valid runs found for ${sub} ${session} ${task}."
        fi
    done
done

date