#!/usr/bin/env python3
import os
import re
import glob
import nibabel as nib
import numpy as np
import pandas as pd

def extract_subject_info(filename):
    """
    Extract subject, session, task, and run info from the filename.
    """
    sub_match = re.search(r"(sub-[0-9]+)", filename)
    ses_match = re.search(r"(ses-[^_]+)", filename)
    task_match = re.search(r"(task-[^_]+)", filename)
    run_match = re.search(r"(run-[0-9]+)", filename)
    return {
        'sub': sub_match.group(1) if sub_match else '',
        'ses': ses_match.group(1) if ses_match else '',
        'task': task_match.group(1) if task_match else '',
        'run': run_match.group(1) if run_match else ''
    }

# Directories and file paths.
asl_dir = "/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/processed/asl2mniSmoothed_flipped"
stats_dir = "/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/processed/stats"
output_csv = "asl_activation_deactivation_cluster_statistics.csv"

# Define the two cluster (mask) file paths.
mask1_path = os.path.join(stats_dir, "ses-pre_task-pain-rest_sub_flipped_tstat1_clusters.nii.gz")
mask2_path = os.path.join(stats_dir, "ses-pre_task-rest-pain_sub_flipped_tstat1_clusters.nii.gz")

# Load each mask and binarize it (>0).
mask1_img = nib.load(mask1_path)
mask1_data = mask1_img.get_fdata() > 0  # Binarize: True for voxels > 0
mask2_img = nib.load(mask2_path)
mask2_data = mask2_img.get_fdata() > 0  # Binarize: True for voxels > 0

# Get the voxel counts for each mask (assumed constant across subjects)
voxels_mask1 = int(np.sum(mask1_data))
voxels_mask2 = int(np.sum(mask2_data))

# List all ASL files. Here we assume the files have '9FWHM' in their names.
asl_files = glob.glob(os.path.join(asl_dir, "*9FWHM.nii.gz"))

results = []

for asl_file in asl_files:
    print(f"Processing ASL file: {asl_file}")
    filename = os.path.basename(asl_file)
    subj_info = extract_subject_info(filename)
    
    # Load ASL image.
    asl_img = nib.load(asl_file)
    asl_data = asl_img.get_fdata()
    
    # Compute statistics for mask1 (pain-rest).
    masked_values1 = asl_data[mask1_data]
    mean1 = float(np.mean(masked_values1)) if masked_values1.size > 0 else float('nan')
    std1  = float(np.std(masked_values1)) if masked_values1.size > 0 else float('nan')
    
    # Compute statistics for mask2 (rest-pain).
    masked_values2 = asl_data[mask2_data]
    mean2 = float(np.mean(masked_values2)) if masked_values2.size > 0 else float('nan')
    std2  = float(np.std(masked_values2)) if masked_values2.size > 0 else float('nan')
    
    # Create a row dictionary with separate columns for each mask.
    row = {
        "File": filename,
        "Subject": subj_info.get('sub', ''),
        "Session": subj_info.get('ses', ''),
        "Task": subj_info.get('task', ''),
        "Run": subj_info.get('run', ''),
        "Mean_pain_rest": mean1,
        "Std_pain_rest": std1,
        "Voxels_pain_rest": voxels_mask1,
        "Mean_rest_pain": mean2,
        "Std_rest_pain": std2,
        "Voxels_rest_pain": voxels_mask2
    }
    results.append(row)

# Create a pandas DataFrame from the results and save as CSV.
df = pd.DataFrame(results)
df.to_csv(output_csv, index=False)
print(f"Results saved to {output_csv}")