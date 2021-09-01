/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: 
pragma solidity ^0.8.5;



contract Test {
    event Sum(uint sum);
    uint sum;
    
    function init(uint a) external returns(uint) {
        sum = a + 3;
        emit Sum(sum);
        return sum;
    }
}