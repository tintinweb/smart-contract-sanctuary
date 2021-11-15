// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";
import { Lib_AddressResolver } from "../../libraries/resolver/Lib_AddressResolver.sol";
import { Lib_MerkleTree } from "../../libraries/utils/Lib_MerkleTree.sol";

/* Interface Imports */
import { iOVM_CanonicalTransactionChain } from "../../iOVM/chain/iOVM_CanonicalTransactionChain.sol";
import { iOVM_ChainStorageContainer } from "../../iOVM/chain/iOVM_ChainStorageContainer.sol";

/* Contract Imports */
import { OVM_ExecutionManager } from "../execution/OVM_ExecutionManager.sol";

/* External Imports */
import { Math } from "@openzeppelin/contracts/math/Math.sol";

/**
 * @title OVM_CanonicalTransactionChain
 * @dev The Canonical Transaction Chain (CTC) contract is an append-only log of transactions
 * which must be applied to the rollup state. It defines the ordering of rollup transactions by
 * writing them to the 'CTC:batches' instance of the Chain Storage Container.
 * The CTC also allows any account to 'enqueue' an L2 transaction, which will require that the Sequencer
 * will eventually append it to the rollup state.
 * If the Sequencer does not include an enqueued transaction within the 'force inclusion period',
 * then any account may force it to be included by calling appendQueueBatch().
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_CanonicalTransactionChain is iOVM_CanonicalTransactionChain, Lib_AddressResolver {

    /*************
     * Constants *
     *************/

    // L2 tx gas-related
    uint256 constant public MIN_ROLLUP_TX_GAS = 100000;
    uint256 constant public MAX_ROLLUP_TX_SIZE = 50000;
    uint256 constant public L2_GAS_DISCOUNT_DIVISOR = 32;

    // Encoding-related (all in bytes)
    uint256 constant internal BATCH_CONTEXT_SIZE = 16;
    uint256 constant internal BATCH_CONTEXT_LENGTH_POS = 12;
    uint256 constant internal BATCH_CONTEXT_START_POS = 15;
    uint256 constant internal TX_DATA_HEADER_SIZE = 3;
    uint256 constant internal BYTES_TILL_TX_DATA = 65;


    /*************
     * Variables *
     *************/

    uint256 public forceInclusionPeriodSeconds;
    uint256 public forceInclusionPeriodBlocks;
    uint256 public maxTransactionGasLimit;


    /***************
     * Constructor *
     ***************/

    constructor(
        address _libAddressManager,
        uint256 _forceInclusionPeriodSeconds,
        uint256 _forceInclusionPeriodBlocks,
        uint256 _maxTransactionGasLimit
    )
        Lib_AddressResolver(_libAddressManager)
    {
        forceInclusionPeriodSeconds = _forceInclusionPeriodSeconds;
        forceInclusionPeriodBlocks = _forceInclusionPeriodBlocks;
        maxTransactionGasLimit = _maxTransactionGasLimit;
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * Accesses the batch storage container.
     * @return Reference to the batch storage container.
     */
    function batches()
        override
        public
        view
        returns (
            iOVM_ChainStorageContainer
        )
    {
        return iOVM_ChainStorageContainer(
            resolve("OVM_ChainStorageContainer:CTC:batches")
        );
    }

    /**
     * Accesses the queue storage container.
     * @return Reference to the queue storage container.
     */
    function queue()
        override
        public
        view
        returns (
            iOVM_ChainStorageContainer
        )
    {
        return iOVM_ChainStorageContainer(
            resolve("OVM_ChainStorageContainer:CTC:queue")
        );
    }

    /**
     * Retrieves the total number of elements submitted.
     * @return _totalElements Total submitted elements.
     */
    function getTotalElements()
        override
        public
        view
        returns (
            uint256 _totalElements
        )
    {
        (uint40 totalElements,,,) = _getBatchExtraData();
        return uint256(totalElements);
    }

    /**
     * Retrieves the total number of batches submitted.
     * @return _totalBatches Total submitted batches.
     */
    function getTotalBatches()
        override
        public
        view
        returns (
            uint256 _totalBatches
        )
    {
        return batches().length();
    }

    /**
     * Returns the index of the next element to be enqueued.
     * @return Index for the next queue element.
     */
    function getNextQueueIndex()
        override
        public
        view
        returns (
            uint40
        )
    {
        (,uint40 nextQueueIndex,,) = _getBatchExtraData();
        return nextQueueIndex;
    }

    /**
     * Returns the timestamp of the last transaction.
     * @return Timestamp for the last transaction.
     */
    function getLastTimestamp()
        override
        public
        view
        returns (
            uint40
        )
    {
        (,,uint40 lastTimestamp,) = _getBatchExtraData();
        return lastTimestamp;
    }

    /**
     * Returns the blocknumber of the last transaction.
     * @return Blocknumber for the last transaction.
     */
    function getLastBlockNumber()
        override
        public
        view
        returns (
            uint40
        )
    {
        (,,,uint40 lastBlockNumber) = _getBatchExtraData();
        return lastBlockNumber;
    }

    /**
     * Gets the queue element at a particular index.
     * @param _index Index of the queue element to access.
     * @return _element Queue element at the given index.
     */
    function getQueueElement(
        uint256 _index
    )
        override
        public
        view
        returns (
            Lib_OVMCodec.QueueElement memory _element
        )
    {
        return _getQueueElement(
            _index,
            queue()
        );
    }

    /**
     * Get the number of queue elements which have not yet been included.
     * @return Number of pending queue elements.
     */
    function getNumPendingQueueElements()
        override
        public
        view
        returns (
            uint40
        )
    {
        return getQueueLength() - getNextQueueIndex();
    }

   /**
     * Retrieves the length of the queue, including
     * both pending and canonical transactions.
     * @return Length of the queue.
     */
    function getQueueLength()
        override
        public
        view
        returns (
            uint40
        )
    {
        return _getQueueLength(
            queue()
        );
    }

    /**
     * Adds a transaction to the queue.
     * @param _target Target L2 contract to send the transaction to.
     * @param _gasLimit Gas limit for the enqueued L2 transaction.
     * @param _data Transaction data.
     */
    function enqueue(
        address _target,
        uint256 _gasLimit,
        bytes memory _data
    )
        override
        public
    {
        require(
            _data.length <= MAX_ROLLUP_TX_SIZE,
            "Transaction data size exceeds maximum for rollup transaction."
        );

        require(
            _gasLimit <= maxTransactionGasLimit,
            "Transaction gas limit exceeds maximum for rollup transaction."
        );

        require(
            _gasLimit >= MIN_ROLLUP_TX_GAS,
            "Transaction gas limit too low to enqueue."
        );

        // We need to consume some amount of L1 gas in order to rate limit transactions going into
        // L2. However, L2 is cheaper than L1 so we only need to burn some small proportion of the
        // provided L1 gas.
        uint256 gasToConsume = _gasLimit/L2_GAS_DISCOUNT_DIVISOR;
        uint256 startingGas = gasleft();

        // Although this check is not necessary (burn below will run out of gas if not true), it
        // gives the user an explicit reason as to why the enqueue attempt failed.
        require(
            startingGas > gasToConsume,
            "Insufficient gas for L2 rate limiting burn."
        );

        // Here we do some "dumb" work in order to burn gas, although we should probably replace
        // this with something like minting gas token later on.
        uint256 i;
        while(startingGas - gasleft() < gasToConsume) {
            i++;
        }

        bytes32 transactionHash = keccak256(
            abi.encode(
                msg.sender,
                _target,
                _gasLimit,
                _data
            )
        );

        bytes32 timestampAndBlockNumber;
        assembly {
            timestampAndBlockNumber := timestamp()
            timestampAndBlockNumber := or(timestampAndBlockNumber, shl(40, number()))
        }

        iOVM_ChainStorageContainer queueRef = queue();

        queueRef.push(transactionHash);
        queueRef.push(timestampAndBlockNumber);

        // The underlying queue data structure stores 2 elements
        // per insertion, so to get the real queue length we need
        // to divide by 2 and subtract 1.
        uint256 queueIndex = queueRef.length() / 2 - 1;
        emit TransactionEnqueued(
            msg.sender,
            _target,
            _gasLimit,
            _data,
            queueIndex,
            block.timestamp
        );
    }

    /**
     * Appends a given number of queued transactions as a single batch.
     * param _numQueuedTransactions Number of transactions to append.
     */
    function appendQueueBatch(
        uint256 // _numQueuedTransactions
    )
        override
        public
        pure
    {
        // TEMPORARY: Disable `appendQueueBatch` for minnet
        revert("appendQueueBatch is currently disabled.");

        // _numQueuedTransactions = Math.min(_numQueuedTransactions, getNumPendingQueueElements());
        // require(
        //     _numQueuedTransactions > 0,
        //     "Must append more than zero transactions."
        // );

        // bytes32[] memory leaves = new bytes32[](_numQueuedTransactions);
        // uint40 nextQueueIndex = getNextQueueIndex();

        // for (uint256 i = 0; i < _numQueuedTransactions; i++) {
        //     if (msg.sender != resolve("OVM_Sequencer")) {
        //         Lib_OVMCodec.QueueElement memory el = getQueueElement(nextQueueIndex);
        //         require(
        //             el.timestamp + forceInclusionPeriodSeconds < block.timestamp,
        //             "Queue transactions cannot be submitted during the sequencer inclusion period."
        //         );
        //     }
        //     leaves[i] = _getQueueLeafHash(nextQueueIndex);
        //     nextQueueIndex++;
        // }

        // Lib_OVMCodec.QueueElement memory lastElement = getQueueElement(nextQueueIndex - 1);

        // _appendBatch(
        //     Lib_MerkleTree.getMerkleRoot(leaves),
        //     _numQueuedTransactions,
        //     _numQueuedTransactions,
        //     lastElement.timestamp,
        //     lastElement.blockNumber
        // );

        // emit QueueBatchAppended(
        //     nextQueueIndex - _numQueuedTransactions,
        //     _numQueuedTransactions,
        //     getTotalElements()
        // );
    }

    /**
     * Allows the sequencer to append a batch of transactions.
     * @dev This function uses a custom encoding scheme for efficiency reasons.
     * .param _shouldStartAtElement Specific batch we expect to start appending to.
     * .param _totalElementsToAppend Total number of batch elements we expect to append.
     * .param _contexts Array of batch contexts.
     * .param _transactionDataFields Array of raw transaction data.
     */
    function appendSequencerBatch()
        override
        public
    {
        uint40 shouldStartAtElement;
        uint24 totalElementsToAppend;
        uint24 numContexts;
        assembly {
            shouldStartAtElement  := shr(216, calldataload(4))
            totalElementsToAppend := shr(232, calldataload(9))
            numContexts           := shr(232, calldataload(12))
        }

        require(
            shouldStartAtElement == getTotalElements(),
            "Actual batch start index does not match expected start index."
        );

        require(
            msg.sender == resolve("OVM_Sequencer"),
            "Function can only be called by the Sequencer."
        );

        require(
            numContexts > 0,
            "Must provide at least one batch context."
        );

        require(
            totalElementsToAppend > 0,
            "Must append at least one element."
        );

        uint40 nextTransactionPtr = uint40(BATCH_CONTEXT_START_POS + BATCH_CONTEXT_SIZE * numContexts);

        require(
            msg.data.length >= nextTransactionPtr,
            "Not enough BatchContexts provided."
        );

        // Take a reference to the queue and its length so we don't have to keep resolving it.
        // Length isn't going to change during the course of execution, so it's fine to simply
        // resolve this once at the start. Saves gas.
        iOVM_ChainStorageContainer queueRef = queue();
        uint40 queueLength = _getQueueLength(queueRef);

        // Reserve some memory to save gas on hashing later on. This is a relatively safe estimate
        // for the average transaction size that will prevent having to resize this chunk of memory
        // later on. Saves gas.
        bytes memory hashMemory = new bytes((msg.data.length / totalElementsToAppend) * 2);

        // Initialize the array of canonical chain leaves that we will append.
        bytes32[] memory leaves = new bytes32[](totalElementsToAppend);

        // Each leaf index corresponds to a tx, either sequenced or enqueued.
        uint32 leafIndex = 0;

        // Counter for number of sequencer transactions appended so far.
        uint32 numSequencerTransactions = 0;

        // We will sequentially append leaves which are pointers to the queue.
        // The initial queue index is what is currently in storage.
        uint40 nextQueueIndex = getNextQueueIndex();

        BatchContext memory curContext;
        for (uint32 i = 0; i < numContexts; i++) {
            BatchContext memory nextContext = _getBatchContext(i);

            if (i == 0) {
                // Execute a special check for the first batch.
                _validateFirstBatchContext(nextContext);
            }

            // Execute this check on every single batch, including the first one.
            _validateNextBatchContext(
                curContext,
                nextContext,
                nextQueueIndex,
                queueRef
            );

            // Now we can update our current context.
            curContext = nextContext;

            // Process sequencer transactions first.
            for (uint32 j = 0; j < curContext.numSequencedTransactions; j++) {
                uint256 txDataLength;
                assembly {
                    txDataLength := shr(232, calldataload(nextTransactionPtr))
                }
                require(
                    txDataLength <= MAX_ROLLUP_TX_SIZE,
                    "Transaction data size exceeds maximum for rollup transaction."
                );

                leaves[leafIndex] = _getSequencerLeafHash(
                    curContext,
                    nextTransactionPtr,
                    txDataLength,
                    hashMemory
                );

                nextTransactionPtr += uint40(TX_DATA_HEADER_SIZE + txDataLength);
                numSequencerTransactions++;
                leafIndex++;
            }

            // Now process any subsequent queue transactions.
            for (uint32 j = 0; j < curContext.numSubsequentQueueTransactions; j++) {
                require(
                    nextQueueIndex < queueLength,
                    "Not enough queued transactions to append."
                );

                leaves[leafIndex] = _getQueueLeafHash(nextQueueIndex);
                nextQueueIndex++;
                leafIndex++;
            }
        }

        _validateFinalBatchContext(
            curContext,
            nextQueueIndex,
            queueLength,
            queueRef
        );

        require(
            msg.data.length == nextTransactionPtr,
            "Not all sequencer transactions were processed."
        );

        require(
            leafIndex == totalElementsToAppend,
            "Actual transaction index does not match expected total elements to append."
        );

        // Generate the required metadata that we need to append this batch
        uint40 numQueuedTransactions = totalElementsToAppend - numSequencerTransactions;
        uint40 blockTimestamp;
        uint40 blockNumber;
        if (curContext.numSubsequentQueueTransactions == 0) {
            // The last element is a sequencer tx, therefore pull timestamp and block number from the last context.
            blockTimestamp = uint40(curContext.timestamp);
            blockNumber = uint40(curContext.blockNumber);
        } else {
            // The last element is a queue tx, therefore pull timestamp and block number from the queue element.
            // curContext.numSubsequentQueueTransactions > 0 which means that we've processed at least one queue element.
            // We increment nextQueueIndex after processing each queue element,
            // so the index of the last element we processed is nextQueueIndex - 1.
            Lib_OVMCodec.QueueElement memory lastElement = _getQueueElement(
                nextQueueIndex - 1,
                queueRef
            );

            blockTimestamp = lastElement.timestamp;
            blockNumber = lastElement.blockNumber;
        }

        // For efficiency reasons getMerkleRoot modifies the `leaves` argument in place
        // while calculating the root hash therefore any arguments passed to it must not
        // be used again afterwards
        _appendBatch(
            Lib_MerkleTree.getMerkleRoot(leaves),
            totalElementsToAppend,
            numQueuedTransactions,
            blockTimestamp,
            blockNumber
        );

        emit SequencerBatchAppended(
            nextQueueIndex - numQueuedTransactions,
            numQueuedTransactions,
            getTotalElements()
        );
    }

    /**
     * Verifies whether a transaction is included in the chain.
     * @param _transaction Transaction to verify.
     * @param _txChainElement Transaction chain element corresponding to the transaction.
     * @param _batchHeader Header of the batch the transaction was included in.
     * @param _inclusionProof Inclusion proof for the provided transaction chain element.
     * @return True if the transaction exists in the CTC, false if not.
     */
    function verifyTransaction(
        Lib_OVMCodec.Transaction memory _transaction,
        Lib_OVMCodec.TransactionChainElement memory _txChainElement,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _inclusionProof
    )
        override
        public
        view
        returns (
            bool
        )
    {
        if (_txChainElement.isSequenced == true) {
            return _verifySequencerTransaction(
                _transaction,
                _txChainElement,
                _batchHeader,
                _inclusionProof
            );
        } else {
            return _verifyQueueTransaction(
                _transaction,
                _txChainElement.queueIndex,
                _batchHeader,
                _inclusionProof
            );
        }
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Returns the BatchContext located at a particular index.
     * @param _index The index of the BatchContext
     * @return The BatchContext at the specified index.
     */
    function _getBatchContext(
        uint256 _index
    )
        internal
        pure
        returns (
            BatchContext memory
        )
    {
        uint256 contextPtr = 15 + _index * BATCH_CONTEXT_SIZE;
        uint256 numSequencedTransactions;
        uint256 numSubsequentQueueTransactions;
        uint256 ctxTimestamp;
        uint256 ctxBlockNumber;

        assembly {
            numSequencedTransactions       := shr(232, calldataload(contextPtr))
            numSubsequentQueueTransactions := shr(232, calldataload(add(contextPtr, 3)))
            ctxTimestamp                   := shr(216, calldataload(add(contextPtr, 6)))
            ctxBlockNumber                 := shr(216, calldataload(add(contextPtr, 11)))
        }

        return BatchContext({
            numSequencedTransactions: numSequencedTransactions,
            numSubsequentQueueTransactions: numSubsequentQueueTransactions,
            timestamp: ctxTimestamp,
            blockNumber: ctxBlockNumber
        });
    }

    /**
     * Parses the batch context from the extra data.
     * @return Total number of elements submitted.
     * @return Index of the next queue element.
     */
    function _getBatchExtraData()
        internal
        view
        returns (
            uint40,
            uint40,
            uint40,
            uint40
        )
    {
        bytes27 extraData = batches().getGlobalMetadata();

        uint40 totalElements;
        uint40 nextQueueIndex;
        uint40 lastTimestamp;
        uint40 lastBlockNumber;
        assembly {
            extraData       :=  shr(40, extraData)
            totalElements   :=  and(extraData, 0x000000000000000000000000000000000000000000000000000000FFFFFFFFFF)
            nextQueueIndex  :=  shr(40, and(extraData, 0x00000000000000000000000000000000000000000000FFFFFFFFFF0000000000))
            lastTimestamp   :=  shr(80, and(extraData, 0x0000000000000000000000000000000000FFFFFFFFFF00000000000000000000))
            lastBlockNumber :=  shr(120, and(extraData, 0x000000000000000000000000FFFFFFFFFF000000000000000000000000000000))
        }

        return (
            totalElements,
            nextQueueIndex,
            lastTimestamp,
            lastBlockNumber
        );
    }

    /**
     * Encodes the batch context for the extra data.
     * @param _totalElements Total number of elements submitted.
     * @param _nextQueueIndex Index of the next queue element.
     * @param _timestamp Timestamp for the last batch.
     * @param _blockNumber Block number of the last batch.
     * @return Encoded batch context.
     */
    function _makeBatchExtraData(
        uint40 _totalElements,
        uint40 _nextQueueIndex,
        uint40 _timestamp,
        uint40 _blockNumber
    )
        internal
        pure
        returns (
            bytes27
        )
    {
        bytes27 extraData;
        assembly {
            extraData := _totalElements
            extraData := or(extraData, shl(40, _nextQueueIndex))
            extraData := or(extraData, shl(80, _timestamp))
            extraData := or(extraData, shl(120, _blockNumber))
            extraData := shl(40, extraData)
        }

        return extraData;
    }

    /**
     * Retrieves the hash of a queue element.
     * @param _index Index of the queue element to retrieve a hash for.
     * @return Hash of the queue element.
     */
    function _getQueueLeafHash(
        uint256 _index
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return _hashTransactionChainElement(
            Lib_OVMCodec.TransactionChainElement({
                isSequenced: false,
                queueIndex: _index,
                timestamp: 0,
                blockNumber: 0,
                txData: hex""
            })
        );
    }

    /**
     * Gets the queue element at a particular index.
     * @param _index Index of the queue element to access.
     * @return _element Queue element at the given index.
     */
    function _getQueueElement(
        uint256 _index,
        iOVM_ChainStorageContainer _queueRef
    )
        internal
        view
        returns (
            Lib_OVMCodec.QueueElement memory _element
        )
    {
        // The underlying queue data structure stores 2 elements
        // per insertion, so to get the actual desired queue index
        // we need to multiply by 2.
        uint40 trueIndex = uint40(_index * 2);
        bytes32 transactionHash = _queueRef.get(trueIndex);
        bytes32 timestampAndBlockNumber = _queueRef.get(trueIndex + 1);

        uint40 elementTimestamp;
        uint40 elementBlockNumber;
        assembly {
            elementTimestamp   :=         and(timestampAndBlockNumber, 0x000000000000000000000000000000000000000000000000000000FFFFFFFFFF)
            elementBlockNumber := shr(40, and(timestampAndBlockNumber, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000))
        }

        return Lib_OVMCodec.QueueElement({
            transactionHash: transactionHash,
            timestamp: elementTimestamp,
            blockNumber: elementBlockNumber
        });
    }

    /**
     * Retrieves the length of the queue.
     * @return Length of the queue.
     */
    function _getQueueLength(
        iOVM_ChainStorageContainer _queueRef
    )
        internal
        view
        returns (
            uint40
        )
    {
        // The underlying queue data structure stores 2 elements
        // per insertion, so to get the real queue length we need
        // to divide by 2.
        return uint40(_queueRef.length() / 2);
    }

    /**
     * Retrieves the hash of a sequencer element.
     * @param _context Batch context for the given element.
     * @param _nextTransactionPtr Pointer to the next transaction in the calldata.
     * @param _txDataLength Length of the transaction item.
     * @return Hash of the sequencer element.
     */
    function _getSequencerLeafHash(
        BatchContext memory _context,
        uint256 _nextTransactionPtr,
        uint256 _txDataLength,
        bytes memory _hashMemory
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        // Only allocate more memory if we didn't reserve enough to begin with.
        if (BYTES_TILL_TX_DATA + _txDataLength > _hashMemory.length) {
            _hashMemory = new bytes(BYTES_TILL_TX_DATA + _txDataLength);
        }

        uint256 ctxTimestamp = _context.timestamp;
        uint256 ctxBlockNumber = _context.blockNumber;

        bytes32 leafHash;
        assembly {
            let chainElementStart := add(_hashMemory, 0x20)

            // Set the first byte equal to `1` to indicate this is a sequencer chain element.
            // This distinguishes sequencer ChainElements from queue ChainElements because
            // all queue ChainElements are ABI encoded and the first byte of ABI encoded
            // elements is always zero
            mstore8(chainElementStart, 1)

            mstore(add(chainElementStart, 1), ctxTimestamp)
            mstore(add(chainElementStart, 33), ctxBlockNumber)

            calldatacopy(add(chainElementStart, BYTES_TILL_TX_DATA), add(_nextTransactionPtr, 3), _txDataLength)

            leafHash := keccak256(chainElementStart, add(BYTES_TILL_TX_DATA, _txDataLength))
        }

        return leafHash;
    }

    /**
     * Retrieves the hash of a sequencer element.
     * @param _txChainElement The chain element which is hashed to calculate the leaf.
     * @return Hash of the sequencer element.
     */
    function _getSequencerLeafHash(
        Lib_OVMCodec.TransactionChainElement memory _txChainElement
    )
        internal
        view
        returns(
            bytes32
        )
    {
        bytes memory txData = _txChainElement.txData;
        uint256 txDataLength = _txChainElement.txData.length;

        bytes memory chainElement = new bytes(BYTES_TILL_TX_DATA + txDataLength);
        uint256 ctxTimestamp = _txChainElement.timestamp;
        uint256 ctxBlockNumber = _txChainElement.blockNumber;

        bytes32 leafHash;
        assembly {
            let chainElementStart := add(chainElement, 0x20)

            // Set the first byte equal to `1` to indicate this is a sequencer chain element.
            // This distinguishes sequencer ChainElements from queue ChainElements because
            // all queue ChainElements are ABI encoded and the first byte of ABI encoded
            // elements is always zero
            mstore8(chainElementStart, 1)

            mstore(add(chainElementStart, 1), ctxTimestamp)
            mstore(add(chainElementStart, 33), ctxBlockNumber)

            pop(staticcall(gas(), 0x04, add(txData, 0x20), txDataLength, add(chainElementStart, BYTES_TILL_TX_DATA), txDataLength))

            leafHash := keccak256(chainElementStart, add(BYTES_TILL_TX_DATA, txDataLength))
        }

        return leafHash;
    }

    /**
     * Inserts a batch into the chain of batches.
     * @param _transactionRoot Root of the transaction tree for this batch.
     * @param _batchSize Number of elements in the batch.
     * @param _numQueuedTransactions Number of queue transactions in the batch.
     * @param _timestamp The latest batch timestamp.
     * @param _blockNumber The latest batch blockNumber.
     */
    function _appendBatch(
        bytes32 _transactionRoot,
        uint256 _batchSize,
        uint256 _numQueuedTransactions,
        uint40 _timestamp,
        uint40 _blockNumber
    )
        internal
    {
        iOVM_ChainStorageContainer batchesRef = batches();
        (uint40 totalElements, uint40 nextQueueIndex,,) = _getBatchExtraData();

        Lib_OVMCodec.ChainBatchHeader memory header = Lib_OVMCodec.ChainBatchHeader({
            batchIndex: batchesRef.length(),
            batchRoot: _transactionRoot,
            batchSize: _batchSize,
            prevTotalElements: totalElements,
            extraData: hex""
        });

        emit TransactionBatchAppended(
            header.batchIndex,
            header.batchRoot,
            header.batchSize,
            header.prevTotalElements,
            header.extraData
        );

        bytes32 batchHeaderHash = Lib_OVMCodec.hashBatchHeader(header);
        bytes27 latestBatchContext = _makeBatchExtraData(
            totalElements + uint40(header.batchSize),
            nextQueueIndex + uint40(_numQueuedTransactions),
            _timestamp,
            _blockNumber
        );

        batchesRef.push(batchHeaderHash, latestBatchContext);
    }

    /**
     * Checks that the first batch context in a sequencer submission is valid
     * @param _firstContext The batch context to validate.
     */
    function _validateFirstBatchContext(
        BatchContext memory _firstContext
    )
        internal
        view
    {
        // If there are existing elements, this batch must have the same context
        // or a later timestamp and block number.
        if (getTotalElements() > 0) {
            (,, uint40 lastTimestamp, uint40 lastBlockNumber) = _getBatchExtraData();

            require(
                _firstContext.blockNumber >= lastBlockNumber,
                "Context block number is lower than last submitted."
            );

            require(
                _firstContext.timestamp >= lastTimestamp,
                "Context timestamp is lower than last submitted."
            );
        }

        // Sequencer cannot submit contexts which are more than the force inclusion period old.
        require(
            _firstContext.timestamp + forceInclusionPeriodSeconds >= block.timestamp,
            "Context timestamp too far in the past."
        );

        require(
            _firstContext.blockNumber + forceInclusionPeriodBlocks >= block.number,
            "Context block number too far in the past."
        );
    }

    /**
     * Checks that a given batch context has a time context which is below a given que element
     * @param _context The batch context to validate has values lower.
     * @param _queueIndex Index of the queue element we are validating came later than the context.
     * @param _queueRef The storage container for the queue.
     */
    function _validateContextBeforeEnqueue(
        BatchContext memory _context,
        uint40 _queueIndex,
        iOVM_ChainStorageContainer _queueRef
    )
        internal
        view
    {
            Lib_OVMCodec.QueueElement memory nextQueueElement = _getQueueElement(
                _queueIndex,
                _queueRef
            );

            // If the force inclusion period has passed for an enqueued transaction, it MUST be the next chain element.
            require(
                block.timestamp < nextQueueElement.timestamp + forceInclusionPeriodSeconds,
                "Previously enqueued batches have expired and must be appended before a new sequencer batch."
            );

            // Just like sequencer transaction times must be increasing relative to each other,
            // We also require that they be increasing relative to any interspersed queue elements.
            require(
                _context.timestamp <= nextQueueElement.timestamp,
                "Sequencer transaction timestamp exceeds that of next queue element."
            );

            require(
                _context.blockNumber <= nextQueueElement.blockNumber,
                "Sequencer transaction blockNumber exceeds that of next queue element."
            );
    }

    /**
     * Checks that a given batch context is valid based on its previous context, and the next queue elemtent.
     * @param _prevContext The previously validated batch context.
     * @param _nextContext The batch context to validate with this call.
     * @param _nextQueueIndex Index of the next queue element to process for the _nextContext's subsequentQueueElements.
     * @param _queueRef The storage container for the queue.
     */
    function _validateNextBatchContext(
        BatchContext memory _prevContext,
        BatchContext memory _nextContext,
        uint40 _nextQueueIndex,
        iOVM_ChainStorageContainer _queueRef
    )
        internal
        view
    {
        // All sequencer transactions' times must be greater than or equal to the previous ones.
        require(
            _nextContext.timestamp >= _prevContext.timestamp,
            "Context timestamp values must monotonically increase."
        );

        require(
            _nextContext.blockNumber >= _prevContext.blockNumber,
            "Context blockNumber values must monotonically increase."
        );

        // If there is going to be a queue element pulled in from this context:
        if (_nextContext.numSubsequentQueueTransactions > 0) {
            _validateContextBeforeEnqueue(
                _nextContext,
                _nextQueueIndex,
                _queueRef
            );
        }
    }

    /**
     * Checks that the final batch context in a sequencer submission is valid.
     * @param _finalContext The batch context to validate.
     * @param _queueLength The length of the queue at the start of the batchAppend call.
     * @param _nextQueueIndex The next element in the queue that will be pulled into the CTC.
     * @param _queueRef The storage container for the queue.
     */
    function _validateFinalBatchContext(
        BatchContext memory _finalContext,
        uint40 _nextQueueIndex,
        uint40 _queueLength,
        iOVM_ChainStorageContainer _queueRef
    )
        internal
        view
    {
        // If the queue is not now empty, check the mononoticity of whatever the next batch that will come in is.
        if (_queueLength - _nextQueueIndex > 0 && _finalContext.numSubsequentQueueTransactions == 0) {
            _validateContextBeforeEnqueue(
                _finalContext,
                _nextQueueIndex,
                _queueRef
            );
        }
        // Batches cannot be added from the future, or subsequent enqueue() contexts would violate monotonicity.
        require(_finalContext.timestamp <= block.timestamp, "Context timestamp is from the future.");
        require(_finalContext.blockNumber <= block.number, "Context block number is from the future.");
    }

    /**
     * Hashes a transaction chain element.
     * @param _element Chain element to hash.
     * @return Hash of the chain element.
     */
    function _hashTransactionChainElement(
        Lib_OVMCodec.TransactionChainElement memory _element
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return keccak256(
            abi.encode(
                _element.isSequenced,
                _element.queueIndex,
                _element.timestamp,
                _element.blockNumber,
                _element.txData
            )
        );
    }

    /**
     * Verifies a sequencer transaction, returning true if it was indeed included in the CTC
     * @param _transaction The transaction we are verifying inclusion of.
     * @param _txChainElement The chain element that the transaction is claimed to be a part of.
     * @param _batchHeader Header of the batch the transaction was included in.
     * @param _inclusionProof An inclusion proof into the CTC at a particular index.
     * @return True if the transaction was included in the specified location, else false.
     */
    function _verifySequencerTransaction(
        Lib_OVMCodec.Transaction memory _transaction,
        Lib_OVMCodec.TransactionChainElement memory _txChainElement,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _inclusionProof
    )
        internal
        view
        returns (
            bool
        )
    {
        OVM_ExecutionManager ovmExecutionManager = OVM_ExecutionManager(resolve("OVM_ExecutionManager"));
        uint256 gasLimit = ovmExecutionManager.getMaxTransactionGasLimit();
        bytes32 leafHash = _getSequencerLeafHash(_txChainElement);

        require(
            _verifyElement(
                leafHash,
                _batchHeader,
                _inclusionProof
            ),
            "Invalid Sequencer transaction inclusion proof."
        );

        require(
            _transaction.blockNumber        == _txChainElement.blockNumber
            && _transaction.timestamp       == _txChainElement.timestamp
            && _transaction.entrypoint      == resolve("OVM_DecompressionPrecompileAddress")
            && _transaction.gasLimit        == gasLimit
            && _transaction.l1TxOrigin      == address(0)
            && _transaction.l1QueueOrigin   == Lib_OVMCodec.QueueOrigin.SEQUENCER_QUEUE
            && keccak256(_transaction.data) == keccak256(_txChainElement.txData),
            "Invalid Sequencer transaction."
        );

        return true;
    }

    /**
     * Verifies a queue transaction, returning true if it was indeed included in the CTC
     * @param _transaction The transaction we are verifying inclusion of.
     * @param _queueIndex The queueIndex of the queued transaction.
     * @param _batchHeader Header of the batch the transaction was included in.
     * @param _inclusionProof An inclusion proof into the CTC at a particular index (should point to queue tx).
     * @return True if the transaction was included in the specified location, else false.
     */
    function _verifyQueueTransaction(
        Lib_OVMCodec.Transaction memory _transaction,
        uint256 _queueIndex,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _inclusionProof
    )
        internal
        view
        returns (
            bool
        )
    {
        bytes32 leafHash = _getQueueLeafHash(_queueIndex);

        require(
            _verifyElement(
                leafHash,
                _batchHeader,
                _inclusionProof
            ),
            "Invalid Queue transaction inclusion proof."
        );

        bytes32 transactionHash = keccak256(
            abi.encode(
                _transaction.l1TxOrigin,
                _transaction.entrypoint,
                _transaction.gasLimit,
                _transaction.data
            )
        );

        Lib_OVMCodec.QueueElement memory el = getQueueElement(_queueIndex);
        require(
            el.transactionHash      == transactionHash
            && el.timestamp   == _transaction.timestamp
            && el.blockNumber == _transaction.blockNumber,
            "Invalid Queue transaction."
        );

        return true;
    }

    /**
     * Verifies a batch inclusion proof.
     * @param _element Hash of the element to verify a proof for.
     * @param _batchHeader Header of the batch in which the element was included.
     * @param _proof Merkle inclusion proof for the element.
     */
    function _verifyElement(
        bytes32 _element,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _proof
    )
        internal
        view
        returns (
            bool
        )
    {
        require(
            Lib_OVMCodec.hashBatchHeader(_batchHeader) == batches().get(uint32(_batchHeader.batchIndex)),
            "Invalid batch header."
        );

        require(
            Lib_MerkleTree.verify(
                _batchHeader.batchRoot,
                _element,
                _proof.index,
                _proof.siblings,
                _batchHeader.batchSize
            ),
            "Invalid inclusion proof."
        );

        return true;
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";
import { Lib_AddressResolver } from "../../libraries/resolver/Lib_AddressResolver.sol";
import { Lib_EthUtils } from "../../libraries/utils/Lib_EthUtils.sol";
import { Lib_ErrorUtils } from "../../libraries/utils/Lib_ErrorUtils.sol";

/* Interface Imports */
import { iOVM_ExecutionManager } from "../../iOVM/execution/iOVM_ExecutionManager.sol";
import { iOVM_StateManager } from "../../iOVM/execution/iOVM_StateManager.sol";
import { iOVM_SafetyChecker } from "../../iOVM/execution/iOVM_SafetyChecker.sol";

/* Contract Imports */
import { OVM_DeployerWhitelist } from "../predeploys/OVM_DeployerWhitelist.sol";

/**
 * @title OVM_ExecutionManager
 * @dev The Execution Manager (EM) is the core of our OVM implementation, and provides a sandboxed
 * environment allowing us to execute OVM transactions deterministically on either Layer 1 or
 * Layer 2.
 * The EM's run() function is the first function called during the execution of any
 * transaction on L2.
 * For each context-dependent EVM operation the EM has a function which implements a corresponding
 * OVM operation, which will read state from the State Manager contract.
 * The EM relies on the Safety Checker to verify that code deployed to Layer 2 does not contain any
 * context-dependent operations.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_ExecutionManager is iOVM_ExecutionManager, Lib_AddressResolver {

    /********************************
     * External Contract References *
     ********************************/

    iOVM_SafetyChecker internal ovmSafetyChecker;
    iOVM_StateManager internal ovmStateManager;


    /*******************************
     * Execution Context Variables *
     *******************************/

    GasMeterConfig internal gasMeterConfig;
    GlobalContext internal globalContext;
    TransactionContext internal transactionContext;
    MessageContext internal messageContext;
    TransactionRecord internal transactionRecord;
    MessageRecord internal messageRecord;


    /**************************
     * Gas Metering Constants *
     **************************/

    address constant GAS_METADATA_ADDRESS = 0x06a506A506a506A506a506a506A506A506A506A5;
    uint256 constant NUISANCE_GAS_SLOAD = 20000;
    uint256 constant NUISANCE_GAS_SSTORE = 20000;
    uint256 constant MIN_NUISANCE_GAS_PER_CONTRACT = 30000;
    uint256 constant NUISANCE_GAS_PER_CONTRACT_BYTE = 100;
    uint256 constant MIN_GAS_FOR_INVALID_STATE_ACCESS = 30000;

    /**************************
     * Default Context Values *
     **************************/

    uint256 constant DEFAULT_UINT256 = 0xdefa017defa017defa017defa017defa017defa017defa017defa017defa017d;
    address constant DEFAULT_ADDRESS = 0xdEfa017defA017DeFA017DEfa017DeFA017DeFa0;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Address Manager.
     */
    constructor(
        address _libAddressManager,
        GasMeterConfig memory _gasMeterConfig,
        GlobalContext memory _globalContext
    )
        Lib_AddressResolver(_libAddressManager)
    {
        ovmSafetyChecker = iOVM_SafetyChecker(resolve("OVM_SafetyChecker"));
        gasMeterConfig = _gasMeterConfig;
        globalContext = _globalContext;
        _resetContext();
    }


    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Applies dynamically-sized refund to a transaction to account for the difference in execution
     * between L1 and L2, so that the overall cost of the ovmOPCODE is fixed.
     * @param _cost Desired gas cost for the function after the refund.
     */
    modifier netGasCost(
        uint256 _cost
    ) {
        uint256 gasProvided = gasleft();
        _;
        uint256 gasUsed = gasProvided - gasleft();

        // We want to refund everything *except* the specified cost.
        if (_cost < gasUsed) {
            transactionRecord.ovmGasRefund += gasUsed - _cost;
        }
    }

    /**
     * Applies a fixed-size gas refund to a transaction to account for the difference in execution
     * between L1 and L2, so that the overall cost of an ovmOPCODE can be lowered.
     * @param _discount Amount of gas cost to refund for the ovmOPCODE.
     */
    modifier fixedGasDiscount(
        uint256 _discount
    ) {
        uint256 gasProvided = gasleft();
        _;
        uint256 gasUsed = gasProvided - gasleft();

        // We want to refund the specified _discount, unless this risks underflow.
        if (_discount < gasUsed) {
            transactionRecord.ovmGasRefund += _discount;
        } else {
            // refund all we can without risking underflow.
            transactionRecord.ovmGasRefund += gasUsed;
        }
    }

    /**
     * Makes sure we're not inside a static context.
     */
    modifier notStatic() {
        if (messageContext.isStatic == true) {
            _revertWithFlag(RevertFlag.STATIC_VIOLATION);
        }
        _;
    }


    /************************************
     * Transaction Execution Entrypoint *
     ************************************/

    /**
     * Starts the execution of a transaction via the OVM_ExecutionManager.
     * @param _transaction Transaction data to be executed.
     * @param _ovmStateManager iOVM_StateManager implementation providing account state.
     */
    function run(
        Lib_OVMCodec.Transaction memory _transaction,
        address _ovmStateManager
    )
        override
        external
        returns (
            bytes memory
        )
    {
        // Make sure that run() is not re-enterable.  This condition should always be satisfied
        // Once run has been called once, due to the behavior of _isValidInput().
        if (transactionContext.ovmNUMBER != DEFAULT_UINT256) {
            return bytes("");
        }

        // Store our OVM_StateManager instance (significantly easier than attempting to pass the
        // address around in calldata).
        ovmStateManager = iOVM_StateManager(_ovmStateManager);

        // Make sure this function can't be called by anyone except the owner of the
        // OVM_StateManager (expected to be an OVM_StateTransitioner). We can revert here because
        // this would make the `run` itself invalid.
        require(
            // This method may return false during fraud proofs, but always returns true in L2 nodes' State Manager precompile.
            ovmStateManager.isAuthenticated(msg.sender),
            "Only authenticated addresses in ovmStateManager can call this function"
        );

        // Initialize the execution context, must be initialized before we perform any gas metering
        // or we'll throw a nuisance gas error.
        _initContext(_transaction);

        // TEMPORARY: Gas metering is disabled for minnet.
        // // Check whether we need to start a new epoch, do so if necessary.
        // _checkNeedsNewEpoch(_transaction.timestamp);

        // Make sure the transaction's gas limit is valid. We don't revert here because we reserve
        // reverts for INVALID_STATE_ACCESS.
        if (_isValidInput(_transaction) == false) {
            _resetContext();
            return bytes("");
        }

        // TEMPORARY: Gas metering is disabled for minnet.
        // // Check gas right before the call to get total gas consumed by OVM transaction.
        // uint256 gasProvided = gasleft();

        // Run the transaction, make sure to meter the gas usage.
        (, bytes memory returndata) = ovmCALL(
            _transaction.gasLimit - gasMeterConfig.minTransactionGasLimit,
            _transaction.entrypoint,
            _transaction.data
        );

        // TEMPORARY: Gas metering is disabled for minnet.
        // // Update the cumulative gas based on the amount of gas used.
        // uint256 gasUsed = gasProvided - gasleft();
        // _updateCumulativeGas(gasUsed, _transaction.l1QueueOrigin);

        // Wipe the execution context.
        _resetContext();

        return returndata;
    }


    /******************************
     * Opcodes: Execution Context *
     ******************************/

    /**
     * @notice Overrides CALLER.
     * @return _CALLER Address of the CALLER within the current message context.
     */
    function ovmCALLER()
        override
        external
        view
        returns (
            address _CALLER
        )
    {
        return messageContext.ovmCALLER;
    }

    /**
     * @notice Overrides ADDRESS.
     * @return _ADDRESS Active ADDRESS within the current message context.
     */
    function ovmADDRESS()
        override
        public
        view
        returns (
            address _ADDRESS
        )
    {
        return messageContext.ovmADDRESS;
    }

    /**
     * @notice Overrides TIMESTAMP.
     * @return _TIMESTAMP Value of the TIMESTAMP within the transaction context.
     */
    function ovmTIMESTAMP()
        override
        external
        view
        returns (
            uint256 _TIMESTAMP
        )
    {
        return transactionContext.ovmTIMESTAMP;
    }

    /**
     * @notice Overrides NUMBER.
     * @return _NUMBER Value of the NUMBER within the transaction context.
     */
    function ovmNUMBER()
        override
        external
        view
        returns (
            uint256 _NUMBER
        )
    {
        return transactionContext.ovmNUMBER;
    }

    /**
     * @notice Overrides GASLIMIT.
     * @return _GASLIMIT Value of the block's GASLIMIT within the transaction context.
     */
    function ovmGASLIMIT()
        override
        external
        view
        returns (
            uint256 _GASLIMIT
        )
    {
        return transactionContext.ovmGASLIMIT;
    }

    /**
     * @notice Overrides CHAINID.
     * @return _CHAINID Value of the chain's CHAINID within the global context.
     */
    function ovmCHAINID()
        override
        external
        view
        returns (
            uint256 _CHAINID
        )
    {
        return globalContext.ovmCHAINID;
    }

    /*********************************
     * Opcodes: L2 Execution Context *
     *********************************/

    /**
     * @notice Specifies from which source (Sequencer or Queue) this transaction originated from.
     * @return _queueOrigin Enum indicating the ovmL1QUEUEORIGIN within the current message context.
     */
    function ovmL1QUEUEORIGIN()
        override
        external
        view
        returns (
            Lib_OVMCodec.QueueOrigin _queueOrigin
        )
    {
        return transactionContext.ovmL1QUEUEORIGIN;
    }

    /**
     * @notice Specifies which L1 account, if any, sent this transaction by calling enqueue().
     * @return _l1TxOrigin Address of the account which sent the tx into L2 from L1.
     */
    function ovmL1TXORIGIN()
        override
        external
        view
        returns (
            address _l1TxOrigin
        )
    {
        return transactionContext.ovmL1TXORIGIN;
    }

    /********************
     * Opcodes: Halting *
     ********************/

    /**
     * @notice Overrides REVERT.
     * @param _data Bytes data to pass along with the REVERT.
     */
    function ovmREVERT(
        bytes memory _data
    )
        override
        public
    {
        _revertWithFlag(RevertFlag.INTENTIONAL_REVERT, _data);
    }


    /******************************
     * Opcodes: Contract Creation *
     ******************************/

    /**
     * @notice Overrides CREATE.
     * @param _bytecode Code to be used to CREATE a new contract.
     * @return Address of the created contract.
     * @return Revert data, if and only if the creation threw an exception.
     */
    function ovmCREATE(
        bytes memory _bytecode
    )
        override
        public
        notStatic
        fixedGasDiscount(40000)
        returns (
            address,
            bytes memory
        )
    {
        // Creator is always the current ADDRESS.
        address creator = ovmADDRESS();

        // Check that the deployer is whitelisted, or
        // that arbitrary contract deployment has been enabled.
        _checkDeployerAllowed(creator);

        // Generate the correct CREATE address.
        address contractAddress = Lib_EthUtils.getAddressForCREATE(
            creator,
            _getAccountNonce(creator)
        );

        return _createContract(
            contractAddress,
            _bytecode
        );
    }

    /**
     * @notice Overrides CREATE2.
     * @param _bytecode Code to be used to CREATE2 a new contract.
     * @param _salt Value used to determine the contract's address.
     * @return Address of the created contract.
     * @return Revert data, if and only if the creation threw an exception.
     */
    function ovmCREATE2(
        bytes memory _bytecode,
        bytes32 _salt
    )
        override
        external
        notStatic
        fixedGasDiscount(40000)
        returns (
            address,
            bytes memory
        )
    {
        // Creator is always the current ADDRESS.
        address creator = ovmADDRESS();

        // Check that the deployer is whitelisted, or
        // that arbitrary contract deployment has been enabled.
        _checkDeployerAllowed(creator);

        // Generate the correct CREATE2 address.
        address contractAddress = Lib_EthUtils.getAddressForCREATE2(
            creator,
            _bytecode,
            _salt
        );

        return _createContract(
            contractAddress,
            _bytecode
        );
    }


    /*******************************
     * Account Abstraction Opcodes *
     ******************************/

    /**
     * Retrieves the nonce of the current ovmADDRESS.
     * @return _nonce Nonce of the current contract.
     */
    function ovmGETNONCE()
        override
        external
        returns (
            uint256 _nonce
        )
    {
        return _getAccountNonce(ovmADDRESS());
    }

    /**
     * Bumps the nonce of the current ovmADDRESS by one.
     */
    function ovmINCREMENTNONCE()
        override
        external
        notStatic
    {
        address account = ovmADDRESS();
        uint256 nonce = _getAccountNonce(account);

        // Prevent overflow.
        if (nonce + 1 > nonce) {
            _setAccountNonce(account, nonce + 1);
        }
    }

    /**
     * Creates a new EOA contract account, for account abstraction.
     * @dev Essentially functions like ovmCREATE or ovmCREATE2, but we can bypass a lot of checks
     *      because the contract we're creating is trusted (no need to do safety checking or to
     *      handle unexpected reverts). Doesn't need to return an address because the address is
     *      assumed to be the user's actual address.
     * @param _messageHash Hash of a message signed by some user, for verification.
     * @param _v Signature `v` parameter.
     * @param _r Signature `r` parameter.
     * @param _s Signature `s` parameter.
     */
    function ovmCREATEEOA(
        bytes32 _messageHash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        override
        public
        notStatic
    {
        // Recover the EOA address from the message hash and signature parameters. Since we do the
        // hashing in advance, we don't have handle different message hashing schemes. Even if this
        // function were to return the wrong address (rather than explicitly returning the zero
        // address), the rest of the transaction would simply fail (since there's no EOA account to
        // actually execute the transaction).
        address eoa = ecrecover(
            _messageHash,
            _v + 27,
            _r,
            _s
        );

        // Invalid signature is a case we proactively handle with a revert. We could alternatively
        // have this function return a `success` boolean, but this is just easier.
        if (eoa == address(0)) {
            ovmREVERT(bytes("Signature provided for EOA contract creation is invalid."));
        }

        // If the user already has an EOA account, then there's no need to perform this operation.
        if (_hasEmptyAccount(eoa) == false) {
            return;
        }

        // We always need to initialize the contract with the default account values.
        _initPendingAccount(eoa);

        // Temporarily set the current address so it's easier to access on L2.
        address prevADDRESS = messageContext.ovmADDRESS;
        messageContext.ovmADDRESS = eoa;

        // Creates a duplicate of the OVM_ProxyEOA located at 0x42....09. Uses the following
        // "magic" prefix to deploy an exact copy of the code:
        // PUSH1 0x0D   # size of this prefix in bytes
        // CODESIZE
        // SUB          # subtract prefix size from codesize
        // DUP1
        // PUSH1 0x0D
        // PUSH1 0x00
        // CODECOPY     # copy everything after prefix into memory at pos 0
        // PUSH1 0x00
        // RETURN       # return the copied code
        address proxyEOA = Lib_EthUtils.createContract(abi.encodePacked(
            hex"600D380380600D6000396000f3",
            ovmEXTCODECOPY(
                0x4200000000000000000000000000000000000009,
                0,
                ovmEXTCODESIZE(0x4200000000000000000000000000000000000009)
            )
        ));

        // Reset the address now that we're done deploying.
        messageContext.ovmADDRESS = prevADDRESS;

        // Commit the account with its final values.
        _commitPendingAccount(
            eoa,
            address(proxyEOA),
            keccak256(Lib_EthUtils.getCode(address(proxyEOA)))
        );

        _setAccountNonce(eoa, 0);
    }


    /*********************************
     * Opcodes: Contract Interaction *
     *********************************/

    /**
     * @notice Overrides CALL.
     * @param _gasLimit Amount of gas to be passed into this call.
     * @param _address Address of the contract to call.
     * @param _calldata Data to send along with the call.
     * @return _success Whether or not the call returned (rather than reverted).
     * @return _returndata Data returned by the call.
     */
    function ovmCALL(
        uint256 _gasLimit,
        address _address,
        bytes memory _calldata
    )
        override
        public
        fixedGasDiscount(100000)
        returns (
            bool _success,
            bytes memory _returndata
        )
    {
        // CALL updates the CALLER and ADDRESS.
        MessageContext memory nextMessageContext = messageContext;
        nextMessageContext.ovmCALLER = nextMessageContext.ovmADDRESS;
        nextMessageContext.ovmADDRESS = _address;

        return _callContract(
            nextMessageContext,
            _gasLimit,
            _address,
            _calldata
        );
    }

    /**
     * @notice Overrides STATICCALL.
     * @param _gasLimit Amount of gas to be passed into this call.
     * @param _address Address of the contract to call.
     * @param _calldata Data to send along with the call.
     * @return _success Whether or not the call returned (rather than reverted).
     * @return _returndata Data returned by the call.
     */
    function ovmSTATICCALL(
        uint256 _gasLimit,
        address _address,
        bytes memory _calldata
    )
        override
        external
        fixedGasDiscount(80000)
        returns (
            bool _success,
            bytes memory _returndata
        )
    {
        // STATICCALL updates the CALLER, updates the ADDRESS, and runs in a static context.
        MessageContext memory nextMessageContext = messageContext;
        nextMessageContext.ovmCALLER = nextMessageContext.ovmADDRESS;
        nextMessageContext.ovmADDRESS = _address;
        nextMessageContext.isStatic = true;

        return _callContract(
            nextMessageContext,
            _gasLimit,
            _address,
            _calldata
        );
    }

    /**
     * @notice Overrides DELEGATECALL.
     * @param _gasLimit Amount of gas to be passed into this call.
     * @param _address Address of the contract to call.
     * @param _calldata Data to send along with the call.
     * @return _success Whether or not the call returned (rather than reverted).
     * @return _returndata Data returned by the call.
     */
    function ovmDELEGATECALL(
        uint256 _gasLimit,
        address _address,
        bytes memory _calldata
    )
        override
        external
        fixedGasDiscount(40000)
        returns (
            bool _success,
            bytes memory _returndata
        )
    {
        // DELEGATECALL does not change anything about the message context.
        MessageContext memory nextMessageContext = messageContext;

        return _callContract(
            nextMessageContext,
            _gasLimit,
            _address,
            _calldata
        );
    }


    /************************************
     * Opcodes: Contract Storage Access *
     ************************************/

    /**
     * @notice Overrides SLOAD.
     * @param _key 32 byte key of the storage slot to load.
     * @return _value 32 byte value of the requested storage slot.
     */
    function ovmSLOAD(
        bytes32 _key
    )
        override
        external
        netGasCost(40000)
        returns (
            bytes32 _value
        )
    {
        // We always SLOAD from the storage of ADDRESS.
        address contractAddress = ovmADDRESS();

        return _getContractStorage(
            contractAddress,
            _key
        );
    }

    /**
     * @notice Overrides SSTORE.
     * @param _key 32 byte key of the storage slot to set.
     * @param _value 32 byte value for the storage slot.
     */
    function ovmSSTORE(
        bytes32 _key,
        bytes32 _value
    )
        override
        external
        notStatic
        netGasCost(60000)
    {
        // We always SSTORE to the storage of ADDRESS.
        address contractAddress = ovmADDRESS();

        _putContractStorage(
            contractAddress,
            _key,
            _value
        );
    }


    /*********************************
     * Opcodes: Contract Code Access *
     *********************************/

    /**
     * @notice Overrides EXTCODECOPY.
     * @param _contract Address of the contract to copy code from.
     * @param _offset Offset in bytes from the start of contract code to copy beyond.
     * @param _length Total number of bytes to copy from the contract's code.
     * @return _code Bytes of code copied from the requested contract.
     */
    function ovmEXTCODECOPY(
        address _contract,
        uint256 _offset,
        uint256 _length
    )
        override
        public
        returns (
            bytes memory _code
        )
    {
        return Lib_EthUtils.getCode(
            _getAccountEthAddress(_contract),
            _offset,
            _length
        );
    }

    /**
     * @notice Overrides EXTCODESIZE.
     * @param _contract Address of the contract to query the size of.
     * @return _EXTCODESIZE Size of the requested contract in bytes.
     */
    function ovmEXTCODESIZE(
        address _contract
    )
        override
        public
        returns (
            uint256 _EXTCODESIZE
        )
    {
        return Lib_EthUtils.getCodeSize(
            _getAccountEthAddress(_contract)
        );
    }

    /**
     * @notice Overrides EXTCODEHASH.
     * @param _contract Address of the contract to query the hash of.
     * @return _EXTCODEHASH Hash of the requested contract.
     */
    function ovmEXTCODEHASH(
        address _contract
    )
        override
        external
        returns (
            bytes32 _EXTCODEHASH
        )
    {
        return Lib_EthUtils.getCodeHash(
            _getAccountEthAddress(_contract)
        );
    }

    /***************************************
     * Public Functions: Execution Context *
     ***************************************/

    function getMaxTransactionGasLimit()
        external
        view
        override
        returns (
            uint256 _maxTransactionGasLimit
        )
    {
        return gasMeterConfig.maxTransactionGasLimit;
    }

    /********************************************
     * Public Functions: Deployment Whitelisting *
     ********************************************/

    /**
     * Checks whether the given address is on the whitelist to ovmCREATE/ovmCREATE2, and reverts if not.
     * @param _deployerAddress Address attempting to deploy a contract.
     */
    function _checkDeployerAllowed(
        address _deployerAddress
    )
        internal
    {
        // From an OVM semantics perspective, this will appear identical to
        // the deployer ovmCALLing the whitelist.  This is fine--in a sense, we are forcing them to.
        (bool success, bytes memory data) = ovmCALL(
            gasleft(),
            0x4200000000000000000000000000000000000002,
            abi.encodeWithSignature("isDeployerAllowed(address)", _deployerAddress)
        );
        bool isAllowed = abi.decode(data, (bool));

        if (!isAllowed || !success) {
            _revertWithFlag(RevertFlag.CREATOR_NOT_ALLOWED);
        }
    }

    /********************************************
     * Internal Functions: Contract Interaction *
     ********************************************/

    /**
     * Creates a new contract and associates it with some contract address.
     * @param _contractAddress Address to associate the created contract with.
     * @param _bytecode Bytecode to be used to create the contract.
     * @return Final OVM contract address.
     * @return Revertdata, if and only if the creation threw an exception.
     */
    function _createContract(
        address _contractAddress,
        bytes memory _bytecode
    )
        internal
        returns (
            address,
            bytes memory
        )
    {
        // We always update the nonce of the creating account, even if the creation fails.
        _setAccountNonce(ovmADDRESS(), _getAccountNonce(ovmADDRESS()) + 1);

        // We're stepping into a CREATE or CREATE2, so we need to update ADDRESS to point
        // to the contract's associated address and CALLER to point to the previous ADDRESS.
        MessageContext memory nextMessageContext = messageContext;
        nextMessageContext.ovmCALLER = messageContext.ovmADDRESS;
        nextMessageContext.ovmADDRESS = _contractAddress;

        // Run the common logic which occurs between call-type and create-type messages,
        // passing in the creation bytecode and `true` to trigger create-specific logic.
        (bool success, bytes memory data) = _handleExternalMessage(
            nextMessageContext,
            gasleft(),
            _contractAddress,
            _bytecode,
            true
        );

        // Yellow paper requires that address returned is zero if the contract deployment fails.
        return (
            success ? _contractAddress : address(0),
            data
        );
    }

    /**
     * Calls the deployed contract associated with a given address.
     * @param _nextMessageContext Message context to be used for the call.
     * @param _gasLimit Amount of gas to be passed into this call.
     * @param _contract OVM address to be called.
     * @param _calldata Data to send along with the call.
     * @return _success Whether or not the call returned (rather than reverted).
     * @return _returndata Data returned by the call.
     */
    function _callContract(
        MessageContext memory _nextMessageContext,
        uint256 _gasLimit,
        address _contract,
        bytes memory _calldata
    )
        internal
        returns (
            bool _success,
            bytes memory _returndata
        )
    {
        // We reserve addresses of the form 0xdeaddeaddead...NNNN for the container contracts in L2 geth.
        // So, we block calls to these addresses since they are not safe to run as an OVM contract itself.
        if (
            (uint256(_contract) & uint256(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000))
            == uint256(0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000)
        ) {
            // EVM does not return data in the success case, see: https://github.com/ethereum/go-ethereum/blob/aae7660410f0ef90279e14afaaf2f429fdc2a186/core/vm/instructions.go#L600-L604
            return (true, hex'');
        }

        // Both 0x0000... and the EVM precompiles have the same address on L1 and L2 --> no trie lookup needed.
        address codeContractAddress =
            uint(_contract) < 100
            ? _contract
            : _getAccountEthAddress(_contract);

        return _handleExternalMessage(
            _nextMessageContext,
            _gasLimit,
            codeContractAddress,
            _calldata,
            false
        );
    }

    /**
     * Handles all interactions which involve the execution manager calling out to untrusted code (both calls and creates).
     * Ensures that OVM-related measures are enforced, including L2 gas refunds, nuisance gas, and flagged reversions.
     *
     * @param _nextMessageContext Message context to be used for the external message.
     * @param _gasLimit Amount of gas to be passed into this message.
     * @param _contract OVM address being called or deployed to
     * @param _data Data for the message (either calldata or creation code)
     * @param _isCreate Whether this is a create-type message.
     * @return Whether or not the message (either a call or deployment) succeeded.
     * @return Data returned by the message.
     */
    function _handleExternalMessage(
        MessageContext memory _nextMessageContext,
        uint256 _gasLimit,
        address _contract,
        bytes memory _data,
        bool _isCreate
    )
        internal
        returns (
            bool,
            bytes memory
        )
    {
        // We need to switch over to our next message context for the duration of this call.
        MessageContext memory prevMessageContext = messageContext;
        _switchMessageContext(prevMessageContext, _nextMessageContext);

        // Nuisance gas is a system used to bound the ability for an attacker to make fraud proofs
        // expensive by touching a lot of different accounts or storage slots. Since most contracts
        // only use a few storage slots during any given transaction, this shouldn't be a limiting
        // factor.
        uint256 prevNuisanceGasLeft = messageRecord.nuisanceGasLeft;
        uint256 nuisanceGasLimit = _getNuisanceGasLimit(_gasLimit);
        messageRecord.nuisanceGasLeft = nuisanceGasLimit;

        // Make the call and make sure to pass in the gas limit. Another instance of hidden
        // complexity. `_contract` is guaranteed to be a safe contract, meaning its return/revert
        // behavior can be controlled. In particular, we enforce that flags are passed through
        // revert data as to retrieve execution metadata that would normally be reverted out of
        // existence.

        bool success;
        bytes memory returndata;
        if (_isCreate) {
            // safeCREATE() is a function which replicates a CREATE message, but uses return values
            // Which match that of CALL (i.e. bool, bytes).  This allows many security checks to be
            // to be shared between untrusted call and create call frames.
            (success, returndata) = address(this).call(
                abi.encodeWithSelector(
                    this.safeCREATE.selector,
                    _gasLimit,
                    _data,
                    _contract
                )
            );
        } else {
            (success, returndata) = _contract.call{gas: _gasLimit}(_data);
        }

        // Switch back to the original message context now that we're out of the call.
        _switchMessageContext(_nextMessageContext, prevMessageContext);

        // Assuming there were no reverts, the message record should be accurate here. We'll update
        // this value in the case of a revert.
        uint256 nuisanceGasLeft = messageRecord.nuisanceGasLeft;

        // Reverts at this point are completely OK, but we need to make a few updates based on the
        // information passed through the revert.
        if (success == false) {
            (
                RevertFlag flag,
                uint256 nuisanceGasLeftPostRevert,
                uint256 ovmGasRefund,
                bytes memory returndataFromFlag
            ) = _decodeRevertData(returndata);

            // INVALID_STATE_ACCESS is the only flag that triggers an immediate abort of the
            // parent EVM message. This behavior is necessary because INVALID_STATE_ACCESS must
            // halt any further transaction execution that could impact the execution result.
            if (flag == RevertFlag.INVALID_STATE_ACCESS) {
                _revertWithFlag(flag);
            }

            // INTENTIONAL_REVERT, UNSAFE_BYTECODE, STATIC_VIOLATION, and CREATOR_NOT_ALLOWED aren't
            // dependent on the input state, so we can just handle them like standard reverts. Our only change here
            // is to record the gas refund reported by the call (enforced by safety checking).
            if (
                flag == RevertFlag.INTENTIONAL_REVERT
                || flag == RevertFlag.UNSAFE_BYTECODE
                || flag == RevertFlag.STATIC_VIOLATION
                || flag == RevertFlag.CREATOR_NOT_ALLOWED
            ) {
                transactionRecord.ovmGasRefund = ovmGasRefund;
            }

            // INTENTIONAL_REVERT needs to pass up the user-provided return data encoded into the
            // flag, *not* the full encoded flag. All other revert types return no data.
            if (
                flag == RevertFlag.INTENTIONAL_REVERT
                || _isCreate
            ) {
                returndata = returndataFromFlag;
            } else {
                returndata = hex'';
            }

            // Reverts mean we need to use up whatever "nuisance gas" was used by the call.
            // EXCEEDS_NUISANCE_GAS explicitly reduces the remaining nuisance gas for this message
            // to zero. OUT_OF_GAS is a "pseudo" flag given that messages return no data when they
            // run out of gas, so we have to treat this like EXCEEDS_NUISANCE_GAS. All other flags
            // will simply pass up the remaining nuisance gas.
            nuisanceGasLeft = nuisanceGasLeftPostRevert;
        }

        // We need to reset the nuisance gas back to its original value minus the amount used here.
        messageRecord.nuisanceGasLeft = prevNuisanceGasLeft - (nuisanceGasLimit - nuisanceGasLeft);

        return (
            success,
            returndata
        );
    }

    /**
     * Handles the creation-specific safety measures required for OVM contract deployment.
     * This function sanitizes the return types for creation messages to match calls (bool, bytes),
     * by being an external function which the EM can call, that mimics the success/fail case of the CREATE.
     * This allows for consistent handling of both types of messages in _handleExternalMessage().
     * Having this step occur as a separate call frame also allows us to easily revert the
     * contract deployment in the event that the code is unsafe.
     *
     * @param _gasLimit Amount of gas to be passed into this creation.
     * @param _creationCode Code to pass into CREATE for deployment.
     * @param _address OVM address being deployed to.
     */
    function safeCREATE(
        uint _gasLimit,
        bytes memory _creationCode,
        address _address
    )
        external
    {
        // The only way this should callable is from within _createContract(),
        // and it should DEFINITELY not be callable by a non-EM code contract.
        if (msg.sender != address(this)) {
            return;
        }
        // Check that there is not already code at this address.
        if (_hasEmptyAccount(_address) == false) {
            // Note: in the EVM, this case burns all allotted gas.  For improved
            // developer experience, we do return the remaining gas.
            _revertWithFlag(
                RevertFlag.CREATE_COLLISION,
                Lib_ErrorUtils.encodeRevertString("A contract has already been deployed to this address")
            );
        }

        // Check the creation bytecode against the OVM_SafetyChecker.
        if (ovmSafetyChecker.isBytecodeSafe(_creationCode) == false) {
            _revertWithFlag(
                RevertFlag.UNSAFE_BYTECODE,
                Lib_ErrorUtils.encodeRevertString("Contract creation code contains unsafe opcodes. Did you use the right compiler or pass an unsafe constructor argument?")
            );
        }

        // We always need to initialize the contract with the default account values.
        _initPendingAccount(_address);

        // Actually execute the EVM create message.
        // NOTE: The inline assembly below means we can NOT make any evm calls between here and then.
        address ethAddress = Lib_EthUtils.createContract(_creationCode);

        if (ethAddress == address(0)) {
            // If the creation fails, the EVM lets us grab its revert data. This may contain a revert flag
            // to be used above in _handleExternalMessage, so we pass the revert data back up unmodified.
            assembly {
                returndatacopy(0,0,returndatasize())
                revert(0, returndatasize())
            }
        }

        // Again simply checking that the deployed code is safe too. Contracts can generate
        // arbitrary deployment code, so there's no easy way to analyze this beforehand.
        bytes memory deployedCode = Lib_EthUtils.getCode(ethAddress);
        if (ovmSafetyChecker.isBytecodeSafe(deployedCode) == false) {
            _revertWithFlag(
                RevertFlag.UNSAFE_BYTECODE,
                Lib_ErrorUtils.encodeRevertString("Constructor attempted to deploy unsafe bytecode.")
            );
        }

        // Contract creation didn't need to be reverted and the bytecode is safe. We finish up by
        // associating the desired address with the newly created contract's code hash and address.
        _commitPendingAccount(
            _address,
            ethAddress,
            Lib_EthUtils.getCodeHash(ethAddress)
        );
    }

    /******************************************
     * Internal Functions: State Manipulation *
     ******************************************/

    /**
     * Checks whether an account exists within the OVM_StateManager.
     * @param _address Address of the account to check.
     * @return _exists Whether or not the account exists.
     */
    function _hasAccount(
        address _address
    )
        internal
        returns (
            bool _exists
        )
    {
        _checkAccountLoad(_address);
        return ovmStateManager.hasAccount(_address);
    }

    /**
     * Checks whether a known empty account exists within the OVM_StateManager.
     * @param _address Address of the account to check.
     * @return _exists Whether or not the account empty exists.
     */
    function _hasEmptyAccount(
        address _address
    )
        internal
        returns (
            bool _exists
        )
    {
        _checkAccountLoad(_address);
        return ovmStateManager.hasEmptyAccount(_address);
    }

    /**
     * Sets the nonce of an account.
     * @param _address Address of the account to modify.
     * @param _nonce New account nonce.
     */
    function _setAccountNonce(
        address _address,
        uint256 _nonce
    )
        internal
    {
        _checkAccountChange(_address);
        ovmStateManager.setAccountNonce(_address, _nonce);
    }

    /**
     * Gets the nonce of an account.
     * @param _address Address of the account to access.
     * @return _nonce Nonce of the account.
     */
    function _getAccountNonce(
        address _address
    )
        internal
        returns (
            uint256 _nonce
        )
    {
        _checkAccountLoad(_address);
        return ovmStateManager.getAccountNonce(_address);
    }

    /**
     * Retrieves the Ethereum address of an account.
     * @param _address Address of the account to access.
     * @return _ethAddress Corresponding Ethereum address.
     */
    function _getAccountEthAddress(
        address _address
    )
        internal
        returns (
            address _ethAddress
        )
    {
        _checkAccountLoad(_address);
        return ovmStateManager.getAccountEthAddress(_address);
    }

    /**
     * Creates the default account object for the given address.
     * @param _address Address of the account create.
     */
    function _initPendingAccount(
        address _address
    )
        internal
    {
        // Although it seems like `_checkAccountChange` would be more appropriate here, we don't
        // actually consider an account "changed" until it's inserted into the state (in this case
        // by `_commitPendingAccount`).
        _checkAccountLoad(_address);
        ovmStateManager.initPendingAccount(_address);
    }

    /**
     * Stores additional relevant data for a new account, thereby "committing" it to the state.
     * This function is only called during `ovmCREATE` and `ovmCREATE2` after a successful contract
     * creation.
     * @param _address Address of the account to commit.
     * @param _ethAddress Address of the associated deployed contract.
     * @param _codeHash Hash of the code stored at the address.
     */
    function _commitPendingAccount(
        address _address,
        address _ethAddress,
        bytes32 _codeHash
    )
        internal
    {
        _checkAccountChange(_address);
        ovmStateManager.commitPendingAccount(
            _address,
            _ethAddress,
            _codeHash
        );
    }

    /**
     * Retrieves the value of a storage slot.
     * @param _contract Address of the contract to query.
     * @param _key 32 byte key of the storage slot.
     * @return _value 32 byte storage slot value.
     */
    function _getContractStorage(
        address _contract,
        bytes32 _key
    )
        internal
        returns (
            bytes32 _value
        )
    {
        _checkContractStorageLoad(_contract, _key);
        return ovmStateManager.getContractStorage(_contract, _key);
    }

    /**
     * Sets the value of a storage slot.
     * @param _contract Address of the contract to modify.
     * @param _key 32 byte key of the storage slot.
     * @param _value 32 byte storage slot value.
     */
    function _putContractStorage(
        address _contract,
        bytes32 _key,
        bytes32 _value
    )
        internal
    {
        // We don't set storage if the value didn't change. Although this acts as a convenient
        // optimization, it's also necessary to avoid the case in which a contract with no storage
        // attempts to store the value "0" at any key. Putting this value (and therefore requiring
        // that the value be committed into the storage trie after execution) would incorrectly
        // modify the storage root.
        if (_getContractStorage(_contract, _key) == _value) {
            return;
        }

        _checkContractStorageChange(_contract, _key);
        ovmStateManager.putContractStorage(_contract, _key, _value);
    }

    /**
     * Validation whenever a contract needs to be loaded. Checks that the account exists, charges
     * nuisance gas if the account hasn't been loaded before.
     * @param _address Address of the account to load.
     */
    function _checkAccountLoad(
        address _address
    )
        internal
    {
        // See `_checkContractStorageLoad` for more information.
        if (gasleft() < MIN_GAS_FOR_INVALID_STATE_ACCESS) {
            _revertWithFlag(RevertFlag.OUT_OF_GAS);
        }

        // See `_checkContractStorageLoad` for more information.
        if (ovmStateManager.hasAccount(_address) == false) {
            _revertWithFlag(RevertFlag.INVALID_STATE_ACCESS);
        }

        // Check whether the account has been loaded before and mark it as loaded if not. We need
        // this because "nuisance gas" only applies to the first time that an account is loaded.
        (
            bool _wasAccountAlreadyLoaded
        ) = ovmStateManager.testAndSetAccountLoaded(_address);

        // If we hadn't already loaded the account, then we'll need to charge "nuisance gas" based
        // on the size of the contract code.
        if (_wasAccountAlreadyLoaded == false) {
            _useNuisanceGas(
                (Lib_EthUtils.getCodeSize(_getAccountEthAddress(_address)) * NUISANCE_GAS_PER_CONTRACT_BYTE) + MIN_NUISANCE_GAS_PER_CONTRACT
            );
        }
    }

    /**
     * Validation whenever a contract needs to be changed. Checks that the account exists, charges
     * nuisance gas if the account hasn't been changed before.
     * @param _address Address of the account to change.
     */
    function _checkAccountChange(
        address _address
    )
        internal
    {
        // Start by checking for a load as we only want to charge nuisance gas proportional to
        // contract size once.
        _checkAccountLoad(_address);

        // Check whether the account has been changed before and mark it as changed if not. We need
        // this because "nuisance gas" only applies to the first time that an account is changed.
        (
            bool _wasAccountAlreadyChanged
        ) = ovmStateManager.testAndSetAccountChanged(_address);

        // If we hadn't already loaded the account, then we'll need to charge "nuisance gas" based
        // on the size of the contract code.
        if (_wasAccountAlreadyChanged == false) {
            ovmStateManager.incrementTotalUncommittedAccounts();
            _useNuisanceGas(
                (Lib_EthUtils.getCodeSize(_getAccountEthAddress(_address)) * NUISANCE_GAS_PER_CONTRACT_BYTE) + MIN_NUISANCE_GAS_PER_CONTRACT
            );
        }
    }

    /**
     * Validation whenever a slot needs to be loaded. Checks that the account exists, charges
     * nuisance gas if the slot hasn't been loaded before.
     * @param _contract Address of the account to load from.
     * @param _key 32 byte key to load.
     */
    function _checkContractStorageLoad(
        address _contract,
        bytes32 _key
    )
        internal
    {
        // Another case of hidden complexity. If we didn't enforce this requirement, then a
        // contract could pass in just enough gas to cause the INVALID_STATE_ACCESS check to fail
        // on L1 but not on L2. A contract could use this behavior to prevent the
        // OVM_ExecutionManager from detecting an invalid state access. Reverting with OUT_OF_GAS
        // allows us to also charge for the full message nuisance gas, because you deserve that for
        // trying to break the contract in this way.
        if (gasleft() < MIN_GAS_FOR_INVALID_STATE_ACCESS) {
            _revertWithFlag(RevertFlag.OUT_OF_GAS);
        }

        // We need to make sure that the transaction isn't trying to access storage that hasn't
        // been provided to the OVM_StateManager. We'll immediately abort if this is the case.
        // We know that we have enough gas to do this check because of the above test.
        if (ovmStateManager.hasContractStorage(_contract, _key) == false) {
            _revertWithFlag(RevertFlag.INVALID_STATE_ACCESS);
        }

        // Check whether the slot has been loaded before and mark it as loaded if not. We need
        // this because "nuisance gas" only applies to the first time that a slot is loaded.
        (
            bool _wasContractStorageAlreadyLoaded
        ) = ovmStateManager.testAndSetContractStorageLoaded(_contract, _key);

        // If we hadn't already loaded the account, then we'll need to charge some fixed amount of
        // "nuisance gas".
        if (_wasContractStorageAlreadyLoaded == false) {
            _useNuisanceGas(NUISANCE_GAS_SLOAD);
        }
    }

    /**
     * Validation whenever a slot needs to be changed. Checks that the account exists, charges
     * nuisance gas if the slot hasn't been changed before.
     * @param _contract Address of the account to change.
     * @param _key 32 byte key to change.
     */
    function _checkContractStorageChange(
        address _contract,
        bytes32 _key
    )
        internal
    {
        // Start by checking for load to make sure we have the storage slot and that we charge the
        // "nuisance gas" necessary to prove the storage slot state.
        _checkContractStorageLoad(_contract, _key);

        // Check whether the slot has been changed before and mark it as changed if not. We need
        // this because "nuisance gas" only applies to the first time that a slot is changed.
        (
            bool _wasContractStorageAlreadyChanged
        ) = ovmStateManager.testAndSetContractStorageChanged(_contract, _key);

        // If we hadn't already changed the account, then we'll need to charge some fixed amount of
        // "nuisance gas".
        if (_wasContractStorageAlreadyChanged == false) {
            // Changing a storage slot means that we're also going to have to change the
            // corresponding account, so do an account change check.
            _checkAccountChange(_contract);

            ovmStateManager.incrementTotalUncommittedContractStorage();
            _useNuisanceGas(NUISANCE_GAS_SSTORE);
        }
    }


    /************************************
     * Internal Functions: Revert Logic *
     ************************************/

    /**
     * Simple encoding for revert data.
     * @param _flag Flag to revert with.
     * @param _data Additional user-provided revert data.
     * @return _revertdata Encoded revert data.
     */
    function _encodeRevertData(
        RevertFlag _flag,
        bytes memory _data
    )
        internal
        view
        returns (
            bytes memory _revertdata
        )
    {
        // Out of gas and create exceptions will fundamentally return no data, so simulating it shouldn't either.
        if (
            _flag == RevertFlag.OUT_OF_GAS
        ) {
            return bytes('');
        }

        // INVALID_STATE_ACCESS doesn't need to return any data other than the flag.
        if (_flag == RevertFlag.INVALID_STATE_ACCESS) {
            return abi.encode(
                _flag,
                0,
                0,
                bytes('')
            );
        }

        // Just ABI encode the rest of the parameters.
        return abi.encode(
            _flag,
            messageRecord.nuisanceGasLeft,
            transactionRecord.ovmGasRefund,
            _data
        );
    }

    /**
     * Simple decoding for revert data.
     * @param _revertdata Revert data to decode.
     * @return _flag Flag used to revert.
     * @return _nuisanceGasLeft Amount of nuisance gas unused by the message.
     * @return _ovmGasRefund Amount of gas refunded during the message.
     * @return _data Additional user-provided revert data.
     */
    function _decodeRevertData(
        bytes memory _revertdata
    )
        internal
        pure
        returns (
            RevertFlag _flag,
            uint256 _nuisanceGasLeft,
            uint256 _ovmGasRefund,
            bytes memory _data
        )
    {
        // A length of zero means the call ran out of gas, just return empty data.
        if (_revertdata.length == 0) {
            return (
                RevertFlag.OUT_OF_GAS,
                0,
                0,
                bytes('')
            );
        }

        // ABI decode the incoming data.
        return abi.decode(_revertdata, (RevertFlag, uint256, uint256, bytes));
    }

    /**
     * Causes a message to revert or abort.
     * @param _flag Flag to revert with.
     * @param _data Additional user-provided data.
     */
    function _revertWithFlag(
        RevertFlag _flag,
        bytes memory _data
    )
        internal
        view
    {
        bytes memory revertdata = _encodeRevertData(
            _flag,
            _data
        );

        assembly {
            revert(add(revertdata, 0x20), mload(revertdata))
        }
    }

    /**
     * Causes a message to revert or abort.
     * @param _flag Flag to revert with.
     */
    function _revertWithFlag(
        RevertFlag _flag
    )
        internal
    {
        _revertWithFlag(_flag, bytes(''));
    }


    /******************************************
     * Internal Functions: Nuisance Gas Logic *
     ******************************************/

    /**
     * Computes the nuisance gas limit from the gas limit.
     * @dev This function is currently using a naive implementation whereby the nuisance gas limit
     *      is set to exactly equal the lesser of the gas limit or remaining gas. It's likely that
     *      this implementation is perfectly fine, but we may change this formula later.
     * @param _gasLimit Gas limit to compute from.
     * @return _nuisanceGasLimit Computed nuisance gas limit.
     */
    function _getNuisanceGasLimit(
        uint256 _gasLimit
    )
        internal
        view
        returns (
            uint256 _nuisanceGasLimit
        )
    {
        return _gasLimit < gasleft() ? _gasLimit : gasleft();
    }

    /**
     * Uses a certain amount of nuisance gas.
     * @param _amount Amount of nuisance gas to use.
     */
    function _useNuisanceGas(
        uint256 _amount
    )
        internal
    {
        // Essentially the same as a standard OUT_OF_GAS, except we also retain a record of the gas
        // refund to be given at the end of the transaction.
        if (messageRecord.nuisanceGasLeft < _amount) {
            _revertWithFlag(RevertFlag.EXCEEDS_NUISANCE_GAS);
        }

        messageRecord.nuisanceGasLeft -= _amount;
    }


    /************************************
     * Internal Functions: Gas Metering *
     ************************************/

    /**
     * Checks whether a transaction needs to start a new epoch and does so if necessary.
     * @param _timestamp Transaction timestamp.
     */
    function _checkNeedsNewEpoch(
        uint256 _timestamp
    )
        internal
    {
        if (
            _timestamp >= (
                _getGasMetadata(GasMetadataKey.CURRENT_EPOCH_START_TIMESTAMP)
                + gasMeterConfig.secondsPerEpoch
            )
        ) {
            _putGasMetadata(
                GasMetadataKey.CURRENT_EPOCH_START_TIMESTAMP,
                _timestamp
            );

            _putGasMetadata(
                GasMetadataKey.PREV_EPOCH_SEQUENCER_QUEUE_GAS,
                _getGasMetadata(
                    GasMetadataKey.CUMULATIVE_SEQUENCER_QUEUE_GAS
                )
            );

            _putGasMetadata(
                GasMetadataKey.PREV_EPOCH_L1TOL2_QUEUE_GAS,
                _getGasMetadata(
                    GasMetadataKey.CUMULATIVE_L1TOL2_QUEUE_GAS
                )
            );
        }
    }

    /**
     * Validates the input values of a transaction.
     * @return _valid Whether or not the transaction data is valid.
     */
    function _isValidInput(
        Lib_OVMCodec.Transaction memory _transaction
    )
        view
        internal
        returns (
            bool
        )
    {
        // Prevent reentrancy to run():
        // This check prevents calling run with the default ovmNumber.
        // Combined with the first check in run():
        //      if (transactionContext.ovmNUMBER != DEFAULT_UINT256) { return; }
        // It should be impossible to re-enter since run() returns before any other call frames are created.
        // Since this value is already being written to storage, we save much gas compared to
        // using the standard nonReentrant pattern.
        if (_transaction.blockNumber == DEFAULT_UINT256)  {
            return false;
        }

        if (_isValidGasLimit(_transaction.gasLimit, _transaction.l1QueueOrigin) == false) {
            return false;
        }

        return true;
    }

    /**
     * Validates the gas limit for a given transaction.
     * @param _gasLimit Gas limit provided by the transaction.
     * param _queueOrigin Queue from which the transaction originated.
     * @return _valid Whether or not the gas limit is valid.
     */
    function _isValidGasLimit(
        uint256 _gasLimit,
        Lib_OVMCodec.QueueOrigin // _queueOrigin
    )
        view
        internal
        returns (
            bool _valid
        )
    {
        // Always have to be below the maximum gas limit.
        if (_gasLimit > gasMeterConfig.maxTransactionGasLimit) {
            return false;
        }

        // Always have to be above the minimum gas limit.
        if (_gasLimit < gasMeterConfig.minTransactionGasLimit) {
            return false;
        }

        // TEMPORARY: Gas metering is disabled for minnet.
        return true;
        // GasMetadataKey cumulativeGasKey;
        // GasMetadataKey prevEpochGasKey;
        // if (_queueOrigin == Lib_OVMCodec.QueueOrigin.SEQUENCER_QUEUE) {
        //     cumulativeGasKey = GasMetadataKey.CUMULATIVE_SEQUENCER_QUEUE_GAS;
        //     prevEpochGasKey = GasMetadataKey.PREV_EPOCH_SEQUENCER_QUEUE_GAS;
        // } else {
        //     cumulativeGasKey = GasMetadataKey.CUMULATIVE_L1TOL2_QUEUE_GAS;
        //     prevEpochGasKey = GasMetadataKey.PREV_EPOCH_L1TOL2_QUEUE_GAS;
        // }

        // return (
        //     (
        //         _getGasMetadata(cumulativeGasKey)
        //         - _getGasMetadata(prevEpochGasKey)
        //         + _gasLimit
        //     ) < gasMeterConfig.maxGasPerQueuePerEpoch
        // );
    }

    /**
     * Updates the cumulative gas after a transaction.
     * @param _gasUsed Gas used by the transaction.
     * @param _queueOrigin Queue from which the transaction originated.
     */
    function _updateCumulativeGas(
        uint256 _gasUsed,
        Lib_OVMCodec.QueueOrigin _queueOrigin
    )
        internal
    {
        GasMetadataKey cumulativeGasKey;
        if (_queueOrigin == Lib_OVMCodec.QueueOrigin.SEQUENCER_QUEUE) {
            cumulativeGasKey = GasMetadataKey.CUMULATIVE_SEQUENCER_QUEUE_GAS;
        } else {
            cumulativeGasKey = GasMetadataKey.CUMULATIVE_L1TOL2_QUEUE_GAS;
        }

        _putGasMetadata(
            cumulativeGasKey,
            (
                _getGasMetadata(cumulativeGasKey)
                + gasMeterConfig.minTransactionGasLimit
                + _gasUsed
                - transactionRecord.ovmGasRefund
            )
        );
    }

    /**
     * Retrieves the value of a gas metadata key.
     * @param _key Gas metadata key to retrieve.
     * @return _value Value stored at the given key.
     */
    function _getGasMetadata(
        GasMetadataKey _key
    )
        internal
        returns (
            uint256 _value
        )
    {
        return uint256(_getContractStorage(
            GAS_METADATA_ADDRESS,
            bytes32(uint256(_key))
        ));
    }

    /**
     * Sets the value of a gas metadata key.
     * @param _key Gas metadata key to set.
     * @param _value Value to store at the given key.
     */
    function _putGasMetadata(
        GasMetadataKey _key,
        uint256 _value
    )
        internal
    {
        _putContractStorage(
            GAS_METADATA_ADDRESS,
            bytes32(uint256(_key)),
            bytes32(uint256(_value))
        );
    }


    /*****************************************
     * Internal Functions: Execution Context *
     *****************************************/

    /**
     * Swaps over to a new message context.
     * @param _prevMessageContext Context we're switching from.
     * @param _nextMessageContext Context we're switching to.
     */
    function _switchMessageContext(
        MessageContext memory _prevMessageContext,
        MessageContext memory _nextMessageContext
    )
        internal
    {
        // Avoid unnecessary the SSTORE.
        if (_prevMessageContext.ovmCALLER != _nextMessageContext.ovmCALLER) {
            messageContext.ovmCALLER = _nextMessageContext.ovmCALLER;
        }

        // Avoid unnecessary the SSTORE.
        if (_prevMessageContext.ovmADDRESS != _nextMessageContext.ovmADDRESS) {
            messageContext.ovmADDRESS = _nextMessageContext.ovmADDRESS;
        }

        // Avoid unnecessary the SSTORE.
        if (_prevMessageContext.isStatic != _nextMessageContext.isStatic) {
            messageContext.isStatic = _nextMessageContext.isStatic;
        }
    }

    /**
     * Initializes the execution context.
     * @param _transaction OVM transaction being executed.
     */
    function _initContext(
        Lib_OVMCodec.Transaction memory _transaction
    )
        internal
    {
        transactionContext.ovmTIMESTAMP = _transaction.timestamp;
        transactionContext.ovmNUMBER = _transaction.blockNumber;
        transactionContext.ovmTXGASLIMIT = _transaction.gasLimit;
        transactionContext.ovmL1QUEUEORIGIN = _transaction.l1QueueOrigin;
        transactionContext.ovmL1TXORIGIN = _transaction.l1TxOrigin;
        transactionContext.ovmGASLIMIT = gasMeterConfig.maxGasPerQueuePerEpoch;

        messageRecord.nuisanceGasLeft = _getNuisanceGasLimit(_transaction.gasLimit);
    }

    /**
     * Resets the transaction and message context.
     */
    function _resetContext()
        internal
    {
        transactionContext.ovmL1TXORIGIN = DEFAULT_ADDRESS;
        transactionContext.ovmTIMESTAMP = DEFAULT_UINT256;
        transactionContext.ovmNUMBER = DEFAULT_UINT256;
        transactionContext.ovmGASLIMIT = DEFAULT_UINT256;
        transactionContext.ovmTXGASLIMIT = DEFAULT_UINT256;
        transactionContext.ovmL1QUEUEORIGIN = Lib_OVMCodec.QueueOrigin.SEQUENCER_QUEUE;

        transactionRecord.ovmGasRefund = DEFAULT_UINT256;

        messageContext.ovmCALLER = DEFAULT_ADDRESS;
        messageContext.ovmADDRESS = DEFAULT_ADDRESS;
        messageContext.isStatic = false;

        messageRecord.nuisanceGasLeft = DEFAULT_UINT256;

        // Reset the ovmStateManager.
        ovmStateManager = iOVM_StateManager(address(0));
    }

    /*****************************
     * L2-only Helper Functions *
     *****************************/

    /**
     * Unreachable helper function for simulating eth_calls with an OVM message context.
     * This function will throw an exception in all cases other than when used as a custom entrypoint in L2 Geth to simulate eth_call.
     * @param _transaction the message transaction to simulate.
     * @param _from the OVM account the simulated call should be from.
     */
    function simulateMessage(
        Lib_OVMCodec.Transaction memory _transaction,
        address _from,
        iOVM_StateManager _ovmStateManager
    )
        external
        returns (
            bytes memory
        )
    {
        // Prevent this call from having any effect unless in a custom-set VM frame
        require(msg.sender == address(0));

        ovmStateManager = _ovmStateManager;
        _initContext(_transaction);
        messageRecord.nuisanceGasLeft = uint(-1);

        messageContext.ovmADDRESS = _from;

        bool isCreate = _transaction.entrypoint == address(0);
        if (isCreate) {
            (address created, bytes memory revertData) = ovmCREATE(_transaction.data);
            if (created == address(0)) {
                return abi.encode(false, revertData);
            } else {
                // The eth_call RPC endpoint for to = undefined will return the deployed bytecode
                // in the success case, differing from standard create messages.
                return abi.encode(true, Lib_EthUtils.getCode(created));
            }
        } else {
            (bool success, bytes memory returndata) = ovmCALL(
                _transaction.gasLimit,
                _transaction.entrypoint,
                _transaction.data
            );
            return abi.encode(success, returndata);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Interface Imports */
import { iOVM_DeployerWhitelist } from "../../iOVM/predeploys/iOVM_DeployerWhitelist.sol";

/**
 * @title OVM_DeployerWhitelist
 * @dev The Deployer Whitelist is a temporary predeploy used to provide additional safety during the
 * initial phases of our mainnet roll out. It is owned by the Optimism team, and defines accounts
 * which are allowed to deploy contracts on Layer2. The Execution Manager will only allow an
 * ovmCREATE or ovmCREATE2 operation to proceed if the deployer's address whitelisted.
 *
 * Compiler used: optimistic-solc
 * Runtime target: OVM
 */
contract OVM_DeployerWhitelist is iOVM_DeployerWhitelist {

    /**********************
     * Contract Constants *
     **********************/

    bool public initialized;
    bool public allowArbitraryDeployment;
    address override public owner;
    mapping (address => bool) public whitelist;


    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Blocks functions to anyone except the contract owner.
     */
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Function can only be called by the owner of this contract."
        );
        _;
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * Initializes the whitelist.
     * @param _owner Address of the owner for this contract.
     * @param _allowArbitraryDeployment Whether or not to allow arbitrary contract deployment.
     */
    function initialize(
        address _owner,
        bool _allowArbitraryDeployment
    )
        override
        external
    {
        if (initialized == true) {
            return;
        }

        initialized = true;
        allowArbitraryDeployment = _allowArbitraryDeployment;
        owner = _owner;
    }

    /**
     * Adds or removes an address from the deployment whitelist.
     * @param _deployer Address to update permissions for.
     * @param _isWhitelisted Whether or not the address is whitelisted.
     */
    function setWhitelistedDeployer(
        address _deployer,
        bool _isWhitelisted
    )
        override
        external
        onlyOwner
    {
        whitelist[_deployer] = _isWhitelisted;
    }

    /**
     * Updates the owner of this contract.
     * @param _owner Address of the new owner.
     */
    function setOwner(
        address _owner
    )
        override
        public
        onlyOwner
    {
        owner = _owner;
    }

    /**
     * Updates the arbitrary deployment flag.
     * @param _allowArbitraryDeployment Whether or not to allow arbitrary contract deployment.
     */
    function setAllowArbitraryDeployment(
        bool _allowArbitraryDeployment
    )
        override
        public
        onlyOwner
    {
        allowArbitraryDeployment = _allowArbitraryDeployment;
    }

    /**
     * Permanently enables arbitrary contract deployment and deletes the owner.
     */
    function enableArbitraryContractDeployment()
        override
        external
        onlyOwner
    {
        setAllowArbitraryDeployment(true);
        setOwner(address(0));
    }

    /**
     * Checks whether an address is allowed to deploy contracts.
     * @param _deployer Address to check.
     * @return _allowed Whether or not the address can deploy contracts.
     */
    function isDeployerAllowed(
        address _deployer
    )
        override
        external
        returns (
            bool
        )
    {
        return (
            initialized == false
            || allowArbitraryDeployment == true
            || whitelist[_deployer]
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";

/* Interface Imports */
import { iOVM_ChainStorageContainer } from "./iOVM_ChainStorageContainer.sol";

/**
 * @title iOVM_CanonicalTransactionChain
 */
interface iOVM_CanonicalTransactionChain {

    /**********
     * Events *
     **********/

    event TransactionEnqueued(
        address _l1TxOrigin,
        address _target,
        uint256 _gasLimit,
        bytes _data,
        uint256 _queueIndex,
        uint256 _timestamp
    );

    event QueueBatchAppended(
        uint256 _startingQueueIndex,
        uint256 _numQueueElements,
        uint256 _totalElements
    );

    event SequencerBatchAppended(
        uint256 _startingQueueIndex,
        uint256 _numQueueElements,
        uint256 _totalElements
    );

    event TransactionBatchAppended(
        uint256 indexed _batchIndex,
        bytes32 _batchRoot,
        uint256 _batchSize,
        uint256 _prevTotalElements,
        bytes _extraData
    );


    /***********
     * Structs *
     ***********/

    struct BatchContext {
        uint256 numSequencedTransactions;
        uint256 numSubsequentQueueTransactions;
        uint256 timestamp;
        uint256 blockNumber;
    }


    /********************
     * Public Functions *
     ********************/


    /**
     * Accesses the batch storage container.
     * @return Reference to the batch storage container.
     */
    function batches()
        external
        view
        returns (
            iOVM_ChainStorageContainer
        );

    /**
     * Accesses the queue storage container.
     * @return Reference to the queue storage container.
     */
    function queue()
        external
        view
        returns (
            iOVM_ChainStorageContainer
        );

    /**
     * Retrieves the total number of elements submitted.
     * @return _totalElements Total submitted elements.
     */
    function getTotalElements()
        external
        view
        returns (
            uint256 _totalElements
        );

    /**
     * Retrieves the total number of batches submitted.
     * @return _totalBatches Total submitted batches.
     */
    function getTotalBatches()
        external
        view
        returns (
            uint256 _totalBatches
        );

    /**
     * Returns the index of the next element to be enqueued.
     * @return Index for the next queue element.
     */
    function getNextQueueIndex()
        external
        view
        returns (
            uint40
        );

    /**
     * Gets the queue element at a particular index.
     * @param _index Index of the queue element to access.
     * @return _element Queue element at the given index.
     */
    function getQueueElement(
        uint256 _index
    )
        external
        view
        returns (
            Lib_OVMCodec.QueueElement memory _element
        );

    /**
     * Returns the timestamp of the last transaction.
     * @return Timestamp for the last transaction.
     */
    function getLastTimestamp()
        external
        view
        returns (
            uint40
        );

    /**
     * Returns the blocknumber of the last transaction.
     * @return Blocknumber for the last transaction.
     */
    function getLastBlockNumber()
        external
        view
        returns (
            uint40
        );

    /**
     * Get the number of queue elements which have not yet been included.
     * @return Number of pending queue elements.
     */
    function getNumPendingQueueElements()
        external
        view
        returns (
            uint40
        );

    /**
     * Retrieves the length of the queue, including
     * both pending and canonical transactions.
     * @return Length of the queue.
     */
    function getQueueLength()
        external
        view
        returns (
            uint40
        );


    /**
     * Adds a transaction to the queue.
     * @param _target Target contract to send the transaction to.
     * @param _gasLimit Gas limit for the given transaction.
     * @param _data Transaction data.
     */
    function enqueue(
        address _target,
        uint256 _gasLimit,
        bytes memory _data
    )
        external;

    /**
     * Appends a given number of queued transactions as a single batch.
     * @param _numQueuedTransactions Number of transactions to append.
     */
    function appendQueueBatch(
        uint256 _numQueuedTransactions
    )
        external;

    /**
     * Allows the sequencer to append a batch of transactions.
     * @dev This function uses a custom encoding scheme for efficiency reasons.
     * .param _shouldStartAtElement Specific batch we expect to start appending to.
     * .param _totalElementsToAppend Total number of batch elements we expect to append.
     * .param _contexts Array of batch contexts.
     * .param _transactionDataFields Array of raw transaction data.
     */
    function appendSequencerBatch(
        // uint40 _shouldStartAtElement,
        // uint24 _totalElementsToAppend,
        // BatchContext[] _contexts,
        // bytes[] _transactionDataFields
    )
        external;

    /**
     * Verifies whether a transaction is included in the chain.
     * @param _transaction Transaction to verify.
     * @param _txChainElement Transaction chain element corresponding to the transaction.
     * @param _batchHeader Header of the batch the transaction was included in.
     * @param _inclusionProof Inclusion proof for the provided transaction chain element.
     * @return True if the transaction exists in the CTC, false if not.
     */
    function verifyTransaction(
        Lib_OVMCodec.Transaction memory _transaction,
        Lib_OVMCodec.TransactionChainElement memory _txChainElement,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _inclusionProof
    )
        external
        view
        returns (
            bool
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title iOVM_ChainStorageContainer
 */
interface iOVM_ChainStorageContainer {

    /********************
     * Public Functions *
     ********************/

    /**
     * Sets the container's global metadata field. We're using `bytes27` here because we use five
     * bytes to maintain the length of the underlying data structure, meaning we have an extra
     * 27 bytes to store arbitrary data.
     * @param _globalMetadata New global metadata to set.
     */
    function setGlobalMetadata(
        bytes27 _globalMetadata
    )
        external;

    /**
     * Retrieves the container's global metadata field.
     * @return Container global metadata field.
     */
    function getGlobalMetadata()
        external
        view
        returns (
            bytes27
        );

    /**
     * Retrieves the number of objects stored in the container.
     * @return Number of objects in the container.
     */
    function length()
        external
        view
        returns (
            uint256
        );

    /**
     * Pushes an object into the container.
     * @param _object A 32 byte value to insert into the container.
     */
    function push(
        bytes32 _object
    )
        external;

    /**
     * Pushes an object into the container. Function allows setting the global metadata since
     * we'll need to touch the "length" storage slot anyway, which also contains the global
     * metadata (it's an optimization).
     * @param _object A 32 byte value to insert into the container.
     * @param _globalMetadata New global metadata for the container.
     */
    function push(
        bytes32 _object,
        bytes27 _globalMetadata
    )
        external;

    /**
     * Retrieves an object from the container.
     * @param _index Index of the particular object to access.
     * @return 32 byte object value.
     */
    function get(
        uint256 _index
    )
        external
        view
        returns (
            bytes32
        );

    /**
     * Removes all objects after and including a given index.
     * @param _index Object index to delete from.
     */
    function deleteElementsAfterInclusive(
        uint256 _index
    )
        external;

    /**
     * Removes all objects after and including a given index. Also allows setting the global
     * metadata field.
     * @param _index Object index to delete from.
     * @param _globalMetadata New global metadata for the container.
     */
    function deleteElementsAfterInclusive(
        uint256 _index,
        bytes27 _globalMetadata
    )
        external;

    /**
     * Marks an index as overwritable, meaing the underlying buffer can start to write values over
     * any objects before and including the given index.
     */
    function setNextOverwritableIndex(
        uint256 _index
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";

interface iOVM_ExecutionManager {
    /**********
     * Enums *
     *********/

    enum RevertFlag {
        OUT_OF_GAS,
        INTENTIONAL_REVERT,
        EXCEEDS_NUISANCE_GAS,
        INVALID_STATE_ACCESS,
        UNSAFE_BYTECODE,
        CREATE_COLLISION,
        STATIC_VIOLATION,
        CREATOR_NOT_ALLOWED
    }

    enum GasMetadataKey {
        CURRENT_EPOCH_START_TIMESTAMP,
        CUMULATIVE_SEQUENCER_QUEUE_GAS,
        CUMULATIVE_L1TOL2_QUEUE_GAS,
        PREV_EPOCH_SEQUENCER_QUEUE_GAS,
        PREV_EPOCH_L1TOL2_QUEUE_GAS
    }

    /***********
     * Structs *
     ***********/

    struct GasMeterConfig {
        uint256 minTransactionGasLimit;
        uint256 maxTransactionGasLimit;
        uint256 maxGasPerQueuePerEpoch;
        uint256 secondsPerEpoch;
    }

    struct GlobalContext {
        uint256 ovmCHAINID;
    }

    struct TransactionContext {
        Lib_OVMCodec.QueueOrigin ovmL1QUEUEORIGIN;
        uint256 ovmTIMESTAMP;
        uint256 ovmNUMBER;
        uint256 ovmGASLIMIT;
        uint256 ovmTXGASLIMIT;
        address ovmL1TXORIGIN;
    }

    struct TransactionRecord {
        uint256 ovmGasRefund;
    }

    struct MessageContext {
        address ovmCALLER;
        address ovmADDRESS;
        bool isStatic;
    }

    struct MessageRecord {
        uint256 nuisanceGasLeft;
    }


    /************************************
     * Transaction Execution Entrypoint *
     ************************************/

    function run(
        Lib_OVMCodec.Transaction calldata _transaction,
        address _txStateManager
    ) external returns (bytes memory);


    /*******************
     * Context Opcodes *
     *******************/

    function ovmCALLER() external view returns (address _caller);
    function ovmADDRESS() external view returns (address _address);
    function ovmTIMESTAMP() external view returns (uint256 _timestamp);
    function ovmNUMBER() external view returns (uint256 _number);
    function ovmGASLIMIT() external view returns (uint256 _gasLimit);
    function ovmCHAINID() external view returns (uint256 _chainId);


    /**********************
     * L2 Context Opcodes *
     **********************/

    function ovmL1QUEUEORIGIN() external view returns (Lib_OVMCodec.QueueOrigin _queueOrigin);
    function ovmL1TXORIGIN() external view returns (address _l1TxOrigin);


    /*******************
     * Halting Opcodes *
     *******************/

    function ovmREVERT(bytes memory _data) external;


    /*****************************
     * Contract Creation Opcodes *
     *****************************/

    function ovmCREATE(bytes memory _bytecode) external returns (address _contract, bytes memory _revertdata);
    function ovmCREATE2(bytes memory _bytecode, bytes32 _salt) external returns (address _contract, bytes memory _revertdata);


    /*******************************
     * Account Abstraction Opcodes *
     ******************************/

    function ovmGETNONCE() external returns (uint256 _nonce);
    function ovmINCREMENTNONCE() external;
    function ovmCREATEEOA(bytes32 _messageHash, uint8 _v, bytes32 _r, bytes32 _s) external;


    /****************************
     * Contract Calling Opcodes *
     ****************************/

    function ovmCALL(uint256 _gasLimit, address _address, bytes memory _calldata) external returns (bool _success, bytes memory _returndata);
    function ovmSTATICCALL(uint256 _gasLimit, address _address, bytes memory _calldata) external returns (bool _success, bytes memory _returndata);
    function ovmDELEGATECALL(uint256 _gasLimit, address _address, bytes memory _calldata) external returns (bool _success, bytes memory _returndata);


    /****************************
     * Contract Storage Opcodes *
     ****************************/

    function ovmSLOAD(bytes32 _key) external returns (bytes32 _value);
    function ovmSSTORE(bytes32 _key, bytes32 _value) external;


    /*************************
     * Contract Code Opcodes *
     *************************/

    function ovmEXTCODECOPY(address _contract, uint256 _offset, uint256 _length) external returns (bytes memory _code);
    function ovmEXTCODESIZE(address _contract) external returns (uint256 _size);
    function ovmEXTCODEHASH(address _contract) external returns (bytes32 _hash);


    /***************************************
     * Public Functions: Execution Context *
     ***************************************/

    function getMaxTransactionGasLimit() external view returns (uint _maxTransactionGasLimit);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title iOVM_SafetyChecker
 */
interface iOVM_SafetyChecker {

    /********************
     * Public Functions *
     ********************/

    function isBytecodeSafe(bytes calldata _bytecode) external pure returns (bool);
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

/**
 * @title iOVM_DeployerWhitelist
 */
interface iOVM_DeployerWhitelist {

    /********************
     * Public Functions *
     ********************/

    function initialize(address _owner, bool _allowArbitraryDeployment) external;
    function owner() external returns (address _owner);
    function setWhitelistedDeployer(address _deployer, bool _isWhitelisted) external;
    function setOwner(address _newOwner) external;
    function setAllowArbitraryDeployment(bool _allowArbitraryDeployment) external;
    function enableArbitraryContractDeployment() external;
    function isDeployerAllowed(address _deployer) external returns (bool _allowed);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_RLPReader } from "../rlp/Lib_RLPReader.sol";
import { Lib_RLPWriter } from "../rlp/Lib_RLPWriter.sol";
import { Lib_BytesUtils } from "../utils/Lib_BytesUtils.sol";
import { Lib_Bytes32Utils } from "../utils/Lib_Bytes32Utils.sol";

/**
 * @title Lib_OVMCodec
 */
library Lib_OVMCodec {

    /*********
     * Enums *
     *********/

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


    /**********************
     * Internal Functions *
     **********************/

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

/* External Imports */
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Lib_AddressManager
 */
contract Lib_AddressManager is Ownable {

    /**********
     * Events *
     **********/

    event AddressSet(
        string _name,
        address _newAddress
    );


    /*************
     * Variables *
     *************/

    mapping (bytes32 => address) private addresses;


    /********************
     * Public Functions *
     ********************/

    /**
     * Changes the address associated with a particular name.
     * @param _name String name to associate an address with.
     * @param _address Address to associate with the name.
     */
    function setAddress(
        string memory _name,
        address _address
    )
        external
        onlyOwner
    {
        addresses[_getNameHash(_name)] = _address;

        emit AddressSet(
            _name,
            _address
        );
    }

    /**
     * Retrieves the address associated with a given name.
     * @param _name Name to retrieve an address for.
     * @return Address associated with the given name.
     */
    function getAddress(
        string memory _name
    )
        external
        view
        returns (
            address
        )
    {
        return addresses[_getNameHash(_name)];
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Computes the hash of a name.
     * @param _name Name to compute a hash for.
     * @return Hash of the given name.
     */
    function _getNameHash(
        string memory _name
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return keccak256(abi.encodePacked(_name));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_AddressManager } from "./Lib_AddressManager.sol";

/**
 * @title Lib_AddressResolver
 */
abstract contract Lib_AddressResolver {

    /*************
     * Variables *
     *************/

    Lib_AddressManager public libAddressManager;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Lib_AddressManager.
     */
    constructor(
        address _libAddressManager
    ) {
        libAddressManager = Lib_AddressManager(_libAddressManager);
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * Resolves the address associated with a given name.
     * @param _name Name to resolve an address for.
     * @return Address associated with the given name.
     */
    function resolve(
        string memory _name
    )
        public
        view
        returns (
            address
        )
    {
        return libAddressManager.getAddress(_name);
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
     * @return The RLP encoded string in bytes.
     */
    function writeBytes(
        bytes memory _in
    )
        internal
        pure
        returns (
            bytes memory
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
     * @return The RLP encoded list of items in bytes.
     */
    function writeList(
        bytes[] memory _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        bytes memory list = _flatten(_in);
        return abi.encodePacked(_writeLength(list.length, 192), list);
    }

    /**
     * RLP encodes a string.
     * @param _in The string to encode.
     * @return The RLP encoded string in bytes.
     */
    function writeString(
        string memory _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        return writeBytes(bytes(_in));
    }

    /**
     * RLP encodes an address.
     * @param _in The address to encode.
     * @return The RLP encoded address in bytes.
     */
    function writeAddress(
        address _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        return writeBytes(abi.encodePacked(_in));
    }

    /**
     * RLP encodes a bytes32 value.
     * @param _in The bytes32 to encode.
     * @return _out The RLP encoded bytes32 in bytes.
     */
    function writeBytes32(
        bytes32 _in
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
     * @return The RLP encoded uint256 in bytes.
     */
    function writeUint(
        uint256 _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        return writeBytes(_toBinary(_in));
    }

    /**
     * RLP encodes a bool.
     * @param _in The bool to encode.
     * @return The RLP encoded bool in bytes.
     */
    function writeBool(
        bool _in
    )
        internal
        pure
        returns (
            bytes memory
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
     * @return RLP encoded bytes.
     */
    function _writeLength(
        uint256 _len,
        uint256 _offset
    )
        private
        pure
        returns (
            bytes memory
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
     * @return RLP encoded bytes.
     */
    function _toBinary(
        uint256 _x
    )
        private
        pure
        returns (
            bytes memory
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
     * @return The flattened byte string.
     */
    function _flatten(
        bytes[] memory _list
    )
        private
        pure
        returns (
            bytes memory
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
        returns (
            bytes memory
        )
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
        returns (
            bytes memory
        )
    {
        if (_start >= _bytes.length) {
            return bytes('');
        }

        return slice(_bytes, _start, _bytes.length - _start);
    }

    function toBytes32PadLeft(
        bytes memory _bytes
    )
        internal
        pure
        returns (
            bytes32
        )
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
        returns (
            bytes32
        )
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
        returns (
            uint256
        )
    {
        return uint256(toBytes32(_bytes));
    }

    function toUint24(
        bytes memory _bytes,
        uint256 _start
    )
        internal
        pure
        returns (
            uint24
        )
    {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3 , "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function toUint8(
        bytes memory _bytes,
        uint256 _start
    )
        internal
        pure
        returns (
            uint8
        )
    {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toAddress(
        bytes memory _bytes,
        uint256 _start
    )
        internal
        pure
        returns (
            address
        )
    {
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
        returns (
            bytes memory
        )
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
        returns (
            bytes memory
        )
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
        returns (
            bool
        )
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
// @unsupported: ovm
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_RLPWriter } from "../rlp/Lib_RLPWriter.sol";
import { Lib_Bytes32Utils } from "./Lib_Bytes32Utils.sol";

/**
 * @title Lib_EthUtils
 */
library Lib_EthUtils {

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Gets the code for a given address.
     * @param _address Address to get code for.
     * @param _offset Offset to start reading from.
     * @param _length Number of bytes to read.
     * @return Code read from the contract.
     */
    function getCode(
        address _address,
        uint256 _offset,
        uint256 _length
    )
        internal
        view
        returns (
            bytes memory
        )
    {
        bytes memory code;
        assembly {
            code := mload(0x40)
            mstore(0x40, add(code, add(_length, 0x20)))
            mstore(code, _length)
            extcodecopy(_address, add(code, 0x20), _offset, _length)
        }

        return code;
    }

    /**
     * Gets the full code for a given address.
     * @param _address Address to get code for.
     * @return Full code of the contract.
     */
    function getCode(
        address _address
    )
        internal
        view
        returns (
            bytes memory
        )
    {
        return getCode(
            _address,
            0,
            getCodeSize(_address)
        );
    }

    /**
     * Gets the size of a contract's code in bytes.
     * @param _address Address to get code size for.
     * @return Size of the contract's code in bytes.
     */
    function getCodeSize(
        address _address
    )
        internal
        view
        returns (
            uint256
        )
    {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(_address)
        }

        return codeSize;
    }

    /**
     * Gets the hash of a contract's code.
     * @param _address Address to get a code hash for.
     * @return Hash of the contract's code.
     */
    function getCodeHash(
        address _address
    )
        internal
        view
        returns (
            bytes32
        )
    {
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(_address)
        }

        return codeHash;
    }

    /**
     * Creates a contract with some given initialization code.
     * @param _code Contract initialization code.
     * @return Address of the created contract.
     */
    function createContract(
        bytes memory _code
    )
        internal
        returns (
            address
        )
    {
        address created;
        assembly {
            created := create(
                0,
                add(_code, 0x20),
                mload(_code)
            )
        }

        return created;
    }

    /**
     * Computes the address that would be generated by CREATE.
     * @param _creator Address creating the contract.
     * @param _nonce Creator's nonce.
     * @return Address to be generated by CREATE.
     */
    function getAddressForCREATE(
        address _creator,
        uint256 _nonce
    )
        internal
        pure
        returns (
            address
        )
    {
        bytes[] memory encoded = new bytes[](2);
        encoded[0] = Lib_RLPWriter.writeAddress(_creator);
        encoded[1] = Lib_RLPWriter.writeUint(_nonce);

        bytes memory encodedList = Lib_RLPWriter.writeList(encoded);
        return Lib_Bytes32Utils.toAddress(keccak256(encodedList));
    }

    /**
     * Computes the address that would be generated by CREATE2.
     * @param _creator Address creating the contract.
     * @param _bytecode Bytecode of the contract to be created.
     * @param _salt 32 byte salt value mixed into the hash.
     * @return Address to be generated by CREATE2.
     */
    function getAddressForCREATE2(
        address _creator,
        bytes memory _bytecode,
        bytes32 _salt
    )
        internal
        pure
        returns (
            address
        )
    {
        bytes32 hashedData = keccak256(abi.encodePacked(
            byte(0xff),
            _creator,
            _salt,
            keccak256(_bytecode)
        ));

        return Lib_Bytes32Utils.toAddress(hashedData);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Lib_MerkleTree
 * @author River Keefer
 */
library Lib_MerkleTree {

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Calculates a merkle root for a list of 32-byte leaf hashes.  WARNING: If the number
     * of leaves passed in is not a power of two, it pads out the tree with zero hashes.
     * If you do not know the original length of elements for the tree you are verifying,
     * then this may allow empty leaves past _elements.length to pass a verification check down the line.
     * Note that the _elements argument is modified, therefore it must not be used again afterwards
     * @param _elements Array of hashes from which to generate a merkle root.
     * @return Merkle root of the leaves, with zero hashes for non-powers-of-two (see above).
     */
    function getMerkleRoot(
        bytes32[] memory _elements
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        require(
            _elements.length > 0,
            "Lib_MerkleTree: Must provide at least one leaf hash."
        );

        if (_elements.length == 1) {
            return _elements[0];
        }

        uint256[16] memory defaults = [
            0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563,
            0x633dc4d7da7256660a892f8f1604a44b5432649cc8ec5cb3ced4c4e6ac94dd1d,
            0x890740a8eb06ce9be422cb8da5cdafc2b58c0a5e24036c578de2a433c828ff7d,
            0x3b8ec09e026fdc305365dfc94e189a81b38c7597b3d941c279f042e8206e0bd8,
            0xecd50eee38e386bd62be9bedb990706951b65fe053bd9d8a521af753d139e2da,
            0xdefff6d330bb5403f63b14f33b578274160de3a50df4efecf0e0db73bcdd3da5,
            0x617bdd11f7c0a11f49db22f629387a12da7596f9d1704d7465177c63d88ec7d7,
            0x292c23a9aa1d8bea7e2435e555a4a60e379a5a35f3f452bae60121073fb6eead,
            0xe1cea92ed99acdcb045a6726b2f87107e8a61620a232cf4d7d5b5766b3952e10,
            0x7ad66c0a68c72cb89e4fb4303841966e4062a76ab97451e3b9fb526a5ceb7f82,
            0xe026cc5a4aed3c22a58cbd3d2ac754c9352c5436f638042dca99034e83636516,
            0x3d04cffd8b46a874edf5cfae63077de85f849a660426697b06a829c70dd1409c,
            0xad676aa337a485e4728a0b240d92b3ef7b3c372d06d189322bfd5f61f1e7203e,
            0xa2fca4a49658f9fab7aa63289c91b7c7b6c832a6d0e69334ff5b0a3483d09dab,
            0x4ebfd9cd7bca2505f7bef59cc1c12ecc708fff26ae4af19abe852afe9e20c862,
            0x2def10d13dd169f550f578bda343d9717a138562e0093b380a1120789d53cf10
        ];

        // Reserve memory space for our hashes.
        bytes memory buf = new bytes(64);

        // We'll need to keep track of left and right siblings.
        bytes32 leftSibling;
        bytes32 rightSibling;

        // Number of non-empty nodes at the current depth.
        uint256 rowSize = _elements.length;

        // Current depth, counting from 0 at the leaves
        uint256 depth = 0;

        // Common sub-expressions
        uint256 halfRowSize;         // rowSize / 2
        bool rowSizeIsOdd;           // rowSize % 2 == 1

        while (rowSize > 1) {
            halfRowSize = rowSize / 2;
            rowSizeIsOdd = rowSize % 2 == 1;

            for (uint256 i = 0; i < halfRowSize; i++) {
                leftSibling  = _elements[(2 * i)    ];
                rightSibling = _elements[(2 * i) + 1];
                assembly {
                    mstore(add(buf, 32), leftSibling )
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[i] = keccak256(buf);
            }

            if (rowSizeIsOdd) {
                leftSibling  = _elements[rowSize - 1];
                rightSibling = bytes32(defaults[depth]);
                assembly {
                    mstore(add(buf, 32), leftSibling)
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[halfRowSize] = keccak256(buf);
            }

            rowSize = halfRowSize + (rowSizeIsOdd ? 1 : 0);
            depth++;
        }

        return _elements[0];
    }

    /**
     * Verifies a merkle branch for the given leaf hash.  Assumes the original length
     * of leaves generated is a known, correct input, and does not return true for indices
     * extending past that index (even if _siblings would be otherwise valid.)
     * @param _root The Merkle root to verify against.
     * @param _leaf The leaf hash to verify inclusion of.
     * @param _index The index in the tree of this leaf.
     * @param _siblings Array of sibline nodes in the inclusion proof, starting from depth 0 (bottom of the tree).
     * @param _totalLeaves The total number of leaves originally passed into.
     * @return Whether or not the merkle branch and leaf passes verification.
     */
    function verify(
        bytes32 _root,
        bytes32 _leaf,
        uint256 _index,
        bytes32[] memory _siblings,
        uint256 _totalLeaves
    )
        internal
        pure
        returns (
            bool
        )
    {
        require(
            _totalLeaves > 0,
            "Lib_MerkleTree: Total leaves must be greater than zero."
        );

        require(
            _index < _totalLeaves,
            "Lib_MerkleTree: Index out of bounds."
        );

        require(
            _siblings.length == _ceilLog2(_totalLeaves),
            "Lib_MerkleTree: Total siblings does not correctly correspond to total leaves."
        );

        bytes32 computedRoot = _leaf;

        for (uint256 i = 0; i < _siblings.length; i++) {
            if ((_index & 1) == 1) {
                computedRoot = keccak256(
                    abi.encodePacked(
                        _siblings[i],
                        computedRoot
                    )
                );
            } else {
                computedRoot = keccak256(
                    abi.encodePacked(
                        computedRoot,
                        _siblings[i]
                    )
                );
            }

            _index >>= 1;
        }

        return _root == computedRoot;
    }


    /*********************
     * Private Functions *
     *********************/

    /**
     * Calculates the integer ceiling of the log base 2 of an input.
     * @param _in Unsigned input to calculate the log.
     * @return ceil(log_base_2(_in))
     */
    function _ceilLog2(
        uint256 _in
    )
        private
        pure
        returns (
            uint256
        )
    {
        require(
            _in > 0,
            "Lib_MerkleTree: Cannot compute ceil(log_2) of 0."
        );

        if (_in == 1) {
            return 0;
        }

        // Find the highest set bit (will be floor(log_2)).
        // Borrowed with <3 from https://github.com/ethereum/solidity-examples
        uint256 val = _in;
        uint256 highest = 0;
        for (uint256 i = 128; i >= 1; i >>= 1) {
            if (val & (uint(1) << i) - 1 << i != 0) {
                highest += i;
                val >>= i;
            }
        }

        // Increment by one if this is not a perfect logarithm.
        if ((uint(1) << highest) != _in) {
            highest += 1;
        }

        return highest;
    }
}

