/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

// SPDX-License-Identifier: unlicensed

pragma solidity >=0.7.0 <0.9.0;
contract Test {
    event TestLog(uint256 value);
    function test(uint8 input) external {
        require(input <= type(uint8).max, "overflow");
        emit TestLog(input);
    }
}