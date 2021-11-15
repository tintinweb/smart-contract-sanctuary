pragma solidity 0.8.4;

import "./BasicAMBInformationReceiver.sol";

contract SimpleTransferConfirmation is BasicAMBInformationReceiver {
    struct Log {
        address from;
        bytes32[] topics;
        bytes data;
    }
    
    struct Receipt {
        bytes32 txHash;
        uint256 blockNumber;
        bool status;
        Log[] logs;
    }
    
    mapping(bytes32 => bytes) public receipts;
    
    event Test(Log log);

    constructor(IHomeAMB _bridge) AMBInformationReceiverStorage(_bridge) {
    }
    
    function requestEthGetTransactionReceipt(bytes32 _txhash) external {
        bytes32 selector = keccak256("eth_getTransactionReceipt(bytes32)");
        lastMessageId = bridge.requireToGetInformation(selector, abi.encode(_txhash));
        status[lastMessageId] = Status.Pending;
    }

    function onResultReceived(bytes32 _messageId, bytes memory _result) internal override {
        (bytes32 txHash, uint256 blockNumber, bool status, Log[] memory logs) = abi.decode(_result, (bytes32, uint256, bool, Log[]));
        require(status);
        for (uint256 i = 0; i < logs.length; i++) {
            emit Test(logs[i]);
        }
    }
}

pragma solidity 0.8.4;

import "./interfaces/IAMBInformationReceiver.sol";
import "./AMBInformationReceiverStorage.sol";

abstract contract BasicAMBInformationReceiver is IAMBInformationReceiver, AMBInformationReceiverStorage {
    function onInformationReceived(bytes32 _messageId, bool _status, bytes memory _result) external override {
        require(msg.sender == address(bridge));
        if (_status) {
            onResultReceived(_messageId, _result);
        }
        status[_messageId] = _status ? Status.Ok : Status.Failed;
    }
    
    function onResultReceived(bytes32 _messageId, bytes memory _result) virtual internal;
}

pragma solidity 0.8.4;

import "./interfaces/IHomeAMB.sol";

contract AMBInformationReceiverStorage {
    IHomeAMB immutable bridge;
    
    enum Status {
        Unknown,
        Pending,
        Ok,
        Failed
    }
    
    mapping(bytes32 => Status) public status;
    bytes32 public lastMessageId;
    
    constructor(IHomeAMB _bridge) {
        bridge = _bridge;
    }
    
}

pragma solidity 0.8.4;

interface IAMBInformationReceiver {
    function onInformationReceived(bytes32 messageId, bool status, bytes calldata result) external;
}

pragma solidity 0.8.4;

interface IHomeAMB {
    function requireToGetInformation(bytes32 _requestSelector, bytes calldata _data) external returns (bytes32);
}

