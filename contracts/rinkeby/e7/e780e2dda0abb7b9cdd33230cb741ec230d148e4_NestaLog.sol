/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NestaLog {
    address owner;
    mapping(string => mapping(string => string)) logs;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, 'insufficient privilege');
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner returns (bool) {
        owner = _newOwner;
        return true;
    }

    function getKeyValue(string memory collection, string memory key) external view returns (string memory) {
        return logs[collection][key];
    }

    function putKeyValue(string memory collection, string memory key, string memory value) external onlyOwner returns (bool) {
        logs[collection][key] = value;
        return true;
    }
}