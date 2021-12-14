// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "./Arbitrum/Inbox.sol";

contract Test {

    address public inbox;
    constructor(address _inbox) {
        inbox = _inbox;
    }
   
    
    function depositEther(uint256 _maxSubmissionCost) public payable
    {   
        // Note that gas price and gas are set to 0; for deposit Ether, we don't need / expect any execution to take place.

        bytes memory callAbi = abi.encodeWithSignature(
            "createRetryableTicket(address,uint256,uint256,address,address,uint256,uint256,bytes)",
            // send msg to corresponding gateway on L2
            msg.sender,
            // do not need to send eth
            0,
            _maxSubmissionCost,
            // all refunds and ticket ownership to _to
            msg.sender,
            msg.sender,
            0,
            0,
            ""
        );
        (bool success, bytes memory returnValue) = inbox.call{value: msg.value}(callAbi);
        require(success, "InboxCall");
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;


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