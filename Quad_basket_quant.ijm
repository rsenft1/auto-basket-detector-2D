//originally 20201223_basket_quad_noSegmentation
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
print("Script: 20201214_Basket_Detector_v1");
print("*******************************************************************************************************************************************");
print("Current Directory: "+dir);
/********************************************
 * Step 2: Open Image and Segment
 ********************************************/
setBatchMode(true);
loadBarName="[Progress...]";
closeIfOpen(loadBarName);
run("Text Window...", "name="+loadBarName+" width=30 height=2 monospaced"); //initialize load bar
for (i=0;i<list.length; i++){
		if ((endsWith(list[i],".czi"))||(endsWith(list[i],".tif"))||(endsWith(list[i],".lsm"))||(endsWith(list[i],".nd2"))||(endsWith(list[i],".tiff"))){
		files=Array.concat(files,list[i]);
		}
	}
for (F=0; F<files.length; F++){
	//setBatchMode(false);
		loadBar(loadBarName,F,files.length);
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
		else{
			print("Image "+saveName+" has no ROIs. It will be skipped");
			continue; //go to next image
		}
		if (File.exists(imageDir+saveName+"_"+"_projections.tiff")==1){
			run("Bio-Formats Windowless Importer", "open=["+imageDir+saveName+"_"+"_projections.tiff"+"]");
			rename("projections-binary");
		}
		else{
			segmentFibers(name,fiberChannel);
			selectWindow("projections-binary");
			saveAs(saveType,imageDir+saveName+"_"+"_projections.tiff");
			rename("projections-binary");
		}
		selectWindow("projections-binary");
		
		//Save Full Cell Measurements
		run("Set Measurements...", "area mean min shape integrated median area_fraction display redirect=None decimal=6"); //Area is now full cell area, not just the part that's + 
		roiManager("deselect");
		roiManager("multi-measure"); //contains quad info
		saveAs("Results",csvDir+date+"_"+saveName+"_FullCellResults.csv");
		IJ.renameResults("temp"); //need to store these for later...
		FullCells=roiManager("count"); //cells at this moment
		//now quarter the cells
		if (File.exists(roiDir+saveName+"_quadROIs.zip")==1){
			roiManager("reset");
			open(roiDir+saveName+"_quadROIs.zip");
			//roiManager("Add"); 
			print("ROIs found for cell quadrants");
		}
		else{
			//Divide each cell into quads
			for (C=1; C<=FullCells; C++){
				divideCell(C);
			}
			//delete the original cells at the top of the ROI list
			cellsToDelete=newArray(FullCells);
			for (i=0;i<FullCells;i++){
				cellsToDelete[i]=i;
			}
			roiManager("select", cellsToDelete);
			roiManager("delete");
			roiManager("save", roiDir+saveName+"_quadROIs.zip");
		}
		//save quad info 1 quad per row:
		run("Set Measurements...", "area mean min shape integrated median area_fraction limit display redirect=None decimal=6"); //Area is limited to the part occupied by boutons
		roiManager("deselect");
		setThreshold(1, 255);
		roiManager("multi-measure"); //contains quad info. Area is Bouton area, not area of each quadrant (which could be back-calculated by dividing the bouton area by its % Area value
		saveAs("Results",csvDir+date+"_"+saveName+"_rowQuads.csv");
		//now reorganize the table so that each cell is a row and the quads are each a new result column
		reorganizeQuadData();
		saveAs("Results",csvDir+date+"_"+saveName+"_FinalData.csv");
}

function segmentFibers(name,fiberChannel){
	selectWindow(name);
	Stack.setChannel(fiberChannel);
	run("Duplicate...", "title=projections");
	run("Duplicate...", "title=projections-blurred");
	selectWindow("projections-blurred");
	run("Gaussian Blur...", "sigma=100");
	imageCalculator("Subtract create", "projections","projections-blurred");
	selectWindow("Result of projections");
	run("Enhance Contrast", "saturated=0.35");
	run("Duplicate...", "title=projections-binary");
	setAutoThreshold("Triangle dark stack");
	run("Convert to Mask");
}
function divideCell(cell){
	run("Clear Results");
	roiManager("deselect");
	numCells=roiManager("count");
	getPixelSize(unit, pixelWidth, pixelHeight);
	roiManager("select",cell-1); // reminder: cell #1 is associated with index #0
	print("working on cell "+cell+".../"+FullCells);
	//roiManager("rename","myCell");
	run("Enlarge...", "enlarge=1"); //want a small border of 1 um around the cell as well
	run("Interpolate", "interval=1");
	getSelectionCoordinates(x,y);
	List.setMeasurements;
	CenterX=List.getValue("X")/pixelWidth;
	CenterY=List.getValue("Y")/pixelHeight;
	//currently hard-coded for quadrants. ImageJ is annoying in not allowing multidimensional vectors so altering this is a pain. 
	q1X=newArray();
	q2X=newArray();
	q3X=newArray();
	q4X=newArray();
	q1Y=newArray();
	q2Y=newArray();
	q3Y=newArray();
	q4Y=newArray();
	q1X=Array.concat(q1X,CenterX);
	q2X=Array.concat(q2X,CenterX);
	q3X=Array.concat(q3X,CenterX);
	q4X=Array.concat(q4X,CenterX);
	q1Y=Array.concat(q1Y,CenterY);
	q2Y=Array.concat(q2Y,CenterY);
	q3Y=Array.concat(q3Y,CenterY);
	q4Y=Array.concat(q4Y,CenterY);
	numPoints=(x.length+x.length%4)/4; //number of points to assign to each quadrant, taking into account numbers non-divisible by 4.
	//this loop just adds the X/Y values for each quadrant by dividing all the perimeter points into 4 even groups. 
	for (i=0; i<x.length;i++){
		//note the interpolation step above ensures the quadrants are more even, but it has the disadvantage of causing 1 pixel long gaps between quad 1/2 and 3/4 so the -1 and +1 below address these.
		 if (i<=numPoints){
		 	q1X=Array.concat(q1X,x[i]);
		 	q1Y=Array.concat(q1Y,y[i]);
		 }
		 if ((i>=numPoints-1)&&(i<=2*numPoints)){
		 	q2X=Array.concat(q2X,x[i]);
		 	q2Y=Array.concat(q2Y,y[i]);
		 }
		 if ((i>=2*numPoints)&&(i<=3*numPoints+1)){
		 	q3X=Array.concat(q3X,x[i]);
		 	q3Y=Array.concat(q3Y,y[i]);
		 }
		 if (i>=3*numPoints){
		 	q4X=Array.concat(q4X,x[i]);
		 	q4Y=Array.concat(q4Y,y[i]);
		 }
	}
	//Also need to add the first point onto the end of Q4. 
	q4X=Array.concat(q4X,x[0]);
	q4Y=Array.concat(q4Y,y[0]); 
	//Now we add the quadrants to the roiManager
	roiManager("deselect")
	makeSelection("polygon",q1X, q1Y);
	addQuad(1, cell);
	makeSelection("polygon",q2X, q2Y);
	addQuad(2, cell);
	makeSelection("polygon",q3X, q3Y);
	addQuad(3, cell);
	makeSelection("polygon",q4X, q4Y);
	addQuad(4, cell);
	//subtract out a circle placed in center for each quadrant to avoid issue where a center bouton could trigger a basket call
	//first make a circle size 12 centered on the cell center
	circleSize=12;
	makeOval(CenterX-circleSize/2, CenterY-circleSize/2, circleSize, circleSize);
	roiManager("add");
	roiManager("select", roiManager("count")-1);
	roiManager("rename", "circle");
	//for each quadrant, subtract the overlapping area with the circle.
	quadrants=newArray("C"+cell+"Q1","C"+cell+"Q2","C"+cell+"Q3","C"+cell+"Q4");
	run("Set Measurements...", "area mean min shape integrated median area_fraction display redirect=None decimal=6");
	for (i=0;i<quadrants.length;i++){
		upToQuads=roiManager("count");
		roiManager("deselect");
		overlap = newArray("circle",quadrants[i]);
		index = roiFind(overlap);
		currentQuad=newArray(quadrants[i]);
		roiManager("deselect");
		roiManager("select", index);
		roiManager("AND");
		roiManager("Add");
		ANDIndex=newArray();
		ANDIndex=Array.concat(newArray,roiManager("count")-1);
		roiManager("deselect");
		CurrentQuadIndex=roiFind(currentQuad); //array
		XORindex=Array.concat(CurrentQuadIndex,ANDIndex);
		roiManager("Select", XORindex);
		//waitForUser("should be AND and whole quad selected");
		roiManager("XOR");
		roiManager("Add");
		roiManager("deselect");
		roiManager("Select",upToQuads);
		//waitForUser("should be AND selected");
		//CHANGE so you have AND(circle, quad), add, then XOR that with quad and save the composite. then we don't even need the size filter
		//upToQuads=roiManager("count")-1;
		roiManager("delete"); //deletes the AND selection
		/*
		winning=0;
		largest=0;
		for (k = upToQuads; k < roiManager("count"); k++) {
			run("Clear Results");
			roiManager("select", k);
			//waitForUser("");
			run("Measure");
			area=getResult("Area",0);
			if (area>winning){
				winning=area;
				largest=k;
			}
		}
		
		//print(quadrants[i]+" Largest:"+largest);
		for (j = upToQuads; j < roiManager("count"); j++) {
			if (j != largest){
				roiManager("select",j);
				roiManager("rename","small");
			}
		}
		*/
		quadName=newArray();
		quadName=Array.concat(quadName,quadrants[i]);;
	}
		deleteKeywords=newArray("circle");
		deleteKeywords=Array.concat(deleteKeywords,quadrants);
		//toDelete=roiFind(deleteKeywords);
		toDelete=roiFind(deleteKeywords);
		//Array.print(toDelete); //should be numbers
		roiManager("deselect");
		roiManager("select", toDelete);
		//waitForUser("whole quads selected");
		roiManager("delete");
		//rename ROIs
		for (i=0;i<4;i++){
			roiManager("select",numCells+i);
			roiManager("rename", "Cell_"+IJ.pad(cell,4)+"_Q"+i+1);	
		}
		run("Set Measurements...", "area mean min shape integrated median area_fraction limit display redirect=None decimal=6");
}
function roiFind(strArray){
	/* Takes in an array of strings corresponding to names of ROIs and returns their indices as an array*/
	roiCount=roiManager("count");
	indices=newArray();
	for (k=0;k<strArray.length;k++){
		roiName=strArray[k];
		for (i=0; i<roiCount; i++) { 
			roiManager("Select", i); 
			name = Roi.getName(); 
			if (matches(name, roiName) ) { 
				indices=Array.concat(indices,i);
			}	
		}		
	}
	return indices;
	}
function addQuad(num,cell){
	roiManager("add");
	roiManager("select", roiManager("count")-1)
	roiManager("rename", "C"+cell+"Q"+num);	
}
function reorganizeQuadData(){
	quadAreas=newArray(roiManager("count"));
	percentAreas=newArray(roiManager("count"));
	for (i = 0; i < nResults; i++) {
		quadAreas[i]=getResult("Area", i);
		percentAreas[i]=getResult("%Area",i);
	}
	closeIfOpen("Results");
	Table.rename("temp", "Results");
	//Append Q1...Q4 columns
	ind=0;
	for (i = 0; i < roiManager("count"); i=i+4) {
			setResult("Q1 Bouton Area", i/4, quadAreas[i+0]);
			setResult("Q2 Bouton Area", i/4, quadAreas[i+1]);
			setResult("Q3 Bouton Area", i/4, quadAreas[i+2]);
			setResult("Q4 Bouton Area", i/4, quadAreas[i+3]);
			setResult("Q1 % Bouton Area", i/4, percentAreas[i+0]);
			setResult("Q2 % Bouton Area", i/4, percentAreas[i+1]);
			setResult("Q3 % Bouton Area", i/4, percentAreas[i+2]);
			setResult("Q4 %Bouton Area", i/4, percentAreas[i+3]);
	}
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
	print(loadBarName, "\\Update:"+percent+"/"+100+" ("+(percent*100)/100+"%)\n"+currentBar);
}