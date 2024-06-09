#!/bin/bash
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo ""
   echo "Bash script that generates side-by-side deepTOOLS heatmaps of samples described in input file. Recommend 6 samples max."
   echo "Run in directory with peak files and unsmoothed bigwigs"
   echo
   echo "Syntax: sh side-by-side-deeptools.sh [-h|i|r|g|s]"
   echo "options:"
   echo "-h      Print this Help."
   echo "-i      Name of input file." 
   echo "           List of sample names you'd like to include. "
   echo "           Order of samples in heatmap is determined by order of samples in input file."
   echo "           File is required"
   echo "-r      Region of heatmaps. Options are: start_site, region, or both. Required."
   echo "-b      Bed file containing regions you'd like to survey. Tab-delimited with chrom, start, stop. No header. Required."
   echo
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":hi:r:b:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      i) # Enter a name
         inputFile=$OPTARG;;
      r) #enter region
         region=$OPTARG;;
      b) #enter genome
         bed=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

#make output name, string for bw file names, and string for bw labels
NUM_FILES=`expr $(wc -l < ${inputFile})`
outputFile=''
labels=''
bigwigInput=''

for i in $(seq 1 ${NUM_FILES}); # loops through all filenames in $FILES
do
    fileLabel=$(sed -n "${i}p" ${inputFile} | cut -f1 -d".")
    outputFile="$outputFile$fileLabel"
    labels="$labels$fileLabel"

    bigwigName=$(sed -n "${i}p" ${inputFile})
    bigwigInput="$bigwigInput$bigwigName"

    if [ $i != $NUM_FILES ]
    then
        outputFile="${outputFile}-"
        labels="${labels} "
        bigwigInput="${bigwigInput} "
    fi

done

shortRefFile="${custom_input%.bed}"
mkdir $shortRefFile
refFile="$bed"
lines=$(wc -l $custom_input | cut -f1 -d' ')

#making TSS and Gene heatmaps or just one?
if [ "$region" = "start_site" ] || [ "$region" = "both" ];
then
## TSS +/2kb, bin 20bp, sort by row mean ###
echo ''
echo 'computeMatrix: Start Site as Reference Point'
computeMatrix  reference-point  --regionsFileName $refFile  --scoreFileName $bigwigInput --outFileName $shortRefFile/${outputFile}.startSite.profile.matrix.gz --referencePoint TSS  --beforeRegionStartLength 2000  --afterRegionStartLength 2000  --binSize 20  --sortUsing mean --averageTypeBins mean  --missingDataAsZero  --scale 1  --numberOfProcessors 1 --samplesLabel $labels 

echo 'plotProfile: Start Site as Reference Point'
plotProfile --matrixFile $shortRefFile/${outputFile}.startSite.profile.matrix.gz  --outFileName $shortRefFile/${outputFile}.startSite.profile.png --perGroup --regionsLabel "$bed"
fi

#making TSS and Gene heatmaps or just one?
if [ "$region" = "region" ] || [ "$region" = "both" ];
then
echo ''
echo 'computeMatrix: Region as Reference Point'
computeMatrix scale-regions --regionsFileName $refFile --outFileName $shortRefFile/${outputFile}.Region.profile.matrix.gz --scoreFileName $bigwigInput --beforeRegionStartLength 2000 --afterRegionStartLength 2000 --regionBodyLength 4000 --binSize 20 --sortUsing mean --missingDataAsZero --numberOfProcessors 1 --startLabel "Start" --endLabel "End" --unscaled5prime 0 --unscaled3prime 0 --samplesLabel $labels

echo 'plotHeatmap: Region as Reference Point'
plotProfile --matrixFile $shortRefFile/${outputFile}.Region.profile.matrix.gz  --outFileName $shortRefFile/${outputFile}.Region.profile.png --perGroup --regionsLabel "$bed"

fi
