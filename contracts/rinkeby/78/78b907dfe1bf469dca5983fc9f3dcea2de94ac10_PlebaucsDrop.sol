/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract PlebaucsDrop {

    address public owner;

    // Define a NFT drop object
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
        bool approved; // Admin needs to approve content bf shown to public. 
    }

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

    // Get the NFT dop objects list
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    } 


    // Add to the NFT drop objects list
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);

        // Assign an id to the drop.
        uint256 id = drops.length - 1;
        users[id] = msg.sender; // What is msg? It is an address.
    }

        function updateDrop(uint256 _index, Drop memory _drop) public {
            require(msg.sender == users[_index], "You are not the owner of this drop.");
            _drop.approved = false;
            drops[_index] = _drop;
    }

    // Approve an NFT drop object to enable displaying
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }


    // Clear out all NFT drop objects from list







}