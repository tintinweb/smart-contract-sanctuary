/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract loop {
    uint read=5;
    function looping(uint s) public view returns(uint){
        uint sum;
        for(uint i = 0 ;i<s;i++){
            sum +=read;
        }
        return sum;
    }
}