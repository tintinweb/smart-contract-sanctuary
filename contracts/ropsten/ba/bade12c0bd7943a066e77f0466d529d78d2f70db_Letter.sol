pragma solidity >0.4.99 <0.6.0;

// File: contracts/SafeMath.sol

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(a >= b);
    uint256 c = a - b;
    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a % b;
    return c;
  }
}

// File: contracts/Letter.sol

contract Letter {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;
  mapping(address => bool) private _isSealeds;

  function balanceOf(address who) public view returns (uint256) {
    return _balances[who];
  }

  function isSealed(address who) public view returns (bool) {
    return _isSealeds[who];
  }

  function () payable external {
    require(!_isSealeds[msg.sender]);
    _balances[msg.sender] = _balances[msg.sender].add(msg.value);
  }

  function seal() public {
    require(_balances[msg.sender] > 0);
    _isSealeds[msg.sender] = true;
  }

  function discard() public {
    uint256 balance = _balances[msg.sender];
    _balances[msg.sender] = 0;
    _isSealeds[msg.sender] = false;
    msg.sender.transfer(balance);
  }
}