// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "./Ownable.sol";
import "./Counters.sol";

contract Wishlist is Ownable {
  using Counters for Counters.Counter;

  uint256 public MIN_DONATION_AMOUNT = 1 ether;

  struct Wish {
    uint256 wishAmount;
    bool wishGranted;
    uint256 amountRaised;
    bool isValid;
    uint256 wishId;
    uint256 userWishId;
  }

  Counters.Counter public wishCounter;

  mapping(string => mapping(uint256 => Wish)) public Wishes;
  mapping(string => uint256) public userWishCount;

  function addWish(string memory userId, uint256 wishAmount) public onlyOwner {
    require(wishAmount >= MIN_DONATION_AMOUNT, "WISH must request at least MIN_DONATION_AMOUNT");
    
    uint256 index = userWishCount[userId];
    Wishes[userId][index].wishAmount = wishAmount;
    Wishes[userId][index].wishGranted = false;
    Wishes[userId][index].amountRaised = 0;
    Wishes[userId][index].isValid = true;
    Wishes[userId][index].wishId = wishCounter.current();
    Wishes[userId][index].userWishId = userWishCount[userId];

    userWishCount[userId] += 1;
    wishCounter.increment();

  }

  function updateMinDonationAmount(uint256 newMin) public onlyOwner {
    MIN_DONATION_AMOUNT = newMin;
  } 

  function getWishAmount(string memory userId, uint256 index) public returns(uint256){
    require(Wishes[userId][index].isValid, "Not a valid WISH");
    return Wishes[userId][index].wishAmount;
  } 

  function getUserWishCount(string memory userId) public returns(uint256){
    return userWishCount[userId];
  } 

  function getTotalWishCount(string memory userId) public returns(uint256){
    return wishCounter.current();
  } 

  function getWishAmountRaised(string memory userId, uint256 index) public returns(uint256){
    require(Wishes[userId][index].isValid, "Not a valid WISH");
    return Wishes[userId][index].amountRaised;
  } 

  function isWishGranted(string memory userId, uint256 index) public returns(bool){
    require(Wishes[userId][index].isValid, "Not a valid WISH");
    return Wishes[userId][index].wishGranted;
  } 

  function removeWish(string memory userId, uint256 index) public onlyOwner {
    require(Wishes[userId][index].isValid, "Not a valid WISH");
    Wishes[userId][index].isValid = false;
  }

  function donate(string memory userId, uint256 index, uint256 donationAmount) public payable {
    require(Wishes[userId][index].isValid, "Not a valid WISH");
    require(msg.value >= MIN_DONATION_AMOUNT, "Must DONATE at least MIN_DONATION_AMOUNT!");
    Wishes[userId][index].amountRaised += donationAmount;
  }

  function grantWish(string memory userId, uint256 index, address to) public onlyOwner {
    uint256 wish = Wishes[userId][index].wishAmount;

    require(Wishes[userId][index].isValid, "Not a valid WISH");
    require(!Wishes[userId][index].wishGranted, "WISH has already been granted");
    require(address(this).balance > wish, "Insufficient funds to grant this wish");
    
    address payable recipient = payable(to);
    recipient.transfer(wish);
    Wishes[userId][index].wishGranted = true;
    Wishes[userId][index].isValid = false;

  }

  function disburseExtraFunds(uint256 amount, address to) public onlyOwner {

    require(address(this).balance > amount, "Insufficient funds to disburse extra funds");
    address payable recipient = payable(to);
    recipient.transfer(amount);

  }

}