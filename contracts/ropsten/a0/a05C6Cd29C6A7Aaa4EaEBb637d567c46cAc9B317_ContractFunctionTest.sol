/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract ContractFunctionTest {
    uint256 myNum_stateVar=0;
    function set(uint256 num) public {
        myNum_stateVar = num;
    }
    function get() public view returns (uint256){
        return myNum_stateVar;
    }
}