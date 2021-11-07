/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Nafia {
    
    address public owner;
    //Define a NFT drop obejct
    struct Drop {
        string imageUrl;
        string name;
        string description;
        string social_link_1;
        string social_link_2;
        string websiteUrl;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }
    
    //Create a list to hold some objects;
    Drop[] public drops;
    mapping ( uint256 => address ) public users;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    
    //Add to NFT drop list
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    }
    
    
    //Update Drop
    function updateDrop(uint256 _index, Drop memory _drop) public {
        require( msg.sender == users[_index], "You are not the owner of this drop" ); 
        _drop.approved = false;
        drops[_index] = _drop;
        
        
    }
    
    //Approve NFT drop for displaying
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }
    
    //Getting all drop objects
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    }
    
}