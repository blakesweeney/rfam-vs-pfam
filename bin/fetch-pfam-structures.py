#!/usr/bin/env python3

# Copied from: https://www.ebi.ac.uk/interpro/result/download/#/entry/interpro

# standard library modules
import csv
import sys, errno, re, json, ssl
from urllib import request
from urllib.error import HTTPError
from time import sleep
import typing as ty

BASE_URL = "https://www.ebi.ac.uk/interpro/api/structure/PDB/entry/pfam?page_size=200"

def output_list() -> ty.Iterable[ty.Dict[str, ty.Any]]:
  #disable SSL verification to avoid config issues
  context = ssl._create_unverified_context()

  next = BASE_URL
  last_page = False

  attempts = 0
  while next:
    try:
      req = request.Request(next, headers={"Accept": "application/json"})
      res = request.urlopen(req, context=context)
      # If the API times out due a long running query
      if res.status == 408:
        # wait just over a minute
        sleep(61)
        # then continue this loop with the same URL
        continue
      elif res.status == 204:
        #no data so leave loop
        break
      payload = json.loads(res.read().decode())
      next = payload["next"]
      attempts = 0
      if not next:
        last_page = True
    except HTTPError as e:
      if e.code == 408:
        sleep(61)
        continue
      else:
        # If there is a different HTTP error, it wil re-try 3 times before failing
        if attempts < 3:
          attempts += 1
          sleep(61)
          continue
        else:
          sys.stderr.write("LAST URL: " + next)
          raise e

    for item in payload["results"]:
      yield item

    # Don't overload the server, give it time before asking for more
    if next:
      sleep(1)


def writeable(item: ty.Dict[str, ty.Any]) -> ty.Iterable[ty.Dict[str, str]]:
    for entry in item['entry_subset']:
      yield {
          'structure': f"{item['metadata']['accession']}_{entry['chain']}",
          'pfam_acc': entry['accession'],
      }


def main():
    writer = csv.DictWriter(sys.stdout, fieldnames=['pfam_acc', 'structure'])
    writer.writeheader()
    for item in output_list():
        writer.writerows(writeable(item))



if __name__ == "__main__":
  main()
