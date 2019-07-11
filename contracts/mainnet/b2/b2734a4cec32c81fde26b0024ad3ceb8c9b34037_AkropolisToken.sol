/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity >=0.4.24;
/* @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
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
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
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

// File: contracts/helpers/Ownable.sol




/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions". This adds two-phase
 * ownership control to OpenZeppelin&#39;s Ownable class. In this model, the original owner 
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
        require(msg.sender == owner, "Account is not owner");
        _;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "Account is not pending owner");
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Empty address");
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

// File: contracts/token/dataStorage/AllowanceSheet.sol





/**
* @title AllowanceSheet
* @notice A wrapper around an allowance mapping. 
*/
contract AllowanceSheet is Ownable {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) public allowanceOf;

    function addAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].add(_value);
    }

    function subAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].sub(_value);
    }

    function setAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = _value;
    }
}

// File: contracts/token/dataStorage/BalanceSheet.sol





/**
* @title BalanceSheet
* @notice A wrapper around the balanceOf mapping. 
*/
contract BalanceSheet is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) public balanceOf;
    uint256 public totalSupply;

    function addBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = balanceOf[_addr].add(_value);
    }

    function subBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = balanceOf[_addr].sub(_value);
    }

    function setBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = _value;
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

// File: contracts/token/dataStorage/TokenStorage.sol





/**
* @title TokenStorage
*/
contract TokenStorage {
    /**
        Storage
    */
    BalanceSheet public balances;
    AllowanceSheet public allowances;


    string public name;   //name of Token                
    uint8  public decimals;        //decimals of Token        
    string public symbol;   //Symbol of Token

    /**
    * @dev a TokenStorage consumer can set its storages only once, on construction
    *
    **/
    constructor (address _balances, address _allowances, string _name, uint8 _decimals, string _symbol) public {
        balances = BalanceSheet(_balances);
        allowances = AllowanceSheet(_allowances);

        name = _name;
        decimals = _decimals;
        symbol = _symbol;
    }

    /**
    * @dev claim ownership of balance sheet passed into constructor.
    **/
    function claimBalanceOwnership() public {
        balances.claimOwnership();
    }

    /**
    * @dev claim ownership of allowance sheet passed into constructor.
    **/
    function claimAllowanceOwnership() public {
        allowances.claimOwnership();
    }
}

// File: openzeppelin-solidity/contracts/AddressUtils.sol

pragma solidity ^0.4.24;


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param _addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

pragma solidity ^0.4.24;


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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;



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

// File: contracts/token/AkropolisBaseToken.sol








/**
* @title AkropolisBaseToken
* @notice A basic ERC20 token with modular data storage
*/
contract AkropolisBaseToken is ERC20, TokenStorage, Ownable {
    using SafeMath for uint256;

    /** Events */
    event Mint(address indexed to, uint256 value);
    event MintFinished();
    event Burn(address indexed burner, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    constructor (address _balances, address _allowances, string _name, uint8 _decimals, string _symbol) public 
    TokenStorage(_balances, _allowances, _name, _decimals, _symbol) {}

    /** Modifiers **/

    modifier canMint() {
        require(!isMintingFinished());
        _;
    }

    /** Functions **/

    function mint(address _to, uint256 _amount) public onlyOwner canMint {
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) public onlyOwner {
        _burn(msg.sender, _amount);
    }


    function isMintingFinished() public view returns (bool) {
        bytes32 slot = keccak256(abi.encode("Minting", "mint"));
        uint256 v;
        assembly {
            v := sload(slot)
        }
        return v != 0;
    }


    function setMintingFinished(bool value) internal {
        bytes32 slot = keccak256(abi.encode("Minting", "mint"));
        uint256 v = value ? 1 : 0;
        assembly {
            sstore(slot, v)
        }
    }

    function mintFinished() public onlyOwner {
        setMintingFinished(true);
        emit MintFinished();
    }


    function approve(address _spender, uint256 _value) 
    public returns (bool) {
        allowances.setAllowance(msg.sender, _spender, _value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(_to != address(0),"to address cannot be 0x0");
        require(_amount <= balanceOf(msg.sender),"not enough balance to transfer");

        balances.subBalance(msg.sender, _amount);
        balances.addBalance(_to, _amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) 
    public returns (bool) {
        require(_amount <= allowance(_from, msg.sender),"not enough allowance to transfer");
        require(_to != address(0),"to address cannot be 0x0");
        require(_amount <= balanceOf(_from),"not enough balance to transfer");
        
        allowances.subAllowance(_from, msg.sender, _amount);
        balances.addBalance(_to, _amount);
        balances.subBalance(_from, _amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    /**
    * @notice Implements balanceOf() as specified in the ERC20 standard.
    */
    function balanceOf(address who) public view returns (uint256) {
        return balances.balanceOf(who);
    }

    /**
    * @notice Implements allowance() as specified in the ERC20 standard.
    */
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances.allowanceOf(owner, spender);
    }

    /**
    * @notice Implements totalSupply() as specified in the ERC20 standard.
    */
    function totalSupply() public view returns (uint256) {
        return balances.totalSupply();
    }


    /** Internal functions **/

    function _burn(address _tokensOf, uint256 _amount) internal {
        require(_amount <= balanceOf(_tokensOf),"not enough balance to burn");
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure
        balances.subBalance(_tokensOf, _amount);
        balances.subTotalSupply(_amount);
        emit Burn(_tokensOf, _amount);
        emit Transfer(_tokensOf, address(0), _amount);
    }

    function _mint(address _to, uint256 _amount) internal {
        balances.addTotalSupply(_amount);
        balances.addBalance(_to, _amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

}

// File: contracts/helpers/Lockable.sol




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

	// Modifiers
	/**
	* @dev Modifier that disables functions by default unless they are explicitly enabled
	*/
	modifier whenUnlocked() {
		require(!isLocked(), "Contact is locked");
		_;
	}

	/**
	* @dev called by the owner to disable method, back to normal state
	*/
	function lock() public  onlyOwner {
		setLock(true);
		emit Locked();
	}

	// Methods
	/**
	* @dev called by the owner to enable method
	*/
	function unlock() public onlyOwner  {
		setLock(false);
		emit Unlocked();
	}

	function setLock(bool value) internal {
        bytes32 slot = keccak256(abi.encode("Lockable", "lock"));
        uint256 v = value ? 1 : 0;
        assembly {
            sstore(slot, v)
        }
    }

    function isLocked() public view returns (bool) {
        bytes32 slot = keccak256(abi.encode("Lockable", "lock"));
        uint256 v;
        assembly {
            v := sload(slot)
        }
        return v != 0;
    }

}

// File: contracts/helpers/Pausable.sol





/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism. Identical to OpenZeppelin version
 * except that it uses local Ownable contract
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!isPaused(), "Contract is paused");
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(isPaused(), "Contract is not paused");
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() public onlyOwner  whenNotPaused  {
        setPause(true);
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() public onlyOwner  whenPaused {
        setPause(false);
        emit Unpause();
    }

    function setPause(bool value) internal {
        bytes32 slot = keccak256(abi.encode("Pausable", "pause"));
        uint256 v = value ? 1 : 0;
        assembly {
            sstore(slot, v)
        }
    }

    function isPaused() public view returns (bool) {
        bytes32 slot = keccak256(abi.encode("Pausable", "pause"));
        uint256 v;
        assembly {
            v := sload(slot)
        }
        return v != 0;
    }
}

// File: contracts/helpers/Whitelist.sol



/**
 * @title Whitelist
 * @dev Base contract which allows children to implement an emergency whitelist mechanism. Identical to OpenZeppelin version
 * except that it uses local Ownable contract
 */
 
contract Whitelist is Ownable {
    event AddToWhitelist(address indexed to);
    event RemoveFromWhitelist(address indexed to);
    event EnableWhitelist();
    event DisableWhitelist();
    event AddPermBalanceToWhitelist(address indexed to, uint256 balance);
    event RemovePermBalanceToWhitelist(address indexed to);

    mapping(address => bool) internal whitelist;
    mapping (address => uint256) internal permBalancesForWhitelist;

    /**
    * @dev Modifier to make a function callable only when msg.sender is in whitelist.
    */
    modifier onlyWhitelist() {
        if (isWhitelisted() == true) {
            require(whitelist[msg.sender] == true, "Address is not in whitelist");
        }
        _;
    }

    /**
    * @dev Modifier to make a function callable only when msg.sender is in permitted balance
    */
    modifier checkPermBalanceForWhitelist(uint256 value) {
        if (isWhitelisted() == true) {
            require(permBalancesForWhitelist[msg.sender]==0 || permBalancesForWhitelist[msg.sender]>=value, "Not permitted balance for transfer");
        }
        
        _;
    }

    /**
    * @dev called by the owner to set permitted balance for transfer
    */

    function addPermBalanceToWhitelist(address _owner, uint256 _balance) public onlyOwner {
        permBalancesForWhitelist[_owner] = _balance;
        emit AddPermBalanceToWhitelist(_owner, _balance);
    }

    /**
    * @dev called by the owner to remove permitted balance for transfer
    */
    function removePermBalanceToWhitelist(address _owner) public onlyOwner {
        permBalancesForWhitelist[_owner] = 0;
        emit RemovePermBalanceToWhitelist(_owner);
    }
   
    /**
    * @dev called by the owner to enable whitelist
    */

    function enableWhitelist() public onlyOwner {
        setWhitelisted(true);
        emit EnableWhitelist();
    }


    /**
    * @dev called by the owner to disable whitelist
    */
    function disableWhitelist() public onlyOwner {
        setWhitelisted(false);
        emit DisableWhitelist();
    }

    /**
    * @dev called by the owner to enable some address for whitelist
    */
    function addToWhitelist(address _address) public onlyOwner  {
        whitelist[_address] = true;
        emit AddToWhitelist(_address);
    }

    /**
    * @dev called by the owner to disable address for whitelist
    */
    function removeFromWhitelist(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemoveFromWhitelist(_address);
    }


    // bool public whitelisted = false;

    function setWhitelisted(bool value) internal {
        bytes32 slot = keccak256(abi.encode("Whitelist", "whitelisted"));
        uint256 v = value ? 1 : 0;
        assembly {
            sstore(slot, v)
        }
    }

    function isWhitelisted() public view returns (bool) {
        bytes32 slot = keccak256(abi.encode("Whitelist", "whitelisted"));
        uint256 v;
        assembly {
            v := sload(slot)
        }
        return v != 0;
    }
}

// File: contracts/token/AkropolisToken.sol








/**
* @title AkropolisToken
* @notice Adds pausability and disables approve() to defend against double-spend attacks in addition
* to inherited AkropolisBaseToken behavior
*/
contract AkropolisToken is AkropolisBaseToken, Pausable, Lockable, Whitelist {
    using SafeMath for uint256;

    /** Events */

    constructor (address _balances, address _allowances, string _name, uint8 _decimals, string _symbol) public 
    AkropolisBaseToken(_balances, _allowances, _name, _decimals, _symbol) {}

    /** Modifiers **/

    /** Functions **/

    function mint(address _to, uint256 _amount) public {
        super.mint(_to, _amount);
    }

    function burn(uint256 _amount) public whenUnlocked  {
        super.burn(_amount);
    }

    /**
    * @notice Implements ERC-20 standard approve function.
    * double spend attacks. To modify allowances, clients should call safer increase/decreaseApproval methods.
    * Upon construction, all calls to approve() will revert unless this contract owner explicitly unlocks approve()
    */
    function approve(address _spender, uint256 _value) 
    public whenNotPaused  whenUnlocked returns (bool) {
        return super.approve(_spender, _value);
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * @notice increaseApproval should be used instead of approve when the user&#39;s allowance
     * is greater than 0. Using increaseApproval protects against potential double-spend attacks
     * by moving the check of whether the user has spent their allowance to the time that the transaction 
     * is mined, removing the user&#39;s ability to double-spend
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint256 _addedValue) 
    public whenNotPaused returns (bool) {
        increaseApprovalAllArgs(_spender, _addedValue, msg.sender);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * @notice decreaseApproval should be used instead of approve when the user&#39;s allowance
     * is greater than 0. Using decreaseApproval protects against potential double-spend attacks
     * by moving the check of whether the user has spent their allowance to the time that the transaction 
     * is mined, removing the user&#39;s ability to double-spend
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint256 _subtractedValue) 
    public whenNotPaused returns (bool) {
        decreaseApprovalAllArgs(_spender, _subtractedValue, msg.sender);
        return true;
    }

    function transfer(address _to, uint256 _amount) public whenNotPaused onlyWhitelist checkPermBalanceForWhitelist(_amount) returns (bool) {
        return super.transfer(_to, _amount);
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
    public whenNotPaused onlyWhitelist checkPermBalanceForWhitelist(_amount) returns (bool) {
        return super.transferFrom(_from, _to, _amount);
    }


    /** Internal functions **/
    
    function decreaseApprovalAllArgs(address _spender, uint256 _subtractedValue, address _tokenHolder) internal {
        uint256 oldValue = allowances.allowanceOf(_tokenHolder, _spender);
        if (_subtractedValue > oldValue) {
            allowances.setAllowance(_tokenHolder, _spender, 0);
        } else {
            allowances.subAllowance(_tokenHolder, _spender, _subtractedValue);
        }
        emit Approval(_tokenHolder, _spender, allowances.allowanceOf(_tokenHolder, _spender));
    }

    function increaseApprovalAllArgs(address _spender, uint256 _addedValue, address _tokenHolder) internal {
        allowances.addAllowance(_tokenHolder, _spender, _addedValue);
        emit Approval(_tokenHolder, _spender, allowances.allowanceOf(_tokenHolder, _spender));
    }
}