import os
import re
import glob
import nibabel as nib
import numpy as np
from scipy.ndimage import label, center_of_mass
import pandas as pd
from nibabel.affines import apply_affine

def process_cluster_file(cluster_filepath):
    """
    Load a cluster-corrected NIfTI image, convert to a binary mask, label individual clusters,
    and compute for each cluster:
      - Cluster number
      - Center-of-mass (in MNI coordinates, using the image affine)
      - Cluster size (number of voxels)
      - Binary mask (as a numpy array)
    Returns a list of dicts.
    """
    img = nib.load(cluster_filepath)
    data = img.get_fdata()
    # Convert to binary: nonzero voxels set to 1.
    binary_data = (data != 0).astype(int)
    # Label clusters (using a 26-connected neighborhood)
    structure = np.ones((3, 3, 3))
    labeled_array, n_clusters = label(binary_data, structure=structure)
    
    clusters = []
    for i in range(1, n_clusters+1):
        cluster_mask = (labeled_array == i)
        size = int(np.sum(cluster_mask))
        # Compute center-of-mass in voxel coordinates and convert to MNI
        com_vox = center_of_mass(cluster_mask)
        com_mni = apply_affine(img.affine, com_vox)
        clusters.append({
            'cluster_num': i,
            'center': com_mni,
            'size': size,
            'mask': cluster_mask
        })
    return clusters

def extract_subject_info(filename):
    """
    Extract subject, session, task, and run info from the filename.
    For example, from:
    meanCBF_0_sub-1001_GMWM2ASL_mcf_brain_thr-130_ses-post_task-pain_run-01_2T1w_2MNI_9FWHM.nii.gz
    it extracts sub-1001, ses-post, task-pain, and run-01.
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

# Define directories.
# For non-flipped, uncomment below and then comment out the other asl_dir
# asl_dir = "/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/processed/asl2mniSmoothed"
asl_dir = "/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/processed/asl2mniSmoothed_flipped"
stats_dir = "/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/processed/stats"

# List the two cluster files.
cluster_files = [
    os.path.join(stats_dir, "ses-pre_task-pain-rest_sub_flipped_tstat1_clusters.nii.gz"),
    os.path.join(stats_dir, "ses-pre_task-rest-pain_sub_flipped_tstat1_clusters.nii.gz")
]

# Process each cluster file into a dictionary mapping a key (derived from the filename)
# to its cluster info.
cluster_info_dict = {}
for cf in cluster_files:
    base = os.path.basename(cf)
    # For example, extract "pain-rest" or "rest-pain" from the filename.
    m = re.search(r"ses-pre_task-([^-]+-[^-]+)_sub_flipped", base)
    key = m.group(1) if m else os.path.splitext(base)[0]
    clusters = process_cluster_file(cf)
    cluster_info_dict[key] = clusters

# List all ASL *9FWHM files.
asl_files = glob.glob(os.path.join(asl_dir, "*9FWHM.nii.gz"))

# Prepare results: each row corresponds to an ASL file.
results = []

for asl_file in asl_files:
    print(f"Processing ASL file: {asl_file}")
    subj_info = extract_subject_info(os.path.basename(asl_file))
    asl_img = nib.load(asl_file)
    asl_data = asl_img.get_fdata()
    
    # Initialize result dictionary with file and subject info.
    row = {
        "File": os.path.basename(asl_file),
        "Subject": subj_info.get('sub', ''),
        "Session": subj_info.get('ses', ''),
        "Task": subj_info.get('task', ''),
        "Run": subj_info.get('run', '')
    }
    
    # For each cluster file (key) and for each cluster within that file,
    # overlay the binary mask on the ASL image and extract mean and std.
    for key, clusters in cluster_info_dict.items():
        # Replace hyphens with underscores for column naming.
        key_prefix = key.replace("-", "_")
        for cluster in clusters:
            clust_num = cluster['cluster_num']
            center = cluster['center']  # already in MNI coordinates
            size = cluster['size']
            mask = cluster['mask']
            masked_values = asl_data[mask]
            mean_val = float(np.mean(masked_values)) if masked_values.size > 0 else float('nan')
            std_val = float(np.std(masked_values)) if masked_values.size > 0 else float('nan')
            # Create column names that incorporate the cluster identifier and MNI coordinates.
            col_prefix = f"{key_prefix}_cluster{clust_num}"
            row[f"{col_prefix}_MNI_x"] = center[0]
            row[f"{col_prefix}_MNI_y"] = center[1]
            row[f"{col_prefix}_MNI_z"] = center[2]
            row[f"{col_prefix}_Size_vox"] = size
            row[f"{col_prefix}_Mean"] = mean_val
            row[f"{col_prefix}_Std"] = std_val
    results.append(row)

# Create a pandas DataFrame from results.
df = pd.DataFrame(results)

# Optionally, sort or reorder columns.
print(df.to_string(index=False))

# Save the output as a CSV file. Uncomment this for non-flipped (also change the asl_dir above)
# output_csv = "asl_cluster_statistics.csv"
# df.to_csv(output_csv, index=False)
# print(f"Results saved to {output_csv}")

# Save the output as a CSV file.
output_csv = "asl_cluster_statistics_flipped.csv"
df.to_csv(output_csv, index=False)
print(f"Results saved to {output_csv}")
