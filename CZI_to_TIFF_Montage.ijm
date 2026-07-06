// CZI/ZVI to TIFF Batch Converter with Montage Creator
// Processes folder structure:
// Main Folder
//   -> Subfolder 1
//       -> "Img" folder (contains ZVI files)
//       -> "LastScan.jpg" (optional - no longer needed for grid dimensions)
//   -> Subfolder 2
//       -> ... etc
//
// Creates "TIFF" folder in each subfolder with converted images and montage

// Dialog to get user input
Dialog.create("Batch CZI/ZVI to TIFF Converter");
Dialog.addDirectory("Main directory (containing subfolders):", "");
Dialog.addString("File extension:", "zvi");
Dialog.addCheckbox("Create montage:", true);
Dialog.addCheckbox("Apply scale to all TIFF files:", false);
Dialog.addNumber("Pixels per unit:", 1.4);
Dialog.addString("Unit of measurement:", "micrometer");
Dialog.addNumber("X offset (optional):", 0);
Dialog.addNumber("Y offset (optional):", 0);
Dialog.addMessage("--- Cleanup Options ---");
Dialog.addCheckbox("Delete Img subfolders after conversion:", false);
Dialog.addCheckbox("Delete individual TIFF files after montage is created:", false);
Dialog.show();

main_dir = Dialog.getString();
extension = Dialog.getString();
create_montage = Dialog.getCheckbox();
apply_scale = Dialog.getCheckbox();
scale_pixels_per_unit = Dialog.getNumber();
scale_unit = Dialog.getString();
scale_offset_x = Dialog.getNumber();
scale_offset_y = Dialog.getNumber();
delete_img_folders = Dialog.getCheckbox();
delete_individual_tiffs = Dialog.getCheckbox();

// Validate directory
if (main_dir == "") {
	showMessage("Error", "Please select a directory.");
	exit();
}

// Deleting individual TIFFs only makes sense if a montage is being created to hold that data
if (delete_individual_tiffs && !create_montage) {
	showMessage("Error", "\"Delete individual TIFF files after montage\" requires \"Create montage\" to be enabled. Please enable montage creation or uncheck this option.");
	exit();
}

// Confirm before enabling any destructive/irreversible cleanup steps
if (delete_img_folders || delete_individual_tiffs) {
	warning = "WARNING - the following cannot be undone:\n";
	if (delete_img_folders) {
		warning += " - Every \"Img\" subfolder (and its original files) will be deleted after conversion.\n";
	}
	if (delete_individual_tiffs) {
		warning += " - Individual converted TIFF files will be deleted after the montage is created, keeping only Montage.tif.\n";
	}
	warning += "\nContinue?";
	proceed = getBoolean(warning);
	if (!proceed) {
		print("Operation cancelled by user.");
		exit();
	}
}

print("Starting batch processing...");
print("Main directory: " + main_dir);
if (apply_scale) {
	print("Scale will be applied: " + scale_pixels_per_unit + " pixels/" + scale_unit);
} else {
	print("No scale will be applied");
}
if (delete_img_folders) {
	print("Img subfolders will be DELETED after conversion");
}
if (delete_individual_tiffs) {
	print("Individual TIFF files will be DELETED after montage creation");
}

// Get list of subfolders
subfolders = getSubfolders(main_dir);

for (f = 0; f < subfolders.length; f++) {
	subfolder = subfolders[f];
	img_folder = subfolder + "Img" + File.separator;
	last_scan = subfolder + "LastScan.jpg";
	output_folder = subfolder + "TIFF" + File.separator;
	
	print("");
	print("Processing: " + subfolder);
	
	// Check if Img folder exists
	if (!File.isDirectory(img_folder)) {
		print("  Skipping - no Img folder found");
		continue;
	}
	
	// Check if LastScan.jpg exists
	if (!File.exists(last_scan)) {
		print("  Skipping - no LastScan.jpg found");
		continue;
	}
	
	// Create TIFF output folder
	if (!File.isDirectory(output_folder)) {
		File.makeDirectory(output_folder);
		print("  Created TIFF folder");
	}
	
	// Extract grid dimensions from LastScan.jpg filename
	last_scan_filename = File.getName(last_scan);
	max_row = extractValue(last_scan_filename, "L");
	max_col = extractValue(last_scan_filename, "C");
	
	print("  Grid dimensions: " + (max_row + 1) + " x " + (max_col + 1));
	
	// Process ZVI files in Img folder
	processFolderImages(img_folder, output_folder, extension, max_row, max_col, create_montage, apply_scale, scale_pixels_per_unit, scale_unit, scale_offset_x, scale_offset_y, delete_img_folders, delete_individual_tiffs);
}

print("");
print("Batch processing complete!");

// Function to get all subfolders
function getSubfolders(path) {
	list = getFileList(path);
	subfolders = newArray();
	count = 0;
	
	for (i = 0; i < list.length; i++) {
		if (File.isDirectory(path + File.separator + list[i])) {
			subfolders[count] = path + File.separator + list[i] + File.separator;
			count++;
		}
	}
	
	return subfolders;
}

// Function to process all images in a folder
function processFolderImages(img_folder, output_folder, extension, max_row, max_col, create_montage, apply_scale, scale_pixels_per_unit, scale_unit, scale_offset_x, scale_offset_y, delete_img_folders, delete_individual_tiffs) {
	list = getFileList(img_folder);
	file_list = newArray();
	row_data = newArray();
	col_data = newArray();
	file_count = 0;
	
	// Find all image files with the specified extension
	for (i = 0; i < list.length; i++) {
		if (endsWith(list[i], "." + extension)) {
			file_list[file_count] = list[i];
			
			// Extract row and column info
			row = extractValue(list[i], "L");
			col = extractValue(list[i], "C");
			
			row_data[file_count] = row;
			col_data[file_count] = col;
			
			print("    Found: " + list[i] + " (Row: " + row + ", Col: " + col + ")");
			file_count++;
		}
	}
	
	if (file_count == 0) {
		print("    No images found");
		return;
	}
	
	// Find the maximum row and column from actual files
	max_row = 0;
	max_col = 0;
	for (i = 0; i < file_count; i++) {
		if (row_data[i] > max_row) max_row = row_data[i];
		if (col_data[i] > max_col) max_col = col_data[i];
	}
	
	print("    Calculating grid from images - Max Row: " + max_row + ", Max Col: " + max_col);
	print("    Converting " + file_count + " images...");
	
	// Convert files
	opened_images = newArray();
	
	for (i = 0; i < file_list.length; i++) {
		filename = file_list[i];
		path = img_folder + filename;
		
		// Open ZVI/CZI file using Bio-Formats
		run("Bio-Formats Importer", "open=[" + path + "] color_mode=Default concatenate_series open_all_series rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		
		image_title = getTitle();
		
		// Ensure image is in RGB color to preserve original colors
		if (bitDepth() != 24) {
			run("RGB Color");
		}
		
		// Apply scale if requested
		if (apply_scale) {
			run("Set Scale...", "distance=" + scale_pixels_per_unit + " known=1 pixel=1 unit=" + scale_unit + " offset.x=" + scale_offset_x + " offset.y=" + scale_offset_y);
		}
		
		// Save as TIFF
		tiff_filename = replace(filename, "." + extension, ".tif");
		tiff_path = output_folder + tiff_filename;
		saveAs("Tiff", tiff_path);
		
		opened_images[i] = image_title;
	}
	
	// Close all open images to prevent window confusion
	while (nImages() > 0) {
		selectImage(1);
		close();
	}
	
	// Delete the Img subfolder now that all its files have been converted to TIFF
	if (delete_img_folders) {
		print("    Deleting Img subfolder...");
		deleteFolder(img_folder);
		print("    Img subfolder deleted");
	}
	
	// Create montage if requested
	if (create_montage) {
		print("    Creating montage...");
		createMontage(file_list, row_data, col_data, max_row, max_col, output_folder, extension, apply_scale, scale_pixels_per_unit, scale_unit, scale_offset_x, scale_offset_y);
		print("    Montage saved");
		
		// Delete the individual TIFF files now that the montage has been created, keeping only Montage.tif
		if (delete_individual_tiffs) {
			print("    Deleting individual TIFF files (keeping Montage.tif)...");
			for (i = 0; i < file_list.length; i++) {
				tiff_filename = replace(file_list[i], "." + extension, ".tif");
				tiff_path = output_folder + tiff_filename;
				if (File.exists(tiff_path)) {
					File.delete(tiff_path);
				}
			}
			print("    Individual TIFF files deleted");
		}
	}
	
	print("    Complete");
}

// Function to extract numeric value after a letter (e.g., "L005" -> 5)
function extractValue(filename, letter) {
	index = indexOf(filename, letter);
	if (index == -1) return 0;
	
	index = index + 1; // Move past the letter
	value_str = "";
	
	while (index < lengthOf(filename) && isDigit(substring(filename, index, index + 1))) {
		value_str += substring(filename, index, index + 1);
		index++;
	}
	
	if (value_str == "") return 0;
	return parseInt(value_str);
}

// Function to check if character is a digit
function isDigit(char) {
	val = parseInt(char);
	return !isNaN(val);
}

// Function to extract numeric value after a letter (e.g., "L005" -> 5)
function extractValue(filename, letter) {
	index = indexOf(filename, letter);
	if (index == -1) return 0;
	
	index = index + 1; // Move past the letter
	value_str = "";
	
	while (index < lengthOf(filename) && isDigit(substring(filename, index, index + 1))) {
		value_str += substring(filename, index, index + 1);
		index++;
	}
	
	if (value_str == "") return 0;
	return parseInt(value_str);
}

// Function to check if character is a digit
function isDigit(char) {
	val = parseInt(char);
	return !isNaN(val);
}

// Function to recursively delete a folder and everything inside it
function deleteFolder(path) {
	list = getFileList(path);
	for (i = 0; i < list.length; i++) {
		item = path + list[i];
		if (File.isDirectory(item)) {
			deleteFolder(item);
		} else {
			File.delete(item);
		}
	}
	File.delete(path);
}

// Function to create montage from files
function createMontage(file_list, rows, cols, max_row, max_col, output_dir, extension, apply_scale, scale_pixels_per_unit, scale_unit, scale_offset_x, scale_offset_y) {
	rows_count = max_row + 1;
	cols_count = max_col + 1;
	
	print("    Montage dimensions: " + rows_count + " rows x " + cols_count + " cols");
	print("    Total files to place: " + file_list.length);
	
	// Open first TIFF to get dimensions
	first_tiff = replace(file_list[0], "." + extension, ".tif");
	first_path = output_dir + first_tiff;
	print("    Opening first file: " + first_path);
	
	open(first_path);
	width = getWidth();
	height = getHeight();
	close();
	
	print("    Image size: " + width + " x " + height);
	
	// Create new montage image in RGB
	montage_width = width * cols_count;
	montage_height = height * rows_count;
	
	print("    Creating montage: " + montage_width + " x " + montage_height);
	
	newImage("Montage", "RGB", montage_width, montage_height, 1);
	montage_id = getImageID();
	
	// Place each TIFF in correct grid position
	for (i = 0; i < file_list.length; i++) {
		row = rows[i];
		col = cols[i];
		
		original_filename = file_list[i];
		tiff_filename = replace(original_filename, "." + extension, ".tif");
		tiff_path = output_dir + tiff_filename;
		
		print("    [" + i + "] Row: " + row + ", Col: " + col + " -> " + tiff_filename);
		
		// Open TIFF file
		open(tiff_path);
		tiff_id = getImageID();
		
		// Apply scale if requested
		if (apply_scale) {
			run("Set Scale...", "distance=" + scale_pixels_per_unit + " known=1 pixel=1 unit=" + scale_unit + " offset.x=" + scale_offset_x + " offset.y=" + scale_offset_y);
		}
		
		// Copy the entire image
		run("Select All");
		run("Copy");
		
		// Paste into montage at correct position
		selectImage(montage_id);
		x = col * width;
		y = row * height;
		makeRectangle(x, y, width, height);
		run("Paste");
		run("Select None");
		
		// Close the temporary TIFF
		selectImage(tiff_id);
		close();
	}
	
	// Save montage as TIFF
	selectImage(montage_id);
	
	// Apply scale to montage if requested
	if (apply_scale) {
		run("Set Scale...", "distance=" + scale_pixels_per_unit + " known=1 pixel=1 unit=" + scale_unit + " offset.x=" + scale_offset_x + " offset.y=" + scale_offset_y);
	}
	
	montage_path = output_dir + "Montage.tif";
	print("    Saving montage to: " + montage_path);
	saveAs("Tiff", montage_path);
	close();
	print("    Montage complete!");
}
