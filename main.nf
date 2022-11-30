process fetch_rfam_seed {
  output:
  tuple val('Rfam seed'), path('rfam.seed')

  """
  wget -O - 'https://ftp.ebi.ac.uk/pub/databases/Rfam/14.9/Rfam.seed.gz' | gzip -d > rfam.seed
  """
}

process fetch_pfam_seed {
  publishDir 'data/', mode: 'copy'

  output:
  tuple val('Pfam seed'), path('pfam.seed')

  """
  wget -O - 'http://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam35.0/Pfam-A.seed.gz' | gzip -d > pfam.seed
  """
}

process seed_stats {
  tag { "$source" }

  publishDir 'data/', mode: 'copy'

  input:
  tuple val(source), path(seed)

  output:
  tuple val(source), path("${seed}"), emit: seed
  tuple val(source), path("${seed.baseName}.stats.csv"), emit: stats
  tuple val(source), path("${seed.baseName}.cinfo"), emit: cinfo

  """
  esl-alistat \
    --cinfo ${seed.baseName}.cinfo \
    -1 \
    $seed \
  | sed 's/# idx/idx/' \
  | grep -v '^#' \
  | mlr --ipprint --ocsv cat \
  | mlr --csv clean-whitespace > ${seed.baseName}.stats.csv
  """
}

process compute_family_stats {
  tag { "$source" }

  publishDir 'data/', mode: 'copy'

  input:
  tuple val(source), path(seed), path(csv)

  output:
  tuple val(source), path("${seed.baseName}.family.csv")

  """
  grep '^#=GF\\|//' ${seed} |\
  sed -e 's|#=GF ||' -e 's|^//|\\n|' |\
  grep -v '^CC' |\
  sed -e 's|DR   \\(\\w\\+\\);|\\1   |' |\
  uniq |\
  mlr --xtab clean-whitespace |\
  mlr --ixtab --ocsv cut -o -f 'AC,ID,DE,TP' > family.csv

  xsv join ID family.csv name $csv \
  | xsv select 'AC,ID,DE,TP,alen,nseq,nres,small,large,avlen,%id' \
  | mlr --csv rename 'AC,rfam_acc,ID,id,TP,rna_type,DE,description,alen,number_of_columns,nseq,number_seqs,nres,number_residues,small,small,large,large,avlen,average_length,%id,percent_identity' \
  | mlr --csv put '\$source="$source"' > ${seed.baseName}.family.csv
  """
}

process merge_family_stats {
  publishDir 'data/', mode: 'copy'

  input:
  path('raw*.csv')

  output:
  path('merged.csv')

  """
  xsv cat rows raw*.csv > merged.csv
  """
}

process create_family_plots {
  publishDir 'plots/', mode: 'copy'

  input:
  path(merged)

  output:
  path("*.png")

  """
  plot.R
  """
}

workflow {
  (fetch_rfam_seed & fetch_pfam_seed) \
  | mix \
  | seed_stats

  seed_stats.out.seed \
  | join(seed_stats.out.stats) \
  | compute_family_stats \
  | map { source, data -> data } \
  | collect \
  | merge_family_stats \
  | create_family_plots
}
