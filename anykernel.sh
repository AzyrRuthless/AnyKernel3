### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=Kinesis Kernel by Clarencelol (Personal Fork)
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

### Encoded Device Verification
check_cmd="Z2V0cHJvcCByby5zZXJpYWxubw==" # Base64-encoded command
device_info=$(echo "$check_cmd" | base64 -d | sh) # Decode & execute
hash_check=$(echo -n "$device_info" | sha256sum | awk '{print $1}')
allowed_hash="596e94b82620c950c0c5a3e87497aa6f22496d8c7bd2b055a134a1219d27b08a"

if [ "$hash_check" != "$allowed_hash" ]; then
    echo "Error: Incompatible device!"
    exit 1
fi

### AnyKernel install
# boot shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=auto;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

# Kernel selection logic
KERNEL_NONKSU="Image-nonksu.gz"
KERNEL_KSU="Image-ksu.gz"
KSU_DUMMY_FILE="$AKHOME/ksu"

SELECTED_KERNEL=""
if [ -f "$KSU_DUMMY_FILE" ]; then
  ui_print "KSU dummy file found. Attempting to use KSU kernel."
  if [ -f "$AKHOME/$KERNEL_KSU" ]; then
    SELECTED_KERNEL=$KERNEL_KSU
    ui_print "Using KernelSU image: $KERNEL_KSU"
  else
    ui_print "KSU kernel image ($KERNEL_KSU) not found!"
    ui_print "Falling back to non-KSU kernel."
    if [ -f "$AKHOME/$KERNEL_NONKSU" ]; then
      SELECTED_KERNEL=$KERNEL_NONKSU
      ui_print "Using non-KernelSU image: $KERNEL_NONKSU"
    else
      ui_print "Non-KSU kernel image ($KERNEL_NONKSU) also not found!"
      ui_print "Aborting: No suitable kernel image found."
      exit 1
    fi
  fi
else
  ui_print "KSU dummy file not found. Using non-KSU kernel."
  if [ -f "$AKHOME/$KERNEL_NONKSU" ]; then
    SELECTED_KERNEL=$KERNEL_NONKSU
    ui_print "Using non-KernelSU image: $KERNEL_NONKSU"
  else
    ui_print "Non-KSU kernel image ($KERNEL_NONKSU) not found!"
    ui_print "Falling back to KSU kernel."
    if [ -f "$AKHOME/$KERNEL_KSU" ]; then
      SELECTED_KERNEL=$KERNEL_KSU
      ui_print "Using KernelSU image: $KERNEL_KSU"
    else
      ui_print "KSU kernel image ($KERNEL_KSU) also not found!"
      ui_print "Aborting: No suitable kernel image found."
      exit 1
    fi
  fi
fi

if [ -n "$SELECTED_KERNEL" ]; then
  if [ -f "$AKHOME/$SELECTED_KERNEL" ]; then # Double check before copying
    cp "$AKHOME/$SELECTED_KERNEL" "$AKHOME/Image.gz"
    ui_print "Selected kernel ($SELECTED_KERNEL) copied to Image.gz"
  else
    # This case should ideally be caught by the logic above, but as a safeguard:
    ui_print "Error: Selected kernel image ($SELECTED_KERNEL) not found before copy."
    ui_print "Aborting due to missing selected kernel."
    exit 1
  fi
else
  # This case should also be caught by the logic above.
  ui_print "Error: No kernel was selected. This should not happen."
  ui_print "Aborting due to logic error in kernel selection."
  exit 1
fi

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;
} # end attributes

## AnyKernel boot install
split_boot;

flash_boot;
flash_dtbo;
## end boot install
