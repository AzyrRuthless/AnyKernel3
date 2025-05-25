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
'; }

### AnyKernel install
# boot shell variables
block=/dev/block/bootdevice/by-name/boot
is_slot_device=auto
ramdisk_compression=auto
patch_vbmeta_flag=auto

# import functions/variables and setup patching
. tools/ak3-core.sh

# Archive and kernel image definitions
ARCHIVE="$AKHOME/Image.7z"
EXTRACT_DIR="$AKHOME/tmp_kernel"
KERNEL_NONKSU="Image-nonksu"
KERNEL_KSU="Image-ksu"
KERNEL_SUSFS="Image-susfs"

# Dummy files
DUMMY_NONKSU="$AKHOME/NONKSU"
DUMMY_KSU="$AKHOME/KSU"
DUMMY_SUSFS="$AKHOME/SUSFS"

SELECTED_KERNEL=""

# ================================================
# Step 1: SHA256 Verification
# ================================================
ui_print "==============================================="
ui_print "         VERIFYING KERNEL ARCHIVE (HASH)"
ui_print "==============================================="

EXPECTED_HASH="ec3e1a48a99a7b089bb1e268aec8f3ac5a800dd13f1ac93bfd71bc69e571093e"

if [ ! -f "$ARCHIVE" ]; then
  ui_print "ERROR: Kernel archive not found!"
  exit 1
fi

ACTUAL_HASH=$(sha256sum "$ARCHIVE" | awk '{print $1}')
if [ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]; then
  ui_print "ERROR: SHA256 checksum mismatch!"
  ui_print "EXPECTED: $EXPECTED_HASH"
  ui_print "ACTUAL:   $ACTUAL_HASH"
  exit 1
fi
ui_print "PASS: SHA256 verification successful"

# ================================================
# Step 2: Extract Archive
# ================================================
ui_print "==============================================="
ui_print "          EXTRACTING KERNEL ARCHIVE"
ui_print "==============================================="

mkdir -p "$EXTRACT_DIR"
chmod 755 "$AKHOME/tools/7za"
ui_print "[==========          ] 33%..."
"$AKHOME/tools/7za" x "$ARCHIVE" -o"$EXTRACT_DIR"
ui_print "[==================  ] 66%..."
sleep 0.5
ui_print "[====================] 100%"
ui_print "DONE: Extraction complete"

# ================================================
# Step 3: Dummy File Detection
# ================================================
ui_print "==============================================="
ui_print "             DETECTING KERNEL TYPE"
ui_print "==============================================="

count=0
[ -f "$DUMMY_NONKSU" ] && count=$((count + 1))
[ -f "$DUMMY_KSU" ] && count=$((count + 1))
[ -f "$DUMMY_SUSFS" ] && count=$((count + 1))

if [ "$count" -gt 1 ]; then
  ui_print "ERROR: More than one dummy trigger found!"
  rm -rf "$EXTRACT_DIR"
  exit 1
elif [ "$count" -eq 1 ]; then
  if [ -f "$DUMMY_KSU" ]; then
    ui_print "TRIGGER DETECTED: KSU -> Using $KERNEL_KSU"
    SELECTED_KERNEL="$EXTRACT_DIR/$KERNEL_KSU"
  elif [ -f "$DUMMY_SUSFS" ]; then
    ui_print "TRIGGER DETECTED: SUSFS -> Using $KERNEL_SUSFS"
    SELECTED_KERNEL="$EXTRACT_DIR/$KERNEL_SUSFS"
  else
    ui_print "TRIGGER DETECTED: NONKSU -> Using $KERNEL_NONKSU"
    SELECTED_KERNEL="$EXTRACT_DIR/$KERNEL_NONKSU"
  fi
else
  # ================================================
  # Step 4: Volume Key Selector
  # ================================================
  ui_print "==============================================="
  ui_print "         VOLUME KEY SELECTION MODE"
  ui_print "==============================================="

  selection=1
  ui_print " "
  ui_print "USE VOLUME + TO CYCLE, VOLUME - TO SELECT"
  ui_print "TIMEOUT: 10 SECONDS"
  ui_print " "
  ui_print "1. KINESIS NON-KSU (DEFAULT)"
  ui_print "2. KINESIS KSU"
  ui_print "3. KINESIS SUSFS"
  ui_print " "
  ui_print "CURRENT SELECTION: NON-KSU"

  start_time=$(date +%s)
  timeout=10

  while true; do
    keyevent=$(getevent -lc 1 2>/dev/null | grep "KEY_" | head -n 1 | awk '{print $3}')
    now=$(date +%s)
    elapsed=$((now - start_time))

    if [ "$elapsed" -ge "$timeout" ]; then
      ui_print "TIMEOUT REACHED. ABORTING!"
      rm -rf "$EXTRACT_DIR"
      exit 1
    fi

    case "$keyevent" in
    KEY_VOLUMEUP)
      selection=$(((selection % 3) + 1))
      case $selection in
      1) ui_print "CURRENT SELECTION: NON-KSU" ;;
      2) ui_print "CURRENT SELECTION: KSU" ;;
      3) ui_print "CURRENT SELECTION: SUSFS" ;;
      esac
      start_time=$(date +%s)
      sleep 0.5
      ;;
    KEY_VOLUMEDOWN)
      case $selection in
      1)
        ui_print "SELECTED: NON-KSU"
        SELECTED_KERNEL="$EXTRACT_DIR/$KERNEL_NONKSU"
        ;;
      2)
        ui_print "SELECTED: KSU"
        SELECTED_KERNEL="$EXTRACT_DIR/$KERNEL_KSU"
        ;;
      3)
        ui_print "SELECTED: SUSFS"
        SELECTED_KERNEL="$EXTRACT_DIR/$KERNEL_SUSFS"
        ;;
      esac
      break
      ;;
    esac
  done
fi

# ================================================
# Step 5: Compress Selected Kernel
# ================================================
ui_print "==============================================="
ui_print "        COMPRESSING SELECTED KERNEL"
ui_print "==============================================="

if [ -f "$SELECTED_KERNEL" ]; then
  ui_print "GZIPPING IMAGE..."
  gzip -c "$SELECTED_KERNEL" > "$AKHOME/Image.gz"
  ui_print "SUCCESS: IMAGE SAVED AS Image.gz"
else
  ui_print "ERROR: SELECTED KERNEL IMAGE NOT FOUND"
  rm -rf "$EXTRACT_DIR"
  exit 1
fi

# ================================================
# Step 6: Clean Temporary Files
# ================================================
ui_print "==============================================="
ui_print "           CLEANING TEMPORARY FILES"
ui_print "==============================================="

rm -rf "$EXTRACT_DIR"

## boot files attributes
boot_attributes() {
  set_perm_recursive 0 0 755 644 $ramdisk/*
  set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin
}

## AnyKernel boot install
split_boot

flash_boot
flash_dtbo
## end boot install