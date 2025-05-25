### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
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
# boot shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=auto;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# Kernel selection logic
KERNEL_NONKSU="Image-nonksu.gz"
KERNEL_KSU="Image-ksu.gz"
KERNEL_SUSFS="Image-susfs.gz"

DUMMY_KSU="$AKHOME/ksu"
DUMMY_SUSFS="$AKHOME/susfs"

SELECTED_KERNEL=""

if [ -f "$DUMMY_SUSFS" ]; then
  ui_print "SUSFS dummy file found. Attempting to use SUSFS kernel."
  if [ -f "$AKHOME/$KERNEL_SUSFS" ]; then
    SELECTED_KERNEL=$KERNEL_SUSFS
    ui_print "Using SUSFS image: $KERNEL_SUSFS"
  else
    ui_print "SUSFS kernel image ($KERNEL_SUSFS) not found!"
    ui_print "Falling back to KSU kernel..."
    if [ -f "$DUMMY_KSU" ] && [ -f "$AKHOME/$KERNEL_KSU" ]; then
      SELECTED_KERNEL=$KERNEL_KSU
      ui_print "Using KernelSU image: $KERNEL_KSU"
    elif [ -f "$AKHOME/$KERNEL_NONKSU" ]; then
      SELECTED_KERNEL=$KERNEL_NONKSU
      ui_print "Using non-KernelSU image: $KERNEL_NONKSU"
    else
      ui_print "No suitable kernel image found!"
      exit 1
    fi
  fi

elif [ -f "$DUMMY_KSU" ]; then
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
      ui_print "Non-KSU kernel image ($KERNEL_NONKSU) not found!"
      ui_print "Aborting: No suitable kernel image found."
      exit 1
    fi
  fi

else
  ui_print "No dummy file found. Using non-KSU kernel by default."
  if [ -f "$AKHOME/$KERNEL_NONKSU" ]; then
    SELECTED_KERNEL=$KERNEL_NONKSU
    ui_print "Using non-KernelSU image: $KERNEL_NONKSU"
  else
    ui_print "Non-KSU kernel image ($KERNEL_NONKSU) not found!"
    ui_print "Falling back to KernelSU kernel."
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
  if [ -f "$AKHOME/$SELECTED_KERNEL" ]; then
    cp "$AKHOME/$SELECTED_KERNEL" "$AKHOME/Image.gz"
    ui_print "Selected kernel ($SELECTED_KERNEL) copied to Image.gz"
  else
    ui_print "Error: Selected kernel image ($SELECTED_KERNEL) not found before copy."
    exit 1
  fi
else
  ui_print "Error: No kernel was selected. This should not happen."
  exit 1
fi

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
