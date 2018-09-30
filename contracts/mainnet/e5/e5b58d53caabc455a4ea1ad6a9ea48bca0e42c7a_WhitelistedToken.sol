pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

/**
* @title PermissionedTokenStorage
* @notice a PermissionedTokenStorage is constructed by setting Regulator, BalanceSheet, and AllowanceSheet locations.
* Once the storages are set, they cannot be changed.
*/
contract PermissionedTokenStorage is Ownable {
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
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
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
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
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
*
* @dev Stores permissions and validators and provides setter and getter methods. 
* Permissions determine which methods users have access to call. Validators
* are able to mutate permissions at the Regulator level.
*
*/
contract RegulatorStorage is Ownable {
    
    /** 
        Structs 
    */

    /* Contains metadata about a permission to execute a particular method signature. */
    struct Permission {
        string name; // A one-word description for the permission. e.g. "canMint"
        string description; // A longer description for the permission. e.g. "Allows user to mint tokens."
        string contract_name; // e.g. "PermissionedToken"
        bool active; // Permissions can be turned on or off by regulator
    }

    /** 
        Constants: stores method signatures. These are potential permissions that a user can have, 
        and each permission gives the user the ability to call the associated PermissionedToken method signature
    */
    bytes4 public constant MINT_SIG = bytes4(keccak256("mint(address,uint256)"));
    bytes4 public constant MINT_CUSD_SIG = bytes4(keccak256("mintCUSD(address,uint256)"));
    bytes4 public constant CONVERT_WT_SIG = bytes4(keccak256("convertWT(uint256)"));
    bytes4 public constant BURN_SIG = bytes4(keccak256("burn(uint256)"));
    bytes4 public constant CONVERT_CARBON_DOLLAR_SIG = bytes4(keccak256("convertCarbonDollar(address,uint256)"));
    bytes4 public constant BURN_CARBON_DOLLAR_SIG = bytes4(keccak256("burnCarbonDollar(address,uint256)"));
    bytes4 public constant DESTROY_BLACKLISTED_TOKENS_SIG = bytes4(keccak256("destroyBlacklistedTokens(address,uint256)"));
    bytes4 public constant APPROVE_BLACKLISTED_ADDRESS_SPENDER_SIG = bytes4(keccak256("approveBlacklistedAddressSpender(address)"));
    bytes4 public constant BLACKLISTED_SIG = bytes4(keccak256("blacklisted()"));

    /** 
        Mappings 
    */

    /* each method signature maps to a Permission */
    mapping (bytes4 => Permission) public permissions;
    /* list of validators, either active or inactive */
    mapping (address => bool) public validators;
    /* each user can be given access to a given method signature */
    mapping (address => mapping (bytes4 => bool)) public userPermissions;

    /** 
        Events 
    */
    event PermissionAdded(bytes4 methodsignature);
    event PermissionRemoved(bytes4 methodsignature);
    event ValidatorAdded(address indexed validator);
    event ValidatorRemoved(address indexed validator);

    /** 
        Modifiers 
    */
    /**
    * @notice Throws if called by any account that does not have access to set attributes
    */
    modifier onlyValidator() {
        require (isValidator(msg.sender), "Sender must be validator");
        _;
    }

    /**
    * @notice Sets a permission within the list of permissions.
    * @param _methodsignature Signature of the method that this permission controls.
    * @param _permissionName A "slug" name for this permission (e.g. "canMint").
    * @param _permissionDescription A lengthier description for this permission (e.g. "Allows user to mint tokens").
    * @param _contractName Name of the contract that the method belongs to.
    */
    function addPermission(
        bytes4 _methodsignature, 
        string _permissionName, 
        string _permissionDescription, 
        string _contractName) public onlyValidator { 
        Permission memory p = Permission(_permissionName, _permissionDescription, _contractName, true);
        permissions[_methodsignature] = p;
        emit PermissionAdded(_methodsignature);
    }

    /**
    * @notice Removes a permission the list of permissions.
    * @param _methodsignature Signature of the method that this permission controls.
    */
    function removePermission(bytes4 _methodsignature) public onlyValidator {
        permissions[_methodsignature].active = false;
        emit PermissionRemoved(_methodsignature);
    }
    
    /**
    * @notice Sets a permission in the list of permissions that a user has.
    * @param _methodsignature Signature of the method that this permission controls.
    */
    function setUserPermission(address _who, bytes4 _methodsignature) public onlyValidator {
        require(permissions[_methodsignature].active, "Permission being set must be for a valid method signature");
        userPermissions[_who][_methodsignature] = true;
    }

    /**
    * @notice Removes a permission from the list of permissions that a user has.
    * @param _methodsignature Signature of the method that this permission controls.
    */
    function removeUserPermission(address _who, bytes4 _methodsignature) public onlyValidator {
        require(permissions[_methodsignature].active, "Permission being removed must be for a valid method signature");
        userPermissions[_who][_methodsignature] = false;
    }

    /**
    * @notice add a Validator
    * @param _validator Address of validator to add
    */
    function addValidator(address _validator) public onlyOwner {
        validators[_validator] = true;
        emit ValidatorAdded(_validator);
    }

    /**
    * @notice remove a Validator
    * @param _validator Address of validator to remove
    */
    function removeValidator(address _validator) public onlyOwner {
        validators[_validator] = false;
        emit ValidatorRemoved(_validator);
    }

    /**
    * @notice does validator exist?
    * @return true if yes, false if no
    **/
    function isValidator(address _validator) public view returns (bool) {
        return validators[_validator];
    }

    /**
    * @notice does permission exist?
    * @return true if yes, false if no
    **/
    function isPermission(bytes4 _methodsignature) public view returns (bool) {
        return permissions[_methodsignature].active;
    }

    /**
    * @notice get Permission structure
    * @param _methodsignature request to retrieve the Permission struct for this methodsignature
    * @return Permission
    **/
    function getPermission(bytes4 _methodsignature) public view returns 
        (string name, 
         string description, 
         string contract_name,
         bool active) {
        return (permissions[_methodsignature].name,
                permissions[_methodsignature].description,
                permissions[_methodsignature].contract_name,
                permissions[_methodsignature].active);
    }

    /**
    * @notice does permission exist?
    * @return true if yes, false if no
    **/
    function hasUserPermission(address _who, bytes4 _methodsignature) public view returns (bool) {
        return userPermissions[_who][_methodsignature];
    }
}

/**
 * @title Regulator
 * @dev Regulator can be configured to meet relevant securities regulations, KYC policies
 * AML requirements, tax laws, and more. The Regulator ensures that the PermissionedToken
 * makes compliant transfers possible. Contains the userPermissions necessary
 * for regulatory compliance.
 *
 */
contract Regulator is RegulatorStorage {
    
    /** 
        Modifiers 
    */
    /**
    * @notice Throws if called by any account that does not have access to set attributes
    */
    modifier onlyValidator() {
        require (isValidator(msg.sender), "Sender must be validator");
        _;
    }

    /** 
        Events 
    */
    event LogWhitelistedUser(address indexed who);
    event LogBlacklistedUser(address indexed who);
    event LogNonlistedUser(address indexed who);
    event LogSetMinter(address indexed who);
    event LogRemovedMinter(address indexed who);
    event LogSetBlacklistDestroyer(address indexed who);
    event LogRemovedBlacklistDestroyer(address indexed who);
    event LogSetBlacklistSpender(address indexed who);
    event LogRemovedBlacklistSpender(address indexed who);

    /**
    * @notice Sets the necessary permissions for a user to mint tokens.
    * @param _who The address of the account that we are setting permissions for.
    */
    function setMinter(address _who) public onlyValidator {
        _setMinter(_who);
    }

    /**
    * @notice Removes the necessary permissions for a user to mint tokens.
    * @param _who The address of the account that we are removing permissions for.
    */
    function removeMinter(address _who) public onlyValidator {
        _removeMinter(_who);
    }

    /**
    * @notice Sets the necessary permissions for a user to spend tokens from a blacklisted account.
    * @param _who The address of the account that we are setting permissions for.
    */
    function setBlacklistSpender(address _who) public onlyValidator {
        require(isPermission(APPROVE_BLACKLISTED_ADDRESS_SPENDER_SIG), "Blacklist spending not supported by token");
        setUserPermission(_who, APPROVE_BLACKLISTED_ADDRESS_SPENDER_SIG);
        emit LogSetBlacklistSpender(_who);
    }
    
    /**
    * @notice Removes the necessary permissions for a user to spend tokens from a blacklisted account.
    * @param _who The address of the account that we are removing permissions for.
    */
    function removeBlacklistSpender(address _who) public onlyValidator {
        require(isPermission(APPROVE_BLACKLISTED_ADDRESS_SPENDER_SIG), "Blacklist spending not supported by token");
        removeUserPermission(_who, APPROVE_BLACKLISTED_ADDRESS_SPENDER_SIG);
        emit LogRemovedBlacklistSpender(_who);
    }

    /**
    * @notice Sets the necessary permissions for a user to destroy tokens from a blacklisted account.
    * @param _who The address of the account that we are setting permissions for.
    */
    function setBlacklistDestroyer(address _who) public onlyValidator {
        require(isPermission(DESTROY_BLACKLISTED_TOKENS_SIG), "Blacklist token destruction not supported by token");
        setUserPermission(_who, DESTROY_BLACKLISTED_TOKENS_SIG);
        emit LogSetBlacklistDestroyer(_who);
    }
    

    /**
    * @notice Removes the necessary permissions for a user to destroy tokens from a blacklisted account.
    * @param _who The address of the account that we are removing permissions for.
    */
    function removeBlacklistDestroyer(address _who) public onlyValidator {
        require(isPermission(DESTROY_BLACKLISTED_TOKENS_SIG), "Blacklist token destruction not supported by token");
        removeUserPermission(_who, DESTROY_BLACKLISTED_TOKENS_SIG);
        emit LogRemovedBlacklistDestroyer(_who);
    }

    /**
    * @notice Sets the necessary permissions for a "whitelisted" user.
    * @param _who The address of the account that we are setting permissions for.
    */
    function setWhitelistedUser(address _who) public onlyValidator {
        _setWhitelistedUser(_who);
    }

    /**
    * @notice Sets the necessary permissions for a "blacklisted" user. A blacklisted user has their accounts
    * frozen; they cannot transfer, burn, or withdraw any tokens.
    * @param _who The address of the account that we are setting permissions for.
    */
    function setBlacklistedUser(address _who) public onlyValidator {
        _setBlacklistedUser(_who);
    }

    /**
    * @notice Sets the necessary permissions for a "nonlisted" user. Nonlisted users can trade tokens,
    * but cannot burn them (and therefore cannot convert them into fiat.)
    * @param _who The address of the account that we are setting permissions for.
    */
    function setNonlistedUser(address _who) public onlyValidator {
        _setNonlistedUser(_who);
    }

    /** Returns whether or not a user is whitelisted.
     * @param _who The address of the account in question.
     * @return `true` if the user is whitelisted, `false` otherwise.
     */
    function isWhitelistedUser(address _who) public view returns (bool) {
        return (hasUserPermission(_who, BURN_SIG) && !hasUserPermission(_who, BLACKLISTED_SIG));
    }

    /** Returns whether or not a user is blacklisted.
     * @param _who The address of the account in question.
     * @return `true` if the user is blacklisted, `false` otherwise.
     */
    function isBlacklistedUser(address _who) public view returns (bool) {
        return (!hasUserPermission(_who, BURN_SIG) && hasUserPermission(_who, BLACKLISTED_SIG));
    }

    /** Returns whether or not a user is nonlisted.
     * @param _who The address of the account in question.
     * @return `true` if the user is nonlisted, `false` otherwise.
     */
    function isNonlistedUser(address _who) public view returns (bool) {
        return (!hasUserPermission(_who, BURN_SIG) && !hasUserPermission(_who, BLACKLISTED_SIG));
    }

    /** Returns whether or not a user is a blacklist spender.
     * @param _who The address of the account in question.
     * @return `true` if the user is a blacklist spender, `false` otherwise.
     */
    function isBlacklistSpender(address _who) public view returns (bool) {
        return hasUserPermission(_who, APPROVE_BLACKLISTED_ADDRESS_SPENDER_SIG);
    }

    /** Returns whether or not a user is a blacklist destroyer.
     * @param _who The address of the account in question.
     * @return `true` if the user is a blacklist destroyer, `false` otherwise.
     */
    function isBlacklistDestroyer(address _who) public view returns (bool) {
        return hasUserPermission(_who, DESTROY_BLACKLISTED_TOKENS_SIG);
    }

    /** Returns whether or not a user is a minter.
     * @param _who The address of the account in question.
     * @return `true` if the user is a minter, `false` otherwise.
     */
    function isMinter(address _who) public view returns (bool) {
        return hasUserPermission(_who, MINT_SIG);
    }

    /** Internal Functions **/

    function _setMinter(address _who) internal {
        require(isPermission(MINT_SIG), "Minting not supported by token");
        setUserPermission(_who, MINT_SIG);
        emit LogSetMinter(_who);
    }

    function _removeMinter(address _who) internal {
        require(isPermission(MINT_SIG), "Minting not supported by token");
        removeUserPermission(_who, MINT_SIG);
        emit LogRemovedMinter(_who);
    }

    function _setNonlistedUser(address _who) internal {
        require(isPermission(BURN_SIG), "Burn method not supported by token");
        require(isPermission(BLACKLISTED_SIG), "Self-destruct method not supported by token");
        removeUserPermission(_who, BURN_SIG);
        removeUserPermission(_who, BLACKLISTED_SIG);
        emit LogNonlistedUser(_who);
    }

    function _setBlacklistedUser(address _who) internal {
        require(isPermission(BURN_SIG), "Burn method not supported by token");
        require(isPermission(BLACKLISTED_SIG), "Self-destruct method not supported by token");
        removeUserPermission(_who, BURN_SIG);
        setUserPermission(_who, BLACKLISTED_SIG);
        emit LogBlacklistedUser(_who);
    }

    function _setWhitelistedUser(address _who) internal {
        require(isPermission(BURN_SIG), "Burn method not supported by token");
        require(isPermission(BLACKLISTED_SIG), "Self-destruct method not supported by token");
        setUserPermission(_who, BURN_SIG);
        removeUserPermission(_who, BLACKLISTED_SIG);
        emit LogWhitelistedUser(_who);
    }
}

/**
* @title PermissionedToken
* @notice A permissioned token that enables transfers, withdrawals, and deposits to occur 
* if and only if it is approved by an on-chain Regulator service. PermissionedToken is an
* ERC-20 smart contract representing ownership of securities and overrides the
* transfer, burn, and mint methods to check with the Regulator.
*/
contract PermissionedToken is ERC20, Pausable, Lockable {
    using SafeMath for uint256;

    /** Events */
    event DestroyedBlacklistedTokens(address indexed account, uint256 amount);
    event ApprovedBlacklistedAddressSpender(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ChangedRegulator(address indexed oldRegulator, address indexed newRegulator );

    PermissionedTokenStorage public tokenStorage;
    Regulator public regulator;

    /**
    * @dev create a new PermissionedToken with a brand new data storage
    **/
    constructor (address _regulator) public {
        regulator = Regulator(_regulator);
        tokenStorage = new PermissionedTokenStorage();
    }

    /** Modifiers **/

    /** @notice Modifier that allows function access to be restricted based on
    * whether the regulator allows the message sender to execute that function.
    **/
    modifier requiresPermission() {
        require (regulator.hasUserPermission(msg.sender, msg.sig), "User does not have permission to execute function");
        _;
    }

    /** @notice Modifier that checks whether or not a transferFrom operation can
    * succeed with the given _from and _to address. See transferFrom()&#39;s documentation for
    * more details.
    **/
    modifier transferFromConditionsRequired(address _from, address _to) {
        require(!regulator.isBlacklistedUser(_to), "Recipient cannot be blacklisted");
        
        // If the origin user is blacklisted, the transaction can only succeed if 
        // the message sender is a user that has been approved to transfer 
        // blacklisted tokens out of this address.
        bool is_origin_blacklisted = regulator.isBlacklistedUser(_from);

        // Is the message sender a person with the ability to transfer tokens out of a blacklisted account?
        bool sender_can_spend_from_blacklisted_address = regulator.isBlacklistSpender(msg.sender);
        require(!is_origin_blacklisted || sender_can_spend_from_blacklisted_address, "Origin cannot be blacklisted if spender is not an approved blacklist spender");
        _;
    }

    /** @notice Modifier that checks whether a user is whitelisted.
     * @param _user The address of the user to check.
    **/
    modifier userWhitelisted(address _user) {
        require(regulator.isWhitelistedUser(_user), "User must be whitelisted");
        _;
    }

    /** @notice Modifier that checks whether a user is blacklisted.
     * @param _user The address of the user to check.
    **/
    modifier userBlacklisted(address _user) {
        require(regulator.isBlacklistedUser(_user), "User must be blacklisted");
        _;
    }

    /** @notice Modifier that checks whether a user is not blacklisted.
     * @param _user The address of the user to check.
    **/
    modifier userNotBlacklisted(address _user) {
        require(!regulator.isBlacklistedUser(_user), "User must not be blacklisted");
        _;
    }

    /** Functions **/

    /**
    * @notice Allows user to mint if they have the appropriate permissions. User generally
    * has to be some sort of centralized authority.
    * @dev Should be access-restricted with the &#39;requiresPermission&#39; modifier when implementing.
    * @param _to The address of the receiver
    * @param _amount The number of tokens to mint
    */
    function mint(address _to, uint256 _amount) public requiresPermission whenNotPaused {
        _mint(_to, _amount);
    }

    /**
    * @notice Allows user to mint if they have the appropriate permissions. User generally
    * is just a "whitelisted" user (i.e. a user registered with the fiat gateway.)
    * @dev Should be access-restricted with the &#39;requiresPermission&#39; modifier when implementing.
    * @param _amount The number of tokens to burn
    * @return `true` if successful and `false` if unsuccessful
    */
    function burn(uint256 _amount) public requiresPermission whenNotPaused {
        _burn(msg.sender, _amount);
    }

    /**
    * @notice Implements ERC-20 standard approve function. Locked or disabled by default to protect against
    * double spend attacks. To modify allowances, clients should call safer increase/decreaseApproval methods.
    * Upon construction, all calls to approve() will revert unless this contract owner explicitly unlocks approve()
    */
    function approve(address _spender, uint256 _value) 
    public userNotBlacklisted(_spender) userNotBlacklisted(msg.sender) whenNotPaused whenUnlocked returns (bool) {
        tokenStorage.setAllowance(msg.sender, _spender, _value);
        emit Approval(msg.sender, _spender, _value);
        return true;
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
    public userNotBlacklisted(_spender) userNotBlacklisted(msg.sender) whenNotPaused returns (bool) {
        _increaseApproval(_spender, _addedValue, msg.sender);
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
    public userNotBlacklisted(_spender) userNotBlacklisted(msg.sender) whenNotPaused returns (bool) {
        _decreaseApproval(_spender, _subtractedValue, msg.sender);
        return true;
    }

    /**
    * @notice Destroy the tokens owned by a blacklisted account. This function can generally
    * only be called by a central authority.
    * @dev Should be access-restricted with the &#39;requiresPermission&#39; modifier when implementing.
    * @param _who Account to destroy tokens from. Must be a blacklisted account.
    */
    function destroyBlacklistedTokens(address _who, uint256 _amount) public userBlacklisted(_who) whenNotPaused requiresPermission {
        tokenStorage.subBalance(_who, _amount);
        tokenStorage.subTotalSupply(_amount);
        emit DestroyedBlacklistedTokens(_who, _amount);
    }
    /**
    * @notice Allows a central authority to approve themselves as a spender on a blacklisted account.
    * By default, the allowance is set to the balance of the blacklisted account, so that the
    * authority has full control over the account balance.
    * @dev Should be access-restricted with the &#39;requiresPermission&#39; modifier when implementing.
    * @param _blacklistedAccount The blacklisted account.
    */
    function approveBlacklistedAddressSpender(address _blacklistedAccount) 
    public userBlacklisted(_blacklistedAccount) whenNotPaused requiresPermission {
        tokenStorage.setAllowance(_blacklistedAccount, msg.sender, balanceOf(_blacklistedAccount));
        emit ApprovedBlacklistedAddressSpender(_blacklistedAccount, msg.sender, balanceOf(_blacklistedAccount));
    }

    /**
    * @notice Initiates a "send" operation towards another user. See `transferFrom` for details.
    * @param _to The address of the receiver. This user must not be blacklisted, or else the tranfer
    * will fail.
    * @param _amount The number of tokens to transfer
    *
    * @return `true` if successful 
    */
    function transfer(address _to, uint256 _amount) public userNotBlacklisted(_to) userNotBlacklisted(msg.sender) whenNotPaused returns (bool) {
        require(_to != address(0),"to address cannot be 0x0");
        require(_amount <= balanceOf(msg.sender),"not enough balance to transfer");

        tokenStorage.subBalance(msg.sender, _amount);
        tokenStorage.addBalance(_to, _amount);
        emit Transfer(msg.sender, _to, _amount);
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
    public whenNotPaused transferFromConditionsRequired(_from, _to) returns (bool) {
        require(_amount <= allowance(_from, msg.sender),"not enough allowance to transfer");
        require(_to != address(0),"to address cannot be 0x0");
        require(_amount <= balanceOf(_from),"not enough balance to transfer");
        
        tokenStorage.subAllowance(_from, msg.sender, _amount);
        tokenStorage.addBalance(_to, _amount);
        tokenStorage.subBalance(_from, _amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    /**
    *
    * @dev Only the token owner can change its regulator
    * @param _newRegulator the new Regulator for this token
    *
    */
    function setRegulator(address _newRegulator) public onlyOwner {
        require(_newRegulator != address(regulator), "Must be a new regulator");
        require(AddressUtils.isContract(_newRegulator), "Cannot set a regulator storage to a non-contract address");
        address old = address(regulator);
        regulator = Regulator(_newRegulator);
        emit ChangedRegulator(old, _newRegulator);
    }

    /**
    * @notice If a user is blacklisted, they will have the permission to 
    * execute this dummy function. This function effectively acts as a marker 
    * to indicate that a user is blacklisted. We include this function to be consistent with our
    * invariant that every possible userPermission (listed in Regulator) enables access to a single 
    * PermissionedToken function. Thus, the &#39;BLACKLISTED&#39; permission gives access to this function
    * @return `true` if successful
    */
    function blacklisted() public view requiresPermission returns (bool) {
        return true;
    }

    /**
    * ERC20 standard functions
    */
    function allowance(address owner, address spender) public view returns (uint256) {
        return tokenStorage.allowances(owner, spender);
    }

    function totalSupply() public view returns (uint256) {
        return tokenStorage.totalSupply();
    }

    function balanceOf(address _addr) public view returns (uint256) {
        return tokenStorage.balances(_addr);
    }


    /** Internal functions **/
    
    function _decreaseApproval(address _spender, uint256 _subtractedValue, address _tokenHolder) internal {
        uint256 oldValue = allowance(_tokenHolder, _spender);
        if (_subtractedValue > oldValue) {
            tokenStorage.setAllowance(_tokenHolder, _spender, 0);
        } else {
            tokenStorage.subAllowance(_tokenHolder, _spender, _subtractedValue);
        }
        emit Approval(_tokenHolder, _spender, allowance(_tokenHolder, _spender));
    }

    function _increaseApproval(address _spender, uint256 _addedValue, address _tokenHolder) internal {
        tokenStorage.addAllowance(_tokenHolder, _spender, _addedValue);
        emit Approval(_tokenHolder, _spender, allowance(_tokenHolder, _spender));
    }

    function _burn(address _tokensOf, uint256 _amount) internal {
        require(_amount <= balanceOf(_tokensOf),"not enough balance to burn");
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure
        tokenStorage.subBalance(_tokensOf, _amount);
        tokenStorage.subTotalSupply(_amount);
        emit Burn(_tokensOf, _amount);
        emit Transfer(_tokensOf, address(0), _amount);
    }

    function _mint(address _to, uint256 _amount) internal userWhitelisted(_to) {
        tokenStorage.addTotalSupply(_amount);
        tokenStorage.addBalance(_to, _amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

}

/**
* @title CarbonDollarStorage
* @notice Contains necessary storage contracts for CarbonDollar (FeeSheet and StablecoinWhitelist).
*/
contract CarbonDollarStorage is Ownable {
    using SafeMath for uint256;

    /** 
        Mappings
    */
    /* fees for withdrawing to stablecoin, in tenths of a percent) */
    mapping (address => uint256) public fees;
    /** @dev Units for fees are always in a tenth of a percent */
    uint256 public defaultFee;
    /* is the token address referring to a stablecoin/whitelisted token? */
    mapping (address => bool) public whitelist;


    /** 
        Events
    */
    event DefaultFeeChanged(uint256 oldFee, uint256 newFee);
    event FeeChanged(address indexed stablecoin, uint256 oldFee, uint256 newFee);
    event FeeRemoved(address indexed stablecoin, uint256 oldFee);
    event StablecoinAdded(address indexed stablecoin);
    event StablecoinRemoved(address indexed stablecoin);

    /** @notice Sets the default fee for burning CarbonDollar into a whitelisted stablecoin.
        @param _fee The default fee.
    */
    function setDefaultFee(uint256 _fee) public onlyOwner {
        uint256 oldFee = defaultFee;
        defaultFee = _fee;
        if (oldFee != defaultFee)
            emit DefaultFeeChanged(oldFee, _fee);
    }
    
    /** @notice Set a fee for burning CarbonDollar into a stablecoin.
        @param _stablecoin Address of a whitelisted stablecoin.
        @param _fee the fee.
    */
    function setFee(address _stablecoin, uint256 _fee) public onlyOwner {
        uint256 oldFee = fees[_stablecoin];
        fees[_stablecoin] = _fee;
        if (oldFee != _fee)
            emit FeeChanged(_stablecoin, oldFee, _fee);
    }

    /** @notice Remove the fee for burning CarbonDollar into a particular kind of stablecoin.
        @param _stablecoin Address of stablecoin.
    */
    function removeFee(address _stablecoin) public onlyOwner {
        uint256 oldFee = fees[_stablecoin];
        fees[_stablecoin] = 0;
        if (oldFee != 0)
            emit FeeRemoved(_stablecoin, oldFee);
    }

    /** @notice Add a token to the whitelist.
        @param _stablecoin Address of the new stablecoin.
    */
    function addStablecoin(address _stablecoin) public onlyOwner {
        whitelist[_stablecoin] = true;
        emit StablecoinAdded(_stablecoin);
    }

    /** @notice Removes a token from the whitelist.
        @param _stablecoin Address of the ex-stablecoin.
    */
    function removeStablecoin(address _stablecoin) public onlyOwner {
        whitelist[_stablecoin] = false;
        emit StablecoinRemoved(_stablecoin);
    }


    /**
     * @notice Compute the fee that will be charged on a "burn" operation.
     * @param _amount The amount that will be traded.
     * @param _stablecoin The stablecoin whose fee will be used.
     */
    function computeStablecoinFee(uint256 _amount, address _stablecoin) public view returns (uint256) {
        uint256 fee = fees[_stablecoin];
        return computeFee(_amount, fee);
    }

    /**
     * @notice Compute the fee that will be charged on a "burn" operation.
     * @param _amount The amount that will be traded.
     * @param _fee The fee that will be charged, in tenths of a percent.
     */
    function computeFee(uint256 _amount, uint256 _fee) public pure returns (uint256) {
        return _amount.mul(_fee).div(1000);
    }
}

/**
 * @title WhitelistedTokenRegulator
 * @dev WhitelistedTokenRegulator is a type of Regulator that modifies its definitions of
 * what constitutes a "whitelisted/nonlisted/blacklisted" user. A WhitelistedToken
 * provides a user the additional ability to convert from a whtielisted stablecoin into the
 * meta-token CUSD, or mint CUSD directly through a specific WT.
 *
 */
contract WhitelistedTokenRegulator is Regulator {

    function isMinter(address _who) public view returns (bool) {
        return (super.isMinter(_who) && hasUserPermission(_who, MINT_CUSD_SIG));
    }

    // Getters

    function isWhitelistedUser(address _who) public view returns (bool) {
        return (hasUserPermission(_who, CONVERT_WT_SIG) && super.isWhitelistedUser(_who));
    }

    function isBlacklistedUser(address _who) public view returns (bool) {
        return (!hasUserPermission(_who, CONVERT_WT_SIG) && super.isBlacklistedUser(_who));
    }

    function isNonlistedUser(address _who) public view returns (bool) {
        return (!hasUserPermission(_who, CONVERT_WT_SIG) && super.isNonlistedUser(_who));
    }   

    /** Internal functions **/

    // A WT minter should have option to either mint directly into CUSD via mintCUSD(), or
    // mint the WT via an ordinary mint() 
    function _setMinter(address _who) internal {
        require(isPermission(MINT_CUSD_SIG), "Minting to CUSD not supported by token");
        setUserPermission(_who, MINT_CUSD_SIG);
        super._setMinter(_who);
    }

    function _removeMinter(address _who) internal {
        require(isPermission(MINT_CUSD_SIG), "Minting to CUSD not supported by token");
        removeUserPermission(_who, MINT_CUSD_SIG);
        super._removeMinter(_who);
    }

    // Setters

    // A WT whitelisted user should gain ability to convert their WT into CUSD. They can also burn their WT, as a
    // PermissionedToken whitelisted user can do
    function _setWhitelistedUser(address _who) internal {
        require(isPermission(CONVERT_WT_SIG), "Converting to CUSD not supported by token");
        setUserPermission(_who, CONVERT_WT_SIG);
        super._setWhitelistedUser(_who);
    }

    function _setBlacklistedUser(address _who) internal {
        require(isPermission(CONVERT_WT_SIG), "Converting to CUSD not supported by token");
        removeUserPermission(_who, CONVERT_WT_SIG);
        super._setBlacklistedUser(_who);
    }

    function _setNonlistedUser(address _who) internal {
        require(isPermission(CONVERT_WT_SIG), "Converting to CUSD not supported by token");
        removeUserPermission(_who, CONVERT_WT_SIG);
        super._setNonlistedUser(_who);
    }

}

/**
* @title WhitelistedToken
* @notice A WhitelistedToken can be converted into CUSD and vice versa. Converting a WT into a CUSD
* is the only way for a user to obtain CUSD. This is a permissioned token, so users have to be 
* whitelisted before they can do any mint/burn/convert operation.
*/
contract WhitelistedToken is PermissionedToken {


    address public cusdAddress;

    /**
        Events
     */
    event CUSDAddressChanged(address indexed oldCUSD, address indexed newCUSD);
    event MintedToCUSD(address indexed user, uint256 amount);
    event ConvertedToCUSD(address indexed user, uint256 amount);

    /**
    * @notice Constructor sets the regulator contract and the address of the
    * CarbonUSD meta-token contract. The latter is necessary in order to make transactions
    * with the CarbonDollar smart contract.
    */
    constructor(address _regulator, address _cusd) public PermissionedToken(_regulator) {

        // base class fields
        regulator = WhitelistedTokenRegulator(_regulator);

        cusdAddress = _cusd;

    }

    /**
    * @notice Mints CarbonUSD for the user. Stores the WT0 that backs the CarbonUSD
    * into the CarbonUSD contract&#39;s escrow account.
    * @param _to The address of the receiver
    * @param _amount The number of CarbonTokens to mint to user
    */
    function mintCUSD(address _to, uint256 _amount) public requiresPermission whenNotPaused userWhitelisted(_to) {
        return _mintCUSD(_to, _amount);
    }

    /**
    * @notice Converts WT0 to CarbonUSD for the user. Stores the WT0 that backs the CarbonUSD
    * into the CarbonUSD contract&#39;s escrow account.
    * @param _amount The number of Whitelisted tokens to convert
    */
    function convertWT(uint256 _amount) public requiresPermission whenNotPaused {
        require(balanceOf(msg.sender) >= _amount, "Conversion amount should be less than balance");
        _burn(msg.sender, _amount);
        _mintCUSD(msg.sender, _amount);
        emit ConvertedToCUSD(msg.sender, _amount);
    }

    /**
     * @notice Change the cusd address.
     * @param _cusd the cusd address.
     */
    function setCUSDAddress(address _cusd) public onlyOwner {
        require(_cusd != address(cusdAddress), "Must be a new cusd address");
        require(AddressUtils.isContract(_cusd), "Must be an actual contract");
        address oldCUSD = address(cusdAddress);
        cusdAddress = _cusd;
        emit CUSDAddressChanged(oldCUSD, _cusd);
    }

    function _mintCUSD(address _to, uint256 _amount) internal {
        require(_to != cusdAddress, "Cannot mint to CarbonUSD contract"); // This is to prevent Carbon Labs from printing money out of thin air!
        CarbonDollar(cusdAddress).mint(_to, _amount);
        _mint(cusdAddress, _amount);
        emit MintedToCUSD(_to, _amount);
    }
}

/**
 * @title CarbonDollarRegulator
 * @dev CarbonDollarRegulator is a type of Regulator that modifies its definitions of
 * what constitutes a "whitelisted/nonlisted/blacklisted" user. A CarbonDollar
 * provides a user the additional ability to convert from CUSD into a whtielisted stablecoin
 *
 */
contract CarbonDollarRegulator is Regulator {

    // Getters
    function isWhitelistedUser(address _who) public view returns(bool) {
        return (hasUserPermission(_who, CONVERT_CARBON_DOLLAR_SIG) 
        && hasUserPermission(_who, BURN_CARBON_DOLLAR_SIG) 
        && !hasUserPermission(_who, BLACKLISTED_SIG));
    }

    function isBlacklistedUser(address _who) public view returns(bool) {
        return (!hasUserPermission(_who, CONVERT_CARBON_DOLLAR_SIG) 
        && !hasUserPermission(_who, BURN_CARBON_DOLLAR_SIG) 
        && hasUserPermission(_who, BLACKLISTED_SIG));
    }

    function isNonlistedUser(address _who) public view returns(bool) {
        return (!hasUserPermission(_who, CONVERT_CARBON_DOLLAR_SIG) 
        && !hasUserPermission(_who, BURN_CARBON_DOLLAR_SIG) 
        && !hasUserPermission(_who, BLACKLISTED_SIG));
    }

    /** Internal functions **/
    
    // Setters: CarbonDollarRegulator overrides the definitions of whitelisted, nonlisted, and blacklisted setUserPermission

    // CarbonDollar whitelisted users burn CUSD into a WhitelistedToken. Unlike PermissionedToken 
    // whitelisted users, CarbonDollar whitelisted users cannot burn ordinary CUSD without converting into WT
    function _setWhitelistedUser(address _who) internal {
        require(isPermission(CONVERT_CARBON_DOLLAR_SIG), "Converting CUSD not supported");
        require(isPermission(BURN_CARBON_DOLLAR_SIG), "Burning CUSD not supported");
        require(isPermission(BLACKLISTED_SIG), "Blacklisting not supported");
        setUserPermission(_who, CONVERT_CARBON_DOLLAR_SIG);
        setUserPermission(_who, BURN_CARBON_DOLLAR_SIG);
        removeUserPermission(_who, BLACKLISTED_SIG);
        emit LogWhitelistedUser(_who);
    }

    function _setBlacklistedUser(address _who) internal {
        require(isPermission(CONVERT_CARBON_DOLLAR_SIG), "Converting CUSD not supported");
        require(isPermission(BURN_CARBON_DOLLAR_SIG), "Burning CUSD not supported");
        require(isPermission(BLACKLISTED_SIG), "Blacklisting not supported");
        removeUserPermission(_who, CONVERT_CARBON_DOLLAR_SIG);
        removeUserPermission(_who, BURN_CARBON_DOLLAR_SIG);
        setUserPermission(_who, BLACKLISTED_SIG);
        emit LogBlacklistedUser(_who);
    }

    function _setNonlistedUser(address _who) internal {
        require(isPermission(CONVERT_CARBON_DOLLAR_SIG), "Converting CUSD not supported");
        require(isPermission(BURN_CARBON_DOLLAR_SIG), "Burning CUSD not supported");
        require(isPermission(BLACKLISTED_SIG), "Blacklisting not supported");
        removeUserPermission(_who, CONVERT_CARBON_DOLLAR_SIG);
        removeUserPermission(_who, BURN_CARBON_DOLLAR_SIG);
        removeUserPermission(_who, BLACKLISTED_SIG);
        emit LogNonlistedUser(_who);
    }
}

/**
* @title CarbonDollar
* @notice The main functionality for the CarbonUSD metatoken. (CarbonUSD is just a proxy
* that implements this contract&#39;s functionality.) This is a permissioned token, so users have to be 
* whitelisted before they can do any mint/burn/convert operation. Every CarbonDollar token is backed by one
* whitelisted stablecoin credited to the balance of this contract address.
*/
contract CarbonDollar is PermissionedToken {
    
    // Events

    event ConvertedToWT(address indexed user, uint256 amount);
    event BurnedCUSD(address indexed user, uint256 feedAmount, uint256 chargedFee);
    
    /**
        Modifiers
    */
    modifier requiresWhitelistedToken() {
        require(isWhitelisted(msg.sender), "Sender must be a whitelisted token contract");
        _;
    }

    CarbonDollarStorage public tokenStorage_CD;

    /** CONSTRUCTOR
    * @dev Passes along arguments to base class.
    */
    constructor(address _regulator) public PermissionedToken(_regulator) {

        // base class override
        regulator = CarbonDollarRegulator(_regulator);

        tokenStorage_CD = new CarbonDollarStorage();
    }

    /**
     * @notice Add new stablecoin to whitelist.
     * @param _stablecoin Address of stablecoin contract.
     */
    function listToken(address _stablecoin) public onlyOwner whenNotPaused {
        tokenStorage_CD.addStablecoin(_stablecoin); 
    }

    /**
     * @notice Remove existing stablecoin from whitelist.
     * @param _stablecoin Address of stablecoin contract.
     */
    function unlistToken(address _stablecoin) public onlyOwner whenNotPaused {
        tokenStorage_CD.removeStablecoin(_stablecoin);
    }

    /**
     * @notice Change fees associated with going from CarbonUSD to a particular stablecoin.
     * @param stablecoin Address of the stablecoin contract.
     * @param _newFee The new fee rate to set, in tenths of a percent. 
     */
    function setFee(address stablecoin, uint256 _newFee) public onlyOwner whenNotPaused {
        require(isWhitelisted(stablecoin), "Stablecoin must be whitelisted prior to setting conversion fee");
        tokenStorage_CD.setFee(stablecoin, _newFee);
    }

    /**
     * @notice Remove fees associated with going from CarbonUSD to a particular stablecoin.
     * The default fee still may apply.
     * @param stablecoin Address of the stablecoin contract.
     */
    function removeFee(address stablecoin) public onlyOwner whenNotPaused {
        require(isWhitelisted(stablecoin), "Stablecoin must be whitelisted prior to setting conversion fee");
       tokenStorage_CD.removeFee(stablecoin);
    }

    /**
     * @notice Change the default fee associated with going from CarbonUSD to a WhitelistedToken.
     * This fee amount is used if the fee for a WhitelistedToken is not specified.
     * @param _newFee The new fee rate to set, in tenths of a percent.
     */
    function setDefaultFee(uint256 _newFee) public onlyOwner whenNotPaused {
        tokenStorage_CD.setDefaultFee(_newFee);
    }

    /**
     * @notice Mints CUSD on behalf of a user. Note the use of the "requiresWhitelistedToken"
     * modifier; this means that minting authority does not belong to any personal account; 
     * only whitelisted token contracts can call this function. The intended functionality is that the only
     * way to mint CUSD is for the user to actually burn a whitelisted token to convert into CUSD
     * @param _to User to send CUSD to
     * @param _amount Amount of CarbonUSD to mint.
     */
    function mint(address _to, uint256 _amount) public requiresWhitelistedToken whenNotPaused {
        _mint(_to, _amount);
    }

    /**
     * @notice user can convert CarbonUSD umbrella token into a whitelisted stablecoin. 
     * @param stablecoin represents the type of coin the users wishes to receive for burning carbonUSD
     * @param _amount Amount of CarbonUSD to convert.
     * we credit the user&#39;s account at the sender address with the _amount minus the percentage fee we want to charge.
     */
    function convertCarbonDollar(address stablecoin, uint256 _amount) public requiresPermission whenNotPaused  {
        require(isWhitelisted(stablecoin), "Stablecoin must be whitelisted prior to setting conversion fee");
        WhitelistedToken whitelisted = WhitelistedToken(stablecoin);
        require(whitelisted.balanceOf(address(this)) >= _amount, "Carbon escrow account in WT0 doesn&#39;t have enough tokens for burning");
 
        // Send back WT0 to calling user, but with a fee reduction.
        // Transfer this fee into the whitelisted token&#39;s CarbonDollar account (this contract&#39;s address)
        uint256 chargedFee = tokenStorage_CD.computeFee(_amount, computeFeeRate(stablecoin));
        uint256 feedAmount = _amount.sub(chargedFee);
        _burn(msg.sender, _amount);
        require(whitelisted.transfer(msg.sender, feedAmount));
        whitelisted.burn(chargedFee);
        _mint(address(this), chargedFee);
        emit ConvertedToWT(msg.sender, _amount);
    }

     /**
     * @notice burns CarbonDollar and an equal amount of whitelisted stablecoin from the CarbonDollar address
     * @param stablecoin Represents the stablecoin whose fee will be charged.
     * @param _amount Amount of CarbonUSD to burn.
     */
    function burnCarbonDollar(address stablecoin, uint256 _amount) public requiresPermission whenNotPaused {
        require(isWhitelisted(stablecoin), "Stablecoin must be whitelisted prior to setting conversion fee");
        WhitelistedToken whitelisted = WhitelistedToken(stablecoin);
        require(whitelisted.balanceOf(address(this)) >= _amount, "Carbon escrow account in WT0 doesn&#39;t have enough tokens for burning");
 
        // Burn user&#39;s CUSD, but with a fee reduction.
        uint256 chargedFee = tokenStorage_CD.computeFee(_amount, computeFeeRate(stablecoin));
        uint256 feedAmount = _amount.sub(chargedFee);
        _burn(msg.sender, _amount);
        whitelisted.burn(_amount);
        _mint(address(this), chargedFee);
        emit BurnedCUSD(msg.sender, feedAmount, chargedFee); // Whitelisted trust account should send user feedAmount USD
    }

    /** 
    * @notice release collected CUSD fees to owner 
    * @param _amount Amount of CUSD to release
    * @return `true` if successful 
    */
    function releaseCarbonDollar(uint256 _amount) public onlyOwner returns (bool) {
        require(_amount <= balanceOf(address(this)),"not enough balance to transfer");

        tokenStorage.subBalance(address(this), _amount);
        tokenStorage.addBalance(msg.sender, _amount);
        emit Transfer(address(this), msg.sender, _amount);
        return true;
    }

    /** Computes fee percentage associated with burning into a particular stablecoin.
     * @param stablecoin The stablecoin whose fee will be charged. Precondition: is a whitelisted
     * stablecoin.
     * @return The fee that will be charged. If the stablecoin&#39;s fee is not set, the default
     * fee is returned.
     */
    function computeFeeRate(address stablecoin) public view returns (uint256 feeRate) {
        if (getFee(stablecoin) > 0) 
            feeRate = getFee(stablecoin);
        else
            feeRate = getDefaultFee();
    }

    /**
    * @notice Check if whitelisted token is whitelisted
    * @return bool true if whitelisted, false if not
    **/
    function isWhitelisted(address _stablecoin) public view returns (bool) {
        return tokenStorage_CD.whitelist(_stablecoin);
    }

    /**
     * @notice Get the fee associated with going from CarbonUSD to a specific WhitelistedToken.
     * @param stablecoin The stablecoin whose fee is being checked.
     * @return The fee associated with the stablecoin.
     */
    function getFee(address stablecoin) public view returns (uint256) {
        return tokenStorage_CD.fees(stablecoin);
    }

    /**
     * @notice Get the default fee associated with going from CarbonUSD to a specific WhitelistedToken.
     * @return The default fee for stablecoin trades.
     */
    function getDefaultFee() public view returns (uint256) {
        return tokenStorage_CD.defaultFee();
    }

    function _mint(address _to, uint256 _amount) internal {
        super._mint(_to, _amount);
    }

}

/**
* @title WhitelistedToken
* @notice A WhitelistedToken can be converted into CUSD and vice versa. Converting a WT into a CUSD
* is the only way for a user to obtain CUSD. This is a permissioned token, so users have to be 
* whitelisted before they can do any mint/burn/convert operation.
*/
// contract WhitelistedToken is PermissionedToken {


//     address public cusdAddress;

//     /**
//         Events
//      */
//     event CUSDAddressChanged(address indexed oldCUSD, address indexed newCUSD);
//     event MintedToCUSD(address indexed user, uint256 amount);
//     event ConvertedToCUSD(address indexed user, uint256 amount);

//     /**
//     * @notice Constructor sets the regulator contract and the address of the
//     * CarbonUSD meta-token contract. The latter is necessary in order to make transactions
//     * with the CarbonDollar smart contract.
//     */
//     constructor(address _regulator, address _cusd) public PermissionedToken(_regulator) {

//         // base class fields
//         regulator = WhitelistedTokenRegulator(_regulator);

//         cusdAddress = _cusd;

//     }

//     /**
//     * @notice Mints CarbonUSD for the user. Stores the WT0 that backs the CarbonUSD
//     * into the CarbonUSD contract&#39;s escrow account.
//     * @param _to The address of the receiver
//     * @param _amount The number of CarbonTokens to mint to user
//     */
//     function mintCUSD(address _to, uint256 _amount) public requiresPermission whenNotPaused userWhitelisted(_to) {
//         return _mintCUSD(_to, _amount);
//     }

//     *
//     * @notice Converts WT0 to CarbonUSD for the user. Stores the WT0 that backs the CarbonUSD
//     * into the CarbonUSD contract&#39;s escrow account.
//     * @param _amount The number of Whitelisted tokens to convert
    
//     function convertWT(uint256 _amount) public requiresPermission whenNotPaused {
//         require(balanceOf(msg.sender) >= _amount, "Conversion amount should be less than balance");
//         _burn(msg.sender, _amount);
//         _mintCUSD(msg.sender, _amount);
//         emit ConvertedToCUSD(msg.sender, _amount);
//     }

//     /**
//      * @notice Change the cusd address.
//      * @param _cusd the cusd address.
//      */
//     function setCUSDAddress(address _cusd) public onlyOwner {
//         require(_cusd != address(cusdAddress), "Must be a new cusd address");
//         require(AddressUtils.isContract(_cusd), "Must be an actual contract");
//         address oldCUSD = address(cusdAddress);
//         cusdAddress = _cusd;
//         emit CUSDAddressChanged(oldCUSD, _cusd);
//     }

//     function _mintCUSD(address _to, uint256 _amount) internal {
//         require(_to != cusdAddress, "Cannot mint to CarbonUSD contract"); // This is to prevent Carbon Labs from printing money out of thin air!
//         CarbonDollar(cusdAddress).mint(_to, _amount);
//         _mint(cusdAddress, _amount);
//         emit MintedToCUSD(_to, _amount);
//     }
// }