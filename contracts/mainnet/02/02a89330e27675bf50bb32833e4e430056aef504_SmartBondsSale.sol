pragma solidity ^0.4.18;

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
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
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract token { function transfer(address receiver, uint amount){  } }

contract SmartBondsSale {
  using SafeMath for uint256;

  // uint256 durationInMinutes;
  // address where funds are collected
  address public badgerWallet;
  address public investmentFundWallet;
  address public buyoutWallet;
  // token address
  address addressOfTokenUsedAsReward;

  token tokenReward;



  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;
  // amount of raised money in wei
  uint256 public weiRaised;
  
  uint256 public badgerAmount;
  uint256 public investAmount;
  uint256 public buyoutAmount;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function SmartBondsSale() {
    // ether addressess where funds will be distributed
    badgerWallet = 0x5cB7a6547A9408e3C9B09FB5c640d4fB767b8070; 
    investmentFundWallet = 0x8F2d31E3c259F65222D0748e416A79e51589Ce3b;
    buyoutWallet = 0x336b903eF5e3c911df7f8172EcAaAA651B80CA1D;
   
    // address of SmartBonds Token 
    addressOfTokenUsedAsReward = 0x38dCb83980183f089FC7D147c5bF82E5C9b8F237;
    tokenReward = token(addressOfTokenUsedAsReward);
    
    // start and end times of contract sale 
    startTime = 1533583718; // now
    endTime = startTime + 182 * 1 days; // 182 days
  }

  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    // minimum amount is 2.5 eth, and max is 25 eth 
    uint256 weiAmount = msg.value;
    if(weiAmount < 2.5 * 10**18) throw; 
    if(weiAmount > 25 * 10**18) throw;
    
    // divide wei sent into distribution wallets 
    badgerAmount = (5 * weiAmount)/100;
    buyoutAmount = (25 * weiAmount)/100;
    investAmount = (70 * weiAmount)/100;

    // tokenPrice
    uint256 tokenPrice = 25000000000000000;
    // calculate token amount to be sent
    uint256 tokens = (weiAmount *10**18) / tokenPrice;

    // update state
    weiRaised = weiRaised.add(weiAmount);

    tokenReward.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    // wallet.transfer(msg.value);
    if (!badgerWallet.send(badgerAmount)) {
      throw;
    }
    if (!investmentFundWallet.send(investAmount)){
        throw;
    }
    if (!buyoutWallet.send(buyoutAmount)){
        throw;
    }
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }

  function withdrawTokens(uint256 _amount) {
    if(msg.sender!=badgerWallet) throw;
    tokenReward.transfer(badgerWallet,_amount);
  }
}