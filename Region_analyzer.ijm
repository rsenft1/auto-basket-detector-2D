//originally 20201216_regionAnalyzer
/********************************************
 * Step 1: Get Directory and Initialize
 ********************************************/
run("Close All");
dir= getDirectory("Choose a Directory"); //select your folder with images
date=getDate();
dirSave=dir + date+"_RegionAnalysis/";
File.makeDirectory(dirSave);
list=getFileList(dir);
roiDir=dir+"ROIs/";
regionDir=dir+"Regions/";
File.makeDirectory(dirSave + "CSV_Files/"); 
csvDir=dirSave + "CSV_Files/";
files=newArray();
saveType="Tiff";
print("\\Clear"); //clears log
run("Clear Results");
roiManager("UseNames", "false"); //unless manually editing ROIs this doesn't help usually.
run("Set Measurements...", "area mean min shape integrated median area_fraction limit display redirect=None decimal=6");
print("*******************************************************************************************************************************************");
print("Regional Labeler Date: "+date);
print("Script: 20201216_AssignCellsToRegions_v1");
print("*******************************************************************************************************************************************");
print("Current Directory: "+dir);
print(regionDir);
/********************************************
 * Step 2: Open Image and Name regions
 ********************************************/
setBatchMode(true);
for (i=0;i<list.length; i++){
		if ((endsWith(list[i],".czi"))||(endsWith(list[i],".tif"))||(endsWith(list[i],".lsm"))||(endsWith(list[i],".nd2"))||(endsWith(list[i],".tiff"))){
		files=Array.concat(files,list[i]);
		}
	}
for (F=0; F<files.length; F++){
	
		run("Close All");
		print("File "+(F+1)+" out of "+files.length+": "+files[F]);
		saveName=extStrip(files[F]);
		if (File.exists(regionDir+saveName+"_regionalROIs.zip")==false){
			print("No ROIs found for regions");
			continue;
		}
		if (File.exists(roiDir+saveName+"_FullCellROIs.zip")==false){
			print("No ROIs found for cells");
			continue;
		}
		roiManager("reset");
		run("Bio-Formats Windowless Importer", "open=["+dir+files[F]+"]");
		name=File.name; 
		saveName=File.nameWithoutExtension;
		open(roiDir+saveName+"_FullCellROIs.zip");
		numCells=roiManager("count");
		open(regionDir+saveName+"_regionalROIs.zip");
		numROIs=roiManager("count")-numCells;
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
		regionNames=newArray(numCells);
		for (c=0; c<numCells; c++){
			winning=0;
			region="none"; //no name for cell's region
			for (r=0; r<numROIs; r++){
				run("Clear Results");
				roiManager("select", numCells+r); //select each region
				run("Create Mask");
				selectWindow("Mask");
				run("Select None");
				roiManager("select",c); //select the cell
				roiManager("measure");
				selectWindow("Mask");
				run("Close");
				overlap=getResult("%Area",0);
				if (overlap>winning){
					winning=overlap;
					roiManager("select", numCells+r);
					region=Roi.getName;
				}
			}
			regionNames[c]=region;
		}
		//Array.print(regionNames);
		//waitForUser("");
		//Export the table
		roiManager("reset");
		run("Clear Results");
		open(roiDir+saveName+"_FullCellROIs.zip");
		roiManager("multi-measure");
		addToTable(regionNames,"Region");
		saveAs("Results",csvDir+date+"_"+saveName+"_RegionInfo.csv");
		run("Close All");
}
function getDate(){
		//This function gets and returns a string of the current date in yearmonthday format.
		getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
		if (dayOfMonth<10) {dayOfMonth = "0"+dayOfMonth;}
		month=month+1;
		if (month<10) {month = "0"+month;}
		return toString(year)+toString(month)+toString(dayOfMonth);
	}
function addToTable(array, title){
		/*This function is used to add a vector into a results table under the column name given by the title 
		 * variable. Note that the array should already be the appropriate length for the existing results table
		 * or you won't get what you want. 
		 */
		for(i=0;i<lengthOf(array);i++){
			setResult(title, i, array[i]);
		}
	}
function extStrip(str){
	str = replace(str, "\\.tif", "");
	str = replace(str, "\\.tiff", "");
	str = replace(str, "\\.nd2", "");
	str = replace(str, "\\.czi", "");
	str = replace(str, "\\.lsm", "");
	return str;
}