/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title EthBalance
 * @notice Read the ETH balance of any address.
 * @author https://github.com/zacel
 */
contract EthBalance {
    function getETHBalance(address input) external view returns (uint256) {
        return input.balance;
    }
}