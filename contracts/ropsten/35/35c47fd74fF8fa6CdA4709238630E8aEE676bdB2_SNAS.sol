/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

/**************************************************************************
  ____   __       __       __         ____  
/  ___ | |     \    |    |    /      \     /    ___| 
\___  \  |       \  |    |  /   /_\   \   \___   \ 
 ___)    |    |\    |     /    ___    \   ___)   |
|____ / |__|  \___ /__/       \__\ ____ / 

Copyright 2021 Simple Name Addressing System

Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
and associated documentation files (the "Software"), to deal in the Software without restriction, 
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

************************************************************************/
pragma solidity ^0.7.5;

contract SNAS {
  mapping(string => address) public names;
  mapping(string => address) public nameOwners;
  mapping(string => uint256) public bids;
  mapping(string => address) public topBidder;
  mapping(string => uint256) public auctionDeadlines;

  event newName(string name, address resolveTo, address owner);
  event bidPlaced(string name, uint256 bidPrice, address bidder);
  event ownershipChanged(string name, address newOwner);
  event auctionStarted(
    string name,
    uint256 auctionDeadline,
    uint256 startingPrice
  );
  event auctionEnded(
    string name,
    uint256 auctionEnded,
    uint256 finalPrice,
    address winningBidder
  );

  uint256 constant ACCEPTABLE_DEADLINE_FROM_CURRENT_BLOCK = 50;
  bool locked = false;

  function createName(string memory name, address resolveTo)
    public
    payable
    returns (bool)
  {
    require(names[name] == address(0x0), "This name is already taken.");
    require(locked == false, "Locked");
    locked = true;
    names[name] = resolveTo;
    nameOwners[name] = msg.sender;
    locked = false;
    emit newName(name, resolveTo, msg.sender);
    return true;
  }

  function changeNameAddress(string memory name, address resolveTo)
    public
    returns (bool)
  {
    require(locked == false, "Locked");
    require(nameOwners[name] == msg.sender, "Not owner");
    locked = true;
    names[name] = resolveTo;
    locked = false;
    return true;
  }

  function handOver(string memory name, address resolveTo)
    public
    returns (bool)
  {
    require(locked == false, "Locked");
    require(nameOwners[name] == msg.sender, "Not owner");
    require(
      auctionDeadlines[name] == 0,
      "Auction is active, cannot hand over."
    );
    locked = true;
    nameOwners[name] = resolveTo;
    locked = false;
    emit ownershipChanged(name, msg.sender);
    return true;
  }

  function auction(
    string memory name,
    uint256 startingPrice,
    uint256 deadline
  ) public returns (bool) {
    require(locked == false, "Locked");
    require(
      auctionDeadlines[name] == 0,
      "Auction is active, cannot open new auction."
    );
    require(
      deadline > block.number + ACCEPTABLE_DEADLINE_FROM_CURRENT_BLOCK,
      "Deadline cannot be less than current block number."
    );
    locked = true;
    bids[name] = startingPrice;
    auctionDeadlines[name] = deadline;
    locked = false;
    emit auctionStarted(name, deadline, startingPrice);
    return true;
  }

  function bid(string memory name, uint256 bidPrice)
    public
    payable
    returns (bool)
  {
    require(locked == false, "Locked");
    require(
      bidPrice > bids[name],
      "Bid cannot be less than current bid price."
    );
    uint256 requiredAdditionalValue = 0;
    if (topBidder[name] == msg.sender) {
      requiredAdditionalValue = bidPrice - bids[name];
    }
    require(
      requiredAdditionalValue > 0 && msg.value >= requiredAdditionalValue,
      "ETH amount required is short on bid price"
    );
    locked = true;
    if (msg.value > requiredAdditionalValue) {
      uint256 refundableETH = 0;
      refundableETH = msg.value - requiredAdditionalValue;
      if (msg.sender.send(refundableETH) == false) {
        locked = false;
        revert();
      }
    }
    bids[name] = bidPrice;
    topBidder[name] = msg.sender;
    locked = false;
    emit bidPlaced(name, bidPrice, topBidder[name]);
    return true;
  }

  function endAuction(string memory name) public returns (bool) {
    require(locked == false, "Locked");
    require(
      block.number >= auctionDeadlines[name],
      "Cannot end auction before deadline."
    );
    require(
      address(uint160(nameOwners[name])).send(bids[name]) == true,
      "Unable to transfer auciton sale to previous owner."
    );
    locked = true;
    uint256 finalPrice = bids[name];
    nameOwners[name] = topBidder[name];
    auctionDeadlines[name] = 0;
    bids[name] = 0;
    topBidder[name] = address(0x0);
    locked = false;
    emit auctionEnded(
      name,
      auctionDeadlines[name],
      finalPrice,
      nameOwners[name]
    );
    emit ownershipChanged(name, nameOwners[name]);
    return true;
  }

  function getCurrentBid(string memory name) public view returns (uint256) {
    return bids[name];
  }

  function resolve(string memory name) public view returns (address) {
    return names[name];
  }
}