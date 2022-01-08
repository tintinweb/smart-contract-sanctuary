/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Test2 {

    // function test(uint256[] memory arr) public returns (uint256[] memory){
    //     uint256[] memory temp = new uint256[](arr.length);
    //     // temp = arr;
    //     // temp[0] = 100;
    //     // temp
    //     temp.push(1);
    //     return temp;
    // }

    function test2(uint256 len) public pure returns(uint256 r){
        for(uint256 i=0;i < len;i++){
            r += i;
        }
    }
    function test3(uint256 len) external pure returns(uint256 r){
        for(uint256 i=0;i < len;i++){
            r += i;
        }
    }
}