#!/usr/bin/env python
# -*- coding: UTF-8 -*-
# github.com/tintinweb
#

import os, sys
import logging
from pyetherchain.pyetherchain import EtherChain

logger = logging.getLogger(__name__)

def iter_contracts(start=0, length=100):
    s = EtherChain(proxies={})
    while True:
        import time
        time.sleep(30)
        s = EtherChain()
        contracts = s.contracts(start=start, length=length)
        for contract in contracts["data"]:
            yield contract
        start += contracts["processed"]


def download_contract_sources(output_directory, start=0, amount=100, batch=50, nr_of_transactions_to_include=5, overwrite=True):
    nr = 0
    for c in (_ for _ in iter_contracts(start=start, length=batch) if _.source and _.source.strip()):
        # only contracts with source
        logger.debug("got contract: %s"%c)
        dst = os.path.join(output_directory, c["address"].replace("0x", "")[:2])  # index by 1st byte

        if any([c["address"].lower() in fname for fname in os.listdir(dst)]):
            print("[%d/%d] skipping, already exists --> %s (%-20s) -> %s" % (
            nr, amount, c["address"], c["name"], "xx"))
            continue
        if not os.path.isdir(dst):
            os.makedirs(dst)
        contract_name = c['name']
        if not contract_name:
            contract_name = c.compiler_settings["Contract Name"]
        fpath = os.path.join(dst, "%s_%s.sol"%(c["address"].replace("0x",""), str(contract_name).replace("\\","_").replace("/","_")))
        if not overwrite and (os.path.exists(fpath) or any([c["address"].lower() in fname for fname in os.listdir(dst)])):
            print("[%d/%d] skipping, already exists --> %s (%-20s) -> %s" % (nr, amount, c["address"], contract_name, fpath))
            continue
        if nr_of_transactions_to_include:
            logger.debug("retrieving transactions")
        with open(fpath,"w") as f:
            f.write(c.describe_contract(nr_of_transactions_to_include=nr_of_transactions_to_include))

        print("[%d/%d] dumped --> %s (%-20s) -> %s" % (nr, amount, c["address"], contract_name, fpath))

        nr += 1
        if nr >= amount:
            print("[%d/%d] finished. maximum amount of contracts to download reached." %(nr, amount))
            break

def main():
    logging.basicConfig(format='[%(filename)s - %(funcName)20s() ][%(levelname)8s] %(message)s',
                        level=logging.INFO)
    logger.setLevel(logging.INFO)
    download_contract_sources(sys.argv[1] if len(sys.argv)>1 else "../contracts/mainnet/",
                              start=0, amount=1000,
                              overwrite=False,
                              nr_of_transactions_to_include=0)

if __name__ == "__main__":
    main()
