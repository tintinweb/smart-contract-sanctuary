/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

// Global Enums and Structs



struct BatchConfig {
    uint64 startBatchIndex; // the index of the first batch using this config
    uint64 startBlockNumber; // the block number from which on this config is applicable
    address[] keypers; // the keyper addresses
    uint64 threshold; // the threshold parameter
    uint64 batchSpan; // the duration of one batch in blocks
    uint64 batchSizeLimit; // the maximum size of a batch in bytes
    uint64 transactionSizeLimit; // the maximum size of each transaction in the batch in bytes
    uint64 transactionGasLimit; // the maximum amount of gas each transaction may use
    address feeReceiver; // the address receiving the collected fees
    address targetAddress; // the address of the contract responsible of executing transactions
    bytes4 targetFunctionSelector; // function of the target contract that executes transactions
    uint64 executionTimeout; // the number of blocks after which execution can be skipped
}

// Part: Context

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Part: ConfigContract

/// @title A contract that manages `BatchConfig` objects.
/// @dev The config objects are stored in sequence, with configs applicable to later batches being
///     lined up behind configs applicable to earlier batches (according to
///     `config.startBlockNumber`). The contract owner is entitled to add or remove configs at the
///     end at will as long as a notice of at least `configChangeHeadsUpBlocks` is given.
/// @dev To add a new config, first populate the `nextConfig` object accordingly and then schedule
///     it with `scheduleNextConfig`.
contract ConfigContract is Ownable {
    /// @notice The event emitted after a new config object has been scheduled.
    /// @param numConfigs The new number of configs stored.
    event ConfigScheduled(uint64 numConfigs);

    /// @notice The event emitted after the owner has unscheduled one or more config objects.
    /// @param numConfigs The new number of configs stored.
    event ConfigUnscheduled(uint64 numConfigs);

    BatchConfig[] public configs;
    BatchConfig public nextConfig;

    uint64 public immutable configChangeHeadsUpBlocks;

    constructor(uint64 headsUp) {
        configs.push(_zeroConfig());

        configChangeHeadsUpBlocks = headsUp;
    }

    function _zeroConfig() internal pure returns (BatchConfig memory) {
        return
            BatchConfig({
                startBatchIndex: 0,
                startBlockNumber: 0,
                keypers: new address[](0),
                threshold: 0,
                batchSpan: 0,
                batchSizeLimit: 0,
                transactionSizeLimit: 0,
                transactionGasLimit: 0,
                feeReceiver: address(0),
                targetAddress: address(0),
                targetFunctionSelector: bytes4(0),
                executionTimeout: 0
            });
    }

    function numConfigs() external view returns (uint64) {
        return uint64(configs.length);
    }

    /// @notice Get the config for a certain batch.
    /// @param batchIndex The index of the batch.
    function getConfig(uint64 batchIndex)
        external
        view
        returns (BatchConfig memory)
    {
        for (uint256 i = configs.length - 1; i >= 0; i--) {
            BatchConfig storage config = configs[i];
            if (config.startBatchIndex <= batchIndex) {
                return config;
            }
        }
        assert(false);
    }

    //
    // Config keyper getters
    //
    function configKeypers(uint64 configIndex, uint64 keyperIndex)
        external
        view
        returns (address)
    {
        return configs[configIndex].keypers[keyperIndex];
    }

    function configNumKeypers(uint64 configIndex)
        external
        view
        returns (uint64)
    {
        return uint64(configs[configIndex].keypers.length);
    }

    //
    // next config setters
    //
    function nextConfigSetStartBatchIndex(uint64 startBatchIndex)
        external
        onlyOwner
    {
        nextConfig.startBatchIndex = startBatchIndex;
    }

    function nextConfigSetStartBlockNumber(uint64 startBlockNumber)
        external
        onlyOwner
    {
        nextConfig.startBlockNumber = startBlockNumber;
    }

    function nextConfigSetThreshold(uint64 threshold) external onlyOwner {
        nextConfig.threshold = threshold;
    }

    function nextConfigSetBatchSpan(uint64 batchSpan) external onlyOwner {
        nextConfig.batchSpan = batchSpan;
    }

    function nextConfigSetBatchSizeLimit(uint64 batchSizeLimit)
        external
        onlyOwner
    {
        nextConfig.batchSizeLimit = batchSizeLimit;
    }

    function nextConfigSetTransactionSizeLimit(uint64 transactionSizeLimit)
        external
        onlyOwner
    {
        nextConfig.transactionSizeLimit = transactionSizeLimit;
    }

    function nextConfigSetTransactionGasLimit(uint64 transactionGasLimit)
        external
        onlyOwner
    {
        nextConfig.transactionGasLimit = transactionGasLimit;
    }

    function nextConfigSetFeeReceiver(address feeReceiver) external onlyOwner {
        nextConfig.feeReceiver = feeReceiver;
    }

    function nextConfigSetTargetAddress(address targetAddress)
        external
        onlyOwner
    {
        nextConfig.targetAddress = targetAddress;
    }

    function nextConfigSetTargetFunctionSelector(bytes4 targetFunctionSelector)
        external
        onlyOwner
    {
        nextConfig.targetFunctionSelector = targetFunctionSelector;
    }

    function nextConfigSetExecutionTimeout(uint64 executionTimeout)
        external
        onlyOwner
    {
        nextConfig.executionTimeout = executionTimeout;
    }

    function nextConfigAddKeypers(address[] calldata newKeypers)
        external
        onlyOwner
    {
        require(
            nextConfig.keypers.length <= type(uint64).max - newKeypers.length,
            "ConfigContract: number of keypers exceeds uint64"
        );
        for (uint64 i = 0; i < newKeypers.length; i++) {
            nextConfig.keypers.push(newKeypers[i]);
        }
    }

    function nextConfigRemoveKeypers(uint64 n) external onlyOwner {
        uint256 currentLength = nextConfig.keypers.length;
        if (n <= currentLength) {
            for (uint64 i = 0; i < n; i++) {
                nextConfig.keypers.pop();
            }
        } else {
            delete nextConfig.keypers;
        }
    }

    //
    // nextConfig keyper getters
    //
    function nextConfigKeypers(uint64 index) external view returns (address) {
        return nextConfig.keypers[index];
    }

    function nextConfigNumKeypers() external view returns (uint64) {
        return uint64(nextConfig.keypers.length);
    }

    //
    // Scheduling
    //

    /// @notice Finalize the `nextConfig` object and add it to the end of the config sequence.
    /// @notice `startBlockNumber` of the next config must be at least `configChangeHeadsUpBlocks`
    ///     blocks or the batch span of the current config in the future, whatever is greater.
    /// @notice The transition between the next config and the config currently at the end of the
    ///     config sequence must be seamless, i.e., the batches must not be cut short.
    function scheduleNextConfig() external onlyOwner {
        require(
            configs.length < type(uint64).max - 1,
            "ConfigContract: number of configs exceeds uint64"
        );
        BatchConfig memory config = configs[configs.length - 1];

        // check start block is not too early
        uint64 headsUp = configChangeHeadsUpBlocks;
        if (config.batchSpan > headsUp) {
            headsUp = config.batchSpan;
        }
        uint64 earliestStart = uint64(block.number) + headsUp + 1;
        require(
            nextConfig.startBlockNumber >= earliestStart,
            "ConfigContract: start block too early"
        );

        // check transition is seamless
        if (config.batchSpan > 0) {
            require(
                nextConfig.startBatchIndex > config.startBatchIndex,
                "ConfigContract: start batch index too small"
            );
            uint64 batchDelta =
                nextConfig.startBatchIndex - config.startBatchIndex;
            require(
                config.startBlockNumber + config.batchSpan * batchDelta ==
                    nextConfig.startBlockNumber,
                "ConfigContract: config transition not seamless"
            );
        } else {
            require(
                nextConfig.startBatchIndex == config.startBatchIndex,
                "ConfigContract: transition from inactive config with wrong start index"
            );
        }

        configs.push(nextConfig);
        nextConfig = _zeroConfig();

        emit ConfigScheduled(uint64(configs.length));
    }

    /// @notice Remove configs from the end.
    /// @param fromStartBlockNumber All configs with a start block number greater than or equal
    ///     to this will be removed.
    /// @notice `fromStartBlockNumber` must be `configChangeHeadsUpBlocks` blocks in the future.
    /// @notice This method can remove one or more configs. If no config would be removed, an error
    ///     is thrown.
    function unscheduleConfigs(uint64 fromStartBlockNumber) external onlyOwner {
        require(
            fromStartBlockNumber > block.number + configChangeHeadsUpBlocks,
            "ConfigContract: from start block too early"
        );

        uint64 lengthBefore = uint64(configs.length);

        for (uint256 i = configs.length - 1; i > 0; i--) {
            BatchConfig storage config = configs[i];
            if (config.startBlockNumber >= fromStartBlockNumber) {
                configs.pop();
            } else {
                break;
            }
        }

        require(
            configs.length < lengthBefore,
            "ConfigContract: no configs unscheduled"
        );
        emit ConfigUnscheduled(uint64(configs.length));
    }
}

// File: KeyBroadcastContract.sol

/// @title A contract that keypers can use to vote on eon public keys. For each eon public key
///     generated, the keypers are expected to submit one vote. The contract logs the number of
///     votes so that users can only pick keys once they have reached votes from enough keypers
///     and thus have confidence that the key is actually correct.
contract KeyBroadcastContract {
    /// @notice The event emitted when a keyper voted on an eon key.
    /// @param keyper The address of the keyper who sent the vote.
    /// @param startBatchIndex The index of the first batch for which the key should be used.
    /// @param key The eon public key for which the keyper voted.
    /// @param numVotes The number of keypers (including this one) who have voted for the key so
    ///     far.
    event Voted(
        address indexed keyper,
        uint64 startBatchIndex,
        bytes key,
        uint64 numVotes
    );

    ConfigContract public configContract;
    mapping(uint64 => mapping(address => bool)) private _voted; // start batch index => keyper => voted or not
    mapping(uint64 => mapping(bytes32 => uint64)) private _numVotes; // start batch index => key hash => number of votes
    mapping(bytes32 => bytes) private _keys; // key hash => key

    mapping(uint64 => bytes32) private _bestKeyHashes;
    mapping(uint64 => uint64) private _bestKeyNumVotes;

    constructor(address configContractAddress) {
        configContract = ConfigContract(configContractAddress);
    }

    /// @notice Submit a vote.
    /// @notice Can only be called by keypers defined in the config responsible for
    ///     `startBatchIndex`, and only once per `startBatchIndex`.
    /// @param keyperIndex The index of the calling keyper in the batch config.
    /// @param startBatchIndex The index of the first batch for which the key should be used.
    /// @param key The eon public key to vote for.
    function vote(
        uint64 keyperIndex,
        uint64 startBatchIndex,
        bytes memory key
    ) public {
        BatchConfig memory config = configContract.getConfig(startBatchIndex);
        require(
            config.batchSpan > 0,
            "KeyBroadcastContract: config is inactive"
        );

        require(
            keyperIndex < config.keypers.length,
            "KeyBroadcastContract: keyper index out of range"
        );
        require(
            msg.sender == config.keypers[keyperIndex],
            "KeyBroadcastContract: sender is not keyper"
        );

        require(
            !_voted[startBatchIndex][msg.sender],
            "KeyBroadcastContract: keyper has already voted"
        );

        bytes32 keyHash = keccak256(key);
        // store the key if it hasn't already
        if (_keys[keyHash].length == 0 && key.length >= 0) {
            _keys[keyHash] = key;
        }

        // count vote
        uint64 numVotes = _numVotes[startBatchIndex][keyHash] + 1;
        _voted[startBatchIndex][msg.sender] = true;
        _numVotes[startBatchIndex][keyHash] = numVotes;

        if (numVotes > _bestKeyNumVotes[startBatchIndex]) {
            _bestKeyNumVotes[startBatchIndex] = numVotes;
            _bestKeyHashes[startBatchIndex] = keyHash;
        }

        emit Voted({
            keyper: msg.sender,
            startBatchIndex: startBatchIndex,
            key: key,
            numVotes: numVotes
        });
    }

    function hasVoted(address keyper, uint64 startBatchIndex)
        public
        view
        returns (bool)
    {
        return _voted[startBatchIndex][keyper];
    }

    function getNumVotes(uint64 startBatchIndex, bytes memory key)
        public
        view
        returns (uint64)
    {
        return _numVotes[startBatchIndex][keccak256(key)];
    }

    function getBestKeyHash(uint64 startBatchIndex)
        public
        view
        returns (bytes32)
    {
        return _bestKeyHashes[startBatchIndex];
    }

    function getBestKey(uint64 startBatchIndex)
        public
        view
        returns (bytes memory)
    {
        return _keys[_bestKeyHashes[startBatchIndex]];
    }

    function getBestKeyNumVotes(uint64 startBatchIndex)
        public
        view
        returns (uint256)
    {
        return _bestKeyNumVotes[startBatchIndex];
    }
}