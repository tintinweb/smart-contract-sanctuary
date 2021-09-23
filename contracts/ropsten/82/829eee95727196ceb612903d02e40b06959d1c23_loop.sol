/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract loop {
    //uint s = 10000;
    uint[] arr;
    
    function looping() public view returns (uint) {
        uint s = arr.length;
        uint sum;
        for(uint i = 0;i<s;i++){
            if(arr[i]!=0)
            sum++;
        }
        return sum;
    }
    function len() public view returns (uint){
        return arr.length;
    }
    function init(uint s) public {
        arr = new uint[](s);
    }
}