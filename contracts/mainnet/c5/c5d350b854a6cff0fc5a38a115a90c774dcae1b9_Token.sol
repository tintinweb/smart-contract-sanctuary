pragma solidity ^0.4.19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() internal {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


/**
 * @title Authorizable
 * @dev The Authorizable contract has authorized addresses, and provides basic authorization control
 * functions, this simplifies the implementation of "multiple user permissions".
 */
contract Authorizable is Ownable {
  mapping(address => bool) public authorized;
  
  event AuthorizationSet(address indexed addressAuthorized, bool indexed authorization);

  /**
   * @dev The Authorizable constructor sets the first `authorized` of the contract to the sender
   * account.
   */ 
  function Authorizable() public {
	authorized[msg.sender] = true;
  }

  /**
   * @dev Throws if called by any account other than the authorized.
   */
  modifier onlyAuthorized() {
    require(authorized[msg.sender]);
    _;
  }

 /**
   * @dev Allows the current owner to set an authorization.
   * @param addressAuthorized The address to change authorization.
   */
  function setAuthorized(address addressAuthorized, bool authorization) onlyOwner public {
    AuthorizationSet(addressAuthorized, authorization);
    authorized[addressAuthorized] = authorization;
  }
  
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token from an address to another specified address 
  * @param _sender The address to transfer from.
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transferFunction(address _sender, address _to, uint256 _value) internal returns (bool) {
    require(_to != address(0));
    require(_to != address(this));
    require(_value <= balances[_sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[_sender] = balances[_sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_sender, _to, _value);
    return true;
  }
  
  /**
  * @dev transfer token for a specified address (BasicToken transfer method)
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
	return transferFunction(msg.sender, _to, _value);
  }
  
  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}

contract ERC223TokenCompatible is BasicToken {
  using SafeMath for uint256;
  
  event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);

  // Function that is called when a user or another contract wants to transfer funds .
	function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public returns (bool success) {
		require(_to != address(0));
        require(_to != address(this));
		require(_value <= balances[msg.sender]);
		// SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
		if( isContract(_to) ) {
			_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data);
		} 
		Transfer(msg.sender, _to, _value, _data);
		return true;
	}

	// Function that is called when a user or another contract wants to transfer funds .
	function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {
		return transfer( _to, _value, _data, "tokenFallback(address,uint256,bytes)");
	}

	//assemble the given address bytecode. If bytecode exists then the _addr is a contract.
	function isContract(address _addr) private view returns (bool is_contract) {
		uint256 length;
		assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
		}
		return (length>0);
    }
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_to != address(this));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title Startable
 * @dev Base contract which allows owner to implement an start mechanism without ever being stopped more.
 */
contract Startable is Ownable, Authorizable {
  event Start();

  bool public started = false;

  /**
   * @dev Modifier to make a function callable only when the contract is started.
   */
  modifier whenStarted() {
	require( started || authorized[msg.sender] );
    _;
  }

  /**
   * @dev called by the owner to start, go to normal state
   */
  function start() onlyOwner public {
    started = true;
    Start();
  }
}

/**
 * @title Startable token
 *
 * @dev StandardToken modified with startable transfers.
 **/

contract StartToken is Startable, ERC223TokenCompatible, StandardToken {

  function transfer(address _to, uint256 _value) public whenStarted returns (bool) {
    return super.transfer(_to, _value);
  }
  function transfer(address _to, uint256 _value, bytes _data) public whenStarted returns (bool) {
    return super.transfer(_to, _value, _data);
  }
  function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public whenStarted returns (bool) {
    return super.transfer(_to, _value, _data, _custom_fallback);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenStarted returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenStarted returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenStarted returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenStarted returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract HumanStandardToken is StandardToken, StartToken {
    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        approve(_spender, _value);
        require(_spender.call(bytes4(keccak256("receiveApproval(address,uint256,bytes)")), msg.sender, _value, _extraData));
        return true;
    }
}

contract BurnToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Function to burn tokens.
     * @param _burner The address of token holder.
     * @param _value The amount of token to be burned.
     */
    function burnFunction(address _burner, uint256 _value) internal returns (bool) {
        require(_value > 0);
		require(_value <= balances[_burner]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_burner] = balances[_burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(_burner, _value);
		return true;
    }
    
    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
	function burn(uint256 _value) public returns(bool) {
        return burnFunction(msg.sender, _value);
    }
	
	/**
	* @dev Burns tokens from one address
	* @param _from address The address which you want to burn tokens from
	* @param _value uint256 the amount of tokens to be burned
	*/
	function burnFrom(address _from, uint256 _value) public returns (bool) {
		require(_value <= allowed[_from][msg.sender]); // check if it has the budget allowed
		burnFunction(_from, _value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		return true;
	}
}

contract OriginToken is Authorizable, BasicToken, BurnToken {
    
    /**
     * @dev transfer token from tx.orgin to a specified address (onlyAuthorized contract)
     */ 
    function originTransfer(address _to, uint256 _value) onlyAuthorized public returns (bool) {
	    return transferFunction(tx.origin, _to, _value);
    }
    
    /**
     * @dev Burns a specific amount of tokens from tx.orgin. (onlyAuthorized contract)
     * @param _value The amount of token to be burned.
     */	
	function originBurn(uint256 _value) onlyAuthorized public returns(bool) {
        return burnFunction(tx.origin, _value);
    }
}

contract Token is ERC223TokenCompatible, StandardToken, StartToken, HumanStandardToken, BurnToken, OriginToken {
    uint8 public decimals = 18;

    string public name = "CryptoForecast";

    string public symbol = "CFT";

    uint256 public initialSupply;

    function Token() public {
        totalSupply = 25000000 * 10 ** uint(decimals);  
        
        initialSupply = totalSupply;
        
        balances[msg.sender] = totalSupply;
    }
}