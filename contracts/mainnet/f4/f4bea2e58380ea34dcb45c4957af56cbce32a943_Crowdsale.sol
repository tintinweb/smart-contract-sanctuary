pragma solidity ^0.4.23;

// ----------------------------------------------------------------------------
// &#39;buckycoin&#39; CROWDSALE token contract
//
// Deployed to : 0xf4bea2e58380ea34dcb45c4957af56cbce32a943
// Symbol      : BUC
// Name        : buckycoin Token
// Total supply: 940000000
// Decimals    : 18
//
// POWERED BY BUCKY HOUSE.
//
// (c) by Team @ BUCKYHOUSE  2018.
// ----------------------------------------------------------------------------

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0 uint256 c = a / b;
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded 
 to a wallet
 * as they arrive.
 */
contract token { function transfer(address receiver, uint amount){  } }
contract Crowdsale {
  using SafeMath for uint256;

  // uint256 durationInMinutes;
  // address where funds are collected
  address public wallet;
  // token address
  address public addressOfTokenUsedAsReward;

  uint256 public price = 1000;
  uint256 public bonusPercent = 20;
  uint256 public referralBonusPercent = 5;

  token tokenReward;

  // mapping (address => uint) public contributions;
  // mapping(address => bool) public whitelist;
  mapping (address => uint) public bonuses;
  mapping (address => uint) public bonusUnlockTime;


  // start and end timestamps where investments are allowed (both inclusive)
  // uint256 public startTime;
  // uint256 public endTime;
  // amount of raised money in wei
  uint256 public weiRaised;
  uint256 public tokensSold;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale() {

    //You will change this to your wallet where you need the ETH 
    wallet = 0x965A2a21C60252C09E5e2872b8d3088424c4f58A;
    // durationInMinutes = _durationInMinutes;
    //Here will come the checksum address we got
    addressOfTokenUsedAsReward = 0xF86C2C4c7Dd79Ba0480eBbEbd096F51311Cfb952;


    tokenReward = token(addressOfTokenUsedAsReward);
  }

  bool public started = true;

  function startSale() {
    require(msg.sender == wallet);
    started = true;
  }

  function stopSale() {
    require(msg.sender == wallet);
    started = false;
  }

  function setPrice(uint256 _price) {
    require(msg.sender == wallet);
    price = _price;
  }

  function changeWallet(address _wallet) {
    require(msg.sender == wallet);
    wallet = _wallet;
  }

  function changeTokenReward(address _token) {
    require(msg.sender==wallet);
    tokenReward = token(_token);
    addressOfTokenUsedAsReward = _token;
  }

  function setBonusPercent(uint256 _bonusPercent) {
    require(msg.sender == wallet);
    bonusPercent = _bonusPercent;
  }

  function getBonus() {
    address sender = msg.sender;
    require(bonuses[sender] > 0);
    require(bonusUnlockTime[sender]!=0 && 
      now > bonusUnlockTime[sender]);
    tokenReward.transfer(sender, bonuses[sender]);
    bonuses[sender] = 0;
  }

  function setReferralBonusPercent(uint256 _referralBonusPercent) {
    require(msg.sender == wallet);
    referralBonusPercent = _referralBonusPercent;
  }


  // function whitelistAddresses(address[] _addrs){
  //   require(msg.sender==wallet);
  //   for(uint i = 0; i < _addrs.length; ++i)
  //     whitelist[_addrs[i]] = true;
  // }

  // function removeAddressesFromWhitelist(address[] _addrs){
  //   require(msg.sender==wallet);
  //   for(uint i = 0;i < _addrs.length;++i)
  //     whitelist[_addrs[i]] = false;
  // }

  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender, 0x0);
  }

  // low level token purchase function
  function buyTokens(address beneficiary, address referrer) payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    // require(whitelist[beneficiary]);

    uint256 weiAmount = msg.value;

    // if(weiAmount < 10**16) throw;
    // if(weiAmount > 50*10**18) throw;

    // calculate token amount to be sent
    uint256 tokens = weiAmount.mul(price);
    uint256 bonusTokens = tokens.mul(bonusPercent)/100;
    uint256 referralBonusTokens = tokens.mul(referralBonusPercent)/100;
    // uint256 tokens = (weiAmount/10**(18-decimals)) * price;//weiamount * price 


    // update state
    weiRaised = weiRaised.add(weiAmount);
    
    // if(contributions[msg.sender].add(weiAmount)>10*10**18) throw;
    // contributions[msg.sender] = contributions[msg.sender].add(weiAmount);

    tokenReward.transfer(beneficiary, tokens);
    tokensSold = tokensSold.add(tokens);
    bonuses[beneficiary] = bonuses[beneficiary].add(bonusTokens);
    bonusUnlockTime[beneficiary] = now.add(6*30 days);
    tokensSold = tokensSold.add(bonusTokens);
    if (referrer != 0x0) {
      bonuses[referrer] = bonuses[referrer].add(referralBonusTokens);
      bonusUnlockTime[referrer] = now.add(6*30 days);
      tokensSold = tokensSold.add(referralBonusTokens);      
    }

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = started;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  function withdrawTokens(uint256 _amount) {
    require(msg.sender==wallet);
    tokenReward.transfer(wallet,_amount);
  }
}