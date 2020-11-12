#!/usr/bin/env python
# -*- coding: UTF-8 -*-
# github.com/tintinweb
import re
import os
from etherscan.contracts import Contract
import csv
import json

ETHERSCAN_API_KEY = ""

class EtherScanIoApi(object):
    """
    Base EtherScan.io Api implementation
    """
    def __init__(self, api_key = None):
        self.api_key = api_key

    def get_contract_source(self, address):
        api = Contract(address=address, api_key=self.api_key)
        sourcecode = api.get_sourcecode()
        return sourcecode[0]['SourceCode']
    


if __name__=="__main__":
    import sys

    if "ropsten" in sys.argv:
        prefix="ropsten"
    else:
        prefix="mainnet"

    output_directory = "../contracts/%s/"%prefix
    overwrite = False
    etherscan = EtherScanIoApi(api_key=ETHERSCAN_API_KEY)

    with open('export-verified-contractaddress-opensource-license.csv') as csvfile:
        readCSV = csv.reader(csvfile, delimiter=',')
        next(readCSV, None)  # skip the headers
        for row in readCSV:
            contract_address = row[1]
            contract_name = row[2]
            print("contract address: %s" %contract_address)
            sourceCode = etherscan.get_contract_source(contract_address)

            #Handle multiContract addresses
            all_contracts = []
            try:
                contract_json = json.loads(sourceCode)
                print("MultiContract Contract")
                for key,value in contract_json.items():
                    contract = {}
                    contract['name'] = key.replace(".sol", "")
                    contract['sourceCode'] = value['content']
                    all_contracts.append(contract)
            except Exception as e:
                all_contracts = [{'name' : contract_name,
                                  'sourceCode' : sourceCode }]


            for cont in all_contracts:
                dst = os.path.join(output_directory, contract_address.replace("0x", "")[:2].lower())  # index by 1st byte
                if not os.path.isdir(dst):
                    os.makedirs(dst)
                fpath = os.path.join(dst, "%s_%s.sol" % (
                contract_address.replace("0x", ""), str(cont['name']).replace("\\", "_").replace("/", "_")))
                if os.path.exists(fpath):
                    print(
                        "skipping, already exists --> %s (%-20s) -> %s" % (contract_address, cont['name'], fpath))
                    continue

                with open(fpath, "wb") as f:
                    f.write(bytes(cont['sourceCode'], "utf8"))

                print("dumped --> %s (%-20s) -> %s" % ( contract_address, cont['name'], fpath))

