// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.4;

contract TEST2 {
    address test;

    function setTest(address _test) external {
        test = _test;
    }

    function getTest() external view returns (address) {
        return test;
    }
}