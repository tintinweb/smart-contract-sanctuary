#!/usr/bin/env python
# -*- coding: UTF-8 -*-
# github.com/tintinweb
#
"""

HACKy - non productive - script to download contracts from etherscan.io with throtteling.
Will eventually being turned into a simple etherscan.io api library. Feel free to take over that part and
 contribute if interested.

"""
import re
import os
import requests
import random
from retry import retry
from bs4 import BeautifulSoup
import json

import logging

logger = logging.getLogger(__name__)
DEBUG_RAISE = False
DEBUG_PRINT_CONTRACTS = False

def is_json(myjson):
    try:
        json_object = json.loads(myjson)
    except ValueError as e:
        return False
    return True


class ContractNotFound(BaseException): 
    def __init__(self, msg):
        self.msg = msg

class UserAgent(object):
    """
    User-Agent handling retries and errors ...
    """

    UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.82 Safari/537.36"

    def __init__(self, baseurl, proxies={}):
        self.baseurl, self.proxies = baseurl, proxies
        self.session = None
        self.initialize()

    def initialize(self):
        self.session = requests.session()
        self.session.headers.update({
            "user-agent":self.UA + str(random.randint(0,100))
        })

    def get(self, path, params={}, headers={}, proxies={}):
        new_headers = self.session.headers.copy()
        new_headers.update(headers)

        proxies = proxies or self.proxies
        _e = None

        resp = self.session.get("%s%s%s"%(self.baseurl, "/" if not path.startswith("/") else "", path),
                                    params=params, headers=new_headers, proxies=proxies)
        if resp.status_code != 200:
            raise Exception("Unexpected Status Code: %s!=200" % resp.status_code)
        return resp


    def post(self, path, params={}, headers={}, json=None):
        new_headers = self.session.headers.copy()
        new_headers.update(headers)
    
        resp = self.session.post("%s%s%s"%(self.baseurl, "/" if not path.startswith("/") else "", path),
                                params=params, headers=new_headers, json=json)
        if resp.status_code != 200:
            raise Exception("Unexpected Status Code: %s!=200" % resp.status_code)
        return resp

class EtherScanIoApi(object):
    """
    Base EtherScan.io Api implementation
    """

    def __init__(self, baseurl=None, proxies={}):
        baseurl = baseurl or "https://www.etherscan.io"
        self.session = UserAgent(baseurl=baseurl, proxies=proxies)

    @retry(Exception, delay=1, backoff=2, max_delay=10, tries=5, jitter=(1,4), logger=logger)
    def _request_contract_list(self, page, amount=100):
        resp = self.session.get("/contractsVerified/%d?ps=%s" % (page, amount))
        pageResult = re.findall(r'Page <strong(?:[^>]+)>(\d+)</strong> of <strong(?:[^>]+)>(\d+)</strong>', resp.text)
        if len(pageResult)>0:
            return resp, pageResult
        raise Exception("Invalid html response: Page marker not found")

    @retry(Exception, delay=1, backoff=2, max_delay=10, tries=10, jitter=(1,4), logger=logger)
    def _request_contract_source(self, address):
        resp = self.session.get("/address/%s"%address).text
        if "You have reached your maximum request limit for this resource. Please try again later" in resp:
            print("[[THROTTELING]]")
            raise Exception("Throtteling")

        print("=======================================================")
        print(address)
        #print(resp)
        sources = []
        # remove settings box. this is not solidity source
        if "<span class='text-secondary'>Settings</span><pre class='js-sourcecopyarea editor' id='editor' style='margin-top: 5px;'>" in resp:
            resp = resp.split("<span class='text-secondary'>Settings</span><pre class='js-sourcecopyarea editor' id='editor' style='margin-top: 5px;'>",1)[0]
            
        for rawSource in re.split("<pre class='js-sourcecopyarea editor' id='editor\d*' style='margin-top: 5px;'>",resp)[1:]:
            src = rawSource.split("</pre><br>",1)[0]
            soup = BeautifulSoup(src, features="html.parser")
            source = soup.get_text() # normalize html.
            
            if source.startswith("{") and "outputSelection" in source and "pragma" not in source and is_json(source):
                continue  # ignore settings
            
            if DEBUG_PRINT_CONTRACTS:
                print(source)
            if "&lt;" in source or "&gt;" in source or "&le;" in source or "&ge;" in source or "&amp;" in source or "&vert;" in source or "&quot;" in source:
                raise Exception("HTML IN OUTPUT!! - BeautifulSoup messed up..")
            source =  source.replace("&lt;", "<").replace("&gt;", ">").replace("&le;","<=").replace("&ge;",">=").replace("&amp;","&").replace("&vert;","|").replace("&quot;",'"')
            sources.append(source)
        if not sources:
            raise Exception("unable to find source-code. rate limited? retry..")
        return "\n\n".join(sources)

    def get_contracts(self, start=0, end=None):
        page = start

        while not end or page <= end:
            resp, pageResult = self._request_contract_list(page)                    
            page, lastpage = pageResult[0]
            page, lastpage = int(page),int(lastpage)
            if not end:
                end = lastpage
            rows = self._parse_tbodies(resp.text)[0]  # only use first tbody
            for col in rows:

                contract = {'address': self._extract_text_from_html(col[0]).split(" ",1)[0],
                            'name': self._extract_text_from_html(col[1]),
                            'compiler': self._extract_text_from_html(col[3]),
                            'balance': self._extract_text_from_html(col[4]),
                            'txcount': int(self._extract_text_from_html(col[5])),
                            'settings': self._extract_text_from_html(col[6]),
                            'date': self._extract_text_from_html(col[7]),
                            }
                yield contract
            page += 1

    def get_contract_source(self, address):
        return self._request_contract_source(address)

    def _extract_text_from_html(self, s):
        return re.sub('<[^<]+?>', '', s).strip()
        # return ''.join(re.findall(r">(.+?)</", s)) if ">" in s and "</" in s else s

    def _extract_hexstr_from_html_attrib(self, s):
        return ''.join(re.findall(r".+/([^']+)'", s)) if ">" in s and "</" in s else s

    def _get_pageable_data(self, path, start=0, length=10):
        params = {
            "start": start,
            "length": length,
        }
        resp = self.session.get(path, params=params).json()
        # cleanup HTML from response
        for item in resp['data']:
            keys = item.keys()
            for san_k in set(keys).intersection(set(("account", "blocknumber", "type", "direction"))):
                item[san_k] = self._extract_text_from_html(item[san_k])
            for san_k in set(keys).intersection(("parenthash", "from", "to", "address")):
                item[san_k] = self._extract_hexstr_from_html_attrib(item[san_k])
        return resp

    def _parse_tbodies(self, data):
        tbodies = []
        for tbody in re.findall(r"<tbody.*?>(.+?)</tbody>", data, re.DOTALL):
            #print(tbody)
            rows = []
            for tr in re.findall(r"<tr.*?>(.+?)</tr>", tbody):
                rows.append(re.findall(r"<td.*?>(.+?)</td>", tr))
            tbodies.append(rows)
        return tbodies



class TronScanApi(object):
    """
    Base EtherScan.io Api implementation
    """

    def __init__(self, baseurl=None, proxies={}):
        baseurl = baseurl or "http://apilist.tronscan.org"
        self.session = UserAgent(baseurl=baseurl, proxies=proxies)

    @retry(Exception, delay=1, backoff=2, max_delay=10, tries=5, jitter=(1,4), logger=logger)
    def _request_contract_list(self, start, amount=1000):
        resp = self.session.get("api/contracts?count=true&limit=%s&confirm=0&start=%s&verified-only=true&open-source-only=false&sort=-verify_time&search="%(amount, start))
        return resp.json()

    @retry(Exception, delay=1, backoff=2, max_delay=10, tries=10, jitter=(1,4), logger=logger)
    def _request_contract_source(self, address):
        resp = self.session.post("api/solidity/contract/info", json={"contractAddress":address})

        print("=======================================================")
        print(address)
        #print(resp)
        respj = resp.json()
        if(respj["code"] <0):
            raise ContractNotFound("server error: %r"%respj)

        sources = respj["data"]["contract_code"]
        
        if not sources:
            raise Exception("unable to find source-code. rate limited? retry..")

        import base64
        sources = ["//SourceUnit: %s\n\n%s"%(s["name"],base64.b64decode(s["code"]).decode("utf-8")) for s in sources]
        return "\n\n".join(sources)

    def get_contracts(self, start=0, end=None):
        entry = start

        while not end or entry <= end:
            pageResult = self._request_contract_list(entry)         
            if not len(pageResult["data"]):
                break  # no more entries

            for entryData in pageResult["data"]:
                entry+=1
                yield entryData

    def get_contract_source(self, address):
        return self._request_contract_source(address)



if __name__=="__main__":
    import sys
    if len(sys.argv)>1:
        prefix = sys.argv.pop()
    else:
        prefix = "www"

    output_directory = "../contracts/%s/"%("mainnet" if prefix=="www" else prefix)
    overwrite = False
    amount = 1000000

    e = EtherScanIoApi(baseurl="https://%s.etherscan.io"%(prefix))
    for nr,c in enumerate(e.get_contracts()):
        with open(os.path.join(output_directory,"contracts.json"),'a') as f:
            f.write("%s\n"%json.dumps(c))
            print("got contract: %s" % c)
            dst = os.path.join(output_directory, c["address"].replace("0x", "")[:2].lower())  # index by 1st byte
            if not os.path.isdir(dst):
                os.makedirs(dst)
            fpath = os.path.join(dst, "%s_%s.sol" % (
            c["address"].replace("0x", ""), str(c['name']).replace("\\", "_").replace("/", "_")))
            if not overwrite and os.path.exists(fpath):
                print(
                    "[%d/%d] skipping, already exists --> %s (%-20s) -> %s" % (nr, amount, c["address"], c["name"], fpath))
                continue

            try:
                source = e.get_contract_source(c["address"]).strip()
                if not len(source):
                    raise Exception(c)
            except Exception as e:
                print(e)
                if DEBUG_RAISE:
                    raise
                continue


            with open(fpath, "wb") as fw:
                fw.write(bytes(source, "utf8"))

            print("[%d/%d] dumped --> %s (%-20s) -> %s" % (nr, amount, c["address"], c["name"], fpath))

            nr += 1
            if nr >= amount:
                print("[%d/%d] finished. maximum amount of contracts to download reached." % (nr, amount))
                break
