/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.7 <0.9.0;

contract HashLipsHunter  {
    address public owner; //
    
    constructor(){
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the contract owner");
        _;
    }
    
    // Define a NFT drop object
    struct Drop {
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
    // Create a list of some sort to hold all the objects
    Drop[] public drops;
    mapping(uint256 => address) users;
    
    // Get the NFt drop object list
    function getDrops() public view returns(Drop[] memory) {
        return drops;
    }
    // Add to the NFT drop objects list
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length -1;
        users[id] = msg.sender;
    }
            
    // Update from the NFT drop objects list
    function UpdateDrop(uint256 _index, Drop memory _drop) public {
        require(msg.sender == users[_index], "You are not the drop owner");
        _drop.approved = false;
        drops[_index] = _drop;
    }

    
    // Approve an NFT drop object to enable displaying
    function approveDrop(uint256 _index) public onlyOwner { // Could be view???
        Drop storage drop = drops[_index];
        drop.approved = true;
        
    }
}