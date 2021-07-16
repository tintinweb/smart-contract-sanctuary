//SourceUnit: CarbonDollar.sol

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions". This adds two-phase
 * ownership control to OpenZeppelin's Ownable class. In this model, the original owner 
 * designates a new owner but does not actually transfer ownership. The new owner then accepts 
 * ownership and completes the transfer.
 */
contract Ownable {
  address public owner;
  address public pendingOwner;


  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
    pendingOwner = address(0);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    pendingOwner = _newOwner;
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
* @title Balances
* @notice Stores token account balances, allowances, and overall token supply
*/
contract Balances is Ownable {
    using SafeMath for uint256;

    /**
        Storage
    */
    mapping (address => mapping (address => uint256)) public allowances;
    mapping (address => uint256) public balances;
    uint256 public totalSupply;

    function addAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowances[_tokenHolder][_spender] = allowances[_tokenHolder][_spender].add(_value);
    }

    function subAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowances[_tokenHolder][_spender] = allowances[_tokenHolder][_spender].sub(_value);
    }

    function setAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowances[_tokenHolder][_spender] = _value;
    }

    function addBalance(address _addr, uint256 _value) public onlyOwner {
        balances[_addr] = balances[_addr].add(_value);
    }

    function subBalance(address _addr, uint256 _value) public onlyOwner {
        balances[_addr] = balances[_addr].sub(_value);
    }

    function setBalance(address _addr, uint256 _value) public onlyOwner {
        balances[_addr] = _value;
    }

    function addTotalSupply(uint256 _value) public onlyOwner {
        totalSupply = totalSupply.add(_value);
    }

    function subTotalSupply(uint256 _value) public onlyOwner {
        totalSupply = totalSupply.sub(_value);
    }

    function setTotalSupply(uint256 _value) public onlyOwner {
        totalSupply = _value;
    }

}

/**
*
* @dev Stores list of blacklisted users whose assets are frozen.
*
*/
contract Blacklist is Ownable {
    /** 
        Storage 
    */

    /* list of blacklisted users */
    mapping (address => bool) public blacklisted;

    /** 
        Events 
    */
    event SetBlacklistStatus(address indexed user, bool blacklisted);

    /**
    * @notice set a user's blacklisted status
    * @param _user Address of user
    * @param _blacklisted True to blacklist user, False to remove from blacklist
    */
    function setBlacklistStatus(address _user, bool _blacklisted) public onlyOwner {
        blacklisted[_user] = _blacklisted;
        emit SetBlacklistStatus(_user, _blacklisted);
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
* @title Lockable
* @dev Base contract which allows children to lock certain methods from being called by clients.
* Locked methods are deemed unsafe by default, but must be implemented in children functionality to adhere by
* some inherited standard, for example. 
*/

contract Lockable is Ownable {

	// Events
	event Unlocked();
	event Locked();

	// Fields
	bool public isMethodEnabled = false;

	// Modifiers
	/**
	* @dev Modifier that disables functions by default unless they are explicitly enabled
	*/
	modifier whenUnlocked() {
		require(isMethodEnabled);
		_;
	}

	// Methods
	/**
	* @dev called by the owner to enable method
	*/
	function unlock() onlyOwner public {
		isMethodEnabled = true;
		emit Unlocked();
	}

	/**
	* @dev called by the owner to disable method, back to normal state
	*/
	function lock() onlyOwner public {
		isMethodEnabled = false;
		emit Locked();
	}

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism. Identical to OpenZeppelin version
 * except that it uses local Ownable contract
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

/**
* @title Carbon Dollar
* @notice A simple mintable and burnable erc20
*/
contract CarbonDollar is ERC20, Pausable, Lockable {
    using SafeMath for uint256;

    /** Events */
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    Balances public balances;
    Blacklist public blacklist;

    /**
    * @dev create a new CarbonDollar with new storage contracts
    **/
    constructor () public {
        balances = new Balances();
        blacklist = new Blacklist();
    }

    /** 
        ERC20 Metadata
    */
    string public constant name = "TRXD";
    string public constant symbol = "TRXD";
    uint8 public constant decimals = 18;

    /** Modifiers **/

    /** @notice Checks whether a user's blacklisted status
     * @param _user The address of the user
     * @return True if not blacklisted, False if blacklisted
    **/
    modifier userNotBlacklisted(address _user) {
        require(!blacklist.blacklisted(_user), "User's assets are temporarily frozen");
        _;
    }

    /** Functions **/

    /**
    * @notice Allows user to mint if they have the appropriate permissions
    * @param _to The address of the receiver
    * @param _amount The number of tokens to mint
    */
    function mint(address _to, uint256 _amount) public userNotBlacklisted(_to) onlyOwner whenNotPaused {
        _mint(_to, _amount);
    }

    /**
    * @notice Remove CUSD from supply
    * @param _amount The number of tokens to burn
    * @return `true` if successful and `false` if unsuccessful
    */
    function burn(uint256 _amount) public userNotBlacklisted(msg.sender) whenNotPaused {
        _burn(msg.sender, _amount);
    }

    /**
    * @notice Implements ERC-20 standard approve function. Locked or disabled by default to protect against
    * double spend attacks. To modify allowances, clients should call safer increase/decreaseApproval methods.
    * Upon construction, all calls to approve() will revert unless this contract owner explicitly unlocks approve()
    */
    function approve(address _spender, uint256 _value) 
    public userNotBlacklisted(_spender) userNotBlacklisted(msg.sender) whenNotPaused whenUnlocked returns (bool) {
        balances.setAllowance(msg.sender, _spender, _value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * @notice increaseApproval should be used instead of approve when the user's allowance
     * is greater than 0. Using increaseApproval protects against potential double-spend attacks
     * by moving the check of whether the user has spent their allowance to the time that the transaction 
     * is mined, removing the user's ability to double-spend
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint256 _addedValue) 
    public userNotBlacklisted(_spender) userNotBlacklisted(msg.sender) whenNotPaused returns (bool) {
        _increaseApproval(_spender, _addedValue, msg.sender);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * @notice decreaseApproval should be used instead of approve when the user's allowance
     * is greater than 0. Using decreaseApproval protects against potential double-spend attacks
     * by moving the check of whether the user has spent their allowance to the time that the transaction 
     * is mined, removing the user's ability to double-spend
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint256 _subtractedValue) 
    public userNotBlacklisted(_spender) userNotBlacklisted(msg.sender) whenNotPaused returns (bool) {
        _decreaseApproval(_spender, _subtractedValue, msg.sender);
        return true;
    }

    /**
    * @notice Initiates a "send" operation towards another user. See `transferFrom` for details.
    * @param _to The address of the receiver. This user must not be blacklisted
    * @param _amount The number of tokens to transfer
    *
    * @return `true` if successful 
    */
    function transfer(address _to, uint256 _amount) public userNotBlacklisted(_to) userNotBlacklisted(msg.sender) whenNotPaused returns (bool) {
        _transfer(_to, msg.sender, _amount);
        return true;
    }

    /**
    * @notice Initiates a transfer operation between address `_from` and `_to`. Requires that the
    * message sender is an approved spender on the _from account.
    * @dev When implemented, it should use the transferFromConditionsRequired() modifier.
    * @param _to The address of the recipient. This address must not be blacklisted.
    * @param _from The address of the origin of funds. This address _could_ be blacklisted, because
    * a regulator may want to transfer tokens out of a blacklisted account, for example.
    * In order to do so, the regulator would have to add themselves as an approved spender
    * on the account via `addBlacklistAddressSpender()`, and would then be able to transfer tokens out of it.
    * @param _amount The number of tokens to transfer
    * @return `true` if successful 
    */
    function transferFrom(address _from, address _to, uint256 _amount) 
    public userNotBlacklisted(_to) userNotBlacklisted(_from) userNotBlacklisted(msg.sender) whenNotPaused returns (bool) {
        require(_amount <= allowance(_from, msg.sender),"not enough allowance to transfer");
        _transfer(_to, _from, _amount);
        balances.subAllowance(_from, msg.sender, _amount);
        return true;
    }

    function setBlacklistStatus(address _user, bool _blacklisted) public onlyOwner {
        blacklist.setBlacklistStatus(_user, _blacklisted);
    }

    /**
    * ERC20 standard functions
    */
    function allowance(address owner, address spender) public view returns (uint256) {
        return balances.allowances(owner, spender);
    }

    function totalSupply() public view returns (uint256) {
        return balances.totalSupply();
    }

    function balanceOf(address _addr) public view returns (uint256) {
        return balances.balances(_addr);
    }


    /** Internal functions **/
    
    function _decreaseApproval(address _spender, uint256 _subtractedValue, address _tokenHolder) internal {
        uint256 oldValue = allowance(_tokenHolder, _spender);
        if (_subtractedValue > oldValue) {
            balances.setAllowance(_tokenHolder, _spender, 0);
        } else {
            balances.subAllowance(_tokenHolder, _spender, _subtractedValue);
        }
        emit Approval(_tokenHolder, _spender, allowance(_tokenHolder, _spender));
    }

    function _increaseApproval(address _spender, uint256 _addedValue, address _tokenHolder) internal {
        balances.addAllowance(_tokenHolder, _spender, _addedValue);
        emit Approval(_tokenHolder, _spender, allowance(_tokenHolder, _spender));
    }

    function _burn(address _tokensOf, uint256 _amount) internal {
        require(_tokensOf != address(0),"burner address cannot be 0x0");
        require(_amount <= balanceOf(_tokensOf),"not enough balance to burn");
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure
        balances.subBalance(_tokensOf, _amount);
        balances.subTotalSupply(_amount);
        emit Burn(_tokensOf, _amount);
        emit Transfer(_tokensOf, address(0), _amount);
    }

    function _mint(address _to, uint256 _amount) internal {
        require(_to != address(0),"to address cannot be 0x0");
        balances.addTotalSupply(_amount);
        balances.addBalance(_to, _amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    function _transfer(address _to, address _from, uint256 _amount) internal {
        require(_to != address(0),"to address cannot be 0x0");
        require(_amount <= balanceOf(_from),"not enough balance to transfer");

        balances.addBalance(_to, _amount);
        balances.subBalance(_from, _amount);
        emit Transfer(_from, _to, _amount);
    }

}