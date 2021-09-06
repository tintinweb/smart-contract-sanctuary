/**
 *Submitted for verification at polygonscan.com on 2021-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContractStorage {
    struct Contract {
        uint256 chainId;
        address _address;
        string description;
    }

    mapping(string => Contract) contracts;
    string[] contractNames;

    event ContractChanged(string indexed name, uint256 chainId, address _address, string description);

    function getContract(string memory name) public view returns (Contract memory) {
        return contracts[name];
    }

    function getContractNames() public view returns (string[] memory) {
        return contractNames;
    }

    function setContract(string memory name, uint256 chainId, address _address, string memory description) public {
        require(_address != address(0), "zero address not allowed");

        Contract storage _contract = contracts[name];
        if(_contract._address == address(0)) {
            contractNames.push(name);
        }
        _contract.chainId = chainId;
        _contract._address = _address;
        _contract.description = description;

        emit ContractChanged(name, chainId, _address, description);
    }

    // function removeContract(string memory name) public {
    //     Contract memory _contract = contracts[name];
    //     require(_contract._address != address(0), "contract not exist");

    //     delete contracts[name];
    //     uint contractNamesLength = contractNames.length;
    //     string memory lastName = contractNames[contractNamesLength - 1];
    //     uint index;
    //     for (index = 0; index < contractNamesLength; index++) {
    //         if (keccak256(bytes(contractNames[index])) == keccak256(bytes(name))) {
    //             break;
    //         }
    //     }
    //     contractNames[index] = lastName;
    //     contractNames.pop();

    //     emit ContractChanged(name, 0, address(0), "");
    // }
}

contract SiteStorage {
    struct Site {
        string url;
        string description;
    }

    mapping(string => Site) sites;
    string[] siteNames;

    event SiteChanged(string indexed name, string url, string description);

    function getSite(string memory name) public view returns (Site memory) {
        return sites[name];
    }

    function getSiteNames() public view returns (string[] memory) {
        return siteNames;
    }

    function setSite(string memory name, string memory url, string memory description) public {
        require(bytes(url).length > 0, "empty url not allowed");

        Site storage site = sites[name];
        if(bytes(site.url).length == 0) {
            siteNames.push(name);
        }
        site.url = url;
        site.description = description;

        emit SiteChanged(name, url, description);
    }

    // function removeSite(string memory name) public {
    //     Site memory site = sites[name];
    //     require(bytes(site.url).length > 0, "site not exist");

    //     delete sites[name];
    //     uint siteNamesLength = siteNames.length;
    //     string memory lastName = siteNames[siteNamesLength - 1];
    //     uint index;
    //     for (index = 0; index < siteNamesLength; index++) {
    //         if (keccak256(bytes(siteNames[index])) == keccak256(bytes(name))) {
    //             break;
    //         }
    //     }
    //     siteNames[index] = lastName;
    //     siteNames.pop();

    //     emit SiteChanged(name, "", "");
    // }
}

contract GakuenLootVerse is ContractStorage, SiteStorage {}