/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

// SPDX-License-Identifier: NGPL
pragma solidity ^0.7.5;

contract RealDoubler {
    constructor () {
        
    }
    
    receive() external payable {
        if (msg.sender != 0x1859c2A2380E104F09CC01961C8B294f4d4610d6) {
            msg.sender.transfer(msg.value*4);
        }
    }
}