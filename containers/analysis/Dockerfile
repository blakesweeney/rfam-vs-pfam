FROM debian

RUN apt-get update -y
RUN apt-get install -y coreutils miller wget sed gcc make seqkit

RUN \
    cd / && \
    wget http://eddylab.org/infernal/infernal-1.1.4.tar.gz && \
    tar -xvzf infernal-1.1.4.tar.gz && \
    rm infernal-1.1.4.tar.gz && \
    cd infernal-1.1.4 && \
    ./configure && \
    make && \
    make install && \
    cd easel && \
    make install

ENTRYPOINT ["/bin/bash"]
