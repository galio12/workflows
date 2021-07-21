cwlVersion: v1.0
class: Workflow


requirements:
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: MultipleInputFeatureRequirement


'sd:upstream':
  genome_indices:
    - "genome-indices.cwl"


inputs:

  alias:
    type: string
    label: "Experiment short name/Alias"
    sd:preview:
      position: 1

  genome_fasta_file:
    type: File
    format: "http://edamontology.org/format_1929"
    label: "Genome type"
    doc: "Reference genome FASTA file that includes all chromosomes"
    'sd:upstreamSource': "genome_indices/fasta_output"
    'sd:localLabel': true

  annotation_gtf_file:
    type: File
    format: "http://edamontology.org/format_2306"
    label: "Genome type"
    doc: "GTF annotation file that includes refGene and mitochondrial DNA annotations"
    'sd:upstreamSource': "genome_indices/annotation_gtf"
    'sd:localLabel': true

  threads:
    type: int?
    default: 4
    label: "Number of threads"
    doc: "Number of threads for those steps that support multithreading"
    'sd:layout':
      advanced: true

  memory_limit:
    type: int?
    default: 20
    label: "Maximum memory used (GB)"
    doc: "Maximum memory used (GB). The same will be applied to virtual memory"
    'sd:layout':
      advanced: true


outputs:

  indices_folder:
    type: Directory
    outputSource: cellranger_mkref/indices_folder
    label: Cell Ranger genome indices
    doc: |
      Cell Ranger generated genome indices folder

  stdout_log:
    type: File
    outputSource: cellranger_mkref/stdout_log
    label: stdout log generated by cellranger mkref
    doc: |
      stdout log generated by cellranger mkref

  stderr_log:
    type: File
    outputSource: cellranger_mkref/stderr_log
    label: stderr log generated by cellranger mkref
    doc: |
      stderr log generated by cellranger mkref

  arc_indices_folder:
    type: Directory
    outputSource: cellranger_arc_mkref/indices_folder
    label: Cell Ranger ARC genome indices
    doc: |
      Cell Ranger ARC generated genome indices folder

  arc_stdout_log:
    type: File
    outputSource: cellranger_arc_mkref/stdout_log
    label: stdout log generated by cellranger-arc mkref
    doc: |
      stdout log generated by cellranger-arc mkref

  arc_stderr_log:
    type: File
    outputSource: cellranger_arc_mkref/stderr_log
    label: stderr log generated by cellranger-arc mkref
    doc: |
      stderr log generated by cellranger-arc mkref


steps:

  cellranger_mkref:
    run: ../tools/cellranger-mkref.cwl
    in:
      genome_fasta_file: genome_fasta_file
      annotation_gtf_file: annotation_gtf_file
      threads: threads
      memory_limit: memory_limit
    out:
    - indices_folder
    - stdout_log
    - stderr_log

  sort_annotation_gtf:
    # Cell Ranger ARC fails to run with UCSC Refgene annotation
    # if records are not grouped by gene_id - due to duplicates
    # in gene_ids.
    run:
      cwlVersion: v1.0
      class: CommandLineTool
      hints:
      - class: DockerRequirement
        dockerPull: python:3.8.6
      inputs:
        script:
          type: string?
          default: |
            #!/usr/bin/env python3
            import re
            import fileinput
            class Gtf(object):
              def __init__(self, gtf_line):
                self.gtf_list = gtf_line.split("\t")
                self.attribute = self.gtf_list[8]
                tmp = map(lambda x: re.split("\s+", x.replace('"', "")), re.split("\s*;\s*", self.attribute.strip().strip(";")))
                self.attribute = dict([x for x in tmp if len(x)==2])
              def __str__(self):
                return "\t".join(self.gtf_list)
            records = []
            for gtf_line in fileinput.input():
              records.append(Gtf(gtf_line))
            records.sort(key=lambda x: (x.attribute["gene_id"]))
            for l in records:
              print(l, end="")
          inputBinding:
            position: 5
        annotation_gtf_file:
          type: File
          inputBinding:
            position: 6
      outputs:
        sorted_annotation_gtf_file:
          type: stdout
      baseCommand: ["python3", "-c"]
      stdout: "sorted.gtf"
    in:
      annotation_gtf_file: annotation_gtf_file
    out:
    - sorted_annotation_gtf_file

  cellranger_arc_mkref:
    run: ../tools/cellranger-arc-mkref.cwl
    in:
      genome_fasta_file: genome_fasta_file
      annotation_gtf_file: sort_annotation_gtf/sorted_annotation_gtf_file
      exclude_chr:
        default: ["chrM"]                        # as recommended in Cell Ranger ARC manual
      threads: threads
      memory_limit: memory_limit
    out:
    - indices_folder
    - stdout_log
    - stderr_log


$namespaces:
  s: http://schema.org/

$schemas:
- https://github.com/schemaorg/schemaorg/raw/main/data/releases/11.01/schemaorg-current-http.rdf

s:name: "Cell Ranger Build Reference Indices"
label: "Cell Ranger Build Reference Indices"
s:alternateName: "Builds reference genome indices for Cell Ranger Gene Expression and Cell Ranger Multiome ATAC + Gene Expression experiments"

s:downloadUrl: https://raw.githubusercontent.com/datirium/workflows/master/workflows/cellranger-mkref.cwl
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
        s:name: Michael Kotliar
        s:email: mailto:misha.kotliar@gmail.com
        s:sameAs:
        - id: http://orcid.org/0000-0002-6486-3898


doc: |
  Cell Ranger Build Reference Indices
  ===================================