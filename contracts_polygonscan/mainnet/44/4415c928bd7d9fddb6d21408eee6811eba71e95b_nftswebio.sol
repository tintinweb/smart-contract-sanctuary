/**
 *Submitted for verification at polygonscan.com on 2022-01-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract nftswebio {
    //Define an owner
    address public owner;
    
    //Define a NFT Object
    struct Drop {
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
    
    //Create list of sort to hold all the objects
    Drop [] public drops;
    mapping (uint256 => address) public users;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You aren not the owner.");
        _;
    }

    //Get the NFT drop objects list
    function getDrops() public view returns (Drop[]memory) {
        return drops;
    }
    //Add to the NFT drop objects list
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length -1;
        users[id] = msg.sender;
    }
    
//Update from NFT to drop objects list
       function updateDrop(
       uint256 _index, Drop memory _drop) public {
           require(msg.sender == users[_index], "You are not the owner of this drop");
           _drop.approved = false;
        drops[_index] = _drop;
    }

        //Aprove an  NFT objektcs from list
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }

}