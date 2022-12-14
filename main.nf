include { rfam } from './workflows/rfam'
include { pfam } from './workflows/pfam'

process alignment_stats {
  tag { "$source-$kind" }
  publishDir 'data/', mode: 'copy'
  container params.containers.analysis
  memory { source == 'Rfam' && kind == 'full' ? 10.GB : 2.GB }

  input:
  tuple val(source), val(kind), path(alignment)

  output:
  tuple val(source), val(kind), path("${alignment.baseName}.stats.csv")

  script:
  /* kind = source.toLowerCase().startsWith('rfam') ? 'rna' : 'amino' */
  /* esl-alistat --small --${kind} --informat pfam -1 $alignment \ */
  """
  esl-alistat -1 $alignment > alistat

  sed 's/# idx/idx/' alistat \
  | grep -v '^#' \
  | mlr --ipprint --ocsv cat \
  | mlr --csv clean-whitespace > ${alignment.baseName}.stats.csv
  """
}

process extract_family_info {
  tag { "$source" }
  publishDir 'data/', mode: 'copy'
  container params.containers.analysis

  input:
  tuple val(source), path(alignment)

  output:
  tuple val(source), path("${source}.families-info.csv")

  """
  grep '^#=GF\\|//' ${alignment} \
  | sed -e 's|#=GF ||' -e 's|^//|\\n|' \
  | grep -v '^CC' \
  | sed -e 's|DR   \\(\\w\\+\\);|\\1   |' \
  | uniq \
  | mlr --xtab clean-whitespace \
  | mlr --ixtab --ocsv cut -o -f 'AC,DE,TP' > ${source}.families-info.csv
  """
}

process combine_stats {
  tag { "$source-$kind" }
  publishDir 'data/', mode: 'copy'
  container params.containers.analysis

  input:
  tuple val(source), val(kind), path(stats), path(info)

  output:
  tuple val(source), val(kind), path("${source}.${kind}.families.csv")

  """
  mlr --csv join -j AC -l AC -r name -f $info $stats \
  | mlr --csv cut -f 'AC,DE,TP,alen,nseq,nres,small,large,avlen,%id' \
  | mlr --csv rename 'AC,rfam_acc,TP,rna_type,DE,description,alen,number_of_columns,nseq,number_seqs,nres,number_residues,small,small,large,large,avlen,average_length,%id,percent_identity' \
  | mlr --csv put '\$source="$source $kind"' > ${source}.${kind}.families.csv
  """
}

process merge_family_stats {
  publishDir 'data/', mode: 'copy'
  container params.containers.analysis

  input:
  path('raw*.csv')

  output:
  path('merged.csv')

  """
  mlr --csv cat raw*.csv > merged.csv
  """
}

process create_family_plots {
  publishDir 'plots/', mode: 'copy'
  container params.containers.plot

  input:
  tuple path(merged), path(rfam_structures)

  output:
  path("*.png")

  """
  plot.R $merged $rfam_structures
  """
}

workflow {
  rfam()
  pfam()

  rfam.out.seeds.mix(pfam.out.seeds) | set { seed }
  rfam.out.full.mix(pfam.out.full) | set { full }

  seed \
  | map { source, kind, align -> [source, align] } \
  | extract_family_info \
  | set { family_info }

  seed.mix(full) \
  | alignment_stats \
  | set { stats }

  stats \
  | join(family_info) \
  | combine_stats \
  | map { source, kind, data -> data } \
  | collect \
  | merge_family_stats \
  | combine(rfam.out.structures)
  | create_family_plots
}
