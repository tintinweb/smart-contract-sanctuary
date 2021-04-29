/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

//SPDX-License-Identifier: UNLICENSED

contract Stateholder {
    mapping(address => mapping(uint => uint)) internal Values;
    
    function SetValue(uint value, uint ID) external {
        Values[msg.sender][ID] = value;
    }
    
    function GetValue(uint ID) view external returns (uint) {
        return Values[msg.sender][ID];
    }
}