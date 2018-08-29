pragma solidity ^0.4.24;

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


contract SBTTokenAbstract {
  function unlock() public;
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract StarbitCrowdsale {
  using SafeMath for uint256;

  // The token being sold
  address constant public SBT = 0x503F9794d6A6bB0Df8FBb19a2b3e2Aeab35339Ad;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public starbitWallet = 0xb94F5256B4B87bb7366fA85963Ae041a31F2CcFE;
  address public setWallet = 0xdca6c0569bb618f8dd91e259681e26363dbc16d4;
  // how many token units a buyer gets per wei
  uint256 public rate = 6000;

  // amount of raised money in wei
  uint256 public weiRaised;
  uint256 public weiSold;

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
    require(msg.value>=100000000000000000 && msg.value<=200000000000000000000);
    // calculate token amount to be created
    uint256 sbtAmounts = calculateObtainedSBT(msg.value);

    // update state
    weiRaised = weiRaised.add(msg.value);
    weiSold = weiSold.add(sbtAmounts);
    require(ERC20Basic(SBT).transfer(beneficiary, sbtAmounts));
    emit TokenPurchase(msg.sender, beneficiary, msg.value, sbtAmounts);
    
    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    starbitWallet.transfer(msg.value);
  }

  function calculateObtainedSBT(uint256 amountEtherInWei) public view returns (uint256) {
    checkRate();
    return amountEtherInWei.mul(rate);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    return withinPeriod;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    bool isEnd = now > endTime || weiRaised >= 20000000000000000000000000;
    return isEnd;
  }

  // only admin 
  function releaseSbtToken() public returns (bool) {
    require (msg.sender == setWallet);
    require (hasEnded() && startTime != 0);
    uint256 remainedSbt = ERC20Basic(SBT).balanceOf(this);
    require(ERC20Basic(SBT).transfer(starbitWallet, remainedSbt));    
    SBTTokenAbstract(SBT).unlock();
  }

  // be sure to get the token ownerships
  function start() public returns (bool) {
    require (msg.sender == setWallet);
    startTime = 1533052800;
    endTime = 1535731199;
  }

  function changeStarbitWallet(address _starbitWallet) public returns (bool) {
    require (msg.sender == setWallet);
    starbitWallet = _starbitWallet;
  }
   function checkRate() public returns (bool) {
    if (now>=startTime && now<1533657600){
        rate = 6000;
    }else if (now >= 1533657600 && now < 1534867200) {
        rate = 5500;
    }else if (now >= 1534867200) {
        rate = 5000;
    }
  }
}