import nibabel as nib
import numpy as np
from skimage.morphology import skeletonize_3d

def apply_threshold(ct_scan_data, threshold):
    return (ct_scan_data > threshold).astype(np.uint8)

# Define input and output file paths. Replace with actual file paths.
input_file = 'exampleinput.nii'
output_file = 'exampleoutput.nii'

# Use nibabel to load in CT scan and extract data.
ct_scan = nib.load(input_file)
ct_scan_data = ct_scan.get_fdata()

# Ideal threshold chosen through experimentation.
threshold = 800

# Apply threshold to extract relevant data.
thresholded_data = apply_threshold(ct_scan_data, threshold)

# Extract skeleton data and create skeleton image using it.
skel_data = skeletonize_3d(thresholded_data)
skel_image = nib.Nifti1Image(skel_data, ct_scan.affine)

# Save the skeleton image as a NIfTI file.
nib.save(skel_image, output_file)
