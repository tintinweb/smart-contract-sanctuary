/**
 *Submitted for verification at Etherscan.io on 2020-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

contract UnchainedIndex {
    constructor() public {
        owner = msg.sender;
        manifestHash = "QmP4i6ihnVrj8Tx7cTFw4aY6ungpaPYxDJEZ7Vg1RSNSdm"; // empty file
        emit HashPublished(manifestHash);
        emit OwnerChanged(address(0), owner);
    }

    function publishHash(string memory hash) public {
        require(msg.sender == owner, "msg.sender must be owner");
        manifestHash = hash;
        emit HashPublished(hash);
    }

    function changeOwner(address newOwner) public returns (address oldOwner) {
        require(msg.sender == owner, "msg.sender must be owner");
        oldOwner = owner;
        owner = newOwner;
        emit OwnerChanged(oldOwner, newOwner);
        return oldOwner;
    }

    event HashPublished(string hash);
    event OwnerChanged(address oldOwner, address newOwner);

    string public manifestHash;
    address public owner;
}