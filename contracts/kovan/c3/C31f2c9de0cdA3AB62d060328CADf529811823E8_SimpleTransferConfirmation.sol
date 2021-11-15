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
    
    event TotalTransferred(bytes32 txHash, uint256 amount);

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
        uint256 amount = 0;
        for (uint256 i = 0; i < logs.length; i++) {
            Log memory log = logs[i];
            if (
                log.from == address(0xcEb5BfB5370323b146b236b23887082412971218) &&
                log.topics.length >= 2 &&
                log.topics[0] == 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef &&
                log.topics[2] == 0x0000000000000000000000002d5c035f99a7df3067edacded0e117d7076abf7c
            ) {
                amount += abi.decode(log.data, (uint256));
            }
        }
        
        emit TotalTransferred(txHash, amount);
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

