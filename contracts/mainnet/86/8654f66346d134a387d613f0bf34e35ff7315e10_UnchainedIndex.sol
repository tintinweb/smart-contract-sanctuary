/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

contract UnchainedIndex {
    constructor() {
        owner = msg.sender;
        publishHash("QmP4i6ihnVrj8Tx7cTFw4aY6ungpaPYxDJEZ7Vg1RSNSdm"); // empty file
        emit OwnerChanged(address(0), owner);
    }

    function publishHash(string memory hash) public {
        require(msg.sender == owner, "msg.sender must be owner");
        lastUpdate = block.timestamp;
        string memory prevHash = manifestHash;
        manifestHash = hash;
        emit HashPublished(prevHash, manifestHash);
    }

    function changeOwner(address newOwner) public returns (address oldOwner) {
        require(msg.sender == owner, "msg.sender must be owner");
        address prevOwner = owner;
        owner = newOwner;
        emit OwnerChanged(prevOwner, newOwner);
        return oldOwner;
    }

    event HashPublished(string prevHash, string newHash);
    event OwnerChanged(address prevOwner, address newOwner);

    address public owner;
    string public manifestHash;
    uint256 public lastUpdate;
}