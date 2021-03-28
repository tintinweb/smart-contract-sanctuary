/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Fracciones {

    uint256 public number = 0;
    uint256 public resto = 0;

     constructor(uint256 _numero){
        number = _numero/1000;
        resto = number % 1000;
    }
    
}