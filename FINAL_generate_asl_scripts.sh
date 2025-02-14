#!/usr/bin/bash

# Arrays of possible session, condition, run
sessions=("ses-pre" "ses-post")
conditions=("task-pain" "task-rest")
runs=("run-01" "run-02" "run-03" "run-04")

for session in "${sessions[@]}"; do
  for condition in "${conditions[@]}"; do
    for run in "${runs[@]}"; do

      # Construct a unique script filename
      script_name="asl_setup_full_${session}_${condition}_${run}.sh"

      echo "Creating script: ${script_name}"

      cat <<EOF > "${script_name}"
#!/bin/bash
#SBATCH --job-name=asl_setup_${session}_${condition}_${run}   # Job name
#SBATCH --mail-type=END,FAIL    # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=jjtanner@ufl.edu  # Where to send mail
#SBATCH --ntasks=1              # Run on a single CPU
#SBATCH --mem=2gb               # Job memory request
#SBATCH --time=72:00:00         # Time limit hrs:min:sec
#SBATCH --output=asl_setup_full_${session}_${condition}_${run}_%j.log  # Std output/error log
#SBATCH --account=jjtanner
#SBATCH --qos=jjtanner-b

pwd; hostname; date

# Load necessary module
module load fsl

# Define the base path for the data
base_path="/blue/jjtanner/shared/proact/dcm2bids"

# Loop over each subject ID from the subjects.txt file
while read -r id; do
  for s in ${session}; do
    for c in ${condition}; do
      for r in ${run}; do

        # Define target directories for performance and anatomy
        target_dir="\${base_path}/derivatives/asl/\${s}_\${c}_\${r}/\${id}"
        mkdir -p "\${target_dir}/perf" "\${target_dir}/anat"

        # ----------------------------------------------------------------------------
        # Copy ASL to perf directory (remain .nii.gz, do NOT decompress)
        # ----------------------------------------------------------------------------
        asl_file="\${base_path}/\${id}/\${s}/perf/\${id}_\${s}_\${c}_\${r}_asl.nii.gz"
        if [ -f "\$asl_file" ]; then
          cp "\$asl_file" "\${target_dir}/perf/ASL.nii.gz"
        else
          echo "ASL file not found for \${id}, \${s}, \${c}, \${r}"
          continue
        fi

        # (Optional) remove an uncompressed copy if found:
        # if [ -f "\${base_path}/\${id}/\${s}/perf/\${id}_\${s}_\${c}_\${r}_asl.nii" ]; then
        #     rm "\${base_path}/\${id}/\${s}/perf/\${id}_\${s}_\${c}_\${r}_asl.nii"
        # fi

        # ----------------------------------------------------------------------------
        # Find T1w (compressed) in fMRIPrep outputs
        # ----------------------------------------------------------------------------
        # 1) Check top-level
        t1_file="\${base_path}/derivatives/fmriprep/\${id}/anat/\${id}_desc-preproc_T1w.nii.gz"

        # 2) If not found, check the current session's anat folder
        if [ ! -f "\$t1_file" ]; then
          t1_file="\${base_path}/derivatives/fmriprep/\${id}/\${s}/anat/\${id}_\${s}_desc-preproc_T1w.nii.gz"
          # 3) If still not found, check the other session
          if [ ! -f "\$t1_file" ]; then
            if [ "\$s" == "ses-pre" ]; then
              other_session="ses-post"
            else
              other_session="ses-pre"
            fi
            t1_file="\${base_path}/derivatives/fmriprep/\${id}/\${other_session}/anat/\${id}_\${other_session}_desc-preproc_T1w.nii.gz"
            # If still not found, skip
            if [ ! -f "\$t1_file" ]; then
              echo "T1 file (\${id}_desc-preproc_T1w.nii.gz) not found for \${id}"
              continue
            fi
          fi
        fi
        cp "\$t1_file" "\${target_dir}/anat/T1.nii.gz"

        # ----------------------------------------------------------------------------
        # Find brain mask
        # ----------------------------------------------------------------------------
        brain_mask_file="\${base_path}/derivatives/fmriprep/\${id}/anat/\${id}_desc-brain_mask.nii.gz"
        if [ ! -f "\$brain_mask_file" ]; then
          brain_mask_file="\${base_path}/derivatives/fmriprep/\${id}/\${s}/anat/\${id}_\${s}_desc-brain_mask.nii.gz"
          if [ ! -f "\$brain_mask_file" ]; then
            if [ "\$s" == "ses-pre" ]; then
              other_session="ses-post"
            else
              other_session="ses-pre"
            fi
            brain_mask_file="\${base_path}/derivatives/fmriprep/\${id}/\${other_session}/anat/\${id}_\${other_session}_desc-brain_mask.nii.gz"
            if [ ! -f "\$brain_mask_file" ]; then
              echo "Brain mask file (\${id}_desc-brain_mask.nii.gz) not found for \${id}"
            else
              cp "\$brain_mask_file" "\${target_dir}/anat/T1_brain_mask.nii.gz"
            fi
          else
            cp "\$brain_mask_file" "\${target_dir}/anat/T1_brain_mask.nii.gz"
          fi
        else
          cp "\$brain_mask_file" "\${target_dir}/anat/T1_brain_mask.nii.gz"
        fi

        # Create T1_brain
        if [ -f "\${target_dir}/anat/T1.nii.gz" ] && [ -f "\${target_dir}/anat/T1_brain_mask.nii.gz" ]; then
          fslmaths \
            "\${target_dir}/anat/T1.nii.gz" \
            -mas "\${target_dir}/anat/T1_brain_mask.nii.gz" \
            "\${target_dir}/anat/T1_brain.nii.gz"
        fi

        # ----------------------------------------------------------------------------
        # Combine GM + WM probability segments -> T1-space GMWM mask
        # ----------------------------------------------------------------------------
        gm_file="\${base_path}/derivatives/fmriprep/\${id}/anat/\${id}_label-GM_probseg.nii.gz"
        wm_file="\${base_path}/derivatives/fmriprep/\${id}/anat/\${id}_label-WM_probseg.nii.gz"

        # Check for GM in current or other session
        if [ ! -f "\$gm_file" ]; then
          gm_file="\${base_path}/derivatives/fmriprep/\${id}/\${s}/anat/\${id}_\${s}_label-GM_probseg.nii.gz"
          if [ ! -f "\$gm_file" ]; then
            if [ "\$s" == "ses-pre" ]; then
              other_session="ses-post"
            else
              other_session="ses-pre"
            fi
            gm_file="\${base_path}/derivatives/fmriprep/\${id}/\${other_session}/anat/\${id}_\${other_session}_label-GM_probseg.nii.gz"
          fi
        fi
        if [ ! -f "\$wm_file" ]; then
          wm_file="\${base_path}/derivatives/fmriprep/\${id}/\${s}/anat/\${id}_\${s}_label-WM_probseg.nii.gz"
          if [ ! -f "\$wm_file" ]; then
            if [ "\$s" == "ses-pre" ]; then
              other_session="ses-post"
            else
              other_session="ses-pre"
            fi
            wm_file="\${base_path}/derivatives/fmriprep/\${id}/\${other_session}/anat/\${id}_\${other_session}_label-WM_probseg.nii.gz"
          fi
        fi

        if [ -f "\$gm_file" ] && [ -f "\$wm_file" ]; then
          fslmaths "\$gm_file" -add "\$wm_file" "\${target_dir}/anat/\${id}_GMWM.nii.gz"
        else
          echo "GM or WM probseg missing for \${id}, skipping."
          continue
        fi

      done
    done
  done
done < "\${base_path}/derivatives/asl/subjects.txt"


# ------------------------------------------------------------------------------
# Perform ASL image processing for ${session}, ${condition}, ${run} (no unzipping)
# ------------------------------------------------------------------------------
for s in ${session}; do
  for c in ${condition}; do
    for r in ${run}; do

      current_dir="${base_path}/derivatives/asl/${s}_${c}_${r}"
      cd "$current_dir" || { echo "Directory not found: $current_dir"; continue; }

      # 1) Motion-correct all ASL.nii or ASL.nii.gz
      find . -type f \( -name 'ASL.nii' -o -name 'ASL.nii.gz' \) -exec mcflirt -in {} \;

      # 2) Gather all ASL_mcf.nii or ASL_mcf.nii.gz into a single list
      find . -type f \( -name 'ASL_mcf.nii' -o -name 'ASL_mcf.nii.gz' \) >> "${base_path}/asl_file_list_${s}_${c}_${r}.txt"

    done
  done
done

# ------------------------------------------------------------------------------
# Final GMWM-based processing
# ------------------------------------------------------------------------------
base_path="/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/${session}_${condition}_${run}"

find "\${base_path}" -type f -name 'sub-*GMWM.nii.gz' | while IFS= read -r file; do

  # Extract subject ID, e.g. sub-0123
  id=\$(basename "\${file}" _GMWM.nii.gz)
  echo "Processing subject: \${id}"

  # a) Brain-extract ASL_mcf.nii.gz -> <id>_ASL_mcf_brain.nii.gz
  bet \
    "\${base_path}/\${id}/perf/ASL_mcf.nii.gz" \
    "\${base_path}/\${id}/perf/\${id}_ASL_mcf_brain.nii.gz" \
    -m -f 0.5

  # b) Compute ASL->T1 transformation
  flirt \
    -in  "\${base_path}/\${id}/perf/\${id}_ASL_mcf_brain.nii.gz" \
    -ref "\${base_path}/\${id}/anat/T1_brain.nii.gz" \
    -dof 6 -cost mutualinfo -interp nearestneighbour \
    -out "\${base_path}/\${id}/perf/\${id}_ASL2T1_mcf_brain.nii.gz" \
    -omat "\${base_path}/\${id}/perf/\${id}_ASL2T1_mcf_brain.mat"

  # c) Invert matrix => T1->ASL
  convert_xfm \
    -inverse \
    -omat "\${base_path}/\${id}/perf/\${id}_T12ASL_mcf_brain.mat" \
    "\${base_path}/\${id}/perf/\${id}_ASL2T1_mcf_brain.mat"

  # d) Apply T1->ASL
  flirt \
    -in  "\${base_path}/\${id}/anat/T1_brain.nii.gz" \
    -ref "\${base_path}/\${id}/perf/ASL_mcf.nii.gz" \
    -applyxfm -init "\${base_path}/\${id}/perf/\${id}_T12ASL_mcf_brain.mat" \
    -out "\${base_path}/\${id}/perf/\${id}_T1_brain_in_ASL.nii.gz"

  # e) Transform GMWM mask T1->ASL
  flirt \
    -in  "\${base_path}/\${id}/anat/\${id}_GMWM.nii.gz" \
    -ref "\${base_path}/\${id}/perf/ASL_mcf.nii.gz" \
    -applyxfm -init "\${base_path}/\${id}/perf/\${id}_T12ASL_mcf_brain.mat" \
    -out "\${base_path}/\${id}/perf/\${id}_GMWM2ASL_mcf.nii.gz"

  # f) Mask ASL_mcf.nii.gz with GMWM2ASL_mcf.nii.gz
  fslmaths \
    "\${base_path}/\${id}/perf/ASL_mcf.nii.gz" \
    -mas "\${base_path}/\${id}/perf/\${id}_GMWM2ASL_mcf.nii.gz" \
    "\${base_path}/\${id}/perf/\${id}_GMWM2ASL_mcf_brain.nii.gz"

done

date
EOF

      # Make the generated script executable
      chmod +x "${script_name}"

    done
  done
done