/**
 *Submitted for verification at BscScan.com on 2022-01-09
*/

// SPDX-License-Identifier: MIT;
pragma solidity ^0.8.0;

contract StellarSyndicateNftdrop {
    address public owner;
    //Define a Nft drop object
    struct Drop {
        string imageUri;
        string name;
        string description;
        string social_1;
        string social_2;
        string websiteUri;
        string price;
        uint16 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }

    // Create a list that holds all the drop objects

    Drop[] public drops;
    mapping(uint256 => address) public users;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == owner, "You are not the owner of this contract");
        _;
    }

    // Get the NT drop objects list
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    }

    //Add to the NFT drop objects list
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push( _drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    }

    //Update existing drop 
      function updateDrop(
        uint256 _index,
        Drop memory _drop
      ) public {
        require(msg.sender == users[_index], "You are not the owner of this drop");
        _drop.approved = false;
        drops[_index] = (_drop);
    }

    function approveDrop(uint256 _index) public onlyOwner{
        Drop storage drop = drops[_index];
        drop.approved = true;
    }
}