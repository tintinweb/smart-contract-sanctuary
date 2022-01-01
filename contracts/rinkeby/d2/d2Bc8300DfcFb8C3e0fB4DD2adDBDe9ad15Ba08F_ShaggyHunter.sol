/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;


contract ShaggyHunter {

    address public owner; 

    // define a nft drop object

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

    //create a list of some sort to hold all the object

    Drop[] public drops;
    mapping(uint256 => address) public users;

    //runs once when the contract is deployed
    constructor() {
        owner = msg.sender;
    }

    // if fun
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner!");
        _; //-> if its true, then continue
    }
    
    //get the neft drop objects list
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    }

    //add to the nft drop objects list

    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    }

    //update functions
     function updateDrop(
        uint256 _index, Drop memory _drop) public {
        require(msg.sender == users[_index], "you are not the owner of this drop");
        _drop.approved = false;
        drops[_index] = _drop;
    }

    //aprove an nft drop object to enable displaying
    
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    } 
}