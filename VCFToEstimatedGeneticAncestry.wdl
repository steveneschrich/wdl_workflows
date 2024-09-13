version 1.0


import "SubsetVCF.wdl" as SubsetVCF
import "ApplyAdmixtureModel.wdl" as Admixture

# This workflow is a per-sample workflow. If you have multiple samples
# to operate on, you should implement a simple scatter to perform this
# in parallel.
#
# The workflow consists of several steps:
# - SubsetVCF
#       Subset existing sample to AIMs only
# - PredictAncestry
#       Use an existing model to produce ancestry estimates
#
workflow VCFToEstimatedGeneticAncestry {
    input {
        File vcf # Sample to deal with
        File referenceFile # Not sure where, but this is the fully genotyped sample
        File snpList # Ancestry-informative markers

        File referenceFasta
        File referenceFastaDict
        File referenceFastaFai
 
        File model
    }
    String vcfBase = basename(vcf, ".vcf.gz")

    # Input: File vcf
    # Input: File snpList
    # Input: File referenceFile
    call SubsetVCF.SubsetToSNPs as subset {
        input:
            vcf = vcf,
            snpList = snpList,
            referenceFile = referenceFile,

            referenceFasta = referenceFasta,
            referenceFastaDict = referenceFastaDict,
            referenceFastaFai = referenceFastaFai
    }
    # Output: File outputVcf
    # Output: File outputVcfIndex

    call Admixture.ApplyAdmixtureModel as admixture {
        input:
            vcf = subset.outputVcf,
            model = model

    }

    output {
        File outputVcf = subset.outputVcf
        File outputVcfIndex = subset.outputVcfIndex
        File bedFile = admixture.bedFile
        File qFile = admixture.qFile
    }

    # This option allows users to set options relative to embedded tasks/workflows
    # via the options file rather than passing them as workflow parameters. 
    meta {
        allowNestedInputs: true
    }
}
