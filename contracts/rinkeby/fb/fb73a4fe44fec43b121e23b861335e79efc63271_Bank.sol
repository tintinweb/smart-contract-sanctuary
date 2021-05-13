/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Bank {

    int bal;
    
    constructor()  {
        bal=2;
    }


    function getBalance () view public returns(int) {
       return bal;
    }


    function withdraw(int amn) public {
        bal = bal - amn;
    }
    
    
    function deposit(int amn) public {
        bal = bal + amn;
    }
    
    
    
}