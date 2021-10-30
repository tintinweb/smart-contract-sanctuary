/**
 *Submitted for verification at Etherscan.io on 2021-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Myfirst{
    int private result; //宣告變數//private不讓合約外的人見
    
    function add(int a, int b) public returns (int c) { //加法
        result = a + b;
        c = result;
    }
    
    function min(int a, int b) public returns (int) { //減法
        result = a - b;
        return result;
    }
    
    function mul(int a, int b) public returns (int) { //乘法
        result = a * b;
        return result;
    }
    
    function div(int a, int b) public returns (int) { //除法
        result = a % b;
        return result;
    }
    
    function getResult() public view returns(int) { // view表示看它而已
        return result;
    }
}