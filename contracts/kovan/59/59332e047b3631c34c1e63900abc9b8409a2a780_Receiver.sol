/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

pragma solidity 0.8.4;

interface IHomeAMB {
    function requireToGetInformation(bytes32 _requestSelector, bytes calldata _data) external returns (bytes32);
}

interface IAMBInformationReceiver {
    function onInformationReceived(bytes32 messageId, bool status, bytes calldata result) external;
}

contract AMBInformationReceiverStorage {
    IHomeAMB immutable bridge;
    
    enum Type {
        Invalid,
        Block,
        Transaction,
        TransactionReceipt
    }

    enum Status {
        Unknown,
        Pending,
        Ok,
        Failed
    }
    
    mapping(bytes32 => Status) public status;
    mapping(bytes32 => Type) public messageType;
    mapping(uint256 => Types.Block) internal blocks;
    mapping(bytes32 => Types.Transaction) internal transactions;
    mapping(bytes32 => bytes) internal receipts;
    bytes32 public lastMessageId;
    
    constructor(IHomeAMB _bridge) {
        bridge = _bridge;
    }
    
}

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

library Types {
    struct Log {
        address from;
        bytes32[] topics;
        bytes data;
    }
    
    struct TransactionReceipt {
        bytes32 txHash;
        uint256 blockNumber;
        bytes32 blockHash;
        uint256 transactionIndex;
        address from;
        address to;
        uint256 gasUsed;
        bool status;
        Log[] logs;
    }
    
    struct Transaction {
        bytes32 txHash;
        uint256 blockNumber;
        bytes32 blockHash;
        uint256 transactionIndex;
        address from;
        address to;
        uint256 value;
        uint256 nonce;
        uint256 gas;
        uint256 gasPrice;
        bytes input;
    }
    
    struct Block {
        uint256 blockNumber;
        bytes32 blockHash;
        address miner;
        uint256 gasUsed;
        uint256 gasLimit;
        bytes32 parentHash;
        bytes32 receiptRoot;
        bytes32 stateRoot;
        bytes32 transactionRoot;
        uint256 timestamp;
        uint256 difficulty;
        uint256 totalDifficulty;
    }
}

contract Receiver is BasicAMBInformationReceiver {
    constructor(IHomeAMB _bridge) AMBInformationReceiverStorage(_bridge) {
    }

    function requestBlock(uint256 n) external {
        _send(Type.Block, "eth_getBlockByNumber(uint256)", abi.encode(n));
    }
    
    function requestTransaction(bytes32 hash) external {
        _send(Type.Transaction, "eth_getTransactionByHash(bytes32)", abi.encode(hash));
    }
    
    function requestReceipt(bytes32 hash) external {
        _send(Type.TransactionReceipt, "eth_getTransactionReceipt(bytes32)", abi.encode(hash));
    }
    
    function _send(Type typ, bytes memory sig, bytes memory data) internal {
        lastMessageId = bridge.requireToGetInformation(keccak256(sig), data);
        status[lastMessageId] = Status.Pending;
        messageType[lastMessageId] = typ;
    }
    
    function onResultReceived(bytes32 _messageId, bytes memory _result) internal override {
        Type typ = messageType[lastMessageId];
        if (typ == Type.Block) {
            Types.Block memory blk = abi.decode(_result, (Types.Block));
            blocks[blk.blockNumber] = blk;
        } else if (typ == Type.Transaction) {
            Types.Transaction memory trx = abi.decode(_result, (Types.Transaction));
            transactions[trx.txHash] = trx;
        } else if (typ == Type.TransactionReceipt) {
            Types.TransactionReceipt memory rcp = abi.decode(_result, (Types.TransactionReceipt));
            receipts[rcp.txHash] = _result;
        } else {
            revert('InvalidType');
        }
    }
    
    function getBlock(uint256 n) external view returns (Types.Block memory) {
        return blocks[n];
    }
    
    function getTransaction(bytes32 hash) external view returns (Types.Transaction memory) {
        return transactions[hash];
    }
    
    function getReceipt(bytes32 hash) external view returns (Types.TransactionReceipt memory) {
        return abi.decode(receipts[hash], (Types.TransactionReceipt));
    }
}