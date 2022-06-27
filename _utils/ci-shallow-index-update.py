#!/usr/bin/env python
# -*- coding: UTF-8 -*-
# github.com/tintinweb
#
"""

Updates the submodule indexes without checking out all the files.

"""
import requests
import subprocess

def getLatestCommit(owner, repo, branch):
    reqUrl = "https://api.github.com/repos/{owner}/{repo}/commits/{branch}".format(owner=owner, repo=repo, branch=branch)
    print("* %s/%s/%s"%(owner, repo, branch))
    response = requests.get(reqUrl)
    if not response.status_code == 200:
        print(response)
        raise Exception("Cannot get last commit")
    return response.json()["sha"]

def updateIndex(mode, sha1, path):
    cmd = ["git", "update-index", "--add", "--cacheinfo", "{mode},{sha1},{submodule_path}".format(mode=mode, sha1=sha1,submodule_path=path)]
    subprocess.check_output(cmd)

def main():
    repos = ["ethereum", "arbitrum", "avalanche", "bsc", "fantom", "polygon", "tron", "optimism", "celo"]
    for r in repos:
        latestCommit = getLatestCommit("tintinweb", "smart-contract-sanctuary-%s"%r, "master")
        print("  ⇝   %s is at %s"%(r, latestCommit))
        updateIndex("160000",latestCommit, r)


main()