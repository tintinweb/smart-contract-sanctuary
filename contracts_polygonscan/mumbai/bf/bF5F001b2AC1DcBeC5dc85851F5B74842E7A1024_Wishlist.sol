// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; 

import "./Ownable.sol";
import "./Counters.sol";

contract Wishlist is Ownable {
  using Counters for Counters.Counter;

  uint256 public MIN_DONATION_AMOUNT = 1 ether;

  struct Wish {
    uint256 id;
    uint256 amount;
    string description;
    bool isGranted;
    uint256 amountRaised;
    uint256 donations;
    bool isValid;
  }

  struct Wisher {
    string id;
    uint256 wishes;
    uint256 grants;
    uint256 totalDonations;
    uint256 totalRaised;
    bool isValid;
  }

  Counters.Counter public totalWishes;
  string[] public allWishers;

  mapping(string => mapping(uint256 => Wish)) public wishes;
  mapping(string => Wisher) public wishers;

  function addWish(string memory userId, uint256 amount, string memory description) public {

    if (!wishers[userId].isValid) {
      wishers[userId] = Wisher(userId, 0, 0, 0, 0, true);
      allWishers.push(userId);
    }
    
    uint256 index = wishers[userId].wishes;
    wishes[userId][index]= Wish(index, amount, description, false, 0, 0, true);

    wishers[userId].wishes +=1;
    totalWishes.increment();    
  }

  function updateMinDonationAmount(uint256 newMin) public onlyOwner {
    MIN_DONATION_AMOUNT = newMin;
  } 

  function removeWish(string memory userId, uint256 index) public onlyOwner {
    require(wishers[userId].isValid,"Not a valid user");
    require(wishes[userId][index].isValid, "Not a valid WISH");
    wishes[userId][index].isValid = false;
  }

  function removeWisher(string memory userId) public onlyOwner {
    require(wishers[userId].isValid,"Not a valid user");
    wishers[userId].isValid = false;
  }

  function getUserWishes(string memory userId) public view returns(Wish[] memory) {
    require(wishers[userId].isValid,"Not a valid user");

    uint256 numWishes = wishers[userId].wishes;
    Wish[] memory userWishes = new Wish[](numWishes);

    for (uint256 i = 0; i < numWishes; i++) {      
        userWishes[i] = (wishes[userId][i]); 
    }
    
    return userWishes;
  }

  function getWisher(string memory userId) public view returns(Wisher memory) {
    return wishers[userId];
  }

  function getAllWishers() public view returns(Wisher[] memory) {
    uint256 numWishers = allWishers.length;
    Wisher[] memory wisherSummary = new Wisher[](numWishers);

    for (uint256 i = 0; i < numWishers; i++) {
      string memory userId = allWishers[i];
      wisherSummary[i] = wishers[userId];
    }
    return wisherSummary;
  }

  function donate(string memory userId, uint256 index) public payable {
    require(wishers[userId].isValid,"Not a valid user");
    require(wishes[userId][index].isValid, "Not a valid WISH");
    require(!wishes[userId][index].isGranted, "WISH has already been granted.");
    require(msg.value >= MIN_DONATION_AMOUNT, "Must DONATE at least MIN_DONATION_AMOUNT!");

    wishes[userId][index].amountRaised += msg.value;
    wishers[userId].totalRaised += msg.value;

    wishes[userId][index].donations+= 1; 
    wishers[userId].totalDonations+= 1;    
  } 

  function grantWish(string memory userId, uint256 index, address to) public onlyOwner {
    require(wishers[userId].isValid,"Not a valid user");
    require(wishes[userId][index].isValid, "Not a valid WISH");
    require(!wishes[userId][index].isGranted, "WISH has already been granted");

    uint256 wish = wishes[userId][index].amount;

    require(address(this).balance > wish, "Insufficient funds to grant this wish");
    
    address payable recipient = payable(to);
    recipient.transfer(wish);
    wishes[userId][index].isGranted = true;
    wishers[userId].grants += 1;
  }

  function disburseExtraFunds(uint256 amount, address to) public onlyOwner {
    require(address(this).balance > amount, "Insufficient funds to disburse extra funds");
    address payable recipient = payable(to);
    recipient.transfer(amount);
  }


}