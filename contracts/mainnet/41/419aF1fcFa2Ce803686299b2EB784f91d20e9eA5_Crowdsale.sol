pragma solidity ^0.6.6;

import "./TRTF.sol";

contract Crowdsale is Ownable {
  using SafeMath for uint256;
  using Address for address;

  TortoToken private token;

  uint256 public cap = 500 ether;

  address payable private wallet; 

  uint256 public rate = 500;

  uint256 public minContribution = 0.5 ether;
  uint256 public maxContribution = 5 ether;

  uint256 public weiRaised;
  mapping (address => uint256) public contributions;

  bool public isCrowdsaleFinalized = false;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function CrowdsaleStarter(TortoToken _token)  public onlyOwner {
    token = _token;
    wallet = address(uint160(owner()));
  }

  receive () external payable {
    purchaseTokens(msg.sender);
  }

  function purchaseTokens(address recipient) public payable {
    require(recipient != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 amount = getTokenAmount(weiAmount);

    weiAmount = weiRaised.add(weiAmount);
    contributions[recipient] = contributions[recipient].add(weiAmount);

    token.purchase(recipient, amount);
    emit TokenPurchase(msg.sender, recipient, weiAmount, amount);
    wallet.transfer(msg.value);
  }

  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return capReached || isCrowdsaleFinalized;
  }

  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    uint256 tokens = weiAmount.mul(rate);
    return tokens;
  }

  function validPurchase() internal view returns (bool) {
    require(weiRaised.add(msg.value) <= cap);
    bool moreThanMinPurchase = msg.value >= minContribution;
    bool lessThanMaxPurchase = contributions[msg.sender] + msg.value <= maxContribution;
    return  moreThanMinPurchase  && lessThanMaxPurchase && !isCrowdsaleFinalized;
  }

  function finalizeCrowdsale() public onlyOwner {
    isCrowdsaleFinalized = true;
  }
}

// SPDX-License-Identifier: UNLICENSED
