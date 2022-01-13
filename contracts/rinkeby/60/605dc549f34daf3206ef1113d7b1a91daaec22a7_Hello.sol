/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

pragma solidity ^0.4.24;
contract Hello{
    string public name;
    string public version;

    constructor() public{
        name = "我是一個智能合約";
        version = "V2.0";
    }

    function setName(string _name) public{
        name = _name;
    }
}