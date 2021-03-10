// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.4;

contract TEST1 {
    uint256 test;

    function setTest(uint256 _test) external {
        test = _test;
    }

    function getTest() external view returns (uint256) {
        return test;
    }
}