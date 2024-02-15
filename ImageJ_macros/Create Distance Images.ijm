// Create distance images for 2 channels as a function of injury

// Author: 	Luke Hammond
// Department of Neurology, The Ohio State University
// Date:	December 19, 2023

// Injury ROIs mask be added to ROI manager by drawing on MIPs and pressing T. create regions in order for each volume


// Initialization
requires("1.53c");
run("Options...", "iterations=3 count=1 black edm=Overwrite");
run("Colors...", "foreground=white background=black selection=yellow");
run("Clear Results"); 
run("Close All");

// Parameters
#@ File[] listOfPaths(label="select files or folders", style="both")
//#@ Integer(label="Background Subtraction (rolling ball radius in px, 0 if none):", value = 0, style="spinner") BGSub
//#@ boolean(label="Export MIPs:", description=".") MIPon
//#@ boolean(label="Export Tif images :", description=".") TIFon

start = getTime();
setBatchMode(true);

print("\\Clear");
print("\\Update0:Updating LUTs...");
print("\\Update1: "+listOfPaths.length+" folders selected for processing.");

xyRes= 0.863; //Res
h_steps = 20; // steps
image_height = 2048
bin_size = parseInt(h_steps/xyRes); //binsize
total_bins = parseInt(image_height / bin_size)

c1_thresh = 1;
c2_thresh = 1;


for (FolderNum=0; FolderNum<listOfPaths.length; FolderNum++) {

	input=listOfPaths[FolderNum];
	if (File.exists(input)) {
    	if (File.isDirectory(input) == 0) {
        	print(input + "Is a file, please select only directories containing brain datasets");
        } else {
        	
	        print("\\Update2:  Processing folder "+FolderNum+1+": " + input + " ");
	
	
			//process folder
			input = input +"/";
			files = getFileList(input);	
			files = ImageFilesOnlyArray( files );
			
			
			
			//process files
			
			for(i=0; i<files.length; i++) {	
				print("\\Update3:   Processing Image " + (i+1) +" of " + files.length +".");
				print(i);
				print(files[i]);
				// open image
				open(input + files[i]);
				//run("Bio-Formats", "open=["+input + files[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
				outputname = short_title(files[i]);
				getDimensions(width, height, channels, slices, frames);
				
				//Create Mask for Dist
				newImage("Injury", "8-bit black", width, height, slices);
				
				roiManager("select", i);
				run("Add...", "value=255 stack");
				setThreshold(131, 255);
				setOption("BlackBackground", true);
				run("Convert to Mask", "background=Dark black");
				run("Distance Transform 3D");

				
				//split channels and mask and then distance transform
				selectWindow(files[i]);
				run("Split Channels");
				selectWindow("C1-"+files[i]);
				
				setThreshold(c1_thresh, 255);
				setOption("BlackBackground", true);
				run("Convert to Mask", "background=Dark black");
				run("Subtract...", "value=254 stack");
				imageCalculator("Multiply create stack", "Distance","C1-"+files[i]);
				selectImage("Result of Distance");
				
				// histogram
				
				stackHisto = newArray(total_bins);
				for ( j=1; j<=nSlices; j++ ) {
				    setSlice( j );
				    getHistogram(values, counts, total_bins, 0, image_height);
				    for ( k=0; k<total_bins; k++ )
				       stackHisto[k] += counts[k];
				}
				
				// add new table
				Table.create("Results");
				// set a whole column
				Table.setColumn("Count", stackHisto);
				saveAs("Results", input + "distance_TR_"+files[i] + ".csv");
				run("Clear Results");
				
				save(input + "distance_TR_"+files[i]);
				close();
				close("C1-"+files[i]);
				
				selectWindow("C2-"+files[i]);
				setThreshold(c2_thresh, 255);
				setOption("BlackBackground", true);
				run("Convert to Mask", "background=Dark black");
				run("Subtract...", "value=254 stack");
				imageCalculator("Multiply create stack", "Distance","C2-"+files[i]);
				selectImage("Result of Distance");
				// histogram
				
				stackHisto = newArray(total_bins);
				for ( j=1; j<=nSlices; j++ ) {
				    setSlice( j );
				    getHistogram(values, counts, total_bins, 0, image_height);
				    for ( k=0; k<total_bins; k++ )
				       stackHisto[k] += counts[k];
				}
				
				// add new table
				Table.create("Results");
				// set a whole column
				Table.setColumn("Count", stackHisto);
				saveAs("Results", input + "distance_680_"+files[i] + ".csv");
				run("Clear Results");
				
				
				save(input + "distance_680_"+files[i]);
								
				close("*");
				run("Collect Garbage");
				
			}
        }
	}
}

end = getTime();
time = (end-start)/1000/60;
print("Processing time =", time, "minutes");			


function ImageFilesOnlyArray (arr) {
	//pass array from getFileList through this e.g. NEWARRAY = ImageFilesOnlyArray(NEWARRAY);
	setOption("ExpandableArrays", true);
	f=0;
	files = newArray;
	for (i = 0; i < arr.length; i++) {
		if(endsWith(arr[i], ".tif") || endsWith(arr[i], ".nd2") || endsWith(arr[i], ".LSM") || endsWith(arr[i], ".czi") || endsWith(arr[i], ".jpg") ) {   //if it's a tiff image add it to the new array
			files[f] = arr[i];
			f = f+1;
		}
	}
	arr = files;
	arr = Array.sort(arr);
	return arr;
}

function short_title(imagename){
	nl=lengthOf(imagename);
	nl2=nl-4;
	Sub_Title=substring(imagename,0,nl2);
	Sub_Title = replace(Sub_Title, "(", "_");
	Sub_Title = replace(Sub_Title, ")", "_");
	Sub_Title = replace(Sub_Title, "-", "_");
	Sub_Title = replace(Sub_Title, "+", "_");
	Sub_Title = replace(Sub_Title, " ", "_");
	Sub_Title=Sub_Title+".tif";
	return Sub_Title;
}
