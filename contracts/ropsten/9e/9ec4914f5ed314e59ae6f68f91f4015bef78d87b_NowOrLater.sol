/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract NowOrLater {

    mapping(address => uint) accountBalance; /// keep account of every address that deposited money
    mapping(address => uint) depositTimes; /// keep account of the deposit time of every address
    mapping(address => bool) withdrawals; /// keep account of the amount of withdrawals of every address

    function deposit() public payable {
        accountBalance[msg.sender] += msg.value;
        depositTimes[msg.sender] = block.timestamp;
        withdrawals[msg.sender] = false;
    }

    function withdraw(uint amount) public {
        require(accountBalance[msg.sender] >= amount, "You do not have enough funds");
        if(block.timestamp > depositTimes[msg.sender] + 2 minutes){
            payable(msg.sender).transfer(amount);
            accountBalance[msg.sender] -= amount;
        }
        else{
            require(!withdrawals[msg.sender], "You already withdrew, you cannot do it a second time");
            payable(msg.sender).transfer(amount/2);
            accountBalance[msg.sender] /= 2;
            withdrawals[msg.sender] = true;
        }
    }
}