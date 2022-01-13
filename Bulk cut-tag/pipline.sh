#PBS -N cuttag
#PBS -j oe
#PBS -q batch
#PBS -o example.stdout
#PBS -e example2.stdout
#PBS -S /bin/sh
#PBS -l nodes=1:ppn=8
#PBS -l mem=6000m


cores=8
projPath=$1
ref=$2
histName=$3
picardCMD="java -jar /public/home/chenbzh5/Tools/picard-tools-2.4.1/picard.jar"

#mkdir for your output path.
mkdir -p ${projPath}/alignment/sam/bowtie2_summary
mkdir -p ${projPath}/alignment/bam
mkdir -p ${projPath}/alignment/bed
mkdir -p ${projPath}/alignment/bedgraph
mkdir -p ${projPath}/alignment/removeDuplicate
mkdir -p ${projPath}/alignment/removeDuplicate/picard_summary
mkdir -p ${projPath}/peakCalling/MACS2

#Bowtie2 mapping.
/public/home/chenbzh5/Tools/bowtie2-2.4.3-linux-x86_64/bowtie2 --local --very-sensitive --no-mixed --no-discordant --phred33 -I 10 -X 700 -p ${cores} -x ${ref} -1 ${projPath}/fastq/${histName}_R1.fq.gz -2 ${projPath}/fastq/${histName}_R2.fq.gz -S ${projPath}/alignment/sam/${histName}_bowtie2.sam &> ${projPath}/alignment/sam/bowtie2_summary/${histName}_bowtie2.txt
#Sortsam
$picardCMD SortSam I=$projPath/alignment/sam/${histName}_bowtie2.sam O=$projPath/alignment/sam/${histName}_bowtie2.sorted.sam SORT_ORDER=coordinate
#Remove dups.
$picardCMD MarkDuplicates I=$projPath/alignment/sam/${histName}_bowtie2.sorted.sam O=$projPath/alignment/removeDuplicate/${histName}_bowtie2.sorted.dupMarked.sam METRICS_FILE=$projPath/alignment/removeDuplicate/picard_summary/${histName}_picard.dupMark.txt
$picardCMD MarkDuplicates I=$projPath/alignment/sam/${histName}_bowtie2.sorted.sam O=$projPath/alignment/removeDuplicate/${histName}_bowtie2.sorted.rmDup.sam REMOVE_DUPLICATES=true METRICS_FILE=$projPath/alignment/removeDuplicate/picard_summary/${histName}_picard.rmDup.txt
#Convert sam to bam
samtools view -bS $projPath/alignment/removeDuplicate/${histName}_bowtie2.sorted.rmDup.sam > $projPath/alignment/bam/${histName}_bowtie2.sorted.rmDup.bam
#Convert bam to bedGraph.
bedtools  genomecov  -bg -ibam $projPath/alignment/bam/${histName}_bowtie2.sorted.rmDup.bam > $projPath/alignment/bedgraph/${histName}_bowtie2.sorted.rmDup.bedGraph
/public/home/chenbzh5/project/mitoDNA_bottleneck/discover_bottleneck/output_GSE142745/PBMC_scATAC_1/12-10_mk_realign_1000reads/CLP_bam_to_wig/bedSort $projPath/alignment/bedgraph/${histName}_bowtie2.sorted.rmDup.bedGraph  $projPath/alignment/bedgraph/${histName}_bowtie2.sorted2.rmDup.bedGraph
#Convert bedGraph to bed.
/public/home/chenbzh5/project/mitoDNA_bottleneck/discover_bottleneck/output_GSE142745/PBMC_scATAC_1/12-10_mk_realign_1000reads/CLP_bam_to_wig/bedGraphToBigWig $projPath/alignment/bedgraph/${histName}_bowtie2.sorted2.rmDup.bedGraph /md01/chenbzh5/TZJ/cut_tag/PM-XS05KF2021010423-97/hg38.chrom.sizes $projPath/alignment/bed/${histName}.bw
#Peak calling use macs2.
macs2 callpeak -t ${projPath}/alignment/bam/${histName}_bowtie2.sorted.rmDup.bam -g hs -f BAMPE -n macs2_peak_q0.01 --outdir $projPath/peakCalling/MACS2 -q 0.01 --keep-dup all 2>${projPath}/peakCalling/MACS2/macs2Peak_summary.txt
