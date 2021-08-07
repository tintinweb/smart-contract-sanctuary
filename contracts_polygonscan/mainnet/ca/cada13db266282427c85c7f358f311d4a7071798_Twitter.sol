/**
 *Submitted for verification at polygonscan.com on 2021-08-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

contract Twitter {
    
    address owner;
    constructor() {
        owner = msg.sender;
    }
    
    mapping(address => string) public tokenURIs;


    function setURI(string memory _value) public {
        tokenURIs[msg.sender] = _value;
    }
    
    function tokenURI(address _tokenId) public view returns (string memory) {
        return tokenURIs[_tokenId];
  }
}