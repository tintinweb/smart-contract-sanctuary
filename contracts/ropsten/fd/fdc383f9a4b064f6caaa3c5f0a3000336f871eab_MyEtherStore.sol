/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.26;

contract MyEtherStore {
    uint public withdrawalLimit = 1000000000 wei; // 10 gwei
    mapping(address => uint) public lastWithdrawTime;
    mapping(address => uint) public balances;

    function depositFunds() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawFunds (uint _weiToWithdraw) public {
        require(balances[msg.sender] >= _weiToWithdraw);

        // limit the withdrawal
        require(_weiToWithdraw <= withdrawalLimit);

        // limit the time allowed to withdraw
        require(now >= lastWithdrawTime[msg.sender] + 1 minutes);
        require(msg.sender.call.value(_weiToWithdraw)());

        balances[msg.sender] -= _weiToWithdraw;
        lastWithdrawTime[msg.sender] = now;
    }
}