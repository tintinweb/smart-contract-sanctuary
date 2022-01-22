/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Luqman {

    address public owner;

    // Define a NFT drop onject
    struct Drop {
        string imageuri;
        string name;
        string description;
        string social_1;
        string social_2;
        string websiteuri;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }

    /* "https://testtest.com/3.png",
    "Test collection",
    "This is my drop for the moon",
    "twitter",
    "https://testtest.com",
    "fasfas",
    "0.03",
    "22",
    1635790237,
    1635790237,
    1,
    false */

    // Create a list of some sort to hold all the objects
    Drop[] public drops;
    mapping (uint256 => address) public users;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    // Get the NFT drop projects list
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    }

    // Add to the NFT drops project list
        function addDrop(Drop memory _drop) public {
            _drop.approved = false;
            drops.push(_drop);
  /*   function addDrop (
        string memory _imageuri,
        string memory _name,
        string memory _description,
        string memory _social_1,
        string memory _social_2,
        string memory _websiteuri,
        string memory _price,
        uint256 _supply,
        uint256 _presale,
        uint256 _sale,
        uint8 _chain) public {
        drops.push(Drop(
            _imageuri,
            _name,
            _description,
            _social_1,
            _social_2,
            _websiteuri,
            _price,
            _supply,
            _presale,
            _sale,
            _chain,
            false
            )); */
           uint256 id = drops.length - 1;
           users[id] = msg.sender; 
        }
        
        // Update from nft drop project list

        function updateDrop(
            uint256 _index, Drop memory _drop) public {
                require(msg.sender == users[_index], "You are not the owners of this drops.");
                _drop.approved = false;
                drops[_index] = _drop;
            }
        /* uint256 _index,
        string memory _imageuri,
        string memory _name,
        string memory _description,
        string memory _social_1,
        string memory _social_2,
        string memory _websiteuri,
        string memory _price,
        uint256 _supply,
        uint256 _presale,
        uint256 _sale,
        uint8 _chain) public {
            require(msg.sender == users[_index], "You are not the owners of this drops");
              drops[_index] = Drop(
            _imageuri,
            _name,
            _description,
            _social_1,
            _social_2,
            _websiteuri,
            _price,
            _supply,
            _presale,
            _sale,
            _chain,
            false
            );
        } */
    // Remove from the NFT drop projects list
    // Approve an NFT drop objects to enabble displaying
    function approvedDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }

}