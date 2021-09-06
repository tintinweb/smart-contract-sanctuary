/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract loop {
    function looping(uint a,uint b,uint sum) public pure returns (uint) {
        if(b>0){
            b--;
            sum += looping(a,b,sum+b);
            return sum;
        }else{
            return sum;
        }
    }
}