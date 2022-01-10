// SPDX-License-Identifier: MIT
// pragma solidity >=0.4.22 <0.9.0;
pragma solidity ^0.8.0;

contract Hello {
    int public tmp;

    function setTmp(int _tmp) public{
        tmp = _tmp;
    }

    function getTmp() view public returns(int){
        return tmp;
    }
}