// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./IAuction.sol";

contract DutchAuction is IAuction {
  enum State {Active, Cancelled, Resolved}
  
  State private auctionState;
  address payable public owner;
  address payable private winner;
  string public ipfsHash;
  uint public startBlock;
  uint public endBlock;
  uint public price;
  uint public priceDrop;
  uint public dropInterval;
  
  constructor(
    address eoa, 
    string memory _ipfsHash,
    uint numWeeks, 
    uint _price,
    uint _priceDrop,
    uint _dropInterval
  ) {
    auctionState = State.Active;
    owner = payable(eoa);
    ipfsHash = _ipfsHash;
    startBlock = block.number;
    endBlock = startBlock + numWeeks*40320;
    price = _price;
    priceDrop = _priceDrop;
    dropInterval = _dropInterval*5760;
  }
  
  modifier notOwner() {
    require(msg.sender != owner);
    _;
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  modifier correctTime() {
    require(block.number >= startBlock);
    require(block.number <= endBlock);
    _;
  }
  
  function getState() external view override returns(uint) {
    return uint(auctionState);
  }
  
  
  function getWinner() external view override returns(address) {
    return winner;
  }
  
  function calculatePrice(uint currentBlock) private correctTime returns(uint256) {
    while(currentBlock > startBlock +dropInterval) {
      startBlock = startBlock +dropInterval;
      price = price -priceDrop;
    }
    return price;
  }
  
  function cancel() public override onlyOwner {
    auctionState = State.Cancelled;
  }
  
  // Sets highestBindingBid and highestBidder
  function placeBid() public payable override notOwner correctTime {
    require(auctionState == State.Active, "Auction no longer active.");
    
    uint256 currentPrice = calculatePrice(block.number);
    require(msg.value >= currentPrice, "Bid has not met current price.");
    require(msg.value <= currentPrice + 20000000000000000, "Bid exceeds current price by over 0.02 ETH.");
    
    winner = payable(msg.sender);
    owner.transfer(msg.value);
    auctionState = State.Resolved;
  }
  
  function finalise() public override onlyOwner {}
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

interface IAuction {
    
  function getState() external view returns(uint);
  
  function getWinner() external view returns(address);
  
  function cancel() external;
  
  function placeBid() external payable;
  
  function finalise() external;
}

