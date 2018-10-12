pragma solidity ^0.4.24;

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