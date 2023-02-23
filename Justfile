docker:
  #!/usr/bin/env bash
  set -euxo pipefail

  pushd containers/analysis/
  docker buildx build -t bsweeneyebi/rfam-pfam-analysis --platform linux/amd64 .
  docker push bsweeneyebi/rfam-pfam-analysis
  popd

plot: plot_rfam_pfam plot_metrics plot_counts plot_pdb_summary

plot_rfam_pfam:
  mkdir -p plots/rfam-vs-pfam 2>/dev/null || true
  bin/plot-rfam-pfam.R data/rfam-vs-pfam-counts.csv data/rfam.structures.csv plots/rfam-vs-pfam

plot_metrics:
  mkdir plots/metrics 2>/dev/null || true
  bin/plot-metrics.R data/puzzles-metrics.csv plots/metrics

plot_counts:
  mkdir plots/counts 2>/dev/null || true
  bin/plot-counts.R data/protein-vs-rna-counts.csv plots/counts

plot_pdb_summary:
  mkdir plots/pdb_summary 2>/dev/null || true
  bin/plot-pdb-summary.R data/pdb-by-year.csv plots/pdb_summary

plot_pdb_counts:
  mkdir plots/pdb_counts 2>/dev/null || true
  bin/plot-pdb-nt-resolution.R.R data/pdb-by-year.csv plots/pdb_counts
