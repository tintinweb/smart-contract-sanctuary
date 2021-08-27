/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// Flashbots currently enforces a gas used floor. As of August 2021, that value is 42,000 gas. Any transaction that consumes less than this floor is rejected by relay
// This contract enables testing Flashbots with a single, simple transaction that will consume transaction's gas limit, ensuring the bundle won't be rejected
// See: https://docs.flashbots.net/flashbots-auction/searchers/advanced/bundle-pricing

contract WasteGas {
    event Waste(address sender, uint256 gas);
    uint256 constant GAS_REQUIRED_TO_FINISH_EXECUTION = 60;
    fallback() external {
        emit Waste(msg.sender, gasleft());
        while (gasleft() > GAS_REQUIRED_TO_FINISH_EXECUTION) {
        }
    }
}