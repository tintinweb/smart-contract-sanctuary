/**
 *Submitted for verification at Etherscan.io on 2020-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

contract UnchainedIndex {
    constructor() public {
        owner = msg.sender;
        indexHash = "QmbFMke1KXqnYyBBWxB74N4c5SBnJMVAiMNRcGu6x1AwQH"; // empty file
        emit HashPublished(indexHash);
        emit OwnerChanged(address(0), owner);
    }

    function publishHash(string memory hash) public {
        require(msg.sender == owner, "msg.sender must be owner");
        indexHash = hash;
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

    string public indexHash;
    address public owner;
}