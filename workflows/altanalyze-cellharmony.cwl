cwlVersion: v1.0
class: Workflow


requirements:
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: MultipleInputFeatureRequirement


'sd:upstream':
  sc_rnaseq_sample:
  - "single-cell-preprocess-cellranger.cwl"
  - "cellranger-aggr.cwl"
  altanalyze_icgs_sample:
  - "altanalyze-icgs.cwl"
  altanalyze_prepare_genome_sample:
  - "altanalyze-prepare-genome.cwl"


inputs:

  alias:
    type: string
    label: "Experiment short name/Alias"
    sd:preview:
      position: 1

  genome_data:
    type: Directory
    label: "AltAnalyze Prepare Genome Experiment"
    doc: "Ensembl database from the altanalyze-prepare-genome.cwl pipeline"
    'sd:upstreamSource': "altanalyze_prepare_genome_sample/genome_data"
    'sd:localLabel': true

  filtered_feature_bc_matrix_h5:
    type: File
    label: "scRNA-Seq Cell Ranger Experiment"
    doc: "Filtered feature-barcode matrices in HDF5 format from cellranger count or aggr results"
    'sd:upstreamSource': "sc_rnaseq_sample/filtered_feature_bc_matrix_h5"
    'sd:localLabel': true

  reference_marker_heatmap_file:
    type: File
    label: "AltAnalyze ICGS Experiment"
    doc: "AltAnalyze ICGS Marker Gene Heatmap"
    'sd:upstreamSource': "altanalyze_icgs_sample/icgs_marker_heatmap_file"
    'sd:localLabel': true

  reference_annotation_metadata_file:
    type: File
    label: "AltAnalyze ICGS Experiment"
    doc: "AltAnalyze ICGS Annotation Metadata"
    'sd:upstreamSource': "altanalyze_icgs_sample/icgs_annotation_metadata_file"
    'sd:localLabel': true

  reference_expression_matrix_file:
    type: File
    label: "AltAnalyze ICGS Experiment"
    doc: "AltAnalyze ICGS Expression Matrix"
    'sd:upstreamSource': "altanalyze_icgs_sample/expression_matrix_file"
    'sd:localLabel': true

  align_by:
    type:
    - "null"
    - type: enum
      symbols:
      - "centroid"
      - "cell"
    default: "centroid"
    label: "Aligning algorithm"
    doc: "Aligning to cluster centroid or cell"
    'sd:layout':
      advanced: true

  correlation_threshold:
    type: float?
    default: 0.4
    label: "Pearson correlation threshold"      
    doc: "Pearson correlation threshold"
    'sd:layout':
      advanced: true

  perform_diff_expression:
    type: boolean?
    default: false
    label: "Perform differential expression analysis"
    doc: "Perform differential expression analysis"
    'sd:layout':
      advanced: true

  diff_expr_fold_change_threshold:
    type: float?
    default: 1.5
    label: "Differential expression fold-change threshold"
    doc: |
      Differential expression fold-change threshold.
      Applied if running differential expression
    'sd:layout':
      advanced: true

  diff_expr_p_value_threshold:
    type: float?
    default: 0.05
    label: "Cutoff value for P-value of P-adjusted-value"
    doc: |
      Cutoff value for P-value of P-adjusted-value.
      Applied if running differential expression
    'sd:layout':
      advanced: true

  use_adjusted_pvalue:
    type: boolean?
    default: true
    label: "Use adjusted P-value for differentially expressed genes threshold"
    doc: |
      Use adjusted P-value for differentially expressed genes threshold.
      Applied if running differential expression
    'sd:layout':
      advanced: true


outputs:

  compressed_cellharmony_data_folder:
    type: File
    outputSource: compress_cellharmony_data_folder/compressed_folder
    label: "Compressed folder with AltAnalyze CellHarmony results"
    doc: |
      Compressed folder with AltAnalyze CellHarmony results

  cellharmony_stdout_log:
    type: File
    outputSource: altanalyze_cellharmony/stdout_log
    label: stdout log generated by altanalyze cellharmony
    doc: |
      stdout log generated by altanalyze cellharmony

  cellharmony_stderr_log:
    type: File
    outputSource: altanalyze_cellharmony/stderr_log
    label: stderr log generated by altanalyze cellharmony
    doc: |
      stderr log generated by altanalyze cellharmony


steps:

  altanalyze_cellharmony:
    run: ../tools/altanalyze-cellharmony.cwl
    in:
      genome_data: genome_data
      query_feature_bc_matrices_h5: filtered_feature_bc_matrix_h5
      reference_marker_heatmap_file: reference_marker_heatmap_file
      reference_annotation_metadata_file: reference_annotation_metadata_file
      reference_expression_matrix_file: reference_expression_matrix_file
      align_by: align_by
      correlation_threshold: correlation_threshold
      perform_diff_expression: perform_diff_expression
      diff_expr_fold_change_threshold: diff_expr_fold_change_threshold
      diff_expr_p_value_threshold: diff_expr_p_value_threshold
      use_adjusted_pvalue: use_adjusted_pvalue
    out:
    - cellharmony_data
    - stdout_log
    - stderr_log

  compress_cellharmony_data_folder:
    run: ../tools/tar-compress.cwl
    in:
      folder_to_compress: altanalyze_cellharmony/cellharmony_data
    out:
    - compressed_folder


$namespaces:
  s: http://schema.org/

$schemas:
- https://github.com/schemaorg/schemaorg/raw/main/data/releases/11.01/schemaorg-current-http.rdf

s:name: "Deprecated. AltAnalyze CellHarmony"
label: "Deprecated. AltAnalyze CellHarmony"
s:alternateName: "Runs cell-level matching and comparison of single-cell transcriptomes for AltAnalyze ICGS, Cell Ranger Count Gene Expression or Cell Ranger Aggregate experiments"

s:downloadUrl: https://raw.githubusercontent.com/datirium/workflows/master/workflows/altanalyze-cellharmony.cwl
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
      s:legalName: "Barnski Research Lab"
      s:member:
      - class: s:Person
        s:name: Michael Kotliar  
        s:email: mailto:misha.kotliar@gmail.com
        s:sameAs:
        - id: http://orcid.org/0000-0002-6486-3898


doc: |
  Deprecated. AltAnalyze CellHarmony
