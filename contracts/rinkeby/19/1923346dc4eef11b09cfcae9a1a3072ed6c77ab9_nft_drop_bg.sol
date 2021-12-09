/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract nft_drop_bg {
    
    address public owner; 

    struct Drop {
        string imageUri;
        string name;
        string description;
        string social_1;
        string social_2;
        string websiteUri ;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain; // 0 = ETH, 1 = Solana etc...
        bool approved;


    }
    //create a list that contains the drop object
    Drop[] public drops;
    mapping (uint256 => address) public users;

    function getDrops() public view returns (Drop[] memory ) {
        return drops; 
    }

    constructor() {
        owner = msg.sender;
    }

modifier onlyOwner {
    require(msg.sender == owner, "you are not the owner");
    _;
}

    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1 ;
        users[id] = msg.sender;
    }

    function updateDrop(uint256 _index, Drop memory _drop) public {
        require (msg.sender == users[_index]);
        _drop.approved = false;
        drops[_index] = _drop;
    }
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }

}