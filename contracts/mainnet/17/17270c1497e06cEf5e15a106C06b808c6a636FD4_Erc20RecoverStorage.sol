/* SPDX-License-Identifier: MIT */
pragma solidity ^0.7.0;

import "./Erc20Interface.sol";

abstract contract Erc20RecoverStorage {
    /**
     * @notice The tokens that can be recovered cannot be in this mapping.
     */
    Erc20Interface[] public nonRecoverableTokens;

    /**
     * @notice A flag that signals whether the the non-recoverable tokens were set or not.
     */
    bool public isInitialized;
}
