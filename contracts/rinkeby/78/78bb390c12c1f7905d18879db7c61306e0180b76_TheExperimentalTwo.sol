/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract TheExperimentalTwo{
    address public owner;
    struct Drop{
        string imageUri;
        string name;
        string description;
        string social_1;
        string social_2;
        //string social_3;
        //string social_4;
        string websiteUri;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }
// "https://testuri.online/3.png",
// "Test collection",
// "Test description",
// "tw",
// "https://testnet.online",
// "faafafafa",
// "0.023",
// "22",
// "1635790217",
// "1635790217",
// 1,
// false
    
    
    //Drop list
    Drop[] public drops;
    mapping(uint256=>address) public users;
    
    constructor(){
        owner = msg.sender;
    }
    
    modifier onlyOwner{
        require(msg.sender == owner,"You are not the owner.");
        _;
    }
    
    // Get NFT drop object lists
    function getDrops() public view returns(Drop[] memory){
        return drops;
    } 
    
    function addDrop(Drop memory _drop) public{
        _drop.approved = false;
        drops.push(_drop);
            uint256 id = drops.length - 1;
            users[id] = msg.sender;
    }
    function updateDrop(
        uint256 _index, Drop memory _drop) public {
            require(msg.sender == users[_index],"You are not the owner of drops.");
            _drop.approved = false;
            drops[_index] = _drop;
            
    }
    function approveDrop(uint256 _index) public onlyOwner{
        Drop storage drop = drops[_index];
        drop.approved = true;
    }
}