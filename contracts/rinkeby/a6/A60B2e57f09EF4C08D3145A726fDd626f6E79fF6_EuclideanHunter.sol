/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EuclideanHunter {
    address public owner; 

    // Define NFT drop object
    struct Drop {
        string imageURI;
        string name;
        string description;
        string social_1;
        string social_2;
        string websiteURL;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }
    
    // Mapping of owner to drop
    mapping(uint256 => address) public users;

    // Create a list to hold objects
    Drop[] public drops;

    // Runs on the deployment of the function
    constructor() {
        owner = msg.sender;
    }

    // Add to function to execute under certain conditions
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner of this contract.");
        _;
    }

    // Add to the drop list
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    }

    // Get the entire NFT drop list
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    }

    // Update a NFT drop
    function update(uint256 _index, Drop memory _drop) public {
            require(msg.sender == users[_index], "You are not the owner of this drop");
            _drop.approved = false;
            drops[_index] = _drop;
    }

    // Approve a drop
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }

}