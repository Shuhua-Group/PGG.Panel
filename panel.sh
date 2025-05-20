#!/bin/bash

i=$1

prefix='POP_zyHan_HXDL'
qc='VQSR' #qc=filtered
minimac4='/home/sunyumeng/software/minimac4-4.1.6-Linux-x86_64/bin/minimac4'

vcf="../03.phase/$prefix.chr${i}.$qc.PASS.biallelic.SNPs.FM10.AC1.shapeit5.final.rmPP.vcf.gz"
$minimac4 --compress-reference $vcf > $prefix.chr${i}.$qc.PASS.biallelic.SNPs.FM10.AC1.shapeit5.msav
