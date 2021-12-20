/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
contract Demo_03{   
    struct  Register{
        string Id;
        address Wallet;
    }
    Register [] public arrRegisters;
    event Send_data(string _id, address _wallet);
    function Regist(string memory _id) public{
        Register memory register1 = Register(_id,msg.sender);
        arrRegisters.push(register1);
        emit Send_data(_id, msg.sender);
    }
}