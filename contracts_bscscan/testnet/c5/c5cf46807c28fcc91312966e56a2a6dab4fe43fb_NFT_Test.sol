/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract NFT_Test {
  // Define a NFT drop object
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
  // create a list of some sort to hold all the objects 
  Drop[] public drops;
  // Get the NFT drop objecte list
  // Add to the NFT drop objects list
  function addDrop(
      string memory _imageUri, 
      string memory _name,
      string memory _description,
      string memory _social_1,
      string memory _social_2,
      string memory _websiteUri,
      string memory _price,
      uint256 _supply,
      uint256 _presale,
      uint256 _sale,
      uint8 _chain) public {
    drops.push(Drop(
        _imageUri, 
        _name,
        _description,
        _social_1,
        _social_2,
        _websiteUri,
        _price,
        _supply,
        _presale,
        _sale,
        _chain,
        false
        ));
  }
  // Remove from the NFT drop objects list
  // Approve on NFT drop object to enable displaying
  // Clear out all NFT drop objects from list
}