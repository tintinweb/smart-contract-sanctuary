// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract BoxV2{
    uint public val;

    // function initialize(uint _val) external {
    //     val = _val;
    // }
 
 function increment(uint _val) external{
     val += _val;
 }

}