//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./optimism/ICrossDomainMessenger.sol";
import "./arbitrum/IInbox.sol";

contract L1Sender {

    enum Network{
        OPTIMISM,
        ARBITRUM
    }

    address[] public messengers;
    address[] public l2Receivers;

    constructor(address[] memory _messengers, address[] memory _l2Receivers) {
        messengers = _messengers;
        l2Receivers = _l2Receivers;
    }

    function sendText(string memory _text, Network _network) public payable {
        _sendMessage(
            abi.encodeWithSignature(
                "setText(string)",
                _text
            ),
            _network
        );
    }

    function sendNum(uint256 _num, Network _network) public payable {
        _sendMessage(
            abi.encodeWithSignature(
                "setNum(uint256)",
                _num
            ),
            _network
        );
    }

    function _sendMessage(bytes memory _message, Network _network) internal {
        if (_network == Network.OPTIMISM) {
            ICrossDomainMessenger(messengers[uint(_network)]).sendMessage(
                l2Receivers[uint(_network)],
                _message,
                1000000      // gasLimit
            );
        }
        else if (_network == Network.ARBITRUM) {
            // theoretically msg.value is at least equal to maxSubmissionCost + (maxGas * gasPriceBid)
            require(msg.value >= 1902000000000);    // 2000000000 + (100000 * 19000000)

            IInbox(messengers[uint(_network)]).createRetryableTicket{value: msg.value} (
                l2Receivers[uint(_network)],
                0,
                2000000000,  // maxSubmissionCost
                msg.sender,
                msg.sender,
                100000,      // maxGas
                19000000,    // gasPriceBid
                _message
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0;


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