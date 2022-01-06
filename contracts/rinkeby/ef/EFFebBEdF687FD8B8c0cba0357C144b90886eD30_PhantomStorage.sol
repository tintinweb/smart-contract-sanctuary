/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Internal Imports*/
import {PhantomStorageKeys} from "PhantomStorageKeys.sol";

/* Internal Interface Imports */
import {IPhantomStorage} from "IPhantomStorage.sol";

/**
 * @title PhantomStorage()
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice The Eternal Storage contract powering the Phantom Network
 */
contract PhantomStorage is PhantomStorageKeys, IPhantomStorage {
    //=================================================================================================================
    // Storage Maps
    //=================================================================================================================

    mapping(bytes32 => string) private stringStorage;
    mapping(bytes32 => bytes) private bytesStorage;
    mapping(bytes32 => uint256) private uintStorage;
    mapping(bytes32 => int256) private intStorage;
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => bool) private booleanStorage;
    mapping(bytes32 => bytes32) private bytes32Storage;

    mapping(bytes32 => string[]) private stringArrayStorage;
    mapping(bytes32 => bytes[]) private bytesArrayStorage;
    mapping(bytes32 => uint256[]) private uintArrayStorage;
    mapping(bytes32 => int256[]) private intArrayStorage;
    mapping(bytes32 => address[]) private addressArrayStorage;
    mapping(bytes32 => bool[]) private booleanArrayStorage;
    mapping(bytes32 => bytes32[]) private bytes32ArrayStorage;

    //=================================================================================================================
    // State Variables
    //=================================================================================================================

    address storageGuardian;
    address newStorageGuardian;
    bool storageInit = false;

    //=================================================================================================================
    // Constructor
    //=================================================================================================================

    constructor() {
        storageGuardian = msg.sender;
    }

    //=================================================================================================================
    // Modifiers
    //=================================================================================================================

    modifier onlyRegisteredContracts() {
        if (storageInit == true) {
            // Make sure the access is permitted to only contracts registered with the network
            if (!booleanStorage[keccak256(abi.encodePacked("phantom.contract.registered", msg.sender))]) {
                revert PhantomStorage__ContractNotRegistered(msg.sender);
            }
        } else {
            // tx.origin is only safe to use in this case for deployment since no external contracts are interacted with
            if (
                !(booleanStorage[keccak256(abi.encodePacked("phantom.contract.registered", msg.sender))] ||
                    tx.origin == storageGuardian)
            ) revert PhantomStorage__ContractNotRegistered(msg.sender);
        }
        _;
    }

    //=================================================================================================================
    // External Functions
    //=================================================================================================================

    function registerContract(bytes calldata contractName, address contractAddress)
        external
        override
        onlyRegisteredContracts
    {
        booleanStorage[keccak256(abi.encodePacked("phantom.contract.registered", contractAddress))] = true;
        addressStorage[keccak256(abi.encodePacked(contractName))] = contractAddress;
    }

    function unregisterContract(bytes calldata contractName) external override onlyRegisteredContracts {
        address contractAddress = addressStorage[keccak256(abi.encodePacked(contractName))];
        delete booleanStorage[keccak256(abi.encodePacked("phantom.contract.registered", contractAddress))];
        delete addressStorage[keccak256(abi.encodePacked(contractName))];
    }

    function getGuardian() external view override returns (address) {
        return storageGuardian;
    }

    function sendGuardianInvitation(address _newAddress) external override {
        if (msg.sender != storageGuardian) revert PhantomStorage__NotStorageGuardian(msg.sender);
        newStorageGuardian = _newAddress;
    }

    function acceptGuardianInvitation() external override {
        if (msg.sender != newStorageGuardian) revert PhantomStorage__NoGuardianInvitation(msg.sender);
        address oldGuardian = storageGuardian;
        storageGuardian = newStorageGuardian;
        delete newStorageGuardian;
        emit GuardianChanged(oldGuardian, storageGuardian);
    }

    function getDeployedStatus() external view override returns (bool) {
        return storageInit;
    }

    function setDeployedStatus() external {
        if (msg.sender != storageGuardian) revert PhantomStorage__NotStorageGuardian(msg.sender);
        storageInit = true;
    }

    //=================================================================================================================
    // Accessors
    //=================================================================================================================

    /// @param _key The key for the record
    function getAddress(bytes32 _key) external view override returns (address r) {
        return addressStorage[_key];
    }

    /// @param _key The key for the record
    function getUint(bytes32 _key) external view override returns (uint256 r) {
        return uintStorage[_key];
    }

    /// @param _key The key for the record
    function getString(bytes32 _key) external view override returns (string memory) {
        return stringStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes(bytes32 _key) external view override returns (bytes memory) {
        return bytesStorage[_key];
    }

    /// @param _key The key for the record
    function getBool(bytes32 _key) external view override returns (bool r) {
        return booleanStorage[_key];
    }

    /// @param _key The key for the record
    function getInt(bytes32 _key) external view override returns (int256 r) {
        return intStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes32(bytes32 _key) external view override returns (bytes32 r) {
        return bytes32Storage[_key];
    }

    //=================================================================================================================
    // Accessors Arrays
    //=================================================================================================================

    /// @param _key The key for the record
    function getAddressArray(bytes32 _key) external view override returns (address[] memory r) {
        return addressArrayStorage[_key];
    }

    /// @param _key The key for the record
    function getUintArray(bytes32 _key) external view override returns (uint256[] memory r) {
        return uintArrayStorage[_key];
    }

    /// @param _key The key for the record
    function getStringArray(bytes32 _key) external view override returns (string[] memory) {
        return stringArrayStorage[_key];
    }

    /// @param _key The key for the record
    function getBytesArray(bytes32 _key) external view override returns (bytes[] memory) {
        return bytesArrayStorage[_key];
    }

    /// @param _key The key for the record
    function getBoolArray(bytes32 _key) external view override returns (bool[] memory r) {
        return booleanArrayStorage[_key];
    }

    /// @param _key The key for the record
    function getIntArray(bytes32 _key) external view override returns (int256[] memory r) {
        return intArrayStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes32Array(bytes32 _key) external view override returns (bytes32[] memory r) {
        return bytes32ArrayStorage[_key];
    }

    //=================================================================================================================
    // Mutators
    //=================================================================================================================

    /// @param _key The key for the record
    function setAddress(bytes32 _key, address _value) external override onlyRegisteredContracts {
        addressStorage[_key] = _value;
    }

    // @param _key The key for the record
    function setUint(bytes32 _key, uint256 _value) external override onlyRegisteredContracts {
        uintStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setString(bytes32 _key, string calldata _value) external override onlyRegisteredContracts {
        stringStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes(bytes32 _key, bytes calldata _value) external override onlyRegisteredContracts {
        bytesStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBool(bytes32 _key, bool _value) external override onlyRegisteredContracts {
        booleanStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setInt(bytes32 _key, int256 _value) external override onlyRegisteredContracts {
        intStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes32(bytes32 _key, bytes32 _value) external override onlyRegisteredContracts {
        bytes32Storage[_key] = _value;
    }

    //=================================================================================================================
    // Mutators Arrays
    //=================================================================================================================

    /// @param _key The key for the record
    function setAddressArray(bytes32 _key, address[] memory _value) external override onlyRegisteredContracts {
        addressArrayStorage[_key] = _value;
    }

    // @param _key The key for the record
    function setUintArray(bytes32 _key, uint256[] memory _value) external override onlyRegisteredContracts {
        uintArrayStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setStringArray(bytes32 _key, string[] memory _value) external override onlyRegisteredContracts {
        stringArrayStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytesArray(bytes32 _key, bytes[] memory _value) external override onlyRegisteredContracts {
        bytesArrayStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBoolArray(bytes32 _key, bool[] memory _value) external override onlyRegisteredContracts {
        booleanArrayStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setIntArray(bytes32 _key, int256[] memory _value) external override onlyRegisteredContracts {
        intArrayStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes32Array(bytes32 _key, bytes32[] memory _value) external override onlyRegisteredContracts {
        bytes32ArrayStorage[_key] = _value;
    }

    //=================================================================================================================
    // Deletion
    //=================================================================================================================

    /// @param _key The key for the record
    function deleteBytes32(bytes32 _key) external override onlyRegisteredContracts {
        delete bytes32Storage[_key];
    }

    /// @param _key The key for the record
    function deleteAddress(bytes32 _key) external override onlyRegisteredContracts {
        delete addressStorage[_key];
    }

    /// @param _key The key for the record
    function deleteUint(bytes32 _key) external override onlyRegisteredContracts {
        delete uintStorage[_key];
    }

    /// @param _key The key for the record
    function deleteString(bytes32 _key) external override onlyRegisteredContracts {
        delete stringStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes(bytes32 _key) external override onlyRegisteredContracts {
        delete bytesStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBool(bytes32 _key) external override onlyRegisteredContracts {
        delete booleanStorage[_key];
    }

    /// @param _key The key for the record
    function deleteInt(bytes32 _key) external override onlyRegisteredContracts {
        delete intStorage[_key];
    }

    //=================================================================================================================
    // Deletion Arrays
    //=================================================================================================================

    /// @param _key The key for the record
    function deleteBytes32Array(bytes32 _key) external override onlyRegisteredContracts {
        delete bytes32ArrayStorage[_key];
    }

    /// @param _key The key for the record
    function deleteAddressArray(bytes32 _key) external override onlyRegisteredContracts {
        delete addressArrayStorage[_key];
    }

    /// @param _key The key for the record
    function deleteUintArray(bytes32 _key) external override onlyRegisteredContracts {
        delete uintArrayStorage[_key];
    }

    /// @param _key The key for the record
    function deleteStringArray(bytes32 _key) external override onlyRegisteredContracts {
        delete stringArrayStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytesArray(bytes32 _key) external override onlyRegisteredContracts {
        delete bytesArrayStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBoolArray(bytes32 _key) external override onlyRegisteredContracts {
        delete booleanArrayStorage[_key];
    }

    /// @param _key The key for the record
    function deleteIntArray(bytes32 _key) external override onlyRegisteredContracts {
        delete intArrayStorage[_key];
    }

    //=================================================================================================================
    // Arithmetic
    //=================================================================================================================

    /// @param _key The key for the record
    /// @param _amount An amount to add to the record's value
    function addUint(bytes32 _key, uint256 _amount) external override onlyRegisteredContracts {
        uintStorage[_key] = uintStorage[_key] + _amount;
    }

    /// @param _key The key for the record
    /// @param _amount An amount to subtract from the record's value
    function subUint(bytes32 _key, uint256 _amount) external override onlyRegisteredContracts {
        uintStorage[_key] = uintStorage[_key] - _amount;
    }
}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title PhantomStorageKeys
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice Stores keys to use for lookup in the PhantomStorage() contract
 */
abstract contract PhantomStorageKeys {
    //=================================================================================================================
    // Declarations
    //=================================================================================================================

    _security internal security = _security("security.addressof", "security.name", "security.registered");

    _phantom internal phantom =
        _phantom(
            _contracts(
                "phantom.contracts.alphaswap",
                "phantom.contracts.founders",
                "phantom.contracts.staking",
                "phantom.contracts.stakingwarmup",
                "phantom.contracts.bonding",
                "phantom.contracts.phm",
                "phantom.contracts.sphm",
                "phantom.contracts.gphm",
                "phantom.contracts.aphm",
                "phantom.contracts.fphm",
                "phantom.contracts.vault",
                "phantom.contracts.treasury",
                "phantom.contracts.spirit_router",
                "phantom.contracts.yearn_router",
                "phantom.contracts.executor"
            ),
            _treasury(
                "phantom.treasury.approved.external.address",
                _treasuryaccounts(
                    "phantom.treasury.account_key.venturecapital",
                    "phantom.treasury.account_key.dao",
                    "phantom.treasury.account_key.reserves"
                ),
                "phantom.treasury.balance"
            ),
            _allocator(
                _tokens(
                    _token_addresses(
                        "phantom.allocator.tokens.address.dai",
                        "phantom.allocator.tokens.address.wftm",
                        "phantom.allocator.tokens.address.mim",
                        "phantom.allocator.tokens.address.dai_phm_lp",
                        "phantom.allocator.tokens.address.spirit"
                    ),
                    "phantom.allocator.tokens.destinations",
                    "phantom.allocator.tokens.dest_percentages",
                    "phantom.allocator.tokens.lp",
                    "phantom.allocator.tokens.single"
                )
            ),
            _bonding(
                _bonding_user("phantom.bonding.user.nonce", "phantom.bonding.user.first_unredeemed_nonce"),
                "phantom.bonding.vestingblocks",
                "phantom.bonding.discount",
                "phantom.bonding.is_redeemed",
                "phantom.bonding.payout",
                "phantom.bonding.vests_at_block",
                "phantom.bonding.is_valid"
            ),
            _staking("phantom.staking.rebaseCounter", "phantom.staking.nextRebaseDeadline"),
            _founder(
                _founder_claims(
                    "phantom.founder.claims.initialAmount",
                    "phantom.founder.claims.remainingAmount",
                    "phantom.founder.claims.lastClaim"
                ),
                _founder_wallet_changes("phantom.founder.changes.newOwner"),
                "phantom.founder.vestingStarts"
            ),
            _routing(
                "phantom.routing.spirit_router_address",
                "phantom.routing.spirit_factory_address",
                "phantom.routing.spirit_gauge_address",
                "phantom.routing.spirit_gauge_proxy_address"
            ),
            _governor(
                "phantom.governor.votingDelay",
                "phantom.governor.votingPeriod",
                "phantom.governor.quorumPercentage",
                "phantom.governor.proposalThreshold"
            )
        );

    //=================================================================================================================
    // Definitions
    //=================================================================================================================

    struct _security {
        bytes addressof;
        bytes name;
        bytes registered;
    }

    struct _phantom {
        _contracts contracts;
        _treasury treasury;
        _allocator allocator;
        _bonding bonding;
        _staking staking;
        _founder founder;
        _routing routing;
        _governor governor;
    }

    struct _treasury {
        bytes approved_address;
        _treasuryaccounts account_keys;
        bytes balances;
    }

    struct _allocator {
        _tokens tokens;
    }

    struct _tokens {
        _token_addresses addresses;
        bytes destinations;
        bytes dest_percentage;
        bytes lp;
        bytes single;
    }

    struct _token_addresses {
        bytes dai;
        bytes wftm;
        bytes mim;
        bytes dai_phm_lp;
        bytes spirit;
    }

    struct _treasuryaccounts {
        bytes venturecapital;
        bytes dao;
        bytes reserves;
    }

    struct _vault {
        bytes something;
    }

    struct _routing {
        bytes spirit_router_address;
        bytes spirit_factory_address;
        bytes spirit_gauge_address;
        bytes spirit_gauge_proxy_address;
    }

    struct _bonding_user {
        bytes nonce;
        bytes first_unredeemed_nonce;
    }

    struct _bonding {
        _bonding_user user;
        bytes vestingblocks;
        bytes discount;
        bytes is_redeemed;
        bytes payout;
        bytes vests_at_block;
        bytes is_valid;
    }

    struct _staking {
        bytes rebaseCounter;
        bytes nextRebaseDeadline;
    }

    struct _founder {
        _founder_claims claims;
        _founder_wallet_changes changes;
        bytes vestingStarts;
    }

    struct _founder_claims {
        bytes initialAmount;
        bytes remainingAmount;
        bytes lastClaim;
    }

    struct _founder_wallet_changes {
        bytes newOwner;
    }

    struct _contracts {
        bytes alphaswap;
        bytes founders;
        bytes staking;
        bytes stakingwarmup;
        bytes bonding;
        bytes phm;
        bytes sphm;
        bytes gphm;
        bytes aphm;
        bytes fphm;
        bytes vault;
        bytes treasury;
        bytes spirit_router;
        bytes yearn_router;
        bytes executor;
    }

    struct _governor {
        bytes votingDelay;
        bytes votingPeriod;
        bytes quorumPercentage;
        bytes proposalThreshold;
    }
}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomStorage
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice The Interface of PhantomStorage()
 */
interface IPhantomStorage {

    //=================================================================================================================
    // Errors
    //=================================================================================================================
    
    error PhantomStorage__ContractNotRegistered(address contractAddress);
    error PhantomStorage__NotStorageGuardian(address user);
    error PhantomStorage__NoGuardianInvitation(address user);

    //=================================================================================================================
    // Events
    //=================================================================================================================

    event ContractRegistered(address contractRegistered);
    event GuardianChanged(address oldStorageGuardian, address newStorageGuardian);

    //=================================================================================================================
    // Deployment Status
    //=================================================================================================================

    function getDeployedStatus() external view returns (bool);
    function registerContract(bytes calldata contractName, address contractAddress) external;
    function unregisterContract(bytes calldata contractName) external;

    //=================================================================================================================
    // Guardian
    //=================================================================================================================

    function getGuardian() external view returns(address);
    function sendGuardianInvitation(address _newAddress) external;
    function acceptGuardianInvitation() external;

    //=================================================================================================================
    // Accessors
    //=================================================================================================================

    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    function getBytes32(bytes32 _key) external view returns (bytes32);

    function getAddressArray(bytes32 _key) external view returns (address[] memory);
    function getUintArray(bytes32 _key) external view returns (uint[] memory);
    function getStringArray(bytes32 _key) external view returns (string[] memory);
    function getBytesArray(bytes32 _key) external view returns (bytes[] memory);
    function getBoolArray(bytes32 _key) external view returns (bool[] memory);
    function getIntArray(bytes32 _key) external view returns (int[] memory);
    function getBytes32Array(bytes32 _key) external view returns (bytes32[] memory);

    //=================================================================================================================
    // Mutators
    //=================================================================================================================
    
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

    function setAddressArray(bytes32 _key, address[] memory _value) external;
    function setUintArray(bytes32 _key, uint[] memory _value) external;
    function setStringArray(bytes32 _key, string[] memory _value) external;
    function setBytesArray(bytes32 _key, bytes[] memory _value) external;
    function setBoolArray(bytes32 _key, bool[] memory _value) external;
    function setIntArray(bytes32 _key, int[] memory _value) external;
    function setBytes32Array(bytes32 _key, bytes32[] memory _value) external;

    //=================================================================================================================
    // Deletion
    //=================================================================================================================

    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;

    function deleteAddressArray(bytes32 _key) external;
    function deleteUintArray(bytes32 _key) external;
    function deleteStringArray(bytes32 _key) external;
    function deleteBytesArray(bytes32 _key) external;
    function deleteBoolArray(bytes32 _key) external;
    function deleteIntArray(bytes32 _key) external;
    function deleteBytes32Array(bytes32 _key) external;

    //=================================================================================================================
    // Arithmetic
    //=================================================================================================================

    function addUint(bytes32 _key, uint256 _amount) external;
    function subUint(bytes32 _key, uint256 _amount) external;
}