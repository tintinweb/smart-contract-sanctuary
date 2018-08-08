pragma solidity 0.4.23;

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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
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

  uint256 totalSupply_;

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
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
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
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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
  constructor() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


contract PausableToken is StandardToken, BurnableToken, Claimable, Pausable {
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    	return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    	return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    	return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
      return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
      return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract LockableToken is PausableToken {
	using SafeMath for uint256;

	event Lock(address indexed owner, uint256 orderId, uint256 amount, uint256 releaseTimestamp);
	event UnLock(address indexed owner, uint256 orderId, uint256 amount);

	struct LockRecord {
	    
	    ///@dev order id
	    uint256 orderId;

	    ///@dev lock amount
	    uint256 amount;

	    ///@dev unlock timestamp
	    uint256 releaseTimestamp;
	}
	
	mapping (address => LockRecord[]) ownedLockRecords;
	mapping (address => uint256) ownedLockAmount;


	/**
	* @dev Lock token until _timeSpan second.
	* @param _orderId uint256
	* @param _amount uint256
	*/
	function lockTokenForNode(uint256 _orderId, uint256 _amount, uint256 _timeSpan) public whenNotPaused {
		require(balances[msg.sender] >= _amount);
		require(_timeSpan > 0 && _timeSpan <= 3 * 365 days);
	    
		uint256 releaseTimestamp = now + _timeSpan;

	 	_lockToken(_orderId, _amount, releaseTimestamp);
	}


	function unlockToken() public whenNotPaused {
		LockRecord[] memory list = ownedLockRecords[msg.sender];
    require(list.length > 0);
		for(uint i = list.length - 1; i >= 0; i--) {
			// If a record can be release.
			if (now >= list[i].releaseTimestamp) {
				_unlockTokenByIndex(i);
			}
			/// @dev i is a type of uint , so it must be break when i == 0.
			if (i == 0) {
				break;
			}
		}
	}

	/**
	* @param _index uint256 Lock record idnex.
	* @return Return a lock record (lock amount, releaseTimestamp)
	*/
	function getLockByIndex(uint256 _index) public view returns(uint256, uint256, uint256) {
        LockRecord memory record = ownedLockRecords[msg.sender][_index];
        
        return (record.orderId, record.amount, record.releaseTimestamp);
    }

  function getLockAmount() public view returns(uint256) {
  	LockRecord[] memory list = ownedLockRecords[msg.sender];
  	uint sum = 0;
  	for (uint i = 0; i < list.length; i++) {
  		sum += list[i].amount;
  	}

  	return sum;
  }

  /**
  * @dev Get lock records count
  */
  function getLockRecordCount() view public returns(uint256) {
    return ownedLockRecords[msg.sender].length;
  }

	/**
	* @param _amount uint256 Lock amount.
	* @param _releaseTimestamp uint256 Unlock timestamp.
	*/
	function _lockToken(uint256 _orderId, uint256 _amount, uint256 _releaseTimestamp) internal {
		require(ownedLockRecords[msg.sender].length <= 20);
    
    balances[msg.sender] = balances[msg.sender].sub(_amount);

		///@dev We don&#39;t care the orderId already exist or not. 
		/// Because the web server will detect it.
		ownedLockRecords[msg.sender].push( LockRecord(_orderId, _amount, _releaseTimestamp) );
		ownedLockAmount[msg.sender] = ownedLockAmount[msg.sender].add(_amount);

		emit Lock(msg.sender, _orderId, _amount, _releaseTimestamp);
	}

	/**
	* @dev using by internal.
	*/
	function _unlockTokenByIndex(uint256 _index) internal {
		LockRecord memory record = ownedLockRecords[msg.sender][_index];
		uint length = ownedLockRecords[msg.sender].length;

		ownedLockRecords[msg.sender][_index] = ownedLockRecords[msg.sender][length - 1];
		delete ownedLockRecords[msg.sender][length - 1];
		ownedLockRecords[msg.sender].length--;

		ownedLockAmount[msg.sender] = ownedLockAmount[msg.sender].sub(record.amount);
		balances[msg.sender] = balances[msg.sender].add(record.amount);

		emit UnLock(msg.sender, record.orderId, record.amount);
	}

}

contract TuzyPayableToken is LockableToken {
	
	event Pay(address indexed owner, uint256 orderId, uint256 amount, uint256 burnAmount);

	address public cooAddress;

	/// @dev User pay action will consume a certain amount of token.
	//uint256 public payAmount;

	/// @dev User pay action will brun a certain amount of token their owned.
	//uint256 public payBrunAmount;


	/**
	* @dev The TuzyPayableToken constructor sets the original `cooAddress` of the contract to the sender
	* account.
	*/
	constructor() public {
		cooAddress = msg.sender;
	}
	
/// @dev Assigns a new address to act as the COO.
  /// @param _newCOO The address of the new COO.
  function setCOO(address _newCOO) external onlyOwner {
      require(_newCOO != address(0));
      
      cooAddress = _newCOO;
  }

  /**
  * @dev Pay for order
  *
  */ 
  function payOrder(uint256 _orderId, uint256 _amount, uint256 _burnAmount) external whenNotPaused {
  	require(balances[msg.sender] >= _amount);
  	
  	/// @dev _burnAmount must be less then _amount, the code can be executed to the next line.
  	uint256 fee = _amount.sub(_burnAmount);
  	if (fee > 0) {
  		transfer(cooAddress, fee);
  	}
  	burn(_burnAmount);
  	emit Pay(msg.sender, _orderId, _amount, _burnAmount);
  }
}

contract TuzyCoin is TuzyPayableToken {
	string public name    = "Tuzy Coin";
	string public symbol  = "TUC";
	uint8 public decimals = 8;

	// 1.6 billion in initial supply
	uint256 public constant INITIAL_SUPPLY = 1600000000;

	constructor() public {
		totalSupply_ = INITIAL_SUPPLY * (10 ** uint256(decimals));
		balances[msg.sender] = totalSupply_;
	}

  function globalBurnAmount() public view returns(uint256) {
    return INITIAL_SUPPLY * (10 ** uint256(decimals)) - totalSupply_;
  }

}