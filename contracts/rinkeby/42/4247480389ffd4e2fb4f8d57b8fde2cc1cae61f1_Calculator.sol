/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

pragma solidity ^0.4.17;


contract Calculator{
    int256 public result;
    
    function add(int256 a, int256 b) public{
        result=a+b;
    }
    function multiply(int256 a, int256 b) public{
        result = a*b;
    }
    
    function subtract(int256 a, int256 b) public view returns (int256){
        int256 resTemp= a-b;
        return resTemp;
    }
}