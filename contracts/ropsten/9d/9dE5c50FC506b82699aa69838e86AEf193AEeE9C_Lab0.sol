// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

contract Lab0{
    int private privateNum = 33;
    int public publicNum = 77;
    
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

