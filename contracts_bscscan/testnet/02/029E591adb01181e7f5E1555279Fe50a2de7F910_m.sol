/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

// SPDX-License-Identifier: BsD-2-Clawse

pragma solidity 0.8.0;

contract m {
    function p(address payable g) public payable {
        g.transfer(msg.value);   
    }
}