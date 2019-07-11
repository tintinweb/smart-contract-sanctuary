/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

// File: contracts/lifecycle/PausableProxy.sol

pragma solidity ^0.4.24;

/**
 * @title PausableProxy
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract PausableProxy {
    /**
     * @dev Storage slot with the paused state of the contract.
     * This is the keccak-256 hash of "org.monetha.proxy.paused", and is
     * validated in the constructor.
     */
    bytes32 private constant PAUSED_OWNER_SLOT = 0x9e7945c55c116aa3404b99fe56db7af9613d3b899554a437c2616a4749a94d8a;

    /**
     * @dev The ClaimableProxy constructor validates PENDING_OWNER_SLOT constant.
     */
    constructor() public {
        assert(PAUSED_OWNER_SLOT == keccak256("org.monetha.proxy.paused"));
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_getPaused(), "contract should not be paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_getPaused(), "contract should be paused");
        _;
    }

    /**
     * @return True when the contract is paused.
     */
    function _getPaused() internal view returns (bool paused) {
        bytes32 slot = PAUSED_OWNER_SLOT;
        assembly {
            paused := sload(slot)
        }
    }

    /**
     * @dev Sets the paused state.
     * @param _paused New paused state.
     */
    function _setPaused(bool _paused) internal {
        bytes32 slot = PAUSED_OWNER_SLOT;
        assembly {
            sstore(slot, _paused)
        }
    }
}

// File: contracts/ownership/OwnableProxy.sol

pragma solidity ^0.4.24;


/**
 * @title OwnableProxy
 */
contract OwnableProxy is PausableProxy {
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Storage slot with the owner of the contract.
     * This is the keccak-256 hash of "org.monetha.proxy.owner", and is
     * validated in the constructor.
     */
    bytes32 private constant OWNER_SLOT = 0x3ca57e4b51fc2e18497b219410298879868edada7e6fe5132c8feceb0a080d22;

    /**
     * @dev The OwnableProxy constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        assert(OWNER_SLOT == keccak256("org.monetha.proxy.owner"));

        _setOwner(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _getOwner());
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner whenNotPaused {
        emit OwnershipRenounced(_getOwner());
        _setOwner(address(0));
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner whenNotPaused {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(_getOwner(), _newOwner);
        _setOwner(_newOwner);
    }

    /**
     * @return The owner address.
     */
    function owner() public view returns (address) {
        return _getOwner();
    }

    /**
     * @return The owner address.
     */
    function _getOwner() internal view returns (address own) {
        bytes32 slot = OWNER_SLOT;
        assembly {
            own := sload(slot)
        }
    }

    /**
     * @dev Sets the address of the proxy owner.
     * @param _newOwner Address of the new proxy owner.
     */
    function _setOwner(address _newOwner) internal {
        bytes32 slot = OWNER_SLOT;

        assembly {
            sstore(slot, _newOwner)
        }
    }
}

// File: contracts/ownership/ClaimableProxy.sol

pragma solidity ^0.4.24;


/**
 * @title ClaimableProxy
 * @dev Extension for the OwnableProxy contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract ClaimableProxy is OwnableProxy {
    /**
     * @dev Storage slot with the pending owner of the contract.
     * This is the keccak-256 hash of "org.monetha.proxy.pendingOwner", and is
     * validated in the constructor.
     */
    bytes32 private constant PENDING_OWNER_SLOT = 0xcfd0c6ea5352192d7d4c5d4e7a73c5da12c871730cb60ff57879cbe7b403bb52;

    /**
     * @dev The ClaimableProxy constructor validates PENDING_OWNER_SLOT constant.
     */
    constructor() public {
        assert(PENDING_OWNER_SLOT == keccak256("org.monetha.proxy.pendingOwner"));
    }

    function pendingOwner() public view returns (address) {
        return _getPendingOwner();
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == _getPendingOwner());
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner whenNotPaused {
        _setPendingOwner(newOwner);
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner whenNotPaused {
        emit OwnershipTransferred(_getOwner(), _getPendingOwner());
        _setOwner(_getPendingOwner());
        _setPendingOwner(address(0));
    }

    /**
     * @return The pending owner address.
     */
    function _getPendingOwner() internal view returns (address penOwn) {
        bytes32 slot = PENDING_OWNER_SLOT;
        assembly {
            penOwn := sload(slot)
        }
    }

    /**
     * @dev Sets the address of the pending owner.
     * @param _newPendingOwner Address of the new pending owner.
     */
    function _setPendingOwner(address _newPendingOwner) internal {
        bytes32 slot = PENDING_OWNER_SLOT;

        assembly {
            sstore(slot, _newPendingOwner)
        }
    }
}

// File: contracts/IPassportLogic.sol

pragma solidity ^0.4.24;

interface IPassportLogic {
    /**
     * @dev Returns the owner address of contract.
     */
    function owner() external view returns (address);

    /**** Storage Set Methods ***********/

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setAddress(bytes32 _key, address _value) external;

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setUint(bytes32 _key, uint _value) external;

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setInt(bytes32 _key, int _value) external;

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setBool(bytes32 _key, bool _value) external;

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setString(bytes32 _key, string _value) external;

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setBytes(bytes32 _key, bytes _value) external;

    /// @param _key The key for the record
    function setTxDataBlockNumber(bytes32 _key, bytes _data) external;

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setIPFSHash(bytes32 _key, string _value) external;

    /**** Storage Delete Methods ***********/

    /// @param _key The key for the record
    function deleteAddress(bytes32 _key) external;

    /// @param _key The key for the record
    function deleteUint(bytes32 _key) external;

    /// @param _key The key for the record
    function deleteInt(bytes32 _key) external;

    /// @param _key The key for the record
    function deleteBool(bytes32 _key) external;

    /// @param _key The key for the record
    function deleteString(bytes32 _key) external;

    /// @param _key The key for the record
    function deleteBytes(bytes32 _key) external;

    /// @param _key The key for the record
    function deleteTxDataBlockNumber(bytes32 _key) external;

    /// @param _key The key for the record
    function deleteIPFSHash(bytes32 _key) external;

    /**** Storage Get Methods ***********/

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    function getAddress(address _factProvider, bytes32 _key) external view returns (bool success, address value);

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    function getUint(address _factProvider, bytes32 _key) external view returns (bool success, uint value);

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    function getInt(address _factProvider, bytes32 _key) external view returns (bool success, int value);

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    function getBool(address _factProvider, bytes32 _key) external view returns (bool success, bool value);

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    function getString(address _factProvider, bytes32 _key) external view returns (bool success, string value);

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    function getBytes(address _factProvider, bytes32 _key) external view returns (bool success, bytes value);

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    function getTxDataBlockNumber(address _factProvider, bytes32 _key) external view returns (bool success, uint blockNumber);

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    function getIPFSHash(address _factProvider, bytes32 _key) external view returns (bool success, string value);
}

// File: contracts/storage/Storage.sol

pragma solidity ^0.4.24;


// Storage contracts holds all state.
// Do not change the order of the fields, аdd new fields to the end of the contract!
contract Storage is ClaimableProxy
{
    /***************************************************************************
     *** STORAGE VARIABLES. DO NOT REORDER!!! ADD NEW VARIABLE TO THE END!!! ***
     ***************************************************************************/

    struct AddressValue {
        bool initialized;
        address value;
    }

    mapping(address => mapping(bytes32 => AddressValue)) internal addressStorage;

    struct UintValue {
        bool initialized;
        uint value;
    }

    mapping(address => mapping(bytes32 => UintValue)) internal uintStorage;

    struct IntValue {
        bool initialized;
        int value;
    }

    mapping(address => mapping(bytes32 => IntValue)) internal intStorage;

    struct BoolValue {
        bool initialized;
        bool value;
    }

    mapping(address => mapping(bytes32 => BoolValue)) internal boolStorage;

    struct StringValue {
        bool initialized;
        string value;
    }

    mapping(address => mapping(bytes32 => StringValue)) internal stringStorage;

    struct BytesValue {
        bool initialized;
        bytes value;
    }

    mapping(address => mapping(bytes32 => BytesValue)) internal bytesStorage;

    struct BlockNumberValue {
        bool initialized;
        uint blockNumber;
    }

    mapping(address => mapping(bytes32 => BlockNumberValue)) internal txBytesStorage;

    bool private onlyFactProviderFromWhitelistAllowed;
    mapping(address => bool) private factProviderWhitelist;

    struct IPFSHashValue {
        bool initialized;
        string value;
    }

    mapping(address => mapping(bytes32 => IPFSHashValue)) internal ipfsHashStorage;

    struct PrivateData {
        string dataIPFSHash; // The IPFS hash of encrypted private data
        bytes32 dataKeyHash; // The hash of symmetric key that was used to encrypt the data
    }

    struct PrivateDataValue {
        bool initialized;
        PrivateData value;
    }

    mapping(address => mapping(bytes32 => PrivateDataValue)) internal privateDataStorage;

    enum PrivateDataExchangeState {Closed, Proposed, Accepted}

    struct PrivateDataExchange {
        address dataRequester;          // The address of the data requester
        uint256 dataRequesterValue;     // The amount staked by the data requester
        address passportOwner;          // The address of the passport owner at the time of the data exchange proposition
        uint256 passportOwnerValue;     // Tha amount staked by the passport owner
        address factProvider;           // The private data provider
        bytes32 key;                    // the key for the private data record
        string dataIPFSHash;            // The IPFS hash of encrypted private data
        bytes32 dataKeyHash;            // The hash of data symmetric key that was used to encrypt the data
        bytes encryptedExchangeKey;     // The encrypted exchange session key (only passport owner can decrypt it)
        bytes32 exchangeKeyHash;        // The hash of exchange session key
        bytes32 encryptedDataKey;       // The data symmetric key XORed with the exchange key
        PrivateDataExchangeState state; // The state of private data exchange
        uint256 stateExpired;           // The state expiration timestamp
    }

    uint public openPrivateDataExchangesCount; // the count of open private data exchanges TODO: use it in contract destruction/ownership transfer logic
    PrivateDataExchange[] public privateDataExchanges;

    /***************************************************************************
     *** END OF SECTION OF STORAGE VARIABLES                                 ***
     ***************************************************************************/

    event WhitelistOnlyPermissionSet(bool indexed onlyWhitelist);
    event WhitelistFactProviderAdded(address indexed factProvider);
    event WhitelistFactProviderRemoved(address indexed factProvider);

    /**
     *  Restrict methods in such way, that they can be invoked only by allowed fact provider.
     */
    modifier allowedFactProvider() {
        require(isAllowedFactProvider(msg.sender));
        _;
    }

    /**
     *  Returns true when the given address is an allowed fact provider.
     */
    function isAllowedFactProvider(address _address) public view returns (bool) {
        return !onlyFactProviderFromWhitelistAllowed || factProviderWhitelist[_address] || _address == _getOwner();
    }

    /**
     *  Returns true when a whitelist of fact providers is enabled.
     */
    function isWhitelistOnlyPermissionSet() external view returns (bool) {
        return onlyFactProviderFromWhitelistAllowed;
    }

    /**
     *  Enables or disables the use of a whitelist of fact providers.
     */
    function setWhitelistOnlyPermission(bool _onlyWhitelist) onlyOwner external {
        onlyFactProviderFromWhitelistAllowed = _onlyWhitelist;
        emit WhitelistOnlyPermissionSet(_onlyWhitelist);
    }

    /**
     *  Returns true if fact provider is added to the whitelist.
     */
    function isFactProviderInWhitelist(address _address) external view returns (bool) {
        return factProviderWhitelist[_address];
    }

    /**
     *  Allows owner to add fact provider to whitelist.
     */
    function addFactProviderToWhitelist(address _address) onlyOwner external {
        factProviderWhitelist[_address] = true;
        emit WhitelistFactProviderAdded(_address);
    }

    /**
     *  Allows owner to remove fact provider from whitelist.
     */
    function removeFactProviderFromWhitelist(address _address) onlyOwner external {
        delete factProviderWhitelist[_address];
        emit WhitelistFactProviderRemoved(_address);
    }
}

// File: contracts/storage/AddressStorageLogic.sol

pragma solidity ^0.4.24;


contract AddressStorageLogic is Storage {
    event AddressUpdated(address indexed factProvider, bytes32 indexed key);
    event AddressDeleted(address indexed factProvider, bytes32 indexed key);

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setAddress(bytes32 _key, address _value) external {
        _setAddress(_key, _value);
    }

    /// @param _key The key for the record
    function deleteAddress(bytes32 _key) external {
        _deleteAddress(_key);
    }

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    function getAddress(address _factProvider, bytes32 _key) external view returns (bool success, address value) {
        return _getAddress(_factProvider, _key);
    }

    function _setAddress(bytes32 _key, address _value) allowedFactProvider internal {
        addressStorage[msg.sender][_key] = AddressValue({
            initialized : true,
            value : _value
            });
        emit AddressUpdated(msg.sender, _key);
    }

    function _deleteAddress(bytes32 _key) allowedFactProvider internal {
        delete addressStorage[msg.sender][_key];
        emit AddressDeleted(msg.sender, _key);
    }

    function _getAddress(address _factProvider, bytes32 _key) internal view returns (bool success, address value) {
        AddressValue storage initValue = addressStorage[_factProvider][_key];
        return (initValue.initialized, initValue.value);
    }
}

// File: contracts/storage/UintStorageLogic.sol

pragma solidity ^0.4.24;


contract UintStorageLogic is Storage {
    event UintUpdated(address indexed factProvider, bytes32 indexed key);
    event UintDeleted(address indexed factProvider, bytes32 indexed key);

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setUint(bytes32 _key, uint _value) external {
        _setUint(_key, _value);
    }

    /// @param _key The key for the record
    function deleteUint(bytes32 _key) external {
        _deleteUint(_key);
    }

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    function getUint(address _factProvider, bytes32 _key) external view returns (bool success, uint value) {
        return _getUint(_factProvider, _key);
    }

    function _setUint(bytes32 _key, uint _value) allowedFactProvider internal {
        uintStorage[msg.sender][_key] = UintValue({
            initialized : true,
            value : _value
            });
        emit UintUpdated(msg.sender, _key);
    }

    function _deleteUint(bytes32 _key) allowedFactProvider internal {
        delete uintStorage[msg.sender][_key];
        emit UintDeleted(msg.sender, _key);
    }

    function _getUint(address _factProvider, bytes32 _key) internal view returns (bool success, uint value) {
        UintValue storage initValue = uintStorage[_factProvider][_key];
        return (initValue.initialized, initValue.value);
    }
}

// File: contracts/storage/IntStorageLogic.sol

pragma solidity ^0.4.24;


contract IntStorageLogic is Storage {
    event IntUpdated(address indexed factProvider, bytes32 indexed key);
    event IntDeleted(address indexed factProvider, bytes32 indexed key);

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setInt(bytes32 _key, int _value) external {
        _setInt(_key, _value);
    }

    /// @param _key The key for the record
    function deleteInt(bytes32 _key) external {
        _deleteInt(_key);
    }

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    function getInt(address _factProvider, bytes32 _key) external view returns (bool success, int value) {
        return _getInt(_factProvider, _key);
    }

    function _setInt(bytes32 _key, int _value) allowedFactProvider internal {
        intStorage[msg.sender][_key] = IntValue({
            initialized : true,
            value : _value
            });
        emit IntUpdated(msg.sender, _key);
    }

    function _deleteInt(bytes32 _key) allowedFactProvider internal {
        delete intStorage[msg.sender][_key];
        emit IntDeleted(msg.sender, _key);
    }

    function _getInt(address _factProvider, bytes32 _key) internal view returns (bool success, int value) {
        IntValue storage initValue = intStorage[_factProvider][_key];
        return (initValue.initialized, initValue.value);
    }
}

// File: contracts/storage/BoolStorageLogic.sol

pragma solidity ^0.4.24;


contract BoolStorageLogic is Storage {
    event BoolUpdated(address indexed factProvider, bytes32 indexed key);
    event BoolDeleted(address indexed factProvider, bytes32 indexed key);

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setBool(bytes32 _key, bool _value) external {
        _setBool(_key, _value);
    }

    /// @param _key The key for the record
    function deleteBool(bytes32 _key) external {
        _deleteBool(_key);
    }

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    function getBool(address _factProvider, bytes32 _key) external view returns (bool success, bool value) {
        return _getBool(_factProvider, _key);
    }

    function _setBool(bytes32 _key, bool _value) allowedFactProvider internal {
        boolStorage[msg.sender][_key] = BoolValue({
            initialized : true,
            value : _value
            });
        emit BoolUpdated(msg.sender, _key);
    }

    function _deleteBool(bytes32 _key) allowedFactProvider internal {
        delete boolStorage[msg.sender][_key];
        emit BoolDeleted(msg.sender, _key);
    }

    function _getBool(address _factProvider, bytes32 _key) internal view returns (bool success, bool value) {
        BoolValue storage initValue = boolStorage[_factProvider][_key];
        return (initValue.initialized, initValue.value);
    }
}

// File: contracts/storage/StringStorageLogic.sol

pragma solidity ^0.4.24;


contract StringStorageLogic is Storage {
    event StringUpdated(address indexed factProvider, bytes32 indexed key);
    event StringDeleted(address indexed factProvider, bytes32 indexed key);

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setString(bytes32 _key, string _value) external {
        _setString(_key, _value);
    }

    /// @param _key The key for the record
    function deleteString(bytes32 _key) external {
        _deleteString(_key);
    }

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    function getString(address _factProvider, bytes32 _key) external view returns (bool success, string value) {
        return _getString(_factProvider, _key);
    }

    function _setString(bytes32 _key, string _value) allowedFactProvider internal {
        stringStorage[msg.sender][_key] = StringValue({
            initialized : true,
            value : _value
            });
        emit StringUpdated(msg.sender, _key);
    }

    function _deleteString(bytes32 _key) allowedFactProvider internal {
        delete stringStorage[msg.sender][_key];
        emit StringDeleted(msg.sender, _key);
    }

    function _getString(address _factProvider, bytes32 _key) internal view returns (bool success, string value) {
        StringValue storage initValue = stringStorage[_factProvider][_key];
        return (initValue.initialized, initValue.value);
    }
}

// File: contracts/storage/BytesStorageLogic.sol

pragma solidity ^0.4.24;


contract BytesStorageLogic is Storage {
    event BytesUpdated(address indexed factProvider, bytes32 indexed key);
    event BytesDeleted(address indexed factProvider, bytes32 indexed key);

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setBytes(bytes32 _key, bytes _value) external {
        _setBytes(_key, _value);
    }

    /// @param _key The key for the record
    function deleteBytes(bytes32 _key) external {
        _deleteBytes(_key);
    }

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    function getBytes(address _factProvider, bytes32 _key) external view returns (bool success, bytes value) {
        return _getBytes(_factProvider, _key);
    }

    function _setBytes(bytes32 _key, bytes _value) allowedFactProvider internal {
        bytesStorage[msg.sender][_key] = BytesValue({
            initialized : true,
            value : _value
            });
        emit BytesUpdated(msg.sender, _key);
    }

    function _deleteBytes(bytes32 _key) allowedFactProvider internal {
        delete bytesStorage[msg.sender][_key];
        emit BytesDeleted(msg.sender, _key);
    }

    function _getBytes(address _factProvider, bytes32 _key) internal view returns (bool success, bytes value) {
        BytesValue storage initValue = bytesStorage[_factProvider][_key];
        return (initValue.initialized, initValue.value);
    }
}

// File: contracts/storage/TxDataStorageLogic.sol

pragma solidity ^0.4.24;


/**
 * @title TxDataStorage
 * @dev This contract saves only the block number for the input data. The input data is not stored into
 * Ethereum storage, but it can be decoded from the transaction input data later.
 */
contract TxDataStorageLogic is Storage {
    event TxDataUpdated(address indexed factProvider, bytes32 indexed key);
    event TxDataDeleted(address indexed factProvider, bytes32 indexed key);

    /// @param _key The key for the record
    /// @param _data The data for the record. Ignore "unused function parameter" warning, it&#39;s not commented out so that
    ///              it would remain in the ABI file.
    function setTxDataBlockNumber(bytes32 _key, bytes _data) allowedFactProvider external {
        _data;
        txBytesStorage[msg.sender][_key] = BlockNumberValue({
            initialized : true,
            blockNumber : block.number
            });
        emit TxDataUpdated(msg.sender, _key);
    }

    /// @param _key The key for the record
    function deleteTxDataBlockNumber(bytes32 _key) allowedFactProvider external {
        delete txBytesStorage[msg.sender][_key];
        emit TxDataDeleted(msg.sender, _key);
    }

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    function getTxDataBlockNumber(address _factProvider, bytes32 _key) external view returns (bool success, uint blockNumber) {
        return _getTxDataBlockNumber(_factProvider, _key);
    }

    function _getTxDataBlockNumber(address _factProvider, bytes32 _key) private view returns (bool success, uint blockNumber) {
        BlockNumberValue storage initValue = txBytesStorage[_factProvider][_key];
        return (initValue.initialized, initValue.blockNumber);
    }
}

// File: contracts/storage/IPFSStorageLogic.sol

pragma solidity ^0.4.24;


contract IPFSStorageLogic is Storage {
    event IPFSHashUpdated(address indexed factProvider, bytes32 indexed key);
    event IPFSHashDeleted(address indexed factProvider, bytes32 indexed key);

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setIPFSHash(bytes32 _key, string _value) external {
        _setIPFSHash(_key, _value);
    }

    /// @param _key The key for the record
    function deleteIPFSHash(bytes32 _key) external {
        _deleteIPFSHash(_key);
    }

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    function getIPFSHash(address _factProvider, bytes32 _key) external view returns (bool success, string value) {
        return _getIPFSHash(_factProvider, _key);
    }

    function _setIPFSHash(bytes32 _key, string _value) allowedFactProvider internal {
        ipfsHashStorage[msg.sender][_key] = IPFSHashValue({
            initialized : true,
            value : _value
            });
        emit IPFSHashUpdated(msg.sender, _key);
    }

    function _deleteIPFSHash(bytes32 _key) allowedFactProvider internal {
        delete ipfsHashStorage[msg.sender][_key];
        emit IPFSHashDeleted(msg.sender, _key);
    }

    function _getIPFSHash(address _factProvider, bytes32 _key) internal view returns (bool success, string value) {
        IPFSHashValue storage initValue = ipfsHashStorage[_factProvider][_key];
        return (initValue.initialized, initValue.value);
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: contracts/storage/PrivateDataStorageLogic.sol

pragma solidity ^0.4.24;



contract PrivateDataStorageLogic is Storage {
    using SafeMath for uint256;

    event PrivateDataHashesUpdated(address indexed factProvider, bytes32 indexed key);
    event PrivateDataHashesDeleted(address indexed factProvider, bytes32 indexed key);

    event PrivateDataExchangeProposed(uint256 indexed exchangeIdx, address indexed dataRequester, address indexed passportOwner);
    event PrivateDataExchangeAccepted(uint256 indexed exchangeIdx, address indexed dataRequester, address indexed passportOwner);
    event PrivateDataExchangeClosed(uint256 indexed exchangeIdx);
    event PrivateDataExchangeDisputed(uint256 indexed exchangeIdx, bool indexed successful, address indexed cheater);

    uint256 constant public privateDataExchangeProposeTimeout = 1 days;
    uint256 constant public privateDataExchangeAcceptTimeout = 1 days;

    /// @param _key The key for the record
    /// @param _dataIPFSHash The IPFS hash of encrypted private data
    /// @param _dataKeyHash The hash of symmetric key that was used to encrypt the data
    function setPrivateDataHashes(bytes32 _key, string _dataIPFSHash, bytes32 _dataKeyHash) external {
        _setPrivateDataHashes(_key, _dataIPFSHash, _dataKeyHash);
    }

    /// @param _key The key for the record
    function deletePrivateDataHashes(bytes32 _key) external {
        _deletePrivateDataHashes(_key);
    }

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    function getPrivateDataHashes(address _factProvider, bytes32 _key) external view returns (bool success, string dataIPFSHash, bytes32 dataKeyHash) {
        return _getPrivateDataHashes(_factProvider, _key);
    }

    /**
     * @dev returns the number of private data exchanges created.
     */
    function getPrivateDataExchangesCount() public constant returns (uint256 count) {
        return privateDataExchanges.length;
    }

    /// @param _factProvider The fact provider
    /// @param _key The key for the record
    /// @param _encryptedExchangeKey The encrypted exchange session key (only passport owner can decrypt it)
    /// @param _exchangeKeyHash The hash of exchange session key
    function proposePrivateDataExchange(
        address _factProvider,
        bytes32 _key,
        bytes _encryptedExchangeKey,
        bytes32 _exchangeKeyHash
    ) external payable {
        (bool success, string memory dataIPFSHash, bytes32 dataKeyHash) = _getPrivateDataHashes(_factProvider, _key);
        require(success, "private data must exist");

        address passportOwner = _getOwner();
        bytes32 encryptedDataKey;
        PrivateDataExchange memory exchange = PrivateDataExchange({
            dataRequester : msg.sender,
            dataRequesterValue : msg.value,
            passportOwner : passportOwner,
            passportOwnerValue : 0,
            factProvider : _factProvider,
            key : _key,
            dataIPFSHash : dataIPFSHash,
            dataKeyHash : dataKeyHash,
            encryptedExchangeKey : _encryptedExchangeKey,
            exchangeKeyHash : _exchangeKeyHash,
            encryptedDataKey : encryptedDataKey,
            state : PrivateDataExchangeState.Proposed,
            stateExpired : _nowSeconds() + privateDataExchangeProposeTimeout
            });
        privateDataExchanges.push(exchange);

        _incOpenPrivateDataExchangesCount();

        uint256 exchangeIdx = privateDataExchanges.length - 1;
        emit PrivateDataExchangeProposed(exchangeIdx, msg.sender, passportOwner);
    }

    /// @param _exchangeIdx The private data exchange index
    /// @param _encryptedDataKey The data symmetric key XORed with the exchange key
    function acceptPrivateDataExchange(uint256 _exchangeIdx, bytes32 _encryptedDataKey) external payable {
        require(_exchangeIdx < privateDataExchanges.length, "invalid exchange index");
        PrivateDataExchange storage exchange = privateDataExchanges[_exchangeIdx];
        require(msg.sender == exchange.passportOwner, "only passport owner allowed");
        require(PrivateDataExchangeState.Proposed == exchange.state, "exchange must be in proposed state");
        require(msg.value >= exchange.dataRequesterValue, "need to stake at least data requester amount");
        require(_nowSeconds() < exchange.stateExpired, "exchange state expired");

        exchange.passportOwnerValue = msg.value;
        exchange.encryptedDataKey = _encryptedDataKey;
        exchange.state = PrivateDataExchangeState.Accepted;
        exchange.stateExpired = _nowSeconds() + privateDataExchangeAcceptTimeout;

        emit PrivateDataExchangeAccepted(_exchangeIdx, exchange.dataRequester, msg.sender);
    }

    /// @param _exchangeIdx The private data exchange index
    function finishPrivateDataExchange(uint256 _exchangeIdx) external {
        require(_exchangeIdx < privateDataExchanges.length, "invalid exchange index");
        PrivateDataExchange storage exchange = privateDataExchanges[_exchangeIdx];
        require(PrivateDataExchangeState.Accepted == exchange.state, "exchange must be in accepted state");
        require(_nowSeconds() > exchange.stateExpired || msg.sender == exchange.dataRequester, "exchange must be either expired or be finished by the data requester");

        exchange.state = PrivateDataExchangeState.Closed;

        // transfer all exchange staked money to passport owner
        uint256 val = exchange.dataRequesterValue.add(exchange.passportOwnerValue);
        require(exchange.passportOwner.send(val));

        _decOpenPrivateDataExchangesCount();

        emit PrivateDataExchangeClosed(_exchangeIdx);
    }

    /// @param _exchangeIdx The private data exchange index
    function timeoutPrivateDataExchange(uint256 _exchangeIdx) external {
        require(_exchangeIdx < privateDataExchanges.length, "invalid exchange index");
        PrivateDataExchange storage exchange = privateDataExchanges[_exchangeIdx];
        require(PrivateDataExchangeState.Proposed == exchange.state, "exchange must be in proposed state");
        require(msg.sender == exchange.dataRequester, "only data requester allowed");
        require(_nowSeconds() > exchange.stateExpired, "exchange must be expired");

        exchange.state = PrivateDataExchangeState.Closed;

        // return staked amount to data requester
        require(exchange.dataRequester.send(exchange.dataRequesterValue));

        _decOpenPrivateDataExchangesCount();

        emit PrivateDataExchangeClosed(_exchangeIdx);
    }

    /// @param _exchangeIdx The private data exchange index
    /// @param _exchangeKey The unencrypted exchange session key
    function disputePrivateDataExchange(uint256 _exchangeIdx, bytes32 _exchangeKey) external {
        require(_exchangeIdx < privateDataExchanges.length, "invalid exchange index");
        PrivateDataExchange storage exchange = privateDataExchanges[_exchangeIdx];
        require(PrivateDataExchangeState.Accepted == exchange.state, "exchange must be in accepted state");
        require(msg.sender == exchange.dataRequester, "only data requester allowed");
        require(_nowSeconds() < exchange.stateExpired, "exchange must not be expired");
        require(keccak256(abi.encodePacked(_exchangeKey)) == exchange.exchangeKeyHash, "exchange key hash must match");

        bytes32 dataKey = _exchangeKey ^ exchange.encryptedDataKey;
        // data symmetric key is XORed with exchange key
        bool validDataKey = keccak256(abi.encodePacked(dataKey)) == exchange.dataKeyHash;

        exchange.state = PrivateDataExchangeState.Closed;

        uint256 val = exchange.dataRequesterValue.add(exchange.passportOwnerValue);

        address cheater;
        if (validDataKey) {// the data key was valid -> data requester cheated
            require(exchange.passportOwner.send(val));
            cheater = exchange.dataRequester;
        } else {// the data key is invalid -> passport owner cheated
            require(exchange.dataRequester.send(val));
            cheater = exchange.passportOwner;
        }

        _decOpenPrivateDataExchangesCount();

        emit PrivateDataExchangeClosed(_exchangeIdx);
        emit PrivateDataExchangeDisputed(_exchangeIdx, !validDataKey, cheater);
    }

    function _incOpenPrivateDataExchangesCount() internal {
        if (++openPrivateDataExchangesCount == 1) {
            // don&#39;t allow passport owner to transfer ownership and destroy passport when there are open exchanges
            _setPaused(true);
        }
    }

    function _decOpenPrivateDataExchangesCount() internal {
        if (--openPrivateDataExchangesCount == 0) {
            // allow passport owner to transfer ownership and destroy passport when all exchanges are closed
            _setPaused(false);
        }
    }

    function _setPrivateDataHashes(bytes32 _key, string _dataIPFSHash, bytes32 _dataKeyHash) allowedFactProvider internal {
        privateDataStorage[msg.sender][_key] = PrivateDataValue({
            initialized : true,
            value : PrivateData({
                dataIPFSHash : _dataIPFSHash,
                dataKeyHash : _dataKeyHash
                })
            });
        emit PrivateDataHashesUpdated(msg.sender, _key);
    }

    function _deletePrivateDataHashes(bytes32 _key) allowedFactProvider internal {
        delete privateDataStorage[msg.sender][_key];
        emit PrivateDataHashesDeleted(msg.sender, _key);
    }

    function _getPrivateDataHashes(address _factProvider, bytes32 _key) internal view returns (bool success, string dataIPFSHash, bytes32 dataKeyHash) {
        PrivateDataValue storage initValue = privateDataStorage[_factProvider][_key];
        return (initValue.initialized, initValue.value.dataIPFSHash, initValue.value.dataKeyHash);
    }

    function _nowSeconds() private view returns(uint256) {
        uint256 t = now;

        // In Quorum blockchain timestamp is in nanoseconds, not seconds:
        // https://github.com/jpmorganchase/quorum/issues/713
        // https://github.com/jpmorganchase/quorum/issues/190
        if (t > 150000000000000000) {
            t /= 1000000000;
        }

        return t;
    }
}

// File: contracts/PassportLogic.sol

pragma solidity ^0.4.24;












contract PassportLogic
is IPassportLogic
, ClaimableProxy
, AddressStorageLogic
, UintStorageLogic
, IntStorageLogic
, BoolStorageLogic
, StringStorageLogic
, BytesStorageLogic
, TxDataStorageLogic
, IPFSStorageLogic
, PrivateDataStorageLogic
{}