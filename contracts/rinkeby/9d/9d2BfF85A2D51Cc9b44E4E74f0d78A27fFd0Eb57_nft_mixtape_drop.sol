/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//Official original contract for nftmixtapes.io

contract nft_mixtape_drop {
    //Specify Owner
    address public owner;

    //Define a NFT drop opject
    struct Drop {
        string imageUri;
        string artist;
        string mixtape_title;
        string description;
        string websiteUri;
        uint8 category;
        string price;
        uint256 supply;
        uint256 presale_date;
        uint256 sale_date;
        uint8 chain;
        bool approved;
    }

// Sample Mixtape
// "https://nftmixtapes.io/logo.png",
// "Dj NFT Mixtapes",
// "The Mixtape Vol. 1",
// "The most prolific mixtape site on the planet.",
// "https://nftmixtapes.io",
// "1",
// "0.005",
// "300000",
// "01012022",
// "01052022",
// "1",
// "false"



    //Create a list of some sort to hold all the objects
    Drop[] public drops;
    mapping (uint256 => address) public users;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }

    //Get the NFT drop objects list
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    }
    //Add to the NFT Drop objects list (limit 11)
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    }
    //Update from the NFT drop object list
    function updateDrop(
        uint256 _index, Drop memory _drop) public {
        require(msg.sender == users[_index], "You are not the owner of this mixtape.");
        _drop.approved = false;
        drops[_index] = _drop;
        }
    //Remove from the NFT drop object to enable displaying
    //Approve an NFT drop object to enable displaying
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
        }
    }
    // Clear out all NFT drop objects from the list