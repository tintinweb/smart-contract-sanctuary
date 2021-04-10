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

import "./Inbox.sol";
import "./Outbox.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IBridge.sol";

contract Bridge is Ownable, IBridge {
    struct InOutInfo {
        uint256 index;
        bool allowed;
    }

    mapping(address => InOutInfo) private allowedInboxesMap;
    mapping(address => InOutInfo) private allowedOutboxesMap;

    address[] public allowedInboxList;
    address[] public allowedOutboxList;

    address public override activeOutbox;
    bytes32[] public override inboxAccs;

    function allowedInboxes(address inbox) external view override returns (bool) {
        return allowedInboxesMap[inbox].allowed;
    }

    function allowedOutboxes(address outbox) external view override returns (bool) {
        return allowedOutboxesMap[outbox].allowed;
    }

    function deliverMessageToInbox(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable override returns (uint256) {
        require(allowedInboxesMap[msg.sender].allowed, "NOT_FROM_INBOX");
        uint256 count = inboxAccs.length;
        bytes32 messageHash =
            Messages.messageHash(
                kind,
                sender,
                block.number,
                block.timestamp, // solhint-disable-line not-rely-on-time
                count,
                tx.gasprice,
                messageDataHash
            );
        bytes32 prevAcc = 0;
        if (count > 0) {
            prevAcc = inboxAccs[count - 1];
        }
        inboxAccs.push(Messages.addMessageToInbox(prevAcc, messageHash));
        emit MessageDelivered(count, prevAcc, msg.sender, kind, sender, messageDataHash);
        return count;
    }

    function executeCall(
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool success, bytes memory returnData) {
        require(allowedOutboxesMap[msg.sender].allowed, "NOT_FROM_OUTBOX");
        address currentOutbox = activeOutbox;
        activeOutbox = msg.sender;
        (success, returnData) = destAddr.call{ value: amount }(data);
        activeOutbox = currentOutbox;
    }

    function setInbox(address inbox, bool enabled) external override onlyOwner {
        InOutInfo storage info = allowedInboxesMap[inbox];
        bool alreadyEnabled = info.allowed;
        if ((alreadyEnabled && enabled) || (!alreadyEnabled && !enabled)) {
            return;
        }
        if (enabled) {
            allowedInboxesMap[inbox] = InOutInfo(allowedInboxList.length, true);
            allowedInboxList.push(inbox);
        } else {
            allowedInboxList[info.index] = allowedInboxList[allowedInboxList.length - 1];
            allowedInboxesMap[allowedInboxList[info.index]].index = info.index;
            allowedInboxList.pop();
            delete allowedInboxesMap[inbox];
        }
    }

    function setOutbox(address outbox, bool enabled) external override onlyOwner {
        InOutInfo storage info = allowedOutboxesMap[outbox];
        bool alreadyEnabled = info.allowed;
        if ((alreadyEnabled && enabled) || (!alreadyEnabled && !enabled)) {
            return;
        }
        if (enabled) {
            allowedOutboxesMap[outbox] = InOutInfo(allowedOutboxList.length, true);
            allowedOutboxList.push(outbox);
        } else {
            allowedOutboxList[info.index] = allowedOutboxList[allowedOutboxList.length - 1];
            allowedOutboxesMap[allowedOutboxList[info.index]].index = info.index;
            allowedOutboxList.pop();
            delete allowedOutboxesMap[outbox];
        }
    }

    function messageCount() external view override returns (uint256) {
        return inboxAccs.length;
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

import "./interfaces/IInbox.sol";
import "./interfaces/IBridge.sol";

import "./Messages.sol";

contract Inbox is IInbox {
    uint8 internal constant ETH_TRANSFER = 0;
    uint8 internal constant L2_MSG = 3;
    uint8 internal constant L1MessageType_L2FundedByL1 = 7;
    uint8 internal constant L1MessageType_submitRetryableTx = 9;

    uint8 internal constant L2MessageType_unsignedEOATx = 0;
    uint8 internal constant L2MessageType_unsignedContractTx = 1;

    IBridge public override bridge;

    constructor(IBridge _bridge) public {
        bridge = _bridge;
    }

    /**
     * @notice Send a generic L2 message to the chain
     * @dev This method is an optimization to avoid having to emit the entirety of the messageData in a log. Instead validators are expected to be able to parse the data from the transaction's input
     * @param messageData Data of the message being sent
     */
    function sendL2MessageFromOrigin(bytes calldata messageData) external returns (uint256) {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender == tx.origin, "origin only");
        uint256 msgNum = deliverToBridge(L2_MSG, msg.sender, keccak256(messageData));
        emit InboxMessageDeliveredFromOrigin(msgNum);
        return msgNum;
    }

    /**
     * @notice Send a generic L2 message to the chain
     * @dev This method can be used to send any type of message that doesn't require L1 validation
     * @param messageData Data of the message being sent
     */
    function sendL2Message(bytes calldata messageData) external override returns (uint256) {
        uint256 msgNum = deliverToBridge(L2_MSG, msg.sender, keccak256(messageData));
        emit InboxMessageDelivered(msgNum, messageData);
        return msgNum;
    }

    function sendL1FundedUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        bytes calldata data
    ) external payable override returns (uint256) {
        return
            _deliverMessage(
                L1MessageType_L2FundedByL1,
                msg.sender,
                abi.encodePacked(
                    L2MessageType_unsignedEOATx,
                    maxGas,
                    gasPriceBid,
                    nonce,
                    uint256(uint160(bytes20(destAddr))),
                    msg.value,
                    data
                )
            );
    }

    function sendL1FundedContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        bytes calldata data
    ) external payable override returns (uint256) {
        return
            _deliverMessage(
                L1MessageType_L2FundedByL1,
                msg.sender,
                abi.encodePacked(
                    L2MessageType_unsignedContractTx,
                    maxGas,
                    gasPriceBid,
                    uint256(uint160(bytes20(destAddr))),
                    msg.value,
                    data
                )
            );
    }

    function sendUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external override returns (uint256) {
        return
            _deliverMessage(
                L2_MSG,
                msg.sender,
                abi.encodePacked(
                    L2MessageType_unsignedEOATx,
                    maxGas,
                    gasPriceBid,
                    nonce,
                    uint256(uint160(bytes20(destAddr))),
                    amount,
                    data
                )
            );
    }

    function sendContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external override returns (uint256) {
        return
            _deliverMessage(
                L2_MSG,
                msg.sender,
                abi.encodePacked(
                    L2MessageType_unsignedContractTx,
                    maxGas,
                    gasPriceBid,
                    uint256(uint160(bytes20(destAddr))),
                    amount,
                    data
                )
            );
    }

    function depositEth(address destAddr) external payable override returns (uint256) {
        return
            _deliverMessage(
                L1MessageType_L2FundedByL1,
                destAddr,
                abi.encodePacked(
                    L2MessageType_unsignedContractTx,
                    uint256(0),
                    uint256(0),
                    uint256(uint160(bytes20(destAddr))),
                    msg.value
                )
            );
    }

    function depositEthRetryable(
        address destAddr,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 maxGasPrice
    ) external payable override returns (uint256) {
        return
            this.createRetryableTicket(
                destAddr,
                msg.value,
                maxSubmissionCost,
                msg.sender,
                msg.sender,
                maxGas,
                maxGasPrice,
                ""
            );
    }

    function createRetryableTicket(
        address destAddr,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable override returns (uint256) {
        return
            _deliverMessage(
                L1MessageType_submitRetryableTx,
                msg.sender,
                abi.encodePacked(
                    uint256(uint160(bytes20(destAddr))),
                    l2CallValue,
                    msg.value,
                    maxSubmissionCost,
                    uint256(uint160(bytes20(excessFeeRefundAddress))),
                    uint256(uint160(bytes20(callValueRefundAddress))),
                    maxGas,
                    gasPriceBid,
                    data.length,
                    data
                )
            );
    }

    function _deliverMessage(
        uint8 _kind,
        address _sender,
        bytes memory _messageData
    ) private returns (uint256) {
        uint256 msgNum = deliverToBridge(_kind, _sender, keccak256(_messageData));
        emit InboxMessageDelivered(msgNum, _messageData);
        return msgNum;
    }

    function deliverToBridge(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) private returns (uint256) {
        return bridge.deliverMessageToInbox{ value: msg.value }(kind, sender, messageDataHash);
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

import "../libraries/CloneFactory.sol";
import "./OutboxEntry.sol";

import "./interfaces/IOutbox.sol";
import "./interfaces/IBridge.sol";

import "./Messages.sol";
import "../libraries/MerkleLib.sol";
import "../libraries/BytesLib.sol";

contract Outbox is CloneFactory, IOutbox {
    using BytesLib for bytes;

    bytes1 internal constant MSG_ROOT = 0;

    uint8 internal constant SendType_sendTxToL1 = 3;

    address rollup;
    IBridge bridge;

    ICloneable outboxEntryTemplate;
    OutboxEntry[] public outboxes;

    // Note, these variables are set and then wiped during a single transaction.
    // Therefore their values don't need to be maintained, and their slots will
    // be empty outside of transactions
    address private _sender;
    uint128 private _l2Block;
    uint128 private _l1Block;
    uint128 private _timestamp;

    constructor(address _rollup, IBridge _bridge) public {
        rollup = _rollup;
        bridge = _bridge;
        outboxEntryTemplate = ICloneable(new OutboxEntry());
    }

    /// @notice When l2ToL1Sender returns a nonzero address, the message was originated by an L2 account
    /// When the return value is zero, that means this is a system message
    function l2ToL1Sender() external view override returns (address) {
        return _sender;
    }

    function l2ToL1Block() external view override returns (uint256) {
        return uint256(_l2Block);
    }

    function l2ToL1EthBlock() external view override returns (uint256) {
        return uint256(_l1Block);
    }

    function l2ToL1Timestamp() external view override returns (uint256) {
        return uint256(_timestamp);
    }

    function processOutgoingMessages(bytes calldata sendsData, uint256[] calldata sendLengths)
        external
        override
    {
        require(msg.sender == rollup, "ONLY_ROLLUP");
        // If we've reached here, we've already confirmed that sum(sendLengths) == sendsData.length
        uint256 messageCount = sendLengths.length;
        uint256 offset = 0;
        for (uint256 i = 0; i < messageCount; i++) {
            handleOutgoingMessage(bytes(sendsData[offset:offset + sendLengths[i]]));
            offset += sendLengths[i];
        }
    }

    function handleOutgoingMessage(bytes memory data) private {
        // Otherwise we have an unsupported message type and we skip the message
        if (data[0] == MSG_ROOT) {
            require(data.length == 97, "BAD_LENGTH");
            uint256 batchNum = data.toUint(1);
            uint256 numInBatch = data.toUint(33);
            bytes32 outputRoot = data.toBytes32(65);

            address clone = createClone(outboxEntryTemplate);
            OutboxEntry(clone).initialize(bridge, outputRoot, numInBatch);
            uint256 outboxIndex = outboxes.length;
            outboxes.push(OutboxEntry(clone));
            emit OutboxEntryCreated(batchNum, outboxIndex, outputRoot, numInBatch);
        }
    }

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
        bytes calldata calldataForL1
    ) external {
        bytes32 userTx = calculateItemHash(
            l2Sender,
            destAddr,
            l2Block,
            l1Block,
            l2Timestamp,
            amount,
            calldataForL1
        );

        spendOutput(outboxIndex, proof, index, userTx);

        address currentSender = _sender;
        uint128 currentL2Block = _l2Block;
        uint128 currentL1Block = _l1Block;
        uint128 currentTimestamp = _timestamp;

        _sender = l2Sender;
        _l2Block = uint128(l2Block);
        _l1Block = uint128(l1Block);
        _timestamp = uint128(l2Timestamp);

        executeBridgeCall(destAddr, amount, calldataForL1);

        _sender = currentSender;
        _l2Block = currentL2Block;
        _l1Block = currentL1Block;
        _timestamp = currentTimestamp;
    }

    function spendOutput(
        uint256 outboxIndex,
        bytes32[] memory proof,
        uint256 path,
        bytes32 item
    ) private {
        require(proof.length <= 256, "PROOF_TOO_LONG");
        require(path < 2**proof.length, "PATH_NOT_MINIMAL");

        // Hash the leaf an extra time to prove it's a leaf
        bytes32 calcRoot = calculateMerkleRoot(proof, path, item);
        OutboxEntry outbox = outboxes[outboxIndex];
        require(address(outbox) != address(0), "NO_OUTBOX");

        // With a minimal path, the pair of path and proof length should always identify
        // a unique leaf. The path itself is not enough since the path length to different
        // leaves could potentially be different
        bytes32 uniqueKey = keccak256(abi.encodePacked(path, proof.length));

        executeBridgeSystemCall(
            address(outbox),
            0,
            abi.encodeWithSelector(OutboxEntry.spendOutput.selector, calcRoot, uniqueKey)
        );

        if (outbox.numRemaining() == 0) {
            executeBridgeSystemCall(
                address(outbox),
                0,
                abi.encodeWithSelector(OutboxEntry.destroy.selector)
            );
            outboxes[outboxIndex] = OutboxEntry(address(0));
        }
    }

    function executeBridgeSystemCall(
        address destAddr,
        uint256 amount,
        bytes memory data
    ) private {
        address currentSender = _sender;
        _sender = address(0);
        executeBridgeCall(destAddr, amount, data);
        _sender = currentSender;
    }

    function executeBridgeCall(
        address destAddr,
        uint256 amount,
        bytes memory data
    ) private {
        (bool success, bytes memory returndata) = bridge.executeCall(destAddr, amount, data);
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("BRIDGE_CALL_FAILED");
            }
        }
    }

    function calculateItemHash(
        address l2Sender,
        address destAddr,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 amount,
        bytes calldata calldataForL1
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                SendType_sendTxToL1,
                uint256(uint160(bytes20(l2Sender))),
                uint256(uint160(bytes20(destAddr))),
                l2Block,
                l1Block,
                l2Timestamp,
                amount,
                calldataForL1
            )
        );
    }

    function calculateMerkleRoot(
        bytes32[] memory proof,
        uint256 path,
        bytes32 item
    ) public pure returns (bytes32) {
        return MerkleLib.calculateRoot(proof, path, keccak256(abi.encodePacked(item)));
    }

    function outboxesLength() public view returns (uint256) {
        return outboxes.length;
    }
}

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

import "./IBridge.sol";
import "./IMessageProvider.sol";

interface IInbox is IMessageProvider {
    function sendL2Message(bytes calldata messageData) external returns (uint256);

    function sendUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function createRetryableTicket(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function depositEth(address destAddr) external payable returns (uint256);

    function depositEthRetryable(address destAddr, uint256 maxSubmissionCost, uint256 maxGas, uint256 maxGasPrice) external payable returns (uint256);

    function bridge() external view returns (IBridge);
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

// SPDX-License-Identifier: MIT

// Taken from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol

pragma solidity ^0.6.11;

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

import "./ICloneable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract CloneFactory {
    using Clones for address;
    string private constant CLONE_MASTER = "CLONE_MASTER";

    function createClone(ICloneable target) internal returns (address result) {
        require(target.isMaster(), CLONE_MASTER);
        result = address(target).clone();
    }

    function create2Clone(ICloneable target, bytes32 salt) internal returns (address result) {
        require(target.isMaster(), CLONE_MASTER);
        result = address(target).cloneDeterministic(salt);
    }

    function calculateCreate2CloneAddress(ICloneable target, bytes32 salt) internal view returns (address calculatedAddress) {
        calculatedAddress = address(target).predictDeterministicAddress(salt, address(this));
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

import "../libraries/Cloneable.sol";

import "./interfaces/IOutbox.sol";
import "./interfaces/IBridge.sol";

contract OutboxEntry is Cloneable {
    IBridge bridge;
    bytes32 public root;
    uint256 public numRemaining;
    mapping(bytes32 => bool) public spentOutput;

    function initialize(
        IBridge _bridge,
        bytes32 _root,
        uint256 _numInBatch
    ) external {
        require(root == 0, "ALREADY_INIT");
        require(_root != 0, "BAD_ROOT");
        bridge = _bridge;
        root = _root;
        numRemaining = _numInBatch;
    }

    function spendOutput(bytes32 _root, bytes32 _id) external {
        requireBridgeSystemCall();
        require(!spentOutput[_id], "ALREADY_SPENT");
        require(_root == root, "BAD_ROOT");
        spentOutput[_id] = true;
        numRemaining--;
        if (numRemaining == 0) {
            safeSelfDestruct(msg.sender);
        }
    }

    function destroy() external {
        requireBridgeSystemCall();
        safeSelfDestruct(msg.sender);
    }

    function requireBridgeSystemCall() private view {
        require(msg.sender == address(bridge), "ONLY_BRIDGE");
        // Make sure this call was generated as a system call from the bridge rather than an L2 call
        require(IOutbox(bridge.activeOutbox()).l2ToL1Sender() == address(0), "ONLY_SYSTEM");
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

interface IOutbox {
    event OutboxEntryCreated(
        uint256 indexed batchNum,
        uint256 outboxIndex,
        bytes32 outputRoot,
        uint256 numInBatch
    );

    function l2ToL1Sender() external view returns (address);

    function l2ToL1Block() external view returns (uint256);

    function l2ToL1EthBlock() external view returns (uint256);

    function l2ToL1Timestamp() external view returns (uint256);

    function processOutgoingMessages(bytes calldata sendsData, uint256[] calldata sendLengths)
        external;
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

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
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

{
  "optimizer": {
    "enabled": true,
    "runs": 100
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}