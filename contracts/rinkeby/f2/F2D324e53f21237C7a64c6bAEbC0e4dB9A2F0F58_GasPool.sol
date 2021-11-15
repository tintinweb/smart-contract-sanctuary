// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;


/**
 * The purpose of this contract is to hold USDQ tokens for gas compensation:
 * https://github.com/liquidity-protocol/liquidity#gas-compensation
 * When a borrower opens a trove, an additional 50 USDQ debt is issued,
 * and 50 USDQ is minted and sent to this contract.
 * When a borrower closes their active trove, this gas compensation is refunded:
 * 50 USDQ is burned from the this contract's balance, and the corresponding
 * 50 USDQ debt on the trove is cancelled.
 * See this issue for more context: issues/186
 */
contract GasPool {
    // do nothing, as the core contracts have permission to send to and burn from this address
}

