/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

//SPDX-License-Identifier: UNLICENSED

interface Stateholder {
    function GetValue(uint256 ID) external view returns (uint256);
    function SetValue(uint256 value, uint256 ID) external;
}

contract StateholderTester {
    event Set(uint Value, uint ID);
    event Get(uint Value, uint ID);
    
    function TestSet(address Target, uint Value, uint ID) external {
        Stateholder(Target).SetValue(Value, ID);
        emit Set(Value, ID);
    }
    
    function TestRead(address Target, uint ID) external {
        uint Value = Stateholder(Target).GetValue(ID);
        emit Get(Value, ID);
    }
}