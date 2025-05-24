### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=Kinesis Kernel by Clarencelol (User Selectable)
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=miatoll
device.name2=curtana
device.name3=excalibur
device.name4=gram
device.name5=joyeuse
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install
# boot shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=auto;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;
} # end attributes

## AnyKernel Kernel Selection and Installation
#
# Kernel Image Naming Convention:
# - For BOOT partition: Place images named `Image-*.gz-dtb` in the zip root.
#   (e.g., Image-MyKernel-v1.gz-dtb, Image-Experimental.gz-dtb)
# - For RECOVERY partition (optional): Place an image named `Image-recovery.gz-dtb` in the zip root.
#
# Selection Process (if multiple BOOT images found):
# 1. A numbered list of available BOOT images will be displayed.
# 2. User will be prompted to create a file `/tmp/ak_selection.txt` with the number of their choice.
# 3. The script waits 30 seconds for this file.
# 4. If a valid choice is made, that kernel is flashed.
# 5. If no choice is made, or the choice is invalid, the first image found alphabetically will be flashed by default.
#

ui_print " "
ui_print "Kernel Image Selection:"
ui_print "-----------------------"
ui_print "Looking for kernel images (Image-*.gz-dtb)..."

# Discover kernel images for BOOT partition
cd $AKHOME
_found_files=($(ls Image-*.gz-dtb 2>/dev/null)) # Get all matching files
kernel_images_for_boot=() # Initialize array for boot kernels
image_count=0

for f in "${_found_files[@]}"; do
  if [ "$f" != "Image-recovery.gz-dtb" ]; then # Exclude the dedicated recovery image
    kernel_images_for_boot+=("$f")
    image_count=$((image_count + 1))
  fi
done
cd - >/dev/null # Go back to previous directory (usually $AKHOME or /tmp/anykernel)

selected_boot_kernel=""

if [ "$image_count" -eq 0 ]; then
  ui_print "No main kernel images (Image-*.gz-dtb) found in zip!"
  ui_print "(Excluding Image-recovery.gz-dtb from this check)."
  abort "Aborting: No main kernel image to flash to BOOT."
elif [ "$image_count" -eq 1 ]; then
  selected_boot_kernel="${kernel_images_for_boot[0]}"
  ui_print "Only one main kernel image found: $selected_boot_kernel"
  ui_print "Proceeding to flash $selected_boot_kernel to BOOT."
else
  ui_print "Multiple BOOT kernel images found. Please choose one:"
  idx=0
  for img_name in "${kernel_images_for_boot[@]}"; do
    idx=$((idx + 1))
    ui_print " $idx: $img_name"
  done
  ui_print " "
  ui_print "HOW TO CHOOSE (You have 30 seconds):"
  ui_print "1. In TWRP: Advanced > File Manager."
  ui_print "2. Navigate to /tmp directory."
  ui_print "3. Create a new file named 'ak_selection.txt'."
  ui_print "4. Edit 'ak_selection.txt', enter the number of your choice, and save."
  ui_print "   (e.g., '1' for the first image, '2' for the second)."
  ui_print " "
  ui_print "DEFAULT: If no valid selection, '${kernel_images_for_boot[0]}' will be flashed."

  ui_print "Waiting 30 seconds for your selection..."
  sleep 30

  user_choice_file="/tmp/ak_selection.txt"
  if [ -f "$user_choice_file" ]; then
    choice_num=$(cat "$user_choice_file" | tr -dc '0-9') # Read only numbers
    rm -f "$user_choice_file" # Clean up selection file

    if [ -n "$choice_num" ] && [ "$choice_num" -gt 0 ] && [ "$choice_num" -le "$image_count" ]; then
      selected_boot_kernel="${kernel_images_for_boot[$((choice_num - 1))]}"
      ui_print "User selected for BOOT: $selected_boot_kernel"
    else
      ui_print "Invalid selection in $user_choice_file."
      selected_boot_kernel="${kernel_images_for_boot[0]}"
      ui_print "Flashing default for BOOT: $selected_boot_kernel"
    fi
  else
    ui_print "No selection file ($user_choice_file) found."
    selected_boot_kernel="${kernel_images_for_boot[0]}"
    ui_print "Flashing default for BOOT: $selected_boot_kernel"
  fi
fi
ui_print "-----------------------"
ui_print " "

# Ensure a boot kernel was selected
if [ -z "$selected_boot_kernel" ]; then
  abort "Critical Error: No BOOT kernel was selected or defaulted. Aborting."
fi

# Prepare the selected BOOT kernel for flashing
ui_print "Preparing to flash '$selected_boot_kernel' to BOOT partition..."
if [ -f $AKHOME/Image.gz-dtb ]; then # Clean up if a previous Image.gz-dtb exists
  rm -f $AKHOME/Image.gz-dtb
fi
mv "$AKHOME/$selected_boot_kernel" $AKHOME/Image.gz-dtb # Rename selected kernel to standard name

# Standard AnyKernel boot install for the selected BOOT kernel
# Ensure 'block' variable points to the boot partition (usually set by default)
# Example: block=/dev/block/bootdevice/by-name/boot; (or let ak3-core.sh auto-detect)
# `is_slot_device=auto` should handle slot if applicable.

ui_print "Flashing '$selected_boot_kernel' to BOOT partition..."
split_boot;
flash_boot;
flash_dtbo; # Flash corresponding DTBO for the boot partition
ui_print "'$selected_boot_kernel' flashed to BOOT successfully."
ui_print " "


# --- Secondary RECOVERY Image Flashing Logic ---
# This part flashes 'Image-recovery.gz-dtb' to the recovery partition if it exists.
# This is independent of the BOOT kernel selection.

recovery_kernel_src_path="$AKHOME/Image-recovery.gz-dtb"
if [ -f "$recovery_kernel_src_path" ]; then
  ui_print "Dedicated RECOVERY kernel (Image-recovery.gz-dtb) found."
  ui_print "Preparing to flash it to RECOVERY partition..."

  # The file $AKHOME/Image.gz-dtb currently is the flashed BOOT kernel.
  # We need to rename it so it's not accidentally reused or overwritten yet.
  if [ -f $AKHOME/Image.gz-dtb ]; then
    mv $AKHOME/Image.gz-dtb "$AKHOME/$selected_boot_kernel.flashed_to_boot"
  fi
  
  # Now, rename the recovery kernel to Image.gz-dtb for flashing
  mv "$recovery_kernel_src_path" $AKHOME/Image.gz-dtb

  # Set up for recovery partition
  block=recovery; # Target the recovery partition
  ramdisk_compression=auto; # Or specific if known for the recovery image

  ui_print "Resetting AnyKernel for RECOVERY partition flash..."
  reset_ak; # Crucial step to reset context for the new partition and image

  ui_print "Flashing 'Image-recovery.gz-dtb' to RECOVERY partition..."
  split_boot; # Process the recovery image (now named Image.gz-dtb)
  flash_boot; # Flash it to the recovery partition
  # flash_dtbo; # Optional: if the recovery kernel has its own DTBO for the recovery's DTBO partition.
              # This usually shares the main dtbo partition or doesn't exist. Manage if needed.

  ui_print "'Image-recovery.gz-dtb' flashed to RECOVERY successfully."

  # Clean up after recovery flash
  if [ -f $AKHOME/Image.gz-dtb ]; then # This is the recovery image that was just flashed
    rm -f $AKHOME/Image.gz-dtb
  fi
  # Restore the original name of the boot kernel image (optional, good for housekeeping)
  if [ -f "$AKHOME/$selected_boot_kernel.flashed_to_boot" ]; then
    mv "$AKHOME/$selected_boot_kernel.flashed_to_boot" "$AKHOME/$selected_boot_kernel"
  fi
else
  ui_print "No dedicated RECOVERY kernel (Image-recovery.gz-dtb) found. Skipping RECOVERY flash."
fi

ui_print " "
ui_print "AnyKernel flashing process complete."
## end boot install