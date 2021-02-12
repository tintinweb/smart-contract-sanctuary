/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract MockERC20Token {
  using SafeMath for uint256;

  mapping(address => uint256) private balances;
  
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  
  constructor(string memory name, string memory symbol, uint8 decimals) public
  { 
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
    mint(msg.sender, 10000 * 10 ** uint256(_decimals));
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string memory) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string memory) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }

  function transfer(address to, uint256 value) public returns (bool) {
    return transferFrom(msg.sender, to, value);
  }

  function mint(address to, uint256 amount) public returns (bool) {
    balances[to] = balances[to].add(amount);
    return true;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return balances[owner];
  }
  
  function approve(address spender, uint256 amount) public returns (bool) {
      return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);
    return true;
  }
}