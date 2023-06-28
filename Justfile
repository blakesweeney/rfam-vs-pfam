docker:
  #!/usr/bin/env bash
  set -euxo pipefail

  pushd containers/analysis/
  docker buildx build -t bsweeneyebi/rfam-pfam-analysis --platform linux/amd64 .
  docker push bsweeneyebi/rfam-pfam-analysis
  popd

plot: plot_rfam_pfam plot_metrics plot_counts plot_pdb_summary plot_pdb_counts plot_puzzle_quality plot_pdb_nt_resolution plot_figures

plot_rfam_pfam:
  rm -r plots/rfam-vs-pfam 2>/dev/null || true
  mkdir -p plots/rfam-vs-pfam
  bin/plot-rfam-pfam.R data/rfam-vs-pfam-counts.csv data/rfam.structures.csv plots/rfam-vs-pfam

plot_metrics:
  rm -r plots/metrics 2>/dev/null
  mkdir -p plots/metrics
  bin/plot-metrics.R data/puzzles-metrics.csv plots/metrics

plot_counts:
  rm -r plots/counts 2>/dev/null || true
  mkdir -p plots/counts
  bin/plot-counts.R data/protein-vs-rna-counts.csv plots/counts

plot_pdb_summary:
  rm -r plots/pdb_summary 2>/dev/null || true
  mkdir -p plots/pdb_summary
  bin/plot-pdb-summary.R data/pdb-by-year.csv plots/pdb_summary

plot_pdb_nt_resolution:
  rm -r plots/pdb_nt_resolution 2>/dev/null || true
  mkdir -p plots/pdb_nt_resolution
  bin/plot-pdb-nt-resolution.R data/pdb-by-resolution.csv plots/pdb_nt_resolution

plot_pdb_counts:
  rm -r plots/pdb_counts 2>/dev/null || true
  mkdir -p plots/pdb_counts
  bin/plot-pdb-counts.R data/pdb-counts.csv plots/pdb_counts

plot_puzzle_quality:
  rm -r plots/puzzle-quality || true
  mkdir -p plots/puzzle-quality
  bin/plot_rna_puzzle_quality.R data/puzzle-quality.csv plots/puzzle-quality

plot_figures:
  rm -r plots/figures || true
  mkdir -p plots/figures
  bin/figure-2.R data/puzzle-quality.csv data/puzzle-counts.tsv plots/figures
  bin/figure-3.R data/protein-vs-rna-counts.csv plots/figures
  bin/figure-5.R data/rfam-vs-pfam-counts.csv data/rfam.structures.csv plots/figures
  bin/figure-6.R data/rfam-vs-pfam-counts.csv data/rfam.structures.csv plots/figures
  bin/rfam-growth.R data/rfam-growth.csv plots/figures
