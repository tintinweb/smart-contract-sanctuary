/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract Hodl {
    mapping(address => uint) adr_balance;
    receive() external payable{}
    fallback() external payable{}
    uint startTime;

    constructor() {
        startTime = block.timestamp;
    }

    function Deposit(uint value) public {
        adr_balance[msg.sender] += value;
    }

    function GetBalance() public view returns(uint) {
        return adr_balance[msg.sender];
    }

    function Withdraw() public {
        require(block.timestamp > startTime + 52 weeks);
        address payable holder = payable(msg.sender);
        selfdestruct(holder);
    }
    
    function Destory() private {
        selfdestruct(payable(msg.sender));
    }
}