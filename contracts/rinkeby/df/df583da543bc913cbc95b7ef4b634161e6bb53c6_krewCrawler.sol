/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT
// Made with direction of Hash Lips

pragma solidity ^0.8.0;

contract krewCrawler {

address public owner;

// Define NFT Drop Object
struct Drop {
        string imageUrl;
        string name;
        string artist;
        string description;
        string social_media;
        string websiteUrl;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
        }

//List to hold Objects
    Drop[] public drops;

    mapping (uint256 => address) public users;

    constructor() {
        owner = msg.sender;
        }
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the Administrator of this Drop");
        _;
    }

// Get NFT Drop Object List
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    }
    
// Addition to NFT Drop Object
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length -1;
        users[id] = msg.sender;
        }
    
    function updateDrop(
        uint256 _index, Drop memory _drop) public {
        require(msg.sender == users[_index], "You are not the orginal creator of this drop.");
        _drop.approved = false;
        drops[_index] = _drop;    
        }

// Approve NFT Drop Object for Display
    function approveDrop(uint256 _index) public {
        Drop storage drop = drops[_index];
        drop.approved = true;
        }

//"https://testtest.com/3.png",
//"test collection",
//"This is my drop for the month",
//"twitter",
//"https://testtest.com",
//"fasfas",
//"0.03",
//"22"
//1635790237,
//1635790237,
//1,
//false


}