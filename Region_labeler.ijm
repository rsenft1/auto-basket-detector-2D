//originally 20201216_regionROILabeler.ijm
/********************************************
 * Step 1: Get Directory and Initialize
 ********************************************/
run("Close All");
dir= getDirectory("Choose a Directory") //select your folder with images
list=getFileList(dir);
roiDir=dir+"ROIs/";
regionDir=dir+"Regions/";
File.makeDirectory(regionDir);
files=newArray();
saveType="Tiff";
print("\\Clear"); //clears log
run("Clear Results");
roiManager("UseNames", "false"); //unless manually editing ROIs this doesn't help usually.
date=getDate();
print("*******************************************************************************************************************************************");
print("Regional Labeler Date: "+date);
print("Script: 20201216_RegionLabeler_v1");
print("*******************************************************************************************************************************************");
print("Current Directory: "+dir);
/********************************************
 * Step 2: Open Image and Name regions
 ********************************************/
 
for (i=0;i<list.length; i++){
		if ((endsWith(list[i],".czi"))||(endsWith(list[i],".tif"))||(endsWith(list[i],".lsm"))||(endsWith(list[i],".nd2"))||(endsWith(list[i],".tiff"))){
		files=Array.concat(files,list[i]);
		}
	}
for (F=0; F<files.length; F++){
	//setBatchMode(false);
		run("Close All");
		print("File "+(F+1)+" out of "+files.length+": "+files[F]);
		saveName=extStrip(files[F]);
		if (File.exists(roiDir+saveName+"_regionalROIs.zip")==false){
			roiManager("reset");
			roiManager("Show All with labels");
			run("Bio-Formats Windowless Importer", "open=["+dir+files[F]+"]");
			name=File.name; 
			selectWindow(name);
			getDimensions(w, h, channels, sliceCount, dummy);
			run("Channels Tool...");
			run("Brightness/Contrast...");
			if (channels>1){
				run("Make Composite");
				for (channel=1; channel<=channels; channel++){
					Stack.setChannel(channel);
					run("Enhance Contrast", "saturated=0.2");
				}
			}
			setTool("polygon");
			waitForUser("Draw the regions you'd like to name for this image. Hit 't' to add them to the ROI manager.");
			imageRegionNames=getUserInput();
			resizeTwo(name,"Channels");
			for (r=0;r<imageRegionNames.length;r++){
				roiManager("select", r);
				roiManager("rename", imageRegionNames[r])
			}
			roiManager("save", regionDir+saveName+"_regionalROIs.zip");
			//Next, we need to ask what cells fall in what regions.
			
		}
		else{
			print("Regions already found for "+files[F]+". It will be skipped");
		}
}

//FUNCTIONS

function getDate(){
		//This function gets and returns a string of the current date in yearmonthday format.
		getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
		if (dayOfMonth<10) {dayOfMonth = "0"+dayOfMonth;}
		month=month+1;
		if (month<10) {month = "0"+month;}
		return toString(year)+toString(month)+toString(dayOfMonth);
	}
function getUserInput(){
	numRegions=roiManager("count");
	Dialog.create("Name the regions in this image");
	for (region=1; region<=numRegions; region++){
		Dialog.addString("Region "+region+": ", "name");
	}
	Dialog.show()
	regionNames=newArray(numRegions);
	for (region=0; region<numRegions; region++){
		regionNames[region]=Dialog.getString();
	}
	return regionNames;
}
function resizeTwo(win1,win2){
		/*
		 * This function resizes two windows to better fit the screen space available. 
		 * No outputs. Win1 should be image and win2 a text menu
		 * Also moves B&C window
		 */
		getLocationAndSize(x, y, pixelwidth, pixelheight);
		selectWindow(win1); //must be image
		setLocation(20, 20, screenWidth/2, screenHeight);
		selectWindow(win2); //must be menu
		setLocation((screenWidth/2)+10, screenHeight/3);
		selectWindow("B&C");
		setLocation((screenWidth/2)+10, screenHeight/2);
		selectWindow("Channels");
		setLocation((screenWidth/2)+200, screenHeight/2);
	}
function extStrip(str){
	str = replace(str, "\\.tif", "");
	str = replace(str, "\\.tiff", "");
	str = replace(str, "\\.nd2", "");
	str = replace(str, "\\.czi", "");
	str = replace(str, "\\.lsm", "");
	return str;
}
