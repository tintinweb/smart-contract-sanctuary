/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract DripDrops {
    
    address public owner; 
     // define drop object    
    struct Drop {
        string imageUri;
        string name;
        string description;
        string audioUri;
        string websiteUri;
        string social;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }
    
    //create list
    Drop[] public drops;
    mapping (uint256 => address) public users;
    
    constructor() {
        owner = msg.sender; 
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the Owner");
        _;
    }
    //get list
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    }
    
    //Ad to drop objects list
    function addDrop(Drop memory _drop) public {
             _drop.approved = false;
             drops.push(_drop);
             uint256 id = drops.length - 1;
             users[id] = msg.sender;
    }
    
        //update    
    function updateDrop(
        uint256 _index, Drop memory _drop) public {
            require(msg.sender == users[_index], "You are not the owner of this Drop.");
            _drop.approved = false;
            drops[_index] = _drop;
    }   
    
        // Approve drop object to enable display
    function approveDrop(uint256 _index) public onlyOwner {
            Drop storage drop = drops[_index];
            drop.approved = true;
            
    }
}