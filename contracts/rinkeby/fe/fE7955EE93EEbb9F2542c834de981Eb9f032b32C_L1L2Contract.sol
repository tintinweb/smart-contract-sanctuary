// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
import "./libraries/Inbox.sol";

contract L1L2Contract {
    address public aliasAddress;
    string public temp = "123";
    address public l1Target;
    address public l2Target;
    IInbox public inbox;
    event RetryableTicketCreated(uint256 ticketID);

    function L1Setup(address _inbox, address _l2Target) public {
        inbox = IInbox(_inbox);
        l2Target = _l2Target;
    }

    function L2Setup(address _l1Target) public {
        l1Target = _l1Target;
    }

    //function L1
    function getInbox() public view returns (address) {
        return address(inbox);
    }

    //function L2
    function setAliasAddress(string memory _temp) public payable {
        temp = _temp;
        aliasAddress = msg.sender;
    }

    // function L1
    function setAliasAddressFromL1ToL2(
        string memory _temp,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid
    ) public payable returns (uint256) {
        bytes memory data = abi.encodeWithSignature(
            "setAliasAddress(string)",
            _temp
        );
        uint256 ticketID = inbox.createRetryableTicket{value: msg.value}(
            l2Target,
            0,
            maxSubmissionCost,
            msg.sender,
            msg.sender,
            maxGas,
            gasPriceBid,
            data
        );
        emit RetryableTicketCreated(ticketID);
        return ticketID;
    }

    //function L1
    function depositETH(uint256 _maxSubmissionCost) public payable {
        inbox.createRetryableTicket{value: msg.value}(msg.sender, 0, _maxSubmissionCost, msg.sender, msg.sender, 0, 0, '0x');   
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IInbox {
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

    function depositEth(uint256 maxSubmissionCost)
        external
        payable
        returns (uint256);

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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
  "libraries": {}
}