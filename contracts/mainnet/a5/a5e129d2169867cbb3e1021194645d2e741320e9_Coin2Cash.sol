// SPDX-License-Identifier: MIT
/* Want to tip the developer?
Send eth to: 0xC0ef45535291D020309c7051ea26B7E36F2A41ff
 */
pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;


contract Coin2Cash {
  
  uint public numSellers = 0;
  uint public numBuyers = 0;
  struct User {
    uint256 latitude;
    uint256 longitude;
    string description;
    string title;
    uint256 lastAccess;
    uint256 markup;
    address owner;
  }
  mapping(uint256=>User) public sellers;
  mapping(uint256=>User) public buyers;

  event SellerAdded(uint256 id);
  event BuyerAdded(uint256 id);
  event SellerRemoved(uint256 id);
  event BuyerRemoved(uint256 id);

  function getNumSellers() public view returns(uint256) {
    return numSellers;
  }

  function getNumBuyers() public view returns(uint256) {
    return numBuyers;
  }

  function getBuyer(uint256 id) public view returns(User memory) {
    require(id <= numBuyers);
    return buyers[id];
  }

function getSeller(uint256 id) public view returns(User memory) {
    require(id <= numSellers);
    return sellers[id];
  }

  function addSeller (
    uint256 latitude, //multiplied by 7
    uint256 longitude,//multiplied by 7
    string memory description,
    string memory title,
    uint256 markup
  ) public returns (uint256){
    User memory user;
    user = User(latitude, longitude, description, title, block.timestamp, markup, msg.sender);
    numSellers++;
    sellers[numSellers] = user;
    emit SellerAdded(numSellers);
    return numSellers;
  }

  function addBuyer (
    uint256 latitude,
    uint256 longitude,
    string memory description,
    string memory title,
    uint256 markup
  ) public returns (uint256){
    User memory user;
    user = User(latitude, longitude, description, title, block.timestamp, markup, msg.sender);
    numBuyers++;
    buyers[numBuyers] = user;
    emit BuyerAdded(numBuyers);
    return numBuyers;
  }

  function removeSeller(uint256 id) public{
    require(sellers[id].owner == msg.sender);// "Your not the owner"
    User memory user;
    user = sellers[id];
    delete sellers[id];
    numSellers--;
    emit SellerRemoved(numSellers);
  }

  function removeBuyer(uint256 id) public{
    require(buyers[id].owner == msg.sender);// "Your not the owner"
    User memory user;
    user = buyers[id];
    delete buyers[id];
    numBuyers--;
    emit BuyerRemoved(numBuyers);
  }

  function reactivateSeller(uint256 id) public {
    require(sellers[id].owner == msg.sender);// "Your not the owner"
    User memory user;
    user = sellers[id];
    user.lastAccess = block.timestamp;
    sellers[id] = user;
  }

  function reactivateBuyer(uint256 id) public {
    require(buyers[id].owner == msg.sender);// "Your not the owner"
    User memory user;
    user = buyers[id];
    user.lastAccess = block.timestamp;
    buyers[id] = user;
  }
}