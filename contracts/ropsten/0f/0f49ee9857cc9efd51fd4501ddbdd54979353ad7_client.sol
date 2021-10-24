/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.4;

contract ParentContract{
    uint internal simpleInteger;
    
    function SetInteger(uint _value) external {
        simpleInteger = _value;
    }
}

contract Childcontract is ParentContract {
    bool private simpleBool;
    
    function GetInteger() public view returns (uint) {
        return simpleInteger;
    }
}

contract client {
    Childcontract pc = new Childcontract();
    
    function workWithInheritance() public {
        pc.SetInteger(100);
    }
    
    function seeresultofWork() public view returns (uint){
        return pc.GetInteger();
    }
}