pragma solidity ^0.4.24;

/**
* @title SafeMath
* @dev Math operations with safety checks that revert on error
*/
library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

library SafeERC20 {
  function safeTransfer(IERC20 token, address to, uint256 value) internal{
    require(token.transfer(to, value));
  }

  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(IERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract TalaRCrowdsale is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // The token being sold
  IERC20 private _token;

  // Address where funds are collected
  address private _wallet;

  // How many token units a buyer gets per wei.
  uint256 private _rate;

  // Same as _rate but in bonus time
  uint256 private _bonusRate;

  // bonus cap in wei
  uint256 private _bonusCap;

  // Amount of wei raised
  uint256 private _weiRaised;

  // Timestamps
  uint256 private _openingTime;
  uint256 private _bonusEndTime;
  uint256 private _closingTime;

  // Minimal contribution - 0.05 ETH
  uint256 private constant MINIMAL_CONTRIBUTION = 50000000000000000;

  event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  constructor(uint256 rate, uint256 bonusRate, uint256 bonusCap, uint256 openingTime, uint256 bonusEndTime, uint256 closingTime, address wallet, IERC20 token) public {
    require(rate > 0);
    require(bonusRate > 0);
    require(bonusCap > 0);
    require(openingTime >= block.timestamp);
    require(bonusEndTime >= openingTime);
    require(closingTime >= bonusEndTime);
    require(wallet != address(0));

    _rate = rate;
    _bonusRate = bonusRate;
    _bonusCap = bonusCap;
    _wallet = wallet;
    _token = token;
    _openingTime = openingTime;
    _closingTime = closingTime;
    _bonusEndTime = bonusEndTime;
  }

  function () external payable {
    buyTokens(msg.sender);
  }

  function token() public view returns(IERC20) {
    return _token;
  }

  function wallet() public view returns(address) {
    return _wallet;
  }

  function rate() public view returns(uint256) {
    return _rate;
  }

  function bonusRate() public view returns(uint256) {
    return _bonusRate;
  }

  function bonusCap() public view returns(uint256) {
    return _bonusCap;
  }

  function weiRaised() public view returns (uint256) {
    return _weiRaised;
  }

  function openingTime() public view returns(uint256) {
    return _openingTime;
  }

  function closingTime() public view returns(uint256) {
    return _closingTime;
  }

  function bonusEndTime() public view returns(uint256) {
    return _bonusEndTime;
  }

  function buyTokens(address beneficiary) public payable {
    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount);

    uint256 tokenAmount = _getTokenAmount(weiAmount);

    _weiRaised = _weiRaised.add(weiAmount);

    _token.safeTransfer(beneficiary, tokenAmount);
    emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokenAmount);

    _forwardFunds();
  }

  function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal {
    require(isOpen());
    require(beneficiary != address(0));
    require(weiAmount >= MINIMAL_CONTRIBUTION);
  }

  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    return weiAmount.mul(_getCurrentRate());
  }

  function _forwardFunds() internal {
    _wallet.transfer(msg.value);
  }

  function _getCurrentRate() internal view returns (uint256) {
    return isBonusTime() ? _bonusRate : _rate;
  }

  function isOpen() public view returns (bool) {
    return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
  }

  function hasClosed() public view returns (bool) {
    return block.timestamp > _closingTime;
  }

  function isBonusTime() public view returns (bool) {
    return block.timestamp >= _openingTime && block.timestamp <= _bonusEndTime && _weiRaised <= _bonusCap;
  }

  // ETH balance is always expected to be 0.
  // but in case something went wrong, owner can extract ETH
  function emergencyETHDrain() external onlyOwner {
    _wallet.transfer(address(this).balance);
  }

  // owner can drain tokens that are sent here by mistake
  function emergencyERC20Drain(IERC20 tokenDrained, uint amount) external onlyOwner {
    tokenDrained.transfer(owner, amount);
  }

  // when sale is closed owner can drain any tokens left 
  function tokensLeftDrain(uint amount) external onlyOwner {
    require(hasClosed());
    _token.transfer(owner, amount);
  }
}