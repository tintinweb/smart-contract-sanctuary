pragma solidity ^0.4.23;

// File: contracts/Auction.sol

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
  function getAccountListLenght() public constant returns(uint) { return accountsList.length; } // lenght is not accessible from DApp, exposing convenience method: https://stackoverflow.com/questions/43016011/getting-the-length-of-public-array-variable-getter

  // THINK: should be (an optional) constructor parameter?
  // For now if you want to change - simply modify the code
  uint public increaseTimeIfBidBeforeEnd = 24 * 60 * 60; // Naming things: https://www.instagram.com/p/BSa_O5zjh8X/
  uint public increaseTimeBy = 24 * 60 * 60;
  

  event BidEvent(address indexed bidder, uint value, uint timestamp); // cannot have event and struct with the same name
  event Refund(address indexed bidder, uint value, uint timestamp);

  
  modifier onlyOwner { require(owner == msg.sender, "only owner"); _; }
  modifier onlyWinner { require(winner == msg.sender, "only winner"); _; }
  modifier ended { require(now > timestampEnd, "not ended yet"); _; }


  function setDescription(string _description) public onlyOwner() {
    description = _description;
  }

  // TODO: Override this method in the derived functions, think about on-chain / off-chain communication mechanism
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

  // Same for all the derived contract, it&#39;s the implementation of refund() and bid() that differs
  function() public payable {
    if (msg.value == 0) {
      refund();
    } else {
      bid();
    }  
  }

  function bid() public payable {
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
    emit BidEvent(winner, msg.value, now); // THINK: I prefer sharing the value of the current transaction, the total value can be retrieved from the array
  }

  function finalize() public ended() onlyOwner() {
    require(finalized == false, "can withdraw only once");
    require(initialPrice == false, "can withdraw only if there were bids");

    finalized = true;
    beneficiary.transfer(price);
  }

  function refund(address addr) private {
    require(addr != winner, "winner cannot refund");
    require(bids[addr] > 0, "refunds only allowed if you sent something");

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

// File: contracts/AuctionMultiple.sol

// 1, "something", 1539659548, "0xca35b7d915458ef540ade6068dfe2f44e8fa733c", 3
// 1, "something", 1539659548, "0x315f80C7cAaCBE7Fb1c14E65A634db89A33A9637", 3

contract AuctionMultiple is Auction {

  uint public constant LIMIT = 2000; // due to gas restrictions we limit the number of participants in the auction (no Burning Man tickets yet)
  uint public constant HEAD = 120000000 * 1e18; // uint(-1); // really big number
  uint public constant TAIL = 0;
  uint public lastBidID = 0;  
  uint public howMany; // number of items to sell, for isntance 40k tickets to a concert

  struct Bid {
    uint prev;            // bidID of the previous element.
    uint next;            // bidID of the next element.
    uint value;
    address contributor;  // The contributor who placed the bid.
  }    

  mapping (uint => Bid) public bids; // map bidID to actual Bid structure
  mapping (address => uint) public contributors; // map address to bidID
  
  event LogNumber(uint number);
  event LogText(string text);
  event LogAddress(address addr);
  
  constructor(uint _price, string _description, uint _timestampEnd, address _beneficiary, uint _howMany) Auction(_price, _description, _timestampEnd, _beneficiary) public {
    require(_howMany > 1, "This auction is suited to multiple items. With 1 item only - use different code. Or remove this &#39;require&#39; - you&#39;ve been warned");
    howMany = _howMany;

    bids[HEAD] = Bid({
        prev: TAIL,
        next: TAIL,
        value: HEAD,
        contributor: address(0)
    });
    bids[TAIL] = Bid({
        prev: HEAD,
        next: HEAD,
        value: TAIL,
        contributor: address(0)
    });    
  }

  function bid() public payable {
    require(now < timestampEnd, "cannot bid after the auction ends");

    uint myBidId = contributors[msg.sender];
    uint insertionBidId;
    
    if (myBidId > 0) { // sender has already placed bid, we increase the existing one
        
      Bid storage existingBid = bids[myBidId];
      existingBid.value = existingBid.value + msg.value;
      if (existingBid.value > bids[existingBid.next].value) { // else do nothing (we are lower than the next one)
        insertionBidId = searchInsertionPoint(existingBid.value, existingBid.next);

        bids[existingBid.prev].next = existingBid.next;
        bids[existingBid.next].prev = existingBid.prev;

        existingBid.prev = insertionBidId;
        existingBid.next = bids[insertionBidId].next;

        bids[ bids[insertionBidId].next ].prev = myBidId;
        bids[insertionBidId].next = myBidId;
      } 

    } else { // bid from this guy does not exist, create a new one
      require(msg.value >= price, "Not much sense sending less than the price, likely an error"); // but it is OK to bid below the cut off bid, some guys may withdraw
      require(lastBidID < LIMIT, "Due to blockGas limit we limit number of people in the auction to 4000 - round arbitrary number - check test gasLimit folder for more info");

      lastBidID++;

      insertionBidId = searchInsertionPoint(msg.value, TAIL);

      contributors[msg.sender] = lastBidID;
      accountsList.push(msg.sender);

      bids[lastBidID] = Bid({
        prev: insertionBidId,
        next: bids[insertionBidId].next,
        value: msg.value,
        contributor: msg.sender
      });

      bids[ bids[insertionBidId].next ].prev = lastBidID;
      bids[insertionBidId].next = lastBidID;
    }

    emit BidEvent(msg.sender, msg.value, now);
  }

  function refund(address addr) private {
    uint bidId = contributors[addr];
    require(bidId > 0, "the guy with this address does not exist, makes no sense to witdraw");
    uint position = getPosition(addr);
    require(position > howMany, "only the non-winning bids can be withdrawn");

    uint refundValue = bids[ bidId ].value;
    _removeBid(bidId);

    addr.transfer(refundValue);
    emit Refund(addr, refundValue, now);
  }

  // Separate function as it is used by derived contracts too
  function _removeBid(uint bidId) internal {
    Bid memory thisBid = bids[ bidId ];
    bids[ thisBid.prev ].next = thisBid.next;
    bids[ thisBid.next ].prev = thisBid.prev;

    delete bids[ bidId ]; // clearning storage
    delete contributors[ msg.sender ]; // clearning storage
    // cannot delete from accountsList - cannot shrink an array in place without spending shitloads of gas
  }

  function finalize() public ended() onlyOwner() {
    require(finalized == false, "auction already finalized, can withdraw only once");
    finalized = true;

    uint sumContributions = 0;
    uint counter = 0;
    Bid memory currentBid = bids[HEAD];
    while(counter++ < howMany && currentBid.prev != TAIL) {
      currentBid = bids[ currentBid.prev ];
      sumContributions += currentBid.value;
    }

    beneficiary.transfer(sumContributions);
  }

  // We are  starting from TAIL and going upwards
  // This is to simplify the case of increasing bids (can go upwards, cannot go lower)
  // NOTE: blockSize gas limit in case of so many bids (wishful thinking)
  function searchInsertionPoint(uint _contribution, uint _startSearch) view public returns (uint) {
    require(_contribution > bids[_startSearch].value, "your contribution and _startSearch does not make sense, it will search in a wrong direction");

    Bid memory lowerBid = bids[_startSearch];
    Bid memory higherBid;

    while(true) { // it is guaranteed to stop as we set the HEAD bid with very high maximum valuation
      higherBid = bids[lowerBid.next];

      if (_contribution < higherBid.value) {
        return higherBid.prev;
      } else {
        lowerBid = higherBid;
      }
    }
  }

  function getPosition(address addr) view public returns(uint) {
    uint bidId = contributors[addr];
    require(bidId != 0, "cannot ask for a position of a guy who is not on the list");
    uint position = 1;

    Bid memory currentBid = bids[HEAD];

    while (currentBid.prev != bidId) { // BIG LOOP WARNING, that why we have LIMIT
      currentBid = bids[currentBid.prev];
      position++;
    }
    return position;
  }

  function getPosition() view public returns(uint) { // shorthand for calling without parameters
    return getPosition(msg.sender);
  }

}

// File: contracts/AuctionMultipleGuaranteed.sol

// 100000000000000000, "membership in Casa Crypto", 1546300799, "0x8855Ef4b740Fc23D822dC8e1cb44782e52c07e87", 20, 5, 5000000000000000000

// 100000000000000000, "Ethereum coding workshop 24th August 2018", 1538351999, "0x09b25F7627A8d509E5FaC01cB7692fdBc26A2663", 12, 3, 5000000000000000000

// For instance: effering limited "Early Bird" tickets that are guaranteed
contract AuctionMultipleGuaranteed is AuctionMultiple {

  uint public howManyGuaranteed; // after guaranteed slots are used, we decrease the number of slots available (in the parent contract)
  uint public priceGuaranteed;
  address[] public guaranteedContributors; // cannot iterate mapping, keeping addresses in an array
  mapping (address => uint) public guaranteedContributions;
  function getGuaranteedContributorsLenght() public constant returns(uint) { return guaranteedContributors.length; } // lenght is not accessible from DApp, exposing convenience method: https://stackoverflow.com/questions/43016011/getting-the-length-of-public-array-variable-getter

  event GuaranteedBid(address indexed bidder, uint value, uint timestamp);
  
  constructor(uint _price, string _description, uint _timestampEnd, address _beneficiary, uint _howMany, uint _howManyGuaranteed, uint _priceGuaranteed) AuctionMultiple(_price, _description, _timestampEnd, _beneficiary, _howMany) public {
    require(_howMany >= _howManyGuaranteed, "The number of guaranteed items should be less or equal than total items. If equal = fixed price sell, kind of OK with me");
    require(_priceGuaranteed > 0, "Guranteed price must be greated than zero");

    howManyGuaranteed = _howManyGuaranteed;
    priceGuaranteed = _priceGuaranteed;
  }

  function bid() public payable {
    require(now < timestampEnd, "cannot bid after the auction ends");
    require(guaranteedContributions[msg.sender] == 0, "already a guranteed contributor, cannot more than once");

    uint myBidId = contributors[msg.sender];
    if (myBidId > 0) {
      uint newTotalValue = bids[myBidId].value + msg.value;
      if (newTotalValue >= priceGuaranteed && howManyGuaranteed > 0) {
        _removeBid(myBidId);
        _guarantedBid(newTotalValue);
      } else {
        super.bid(); // regular bid (sum is smaller than guranteed or guranteed already used)
      }
    } else if (msg.value >= priceGuaranteed && howManyGuaranteed > 0) {
      _guarantedBid(msg.value);
    } else {
       super.bid(); // regular bid (completely new one)
    }
  }

  function _guarantedBid(uint value) private {
    guaranteedContributors.push(msg.sender);
    guaranteedContributions[msg.sender] = value;
    howManyGuaranteed--;
    howMany--;
    emit GuaranteedBid(msg.sender, value, now);
  }

  function finalize() public ended() onlyOwner() {
    require(finalized == false, "auction already finalized, can withdraw only once");
    finalized = true;

    uint sumContributions = 0;
    uint counter = 0;
    Bid memory currentBid = bids[HEAD];
    while(counter++ < howMany && currentBid.prev != TAIL) {
      currentBid = bids[ currentBid.prev ];
      sumContributions += currentBid.value;
    }

    // At all times we are aware of gas limits - that&#39;s why we limit auction to 2000 participants, see also `test-gasLimit` folder
    for (uint i=0; i<guaranteedContributors.length; i++) {
      sumContributions += guaranteedContributions[ guaranteedContributors[i] ];
    }

    beneficiary.transfer(sumContributions);
  }
}