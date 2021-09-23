/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract loop {
    uint s = 100;
    uint[] arr = new uint[](s);
    
    function looping() public view returns (uint) {
        uint s2 = arr.length;
        uint sum;
        for(uint i = 0;i<s2;i++){
            if(arr[i]!=0)
            sum++;
        }
        return sum;
    }
    function len() public view returns (uint){
        return arr.length;
    }
    function init(uint s1) public {
        for(uint i =0;i<s1;i++){
            arr.push(s1);
        }
    }
}