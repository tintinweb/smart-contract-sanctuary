/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DRIPDROPS {

    address public owner;

    //define objeect
    struct Drop {
        string imageURI;
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
//Create list

     Drop[] public drops;
     mapping (uint256 => address) users;

     constructor() {
         owner = msg.sender;
     }

     modifier onlyOwner {
         require(msg.sender == owner, "You are not the Owner");
         _;
     }
//Get List
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    }   
// Add to drop list
     function addDrop(
         Drop memory _drop) public {  
                     drops.push(_drop);
                     uint256 id = drops.length - 1;
                     users[id] = msg.sender;
        
}
     function updateDrop(
         uint256 _index, Drop memory _drop) public { 
        require(msg.sender == users[_index], "You are not the Owner") ;
        _drop.approved = false;     
       drops[_index] = _drop;
    }
    //approved
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;

    }
}