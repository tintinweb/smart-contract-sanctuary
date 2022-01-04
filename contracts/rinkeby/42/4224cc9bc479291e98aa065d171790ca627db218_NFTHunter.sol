/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract NFTHunter {

address public owner;
    // Define a NFT drop object
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

    // create a list of some sort to hold all the objects
    Drop[] public drops;
    mapping (uint256 => address) public users;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    // get the nft drop object list
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    }
    // add to the nft drop object list
    function addDrop(
        Drop memory _drop) public {
            _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender; 
    }

    function updateDrop(
        uint256 _index, Drop memory _drop) public {
        require(msg.sender == users[_index], "you are the owner of this drop.");
        _drop.approved = false;
        drops[_index] = _drop;
    }
    // remove the nft from the drop object list
    // Approve a nft drop object to enable displaying
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }
    // clear out all NFT drop objects list
}