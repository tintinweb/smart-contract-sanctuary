/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// "https://testtest.com/3.png",
// "Test Collection",
// "This is my drop for the month",
// "twitter",
// "https://testtest.com",
// "fasfas",
// "0.03",
// "22",
// "1635790237",
// "1635790237",
// 1,
// false


// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract DegenerateBallerAssociation{

    address public owner;
    
    // define an nft drop object
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
    // create a list of some sort to hold all the objects
    Drop[] public drops;
    mapping (uint256 => address) public users;
    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner, "Sorry, you are not the owner!");
        _;
    }

    // get the nft drop object list
    function getDrops() public view returns (Drop[] memory){
        return drops;  
    } 
    // add to the nft drop object list
    function addDrop(  Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;    
    }

    //update function
    function updateDrop(uint256 _index, Drop memory _drop ) public {
        require(msg.sender == users[_index], "Sorry, you are not the owner of the drop!");
        _drop.approved = false;
        drops[_index] = _drop;
    }
    
    // remove from the nft drop object list
    // approve an nft drop object to enable displaying
    function approveDrop(uint256 _index) public onlyOwner{
        Drop storage drop = drops[_index];
        drop.approved = true;

    } 


}