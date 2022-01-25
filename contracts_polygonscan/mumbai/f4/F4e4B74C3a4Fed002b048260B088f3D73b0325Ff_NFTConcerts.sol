/**
 *Submitted for verification at polygonscan.com on 2022-01-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract NFTConcerts{

    address public owner;

    //Define a NFT Drop Object
    struct Drop{
        string thumbImageUri;
        string concertName;
        string concertDate;
        string concertTime;
        string concertDescription;
        string playerLink;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint256 chain;
        bool approved;
    }
    //Create a list to hold all the objects
    Drop[] public drops;
    mapping (uint256 => address) public users;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    //Get the NFT Drop ojects list
    function getDrops() public view returns(Drop[] memory){
        return drops;
    }

    //Add to the NFT Drop objects list
    function addDrop(Drop memory _drop) public{
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    }
    
    function updateDrop(
        uint256 _index, Drop memory _drop) public{
         require(msg.sender == users[_index], "You are not the owner of this drop.");
         _drop.approved = false;
        drops[_index] = _drop;
    
    }
    //Remove from the NFT Drop objects list
    //Approve an NFT Drop object to enable displaying
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }
    //Clear out all NFT Drop objects from list
}