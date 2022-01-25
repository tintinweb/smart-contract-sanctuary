/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract tle{



uint public amount;

    function sendEther() payable public{
        amount =msg.value;
    }

}