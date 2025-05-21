#!/bin/bash

prefix='POP_zyHan_HXDL'
qc='VQSR' #qc=filtered

rm merge.list.txt
for i in {1..22}
do
    echo -e "../01.qc/$prefix.chr${i}.$qc.PASS.biallelic.SNPs.FM10.AC1.bed  ../01.qc/$prefix.chr${i}.$qc.PASS.biallelic.SNPs.FM10.AC1.bim  ../01.qc/$prefix.chr${i}.$qc.PASS.biallelic.SNPs.FM10.AC1.fam" >> merge.list.txt
done
plink2 --pmerge-list merge.list.txt --make-bed --out $prefix.chrA.$qc.PASS.biallelic.SNPs.FM10.AC1

king -b $prefix.chrA.$qc.PASS.biallelic.SNPs.FM10.AC1.bed --related --degree 3 --prefix $prefix
grep -v 'InfType' $prefix.kin0 | awk '$14=="Dup/MZ"||$14=="PO"||$14=="FS"||$14=="2nd"{print $1,$3}' | python 5011.relative.combinations.py  /dev/stdin  rm.relative.king.list 1>rm.relative.king.log  2>&1
cat $prefix.chrA.$qc.PASS.biallelic.SNPs.FM10.AC1.fam  rm.relative.king.list|awk '{print $1}'|sort|uniq -u >  no.relate.list
