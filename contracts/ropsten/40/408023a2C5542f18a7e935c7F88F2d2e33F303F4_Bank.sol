/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

contract Bank {
    address insurAddr;
    event sendMoney(address sender, uint amount);
    event receiveMoney(address sender, uint amount);

    function giveMoneyInsur(uint256 _value) external {
        payable(insurAddr).transfer(_value);
        emit sendMoney(insurAddr, _value);
    }

    function bb() external payable{
        emit receiveMoney(msg.sender, msg.value);
    }
    
    receive() external payable{
        emit sendMoney(msg.sender, msg.value);
    }

    function getBalance() view external returns(uint256){
       return address(this).balance;
    }
}