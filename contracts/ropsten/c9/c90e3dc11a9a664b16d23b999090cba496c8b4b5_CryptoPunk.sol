/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

/**
 *Submitted for verification at Etherscan.io on 2020-20-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract CryptoPunk {
    
    address public owner;
    
    // Define a NFT drop object
    struct Drop {
        string videoUri;
        address advertiser;
        bool approved;
    }
    
// "https://testtest.com/3.mp4",
// false
   
    // Create a list of some sort to hold all the objects
    Drop[] public drops;
    mapping (uint256 => address) public videoAdvertiser;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }

    // Get the NFT drop objects list
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    }
    
    // Add to the NFT drop objects list
    function addDrop(Drop memory _drop) public {
            _drop.approved = false;
            drops.push(_drop);
            uint256 id = drops.length - 1;
            videoAdvertiser[id] = _drop.advertiser;
    }
    
    // Update from the NFT drop objects list
    function updateDrop(
        uint256 _index, Drop memory _drop) public {
            require(msg.sender == videoAdvertiser[_index], "You are not the owner of this drop.");
            _drop.approved = false;
            drops[_index] = _drop;
    }
    
    // Approve an NFT drop object to enable displaying
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }
}