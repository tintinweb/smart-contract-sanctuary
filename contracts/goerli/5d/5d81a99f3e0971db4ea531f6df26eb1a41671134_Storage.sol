/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    int private res;
    
    function add(int a, int b) public returns (int c){
        c = a + b;
        res = c;
        return res;
    }
    
    
    function del(int a, int b) public returns(int){
        res = a - b;
        return res;
    }
    
    function getRes() public view returns(int){
        
        return res;
    }
}