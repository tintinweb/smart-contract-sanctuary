/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

contract Calc {
    int private result;
    function add(int a, int b) public returns (int c){
        result=a+b;
        c=result;
    }
    function min(int a, int b) public returns(int c){
        result=a-b;
        c=result;
    }
    function mul(int a, int b) public returns(int c){
        result=a*b;
        c=result;
    }
    function div(int a, int b) public returns(int c){
        result=a/b;
        c=result;
    }
    function getResult() public view returns(int c){
        c=result;
    }

}