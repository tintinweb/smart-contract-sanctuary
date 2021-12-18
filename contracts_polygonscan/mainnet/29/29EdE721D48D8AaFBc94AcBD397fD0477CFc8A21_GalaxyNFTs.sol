/**
 *Submitted for verification at polygonscan.com on 2021-12-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract GalaxyNFTs {

    address public owner;
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

// "https://testtest.com/3.png",
// "Test Collection",
// "This is my drop for the month",
// "twitter",
// "https://testtest.com",
// "fasfas",
// "0.03",
// "22",
// 13333333333,
// 13333333333,
// 1,
// false
    Drop[] public drops;

    
    mapping (uint256 => address) public users;

    constructor () {
        owner= msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    


    function getDrops() public view returns (Drop[] memory){
        return drops;

    }
    function addDrop(Drop memory _drop) public {
        _drop.approved=false;
        drops.push(_drop);
        uint256 id = drops.length -1; 
        users[id] = msg.sender;

    }
        function updateDrop(
        uint256 _index, Drop memory _drop) public {
        require(msg.sender == users[_index], "You are not the owner of this drop.");
        _drop.approved = false;
        drops[_index]=_drop;
    }
        function approveDrop(uint256 _index) public onlyOwner  {
            Drop storage drop = drops[_index];
            drop.approved = true;
        }



}