/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.24;

contract class22{
    
    uint public integer_1 = 1;
    uint public abc = 0;
    uint256 public integer_2 = 2;
    string public string_1;
    
    //pure 不讀鏈上資料 不改鏈上資料     計算東西...
    function function_1(uint a,uint b) public pure returns(uint256){
        return a + 2*b;
    }
    
    //view 讀鏈上資料 不改鏈上資料   getName...
    function function_2() public view returns(uint256){
        return integer_1 + integer_2;
    }

    //修改鏈上資料    setName...
    function function_3(string x) public returns(string){
        string_1 = x;
        abc++;
        return string_1;
        
    }
    
    //修改鏈上資料
    function class(string x) public returns(string){
        string_1 = x;
        return string_1;
    }
    
}