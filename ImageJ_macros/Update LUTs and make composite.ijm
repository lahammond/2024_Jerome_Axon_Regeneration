// Update LUTS and autoscale for easy viewing
// Author: 	Luke Hammond
// Department of Neurology, The Ohio State University
// Date:	December 19, 2023

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
				// open image
				open(input + files[i]);
				//run("Bio-Formats", "open=["+input + files[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
				outputname = short_title(files[i]);
				getDimensions(width, height, channels, slices, frames);
				
				Stack.setChannel(1);
				run("Grays");
				run("Enhance Contrast", "saturated=0.1");
				Stack.setChannel(2);
				run("Enhance Contrast", "saturated=0.35");
				run("Green");
				Stack.setChannel(3);
				run("Enhance Contrast", "saturated=0.35");
				run("Magenta");
				run("Make Composite");
				Stack.setActiveChannels("011");
				save(input + files[i]);
				
				
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
