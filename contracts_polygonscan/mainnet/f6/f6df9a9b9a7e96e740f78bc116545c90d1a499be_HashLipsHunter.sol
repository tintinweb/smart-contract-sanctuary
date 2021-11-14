/**
 *Submitted for verification at polygonscan.com on 2021-11-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract HashLipsHunter{

    address public owner;
    
    //Define a Nft Drop object
    struct Drop{
        string  imageUri;
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
    
    
    //create a list of some sort of hold all the objects

    Drop[] public drops;
    mapping (uint256 => address) public users;
    
    //is a code added to a function that can only execute only on a certain condition
    modifier onlyOwner{
        require(msg.sender == owner, "Invalid Transaction");
        _;
        
    }
    constructor(){
        //run only once: when the contract is created 
        owner = msg.sender;
    }
    //Get the nft drop object list
    function getDrops() public view returns(Drop[] memory){
        return drops;
    }
    //Add to the nft drop object list
    
    function addDrop(Drop memory _drop) 
        public
        {
         _drop.approved= false;
         drops.push(_drop);
         uint256 id = drops.length -1;
         users[id] = msg.sender;
        
        }
    
    
    
    //Edit drops
    
    function updateDrop(
        uint256 _index, Drop memory _drop) 
        public
        {
         require(msg.sender == users[_index], 'You are not the Creator of this particular collection');
         _drop.approved= false; 
         drops[_index]= _drop;
        }
        
        
    //remove from the nft drop object list
    //Approve on Nft drop object to eneble display
    function approveDrop(uint256 _index) public onlyOwner{
        Drop storage drop = drops[_index];
        drop.approved = true;

    }
    
    // Clear out nft drop objects
    
    
    
}