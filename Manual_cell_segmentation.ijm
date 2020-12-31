//Manual thresholder for cell bodies using magic wand!
//Originally 20201215_manualCellSegmentation_calbindinMod 
 /********************************************
 * Step 1: Get Directory and Initialize
 ********************************************/
run("Close All");
dir= getDirectory("Choose a Directory") //select your folder with images
list=getFileList(dir);
roiDir=dir+"ROIs/";
File.makeDirectory(roiDir);
files=newArray();
saveType="Tiff";
print("\\Clear"); //clears log
run("Clear Results");
roiManager("UseNames", "false"); //unless manually editing ROIs this doesn't help usually.
run("Set Measurements...", "area mean min shape integrated median area_fraction limit display redirect=None decimal=6");
fiberChannel=1; //GFP
somaChannel=2; //VGLUT3

/********************************************
 * Step 2: Open Image and Segment
 ********************************************/
 
for (i=0;i<list.length; i++){
		if ((endsWith(list[i],".czi"))||(endsWith(list[i],".tif"))||(endsWith(list[i],".lsm"))||(endsWith(list[i],".nd2"))||(endsWith(list[i],".tiff"))){
		files=Array.concat(files,list[i]);
		}
	}
for (F=0; F<files.length; F++){
	//setBatchMode(false);
	roiManager("reset");
	run("Close All");
	run("Bio-Formats Windowless Importer", "open=["+dir+files[F]+"]");
	name=File.name; 
	saveName=File.nameWithoutExtension;
	selectWindow(name);
	Stack.setChannel(somaChannel);
	run("Grays");
	run("Enhance Contrast", "saturated=0.35");
	run("Duplicate...", "title=original");
	run("Duplicate...", "title=median_filtered");
	selectWindow("median_filtered");
	run("Median...", "radius=5");
	run("Synchronize Windows");
	resizeThree("original","median_filtered","Synchronize Windows");
	run("Wand Tool...", "tolerance=400 mode=8-connected");
	setTool("wand");
	waitForUser("Select Original and Median_filtered in Synchronize Windows. Ensure 'Image Scaling' is checked.");
	waitForUser("Look at original image and median filtered and click on the median filtered to select cell soma. \nClick until good segmentation is achieved in the median filtered image. \nFor each cell, hit 't' to add it to the roiManager. \nTo pan, hold down space, click and drage. \nTo zoom, hold 'alt/option' and hit the '-/+' keys.");
    selectWindow("median_filtered");
	roiManager("save", roiDir+"/"+saveName+"_FullCellROIs.zip");
	run("Close All");
}
	
function resizeThree(win1,win2,win3){
		/*
		 * This function resizes two windows to better fit the screen space available. --
		 * No outputs.Third window is menu
		 * Also moves B&C window
		 */
		getLocationAndSize(x, y, pixelwidth, pixelheight);
		x1=20;
		y1=120;
		x2=screenWidth/3+20;
		x3=(screenWidth*2/3)+50;
		selectWindow(win1); //must be image
		setLocation(x1, y1, screenWidth/3, screenHeight);
		setLocation(x1, y1, screenWidth/3, screenHeight);
		selectWindow(win2); //must be image
		setLocation(x2, y1, screenWidth/3, screenHeight);
		setLocation(x2, y1, screenWidth/3, screenHeight);
		selectWindow(win3); //must be menu 
		setLocation(x3, 150);
		run("Brightness/Contrast...");
		selectWindow("B&C");
		setLocation(x3, screenHeight/2);
		run("Channels Tool...");
		selectWindow("Channels");
		setLocation(x3+200, screenHeight/2);
	}