# CZI/ZVI to TIFF Batch Converter with Montage Creator
# WARNING: THIS IS VIBE CODED, DOUBLE CHECK EVERYTHING
A FIJI/ImageJ macro for batch converting microscopy image files (CZI, ZVI) to TIFF format with automatic montage assembly and optional calibration scaling.

## Features

- **Batch Processing**: Process multiple folders of microscopy images in one run
- **Format Conversion**: Convert CZI and ZVI files to publication-ready TIFF format
- **Color Preservation**: Maintains original blue/RGB coloring through conversion
- **Automatic Montage Assembly**: Creates composite montage images from grid-scanned tiles
- **Grid Auto-Detection**: Automatically determines montage dimensions from image filenames
- **Universal Scaling**: Apply consistent calibration (pixels/micrometer) to all output images
- **Folder Organization**: Creates organized TIFF subdirectories within existing folder structure

## Installation

### Requirements
- FIJI (Fiji Is Just ImageJ) - [download here](https://fiji.sc/)
- Bio-Formats plugin (included in FIJI by default)

### Setup

1. Download `CZI_to_TIFF_Montage.ijm`
2. In FIJI, go to `Plugins > Macros > Install...` and select the file
3. Or copy the file to your FIJI installation: `Fiji.app/macros/`
4. Restart FIJI or reload macros

## Usage

### Input Folder Structure

The macro expects a specific folder organization:

```
Main Folder/
├── Subfolder 1/
│   ├── Img/
│   │   ├── Scan_L000C000.zvi
│   │   ├── Scan_L000C001.zvi
│   │   ├── Scan_L001C000.zvi
│   │   └── ... (more images)
│   └── LastScan.jpg (optional - no longer needed for grid dimensions)
├── Subfolder 2/
│   ├── Img/
│   │   └── ... (images)
│   └── LastScan.jpg
└── ... (more subfolders)
```

### Filename Conventions

Image files must follow this naming pattern:
- `Scan_L###C###.zvi` (or `.czi`)
- **L** = row coordinate (0-indexed)
- **C** = column coordinate (0-indexed)

Examples:
- `Scan_L000C000.zvi` → Row 0, Column 0 (top-left)
- `Scan_L003C002.zvi` → Row 3, Column 2

### Running the Macro

1. Open FIJI
2. Go to `Plugins > Macros > CZI_to_TIFF_Montage`
3. A configuration dialog will appear with options:
   - **Main directory**: Select the folder containing your subfolders
   - **File extension**: Set to `zvi` or `czi` (default: `zvi`)
   - **Create montage**: Check to generate composite montage images
   - **Apply scale**: Check to calibrate images with pixel/unit scaling
   - **Pixels per unit**: Calibration factor (default: 1.4)
   - **Unit of measurement**: Calibration unit (default: micrometer)
   - **X/Y offset**: Optional calibration offsets

4. Click OK and the macro will:
   - Process all subfolders
   - Convert images to TIFF
   - Create TIFF subfolder in each subfolder
   - Generate montage images if selected
   - Apply scaling if selected

## Output

### Output Structure

For each input subfolder, the macro creates:

```
Subfolder/
├── Img/
│   └── (original ZVI/CZI files)
└── TIFF/
    ├── Scan_L000C000.tif
    ├── Scan_L000C001.tif
    ├── ... (all converted images)
    └── Montage.tif (if montage option selected)
```

### Image Properties

- **Format**: TIFF (Tagged Image File Format)
- **Color**: RGB (preserves original blue/purple microscopy staining)
- **Bit Depth**: 24-bit RGB
- **Scaling**: Applied to all images if enabled in configuration

## Features in Detail

### Automatic Grid Assembly

The macro automatically detects the grid dimensions from your image filenames:
- Scans all images in the `Img` folder
- Extracts row (L) and column (C) values
- Determines the maximum row and column
- Creates a montage of the correct size

**Example**: If your images range from L000C000 to L003C002:
- Grid dimensions: 4 rows × 3 columns
- Montage size: (image_height × 4) × (image_width × 3)

### Calibration Scaling

Apply universal microscope calibration to all TIFF files:

1. Check "Apply scale to all TIFF files" in the dialog
2. Enter your calibration values:
   - **Pixels per unit**: How many pixels equal one unit (e.g., 1.4 pixels/micrometer)
   - **Unit**: Measurement unit (micrometer, nanometer, pixel, etc.)
   - **Offsets**: Optional X/Y coordinate offsets

The scale metadata is embedded in each TIFF file and can be read by downstream analysis software.

### Montage Assembly

If "Create montage" is selected:
- All individual tile images are stitched into a single composite image
- Images are placed in their correct grid positions
- Maintains full resolution of original tiles
- Blue color preserved throughout assembly

## Tips & Troubleshooting

### Issue: "Montage dimensions: 1 rows x 1 cols"

**Solution**: Ensure your image filenames follow the convention `Scan_L###C###.zvi`. The macro extracts the row and column numbers from these filenames. You don't need to use `LastScan.jpg` for grid dimensions—they're auto-detected.

### Issue: Montage shows the same image repeated

**Solution**: Make sure all images in the `Img` folder are present. The macro will still create a montage even if some tiles are missing, but those positions will be empty. Check that file permissions allow reading all images.

### Issue: Images appear washed out or wrong colors

**Solution**: This indicates a Bio-Formats import issue. Ensure:
- Bio-Formats plugin is up to date (check Fiji > Help > Update FIJI)
- Original ZVI/CZI files are not corrupted
- Image files are not open in another application

### Issue: Scale not applied correctly

**Solution**: 
- Check the FIJI Log window for error messages (Windows > Show Log)
- Verify that your calibration values are correct
- Open a TIFF in FIJI and check Analyze > Set Scale to see the applied values

### Batch Processing Large Datasets

For processing many folders:
1. Organize all subfolders in a single parent directory
2. Select the parent directory at the start
3. The macro will process all subfolders sequentially
4. Monitor the Log window (Windows > Show Log) for progress

## File Size Considerations

- **Input**: CZI/ZVI files (typically 10-50 MB per image)
- **Output**: TIFF files (typically 5-15 MB per image, uncompressed)
- **Montage**: Size = (image_width × cols) × (image_height × rows)

For a 4×3 montage of 1388×1038 images: ~50 MB per montage

## Advanced Usage

### Command Line Execution

Run the macro from the command line:
```bash
fiji --run /path/to/CZI_to_TIFF_Montage.ijm
```

### Modifying the Macro

The macro is fully documented and can be edited:
1. Open in FIJI: `Plugins > Macros > Edit`
2. Or open the `.ijm` file in a text editor
3. Modify as needed and save

## Performance

Processing time depends on:
- Image size and bit depth
- Number of images per folder
- Whether montage assembly is enabled
- System RAM and disk speed

**Typical performance**: 30-60 seconds per folder (12 images, 1388×1038 resolution)

## Citation

If you use this macro in published research, please cite:
- FIJI/ImageJ (Schindelin et al., 2012)
- Bio-Formats (Linkert et al., 2010)

## Support

For issues or questions:
1. Check the Log window (Windows > Show Log) for detailed error messages
2. Verify your folder structure matches the expected format
3. Ensure all image filenames follow the `Scan_L###C###` convention
4. Test with a single subfolder first before batch processing

## Version History

- **v1.0**: Initial release with color preservation fix and auto-grid detection
- **Features**: Batch conversion, montage assembly, calibration scaling

---

**Last Updated**: June 2026
