// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library RedeemLib {
    function calculateRedeemable(address token, uint256 amount)
        external
        pure
        returns (uint256 redeemable)
    {
        redeemable = amount;
    }
}

