pragma solidity ^0.4.11;

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

  // uint256 public price = 18000;

  token tokenReward;

  // mapping (address => uint) public contributions;
  mapping(address => bool) public whitelist;


  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;
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
    // how many minutes
    startTime = now + 80715 * 1 minutes;
    endTime = startTime + 31*24*60*1 minutes;

    //You will change this to your wallet where you need the ETH 
    wallet = 0xe65b6eEAfE34adb2e19e8b2AE9c517688771548E;
    // durationInMinutes = _durationInMinutes;
    //Here will come the checksum address we got
    addressOfTokenUsedAsReward = 0xA024E8057EEC474a9b2356833707Dd0579E26eF3;


    tokenReward = token(addressOfTokenUsedAsReward);
  }

  // bool public started = true;

  // function startSale(){
  //   require(msg.sender == wallet);
  //   started = true;
  // }

  // function stopSale(){
  //   require(msg.sender == wallet);
  //   started = false;
  // }

  // function setPrice(uint256 _price){
  //   require(msg.sender == wallet);
  //   price = _price;
  // }

  function changeWallet(address _wallet){
  	require(msg.sender == wallet);
  	wallet = _wallet;
  }

  // function changeTokenReward(address _token){
  //   require(msg.sender==wallet);
  //   tokenReward = token(_token);
  //   addressOfTokenUsedAsReward = _token;
  // }

  function whitelistAddresses(address[] _addrs){
    require(msg.sender==wallet);
    for(uint i = 0; i < _addrs.length; ++i)
      whitelist[_addrs[i]] = true;
  }

  function removeAddressesFromWhitelist(address[] _addrs){
    require(msg.sender==wallet);
    for(uint i = 0;i < _addrs.length;++i)
      whitelist[_addrs[i]] = false;
  }

  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    require(whitelist[beneficiary]);

    uint256 weiAmount = msg.value;

    // if(weiAmount < 10**16) throw;
    // if(weiAmount > 50*10**18) throw;

    // calculate token amount to be sent
    uint256 tokens = (weiAmount) * 5000;//weiamount * price 
    // uint256 tokens = (weiAmount/10**(18-decimals)) * price;//weiamount * price 

    //bonus schedule

    /*
      PRE-ICO. (1ETH= 7000 FXY)
      Start 1.5.2018
      End 9.5.2018
      Total coins with 40% bonus 14.000.000 FXY
      ICO LEVEL 1 (1ETH=6000 FXY)
      Start 16.5.2018
      End 23.5.2018
      Total coins 54.000.000 FXY with 20% bonus
      ICO LEVEL 2 (1ETH=5000FXY)
      Start 25.5.2018
      End 31.5.2018
      Total coins —> if on ICO Level 1 not sold out, it will be drop here.
    */
    if(now < startTime + 9*24*60* 1 minutes){
      tokens += (tokens * 40) / 100;//40%
      if(tokensSold>14000000*10**18) throw;
    }else if(now < startTime + 16*24*60* 1 minutes){
      throw;
    }else if(now < startTime + 23*24*60* 1 minutes){
      tokens += (tokens * 20) / 100;
    }else if(now < startTime + 25*24*60* 1 minutes){
      throw;
    }

    // update state
    weiRaised = weiRaised.add(weiAmount);
    
    // if(contributions[msg.sender].add(weiAmount)>10*10**18) throw;
    // contributions[msg.sender] = contributions[msg.sender].add(weiAmount);

    tokenReward.transfer(beneficiary, tokens);
    tokensSold = tokensSold.add(tokens);
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
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  function withdrawTokens(uint256 _amount) {
    require(msg.sender==wallet);
    tokenReward.transfer(wallet,_amount);
  }
}