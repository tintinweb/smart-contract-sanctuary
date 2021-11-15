// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Ref {
    mapping(string => address) private holders;

    constructor(){
        holders["test"] = 0xe2E0256d6785d49eC7BadCD1D44aDBD3F6B0Ab58;
    }
}

