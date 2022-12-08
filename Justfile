docker:
  #!/usr/bin/env bash
  set -euxo pipefail

  pushd containers/analysis/
  docker buildx build -t bsweeneyebi/rfam-pfam-analysis --platform linux/amd64 .
  docker push bsweeneyebi/rfam-pfam-analysis
  popd

  pushd containers/ggplot
  docker build -t bsweeneyebi/rfam-pfam-plot .
  docker push bsweeneyebi/rfam-pfam-plot
  popd
