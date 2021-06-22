/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
contract serachBlockdata{

    address public senderAddress;

    function buy() public payable{

        senderAddress = msg.sender;

    }  

}