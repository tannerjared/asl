#!/usr/bin/bash

# Path to your base directory
base_dir="/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl"

# Path to the list of subjects
subjects_list="${base_dir}/subjects.txt"

# Define the fixed (template) image
fixed_image="${base_dir}/processed/mniTemplate/tpl-MNI152NLin2009cAsym_res-01_T1w.nii.gz"

# Loop over each subject in subjects.txt
while IFS= read -r sub; do
  # Skip empty lines or lines that don't start with 'sub-'
  [[ -z "$sub" || "$sub" != sub-* ]] && continue
  
  # Name of the script we will create for this subject
  script_name="run_antsRegistrationSyN_${sub}.sh"

  # Write the script contents with a HERE-document
  cat <<EOF > "$script_name"
#!/usr/bin/bash
#SBATCH --job-name="${sub}_T1toMNI"      # Job name
#SBATCH --mail-type=FAIL            # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=jjtanner@ufl.edu    # Where to send mail
#SBATCH --ntasks=1                      # Run on a single CPU
#SBATCH --mem=8gb                       # Job memory request
#SBATCH --time=96:00:00                 # Time limit hrs:min:sec
#SBATCH --output=proact_T1toMNI_%j.log  # Standard output and error log
#SBATCH --account=clp7934               # Account
#SBATCH --qos=clp7934-b                 # QOS

pwd; hostname; date

module load ants

# -------------------------------------------------
# This script runs ANTs registration once for:
#   - The first T1.nii.gz found in any "ses-pre" directory.
#   - The first T1.nii.gz found in any "ses-post" directory.
# for subject: $sub
# -------------------------------------------------

# Fixed (template) image
fixed_image="${fixed_image}"

# Base directory
base_dir="${base_dir}"

# -------------------------------------------------
# 1. Look for the first T1 in ses-pre directories
#    e.g. ses-pre_task-*_run-*/sub-XXXX/anat/T1.nii.gz
# -------------------------------------------------
pre_t1=\$(find \${base_dir}/ses-pre_task-*_run-*/${sub} -type f -name "T1.nii.gz" 2>/dev/null | head -n 1)

if [[ -n "\$pre_t1" ]]; then
  echo "Found T1 for ses-pre: \$pre_t1"
  output_prefix="\${base_dir}/T12MNI/${sub}/${sub}_ses-pre_"
  mkdir -p "\$(dirname "\$output_prefix")"

  echo "Running ANTs registration for $sub ses-pre..."
  antsRegistrationSyN.sh \\
    -d 3 \\
    -f "\$fixed_image" \\
    -m "\$pre_t1" \\
    -o "\$output_prefix"

  echo "Registration completed for $sub ses-pre (\$pre_t1)."
else
  echo "No T1.nii.gz found for $sub in ses-pre directories."
fi

# -------------------------------------------------
# 2. Look for the first T1 in ses-post directories
#    e.g. ses-post_task-*_run-*/sub-XXXX/anat/T1.nii.gz
# -------------------------------------------------
post_t1=\$(find \${base_dir}/ses-post_task-*_run-*/${sub} -type f -name "T1.nii.gz" 2>/dev/null | head -n 1)

if [[ -n "\$post_t1" ]]; then
  echo "Found T1 for ses-post: \$post_t1"
  output_prefix="\${base_dir}/T12MNI/${sub}/${sub}_ses-post_"
  mkdir -p "\$(dirname "\$output_prefix")"

  echo "Running ANTs registration for $sub ses-post..."
  antsRegistrationSyN.sh \\
    -d 3 \\
    -f "\$fixed_image" \\
    -m "\$post_t1" \\
    -o "\$output_prefix"

  echo "Registration completed for $sub ses-post (\$post_t1)."
else
  echo "No T1.nii.gz found for $sub in ses-post directories."
fi

EOF

  # Make the newly created script executable
  chmod +x "$script_name"
  echo "Created script: $script_name"

done < "$subjects_list"