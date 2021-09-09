/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract weddingBook {
    uint256 public amountOfMessages = 0;
    
    // Mapping from token ID to wedMessage;
    mapping(uint256 => string) private _wedMessages;
    mapping(uint256 => string) private _assistant;
    
    address private owner;
    
    constructor () {
        owner = msg.sender;
    }
    
     function createWeedingMessage(string memory iAm, string memory message) public payable {
        _wedMessages[amountOfMessages] = message;
        _assistant[amountOfMessages] = iAm;
        amountOfMessages = amountOfMessages + 1;
    }
    
    function getWedMessage(uint256 tokenId) public view virtual returns (string memory , string memory) {
        return (_assistant[tokenId],  _wedMessages[tokenId]);
    }
    
    function cashback() public {
        require(msg.sender == owner);
        payable(address(msg.sender)).transfer(address(this).balance);
    }
    
}