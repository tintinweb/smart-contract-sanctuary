//SPDX-License-Identifier: MIT
pragma solidity 0.7.1;

contract ClaudioTest {
    function test(uint256 num1, uint256 num2)
        public
        view
        returns (uint256 batatinha)
    {
        batatinha = num1 + num2;
    }
}

