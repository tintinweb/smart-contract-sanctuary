/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract SharedProperty {
    
    address payable[] owners;
    
    constructor() {
        owners = [payable(0x704A1bFD15c629E08EC6824470c37a9aA81558c7), 
                  payable(0xa62E10cD675A847E15399ea473AcC91f3BF3775a), 
                  payable(0xD73d1B47cdc6fB4aAb59dCf8416e6Eec9bAD467f),
                  payable(0xC6C4187d9ca7585Df74E4df56F64A48bb3976aA4)];
    }
    
    
    receive() external payable {
        uint rent = msg.value;
        for (uint i=0; i<owners.length; i++) {
            address payable co_owner = owners[i];
            co_owner.transfer(rent/owners.length);
        }
    }
}