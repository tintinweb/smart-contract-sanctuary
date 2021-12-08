/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Auction {
    struct Asset {
        string name;
        uint256 value;
        address owner;
    }

    Asset[] private assets;
    uint256 numAssets = 0;
    address manager;
    uint256 mininmumValue;

    constructor() {
        manager = msg.sender;
        createAsset("AAA", 0.0001 ether, manager);
        createAsset("BBB", 0.0001 ether, manager);
        createAsset("CCC", 0.0001 ether, manager);
        createAsset("DDD", 0.0001 ether, manager);
        createAsset("EEE", 0.0001 ether, manager);
    }

    function createAsset(string memory name, uint256 value, address owner) private {
        assets.push(Asset({name: name, value: value, owner: owner}));
    }

    function buyAsset(uint index) public payable {
        mininmumValue = assets[index].value;
        require(msg.value >= (mininmumValue * 3 / 2), "Your price must be 50% higher than the current one");
        assets[index].value = msg.value;
        assets[index].owner = msg.sender;
    }

    function getAssets() external view returns(string[] memory, uint256[] memory) {
        string[] memory names = new string[](assets.length);
        uint256[] memory values = new uint256[](assets.length);

        for(uint i = 0; i < assets.length; i++){
            names[i] = assets[i].name;
            values[i] = assets[i].value;
        }
        return (names, values);
    }

    // in case of returning the whole assets array
    // function getAssets() external view returns(Asset[] memory) {
    //     return assets;
    // }
}