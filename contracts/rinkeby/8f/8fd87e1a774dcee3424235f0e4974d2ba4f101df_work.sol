/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.1;
contract work{
    address public senderAddress;
    uint public Value;
    uint public n=7;
    uint public calcu;

    
    function buy() public payable{
        senderAddress = msg.sender;
        Value = msg.value;
        calcu = (1+n)*7/2;
    }
}