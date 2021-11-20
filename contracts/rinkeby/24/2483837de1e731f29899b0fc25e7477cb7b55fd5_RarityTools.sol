/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RarityTools {
    // creating drop listing
    address public owner;
    
    struct Drop {
        string ImageUri;
        string name;
        string description;
        string socail_1;
        string socail_2;
        string websiteUri;
        string price;
        string supply;
        string preSale;
        uint8 chain;
        uint256 sale;
        bool approved;
    }
    // "www.google.com",
    // "images",
    // "Hello how are you",
    //  "facebook",
    // "gmail",
    // "www.porn.com",
    // "33.33",
    // "sdkfk",
    // " =sdf",
    // 1,
    // 565656,
    // false
    // creating array for Drop struct;
    Drop[] public drops;
    
    mapping (uint256 => address) public users;
    
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner, "you are not the Owner");
        _;
    }
    // creating function to approved drop listing
    function getDrops() public view returns(Drop[] memory) {
        return drops;        
    }
    
    // creating function to adding drop;
    function addDrop (Drop memory _drops) public  {
         _drops.approved = false;
         drops.push(_drops);
         uint id = drops.length - 1;
         users[id] = msg.sender;
    }
    // creating function for update drops
    function updateDrop(Drop memory _drop, uint256 _index) public {
        require(msg.sender == users[_index], "you are not the owner");            
        _drop.approved = false;
        drops[_index] = _drop;
        
    }  
    
    function approvedDrop(uint256 _index) onlyOwner public {
        Drop storage drop = drops[_index];
        drop.approved = true;        
    }
    
}