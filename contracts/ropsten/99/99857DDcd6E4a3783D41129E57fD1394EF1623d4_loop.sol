/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract loop {
    function looping(uint a,uint b) public pure returns (uint) {
        uint sum;
        for(uint i = 0;i<a;i++){
            sum = b*(a*a-a)/(b*b-b); 
        }
        return sum;
    }
}