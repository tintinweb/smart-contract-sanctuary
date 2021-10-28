// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Library Imports */
import {AddressAliasHelper} from '../../standards/AddressAliasHelper.sol';
import {Lib_OVMCodec} from '../../libraries/codec/Lib_OVMCodec.sol';
import {Lib_AddressResolver} from '../../libraries/resolver/Lib_AddressResolver.sol';

/* Interface Imports */
import {ICanonicalTransactionChain} from './ICanonicalTransactionChain.sol';
import {IChainStorageContainer} from './IChainStorageContainer.sol';

/**
 * @title CanonicalTransactionChain
 * @dev The Canonical Transaction Chain (CTC) contract is an append-only log of transactions
 * which must be applied to the rollup state. It defines the ordering of rollup transactions by
 * writing them to the 'CTC:batches' instance of the Chain Storage Container.
 * The CTC also allows any account to 'enqueue' an L2 transaction, which will require that the
 * Sequencer will eventually append it to the rollup state.
 *
 * Runtime target: EVM
 */
contract CanonicalTransactionChain is
  ICanonicalTransactionChain,
  Lib_AddressResolver
{
  /*************
   * Constants *
   *************/

  // L2 tx gas-related
  uint256 public constant MIN_ROLLUP_TX_GAS = 100000;
  uint256 public constant MAX_ROLLUP_TX_SIZE = 50000;

  // The approximate cost of calling the enqueue function
  uint256 public enqueueGasCost;
  // The ratio of the cost of L1 gas to the cost of L2 gas
  uint256 public l2GasDiscountDivisor;
  // The amount of L2 gas which can be forwarded to L2 without spam prevention via 'gas burn'.
  // Calculated as the product of l2GasDiscountDivisor * enqueueGasCost.
  // See comments in enqueue() for further detail.
  uint256 public enqueueL2GasPrepaid;

  // Encoding-related (all in bytes)
  uint256 internal constant BATCH_CONTEXT_SIZE = 16;
  uint256 internal constant BATCH_CONTEXT_LENGTH_POS = 12;
  uint256 internal constant BATCH_CONTEXT_START_POS = 15;
  uint256 internal constant TX_DATA_HEADER_SIZE = 3;
  uint256 internal constant BYTES_TILL_TX_DATA = 65;

  /*************
   * Variables *
   *************/

  uint256 public maxTransactionGasLimit;

  /***************
   * Queue State *
   ***************/

  uint40 private _nextQueueIndex; // index of the first queue element not yet included
  Lib_OVMCodec.QueueElement[] queueElements;

  /***************
   * Constructor *
   ***************/

  constructor(
    address _libAddressManager,
    uint256 _maxTransactionGasLimit,
    uint256 _l2GasDiscountDivisor,
    uint256 _enqueueGasCost
  ) Lib_AddressResolver(_libAddressManager) {
    maxTransactionGasLimit = _maxTransactionGasLimit;
    l2GasDiscountDivisor = _l2GasDiscountDivisor;
    enqueueGasCost = _enqueueGasCost;
    enqueueL2GasPrepaid = _l2GasDiscountDivisor * _enqueueGasCost;
  }

  /**********************
   * Function Modifiers *
   **********************/

  /**
   * Modifier to enforce that, if configured, only the Burn Admin may
   * successfully call a method.
   */
  modifier onlyBurnAdmin() {
    require(
      msg.sender == libAddressManager.owner(),
      'Only callable by the Burn Admin.'
    );
    _;
  }

  /*******************************
   * Authorized Setter Functions *
   *******************************/

  /**
   * Allows the Burn Admin to update the parameters which determine the amount of gas to burn.
   * The value of enqueueL2GasPrepaid is immediately updated as well.
   */
  function setGasParams(uint256 _l2GasDiscountDivisor, uint256 _enqueueGasCost)
    external
    onlyBurnAdmin
  {
    enqueueGasCost = _enqueueGasCost;
    l2GasDiscountDivisor = _l2GasDiscountDivisor;
    // See the comment in enqueue() for the rationale behind this formula.
    enqueueL2GasPrepaid = _l2GasDiscountDivisor * _enqueueGasCost;

    emit L2GasParamsUpdated(
      l2GasDiscountDivisor,
      enqueueGasCost,
      enqueueL2GasPrepaid
    );
  }

  /********************
   * Public Functions *
   ********************/

  /**
   * Accesses the batch storage container.
   * @return Reference to the batch storage container.
   */
  function batches() public view returns (IChainStorageContainer) {
    return IChainStorageContainer(resolve('ChainStorageContainer-CTC-batches'));
  }

  /**
   * Accesses the queue storage container.
   * @return Reference to the queue storage container.
   */
  function queue() public view returns (IChainStorageContainer) {
    return IChainStorageContainer(resolve('ChainStorageContainer-CTC-queue'));
  }

  /**
   * Retrieves the total number of elements submitted.
   * @return _totalElements Total submitted elements.
   */
  function getTotalElements() public view returns (uint256 _totalElements) {
    (uint40 totalElements, , , ) = _getBatchExtraData();
    return uint256(totalElements);
  }

  /**
   * Retrieves the total number of batches submitted.
   * @return _totalBatches Total submitted batches.
   */
  function getTotalBatches() public view returns (uint256 _totalBatches) {
    return batches().length();
  }

  /**
   * Returns the index of the next element to be enqueued.
   * @return Index for the next queue element.
   */
  function getNextQueueIndex() public view returns (uint40) {
    return _nextQueueIndex;
  }

  /**
   * Returns the timestamp of the last transaction.
   * @return Timestamp for the last transaction.
   */
  function getLastTimestamp() public view returns (uint40) {
    (, , uint40 lastTimestamp, ) = _getBatchExtraData();
    return lastTimestamp;
  }

  /**
   * Returns the blocknumber of the last transaction.
   * @return Blocknumber for the last transaction.
   */
  function getLastBlockNumber() public view returns (uint40) {
    (, , , uint40 lastBlockNumber) = _getBatchExtraData();
    return lastBlockNumber;
  }

  /**
   * Gets the queue element at a particular index.
   * @param _index Index of the queue element to access.
   * @return _element Queue element at the given index.
   */
  function getQueueElement(uint256 _index)
    public
    view
    returns (Lib_OVMCodec.QueueElement memory _element)
  {
    return queueElements[_index];
  }

  /**
   * Get the number of queue elements which have not yet been included.
   * @return Number of pending queue elements.
   */
  function getNumPendingQueueElements() public view returns (uint40) {
    return uint40(queueElements.length) - _nextQueueIndex;
  }

  /**
   * Retrieves the length of the queue, including
   * both pending and canonical transactions.
   * @return Length of the queue.
   */
  function getQueueLength() public view returns (uint40) {
    return uint40(queueElements.length);
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
  ) external {
    require(
      _data.length <= MAX_ROLLUP_TX_SIZE,
      'Transaction data size exceeds maximum for rollup transaction.'
    );

    require(
      _gasLimit <= maxTransactionGasLimit,
      'Transaction gas limit exceeds maximum for rollup transaction.'
    );

    require(
      _gasLimit >= MIN_ROLLUP_TX_GAS,
      'Transaction gas limit too low to enqueue.'
    );

    // Transactions submitted to the queue lack a method for paying gas fees to the Sequencer.
    // So we need to prevent spam attacks by ensuring that the cost of enqueueing a transaction
    // from L1 to L2 is not underpriced. For transaction with a high L2 gas limit, we do this by
    // burning some extra gas on L1. Of course there is also some intrinsic cost to enqueueing a
    // transaction, so we want to make sure not to over-charge (by burning too much L1 gas).
    // Therefore, we define 'enqueueL2GasPrepaid' as the L2 gas limit above which we must burn
    // additional gas on L1. This threshold is the product of two inputs:
    // 1. enqueueGasCost: the base cost of calling this function.
    // 2. l2GasDiscountDivisor: the ratio between the cost of gas on L1 and L2. This is a
    //    positive integer, meaning we assume L2 gas is always less costly.
    // The calculation below for gasToConsume can be seen as converting the difference (between
    // the specified L2 gas limit and the prepaid L2 gas limit) to an L1 gas amount.
    if (_gasLimit > enqueueL2GasPrepaid) {
      uint256 gasToConsume = (_gasLimit - enqueueL2GasPrepaid) /
        l2GasDiscountDivisor;
      uint256 startingGas = gasleft();

      // Although this check is not necessary (burn below will run out of gas if not true), it
      // gives the user an explicit reason as to why the enqueue attempt failed.
      require(
        startingGas > gasToConsume,
        'Insufficient gas for L2 rate limiting burn.'
      );

      uint256 i;
      while (startingGas - gasleft() < gasToConsume) {
        i++;
      }
    }

    // Apply an aliasing unless msg.sender == tx.origin. This prevents an attack in which a
    // contract on L1 has the same address as a contract on L2 but doesn't have the same code.
    // We can safely ignore this for EOAs because they're guaranteed to have the same "code"
    // (i.e. no code at all). This also makes it possible for users to interact with contracts
    // on L2 even when the Sequencer is down.
    address sender;
    if (msg.sender == tx.origin) {
      sender = msg.sender;
    } else {
      sender = AddressAliasHelper.applyL1ToL2Alias(msg.sender);
    }

    bytes32 transactionHash = keccak256(
      abi.encode(sender, _target, _gasLimit, _data)
    );

    queueElements.push(
      Lib_OVMCodec.QueueElement({
        transactionHash: transactionHash,
        timestamp: uint40(block.timestamp),
        blockNumber: uint40(block.number)
      })
    );
    uint256 queueIndex = queueElements.length - 1;
    emit TransactionEnqueued(
      sender,
      _target,
      _gasLimit,
      _data,
      queueIndex,
      block.timestamp
    );
  }

  /**
   * Allows the sequencer to append a batch of transactions.
   * @dev This function uses a custom encoding scheme for efficiency reasons.
   * .param _shouldStartAtElement Specific batch we expect to start appending to.
   * .param _totalElementsToAppend Total number of batch elements we expect to append.
   * .param _contexts Array of batch contexts.
   * .param _transactionDataFields Array of raw transaction data.
   */
  function appendSequencerBatch() external {
    uint40 shouldStartAtElement;
    uint24 totalElementsToAppend;
    uint24 numContexts;
    assembly {
      shouldStartAtElement := shr(216, calldataload(4))
      totalElementsToAppend := shr(232, calldataload(9))
      numContexts := shr(232, calldataload(12))
    }

    require(
      shouldStartAtElement == getTotalElements(),
      'Actual batch start index does not match expected start index.'
    );

    require(
      msg.sender == resolve('OVM_Sequencer'),
      'Function can only be called by the Sequencer.'
    );

    uint40 nextTransactionPtr = uint40(
      BATCH_CONTEXT_START_POS + BATCH_CONTEXT_SIZE * numContexts
    );

    require(
      msg.data.length >= nextTransactionPtr,
      'Not enough BatchContexts provided.'
    );

    // Counter for number of sequencer transactions appended so far.
    uint32 numSequencerTransactions = 0;

    // Cache the _nextQueueIndex storage variable to a temporary stack variable.
    // This is safe as long as nothing reads or writes to the storage variable
    // until it is updated by the temp variable.
    uint40 nextQueueIndex = _nextQueueIndex;

    BatchContext memory curContext;
    for (uint32 i = 0; i < numContexts; i++) {
      BatchContext memory nextContext = _getBatchContext(i);

      // Now we can update our current context.
      curContext = nextContext;

      // Process sequencer transactions first.
      numSequencerTransactions += uint32(curContext.numSequencedTransactions);

      // Now process any subsequent queue transactions.
      nextQueueIndex += uint40(curContext.numSubsequentQueueTransactions);
    }

    require(
      nextQueueIndex <= queueElements.length,
      'Attempted to append more elements than are available in the queue.'
    );

    // Generate the required metadata that we need to append this batch
    uint40 numQueuedTransactions = totalElementsToAppend -
      numSequencerTransactions;
    uint40 blockTimestamp;
    uint40 blockNumber;
    if (curContext.numSubsequentQueueTransactions == 0) {
      // The last element is a sequencer tx, therefore pull timestamp and block number from
      // the last context.
      blockTimestamp = uint40(curContext.timestamp);
      blockNumber = uint40(curContext.blockNumber);
    } else {
      // The last element is a queue tx, therefore pull timestamp and block number from the
      // queue element.
      // curContext.numSubsequentQueueTransactions > 0 which means that we've processed at
      // least one queue element. We increment nextQueueIndex after processing each queue
      // element, so the index of the last element we processed is nextQueueIndex - 1.
      Lib_OVMCodec.QueueElement memory lastElement = queueElements[
        nextQueueIndex - 1
      ];

      blockTimestamp = lastElement.timestamp;
      blockNumber = lastElement.blockNumber;
    }

    // Cache the previous blockhash to ensure all transaction data can be retrieved efficiently.
    _appendBatch(
      blockhash(block.number - 1),
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

    // Update the _nextQueueIndex storage variable.
    _nextQueueIndex = nextQueueIndex;
  }

  /**********************
   * Internal Functions *
   **********************/

  /**
   * Returns the BatchContext located at a particular index.
   * @param _index The index of the BatchContext
   * @return The BatchContext at the specified index.
   */
  function _getBatchContext(uint256 _index)
    internal
    pure
    returns (BatchContext memory)
  {
    uint256 contextPtr = 15 + _index * BATCH_CONTEXT_SIZE;
    uint256 numSequencedTransactions;
    uint256 numSubsequentQueueTransactions;
    uint256 ctxTimestamp;
    uint256 ctxBlockNumber;

    assembly {
      numSequencedTransactions := shr(232, calldataload(contextPtr))
      numSubsequentQueueTransactions := shr(
        232,
        calldataload(add(contextPtr, 3))
      )
      ctxTimestamp := shr(216, calldataload(add(contextPtr, 6)))
      ctxBlockNumber := shr(216, calldataload(add(contextPtr, 11)))
    }

    return
      BatchContext({
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

    // solhint-disable max-line-length
    assembly {
      extraData := shr(40, extraData)
      totalElements := and(
        extraData,
        0x000000000000000000000000000000000000000000000000000000FFFFFFFFFF
      )
      nextQueueIndex := shr(
        40,
        and(
          extraData,
          0x00000000000000000000000000000000000000000000FFFFFFFFFF0000000000
        )
      )
      lastTimestamp := shr(
        80,
        and(
          extraData,
          0x0000000000000000000000000000000000FFFFFFFFFF00000000000000000000
        )
      )
      lastBlockNumber := shr(
        120,
        and(
          extraData,
          0x000000000000000000000000FFFFFFFFFF000000000000000000000000000000
        )
      )
    }
    // solhint-enable max-line-length

    return (totalElements, nextQueueIndex, lastTimestamp, lastBlockNumber);
  }

  /**
   * Encodes the batch context for the extra data.
   * @param _totalElements Total number of elements submitted.
   * @param _nextQueueIdx Index of the next queue element.
   * @param _timestamp Timestamp for the last batch.
   * @param _blockNumber Block number of the last batch.
   * @return Encoded batch context.
   */
  function _makeBatchExtraData(
    uint40 _totalElements,
    uint40 _nextQueueIdx,
    uint40 _timestamp,
    uint40 _blockNumber
  ) internal pure returns (bytes27) {
    bytes27 extraData;
    assembly {
      extraData := _totalElements
      extraData := or(extraData, shl(40, _nextQueueIdx))
      extraData := or(extraData, shl(80, _timestamp))
      extraData := or(extraData, shl(120, _blockNumber))
      extraData := shl(40, extraData)
    }

    return extraData;
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
  ) internal {
    IChainStorageContainer batchesRef = batches();
    (uint40 totalElements, uint40 nextQueueIndex, , ) = _getBatchExtraData();

    Lib_OVMCodec.ChainBatchHeader memory header = Lib_OVMCodec
      .ChainBatchHeader({
        batchIndex: batchesRef.length(),
        batchRoot: _transactionRoot,
        batchSize: _batchSize,
        prevTotalElements: totalElements,
        extraData: hex''
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
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.7;

library AddressAliasHelper {
  uint160 constant offset = uint160(0x1111000000000000000000000000000000001111);

  /// @notice Utility function that converts the address in the L1 that submitted a tx to
  /// the inbox to the msg.sender viewed in the L2
  /// @param l1Address the address in the L1 that triggered the tx to L2
  /// @return l2Address L2 address as viewed in msg.sender
  function applyL1ToL2Alias(address l1Address)
    internal
    pure
    returns (address l2Address)
  {
    unchecked {
      l2Address = address(uint160(l1Address) + offset);
    }
  }

  /// @notice Utility function that converts the msg.sender viewed in the L2 to the
  /// address in the L1 that submitted a tx to the inbox
  /// @param l2Address L2 address as viewed in msg.sender
  /// @return l1Address the address in the L1 that triggered the tx to L2
  function undoL1ToL2Alias(address l2Address)
    internal
    pure
    returns (address l1Address)
  {
    unchecked {
      l1Address = address(uint160(l2Address) - offset);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Library Imports */
import {Lib_RLPReader} from '../rlp/Lib_RLPReader.sol';
import {Lib_RLPWriter} from '../rlp/Lib_RLPWriter.sol';
import {Lib_BytesUtils} from '../utils/Lib_BytesUtils.sol';
import {Lib_Bytes32Utils} from '../utils/Lib_Bytes32Utils.sol';

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
    uint256 queueIndex; // QUEUED TX ONLY
    uint256 timestamp; // SEQUENCER TX ONLY
    uint256 blockNumber; // SEQUENCER TX ONLY
    bytes txData; // SEQUENCER TX ONLY
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
  function encodeTransaction(Transaction memory _transaction)
    internal
    pure
    returns (bytes memory)
  {
    return
      abi.encodePacked(
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
  function hashTransaction(Transaction memory _transaction)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(encodeTransaction(_transaction));
  }

  /**
   * @notice Decodes an RLP-encoded account state into a useful struct.
   * @param _encoded RLP-encoded account state.
   * @return Account state struct.
   */
  function decodeEVMAccount(bytes memory _encoded)
    internal
    pure
    returns (EVMAccount memory)
  {
    Lib_RLPReader.RLPItem[] memory accountState = Lib_RLPReader.readList(
      _encoded
    );

    return
      EVMAccount({
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
  function hashBatchHeader(Lib_OVMCodec.ChainBatchHeader memory _batchHeader)
    internal
    pure
    returns (bytes32)
  {
    return
      keccak256(
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
pragma solidity ^0.8.9;

/* Library Imports */
import {Lib_AddressManager} from './Lib_AddressManager.sol';

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
  constructor(address _libAddressManager) {
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
  function resolve(string memory _name) public view returns (address) {
    return libAddressManager.getAddress(_name);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

/* Library Imports */
import {Lib_OVMCodec} from '../../libraries/codec/Lib_OVMCodec.sol';

/* Interface Imports */
import {IChainStorageContainer} from './IChainStorageContainer.sol';

/**
 * @title ICanonicalTransactionChain
 */
interface ICanonicalTransactionChain {
  /**********
   * Events *
   **********/

  event L2GasParamsUpdated(
    uint256 l2GasDiscountDivisor,
    uint256 enqueueGasCost,
    uint256 enqueueL2GasPrepaid
  );

  event TransactionEnqueued(
    address indexed _l1TxOrigin,
    address indexed _target,
    uint256 _gasLimit,
    bytes _data,
    uint256 indexed _queueIndex,
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

  /*******************************
   * Authorized Setter Functions *
   *******************************/

  /**
   * Allows the Burn Admin to update the parameters which determine the amount of gas to burn.
   * The value of enqueueL2GasPrepaid is immediately updated as well.
   */
  function setGasParams(uint256 _l2GasDiscountDivisor, uint256 _enqueueGasCost)
    external;

  /********************
   * Public Functions *
   ********************/

  /**
   * Accesses the batch storage container.
   * @return Reference to the batch storage container.
   */
  function batches() external view returns (IChainStorageContainer);

  /**
   * Accesses the queue storage container.
   * @return Reference to the queue storage container.
   */
  function queue() external view returns (IChainStorageContainer);

  /**
   * Retrieves the total number of elements submitted.
   * @return _totalElements Total submitted elements.
   */
  function getTotalElements() external view returns (uint256 _totalElements);

  /**
   * Retrieves the total number of batches submitted.
   * @return _totalBatches Total submitted batches.
   */
  function getTotalBatches() external view returns (uint256 _totalBatches);

  /**
   * Returns the index of the next element to be enqueued.
   * @return Index for the next queue element.
   */
  function getNextQueueIndex() external view returns (uint40);

  /**
   * Gets the queue element at a particular index.
   * @param _index Index of the queue element to access.
   * @return _element Queue element at the given index.
   */
  function getQueueElement(uint256 _index)
    external
    view
    returns (Lib_OVMCodec.QueueElement memory _element);

  /**
   * Returns the timestamp of the last transaction.
   * @return Timestamp for the last transaction.
   */
  function getLastTimestamp() external view returns (uint40);

  /**
   * Returns the blocknumber of the last transaction.
   * @return Blocknumber for the last transaction.
   */
  function getLastBlockNumber() external view returns (uint40);

  /**
   * Get the number of queue elements which have not yet been included.
   * @return Number of pending queue elements.
   */
  function getNumPendingQueueElements() external view returns (uint40);

  /**
   * Retrieves the length of the queue, including
   * both pending and canonical transactions.
   * @return Length of the queue.
   */
  function getQueueLength() external view returns (uint40);

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
  ) external;

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
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

/**
 * @title IChainStorageContainer
 */
interface IChainStorageContainer {
  /********************
   * Public Functions *
   ********************/

  /**
   * Sets the container's global metadata field. We're using `bytes27` here because we use five
   * bytes to maintain the length of the underlying data structure, meaning we have an extra
   * 27 bytes to store arbitrary data.
   * @param _globalMetadata New global metadata to set.
   */
  function setGlobalMetadata(bytes27 _globalMetadata) external;

  /**
   * Retrieves the container's global metadata field.
   * @return Container global metadata field.
   */
  function getGlobalMetadata() external view returns (bytes27);

  /**
   * Retrieves the number of objects stored in the container.
   * @return Number of objects in the container.
   */
  function length() external view returns (uint256);

  /**
   * Pushes an object into the container.
   * @param _object A 32 byte value to insert into the container.
   */
  function push(bytes32 _object) external;

  /**
   * Pushes an object into the container. Function allows setting the global metadata since
   * we'll need to touch the "length" storage slot anyway, which also contains the global
   * metadata (it's an optimization).
   * @param _object A 32 byte value to insert into the container.
   * @param _globalMetadata New global metadata for the container.
   */
  function push(bytes32 _object, bytes27 _globalMetadata) external;

  /**
   * Retrieves an object from the container.
   * @param _index Index of the particular object to access.
   * @return 32 byte object value.
   */
  function get(uint256 _index) external view returns (bytes32);

  /**
   * Removes all objects after and including a given index.
   * @param _index Object index to delete from.
   */
  function deleteElementsAfterInclusive(uint256 _index) external;

  /**
   * Removes all objects after and including a given index. Also allows setting the global
   * metadata field.
   * @param _index Object index to delete from.
   * @param _globalMetadata New global metadata for the container.
   */
  function deleteElementsAfterInclusive(uint256 _index, bytes27 _globalMetadata)
    external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Lib_RLPReader
 * @dev Adapted from "RLPReader" by Hamdi Allam ([email protected]).
 */
library Lib_RLPReader {
  /*************
   * Constants *
   *************/

  uint256 internal constant MAX_LIST_LENGTH = 32;

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
  function toRLPItem(bytes memory _in) internal pure returns (RLPItem memory) {
    uint256 ptr;
    assembly {
      ptr := add(_in, 32)
    }

    return RLPItem({length: _in.length, ptr: ptr});
  }

  /**
   * Reads an RLP list value into a list of RLP items.
   * @param _in RLP list value.
   * @return Decoded RLP list items.
   */
  function readList(RLPItem memory _in)
    internal
    pure
    returns (RLPItem[] memory)
  {
    (uint256 listOffset, , RLPItemType itemType) = _decodeLength(_in);

    require(itemType == RLPItemType.LIST_ITEM, 'Invalid RLP list value.');

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
        'Provided RLP list exceeds max list length.'
      );

      (uint256 itemOffset, uint256 itemLength, ) = _decodeLength(
        RLPItem({length: _in.length - offset, ptr: _in.ptr + offset})
      );

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
  function readList(bytes memory _in) internal pure returns (RLPItem[] memory) {
    return readList(toRLPItem(_in));
  }

  /**
   * Reads an RLP bytes value into bytes.
   * @param _in RLP bytes value.
   * @return Decoded bytes.
   */
  function readBytes(RLPItem memory _in) internal pure returns (bytes memory) {
    (
      uint256 itemOffset,
      uint256 itemLength,
      RLPItemType itemType
    ) = _decodeLength(_in);

    require(itemType == RLPItemType.DATA_ITEM, 'Invalid RLP bytes value.');

    return _copy(_in.ptr, itemOffset, itemLength);
  }

  /**
   * Reads an RLP bytes value into bytes.
   * @param _in RLP bytes value.
   * @return Decoded bytes.
   */
  function readBytes(bytes memory _in) internal pure returns (bytes memory) {
    return readBytes(toRLPItem(_in));
  }

  /**
   * Reads an RLP string value into a string.
   * @param _in RLP string value.
   * @return Decoded string.
   */
  function readString(RLPItem memory _in)
    internal
    pure
    returns (string memory)
  {
    return string(readBytes(_in));
  }

  /**
   * Reads an RLP string value into a string.
   * @param _in RLP string value.
   * @return Decoded string.
   */
  function readString(bytes memory _in) internal pure returns (string memory) {
    return readString(toRLPItem(_in));
  }

  /**
   * Reads an RLP bytes32 value into a bytes32.
   * @param _in RLP bytes32 value.
   * @return Decoded bytes32.
   */
  function readBytes32(RLPItem memory _in) internal pure returns (bytes32) {
    require(_in.length <= 33, 'Invalid RLP bytes32 value.');

    (
      uint256 itemOffset,
      uint256 itemLength,
      RLPItemType itemType
    ) = _decodeLength(_in);

    require(itemType == RLPItemType.DATA_ITEM, 'Invalid RLP bytes32 value.');

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
  function readBytes32(bytes memory _in) internal pure returns (bytes32) {
    return readBytes32(toRLPItem(_in));
  }

  /**
   * Reads an RLP uint256 value into a uint256.
   * @param _in RLP uint256 value.
   * @return Decoded uint256.
   */
  function readUint256(RLPItem memory _in) internal pure returns (uint256) {
    return uint256(readBytes32(_in));
  }

  /**
   * Reads an RLP uint256 value into a uint256.
   * @param _in RLP uint256 value.
   * @return Decoded uint256.
   */
  function readUint256(bytes memory _in) internal pure returns (uint256) {
    return readUint256(toRLPItem(_in));
  }

  /**
   * Reads an RLP bool value into a bool.
   * @param _in RLP bool value.
   * @return Decoded bool.
   */
  function readBool(RLPItem memory _in) internal pure returns (bool) {
    require(_in.length == 1, 'Invalid RLP boolean value.');

    uint256 ptr = _in.ptr;
    uint256 out;
    assembly {
      out := byte(0, mload(ptr))
    }

    require(
      out == 0 || out == 1,
      'Lib_RLPReader: Invalid RLP boolean value, must be 0 or 1'
    );

    return out != 0;
  }

  /**
   * Reads an RLP bool value into a bool.
   * @param _in RLP bool value.
   * @return Decoded bool.
   */
  function readBool(bytes memory _in) internal pure returns (bool) {
    return readBool(toRLPItem(_in));
  }

  /**
   * Reads an RLP address value into a address.
   * @param _in RLP address value.
   * @return Decoded address.
   */
  function readAddress(RLPItem memory _in) internal pure returns (address) {
    if (_in.length == 1) {
      return address(0);
    }

    require(_in.length == 21, 'Invalid RLP address value.');

    return address(uint160(readUint256(_in)));
  }

  /**
   * Reads an RLP address value into a address.
   * @param _in RLP address value.
   * @return Decoded address.
   */
  function readAddress(bytes memory _in) internal pure returns (address) {
    return readAddress(toRLPItem(_in));
  }

  /**
   * Reads the raw bytes of an RLP item.
   * @param _in RLP item to read.
   * @return Raw RLP bytes.
   */
  function readRawBytes(RLPItem memory _in)
    internal
    pure
    returns (bytes memory)
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
  function _decodeLength(RLPItem memory _in)
    private
    pure
    returns (
      uint256,
      uint256,
      RLPItemType
    )
  {
    require(_in.length > 0, 'RLP item cannot be null.');

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

      require(_in.length > strLen, 'Invalid RLP short string.');

      return (1, strLen, RLPItemType.DATA_ITEM);
    } else if (prefix <= 0xbf) {
      // Long string.
      uint256 lenOfStrLen = prefix - 0xb7;

      require(_in.length > lenOfStrLen, 'Invalid RLP long string length.');

      uint256 strLen;
      assembly {
        // Pick out the string length.
        strLen := div(mload(add(ptr, 1)), exp(256, sub(32, lenOfStrLen)))
      }

      require(_in.length > lenOfStrLen + strLen, 'Invalid RLP long string.');

      return (1 + lenOfStrLen, strLen, RLPItemType.DATA_ITEM);
    } else if (prefix <= 0xf7) {
      // Short list.
      uint256 listLen = prefix - 0xc0;

      require(_in.length > listLen, 'Invalid RLP short list.');

      return (1, listLen, RLPItemType.LIST_ITEM);
    } else {
      // Long list.
      uint256 lenOfListLen = prefix - 0xf7;

      require(_in.length > lenOfListLen, 'Invalid RLP long list length.');

      uint256 listLen;
      assembly {
        // Pick out the list length.
        listLen := div(mload(add(ptr, 1)), exp(256, sub(32, lenOfListLen)))
      }

      require(_in.length > lenOfListLen + listLen, 'Invalid RLP long list.');

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
  ) private pure returns (bytes memory) {
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
    uint256 mask;
    unchecked {
      mask = 256**(32 - (_length % 32)) - 1;
    }

    assembly {
      mstore(dest, or(and(mload(src), not(mask)), and(mload(dest), mask)))
    }
    return out;
  }

  /**
   * Copies an RLP item into bytes.
   * @param _in RLP item to copy.
   * @return Copied bytes.
   */
  function _copy(RLPItem memory _in) private pure returns (bytes memory) {
    return _copy(_in.ptr, 0, _in.length);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
  function writeBytes(bytes memory _in) internal pure returns (bytes memory) {
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
  function writeList(bytes[] memory _in) internal pure returns (bytes memory) {
    bytes memory list = _flatten(_in);
    return abi.encodePacked(_writeLength(list.length, 192), list);
  }

  /**
   * RLP encodes a string.
   * @param _in The string to encode.
   * @return The RLP encoded string in bytes.
   */
  function writeString(string memory _in) internal pure returns (bytes memory) {
    return writeBytes(bytes(_in));
  }

  /**
   * RLP encodes an address.
   * @param _in The address to encode.
   * @return The RLP encoded address in bytes.
   */
  function writeAddress(address _in) internal pure returns (bytes memory) {
    return writeBytes(abi.encodePacked(_in));
  }

  /**
   * RLP encodes a uint.
   * @param _in The uint256 to encode.
   * @return The RLP encoded uint256 in bytes.
   */
  function writeUint(uint256 _in) internal pure returns (bytes memory) {
    return writeBytes(_toBinary(_in));
  }

  /**
   * RLP encodes a bool.
   * @param _in The bool to encode.
   * @return The RLP encoded bool in bytes.
   */
  function writeBool(bool _in) internal pure returns (bytes memory) {
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
  function _writeLength(uint256 _len, uint256 _offset)
    private
    pure
    returns (bytes memory)
  {
    bytes memory encoded;

    if (_len < 56) {
      encoded = new bytes(1);
      encoded[0] = bytes1(uint8(_len) + uint8(_offset));
    } else {
      uint256 lenLen;
      uint256 i = 1;
      while (_len / i != 0) {
        lenLen++;
        i *= 256;
      }

      encoded = new bytes(lenLen + 1);
      encoded[0] = bytes1(uint8(lenLen) + uint8(_offset) + 55);
      for (i = 1; i <= lenLen; i++) {
        encoded[i] = bytes1(uint8((_len / (256**(lenLen - i))) % 256));
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
  function _toBinary(uint256 _x) private pure returns (bytes memory) {
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
  ) private pure {
    uint256 dest = _dest;
    uint256 src = _src;
    uint256 len = _len;

    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    uint256 mask;
    unchecked {
      mask = 256**(32 - len) - 1;
    }
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
  function _flatten(bytes[] memory _list) private pure returns (bytes memory) {
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
    assembly {
      flattenedPtr := add(flattened, 0x20)
    }

    for (i = 0; i < _list.length; i++) {
      bytes memory item = _list[i];

      uint256 listPtr;
      assembly {
        listPtr := add(item, 0x20)
      }

      _memcpy(flattenedPtr, listPtr, item.length);
      flattenedPtr += _list[i].length;
    }

    return flattened;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
  ) internal pure returns (bytes memory) {
    require(_length + 31 >= _length, 'slice_overflow');
    require(_start + _length >= _start, 'slice_overflow');
    require(_bytes.length >= _start + _length, 'slice_outOfBounds');

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
          let cc := add(
            add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))),
            _start
          )
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

  function slice(bytes memory _bytes, uint256 _start)
    internal
    pure
    returns (bytes memory)
  {
    if (_start >= _bytes.length) {
      return bytes('');
    }

    return slice(_bytes, _start, _bytes.length - _start);
  }

  function toBytes32(bytes memory _bytes) internal pure returns (bytes32) {
    if (_bytes.length < 32) {
      bytes32 ret;
      assembly {
        ret := mload(add(_bytes, 32))
      }
      return ret;
    }

    return abi.decode(_bytes, (bytes32)); // will truncate if input length > 32 bytes
  }

  function toUint256(bytes memory _bytes) internal pure returns (uint256) {
    return uint256(toBytes32(_bytes));
  }

  function toNibbles(bytes memory _bytes) internal pure returns (bytes memory) {
    bytes memory nibbles = new bytes(_bytes.length * 2);

    for (uint256 i = 0; i < _bytes.length; i++) {
      nibbles[i * 2] = _bytes[i] >> 4;
      nibbles[i * 2 + 1] = bytes1(uint8(_bytes[i]) % 16);
    }

    return nibbles;
  }

  function fromNibbles(bytes memory _bytes)
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

  function equal(bytes memory _bytes, bytes memory _other)
    internal
    pure
    returns (bool)
  {
    return keccak256(_bytes) == keccak256(_other);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
  function toBool(bytes32 _in) internal pure returns (bool) {
    return _in != 0;
  }

  /**
   * Converts a boolean to a bytes32 value.
   * @param _in Input boolean value.
   * @return Boolean as a bytes32.
   */
  function fromBool(bool _in) internal pure returns (bytes32) {
    return bytes32(uint256(_in ? 1 : 0));
  }

  /**
   * Converts a bytes32 value to an address. Takes the *last* 20 bytes.
   * @param _in Input bytes32 value.
   * @return Bytes32 as an address.
   */
  function toAddress(bytes32 _in) internal pure returns (address) {
    return address(uint160(uint256(_in)));
  }

  /**
   * Converts an address to a bytes32.
   * @param _in Input address value.
   * @return Address as a bytes32.
   */
  function fromAddress(address _in) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(_in)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* External Imports */
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title Lib_AddressManager
 */
contract Lib_AddressManager is Ownable {
  /**********
   * Events *
   **********/

  event AddressSet(
    string indexed _name,
    address _newAddress,
    address _oldAddress
  );

  /*************
   * Variables *
   *************/

  mapping(bytes32 => address) private addresses;

  /********************
   * Public Functions *
   ********************/

  /**
   * Changes the address associated with a particular name.
   * @param _name String name to associate an address with.
   * @param _address Address to associate with the name.
   */
  function setAddress(string memory _name, address _address)
    external
    onlyOwner
  {
    bytes32 nameHash = _getNameHash(_name);
    address oldAddress = addresses[nameHash];
    addresses[nameHash] = _address;

    emit AddressSet(_name, _address, oldAddress);
  }

  /**
   * Retrieves the address associated with a given name.
   * @param _name Name to retrieve an address for.
   * @return Address associated with the given name.
   */
  function getAddress(string memory _name) external view returns (address) {
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
  function _getNameHash(string memory _name) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_name));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}