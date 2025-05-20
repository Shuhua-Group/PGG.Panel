#!/bin/bash

# 定义shapeit5工具路径
SHAPEIT_DIR="/home/sunyumeng/software/shapeit5.1.1"

# 默认参数
THREADS=1
SPARSE_MAF=0.01
FILTER_MAF=0.01

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--input) INPUT_VCF="$2"; shift ;;
        -m|--map) MAP_FILE="$2"; shift ;;
        -c|--chr) CHR="$2"; shift ;;
        -o|--output-prefix) OUTPUT_PREFIX="$2"; shift ;;
        -t|--threads) THREADS="$2"; shift ;;
        --sparse-maf) SPARSE_MAF="$2"; shift ;;
        --filter-maf) FILTER_MAF="$2"; shift ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z "$INPUT_VCF" || -z "$MAP_FILE" || -z "$CHR" || -z "$OUTPUT_PREFIX" ]]; then
    echo "用法: $0 --input <input.vcf.gz> --map <map_file> --chr <chromosome> --output-prefix <prefix> [选项]"
    echo "选项:"
    echo "  -t, --threads <num>       线程数 (默认: 1)"
    echo "  --sparse-maf <value>      Sparse MAF阈值 (默认: 0.01)"
    echo "  --filter-maf <value>      Filter MAF阈值 (默认: 0.01)"
    exit 1
fi

# echo "=== 步骤1/5: 生成分块文件 ==="
CHUNKS_FILE="${OUTPUT_PREFIX}_chunks.txt"
"$SHAPEIT_DIR/GLIMPSE2_chunk_static" --input "$INPUT_VCF" \
                                     --map "$MAP_FILE" \
                                     --sparse-maf "$SPARSE_MAF" \
                                     --region "$CHR" \
                                     --sequential \
                                     --threads "$THREADS" \
                                     --output "$CHUNKS_FILE" || exit 1

if [ ! -s "$CHUNKS_FILE" ]
then
    echo "=== no need to use the chunk program ==="

    echo "=== 步骤2/5: 处理常见变异 ==="
    OUT_BCF="${OUTPUT_PREFIX}.shapeit5_common.bcf"
    OUT_LOG="${OUTPUT_PREFIX}.shapeit5_common.log"
    
    "$SHAPEIT_DIR/phase_common_static" --input "$INPUT_VCF" \
                                      --map "$MAP_FILE" \
                                      --output "$OUT_BCF" \
                                      --thread "$THREADS" \
                                      --log "$OUT_LOG" \
                                      --filter-maf "$FILTER_MAF" \
                                      --region "$CHR" || exit 1

    echo "=== skip 步骤3/5: 合并常见变异 ==="
    COMMON_BCF="${OUTPUT_PREFIX}.shapeit5_common.bcf"

    echo "=== 步骤4/5: 处理稀有变异 ==="
    OUT_BCF="${OUTPUT_PREFIX}.shapeit5_rare.bcf"
    OUT_LOG="${OUTPUT_PREFIX}.shapeit5_rare.log"
    
    echo "处理稀有变异分块 $CHUNK_NBR"
    CHROM_LENGTHS=(248956422 242193529 198295559 190214555 181538259 170805979 159345973 145138636 138394717 133797422 135086622 133275309 114364328 107043718 101991189 90338345 83257441 80373285 58617616 64444167 46709983 50818468)
    k=`echo "$CHR"|sed  's/chr//'`
    "$SHAPEIT_DIR/phase_rare_static" --input "$INPUT_VCF" \
                                    --map "$MAP_FILE" \
                                    --output "$OUT_BCF" \
                                    --thread "$THREADS" \
                                    --log "$OUT_LOG" \
                                    --scaffold "$COMMON_BCF" \
                                    --input-region "$CHR:1-${CHROM_LENGTHS[$(($k-1))]}" \
                                    --scaffold-region "$CHR:1-${CHROM_LENGTHS[$(($k-1))]}" || exit 1
    echo "=== 步骤5/5: 生成最终结果 ==="
    FINAL_BCF="${OUTPUT_PREFIX}.shapeit5_rare.bcf"

    # 格式转换
    FINAL_VCF="${OUTPUT_PREFIX}.shapeit5.final.vcf.gz"
    bcftools view -Oz -o "$FINAL_VCF" "$FINAL_BCF" --threads "$THREADS" || exit 1
    tabix -p vcf "$FINAL_VCF" || exit 1

    FINAL_RMPP_VCF="${OUTPUT_PREFIX}.shapeit5.final.rmPP.vcf.gz"
    bcftools annotate -x FORMAT/PP -O z -o "$FINAL_RMPP_VCF" "$FINAL_VCF" || exit 1
    tabix -p vcf "$FINAL_RMPP_VCF" || exit 1

    echo "处理完成！最终结果："
    echo "- 移除PP字段结果: $FINAL_RMPP_VCF"

    exit 0
fi

echo "=== 步骤2/5: 处理常见变异 ==="
while IFS= read -r LINE; do
    REG=$(echo "$LINE" | awk '{print $3}')
    CHUNK_NBR=$(echo "$LINE" | awk '{print $1}')
    
    OUT_BCF="${OUTPUT_PREFIX}.shapeit5_common_${CHUNK_NBR}.bcf"
    OUT_LOG="${OUTPUT_PREFIX}.shapeit5_common_${CHUNK_NBR}.log"
    
    echo "处理分块 $CHUNK_NBR: $REG"
    "$SHAPEIT_DIR/phase_common_static" --input "$INPUT_VCF" \
                                      --map "$MAP_FILE" \
                                      --output "$OUT_BCF" \
                                      --thread "$THREADS" \
                                      --log "$OUT_LOG" \
                                      --filter-maf "$FILTER_MAF" \
                                      --region "$REG" || exit 1
done < "$CHUNKS_FILE"

echo "=== 步骤3/5: 合并常见变异 ==="
LIGATE_LIST="${OUTPUT_PREFIX}_ligate.list"
ls -1v "${OUTPUT_PREFIX}.shapeit5_common_"*.bcf > "$LIGATE_LIST"

COMMON_BCF="${OUTPUT_PREFIX}.shapeit5_common.bcf"
"$SHAPEIT_DIR/ligate_static" --input "$LIGATE_LIST" \
                             --output "$COMMON_BCF" \
                             --thread "$THREADS" || exit 1
bcftools index -f "$COMMON_BCF" --threads "$THREADS" || exit 1

echo "=== 步骤4/5: 处理稀有变异 ==="
while IFS= read -r LINE; do
    CHUNK_NBR=$(echo "$LINE" | awk '{print $1}')
    SCAFFOLD_REG=$(echo "$LINE" | awk '{print $3}')
    INPUT_REG=$(echo "$LINE" | awk '{print $4}')

    OUT_BCF="${OUTPUT_PREFIX}.shapeit5_rare_${CHUNK_NBR}.bcf"
    OUT_LOG="${OUTPUT_PREFIX}.shapeit5_rare_${CHUNK_NBR}.log"
    
    echo "处理稀有变异分块 $CHUNK_NBR"
    "$SHAPEIT_DIR/phase_rare_static" --input "$INPUT_VCF" \
                                    --map "$MAP_FILE" \
                                    --output "$OUT_BCF" \
                                    --thread "$THREADS" \
                                    --log "$OUT_LOG" \
                                    --scaffold "$COMMON_BCF" \
                                    --scaffold-region "$SCAFFOLD_REG" \
                                    --input-region "$INPUT_REG" || exit 1
done < "$CHUNKS_FILE"

echo "=== 步骤5/5: 生成最终结果 ==="
CONCAT_LIST="${OUTPUT_PREFIX}_concat.list"
ls -1v "${OUTPUT_PREFIX}.shapeit5_rare_"*.bcf > "$CONCAT_LIST"

FINAL_BCF="${OUTPUT_PREFIX}.shapeit5.final.bcf"
bcftools concat -n -f "$CONCAT_LIST" -o "$FINAL_BCF" --threads "$THREADS" || exit 1

# 格式转换
FINAL_VCF="${OUTPUT_PREFIX}.shapeit5.final.vcf.gz"
bcftools view -Oz -o "$FINAL_VCF" "$FINAL_BCF" --threads "$THREADS" || exit 1
tabix -p vcf "$FINAL_VCF" || exit 1

FINAL_RMPP_VCF="${OUTPUT_PREFIX}.shapeit5.final.rmPP.vcf.gz"
bcftools annotate -x FORMAT/PP -O z -o "$FINAL_RMPP_VCF" "$FINAL_VCF" || exit 1
tabix -p vcf "$FINAL_RMPP_VCF" || exit 1

echo "处理完成！最终结果："
echo "- 移除PP字段结果: $FINAL_RMPP_VCF"