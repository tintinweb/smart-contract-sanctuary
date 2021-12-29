/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Test2 {

    event L(address indexed sender, uint256 indexed a);

    function f1(uint a) public {

        // uint a = 0;
        while(true){
            emit L(msg.sender,a);
            //a++;
        }
    }
}