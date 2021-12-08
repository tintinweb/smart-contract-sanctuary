/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract W3Avatar {

    mapping(address => string) hashes;

    function updateIPFSHash(string calldata hash) public {
        hashes[msg.sender] = hash;
    }

    function getIPFSHash(address addr) public view returns(string memory) {
        return hashes[addr];
    }

    function getIPFSHash() public view returns(string memory) {
        return hashes[msg.sender];
    }

}