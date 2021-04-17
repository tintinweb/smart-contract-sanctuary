/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

contract PoolTest {
    uint public swapFee;
    function setSwapFee(uint256 _swapFee) public {
        swapFee = _swapFee;
    }
    function getSwapFee() view public returns (uint256){
        return swapFee;
    }
}