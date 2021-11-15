/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Greeter.
 * @notice There is a test contract.
 */
contract Greeter {
    /// Greeting function call counter
    uint256 public counter;

    /**
     * @dev Initializes the contract.
     */
    constructor() { counter = 5; }

    /**
     * @dev Returns the address of the caller.
     */
    function hello() external returns (address) {
        ++counter;
        return msg.sender;
    }
}