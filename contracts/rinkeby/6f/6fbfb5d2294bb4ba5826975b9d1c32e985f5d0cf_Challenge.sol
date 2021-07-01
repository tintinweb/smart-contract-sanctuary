/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.6;

contract Challenge {
    
    address public owner;
    uint private random = 0xf3a74394049d051b4b28a7d75e00caa86bd7dc9890614de13de3658c65d45288;
    bool public running = false;
    uint public start_time = 0;
    uint public end_time = 0;
    address public last_holder;
    address public last_winner;
    
    event SendFlag(address);
    
    modifier check_start() {
        if (running == false) {
            running = true;
            start_time = block.timestamp;
            end_time = start_time + 3 minutes;
            last_holder = msg.sender;
            last_winner = address(0);
        }
        _;
    }
    
    modifier check_stop() {
        if (running == true && block.timestamp >= end_time) {
            running = false;
            start_time = 0;
            end_time = 0;
            last_winner = last_holder;
            emit SendFlag(last_winner);
            return;
        }
        _;
    }
    
    constructor() payable {
        owner = msg.sender;
    }
    
    receive() external payable check_start check_stop {}
    fallback() external payable check_start check_stop {}
    
    function hold() public payable check_start check_stop {
        last_holder = msg.sender;
        if (block.timestamp + 60 seconds > end_time) {
            end_time += 30 seconds;
        }
    }
    
    function kill() public payable {
        require(owner == msg.sender);
        selfdestruct(payable(owner));
    }
}