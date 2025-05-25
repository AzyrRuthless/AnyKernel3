### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# Global properties
properties() { '
kernel.string=Kinesis Kernel by Clarencelol
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
# Boot shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=auto;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

# Import core functions and setup patching (DO NOT REMOVE)
. tools/ak3-core.sh;

# Archive and dummy file definitions
ARCHIVE="$AKHOME/Image.tar.gz"
EXTRACT_DIR="$AKHOME/tmp_kernel"
KERNEL_NONKSU="Image-nonksu"
KERNEL_KSU="Image-ksu"
KERNEL_SUSFS="Image-susfs"
DUMMY_KSU="$AKHOME/ksu"
DUMMY_SUSFS="$AKHOME/susfs"
SELECTED_KERNEL=""

# Ensure temporary directory is cleaned on exit
cleanup() {
  rm -rf "$EXTRACT_DIR"
}
trap cleanup EXIT

# Step 1: Extract the archive
if [ -f "$ARCHIVE" ]; then
  ui_print "Extracting kernel archive..."
  mkdir -p "$EXTRACT_DIR"
  tar -xzf "$ARCHIVE" -C "$EXTRACT_DIR"
  ui_print "Extraction complete."
else
  ui_print "Error: Kernel archive ($ARCHIVE) not found!"
  exit 1
fi

# Step 2: Dummy file selection logic
if [ -f "$DUMMY_SUSFS" ]; then
  ui_print "SUSFS dummy file found. Using: $KERNEL_SUSFS"
  SELECTED_KERNEL="$EXTRACT_DIR/$KERNEL_SUSFS"
elif [ -f "$DUMMY_KSU" ]; then
  ui_print "KernelSU dummy file found. Using: $KERNEL_KSU"
  SELECTED_KERNEL="$EXTRACT_DIR/$KERNEL_KSU"
else
  ui_print "No dummy file found. Defaulting to: $KERNEL_NONKSU"
  SELECTED_KERNEL="$EXTRACT_DIR/$KERNEL_NONKSU"
fi

# Step 3: Validate and copy the selected kernel image
if [ -f "$SELECTED_KERNEL" ]; then
  cp "$SELECTED_KERNEL" "$AKHOME/Image.gz"
  ui_print "Selected kernel image copied to Image.gz"
else
  ui_print "Error: Selected kernel image not found!"
  exit 1
fi

# Step 4: Set boot ramdisk file permissions
boot_attributes() {
  set_perm_recursive 0 0 755 644 $ramdisk/*
  set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin
} # end attributes

# Step 5: Patch and flash boot and dtbo
split_boot
flash_boot
flash_dtbo
## end boot install
