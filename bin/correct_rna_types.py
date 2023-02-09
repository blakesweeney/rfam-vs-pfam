#!/usr/bin/env python

import csv
import sys

import typing as ty

MAPPING = {
    "Cis-reg;": "Cis-regulatory",
    "Cis-reg; IRES;": "IRES",
    "Cis-reg; frameshift_element;": "Frameshift Element",
    "Cis-reg; leader;": "5' Leader Element",
    "Cis-reg; riboswitch;": "Riboswitch",
    "Cis-reg; thermoregulator;": "Thermoregulator",
    "Gene;": "Gene",
    "Gene; CRISPR;": "CRISPR",
    "Gene; antisense;": "Antisense RNA",
    "Gene; antitoxin;": "Antitoxin",
    "Gene; lncRNA;": "lncRNA Doman",
    "Gene; miRNA;": "miRNA Precursor",
    "Gene; rRNA;": "rRNA subunit",
    "Gene; ribozyme;": "Ribozyme",
    "Gene; sRNA;": "sRNA",
    "Gene; snRNA;": "snRNA",
    "Gene; snRNA; snoRNA;": "snoRNA",
    "Gene; snRNA; snoRNA; CD-box;": "snoRNA",
    "Gene; snRNA; snoRNA; HACA-box;": "snoRNA",
    "Gene; snRNA; snoRNA; scaRNA;": "snoRNA",
    "Gene; snRNA; splicing;": "Splicing Factor",
    "Gene; tRNA;": "tRNA",
    "Intron;": "Intron",
}

FIELDS = [
    "id",
    "rfam_acc",
    "description",
    "rna_type",
    "number_seqs",
    "number_of_columns",
    "number_residues",
    "average_length",
    "percent_identity",
    "source",
]


def fix_rna_type(given: ty.Dict[str, str]) -> ty.Dict[str, str]:
    if given['rna_type'] not in MAPPING:
        raise ValueError(f"Unknown type of RNA type in {given}")
    given['rna_type'] = MAPPING[given['rna_type']]
    return given


def parse(filename: str) -> ty.Iterable[ty.Dict[str, str]]:
    with open(filename, 'r') as raw:
        yield from csv.DictReader(raw)


def fix_all(rows: ty.Iterable[ty.Dict[str, str]]) -> ty.Iterable[ty.Dict[str, str]]:
    for row in rows:
        if 'Pfam' in row['source']:
            yield row
        else:
            yield fix_rna_type(row)


def main(filename: str):
    writer = csv.DictWriter(sys.stdout, fieldnames=FIELDS)
    writer.writeheader()
    writer.writerows(fix_all(parse(filename)))


if __name__ == '__main__':
    main(sys.argv[1])
