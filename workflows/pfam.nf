process fetch_seed {
  container params.containers.analysis
  time '1h'
  memory 1.GB

  output:
  tuple val('Pfam'), val('seed'), path('pfam.seed')

  """
  wget -O - 'http://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam${params.pfam.version}/Pfam-A.seed.gz' | gzip -d > pfam.seed
  """
}

process fetch_full {
  container params.containers.analysis
  time '1h'
  memory 1.GB

  output:
  tuple val('Pfam'), val('full'), path('pfam.full')

  """
  wget -O - 'http://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam${params.pfam.version}/Pfam-A.full.gz' | gzip -d > pfam.full
  """
}

process fetch_structures {
  publishDir 'data/', mode: 'copy'
  container params.containers.analysis
  time '6h'
  memory 1.GB

  """
  fetch-pfam-structures.py > pfam.structures.csv
  """
}

workflow pfam {
  main:
    fetch_seed | set { seeds }
    fetch_full | set { full }
    fetch_structures | set { structures }
  emit:
    seeds = seeds
    full = full
    structures = structures
}
