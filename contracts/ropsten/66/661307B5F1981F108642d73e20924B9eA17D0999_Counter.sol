pragma solidity =0.8.0;

interface ICounter {
    function getCount() external view returns (uint);
    function increment() external;
    function getMessageSender() external view returns(address);
}

contract Counter is ICounter {
    uint private _count;
    
    function getCount() external override view returns (uint) {
        return(_count);
    }
    
    function increment() external override {
        _count = ++_count;
    }
    
    function getMessageSender() external override view returns(address) {
        return msg.sender;
    }
}

contract TestInternal {
    function _getMessageSenderInternal() internal view returns(address) {
        return msg.sender;
    }
}

contract Test is TestInternal {
    address _counter;
    
    constructor(address counter) {
        _counter = counter;    
    }
    
    function getMessageSenderInternal() external view returns(address) {
        return _getMessageSenderInternal();
    }
    
    function getMessageSender() external view returns(address) {
        return msg.sender;
    }
    
    function getCounterMessageSender() external view returns(address) {
        return ICounter(_counter).getMessageSender();
    }
}

