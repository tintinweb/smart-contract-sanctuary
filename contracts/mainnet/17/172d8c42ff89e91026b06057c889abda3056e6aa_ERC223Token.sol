pragma solidity ^0.4.23;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
 
/*
 * Safe Math Smart Contract. 
 * https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * ERC223 Receiving token Fallback Contract
 */

contract ERC223ReceivingContract { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint256 _value, bytes _data);
}

/**
 * ERC223 standard interface
 */

contract ERC223Interface {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool success);
    function transfer(address to, uint256 value, bytes data) public returns (bool success);
	function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
/**
 * Implementation of the ERC223 standard token.
 */
 
contract ERC223Token is ERC223Interface {
     using SafeMath for uint256;

     mapping(address => uint256) balances; // List of user balances
	 mapping (address => mapping (address => uint256)) internal allowed;
	
	
	
	 string public name = "COOPAY COIN";
     string public symbol = "COO";
     uint8 public decimals = 18;
     uint256 public totalSupply = 265200000 * (10**18);
	
	
	 function ERC223Token()
     {
       balances[msg.sender] = totalSupply;
     }
  
  
	  // Function to access name of token .
	  function name() constant returns (string _name) {
		  return name;
	  }
	  // Function to access symbol of token .
	  function symbol() constant returns (string _symbol) {
		  return symbol;
	  }
	  // Function to access decimals of token .
	  function decimals() constant returns (uint8 _decimals) {
		  return decimals;
	  }
	  // Function to access total supply of tokens .
	  function totalSupply() constant returns (uint256 _totalSupply) {
		  return totalSupply;
	  }
  
	
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function transfer(address _to, uint256 _value, bytes _data) returns (bool success) {
        
		require(_value > 0);
		require(_to != 0x0);
		require(balances[msg.sender] > 0);
		
        uint256 codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      This function works the same with the previous one
     *      but doesn&#39;t contain `_data` param.
     *      Added due to backwards compatibility reasons.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     */
    function transfer(address _to, uint256 _value) returns (bool success) {
	
	    require(_value > 0);
		require(_to != 0x0);
		require(balances[msg.sender] > 0);
		
        uint256 codeLength;
        bytes memory empty;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value, empty);
        return true;
    }
	
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
     require(_to != address(0));
     require(_value <= balances[_from]);
     require(_value <= allowed[_from][msg.sender]);
     bytes memory empty;
     balances[_from] = balances[_from].sub(_value);
     balances[_to] = balances[_to].add(_value);
     allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
     emit Transfer(_from, _to, _value,empty);
     return true;
   }

   function approve(address _spender, uint256 _value) public returns (bool) {
     allowed[msg.sender][_spender] = _value;
     emit Approval(msg.sender, _spender, _value);
     return true;
   }

  function allowance(address _owner, address _spender) public view returns (uint256) {
     return allowed[_owner][_spender];
   }

    
    /**
     * @dev Returns balance of the `_owner`.
     *
     * @param _owner   The address whose balance will be returned.
     * @return balance Balance of the `_owner`.
     */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
}