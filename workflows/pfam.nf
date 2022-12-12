process fetch_pfam_seed {
  container params.containers.analysis

  output:
  tuple val('Pfam seed'), path('pfam.seed')

  """
  wget -O - 'http://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam35.0/Pfam-A.seed.gz' | gzip -d > pfam.seed
  """
}

process fetch_pfam_full {
  container params.containers.analysis

  output:
  tuple val('Pfam full'), path('pfam.full')

  // """
  // wget -O - 'http://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam35.0/Pfam-A.full.gz' | gzip -d > pfam.full
  // """

  """
  wget -O - 'http://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam35.0/Pfam-A.seed.gz' | gzip -d > pfam.full
  """
}

workflow pfam {
  emit:
    seeds = seeds
    full = full
  main:
    fetch_pfam_seed | set { seeds }
    fetch_pfam_full | set { full }
}
