pragma solidity ^0.4.18;

 
contract Token {
	function SetupToken(string tokenName, string tokenSymbol, uint256 tokenSupply) public;
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _amount) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
    function approve(address _spender, uint256 _amount) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

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
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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


/**
 * @title Crowdsale *Modded*
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Author: https://github.com/OpenZeppelin/zeppelin-solidity/tree/master/contracts/crowdsale
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive. 
 * Modded to use preminted token contract, and graft in capped crowdsale code from the openZepplin github
 * Adapted for VRENAR WINK tokens pre-sale
 */
 
 
contract WinkSale {
  using SafeMath for uint256;

  Token token;
  address public owner;
  
  // public cap in wei : when initialized, its per ether
  uint256 public cap;
  
  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei : when initialized, its per ether
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;
  
  
  // amount of raised money in current tier in wei
  uint256 public tierTotal;
  
  //tier count
  uint256 public tierNum = 0;
  
  //Funding Tiers  
  //Each tier will be funded with tokens one year at a time
  //The tokens for each successive year will not be added to the sales contract until:
  //the VRENAR community agrees the objectives for the previous year have been met.
  //This may be executed by secondary democratic contract, or by manual crowd consensus
  uint256[5] fundingRate = [1200, 480, 96, 48, 24]; //WINK per Eth
  uint256[5] fundingLimit = [7800000000, 3000000000, 560000000, 400000000, 240000000]; //Max WINKs Available per tier


  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event FailedTransfer(address indexed to, uint256 value);
  event initialCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _cap, uint256 cap, uint256 _rate, uint256 rate, address _wallet);

  function WinkSale(uint256 _startTime, uint256 _endTime, uint256 _cap, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_cap > 0);
    require(_wallet != address(0));
    
    owner = msg.sender;
    address _tokenAddr = 0x29fA00dCF17689c8654d07780F9E222311D6Bf0c; //Token Contract Address
    token = Token(_tokenAddr);
      
    startTime = _startTime;
    endTime = _endTime;
    rate =  fundingRate[tierNum];  
    cap = _cap.mul(1 ether);  
    wallet = _wallet;
    
    initialCrowdsale(_startTime, _endTime, _cap, cap, fundingRate[tierNum], rate, _wallet);

  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be sent in wei
    uint256 tokens = getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);
    tierTotal = tierTotal.add(weiAmount);

    // Check balance of contract
    token.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    
    forwardFunds();
    
    //upgrade rate tier check
    rateUpgrade(tierTotal);
  }

  // @return true if crowdsale event has ended & limit has not been reached
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    bool timeLimit = now > endTime;
    return capReached || timeLimit;
  }


  // If weiAmountRaised is over tier thresholds, then upgrade WINK per eth
  function rateUpgrade(uint256 tierAmount) internal {
    uint256 tierEthLimit  = fundingLimit[tierNum].div(fundingRate[tierNum]);
    uint256 tierWeiLimit  = tierEthLimit.mul(1 ether);
    if(tierAmount >= tierWeiLimit) {
        tierNum = tierNum.add(1); //increment tier number
        rate = fundingRate[tierNum]; // set new rate in wei
        tierTotal = 0; //reset to 0 wei
    }
 }
  // Override this method to have a way to add business logic to your crowdsale when buying
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
        return weiAmount.mul(rate);
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  
  // @return true if the transaction can buy tokens & within cap & nonzero
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && withinCap && nonZeroPurchase;
  }
  
  function tokensAvailable() public onlyOwner constant returns (uint256) {
    return token.balanceOf(this);
  }
  
  
  function getRate() public onlyOwner constant returns(uint256) {
    return rate;
  }

  function getWallet() public onlyOwner constant returns(address) {
    return wallet;
  }
  
  function destroy() public onlyOwner payable {
    uint256 balance = tokensAvailable();
    if(balance > 0) {
    token.transfer(owner, balance);
    }
    selfdestruct(owner);
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}