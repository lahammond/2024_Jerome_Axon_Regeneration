# 2024_Jerome_Axon_Regeneration
Python scripts and ImageJ macros used for quantifying axon regeneration in the spinal cord in  <b>Jerome et al. "Cytokine polarized, alternatively activated bone marrow neutrophils drive axon regeneration." 2024.</b> 

Briefly, spinal cords were imaged in µ-Slide 4 well glass bottom chambered coverslips (Ibidi) using a Nikon AXR confocal microscope equipped with a 10x 0.45 N.A. air objective lens. Image volumes were captured using resonant scanning with 16x averaging with a scan area of 2048x2048 pixels, resulting in a voxel size of 0.863 µm in xy-dimensions and a z-step size of 2.2 µm. Autofluorescence and dextran labeling were excited sequentially using 488 nm, 561 nm, and 640 nm laser lines. Image volumes were denoised and restored using 3D content-aware image restoration networks(Weigert 2018) trained using high and low signal-to-noise image pairs. Following noise reduction, 3D pixel classification (Ilastik) (Berg 2019) was employed using information from all three channels to further isolate axonal processes followed by volumetric measurements as a function of distance along the spinal cord using custom scripts in Python and Fiji (Schindelin 2012). 

The restoration Python script included here restores each channel and creates a restored image volume (for analysis) and an unmixed image volume (for visualization purposes). Subsequently, restored images can be batch-processed in Ilastik using a 3D pixel classifier to identify axon-positive voxels using dextran and autofluorescence channels as input. Finally, the ImageJ macro can be used to process the Ilastik outputs, in conjunction with manually annotated lesion sites, to measure the total volume of axon-positive voxels with respect to their distance to the lesion site.

<b>References:</b>

Schindelin, Johannes, Ignacio Arganda-Carreras, Erwin Frise, Verena Kaynig, Mark Longair, Tobias Pietzsch, Stephan Preibisch, et al. “Fiji: An Open-Source Platform for Biological-Image Analysis.” Nature Methods 9, no. 7 (July 2012): 676–82. https://doi.org/10.1038/nmeth.2019.

Berg, Stuart, Dominik Kutra, Thorben Kroeger, Christoph N. Straehle, Bernhard X. Kausler, Carsten Haubold, Martin Schiegg, et al. “Ilastik: Interactive Machine Learning for (Bio)Image Analysis.” Nature Methods 16, no. 12 (December 2019): 1226–32. https://doi.org/10.1038/s41592-019-0582-9.

Weigert, Martin, Uwe Schmidt, Tobias Boothe, Andreas Müller, Alexandr Dibrov, Akanksha Jain, Benjamin Wilhelm, et al. “Content-Aware Image Restoration: Pushing the Limits of Fluorescence Microscopy.” Nature Methods 15, no. 12 (December 2018): 1090–97. https://doi.org/10.1038/s41592-018-0216-7.


