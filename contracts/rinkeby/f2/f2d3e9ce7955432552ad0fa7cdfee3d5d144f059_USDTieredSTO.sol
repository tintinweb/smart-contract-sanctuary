/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IModule {
    /**
     * @notice This function returns the signature of configure function
     */
    function getInitFunction() external pure returns(bytes4 initFunction);

    /**
     * @notice Return the permission flags that are associated with a module
     */
    function getPermissions() external view returns(bytes32[] memory permissions);

    function getTypes() external view returns(uint8 [] memory);

    function getName() external view returns(bytes32);
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * return bool
     */
    function has(Role storage role, address account)
    internal
    view
    returns (bool)
    {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private pausers;

    constructor() {
        pausers.add(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        pausers.add(account);
        emit PauserAdded(account);
    }

    function renouncePauser() public {
        pausers.remove(msg.sender);
    }

    function _removePauser(address account) internal {
        pausers.remove(account);
        emit PauserRemoved(account);
    }
}

contract Pausable is PauserRole {
    event Paused();
    event Unpaused();

    bool private _paused = false;


    /**
     * return true if the contract is paused, false otherwise.
     */
    function paused() public view returns(bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public virtual onlyPauser whenNotPaused {
        _paused = true;
        emit Paused();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public virtual onlyPauser whenPaused {
        _paused = false;
        emit Unpaused();
    }
}

interface IModuleFactory {
    event ChangeSetupCost(uint256 _oldSetupCost, uint256 _newSetupCost);
    event ChangeCostType(bool _isOldCostInPoly, bool _isNewCostInPoly);
    event GenerateModuleFromFactory(
        address _module,
        bytes32 indexed _moduleName,
        address indexed _moduleFactory,
        address _creator,
        uint256 _setupCost,
        uint256 _setupCostInPoly
    );
    event ChangeSTVersionBound(string _boundType, uint8 _major, uint8 _minor, uint8 _patch);

    //Should create an instance of the Module, or throw
    function deploy(bytes calldata _data) external returns(address moduleAddress);

    /**
     * @notice Get the tags related to the module factory
     */
    function version() external view returns(string memory moduleVersion);

    /**
     * @notice Get the tags related to the module factory
     */
    function name() external view returns(bytes32 moduleName);

    /**
     * @notice Returns the title associated with the module
     */
    function title() external view returns(string memory moduleTitle);

    /**
     * @notice Returns the description associated with the module
     */
    function description() external view returns(string memory moduleDescription);

    /**
     * @notice Get the setup cost of the module in USD
     */
    function setupCost() external returns(uint256 usdSetupCost);

    /**
     * @notice Type of the Module factory
     */
    function getTypes() external view returns(uint8[] memory moduleTypes);

    /**
     * @notice Get the tags related to the module factory
     */
    function getTags() external view returns(bytes32[] memory moduleTags);

    /**
     * @notice Used to change the setup fee
     * @param _newSetupCost New setup fee
     */
    function changeSetupCost(uint256 _newSetupCost) external;

    /**
     * @notice Used to change the currency and amount setup cost
     * @param _setupCost new setup cost
     * @param _isCostInPoly new setup cost currency. USD or POLY
     */
    function changeCostAndType(uint256 _setupCost, bool _isCostInPoly) external;

    /**
     * @notice Function use to change the lower and upper bound of the compatible version st
     * @param _boundType Type of bound
     * @param _newVersion New version array
     */
    function changeSTVersionBounds(string calldata _boundType, uint8[] calldata _newVersion) external;

    /**
     * @notice Get the setup cost of the module
     */
    function setupCostInPoly() external returns (uint256 polySetupCost);

    /**
     * @notice Used to get the lower bound
     * return Lower bound
     */
    function getLowerSTVersionBounds() external view returns(uint8[] memory lowerBounds);

    /**
     * @notice Used to get the upper bound
     * return Upper bound
     */
    function getUpperSTVersionBounds() external view returns(uint8[] memory upperBounds);

    /**
     * @notice Updates the tags of the ModuleFactory
     * @param _tagsData New list of tags
     */
    function changeTags(bytes32[] calldata _tagsData) external;

    /**
     * @notice Updates the name of the ModuleFactory
     * @param _name New name that will replace the old one.
     */
    function changeName(bytes32 _name) external;

    /**
     * @notice Updates the description of the ModuleFactory
     * @param _description New description that will replace the old one.
     */
    function changeDescription(string calldata _description) external;

    /**
     * @notice Updates the title of the ModuleFactory
     * @param _title New Title that will replace the old one.
     */
    function changeTitle(string calldata _title) external;

}

interface IDataStore {
    /**
     * @dev Changes security token atatched to this data store
     * @param _securityToken address of the security token
     */
    function setSecurityToken(address _securityToken) external;

    /**
     * @dev Stores a uint256 data against a key
     * @param _key Unique key to identify the data
     * @param _data Data to be stored against the key
     */
    function setUint256(bytes32 _key, uint256 _data) external;

    function setBytes32(bytes32 _key, bytes32 _data) external;

    function setAddress(bytes32 _key, address _data) external;

    function setString(bytes32 _key, string calldata _data) external;

    function setBytes(bytes32 _key, bytes calldata _data) external;

    function setBool(bytes32 _key, bool _data) external;

    /**
     * @dev Stores a uint256 array against a key
     * @param _key Unique key to identify the array
     * @param _data Array to be stored against the key
     */
    function setUint256Array(bytes32 _key, uint256[] calldata _data) external;

    function setBytes32Array(bytes32 _key, bytes32[] calldata _data) external;

    function setAddressArray(bytes32 _key, address[] calldata _data) external;

    function setBoolArray(bytes32 _key, bool[] calldata _data) external;

    /**
     * @dev Inserts a uint256 element to the array identified by the key
     * @param _key Unique key to identify the array
     * @param _data Element to push into the array
     */
    function insertUint256(bytes32 _key, uint256 _data) external;

    function insertBytes32(bytes32 _key, bytes32 _data) external;

    function insertAddress(bytes32 _key, address _data) external;

    function insertBool(bytes32 _key, bool _data) external;

    /**
     * @dev Deletes an element from the array identified by the key.
     * When an element is deleted from an Array, last element of that array is moved to the index of deleted element.
     * @param _key Unique key to identify the array
     * @param _index Index of the element to delete
     */
    function deleteUint256(bytes32 _key, uint256 _index) external;

    function deleteBytes32(bytes32 _key, uint256 _index) external;

    function deleteAddress(bytes32 _key, uint256 _index) external;

    function deleteBool(bytes32 _key, uint256 _index) external;

    /**
     * @dev Stores multiple uint256 data against respective keys
     * @param _keys Array of keys to identify the data
     * @param _data Array of data to be stored against the respective keys
     */
    function setUint256Multi(bytes32[] calldata _keys, uint256[] calldata _data) external;

    function setBytes32Multi(bytes32[] calldata _keys, bytes32[] calldata _data) external;

    function setAddressMulti(bytes32[] calldata _keys, address[] calldata _data) external;

    function setBoolMulti(bytes32[] calldata _keys, bool[] calldata _data) external;

    /**
     * @dev Inserts multiple uint256 elements to the array identified by the respective keys
     * @param _keys Array of keys to identify the data
     * @param _data Array of data to be inserted in arrays of the respective keys
     */
    function insertUint256Multi(bytes32[] calldata _keys, uint256[] calldata _data) external;

    function insertBytes32Multi(bytes32[] calldata _keys, bytes32[] calldata _data) external;

    function insertAddressMulti(bytes32[] calldata _keys, address[] calldata _data) external;

    function insertBoolMulti(bytes32[] calldata _keys, bool[] calldata _data) external;

    function getUint256(bytes32 _key) external view returns(uint256);

    function getBytes32(bytes32 _key) external view returns(bytes32);

    function getAddress(bytes32 _key) external view returns(address);

    function getString(bytes32 _key) external view returns(string memory);

    function getBytes(bytes32 _key) external view returns(bytes memory);

    function getBool(bytes32 _key) external view returns(bool);

    function getUint256Array(bytes32 _key) external view returns(uint256[] memory);

    function getBytes32Array(bytes32 _key) external view returns(bytes32[] memory);

    function getAddressArray(bytes32 _key) external view returns(address[] memory);

    function getBoolArray(bytes32 _key) external view returns(bool[] memory);

    function getUint256ArrayLength(bytes32 _key) external view returns(uint256);

    function getBytes32ArrayLength(bytes32 _key) external view returns(uint256);

    function getAddressArrayLength(bytes32 _key) external view returns(uint256);

    function getBoolArrayLength(bytes32 _key) external view returns(uint256);

    function getUint256ArrayElement(bytes32 _key, uint256 _index) external view returns(uint256);

    function getBytes32ArrayElement(bytes32 _key, uint256 _index) external view returns(bytes32);

    function getAddressArrayElement(bytes32 _key, uint256 _index) external view returns(address);

    function getBoolArrayElement(bytes32 _key, uint256 _index) external view returns(bool);

    function getUint256ArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(uint256[] memory);

    function getBytes32ArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(bytes32[] memory);

    function getAddressArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(address[] memory);

    function getBoolArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(bool[] memory);
}

interface ICheckPermission {
    /**
     * @notice Validate permissions with PermissionManager if it exists, If no Permission return false
     * @dev Note that IModule withPerm will allow ST owner all permissions anyway
     * @dev this allows individual modules to override this logic if needed (to not allow ST owner all permissions)
     * @param _delegate address of delegate
     * @param _module address of PermissionManager module
     * @param _perm the permissions
     * return success
     */
    function checkPermission(address _delegate, address _module, bytes32 _perm) external view returns(bool hasPerm);
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISecurityToken {
    // Standard ERC20 interface
    function totalSupply() external view returns(uint256);
    function name() external view returns(string memory);
    function balanceOf(address owner_) external view returns(uint256);
    function allowance(address owner_, address spender) external view returns(uint256);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function approve(address spender, uint256 value) external returns(bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @notice Transfers of securities may fail for a number of reasons. So this function will used to understand the
     * cause of failure by getting the byte value. Which will be the ESC that follows the EIP 1066. ESC can be mapped
     * with a reson string to understand the failure cause, table of Ethereum status code will always reside off-chain
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * return byte Ethereum status code (ESC)
     * return bytes32 Application specific reason code
     */
    function canTransfer(address _to, uint256 _value, bytes calldata _data) external view returns (bytes1 statusCode, bytes32 reasonCode);

    // Emit at the time when module get added
    event ModuleAdded(
        uint8[] _types,
        bytes32 indexed _name,
        address _module,
        uint256 _moduleCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    );

    // Emit when the token details get updated
    event UpdateTokenDetails(string _oldDetails, string _newDetails);
    // Emit when the token name get updated
    event UpdateTokenName(string _oldName, string _newName);
    // Emit when the granularity get changed
    event GranularityChanged(uint256 _oldGranularity, uint256 _newGranularity);
    // Emit when is permanently frozen by the issuer
    event FreezeIssuance();
    // Emit when transfers are frozen or unfrozen
    event FreezeTransfers(bool _status);
    // Emit when new checkpoint created
    event CheckpointCreated(uint256 indexed _checkpointId, uint256 _investorLength);
    // Events to log controller actions
    event SetController(address indexed _oldController, address indexed _newController);
    //Event emit when the global treasury wallet address get changed
    event TreasuryWalletChanged(address _oldTreasuryWallet, address _newTreasuryWallet);
    event DisableController();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokenUpgraded(uint8 _major, uint8 _minor, uint8 _patch);

    // Transfer Events
    event TransferByPartition(
        bytes32 indexed _fromPartition,
        address _operator,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    // Operator Events
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
    event AuthorizedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);
    event RevokedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);

    // Issuance / Redemption Events
    event IssuedByPartition(bytes32 indexed partition, address indexed to, uint256 value, bytes data);
    event RedeemedByPartition(bytes32 indexed partition, address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);

    // Document Events
    event DocumentRemoved(bytes32 indexed _name, string _uri, bytes32 _documentHash);
    event DocumentUpdated(bytes32 indexed _name, string _uri, bytes32 _documentHash);

    // Controller Events
    event ControllerTransfer(
        address _controller,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    event ControllerRedemption(
        address _controller,
        address indexed _tokenHolder,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    // Issuance / Redemption Events
    event Issued(address indexed _operator, address indexed _to, uint256 _value, bytes _data);
    event Redeemed(address indexed _operator, address indexed _from, uint256 _value, bytes _data);

    /**
     * @notice Initialization function
     * @dev Expected to be called atomically with the proxy being created, by the owner of the token
     * @dev Can only be called once
     */
    //function initialize(address _getterDelegate) external;
    function initialize(string calldata _name, string calldata _symbol, uint8 _decimals, uint256 _granularity, string calldata _tokenDetails) external;

    /**
     * @notice The standard provides an on-chain function to determine whether a transfer will succeed,
     * and return details indicating the reason if the transfer is not valid.
     * @param _from The address from whom the tokens get transferred.
     * @param _to The address to which to transfer tokens to.
     * @param _partition The partition from which to transfer tokens
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * return ESC (Ethereum Status Code) following the EIP-1066 standard
     * return Application specific reason codes with additional details
     * return The partition to which the transferred tokens were allocated for the _to address
     */
    function canTransferByPartition(
        address _from,
        address _to,
        bytes32 _partition,
        uint256 _value,
        bytes calldata _data
    )
    external
    view
    returns (bytes1 statusCode, bytes32 reasonCode, bytes32 partition);

    /**
     * @notice Transfers of securities may fail for a number of reasons. So this function will used to understand the
     * cause of failure by getting the byte value. Which will be the ESC that follows the EIP 1066. ESC can be mapped
     * with a reson string to understand the failure cause, table of Ethereum status code will always reside off-chain
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * return byte Ethereum status code (ESC)
     * return bytes32 Application specific reason code
     */
    function canTransferFrom(address _from, address _to, uint256 _value, bytes calldata _data) external view returns (bytes1 statusCode, bytes32 reasonCode);

    /**
     * @notice Used to attach a new document to the contract, or update the URI or hash of an existing attached document
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     * @param _uri Off-chain uri of the document from where it is accessible to investors/advisors to read.
     * @param _documentHash hash (of the contents) of the document.
     */
    function setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) external;

    /**
     * @notice Used to remove an existing document from the contract by giving the name of the document.
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     */
    function removeDocument(bytes32 _name) external;

    /**
     * @notice Used to return the details of a document with a known name (`bytes32`).
     * @param _name Name of the document
     * return string The URI associated with the document.
     * return bytes32 The hash (of the contents) of the document.
     * return uint256 the timestamp at which the document was last modified.
     */
    function getDocument(bytes32 _name) external view returns (string memory documentUri, bytes32 documentHash, uint256 documentTime);

    /**
     * @notice Used to retrieve a full list of documents attached to the smart contract.
     * return bytes32 List of all documents names present in the contract.
     */
    function getAllDocuments() external view returns (bytes32[] memory documentNames);

    /**
     * @notice In order to provide transparency over whether `controllerTransfer` / `controllerRedeem` are useable
     * or not `isControllable` function will be used.
     * @dev If `isControllable` returns `false` then it always return `false` and
     * `controllerTransfer` / `controllerRedeem` will always revert.
     * return bool `true` when controller address is non-zero otherwise return `false`.
     */
    function isControllable() external view returns (bool controlled);

    /**
     * @notice Checks if an address is a module of certain type
     * @param _module Address to check
     * @param _type type to check against
     */
    function isModule(address _module, uint8 _type) external view returns(bool isValid);

    /**
     * @notice This function must be called to increase the total supply (Corresponds to mint function of ERC20).
     * @dev It only be called by the token issuer or the operator defined by the issuer. ERC1594 doesn't have
     * have the any logic related to operator but its superset ERC1400 have the operator logic and this function
     * is allowed to call by the operator.
     * @param _tokenHolder The account that will receive the created tokens (account should be whitelisted or KYCed).
     * @param _value The amount of tokens need to be issued
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     */
    function issue(address _tokenHolder, uint256 _value, bytes calldata _data) external;

    /**
     * @notice issue new tokens and assigns them to the target _tokenHolder.
     * @dev Can only be called by the issuer or STO attached to the token.
     * @param _tokenHolders A list of addresses to whom the minted tokens will be dilivered
     * @param _values A list of number of tokens get minted and transfer to corresponding address of the investor from _tokenHolders[] list
     * return success
     */
    function issueMulti(address[] calldata _tokenHolders, uint256[] calldata _values) external;

    /**
     * @notice Increases totalSupply and the corresponding amount of the specified owners partition
     * @param _partition The partition to allocate the increase in balance
     * @param _tokenHolder The token holder whose balance should be increased
     * @param _value The amount by which to increase the balance
     * @param _data Additional data attached to the minting of tokens
     */
    function issueByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Decreases totalSupply and the corresponding amount of the specified partition of msg.sender
     * @param _partition The partition to allocate the decrease in balance
     * @param _value The amount by which to decrease the balance
     * @param _data Additional data attached to the burning of tokens
     */
    function redeemByPartition(bytes32 _partition, uint256 _value, bytes calldata _data) external;

    /**
     * @notice This function redeem an amount of the token of a msg.sender. For doing so msg.sender may incentivize
     * using different ways that could be implemented with in the `redeem` function definition. But those implementations
     * are out of the scope of the ERC1594.
     * @param _value The amount of tokens need to be redeemed
     * @param _data The `bytes _data` it can be used in the token contract to authenticate the redemption.
     */
    function redeem(uint256 _value, bytes calldata _data) external;

    /**
     * @notice This function redeem an amount of the token of a msg.sender. For doing so msg.sender may incentivize
     * using different ways that could be implemented with in the `redeem` function definition. But those implementations
     * are out of the scope of the ERC1594.
     * @dev It is analogy to `transferFrom`
     * @param _tokenHolder The account whose tokens gets redeemed.
     * @param _value The amount of tokens need to be redeemed
     * @param _data The `bytes _data` it can be used in the token contract to authenticate the redemption.
     */
    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Decreases totalSupply and the corresponding amount of the specified partition of tokenHolder
     * @dev This function can only be called by the authorised operator.
     * @param _partition The partition to allocate the decrease in balance.
     * @param _tokenHolder The token holder whose balance should be decreased
     * @param _value The amount by which to decrease the balance
     * @param _data Additional data attached to the burning of tokens
     * @param _operatorData Additional data attached to the transfer of tokens by the operator
     */
    function operatorRedeemByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external;

    /**
     * @notice Validate permissions with PermissionManager if it exists, If no Permission return false
     * @dev Note that IModule withPerm will allow ST owner all permissions anyway
     * @dev this allows individual modules to override this logic if needed (to not allow ST owner all permissions)
     * @param _delegate address of delegate
     * @param _module address of PermissionManager module
     * @param _perm the permissions
     * return success
     */
    //TODO REMOVE function checkPermission(address _delegate, address _module, bytes32 _perm) external view returns(bool hasPermission);


    /**
     * @notice Returns module list for a module type
     * @param _module Address of the module
     * return bytes32 Name
     * return address Module address
     * return address Module factory address
     * return bool Module archived
     * return uint8 Array of module types
     * return bytes32 Module label
     */
    function getModule(address _module) external view returns (bytes32 moduleName, address moduleAddress, bool isArchived, uint8[] memory moduleTypes, bytes32 moduleLabel);

    /**
     * @notice Returns module list for a module name
     * @param _name Name of the module
     * return address[] List of modules with this name
     */
    function getModulesByName(bytes32 _name) external view returns(address[] memory modules);

    /**
     * @notice Returns module list for a module type
     * @param _type Type of the module
     * return address[] List of modules with this type
     */
    function getModulesByType(uint8 _type) external view returns(address[] memory modules);

    /**
     * @notice use to return the global treasury wallet
     */
    function getTreasuryWallet() external view returns(address treasuryWallet);

    /**
     * @notice Queries totalSupply at a specified checkpoint
     * @param _checkpointId Checkpoint ID to query as of
     */
    function totalSupplyAt(uint256 _checkpointId) external view returns(uint256 supply);

    /**
     * @notice Queries balance at a specified checkpoint
     * @param _investor Investor to query balance for
     * @param _checkpointId Checkpoint ID to query as of
     */
    function balanceOfAt(address _investor, uint256 _checkpointId) external view returns(uint256 balance);

    /**
     * @notice Creates a checkpoint that can be used to query historical balances / totalSuppy
     */
    function createCheckpoint() external returns(uint256 checkpointId);

    /**
     * @notice Gets list of times that checkpoints were created
     * return List of checkpoint times
     */
    function getCheckpointTimes() external view returns(uint256[] memory checkpointTimes);

    /**
     * @notice returns an array of investors
     * NB - this length may differ from investorCount as it contains all investors that ever held tokens
     * return list of addresses
     */
    function getInvestors() external view returns(address[] memory investors);

    /**
     * @notice returns an array of investors at a given checkpoint
     * NB - this length may differ from investorCount as it contains all investors that ever held tokens
     * @param _checkpointId Checkpoint id at which investor list is to be populated
     * return list of investors
     */
    function getInvestorsAt(uint256 _checkpointId) external view returns(address[] memory investors);

    /**
     * @notice returns an array of investors with non zero balance at a given checkpoint
     * @param _checkpointId Checkpoint id at which investor list is to be populated
     * @param _start Position of investor to start iteration from
     * @param _end Position of investor to stop iteration at
     * return list of investors
     */
    function getInvestorsSubsetAt(uint256 _checkpointId, uint256 _start, uint256 _end) external view returns(address[] memory investors);

    /**
     * @notice generates subset of investors
     * NB - can be used in batches if investor list is large
     * @param _start Position of investor to start iteration from
     * @param _end Position of investor to stop iteration at
     * return list of investors
     */
    function iterateInvestors(uint256 _start, uint256 _end) external view returns(address[] memory investors);

    /**
     * @notice Gets current checkpoint ID
     * return Id
     */
    function currentCheckpointId() external view returns(uint256 checkpointId);

    /**
     * @notice Determines whether `_operator` is an operator for all partitions of `_tokenHolder`
     * @param _operator The operator to check
     * @param _tokenHolder The token holder to check
     * return Whether the `_operator` is an operator for all partitions of `_tokenHolder`
     */
    function isOperator(address _operator, address _tokenHolder) external view returns (bool isValid);

    /**
     * @notice Determines whether `_operator` is an operator for a specified partition of `_tokenHolder`
     * @param _partition The partition to check
     * @param _operator The operator to check
     * @param _tokenHolder The token holder to check
     * return Whether the `_operator` is an operator for a specified partition of `_tokenHolder`
     */
    function isOperatorForPartition(bytes32 _partition, address _operator, address _tokenHolder) external view returns (bool isValid);

    /**
     * @notice Return all partitions
     * @param _tokenHolder Whom balance need to queried
     * return List of partitions
     */
    function partitionsOf(address _tokenHolder) external view returns (bytes32[] memory partitions);

    /**
    * @notice Allows owner to change data store
    * @param _dataStore Address of the token data store
    */
    function changeDataStore(address _dataStore) external;


    /**
     * @notice Allows to change the treasury wallet address
     * @param _wallet Ethereum address of the treasury wallet
     */
    function changeTreasuryWallet(address _wallet) external;

    /**
     * @notice Allows the owner to withdraw unspent POLY stored by them on the ST or any ERC20 token.
     * @dev Owner can transfer POLY to the ST which will be used to pay for modules that require a POLY fee.
     * @param _tokenContract Address of the ERC20Basic compliance token
     * @param _value Amount of POLY to withdraw
     */
    function withdrawERC20(address _tokenContract, uint256 _value) external;

    /**
    * @notice Allows the owner to change token granularity
    * @param _granularity Granularity level of the token
    */
    function changeGranularity(uint256 _granularity) external;

    /**
     * @notice Freezes all the transfers
     */
    function freezeTransfers() external;

    /**
     * @notice Un-freezes all the transfers
     */
    function unfreezeTransfers() external;

    /**
     * @notice Permanently freeze issuance of this security token.
     * @dev It MUST NOT be possible to increase `totalSuppy` after this function is called.
     */
    function freezeIssuance(bytes calldata _signature) external;

    /**
      * @notice Attachs a module to the SecurityToken
      * @dev  E.G.: On deployment (through the STR) ST gets a TransferManager module attached to it
      * @dev to control restrictions on transfers.
      * @param _maxCost max amount of POLY willing to pay to the module.
      * @param _budget max amount of ongoing POLY willing to assign to the module.
      * @param _label custom module label.
      * @param _archived whether to add the module as an archived module
      */
    function addModuleWithLabel(
        address _module,
        uint256 _maxCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    ) external;

    /**
     * @notice Function used to attach a module to the security token
     * @dev  E.G.: On deployment (through the STR) ST gets a TransferManager module attached to it
     * @dev to control restrictions on transfers.
     * @dev You are allowed to add a new moduleType if:
     * @dev - there is no existing module of that type yet added
     * @dev - the last member of the module list is replacable
     * @param _maxCost max amount of POLY willing to pay to module. (WIP)
     * @param _budget max amount of ongoing POLY willing to assign to the module.
     * @param _archived whether to add the module as an archived module
     */
    function addModule(address _module, uint256 _maxCost, uint256 _budget, bool _archived) external;

    /**
    * @notice Removes a module attached to the SecurityToken
    * @param _module address of module to archiv
    */
    function removeModule(address _module) external;

    /**
     * @notice Used by the issuer to set the controller addresses
     * @param _controller address of the controller
     */
    function setController(address _controller) external;

    /**
     * @notice This function allows an authorised address to transfer tokens between any two token holders.
     * The transfer must still respect the balances of the token holders (so the transfer must be for at most
     * `balanceOf(_from)` tokens) and potentially also need to respect other transfer restrictions.
     * @dev This function can only be executed by the `controller` address.
     * @param _from Address The address which you want to send tokens from
     * @param _to Address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data data to validate the transfer. (It is not used in this reference implementation
     * because use of `_data` parameter is implementation specific).
     * @param _operatorData data attached to the transfer by controller to emit in event. (It is more like a reason string
     * for calling this function (aka force transfer) which provides the transparency on-chain).
     */
    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;

    /**
     * @notice This function allows an authorised address to redeem tokens for any token holder.
     * The redemption must still respect the balances of the token holder (so the redemption must be for at most
     * `balanceOf(_tokenHolder)` tokens) and potentially also need to respect other transfer restrictions.
     * @dev This function can only be executed by the `controller` address.
     * @param _tokenHolder The account whose tokens will be redeemed.
     * @param _value uint256 the amount of tokens need to be redeemed.
     * @param _data data to validate the transfer. (It is not used in this reference implementation
     * because use of `_data` parameter is implementation specific).
     * @param _operatorData data attached to the transfer by controller to emit in event. (It is more like a reason string
     * for calling this function (aka force transfer) which provides the transparency on-chain).
     */
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;

    /**
     * @notice Used by the issuer to permanently disable controller functionality
     * @dev enabled via feature switch "disableControllerAllowed"
     */
    function disableController(bytes calldata _signature) external;

    /**
     * @notice Used to get the version of the securityToken
     */
    function getVersion() external view returns(uint8[] memory version);

    /**
     * @notice Gets the investor count
     */
    function getInvestorCount() external view returns(uint256 investorCount);

    /**
     * @notice Gets the holder count (investors with non zero balance)
     */
    function holderCount() external view returns(uint256 count);

    /**
      * @notice Overloaded version of the transfer function
      * @param _to receiver of transfer
      * @param _value value of transfer
      * @param _data data to indicate validation
      * return bool success
      */
    function transferWithData(address _to, uint256 _value, bytes calldata _data) external;

    /**
      * @notice Overloaded version of the transferFrom function
      * @param _from sender of transfer
      * @param _to receiver of transfer
      * @param _value value of transfer
      * @param _data data to indicate validation
      * return bool success
      */
    function transferFromWithData(address _from, address _to, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Transfers the ownership of tokens from a specified partition from one address to another address
     * @param _partition The partition from which to transfer tokens
     * @param _to The address to which to transfer tokens to
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * return The partition to which the transferred tokens were allocated for the _to address
     */
    function transferByPartition(bytes32 _partition, address _to, uint256 _value, bytes calldata _data) external returns (bytes32 partition);

    /**
     * @notice Get the balance according to the provided partitions
     * @param _partition Partition which differentiate the tokens.
     * @param _tokenHolder Whom balance need to queried
     * return Amount of tokens as per the given partitions
     */
    function balanceOfByPartition(bytes32 _partition, address _tokenHolder) external view returns(uint256 balance);

    /**
    * @notice Upgrades a module attached to the SecurityToken
    * @param _module address of module to archive
    */
    function upgradeModule(address _module) external;

    /**
    * @notice Upgrades security token
    */

    /**
     * @notice A security token issuer can specify that issuance has finished for the token
     * (i.e. no new tokens can be minted or issued).
     * @dev If a token returns FALSE for `isIssuable()` then it MUST always return FALSE in the future.
     * If a token returns FALSE for `isIssuable()` then it MUST never allow additional tokens to be issued.
     * return bool `true` signifies the minting is allowed. While `false` denotes the end of minting
     */
    function isIssuable() external view returns (bool issuable);

    /**
     * @notice Authorises an operator for all partitions of `msg.sender`.
     * NB - Allowing investors to authorize an investor to be an operator of all partitions
     * but it doesn't mean we operator is allowed to transfer the LOCKED partition values.
     * Logic for this restriction is written in `operatorTransferByPartition()` function.
     * @param _operator An address which is being authorised.
     */
    function authorizeOperator(address _operator) external;

    /**
     * @notice Revokes authorisation of an operator previously given for all partitions of `msg.sender`.
     * NB - Allowing investors to authorize an investor to be an operator of all partitions
     * but it doesn't mean we operator is allowed to transfer the LOCKED partition values.
     * Logic for this restriction is written in `operatorTransferByPartition()` function.
     * @param _operator An address which is being de-authorised
     */
    function revokeOperator(address _operator) external;

    /**
     * @notice Authorises an operator for a given partition of `msg.sender`
     * @param _partition The partition to which the operator is authorised
     * @param _operator An address which is being authorised
     */
    function authorizeOperatorByPartition(bytes32 _partition, address _operator) external;

    /**
     * @notice Revokes authorisation of an operator previously given for a specified partition of `msg.sender`
     * @param _partition The partition to which the operator is de-authorised
     * @param _operator An address which is being de-authorised
     */
    function revokeOperatorByPartition(bytes32 _partition, address _operator) external;

    /**
     * @notice Transfers the ownership of tokens from a specified partition from one address to another address
     * @param _partition The partition from which to transfer tokens.
     * @param _from The address from which to transfer tokens from
     * @param _to The address to which to transfer tokens to
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * @param _operatorData Additional data attached to the transfer of tokens by the operator
     * return The partition to which the transferred tokens were allocated for the _to address
     */
    function operatorTransferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    )
    external
    returns (bytes32 partition);

    /*
    * @notice Returns if transfers are currently frozen or not
    */
    function getTransfersFrozen() external view returns (bool isFrozen);

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external;

    /**
     * return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() external view returns (bool);

    /**
     * return the address of the owner.
     */
    function owner() external view returns (address ownerAddress);


    //TODO I give up to have these functions explicitly. Variable dataStore exists as the type of ISecutityToken...
    function dataStore() external view returns (address _dataStore);
    function granularity() external view returns (uint256 _granularity);
    function registry() external view returns (address _registry);
}

contract ModuleStorage {
    address public factory;

    ISecurityToken public securityToken;

    // Permission flag
    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant OPERATOR = "OPERATOR";

    bytes32 internal constant TREASURY = 0xaae8817359f3dcb67d050f44f3e49f982e0359d90ca4b5f18569926304aaece6; // keccak256(abi.encodePacked("TREASURY_WALLET"))

    IERC20 public payToken;

    /**
     * @notice Constructor
     * @param _securityToken Address of the security token
     * @param _payTokenAddress Address of the paytoken
     */
    constructor(address _securityToken, address _payTokenAddress) {
        securityToken = ISecurityToken(_securityToken);
        factory = msg.sender;
        payToken = IERC20(_payTokenAddress);
    }

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Module is IModule, ModuleStorage, Pausable {
    /**
     * @notice Constructor
     * @param _securityToken Address of the security token
     */
    constructor (address _securityToken, address _payToken)
    ModuleStorage(_securityToken, _payToken)
    {
    }

    /**
     * @notice This function returns the signature of configure function
     */
    function getInitFunction() external pure virtual override returns(bytes4 initFunction) {
        return bytes4(0); // TODO, Temp
    }


    function getTypes() external view virtual override returns(uint8 [] memory) {
        //Will be overloaded.
        //TODO NOW
        uint8[] memory temp;
        return temp;
    }

    function getName() external view virtual override returns(bytes32) {
        //Will be overloaded.
        //TODO NOW
        bytes32 temp;
        return temp;
    }

    /**
     * @notice Return the permission flags that are associated with a module
     */
    function getPermissions() external view virtual override returns(bytes32[] memory permissions) {
        // return 0; // TODO block.timestamp
        bytes32[] memory temp;
        return temp;
    }

    //Allows owner, factory or permissioned delegate
    modifier withPerm(bytes32 _perm) {
        require(_checkPerm(_perm, msg.sender), "Invalid permission");
        _;
    }

    function _checkPerm(bytes32 _perm, address _caller) internal view returns (bool) {
        bool isOwner = _caller == Ownable(address(securityToken)).owner();
        bool isFactory = _caller == factory;
        return isOwner || isFactory || ICheckPermission(address(securityToken)).checkPermission(_caller, address(this), _perm);
    }

    function _onlySecurityTokenOwner() internal view {
        require(msg.sender == Ownable(address(securityToken)).owner(), "Sender is not owner");
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Sender is not factory");
        _;
    }

    /**
     * @notice Pause (overridden function)
     */
    function pause() public virtual override {
        _onlySecurityTokenOwner();
        //TODO super._pause();
        super.pause();
    }

    /**
     * @notice Unpause (overridden function)
     */
    function unpause() public override {
        _onlySecurityTokenOwner();
        //super._unpause();
        super.unpause();
    }

    /**
     * @notice used to return the data store address of securityToken
     */
    function getDataStore() public view returns(IDataStore) {
        return IDataStore(securityToken.dataStore());
    }

    /**
    * @notice Reclaims ERC20Basic compatible tokens
    * @dev We duplicate here due to the overriden owner & onlyOwner
    * @param _tokenContract The address of the token contract
    */
    function reclaimERC20(address _tokenContract) external {
        _onlySecurityTokenOwner();
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance), "Transfer failed");
    }

    /**
     * @notice Reclaims ETH
     * @dev We duplicate here due to the overriden owner & onlyOwner
     */
    function reclaimETH() external {
        _onlySecurityTokenOwner();
        payable(msg.sender).transfer(address(this).balance);
    }
}

contract STOStorage {
    bytes32 internal constant INVESTORFLAGS = "INVESTORFLAGS";

    mapping (uint8 => bool) public fundRaiseTypes;
    mapping (uint8 => uint256) public fundsRaised;

    // Start time of the STO
    uint256 public startTime;
    // End time of the STO
    uint256 public endTime;
    // Time STO was paused
    uint256 public pausedTime;
    // Number of individual investors
    uint256 public investorCount;
    // Address where ETH & POLY funds are delivered
    address payable public wallet;
    // Final amount of tokens sold
    uint256 public totalTokensSold;

}

interface ISTO {

    enum FundRaiseType {ETH, PAY, SC}

    // Event
    event SetFundRaiseTypes(FundRaiseType[] _fundRaiseTypes);

    /**
     * @notice Returns the total no. of tokens sold
     */
    function getTokensSold() external view returns(uint256 soldTokens);

    /**
     * @notice Returns funds raised by the STO
     */
    function getRaised(FundRaiseType _fundRaiseType) external view returns(uint256 raisedAmount);

    /**
     * @notice Pause (overridden function)
     * @dev Only securityToken owner restriction applied on the super function
     */
    function pause() external;

}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

contract STO is /*ISTO,*/ STOStorage, Module {

    enum FundRaiseType {ETH, PAY, SC}

    event SetFundRaiseTypes(FundRaiseType[] _fundRaiseTypes);

    using SafeMath for uint256;

    constructor (address _securityToken, address _payToken)
    Module(_securityToken, _payToken)
    {
    }

    /**
     * @notice Returns funds raised by the STO
     */
    function getRaised(FundRaiseType _fundRaiseType) external view returns(uint256) {
        return fundsRaised[uint8(_fundRaiseType)];
    }

    /**
     * @notice Returns the total no. of tokens sold
     */
    function getTokensSold() external view virtual returns(uint256) {
        return uint256(0); // TODO, Temp
    }

    /**
     * @notice Pause (overridden function)
     * @dev Only securityToken owner restriction applied on the super function
     */
    function pause() public override {
        /*solium-disable-next-line security/no-block-members*/
        require(block.timestamp < endTime, "STO has been finalized");
        super.pause();
    }

    function _setFundRaiseType(FundRaiseType[] memory _fundRaiseTypes) internal {
        // FundRaiseType[] parameter type ensures only valid values for _fundRaiseTypes
        require(_fundRaiseTypes.length > 0 && _fundRaiseTypes.length <= 3, "Raise type is not specified properly");
        fundRaiseTypes[uint8(FundRaiseType.ETH)] = false;
        fundRaiseTypes[uint8(FundRaiseType.PAY)] = false;
        fundRaiseTypes[uint8(FundRaiseType.SC)] = false;
        for (uint8 j = 0; j < _fundRaiseTypes.length; j++) {
            fundRaiseTypes[uint8(_fundRaiseTypes[j])] = true;
        }
        emit SetFundRaiseTypes(_fundRaiseTypes);
    }

    function _canBuy(address _investor) internal view returns(bool) {
        IDataStore dataStore = getDataStore();
        uint256 flags = dataStore.getUint256(_getKey(INVESTORFLAGS, _investor));
        return(flags & (uint256(1) << 1) == 0);
    }


    function _getKey(bytes32 _key1, address _key2) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }


    // function _canRefund(address _investor) internal view returns(bool) {
    //     IDataStore dataStore = getDataStore();
    //     uint256 flags = dataStore.getUint256(_getKey(INVESTORFLAGS, _investor));
    //     return(flags & (uint256(1) << 1) == 0);
    // }
}

interface IRegistry {

    event ChangeAddress(string _nameKey, address indexed _oldAddress, address indexed _newAddress);

    /**
     * @notice Returns the contract address
     * @param _nameKey is the key for the contract address mapping
     * return address
     */
    function getAddress(string calldata _nameKey) external view returns(address registryAddress);

    /**
     * @notice Changes the contract address
     * @param _nameKey is the key for the contract address mapping
     * @param _newAddress is the new contract address
     */
    function changeAddress(string calldata _nameKey, address _newAddress) external;

}

interface IOracle {
    /**
    * @notice Returns address of oracle currency (0x0 for ETH)
    */
    function getCurrencyAddress() external view returns(address currency);

    /**
    * @notice Returns symbol of oracle currency (0x0 for ETH)
    */
    function getCurrencySymbol() external view returns(bytes32 symbol);

    /**
    * @notice Returns denomination of price
    */
    function getCurrencyDenominated() external view returns(bytes32 denominatedCurrency);

    /**
    * @notice Returns price - should throw if not valid
    */
    function getPrice() external returns(uint256 price);

}

library DecimalMath {
    using SafeMath for uint256;

    uint256 internal constant e18 = uint256(10) ** uint256(18);

    /**
     * @notice This function multiplies two decimals represented as (decimal * 10**DECIMALS)
     * return uint256 Result of multiplication represented as (decimal * 10**DECIMALS)
     */
    function mul(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, y), (e18) / 2) / (e18);
    }

    /**
     * @notice This function divides two decimals represented as (decimal * 10**DECIMALS)
     * return uint256 Result of division represented as (decimal * 10**DECIMALS)
     */
    function div(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, (e18)), y / 2) / y;
    }

}

contract USDTieredSTOStorage {

    bytes32 internal constant INVESTORSKEY = 0xdf3a8dd24acdd05addfc6aeffef7574d2de3f844535ec91e8e0f3e45dba96731; //keccak256(abi.encodePacked("INVESTORS"))

    /////////////
    // Storage //
    /////////////
    struct Tier {
        // NB rates mentioned below are actually price and are used like price in the logic.
        // How many token units a buyer gets per USD in this tier (multiplied by 10**18)
        uint256 rate;
        // How many token units a buyer gets per USD in this tier (multiplied by 10**18) when investing in POLY up to tokensDiscountPayToken
        uint256 rateDiscountPayToken;
        // How many tokens are available in this tier (relative to totalSupply)
        uint256 tokenTotal;
        // How many token units are available in this tier (relative to totalSupply) at the ratePerTierDiscountPayToken rate
        uint256 tokensDiscountPayToken;
        // How many tokens have been minted in this tier (relative to totalSupply)
        uint256 mintedTotal;
        // How many tokens have been minted in this tier (relative to totalSupply) for each fund raise type
        mapping(uint8 => uint256) minted;
        // How many tokens have been minted in this tier (relative to totalSupply) at discounted POLY rate
        uint256 mintedDiscountPayToken;
    }

    mapping(address => uint256) public nonAccreditedLimitUSDOverride;

    mapping(bytes32 => mapping(bytes32 => string)) oracleKeys;

    // Determine whether users can invest on behalf of a beneficiary
    bool public allowBeneficialInvestments;

    // Whether or not the STO has been finalized
    bool public isFinalized;

    // Address of issuer treasury wallet for unsold tokens
    address public treasuryWallet;

    // List of stable coin addresses
    IERC20[] internal usdTokens;

    // Current tier
    uint256 public currentTier;

    // Amount of USD funds raised
    uint256 public fundsRaisedUSD;

    // Amount of stable coins raised
    mapping (address => uint256) public stableCoinsRaised;

    // Amount in USD invested by each address
    mapping(address => uint256) public investorInvestedUSD;

    // Amount in fund raise type invested by each investor
    mapping(address => mapping(uint8 => uint256)) public investorInvested;

    // List of active stable coin addresses
    mapping (address => bool) internal usdTokenEnabled;

    // Default limit in USD for non-accredited investors multiplied by 10**18
    uint256 public nonAccreditedLimitUSD;

    // Minimum investable amount in USD
    uint256 public minimumInvestmentUSD;

    // Final amount of tokens returned to issuer
    uint256 public finalAmountReturned;

    // Array of Tiers
    Tier[] public tiers;

    // Optional custom Oracles.
    mapping(bytes32 => mapping(bytes32 => address)) customOracles;
}

contract USDTieredSTO is USDTieredSTOStorage, STO {
//contract USDTieredSTO is USDTieredSTOStorage {

    using SafeMath for uint256;

    string internal constant POLY_ORACLE = "PolyUsdOracle";
    string internal constant ETH_ORACLE = "EthUsdOracle";

    ////////////
    // Events //
    ////////////

    event SetAllowBeneficialInvestments(bool _allowed);
    event SetNonAccreditedLimit(address _investor, uint256 _limit);
    event TokenPurchase(
        address indexed _purchaser,
        address indexed _beneficiary,
        uint256 _tokens,
        uint256 _usdAmount,
        uint256 _tierPrice,
        uint256 _tier
    );
    event FundsReceived(
        address indexed _purchaser,
        address indexed _beneficiary,
        uint256 _usdAmount,
        FundRaiseType _fundRaiseType,
        uint256 _receivedValue,
        uint256 _spentValue,
        uint256 _rate
    );
    event ReserveTokenMint(address indexed _owner, address indexed _wallet, uint256 _tokens, uint256 _latestTier);
    event SetAddresses(address indexed _wallet, IERC20[] _usdTokens);
    event SetLimits(uint256 _nonAccreditedLimitUSD, uint256 _minimumInvestmentUSD);
    event SetTimes(uint256 _startTime, uint256 _endTime);
    event SetTiers(
        uint256[] _ratePerTier,
        uint256[] _ratePerTierDiscountPayToken,
        uint256[] _tokensPerTierTotal,
        uint256[] _tokensPerTierDiscountPayToken
    );
    event SetTreasuryWallet(address _oldWallet, address _newWallet);

    ///////////////
    // Modifiers //
    ///////////////

    modifier validETH() {
        require(_getOracle(bytes32("ETH"), bytes32("USD")) != address(0), "Invalid Oracle");
        require(fundRaiseTypes[uint8(FundRaiseType.ETH)], "ETH not allowed");
        _;
    }

    modifier validPOLY() {
        require(_getOracle(bytes32("POLY"), bytes32("USD")) != address(0), "Invalid Oracle");
        require(fundRaiseTypes[uint8(FundRaiseType.PAY)], "POLY not allowed");
        _;
    }

    modifier validSC(address _usdToken) {
        require(fundRaiseTypes[uint8(FundRaiseType.SC)] && usdTokenEnabled[_usdToken], "USD not allowed");
        _;
    }

    ///////////////////////
    // STO Configuration //
    ///////////////////////

    constructor(address _securityToken, address _payToken) STO(_securityToken, _payToken) {
    
    }

    /**
     * @notice Function used to intialize the contract variables
     * @param _startTime Unix timestamp at which offering get started
     * @param _endTime Unix timestamp at which offering get ended
     * @param _ratePerTier Rate (in USD) per tier (* 10**18)
     * @param _tokensPerTierTotal Tokens available in each tier
     * @param _nonAccreditedLimitUSD Limit in USD (* 10**18) for non-accredited investors
     * @param _minimumInvestmentUSD Minimun investment in USD (* 10**18)
     * @param _fundRaiseTypes Types of currency used to collect the funds
     * @param _wallet Ethereum account address to hold the funds
     * @param _treasuryWallet Ethereum account address to receive unsold tokens
     * @param _usdTokens Contract address of the stable coins
     */
    function configure(
        uint256 _startTime,
        uint256 _endTime,
        uint256[] memory _ratePerTier,
        uint256[] memory _ratePerTierDiscountPayToken,
        uint256[] memory _tokensPerTierTotal,
        uint256[] memory _tokensPerTierDiscountPayToken,
        uint256 _nonAccreditedLimitUSD,
        uint256 _minimumInvestmentUSD,
        FundRaiseType[] memory _fundRaiseTypes, // enum FundRaiseType {ETH, POLY, SC}. SC for stable coin.
        address payable _wallet,
        address _treasuryWallet,
        IERC20[] memory _usdTokens              // stable coins acceptable. No payToken.
    )
        public
        onlyFactory
    {
        oracleKeys[bytes32("ETH")][bytes32("USD")] = ETH_ORACLE;
        oracleKeys[bytes32("POLY")][bytes32("USD")] = POLY_ORACLE;
        require(endTime == 0, "Already configured");
        _modifyTimes(_startTime, _endTime);
        _modifyTiers(_ratePerTier, _ratePerTierDiscountPayToken, _tokensPerTierTotal, _tokensPerTierDiscountPayToken);
        // NB - _setFundRaiseType must come before modifyAddresses
        _setFundRaiseType(_fundRaiseTypes);
        _modifyAddresses(_wallet, _treasuryWallet, _usdTokens);
        _modifyLimits(_nonAccreditedLimitUSD, _minimumInvestmentUSD);
    }

    

    function getTypes() external pure override returns(uint8 [] memory) {
        //TODO NOW
        uint8[] memory temp;
        return temp;
    }

    function getName() external pure override returns(bytes32) {
        //TODO NOW
        bytes32 temp;
        return temp;
    }

    /**
     * @dev Modifies fund raise types
     * @param _fundRaiseTypes Array of fund raise types to allow
     */
    function modifyFunding(FundRaiseType[] calldata _fundRaiseTypes) external withPerm(OPERATOR) {
        _isSTOStarted();
        _setFundRaiseType(_fundRaiseTypes);
    }

    /**
     * @dev modifies max non accredited invets limit and overall minimum investment limit
     * @param _nonAccreditedLimitUSD max non accredited invets limit
     * @param _minimumInvestmentUSD overall minimum investment limit
     */
    function modifyLimits(uint256 _nonAccreditedLimitUSD, uint256 _minimumInvestmentUSD) external withPerm(OPERATOR) {
        _isSTOStarted();
        _modifyLimits(_nonAccreditedLimitUSD, _minimumInvestmentUSD);
    }

    /**
     * @dev modifiers STO tiers. All tiers must be passed, can not edit specific tiers.
     * @param _ratePerTier Array of rates per tier
     * @param _ratePerTierDiscountPayToken Array of discounted poly rates per tier
     * @param _tokensPerTierTotal Array of total tokens per tier
     * @param _tokensPerTierDiscountPayToken Array of discounted tokens per tier
     */
    function modifyTiers(
        uint256[] calldata _ratePerTier,
        uint256[] calldata _ratePerTierDiscountPayToken,
        uint256[] calldata _tokensPerTierTotal,
        uint256[] calldata _tokensPerTierDiscountPayToken
    )
        external
        withPerm(OPERATOR)
    {
        _isSTOStarted();
        _modifyTiers(_ratePerTier, _ratePerTierDiscountPayToken, _tokensPerTierTotal, _tokensPerTierDiscountPayToken);
    }

    /**
     * @dev Modifies STO start and end times
     * @param _startTime start time of sto
     * @param _endTime end time of sto
     */
    function modifyTimes(uint256 _startTime, uint256 _endTime) external withPerm(OPERATOR) {
        _isSTOStarted();
        _modifyTimes(_startTime, _endTime);
    }

    function _isSTOStarted() internal view {
        /*solium-disable-next-line security/no-block-members*/
        require(block.timestamp < startTime, "Already started");
    }


    /**
     * @dev Modifies Oracle address.
     *      By default, Polymath oracles are used but issuer can overide them using this function
     *      Set _oracleAddress to 0x0 to fallback to using Polymath oracles
     * @param _fundRaiseType Actual currency
     * @param _oracleAddress address of the oracle
     */
    function modifyOracle(FundRaiseType _fundRaiseType, address _oracleAddress) external {
        _onlySecurityTokenOwner();
        if (_fundRaiseType == FundRaiseType.ETH) {
            customOracles[bytes32("ETH")][bytes32("USD")] = _oracleAddress;
        } else {
            require(_fundRaiseType == FundRaiseType.PAY, "Invalid currency");
            customOracles[bytes32("POLY")][bytes32("USD")] = _oracleAddress;
        }
    }

    function _modifyLimits(uint256 _nonAccreditedLimitUSD, uint256 _minimumInvestmentUSD) internal {
        minimumInvestmentUSD = _minimumInvestmentUSD;
        nonAccreditedLimitUSD = _nonAccreditedLimitUSD;
        emit SetLimits(minimumInvestmentUSD, nonAccreditedLimitUSD);
    }

    function _modifyTiers(
        uint256[] memory _ratePerTier,
        uint256[] memory _ratePerTierDiscountPayToken,
        uint256[] memory _tokensPerTierTotal,
        uint256[] memory _tokensPerTierDiscountPayToken
    )
        internal
    {
        require(
            _tokensPerTierTotal.length > 0 &&
            _ratePerTier.length == _tokensPerTierTotal.length &&
            _ratePerTierDiscountPayToken.length == _tokensPerTierTotal.length &&
            _tokensPerTierDiscountPayToken.length == _tokensPerTierTotal.length,
            "Invalid Input"
        );
        delete tiers;
        for (uint256 i = 0; i < _ratePerTier.length; i++) {
            require(_ratePerTier[i] > 0 && _tokensPerTierTotal[i] > 0, "Invalid value");
            require(_tokensPerTierDiscountPayToken[i] <= _tokensPerTierTotal[i], "Too many discounted tokens");
            require(_ratePerTierDiscountPayToken[i] <= _ratePerTier[i], "Invalid discount");
//            tiers.push(Tier(_ratePerTier[i], _ratePerTierDiscountPayToken[i], _tokensPerTierTotal[i], _tokensPerTierDiscountPayToken[i], 0, 0));
            Tier storage newTier =  tiers.push();
            newTier.rate = _ratePerTier[i];
            newTier.rateDiscountPayToken = _ratePerTierDiscountPayToken[i];
            newTier.tokenTotal = _tokensPerTierTotal[i];
            newTier.tokensDiscountPayToken = _tokensPerTierDiscountPayToken[i];
            newTier.mintedTotal = 0;
            newTier.mintedDiscountPayToken = 0;
        }
        emit SetTiers(_ratePerTier, _ratePerTierDiscountPayToken, _tokensPerTierTotal, _tokensPerTierDiscountPayToken);
    }

    function _modifyTimes(uint256 _startTime, uint256 _endTime) internal {
        /*solium-disable-next-line security/no-block-members*/
        require((_endTime > _startTime) && (_startTime > block.timestamp), "Invalid times");
        startTime = _startTime;
        endTime = _endTime;
        emit SetTimes(_startTime, _endTime);
    }

    /**
     * @dev Modifies addresses used as wallet, reserve wallet and usd token
     * @param _wallet Address of wallet where funds are sent
     * @param _treasuryWallet Address of wallet where unsold tokens are sent
     * @param _usdTokens Address of usd tokens
     */
    function modifyAddresses(address payable _wallet, address _treasuryWallet, IERC20[] calldata _usdTokens) external {
        _onlySecurityTokenOwner();
        _modifyAddresses(_wallet, _treasuryWallet, _usdTokens);
    }

    function _modifyAddresses(address payable _wallet, address _treasuryWallet, IERC20[] memory _usdTokens) internal {
        require(_wallet != address(0), "Invalid wallet");
        wallet = _wallet;
        emit SetTreasuryWallet(treasuryWallet, _treasuryWallet);
        treasuryWallet = _treasuryWallet;
        _modifyUSDTokens(_usdTokens);
    }

    function _modifyUSDTokens(IERC20[] memory _usdTokens) internal {
        uint256 i;
        for(i = 0; i < usdTokens.length; i++) {
            usdTokenEnabled[address(usdTokens[i])] = false;
        }
        usdTokens = _usdTokens;
        for(i = 0; i < _usdTokens.length; i++) {
            require(address(_usdTokens[i]) != address(0) && _usdTokens[i] != payToken, "Invalid USD token");
            usdTokenEnabled[address(_usdTokens[i])] = true;
        }
        emit SetAddresses(wallet, _usdTokens);
    }

    ////////////////////
    // STO Management //
    ////////////////////

    /**
     * @notice Finalizes the STO and mint remaining tokens to treasury address
     * @notice Treasury wallet address must be whitelisted to successfully finalize
     */
    function finalize() external withPerm(ADMIN) {
        require(!isFinalized, "STO is finalized");
        isFinalized = true;
        uint256 tempReturned;
        uint256 tempSold;
        uint256 remainingTokens;
        for (uint256 i = 0; i < tiers.length; i++) {
            remainingTokens = tiers[i].tokenTotal.sub(tiers[i].mintedTotal);
            tempReturned = tempReturned.add(remainingTokens);
            tempSold = tempSold.add(tiers[i].mintedTotal);
            if (remainingTokens > 0) {
                tiers[i].mintedTotal = tiers[i].tokenTotal;
            }
        }
        address walletAddress = (treasuryWallet == address(0) ? IDataStore(getDataStore()).getAddress(TREASURY) : treasuryWallet);
        require(walletAddress != address(0), "Invalid address");
        uint256 granularity = securityToken.granularity();
        tempReturned = tempReturned.div(granularity);
        tempReturned = tempReturned.mul(granularity);
        securityToken.issue(walletAddress, tempReturned, "");
        emit ReserveTokenMint(msg.sender, walletAddress, tempReturned, currentTier);
        finalAmountReturned = tempReturned;
        totalTokensSold = tempSold;
    }

    /**
     * @notice Modifies the list of overrides for non-accredited limits in USD
     * @param _investors Array of investor addresses to modify
     * @param _nonAccreditedLimit Array of uints specifying non-accredited limits
     */
    function changeNonAccreditedLimit(address[] calldata _investors, uint256[] calldata _nonAccreditedLimit) external withPerm(OPERATOR) {
        //nonAccreditedLimitUSDOverride
        require(_investors.length == _nonAccreditedLimit.length, "Length mismatch");
        for (uint256 i = 0; i < _investors.length; i++) {
            nonAccreditedLimitUSDOverride[_investors[i]] = _nonAccreditedLimit[i];
            emit SetNonAccreditedLimit(_investors[i], _nonAccreditedLimit[i]);
        }
    }

    /**
     * @notice Returns investor accredited & non-accredited override informatiomn
     * return investors list of all configured investors
     * return accredited whether investor is accredited
     * return override any USD overrides for non-accredited limits for the investor
     */
    function getAccreditedData() external view returns (address[] memory investors, bool[] memory accredited, uint256[] memory overrides) {
        IDataStore dataStore = getDataStore();
        investors = dataStore.getAddressArray(INVESTORSKEY);
        accredited = new bool[](investors.length);
        overrides = new uint256[](investors.length);
        for (uint256 i = 0; i < investors.length; i++) {
            accredited[i] = _getIsAccredited(investors[i], dataStore);
            overrides[i] = nonAccreditedLimitUSDOverride[investors[i]];
        }
    }

    /**
     * @notice Function to set allowBeneficialInvestments (allow beneficiary to be different to funder)
     * @param _allowBeneficialInvestments Boolean to allow or disallow beneficial investments
     */
    function changeAllowBeneficialInvestments(bool _allowBeneficialInvestments) external withPerm(OPERATOR) {
        require(_allowBeneficialInvestments != allowBeneficialInvestments);
        allowBeneficialInvestments = _allowBeneficialInvestments;
        emit SetAllowBeneficialInvestments(allowBeneficialInvestments);
    }

    //////////////////////////
    // Investment Functions //
    //////////////////////////

    /**
    * @notice fallback function - assumes ETH being invested
    */
    receive() external payable {
        buyWithETHRateLimited(msg.sender, 0);
    }

    // Buy functions without rate restriction
    function buyWithETH(address _beneficiary) external payable returns (uint256, uint256, uint256) {
        return buyWithETHRateLimited(_beneficiary, 0);
    }

    function buyWithPOLY(address _beneficiary, uint256 _investedPOLY) external returns (uint256, uint256, uint256) {
        return buyWithPOLYRateLimited(_beneficiary, _investedPOLY, 0);
    }

    function buyWithUSD(address _beneficiary, uint256 _investedSC, IERC20 _usdToken) external returns (uint256, uint256, uint256) {
        return buyWithUSDRateLimited(_beneficiary, _investedSC, 0, _usdToken);
    }

    /**
      * @notice Purchase tokens using ETH
      * @param _beneficiary Address where security tokens will be sent
      * @param _minTokens Minumum number of tokens to buy or else revert
      */
    function buyWithETHRateLimited(address _beneficiary, uint256 _minTokens) public payable validETH returns (uint256, uint256, uint256) {
        (uint256 rate, uint256 spentUSD, uint256 spentValue, uint256 initialMinted) = _getSpentvalues(_beneficiary,  msg.value, FundRaiseType.ETH, _minTokens);
        // TODO. spentUSD has been recorded by this call. spentValue not. They should have been be recorded at the same place at the same time.

        // Modify storage
        investorInvested[_beneficiary][uint8(FundRaiseType.ETH)] = investorInvested[_beneficiary][uint8(FundRaiseType.ETH)].add(spentValue);
        fundsRaised[uint8(FundRaiseType.ETH)] = fundsRaised[uint8(FundRaiseType.ETH)].add(spentValue);
        // Forward ETH to issuer wallet
        wallet.transfer(spentValue);
        // Refund excess ETH to investor wallet
        payable(msg.sender).transfer(msg.value.sub(spentValue));
        emit FundsReceived(msg.sender, _beneficiary, spentUSD, FundRaiseType.ETH, msg.value, spentValue, rate);
        return (spentUSD, spentValue, getTokensMinted().sub(initialMinted));
    }

    /**
      * @notice Purchase tokens using POLY
      * @param _beneficiary Address where security tokens will be sent
      * @param _investedPOLY Amount of POLY invested
      * @param _minTokens Minumum number of tokens to buy or else revert
      */
    function buyWithPOLYRateLimited(address _beneficiary, uint256 _investedPOLY, uint256 _minTokens) public validPOLY returns (uint256, uint256, uint256) {
        return _buyWithTokens(_beneficiary, _investedPOLY, FundRaiseType.PAY, _minTokens, payToken);
    }

    /**
      * @notice Purchase tokens using Stable coins
      * @param _beneficiary Address where security tokens will be sent
      * @param _investedSC Amount of Stable coins invested
      * @param _minTokens Minumum number of tokens to buy or else revert
      * @param _usdToken Address of USD stable coin to buy tokens with
      */
    function buyWithUSDRateLimited(address _beneficiary, uint256 _investedSC, uint256 _minTokens, IERC20 _usdToken)
        public validSC(address(_usdToken)) returns (uint256, uint256, uint256)
    {
        return _buyWithTokens(_beneficiary, _investedSC, FundRaiseType.SC, _minTokens, _usdToken);
    }

    function _buyWithTokens(address _beneficiary, uint256 _tokenAmount, FundRaiseType _fundRaiseType, uint256 _minTokens, IERC20 _token) internal returns (uint256, uint256, uint256) {
        (uint256 rate, uint256 spentUSD, uint256 spentValue, uint256 initialMinted) = _getSpentvalues(_beneficiary, _tokenAmount, _fundRaiseType, _minTokens);
        // TODO. spentUSD has been recorded by this call. spentValue not. They should have been be recorded at the same place at the same time.

        // Modify storage
        investorInvested[_beneficiary][uint8(_fundRaiseType)] = investorInvested[_beneficiary][uint8(_fundRaiseType)].add(spentValue);
        fundsRaised[uint8(_fundRaiseType)] = fundsRaised[uint8(_fundRaiseType)].add(spentValue);
        if(address(_token) != address(payToken))
            stableCoinsRaised[address(_token)] = stableCoinsRaised[address(_token)].add(spentValue);
        // Forward coins to issuer wallet
        require(_token.transferFrom(msg.sender, wallet, spentValue), "Transfer failed");
        emit FundsReceived(msg.sender, _beneficiary, spentUSD, _fundRaiseType, _tokenAmount, spentValue, rate);
        return (spentUSD, spentValue, getTokensMinted().sub(initialMinted));
    }

    function _getSpentvalues(address _beneficiary, uint256 _amount, FundRaiseType _fundRaiseType, uint256 _minTokens) internal returns(uint256 rate, uint256 spentUSD, uint256 spentValue, uint256 initialMinted) {
        initialMinted = getTokensMinted();
        rate = getRate(_fundRaiseType);
        (spentUSD, spentValue) = _buyTokens(_beneficiary, _amount, rate, _fundRaiseType);
        require(getTokensMinted().sub(initialMinted) >= _minTokens, "Insufficient minted");
    }


    /**
      * @notice Low level token purchase
      * @param _beneficiary Address where security tokens will be sent
      * @param _investmentValue Amount of POLY, ETH or Stable coins invested
      * @param _fundRaiseType Fund raise type (POLY, ETH, SC)
      */
    function _buyTokens(
        address _beneficiary,
        uint256 _investmentValue,
        uint256 _rate,
        FundRaiseType _fundRaiseType
    )
        internal
        whenNotPaused
        returns(uint256 spentUSD, uint256 spentValue)
    {
        if (!allowBeneficialInvestments) {
            require(_beneficiary == msg.sender, "Beneficiary != funder");
        }

        require(_canBuy(_beneficiary), "Unauthorized");

        uint256 originalUSD = DecimalMath.mul(_rate, _investmentValue);
        uint256 allowedUSD = _buyTokensChecks(_beneficiary, _investmentValue, originalUSD);

        for (uint256 i = currentTier; i < tiers.length; i++) {
            bool gotoNextTier;
            uint256 tempSpentUSD;
            // Update current tier if needed
            if (currentTier != i)
                currentTier = i;
            // If there are tokens remaining, process investment
            if (tiers[i].mintedTotal < tiers[i].tokenTotal) {
                (tempSpentUSD, gotoNextTier) = _calculateTier(_beneficiary, i, allowedUSD.sub(spentUSD), _fundRaiseType);
                spentUSD = spentUSD.add(tempSpentUSD);
                // If all funds have been spent, exit the loop
                if (!gotoNextTier)
                    break;
            }
        }

        // Modify storage
        if (spentUSD > 0) {
            if (investorInvestedUSD[_beneficiary] == 0)
                investorCount = investorCount + 1;
            investorInvestedUSD[_beneficiary] = investorInvestedUSD[_beneficiary].add(spentUSD);
            fundsRaisedUSD = fundsRaisedUSD.add(spentUSD);
        }

        spentValue = DecimalMath.div(spentUSD, _rate);
    }

    function _buyTokensChecks(
        address _beneficiary,
        uint256 _investmentValue,
        uint256 investedUSD
    )
        internal
        view
        returns(uint256 netInvestedUSD)
    {
        require(isOpen(), "STO not open");
        require(_investmentValue > 0, "No funds sent");

        // Check for minimum investment
        require(investedUSD.add(investorInvestedUSD[_beneficiary]) >= minimumInvestmentUSD, "Investment < min");
        netInvestedUSD = investedUSD;
        // Check for non-accredited cap
        if (!_isAccredited(_beneficiary)) {
            uint256 investorLimitUSD = (nonAccreditedLimitUSDOverride[_beneficiary] == 0) ? nonAccreditedLimitUSD : nonAccreditedLimitUSDOverride[_beneficiary];
            require(investorInvestedUSD[_beneficiary] < investorLimitUSD, "Over Non-accredited investor limit");
            if (investedUSD.add(investorInvestedUSD[_beneficiary]) > investorLimitUSD)
                netInvestedUSD = investorLimitUSD.sub(investorInvestedUSD[_beneficiary]);
        }
    }

    function _calculateTier(
        address _beneficiary,
        uint256 _tier,
        uint256 _investedUSD,
        FundRaiseType _fundRaiseType
    )
        internal
        returns(uint256 spentUSD, bool gotoNextTier)
     {
        // First purchase any discounted tokens if POLY investment
        uint256 tierSpentUSD;
        uint256 tierPurchasedTokens;
        uint256 investedUSD = _investedUSD;
        Tier storage tierData = tiers[_tier];
        // Check whether there are any remaining discounted tokens
        if ((_fundRaiseType == FundRaiseType.PAY) && (tierData.tokensDiscountPayToken > tierData.mintedDiscountPayToken)) {
            uint256 discountRemaining = tierData.tokensDiscountPayToken.sub(tierData.mintedDiscountPayToken);
            uint256 totalRemaining = tierData.tokenTotal.sub(tierData.mintedTotal);
            if (totalRemaining < discountRemaining)
                (spentUSD, tierPurchasedTokens, gotoNextTier) = _purchaseTier(_beneficiary, tierData.rateDiscountPayToken, totalRemaining, investedUSD, _tier);
            else
                (spentUSD, tierPurchasedTokens, gotoNextTier) = _purchaseTier(_beneficiary, tierData.rateDiscountPayToken, discountRemaining, investedUSD, _tier);
            investedUSD = investedUSD.sub(spentUSD);
            tierData.mintedDiscountPayToken = tierData.mintedDiscountPayToken.add(tierPurchasedTokens);
            tierData.minted[uint8(_fundRaiseType)] = tierData.minted[uint8(_fundRaiseType)].add(tierPurchasedTokens);
            tierData.mintedTotal = tierData.mintedTotal.add(tierPurchasedTokens);
        }
        // Now, if there is any remaining USD to be invested, purchase at non-discounted rate
        if (investedUSD > 0 &&
            tierData.tokenTotal.sub(tierData.mintedTotal) > 0 &&
            (_fundRaiseType != FundRaiseType.PAY || tierData.tokensDiscountPayToken <= tierData.mintedDiscountPayToken)
        ) {
            (tierSpentUSD, tierPurchasedTokens, gotoNextTier) = _purchaseTier(_beneficiary, tierData.rate, tierData.tokenTotal.sub(tierData.mintedTotal), investedUSD, _tier);
            spentUSD = spentUSD.add(tierSpentUSD);
            tierData.minted[uint8(_fundRaiseType)] = tierData.minted[uint8(_fundRaiseType)].add(tierPurchasedTokens);
            tierData.mintedTotal = tierData.mintedTotal.add(tierPurchasedTokens);
        }
    }

    function _purchaseTier(
        address _beneficiary,
        uint256 _tierPrice,
        uint256 _tierRemaining,
        uint256 _investedUSD,
        uint256 _tier
    )
        internal
        returns(uint256 spentUSD, uint256 purchasedTokens, bool gotoNextTier)
    {
        purchasedTokens = DecimalMath.div(_investedUSD, _tierPrice);
        uint256 granularity = securityToken.granularity();

        if (purchasedTokens > _tierRemaining) {
            purchasedTokens = _tierRemaining.div(granularity);
            gotoNextTier = true;
        } else {
            purchasedTokens = purchasedTokens.div(granularity);
        }

        purchasedTokens = purchasedTokens.mul(granularity);
        spentUSD = DecimalMath.mul(purchasedTokens, _tierPrice);

        // In case of rounding issues, ensure that spentUSD is never more than investedUSD
        if (spentUSD > _investedUSD) {
            spentUSD = _investedUSD;
        }

        if (purchasedTokens > 0) {
            securityToken.issue(_beneficiary, purchasedTokens, "");
            emit TokenPurchase(msg.sender, _beneficiary, purchasedTokens, spentUSD, _tierPrice, _tier);
        }
    }

    function _isAccredited(address _investor) internal view returns(bool) {
        IDataStore dataStore = getDataStore();
        return _getIsAccredited(_investor, dataStore);
    }

    function _getIsAccredited(address _investor, IDataStore dataStore) internal view returns(bool) {
        uint256 flags = dataStore.getUint256(_getKey(INVESTORFLAGS, _investor));
        uint256 flag = flags & uint256(1); //isAccredited is flag 0 so we don't need to bit shift flags.
        return flag > 0 ? true : false;
    }

    /////////////
    // Getters //
    /////////////

    /**
     * @notice This function returns whether or not the STO is in fundraising mode (open)
     * return bool Whether the STO is accepting investments
     */
    function isOpen() public view returns(bool) {
        /*solium-disable-next-line security/no-block-members*/
        if (isFinalized || block.timestamp < startTime || block.timestamp >= endTime || capReached())
            return false;
        return true;
    }

    /**
     * @notice Checks whether the cap has been reached.
     * return bool Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        if (isFinalized) {
            return (finalAmountReturned == 0);
        }
        return (tiers[tiers.length - 1].mintedTotal == tiers[tiers.length - 1].tokenTotal);
    }

    /**
     * @dev returns current conversion rate of funds
     * @param _fundRaiseType Fund raise type to get rate of
     */
    function getRate(FundRaiseType _fundRaiseType) public returns (uint256) {
        if (_fundRaiseType == FundRaiseType.ETH) {
            return IOracle(_getOracle(bytes32("ETH"), bytes32("USD"))).getPrice();
        } else if (_fundRaiseType == FundRaiseType.PAY) {
            return IOracle(_getOracle(bytes32("POLY"), bytes32("USD"))).getPrice();
        } else if (_fundRaiseType == FundRaiseType.SC) {
            return 10**18;
        }
    }

    /**
     * @notice This function converts from ETH or POLY to USD
     * @param _fundRaiseType Currency key
     * @param _amount Value to convert to USD
     * return uint256 Value in USD
     */
    function convertToUSD(FundRaiseType _fundRaiseType, uint256 _amount) public returns(uint256) {
        return DecimalMath.mul(_amount, getRate(_fundRaiseType));
    }

    /**
     * @notice This function converts from USD to ETH or POLY
     * @param _fundRaiseType Currency key
     * @param _amount Value to convert from USD
     * return uint256 Value in ETH or POLY
     */
    function convertFromUSD(FundRaiseType _fundRaiseType, uint256 _amount) public returns(uint256) {
        return DecimalMath.div(_amount, getRate(_fundRaiseType));
    }

    /**
     * @notice Return the total no. of tokens sold
     * return uint256 Total number of tokens sold
     */
    function getTokensSold() public view override returns (uint256) {
        if (isFinalized)
            return totalTokensSold;
        return getTokensMinted();
    }

    /**
     * @notice Return the total no. of tokens minted
     * return uint256 Total number of tokens minted
     */
    function getTokensMinted() public view returns (uint256 tokensMinted) {
        for (uint256 i = 0; i < tiers.length; i++) {
            tokensMinted = tokensMinted.add(tiers[i].mintedTotal);
        }
    }

    /**
     * @notice Return the total no. of tokens sold for the given fund raise type
     * param _fundRaiseType The fund raising currency (e.g. ETH, POLY, SC) to calculate sold tokens for
     * return uint256 Total number of tokens sold for ETH
     */
    function getTokensSoldFor(FundRaiseType _fundRaiseType) external view returns (uint256 tokensSold) {
        for (uint256 i = 0; i < tiers.length; i++) {
            tokensSold = tokensSold.add(tiers[i].minted[uint8(_fundRaiseType)]);
        }
    }

    /**
     * @notice Return array of minted tokens in each fund raise type for given tier
     * param _tier The tier to return minted tokens for
     * return uint256[] array of minted tokens in each fund raise type
     */
    function getTokensMintedByTier(uint256 _tier) external view returns(uint256[] memory) {
        uint256[] memory tokensMinted = new uint256[](3);
        tokensMinted[0] = tiers[_tier].minted[uint8(FundRaiseType.ETH)];
        tokensMinted[1] = tiers[_tier].minted[uint8(FundRaiseType.PAY)];
        tokensMinted[2] = tiers[_tier].minted[uint8(FundRaiseType.SC)];
        return tokensMinted;
    }

    /**
     * @notice Return the total no. of tokens sold in a given tier
     * param _tier The tier to calculate sold tokens for
     * return uint256 Total number of tokens sold in the tier
     */
    function getTokensSoldByTier(uint256 _tier) external view returns (uint256) {
        uint256 tokensSold;
        tokensSold = tokensSold.add(tiers[_tier].minted[uint8(FundRaiseType.ETH)]);
        tokensSold = tokensSold.add(tiers[_tier].minted[uint8(FundRaiseType.PAY)]);
        tokensSold = tokensSold.add(tiers[_tier].minted[uint8(FundRaiseType.SC)]);
        return tokensSold;
    }

    /**
     * @notice Return the total no. of tiers
     * return uint256 Total number of tiers
     */
    function getNumberOfTiers() external view returns (uint256) {
        return tiers.length;
    }

    /**
     * @notice Return the usd tokens accepted by the STO
     * return address[] usd tokens
     */
    function getUsdTokens() external view returns (IERC20[] memory) {
        return usdTokens;
    }

    /**
     * @notice Return the permissions flag that are associated with STO
     */
    function getPermissions() public pure override returns(bytes32[] memory allPermissions) {
        allPermissions = new bytes32[](2);
        allPermissions[0] = OPERATOR;
        allPermissions[1] = ADMIN;
        return allPermissions;
    }

    /**
     * @notice Return the STO details
     * return Unixtimestamp at which offering gets start.
     * return Unixtimestamp at which offering ends.
     * return Currently active tier
     * return Array of Number of tokens this STO will be allowed to sell at different tiers.
     * return Array Rate at which tokens are sold at different tiers
     * return Amount of funds raised
     * return Number of individual investors this STO have.
     * return Amount of tokens sold.
     * return Array of bools to show if funding is allowed in ETH, POLY, SC respectively
     */
    function getSTODetails() external view returns(uint256, uint256, uint256, uint256[] memory, uint256[] memory, uint256, uint256, uint256, bool[] memory) {
        uint256[] memory cap = new uint256[](tiers.length);
        uint256[] memory rate = new uint256[](tiers.length);
        for(uint256 i = 0; i < tiers.length; i++) {
            cap[i] = tiers[i].tokenTotal;
            rate[i] = tiers[i].rate;
        }
        bool[] memory _fundRaiseTypes = new bool[](3);
        _fundRaiseTypes[0] = fundRaiseTypes[uint8(FundRaiseType.ETH)];
        _fundRaiseTypes[1] = fundRaiseTypes[uint8(FundRaiseType.PAY)];
        _fundRaiseTypes[2] = fundRaiseTypes[uint8(FundRaiseType.SC)];
        return (
            startTime,
            endTime,
            currentTier,
            cap,
            rate,
            fundsRaisedUSD,
            investorCount,
            getTokensSold(),
            _fundRaiseTypes
        );
    }

    /**
     * @notice This function returns the signature of configure function
     * return bytes4 Configure function signature
     */
    function getInitFunction() public pure override returns(bytes4) {
        return this.configure.selector;
    }

    function _getOracle(bytes32 _currency, bytes32 _denominatedCurrency) internal view returns(address oracleAddress) {
        oracleAddress = customOracles[_currency][_denominatedCurrency];
        
        return address(0);
        
        if (oracleAddress == address(0))
            oracleAddress =  IRegistry(securityToken.registry()).getAddress(oracleKeys[_currency][_denominatedCurrency]);
    }
}