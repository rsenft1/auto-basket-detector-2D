//Manual removal script made from the manual segmentation script.
 
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
somaChannel=2; //Calb

/********************************************
 * Step 2: Open Image and Remove (or add, technically) ROIs
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
	if (File.exists(roiDir+saveName+"_FullCellROIs.zip")==1){
		roiManager("reset");
		open(roiDir+saveName+"_FullCellROIs.zip");
		//roiManager("Add"); 
		print("ROIs found for full Cells");
	}
	selectWindow(name);
	Stack.setChannel(somaChannel);
	run("Grays");
	run("Enhance Contrast", "saturated=0.35");
	selectWindow("ROI Manager");
	roiManager("show all with labels");
	//waitForUser("Select Original and Median_filtered in Synchronize Windows. Ensure 'Image Scaling' is checked.");
	waitForUser("Get rid of any incorrect ROIs");
    //selectWindow("median_filtered");
	roiManager("save", roiDir+"/"+saveName+"_FullCellROIs.zip");
	run("Close All");
}