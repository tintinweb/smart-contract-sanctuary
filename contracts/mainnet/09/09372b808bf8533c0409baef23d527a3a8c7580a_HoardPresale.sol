/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 * 
 ** Code Modified by : TokenMagic
 ** Change Log: 
 *** Solidity version upgraded from 0.4.8 to 0.4.23
 *** Functions Added: setPresaleParticipantWhitelist, setFreezeEnd, getInvestorsCount
 */


pragma solidity ^0.4.23;

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  modifier stopNonOwnersInEmergency {
    require(!halted && msg.sender == owner);
    _;
  }

  modifier onlyInEmergency {
    require(halted);
    _;
  }

  // called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner {
    halted = true;
  }

  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}


contract HoardCrowdsale {
    function invest(address addr,uint tokenAmount) public payable {
    }
}
library SafeMathLib {

  function times(uint a, uint b) public pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}


contract HoardPresale is Ownable {

  using SafeMathLib for uint;
  
  /** Addresses that are allowed to invest even before ICO offical opens. For testing, for ICO partners, etc. */
  mapping (address => bool) public presaleParticipantWhitelist;
  
  /** Who are our investors */
  address[] public investors;
  mapping (address => bool) private investorsMapping;

  /** How much they have invested */
  mapping(address => uint) public balances;
  
  /** A mapping of buyers and their amounts of total tokens due */
  mapping(address => uint256) public tokenDue;

  /** When our refund freeze is over (UNIX timestamp) */
  uint public freezeEndsAt;
  
  /* How many wei of funding pre-sale have raised */
  uint public weiRaised = 0;

  /** Maximum pre-sale ETH fund limit in Wei  */
  uint public maxFundLimit = 16000000000000000000000; //16000 ETH
  
  /** Our ICO contract where we will move the funds */
  HoardCrowdsale public crowdsale;

  /**
  * Define pricing schedule using tranches.
  */
  struct Tranche {
    // Amount in weis when this tranche becomes active
    uint amount;
    // How many tokens per satoshi you will get while this tranche is active
    uint price;
  }
  
  // Store tranches in a fixed array, so that it can be seen in a blockchain explorer
  // Tranche 0 is always (0, 0)
  // (TODO: change this when we confirm dynamic arrays are explorable)
  //
  /* Calculations made by $500/ETH as rate */
  /*
  0 to 114 ETH = 120000000000000 WEI = 0.00012 ETH
  114 ETH to 10000 ETH = 142857142857500 WEI = 0.0001428571428575 ETH
  10000 ETH to 14000 ETH = 200000000000000 WEI = 0.0002 ETH
  */
  Tranche[10] public tranches;

  // How many active tranches we have
  uint public trancheCount;
  uint public constant MAX_TRANCHES = 10;
  uint public tokenDecimals = 18;
  
  event Invested(address investor, uint value);
  event Refunded(address investor, uint value);
  
  //Event to show whitelisted address
  event Whitelisted(address[] addr, bool status);
  
  //Event to show when freezeends data changed
  event FreezeEndChanged(uint newFreezeEnd);
  
  //Event to show crowdsale address changes
  event CrowdsaleAdded(address newCrowdsale);
  
  /**
   * Create presale contract
   */
   
  constructor(address _owner, uint _freezeEndsAt) public {
    require(_owner != address(0) && _freezeEndsAt != 0);
    owner = _owner;
    freezeEndsAt = _freezeEndsAt;
  }

  /**
   * Receive funds for presale
   * Modified by: TokenMagic
   */
   
  function() public payable {  
    // Only Whitelisted addresses can contribute
    require(presaleParticipantWhitelist[msg.sender]);
    require(trancheCount > 0);
    
    address investor = msg.sender;

    bool existing = investorsMapping[investor];

    balances[investor] = balances[investor].add(msg.value);
    weiRaised = weiRaised.add(msg.value);
    require(weiRaised <= maxFundLimit);
    
    uint weiAmount = msg.value;
    uint tokenAmount = calculatePrice(weiAmount);
    
    // Add the amount of tokens they are now due to total tally
    tokenDue[investor] = tokenDue[investor].add(tokenAmount);
        
    if(!existing) {
      investors.push(investor);
      investorsMapping[investor] = true;
    }

    emit Invested(investor, msg.value);
  }
  
  /**
   * Add KYC whitelisted pre-sale participant ETH addresses to contract.
   * Added by: TokenMagic
   */
  function setPresaleParticipantWhitelist(address[] addr, bool status) public onlyOwner {
    for(uint i = 0; i < addr.length; i++ ){
      presaleParticipantWhitelist[addr[i]] = status;
    }
    emit Whitelisted(addr, status);
  }
    
   /**
   * Allow owner to set freezeEndsAt (Timestamp).
   * Added by: TokenMagic
   */
  function setFreezeEnd(uint _freezeEndsAt) public onlyOwner {
    require(_freezeEndsAt != 0);
    freezeEndsAt = _freezeEndsAt;
    emit FreezeEndChanged(freezeEndsAt);
  }  
    
  /**
   * Move single pre-sale participant&#39;s fund to the crowdsale contract.
   * Modified by: TokenMagic
   */
  function participateCrowdsaleInvestor(address investor) public onlyOwner {

    // Crowdsale not yet set
    require(address(crowdsale) != 0);

    if(balances[investor] > 0) {
      uint amount = balances[investor];
      uint tokenAmount = tokenDue[investor];
      delete balances[investor];
      delete tokenDue[investor];
      crowdsale.invest.value(amount)(investor,tokenAmount);
    }
  }

  /**
   * Move all pre-sale participants fund to the crowdsale contract.
   *
   */
  function participateCrowdsaleAll() public onlyOwner {
    // We might hit a max gas limit in this loop,
    // and in this case you can simply call participateCrowdsaleInvestor() for all investors
    for(uint i = 0; i < investors.length; i++) {
      participateCrowdsaleInvestor(investors[i]);
    }
  }
  
  /**
   * Move selected pre-sale participants fund to the crowdsale contract.
   *
   */
  function participateCrowdsaleSelected(address[] addr) public onlyOwner {
    for(uint i = 0; i < addr.length; i++ ){
      participateCrowdsaleInvestor(investors[i]);
    }
  }

  /**
   * ICO never happened. Allow refund.
   * Modified by: TokenMagic
   */
  function refund() public {

    // Trying to ask refund too soon
    require(now > freezeEndsAt && balances[msg.sender] > 0);

    address investor = msg.sender;
    uint amount = balances[investor];
    delete balances[investor];
    emit Refunded(investor, amount);
    investor.transfer(amount);
  }

  /**
   * Set the crowdsale contract address, where we will move presale funds when the crowdsale opens.
   */
  function setCrowdsale(HoardCrowdsale _crowdsale) public onlyOwner {
    crowdsale = _crowdsale;
    emit CrowdsaleAdded(crowdsale);
  }

  /**
  * Get total investors count
  * Added by: TokenMagic
  */ 
  function getInvestorsCount() public view returns(uint investorsCount) {
    return investors.length;
  }
  
  /// @dev Contruction, creating a list of tranches
  /// @param _tranches uint[] tranches Pairs of (start amount, price)
  function setPricing(uint[] _tranches) public onlyOwner {
    // Need to have tuples, length check
    if(_tranches.length % 2 == 1 || _tranches.length >= MAX_TRANCHES*2) {
      revert();
    }

    trancheCount = _tranches.length / 2;

    uint highestAmount = 0;

    for(uint i=0; i<_tranches.length/2; i++) {
      tranches[i].amount = _tranches[i*2];
      tranches[i].price = _tranches[i*2+1];

      // No invalid steps
      if((highestAmount != 0) && (tranches[i].amount <= highestAmount)) {
        revert();
      }

      highestAmount = tranches[i].amount;
    }

    // We need to start from zero, otherwise we blow up our deployment
    if(tranches[0].amount != 0) {
      revert();
    }

    // Last tranche price must be zero, terminating the crowdale
    if(tranches[trancheCount-1].price != 0) {
      revert();
    }
  }
  
  /// @dev Get the current tranche or bail out if we are not in the tranche periods.
  /// @return {[type]} [description]
  function getCurrentTranche() private view returns (Tranche) {
    uint i;

    for(i=0; i < tranches.length; i++) {
      if(weiRaised <= tranches[i].amount) {
        return tranches[i-1];
      }
    }
  }
  
  /// @dev Get the current price.
  /// @return The current price or 0 if we are outside trache ranges
  function getCurrentPrice() public view returns (uint result) {
    return getCurrentTranche().price;
  }
  
  /// @dev Calculate the current price for buy in amount.
  function calculatePrice(uint value) public view returns (uint) {
    uint multiplier = 10 ** tokenDecimals;
    uint price = getCurrentPrice();
    return value.times(multiplier) / price;
  }
  
  /// @dev Iterate through tranches. You reach end of tranches when price = 0
  /// @return tuple (time, price)
  function getTranche(uint n) public view returns (uint, uint) {
    return (tranches[n].amount, tranches[n].price);
  }

  function getFirstTranche() private view returns (Tranche) {
    return tranches[0];
  }

  function getLastTranche() private view returns (Tranche) {
    return tranches[trancheCount-1];
  }

  function getPricingStartsAt() public view returns (uint) {
    return getFirstTranche().amount;
  }

  function getPricingEndsAt() public view returns (uint) {
    return getLastTranche().amount;
  }
  
}