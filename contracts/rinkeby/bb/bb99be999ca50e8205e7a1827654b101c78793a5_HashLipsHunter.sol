/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HashLipsHunter {
    
    address public owner;

    uint256 public ballance;

    uint256 public value = 2000000000000000;
    
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
    
// "https://testtest.com/3.png",
// "Test Collection",
// "This is my drop for the month",
// "twitter",
// "https://testtest.com",
// "fasfas",
// "0.03",
// "22",
// 1635790237,
// 1635790237,
// 1,
// false
    
    // Create a list of some sort to hold all the objects
    Drop[] public drops;
    mapping (uint256 => address) public users;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }

    // Get the NFT drop objects list
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    }
    
    // Add to the NFT drop objects list
    function addDrop(Drop memory _drop ) public payable {
          require(msg.value == value,"Insufficient funds! ");
            
            if(msg.value != value) revert();


          ballance = ballance + msg.value;
            _drop.approved = false;
            drops.push(_drop);
            uint256 id = drops.length - 1;
            users[id] = msg.sender;
    }
    
    // Update from the NFT drop objects list
    function updateDrop(
        uint256 _index, Drop memory _drop) public {
            require(msg.sender == users[_index], "You are not the owner of this drop.");
            _drop.approved = false;
            drops[_index] = _drop;
    }
    
    // Approve an NFT drop object to enable displaying
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }

    function Get_Ballance(address payable _to) public onlyOwner{
        _to.transfer(ballance);
    }

    function set_Value(uint256 value_in_wei) public onlyOwner{
              value = value_in_wei;

    }
}