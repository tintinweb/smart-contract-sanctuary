/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract HashLipsHunter {

    address public owner;

    // Define a NFT drop 
    struct Drop {
        string imageUri;
        string name;
        string description;
        string social_1;
        string social_2;
        string websiteUrl;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }

    // "test",
    // "test",
    // "test",
    // "test",
    // "test",
    // "test",
    // "test",
    // 1,
    // 1,
    // 1,
    // 1,
    // false

    // Create a list of some sort to hold all the objects
    Drop[] public drops;
    mapping (uint256 => address) public users;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "you are not the owner");
        _;
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

    function updateDrop(
        uint256 _index,
        Drop memory _drop
    ) public {
        require(msg.sender == users[_index], "You are not the correct owner.");

        _drop.approved = false;
        drops[_index] = _drop;
    }

    // Remove from the NFT drop objects list
    // Approve on NFT drop objects to enable displaying
    function approveDrop(uint256 _index) public {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }
    // Cleaer out all NFT drop objects from list
}