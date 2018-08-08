pragma solidity ^0.4.23;

// Deploying version: https://github.com/astralship/auction-ethereum/commit/1359e14e0319c6019eb9c7e57348b95c722e3dd6
// Timestamp Converter: 1529279999
// Is equivalent to: 06/17/2018 @ 11:59pm (UTC)
// Sunday midnight, in a week &#128526;

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
  

  event Bid(address indexed winner, uint indexed price, uint indexed timestamp);
  event Refund(address indexed sender, uint indexed amount, uint indexed timestamp);
  
  modifier onlyOwner { require(owner == msg.sender, "only owner"); _; }
  modifier onlyWinner { require(winner == msg.sender, "only winner"); _; }
  modifier ended { require(now > timestampEnd, "not ended yet"); _; }

  function setDescription(string _description) public onlyOwner() {
    description = _description;
  }

  function setInstructions(string _instructions) public ended() onlyWinner()  {
    instructions = _instructions;
  }

  constructor(uint _price, string _description, uint _timestampEnd, address _beneficiary) public {
    require(_timestampEnd > now, "end of the auction must be in the future");
    owner = msg.sender;
    price = _price;
    description = _description;
    timestampEnd = _timestampEnd;
    beneficiary = _beneficiary;
  }

  function() public payable {

    if (msg.value == 0) { // when sending `0` it acts as if it was `withdraw`
      refund();
      return;
    }

    require(now < timestampEnd, "auction has ended"); // sending ether only allowed before the end

    if (bids[msg.sender] > 0) { // First we add the bid to an existing bid
      bids[msg.sender] += msg.value;
    } else {
      bids[msg.sender] = msg.value;
      accountsList.push(msg.sender); // this is out first bid, therefore adding 
    }

    if (initialPrice) {
      require(bids[msg.sender] >= price, "bid too low, minimum is the initial price");
    } else {
      require(bids[msg.sender] >= (price * 5 / 4), "bid too low, minimum 25% increment");
    }
    
    if (now > timestampEnd - increaseTimeIfBidBeforeEnd) {
      timestampEnd = now + increaseTimeBy;
    }

    initialPrice = false;
    price = bids[msg.sender];
    winner = msg.sender;
    emit Bid(winner, price, now);
  }

  function finalize() public ended() onlyOwner() {
    require(finalized == false, "can withdraw only once");
    require(initialPrice == false, "can withdraw only if there were bids");

    finalized = true; // THINK: DAO hack reentrancy - does it matter which order? (just in case setting it first)
    beneficiary.send(price);

    bids[winner] = 0; // setting it to zero that in the refund loop it is skipped
    for (uint i = 0; i < accountsList.length;  i++) {
      if (bids[accountsList[i]] > 0) {
        accountsList[i].send( bids[accountsList[i]] ); // send? transfer? tell me baby: https://ethereum.stackexchange.com/a/38642/2524
        bids[accountsList[i]] = 0; // in case someone calls `refund` again
      }
    }     
  }

  function refund() public {
    require(msg.sender != winner, "winner cannot refund");

    msg.sender.send( bids[msg.sender] );
    emit Refund(msg.sender, bids[msg.sender], now);
    bids[msg.sender] = 0;
  }

}