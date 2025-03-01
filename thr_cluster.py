import nibabel as nib
import numpy as np
from scipy.ndimage import gaussian_filter, label
from statsmodels.stats.multitest import fdrcorrection

def process_image(infile, out_prefix, tcrit=3.09, n_permutations=1000, sigma_mm=3.82):
    """
    Process a t-statistic image:
      - Thresholds voxels at t >= tcrit.
      - Labels clusters.
      - Generates a null distribution via n_permutations of smoothed noise (sigma_mm in mm).
      - Computes cluster-level p-values and FDR-corrects them.
      - Writes an output image retaining only clusters surviving FDR correction.
    """
    # Load image and determine voxel size
    img = nib.load(infile)
    data = img.get_fdata()
    voxel_size = img.header.get_zooms()[0]  # in mm
    sigma_vox = sigma_mm / voxel_size  # convert smoothing sigma from mm to voxels
    print(f"Processing {infile}: voxel size = {voxel_size} mm, sigma (voxels) = {sigma_vox:.2f}")

    # Step 1: Voxelwise thresholding
    data_thr = np.where(data >= tcrit, data, 0)
    img_thr = nib.Nifti1Image(data_thr, affine=img.affine, header=img.header)
    nib.save(img_thr, f'{out_prefix}_thr.nii.gz')
    
    # Step 2: Identify clusters in the thresholded image
    structure = np.ones((3, 3, 3))  # 26-connected
    labeled_array, num_clusters = label(data_thr, structure=structure)
    print(f"Found {num_clusters} clusters in {infile}.")
    observed_cluster_sizes = np.array([np.sum(labeled_array == i) for i in range(1, num_clusters+1)])
    print("Observed cluster sizes (voxels):", observed_cluster_sizes)
    
    # Step 3: Build null distribution via permutation testing
    max_cluster_sizes = np.zeros(n_permutations)
    for i in range(n_permutations):
        null_img = np.random.randn(*data.shape)
        # Smooth the noise image with sigma (in voxel units)
        null_img_smooth = gaussian_filter(null_img, sigma=sigma_vox)
        null_thr = np.where(null_img_smooth >= tcrit, null_img_smooth, 0)
        labeled_null, n_clusters_null = label(null_thr, structure=structure)
        if n_clusters_null > 0:
            cluster_sizes_null = np.array([np.sum(labeled_null == j) for j in range(1, n_clusters_null+1)])
            max_cluster_sizes[i] = cluster_sizes_null.max()
        else:
            max_cluster_sizes[i] = 0

    # Step 4: Compute cluster-level p-values (proportion of permutations exceeding observed cluster size)
    p_values = np.array([np.mean(max_cluster_sizes >= size) for size in observed_cluster_sizes])
    print("Raw cluster-level p-values:", p_values)
    
    # Step 5: FDR correction at the cluster level (alpha = 0.05)
    rejected, pvals_corrected = fdrcorrection(p_values, alpha=0.05)
    print("FDR-corrected cluster p-values:", pvals_corrected)
    surviving_clusters = np.where(rejected)[0] + 1
    print("Clusters surviving FDR correction (labels):", surviving_clusters)
    
    # Step 6: Create final output image (retain only clusters passing FDR correction)
    output_mask = np.zeros(data.shape)
    for idx in range(num_clusters):
        if rejected[idx]:
            output_mask[labeled_array == (idx + 1)] = data_thr[labeled_array == (idx + 1)]
    out_img = nib.Nifti1Image(output_mask, affine=img.affine, header=img.header)
    nib.save(out_img, f'{out_prefix}_clusters.nii.gz')

# Process the first image: "ses-pre_task-pain-rest_sub_flipped_tstat1.nii.gz"
process_image('ses-pre_task-pain-rest_sub_flipped_tstat1.nii.gz',
              'ses-pre_task-pain-rest_sub_flipped_tstat1')

# Process the second image: "ses-pre_task-rest-pain_sub_flipped_tstat1.nii.gz"
process_image('ses-pre_task-rest-pain_sub_flipped_tstat1.nii.gz',
              'ses-pre_task-rest-pain_sub_flipped_tstat1')