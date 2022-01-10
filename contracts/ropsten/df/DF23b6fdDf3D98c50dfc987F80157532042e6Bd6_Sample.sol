// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Sample contract
 * @dev Perform complicated arithmetic that will dazzle the reader
 */
contract Sample {

    /// @notice The last result of the math function
    uint256 public lastMathResult;

    /**
     * @notice Perform complicated arithmetic
     * @param x A number
     * @param y Another number
     * @return Complicated result
     */
    function math(uint256 x, uint256 y) public returns(uint256) {
        uint256 res = x + y;
        lastMathResult = res;
        return res;
    }
}