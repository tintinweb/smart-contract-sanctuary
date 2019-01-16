// ERC20Faucet
// Copyright (C) 2018  WeTrustPlatform
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.4.19;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
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

contract ERC20TokenInterface {
  function totalSupply() constant public returns (uint256 supply);
  function balanceOf(address _owner) constant public returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Faucet {
  using SafeMath for uint256;

  uint256 public maxAllowanceInclusive;
  mapping (address => uint256) public claimedTokens;
  ERC20TokenInterface public erc20Contract;
  bool public isPaused = false;

  address private mOwner;
  bool private mReentrancyLock = false;

  event GetTokens(address requestor, uint256 amount);
  event ReclaimTokens(address owner, uint256 tokenAmount);
  event SetPause(address setter, bool newState, bool oldState);
  event SetMaxAllowance(address setter, uint256 newState, uint256 oldState);

  modifier notPaused() {
    require(!isPaused);
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == mOwner);
    _;
  }

  modifier nonReentrant() {
    require(!mReentrancyLock);
    mReentrancyLock = true;
    _;
    mReentrancyLock = false;
  }

  constructor (ERC20TokenInterface _erc20ContractAddress, uint256 _maxAllowanceInclusive) public {
    mOwner = msg.sender;
    maxAllowanceInclusive = _maxAllowanceInclusive;
    erc20Contract = _erc20ContractAddress;
  }

  function getTokens(uint256 amount) notPaused nonReentrant public returns (bool) {
    require(claimedTokens[msg.sender].add(amount) <= maxAllowanceInclusive);
    require(erc20Contract.balanceOf(this) >= amount);
    
    claimedTokens[msg.sender] = claimedTokens[msg.sender].add(amount);

    if (!erc20Contract.transfer(msg.sender, amount)) {
      claimedTokens[msg.sender] = claimedTokens[msg.sender].sub(amount);
      return false;
    }
    
    emit GetTokens(msg.sender, amount);
    return true;
  }

  function setMaxAllowance(uint256 _maxAllowanceInclusive) onlyOwner nonReentrant public {
    emit SetMaxAllowance(msg.sender, _maxAllowanceInclusive, maxAllowanceInclusive);
    maxAllowanceInclusive = _maxAllowanceInclusive;
  }

  function reclaimTokens() onlyOwner nonReentrant public returns (bool) {
    uint256 tokenBalance = erc20Contract.balanceOf(this);
    if (!erc20Contract.transfer(msg.sender, tokenBalance)) {
      return false;
    }

    emit ReclaimTokens(msg.sender, tokenBalance);
    return true;
  }

  function setPause(bool _isPaused) onlyOwner nonReentrant public {
    emit SetPause(msg.sender, _isPaused, isPaused);
    isPaused = _isPaused;
  }
}