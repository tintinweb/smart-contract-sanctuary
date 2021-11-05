/**
 *Submitted for verification at polygonscan.com on 2021-11-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract NFTandShillHunter {
    
    address public owner;
    
    struct Drop {
        string imageURI;
        string name;
        string description;
        string social_1;
        string social_2;
        string websiteURI;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }
    
    //"https://thetest.com/3.png",
    //"My Test Collection",
    //"this is my drop for the month",
    //"Twitter",
    //"Discord",
    //"https://thetest.com",
    //"0.03",
    //"10000",
    //1635790237,
    //1635790237,
    //1,
    //false
    Drop [] public drops;
    mapping (uint256 => address) public users;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "you are not the owner");
        _;
    }
    
    function getDrops() public view returns  (Drop[] memory) {
        return drops;
    }

    
    function addDrop(Drop memory _drop) public {
        _drop.approved = false; 
        drops.push(_drop);
            
        uint256 id = drops.length -1;   
        users[id] = msg.sender;
    }
    
        function updateDrop(
        uint256 _index, Drop memory _drop) public {
        require(msg.sender == users[_index], "You are not the owner of this Drop");
        _drop.approved = false;
        drops [_index] = _drop;
    }
    
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }
    
}