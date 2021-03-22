/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

contract SayHello {
    string internal _version;
    
    constructor(){
        _version = "1.0";
    }
    
    function sayHello(string memory _to) public pure returns(string memory){
        return string(abi.encodePacked("Hello ", _to, "!"));
    }
    
    function version() public view returns(string memory){
        return _version;
    }
}