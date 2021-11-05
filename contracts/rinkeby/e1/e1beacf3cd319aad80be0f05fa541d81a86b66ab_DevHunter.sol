/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DevHunter {
    
    address public owner;
    
    //Define a NFT drop Object
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
    
    // "https://test.com/3.png",
    // "Test Collection",
    // "Ini deskripsi NFT bossku by CoderPack",
    // "twitter",
    // "Discord",
    // "https://CoderPack.com",
    // "0.05",
    // "5000",
    // 165748362,
    // 165748362,
    // 1,
    // false
    
    //Create a list some sort to hold all objects
    Drop[] public drops;
    mapping (uint256 => address) public users;
    
    constructor(){
        owner = msg.sender;
    }
    
    modifier onlyOwner{
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    
    //Get the Nft Drop objects list
    function getDrop() public view returns (Drop[] memory){
        return drops;
    }
    //Add to NFT Drop  objects list
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    }
    
    // Update from the NFT drop objects lists
    function updateDrop(
        uint256 _index, Drop memory _drop) public {
        require(msg.sender == users[_index], "You are not the owner of this drop.");
        _drop.approved = false;
        drops[_index] = _drop;
    }

    //Approve on NFT drop Object to enable displaying
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }
}