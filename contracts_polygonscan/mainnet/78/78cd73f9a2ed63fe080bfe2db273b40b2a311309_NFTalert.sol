/**
 *Submitted for verification at polygonscan.com on 2021-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract NFTalert{
    
    address public owner;
    
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

// "khhh",
// "Test",
// "drop of m",
// "tytt",
// "test",
// "f",
// "0.03",
// "22",
// 141,
// 141,
// 1,
// false
    
    Drop[] public drops;
    mapping (uint256 => address) public users;
    
    constructor(){
        owner = msg.sender;
    }
    
    modifier onlyOwner{
        require(msg.sender == owner,"You are not the owner");
        _;
    }
    
    function getDrops() public view returns(Drop[] memory) {
        return drops;
        
    } 
    
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    }
    
     function updateDrop( 
       uint256 _index, Drop memory _drop) public {
           require(msg.sender == users[_index], "You are not the owner of this drop");
           _drop.approved = false;
           drops[_index] = _drop;
    }
    function approveDrop(uint256 _index) public onlyOwner{
        
        Drop storage drop = drops[_index];
        drop.approved = true;
    }
}