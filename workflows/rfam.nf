process fetch_seed {
  container params.containers.analysis

  output:
  tuple val('Rfam'), val('seed'), path('rfam.seed')

  """
  wget -O - 'https://ftp.ebi.ac.uk/pub/databases/Rfam/${params.rfam.version}/Rfam.seed.gz' | gzip -d > rfam.seed
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

process fetch_all_cms {
  output:
  path("*.cm")

  """
  wget -O Rfam.tar.gz 'https://ftp.ebi.ac.uk/pub/databases/Rfam/${params.rfam.version}/Rfam.tar.gz'
  tar xvf Rfam.tar.gz
  """
}

process fetch_all_sequences {
  container params.containers.analysis

  output:
  path("*.fa")

  """
  wget 'ftp://ftp.ebi.ac.uk/pub/databases/Rfam/${params.rfam.version}/fasta_files/RF*.fa.gz'
  gzip -d *.fa.gz
  """
}

process build_full_alignments {
  tag { "$family" }
  memory { 6.GB * params.cmalign.cpus }
  cpus { params.cmalign.cpus }
  container params.containers.analysis
  maxForks 20

  input:
  tuple val(family), path(fasta), path(cm)

  output:
  path("${family}.sto")

  """
  cmalign --cpu ${params.cmalign.cpus} $cm $fasta > ${family}.sto
  """
}

process combine_full_alignments {
  input:
  path("raw*.sto")

  output:
  tuple val('Rfam'), val('full'), path('rfam.full')

  """
  cat raw*.sto > rfam.full
  """
}

workflow rfam {
  main:
    fetch_seed | set { seeds }

    fetch_all_cms \
    | flatten \
    | map { it -> [it.baseName, it] } \
    | set { cms }

    fetch_all_sequences \
    | flatten \
    | map { it -> [it.baseName, it] } \
    | set { sequences } 

    sequences
    | join(cms, failOnMismatch: true) \
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
