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
  

  event BidEvent(address indexed winner, uint indexed price, uint indexed timestamp); // cannot have event and struct with the same name
  event Refund(address indexed sender, uint indexed amount, uint indexed timestamp);
  
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

  function() public payable {

    if (msg.value == 0) { // when sending `0` it acts as if it was `withdraw`
      refund();
      return;
    }

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

  function refundContributors() public ended() onlyOwner() {
    bids[winner] = 0; // setting it to zero that in the refund loop it is skipped
    for (uint i = 0; i < accountsList.length;  i++) {
      if (bids[accountsList[i]] > 0) {
        uint refundValue = bids[accountsList[i]];
        bids[accountsList[i]] = 0;
        accountsList[i].transfer(refundValue); 
      }
    }
  }   

  function refund() public {
    require(msg.sender != winner, &quot;winner cannot refund&quot;);
    require(bids[msg.sender] > 0, &quot;refunds only allowed if you sent something&quot;);

    uint refundValue = bids[msg.sender];
    bids[msg.sender] = 0; // reentrancy fix, setting to zero first
    msg.sender.transfer(refundValue);
    
    emit Refund(msg.sender, refundValue, now);
  }

}

// 1, &quot;something&quot;, 1529659548, &quot;0xca35b7d915458ef540ade6068dfe2f44e8fa733c&quot;, 3

contract AuctionMultiple is Auction {

  uint public constant HEAD = 120000000 * 1e18; // uint(-1); // really big number
  uint public constant TAIL = 0;
  uint public lastBidID = 0;
  uint public acceptedBids = 0;
  uint public cutOffBidID = TAIL; // the last bid that gets it, the remainder will be refunded
  uint public howMany; // number of items to sell, for isntance 40k tickets to a concert
  uint private TEMP = 0; // need to use it when creating new struct
 
  struct Bid {
    uint prev;            // bidID of the previous element.
    uint next;            // bidID of the next element.
    uint value;
    address contributor;  // The contributor who placed the bid.
  }    

  mapping (uint => Bid) public bids; // Map bidID to bid
  mapping (address => uint) public contributors; 
  
  event Withdrawal(address addr, uint value, bool succees);


  event LogNumber(uint number);
  event LogText(string text);
  event LogAddress(address addr);
  
  constructor(uint _price, string _description, uint _timestampEnd, address _beneficiary, uint _howMany) Auction(_price, _description, _timestampEnd, _beneficiary) public {
    emit LogText(&quot;constructor&quot;);


    require(_howMany > 1, &quot;This auction is suited to multiple items. With 1 item only - use different code. Or remove this &#39;require&#39; - you&#39;ve been warned&quot;);
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

  function() public payable {
    if (msg.value == 0) {
      withdraw();
    } else {
      bid();
    }  
  }

  function bid() public payable {
    require(now < timestampEnd, &quot;cannot bid after the auction ends&quot;);

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

          // TODO UPDATE CUTOFF WITDRAWAL BID HERE... ! ! ! ! ! ! ! ! ! ! ! 

        } 

    } else { // bid from this guy does not exist, create a new one
        require(msg.value >= price, &quot;Not much sense sending less than the price, likely an error&quot;); // but it is OK to bid below the cut off bid, some guys may withdraw
        require(lastBidID < 4000, &quot;Due to blockGas limit we limit number of people in the auction to 4000 - round arbitrary number - check test gasLimit folder for more info&quot;);

        lastBidID++;
        acceptedBids++;

        if (msg.value > bids[cutOffBidID].value && acceptedBids > howMany) {
          cutOffBidID = bids[cutOffBidID].next;
        }

        insertionBidId = searchInsertionPoint(msg.value, TAIL);

        contributors[msg.sender] = lastBidID;

        bids[lastBidID] = Bid({
          prev: insertionBidId,
          next: bids[insertionBidId].next,
          value: msg.value,
          contributor: msg.sender
        });

        bids[ bids[insertionBidId].next ].prev = lastBidID;
        bids[insertionBidId].next = lastBidID;
    }
  }

  // We are  starting from TAIL and going upwards
  // This is to simplify the case of increasing bids (can go upwards, cannot go lower)
  // NOTE: blockSize gas limit in case of so many bids (wishful thinking)
  function searchInsertionPoint(uint _contribution, uint _startSearch) view public returns (uint) {
    require(_contribution > bids[_startSearch].value, &quot;your contribution and _startSearch does not make sense, it will search in a wrong direction&quot;);

    Bid memory lowerBid = bids[_startSearch];
    Bid memory higherBid;

    while(true) { // it is guaranteed to stop as we set the HEAD bid with very high maximum valuation
      higherBid = bids[lowerBid.next];

      if (higherBid.value > _contribution) {
        return higherBid.prev;
      } else {
        lowerBid = higherBid;
      }
    }
  }

  function getPosition(address addr) view public returns(uint) {
    uint bidId = contributors[addr];
    require(bidId != 0, &quot;cannot ask for a position of a guy who is not on the list&quot;);
    uint position = 1;

    Bid memory currentBid = bids[HEAD];

    while (currentBid.prev != bidId) { // BIG LOOP WARNING ! ! ! ! ! ! ! ! !
      currentBid = bids[currentBid.prev];
      position++;
    }
    return position;
  }

  // shorthand for calling without parameters
  function getPosition() view public returns(uint) {
    return getPosition(msg.sender);
  }

  // CODE REVIEW / AUDIT PLEASE
  // What is the best practice here?

  function withdraw() public returns (bool) {
    LogText(&quot;withdraw&quot;);

    bool result = withdraw(msg.sender);
    return result;
  }

  function withdraw(address addr) private returns (bool) {
    uint myBidId = contributors[addr];

    require(myBidId > 0, &quot;the guy with this address does not exist, makes no sense to witdraw&quot;);

    Bid memory myBid = bids[ myBidId ];
    Bid memory cutOffBid = bids[cutOffBidID];
    if (myBid.value < cutOffBid.value) { // below treshhold, can withdraw

      bids[ myBid.prev ].next = myBid.next;
      bids[ myBid.next ].prev = myBid.prev;

      delete bids[ myBidId ]; // clearning storage
      delete contributors[ msg.sender ]; // clearning storage

      acceptedBids--;

      addr.transfer(myBid.value);
      emit Withdrawal(addr, myBid.value, true);
      return true; // returning value so that we can test
    } else {
      emit Withdrawal(addr, myBid.value, false);
      return false;
    }
  }

  function withdrawOnBehalf(address addr) public onlyOwner returns (bool){
    bool result = withdraw(addr);
    return result;
  }

  function finalize() public ended() onlyOwner() {
    require(finalized == false, &quot;can withdraw only once&quot;);
    require(initialPrice == false, &quot;can withdraw only if there were bids&quot;);

    finalized = true;
    beneficiary.transfer(1); // TODO: calculate amount to witdraw
  }


}