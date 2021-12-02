/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ~0.8.7;

contract NFTsHunter {

    // Specify owner
    address public owner;

    // Define an NFT Drop
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


    // Create a list to hold objects
    Drop[] public drops;
    mapping (uint256 => address) public users;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner.");
        _; // run code only if owner
    }

    // Get the NFT drop objects list
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    }

    // Add to the NFT drop objects list
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        // assign user who created drop
        uint256 id = drops.length - 1;
        users[id] = msg.sender;

    
    }

    function updateDrop(
        uint256 _index, Drop memory _drop) public {
            // can only update drop you created
            require(msg.sender == users[_index], "You are not the owner of this drop");
            _drop.approved = false;
            drops[_index] = _drop;
    }

    // Remove from NFT drop objects list

    // Approve an NFT drop object to enable displaying
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;

    }

}