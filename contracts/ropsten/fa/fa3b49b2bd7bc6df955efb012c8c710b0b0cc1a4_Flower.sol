/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.7.0; 

contract Flower {
    address owner;
    string flowerType;
    
    constructor(string memory newFlowerType) public{
        owner = msg.sender;
        flowerType = newFlowerType;
    }
    function water() public pure returns (string memory){
        return "Aww thanks, I love water!";
    }

} 

contract Rose is Flower("Rose"){
    function pick() public pure returns (string memory){
        return "Ouch...";
    }
}

contract Jasmine is Flower("Jasmine"){
    function smell() public pure returns (string memory){
        return "Mmmmm, smells good";
    }
}