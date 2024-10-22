# This script performs initial configuration, unit test fw build and
# execution on QEMU, producing .xml tests report in JUNIT format

# Stop keywords definition
KEYWORD_OK="OK"
KEYWORD_FAIL="FAIL"
KEYWORD_RETURN="main_task: Returned from app_main()"

# export
source /opt/esp/idf/export.sh
export PATH=/opt/qemu/bin:${PATH}

# Build test binaries
idf.py build

# Create united binary file for launch on QEMU
esptool.py --chip esp32s3 merge_bin -o result.bin --fill-flash-size 2MB \
    --flash_mode dio --flash_freq 40m --flash_size 2MB \
    0x0 build/bootloader/bootloader.bin \
    0x8000 build/partition_table/partition-table.bin \
    0x10000 build/smartoven_firmware_test.bin

# Run units tests on QEMU with forced quit after keyphrase
qemu-system-xtensa -nographic -serial mon:stdio -monitor null -machine esp32s3 -drive file=result.bin,if=mtd,format=raw | while IFS= read -r line; do
    echo "$line" >> tests_results.txt # Write line in a file
    if [[ "$line" == *"$KEYWORD_RETURN"* ]]; then
        # Stop the command
        pkill -f "qemu-system-xtensa"
        echo "Command was stopped after keyphrase was detected"
        break
    fi
done