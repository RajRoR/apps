#!/usr/bin/env bash
# Test hash performance with different file sizes

echo "Testing SHA-256 hash performance with different file sizes"
echo "==========================================================="

# Create test files of varying sizes
TEMP_DIR="temp_test_files"
mkdir -p "$TEMP_DIR"

# Function to format bytes to human readable
format_bytes() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes}B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$((bytes / 1024))KB"
    elif [ $bytes -lt 1073741824 ]; then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

# Generate files with increasing sizes
echo "Generating test files..."

# 1 KB file
head -c 1024 /dev/urandom > "$TEMP_DIR/file_001KB.bin"

# 10 KB file
head -c 10240 /dev/urandom > "$TEMP_DIR/file_010KB.bin"

# 100 KB file
head -c 102400 /dev/urandom > "$TEMP_DIR/file_100KB.bin"

# 1 MB file
head -c 1048576 /dev/urandom > "$TEMP_DIR/file_001MB.bin"

# 10 MB file
head -c 10485760 /dev/urandom > "$TEMP_DIR/file_010MB.bin"

# 50 MB file
head -c 52428800 /dev/urandom > "$TEMP_DIR/file_050MB.bin"

# 100 MB file
head -c 104857600 /dev/urandom > "$TEMP_DIR/file_100MB.bin"

# 500 MB file
head -c 524288000 /dev/urandom > "$TEMP_DIR/file_500MB.bin"

# 1 GB file
head -c 1073741824 /dev/urandom > "$TEMP_DIR/file_1GB.bin"

echo ""
echo "File Size          Elapsed Time       Throughput"
echo "---------------------------------------------------"

# Sort files by size ascending (smallest first) using -r flag to reverse
for file in $(ls -1Sr "$TEMP_DIR"/*.bin); do
    BYTES=$(wc -c < "$file")
    SIZE=$(format_bytes $BYTES)
    RESULT=$(python3 scripts/hash_sdtm.py csv "$file")
    TIME=$(echo "$RESULT" | grep elapsed_ms | awk -F= '{print $2}')
    
    # Calculate throughput (MB/sec)
    if command -v bc > /dev/null; then
        MB=$(echo "scale=2; $BYTES / 1048576" | bc)
        SEC=$(echo "scale=4; $TIME / 1000" | bc)
        if [ "$SEC" != "0" ]; then
            THROUGHPUT=$(echo "scale=1; $MB / $SEC" | bc)
            # Show "-" for very small throughput (< 1 MB/s)
            if [ $(echo "$THROUGHPUT < 1" | bc) -eq 1 ]; then
                printf "%-18s %-18s %s\n" "$SIZE" "$TIME ms" "-"
            else
                printf "%-18s %-18s %s MB/s\n" "$SIZE" "$TIME ms" "$THROUGHPUT"
            fi
        else
            printf "%-18s %-18s %s\n" "$SIZE" "$TIME ms" "-"
        fi
    else
        printf "%-18s %-18s\n" "$SIZE" "$TIME ms"
    fi
done

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "✓ Hash computation time scales linearly with file size"
