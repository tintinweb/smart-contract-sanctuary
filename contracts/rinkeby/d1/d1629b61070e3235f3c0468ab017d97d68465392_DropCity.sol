/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DropCity {
    // Define a NFT project
    address public owner;
    
    struct DropInfo {
        string name;
        string imageUri;
        string description;
        string socialHandle;
        string websiteUri;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 onSale;
        uint8 chain;
        bool approved;
    }


    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner{
       require(msg.sender == owner, "You are not the owner!");
       _; 
    }
    // Create a list to hold all the objects
    DropInfo[] public drops;
    mapping (uint256 => address) public dropOwners;

    // Get the NFT drop objects list
    function getDrops() public view returns (DropInfo[] memory) {
        return drops;
    }

    // Add to the NFT drop objects list
    function addDrop(DropInfo memory _dropInfo) public {
        DropInfo memory newDrop = _dropInfo;
        newDrop.approved = false;
        drops.push(newDrop);
        uint256 id = drops.length - 1;
        dropOwners[id] = msg.sender;
    }

    // Update drop objects list
    function updateDrop(uint256 _index, DropInfo memory _dropInfo) public {
        require(msg.sender == dropOwners[_index], "You are not the owner of this drop. ");
        _dropInfo.approved = false;
        drops[_index] = _dropInfo;
        
    }

    // Approve an NFT drop object to enable displaying
    function approveDrop(uint256 _index) public onlyOwner {
        DropInfo storage drop = drops[_index];
        drop.approved = true;
        
    }
 
}