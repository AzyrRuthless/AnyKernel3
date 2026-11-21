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

### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# boot shell variables
BLOCK=/dev/block/bootdevice/by-name/boot;
IS_SLOT_DEVICE=auto;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

### Encoded Device Verification
check_cmd="Z2V0cHJvcCByby5zZXJpYWxubw==" # Base64-encoded command
device_info=$(echo "$check_cmd" | base64 -d | sh) # Decode & execute
hash_check=$(echo -n "$device_info" | sha256sum | awk '{print $1}')
allowed_hash="596e94b82620c950c0c5a3e87497aa6f22496d8c7bd2b055a134a1219d27b08a"

if [ "$hash_check" != "$allowed_hash" ]; then
    ui_print " "
    ui_print "Error: Incompatible hardware serial detected!"
    abort
fi

## AnyKernel boot install
split_boot;

flash_boot;
flash_generic dtbo;
## end boot install
