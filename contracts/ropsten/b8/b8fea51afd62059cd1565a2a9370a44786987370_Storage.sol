/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Storage{

function mult(int32 number ) public pure returns(int32[] memory){
    // Локальные переменные
    int32[] memory arr;
    arr[0] = number;
    arr[1] = number * 2;
    return arr;
}

}