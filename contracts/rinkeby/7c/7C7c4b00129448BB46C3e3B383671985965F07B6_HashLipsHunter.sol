/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HashLipsHunter {
    address public owner;
    
    // define a nft drop object
    struct Drop {
        string imageUri;
        string name;
        string description;
        string social_1;
        string social_2;
        string website;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }
    
    // "http://image.uri.ipfss.test",
    // "tes collection",
    // "this is just a test",
    // "twitter",
    // "http:''asd,.",
    // "dao",
    // "0.03",
    // "22",
    // "1635790237",
    // "1635790237",
    // 1,
    // false
    
    // create a list of some sort to hold all the objects
    Drop[] public drops;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner,"not owner");
        _;
    }
    
    mapping (uint256 => address) public users;
    // get the nft drop object list
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    }
    // add to the nft drop object list
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    }
    
    function updateDrop(uint256 _index,Drop memory _drop) public {
        require(msg.sender == users[_index],"not owner of this drop");
        _drop.approved = false;
        drops[_index] = _drop;
    }
    
    // approve on nft drop object to enable displaying
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }
    
    
}