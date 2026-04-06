import nibabel as nib
import numpy as np
import os
import shutil
import fnmatch

# List of subject IDs for which the flip should be applied
subject_ids = [
    1005, 1006, 1007, 1012, 1021, 1026, 1034, 1037, 1043, 1050, 1054, 1059, 1069, 1074, 1075, 1086, 1093, 1095, 1107,
    1109, 1110, 1113, 1124, 1128, 1129, 1136, 1140, 1142, 1166, 1171, 1182, 1192, 1196, 1214, 1229, 1239, 1242, 1247,
    1250, 1251, 1256, 1283, 1293, 1299, 1310, 1313, 1316, 1318, 1325, 1331, 1334, 1342, 1346, 1347, 1349, 1355, 1357,
    1362, 1365, 1378, 1411, 1412, 2001, 2002, 2005, 2009, 2010, 2011, 2012, 2027, 2033, 2035, 2039, 2041, 2050, 2054,
    2056, 2073, 2081, 2088, 2092, 2094, 2097, 2109, 2112, 2113, 2116, 2121, 2123, 2124, 2136, 2138, 2142, 2143, 2151,
    2167, 2183, 2184, 2188, 2192, 2199, 2200, 2201, 2202, 2213, 2220, 2221, 2231, 2234, 2244, 2258, 2261, 2266, 2268,
    2273, 2285, 2289, 2307, 2337, 2344, 2346, 2353, 2356, 2358, 2363, 2366, 2380, 2387, 2401, 2402, 2405, 2410, 2438,
    2452, 2473, 2493
]

# Input and output directories
input_dir = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/processed/asl2mniSmoothed'
output_dir = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/processed/asl2mniSmoothed_flipped'

# Ensure the output directory exists
os.makedirs(output_dir, exist_ok=True)

# Function to flip the image data along the x-axis
def flip_image_left_right(img):
    data = img.get_fdata()
    flipped_data = np.flip(data, axis=0)
    flipped_img = nib.Nifti1Image(flipped_data, img.affine, img.header)
    return flipped_img

# Create a list of filename patterns to be flipped
flip_patterns = [f'meanCBF_0_sub-{subj_id}_GMWM2ASL_*_9FWHM.nii.gz' for subj_id in subject_ids]

# Iterate over all items in the input directory
for filename in os.listdir(input_dir):
    input_filepath = os.path.join(input_dir, filename)
    
    # Skip directories
    if os.path.isdir(input_filepath):
        print(f"Skipping directory: {filename}")
        continue

    output_filepath = os.path.join(output_dir, filename)
    
    # Check if the filename matches any of the flip patterns
    if any(fnmatch.fnmatch(filename, pattern) for pattern in flip_patterns):
        # Load the NIfTI file
        img = nib.load(input_filepath)
        
        # Flip the image left-right
        flipped_img = flip_image_left_right(img)
        
        # Save the flipped image to the output directory
        nib.save(flipped_img, output_filepath)
        print(f'Flipped image saved for {filename}')
    else:
        # Copy the file to the output directory
        shutil.copy2(input_filepath, output_filepath)
        print(f'Copied {filename} to output directory')