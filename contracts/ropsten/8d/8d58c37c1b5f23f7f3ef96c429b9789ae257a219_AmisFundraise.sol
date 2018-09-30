pragma solidity ^0.4.24;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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


contract AmisTokenAbstract {
  function unlock();
}

/**
 * @title Airdrop Marketing Incentives Solutions - AMIS-
 * @dev Airdrop Marketing Incentives Solutions - AMIS - is a base contract for managing Amis token ATF - Asset Traded Fund as a
 * revenue generator leveraged by a time based Airdrop distribution mecanism used for new projects developments; it has a start and end timestamps, where traders, investors, subscribers
 * purchase Amis Tokens and the Smart Contract will assign them tokens based
 * on AMIS - ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract AmisFundraise {
  using SafeMath for uint256;

  // The token being sold
  address constant public AMIS = 0x949bEd886c739f1A3273629b3320db0C5024c719;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public amisWallet = 0xB7C7D8488966BD297BAB7Ca780FB1923F982A419;

  // how many token units a buyer gets per wei current 0.01 for 1 amis
  uint256 public rate = 10000000000000000;

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

    // calculate token amount 
    uint256 amisAmounts = calculateObtainedAMIS(msg.value);

    // update state
    weiRaised = weiRaised.add(msg.value);

    require(ERC20Basic(AMIS).transfer(beneficiary, amisAmounts));
    TokenPurchase(msg.sender, beneficiary, msg.value, amisAmounts);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    amisWallet.transfer(msg.value);
  }

  function calculateObtainedAMIS(uint256 amountEtherInWei) public view returns (uint256) {
    return amountEtherInWei.mul(rate).div(10 ** 12);
  } 

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    return withinPeriod;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    bool isEnd = now > endTime || weiRaised >= 10 ** (18 + 2);
    return isEnd;
  }

  // only admin 
  function releaseAmisToken() public returns (bool) {
    require (hasEnded() && startTime != 0);
    require (msg.sender == amisWallet || now > endTime + 3 days);
    uint256 remainedAmis = ERC20Basic(AMIS).balanceOf(this);
    require(ERC20Basic(AMIS).transfer(amisWallet, remainedAmis));    
    AmisTokenAbstract(AMIS).unlock();
  }

  // be sure to get the Amis token ownerships
  function start() public returns (bool) {
    require (msg.sender == amisWallet);
    startTime = now;
    endTime = now + 2 days;
  }

  function changeAmisWallet(address _amisWallet) public returns (bool) {
    require (msg.sender == amisWallet);
    amisWallet = _amisWallet;
  }
}