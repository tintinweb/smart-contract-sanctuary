// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

contract Lab0{
    int private privateNum;
    int public publicNum;
    int public test;
    constructor(int prNum, int puNum){
        privateNum = prNum;
        publicNum = puNum;
    }
    function getPrivateNum() public view returns (int){
        return privateNum;
    }
    function setPublicNum(int target) public{
        publicNum = target;
    }
    function setPrivateNum(int target) public{
        privateNum = target;
    }
    
}

