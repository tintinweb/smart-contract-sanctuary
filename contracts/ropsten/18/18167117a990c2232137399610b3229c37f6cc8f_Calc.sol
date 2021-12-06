/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }
}
contract Calc{
    int private result;
    function add(int a,int b) public returns (int){
        result = a + b;
        return result;
    }
    function getResult() public view returns(int){
        return result;
    } 
}