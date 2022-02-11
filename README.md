# smart-contract-sanctuary
🐦🌴🌴🌴🦕 A home for ethereum smart contracts verified on Etherscan. 🏠


**Note**: This repo is updated twice a day.

## How to check out and update the repo

Clone all subchains:

```console
⇒  git clone --recursive git@github.com:tintinweb/smart-contract-sanctuary-multirepo.git
```

Update all subrepos:

```
⇒  git submodule update --remote --recursive
```

## Repo Layout

| Folder       | Description   |
| ------------ | ------------- |
| contracts    | folder structure of dumped solidity contract sources (ethereum) |
| contracts_`chainProvider`    | folder structure of dumped solidity contract sources (other chains)|
| utils        | utilities for dumping smart contracts from public sources |

#### 📂 Contracts

Contains smart contract sources for various networks, grouped by the first two chars of the contract address.
Files are named in the format `<address>_<source_unit_name>`, e.g. `0f0c3fedb6226cd5a18826ce23bec92d18336a98_URToken.sol`

Some contracts are listed in `contracts.json`, but this file is not complete. Rely on the file structure for a full list. 
This repo used to auto submit contracts to [4byte.directory](https://www.4byte.directory/).


#### 📂 Utils

Scripts for dumping smart contracts from public sources (etherscan.io, etherchain.com)

**requires:** `pip install -r requirements.txt`


##### Update

To use [List of Verified Contract addresses with an OpenSource license](https://etherscan.io/exportData?type=open-source-contract-codes), you can download the csv file, add it to the util folder, and run `parse_download_contracts_etherscan_io.py` (with your etherscan API). This will add the new contracts to the appropriate folder

## 👩‍🔬 Data Science Tools

* [🧠 SolGrep](https://github.com/tintinweb/solgrep) - A scriptable semantic grep utility for solidity (crunch numbers, find specific contracts, extract data)

## 🎓 Citation

If you are using this dataset in your research and paper, here's how you can cite this dataset: 

- APA6
```
Ortner, M., Eskandari, S. (n.d.). Smart Contract Sanctuary. Retrieved from https://github.com/tintinweb/smart-contract-sanctuary.
```

- LateX (Bib)
```
 @article{smart_contract_sanctuary, 
          title={Smart Contract Sanctuary}, 
          url={https://github.com/tintinweb/smart-contract-sanctuary}, 
          author={Ortner, Martin and Eskandari, Shayan}} 
 ```
