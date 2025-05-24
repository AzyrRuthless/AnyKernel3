## Multi-Kernel Flashing with AnyKernel3

This AnyKernel3 script has been enhanced to support flashing a user-selected kernel to the BOOT partition and, optionally, a separate, predefined kernel to the RECOVERY partition.

### Overview

The new multi-kernel flashing capability allows you to package multiple kernel images for the BOOT partition within a single AnyKernel3 zip. If more than one such kernel is found, you will be prompted during the flashing process in your recovery (e.g., TWRP) to choose which one to install. Additionally, you can include a specific kernel image that will be automatically flashed to your RECOVERY partition.

### Image Naming Conventions

To utilize this feature, your kernel image files must adhere to specific naming patterns and be placed in the root directory of the AnyKernel.zip file:

*   **For BOOT Partition Selection:**
    *   Kernel images intended for the BOOT partition, from which you can select one during installation, must be named following the pattern: `Image-*.gz-dtb`.
    *   Examples: `Image-MyAwesomeKernel.gz-dtb`, `Image-SuperStable-v1.2.gz-dtb`, `Image-GamingPerformance.gz-dtb`.
    *   The part of the filename represented by `*` will be used to identify the kernel in the selection menu.

*   **For RECOVERY Partition (Optional):**
    *   If you wish to flash a separate kernel to the RECOVERY partition automatically, this image must be named exactly: `Image-recovery.gz-dtb`.
    *   This image will be flashed to the RECOVERY partition independently of the BOOT kernel selection process. If this file is not present, the RECOVERY partition will not be modified.

### Selection Process (for Multiple BOOT Kernels)

The script handles the selection of the BOOT kernel as follows:

1.  **Automatic Selection:** If only one kernel file matching the `Image-*.gz-dtb` pattern (excluding `Image-recovery.gz-dtb`) is found in the zip root, it will be automatically selected and flashed to the BOOT partition. No user interaction will be required for selection.

2.  **User Selection (Multiple Kernels Found):** If multiple kernel files matching `Image-*.gz-dtb` are found, the script will initiate a user selection process:
    *   A numbered list of the available BOOT kernels will be displayed on your recovery screen (via `ui_print` messages).
    *   You will be instructed to create a temporary file named `/tmp/ak_selection.txt` on your device. This can typically be done using the File Manager feature within your recovery (e.g., TWRP: Advanced > File Manager).
    *   Inside `/tmp/ak_selection.txt`, you should write the number corresponding to the kernel you wish to flash from the displayed list (e.g., if you want the first kernel, write `1`; for the second, write `2`, and so on).
    *   You will have approximately **30 seconds** to create and save this file with your selection.
    *   **Default Behavior:** If the `/tmp/ak_selection.txt` file is not created within the time limit, or if its content is invalid (e.g., empty, not a number, or a number out of range), the script will automatically default to flashing the *first kernel* that appeared in the numbered list.
    *   The `ui_print` messages from the script will clearly indicate which kernel is being selected, whether by user choice or by default.

### Flashing Process

1.  **BOOT Partition:** The kernel image that was either automatically selected, chosen by you, or selected by default will be flashed to your device's BOOT partition.
2.  **RECOVERY Partition:** If an image named `Image-recovery.gz-dtb` is present in the root of the zip, it will be flashed to your device's RECOVERY partition. This occurs after the BOOT kernel has been flashed.

### Example Usage

Consider the following structure for your `MyCustomKernels.zip`:

```
MyCustomKernels.zip/
├── anykernel.sh                # The main AnyKernel3 script
├── META-INF/                   # Standard Android update-zip directory
│   └── com/
│       └── google/
│           └── android/
│               ├── update-binary
│               └── ...
├── tools/                      # AnyKernel3 helper tools
├── ramdisk/                    # Ramdisk modifications (if any)
├── patch/                      # Patch files (if any)
├── Image-StableBuild.gz-dtb    # First BOOT kernel option
├── Image-PerfTune.gz-dtb       # Second BOOT kernel option
└── Image-recovery.gz-dtb       # Kernel for the RECOVERY partition
```

**Scenario: Flashing `Image-PerfTune.gz-dtb`**

1.  When you flash `MyCustomKernels.zip` in TWRP:
2.  The script will detect `Image-StableBuild.gz-dtb` and `Image-PerfTune.gz-dtb`.
3.  It will display:
    ```
    Multiple BOOT kernel images found. Please choose one:
     1: Image-StableBuild.gz-dtb
     2: Image-PerfTune.gz-dtb
    (Instructions to create /tmp/ak_selection.txt will follow)
    ```
4.  You navigate to TWRP's File Manager, go to `/tmp`, create `ak_selection.txt`, and type `2` into it, then save.
5.  The script will detect your choice and proceed to flash `Image-PerfTune.gz-dtb` to the BOOT partition.
6.  After that, it will automatically flash `Image-recovery.gz-dtb` to the RECOVERY partition.

If you had not created `/tmp/ak_selection.txt`, or if you entered an invalid choice, the script would have defaulted to flashing `Image-StableBuild.gz-dtb` (as it's the first in the list).
