# -*- coding: utf-8 -*-
"""
Luke Hammond

Care processing batch script

19 December 2023

"""

import os
import numpy as np
from tifffile import imread, imwrite
from csbdeep.models import CARE
from skimage.util import view_as_blocks
import contextlib
import sys

#c1_model_path = 'D:/Project_Data/Care3D Models/20x 2z 04xy SC AutoF Care3D/'
#c2_model_path = 'D:/Project_Data/Care3D Models/20x 2z 04xy SC TexaRed Care3D/'
#c3_model_path = 'D:/Project_Data/Care3D Models/20x 2z 04xy SC TexaRed Care3D/'


c1_model_path = 'D:/Project_Data/Care3D Models/20x 0_7z 04xy SC AutoF/'
c2_model_path = 'D:/Project_Data/Care3D Models/20x 0_7z 04xy SC TexaRed/'
c3_model_path = 'D:/Project_Data/Care3D Models/20x 0_7z 04xy SC TexaRed/'

models = (c1_model_path, c2_model_path, c3_model_path)



#input_folder = 'D:\Project_Data\Segal_SC_Regen_2023\Yan Data 2\TIF'

folders = ['D:/Project_Data/Segal_SC_Regen_2023/Yan Data 10x 2/TIF']
           #'D:/Project_Data/Segal_SC_Regen_2023/Yan_Raw_Data_ND2_2023_12/10x/TIF',
           #'D:/Project_Data/Segal_SC_Regen_2023/Yan_Raw_Data_ND2_2023_12/20x/TIF']



# Define required substrings in filenames
#filename_inclusions = ['680', 'TexasRed']

patch_size = (64, 512, 512) # Faster to use fewer Z tiles and more XY tiles 2 x 4 x4 faster than 3 x 4 x 

care_underflow = True
underflow = 64000 # in tiles of low intensity low values can wrap into high values - this will set these values to zero

oversaturation_correction = False
cutoff = 60000 # if images contain excessive oversaturation this can create issues with care - this will fill these areas with max values

#metadata for imwrite
Zres =2
XYres = 0.43

#Crosstalk correction
c2_crosstalk = 0.6
c3_crosstalk = 0.2

@contextlib.contextmanager
def suppress_stdout():
    with open(os.devnull, 'w') as devnull:
        old_stdout = sys.stdout
        sys.stdout = devnull
        try:  
            yield
        finally:
            sys.stdout = old_stdout


for input_folder in folders:

    
    foldername = ('Restored_'+str(c2_crosstalk)+'_'+str(c3_crosstalk)).replace(".", "")
    output_folder = os.path.join(input_folder, foldername)
    # Create output folder if it doesn't exist
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
        os.makedirs(output_folder+"/Restored")
        os.makedirs(output_folder+"/Restored_MIPs")
        os.makedirs(output_folder+"/Unmixed")
        os.makedirs(output_folder+"/Unmixed_MIPs")
    
    # Process files that include all specified substrings and end with '.tif'
    for filename in os.listdir(input_folder):
        #if any(substr in filename for substr in filename_inclusions) and filename.endswith('.tif'):
        if filename.endswith('.tif'):
            print(f"Processing file {filename}")
           
            file_path = os.path.join(input_folder, filename)
            full_image = imread(file_path)
            
            processed_array = np.empty_like(full_image)
            for channel in range(full_image.shape[1]):
                #ZCYX
                print(f" Processing channel {channel}")
                image = full_image[:,channel,:,:]
                
                with suppress_stdout():
                    model = CARE(config=None, name=models[channel])
                print(f" Using model {models[channel]}")
            
                if oversaturation_correction == True:
                    oversaturated_pixels = np.sum(image > cutoff)
                    print(f" Number of oversaturated pixels = {oversaturated_pixels}")
                    mask = image > cutoff
                    mask =  mask * 65535
                    mask = mask.astype(np.uint32)
                    
                
                print(f"Image shape {image.shape}")
                print(" Padding...")
                
                # Calculate padding needed to make the image divisible by the patch size
                pad_widths = [(0, desired - current % desired) if current % desired != 0 else (0, 0) 
                              for current, desired in zip(image.shape, patch_size)]
                padded_image = np.pad(image, pad_widths, mode='symmetric')
                
                print(" Patching...")
                # Extract patches
                patches = view_as_blocks(padded_image, patch_size)
                restored_patches = np.zeros_like(patches)
                
                # Process each patch
                print(" Restoring...")
                total_patches = patches.shape[0] * patches.shape[1] * patches.shape[2]
                patch_count = 0
                for i in range(patches.shape[0]):
                    for j in range(patches.shape[1]):
                        for k in range(patches.shape[2]):
                            patch = patches[i, j, k]
                            patch_count += 1
                            print(" " * 50, end='\r')  # Clear the line
                            print(f" Processing patch {patch_count} of {total_patches}", end='\r', flush=True)
                            with suppress_stdout():
                                restored_patch = model.predict(patch, axes='ZYX')
                            restored_patches[i, j, k] = restored_patch
                            
                
                print(" Reassembling and unpadding") 
                # Reassemble the processed patches
                restored_image = np.block([[[restored_patches[i, j, k] 
                                             for k in range(restored_patches.shape[2])]
                                            for j in range(restored_patches.shape[1])]
                                           for i in range(restored_patches.shape[0])])
        
                # Calculate the original image size before padding
                original_size = [length - pad_width[0] - pad_width[1] for length, pad_width in zip(padded_image.shape, pad_widths)]
                # Unpad the image to get back to the original size
                unpadded_restored_image = restored_image[:original_size[0], :original_size[1], :original_size[2]]
        
                
                if oversaturation_correction == True:
                    unpadded_restored_image = unpadded_restored_image + mask
                    unpadded_restored_image = np.clip(unpadded_restored_image, 0, 65535).astype(np.uint16)
                    
                if care_underflow == True:
                    unpadded_restored_image[unpadded_restored_image > underflow] = 0
                    
                processed_array[:, channel, :, :] = unpadded_restored_image
            
            save_path = os.path.join(output_folder+"/Restored/", filename)          
            imwrite(save_path, processed_array, 
                    metadata={'spacing': 2,  # Z spacing
                              'unit': 'um',
                              'axes': 'ZCYX'}, 
                    photometric='minisblack', imagej=True)
            
            mip = np.max(processed_array, axis=0)
            save_path = os.path.join(output_folder+"/Restored_MIPs/", filename)          
            imwrite(save_path, mip, 
                    metadata={'spacing': 2,  # Z spacing
                                'unit': 'um',
                                'axes': 'CYX'}, 
                    photometric='minisblack', imagej=True)
            
            
            print(" Subtracting background...") 
            clean_array = np.empty_like(full_image)
            clean_array[:, 0, :, :] = processed_array[:, 0, :, :]
    
            cleaned_image = processed_array[:, 1, :, :].astype(np.int16) - processed_array[:, 0, :, :].astype(np.int16)*c2_crosstalk
            cleaned_image[cleaned_image < 0] = 0
            clean_array[:, 1, :, :] = cleaned_image.astype(np.uint16)
           
            cleaned_image = processed_array[:, 2, :, :].astype(np.int16) - processed_array[:, 0, :, :].astype(np.int16)*c3_crosstalk       
            cleaned_image[cleaned_image < 0] = 0
            clean_array[:, 2, :, :] = cleaned_image.astype(np.uint16)
            
            save_path = os.path.join(output_folder+"/Unmixed/", filename)  
            imwrite(save_path, clean_array, 
                    metadata={'spacing': 2,  # Z spacing
                              'unit': 'um',
                              'axes': 'ZCYX'}, 
                    photometric='minisblack', imagej=True)
            
            mip = np.max(clean_array, axis=0)
            
            save_path = os.path.join(output_folder+"/Unmixed_MIPs/", filename)  
            imwrite(save_path, mip, 
                    metadata={'spacing': 2,  # Z spacing
                                'unit': 'um',
                                'axes': 'CYX'}, 
                    photometric='minisblack', imagej=True)
            
            
            
            print(" Complete.")
            

