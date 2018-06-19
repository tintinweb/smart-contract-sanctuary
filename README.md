# smart-contract-sanctuary
🐦🌴🌴🌴🦕 That place where ethereum smart contracts feel home.

A place to store solidity contract sources. Not deduplicated yet.


| Folder       | Description   |
| ------------ | ------------- |
| contracts    | folder structure of dumped solidity contract sources |
| utils        | utilities for dumping smart contracts from public sources |

### Contracts

The folder structure contains the solidity sources. `contracts.json` is more or less an index with some metadata of that day the contract was dumped.


### Utils

Scripts for dumping smart contracts from public sources (etherscan.io, etherchain.com)

**requires:** `pip install pyetherchain`

## Contribute

Feel free to contribute smart contract sources or scripts for dumping sources.
I will keep this repository updated every now and then.

### Want

* deduplication script (link instead of duplicate)
* statistics
* scripts to dump more sources
* code-hash (without comments; maybe compile and hash bytecode to dedup sources)
