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

// File: contracts/ChristmasTree.sol

contract ChristmasTree {
  using SafeMath for uint256;

  mapping(address => uint256) private _powers;
  mapping(address => uint256[]) private _decorations;

  function powerOf(address who) public view returns (uint256) {
    return _powers[who];
  }

  function decorationAt(address who, uint256 index) public view returns (uint256) {
    return _decorations[who][index];
  }

  function pray() public {
    _powers[msg.sender] = _powers[msg.sender].add(1);
  }

  function pushDecoration(uint256 decoration) public {
    _decorations[msg.sender].push(decoration);
  }

  function popDecoration() public {
    require(_decorations[msg.sender].length >= 0);
    _decorations[msg.sender].length--;
  }

  function replaceDecoration(uint256 index, uint256 decoration) public {
    require(index < _decorations[msg.sender].length);
    _decorations[msg.sender][index] = decoration;
  }
}