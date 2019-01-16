pragma solidity ^0.5.0;

// File: contracts/Pingpong.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "overflow in multiplies operation.");

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "b must be greater than zero.");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "a must be greater than b or equal to b.");
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "c must be greater than b or equal to a.");

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "b must not be zero.");
    return a % b;
  }
}


/**
 * @title PingPong
 * @dev ping pong wei
 */
contract PingPong {
  using SafeMath for uint256;
  uint256 private _total = 0;
  mapping (address => uint256) private _usersUsage;
  address private _owner;

  event Pong(address indexed account, uint256 value);

  constructor() public {
    _owner = msg.sender;
  }

  function () external payable {
    _total = _total.add(1);
    _usersUsage[msg.sender] = _usersUsage[msg.sender].add(1);
    msg.sender.transfer(msg.value);
    emit Pong(msg.sender, msg.value);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  function total() public view returns (uint) {
    return _total;
  }
}