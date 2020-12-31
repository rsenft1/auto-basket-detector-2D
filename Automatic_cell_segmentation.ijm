//Original name: 20201223_SegmentCalb_only
/********************************************
 * Step 1: Get Directory and Initialize
 ********************************************/
run("Close All");
dir= getDirectory("Choose a Directory") //select your folder with images
list=getFileList(dir);
roiDir=dir+"ROIs/";
//File.makeDirectory(roiDir); 
date=getDate();
File.makeDirectory(dir + date+"_BasketAnalysis/"); 
dirSave=dir + date+"_BasketAnalysis/";
//File.makeDirectory(dirSave + "savedOverlays/"); 
//imageDir=dirSave + "savedOverlays/";
File.makeDirectory(dirSave + "CSV_Files/"); 
csvDir=dirSave + "CSV_Files/";
imageDir=dirSave + "BinaryMask/";
File.makeDirectory(imageDir); 
files=newArray();
saveType="Tiff";
print("\\Clear"); //clears log
run("Clear Results");
roiManager("UseNames", "false"); //unless manually editing ROIs this doesn't help usually.
run("Set Measurements...", "area mean min shape integrated median area_fraction limit display redirect=None decimal=6");
fiberChannel=1; //GFP
cellSomaChannel=2; //Calb
 
print("*******************************************************************************************************************************************");
print("Basket-Detector Analysis Date: "+date);
print("Script: 20201223_SegmentCalbOnly_v1");
print("*******************************************************************************************************************************************");
print("Current Directory: "+dir);
/********************************************
 * Step 2: Open Image and Segment
 ********************************************/
setBatchMode(true);
for (i=0;i<list.length; i++){
		if ((endsWith(list[i],".czi"))||(endsWith(list[i],".tif"))||(endsWith(list[i],".lsm"))||(endsWith(list[i],".nd2"))||(endsWith(list[i],".tiff"))){
		files=Array.concat(files,list[i]);
		}
	}
if (File.exists(roiDir)==0){ //make roiDir if it doesn't exist
		File.makeDirectory(roiDir); 
}
loadBarName="[Progress...]";
closeIfOpen(loadBarName);
run("Text Window...", "name="+loadBarName+" width=30 height=2 monospaced"); //initialize load bar
for (F=0; F<files.length; F++){
		loadBar(loadBarName,F,files.length);
		run("Close All");
		print("Working on image "+F+1+" / "+files.length+"...");
		run("Bio-Formats Windowless Importer", "open=["+dir+files[F]+"]");
		name=File.name; 
		saveName=File.nameWithoutExtension;
		if (File.exists(roiDir+saveName+"_FullCellROIs.zip")==1){
			roiManager("reset");
			open(roiDir+saveName+"_FullCellROIs.zip");
			//roiManager("Add"); 
			print("ROIs found for full Cells");
		}
		else{
			segmentCalb(name,cellSomaChannel);
		}
}
closeIfOpen(loadBarName);

function segmentCalb(name, somaChannel){
	roiManager("reset");
	Stack.setChannel(somaChannel);
	run("Enhance Contrast", "saturated=0.35");
	run("Duplicate...", "title=Calb");
	run("Duplicate...", "title=Calb-blurred");
	selectWindow(name);
	Stack.setChannel(1);
	run("Enhance Contrast", "saturated=0.35");
	run("Make Composite");
	selectWindow("Calb-blurred");
	run("Gaussian Blur...", "sigma=100");
	imageCalculator("Subtract create", "Calb","Calb-blurred");
	run("Gaussian Blur...", "sigma=2");
	setAutoThreshold("Triangle stack");
	run("Convert to Mask");
	run("Invert");
	run("Analyze Particles...", "size=40.00-600.00 circularity=0.30-1.00 show=Masks exclude clear include");
	run("Invert");
	run("Close-");
	run("Fill Holes");
	run("Adjustable Watershed", "tolerance=1");
	//run again to get rid of small specs
	run("Analyze Particles...", "size=40.00-300.00 circularity=0.40-1.00 show=Masks exclude clear include summarize add");
	//save Full cell ROIs:
	roiManager("save", roiDir+"/"+saveName+"_FullCellROIs.zip");
	//waitForUser("check calb");
}
function closeIfOpen(string) {
		/*
		 * This function is useful if you desire to close a window by name but there is a chance depending on user action
		 * that the window may already be closed. 
		 */
	 	if (isOpen(string)) {
	         selectWindow(string);
	         run("Close");
	    }
	}
function getDate(){
	//This function gets and returns a string of the current date in yearmonthday format.
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	if (dayOfMonth<10) {dayOfMonth = "0"+dayOfMonth;}
	month=month+1;
	if (month<10) {month = "0"+month;}
	return toString(year)+toString(month)+toString(dayOfMonth);
}
function loadBar(loadBarName, current, max){
	//adapted from the Progress Bar ImageJ macro available at imagej.nih.goc/macros/ProgressBar.txt
	percent=round(current/max*100);
	bar1 = "--------------------";
    bar2 = "********************";
    outOf20=round(current/max*20);
    currentBar=substring(bar2,0,outOf20)+substring(bar1,outOf20,20);
	print(loadBarName, "\\Update:"+current+"/"+max+" ("+(percent*100)/100+"%)\n"+currentBar);
}
