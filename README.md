# CZI/ZVI to TIFF Montage Converter

A FIJI/ImageJ macro that batch-converts CZI/ZVI microscopy images to TIFF and stitches them into montages based on a folder structure of scan tiles.

## Folder Structure Expected

```
Main Folder
  └── Subfolder 1
        ├── Img/              (contains .zvi or .czi files)
        └── LastScan.jpg       (used to determine grid dimensions)
  └── Subfolder 2
        └── ... etc
```

For each subfolder, the macro creates a `TIFF/` folder containing the converted images and (optionally) a `Montage.tif`.

## Installation

1. Open FIJI/ImageJ.
2. Go to `Plugins > Macros > Install...` and select `CZI_to_TIFF_Montage.ijm`, **or** just drag-and-drop the `.ijm` file onto the FIJI toolbar and click "Run" in the editor window that opens.
3. Make sure the **Bio-Formats** plugin is installed (bundled with FIJI by default).

## Usage

1. Run the macro.
2. In the dialog:
   - **Main directory** — select the top-level folder containing your subfolders.
   - **File extension** — `zvi` or `czi` depending on your raw files.
   - **Create montage** — stitches all tiles into a single `Montage.tif` per subfolder.
   - **Apply scale** — sets a pixel-to-unit calibration on saved TIFFs/montage.
   - **Pixels per unit / Unit of measurement / X-Y offset** — calibration parameters (only used if "Apply scale" is checked).
   - **Cleanup options**:
     - *Delete Img subfolders after conversion* — removes the raw `Img/` folder once its files are converted.
     - *Delete individual TIFF files after montage is created* — keeps only `Montage.tif`, removing the per-tile TIFFs (requires "Create montage" to be enabled).
3. If either cleanup option is checked, you'll get a confirmation prompt before anything is deleted — **these actions are irreversible**, so double check your selections.
4. Progress and any skipped folders are logged to the ImageJ **Log** window as it runs.

## Notes

- Subfolders missing an `Img/` folder or `LastScan.jpg` are skipped automatically (logged, not an error).
- Grid row/column position for each tile is parsed from filename patterns containing `L###` (row) and `C###` (column).
- Cleanup deletions only run after their corresponding step succeeds (TIFF conversion for Img deletion; montage save for individual TIFF deletion).
