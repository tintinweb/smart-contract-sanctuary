// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IInbox.sol";
import "./IOutbox.sol";
import "../Greeter.sol";

contract GreeterL1 is Greeter {
  address public l2Target;
  IInbox public inbox;

  event RetryableTicketCreated(uint256 indexed ticketId);

  constructor(string memory _greeting, address _l2Target, address _inbox)
    Greeter(_greeting)
  {
    l2Target = _l2Target;
    inbox = IInbox(_inbox);
  }

  function updateL2Target(address _l2Target) public {
    l2Target = _l2Target;
  }

  function setGreetingInL2(
    string memory _greeting,
    uint256 maxSubmissionCost,
    uint256 maxGas,
    uint256 gasPriceBid
  ) public payable returns (uint256)
  {
    bytes memory data = abi.encodeWithSelector(Greeter.setGreeting.selector, _greeting);

    uint256 ticketId = inbox.createRetryableTicket{ value: msg.value }(
      l2Target,
      0,
      maxSubmissionCost,
      msg.sender,
      msg.sender,
      maxGas,
      gasPriceBid,
      data
    );

    emit RetryableTicketCreated(ticketId);
    return ticketId;
  }

  function setGreeting(string memory _greeting) public override {
    IOutbox outbox = IOutbox(inbox.bridge().activeOutbox());
    address l2Sender = outbox.l2ToL1Sender();
    require(l2Sender == l2Target, "Greeting only updateable by L2");

    Greeter.setGreeting(_greeting);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IInbox {
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

  function depositEth(uint256 maxSubmissionCost) external payable returns (uint256);

  function bridge() external view returns (IBridge);
}

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
    uint256 outboxIndex,
    bytes32 outputRoot,
    uint256 numInBatch
  );

  function l2ToL1Sender() external view returns (address);

  function l2ToL1Block() external view returns (uint256);

  function l2ToL1EthBlock() external view returns (uint256);

  function l2ToL1Timestamp() external view returns (uint256);

  function processOutgoingMessages(
    bytes calldata sendsData,
    uint256[] calldata sendLengths
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Greeter {
  string greeting;

  constructor(string memory _greeting) {
    greeting = _greeting;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public virtual {
    greeting = _greeting;
  }
}