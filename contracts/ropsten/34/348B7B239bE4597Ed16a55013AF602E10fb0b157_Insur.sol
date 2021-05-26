/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

contract Insur {
    address insurAddr;
    event receiveMoney(address sender, uint amount);

    function getBalance() view external returns(uint256){
       return address(this).balance;
    }
    
    receive() external payable{
        emit receiveMoney(msg.sender, msg.value);
    }
}