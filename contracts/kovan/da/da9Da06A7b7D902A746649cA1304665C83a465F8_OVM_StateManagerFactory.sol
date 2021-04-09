// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";

/* Interface Imports */
import { iOVM_StateManager } from "../../iOVM/execution/iOVM_StateManager.sol";

/**
 * @title OVM_StateManager
 * @dev The State Manager contract holds all storage values for contracts in the OVM. It can only be written to by the
 * the Execution Manager and State Transitioner. It runs on L1 during the setup and execution of a fraud proof.
 * The same logic runs on L2, but has been implemented as a precompile in the L2 go-ethereum client
 * (see https://github.com/ethereum-optimism/go-ethereum/blob/master/core/vm/ovm_state_manager.go).
 * 
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_StateManager is iOVM_StateManager {

    /*************
     * Constants *
     *************/

    bytes32 constant internal EMPTY_ACCOUNT_STORAGE_ROOT = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;
    bytes32 constant internal EMPTY_ACCOUNT_CODE_HASH =    0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    bytes32 constant internal STORAGE_XOR_VALUE =          0xFEEDFACECAFEBEEFFEEDFACECAFEBEEFFEEDFACECAFEBEEFFEEDFACECAFEBEEF;


    /*************
     * Variables *
     *************/

    address override public owner;
    address override public ovmExecutionManager;
    mapping (address => Lib_OVMCodec.Account) internal accounts;
    mapping (address => mapping (bytes32 => bytes32)) internal contractStorage;
    mapping (address => mapping (bytes32 => bool)) internal verifiedContractStorage;
    mapping (bytes32 => ItemState) internal itemStates;
    uint256 internal totalUncommittedAccounts;
    uint256 internal totalUncommittedContractStorage;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _owner Address of the owner of this contract.
     */
    constructor(
        address _owner
    )
    {
        owner = _owner;
    }


    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Simple authentication, this contract should only be accessible to the owner (which is expected to be the State Transitioner during `PRE_EXECUTION` 
     * or the OVM_ExecutionManager during transaction execution.
     */
    modifier authenticated() {
        // owner is the State Transitioner
        require(
            msg.sender == owner || msg.sender == ovmExecutionManager,
            "Function can only be called by authenticated addresses"
        );
        _;
    }

    /********************
     * Public Functions *
     ********************/

    /**
     * Checks whether a given address is allowed to modify this contract.
     * @param _address Address to check.
     * @return Whether or not the address can modify this contract.
     */
    function isAuthenticated(
        address _address
    )
        override
        public
        view
        returns (
            bool
        )
    {
        return (_address == owner || _address == ovmExecutionManager);
    }

    /**
     * Sets the address of the OVM_ExecutionManager.
     * @param _ovmExecutionManager Address of the OVM_ExecutionManager.
     */
    function setExecutionManager(
        address _ovmExecutionManager
    )
        override
        public
        authenticated
    {
        ovmExecutionManager = _ovmExecutionManager;
    }

    /**
     * Inserts an account into the state.
     * @param _address Address of the account to insert.
     * @param _account Account to insert for the given address.
     */
    function putAccount(
        address _address,
        Lib_OVMCodec.Account memory _account
    )
        override
        public
        authenticated
    {
        accounts[_address] = _account;
    }

    /**
     * Marks an account as empty.
     * @param _address Address of the account to mark.
     */
    function putEmptyAccount(
        address _address
    )
        override
        public
        authenticated
    {
        Lib_OVMCodec.Account storage account = accounts[_address];
        account.storageRoot = EMPTY_ACCOUNT_STORAGE_ROOT;
        account.codeHash = EMPTY_ACCOUNT_CODE_HASH;
    }

    /**
     * Retrieves an account from the state.
     * @param _address Address of the account to retrieve.
     * @return Account for the given address.
     */
    function getAccount(
        address _address
    )
        override
        public
        view
        returns (
            Lib_OVMCodec.Account memory
        )
    {
        return accounts[_address];
    }

    /**
     * Checks whether the state has a given account.
     * @param _address Address of the account to check.
     * @return Whether or not the state has the account.
     */
    function hasAccount(
        address _address
    )
        override
        public
        view
        returns (
            bool
        )
    {
        return accounts[_address].codeHash != bytes32(0);
    }

    /**
     * Checks whether the state has a given known empty account.
     * @param _address Address of the account to check.
     * @return Whether or not the state has the empty account.
     */
    function hasEmptyAccount(
        address _address
    )
        override
        public
        view
        returns (
            bool
        )
    {
        return (
            accounts[_address].codeHash == EMPTY_ACCOUNT_CODE_HASH
            && accounts[_address].nonce == 0
        );
    }

    /**
     * Sets the nonce of an account.
     * @param _address Address of the account to modify.
     * @param _nonce New account nonce.
     */
    function setAccountNonce(
        address _address,
        uint256 _nonce
    )
        override
        public
        authenticated
    {
        accounts[_address].nonce = _nonce;
    }

    /**
     * Gets the nonce of an account.
     * @param _address Address of the account to access.
     * @return Nonce of the account.
     */
    function getAccountNonce(
        address _address
    )
        override
        public
        view
        returns (
            uint256
        )
    {
        return accounts[_address].nonce;
    }

    /**
     * Retrieves the Ethereum address of an account.
     * @param _address Address of the account to access.
     * @return Corresponding Ethereum address.
     */
    function getAccountEthAddress(
        address _address
    )
        override
        public
        view
        returns (
            address
        )
    {
        return accounts[_address].ethAddress;
    }

    /**
     * Retrieves the storage root of an account.
     * @param _address Address of the account to access.
     * @return Corresponding storage root.
     */
    function getAccountStorageRoot(
        address _address
    )
        override
        public
        view
        returns (
            bytes32
        )
    {
        return accounts[_address].storageRoot;
    }

    /**
     * Initializes a pending account (during CREATE or CREATE2) with the default values.
     * @param _address Address of the account to initialize.
     */
    function initPendingAccount(
        address _address
    )
        override
        public
        authenticated
    {
        Lib_OVMCodec.Account storage account = accounts[_address];
        account.nonce = 1;
        account.storageRoot = EMPTY_ACCOUNT_STORAGE_ROOT;
        account.codeHash = EMPTY_ACCOUNT_CODE_HASH;
        account.isFresh = true;
    }

    /**
     * Finalizes the creation of a pending account (during CREATE or CREATE2).
     * @param _address Address of the account to finalize.
     * @param _ethAddress Address of the account's associated contract on Ethereum.
     * @param _codeHash Hash of the account's code.
     */
    function commitPendingAccount(
        address _address,
        address _ethAddress,
        bytes32 _codeHash
    )
        override
        public
        authenticated
    {
        Lib_OVMCodec.Account storage account = accounts[_address];
        account.ethAddress = _ethAddress;
        account.codeHash = _codeHash;
    }

    /**
     * Checks whether an account has already been retrieved, and marks it as retrieved if not.
     * @param _address Address of the account to check.
     * @return Whether or not the account was already loaded.
     */
    function testAndSetAccountLoaded(
        address _address
    )
        override
        public
        authenticated
        returns (
            bool
        )
    {
        return _testAndSetItemState(
            _getItemHash(_address),
            ItemState.ITEM_LOADED
        );
    }

    /**
     * Checks whether an account has already been modified, and marks it as modified if not.
     * @param _address Address of the account to check.
     * @return Whether or not the account was already modified.
     */
    function testAndSetAccountChanged(
        address _address
    )
        override
        public
        authenticated
        returns (
            bool
        )
    {
        return _testAndSetItemState(
            _getItemHash(_address),
            ItemState.ITEM_CHANGED
        );
    }

    /**
     * Attempts to mark an account as committed.
     * @param _address Address of the account to commit.
     * @return Whether or not the account was committed.
     */
    function commitAccount(
        address _address
    )
        override
        public
        authenticated
        returns (
            bool
        )
    {
        bytes32 item = _getItemHash(_address);
        if (itemStates[item] != ItemState.ITEM_CHANGED) {
            return false;
        }

        itemStates[item] = ItemState.ITEM_COMMITTED;
        totalUncommittedAccounts -= 1;

        return true;
    }

    /**
     * Increments the total number of uncommitted accounts.
     */
    function incrementTotalUncommittedAccounts()
        override
        public
        authenticated
    {
        totalUncommittedAccounts += 1;
    }

    /**
     * Gets the total number of uncommitted accounts.
     * @return Total uncommitted accounts.
     */
    function getTotalUncommittedAccounts()
        override
        public
        view
        returns (
            uint256
        )
    {
        return totalUncommittedAccounts;
    }

    /**
     * Checks whether a given account was changed during execution.
     * @param _address Address to check.
     * @return Whether or not the account was changed.
     */
    function wasAccountChanged(
        address _address
    )
        override
        public
        view
        returns (
            bool
        )
    {
        bytes32 item = _getItemHash(_address);
        return itemStates[item] >= ItemState.ITEM_CHANGED;
    }

    /**
     * Checks whether a given account was committed after execution.
     * @param _address Address to check.
     * @return Whether or not the account was committed.
     */
    function wasAccountCommitted(
        address _address
    )
        override
        public
        view
        returns (
            bool
        )
    {
        bytes32 item = _getItemHash(_address);
        return itemStates[item] >= ItemState.ITEM_COMMITTED;
    }


    /************************************
     * Public Functions: Storage Access *
     ************************************/

    /**
     * Changes a contract storage slot value.
     * @param _contract Address of the contract to modify.
     * @param _key 32 byte storage slot key.
     * @param _value 32 byte storage slot value.
     */
    function putContractStorage(
        address _contract,
        bytes32 _key,
        bytes32 _value
    )
        override
        public
        authenticated
    {
        // A hilarious optimization. `SSTORE`ing a value of `bytes32(0)` is common enough that it's
        // worth populating this with a non-zero value in advance (during the fraud proof
        // initialization phase) to cut the execution-time cost down to 5000 gas.
        contractStorage[_contract][_key] = _value ^ STORAGE_XOR_VALUE;

        // Only used when initially populating the contract storage. OVM_ExecutionManager will
        // perform a `hasContractStorage` INVALID_STATE_ACCESS check before putting any contract
        // storage because writing to zero when the actual value is nonzero causes a gas
        // discrepancy. Could be moved into a new `putVerifiedContractStorage` function, or
        // something along those lines.
        if (verifiedContractStorage[_contract][_key] == false) {
            verifiedContractStorage[_contract][_key] = true;
        }
    }

    /**
     * Retrieves a contract storage slot value.
     * @param _contract Address of the contract to access.
     * @param _key 32 byte storage slot key.
     * @return 32 byte storage slot value.
     */
    function getContractStorage(
        address _contract,
        bytes32 _key
    )
        override
        public
        view
        returns (
            bytes32
        )
    {
        // Storage XOR system doesn't work for newly created contracts that haven't set this
        // storage slot value yet.
        if (
            verifiedContractStorage[_contract][_key] == false
            && accounts[_contract].isFresh
        ) {
            return bytes32(0);
        }

        // See `putContractStorage` for more information about the XOR here.
        return contractStorage[_contract][_key] ^ STORAGE_XOR_VALUE;
    }

    /**
     * Checks whether a contract storage slot exists in the state.
     * @param _contract Address of the contract to access.
     * @param _key 32 byte storage slot key.
     * @return Whether or not the key was set in the state.
     */
    function hasContractStorage(
        address _contract,
        bytes32 _key
    )
        override
        public
        view
        returns (
            bool
        )
    {
        return verifiedContractStorage[_contract][_key] || accounts[_contract].isFresh;
    }

    /**
     * Checks whether a storage slot has already been retrieved, and marks it as retrieved if not.
     * @param _contract Address of the contract to check.
     * @param _key 32 byte storage slot key.
     * @return Whether or not the slot was already loaded.
     */
    function testAndSetContractStorageLoaded(
        address _contract,
        bytes32 _key
    )
        override
        public
        authenticated
        returns (
            bool
        )
    {
        return _testAndSetItemState(
            _getItemHash(_contract, _key),
            ItemState.ITEM_LOADED
        );
    }

    /**
     * Checks whether a storage slot has already been modified, and marks it as modified if not.
     * @param _contract Address of the contract to check.
     * @param _key 32 byte storage slot key.
     * @return Whether or not the slot was already modified.
     */
    function testAndSetContractStorageChanged(
        address _contract,
        bytes32 _key
    )
        override
        public
        authenticated
        returns (
            bool
        )
    {
        return _testAndSetItemState(
            _getItemHash(_contract, _key),
            ItemState.ITEM_CHANGED
        );
    }

    /**
     * Attempts to mark a storage slot as committed.
     * @param _contract Address of the account to commit.
     * @param _key 32 byte slot key to commit.
     * @return Whether or not the slot was committed.
     */
    function commitContractStorage(
        address _contract,
        bytes32 _key
    )
        override
        public
        authenticated
        returns (
            bool
        )
    {
        bytes32 item = _getItemHash(_contract, _key);
        if (itemStates[item] != ItemState.ITEM_CHANGED) {
            return false;
        }

        itemStates[item] = ItemState.ITEM_COMMITTED;
        totalUncommittedContractStorage -= 1;

        return true;
    }

    /**
     * Increments the total number of uncommitted storage slots.
     */
    function incrementTotalUncommittedContractStorage()
        override
        public
        authenticated
    {
        totalUncommittedContractStorage += 1;
    }

    /**
     * Gets the total number of uncommitted storage slots.
     * @return Total uncommitted storage slots.
     */
    function getTotalUncommittedContractStorage()
        override
        public
        view
        returns (
            uint256
        )
    {
        return totalUncommittedContractStorage;
    }

    /**
     * Checks whether a given storage slot was changed during execution.
     * @param _contract Address to check.
     * @param _key Key of the storage slot to check.
     * @return Whether or not the storage slot was changed.
     */
    function wasContractStorageChanged(
        address _contract,
        bytes32 _key
    )
        override
        public
        view
        returns (
            bool
        )
    {
        bytes32 item = _getItemHash(_contract, _key);
        return itemStates[item] >= ItemState.ITEM_CHANGED;
    }

    /**
     * Checks whether a given storage slot was committed after execution.
     * @param _contract Address to check.
     * @param _key Key of the storage slot to check.
     * @return Whether or not the storage slot was committed.
     */
    function wasContractStorageCommitted(
        address _contract,
        bytes32 _key
    )
        override
        public
        view
        returns (
            bool
        )
    {
        bytes32 item = _getItemHash(_contract, _key);
        return itemStates[item] >= ItemState.ITEM_COMMITTED;
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Generates a unique hash for an address.
     * @param _address Address to generate a hash for.
     * @return Unique hash for the given address.
     */
    function _getItemHash(
        address _address
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return keccak256(abi.encodePacked(_address));
    }

    /**
     * Generates a unique hash for an address/key pair.
     * @param _contract Address to generate a hash for.
     * @param _key Key to generate a hash for.
     * @return Unique hash for the given pair.
     */
    function _getItemHash(
        address _contract,
        bytes32 _key
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return keccak256(abi.encodePacked(
            _contract,
            _key
        ));
    }

    /**
     * Checks whether an item is in a particular state (ITEM_LOADED or ITEM_CHANGED) and sets the
     * item to the provided state if not.
     * @param _item 32 byte item ID to check.
     * @param _minItemState Minimum state that must be satisfied by the item.
     * @return Whether or not the item was already in the state.
     */
    function _testAndSetItemState(
        bytes32 _item,
        ItemState _minItemState
    )
        internal
        returns (
            bool
        )
    {
        bool wasItemState = itemStates[_item] >= _minItemState;

        if (wasItemState == false) {
            itemStates[_item] = _minItemState;
        }

        return wasItemState;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Interface Imports */
import { iOVM_StateManager } from "../../iOVM/execution/iOVM_StateManager.sol";
import { iOVM_StateManagerFactory } from "../../iOVM/execution/iOVM_StateManagerFactory.sol";

/* Contract Imports */
import { OVM_StateManager } from "./OVM_StateManager.sol";

/**
 * @title OVM_StateManagerFactory
 * @dev The State Manager Factory is called by a State Transitioner's init code, to create a new
 * State Manager for use in the Fraud Verification process.
 * 
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_StateManagerFactory is iOVM_StateManagerFactory {

    /********************
     * Public Functions *
     ********************/

    /**
     * Creates a new OVM_StateManager
     * @param _owner Owner of the created contract.
     * @return New OVM_StateManager instance.
     */
    function create(
        address _owner
    )
        override
        public
        returns (
            iOVM_StateManager
        )
    {
        return new OVM_StateManager(_owner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";

/**
 * @title iOVM_StateManager
 */
interface iOVM_StateManager {

    /*******************
     * Data Structures *
     *******************/

    enum ItemState {
        ITEM_UNTOUCHED,
        ITEM_LOADED,
        ITEM_CHANGED,
        ITEM_COMMITTED
    }

    /***************************
     * Public Functions: Misc *
     ***************************/

    function isAuthenticated(address _address) external view returns (bool);

    /***************************
     * Public Functions: Setup *
     ***************************/

    function owner() external view returns (address _owner);
    function ovmExecutionManager() external view returns (address _ovmExecutionManager);
    function setExecutionManager(address _ovmExecutionManager) external;


    /************************************
     * Public Functions: Account Access *
     ************************************/

    function putAccount(address _address, Lib_OVMCodec.Account memory _account) external;
    function putEmptyAccount(address _address) external;
    function getAccount(address _address) external view returns (Lib_OVMCodec.Account memory _account);
    function hasAccount(address _address) external view returns (bool _exists);
    function hasEmptyAccount(address _address) external view returns (bool _exists);
    function setAccountNonce(address _address, uint256 _nonce) external;
    function getAccountNonce(address _address) external view returns (uint256 _nonce);
    function getAccountEthAddress(address _address) external view returns (address _ethAddress);
    function getAccountStorageRoot(address _address) external view returns (bytes32 _storageRoot);
    function initPendingAccount(address _address) external;
    function commitPendingAccount(address _address, address _ethAddress, bytes32 _codeHash) external;
    function testAndSetAccountLoaded(address _address) external returns (bool _wasAccountAlreadyLoaded);
    function testAndSetAccountChanged(address _address) external returns (bool _wasAccountAlreadyChanged);
    function commitAccount(address _address) external returns (bool _wasAccountCommitted);
    function incrementTotalUncommittedAccounts() external;
    function getTotalUncommittedAccounts() external view returns (uint256 _total);
    function wasAccountChanged(address _address) external view returns (bool);
    function wasAccountCommitted(address _address) external view returns (bool);


    /************************************
     * Public Functions: Storage Access *
     ************************************/

    function putContractStorage(address _contract, bytes32 _key, bytes32 _value) external;
    function getContractStorage(address _contract, bytes32 _key) external view returns (bytes32 _value);
    function hasContractStorage(address _contract, bytes32 _key) external view returns (bool _exists);
    function testAndSetContractStorageLoaded(address _contract, bytes32 _key) external returns (bool _wasContractStorageAlreadyLoaded);
    function testAndSetContractStorageChanged(address _contract, bytes32 _key) external returns (bool _wasContractStorageAlreadyChanged);
    function commitContractStorage(address _contract, bytes32 _key) external returns (bool _wasContractStorageCommitted);
    function incrementTotalUncommittedContractStorage() external;
    function getTotalUncommittedContractStorage() external view returns (uint256 _total);
    function wasContractStorageChanged(address _contract, bytes32 _key) external view returns (bool);
    function wasContractStorageCommitted(address _contract, bytes32 _key) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Contract Imports */
import { iOVM_StateManager } from "./iOVM_StateManager.sol";

/**
 * @title iOVM_StateManagerFactory
 */
interface iOVM_StateManagerFactory {

    /***************************************
     * Public Functions: Contract Creation *
     ***************************************/

    function create(
        address _owner
    )
        external
        returns (
            iOVM_StateManager _ovmStateManager
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_RLPReader } from "../rlp/Lib_RLPReader.sol";
import { Lib_RLPWriter } from "../rlp/Lib_RLPWriter.sol";
import { Lib_BytesUtils } from "../utils/Lib_BytesUtils.sol";
import { Lib_Bytes32Utils } from "../utils/Lib_Bytes32Utils.sol";
import { Lib_SafeExecutionManagerWrapper } from "../../libraries/wrappers/Lib_SafeExecutionManagerWrapper.sol";

/**
 * @title Lib_OVMCodec
 */
library Lib_OVMCodec {

    /*********
     * Enums *
     *********/

    enum EOASignatureType {
        EIP155_TRANSACTION,
        ETH_SIGNED_MESSAGE
    }

    enum QueueOrigin {
        SEQUENCER_QUEUE,
        L1TOL2_QUEUE
    }


    /***********
     * Structs *
     ***********/

    struct Account {
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
        address ethAddress;
        bool isFresh;
    }

    struct EVMAccount {
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
    }

    struct ChainBatchHeader {
        uint256 batchIndex;
        bytes32 batchRoot;
        uint256 batchSize;
        uint256 prevTotalElements;
        bytes extraData;
    }

    struct ChainInclusionProof {
        uint256 index;
        bytes32[] siblings;
    }

    struct Transaction {
        uint256 timestamp;
        uint256 blockNumber;
        QueueOrigin l1QueueOrigin;
        address l1TxOrigin;
        address entrypoint;
        uint256 gasLimit;
        bytes data;
    }

    struct TransactionChainElement {
        bool isSequenced;
        uint256 queueIndex;  // QUEUED TX ONLY
        uint256 timestamp;   // SEQUENCER TX ONLY
        uint256 blockNumber; // SEQUENCER TX ONLY
        bytes txData;        // SEQUENCER TX ONLY
    }

    struct QueueElement {
        bytes32 transactionHash;
        uint40 timestamp;
        uint40 blockNumber;
    }

    struct EIP155Transaction {
        uint256 nonce;
        uint256 gasPrice;
        uint256 gasLimit;
        address to;
        uint256 value;
        bytes data;
        uint256 chainId;
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Decodes an EOA transaction (i.e., native Ethereum RLP encoding).
     * @param _transaction Encoded EOA transaction.
     * @return Transaction decoded into a struct.
     */
    function decodeEIP155Transaction(
        bytes memory _transaction,
        bool _isEthSignedMessage
    )
        internal
        pure
        returns (
            EIP155Transaction memory
        )
    {
        if (_isEthSignedMessage) {
            (
                uint256 _nonce,
                uint256 _gasLimit,
                uint256 _gasPrice,
                uint256 _chainId,
                address _to,
                bytes memory _data
            ) = abi.decode(
                _transaction,
                (uint256, uint256, uint256, uint256, address ,bytes)
            );
            return EIP155Transaction({
                nonce: _nonce,
                gasPrice: _gasPrice,
                gasLimit: _gasLimit,
                to: _to,
                value: 0,
                data: _data,
                chainId: _chainId
            });
        } else {
            Lib_RLPReader.RLPItem[] memory decoded = Lib_RLPReader.readList(_transaction);

            return EIP155Transaction({
                nonce: Lib_RLPReader.readUint256(decoded[0]),
                gasPrice: Lib_RLPReader.readUint256(decoded[1]),
                gasLimit: Lib_RLPReader.readUint256(decoded[2]),
                to: Lib_RLPReader.readAddress(decoded[3]),
                value: Lib_RLPReader.readUint256(decoded[4]),
                data: Lib_RLPReader.readBytes(decoded[5]),
                chainId:  Lib_RLPReader.readUint256(decoded[6])
            });
        }
    }

    /**
     * Decompresses a compressed EIP155 transaction.
     * @param _transaction Compressed EIP155 transaction bytes.
     * @return Transaction parsed into a struct.
     */
    function decompressEIP155Transaction(
        bytes memory _transaction
    )
        internal
        returns (
            EIP155Transaction memory
        )
    {
        return EIP155Transaction({
            gasLimit: Lib_BytesUtils.toUint24(_transaction, 0),
            gasPrice: uint256(Lib_BytesUtils.toUint24(_transaction, 3)) * 1000000,
            nonce: Lib_BytesUtils.toUint24(_transaction, 6),
            to: Lib_BytesUtils.toAddress(_transaction, 9),
            data: Lib_BytesUtils.slice(_transaction, 29),
            chainId: Lib_SafeExecutionManagerWrapper.safeCHAINID(),
            value: 0
        });
    }

    /**
     * Encodes an EOA transaction back into the original transaction.
     * @param _transaction EIP155transaction to encode.
     * @param _isEthSignedMessage Whether or not this was an eth signed message.
     * @return Encoded transaction.
     */
    function encodeEIP155Transaction(
        EIP155Transaction memory _transaction,
        bool _isEthSignedMessage
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        if (_isEthSignedMessage) {
            return abi.encode(
                _transaction.nonce,
                _transaction.gasLimit,
                _transaction.gasPrice,
                _transaction.chainId,
                _transaction.to,
                _transaction.data
            );
        } else {
            bytes[] memory raw = new bytes[](9);

            raw[0] = Lib_RLPWriter.writeUint(_transaction.nonce);
            raw[1] = Lib_RLPWriter.writeUint(_transaction.gasPrice);
            raw[2] = Lib_RLPWriter.writeUint(_transaction.gasLimit);
            if (_transaction.to == address(0)) {
                raw[3] = Lib_RLPWriter.writeBytes('');
            } else {
                raw[3] = Lib_RLPWriter.writeAddress(_transaction.to);
            }
            raw[4] = Lib_RLPWriter.writeUint(0);
            raw[5] = Lib_RLPWriter.writeBytes(_transaction.data);
            raw[6] = Lib_RLPWriter.writeUint(_transaction.chainId);
            raw[7] = Lib_RLPWriter.writeBytes(bytes(''));
            raw[8] = Lib_RLPWriter.writeBytes(bytes(''));

            return Lib_RLPWriter.writeList(raw);
        }
    }

    /**
     * Encodes a standard OVM transaction.
     * @param _transaction OVM transaction to encode.
     * @return Encoded transaction bytes.
     */
    function encodeTransaction(
        Transaction memory _transaction
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        return abi.encodePacked(
            _transaction.timestamp,
            _transaction.blockNumber,
            _transaction.l1QueueOrigin,
            _transaction.l1TxOrigin,
            _transaction.entrypoint,
            _transaction.gasLimit,
            _transaction.data
        );
    }

    /**
     * Hashes a standard OVM transaction.
     * @param _transaction OVM transaction to encode.
     * @return Hashed transaction
     */
    function hashTransaction(
        Transaction memory _transaction
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return keccak256(encodeTransaction(_transaction));
    }

    /**
     * Converts an OVM account to an EVM account.
     * @param _in OVM account to convert.
     * @return Converted EVM account.
     */
    function toEVMAccount(
        Account memory _in
    )
        internal
        pure
        returns (
            EVMAccount memory
        )
    {
        return EVMAccount({
            nonce: _in.nonce,
            balance: _in.balance,
            storageRoot: _in.storageRoot,
            codeHash: _in.codeHash
        });
    }

    /**
     * @notice RLP-encodes an account state struct.
     * @param _account Account state struct.
     * @return RLP-encoded account state.
     */
    function encodeEVMAccount(
        EVMAccount memory _account
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        bytes[] memory raw = new bytes[](4);

        // Unfortunately we can't create this array outright because
        // Lib_RLPWriter.writeList will reject fixed-size arrays. Assigning
        // index-by-index circumvents this issue.
        raw[0] = Lib_RLPWriter.writeBytes(
            Lib_Bytes32Utils.removeLeadingZeros(
                bytes32(_account.nonce)
            )
        );
        raw[1] = Lib_RLPWriter.writeBytes(
            Lib_Bytes32Utils.removeLeadingZeros(
                bytes32(_account.balance)
            )
        );
        raw[2] = Lib_RLPWriter.writeBytes(abi.encodePacked(_account.storageRoot));
        raw[3] = Lib_RLPWriter.writeBytes(abi.encodePacked(_account.codeHash));

        return Lib_RLPWriter.writeList(raw);
    }

    /**
     * @notice Decodes an RLP-encoded account state into a useful struct.
     * @param _encoded RLP-encoded account state.
     * @return Account state struct.
     */
    function decodeEVMAccount(
        bytes memory _encoded
    )
        internal
        pure
        returns (
            EVMAccount memory
        )
    {
        Lib_RLPReader.RLPItem[] memory accountState = Lib_RLPReader.readList(_encoded);

        return EVMAccount({
            nonce: Lib_RLPReader.readUint256(accountState[0]),
            balance: Lib_RLPReader.readUint256(accountState[1]),
            storageRoot: Lib_RLPReader.readBytes32(accountState[2]),
            codeHash: Lib_RLPReader.readBytes32(accountState[3])
        });
    }

    /**
     * Calculates a hash for a given batch header.
     * @param _batchHeader Header to hash.
     * @return Hash of the header.
     */
    function hashBatchHeader(
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return keccak256(
            abi.encode(
                _batchHeader.batchRoot,
                _batchHeader.batchSize,
                _batchHeader.prevTotalElements,
                _batchHeader.extraData
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Lib_RLPReader
 * @dev Adapted from "RLPReader" by Hamdi Allam ([email protected]).
 */
library Lib_RLPReader {

    /*************
     * Constants *
     *************/

    uint256 constant internal MAX_LIST_LENGTH = 32;


    /*********
     * Enums *
     *********/

    enum RLPItemType {
        DATA_ITEM,
        LIST_ITEM
    }

    
    /***********
     * Structs *
     ***********/

    struct RLPItem {
        uint256 length;
        uint256 ptr;
    }
    

    /**********************
     * Internal Functions *
     **********************/
    
    /**
     * Converts bytes to a reference to memory position and length.
     * @param _in Input bytes to convert.
     * @return Output memory reference.
     */
    function toRLPItem(
        bytes memory _in
    )
        internal
        pure
        returns (
            RLPItem memory
        )
    {
        uint256 ptr;
        assembly {
            ptr := add(_in, 32)
        }

        return RLPItem({
            length: _in.length,
            ptr: ptr
        });
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            RLPItem[] memory
        )
    {
        (
            uint256 listOffset,
            ,
            RLPItemType itemType
        ) = _decodeLength(_in);

        require(
            itemType == RLPItemType.LIST_ITEM,
            "Invalid RLP list value."
        );

        // Solidity in-memory arrays can't be increased in size, but *can* be decreased in size by
        // writing to the length. Since we can't know the number of RLP items without looping over
        // the entire input, we'd have to loop twice to accurately size this array. It's easier to
        // simply set a reasonable maximum list length and decrease the size before we finish.
        RLPItem[] memory out = new RLPItem[](MAX_LIST_LENGTH);

        uint256 itemCount = 0;
        uint256 offset = listOffset;
        while (offset < _in.length) {
            require(
                itemCount < MAX_LIST_LENGTH,
                "Provided RLP list exceeds max list length."
            );

            (
                uint256 itemOffset,
                uint256 itemLength,
            ) = _decodeLength(RLPItem({
                length: _in.length - offset,
                ptr: _in.ptr + offset
            }));

            out[itemCount] = RLPItem({
                length: itemLength + itemOffset,
                ptr: _in.ptr + offset
            });

            itemCount += 1;
            offset += itemOffset + itemLength;
        }

        // Decrease the array size to match the actual item count.
        assembly {
            mstore(out, itemCount)
        }

        return out;
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(
        bytes memory _in
    )
        internal
        pure
        returns (
            RLPItem[] memory
        )
    {
        return readList(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        (
            uint256 itemOffset,
            uint256 itemLength,
            RLPItemType itemType
        ) = _decodeLength(_in);

        require(
            itemType == RLPItemType.DATA_ITEM,
            "Invalid RLP bytes value."
        );

        return _copy(_in.ptr, itemOffset, itemLength);
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(
        bytes memory _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        return readBytes(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            string memory
        )
    {
        return string(readBytes(_in));
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(
        bytes memory _in
    )
        internal
        pure
        returns (
            string memory
        )
    {
        return readString(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        require(
            _in.length <= 33,
            "Invalid RLP bytes32 value."
        );

        (
            uint256 itemOffset,
            uint256 itemLength,
            RLPItemType itemType
        ) = _decodeLength(_in);

        require(
            itemType == RLPItemType.DATA_ITEM,
            "Invalid RLP bytes32 value."
        );

        uint256 ptr = _in.ptr + itemOffset;
        bytes32 out;
        assembly {
            out := mload(ptr)

            // Shift the bytes over to match the item size.
            if lt(itemLength, 32) {
                out := div(out, exp(256, sub(32, itemLength)))
            }
        }

        return out;
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(
        bytes memory _in
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return readBytes32(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            uint256
        )
    {
        return uint256(readBytes32(_in));
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(
        bytes memory _in
    )
        internal
        pure
        returns (
            uint256
        )
    {
        return readUint256(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            bool
        )
    {
        require(
            _in.length == 1,
            "Invalid RLP boolean value."
        );

        uint256 ptr = _in.ptr;
        uint256 out;
        assembly {
            out := byte(0, mload(ptr))
        }

        require(
            out == 0 || out == 1,
            "Lib_RLPReader: Invalid RLP boolean value, must be 0 or 1"
        );

        return out != 0;
    }

    /**
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(
        bytes memory _in
    )
        internal
        pure
        returns (
            bool
        )
    {
        return readBool(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            address
        )
    {
        if (_in.length == 1) {
            return address(0);
        }

        require(
            _in.length == 21,
            "Invalid RLP address value."
        );

        return address(readUint256(_in));
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(
        bytes memory _in
    )
        internal
        pure
        returns (
            address
        )
    {
        return readAddress(
            toRLPItem(_in)
        );
    }

    /**
     * Reads the raw bytes of an RLP item.
     * @param _in RLP item to read.
     * @return Raw RLP bytes.
     */
    function readRawBytes(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        return _copy(_in);
    }


    /*********************
     * Private Functions *
     *********************/

    /**
     * Decodes the length of an RLP item.
     * @param _in RLP item to decode.
     * @return Offset of the encoded data.
     * @return Length of the encoded data.
     * @return RLP item type (LIST_ITEM or DATA_ITEM).
     */
    function _decodeLength(
        RLPItem memory _in
    )
        private
        pure
        returns (
            uint256,
            uint256,
            RLPItemType
        )
    {
        require(
            _in.length > 0,
            "RLP item cannot be null."
        );

        uint256 ptr = _in.ptr;
        uint256 prefix;
        assembly {
            prefix := byte(0, mload(ptr))
        }

        if (prefix <= 0x7f) {
            // Single byte.

            return (0, 1, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xb7) {
            // Short string.

            uint256 strLen = prefix - 0x80;
            
            require(
                _in.length > strLen,
                "Invalid RLP short string."
            );

            return (1, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xbf) {
            // Long string.
            uint256 lenOfStrLen = prefix - 0xb7;

            require(
                _in.length > lenOfStrLen,
                "Invalid RLP long string length."
            );

            uint256 strLen;
            assembly {
                // Pick out the string length.
                strLen := div(
                    mload(add(ptr, 1)),
                    exp(256, sub(32, lenOfStrLen))
                )
            }

            require(
                _in.length > lenOfStrLen + strLen,
                "Invalid RLP long string."
            );

            return (1 + lenOfStrLen, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xf7) {
            // Short list.
            uint256 listLen = prefix - 0xc0;

            require(
                _in.length > listLen,
                "Invalid RLP short list."
            );

            return (1, listLen, RLPItemType.LIST_ITEM);
        } else {
            // Long list.
            uint256 lenOfListLen = prefix - 0xf7;

            require(
                _in.length > lenOfListLen,
                "Invalid RLP long list length."
            );

            uint256 listLen;
            assembly {
                // Pick out the list length.
                listLen := div(
                    mload(add(ptr, 1)),
                    exp(256, sub(32, lenOfListLen))
                )
            }

            require(
                _in.length > lenOfListLen + listLen,
                "Invalid RLP long list."
            );

            return (1 + lenOfListLen, listLen, RLPItemType.LIST_ITEM);
        }
    }

    /**
     * Copies the bytes from a memory location.
     * @param _src Pointer to the location to read from.
     * @param _offset Offset to start reading from.
     * @param _length Number of bytes to read.
     * @return Copied bytes.
     */
    function _copy(
        uint256 _src,
        uint256 _offset,
        uint256 _length
    )
        private
        pure
        returns (
            bytes memory
        )
    {
        bytes memory out = new bytes(_length);
        if (out.length == 0) {
            return out;
        }

        uint256 src = _src + _offset;
        uint256 dest;
        assembly {
            dest := add(out, 32)
        }

        // Copy over as many complete words as we can.
        for (uint256 i = 0; i < _length / 32; i++) {
            assembly {
                mstore(dest, mload(src))
            }

            src += 32;
            dest += 32;
        }

        // Pick out the remaining bytes.
        uint256 mask = 256 ** (32 - (_length % 32)) - 1;
        assembly {
            mstore(
                dest,
                or(
                    and(mload(src), not(mask)),
                    and(mload(dest), mask)
                )
            )
        }

        return out;
    }

    /**
     * Copies an RLP item into bytes.
     * @param _in RLP item to copy.
     * @return Copied bytes.
     */
    function _copy(
        RLPItem memory _in
    )
        private
        pure
        returns (
            bytes memory
        )
    {
        return _copy(_in.ptr, 0, _in.length);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_BytesUtils } from "../utils/Lib_BytesUtils.sol";

/**
 * @title Lib_RLPWriter
 * @author Bakaoh (with modifications)
 */
library Lib_RLPWriter {

    /**********************
     * Internal Functions *
     **********************/

    /**
     * RLP encodes a byte string.
     * @param _in The byte string to encode.
     * @return _out The RLP encoded string in bytes.
     */
    function writeBytes(
        bytes memory _in
    )
        internal
        pure
        returns (
            bytes memory _out
        )
    {
        bytes memory encoded;

        if (_in.length == 1 && uint8(_in[0]) < 128) {
            encoded = _in;
        } else {
            encoded = abi.encodePacked(_writeLength(_in.length, 128), _in);
        }

        return encoded;
    }

    /**
     * RLP encodes a list of RLP encoded byte byte strings.
     * @param _in The list of RLP encoded byte strings.
     * @return _out The RLP encoded list of items in bytes.
     */
    function writeList(
        bytes[] memory _in
    )
        internal
        pure
        returns (
            bytes memory _out
        )
    {
        bytes memory list = _flatten(_in);
        return abi.encodePacked(_writeLength(list.length, 192), list);
    }

    /**
     * RLP encodes a string.
     * @param _in The string to encode.
     * @return _out The RLP encoded string in bytes.
     */
    function writeString(
        string memory _in
    )
        internal
        pure
        returns (
            bytes memory _out
        )
    {
        return writeBytes(bytes(_in));
    }

    /**
     * RLP encodes an address.
     * @param _in The address to encode.
     * @return _out The RLP encoded address in bytes.
     */
    function writeAddress(
        address _in
    )
        internal
        pure
        returns (
            bytes memory _out
        )
    {
        return writeBytes(abi.encodePacked(_in));
    }

    /**
     * RLP encodes a uint.
     * @param _in The uint256 to encode.
     * @return _out The RLP encoded uint256 in bytes.
     */
    function writeUint(
        uint256 _in
    )
        internal
        pure
        returns (
            bytes memory _out
        )
    {
        return writeBytes(_toBinary(_in));
    }

    /**
     * RLP encodes a bool.
     * @param _in The bool to encode.
     * @return _out The RLP encoded bool in bytes.
     */
    function writeBool(
        bool _in
    )
        internal
        pure
        returns (
            bytes memory _out
        )
    {
        bytes memory encoded = new bytes(1);
        encoded[0] = (_in ? bytes1(0x01) : bytes1(0x80));
        return encoded;
    }


    /*********************
     * Private Functions *
     *********************/

    /**
     * Encode the first byte, followed by the `len` in binary form if `length` is more than 55.
     * @param _len The length of the string or the payload.
     * @param _offset 128 if item is string, 192 if item is list.
     * @return _encoded RLP encoded bytes.
     */
    function _writeLength(
        uint256 _len,
        uint256 _offset
    )
        private
        pure
        returns (
            bytes memory _encoded
        )
    {
        bytes memory encoded;

        if (_len < 56) {
            encoded = new bytes(1);
            encoded[0] = byte(uint8(_len) + uint8(_offset));
        } else {
            uint256 lenLen;
            uint256 i = 1;
            while (_len / i != 0) {
                lenLen++;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = byte(uint8(lenLen) + uint8(_offset) + 55);
            for(i = 1; i <= lenLen; i++) {
                encoded[i] = byte(uint8((_len / (256**(lenLen-i))) % 256));
            }
        }

        return encoded;
    }

    /**
     * Encode integer in big endian binary form with no leading zeroes.
     * @notice TODO: This should be optimized with assembly to save gas costs.
     * @param _x The integer to encode.
     * @return _binary RLP encoded bytes.
     */
    function _toBinary(
        uint256 _x
    )
        private
        pure
        returns (
            bytes memory _binary
        )
    {
        bytes memory b = abi.encodePacked(_x);

        uint256 i = 0;
        for (; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }

        bytes memory res = new bytes(32 - i);
        for (uint256 j = 0; j < res.length; j++) {
            res[j] = b[i++];
        }

        return res;
    }

    /**
     * Copies a piece of memory to another location.
     * @notice From: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol.
     * @param _dest Destination location.
     * @param _src Source location.
     * @param _len Length of memory to copy.
     */
    function _memcpy(
        uint256 _dest,
        uint256 _src,
        uint256 _len
    )
        private
        pure
    {
        uint256 dest = _dest;
        uint256 src = _src;
        uint256 len = _len;

        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint256 mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * Flattens a list of byte strings into one byte string.
     * @notice From: https://github.com/sammayo/solidity-rlp-encoder/blob/master/RLPEncode.sol.
     * @param _list List of byte strings to flatten.
     * @return _flattened The flattened byte string.
     */
    function _flatten(
        bytes[] memory _list
    )
        private
        pure
        returns (
            bytes memory _flattened
        )
    {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint256 len;
        uint256 i = 0;
        for (; i < _list.length; i++) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint256 flattenedPtr;
        assembly { flattenedPtr := add(flattened, 0x20) }

        for(i = 0; i < _list.length; i++) {
            bytes memory item = _list[i];

            uint256 listPtr;
            assembly { listPtr := add(item, 0x20)}

            _memcpy(flattenedPtr, listPtr, item.length);
            flattenedPtr += _list[i].length;
        }

        return flattened;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Lib_Byte32Utils
 */
library Lib_Bytes32Utils {

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Converts a bytes32 value to a boolean. Anything non-zero will be converted to "true."
     * @param _in Input bytes32 value.
     * @return Bytes32 as a boolean.
     */
    function toBool(
        bytes32 _in
    )
        internal
        pure
        returns (
            bool
        )
    {
        return _in != 0;
    }

    /**
     * Converts a boolean to a bytes32 value.
     * @param _in Input boolean value.
     * @return Boolean as a bytes32.
     */
    function fromBool(
        bool _in
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return bytes32(uint256(_in ? 1 : 0));
    }

    /**
     * Converts a bytes32 value to an address. Takes the *last* 20 bytes.
     * @param _in Input bytes32 value.
     * @return Bytes32 as an address.
     */
    function toAddress(
        bytes32 _in
    )
        internal
        pure
        returns (
            address
        )
    {
        return address(uint160(uint256(_in)));
    }

    /**
     * Converts an address to a bytes32.
     * @param _in Input address value.
     * @return Address as a bytes32.
     */
    function fromAddress(
        address _in
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return bytes32(uint256(_in));
    }

    /**
     * Removes the leading zeros from a bytes32 value and returns a new (smaller) bytes value.
     * @param _in Input bytes32 value.
     * @return Bytes32 without any leading zeros.
     */
    function removeLeadingZeros(
        bytes32 _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        bytes memory out;

        assembly {
            // Figure out how many leading zero bytes to remove.
            let shift := 0
            for { let i := 0 } and(lt(i, 32), eq(byte(i, _in), 0)) { i := add(i, 1) } {
                shift := add(shift, 1)
            }

            // Reserve some space for our output and fix the free memory pointer.
            out := mload(0x40)
            mstore(0x40, add(out, 0x40))

            // Shift the value and store it into the output bytes.
            mstore(add(out, 0x20), shl(mul(shift, 8), _in))

            // Store the new size (with leading zero bytes removed) in the output byte size.
            mstore(out, sub(32, shift))
        }

        return out;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Lib_BytesUtils
 */
library Lib_BytesUtils {

    /**********************
     * Internal Functions *
     **********************/

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function slice(
        bytes memory _bytes,
        uint256 _start
    )
        internal
        pure
        returns (bytes memory)
    {
        if (_bytes.length - _start == 0) {
            return bytes('');
        }

        return slice(_bytes, _start, _bytes.length - _start);
    }

    function toBytes32PadLeft(
        bytes memory _bytes
    )
        internal
        pure
        returns (bytes32)
    {
        bytes32 ret;
        uint256 len = _bytes.length <= 32 ? _bytes.length : 32;
        assembly {
            ret := shr(mul(sub(32, len), 8), mload(add(_bytes, 32)))
        }
        return ret;
    }

    function toBytes32(
        bytes memory _bytes
    )
        internal
        pure
        returns (bytes32)
    {
        if (_bytes.length < 32) {
            bytes32 ret;
            assembly {
                ret := mload(add(_bytes, 32))
            }
            return ret;
        }

        return abi.decode(_bytes,(bytes32)); // will truncate if input length > 32 bytes
    }

    function toUint256(
        bytes memory _bytes
    )
        internal
        pure
        returns (uint256)
    {
        return uint256(toBytes32(_bytes));
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3 , "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toNibbles(
        bytes memory _bytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory nibbles = new bytes(_bytes.length * 2);

        for (uint256 i = 0; i < _bytes.length; i++) {
            nibbles[i * 2] = _bytes[i] >> 4;
            nibbles[i * 2 + 1] = bytes1(uint8(_bytes[i]) % 16);
        }

        return nibbles;
    }

    function fromNibbles(
        bytes memory _bytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory ret = new bytes(_bytes.length / 2);

        for (uint256 i = 0; i < ret.length; i++) {
            ret[i] = (_bytes[i * 2] << 4) | (_bytes[i * 2 + 1]);
        }

        return ret;
    }

    function equal(
        bytes memory _bytes,
        bytes memory _other
    )
        internal
        pure
        returns (bool)
    {
        return keccak256(_bytes) == keccak256(_other);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title Lib_ErrorUtils
 */
library Lib_ErrorUtils {

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Encodes an error string into raw solidity-style revert data.
     * (i.e. ascii bytes, prefixed with bytes4(keccak("Error(string))"))
     * Ref: https://docs.soliditylang.org/en/v0.8.2/control-structures.html?highlight=Error(string)#panic-via-assert-and-error-via-require
     * @param _reason Reason for the reversion.
     * @return Standard solidity revert data for the given reason.
     */
    function encodeRevertString(
        string memory _reason
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        return abi.encodeWithSignature(
            "Error(string)",
            _reason
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_ErrorUtils } from "../utils/Lib_ErrorUtils.sol";

/**
 * @title Lib_SafeExecutionManagerWrapper
 * @dev The Safe Execution Manager Wrapper provides functions which facilitate writing OVM safe 
 * code using the standard solidity compiler, by routing all its operations through the Execution 
 * Manager.
 * 
 * Compiler used: solc
 * Runtime target: OVM
 */
library Lib_SafeExecutionManagerWrapper {

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Performs a safe ovmCALL.
     * @param _gasLimit Gas limit for the call.
     * @param _target Address to call.
     * @param _calldata Data to send to the call.
     * @return _success Whether or not the call reverted.
     * @return _returndata Data returned by the call.
     */
    function safeCALL(
        uint256 _gasLimit,
        address _target,
        bytes memory _calldata
    )
        internal
        returns (
            bool _success,
            bytes memory _returndata
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmCALL(uint256,address,bytes)",
                _gasLimit,
                _target,
                _calldata
            )
        );

        return abi.decode(returndata, (bool, bytes));
    }

    /**
     * Performs a safe ovmDELEGATECALL.
     * @param _gasLimit Gas limit for the call.
     * @param _target Address to call.
     * @param _calldata Data to send to the call.
     * @return _success Whether or not the call reverted.
     * @return _returndata Data returned by the call.
     */
    function safeDELEGATECALL(
        uint256 _gasLimit,
        address _target,
        bytes memory _calldata
    )
        internal
        returns (
            bool _success,
            bytes memory _returndata
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmDELEGATECALL(uint256,address,bytes)",
                _gasLimit,
                _target,
                _calldata
            )
        );

        return abi.decode(returndata, (bool, bytes));
    }

    /**
     * Performs a safe ovmCREATE call.
     * @param _gasLimit Gas limit for the creation.
     * @param _bytecode Code for the new contract.
     * @return _contract Address of the created contract.
     */
    function safeCREATE(
        uint256 _gasLimit,
        bytes memory _bytecode
    )
        internal
        returns (
            address,
            bytes memory
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            _gasLimit,
            abi.encodeWithSignature(
                "ovmCREATE(bytes)",
                _bytecode
            )
        );

        return abi.decode(returndata, (address, bytes));
    }

    /**
     * Performs a safe ovmEXTCODESIZE call.
     * @param _contract Address of the contract to query the size of.
     * @return _EXTCODESIZE Size of the requested contract in bytes.
     */
    function safeEXTCODESIZE(
        address _contract
    )
        internal
        returns (
            uint256 _EXTCODESIZE
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmEXTCODESIZE(address)",
                _contract
            )
        );

        return abi.decode(returndata, (uint256));
    }

    /**
     * Performs a safe ovmCHAINID call.
     * @return _CHAINID Result of calling ovmCHAINID.
     */
    function safeCHAINID()
        internal
        returns (
            uint256 _CHAINID
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmCHAINID()"
            )
        );

        return abi.decode(returndata, (uint256));
    }

    /**
     * Performs a safe ovmCALLER call.
     * @return _CALLER Result of calling ovmCALLER.
     */
    function safeCALLER()
        internal
        returns (
            address _CALLER
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmCALLER()"
            )
        );

        return abi.decode(returndata, (address));
    }

    /**
     * Performs a safe ovmADDRESS call.
     * @return _ADDRESS Result of calling ovmADDRESS.
     */
    function safeADDRESS()
        internal
        returns (
            address _ADDRESS
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmADDRESS()"
            )
        );

        return abi.decode(returndata, (address));
    }

    /**
     * Performs a safe ovmGETNONCE call.
     * @return _nonce Result of calling ovmGETNONCE.
     */
    function safeGETNONCE()
        internal
        returns (
            uint256 _nonce
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmGETNONCE()"
            )
        );

        return abi.decode(returndata, (uint256));
    }

    /**
     * Performs a safe ovmINCREMENTNONCE call.
     */
    function safeINCREMENTNONCE()
        internal
    {
        _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmINCREMENTNONCE()"
            )
        );
    }

    /**
     * Performs a safe ovmCREATEEOA call.
     * @param _messageHash Message hash which was signed by EOA
     * @param _v v value of signature (0 or 1)
     * @param _r r value of signature
     * @param _s s value of signature
     */
    function safeCREATEEOA(
        bytes32 _messageHash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        internal
    {
        _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmCREATEEOA(bytes32,uint8,bytes32,bytes32)",
                _messageHash,
                _v,
                _r,
                _s
            )
        );
    }

    /**
     * Performs a safe REVERT.
     * @param _reason String revert reason to pass along with the REVERT.
     */
    function safeREVERT(
        string memory _reason
    )
        internal
    {
        _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmREVERT(bytes)",
                Lib_ErrorUtils.encodeRevertString(
                    _reason
                )
            )
        );
    }

    /**
     * Performs a safe "require".
     * @param _condition Boolean condition that must be true or will revert.
     * @param _reason String revert reason to pass along with the REVERT.
     */
    function safeREQUIRE(
        bool _condition,
        string memory _reason
    )
        internal
    {
        if (!_condition) {
            safeREVERT(
                _reason
            );
        }
    }

    /**
     * Performs a safe ovmSLOAD call.
     */
    function safeSLOAD(
        bytes32 _key
    )
        internal
        returns (
            bytes32
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmSLOAD(bytes32)",
                _key
            )
        );

        return abi.decode(returndata, (bytes32));
    }

    /**
     * Performs a safe ovmSSTORE call.
     */
    function safeSSTORE(
        bytes32 _key,
        bytes32 _value
    )
        internal
    {
        _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmSSTORE(bytes32,bytes32)",
                _key,
                _value
            )
        );
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * Performs an ovm interaction and the necessary safety checks.
     * @param _gasLimit Gas limit for the interaction.
     * @param _calldata Data to send to the OVM_ExecutionManager (encoded with sighash).
     * @return _returndata Data sent back by the OVM_ExecutionManager.
     */
    function _safeExecutionManagerInteraction(
        uint256 _gasLimit,
        bytes memory _calldata
    )
        private
        returns (
            bytes memory _returndata
        )
    {
        address ovmExecutionManager = msg.sender;
        (
            bool success,
            bytes memory returndata
        ) = ovmExecutionManager.call{gas: _gasLimit}(_calldata);

        if (success == false) {
            assembly {
                revert(add(returndata, 0x20), mload(returndata))
            }
        } else if (returndata.length == 1) {
            assembly {
                return(0, 1)
            }
        } else {
            return returndata;
        }
    }

    function _safeExecutionManagerInteraction(
        bytes memory _calldata
    )
        private
        returns (
            bytes memory _returndata
        )
    {
        return _safeExecutionManagerInteraction(
            gasleft(),
            _calldata
        );
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}