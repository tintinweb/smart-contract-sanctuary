pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
  /**
  * @dev Exponentiation two numbers, throws on overflow.
  */
  function pow(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(a ** b > 0);
    return a ** b;
  }

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20StandardToken {

  string public name;
  string public symbol;
  uint8 public decimals;

  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

}

contract MultiTransfer {

  using SafeMath for uint256;

  /*
   * @dev. Get ERC20 Standard Token detail information
   */
  function name(address _token) public view returns(string) { return ERC20StandardToken(_token).name(); }
  function symbol(address _token) public view returns(string) { return ERC20StandardToken(_token).symbol(); }
  function decimals(address _token) public view returns(uint8) { return ERC20StandardToken(_token).decimals(); }
  
  /*
   * @dev. Get allowed balance of contract at token
   */
  function allowance(address _token) public view returns(uint256) { return ERC20StandardToken(_token).allowance(msg.sender, address(this)); }
  
  /*
   * @dev. Transfer allowed token
   */
  function transfer(address _token, address[] _to, uint256[] _value) public returns(bool) {

    // Check invalid request
    require(_to.length != 0);
    require(_value.length != 0);
    require(_to.length == _value.length);

    uint256 sum = 0;

    // Check receiver effectiveness
    for (uint256 i = 0; i < _to.length; i++) {
      require(_to[i] != address(0));
      sum.add(_value[i]);
    }

    // Check allowed token balance effectiveness
    assert(allowance(_token) >= sum);

    // Send token
    for (i = 0; i < _to.length; i++) {
      require(ERC20StandardToken(_token).transferFrom(msg.sender, _to[i], _value[i]));
    }

    return true;
  }
}