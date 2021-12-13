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
pragma solidity ^0.7.0;

//创建合约
contract t1{
    //结构体，用来表示复杂的数据类型
    struct Person {
        uint age;   //uint 无符号数据类型， 指其值不能是负数
        string name;
    }
    // 创建一个新的Person:
    Person actor = Person(1688,"delf");
    //固定长度的为2的静态数组
    uint[2] fixedArray=[123,456];
    //固定长度为5的string类型的静态数据
    string[5] stringArray;
    //动态数据，长度不固定，可以动态添加元素
    uint[] dynamicArray;
    //定义函数
    string greeting = "Welcome to my world";
    function sayHello() public view returns (string memory) { //view 表示函数只读不修改数据
        return greeting;                                      //memory:给出变量的数据位置                                            
    }
    function _multiply(uint a, uint b) private pure returns (uint) {//pure 不读取或修改状态
         return a * b; 
    }
}