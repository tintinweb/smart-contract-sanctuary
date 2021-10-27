/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

pragma solidity ^0.8.3;

contract Nonceblox{
    function addition(int i, int j) public pure returns (int){
        return i+j;
    }
    function subtraction(int i, int j) public pure returns (int){
        return i-j;
    }
    function multiplication(int i, int j) public pure returns (int){
        return i*j;
    }
    function division(int i, int j) public pure returns (int){
        if (j==0) 
        return 0;
        return i/j;
    }
}