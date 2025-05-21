#!/bin/bash

i=$1

vcf="/mnt/share9/gaoyang/20240807.Saile/14.POP_zyHan_HXDL/VQSR/190.variant.quality.score.recal/POP2099_HXDL_zyHan.Saile.VQSR.variants.vcf.gz"
prefix='POP_zyHan_HXDL'
qc='VQSR' #qc=filtered


bcftools view -r chr$i -f PASS -m 2 -M 2 -v snps -i 'F_MISSING<=0.1 && AC>=1  && (AN-AC)>=1' $vcf| bcftools annotate -x ^INFO/AC,^INFO/AF,^INFO/AN,^FORMAT/GT -Oz -o $prefix.chr${i}.$qc.PASS.biallelic.SNPs.FM10.AC1.vcf.gz  
tabix $prefix.chr${i}.$qc.PASS.biallelic.SNPs.FM10.AC1.vcf.gz
plink2 --vcf $prefix.chr${i}.$qc.PASS.biallelic.SNPs.FM10.AC1.vcf.gz --out $prefix.chr${i}.$qc.PASS.biallelic.SNPs.FM10.AC1 --double-id --set-all-var-ids @:# --make-bed
