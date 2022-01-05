/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.4;

contract DepositWithdraw {


    mapping(address => uint) balanceOf;
    
    function getSmartContactBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function deposit() public payable {
        require(msg.value > 0, "must deposit more then zero amount");
        
        balanceOf[msg.sender] += msg.value; 
    }
    
    function withdrawal(uint _amount) public {
        require(balanceOf[msg.sender] >= _amount,"you have not enough balance");
        
        address payable reciver = payable(msg.sender);
        reciver.transfer(_amount);
        balanceOf[msg.sender] -= _amount;
    }
}