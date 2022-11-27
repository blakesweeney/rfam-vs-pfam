process fetch_seed {
  output:
  path('rfam.seed')

  """
  wget -O - 'https://ftp.ebi.ac.uk/pub/databases/Rfam/14.9/Rfam.seed.gz' | gzip -d > rfam.seed
  """
}

process seed_stats {
  input:
  path(seed)

  output:
  path("${seed}.stats.tsv"), emit: stats
  path("${seed}.iinfo"), emit: iinfo
  path("${seed}.cinfo"), emit: cinfo

  """
  esl-alistat \
    --cinfo ${seed}.cinfo \
    --iinfo ${seed}.iinfo \
    -1 \
    $seed > ${seed}.stats.tsv
  """
}

workflow {
  fetch_seed \
  | seed_stats
}
