/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

// SPDX SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

contract MOM {
                                 
    event Message(bool);

    fallback() external {
        emit Message(true);
    }
    
}