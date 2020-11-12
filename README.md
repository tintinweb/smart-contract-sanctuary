# smart-contract-sanctuary
🐦🌴🌴🌴🦕 A home for ethereum smart contracts. 🏠

This repo autosubmits contracts to [4byte.directory](https://www.4byte.directory/). Feel free to contribute sources.


| Folder       | Description   |
| ------------ | ------------- |
| contracts    | folder structure of dumped solidity contract sources |
| utils        | utilities for dumping smart contracts from public sources |

### Contracts

The folder structure contains the solidity sources. `contracts.json` is more or less an index with some metadata of that day the contract was dumped.


### Utils

Scripts for dumping smart contracts from public sources (etherscan.io, etherchain.com)

**requires:** `pip install pyetherchain`


#### Update
To use [List of Verified Contract addresses with an OpenSource license](https://etherscan.io/exportData?type=open-source-contract-codes), you can download the csv file, add it to the util folder, and run `parse_download_contracts_etherscan_io.py` (with your etherscan API). This will add the new contracts to the appropriate folder
## Contribute

Feel free to contribute smart contract sources, scripts for dumping sources or your analysis results with us.

### Want

* deduplication script (link instead of duplicate)
* statistics
* scripts to dump more sources
* code-hash (without comments; maybe compile and hash bytecode to dedup sources)
