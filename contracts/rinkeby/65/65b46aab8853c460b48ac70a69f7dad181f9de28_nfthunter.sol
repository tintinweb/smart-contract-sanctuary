/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
contract nfthunter {

    address public owner;
// Define a NFT drop object

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
// Create a list of some sort to hold all the objects
    Drop[] public drops;
    mapping (uint256 => address) user;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == owner, " You're not the owner.");
        _;
    }
// Get the NFT drop object list
    function getDrops() public view returns (Drop[] memory ){
        return drops;
    }
// Add the NFT drop object list
    function addDrop( Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256  id = drops.length - 1; 
        user [id] = msg.sender; 
 }

 function updateDrop(
     uint256 _index,Drop memory _drop) public {
        require( msg.sender == user[_index], "You are not the owner of this drop.");
        _drop.approved = false;
        drops[_index] = _drop;
 }
// Remove the NFT drop object list
// Approve an NFt drop object to enable displaying
    function approveDrop (uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }
// Clear out all NFT drop object from list

}