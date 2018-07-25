pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract BubTokenAbstract {
  function unlock();
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract BubbleCrowdsale {
  using SafeMath for uint256;

  // The token being sold
  address constant public BUB = 0xa27b93097ceA5538456c03630d0c3937BC7D25F8;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public bubbleWallet = 0x8396439236184057aE2efc2578F08be96691C530;

  // how many token units a buyer gets per wei
  uint256 public rate = 10000;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    // calculate token amount to be created
    uint256 bubAmounts = calculateObtainedBUB(msg.value);

    // update state
    weiRaised = weiRaised.add(msg.value);

    require(ERC20Basic(BUB).transfer(beneficiary, bubAmounts));
    TokenPurchase(msg.sender, beneficiary, msg.value, bubAmounts);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    bubbleWallet.transfer(msg.value);
  }

  function calculateObtainedBUB(uint256 amountEtherInWei) public view returns (uint256) {
    return amountEtherInWei.mul(rate).div(10 ** 12);
  } 

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    return withinPeriod;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    bool isEnd = now > endTime || weiRaised >= 10 ** (18 + 4);
    return isEnd;
  }

  // only admin 
  function releaseBubToken() public returns (bool) {
    require (hasEnded() && startTime != 0);
    require (msg.sender == bubbleWallet || now > endTime + 1 hours);
    uint256 remainedBub = ERC20Basic(BUB).balanceOf(this);
    require(ERC20Basic(BUB).transfer(bubbleWallet, remainedBub));    
    BubTokenAbstract(BUB).unlock();
  }

  // be sure to get the joy token ownerships
  function start() public returns (bool) {
    require (msg.sender == bubbleWallet);
    startTime = now;
    endTime = now + 1 hours;
  }

  function changeBubbleWallet(address _bubbleWallet) public returns (bool) {
    require (msg.sender == bubbleWallet);
    bubbleWallet = _bubbleWallet;
  }
}