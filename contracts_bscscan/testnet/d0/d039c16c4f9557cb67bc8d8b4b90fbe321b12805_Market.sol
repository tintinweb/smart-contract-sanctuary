/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Market {
  event ItemSold(address indexed _buyer, bytes32 indexed _id, uint256 _value);
  function buy(bytes32 _id, address seller, uint256 _price) public payable {
    emit ItemSold(seller, _id, _price);
  }
  event ItemListed(address indexed _from, bytes32 indexed _id, uint256 _value);
  function sell(bytes32 _id, uint256 _price, address seller) public payable {
    emit ItemListed(seller, _id, _price);
  }
  event ItemDelisted(bytes32 indexed _id);
  function delist(bytes32 _id) public payable {
    emit ItemDelisted(_id);
  }
}