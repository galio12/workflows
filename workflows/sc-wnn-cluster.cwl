cwlVersion: v1.0
class: Workflow


requirements:
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: MultipleInputFeatureRequirement
  - class: InlineJavascriptRequirement
    expressionLib:
    - var split_features = function(line) {
          function get_unique(value, index, self) {
            return self.indexOf(value) === index && value != "";
          }
          let splitted_line = line?line.split(/[\s,]+/).filter(get_unique):null;
          return (splitted_line && !!splitted_line.length)?splitted_line:null;
      };
    - var split_numbers = function(line) {
          let splitted_line = line?line.split(/[\s,]+/).map(parseFloat):null;
          return (splitted_line && !!splitted_line.length)?splitted_line:null;
      };


'sd:upstream':
  sc_tools_sample:
  - "sc-wnn-cluster.cwl"
  - "sc-rna-cluster.cwl"
  - "sc-atac-cluster.cwl"
  - "sc-rna-reduce.cwl"
  - "sc-atac-reduce.cwl"
  sc_arc_sample:
  - "cellranger-arc-count.cwl"
  - "cellranger-arc-aggr.cwl"


inputs:

  alias:
    type: string
    label: "Analysis name"
    sd:preview:
      position: 1

  query_data_rds:
    type: File
    label: "Single-cell Analysis with both PCA and LSI Transformed Datasets"
    doc: |
      Analysis that includes single-cell
      multiome RNA and ATAC-Seq datasets
      run through both "Single-Cell
      RNA-Seq Dimensionality Reduction
      Analysis" and "Single-Cell ATAC-Seq
      Dimensionality Reduction Analysis"
      at any of the processing stages.
    'sd:upstreamSource': "sc_tools_sample/seurat_data_rds"
    'sd:localLabel': true

  atac_fragments_file:
    type: File?
    secondaryFiles:
    - .tbi
    label: "Cell Ranger RNA+ATAC Sample (optional)"
    doc: |
      Any "Cell Ranger ATAC or RNA+ATAC Sample"
      for generating ATAC fragments coverage
      plots over the genes of interest. This
      sample can be obtained from either
      "Cell Ranger Count (RNA+ATAC)" or "Cell
      Ranger Aggregate (RNA+ATAC)" pipeline
    'sd:upstreamSource': "sc_arc_sample/atac_fragments_file"
    'sd:localLabel': true

  rna_dimensions:
    type: int?
    default: 40
    label: "Target RNA dimensionality"
    doc: |
      Number of principal components to be used
      in constructing weighted nearest-neighbor
      graph before clustering. Accepted values
      range from 1 to 50.
      Default: 40

  atac_dimensions:
    type: int?
    default: 40
    label: "Target ATAC dimensionality"
    doc: |
      Number of LSI components to be used in
      constructing weighted nearest-neighbor
      graph before clustering. Accepted values
      range from 2 to 50. First dimension is
      always excluded
      Default: 40

  resolution:
    type: float?
    default: 0.3
    label: "Clustering resolution"
    doc: |
      Resolution to define the "granularity"
      of the clustered data. Larger values
      lead to a bigger number of clusters.
      Optimal resolution often increases
      with the number of cells.
      Default: 0.3

  identify_diff_genes:
    type: boolean?
    default: true
    label: "Find gene markers"
    doc: |
      Identify upregulated genes in each
      cluster compared to all other cells.
      Include only genes that are expressed
      in at least 10% of the cells coming
      from either current cluster or from
      all other clusters together.
      Exclude cells with log2FoldChange
      values less than 0.25. Use Wilcoxon
      Rank Sum test to calculate P-values.
      Keep only genes with P-values lower
      than 0.01. Adjust P-values for multiple
      comparisons using Bonferroni correction.
      Default: true

  identify_diff_peaks:
    type: boolean?
    default: false
    label: "Find peak markers"
    doc: |
      Identify differentially accessible
      peaks in each cluster compared to
      all other cells. Include only peaks
      that are present in at least 5% of
      the cells coming from either current
      cluster or from all other clusters
      together. Exclude cells with
      log2FoldChange values less than 0.25.
      Use logistic regression framework to
      calculate P-values. Keep only genes
      with P-values lower than 0.01. Adjust
      P-values for multiple comparisons
      using Bonferroni correction.
      Default: false

  genes_of_interest:
    type: string?
    default: null
    label: "Genes of interest"
    doc: |
      Comma or space separated list of genes
      of interest to visualize expression and
      to generate ATAC fragments coverage plots.
      Ignored if "Cell Ranger RNA+ATAC Sample
      (optional)" input is not provided.
      Default: None

  color_theme:
    type:
    - "null"
    - type: enum
      symbols:
      - "gray"
      - "bw"
      - "linedraw"
      - "light"
      - "dark"
      - "minimal"
      - "classic"
      - "void"
    default: "classic"
    label: "Plots color theme"
    doc: |
      Color theme for all plots saved
      as PNG files.
      Default: classic
    "sd:layout":
      advanced: true

  threads:
    type:
    - "null"
    - type: enum
      symbols:
      - "1"
      - "2"
      - "3"
      - "4"
      - "5"
      - "6"
    default: "1"
    label: "Cores/CPUs"
    doc: |
      Parallelization parameter to define the
      number of cores/CPUs that can be utilized
      simultaneously.
      Default: 1
    "sd:layout":
      advanced: true


outputs:

  umap_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/umap_res_plot_png
    label: "UMAP, colored by cluster"
    doc: |
      UMAP, colored by cluster
    'sd:visualPlugins':
    - image:
        tab: 'Per cluster'
        Caption: 'UMAP, colored by cluster'

  umap_spl_ph_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/umap_spl_ph_res_plot_png
    label: "UMAP, colored by cluster, split by cell cycle phase"
    doc: |
      UMAP, colored by cluster,
      split by cell cycle phase
    'sd:visualPlugins':
    - image:
        tab: 'Per cluster'
        Caption: 'UMAP, colored by cluster, split by cell cycle phase'

  cmp_gr_ph_spl_clst_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/cmp_gr_ph_spl_clst_res_plot_png
    label: "Composition plot, colored by cell cycle phase, split by cluster, downsampled"
    doc: |
      Composition plot, colored by
      cell cycle phase, split by
      cluster, downsampled
    'sd:visualPlugins':
    - image:
        tab: 'Per cluster'
        Caption: 'Composition plot, colored by cell cycle phase, split by cluster, downsampled'

  umap_spl_idnt_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/umap_spl_idnt_res_plot_png
    label: "UMAP, colored by cluster, split by dataset"
    doc: |
      UMAP, colored by cluster,
      split by dataset
    'sd:visualPlugins':
    - image:
        tab: 'Per dataset'
        Caption: 'UMAP, colored by cluster, split by dataset'

  cmp_gr_clst_spl_idnt_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/cmp_gr_clst_spl_idnt_res_plot_png
    label: "Composition plot, colored by cluster, split by dataset, downsampled"
    doc: |
      Composition plot, colored by
      cluster, split by dataset,
      downsampled
    'sd:visualPlugins':
    - image:
        tab: 'Per dataset'
        Caption: 'Composition plot, colored by cluster, split by dataset, downsampled'

  cmp_gr_idnt_spl_clst_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/cmp_gr_idnt_spl_clst_res_plot_png
    label: "Composition plot, colored by dataset, split by cluster, downsampled"
    doc: |
      Composition plot, colored by
      dataset, split by cluster,
      downsampled
    'sd:visualPlugins':
    - image:
        tab: 'Per dataset'
        Caption: 'Composition plot, colored by dataset, split by cluster, downsampled'

  cmp_gr_ph_spl_idnt_plot_png:
    type: File?
    outputSource: sc_wnn_cluster/cmp_gr_ph_spl_idnt_plot_png
    label: "Composition plot, colored by cell cycle phase, split by dataset, downsampled"
    doc: |
      Composition plot, colored by
      cell cycle phase, split by
      dataset, downsampled
    'sd:visualPlugins':
    - image:
        tab: 'Per dataset'
        Caption: 'Composition plot, colored by cell cycle phase, split by dataset, downsampled'

  umap_spl_cnd_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/umap_spl_cnd_res_plot_png
    label: "UMAP, colored by cluster, split by grouping condition"
    doc: |
      UMAP, colored by cluster,
      split by grouping condition
    'sd:visualPlugins':
    - image:
        tab: 'Per group'
        Caption: 'UMAP, colored by cluster, split by grouping condition'

  cmp_gr_clst_spl_cnd_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/cmp_gr_clst_spl_cnd_res_plot_png
    label: "Composition plot, colored by cluster, split by grouping condition, downsampled"
    doc: |
      Composition plot, colored by
      cluster, split by grouping
      condition, downsampled
    'sd:visualPlugins':
    - image:
        tab: 'Per group'
        Caption: 'Composition plot, colored by cluster, split by grouping condition, downsampled'

  cmp_gr_cnd_spl_clst_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/cmp_gr_cnd_spl_clst_res_plot_png
    label: "Composition plot, colored by grouping condition, split by cluster, downsampled"
    doc: |
      Composition plot, colored by
      grouping condition, split by
      cluster, downsampled
    'sd:visualPlugins':
    - image:
        tab: 'Per group'
        Caption: 'Composition plot, colored by grouping condition, split by cluster, downsampled'

  xpr_avg_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/xpr_avg_res_plot_png
    label: "Gene expression dot plot"
    doc: |
      Gene expression dot plot
    'sd:visualPlugins':
    - image:
        tab: 'Genes of interest'
        Caption: 'Gene expression dot plot'

  xpr_dnst_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/xpr_dnst_res_plot_png
    label: "Gene expression violin plot"
    doc: |
      Gene expression violin plot
    'sd:visualPlugins':
    - image:
        tab: 'Genes of interest'
        Caption: 'Gene expression violin plot'

  xpr_per_cell_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/xpr_per_cell_plot_png
    label: "UMAP, gene expression"
    doc: |
      UMAP, gene expression
    'sd:visualPlugins':
    - image:
        tab: 'Genes of interest'
        Caption: 'UMAP, gene expression'

  xpr_htmp_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/xpr_htmp_res_plot_png
    label: "Gene expression heatmap"
    doc: |
      Gene expression heatmap
    'sd:visualPlugins':
    - image:
        tab: 'Heatmap'
        Caption: 'Gene expression heatmap'

  cvrg_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/cvrg_res_plot_png
    label: "ATAC fragments coverage"
    doc: |
      ATAC fragments coverage
    'sd:visualPlugins':
    - image:
        tab: 'Genome coverage'
        Caption: 'ATAC fragments coverage'

  xpr_htmp_res_tsv:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/xpr_htmp_res_tsv
    label: "Markers from gene expression heatmap"
    doc: |
      Gene markers used for gene
      expression heatmap

  gene_markers_tsv:
    type: File?
    outputSource: sc_wnn_cluster/gene_markers_tsv
    label: "Gene markers per cluster for all resolutions"
    doc: |
      Gene markers per cluster for
      all resolutions
    'sd:visualPlugins':
    - syncfusiongrid:
        tab: 'Gene markers'
        Title: 'Gene markers per cluster for all resolutions'

  peak_markers_tsv:
    type: File?
    outputSource: sc_wnn_cluster/peak_markers_tsv
    label: "Peak markers per cluster for all resolutions"
    doc: |
      Peak markers per cluster for
      all resolutions
    'sd:visualPlugins':
    - syncfusiongrid:
        tab: 'Peak markers'
        Title: 'Peak markers per cluster for all resolutions'

  ucsc_cb_html_data:
    type: Directory?
    outputSource: sc_wnn_cluster/ucsc_cb_html_data
    label: "UCSC Cell Browser data"
    doc: |
      Directory with UCSC Cell Browser
      data

  ucsc_cb_html_file:
    type: File?
    outputSource: sc_wnn_cluster/ucsc_cb_html_file
    label: "UCSC Cell Browser"
    doc: |
      UCSC Cell Browser HTML index file
    "sd:visualPlugins":
    - linkList:
        tab: "Overview"
        target: "_blank"

  seurat_data_rds:
    type: File
    outputSource: sc_wnn_cluster/seurat_data_rds
    label: "Processed Seurat data in RDS format"
    doc: |
      Processed Seurat data in RDS format

  seurat_data_scope:
    type: File?
    outputSource: sc_wnn_cluster/seurat_data_scope
    label: "Processed Seurat data in SCope compatible loom format"
    doc: |
      Processed Seurat data in SCope compatible loom format.
      Only not normalized raw counts from the RNA assay will
      be saved

  pdf_plots:
    type: File
    outputSource: compress_pdf_plots/compressed_folder
    label: "Plots in PDF format"
    doc: |
      Compressed folder with plots
      in PDF format

  sc_wnn_cluster_stdout_log:
    type: File
    outputSource: sc_wnn_cluster/stdout_log
    label: "stdout log generated by sc_wnn_cluster step"
    doc: |
      stdout log generated by sc_wnn_cluster step

  sc_wnn_cluster_stderr_log:
    type: File
    outputSource: sc_wnn_cluster/stderr_log
    label: "stderr log generated by sc_wnn_cluster step"
    doc: |
      stderr log generated by sc_wnn_cluster step


steps:

  sc_wnn_cluster:
    doc: |
      Clusters multiome ATAC and RNA-Seq datasets, identifies
      gene markers and differentially accessible peaks
    run: ../tools/sc-wnn-cluster.cwl
    in:
      query_data_rds: query_data_rds
      rna_dimensions: rna_dimensions
      atac_dimensions: atac_dimensions
      cluster_algorithm:
        default: "slm"
      resolution: resolution
      atac_fragments_file: atac_fragments_file
      genes_of_interest:
        source: genes_of_interest
        valueFrom: $(split_features(self))
      identify_diff_genes: identify_diff_genes
      identify_diff_peaks: identify_diff_peaks
      rna_minimum_logfc:
        default: 0.25
      rna_minimum_pct:
        default: 0.1
      atac_minimum_logfc:
        default: 0.25
      atac_minimum_pct:
        default: 0.05
      only_positive_diff_genes:
        default: true
      rna_test_to_use: 
        default: wilcox
      atac_test_to_use:
        default: LR
      verbose:
        default: true      
      export_ucsc_cb:
        default: true
      export_scope_data:
        default: true
      export_pdf_plots:
        default: true
      color_theme: color_theme
      parallel_memory_limit:
        default: 32
      vector_memory_limit:
        default: 96
      threads:
        source: threads
        valueFrom: $(parseInt(self))
    out:
    - umap_res_plot_png
    - umap_spl_idnt_res_plot_png
    - cmp_gr_clst_spl_idnt_res_plot_png
    - cmp_gr_idnt_spl_clst_res_plot_png
    - umap_spl_cnd_res_plot_png
    - cmp_gr_clst_spl_cnd_res_plot_png
    - cmp_gr_cnd_spl_clst_res_plot_png
    - umap_spl_ph_res_plot_png
    - cmp_gr_ph_spl_idnt_plot_png
    - cmp_gr_ph_spl_clst_res_plot_png
    - xpr_avg_res_plot_png
    - xpr_per_cell_plot_png
    - xpr_dnst_res_plot_png
    - cvrg_res_plot_png
    - xpr_htmp_res_plot_png
    - umap_res_plot_pdf
    - umap_spl_idnt_res_plot_pdf
    - cmp_gr_clst_spl_idnt_res_plot_pdf
    - cmp_gr_idnt_spl_clst_res_plot_pdf
    - umap_spl_cnd_res_plot_pdf
    - cmp_gr_clst_spl_cnd_res_plot_pdf
    - cmp_gr_cnd_spl_clst_res_plot_pdf
    - umap_spl_ph_res_plot_pdf
    - cmp_gr_ph_spl_idnt_plot_pdf
    - cmp_gr_ph_spl_clst_res_plot_pdf
    - xpr_avg_res_plot_pdf
    - xpr_per_cell_plot_pdf
    - xpr_per_cell_sgnl_plot_pdf
    - xpr_dnst_res_plot_pdf
    - cvrg_res_plot_pdf
    - xpr_htmp_res_plot_pdf
    - xpr_htmp_res_tsv
    - gene_markers_tsv
    - peak_markers_tsv
    - ucsc_cb_html_data
    - ucsc_cb_html_file
    - seurat_data_rds
    - seurat_data_scope
    - stdout_log
    - stderr_log

  folder_pdf_plots:
    run: ../tools/files-to-folder.cwl
    in:
      input_files:
        source:
        - sc_wnn_cluster/umap_res_plot_pdf
        - sc_wnn_cluster/umap_spl_idnt_res_plot_pdf
        - sc_wnn_cluster/cmp_gr_clst_spl_idnt_res_plot_pdf
        - sc_wnn_cluster/cmp_gr_idnt_spl_clst_res_plot_pdf
        - sc_wnn_cluster/umap_spl_cnd_res_plot_pdf
        - sc_wnn_cluster/cmp_gr_clst_spl_cnd_res_plot_pdf
        - sc_wnn_cluster/cmp_gr_cnd_spl_clst_res_plot_pdf
        - sc_wnn_cluster/umap_spl_ph_res_plot_pdf
        - sc_wnn_cluster/cmp_gr_ph_spl_idnt_plot_pdf
        - sc_wnn_cluster/cmp_gr_ph_spl_clst_res_plot_pdf
        - sc_wnn_cluster/xpr_avg_res_plot_pdf
        - sc_wnn_cluster/xpr_per_cell_plot_pdf
        - sc_wnn_cluster/xpr_per_cell_sgnl_plot_pdf
        - sc_wnn_cluster/xpr_dnst_res_plot_pdf
        - sc_wnn_cluster/cvrg_res_plot_pdf
        - sc_wnn_cluster/xpr_htmp_res_plot_pdf
        valueFrom: $(self.flat().filter(n => n))
      folder_basename:
        default: "pdf_plots"
    out:
    - folder

  compress_pdf_plots:
    run: ../tools/tar-compress.cwl
    in:
      folder_to_compress: folder_pdf_plots/folder
    out:
    - compressed_folder


$namespaces:
  s: http://schema.org/

$schemas:
- https://github.com/schemaorg/schemaorg/raw/main/data/releases/11.01/schemaorg-current-http.rdf

label: "Single-Cell WNN Cluster Analysis"
s:name: "Single-Cell WNN Cluster Analysis"
s:alternateName: "Clusters cells by similarity based on both gene expression and chromatin accessibility data"

s:downloadUrl: https://raw.githubusercontent.com/Barski-lab/workflows-datirium/master/workflows/sc-wnn-cluster.cwl
s:codeRepository: https://github.com/Barski-lab/workflows-datirium
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
  Single-Cell WNN Cluster Analysis

  Clusters cells by similarity based on both gene expression and
  chromatin accessibility data from the outputs of “Single-Cell
  RNA-Seq Dimensionality Reduction Analysis” and “Single-Cell
  ATAC-Seq Dimensionality Reduction Analysis” pipelines run
  sequentially. The results of this workflow are primarily used
  in “Single-Cell Manual Cell Type Assignment” pipeline.