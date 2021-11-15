// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

import "./interfaces/ISequencerInbox.sol";
import "./interfaces/IBridge.sol";
import "../arch/Marshaling.sol";
import "../libraries/Cloneable.sol";
import "../rollup/Rollup.sol";

import "./Messages.sol";

interface OldRollup {
    function sequencerInboxMaxDelayBlocks() external view returns (uint256);

    function sequencerInboxMaxDelaySeconds() external view returns (uint256);
}

contract SequencerInbox is ISequencerInbox, Cloneable {
    // Sequencer-Inbox state accumulator
    bytes32[] public override inboxAccs;

    // Number of messages included in the sequencer-inbox; tracked seperately from inboxAccs since multiple messages can be included in a single inboxAcc update (i.e., many messages in a batch, many batches in a single inboxAccs update, etc)
    uint256 public override messageCount;

    // count of messages read from the delayedInbox
    uint256 public totalDelayedMessagesRead;

    IBridge public delayedInbox;
    address private deprecatedSequencer;
    address public rollup;
    mapping(address => bool) public override isSequencer;

    // Window in which only the Sequencer can update the Inbox; this delay is what allows the Sequencer to give receipts with sub-blocktime latency.
    uint256 public override maxDelayBlocks;
    uint256 public override maxDelaySeconds;

    function initialize(
        IBridge _delayedInbox,
        address _sequencer,
        address _rollup
    ) external {
        require(address(delayedInbox) == address(0), "ALREADY_INIT");
        delayedInbox = _delayedInbox;
        isSequencer[_sequencer] = true;
        rollup = _rollup;
        // it is assumed that maxDelayBlocks and maxDelaySeconds are set by the rollup
    }

    function postUpgradeInit() external {
        // it is assumed the sequencer inbox contract is behind a Proxy controlled by a
        // proxy admin. this function can only be called by the proxy admin contract
        address proxyAdmin = ProxyUtil.getProxyAdmin();
        require(msg.sender == proxyAdmin, "NOT_FROM_ADMIN");

        // the sequencer inbox needs to query the old rollup interface since it will be upgraded first
        OldRollup _rollup = OldRollup(rollup);

        maxDelayBlocks = _rollup.sequencerInboxMaxDelayBlocks();
        maxDelaySeconds = _rollup.sequencerInboxMaxDelaySeconds();

        isSequencer[deprecatedSequencer] = true;
    }

    /// @notice DEPRECATED - use isSequencer instead
    function sequencer() external view override returns (address) {
        return deprecatedSequencer;
    }

    function setIsSequencer(address addr, bool newIsSequencer) external override {
        require(msg.sender == rollup, "ONLY_ROLLUP");
        isSequencer[addr] = newIsSequencer;
        emit IsSequencerUpdated(addr, newIsSequencer);
    }

    function setMaxDelay(uint256 newMaxDelayBlocks, uint256 newMaxDelaySeconds) external override {
        require(msg.sender == rollup, "ONLY_ROLLUP");
        maxDelayBlocks = newMaxDelayBlocks;
        maxDelaySeconds = newMaxDelaySeconds;
        emit MaxDelayUpdated(newMaxDelayBlocks, newMaxDelaySeconds);
    }

    /**
     * @notice Move messages from the delayed inbox into the Sequencer inbox. Callable by any address. Necessary iff Sequencer hasn't included them before delay period expired.
     */

    function forceInclusion(
        uint256 _totalDelayedMessagesRead,
        uint8 kind,
        uint256[2] calldata l1BlockAndTimestamp,
        uint256 inboxSeqNum,
        uint256 gasPriceL1,
        address sender,
        bytes32 messageDataHash,
        bytes32 delayedAcc
    ) external {
        require(_totalDelayedMessagesRead > totalDelayedMessagesRead, "DELAYED_BACKWARDS");
        {
            bytes32 messageHash = Messages.messageHash(
                kind,
                sender,
                l1BlockAndTimestamp[0],
                l1BlockAndTimestamp[1],
                inboxSeqNum,
                gasPriceL1,
                messageDataHash
            );
            // Can only force-include after the Sequencer-only window has expired.
            require(l1BlockAndTimestamp[0] + maxDelayBlocks < block.number, "MAX_DELAY_BLOCKS");
            require(l1BlockAndTimestamp[1] + maxDelaySeconds < block.timestamp, "MAX_DELAY_TIME");

            // Verify that message hash represents the last message sequence of delayed message to be included
            bytes32 prevDelayedAcc = 0;
            if (_totalDelayedMessagesRead > 1) {
                prevDelayedAcc = delayedInbox.inboxAccs(_totalDelayedMessagesRead - 2);
            }
            require(
                delayedInbox.inboxAccs(_totalDelayedMessagesRead - 1) ==
                    Messages.addMessageToInbox(prevDelayedAcc, messageHash),
                "DELAYED_ACCUMULATOR"
            );
        }

        uint256 startNum = messageCount;
        bytes32 beforeAcc = 0;
        if (inboxAccs.length > 0) {
            beforeAcc = inboxAccs[inboxAccs.length - 1];
        }

        (bytes32 acc, uint256 count) = includeDelayedMessages(
            beforeAcc,
            startNum,
            _totalDelayedMessagesRead,
            block.number,
            block.timestamp,
            delayedAcc
        );
        inboxAccs.push(acc);
        messageCount = count;
        emit DelayedInboxForced(
            startNum,
            beforeAcc,
            count,
            _totalDelayedMessagesRead,
            [acc, delayedAcc],
            inboxAccs.length - 1
        );
    }

    function addSequencerL2BatchFromOrigin(
        bytes calldata transactions,
        uint256[] calldata lengths,
        uint256[] calldata sectionsMetadata,
        bytes32 afterAcc
    ) external {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender == tx.origin, "origin only");
        uint256 startNum = messageCount;
        bytes32 beforeAcc = addSequencerL2BatchImpl(
            transactions,
            lengths,
            sectionsMetadata,
            afterAcc
        );
        emit SequencerBatchDeliveredFromOrigin(
            startNum,
            beforeAcc,
            messageCount,
            afterAcc,
            inboxAccs.length - 1
        );
    }

    /**
     * @notice Sequencer adds a batch to inbox.
     * @param transactions concatenated bytes of L2 messages
     * @param lengths length of each txn in transctions (for parsing)
     * @param sectionsMetadata Each consists of [numItems, l1BlockNumber, l1Timestamp, newTotalDelayedMessagesRead, newDelayedAcc]
     * @param afterAcc Expected inbox hash after batch is added
     * @dev sectionsMetadata lets the sequencer delineate new l1Block numbers and l1Timestamps within a given batch; this lets the sequencer minimize the number of batches created (and thus amortizing cost) while still giving timely receipts
     */
    function addSequencerL2Batch(
        bytes calldata transactions,
        uint256[] calldata lengths,
        uint256[] calldata sectionsMetadata,
        bytes32 afterAcc
    ) external {
        uint256 startNum = messageCount;
        bytes32 beforeAcc = addSequencerL2BatchImpl(
            transactions,
            lengths,
            sectionsMetadata,
            afterAcc
        );
        emit SequencerBatchDelivered(
            startNum,
            beforeAcc,
            messageCount,
            afterAcc,
            transactions,
            lengths,
            sectionsMetadata,
            inboxAccs.length - 1,
            msg.sender
        );
    }

    function addSequencerL2BatchImpl(
        bytes memory transactions,
        uint256[] calldata lengths,
        uint256[] calldata sectionsMetadata,
        bytes32 afterAcc
    ) private returns (bytes32 beforeAcc) {
        require(isSequencer[msg.sender], "ONLY_SEQUENCER");

        if (inboxAccs.length > 0) {
            beforeAcc = inboxAccs[inboxAccs.length - 1];
        }

        uint256 runningCount = messageCount;
        bytes32 runningAcc = beforeAcc;
        uint256 processedItems = 0;
        uint256 dataOffset;
        assembly {
            dataOffset := add(transactions, 32)
        }
        for (uint256 i = 0; i + 5 <= sectionsMetadata.length; i += 5) {
            // Each metadata section consists of:
            // [numItems, l1BlockNumber, l1Timestamp, newTotalDelayedMessagesRead, newDelayedAcc]
            {
                uint256 l1BlockNumber = sectionsMetadata[i + 1];
                require(l1BlockNumber + maxDelayBlocks >= block.number, "BLOCK_TOO_OLD");
                require(l1BlockNumber <= block.number, "BLOCK_TOO_NEW");
            }
            {
                uint256 l1Timestamp = sectionsMetadata[i + 2];
                require(l1Timestamp + maxDelaySeconds >= block.timestamp, "TIME_TOO_OLD");
                require(l1Timestamp <= block.timestamp, "TIME_TOO_NEW");
            }

            {
                bytes32 prefixHash = keccak256(
                    abi.encodePacked(msg.sender, sectionsMetadata[i + 1], sectionsMetadata[i + 2])
                );
                uint256 numItems = sectionsMetadata[i];
                (runningAcc, runningCount, dataOffset) = calcL2Batch(
                    dataOffset,
                    lengths,
                    processedItems,
                    numItems,
                    prefixHash,
                    runningCount,
                    runningAcc
                );
                processedItems += numItems;
            }

            uint256 newTotalDelayedMessagesRead = sectionsMetadata[i + 3];
            require(newTotalDelayedMessagesRead >= totalDelayedMessagesRead, "DELAYED_BACKWARDS");
            require(newTotalDelayedMessagesRead >= 1, "MUST_DELAYED_INIT");
            require(
                totalDelayedMessagesRead >= 1 || sectionsMetadata[i] == 0,
                "MUST_DELAYED_INIT_START"
            );
            // Sequencer decides how many messages (if any) to include from the delayed inbox
            if (newTotalDelayedMessagesRead > totalDelayedMessagesRead) {
                (runningAcc, runningCount) = includeDelayedMessages(
                    runningAcc,
                    runningCount,
                    newTotalDelayedMessagesRead,
                    sectionsMetadata[i + 1], // block number
                    sectionsMetadata[i + 2], // timestamp
                    bytes32(sectionsMetadata[i + 4]) // delayed accumulator
                );
            }
        }

        uint256 startOffset;
        assembly {
            startOffset := add(transactions, 32)
        }
        require(dataOffset >= startOffset, "OFFSET_OVERFLOW");
        require(dataOffset <= startOffset + transactions.length, "TRANSACTIONS_OVERRUN");

        require(runningCount > messageCount, "EMPTY_BATCH");
        inboxAccs.push(runningAcc);
        messageCount = runningCount;

        require(runningAcc == afterAcc, "AFTER_ACC");
    }

    function calcL2Batch(
        uint256 beforeOffset,
        uint256[] calldata lengths,
        uint256 lengthsOffset,
        uint256 itemCount,
        bytes32 prefixHash,
        uint256 beforeCount,
        bytes32 beforeAcc
    )
        private
        pure
        returns (
            bytes32 acc,
            uint256 count,
            uint256 offset
        )
    {
        offset = beforeOffset;
        count = beforeCount;
        acc = beforeAcc;
        itemCount += lengthsOffset;
        for (uint256 i = lengthsOffset; i < itemCount; i++) {
            uint256 length = lengths[i];
            bytes32 messageDataHash;
            assembly {
                messageDataHash := keccak256(offset, length)
            }
            acc = keccak256(abi.encodePacked(acc, count, prefixHash, messageDataHash));
            offset += length;
            count++;
        }
        return (acc, count, offset);
    }

    // Precondition: _totalDelayedMessagesRead > totalDelayedMessagesRead
    function includeDelayedMessages(
        bytes32 acc,
        uint256 count,
        uint256 _totalDelayedMessagesRead,
        uint256 l1BlockNumber,
        uint256 timestamp,
        bytes32 delayedAcc
    ) private returns (bytes32, uint256) {
        require(_totalDelayedMessagesRead <= delayedInbox.messageCount(), "DELAYED_TOO_FAR");
        require(delayedAcc == delayedInbox.inboxAccs(_totalDelayedMessagesRead - 1), "DELAYED_ACC");
        acc = keccak256(
            abi.encodePacked(
                "Delayed messages:",
                acc,
                count,
                totalDelayedMessagesRead,
                _totalDelayedMessagesRead,
                delayedAcc
            )
        );
        count += _totalDelayedMessagesRead - totalDelayedMessagesRead;
        bytes memory emptyBytes;
        acc = keccak256(
            abi.encodePacked(
                acc,
                count,
                keccak256(abi.encodePacked(address(0), l1BlockNumber, timestamp)),
                keccak256(emptyBytes)
            )
        );
        count++;
        totalDelayedMessagesRead = _totalDelayedMessagesRead;
        return (acc, count);
    }

    /**
     * @notice Prove message count as of provided inbox state hash
     * @param proof proof data
     * @param offset offset for parsing proof data
     * @param inboxAcc target inbox state hash
     */
    function proveSeqBatchMsgCount(
        bytes calldata proof,
        uint256 offset,
        bytes32 inboxAcc
    ) internal pure returns (uint256, uint256) {
        uint256 endMessageCount;

        bytes32 buildingAcc;
        uint256 seqNum;
        bytes32 messageHeaderHash;
        bytes32 messageDataHash;
        (offset, buildingAcc) = Marshaling.deserializeBytes32(proof, offset);
        (offset, seqNum) = Marshaling.deserializeInt(proof, offset);
        (offset, messageHeaderHash) = Marshaling.deserializeBytes32(proof, offset);
        (offset, messageDataHash) = Marshaling.deserializeBytes32(proof, offset);
        buildingAcc = keccak256(
            abi.encodePacked(buildingAcc, seqNum, messageHeaderHash, messageDataHash)
        );
        endMessageCount = seqNum + 1;
        require(buildingAcc == inboxAcc, "BATCH_ACC");

        return (offset, endMessageCount);
    }

    /**
     * @notice Show that given messageCount falls inside of some batch and prove/return inboxAcc state. This is used to ensure that the creation of new nodes are replay protected to the state of the inbox, thereby ensuring their validity/invalidy can't be modified upon reorging the inbox contents.
     * @dev (wrapper in leiu of proveBatchContainsSequenceNumber for sementics)
     * @return (message count at end of target batch, inbox hash as of target batch)
     */
    function proveInboxContainsMessage(bytes calldata proof, uint256 _messageCount)
        external
        view
        override
        returns (uint256, bytes32)
    {
        return proveInboxContainsMessageImp(proof, _messageCount);
    }

    // deprecated in favor of proveInboxContainsMessage
    function proveBatchContainsSequenceNumber(bytes calldata proof, uint256 _messageCount)
        external
        view
        returns (uint256, bytes32)
    {
        return proveInboxContainsMessageImp(proof, _messageCount);
    }

    function proveInboxContainsMessageImp(bytes calldata proof, uint256 _messageCount)
        internal
        view
        returns (uint256, bytes32)
    {
        if (_messageCount == 0) {
            return (0, 0);
        }

        (uint256 offset, uint256 targetInboxStateIndex) = Marshaling.deserializeInt(proof, 0);

        uint256 messageCountAsOfPreviousInboxState = 0;
        if (targetInboxStateIndex > 0) {
            (offset, messageCountAsOfPreviousInboxState) = proveSeqBatchMsgCount(
                proof,
                offset,
                inboxAccs[targetInboxStateIndex - 1]
            );
        }

        bytes32 targetInboxState = inboxAccs[targetInboxStateIndex];
        uint256 messageCountAsOfTargetInboxState;
        (offset, messageCountAsOfTargetInboxState) = proveSeqBatchMsgCount(
            proof,
            offset,
            targetInboxState
        );

        require(_messageCount > messageCountAsOfPreviousInboxState, "BATCH_START");
        require(_messageCount <= messageCountAsOfTargetInboxState, "BATCH_END");

        return (messageCountAsOfTargetInboxState, targetInboxState);
    }

    function getInboxAccsLength() external view override returns (uint256) {
        return inboxAccs.length;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

interface ISequencerInbox {
    event SequencerBatchDelivered(
        uint256 indexed firstMessageNum,
        bytes32 indexed beforeAcc,
        uint256 newMessageCount,
        bytes32 afterAcc,
        bytes transactions,
        uint256[] lengths,
        uint256[] sectionsMetadata,
        uint256 seqBatchIndex,
        address sequencer
    );

    event SequencerBatchDeliveredFromOrigin(
        uint256 indexed firstMessageNum,
        bytes32 indexed beforeAcc,
        uint256 newMessageCount,
        bytes32 afterAcc,
        uint256 seqBatchIndex
    );

    event DelayedInboxForced(
        uint256 indexed firstMessageNum,
        bytes32 indexed beforeAcc,
        uint256 newMessageCount,
        uint256 totalDelayedMessagesRead,
        bytes32[2] afterAccAndDelayed,
        uint256 seqBatchIndex
    );

    /// @notice DEPRECATED - look at IsSequencerUpdated for new updates
    // event SequencerAddressUpdated(address newAddress);

    event IsSequencerUpdated(address addr, bool isSequencer);
    event MaxDelayUpdated(uint256 newMaxDelayBlocks, uint256 newMaxDelaySeconds);

    /// @notice DEPRECATED - look at MaxDelayUpdated for new updates
    // event MaxDelayBlocksUpdated(uint256 newValue);
    /// @notice DEPRECATED - look at MaxDelayUpdated for new updates
    // event MaxDelaySecondsUpdated(uint256 newValue);

    function setMaxDelay(uint256 newMaxDelayBlocks, uint256 newMaxDelaySeconds) external;

    function setIsSequencer(address addr, bool isSequencer) external;

    function messageCount() external view returns (uint256);

    function maxDelayBlocks() external view returns (uint256);

    function maxDelaySeconds() external view returns (uint256);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function getInboxAccsLength() external view returns (uint256);

    function proveInboxContainsMessage(bytes calldata proof, uint256 inboxCount)
        external
        view
        returns (uint256, bytes32);

    /// @notice DEPRECATED - use isSequencer instead
    function sequencer() external view returns (address);

    function isSequencer(address seq) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    );

    event BridgeCallTriggered(
        address indexed outbox,
        address indexed destAddr,
        uint256 amount,
        bytes data
    );

    event InboxToggle(address indexed inbox, bool enabled);

    event OutboxToggle(address indexed outbox, bool enabled);

    function deliverMessageToInbox(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function executeCall(
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    // These are only callable by the admin
    function setInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // View functions

    function activeOutbox() external view returns (address);

    function allowedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function messageCount() external view returns (uint256);
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

pragma solidity ^0.6.11;

import "./Value.sol";
import "./Hashing.sol";

import "../libraries/BytesLib.sol";

library Marshaling {
    using BytesLib for bytes;
    using Value for Value.Data;

    function deserializeHashPreImage(bytes memory data, uint256 startOffset)
        internal
        pure
        returns (uint256 offset, Value.Data memory value)
    {
        require(data.length >= startOffset && data.length - startOffset >= 64, "too short");
        bytes32 hashData;
        uint256 size;
        (offset, hashData) = extractBytes32(data, startOffset);
        (offset, size) = deserializeInt(data, offset);
        return (offset, Value.newTuplePreImage(hashData, size));
    }

    function deserializeInt(bytes memory data, uint256 startOffset)
        internal
        pure
        returns (
            uint256, // offset
            uint256 // val
        )
    {
        require(data.length >= startOffset && data.length - startOffset >= 32, "too short");
        return (startOffset + 32, data.toUint(startOffset));
    }

    function deserializeBytes32(bytes memory data, uint256 startOffset)
        internal
        pure
        returns (
            uint256, // offset
            bytes32 // val
        )
    {
        require(data.length >= startOffset && data.length - startOffset >= 32, "too short");
        return (startOffset + 32, data.toBytes32(startOffset));
    }

    function deserializeCodePoint(bytes memory data, uint256 startOffset)
        internal
        pure
        returns (
            uint256, // offset
            Value.Data memory // val
        )
    {
        uint256 offset = startOffset;
        uint8 immediateType;
        uint8 opCode;
        Value.Data memory immediate;
        bytes32 nextHash;

        (offset, immediateType) = extractUint8(data, offset);
        (offset, opCode) = extractUint8(data, offset);
        if (immediateType == 1) {
            (offset, immediate) = deserialize(data, offset);
        }
        (offset, nextHash) = extractBytes32(data, offset);
        if (immediateType == 1) {
            return (offset, Value.newCodePoint(opCode, nextHash, immediate));
        }
        return (offset, Value.newCodePoint(opCode, nextHash));
    }

    function deserializeTuple(
        uint8 memberCount,
        bytes memory data,
        uint256 startOffset
    )
        internal
        pure
        returns (
            uint256, // offset
            Value.Data[] memory // val
        )
    {
        uint256 offset = startOffset;
        Value.Data[] memory members = new Value.Data[](memberCount);
        for (uint8 i = 0; i < memberCount; i++) {
            (offset, members[i]) = deserialize(data, offset);
        }
        return (offset, members);
    }

    function deserialize(bytes memory data, uint256 startOffset)
        internal
        pure
        returns (
            uint256, // offset
            Value.Data memory // val
        )
    {
        require(startOffset < data.length, "invalid offset");
        (uint256 offset, uint8 valType) = extractUint8(data, startOffset);
        if (valType == Value.intTypeCode()) {
            uint256 intVal;
            (offset, intVal) = deserializeInt(data, offset);
            return (offset, Value.newInt(intVal));
        } else if (valType == Value.codePointTypeCode()) {
            return deserializeCodePoint(data, offset);
        } else if (valType == Value.bufferTypeCode()) {
            bytes32 hashVal;
            (offset, hashVal) = deserializeBytes32(data, offset);
            return (offset, Value.newBuffer(hashVal));
        } else if (valType == Value.tuplePreImageTypeCode()) {
            return deserializeHashPreImage(data, offset);
        } else if (valType >= Value.tupleTypeCode() && valType < Value.valueTypeCode()) {
            uint8 tupLength = uint8(valType - Value.tupleTypeCode());
            Value.Data[] memory tupleVal;
            (offset, tupleVal) = deserializeTuple(tupLength, data, offset);
            return (offset, Value.newTuple(tupleVal));
        }
        require(false, "invalid typecode");
    }

    function extractUint8(bytes memory data, uint256 startOffset)
        private
        pure
        returns (
            uint256, // offset
            uint8 // val
        )
    {
        return (startOffset + 1, uint8(data[startOffset]));
    }

    function extractBytes32(bytes memory data, uint256 startOffset)
        private
        pure
        returns (
            uint256, // offset
            bytes32 // val
        )
    {
        return (startOffset + 32, data.toBytes32(startOffset));
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2020, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

import "./ICloneable.sol";

contract Cloneable is ICloneable {
    string private constant NOT_CLONE = "NOT_CLONE";

    bool private isMasterCopy;

    constructor() public {
        isMasterCopy = true;
    }

    function isMaster() external view override returns (bool) {
        return isMasterCopy;
    }

    function safeSelfDestruct(address payable dest) internal {
        require(!isMasterCopy, NOT_CLONE);
        selfdestruct(dest);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./RollupEventBridge.sol";
import "./RollupCore.sol";
import "./RollupLib.sol";
import "./INode.sol";
import "./INodeFactory.sol";

import "../challenge/IChallenge.sol";
import "../challenge/IChallengeFactory.sol";

import "../bridge/interfaces/IBridge.sol";
import "../bridge/interfaces/IOutbox.sol";
import "../bridge/Messages.sol";

import "../libraries/ProxyUtil.sol";
import "../libraries/Cloneable.sol";
import "./facets/IRollupFacets.sol";

abstract contract RollupBase is Cloneable, RollupCore, Pausable {
    // Rollup Config
    uint256 public confirmPeriodBlocks;
    uint256 public extraChallengeTimeBlocks;
    uint256 public avmGasSpeedLimitPerBlock;
    uint256 public baseStake;

    // Bridge is an IInbox and IOutbox
    IBridge public delayedBridge;
    ISequencerInbox public sequencerBridge;
    IOutbox public outbox;
    RollupEventBridge public rollupEventBridge;
    IChallengeFactory public challengeFactory;
    INodeFactory public nodeFactory;
    address public owner;
    address public stakeToken;
    uint256 public minimumAssertionPeriod;

    uint256 public STORAGE_GAP_1;
    uint256 public STORAGE_GAP_2;
    uint256 public challengeExecutionBisectionDegree;

    address[] internal facets;

    mapping(address => bool) isValidator;

    /// @notice DEPRECATED -- this method is deprecated but still mantained for backward compatibility
    /// @dev this actually returns the avmGasSpeedLimitPerBlock
    /// @return this actually returns the avmGasSpeedLimitPerBlock
    function arbGasSpeedLimitPerBlock() external view returns (uint256) {
        return avmGasSpeedLimitPerBlock;
    }
}

contract Rollup is Proxy, RollupBase {
    using Address for address;

    constructor(uint256 _confirmPeriodBlocks) public Cloneable() Pausable() {
        // constructor is used so logic contract can't be init'ed
        confirmPeriodBlocks = _confirmPeriodBlocks;
        require(isInit(), "CONSTRUCTOR_NOT_INIT");
    }

    function isInit() internal view returns (bool) {
        return confirmPeriodBlocks != 0;
    }

    // _rollupParams = [ confirmPeriodBlocks, extraChallengeTimeBlocks, avmGasSpeedLimitPerBlock, baseStake ]
    // connectedContracts = [delayedBridge, sequencerInbox, outbox, rollupEventBridge, challengeFactory, nodeFactory]
    function initialize(
        bytes32 _machineHash,
        uint256[4] calldata _rollupParams,
        address _stakeToken,
        address _owner,
        bytes calldata _extraConfig,
        address[6] calldata connectedContracts,
        address[2] calldata _facets,
        uint256[2] calldata sequencerInboxParams
    ) public {
        require(!isInit(), "ALREADY_INIT");

        // calls initialize method in user facet
        require(_facets[0].isContract(), "FACET_0_NOT_CONTRACT");
        require(_facets[1].isContract(), "FACET_1_NOT_CONTRACT");
        (bool success, ) = _facets[1].delegatecall(
            abi.encodeWithSelector(IRollupUser.initialize.selector, _stakeToken)
        );
        require(success, "FAIL_INIT_FACET");

        delayedBridge = IBridge(connectedContracts[0]);
        sequencerBridge = ISequencerInbox(connectedContracts[1]);
        outbox = IOutbox(connectedContracts[2]);
        delayedBridge.setOutbox(connectedContracts[2], true);
        rollupEventBridge = RollupEventBridge(connectedContracts[3]);
        delayedBridge.setInbox(connectedContracts[3], true);

        rollupEventBridge.rollupInitialized(
            _rollupParams[0],
            _rollupParams[2],
            _owner,
            _extraConfig
        );

        challengeFactory = IChallengeFactory(connectedContracts[4]);
        nodeFactory = INodeFactory(connectedContracts[5]);

        INode node = createInitialNode(_machineHash);
        initializeCore(node);

        confirmPeriodBlocks = _rollupParams[0];
        extraChallengeTimeBlocks = _rollupParams[1];
        avmGasSpeedLimitPerBlock = _rollupParams[2];
        baseStake = _rollupParams[3];
        owner = _owner;
        // A little over 15 minutes
        minimumAssertionPeriod = 75;
        challengeExecutionBisectionDegree = 400;

        sequencerBridge.setMaxDelay(sequencerInboxParams[0], sequencerInboxParams[1]);

        // facets[0] == admin, facets[1] == user
        facets = _facets;

        emit RollupCreated(_machineHash);
        require(isInit(), "INITIALIZE_NOT_INIT");
    }

    function postUpgradeInit() external {
        // it is assumed the rollup contract is behind a Proxy controlled by a proxy admin
        // this function can only be called by the proxy admin contract
        address proxyAdmin = ProxyUtil.getProxyAdmin();
        require(msg.sender == proxyAdmin, "NOT_FROM_ADMIN");

        // this upgrade moves the delay blocks and seconds tracking to the sequencer inbox
        // because of that we need to update the admin facet logic to allow the owner to set
        // these values in the sequencer inbox

        STORAGE_GAP_1 = 0;
        STORAGE_GAP_2 = 0;
    }

    function createInitialNode(bytes32 _machineHash) private returns (INode) {
        bytes32 state = RollupLib.stateHash(
            RollupLib.ExecutionState(
                0, // total gas used
                _machineHash,
                0, // inbox count
                0, // send count
                0, // log count
                0, // send acc
                0, // log acc
                block.number, // block proposed
                1 // Initialization message already in inbox
            )
        );
        return
            INode(
                nodeFactory.createNode(
                    state,
                    0, // challenge hash (not challengeable)
                    0, // confirm data
                    0, // prev node
                    block.number // deadline block (not challengeable)
                )
            );
    }

    /**
     * This contract uses a dispatch pattern from EIP-2535: Diamonds
     * together with Open Zeppelin's proxy
     */

    function getFacets() external view returns (address, address) {
        return (getAdminFacet(), getUserFacet());
    }

    function getAdminFacet() public view returns (address) {
        return facets[0];
    }

    function getUserFacet() public view returns (address) {
        return facets[1];
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual override returns (address) {
        require(msg.data.length >= 4, "NO_FUNC_SIG");
        address rollupOwner = owner;
        // if there is an owner and it is the sender, delegate to admin facet
        address target = rollupOwner != address(0) && rollupOwner == msg.sender
            ? getAdminFacet()
            : getUserFacet();
        require(target.isContract(), "TARGET_NOT_CONTRACT");
        return target;
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

pragma solidity ^0.6.11;

library Messages {
    function messageHash(
        uint8 kind,
        address sender,
        uint256 blockNumber,
        uint256 timestamp,
        uint256 inboxSeqNum,
        uint256 gasPriceL1,
        bytes32 messageDataHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    kind,
                    sender,
                    blockNumber,
                    timestamp,
                    inboxSeqNum,
                    gasPriceL1,
                    messageDataHash
                )
            );
    }

    function addMessageToInbox(bytes32 inbox, bytes32 message) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(inbox, message));
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

pragma solidity ^0.6.11;

library Value {
    uint8 internal constant INT_TYPECODE = 0;
    uint8 internal constant CODE_POINT_TYPECODE = 1;
    uint8 internal constant HASH_PRE_IMAGE_TYPECODE = 2;
    uint8 internal constant TUPLE_TYPECODE = 3;
    uint8 internal constant BUFFER_TYPECODE = TUPLE_TYPECODE + 9;
    // All values received from clients will have type codes less than the VALUE_TYPE_COUNT
    uint8 internal constant VALUE_TYPE_COUNT = TUPLE_TYPECODE + 10;

    // The following types do not show up in the marshalled format and is
    // only used for internal tracking purposes
    uint8 internal constant HASH_ONLY = 100;

    struct CodePoint {
        uint8 opcode;
        bytes32 nextCodePoint;
        Data[] immediate;
    }

    struct Data {
        uint256 intVal;
        CodePoint cpVal;
        Data[] tupleVal;
        bytes32 bufferHash;
        uint8 typeCode;
        uint256 size;
    }

    function tupleTypeCode() internal pure returns (uint8) {
        return TUPLE_TYPECODE;
    }

    function tuplePreImageTypeCode() internal pure returns (uint8) {
        return HASH_PRE_IMAGE_TYPECODE;
    }

    function intTypeCode() internal pure returns (uint8) {
        return INT_TYPECODE;
    }

    function bufferTypeCode() internal pure returns (uint8) {
        return BUFFER_TYPECODE;
    }

    function codePointTypeCode() internal pure returns (uint8) {
        return CODE_POINT_TYPECODE;
    }

    function valueTypeCode() internal pure returns (uint8) {
        return VALUE_TYPE_COUNT;
    }

    function hashOnlyTypeCode() internal pure returns (uint8) {
        return HASH_ONLY;
    }

    function isValidTupleSize(uint256 size) internal pure returns (bool) {
        return size <= 8;
    }

    function typeCodeVal(Data memory val) internal pure returns (Data memory) {
        if (val.typeCode == 2) {
            // Map HashPreImage to Tuple
            return newInt(TUPLE_TYPECODE);
        }
        return newInt(val.typeCode);
    }

    function valLength(Data memory val) internal pure returns (uint8) {
        if (val.typeCode == TUPLE_TYPECODE) {
            return uint8(val.tupleVal.length);
        } else {
            return 1;
        }
    }

    function isInt(Data memory val) internal pure returns (bool) {
        return val.typeCode == INT_TYPECODE;
    }

    function isInt64(Data memory val) internal pure returns (bool) {
        return val.typeCode == INT_TYPECODE && val.intVal < (1 << 64);
    }

    function isCodePoint(Data memory val) internal pure returns (bool) {
        return val.typeCode == CODE_POINT_TYPECODE;
    }

    function isTuple(Data memory val) internal pure returns (bool) {
        return val.typeCode == TUPLE_TYPECODE;
    }

    function isBuffer(Data memory val) internal pure returns (bool) {
        return val.typeCode == BUFFER_TYPECODE;
    }

    function newEmptyTuple() internal pure returns (Data memory) {
        return newTuple(new Data[](0));
    }

    function newBoolean(bool val) internal pure returns (Data memory) {
        if (val) {
            return newInt(1);
        } else {
            return newInt(0);
        }
    }

    function newInt(uint256 _val) internal pure returns (Data memory) {
        return
            Data(_val, CodePoint(0, 0, new Data[](0)), new Data[](0), 0, INT_TYPECODE, uint256(1));
    }

    function newHashedValue(bytes32 valueHash, uint256 valueSize)
        internal
        pure
        returns (Data memory)
    {
        return
            Data(
                uint256(valueHash),
                CodePoint(0, 0, new Data[](0)),
                new Data[](0),
                0,
                HASH_ONLY,
                valueSize
            );
    }

    function newTuple(Data[] memory _val) internal pure returns (Data memory) {
        require(isValidTupleSize(_val.length), "Tuple must have valid size");
        uint256 size = 1;

        for (uint256 i = 0; i < _val.length; i++) {
            size += _val[i].size;
        }

        return Data(0, CodePoint(0, 0, new Data[](0)), _val, 0, TUPLE_TYPECODE, size);
    }

    function newTuplePreImage(bytes32 preImageHash, uint256 size)
        internal
        pure
        returns (Data memory)
    {
        return
            Data(
                uint256(preImageHash),
                CodePoint(0, 0, new Data[](0)),
                new Data[](0),
                0,
                HASH_PRE_IMAGE_TYPECODE,
                size
            );
    }

    function newCodePoint(uint8 opCode, bytes32 nextHash) internal pure returns (Data memory) {
        return newCodePoint(CodePoint(opCode, nextHash, new Data[](0)));
    }

    function newCodePoint(
        uint8 opCode,
        bytes32 nextHash,
        Data memory immediate
    ) internal pure returns (Data memory) {
        Data[] memory imm = new Data[](1);
        imm[0] = immediate;
        return newCodePoint(CodePoint(opCode, nextHash, imm));
    }

    function newCodePoint(CodePoint memory _val) private pure returns (Data memory) {
        return Data(0, _val, new Data[](0), 0, CODE_POINT_TYPECODE, uint256(1));
    }

    function newBuffer(bytes32 bufHash) internal pure returns (Data memory) {
        return
            Data(
                uint256(0),
                CodePoint(0, 0, new Data[](0)),
                new Data[](0),
                bufHash,
                BUFFER_TYPECODE,
                uint256(1)
            );
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2020, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

import "./Value.sol";

library Hashing {
    using Hashing for Value.Data;
    using Value for Value.CodePoint;

    function keccak1(bytes32 b) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(b));
    }

    function keccak2(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(a, b));
    }

    function bytes32FromArray(
        bytes memory arr,
        uint256 offset,
        uint256 arrLength
    ) internal pure returns (uint256) {
        uint256 res = 0;
        for (uint256 i = 0; i < 32; i++) {
            res = res << 8;
            bytes1 b = arrLength > offset + i ? arr[offset + i] : bytes1(0);
            res = res | uint256(uint8(b));
        }
        return res;
    }

    /*
     * !! Note that dataLength must be a power of two !!
     *
     * If you have an arbitrary data length, you can round it up with roundUpToPow2.
     * The boolean return value tells if the data segment data[startOffset..startOffset+dataLength] only included zeroes.
     * If pack is true, the returned value is the merkle hash where trailing zeroes are ignored, that is,
     *   if h is the smallest height for which all data[startOffset+2**h..] are zero, merkle hash of data[startOffset..startOffset+2**h] is returned.
     * If all elements in the data segment are zero (and pack is true), keccak1(bytes32(0)) is returned.
     */
    function merkleRoot(
        bytes memory data,
        uint256 rawDataLength,
        uint256 startOffset,
        uint256 dataLength,
        bool pack
    ) internal pure returns (bytes32, bool) {
        if (dataLength <= 32) {
            if (startOffset >= rawDataLength) {
                return (keccak1(bytes32(0)), true);
            }
            bytes32 res = keccak1(bytes32(bytes32FromArray(data, startOffset, rawDataLength)));
            return (res, res == keccak1(bytes32(0)));
        }
        (bytes32 h2, bool zero2) =
            merkleRoot(data, rawDataLength, startOffset + dataLength / 2, dataLength / 2, false);
        if (zero2 && pack) {
            return merkleRoot(data, rawDataLength, startOffset, dataLength / 2, pack);
        }
        (bytes32 h1, bool zero1) =
            merkleRoot(data, rawDataLength, startOffset, dataLength / 2, false);
        return (keccak2(h1, h2), zero1 && zero2);
    }

    function roundUpToPow2(uint256 len) internal pure returns (uint256) {
        if (len <= 1) return 1;
        else return 2 * roundUpToPow2((len + 1) / 2);
    }

    function bytesToBufferHash(
        bytes memory buf,
        uint256 startOffset,
        uint256 length
    ) internal pure returns (bytes32) {
        (bytes32 mhash, ) =
            merkleRoot(buf, startOffset + length, startOffset, roundUpToPow2(length), true);
        return keccak2(bytes32(uint256(123)), mhash);
    }

    function hashInt(uint256 val) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(val));
    }

    function hashCodePoint(Value.CodePoint memory cp) internal pure returns (bytes32) {
        assert(cp.immediate.length < 2);
        if (cp.immediate.length == 0) {
            return
                keccak256(abi.encodePacked(Value.codePointTypeCode(), cp.opcode, cp.nextCodePoint));
        }
        return
            keccak256(
                abi.encodePacked(
                    Value.codePointTypeCode(),
                    cp.opcode,
                    cp.immediate[0].hash(),
                    cp.nextCodePoint
                )
            );
    }

    function hashTuplePreImage(bytes32 innerHash, uint256 valueSize)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(uint8(Value.tupleTypeCode()), innerHash, valueSize));
    }

    function hash(Value.Data memory val) internal pure returns (bytes32) {
        if (val.typeCode == Value.intTypeCode()) {
            return hashInt(val.intVal);
        } else if (val.typeCode == Value.codePointTypeCode()) {
            return hashCodePoint(val.cpVal);
        } else if (val.typeCode == Value.tuplePreImageTypeCode()) {
            return hashTuplePreImage(bytes32(val.intVal), val.size);
        } else if (val.typeCode == Value.tupleTypeCode()) {
            Value.Data memory preImage = getTuplePreImage(val.tupleVal);
            return preImage.hash();
        } else if (val.typeCode == Value.hashOnlyTypeCode()) {
            return bytes32(val.intVal);
        } else if (val.typeCode == Value.bufferTypeCode()) {
            return keccak256(abi.encodePacked(uint256(123), val.bufferHash));
        } else {
            require(false, "Invalid type code");
        }
    }

    function getTuplePreImage(Value.Data[] memory vals) internal pure returns (Value.Data memory) {
        require(vals.length <= 8, "Invalid tuple length");
        bytes32[] memory hashes = new bytes32[](vals.length);
        uint256 hashCount = hashes.length;
        uint256 size = 1;
        for (uint256 i = 0; i < hashCount; i++) {
            hashes[i] = vals[i].hash();
            size += vals[i].size;
        }
        bytes32 firstHash = keccak256(abi.encodePacked(uint8(hashes.length), hashes));
        return Value.newTuplePreImage(firstHash, size);
    }
}

// SPDX-License-Identifier: MIT

/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */

pragma solidity ^0.6.11;

/* solhint-disable no-inline-assembly */
library BytesLib {
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= (_start + 20), "Read out of bounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= (_start + 1), "Read out of bounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= (_start + 32), "Read out of bounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= (_start + 32), "Read out of bounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }
}
/* solhint-enable no-inline-assembly */

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

interface ICloneable {
    function isMaster() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

import "./Rollup.sol";
import "./facets/IRollupFacets.sol";

import "../bridge/interfaces/IBridge.sol";
import "../bridge/interfaces/IMessageProvider.sol";
import "./INode.sol";
import "../libraries/Cloneable.sol";

contract RollupEventBridge is IMessageProvider, Cloneable {
    uint8 internal constant INITIALIZATION_MSG_TYPE = 11;
    uint8 internal constant ROLLUP_PROTOCOL_EVENT_TYPE = 8;

    uint8 internal constant CREATE_NODE_EVENT = 0;
    uint8 internal constant CONFIRM_NODE_EVENT = 1;
    uint8 internal constant REJECT_NODE_EVENT = 2;
    uint8 internal constant STAKE_CREATED_EVENT = 3;

    IBridge bridge;
    address rollup;

    modifier onlyRollup() {
        require(msg.sender == rollup, "ONLY_ROLLUP");
        _;
    }

    function initialize(address _bridge, address _rollup) external {
        require(rollup == address(0), "ALREADY_INIT");
        bridge = IBridge(_bridge);
        rollup = _rollup;
    }

    function rollupInitialized(
        uint256 confirmPeriodBlocks,
        uint256 avmGasSpeedLimitPerBlock,
        address owner,
        bytes calldata extraConfig
    ) external onlyRollup {
        bytes memory initMsg = abi.encodePacked(
            keccak256("ChallengePeriodEthBlocks"),
            confirmPeriodBlocks,
            keccak256("SpeedLimitPerSecond"),
            avmGasSpeedLimitPerBlock / 100, // convert avm gas to arbgas
            keccak256("ChainOwner"),
            uint256(uint160(bytes20(owner))),
            extraConfig
        );
        uint256 num = bridge.deliverMessageToInbox(
            INITIALIZATION_MSG_TYPE,
            address(0),
            keccak256(initMsg)
        );
        emit InboxMessageDelivered(num, initMsg);
    }

    function nodeCreated(
        uint256 nodeNum,
        uint256 prev,
        uint256 deadline,
        address asserter
    ) external onlyRollup {
        deliverToBridge(
            abi.encodePacked(
                CREATE_NODE_EVENT,
                nodeNum,
                prev,
                block.number,
                deadline,
                uint256(uint160(bytes20(asserter)))
            )
        );
    }

    function nodeConfirmed(uint256 nodeNum) external onlyRollup {
        deliverToBridge(abi.encodePacked(CONFIRM_NODE_EVENT, nodeNum));
    }

    function nodeRejected(uint256 nodeNum) external onlyRollup {
        deliverToBridge(abi.encodePacked(REJECT_NODE_EVENT, nodeNum));
    }

    function stakeCreated(address staker, uint256 nodeNum) external onlyRollup {
        deliverToBridge(
            abi.encodePacked(
                STAKE_CREATED_EVENT,
                uint256(uint160(bytes20(staker))),
                nodeNum,
                block.number
            )
        );
    }

    function deliverToBridge(bytes memory message) private {
        emit InboxMessageDelivered(
            bridge.deliverMessageToInbox(
                ROLLUP_PROTOCOL_EVENT_TYPE,
                msg.sender,
                keccak256(message)
            ),
            message
        );
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

import "./INode.sol";
import "./IRollupCore.sol";
import "./RollupLib.sol";
import "./INodeFactory.sol";
import "./RollupEventBridge.sol";
import "../bridge/interfaces/ISequencerInbox.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

contract RollupCore is IRollupCore {
    using SafeMath for uint256;

    // Stakers become Zombies after losing a challenge
    struct Zombie {
        address stakerAddress;
        uint256 latestStakedNode;
    }

    struct Staker {
        uint256 index;
        uint256 latestStakedNode;
        uint256 amountStaked;
        // currentChallenge is 0 if staker is not in a challenge
        address currentChallenge;
        bool isStaked;
    }

    uint256 private _latestConfirmed;
    uint256 private _firstUnresolvedNode;
    uint256 private _latestNodeCreated;
    uint256 private _lastStakeBlock;
    mapping(uint256 => INode) private _nodes;
    mapping(uint256 => bytes32) private _nodeHashes;

    address payable[] private _stakerList;
    mapping(address => Staker) public override _stakerMap;

    Zombie[] private _zombies;

    mapping(address => uint256) private _withdrawableFunds;

    /**
     * @notice Get the address of the Node contract for the given node
     * @param nodeNum Index of the node
     * @return Address of the Node contract
     */
    function getNode(uint256 nodeNum) public view override returns (INode) {
        return _nodes[nodeNum];
    }

    /**
     * @notice Get the address of the staker at the given index
     * @param stakerNum Index of the staker
     * @return Address of the staker
     */
    function getStakerAddress(uint256 stakerNum) external view override returns (address) {
        return _stakerList[stakerNum];
    }

    /**
     * @notice Check whether the given staker is staked
     * @param staker Staker address to check
     * @return True or False for whether the staker was staked
     */
    function isStaked(address staker) public view override returns (bool) {
        return _stakerMap[staker].isStaked;
    }

    /**
     * @notice Get the latest staked node of the given staker
     * @param staker Staker address to lookup
     * @return Latest node staked of the staker
     */
    function latestStakedNode(address staker) public view override returns (uint256) {
        return _stakerMap[staker].latestStakedNode;
    }

    /**
     * @notice Get the current challenge of the given staker
     * @param staker Staker address to lookup
     * @return Current challenge of the staker
     */
    function currentChallenge(address staker) public view override returns (address) {
        return _stakerMap[staker].currentChallenge;
    }

    /**
     * @notice Get the amount staked of the given staker
     * @param staker Staker address to lookup
     * @return Amount staked of the staker
     */
    function amountStaked(address staker) public view override returns (uint256) {
        return _stakerMap[staker].amountStaked;
    }

    /**
     * @notice Get the original staker address of the zombie at the given index
     * @param zombieNum Index of the zombie to lookup
     * @return Original staker address of the zombie
     */
    function zombieAddress(uint256 zombieNum) public view override returns (address) {
        return _zombies[zombieNum].stakerAddress;
    }

    /**
     * @notice Get Latest node that the given zombie at the given index is staked on
     * @param zombieNum Index of the zombie to lookup
     * @return Latest node that the given zombie is staked on
     */
    function zombieLatestStakedNode(uint256 zombieNum) public view override returns (uint256) {
        return _zombies[zombieNum].latestStakedNode;
    }

    /// @return Current number of un-removed zombies
    function zombieCount() public view override returns (uint256) {
        return _zombies.length;
    }

    function isZombie(address staker) public view override returns (bool) {
        for (uint256 i = 0; i < _zombies.length; i++) {
            if (staker == _zombies[i].stakerAddress) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Get the amount of funds withdrawable by the given address
     * @param owner Address to check the funds of
     * @return Amount of funds withdrawable by owner
     */
    function withdrawableFunds(address owner) external view override returns (uint256) {
        return _withdrawableFunds[owner];
    }

    /**
     * @return Index of the first unresolved node
     * @dev If all nodes have been resolved, this will be latestNodeCreated + 1
     */
    function firstUnresolvedNode() public view override returns (uint256) {
        return _firstUnresolvedNode;
    }

    /// @return Index of the latest confirmed node
    function latestConfirmed() public view override returns (uint256) {
        return _latestConfirmed;
    }

    /// @return Index of the latest rollup node created
    function latestNodeCreated() public view override returns (uint256) {
        return _latestNodeCreated;
    }

    /// @return Ethereum block that the most recent stake was created
    function lastStakeBlock() external view override returns (uint256) {
        return _lastStakeBlock;
    }

    /// @return Number of active stakers currently staked
    function stakerCount() public view override returns (uint256) {
        return _stakerList.length;
    }

    /**
     * @notice Initialize the core with an initial node
     * @param initialNode Initial node to start the chain with
     */
    function initializeCore(INode initialNode) internal {
        _nodes[0] = initialNode;
        _firstUnresolvedNode = 1;
    }

    /**
     * @notice React to a new node being created by storing it an incrementing the latest node counter
     * @param node Node that was newly created
     * @param nodeHash The hash of said node
     */
    function nodeCreated(INode node, bytes32 nodeHash) internal {
        _latestNodeCreated++;
        _nodes[_latestNodeCreated] = node;
        _nodeHashes[_latestNodeCreated] = nodeHash;
    }

    /// @return Node hash as of this node number
    function getNodeHash(uint256 index) public view override returns (bytes32) {
        return _nodeHashes[index];
    }

    /// @notice Reject the next unresolved node
    function _rejectNextNode() internal {
        destroyNode(_firstUnresolvedNode);
        _firstUnresolvedNode++;
    }

    /// @notice Confirm the next unresolved node
    function confirmNextNode(
        bytes32 beforeSendAcc,
        bytes calldata sendsData,
        uint256[] calldata sendLengths,
        uint256 afterSendCount,
        bytes32 afterLogAcc,
        uint256 afterLogCount,
        IOutbox outbox,
        RollupEventBridge rollupEventBridge
    ) internal {
        confirmNode(
            _firstUnresolvedNode,
            beforeSendAcc,
            sendsData,
            sendLengths,
            afterSendCount,
            afterLogAcc,
            afterLogCount,
            outbox,
            rollupEventBridge
        );
    }

    function confirmNode(
        uint256 nodeNum,
        bytes32 beforeSendAcc,
        bytes calldata sendsData,
        uint256[] calldata sendLengths,
        uint256 afterSendCount,
        bytes32 afterLogAcc,
        uint256 afterLogCount,
        IOutbox outbox,
        RollupEventBridge rollupEventBridge
    ) internal {
        bytes32 afterSendAcc = RollupLib.feedAccumulator(sendsData, sendLengths, beforeSendAcc);

        INode node = getNode(nodeNum);
        // Authenticate data against node's confirm data pre-image
        require(
            node.confirmData() ==
                RollupLib.confirmHash(
                    beforeSendAcc,
                    afterSendAcc,
                    afterLogAcc,
                    afterSendCount,
                    afterLogCount
                ),
            "CONFIRM_DATA"
        );

        // trusted external call to outbox
        outbox.processOutgoingMessages(sendsData, sendLengths);

        destroyNode(_latestConfirmed);
        _latestConfirmed = nodeNum;
        _firstUnresolvedNode = nodeNum + 1;

        rollupEventBridge.nodeConfirmed(nodeNum);
        emit NodeConfirmed(nodeNum, afterSendAcc, afterSendCount, afterLogAcc, afterLogCount);
    }

    /**
     * @notice Create a new stake at latest confirmed node
     * @param stakerAddress Address of the new staker
     * @param depositAmount Stake amount of the new staker
     */
    function createNewStake(address payable stakerAddress, uint256 depositAmount) internal {
        uint256 stakerIndex = _stakerList.length;
        _stakerList.push(stakerAddress);
        _stakerMap[stakerAddress] = Staker(
            stakerIndex,
            _latestConfirmed,
            depositAmount,
            address(0), // new staker is not in challenge
            true
        );
        _lastStakeBlock = block.number;
        emit UserStakeUpdated(stakerAddress, 0, depositAmount);
    }

    /**
     * @notice Check to see whether the two stakers are in the same challenge
     * @param stakerAddress1 Address of the first staker
     * @param stakerAddress2 Address of the second staker
     * @return Address of the challenge that the two stakers are in
     */
    function inChallenge(address stakerAddress1, address stakerAddress2)
        internal
        view
        returns (address)
    {
        Staker storage staker1 = _stakerMap[stakerAddress1];
        Staker storage staker2 = _stakerMap[stakerAddress2];
        address challenge = staker1.currentChallenge;
        require(challenge != address(0), "NO_CHAL");
        require(challenge == staker2.currentChallenge, "DIFF_IN_CHAL");
        return challenge;
    }

    /**
     * @notice Make the given staker as not being in a challenge
     * @param stakerAddress Address of the staker to remove from a challenge
     */
    function clearChallenge(address stakerAddress) internal {
        Staker storage staker = _stakerMap[stakerAddress];
        staker.currentChallenge = address(0);
    }

    /**
     * @notice Mark both the given stakers as engaged in the challenge
     * @param staker1 Address of the first staker
     * @param staker2 Address of the second staker
     * @param challenge Address of the challenge both stakers are now in
     */
    function challengeStarted(
        address staker1,
        address staker2,
        address challenge
    ) internal {
        _stakerMap[staker1].currentChallenge = challenge;
        _stakerMap[staker2].currentChallenge = challenge;
    }

    /**
     * @notice Add to the stake of the given staker by the given amount
     * @param stakerAddress Address of the staker to increase the stake of
     * @param amountAdded Amount of stake to add to the staker
     */
    function increaseStakeBy(address stakerAddress, uint256 amountAdded) internal {
        Staker storage staker = _stakerMap[stakerAddress];
        uint256 initialStaked = staker.amountStaked;
        uint256 finalStaked = initialStaked.add(amountAdded);
        staker.amountStaked = finalStaked;
        emit UserStakeUpdated(stakerAddress, initialStaked, finalStaked);
    }

    /**
     * @notice Reduce the stake of the given staker to the given target
     * @param stakerAddress Address of the staker to reduce the stake of
     * @param target Amount of stake to leave with the staker
     * @return Amount of value released from the stake
     */
    function reduceStakeTo(address stakerAddress, uint256 target) internal returns (uint256) {
        Staker storage staker = _stakerMap[stakerAddress];
        uint256 current = staker.amountStaked;
        require(target <= current, "TOO_LITTLE_STAKE");
        uint256 amountWithdrawn = current.sub(target);
        staker.amountStaked = target;
        increaseWithdrawableFunds(stakerAddress, amountWithdrawn);
        emit UserStakeUpdated(stakerAddress, current, target);
        return amountWithdrawn;
    }

    /**
     * @notice Remove the given staker and turn them into a zombie
     * @param stakerAddress Address of the staker to remove
     */
    function turnIntoZombie(address stakerAddress) internal {
        Staker storage staker = _stakerMap[stakerAddress];
        _zombies.push(Zombie(stakerAddress, staker.latestStakedNode));
        deleteStaker(stakerAddress);
    }

    /**
     * @notice Update the latest staked node of the zombie at the given index
     * @param zombieNum Index of the zombie to move
     * @param latest New latest node the zombie is staked on
     */
    function zombieUpdateLatestStakedNode(uint256 zombieNum, uint256 latest) internal {
        _zombies[zombieNum].latestStakedNode = latest;
    }

    /**
     * @notice Remove the zombie at the given index
     * @param zombieNum Index of the zombie to remove
     */
    function removeZombie(uint256 zombieNum) internal {
        _zombies[zombieNum] = _zombies[_zombies.length - 1];
        _zombies.pop();
    }

    /**
     * @notice Remove the given staker and return their stake
     * @param stakerAddress Address of the staker withdrawing their stake
     */
    function withdrawStaker(address stakerAddress) internal {
        Staker storage staker = _stakerMap[stakerAddress];
        uint256 initialStaked = staker.amountStaked;
        increaseWithdrawableFunds(stakerAddress, initialStaked);
        deleteStaker(stakerAddress);
        emit UserStakeUpdated(stakerAddress, initialStaked, 0);
    }

    /**
     * @notice Advance the given staker to the given node
     * @param stakerAddress Address of the staker adding their stake
     * @param nodeNum Index of the node to stake on
     */
    function stakeOnNode(
        address stakerAddress,
        uint256 nodeNum,
        uint256 confirmPeriodBlocks
    ) internal {
        Staker storage staker = _stakerMap[stakerAddress];
        INode node = _nodes[nodeNum];
        uint256 newStakerCount = node.addStaker(stakerAddress);
        staker.latestStakedNode = nodeNum;
        if (newStakerCount == 1) {
            INode parent = _nodes[node.prev()];
            parent.newChildConfirmDeadline(block.number.add(confirmPeriodBlocks));
        }
    }

    /**
     * @notice Clear the withdrawable funds for the given address
     * @param owner Address of the account to remove funds from
     * @return Amount of funds removed from account
     */
    function withdrawFunds(address owner) internal returns (uint256) {
        uint256 amount = _withdrawableFunds[owner];
        _withdrawableFunds[owner] = 0;
        emit UserWithdrawableFundsUpdated(owner, amount, 0);
        return amount;
    }

    /**
     * @notice Increase the withdrawable funds for the given address
     * @param owner Address of the account to add withdrawable funds to
     */
    function increaseWithdrawableFunds(address owner, uint256 amount) internal {
        uint256 initialWithdrawable = _withdrawableFunds[owner];
        uint256 finalWithdrawable = initialWithdrawable.add(amount);
        _withdrawableFunds[owner] = finalWithdrawable;
        emit UserWithdrawableFundsUpdated(owner, initialWithdrawable, finalWithdrawable);
    }

    /**
     * @notice Remove the given staker
     * @param stakerAddress Address of the staker to remove
     */
    function deleteStaker(address stakerAddress) private {
        Staker storage staker = _stakerMap[stakerAddress];
        uint256 stakerIndex = staker.index;
        _stakerList[stakerIndex] = _stakerList[_stakerList.length - 1];
        _stakerMap[_stakerList[stakerIndex]].index = stakerIndex;
        _stakerList.pop();
        delete _stakerMap[stakerAddress];
    }

    /**
     * @notice Destroy the given node and clear out its address
     * @param nodeNum Index of the node to remove
     */
    function destroyNode(uint256 nodeNum) internal {
        _nodes[nodeNum].destroy();
        _nodes[nodeNum] = INode(0);
    }

    function nodeDeadline(
        uint256 avmGasSpeedLimitPerBlock,
        uint256 gasUsed,
        uint256 confirmPeriodBlocks,
        INode prevNode
    ) internal view returns (uint256 deadlineBlock) {
        // Set deadline rounding up to the nearest block
        uint256 checkTime =
            gasUsed.add(avmGasSpeedLimitPerBlock.sub(1)).div(avmGasSpeedLimitPerBlock);

        deadlineBlock = max(block.number.add(confirmPeriodBlocks), prevNode.deadlineBlock()).add(
            checkTime
        );

        uint256 olderSibling = prevNode.latestChildNumber();
        if (olderSibling != 0) {
            deadlineBlock = max(deadlineBlock, getNode(olderSibling).deadlineBlock());
        }
        return deadlineBlock;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    struct StakeOnNewNodeFrame {
        uint256 currentInboxSize;
        INode node;
        bytes32 executionHash;
        INode prevNode;
        bytes32 lastHash;
        bool hasSibling;
        uint256 deadlineBlock;
        uint256 gasUsed;
        uint256 sequencerBatchEnd;
        bytes32 sequencerBatchAcc;
    }

    struct CreateNodeDataFrame {
        uint256 prevNode;
        uint256 confirmPeriodBlocks;
        uint256 avmGasSpeedLimitPerBlock;
        ISequencerInbox sequencerInbox;
        RollupEventBridge rollupEventBridge;
        INodeFactory nodeFactory;
    }

    uint8 internal constant MAX_SEND_COUNT = 100;

    function createNewNode(
        RollupLib.Assertion memory assertion,
        bytes32[3][2] calldata assertionBytes32Fields,
        uint256[4][2] calldata assertionIntFields,
        bytes calldata sequencerBatchProof,
        CreateNodeDataFrame memory inputDataFrame,
        bytes32 expectedNodeHash
    ) internal returns (bytes32 newNodeHash) {
        StakeOnNewNodeFrame memory memoryFrame;
        {
            // validate data
            memoryFrame.gasUsed = RollupLib.assertionGasUsed(assertion);
            memoryFrame.prevNode = getNode(inputDataFrame.prevNode);
            memoryFrame.currentInboxSize = inputDataFrame.sequencerInbox.messageCount();

            // Make sure the previous state is correct against the node being built on
            require(
                RollupLib.stateHash(assertion.beforeState) == memoryFrame.prevNode.stateHash(),
                "PREV_STATE_HASH"
            );

            // Ensure that the assertion doesn't read past the end of the current inbox
            require(
                assertion.afterState.inboxCount <= memoryFrame.currentInboxSize,
                "INBOX_PAST_END"
            );
            // Insure inbox tip after assertion is included in a sequencer-inbox batch and return inbox acc; this gives replay protection against the state of the inbox
            (memoryFrame.sequencerBatchEnd, memoryFrame.sequencerBatchAcc) = inputDataFrame
                .sequencerInbox
                .proveInboxContainsMessage(sequencerBatchProof, assertion.afterState.inboxCount);
        }

        {
            memoryFrame.executionHash = RollupLib.executionHash(assertion);

            memoryFrame.deadlineBlock = nodeDeadline(
                inputDataFrame.avmGasSpeedLimitPerBlock,
                memoryFrame.gasUsed,
                inputDataFrame.confirmPeriodBlocks,
                memoryFrame.prevNode
            );

            memoryFrame.hasSibling = memoryFrame.prevNode.latestChildNumber() > 0;
            // here we don't use ternacy operator to remain compatible with slither
            if (memoryFrame.hasSibling) {
                memoryFrame.lastHash = getNodeHash(memoryFrame.prevNode.latestChildNumber());
            } else {
                memoryFrame.lastHash = getNodeHash(inputDataFrame.prevNode);
            }

            memoryFrame.node = INode(
                inputDataFrame.nodeFactory.createNode(
                    RollupLib.stateHash(assertion.afterState),
                    RollupLib.challengeRoot(assertion, memoryFrame.executionHash, block.number),
                    RollupLib.confirmHash(assertion),
                    inputDataFrame.prevNode,
                    memoryFrame.deadlineBlock
                )
            );
        }

        {
            uint256 nodeNum = latestNodeCreated() + 1;
            memoryFrame.prevNode.childCreated(nodeNum);

            newNodeHash = RollupLib.nodeHash(
                memoryFrame.hasSibling,
                memoryFrame.lastHash,
                memoryFrame.executionHash,
                memoryFrame.sequencerBatchAcc
            );
            require(newNodeHash == expectedNodeHash, "UNEXPECTED_NODE_HASH");

            nodeCreated(memoryFrame.node, newNodeHash);
            inputDataFrame.rollupEventBridge.nodeCreated(
                nodeNum,
                inputDataFrame.prevNode,
                memoryFrame.deadlineBlock,
                msg.sender
            );
        }

        emit NodeCreated(
            latestNodeCreated(),
            getNodeHash(inputDataFrame.prevNode),
            newNodeHash,
            memoryFrame.executionHash,
            memoryFrame.currentInboxSize,
            memoryFrame.sequencerBatchEnd,
            memoryFrame.sequencerBatchAcc,
            assertionBytes32Fields,
            assertionIntFields
        );

        return newNodeHash;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

import "../challenge/ChallengeLib.sol";
import "./INode.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

library RollupLib {
    using SafeMath for uint256;

    struct Config {
        bytes32 machineHash;
        uint256 confirmPeriodBlocks;
        uint256 extraChallengeTimeBlocks;
        uint256 avmGasSpeedLimitPerBlock;
        uint256 baseStake;
        address stakeToken;
        address owner;
        address sequencer;
        uint256 sequencerDelayBlocks;
        uint256 sequencerDelaySeconds;
        bytes extraConfig;
    }

    struct ExecutionState {
        uint256 gasUsed;
        bytes32 machineHash;
        uint256 inboxCount;
        uint256 sendCount;
        uint256 logCount;
        bytes32 sendAcc;
        bytes32 logAcc;
        uint256 proposedBlock;
        uint256 inboxMaxCount;
    }

    function stateHash(ExecutionState memory execState) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    execState.gasUsed,
                    execState.machineHash,
                    execState.inboxCount,
                    execState.sendCount,
                    execState.logCount,
                    execState.sendAcc,
                    execState.logAcc,
                    execState.proposedBlock,
                    execState.inboxMaxCount
                )
            );
    }

    struct Assertion {
        ExecutionState beforeState;
        ExecutionState afterState;
    }

    function decodeExecutionState(
        bytes32[3] memory bytes32Fields,
        uint256[4] memory intFields,
        uint256 proposedBlock,
        uint256 inboxMaxCount
    ) internal pure returns (ExecutionState memory) {
        return
            ExecutionState(
                intFields[0],
                bytes32Fields[0],
                intFields[1],
                intFields[2],
                intFields[3],
                bytes32Fields[1],
                bytes32Fields[2],
                proposedBlock,
                inboxMaxCount
            );
    }

    function decodeAssertion(
        bytes32[3][2] memory bytes32Fields,
        uint256[4][2] memory intFields,
        uint256 beforeProposedBlock,
        uint256 beforeInboxMaxCount,
        uint256 inboxMaxCount
    ) internal view returns (Assertion memory) {
        return
            Assertion(
                decodeExecutionState(
                    bytes32Fields[0],
                    intFields[0],
                    beforeProposedBlock,
                    beforeInboxMaxCount
                ),
                decodeExecutionState(bytes32Fields[1], intFields[1], block.number, inboxMaxCount)
            );
    }

    function executionStateChallengeHash(ExecutionState memory state)
        internal
        pure
        returns (bytes32)
    {
        return
            ChallengeLib.assertionHash(
                state.gasUsed,
                ChallengeLib.assertionRestHash(
                    state.inboxCount,
                    state.machineHash,
                    state.sendAcc,
                    state.sendCount,
                    state.logAcc,
                    state.logCount
                )
            );
    }

    function executionHash(Assertion memory assertion) internal pure returns (bytes32) {
        return
            ChallengeLib.bisectionChunkHash(
                assertion.beforeState.gasUsed,
                assertion.afterState.gasUsed - assertion.beforeState.gasUsed,
                RollupLib.executionStateChallengeHash(assertion.beforeState),
                RollupLib.executionStateChallengeHash(assertion.afterState)
            );
    }

    function assertionGasUsed(RollupLib.Assertion memory assertion)
        internal
        pure
        returns (uint256)
    {
        return assertion.afterState.gasUsed.sub(assertion.beforeState.gasUsed);
    }

    function challengeRoot(
        Assertion memory assertion,
        bytes32 assertionExecHash,
        uint256 blockProposed
    ) internal pure returns (bytes32) {
        return challengeRootHash(assertionExecHash, blockProposed, assertion.afterState.inboxCount);
    }

    function challengeRootHash(
        bytes32 execution,
        uint256 proposedTime,
        uint256 maxMessageCount
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(execution, proposedTime, maxMessageCount));
    }

    function confirmHash(Assertion memory assertion) internal pure returns (bytes32) {
        return
            confirmHash(
                assertion.beforeState.sendAcc,
                assertion.afterState.sendAcc,
                assertion.afterState.logAcc,
                assertion.afterState.sendCount,
                assertion.afterState.logCount
            );
    }

    function confirmHash(
        bytes32 beforeSendAcc,
        bytes32 afterSendAcc,
        bytes32 afterLogAcc,
        uint256 afterSendCount,
        uint256 afterLogCount
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    beforeSendAcc,
                    afterSendAcc,
                    afterSendCount,
                    afterLogAcc,
                    afterLogCount
                )
            );
    }

    function feedAccumulator(
        bytes memory messageData,
        uint256[] memory messageLengths,
        bytes32 beforeAcc
    ) internal pure returns (bytes32) {
        uint256 offset = 0;
        uint256 messageCount = messageLengths.length;
        uint256 dataLength = messageData.length;
        bytes32 messageAcc = beforeAcc;
        for (uint256 i = 0; i < messageCount; i++) {
            uint256 messageLength = messageLengths[i];
            require(offset + messageLength <= dataLength, "DATA_OVERRUN");
            bytes32 messageHash;
            assembly {
                messageHash := keccak256(add(messageData, add(offset, 32)), messageLength)
            }
            messageAcc = keccak256(abi.encodePacked(messageAcc, messageHash));
            offset += messageLength;
        }
        require(offset == dataLength, "DATA_LENGTH");
        return messageAcc;
    }

    function nodeHash(
        bool hasSibling,
        bytes32 lastHash,
        bytes32 assertionExecHash,
        bytes32 inboxAcc
    ) internal pure returns (bytes32) {
        uint8 hasSiblingInt = hasSibling ? 1 : 0;
        return keccak256(abi.encodePacked(hasSiblingInt, lastHash, assertionExecHash, inboxAcc));
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

interface INode {
    function initialize(
        address _rollup,
        bytes32 _stateHash,
        bytes32 _challengeHash,
        bytes32 _confirmData,
        uint256 _prev,
        uint256 _deadlineBlock
    ) external;

    function destroy() external;

    function addStaker(address staker) external returns (uint256);

    function removeStaker(address staker) external;

    function childCreated(uint256) external;

    function newChildConfirmDeadline(uint256 deadline) external;

    function stateHash() external view returns (bytes32);

    function challengeHash() external view returns (bytes32);

    function confirmData() external view returns (bytes32);

    function prev() external view returns (uint256);

    function deadlineBlock() external view returns (uint256);

    function noChildConfirmedBeforeBlock() external view returns (uint256);

    function stakerCount() external view returns (uint256);

    function stakers(address staker) external view returns (bool);

    function firstChildBlock() external view returns (uint256);

    function latestChildNumber() external view returns (uint256);

    function requirePastDeadline() external view;

    function requirePastChildConfirmDeadline() external view;
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

interface INodeFactory {
    function createNode(
        bytes32 _stateHash,
        bytes32 _challengeHash,
        bytes32 _confirmData,
        uint256 _prev,
        uint256 _deadlineBlock
    ) external returns (address);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

import "../bridge/interfaces/IBridge.sol";
import "../bridge/interfaces/ISequencerInbox.sol";
import "../arch/IOneStepProof.sol";

interface IChallenge {
    function initializeChallenge(
        IOneStepProof[] calldata _executors,
        address _resultReceiver,
        bytes32 _executionHash,
        uint256 _maxMessageCount,
        address _asserter,
        address _challenger,
        uint256 _asserterTimeLeft,
        uint256 _challengerTimeLeft,
        ISequencerInbox _sequencerBridge,
        IBridge _delayedBridge
    ) external;

    function currentResponderTimeLeft() external view returns (uint256);

    function lastMoveBlock() external view returns (uint256);

    function timeout() external;

    function asserter() external view returns (address);

    function challenger() external view returns (address);

    function clearChallenge() external;
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

pragma solidity ^0.6.11;

import "../bridge/interfaces/IBridge.sol";
import "../bridge/interfaces/ISequencerInbox.sol";

interface IChallengeFactory {
    function createChallenge(
        address _resultReceiver,
        bytes32 _executionHash,
        uint256 _maxMessageCount,
        address _asserter,
        address _challenger,
        uint256 _asserterTimeLeft,
        uint256 _challengerTimeLeft,
        ISequencerInbox _sequencerBridge,
        IBridge _delayedBridge
    ) external returns (address);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

interface IOutbox {
    event OutboxEntryCreated(
        uint256 indexed batchNum,
        uint256 outboxEntryIndex,
        bytes32 outputRoot,
        uint256 numInBatch
    );
    event OutBoxTransactionExecuted(
        address indexed destAddr,
        address indexed l2Sender,
        uint256 indexed outboxEntryIndex,
        uint256 transactionIndex
    );

    function l2ToL1Sender() external view returns (address);

    function l2ToL1Block() external view returns (uint256);

    function l2ToL1EthBlock() external view returns (uint256);

    function l2ToL1Timestamp() external view returns (uint256);

    function l2ToL1BatchNum() external view returns (uint256);

    function l2ToL1OutputId() external view returns (bytes32);

    function processOutgoingMessages(bytes calldata sendsData, uint256[] calldata sendLengths)
        external;

    function outboxEntryExists(uint256 batchNum) external view returns (bool);

    function executeTransaction(
        uint256 outboxIndex,
        bytes32[] calldata proof,
        uint256 index,
        address l2Sender,
        address destAddr,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 amount,
        bytes calldata calldataForL1) external;
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

library ProxyUtil {
    function getProxyAdmin() internal view returns (address admin) {
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/proxy/TransparentUpgradeableProxy.sol#L48
        // Storage slot with the admin of the proxy contract.
        // This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
        bytes32 slot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        assembly {
            admin := sload(slot)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

import "../INode.sol";
import "../../bridge/interfaces/IOutbox.sol";

interface IRollupUser {
    function initialize(address _stakeToken) external;

    function completeChallenge(address winningStaker, address losingStaker) external;

    function returnOldDeposit(address stakerAddress) external;

    function requireUnresolved(uint256 nodeNum) external view;

    function requireUnresolvedExists() external view;

    function countStakedZombies(INode node) external view returns (uint256);
}

interface IRollupAdmin {
    event OwnerFunctionCalled(uint256 indexed id);

    /**
     * @notice Add a contract authorized to put messages into this rollup's inbox
     * @param _outbox Outbox contract to add
     */
    function setOutbox(IOutbox _outbox) external;

    /**
     * @notice Disable an old outbox from interacting with the bridge
     * @param _outbox Outbox contract to remove
     */
    function removeOldOutbox(address _outbox) external;

    /**
     * @notice Enable or disable an inbox contract
     * @param _inbox Inbox contract to add or remove
     * @param _enabled New status of inbox
     */
    function setInbox(address _inbox, bool _enabled) external;

    /**
     * @notice Pause interaction with the rollup contract
     */
    function pause() external;

    /**
     * @notice Resume interaction with the rollup contract
     */
    function resume() external;

    /**
     * @notice Set the addresses of rollup logic facets called
     * @param newAdminFacet address of logic that owner of rollup calls
     * @param newUserFacet ddress of logic that user of rollup calls
     */
    function setFacets(address newAdminFacet, address newUserFacet) external;

    /**
     * @notice Set the addresses of the validator whitelist
     * @dev It is expected that both arrays are same length, and validator at
     * position i corresponds to the value at position i
     * @param _validator addresses to set in the whitelist
     * @param _val value to set in the whitelist for corresponding address
     */
    function setValidator(address[] memory _validator, bool[] memory _val) external;

    /**
     * @notice Set a new owner address for the rollup
     * @param newOwner address of new rollup owner
     */
    function setOwner(address newOwner) external;

    /**
     * @notice Set minimum assertion period for the rollup
     * @param newPeriod new minimum period for assertions
     */
    function setMinimumAssertionPeriod(uint256 newPeriod) external;

    /**
     * @notice Set number of blocks until a node is considered confirmed
     * @param newConfirmPeriod new number of blocks until a node is confirmed
     */
    function setConfirmPeriodBlocks(uint256 newConfirmPeriod) external;

    /**
     * @notice Set number of extra blocks after a challenge
     * @param newExtraTimeBlocks new number of blocks
     */
    function setExtraChallengeTimeBlocks(uint256 newExtraTimeBlocks) external;

    /**
     * @notice Set speed limit per block
     * @param newAvmGasSpeedLimitPerBlock maximum avmgas to be used per block
     */
    function setAvmGasSpeedLimitPerBlock(uint256 newAvmGasSpeedLimitPerBlock) external;

    /**
     * @notice Set base stake required for an assertion
     * @param newBaseStake maximum avmgas to be used per block
     */
    function setBaseStake(uint256 newBaseStake) external;

    /**
     * @notice Set the token used for stake, where address(0) == eth
     * @dev Before changing the base stake token, you might need to change the
     * implementation of the Rollup User facet!
     * @param newStakeToken address of token used for staking
     */
    function setStakeToken(address newStakeToken) external;

    /**
     * @notice Set max delay for sequencer inbox
     * @param newSequencerInboxMaxDelayBlocks max number of blocks
     * @param newSequencerInboxMaxDelaySeconds max number of seconds
     */
    function setSequencerInboxMaxDelay(
        uint256 newSequencerInboxMaxDelayBlocks,
        uint256 newSequencerInboxMaxDelaySeconds
    ) external;

    /**
     * @notice Set execution bisection degree
     * @param newChallengeExecutionBisectionDegree execution bisection degree
     */
    function setChallengeExecutionBisectionDegree(uint256 newChallengeExecutionBisectionDegree)
        external;

    /**
     * @notice Updates a whitelist address for its consumers
     * @dev setting the newWhitelist to address(0) disables it for consumers
     * @param whitelist old whitelist to be deprecated
     * @param newWhitelist new whitelist to be used
     * @param targets whitelist consumers to be triggered
     */
    function updateWhitelistConsumers(
        address whitelist,
        address newWhitelist,
        address[] memory targets
    ) external;

    /**
     * @notice Updates a whitelist's entries
     * @dev user at position i will be assigned value i
     * @param whitelist whitelist to be updated
     * @param user users to be updated in the whitelist
     * @param val if user is or not allowed in the whitelist
     */
    function setWhitelistEntries(
        address whitelist,
        address[] memory user,
        bool[] memory val
    ) external;

    /**
     * @notice Updates whether an address is a sequencer at the sequencer inbox
     * @param newSequencer address to be modified
     * @param isSequencer whether this address should be authorized as a sequencer
     */
    function setIsSequencer(address newSequencer, bool isSequencer) external;

    /**
     * @notice Upgrades the implementation of a beacon controlled by the rollup
     * @param beacon address of beacon to be upgraded
     * @param newImplementation new address of implementation
     */
    function upgradeBeacon(address beacon, address newImplementation) external;

    function forceResolveChallenge(address[] memory stackerA, address[] memory stackerB) external;

    function forceRefundStaker(address[] memory stacker) external;

    function forceCreateNode(
        bytes32 expectedNodeHash,
        bytes32[3][2] calldata assertionBytes32Fields,
        uint256[4][2] calldata assertionIntFields,
        bytes calldata sequencerBatchProof,
        uint256 beforeProposedBlock,
        uint256 beforeInboxMaxCount,
        uint256 prevNode
    ) external;

    function forceConfirmNode(
        uint256 nodeNum,
        bytes32 beforeSendAcc,
        bytes calldata sendsData,
        uint256[] calldata sendLengths,
        uint256 afterSendCount,
        bytes32 afterLogAcc,
        uint256 afterLogCount
    ) external;
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

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

interface IMessageProvider {
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

import "./INode.sol";

interface IRollupCore {
    function _stakerMap(address stakerAddress)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            bool
        );

    event RollupCreated(bytes32 machineHash);

    event NodeCreated(
        uint256 indexed nodeNum,
        bytes32 indexed parentNodeHash,
        bytes32 nodeHash,
        bytes32 executionHash,
        uint256 inboxMaxCount,
        uint256 afterInboxBatchEndCount,
        bytes32 afterInboxBatchAcc,
        bytes32[3][2] assertionBytes32Fields,
        uint256[4][2] assertionIntFields
    );

    event NodeConfirmed(
        uint256 indexed nodeNum,
        bytes32 afterSendAcc,
        uint256 afterSendCount,
        bytes32 afterLogAcc,
        uint256 afterLogCount
    );

    event NodeRejected(uint256 indexed nodeNum);

    event RollupChallengeStarted(
        address indexed challengeContract,
        address asserter,
        address challenger,
        uint256 challengedNode
    );

    event UserStakeUpdated(address indexed user, uint256 initialBalance, uint256 finalBalance);

    event UserWithdrawableFundsUpdated(
        address indexed user,
        uint256 initialBalance,
        uint256 finalBalance
    );

    function getNode(uint256 nodeNum) external view returns (INode);

    /**
     * @notice Get the address of the staker at the given index
     * @param stakerNum Index of the staker
     * @return Address of the staker
     */
    function getStakerAddress(uint256 stakerNum) external view returns (address);

    /**
     * @notice Check whether the given staker is staked
     * @param staker Staker address to check
     * @return True or False for whether the staker was staked
     */
    function isStaked(address staker) external view returns (bool);

    /**
     * @notice Get the latest staked node of the given staker
     * @param staker Staker address to lookup
     * @return Latest node staked of the staker
     */
    function latestStakedNode(address staker) external view returns (uint256);

    /**
     * @notice Get the current challenge of the given staker
     * @param staker Staker address to lookup
     * @return Current challenge of the staker
     */
    function currentChallenge(address staker) external view returns (address);

    /**
     * @notice Get the amount staked of the given staker
     * @param staker Staker address to lookup
     * @return Amount staked of the staker
     */
    function amountStaked(address staker) external view returns (uint256);

    /**
     * @notice Get the original staker address of the zombie at the given index
     * @param zombieNum Index of the zombie to lookup
     * @return Original staker address of the zombie
     */
    function zombieAddress(uint256 zombieNum) external view returns (address);

    /**
     * @notice Get Latest node that the given zombie at the given index is staked on
     * @param zombieNum Index of the zombie to lookup
     * @return Latest node that the given zombie is staked on
     */
    function zombieLatestStakedNode(uint256 zombieNum) external view returns (uint256);

    /// @return Current number of un-removed zombies
    function zombieCount() external view returns (uint256);

    function isZombie(address staker) external view returns (bool);

    /**
     * @notice Get the amount of funds withdrawable by the given address
     * @param owner Address to check the funds of
     * @return Amount of funds withdrawable by owner
     */
    function withdrawableFunds(address owner) external view returns (uint256);

    /**
     * @return Index of the first unresolved node
     * @dev If all nodes have been resolved, this will be latestNodeCreated + 1
     */
    function firstUnresolvedNode() external view returns (uint256);

    /// @return Index of the latest confirmed node
    function latestConfirmed() external view returns (uint256);

    /// @return Index of the latest rollup node created
    function latestNodeCreated() external view returns (uint256);

    /// @return Ethereum block that the most recent stake was created
    function lastStakeBlock() external view returns (uint256);

    /// @return Number of active stakers currently staked
    function stakerCount() external view returns (uint256);

    /// @return Node hash as of this node number
    function getNodeHash(uint256 index) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
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

pragma solidity ^0.6.11;

import "../libraries/MerkleLib.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library ChallengeLib {
    using SafeMath for uint256;

    function firstSegmentSize(uint256 totalCount, uint256 bisectionCount)
        internal
        pure
        returns (uint256)
    {
        return totalCount / bisectionCount + (totalCount % bisectionCount);
    }

    function otherSegmentSize(uint256 totalCount, uint256 bisectionCount)
        internal
        pure
        returns (uint256)
    {
        return totalCount / bisectionCount;
    }

    function bisectionChunkHash(
        uint256 _segmentStart,
        uint256 _segmentLength,
        bytes32 _startHash,
        bytes32 _endHash
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_segmentStart, _segmentLength, _startHash, _endHash));
    }

    function assertionHash(uint256 _avmGasUsed, bytes32 _restHash) internal pure returns (bytes32) {
        // Note: make sure this doesn't return Challenge.UNREACHABLE_ASSERTION (currently 0)
        return keccak256(abi.encodePacked(_avmGasUsed, _restHash));
    }

    function assertionRestHash(
        uint256 _totalMessagesRead,
        bytes32 _machineState,
        bytes32 _sendAcc,
        uint256 _sendCount,
        bytes32 _logAcc,
        uint256 _logCount
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _totalMessagesRead,
                    _machineState,
                    _sendAcc,
                    _sendCount,
                    _logAcc,
                    _logCount
                )
            );
    }

    function updatedBisectionRoot(
        bytes32[] memory _chainHashes,
        uint256 _challengedSegmentStart,
        uint256 _challengedSegmentLength
    ) internal pure returns (bytes32) {
        uint256 bisectionCount = _chainHashes.length - 1;
        bytes32[] memory hashes = new bytes32[](bisectionCount);
        uint256 chunkSize = ChallengeLib.firstSegmentSize(_challengedSegmentLength, bisectionCount);
        uint256 segmentStart = _challengedSegmentStart;
        hashes[0] = ChallengeLib.bisectionChunkHash(
            segmentStart,
            chunkSize,
            _chainHashes[0],
            _chainHashes[1]
        );
        segmentStart = segmentStart.add(chunkSize);
        chunkSize = ChallengeLib.otherSegmentSize(_challengedSegmentLength, bisectionCount);
        for (uint256 i = 1; i < bisectionCount; i++) {
            hashes[i] = ChallengeLib.bisectionChunkHash(
                segmentStart,
                chunkSize,
                _chainHashes[i],
                _chainHashes[i + 1]
            );
            segmentStart = segmentStart.add(chunkSize);
        }
        return MerkleLib.generateRoot(hashes);
    }

    function verifySegmentProof(
        bytes32 challengeState,
        bytes32 item,
        bytes32[] calldata _merkleNodes,
        uint256 _merkleRoute
    ) internal pure returns (bool) {
        return challengeState == MerkleLib.calculateRoot(_merkleNodes, _merkleRoute, item);
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

pragma solidity ^0.6.11;

library MerkleLib {
    function generateRoot(bytes32[] memory _hashes) internal pure returns (bytes32) {
        bytes32[] memory prevLayer = _hashes;
        while (prevLayer.length > 1) {
            bytes32[] memory nextLayer = new bytes32[]((prevLayer.length + 1) / 2);
            for (uint256 i = 0; i < nextLayer.length; i++) {
                if (2 * i + 1 < prevLayer.length) {
                    nextLayer[i] = keccak256(
                        abi.encodePacked(prevLayer[2 * i], prevLayer[2 * i + 1])
                    );
                } else {
                    nextLayer[i] = prevLayer[2 * i];
                }
            }
            prevLayer = nextLayer;
        }
        return prevLayer[0];
    }

    function calculateRoot(
        bytes32[] memory nodes,
        uint256 route,
        bytes32 item
    ) internal pure returns (bytes32) {
        uint256 proofItems = nodes.length;
        require(proofItems <= 256);
        bytes32 h = item;
        for (uint256 i = 0; i < proofItems; i++) {
            if (route % 2 == 0) {
                h = keccak256(abi.encodePacked(nodes[i], h));
            } else {
                h = keccak256(abi.encodePacked(h, nodes[i]));
            }
            route /= 2;
        }
        return h;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

import "../bridge/interfaces/IBridge.sol";
import "../bridge/interfaces/ISequencerInbox.sol";

interface IOneStepProof {
    // Bridges is sequencer bridge then delayed bridge
    function executeStep(
        address[2] calldata bridges,
        uint256 initialMessagesRead,
        bytes32[2] calldata accs,
        bytes calldata proof,
        bytes calldata bproof
    )
        external
        view
        returns (
            uint64 gas,
            uint256 afterMessagesRead,
            bytes32[4] memory fields
        );

    function executeStepDebug(
        address[2] calldata bridges,
        uint256 initialMessagesRead,
        bytes32[2] calldata accs,
        bytes calldata proof,
        bytes calldata bproof
    ) external view returns (string memory startMachine, string memory afterMachine);
}

