#Refenerce should build by bowtie2 first.
ref="/public/home/chenbzh5/DB/hg38_bowtie2_index/hg38"
#Dir of your raw data.
dir=/md01/chenbzh5/TZJ/cut_tag/PM-XS05KF2021010423-115/ANNO_XS05KF2021010423_PM-XS05KF2021010423-115_2022-01-10_00-27-55_AHW7TJDSX2/Cleandata/
#Move your .gz to fastq. 
mkdir $dir fastq
mv $dir/*.gz $dir fastq
#Prefix of you filename.
hisName=("polII-h3k27ac" "polII-h3k4me3")
#Run pipline for GZ
for i in "${!hisName[@]}";
do 
	path=$dir${hisName[$i]};
	sh pipline.sh $path $ref ${hisName[$i]} & 
done;
