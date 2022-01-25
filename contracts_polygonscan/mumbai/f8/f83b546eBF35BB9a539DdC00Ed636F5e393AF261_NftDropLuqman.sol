/**
 *Submitted for verification at polygonscan.com on 2022-01-24
*/

// SPDX-License-Identifier: GPL-3.0 /MIT

pragma solidity ^0.8.0;

contract NftDropLuqman {

    address public owner;

    // Define a NFT drop object
    struct Drop {
        string imageuri;
        string name;
        string description;
        string social_1;
        string social_2;
        string websiteuri;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }

/* "https://testets.com/3.png",
"test collection",
"this is my nft",
"twitter",
"https://testest.com",
"fasfafs",
"0.03",
"22",
123123123,
123123123,
1,
false */
 
    // Create list of some sort to hold all the project
    Drop[] public drops;
    mapping (uint256 => address) public users;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "you are not the owner.");
        _ ;
    }

    // Get the NFT drop objects list
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    }
    // Add to the NFT drop objects list
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    }
    // Update from the NFT drop object list
    function updateDrop(
        uint256 _index, Drop memory _drop) public {
            require(msg.sender == users[_index], "You are not the owner of drops.");
            _drop.approved = false;
            drops[_index] = _drop;
    }

    // Approve an NFT drop objects to enable displaying
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }
}