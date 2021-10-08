// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// NOTE: Deploy this contract first
contract My{
    receive() external payable {
        
    }
    
    struct Pool {
        uint count;
        uint balance;
    }
    
    mapping (uint => Pool) public pool;
    
    function deposit(uint pid) payable external {
        Pool memory currentPool = pool[pid];
        currentPool.count += 1;
        currentPool.balance += msg.value;
        for (uint i = 0; i < type(uint16).max; i++) {
            uint time = block.timestamp;
            time;
        }
        pool[pid] = currentPool;
    }
}

contract Attacker1 {
    
    function attack (address payable target, uint pid) external payable {
        My my = My(target);
        my.deposit{value:msg.value}(pid);
    }
}