version 1.0

import "../../wdl/biowdl_tasks/bcftools.wdl" as bcftools

# The goal of this workflow is to take a VCF and rename the
# chromosomes in the file from "1" to "chr1". Various versions
# of software seem to inconsistently use these variations.
workflow RenameChromosomes {

    input {
        File vcfFile
    }
   
    String vcfBase = basename(vcfFile, ".vcf.gz")

    # Input: None
    call CreateChromosomeMapping as createChromosomeMapping {
       input:
    }
    # Output: File chromosomeMappingFile


    # Input: File inputFile
    # Input: File? inputFileIndex
    # Input: String outputPath = "output.vcf.gz"
    # Input: File? renameChrs
    call bcftools.Annotate as bcfRenameChromosomes {
        input:
            inputFile = vcfFile,
            renameChrs = createChromosomeMapping.chromosomeMappingFile,
            outputPath = vcfBase + "_chrfix.vcf.gz"
    }
    # Output: File outputVcf
    # Output: File? outputVcfIndex

    #-- Re-sort with new chromosome names (re-indexing done in sort)
    # Input: File inputFile
    # Input: String outputPath = "output.vcf.gz" # Would like a better name here
    call bcftools.Sort as bcfSortVcf {
        input:
            inputFile = bcfRenameChromosomes.outputVcf

    }
    # Output: File outputVcf
    # Output: File? outputVcfIndex
 
    output {
        File outputVcf = bcfSortVcf.outputVcf
        File? outputVcfIndex = bcfSortVcf.outputVcfIndex
    }  

}

task CreateChromosomeMapping {

    input {

        String outputPath = "nochr_to_chr.txt"
        String memory = "5GiB"
        String dockerImage = "debian:trixie-slim"
 
    }

    command <<<

        for i in {1..22}; do
            echo "$i chr${i}"
        done > ~{outputPath}

    >>>

    output {
        File chromosomeMappingFile = outputPath
    }

    runtime {
        memory: memory
        docker: dockerImage
    }
   parameter_meta {
        # inputs
        outputPath: {description: "The location the chromosome mapping file should be written.", category: "common"}
        memory: {description: "The amount of memory this job will use.", category: "advanced"}
        dockerImage: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}

        # outputs
        chromosomeMappingFile: {description: "Mapping file for renaming chromosomes."}
    }
}