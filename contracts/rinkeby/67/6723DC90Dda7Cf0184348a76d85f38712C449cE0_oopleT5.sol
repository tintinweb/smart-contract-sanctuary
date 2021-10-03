/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract oopleT5 {

    address private owner;
    string[] private words;

    constructor() {
            owner = msg.sender;
        }   
    
    modifier onlyOwner() {
        require(msg.sender == owner, "You must be the Contract owner.");
        _;
    }

    function addWord(string memory newWord) public onlyOwner {
        words.push(newWord);
    }
    
    function viewOwner() public view returns (address){
        return owner;
    }
    
    function becomeOwner() public {
        owner = msg.sender;
    }
    
    function viewWord(uint16 number) public view returns (string memory){
        require(number > 0, "Number cannot be below one.");
        return words[(number-1)];
    }
}