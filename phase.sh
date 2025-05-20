#!/bin/bash

i=$1

prefix='POP_zyHan_HXDL'
qc='VQSR' #qc=filtered
script='/home/sunyumeng/script/shapeit5.sh'
map="/home/sunyumeng/software/shapeit4-4.2.2/maps/b38/chr$i.b38.gmap.gz"

vcf="../01.qc/$prefix.chr${i}.$qc.PASS.biallelic.SNPs.FM10.AC1.vcf.gz"
sh $script --input $vcf --map $map --chr chr$i --output-prefix $prefix.chr${i}.$qc.PASS.biallelic.SNPs.FM10.AC1
