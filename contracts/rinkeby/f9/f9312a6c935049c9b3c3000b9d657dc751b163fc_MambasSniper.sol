/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
contract MambasSniper {
    address public owner;
// definine an nft drop object
        struct Drop{
        string imageUri;
        string name;
        string description;
        string social_1;
        string social_2;
        string websiteUri;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }
    
// "https://themambas.io/image.png",
// "Test Mambas NFT Rarity",
// "This is the NFT Rare Test",
// "@fbeach73",
// "@SuperMamba",
// "https://themambas.io/",
// "0.08",
// "22",
// 1635790237,
// 1635790237,
// 1,
// false 
    
    
// create a type of list to hold all the objects
    Drop[] public drops;
    mapping (uint256 => address) public users;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner of this contract!");
        _;
    }

// get the NFT drop objects list
    function getDrops() public view returns (Drop[] memory)  {
        
    return drops;
    }

// add to the the nft drops object list

    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    }
  
// update the existing nft drops object list 

    function updateDrop(
    uint256 _index, Drop memory _drop) public {
    require(msg.sender == users[_index], "You are not the owner of this drop!");
    _drop.approved = false;
    drops[_index] = _drop;
       
    }
    
// remove from the nft drops object list
// approve an nft drop object to then enable it to display
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }


}