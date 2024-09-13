version 1.0

import "../biowdl_tasks/plink.wdl" as plink
import "../biowdl_tasks/admixture.wdl" as admixture

# The goal of this workflow is to apply a specific ancestry model to a vcf and
# return the prediction(s) in whatever form is appropriate for the model.
# Here, we are using an admixture model

workflow ApplyAdmixtureModel {
    input {
        File vcf
        File model
        Int K = 8
    }
    String baseVcf = basename(vcf, ".vcf.gz")
    # Input: File vcf
    # Input: String outputPath
    call plink.MakeBed as convertToPlink {
        input:
            vcf = vcf,
            outputPath = baseVcf + "_plink"
    }
    # Output: File bedfile
    # Output: File bimFile
    # Output: File famFile


    # Input: File bed
    # Input: File bim
    # Input: File fam
    # Input: File model
    # Input: String outputPath
    # Input: int K
    call admixture.Predict as predict {
        input:
            bed = convertToPlink.bedFile,
            bim = convertToPlink.bimFile,
            fam = convertToPlink.famFile,
            model = model,
            outputPath = baseVcf + "-K-" + K + ".txt" 
    }
    # Last bit, copy/localize the model and admixture works funny where everything
    # is supposed to be there so we need to specifiy them so the localize


    output {
        File bedFile = convertToPlink.bedFile
        File qFile = predict.qFile
    }


    # This option allows users to set options relative to embedded tasks/workflows
    # via the options file rather than passing them as workflow parameters. 
    meta {
        allowNestedInputs: true
    }
}

#admixture -P ${WORK_DIR}/samples.bed ${K} -j${THREADS} --cv=${CVE}

#task foo {
#    echo "...."
#echo "Step 4 - Converting VCF to bed file using plink1.9..."
#singularity exec -H ${WORK_DIR} ${SIF_DIR}/plink.sif plink1.9 --make-bed --vcf ${WORK_DIR}/samples_AIMs.vcf.gz --double-id --out ${WORK_DIR}/samples
#echo "...."

#echo "Step 5 - Using K=8 reference results "in" file (aka samples.8.P.in) for analysis of ORIEN samples"
#cp ${PIN_DIR}/${PIN_FILE8} ${WORK_DIR}/
#singularity exec -H $WORK_DIR ${SIF_DIR}/admixture.sif admixture -P ${WORK_DIR}/samples.bed ${K} -j${THREADS} --cv=${CVE}

#echo "...."
#echo "Step 6 - Adding row and column headers to sample Q output..."
#for (( c=1; c<=$K; c++ ))
#    do
#echo -n "Q$c "
#    done > ${NAME}.K${K}.Q.tsv
#sed -i 's/Q1 /ID\tQ1\t/g' ${NAME}.K${K}.Q.tsv
#echo "Self-Reported_Gender Self-Reported_Race Self-Reported_Ethnicity" >> ${NAME}.K${K}.Q.tsv
#tr ' ' '\t' < ${NAME}.K${K}.Q.tsv > temp
#mv temp ${NAME}.K${K}.Q.tsv
#line1=1
#nlinessamp=$(wc -l ${NAME}.fam | awk '{print $1}')
#for i in $(seq ${line1} ${nlinessamp}); do ID=$(sed -n ${i}p samples.fam | awk '{print $1}'); Qs=$(sed -n ${i}p samples.8.Q); gender=$(grep "\"$ID\"," WESID_Self-Report_Gender_Race_Ethnicity.csv | cut -d"," -f2 | sed 's/"//g'); race=$(grep "\"$ID\"," WESID_Self-Report_Gender_Race_Ethnicity.csv | cut -d"," -f3 | sed 's/"//g'); ethnicity=$(grep "\"$ID\"," WESID_Self-Report_Gender_Race_Ethnicity.csv | cut -d"," -f4 | sed 's/"//g'); echo -e "${ID}\t${Qs}\t${gender}\t${race}\t${ethnicity}"; done >> ${NAME}.K${K}.Q.tsv
#sed -i 's/ /\t/g' ${NAME}.K${K}.Q.tsv
#rep -v ignoreSample ${NAME}.K${K}.Q.tsv > temp
#mv temp ${NAME}.K${K}.Q.tsv

#N1=2
#N2=$(wc -l ${NAME}.K${K}.Q.tsv  | awk '{print $1}')
#echo "ID European East_Asian Indigenous_American African South_Asian Middle_Eastern Oceanian Self-Reported_Gender Self-Reported_Race Self-Reported_Ethnicity" | tr ' ' '\t' > ${NAME}.summary.K8.tsv
#for i in $(seq ${N1} ${N2})
#    do
#ID=$(sed -n ${i}p ${NAME}.K${K}.Q.tsv | awk -v FS='\t' -v OFS='\t' '{print $1}')
#Q1=$(sed -n ${i}p ${NAME}.K${K}.Q.tsv | awk -v FS='\t' -v OFS='\t' '{print $2}')
#Q2=$(sed -n ${i}p ${NAME}.K${K}.Q.tsv | awk -v FS='\t' -v OFS='\t' '{print $3}')
#Q3=$(sed -n ${i}p ${NAME}.K${K}.Q.tsv | awk -v FS='\t' -v OFS='\t' '{print $4}')
#Q4=$(sed -n ${i}p ${NAME}.K${K}.Q.tsv | awk -v FS='\t' -v OFS='\t' '{print $5}')
#Q5=$(sed -n ${i}p ${NAME}.K${K}.Q.tsv | awk -v FS='\t' -v OFS='\t' '{print $6}')
#Q6=$(sed -n ${i}p ${NAME}.K${K}.Q.tsv | awk -v FS='\t' -v OFS='\t' '{print $7}')
##Q7=$(sed -n ${i}p ${NAME}.K${K}.Q.tsv | awk -v FS='\t' -v OFS='\t' '{print $8}')
#Q8=$(sed -n ${i}p ${NAME}.K${K}.Q.tsv | awk -v FS='\t' -v OFS='\t' '{print $9}')
#Self_Reported_Gender=$(sed -n ${i}p ${NAME}.K${K}.Q.tsv | awk -v FS='\t' -v OFS='\t' '{print $10}')
#Self_Reported_Race=$(sed -n ${i}p ${NAME}.K${K}.Q.tsv | awk -v FS='\t' -v OFS='\t' '{print $11}')
#Self_Reported_Ethnicity=$(sed -n ${i}p ${NAME}.K${K}.Q.tsv | awk -v FS='\t' -v OFS='\t' '{print $12}')
#OCE=$Q7
#MDE=$Q6
#AFR=$(echo "$Q4 + $Q8" | bc -l | awk '{printf "%.6f\n", $0}')
#EAS=$Q2
#EUR=$Q1
#IA=$Q3
#SAS=$Q5
#echo "$ID $EUR $EAS $IA $AFR $SAS $MDE $OCE $Self_Reported_Gender $Self_Reported_Race $Self_Reported_Ethnicity" |  tr ' ' '\t'
#    done >> ${NAME}.summary.K8.tsv#
#
#}