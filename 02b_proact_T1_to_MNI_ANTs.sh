#!/bin/bash
#SBATCH --job-name=proact_T1toMNI    # Job name
#SBATCH --mail-type=END,FAIL          # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=jjtanner@ufl.edu     # Where to send mail	
#SBATCH --ntasks=2                    # Run on a single CPU
#SBATCH --mem=8gb                     # Job memory request
#SBATCH --time=96:00:00               # Time limit hrs:min:sec
#SBATCH --output=proact_T1toMNI_%j.log   # Standard output and error log

pwd; hostname; date

module load ants

# Define the template (fixed) image
fixed_image="/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/processed/mniTemplate/tpl-MNI152NLin2009cAsym_res-01_T1w.nii.gz"

# Define the base directory containing the subject images
base_dir="/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl"

# Find all T1.nii.gz images matching the specified pattern
find "$base_dir" -type f -name "T1.nii.gz" | while read -r moving_image; do
  # Extract subject, session, and task identifiers from the file path
  if [[ $moving_image =~ /ses-([^/]+)_task-([^/]+)_run-[^/]+/sub-([^/]+)/anat/T1\.nii\.gz$ ]]; then
    ses_id=${BASH_REMATCH[1]}
    task_id=${BASH_REMATCH[2]}
    sub_id=${BASH_REMATCH[3]}

    # Define the output prefix incorporating the identifiers
    output_prefix="${base_dir}/registration_outputs/${sub_id}_${ses_id}_${task_id}_"

    # Create the output directory if it doesn't exist
    mkdir -p "$(dirname "$output_prefix")"

    # Execute the antsRegistrationSyN.sh script
    antsRegistrationSyN.sh \
      -d 3 \
      -f "$fixed_image" \
      -m "$moving_image" \
      -o "$output_prefix"

    echo "Registration completed for ${moving_image}"
  else
    echo "Failed to extract identifiers from ${moving_image}"
  fi
done

date
