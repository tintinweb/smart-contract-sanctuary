#!/usr/bin/env python
# -*- coding: UTF-8 -*-
# github.com/tintinweb
#
"""

HACKy - non productive - script to download contracts from etherscan.io with throtteling.
Will eventually being turned into a simple etherscan.io api library. Feel free to take over that part and
 contribute if interested.

"""

import os
import logging
import argparse
from connector.etherscan import EtherScanIoApi
import json

logger = logging.getLogger(__name__)
DEBUG_RAISE = False
DEBUG_PRINT_CONTRACTS = False

def main():
    description = ""
    examples = ""
    parser = argparse.ArgumentParser(description=description, epilog=examples,
                                    formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('-v', "--verbose", action="store_true", default=False, help="Set loglevel to DEBUG")
    parser.add_argument('-n', "--network", type=str, default=None, help="network")
    parser.add_argument('-c', "--chain", type=str, default="etherscan.io", required=True, help="blockchain")

    args = parser.parse_args()
    
    if args.chain.startswith("etherscan"):
        # special etherscan case :D
        output_directory = "../contracts/%s/"%("mainnet" if args.network==None else args.network)
    else:
        output_directory = "../contracts_%s/%s/"%(args.chain.split(".",1)[0],"mainnet" if args.network==None else args.network)
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    overwrite = False
    amount = 1000000
    break_on_dupes_threshold_initial = 500
    break_on_dupes_threshold = break_on_dupes_threshold_initial

    e = EtherScanIoApi(baseurl="https://%s"%(args.chain if not args.network else "%s.%s"%(args.network, args.chain)))
    print(e.session.baseurl)
    print(output_directory)
    for nr,c in enumerate(e.get_contracts()):
        with open(os.path.join(output_directory,"contracts.json"),'a') as f:
            print("got contract: %s" % c)
            dst = os.path.join(output_directory, c["address"].replace("0x", "")[:2].lower())  # index by 1st byte
            if not os.path.isdir(dst):
                os.makedirs(dst)
            fpath = os.path.join(dst, "%s_%s.sol" % (
            c["address"].replace("0x", ""), str(c['name']).replace("\\", "_").replace("/", "_")))
            if not overwrite and os.path.exists(fpath):
                print(
                    "[%d/%d] skipping, already exists --> %s (%-20s) -> %s" % (nr, amount, c["address"], c["name"], fpath))
                break_on_dupes_threshold -=1
                if break_on_dupes_threshold<=0:
                    print("<--STOP: break on dupes threshold")
                    break
                continue

            break_on_dupes_threshold = break_on_dupes_threshold_initial # reset dupecount on new contract

            try:
                source = e.get_contract_source(c["address"]).strip()
                if not len(source):
                    raise Exception(c)
                f.write("%s\n"%json.dumps(c))
            except Exception as e:
                print(e)
                if DEBUG_RAISE:
                    raise
                c["err"]=repr(e)
                f.write("%s\n"%json.dumps(c))
                continue


            with open(fpath, "wb") as fw:
                fw.write(bytes(source, "utf8"))

            print("[%d/%d] dumped --> %s (%-20s) -> %s" % (nr, amount, c["address"], c["name"], fpath))

            nr += 1
            if nr >= amount:
                print("[%d/%d] finished. maximum amount of contracts to download reached." % (nr, amount))
                break





if __name__=="__main__":
    main()
    