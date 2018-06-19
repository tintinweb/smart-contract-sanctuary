pragma solidity ^0.4.7;

contract bet_various{
    enum State { Started, Locked }
  State public state = State.Started;
  struct Guess{
    address addr;
    uint    guess;
  }
  uint arraysize=1000;
  uint constant maxguess=1000000;
  uint bettingprice = 0.01 ether;
  Guess[1000] guesses;
  uint    numguesses = 0;
  bytes32 curhash = &#39;&#39;;
  
  uint stasticsarrayitems = 20;
  uint[20] statistics;

  uint _gameindex = 1;
  
  struct Winner{
    address addr;
  }
  Winner[1000] winnners;
  uint    numwinners = 0;

  modifier inState(State _state) {
      require(state == _state);
      _;
  }
 
  address developer = 0x0;
  event SentPrizeToWinner(address winner, uint money, uint guess, uint gameindex, uint lotterynumber, uint timestamp);
  event SentDeveloperFee(uint amount, uint balance);

  function bet_various() 
  {
    if(developer==address(0)){
      developer = msg.sender;
    }
  }

  function setBettingCondition(uint _contenders, uint _bettingprice)
  {
    if(msg.sender != developer)
      return;
  	arraysize  = _contenders;
  	if(arraysize>1000)
  	  arraysize = 1000;
  	bettingprice = _bettingprice;
  }
  
  function getMaxContenders() constant returns(uint){
  	return arraysize;
  }

  function getBettingPrice() constant returns(uint){
  	return bettingprice;
  }
    
  function findWinners(uint value) returns (uint)
  {
    numwinners = 0;
    uint lastdiff = maxguess;
    uint i = 0;
    int diff = 0;
    uint guess = 0;
    for (i = 0; i < numguesses; i++) {
      diff = (int)((int)(value)-(int)(guesses[i].guess));
      if(diff<0)
        diff = diff*-1;
      if(lastdiff>(uint)(diff)){
        guess = guesses[i].guess;
        lastdiff = (uint)(diff);
      }
    }
    
    for (i = 0; i < numguesses; i++) {
      diff = (int)((int)(value)-(int)(guesses[i].guess));
      if(diff<0)
        diff = diff*-1;
      if(lastdiff==uint(diff)){
        winnners[numwinners++].addr = guesses[i].addr;
      }
    }
    return guess;
  }
  
  function getDeveloperAddress() constant returns(address)
  {
    return developer;
  }
  
  function getDeveloperFee() constant returns(uint)
  {
    uint developerfee = this.balance/100;
    return developerfee;
  }
  
  function getBalance() constant returns(uint)
  {
     return this.balance;
  }
  
  function getLotteryMoney() constant returns(uint)
  {
    uint developerfee = getDeveloperFee();
    uint prize = (this.balance - developerfee)/(numwinners<1?1:numwinners);
    return prize;
  }

  function getBettingStastics() 
    payable
    returns(uint[20])
  {
    require(msg.value == bettingprice*3);
    return statistics;
  }
  
  function getBettingStatus()
    constant
    returns (uint, uint, uint, uint, uint)
  {
    return ((uint)(state), numguesses, getLotteryMoney(), this.balance, bettingprice);
  }
  
  function finish()
  {
    state = State.Locked;

    uint lotterynumber = (uint(curhash)+block.timestamp)%(maxguess+1);
    // now that we know the random number was safely generate, let&#39;s do something with the random number..
    var guess = findWinners(lotterynumber);
    uint prize = getLotteryMoney();
    uint remain = this.balance - (prize*numwinners);
    for (uint i = 0; i < numwinners; i++) {
      address winner = winnners[i].addr;
      winner.transfer(prize);
      SentPrizeToWinner(winner, prize, guess, _gameindex, lotterynumber, block.timestamp);
    }
    // give delveoper the money left behind
    SentDeveloperFee(remain, this.balance);
    developer.transfer(remain); 
    
    numguesses = 0;
    for (i = 0; i < stasticsarrayitems; i++) {
      statistics[i] = 0;
    }
    _gameindex++;
    state = State.Started;
  }

  function addguess(uint guess) 
    inState(State.Started)
    payable
  {
    require(msg.value == bettingprice);
    
    uint divideby = maxguess/stasticsarrayitems;
    curhash = sha256(block.timestamp, block.coinbase, block.difficulty, curhash);
    if((uint)(numguesses+1)<=arraysize) {
      guesses[numguesses++] = Guess(msg.sender, guess);
      uint statindex = guess / divideby;
      if(statindex>=stasticsarrayitems) statindex = stasticsarrayitems-1;
      statistics[statindex] ++;
      if((uint)(numguesses)>=arraysize){
        finish();
      }
    }
  }
}