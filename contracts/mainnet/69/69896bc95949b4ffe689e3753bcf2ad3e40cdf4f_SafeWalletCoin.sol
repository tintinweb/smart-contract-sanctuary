pragma solidity ^0.4.4;


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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title SafeWallet Coin
 * @dev Basic version of StandardToken, with no allowances.
 */
contract SafeWalletCoin is ERC20Basic {
  
  using SafeMath for uint256;
  
  string public name = "SafeWallet Coin";
  string public symbol = "SWC";
  uint8 public decimals = 0;
  uint256 public airDropNum = 1000;
  uint256 public totalSupply = 100000000;
  address public owner;

  mapping(address => uint256) balances;

  uint256 totalSupply_;
 
  //event Burn(address indexed from, uint256 value);
 
  function SafeWalletCoin() public {

    totalSupply_ = totalSupply;
    owner = msg.sender;
    balances[msg.sender] = totalSupply;
  }

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(msg.sender == owner);
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
	
    balances[msg.sender] = SafeMath.sub(balances[msg.sender],(_value));
    balances[_to] = SafeMath.add(balances[_to],(_value));

    return true;
  }
  
  function multyTransfer(address[] arrAddr, uint256[] value) public{
    require(msg.sender == owner);
    require(arrAddr.length == value.length);
    for(uint i = 0; i < arrAddr.length; i++) {
      transfer(arrAddr[i],value[i]);
    }
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  
  /**
  * @dev recycle token for a specified address
  * @param _user user address.
  * @param _value The amount to be burnned.
  */
  function recycle(address _user,uint256 _value) returns (bool success) {
	require(msg.sender == owner);
    require(balances[_user] >= _value);
	require(_value > 0);
	balances[msg.sender] = SafeMath.add(balances[msg.sender],(_value));
	balances[_user] = SafeMath.sub(balances[_user],(_value));           
    //Burn(msg.sender, _value);
    return true;
    }

}