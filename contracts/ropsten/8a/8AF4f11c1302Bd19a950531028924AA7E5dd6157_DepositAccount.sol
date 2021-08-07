/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

pragma solidity ^0.8.3;

// SPDX-License-Identifier: GPL-3.0-or-later

contract DepositAccount {
    address payable target;


    function withdraw( address payable target ) public {

        target.transfer(address(this).balance);
    }
    
    fallback() payable external {}
}