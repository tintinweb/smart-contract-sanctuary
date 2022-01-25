/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

//合約:calaulate，2個function
contract calaulate{
    int private a;//這是一個儲存結果的變數
    
    function add(int x, int y) public returns(int z){//這是加法的function，兩數相加為x,y，結果為z
        a = x + y;
        z = a;
    }
    
    function sub(int x, int y) public returns(int z){//這是減法的function，兩數相減為x,y，結果為z
        a = x - y;
        z = a;
    }
    
    function total() public view returns(int){
        return a;
    }
}