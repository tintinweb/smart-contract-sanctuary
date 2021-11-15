//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./utils/SafeMath.sol";
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
abstract contract ERC20Basic {
  function totalSupply() public virtual view returns (uint256);
  function balanceOf(address who) public virtual view returns (uint256);
  function transfer(address to, uint256 value) public virtual returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public virtual view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
  function approve(address spender, uint256 value) public virtual returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SevereRiseGame is ERC20 {
  using SafeMath for uint256;

  string public constant name = "SevereRiseGame";
  string public constant symbol = "SRG";
  uint8 public constant decimals = 18;
  uint internal totalSupply_;

  address public owner;

  mapping(address => User) public users;
  
  struct User {
    uint256 balance;
    mapping(address => uint256) authorized;
  }

  modifier only_owner(){
    require(msg.sender == owner);
    _;
  }

  // Value argument must be less than unlocked balance.
  modifier value_less_than_unlocked_balance(address _user, uint256 _value){
    User storage user = users[_user];
    require(_value <= user.balance);
    _;
  }
  
  event Burn(address indexed owner, uint256 value);

  constructor(uint _totalSupply) public {
    totalSupply_ = _totalSupply;
    owner = msg.sender;
    User storage user = users[owner];
    user.balance = totalSupply_;
    emit Transfer(address(0), owner, _totalSupply);
  }

  function totalSupply() public view override returns (uint256){
    return totalSupply_;
  }

  function balanceOf(address _addr) public view override returns (uint256 balance) {
    return users[_addr].balance;
  }

  function transfer(address _to, uint256 _value) public override value_less_than_unlocked_balance(msg.sender, _value) returns (bool success) {
    User storage user = users[msg.sender];
    user.balance = user.balance.sub(_value);
    users[_to].balance = users[_to].balance.add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public override value_less_than_unlocked_balance(_from, _value) returns (bool success) {
    User storage user = users[_from];
    user.balance = user.balance.sub(_value);
    users[_to].balance = users[_to].balance.add(_value);
    user.authorized[msg.sender] = user.authorized[msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public override returns (bool success){
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (users[msg.sender].authorized[_spender] == 0));
    users[msg.sender].authorized[_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _user, address _spender) public view override returns (uint256){
    return users[_user].authorized[_spender];
  }

  function burnTokens(uint256 _value) public value_less_than_unlocked_balance(msg.sender, _value) returns (bool success) {
    User storage user = users[msg.sender];
    user.balance = user.balance.sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(msg.sender, _value);
    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }
}

