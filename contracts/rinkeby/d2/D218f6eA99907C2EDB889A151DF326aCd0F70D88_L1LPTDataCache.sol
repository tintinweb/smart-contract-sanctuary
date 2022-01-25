//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBridge} from "../../arbitrum/IBridge.sol";
import {IInbox} from "../../arbitrum/IInbox.sol";
import {IOutbox} from "../../arbitrum/IOutbox.sol";

abstract contract L1ArbitrumMessenger {
    IInbox public immutable inbox;

    event TxToL2(
        address indexed from,
        address indexed to,
        uint256 indexed seqNum,
        bytes data
    );

    constructor(address _inbox) {
        inbox = IInbox(_inbox);
    }

    modifier onlyL2Counterpart(address l2Counterpart) {
        // a message coming from the counterpart gateway was executed by the bridge
        address bridge = inbox.bridge();
        require(msg.sender == bridge, "NOT_FROM_BRIDGE");

        // and the outbox reports that the L2 address of the sender is the counterpart gateway
        address l2ToL1Sender = IOutbox(IBridge(bridge).activeOutbox())
            .l2ToL1Sender();
        require(l2ToL1Sender == l2Counterpart, "ONLY_COUNTERPART_GATEWAY");
        _;
    }

    function sendTxToL2(
        address target,
        address from,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes memory data
    ) internal returns (uint256) {
        return
            sendTxToL2(
                target,
                from,
                msg.value,
                0, // we always assume that l2CallValue = 0
                maxSubmissionCost,
                maxGas,
                gasPriceBid,
                data
            );
    }

    function sendTxToL2(
        address target,
        address from,
        uint256 _l1CallValue,
        uint256 _l2CallValue,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes memory data
    ) internal returns (uint256) {
        uint256 seqNum = inbox.createRetryableTicket{value: _l1CallValue}(
            target,
            _l2CallValue,
            maxSubmissionCost,
            from,
            from,
            maxGas,
            gasPriceBid,
            data
        );
        emit TxToL2(from, target, seqNum, data);
        return seqNum;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {L1ArbitrumMessenger} from "./L1ArbitrumMessenger.sol";

interface TotalSupplyLike {
    function totalSupply() external view returns (uint256);
}

interface IL2LPTDataCache {
    function finalizeCacheTotalSupply(uint256 _totalSupply) external;
}

contract L1LPTDataCache is L1ArbitrumMessenger {
    address public immutable tokenAddr;
    address public immutable l2LPTDataCacheAddr;

    event CacheTotalSupplyInitiated(uint256 seqNo, uint256 totalSupply);

    constructor(
        address _inbox,
        address _tokenAddr,
        address _l2LPTDataCacheAddr
    ) L1ArbitrumMessenger(_inbox) {
        tokenAddr = _tokenAddr;
        l2LPTDataCacheAddr = _l2LPTDataCacheAddr;
    }

    /**
     * @notice Executes a L2 call to cache L1 LPT total supply in L2LPTDataCache
     * @param _maxGas Gas limit for L2 execution
     * @param _gasPriceBid Gas price bid for L2 execution
     * @param _maxSubmissionCost Max ETH to pay for retryable ticket base submission fee
     */
    function cacheTotalSupply(
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable {
        (bytes memory data, uint256 totalSupply) = getCacheTotalSupplyData();

        uint256 seqNo = sendTxToL2(
            l2LPTDataCacheAddr,
            msg.sender, // Refund to caller
            _maxSubmissionCost,
            _maxGas,
            _gasPriceBid,
            data
        );

        emit CacheTotalSupplyInitiated(seqNo, totalSupply);
    }

    /**
     * @notice Return L2 calldata and total supply to use for a L2 call on L2LPTDataCache
     * @return data L2 calldata for L2LPTDataCache
     * @return totalSupply L1 LPT total supply
     */
    function getCacheTotalSupplyData()
        public
        view
        returns (bytes memory data, uint256 totalSupply)
    {
        totalSupply = TotalSupplyLike(tokenAddr).totalSupply();

        data = abi.encodeWithSelector(
            IL2LPTDataCache.finalizeCacheTotalSupply.selector,
            totalSupply
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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "./IMessageProvider.sol";

interface IInbox is IMessageProvider {
    function sendL2Message(bytes calldata messageData)
        external
        returns (uint256);

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

    function createRetryableTicketNoRefundAliasRewrite(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function depositEth(uint256 maxSubmissionCost)
        external
        payable
        returns (uint256);

    function bridge() external view returns (address);

    function pauseCreateRetryables() external;

    function unpauseCreateRetryables() external;

    function startRewriteAddress() external;

    function stopRewriteAddress() external;
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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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

    function processOutgoingMessages(
        bytes calldata sendsData,
        uint256[] calldata sendLengths
    ) external;

    function outboxEntryExists(uint256 batchNum) external view returns (bool);
}