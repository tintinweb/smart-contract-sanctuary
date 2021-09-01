/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.1;

interface Counter {
    function getCount() external view returns (uint256);
    function increment() external;
}

contract CounterFactory {
    mapping(address => uint) _counters;
    mapping(address => bool) _registerMap;

    Counter constant public counter = Counter(0x5af602D691F3047c7D0c5d4ddaF089f4BA38a19a);

    event LogRegister(address);
    event LogIncrement(address);
    event LogGetCount(address,uint);

    modifier needRegistered(address addr) {
        require (_registerMap[addr] == true, "counter not registered");
        _;
    }

    function register() public {
        require (_registerMap[msg.sender] == false, "counter already register");
        _registerMap[msg.sender] = true;
        emit LogRegister(msg.sender);
    }
    function increment() public needRegistered(msg.sender) {
        counter.increment();
        _counters[msg.sender] = counter.getCount();
        emit LogIncrement(msg.sender);
    }
    function getCount(address account) public needRegistered(account) returns (uint256) {
        emit LogGetCount(account, _counters[account]);
        return  _counters[account];
    }
    function getMyCount() public returns (uint256) {
        return (getCount(msg.sender));
    }
}