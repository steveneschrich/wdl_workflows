version 1.0

import "../biowdl_tasks/samtools.wdl" as samtools
import "../biowdl_tasks/vcftools.wdl" as vcftools
import "../biowdl_tasks/bcftools.wdl" as bcftools
import "../biowdl_tasks/gatk.wdl" as gatk
import "RenameChromosomes.wdl" as renamechromosomes

# I think this should be subset and export. As in ExportToBed (SNPLIST)
workflow SubsetToSNPs {
    input {
        File vcf
        File snpList
        File referenceFile

        File referenceFasta
        File referenceFastaDict
        File referenceFastaFai
    }
    String vcfBase = basename(vcf, ".vcf.gz")

    # This option allows users to set options relative to embedded tasks/workflows
    # via the options file rather than passing them as workflow parameters. 
    meta {
        allowNestedInputs: true
    }
    

    ##-------------------------------------------------------
    ## Genotype VCF in case the positions are marked as [REF]
    ## instead of the actual base.
    ##
    #-- Index before running anything (just in case)
    # Input: File vcf
    call bcftools.Index as bcfIndexBeforeGenotyping {
        input: 
            vcf = vcf
    }
    # File outputVcf
    # File? outputVcfIndex

    #-- Genotype
    call gatk.GenotypeGVCFs as genotypeVCF {
        input:
            gvcfFile = bcfIndexBeforeGenotyping.outputVcf,
            gvcfFileIndex = bcfIndexBeforeGenotyping.outputVcfIndex,
            outputPath = vcfBase + "_genotyped.vcf.gz",

            # Annotation required for genotyping
            referenceFasta = referenceFasta,
            referenceFastaDict = referenceFastaDict,
            referenceFastaFai = referenceFastaFai
    }
    #-- Reindex
    # Input: File vcf
    call bcftools.Index as bcfIndexAfterGenotyping {
        input:
            vcf = genotypeVCF.outputVCF
    }
    # File outputVcf
    # File? outputVcfIndex
  


    ##-------------------------------------------------------
    ## Rename chromosomes in the vcf (chr1 -> 1)
    # Input:  File vcf
    call renamechromosomes.RenameChromosomes as rename {
        input:
            vcfFile = bcfIndexAfterGenotyping.outputVcf
    }
    # Output: File outputVcf
    # Output: File outputVcfIndex

    ##--------------------------------------------------
    ## Select only autosomal chromosomes
    ##
    # Subset to autosomes only
    # Input: File inputFile
    # Input: String outputPath = "output.vcf"
    # Input: Boolean excludeUncalled = false
    # Input: String? regions
    # Input: String memory = "256MiB"
    # Input: Int timeMinutes = 1 + ceil(size(inputFile, "G"))
    # Input: String dockerImage = "quay.io/biocontainers/bcftools:1.10.2--h4f4756c_2"
    call bcftools.View as bcfSubset {
        input:
            inputFile = rename.outputVcf,
            outputPath = vcfBase + "_autosomes.vcf.gz",
            regions = "chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22"
    }
    # File outputVcf
    # File? outputVcfIndex


    ##------------------------------------------------------------------
    ## Force all positions to be included per a reference file. Missing
    ## positions should be given an 'N' in the sample. 
    ##
    # Merge SNP Sites
    # Input: File inputFile
    # Input: File referenceFile
    # Input: String outputPath
    call bcftools.Merge as merge {
        input:
            inputFile = bcfSubset.outputVcf,
            referenceFile = referenceFile,
            outputPath = vcfBase + "_complete.vcf.gz"
    }
    # Output: File outputVcf
    # Output: File? outputVcfIndex




    ##------------------------------------------------
    ## Filter to SNP list and create vcf.gz/vcf.gz.tbi
    ##

    # Input: File inputFile
    # Input: File SNPList
    # Input: String? outputDir
    call vcftools.SNPFilter as snpfilter {
        input:
            inputFile = merge.outputVcf,
            SNPList = snpList,
            outputDir = vcfBase + "_snpfiltered"
    }
    # Output: File outputFile


    # Input: File inputFile
    # Input: String outputDir
    # Input: String type = "vcf"
    call samtools.BgzipAndIndex as index {
        input:
            inputFile = snpfilter.outputFile,
            outputDir = vcfBase + "_snpfiltered.vcf.gz"
    }
    # Output: File compressed
    # Output: File index


    ##---------------------------------------
    ## End of pipeline

    output {
        File outputVcf = index.compressed
        File outputVcfIndex = index.index
    }
}







