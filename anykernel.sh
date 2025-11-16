### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
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
'; }

### AnyKernel install

block=/dev/block/bootdevice/by-name/boot
is_slot_device=auto
ramdisk_compression=auto
patch_vbmeta_flag=auto

. tools/ak3-core.sh

ARCHIVE="$AKHOME/Image.7z"
EXTRACT_DIR="$AKHOME/tmp_kernel"
KERNEL_NONKSU="Image-nonksu"
KERNEL_KSU="Image-ksu"
KERNEL_SUSFS="Image-susfs"

SELECTED_KERNEL=""

# Step 1: SHA256 Verification
ui_print "==============================================="
ui_print "          VERIFYING KERNEL ARCHIVE"
ui_print "==============================================="

EXPECTED_HASH="ec3e1a48a99a7b089bb1e268aec8f3ac5a800dd13f1ac93bfd71bc69e571093e"

if [ ! -f "$ARCHIVE" ]; then
  ui_print "ERROR: Kernel archive not found!"
  exit 1
fi

ACTUAL_HASH=$(sha256sum "$ARCHIVE" | awk '{print $1}')
if [ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]; then
  ui_print "ERROR: SHA256 checksum mismatch!"
  ui_print "Expected: $EXPECTED_HASH"
  ui_print "Actual:   $ACTUAL_HASH"
  exit 1
fi
ui_print "OK: SHA256 verification passed"

# Step 2: Extract Archive
ui_print "==============================================="
ui_print "            EXTRACTING KERNEL"
ui_print "==============================================="

mkdir -p "$EXTRACT_DIR"
chmod 755 "$AKHOME/tools/7za"
ui_print "[==========          ] 33%..."
"$AKHOME/tools/7za" x "$ARCHIVE" -o"$EXTRACT_DIR"
ui_print "[==================  ] 66%..."
sleep 0.5
ui_print "[====================] 100%"
ui_print "Done: extraction complete"

# Step 3: ZIP Name Detection (with fallback)
ui_print "==============================================="
ui_print "        DETECTING KERNEL FLAVOR"
ui_print "==============================================="

[ -z "$ZIPFILE" ] && ZIPFILE="$3"
ZIP_BASENAME="${ZIPFILE##*/}"

ui_print "Zip name: $ZIP_BASENAME"
ui_print "Rules:"
ui_print "- Plain name  -> NON-KSU or manual choice"
ui_print "- RKSU-*      -> KSU"
ui_print "- SUSFS-*     -> SUSFS"

case "$ZIP_BASENAME" in
  RKSU-*)
    ui_print "Prefix detected: RKSU -> using KSU image"
    SELECTED_KERNEL="$EXTRACT_DIR/$KERNEL_KSU"
    ;;
  SUSFS-*)
    ui_print "Prefix detected: SUSFS -> using SUSFS image"
    SELECTED_KERNEL="$EXTRACT_DIR/$KERNEL_SUSFS"
    ;;
  *)
    ui_print "No prefix detected -> switching to volume key selection"
    selection=1
    ui_print " "
    ui_print "Use VOL+ to move, VOL- to select"
    ui_print "Timeout: 10 seconds"
    ui_print " "
    ui_print "1. KINESIS NON-KSU (default)"
    ui_print "2. KINESIS KSU"
    ui_print "3. KINESIS SUSFS"
    ui_print " "
    ui_print "Current: NON-KSU"

    start_time=$(date +%s)
    timeout=10

    while true; do
      keyevent=$(getevent -lc 1 2>/dev/null | grep "KEY_" | head -n 1 | awk '{print $3}')
      now=$(date +%s)
      elapsed=$((now - start_time))

      if [ "$elapsed" -ge "$timeout" ]; then
        ui_print "No input, sticking with NON-KSU"
        SELECTED_KERNEL="$EXTRACT_DIR/$KERNEL_NONKSU"
        break
      fi

      case "$keyevent" in
        KEY_VOLUMEUP)
          selection=$(((selection % 3) + 1))
          case $selection in
            1) ui_print "Current: NON-KSU" ;;
            2) ui_print "Current: KSU" ;;
            3) ui_print "Current: SUSFS" ;;
          esac
          start_time=$(date +%s)
          sleep 0.5
          ;;
        KEY_VOLUMEDOWN)
          case $selection in
            1)
              ui_print "Selected: NON-KSU"
              SELECTED_KERNEL="$EXTRACT_DIR/$KERNEL_NONKSU"
              ;;
            2)
              ui_print "Selected: KSU"
              SELECTED_KERNEL="$EXTRACT_DIR/$KERNEL_KSU"
              ;;
            3)
              ui_print "Selected: SUSFS"
              SELECTED_KERNEL="$EXTRACT_DIR/$KERNEL_SUSFS"
              ;;
          esac
          break
          ;;
      esac
    done
    ;;
esac

# Step 4: Compress Selected Kernel
ui_print "==============================================="
ui_print "         PACKING SELECTED KERNEL"
ui_print "==============================================="

if [ -f "$SELECTED_KERNEL" ]; then
  ui_print "Gzipping image..."
  gzip -c "$SELECTED_KERNEL" > "$AKHOME/Image.gz"
  ui_print "Success: Image.gz ready"
else
  ui_print "ERROR: Selected kernel image not found!"
  rm -rf "$EXTRACT_DIR"
  exit 1
fi

# Step 5: Clean Temporary Files
ui_print "==============================================="
ui_print "           CLEANING TEMPORARY FILES"
ui_print "==============================================="

rm -rf "$EXTRACT_DIR"
ui_print "Cleanup done"

boot_attributes() {
  set_perm_recursive 0 0 755 644 $ramdisk/*
  set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin
}

split_boot
flash_boot
flash_dtbo