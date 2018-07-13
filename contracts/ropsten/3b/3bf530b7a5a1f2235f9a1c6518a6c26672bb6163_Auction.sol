pragma solidity ^0.4.23;

contract Auction {
  
  string public description;
  string public instructions; // will be used for delivery address or email
  uint public price;
  bool public initialPrice = true; // at first asking price is OK, then +25% required
  uint public timestampEnd;
  address public beneficiary;
  bool public finalized = false;

  address public owner;
  address public winner;
  mapping(address => uint) public bids;
  address[] public accountsList; // so we can iterate: https://ethereum.stackexchange.com/questions/13167/are-there-well-solved-and-simple-storage-patterns-for-solidity

  // THINK: should be (an optional) constructor parameter?
  // For now if you want to change - simply modify the code
  uint public increaseTimeIfBidBeforeEnd = 24 * 60 * 60; // Naming things: https://www.instagram.com/p/BSa_O5zjh8X/
  uint public increaseTimeBy = 24 * 60 * 60;
  

  event BidEvent(address indexed bidder, uint indexed price, uint indexed timestamp); // cannot have event and struct with the same name
  // event Refund(address indexed sender, uint indexed amount, uint indexed timestamp);
  event Refund(address addr, uint value, uint timestamp);

  
  modifier onlyOwner { require(owner == msg.sender, &quot;only owner&quot;); _; }
  modifier onlyWinner { require(winner == msg.sender, &quot;only winner&quot;); _; }
  modifier ended { require(now > timestampEnd, &quot;not ended yet&quot;); _; }

  function setDescription(string _description) public onlyOwner() {
    description = _description;
  }

  function setInstructions(string _instructions) public ended() onlyWinner()  {
    instructions = _instructions;
  }

  constructor(uint _price, string _description, uint _timestampEnd, address _beneficiary) public {
    require(_timestampEnd > now, &quot;end of the auction must be in the future&quot;);
    owner = msg.sender;
    price = _price;
    description = _description;
    timestampEnd = _timestampEnd;
    beneficiary = _beneficiary;
  }

  // Same for all the derived contract, it&#39;s the implementation of refund() and bid() that differs
  function() public payable {
    if (msg.value == 0) {
      refund();
    } else {
      bid();
    }  
  }

  function bid() public payable {
    require(now < timestampEnd, &quot;auction has ended&quot;); // sending ether only allowed before the end

    if (bids[msg.sender] > 0) { // First we add the bid to an existing bid
      bids[msg.sender] += msg.value;
    } else {
      bids[msg.sender] = msg.value;
      accountsList.push(msg.sender); // this is out first bid, therefore adding 
    }

    if (initialPrice) {
      require(bids[msg.sender] >= price, &quot;bid too low, minimum is the initial price&quot;);
    } else {
      require(bids[msg.sender] >= (price * 5 / 4), &quot;bid too low, minimum 25% increment&quot;);
    }
    
    if (now > timestampEnd - increaseTimeIfBidBeforeEnd) {
      timestampEnd = now + increaseTimeBy;
    }

    initialPrice = false;
    price = bids[msg.sender];
    winner = msg.sender;
    emit BidEvent(winner, price, now);
  }

  function finalize() public ended() onlyOwner() {
    require(finalized == false, &quot;can withdraw only once&quot;);
    require(initialPrice == false, &quot;can withdraw only if there were bids&quot;);

    finalized = true;
    beneficiary.transfer(price);
  }

  function refund(address addr) private {
    require(addr != winner, &quot;winner cannot refund&quot;);
    require(bids[addr] > 0, &quot;refunds only allowed if you sent something&quot;);

    uint refundValue = bids[addr];
    bids[addr] = 0; // reentrancy fix, setting to zero first
    addr.transfer(refundValue);
    
    emit Refund(addr, refundValue, now);
  }

  function refund() public {
    refund(msg.sender);
  }

  function refundOnBehalf(address addr) public onlyOwner() {
    refund(addr);
  }

}