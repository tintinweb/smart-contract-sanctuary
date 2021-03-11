/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// SPDX-License-Identifier: gpl-3.0
pragma solidity 0.8.2;

contract owned {
    address payable public owner;

    event OwnershipTransfer(address indexed oldOwner, address indexed newOwner);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "not the owner");
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        emit OwnershipTransfer(owner, newOwner);
        owner = newOwner;
    }
}

contract KeyValueStorage is owned {
    mapping(bytes32 => bytes) public KVStore;
    mapping(bytes32 => string) public reverse;
    
    function setKeyFromBytes(bytes32 key, bytes calldata value) external onlyOwner {
        KVStore[key] = value;
    }
    
    function setKeyFromString(string memory skey, bytes calldata value) external onlyOwner {
        bytes32 key = keccak256(bytes(skey));
        reverse[key] = skey;
        KVStore[key] = value;
    }
    
    function setReverse(string memory key) external {
        reverse[keccak256(bytes(key))] = key;
    }
}