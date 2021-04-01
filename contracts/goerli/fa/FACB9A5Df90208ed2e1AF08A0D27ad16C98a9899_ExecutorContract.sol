/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

// Global Enums and Structs

enum TransactionType {Cipher, Plain}

struct CipherExecutionReceipt {
    bool executed;
    address executor;
    uint64 halfStep;
    bytes32 cipherBatchHash;
    bytes32 batchHash;
}
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

// Part: FeeBankContract

/// @title A contract that stores fees for later withdrawal
contract FeeBankContract {
    /// @notice The event emitted whenever ETH is deposited.
    /// @param depositor The address of the account making the deposit.
    /// @param receiver The address of the account eligible for withdrawal.
    /// @param amount The newly deposited amount.
    /// @param totalAmount The total amount the receiver can withdraw, including the new deposit.
    event DepositEvent(
        address depositor,
        address receiver,
        uint64 amount,
        uint64 totalAmount
    );

    /// @notice The event emitted whenever ETH is withdrawn.
    /// @param sender The address of the account that triggered the withdrawal.
    /// @param receiver The address of the account to which the ETH is sent.
    /// @param amount The withdrawn amount.
    /// @param totalAmount The remaining deposit.
    event WithdrawEvent(
        address sender,
        address receiver,
        uint64 amount,
        uint64 totalAmount
    );

    mapping(address => uint64) public deposits;

    /// @notice Deposit ETH for later withdrawal
    /// @param receiver Address of the account that is eligible for withdrawal.
    function deposit(address receiver) external payable {
        require(receiver != address(0), "FeeBank: receiver is zero address");
        require(msg.value > 0, "FeeBank: fee is zero");
        require(
            msg.value <= type(uint64).max - deposits[receiver],
            "FeeBank: balance would exceed uint64"
        );
        deposits[receiver] += uint64(msg.value);

        emit DepositEvent(
            msg.sender,
            receiver,
            uint64(msg.value),
            deposits[receiver]
        );
    }

    /// @notice Withdraw ETH previously deposited in favor of the caller.
    /// @param receiver The address to which the ETH will be sent.
    /// @param amount The amount to withdraw (must not be greater than the deposited amount)
    function withdraw(address receiver, uint64 amount) external {
        _withdraw(receiver, amount);
    }

    /// @notice Withdraw all ETH previously deposited in favor of the caller and send it to them.
    function withdraw() external {
        _withdraw(msg.sender, deposits[msg.sender]);
    }

    function _withdraw(address receiver, uint64 amount) internal {
        require(receiver != address(0), "FeeBank: receiver is zero address");
        uint64 depositBefore = deposits[msg.sender];
        require(depositBefore > 0, "FeeBank: deposit is empty");
        require(amount <= depositBefore, "FeeBank: amount exceeds deposit");
        deposits[msg.sender] = depositBefore - amount;
        (bool success, ) = receiver.call{value: amount}("");
        require(success, "FeeBank: withdrawal call failed");
        emit WithdrawEvent(msg.sender, receiver, amount, deposits[msg.sender]);
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

// Part: BatcherContract

/// @title A contract that batches transactions.
contract BatcherContract is Ownable {
    /// @notice The event emitted whenever a transaction is added to a batch.
    /// @param batchIndex The index of the batch to which the transaction has been added.
    /// @param transactionType The type of the transaction (cipher or plain).
    /// @param transaction The encrypted or plaintext transaction (depending on the type).
    /// @param batchHash The batch hash after adding the transaction.
    event TransactionAdded(
        uint64 batchIndex,
        TransactionType transactionType,
        bytes transaction,
        bytes32 batchHash
    );

    // The contract from which batch configs are fetched.
    ConfigContract public configContract;
    // The contract to which fees are sent.
    FeeBankContract public feeBankContract;

    // Stores the current size of the batches by batch index. Note that cipher and plain batches
    // are not tracked separately but in sum.
    mapping(uint64 => uint64) public batchSizes;
    // The current batch hashes by index and type (cipher or plain).
    mapping(uint64 => mapping(TransactionType => bytes32)) public batchHashes;

    // The minimum fee required to add a transaction to a batch.
    uint64 public minFee;

    constructor(
        ConfigContract configContractAddress,
        FeeBankContract feeBankContractAddress
    ) {
        configContract = configContractAddress;
        feeBankContract = feeBankContractAddress;
    }

    /// @notice Add a transaction to a batch.
    /// @param batchIndex The index of the batch to which the transaction should be added. Note
    ///     that this must match the batch corresponding to the current block number.
    /// @param transactionType The type of the transaction (either cipher or plain).
    /// @param transaction The encrypted or plaintext transaction (depending on `transactionType`).
    function addTransaction(
        uint64 batchIndex,
        TransactionType transactionType,
        bytes calldata transaction
    ) external payable {
        BatchConfig memory config = configContract.getConfig(batchIndex);

        // check batching is active
        require(config.batchSpan > 0, "BatcherContract: batch not active");

        // check given batch is open
        assert(batchIndex >= config.startBatchIndex); // ensured by configContract.getConfig
        uint64 relativeBatchIndex = batchIndex - config.startBatchIndex;
        uint64 batchEndBlock =
            config.startBlockNumber +
                (relativeBatchIndex + 1) *
                config.batchSpan;
        uint64 batchStartBlock = batchEndBlock - config.batchSpan;
        if (batchStartBlock >= config.batchSpan && relativeBatchIndex >= 1) {
            batchStartBlock -= config.batchSpan;
        }

        require(
            block.number >= batchStartBlock,
            "BatcherContract: batch not started yet"
        );
        require(
            block.number < batchEndBlock,
            "BatcherContract: batch already ended"
        );

        // check tx and batch size limits
        require(
            transaction.length > 0,
            "BatcherContract: transaction is empty"
        );
        require(
            transaction.length <= config.transactionSizeLimit,
            "BatcherContract: transaction too big"
        );
        require(
            batchSizes[batchIndex] + transaction.length <=
                config.batchSizeLimit,
            "BatcherContract: batch already full"
        ); // overflow can be ignored here because number of txs and their sizes are both small

        // check fee
        require(msg.value >= minFee, "BatcherContract: fee too small");

        // add tx to batch
        bytes memory batchHashPreimage =
            abi.encodePacked(
                transaction,
                batchHashes[batchIndex][transactionType]
            );
        bytes32 newBatchHash = keccak256(batchHashPreimage);
        batchHashes[batchIndex][transactionType] = newBatchHash;
        batchSizes[batchIndex] += uint64(transaction.length);

        // pay fee to fee bank and emit event
        if (msg.value > 0 && config.feeReceiver != address(0)) {
            feeBankContract.deposit{value: msg.value}(config.feeReceiver);
        }
        emit TransactionAdded(
            batchIndex,
            transactionType,
            transaction,
            newBatchHash
        );
    }

    /// @notice Set the minimum fee required to add a transaction to the batch.
    /// @param newMinFee The new value for the minimum fee.
    function setMinFee(uint64 newMinFee) external onlyOwner {
        minFee = newMinFee;
    }
}

// File: ExecutorContract.sol

/// @title A contract that serves as the entry point of batch execution
/// @dev Batch execution is carried out in two separate steps: Execution of the encrypted portion,
///     followed by execution of the plaintext portion. Thus, progress is counted in half steps (0
///     and 1 for batch 0, 2 and 3 for batch 1, and so on).
contract ExecutorContract {
    /// @notice The event emitted after a batch execution half step has been carried out.
    /// @param numExecutionHalfSteps The total number of finished execution half steps, including
    ///     the one responsible for emitting the event.
    /// @param batchHash The hash of the executed batch (consisting of plaintext transactions).
    event BatchExecuted(uint64 numExecutionHalfSteps, bytes32 batchHash);

    /// @notice The event emitted after execution of the cipher portion of a batch has been skipped.
    /// @param numExecutionHalfSteps The total number of finished execution half steps, including
    ///     this one.
    event CipherExecutionSkipped(uint64 numExecutionHalfSteps);

    event TransactionFailed(uint64 txIndex, bytes32 txHash, bytes data);

    ConfigContract public configContract;
    BatcherContract public batcherContract;

    uint64 public numExecutionHalfSteps;
    mapping(uint64 => CipherExecutionReceipt) public cipherExecutionReceipts;

    constructor(
        ConfigContract configContractAddress,
        BatcherContract batcherContractAddress
    ) {
        configContract = configContractAddress;
        batcherContract = batcherContractAddress;
    }

    /// @notice Execute the cipher portion of a batch.
    /// @param batchIndex The index of the batch
    /// @param cipherBatchHash The hash of the batch (consisting of encrypted transactions)
    /// @param transactions The sequence of (decrypted) transactions to execute.
    /// @param keyperIndex The index of the keyper calling the function.
    /// @notice Execution is only performed if `cipherBatchHash` matches the hash in the batcher
    ///     contract and the batch is active and completed.
    function executeCipherBatch(
        uint64 batchIndex,
        bytes32 cipherBatchHash,
        bytes[] calldata transactions,
        uint64 keyperIndex
    ) external {
        require(
            numExecutionHalfSteps / 2 == batchIndex,
            "ExecutorContract: unexpected batch index"
        );
        // Check that it's a cipher batch turn
        require(
            numExecutionHalfSteps % 2 == 0,
            "ExecutorContract: unexpected half step"
        );

        BatchConfig memory config = configContract.getConfig(batchIndex);

        // Check that batching is active and the batch is closed
        require(config.batchSpan > 0, "ExecutorContract: config is inactive");

        // skip cipher execution if we reached the execution timeout.
        if (
            block.number >=
            config.startBlockNumber +
                config.batchSpan *
                (batchIndex + 1) +
                config.executionTimeout
        ) {
            numExecutionHalfSteps++;
            emit CipherExecutionSkipped(numExecutionHalfSteps);
            return;
        }
        require(
            block.number >=
                config.startBlockNumber + config.batchSpan * (batchIndex + 1),
            "ExecutorContract: batch is not closed yet"
        );

        // Check that caller is keyper
        require(
            keyperIndex < config.keypers.length,
            "ExecutorContract: keyper index out of bounds"
        );
        require(
            msg.sender == config.keypers[keyperIndex],
            "ExecutorContract: sender is not specified keyper"
        );

        // Check the cipher batch hash is correct
        require(
            cipherBatchHash ==
                batcherContract.batchHashes(batchIndex, TransactionType.Cipher),
            "ExecutorContract: incorrect cipher batch hash"
        );

        // Execute the batch
        bytes32 batchHash =
            executeTransactions(
                config.targetAddress,
                config.targetFunctionSelector,
                config.transactionGasLimit,
                transactions
            );

        cipherExecutionReceipts[
            numExecutionHalfSteps
        ] = CipherExecutionReceipt({
            executed: true,
            executor: msg.sender,
            halfStep: numExecutionHalfSteps,
            cipherBatchHash: cipherBatchHash,
            batchHash: batchHash
        });
        numExecutionHalfSteps++;
        emit BatchExecuted(numExecutionHalfSteps, batchHash);
    }

    /// @notice Skip execution of the cipher portion of a batch.
    /// @notice This is only possible if successful execution has not been carried out in time
    ///     (according to the execution timeout defined in the config)
    function skipCipherExecution(uint64 batchIndex) external {
        require(
            numExecutionHalfSteps / 2 == batchIndex,
            "ExecutorContract: unexpected batch index"
        );

        require(
            numExecutionHalfSteps % 2 == 0,
            "ExecutorContract: unexpected half step"
        );

        BatchConfig memory config = configContract.getConfig(batchIndex);

        require(config.batchSpan > 0, "ExecutorContract: config is inactive");
        require(
            block.number >=
                config.startBlockNumber +
                    config.batchSpan *
                    (batchIndex + 1) +
                    config.executionTimeout,
            "ExecutorContract: execution timeout not reached yet"
        );

        numExecutionHalfSteps++;

        emit CipherExecutionSkipped(numExecutionHalfSteps);
    }

    /// @notice Execute the plaintext portion of a batch.
    /// @param batchIndex The index of the batch
    /// @param transactions The array of plaintext transactions in the batch.
    /// @notice This is a trustless operation since `transactions` will be checked against the
    ///     (plaintext) batch hash from the batcher contract.
    function executePlainBatch(uint64 batchIndex, bytes[] calldata transactions)
        external
    {
        require(
            numExecutionHalfSteps / 2 == batchIndex,
            "ExecutorContract: unexpected batch index"
        );
        require(
            numExecutionHalfSteps % 2 == 1,
            "ExecutorContract: unexpected half step"
        );

        BatchConfig memory config = configContract.getConfig(batchIndex);

        // Since the cipher part of the batch has already been executed or skipped and the
        // config cannot be changed anymore (since the batching period is over), the following
        // checks remain true.
        assert(config.batchSpan > 0);
        assert(
            block.number >=
                config.startBlockNumber + config.batchSpan * (batchIndex + 1)
        );

        bytes32 batchHash =
            executeTransactions(
                config.targetAddress,
                config.targetFunctionSelector,
                config.transactionGasLimit,
                transactions
            );

        require(
            batchHash ==
                batcherContract.batchHashes(batchIndex, TransactionType.Plain),
            "ExecutorContract: batch hash does not match"
        );

        numExecutionHalfSteps++;

        emit BatchExecuted(numExecutionHalfSteps, batchHash);
    }

    function executeTransactions(
        address targetAddress,
        bytes4 targetFunctionSelector,
        uint64 gasLimit,
        bytes[] calldata transactions
    ) private returns (bytes32) {
        bytes32 batchHash;
        for (uint64 i = 0; i < transactions.length; i++) {
            bytes memory callData =
                abi.encodeWithSelector(targetFunctionSelector, transactions[i]);

            // call target function, ignoring any errors
            (bool success, bytes memory returnData) =
                targetAddress.call{gas: gasLimit}(callData);
            if (!success) {
                emit TransactionFailed({
                    txIndex: i,
                    txHash: keccak256(transactions[i]),
                    data: returnData
                });
            }

            batchHash = keccak256(abi.encodePacked(transactions[i], batchHash));
        }
        return batchHash;
    }

    function getReceipt(uint64 halfStep)
        public
        view
        returns (CipherExecutionReceipt memory)
    {
        return cipherExecutionReceipts[halfStep];
    }
}