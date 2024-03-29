process fetch_seed {
  container params.containers.analysis

  output:
  tuple val('Rfam'), val('seed'), path('rfam.seed')

  """
  wget -O - 'https://ftp.ebi.ac.uk/pub/databases/Rfam/${params.rfam.version}/Rfam.seed.gz' | gzip -d > rfam.seed
  """
}

process fetch_structures {
  publishDir 'data/', mode: 'copy'
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

process extract_cm_info {
  container params.containers.analysis

  input:
  path("*.cm")

  output:
  path("names.csv")

  """
  cat *.cm | cmstat - > stats
  sed s'|# idx|idx|' stats | grep -v '^#' > stats.pprint
  mlr --ipprint --ocsv cat stats.pprint | mlr --csv cut -o -f accession,name > names.csv
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
  publishDir 'data/full-alignments', mode: 'copy'
  tag { "$family" }
  memory { 6.GB * params.cmalign.cpus }
  cpus { params.cmalign.cpus }
  queue 'standard'
  container params.containers.analysis
  maxForks params.cmalign.maxForks

  input:
  tuple val(family), path(fasta), path(cm)

  output:
  tuple val(family), path("${family}.sto")

  script:
  options = family in ['RF02543', 'RF02541', 'RF02546', 'RF02540'] ? '--mxsize 4096' : ''
  """
  esl-reformat -r fasta $fasta > rna.fa
  seqkit rmdup rna.fa > dedup.fa
  cmalign $options --cpu ${params.cmalign.cpus} $cm dedup.fa > ${family}.sto
  """
}

process fixup_alignments {
  tag { "$family" }
  memory 1.GB

  input:
  tuple val(family), path('raw.sto'), val(name)

  output:
  path("${family}.sto")

  """
  sed 's|#=GF AU Infernal 1.1.4|#=GF AC   ${family}\\n#=GF ID   ${name}|' raw.sto > ${family}.sto
  """
}

process combine_full_alignments {
  memory 1.GB

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

    fetch_all_cms | set { cm_files }

    cm_files
    | flatten \
    | map { it -> [it.baseName, it] } \
    | set { cms }

    cm_files \
    | extract_cm_info \
    | splitCsv \
    | set { family_names }

    fetch_all_sequences \
    | flatten \
    | map { it -> [it.baseName, it] } \
    | set { sequences } 

    sequences
    | join(cms, failOnMismatch: true) \
    | build_full_alignments \
    | join(family_names) \
    | fixup_alignments \
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
