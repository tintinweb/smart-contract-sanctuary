/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Storage{

function mult(int number ) public pure returns(int){
    // Локальные переменные
    int result = number * 2;
    return result;
}

}