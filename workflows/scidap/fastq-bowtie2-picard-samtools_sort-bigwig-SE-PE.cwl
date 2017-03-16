cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  upstream_fastq:
    type: File
  downstream_fastq:
    type: File?
  bowtie2_indices_folder:
    type: Directory
    doc: "Path to BOWTIE2 indices folder"
  split:
    type: boolean?
    doc: define if use split option for bedtools genomcove
  chrLengthFile:
    type: File

outputs:

  bowtie2_aligner_log:
    type: File
    outputSource: bowtie2_aligner/output_log
  picard_metrics:
    type: File
    outputSource: remove_dup_picard/metrics_file
  bam_file:
    type: File
    outputSource: samtools_sort_index_after_dup_removing/bamBaiPair
  bamtools_stats_log:
    type: File
    outputSource: bamtools_stats/statsLog
  bed:
    type: File
    outputSource: bam_to_bigwig/bed_file
  bigwig:
    type: File
    outputSource: bam_to_bigwig/outfile

steps:
  bowtie2_aligner:
    run: ../../tools/bowtie2.cwl
    in:
      filelist: upstream_fastq
      filelist_mates: downstream_fastq
      indices_folder: bowtie2_indices_folder
      output_filename:
        source: upstream_fastq
        valueFrom: |
          ${
            return self.basename.split('.').slice(0, -1).join('.')+".sam";
          }
    out: [output, output_log]

  samtools_sort_index:
    run: ../../tools/samtools-sort-index.cwl
    in:
      sortInput: bowtie2_aligner/output
      sortOutputFileName:
        source: upstream_fastq
        valueFrom: |
          ${
            return self.basename.split('.').slice(0, -1).join('.')+".bam";
          }
    out: [bamBaiPair]

  remove_dup_picard:
    run: ../../tools/picard-markduplicates.cwl
    in:
      input_file: samtools_sort_index/bamBaiPair
      output_filename:
        source: upstream_fastq
        valueFrom: |
          ${
            return self.basename.split('.').slice(0, -1).join('.') + ".picard.bam";
          }
      output_metrics_filename:
        source: upstream_fastq
        valueFrom: |
          ${
            return self.basename.split('.').slice(0, -1).join('.') + ".metrics";
          }
      remove_dup:
        default: true
    out: [output_file, metrics_file]

  samtools_sort_index_after_dup_removing:
    run: ../../tools/samtools-sort-index.cwl
    in:
      sortInput: remove_dup_picard/output_file
      sortOutputFileName:
        source: upstream_fastq
        valueFrom: |
          ${
            return self.basename.split('.').slice(0, -1).join('.')+".bam";
          }
    out: [bamBaiPair]

  bamtools_stats:
    run: ../../tools/bamtools-stats.cwl
    in:
      inputFiles: samtools_sort_index_after_dup_removing/bamBaiPair
    out: [mappedreads, statsLog]

  bam_to_bigwig:
    run: bam-genomecov-bigwig.cwl
    in:
      input: samtools_sort_index_after_dup_removing/bamBaiPair
      genomeFile: chrLengthFile
      mappedreads: bamtools_stats/mappedreads
      split:
        source: split
        valueFrom: |
          ${
            if (self == null){
              return true;
            } else {
              return self;
            }
          }
      bigWig:
        source: upstream_fastq
        valueFrom: |
          ${
            return self.basename.split('.')[0]+".bigwig";
          }
    out: [outfile, bed_file]