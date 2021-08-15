/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

pragma solidity ^0.7.5;

contract SNAS {
  mapping(string => address) public names;
  mapping(string => address) public nameOwners;
  mapping(string => uint256) public bids;
  mapping(string => address) public topBidder;
  mapping(string => uint256) public auctionDeadlines;

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
    return true;
  }

  function auction(
    string memory name,
    uint256 minimumPrice,
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
    bids[name] = minimumPrice;
    auctionDeadlines[name] = deadline;
    locked = false;
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
    nameOwners[name] = topBidder[name];
    auctionDeadlines[name] = 0;
    bids[name] = 0;
    topBidder[name] = address(0x0);
    locked = false;
    return true;
  }

  function getCurrentBid(string memory name) public view returns (uint256) {
    return bids[name];
  }

  function resolve(string memory name) public view returns (address) {
    return names[name];
  }
}