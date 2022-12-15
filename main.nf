include { rfam } from './workflows/rfam'
include { pfam } from './workflows/pfam'

process split_alignments {
  tag { "$source-$kind" }
  container params.containers.analysis

  input:
  tuple val(source), val(kind), path(alignment)

  input:
  tuple val(source), val(kind), path('alignments/*.sto')

  """
  mkdir alignments
  esl-afetch --index "$alignment"
  grep '^#=GF ID' "$alignment" | awk '{ print \$3 }' > ids
  split \
    --filter 'esl-afetch -f "$alignment" - >> "$FILE"' \
    --additional-suffix='.sto' \
    --lines=4000 \
    ids "alignments/${source}-${kind}-"
  """
}

process alignment_stats {
  tag { "$source-$kind" }
  publishDir 'data/', mode: 'copy'
  container params.containers.analysis
  memory { kind == 'full' ? 10.GB : 2.GB }

  input:
  tuple val(source), val(kind), path(alignment)

  output:
  tuple val(source), val(kind), path("${source}-${kind}.stats.csv")

  script:
  /* kind = source.toLowerCase().startsWith('rfam') ? 'rna' : 'amino' */
  /* esl-alistat --small --${kind} --informat pfam -1 $alignment \ */
  """
  esl-alistat -1 $alignment > alistat

  sed 's/# idx/idx/' alistat \
  | grep -v '^#' \
  | mlr --ipprint --ocsv cat \
  | mlr --csv clean-whitespace > ${source}-${kind}.stats.csv
  """
}

process merge_stats {
  tag { "$source-$kind" }
  container params.containers.analysis

  input:
  tuple val(source), val(kind), path('raw*.csv')

  input:
  tuple val(source), val(kind), path("${source}-${kind}.csv")

  """
  mlr --csv cat raw*.csv >"${source}-${kind}.csv"
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
  | mlr --ixtab --ocsv cut -o -f 'AC,ID,DE,TP' > ${source}.families-info.csv
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
  mlr --csv join -j ID -l ID -r name -f $info $stats \
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
  | split_alignments \
  | alignment_stats \
  | groupBy(by: [0, 1]) \
  | merge_stats \
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
