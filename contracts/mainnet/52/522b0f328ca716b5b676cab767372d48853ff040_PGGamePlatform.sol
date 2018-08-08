pragma solidity 0.4.21;

/**

 * @title ERC20Basic

 * @dev Simpler version of ERC20 interface

 * @dev see https://github.com/ethereum/EIPs/issues/179

 */

contract ERC20Basic {

  function totalSupply() public view returns (uint256);

  function balanceOf(address who) public view returns (uint256);

  function transfer(address to, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

}



/**

 * @title SafeMath

 * @dev Math operations with safety checks that throw on error

 */

library SafeMath {



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


/**
* @title ERC223 interface
* @dev see https://github.com/ethereum/eips/issues/223
*/
contract ERC223 {
    function transfer(address _to, uint _value, bytes _data) public returns (bool success);
    function transfer(address _to, uint _value, bytes _data, string _fallback) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

/**
 * @title Contract that will work with ERC223 tokens.
 */
 
contract ERC223ReceivingContract { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes _data);
}

/**
* @title ERC223Token
* @dev Generic implementation for the required functionality of the ERC223 standard.
* @dev 
*/
contract PGGamePlatform is ERC223, ERC20Basic {
  using SafeMath for uint256;
  
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  mapping(address => uint256) public balances;

  /**
  * @dev Function to access name of token.
  * @return _name string the name of the token.
  */
  function name() public view returns (string _name) {
    return name;
  }
    
  /**
  * @dev Function to access symbol of token.
  * @return _symbol string the symbol of the token.
  */
  function symbol() public view returns (string _symbol) {
    return symbol;
  }
    
  /**
  * @dev Function to access decimals of token.
  * @return _decimals uint8 decimal point of token fractions.
  */
  function decimals() public view returns (uint8 _decimals) {
    return decimals;
  }
  
  /**
  * @dev Function to access total supply of tokens.
  * @return _totalSupply uint256 total token supply.
  */
  function totalSupply() public view returns (uint256 _totalSupply) {
    return totalSupply;
  }

  /**
  * @dev Function to access the balance of a specific address.
  * @param _owner address the target address to get the balance from.
  * @return _balance uint256 the balance of the target address.
  */
  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return balances[_owner];
  }
  
  
  function PGGamePlatform() public{
      name = "PG Game Platform";
      symbol = "PGG";
      decimals = 4;
      totalSupply = 10000000000 * 10 ** uint(decimals);
      balances[msg.sender] = totalSupply;

  }

  /**
  * @dev Function that is called when a user or another contract wants to transfer funds using custom fallback.
  * @param _to address to which the tokens are transfered.
  * @param _value uint256 amount of tokens to be transfered.
  * @param _data bytes data along token transaction.
  * @param _fallback string name of the custom fallback function to be called after transaction.
  */
  function transfer(address _to, uint256 _value, bytes _data, string _fallback) public returns (bool _success) {
    if (isContract(_to)) {
      if (balanceOf(msg.sender) < _value)
      revert();
      balances[msg.sender] = balanceOf(msg.sender).sub(_value);
      balances[_to] = balanceOf(_to).add(_value);
      
      // Calls the custom fallback function.
      // Will fail if not implemented, reverting transaction.
      assert(_to.call.value(0)(bytes4(keccak256(_fallback)), msg.sender, _value, _data));
      
      Transfer(msg.sender, _to, _value, _data);
      return true;
    } else {
      return transferToAddress(_to, _value, _data);
    }
  }

  /**
  * @dev Function that is called when a user or another contract wants to transfer funds using default fallback.
  * @param _to address to which the tokens are transfered.
  * @param _value uint256 amount of tokens to be transfered.
  * @param _data bytes data along token transaction.
  */
  function transfer(address _to, uint256 _value, bytes _data) public returns (bool _success) {
    if (isContract(_to)) {
      return transferToContract(_to, _value, _data);
    } else {
      return transferToAddress(_to, _value, _data);
    }
  }

  /**
  * @dev Standard function transfer similar to ERC20 transfer with no _data.
  * Added due to backwards compatibility reasons.
  * @param _to address to which the tokens are transfered.
  * @param _value uint256 amount of tokens to be transfered.
  */
  function transfer(address _to, uint256 _value) public returns (bool _success) {
    // Adds empty bytes to fill _data param in functions
    bytes memory empty;
    if (isContract(_to)) {
      return transferToContract(_to, _value, empty);
    } else {
      return transferToAddress(_to, _value, empty);
    }
  }

  /**
  * @dev Function to test whether target address is a contract.
  * @param _addr address to be tested as a contract address or something else.
  * @return _isContract bool true if target address is a contract false otherwise.
  */
  function isContract(address _addr) private view returns (bool _isContract) {
    uint length;
    assembly {
      length := extcodesize(_addr)
    }
    return (length > 0);
  }
    
  /**
  * @dev Function that is called when transaction target is an address.
  * @param _to address to which the tokens are transfered.
  * @param _value uint256 amount of tokens to be transfered.
  * @param _data bytes data along token transaction.
  */
  function transferToAddress(address _to, uint256 _value, bytes _data) private returns (bool _success) {
    if (balanceOf(msg.sender) < _value)
    revert();
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);

    Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  /**
  * @dev Function that is called when transaction target is a contract.
  * @param _to address to which the tokens are transfered.
  * @param _value uint256 amount of tokens to be transfered.
  * @param _data bytes data along token transaction.
  */
  function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool _success) {
    if (balanceOf(msg.sender) < _value) {
        revert();
    }
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);

    // Calls the default fallback function.
    // Will fail if not implemented, reverting transaction.
    ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
    receiver.tokenFallback(msg.sender, _value, _data);

    Transfer(msg.sender, _to, _value, _data);
    return true;
  }
}