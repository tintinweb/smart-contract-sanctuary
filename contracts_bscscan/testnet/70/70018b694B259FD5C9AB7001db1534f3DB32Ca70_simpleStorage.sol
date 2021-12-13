/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

//SPDX-License-Identifier: UNLICENSED
/*
             多
             行
             注
             释
*/
pragma solidity ^0.7.0;  //>=0.4.16 <0.9.0;

//创建合约
contract simpleStorage{
    uint storedData;
    function set(uint x) public{
        storedData=x;
    }
    function get() public view returns(uint){
        return storedData;
    }
}