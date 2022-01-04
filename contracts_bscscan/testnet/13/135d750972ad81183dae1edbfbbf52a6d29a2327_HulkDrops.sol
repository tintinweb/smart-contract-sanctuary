/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HulkDrops {

    address public owner; 

    //Define an drop listing
    struct Drop {
        string imageUri;
        string name;
        string description;
        string social_1;
        string social_2;
        string social_3;
        string websiteUri;
        string price;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }
    // format to use within brackets []
    // "https://testtest.com/3.png",
    // "test project",
    // "This is a drop",
    // "telegram",
    // "Discord",
    // "twitter",
    // "site.com",
    // "0.05",
    // "1635790237",
    // "1635790237",
    // 1,
    // false

    // Creates a list to hold all the objects
    Drop[] public drops;
    mapping (uint256 => address) public users;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner.");
        _;
       }

    // Get all the drops in a list
    function getDrops() public view returns (Drop[] memory) {
        return drops; 
    }
    // Add the a New drop listing
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    }

        function updateDrop(
        uint256 _index, Drop memory _drop) public {
        require(msg.sender == users[_index], "You are not the owner of this drop!");
        _drop.approved = false;
        drops[_index] = _drop;
    }

    // Remove from the drop objects list
    // Approve an drop object and eanble displaying
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }
}