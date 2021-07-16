/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

contract ContractA{
    uint256 a;
    function setA(uint256 value) external{
        a = value;
    }
    function getA() external view returns(uint256){
        return a;
    }
}