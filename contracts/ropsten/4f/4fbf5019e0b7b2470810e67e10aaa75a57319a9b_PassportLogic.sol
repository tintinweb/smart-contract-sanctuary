pragma solidity ^0.4.24;

// File: contracts/ownership/OwnableProxy.sol

/**
 * @title OwnableProxy
 */
contract OwnableProxy {
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_getOwner());
        _setOwner(address(0));
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
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
    function transferOwnership(address newOwner) public onlyOwner {
        _setPendingOwner(newOwner);
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
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
}

// File: contracts/storage/Storage.sol

// Storage contracts holds all state.
// Do not change the order of the fields, аdd new fields to the end of the contract!
contract Storage is ClaimableProxy
{
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

// File: contracts/PassportLogic.sol

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
{}