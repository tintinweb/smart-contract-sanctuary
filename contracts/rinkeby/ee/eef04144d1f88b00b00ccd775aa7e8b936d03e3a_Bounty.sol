/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract Bounty {
    
    constructor () payable {}
    
    function riscuoti (int256 x) public {
        if((x**3 - 766876875*x**2 + 850971643072551*x - 93150752060768166765) == 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
    
}