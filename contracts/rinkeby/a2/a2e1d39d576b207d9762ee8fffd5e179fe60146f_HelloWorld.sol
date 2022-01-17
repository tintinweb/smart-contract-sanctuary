/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// My First Smart Contract 
// SPDX-License-Identifier: All rights reserved
pragma solidity >=0.8.0;
contract HelloWorld {
    function get()public pure returns (string memory){
        return 'Hello Contracts';
    }
}