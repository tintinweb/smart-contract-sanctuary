/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Calc {
    int private result;
    
    function min(int a,int b) public returns (int) {
        result= a - b;
        return result;
    }
    function GetResult() public view returns (int) {
        return result;
    }
}