process fetch_seed {
  container params.containers.analysis

  output:
  tuple val('Rfam seed'), path('rfam.seed')

  """
  wget -O - 'https://ftp.ebi.ac.uk/pub/databases/Rfam/14.9/Rfam.seed.gz' | gzip -d > rfam.seed
  """
}

process extract_families {
  input:
  path(seed)

  output:
  path('families.csv')

  """
  grep '^#=GF AC' ${seed} | awk '{ print \$3 }' > families.csv
  """
}

process fetch_structures {
  container params.containers.analysis

  output:
  path('rfam.structures.csv')

  """
  wget -O - 'https://ftp.ebi.ac.uk/pub/databases/Rfam/.preview/pdb_full_region.txt.gz' \
  | gzip -d \
  | mlr --itsv --ocsv --implicit-csv-header label rfam_acc,pdb,chain,sequence_start,sequence_stop,bit_score,e_value,cm_start,cm_stop,hexcolor,is_significant \
  | mlr --csv filter '\$is_significant == "1"' > rfam.structures.csv
  """
}

process compute_structure_counts {
  container params.containers.analysis

  input:
  path(csv)

  output:
  path("rfam.structure_counts.csv")

  """
  mlr --csv count -g rfam_acc $csv \
  | mlr --csv rename 'count,number_of_structures' > rfam.structure_counts.csv
  """
}

process fetch_full_data {
  tag { "$family" }
  container params.containers.analysis

  input:
  val(family)

  output:
  tuple val(family), path("${family}.cm"), path("${family}.fa")

  """
  wget -O - 'https://ftp.ebi.ac.uk/pub/databases/Rfam/14.9/fasta_files/${family}.fa.gz' | gzip -d > ${family}.fa
  wget -O ${family}.cm 'https://rfam.org/family/${family}/cm'
  """
}

process build_full_alignments {
  tag { "$family" }
  memory '10GB'
  container params.containers.analysis

  input:
  tuple val(family), path(cm), path(fasta)

  output:
  path("${family}.sto")

  """
  cmalign $cm $fasta > ${family}.sto
  """
}

process combine_full_alignments {
  input:
  path("raw*.sto")

  output:
  tuple val('Rfam full'), path('rfam.full')

  """
  cat raw*.sto > rfam.full
  """
}

workflow rfam {
  main:
    fetch_seed | set { seeds }

    seeds \
    | map { _, fasta -> fasta } \
    | extract_families \
    | splitCsv \
    | map { it -> it[0] } \
    | fetch_full_data \
    | build_full_alignments \
    | collect \
    | combine_full_alignments \
    | set { full }

    fetch_structures \
    | compute_structure_counts \
    | set { structure_counts }
  emit:
    seeds = seeds
    full = full
    structures = structure_counts
}
