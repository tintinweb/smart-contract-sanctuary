/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Splitter{
    address payable public recipient1;
    address payable public recipient2;
    
    event Transfered(uint value);
    
    function setRecipient(address payable _recipient1, address payable _recipient2) public {
        recipient1 = _recipient1;
        recipient2 = _recipient2;
    }
       
    function splitMoney() external payable{
        uint value = msg.value / 2;
        recipient1.transfer(value);
        recipient2.transfer(value);
        
        emit Transfered(value);
    }
}