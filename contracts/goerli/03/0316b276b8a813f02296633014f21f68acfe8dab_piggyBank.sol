/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract piggyBank {
    uint public goal;

    constructor(uint _goal) {
        goal = _goal;
    }
    receive() external payable{}

    // 获取balance
    function getMyBalance() public view returns(uint) {
        return address(this).balance;
    }

    // 提取时，存储的总金额需大于储蓄目标,并销毁
    function withdraw() public {
        if(getMyBalance() > goal) {
            selfdestruct(msg.sender);
        }
    }
}