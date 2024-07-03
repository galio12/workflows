cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: MultipleInputFeatureRequirement
  - class: InlineJavascriptRequirement
    expressionLib:
    - var get_root = function(basename) {
          return basename.split('.').slice(0,1).join('.');
      };


'sd:metadata':
  - "../metadata/chipseq-header.cwl"

'sd:upstream':
  genome_indices: "genome-indices.cwl"
  control_file: "chipseq-se.cwl"


inputs:

  indices_folder:
    type: Directory
    'sd:upstreamSource': "genome_indices/bowtie_indices"
    label: "Genome indices"
    doc: "Directory with the genome indices generated by Bowtie"

  annotation_file:
    type: File
    'sd:upstreamSource': "genome_indices/annotation"
    label: "Genome annotation file"
    format: "http://edamontology.org/format_3475"
    doc: "Genome annotation file in TSV format"

  genome_size:
    type: string
    'sd:upstreamSource': "genome_indices/genome_size"
    label: "Effective genome size"
    doc: "The length of the mappable genome (hs, mm, ce, dm or number, for example 2.7e9)"

  chrom_length:
    type: File
    'sd:upstreamSource': "genome_indices/chrom_length"
    label: "Chromosome lengths file"
    format: "http://edamontology.org/format_2330"
    doc: "Chromosome lengths file in TSV format"

  control_file:
    type: File?
    default: null
    'sd:upstreamSource': "control_file/bambai_pair"
    'sd:localLabel': true
    label: "Control ChIP-Seq single-read experiment"
    format: "http://edamontology.org/format_2572"
    doc: "Indexed BAM file from the ChIP-Seq single-read experiment to be used as a control for MACS2 peak calling"

  broad_peak:
    type: boolean?
    default: False
    # 'sd:parent': "https://raw.githubusercontent.com/datirium/workflows/master/tags/antibody-dummy.cwl"
    label: "Call broad peaks"
    doc: "Make MACS2 call broad peaks by linking nearby highly enriched regions"

  fastq_file:
    type:
    - File
    - type: array
      items: File
    label: "FASTQ file(s)"
    format: "http://edamontology.org/format_1930"
    doc: "Single-read sequencing data in FASTQ format (fastq, fq, bzip2, gzip, zip)"

  exp_fragment_size:
    type: int?
    default: 150
    'sd:layout':
      advanced: true
    label: "Expected fragment size"
    doc: "Expected fragment size for read extenstion towards 3' end if force_fragment_size was set to True or if calculated by MACS2 fragment size was less that 80 bp"

  force_fragment_size:
    type: boolean?
    default: false
    'sd:layout':
      advanced: true
    label: "Force peak calling with expected fragment size"
    doc: "Make MACS2 don't build the shifting model and use expected fragment size for read extenstion towards 3' end"

  clip_3p_end:
    type: int?
    default: 0
    'sd:layout':
      advanced: true
    label: "Clip from 3' end"
    doc: "Number of base pairs to clip from 3' end"

  clip_5p_end:
    type: int?
    default: 0
    'sd:layout':
      advanced: true
    label: "Clip from 5' end"
    doc: "Number of base pairs to clip from 5' end"

  remove_duplicates:
    type: boolean?
    default: false
    'sd:layout':
      advanced: true
    label: "Remove PCR duplicates"
    doc: "Remove PCR duplicates from sorted BAM file"

  peak_calling_fdr:
    type: float?
    default: 0.05
    'sd:layout':
      advanced: true
    label: "Minimum FDR (q-value) cutoff for peak detection"
    doc: |
      Minimum FDR (q-value) cutoff for peak detection. -q, and
      -p are mutually exclusive.

  promoter_dist:
    type: int?
    default: 1000
    'sd:layout':
      advanced: true
    label: "Max distance from gene TSS (in both direction) overlapping which the peak will be assigned to the promoter region"
    doc: "Max distance from gene TSS (in both direction) overlapping which the peak will be assigned to the promoter region"

  upstream_dist:
    type: int?
    default: 20000
    'sd:layout':
      advanced: true
    label: "Max distance from the promoter (only in upstream direction) overlapping which the peak will be assigned to the upstream region"
    doc: "Max distance from the promoter (only in upstream direction) overlapping which the peak will be assigned to the upstream region"

  threads:
    type: int?
    default: 2
    'sd:layout':
      advanced: true
    label: "Number of threads"
    doc: "Number of threads for those steps that support multithreading"


outputs:

  unaligned_fastq:
    type:
      - "null"
      - File[]
    format: "http://edamontology.org/format_1930"
    label: "Unaligned FASTQ file(s)"
    doc: "Unaligned FASTQ file(s)"
    outputSource: bowtie_aligner/unaligned_fastq

  multimapped_fastq:
    type:
      - "null"
      - File[]
    format: "http://edamontology.org/format_1930"
    label: "Multimapped FASTQ file(s)"
    doc: "Multimapped FASTQ file(s)"
    outputSource: bowtie_aligner/multimapped_fastq

  bigwig:
    type: File
    format: "http://edamontology.org/format_3006"
    label: "Genome coverage"
    doc: "Genome coverage in bigWig format"
    outputSource: bam_to_bigwig/bigwig_file
    'sd:visualPlugins':
    - igvbrowser:
        tab: 'IGV Genome Browser'
        id: 'igvbrowser'
        optional: true
        type: 'wig'
        name: "Genome Coverage"
        height: 120

  fastx_statistics:
    type: File
    label: "FASTQ quality statistics"
    format: "http://edamontology.org/format_2330"
    doc: "FASTQ quality statistics in TSV format"
    outputSource: fastx_quality_stats/statistics_file
    'sd:visualPlugins':
    - line:
        tab: 'QC Plots'
        Title: 'Base Frequency Plot'
        xAxisTitle: 'Nucleotide position'
        yAxisTitle: 'Frequency'
        colors: ["#b3de69", "#888888", "#fb8072", "#fdc381", "#99c0db"]
        data: [$13, $14, $15, $16, $17]
    - boxplot:
        tab: 'QC Plots'
        Title: 'Base Quality Plot'
        xAxisTitle: 'Nucleotide position'
        yAxisTitle: 'Quality score'
        colors: ["#b3de69", "#888888", "#fb8072", "#fdc381", "#99c0db"]
        data: [$11, $7, $8, $9, $12]

  bowtie_log:
    type: File
    label: "Read alignment log"
    format: "http://edamontology.org/format_2330"
    doc: "Read alignment log file from Bowtie"
    outputSource: bowtie_aligner/log_file

  iaintersect_result:
    type: File
    label: "Gene annotated peaks"
    format: "http://edamontology.org/format_3475"
    doc: "MACS2 peak file annotated with nearby genes"
    outputSource: island_intersect/result_file
    'sd:visualPlugins':
    - syncfusiongrid:
        tab: 'Peak Calling'
        Title: 'Peak Coordinates'

  atdp_result:
    type: File
    label: "Average Tag Density Plot"
    format: "http://edamontology.org/format_3475"
    doc: "Average Tag Density Plot file in TSV format"
    outputSource: average_tag_density/result_file
    'sd:visualPlugins':
    - scatter:
        tab: 'QC Plots'
        Title: 'Average Tag Density Plot'
        xAxisTitle: 'Distance From TSS (bp)'
        yAxisTitle: 'Average Tag Density (per bp)'
        colors: ["#b3de69"]
        height: 500
        data: [$1, $2]
        comparable: "atdp"

  bambai_pair:
    type: File
    format: "http://edamontology.org/format_2572"
    label: "Aligned reads"
    doc: "Coordinate sorted BAM alignment and index BAI files"
    outputSource: samtools_remove_duplicates/deduplicated_bam_bai_pair
    'sd:visualPlugins':
    - igvbrowser:
        tab: 'IGV Genome Browser'
        id: 'igvbrowser'
        type: 'alignment'
        format: 'bam'
        name: "Nucleotide Sequence Alignments"
        displayMode: "SQUISHED"

  macs2_called_peaks:
    type: File
    label: "Called peaks"
    format: "http://edamontology.org/format_3468"
    doc: "Called peaks file with 1-based coordinates in XLS format"
    outputSource: macs2_callpeak/peak_xls_file

  macs2_narrow_peaks:
    type: File?
    label: "Narrow peaks"
    format: "http://edamontology.org/format_3613"
    doc: "Called peaks file in ENCODE narrow peak format"
    outputSource: macs2_callpeak/narrow_peak_file
    'sd:visualPlugins':
    - igvbrowser:
        tab: 'IGV Genome Browser'
        id: 'igvbrowser'
        type: 'annotation'
        name: "Narrow peaks"
        displayMode: "COLLAPSE"
        height: 40

  macs2_broad_peaks:
    type: File?
    label: "Broad peaks"
    format: "http://edamontology.org/format_3614"
    doc: "Called peaks file in ENCODE broad peak format"
    outputSource: macs2_callpeak/broad_peak_file
    'sd:visualPlugins':
    - igvbrowser:
        tab: 'IGV Genome Browser'
        id: 'igvbrowser'
        type: 'annotation'
        name: "Broad peaks"
        displayMode: "COLLAPSE"
        height: 40

  workflow_statistics_yaml:
    type: File?
    label: "YAML formatted combined log"
    format: "http://edamontology.org/format_3750"
    doc: "YAML formatted combined log"
    outputSource: get_stat/collected_statistics_yaml

  workflow_statistics_markdown:
    type: File?
    label: "Markdown formatted combined log"
    format: "http://edamontology.org/format_3835"
    doc: "Markdown formatted combined log"
    outputSource: get_stat/collected_statistics_md
    'sd:visualPlugins':
    - markdownView:
        tab: 'Overview'

  workflow_statistics_tsv:
    type: File
    label: "Workflow execution statistics"
    format: "http://edamontology.org/format_3475"
    doc: "Overall workflow execution statistics from bowtie_aligner and samtools_rmdup steps"
    outputSource: get_stat/collected_statistics_tsv
    'sd:visualPlugins':
    - tableView:
        vertical: true
        tab: 'Overview'
    'sd:preview':
      'sd:visualPlugins':
      - pie:
          colors: ['#b3de69', '#99c0db', '#fb8072', '#fdc381']
          data: [$2, $3, $4, $5]

  bam_statistics_report:
    type: File
    label: "BAM statistics report (original)"
    format: "http://edamontology.org/format_2330"
    doc: "BAM statistics report (right after alignment and sorting)"
    outputSource: get_bam_statistics/log_file

  bam_statistics_report_after_filtering:
    type: File
    label: "BAM statistics report (after filtering)"
    format: "http://edamontology.org/format_2330"
    doc: "BAM statistics report (after all filters applied)"
    outputSource: get_bam_statistics_after_filtering/log_file

  preseq_estimates_plot_data:
    type: File?
    label: "Preseq estimates"
    format: "http://edamontology.org/format_3475"
    doc: "Preseq estimated results"
    outputSource: preseq_plot_data/estimates_file_plot_data
    'sd:visualPlugins':
    - line:
        tab: 'QC Plots'
        Title: 'Distinct Read Counts Estimates'
        xAxisTitle: 'Mapped Reads/Fragments/Tags (millions)'
        yAxisTitle: 'Distinct Reads Count'
        colors: ["#4b78a3", "#a3514b"]
        height: 500
        data: [$2, $5]

  estimated_fragment_size:
    type: int
    label: "Estimated fragment size"
    doc: "Estimated fragment size for downstream analyses"
    outputSource: macs2_callpeak/macs2_fragments_calculated

  mapped_reads_number:
    type: int
    label: "Mapped reads number"
    doc: "Mapped reads number for downstream analyses"
    outputSource: get_stat/mapped_reads


steps:

  extract_fastq:
    label: "Loading unmapped sequence data"
    doc: |
      Most DNA cores and commercial NGS companies return unmapped sequence data in FASTQ format.
      The data can be uploaded from users computer, downloaded directly from an ftp server of
      the core facility by providing a URL or from GEO by providing SRA accession number.
    run: ../tools/extract-fastq.cwl
    in:
      compressed_file: fastq_file
      output_prefix:
        default: "read_1"
    out: [fastq_file]

  fastx_quality_stats:
    label: "Quality control of unmapped sequence data"
    doc: |
      Evaluates the quality of your sequence data. Provides per base quality scores as well as
      base frequencies along the reads. These metrics can be used to identify whether your data
      has any problems that should be taken into account in the subsequent analysis steps.
    run: ../tools/fastx-quality-stats.cwl
    in:
      input_file: extract_fastq/fastq_file
    out: [statistics_file]

  bowtie_aligner:
    label: "Alignment to reference genome"
    doc: |
      Aligns reads to the reference genome.
      Reads are assumed to be mapped if they
      have less than 3 mismatches.
      sam_file output includes both mapped
      and unmapped reads.
    run: ../tools/bowtie-alignreads.cwl
    in:
      upstream_filelist: extract_fastq/fastq_file
      indices_folder: indices_folder
      clip_3p_end: clip_3p_end
      clip_5p_end: clip_5p_end
      v:
        default: 3
      m:
        default: 1
      best:
        default: true
      strata:
        default: true
      sam:
        default: true
      unaligned_prefix:
        default: "unaligned_reads"
      multimapped_prefix:
        default: "multimapped_reads"
      threads: threads
      q:
        default: true
      X:
        default: 500
    out:
      - sam_file
      - log_file
      - unaligned_fastq
      - multimapped_fastq

  samtools_sort_index:
    run: ../tools/samtools-sort-index.cwl
    in:
      sort_input: bowtie_aligner/sam_file
      threads: threads
    out: [bam_bai_pair]

  samtools_mark_duplicates:
    run: ../tools/samtools-markdup.cwl
    in:
      bam_bai_pair: samtools_sort_index/bam_bai_pair
      keep_duplicates:
        default: true
      threads: threads
    out: [deduplicated_bam_bai_pair]

  clean_sam_headers_for_preseq:
    run: ../tools/samtools-clean-headers.cwl
    in:
      bam_file: samtools_mark_duplicates/deduplicated_bam_bai_pair
    out: [preseq_bam]

  preseq:
    label: "Sequencing depth estimation"
    doc: |
      Estimates the complexity of the sequencing library, evaluates how many reads can
      be expected from the additional sequencing of the same experiment.
    run: ../tools/preseq-lc-extrap.cwl
    in:
      bam_file: clean_sam_headers_for_preseq/preseq_bam
      extrapolation:
        default: 1000000000
    out: [estimates_file, log_file_stdout, log_file_stderr]

  samtools_remove_duplicates:
    run: ../tools/samtools-markdup.cwl
    in:
      bam_bai_pair: samtools_mark_duplicates/deduplicated_bam_bai_pair
      keep_duplicates:
        source: remove_duplicates
        valueFrom: $(!self)
      threads: threads
    out: [deduplicated_bam_bai_pair]

  macs2_callpeak:
    label: "Peak detection"
    doc: |
      Identifies enriched with aligned reads genome areas. Those areas correspond to the
      transcription factor binding sites.
    run: ../tools/macs2-callpeak-biowardrobe-only.cwl
    in:
      treatment_file: samtools_remove_duplicates/deduplicated_bam_bai_pair
      control_file: control_file
      nolambda:
        source: control_file
        valueFrom: $(!self)
      genome_size: genome_size
      mfold:
        default: "4 40"
      verbose:
        default: 3
      nomodel: force_fragment_size
      extsize: exp_fragment_size
      bw: exp_fragment_size
      broad: broad_peak
      call_summits:
        source: broad_peak
        valueFrom: $(!self)
      keep_dup:
        default: auto
      q_value: peak_calling_fdr
      format_mode:
        default: BAM
      buffer_size:
        default: 10000
    out:
      - peak_xls_file
      - narrow_peak_file
      - broad_peak_file
      - macs2_fragments_calculated

  bam_to_bigwig:
    run: ../tools/bam-bedgraph-bigwig.cwl
    in:
      bam_file: samtools_remove_duplicates/deduplicated_bam_bai_pair
      chrom_length_file: chrom_length
      mapped_reads_number: get_stat/mapped_reads
      fragment_size: macs2_callpeak/macs2_fragments_calculated
    out: [bigwig_file]

  get_bam_statistics:
    label: "Quality control of aligned sequence data"
    doc: |
      Calculates alignment statistics, such as reads mapped/unmapped, average
      read length and quality score, etc.
    run: ../tools/samtools-stats.cwl
    in:
      bambai_pair: samtools_mark_duplicates/deduplicated_bam_bai_pair
      output_filename:
        source: samtools_mark_duplicates/deduplicated_bam_bai_pair
        valueFrom: $(get_root(self.basename)+"_bam_statistics_report.txt")
    out: [log_file]

  get_bam_statistics_after_filtering:
    run: ../tools/samtools-stats.cwl
    in:
      bambai_pair: samtools_remove_duplicates/deduplicated_bam_bai_pair
      output_filename:
        source: samtools_remove_duplicates/deduplicated_bam_bai_pair
        valueFrom: $(get_root(self.basename)+"_bam_statistics_report_after_filtering.txt")
    out: [log_file, reads_mapped]

  get_stat:
    run: ../tools/collect-statistics-chip-seq.cwl
    in:
      bowtie_alignment_report: bowtie_aligner/log_file
      bam_statistics_report: get_bam_statistics/log_file
      bam_statistics_after_filtering_report: get_bam_statistics_after_filtering/log_file
      macs2_called_peaks: macs2_callpeak/peak_xls_file
      atdp_results: average_tag_density/result_file
      preseq_results: preseq/estimates_file
    out: [collected_statistics_yaml, collected_statistics_tsv, mapped_reads, collected_statistics_md]

  preseq_plot_data:
    label: "Formats sequencing depth estimation data for plotting"
    doc: |
      Formats estimates file from preseq standard output for QC plotting. This adds a new
      column that includes the actual read count point on the plot.
    run: ../tools/preseq-plot-data.cwl
    in:
      preseq_stderr_log_file: preseq/log_file_stderr
      estimates_file: preseq/estimates_file
      mapped_reads: get_stat/mapped_reads
    out: [estimates_file_plot_data]

  island_intersect:
    label: "Peak annotation"
    doc: |
      Assigns nearest genes to peaks to explore the biological implication of the open
      chromatin binding sites.
    run: ../tools/iaintersect.cwl
    in:
      input_filename: macs2_callpeak/peak_xls_file
      annotation_filename: annotation_file
      promoter_bp: promoter_dist
      upstream_bp: upstream_dist
    out: [result_file]

  samtools_sort_index_for_atdp:
    run: ../tools/samtools-sort-index.cwl
    in:
      sort_input: samtools_remove_duplicates/deduplicated_bam_bai_pair
      threads: threads
    out: [bam_bai_pair]

  average_tag_density:
    label: "Read enrichment around genes TSS"
    doc: |
      Generates average tag density plot around genes TSS as a lot of cis-regulatory
      elements are close to the TSS of their targets.
    run: ../tools/atdp.cwl
    in:
      input_file: samtools_sort_index_for_atdp/bam_bai_pair
      annotation_filename: annotation_file
      fragmentsize_bp: macs2_callpeak/macs2_fragments_calculated
      avd_window_bp:
        default: 5000
      avd_smooth_bp:
        default: 50
      ignore_chr:
        default: chrM
      double_chr:
        default: "chrX chrY"
      avd_heat_window_bp:
        default: 200
      mapped_reads:
        source: get_bam_statistics_after_filtering/reads_mapped
        valueFrom: $(parseInt(self))
    out: [result_file]


$namespaces:
  s: http://schema.org/

$schemas:
- https://github.com/schemaorg/schemaorg/raw/main/data/releases/11.01/schemaorg-current-http.rdf

label: "Deprecated. ChIP-Seq pipeline single-read"
s:name: "Deprecated. ChIP-Seq pipeline single-read"
s:alternateName: "ChIP-Seq basic analysis workflow for single-read data"

s:downloadUrl: https://raw.githubusercontent.com/datirium/workflows/master/workflows/chipseq-se.cwl
s:codeRepository: https://github.com/datirium/workflows
s:license: http://www.apache.org/licenses/LICENSE-2.0

s:isPartOf:
  class: s:CreativeWork
  s:name: Common Workflow Language
  s:url: http://commonwl.org/

s:creator:
- class: s:Organization
  s:legalName: "Cincinnati Children's Hospital Medical Center"
  s:location:
  - class: s:PostalAddress
    s:addressCountry: "USA"
    s:addressLocality: "Cincinnati"
    s:addressRegion: "OH"
    s:postalCode: "45229"
    s:streetAddress: "3333 Burnet Ave"
    s:telephone: "+1(513)636-4200"
  s:logo: "https://www.cincinnatichildrens.org/-/media/cincinnati%20childrens/global%20shared/childrens-logo-new.png"
  s:department:
  - class: s:Organization
    s:legalName: "Allergy and Immunology"
    s:department:
    - class: s:Organization
      s:legalName: "Barski Research Lab"
      s:member:
      - class: s:Person
        s:name: Michael Kotlia
        s:email: mailto:michael.kotliar@cchmc.org
        s:sameAs:
        - id: http://orcid.org/0000-0002-6486-3898

# doc:
#   $include: ../descriptions/chipseq-se.md


doc: |
  # ChIP-Seq basic analysis workflow for single-read data

  Reads are aligned to the reference genome with [Bowtie](http://bowtie-bio.sourceforge.net/index.shtml). Results are saved as coordinate sorted [BAM](http://samtools.github.io/hts-specs/SAMv1.pdf) alignment and index BAI files. Optionally, PCR duplicates can be removed. To obtain coverage in [bigWig](https://genome.ucsc.edu/goldenpath/help/bigWig.html) format, average fragment length is calculated by [MACS2](https://github.com/taoliu/MACS), and individual reads are extended to this length in the 3’ direction. Areas of enrichment identified by MACS2 are saved in ENCODE [narrow peak](http://genome.ucsc.edu/FAQ/FAQformat.html#format12) or [broad peak](https://genome.ucsc.edu/FAQ/FAQformat.html#format13) formats. Called peaks together with the nearest genes are saved in TSV format. In addition to basic statistics (number of total/mapped/multi-mapped/unmapped/duplicate reads), pipeline generates several quality control measures. Base frequency plots are used to estimate adapter contamination, a frequent occurrence in low-input ChIP-Seq experiments. Expected distinct reads count from [Preseq](http://smithlabresearch.org/software/preseq/) can be used to estimate read redundancy for a given sequencing depth. Average tag density profiles can be used to estimate ChIP enrichment for promoter proximal histone modifications. Use of different parameters for different antibodies (calling broad or narrow peaks) is possible. Additionally, users can elect to use BAM file from another experiment as control for MACS2 peak calling.

  ## Cite as

  *Kartashov AV, Barski A. BioWardrobe: an integrated platform for analysis of epigenomics and transcriptomics data. Genome Biol. 2015;16(1):158. Published 2015 Aug 7. [doi:10.1186/s13059-015-0720-3](https://www.ncbi.nlm.nih.gov/pubmed/26248465)*

  ## Software versions

  - Bowtie 1.2.0
  - Samtools 1.4
  - Preseq 2.0
  - MACS2 2.1.1.20160309
  - Bedtools 2.26.0
  - UCSC userApps v358

  ## Inputs

  | ID                        | Label                                          | Description                                                                                                                                                      | Required | Default | Upstream analyses               |
  | ------------------------- | ---------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------: | ------- | ------------------------------- |
  | **fastq\_file**           | FASTQ file                                     | Single-read sequencing data in FASTQ format (fastq, fq, bzip2, gzip, zip)                                                                                        |    +     |         |                                 |
  | **indices\_folder**       | Genome indices                                 | Directory with the genome indices generated by Bowtie                                                                                                            |    +     |         | genome\_indices/bowtie\_indices |
  | **annotation\_file**      | Genome annotation file                         | Genome annotation file in TSV format                                                                                                                             |    +     |         | genome\_indices/annotation      |
  | **genome\_size**          | Effective genome size                          | The length of the mappable genome (hs, mm, ce, dm or number, for example 2.7e9)                                                                                  |    +     |         | genome\_indices/genome\_size    |
  | **chrom\_length**         | Chromosome lengths file                        | Chromosome lengths file in TSV format                                                                                                                            |    +     |         | genome\_indices/chrom\_length   |
  | **broad\_peak**           | Call broad peaks                               | Make MACS2 call broad peaks by linking nearby highly enriched regions                                                                                            |    +     |         |                                 |
  | **control\_file**         | Control ChIP-Seq single-read experiment        | Indexed BAM file from the ChIP-Seq single-read experiment to be used as a control for MACS2 peak calling                                                         |          | Null    | control\_file/bambai\_pair      |
  | **exp\_fragment\_size**   | Expected fragment size                         | Expected fragment size for read extenstion towards 3' end if *force\_fragment\_size* was set to True or if calculated by MACS2 fragment size was less that 80 bp |          | 150     |                                 |
  | **force\_fragment\_size** | Force peak calling with expected fragment size | Make MACS2 don't build the shifting model and use expected fragment size for read extenstion towards 3' end                                                      |          | False   |                                 |
  | **clip\_3p\_end**         | Clip from 3' end                               | Number of base pairs to clip from 3' end                                                                                                                         |          | 0       |                                 |
  | **clip\_5p\_end**         | Clip from 5' end                               | Number of base pairs to clip from 5' end                                                                                                                         |          | 0       |                                 |
  | **remove\_duplicates**    | Remove PCR duplicates                          | Remove PCR duplicates from sorted BAM file                                                                                                                       |          | False   |                                 |
  | **threads**               | Number of threads                              | Number of threads for those steps that support multithreading                                                                                                    |          | 2       |                                 |


  ## Outputs

  | ID                       | Label                              | Description                                                                          | Required | Visualization                                                      |
  | ------------------------ | ---------------------------------- | ------------------------------------------------------------------------------------ | :------: | ------------------------------------------------------------------ |
  | **fastx\_statistics**    | FASTQ quality statistics           | FASTQ quality statistics in TSV format                                               |    +     | *Base Frequency* and *Quality Control* plots in *QC Plots* tab     |
  | **bambai\_pair**         | Aligned reads                      | Coordinate sorted BAM alignment and index BAI files                                  |    +     | *Nucleotide Sequence Alignments* track in *IGV Genome Browser* tab |
  | **bigwig**               | Genome coverage                    | Genome coverage in bigWig format                                                     |    +     | *Genome Coverage* track in *IGV Genome Browser* tab                |
  | **iaintersect\_result**  | Gene annotated peaks               | MACS2 peak file annotated with nearby genes                                          |    +     | *Peak Coordinates* table in *Peak Calling* tab                     |
  | **atdp\_result**         | Average Tag Density Plot           | Average Tag Density Plot file in TSV format                                          |    +     | *Average Tag Density Plot* in *QC Plots* tab                       |
  | **macs2\_called\_peaks** | Called peaks                       | Called peaks file with 1-based coordinates in XLS format                             |    +     |                                                                    |
  | **macs2\_narrow\_peaks** | Narrow peaks                       | Called peaks file in ENCODE narrow peak format                                       |          | *Narrow peaks* track in *IGV Genome Browser* tab                   |
  | **macs2\_broad\_peaks**  | Broad peaks                        | Called peaks file in ENCODE broad peak format                                        |          | *Broad peaks* track in *IGV Genome Browser* tab                    |
  | **preseq\_estimates**    | Expected Distinct Reads Count Plot | Expected distinct reads count file from Preseq in TSV format                         |          | *Expected Distinct Reads Count Plot* in *QC Plots* tab             |
  | **workflow\_statistics** | Workflow execution statistics      | Overall workflow execution statistics from bowtie\_aligner and samtools\_rmdup steps |    +     | *Overview* tab and experiment's preview                            |
  | **bowtie\_log**          | Read alignment log                 | Read alignment log file from Bowtie                                                  |    +     |                                                                    |