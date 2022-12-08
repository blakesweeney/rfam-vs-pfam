process fetch_rfam_seed {
  output:
  tuple val('Rfam seed'), path('rfam.seed')

  """
  wget -O - 'https://ftp.ebi.ac.uk/pub/databases/Rfam/14.9/Rfam.seed.gz' | gzip -d > rfam.seed
  """
}

process fetch_rfam_structures {
  output:
  path('rfam.structures.csv')

  """
  wget -O - 'https://ftp.ebi.ac.uk/pub/databases/Rfam/.preview/pdb_full_region.txt.gz' \
  | gzip -d \
  | mlr --itsv --ocsv --implicit-csv-header label rfam_acc,pdb,chain,sequence_start,sequence_stop,bit_score,e_value,cm_start,cm_stop,hexcolor,is_significant \
  | mlr --csv filter '\$is_significant == "1"' > rfam.structures.csv
  """
}

process fetch_pfam_seed {
  output:
  tuple val('Pfam seed'), path('pfam.seed')

  """
  wget -O - 'http://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam35.0/Pfam-A.seed.gz' | gzip -d > pfam.seed
  """
}

process fetch_pfam_full {
  output:
  tuple val('Pfam full'), path('pfam.full')

  """
  wget -O - 'http://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam35.0/Pfam-A.full.gz' | gzip -d > pfam.full
  """
}

process compute_rfam_structure_counts {
  input:
  path(csv)

  output:
  path("rfam.structure_counts.csv")

  """
  mlr --csv count -g rfam_acc $csv \
  | mlr --csv rename 'count,number_of_structures' > rfam.structure_counts.csv
  """
}

process alignment_stats {
  publishDir 'data/', mode: 'copy'
  tag { "$source" }

  input:
  tuple val(source), path(alignment)

  output:
  tuple val(source), path("${alignment.baseName}.stats.csv")

  """
  esl-alistat -1 $alignment \
  | sed 's/# idx/idx/' \
  | grep -v '^#' \
  | mlr --ipprint --ocsv cat \
  | mlr --csv clean-whitespace > ${alignment.baseName}.stats.csv
  """
}

process extract_alignment_info {
  publishDir 'data/', mode: 'copy'
  tag { "$source" }

  input:
  tuple val(source), path(alignment)

  output:
  tuple val(source), path("${alignment.baseName}.info.csv")

  """
  grep '^#=GF\\|//' ${alignment} \
  | sed -e 's|#=GF ||' -e 's|^//|\\n|' \
  | grep -v '^CC' \
  | sed -e 's|DR   \\(\\w\\+\\);|\\1   |' \
  | uniq \
  | mlr --xtab clean-whitespace \
  | mlr --ixtab --ocsv cut -o -f 'AC,ID,DE,TP' > ${alignment.baseName}.info.csv
  """
}

process combine_stats {
  publishDir 'data/', mode: 'copy'
  tag { "$source" }

  input:
  tuple val(source), path(info), path(stats)

  output:
  tuple val(source), path("${info.baseName}.families.csv")

  """
  mlr --csv join -j ID -l ID -r name -f $info $stats \
  | mlr --csv cut -f 'AC,ID,DE,TP,alen,nseq,nres,small,large,avlen,%id' \
  | mlr --csv rename 'AC,rfam_acc,ID,id,TP,rna_type,DE,description,alen,number_of_columns,nseq,number_seqs,nres,number_residues,small,small,large,large,avlen,average_length,%id,percent_identity' \
  | mlr --csv put '\$source="$source"' > ${info.baseName}.families.csv
  """
}

process merge_family_stats {
  publishDir 'data/', mode: 'copy'

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

  input:
  tuple path(merged), path(rfam_structures)

  output:
  path("*.png")

  """
  plot.R $merged $rfam_structures
  """
}

workflow {
  (fetch_rfam_seed & fetch_pfam_seed) \
  | mix \
  | set { alignments }

  alignments | alignment_stats | set { stats }
  alignments | extract_alignment_info | set { info }

  fetch_rfam_structures \
  | compute_rfam_structure_counts \
  | set { rfam_structure_counts }

  info \
  | join(stats) \
  | combine_stats \
  | map { source, data -> data } \
  | collect \
  | merge_family_stats \
  | combine(rfam_structure_counts)
  | create_family_plots
}
