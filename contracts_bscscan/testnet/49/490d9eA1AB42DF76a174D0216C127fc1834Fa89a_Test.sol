/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Test {

    uint locked_rewards;

    constructor() payable {
        locked_rewards = msg.value;
    }

    function add_reward() payable public {
        locked_rewards = msg.value;
    }
    
    function claim_reward() public {
        require(locked_rewards >= 0);
        address payable send_to = payable(msg.sender);
        send_to.transfer(locked_rewards);
    }
}