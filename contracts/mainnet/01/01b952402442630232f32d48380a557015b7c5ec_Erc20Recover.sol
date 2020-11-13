/* SPDX-License-Identifier: MIT */
pragma solidity ^0.7.0;

import "./Admin.sol";
import "./Erc20Interface.sol";
import "./Erc20RecoverInterface.sol";
import "./SafeErc20.sol";

/**
 * @title Erc20Recover
 * @author Paul Razvan Berg
 * @notice Gives the administrator the ability to recover the Erc20 tokens that
 * had been sent (accidentally, or not) to the contract.
 */
abstract contract Erc20Recover is
    Erc20RecoverInterface, /* one dependency */
    Admin /* two dependencies */
{
    using SafeErc20 for Erc20Interface;

    /**
     * @notice Sets the tokens that this contract cannot recover.
     *
     * @dev Emits a {SetNonRecoverableTokens} event.
     *
     * Requirements:
     *
     * - The caller must be the administrator.
     * - The contract must be non-initialized.
     * - The array of given tokens cannot be empty.
     *
     * @param tokens The array of tokens to set as non-recoverable.
     */
    function _setNonRecoverableTokens(Erc20Interface[] calldata tokens) external override onlyAdmin {
        /* Checks */
        require(isInitialized == false, "ERR_INITALIZED");

        /* Iterate over the token list, sanity check each and update the mapping. */
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i += 1) {
            tokens[i].symbol();
            nonRecoverableTokens.push(tokens[i]);
        }

        /* Effects: prevent this function from ever being called again. */
        isInitialized = true;

        emit SetNonRecoverableTokens(admin, tokens);
    }

    /**
     * @notice Recover Erc20 tokens sent to this contract (by accident or otherwise).
     * @dev Emits a {RecoverToken} event.
     *
     * Requirements:
     *
     * - The caller must be the administrator.
     * - The contract must be initialized.
     * - The amount to recover cannot be zero.
     * - The token to recover cannot be among the non-recoverable tokens.
     *
     * @param token The token to make the recover for.
     * @param recoverAmount The uint256 amount to recover, specified in the token's decimal system.
     */
    function _recover(Erc20Interface token, uint256 recoverAmount) external override onlyAdmin {
        /* Checks */
        require(isInitialized == true, "ERR_NOT_INITALIZED");
        require(recoverAmount > 0, "ERR_RECOVER_ZERO");

        bytes32 tokenSymbolHash = keccak256(bytes(token.symbol()));
        uint256 length = nonRecoverableTokens.length;

        /**
         * We iterate over the non-recoverable token array and check that:
         *
         *   1. The addresses of the tokens are not the same
         *   2. The symbols of the tokens are not the same
         *
         * It is true that the second check may lead to a false positive, but
         * there is no better way to fend off against proxied tokens.
         */
        for (uint256 i = 0; i < length; i += 1) {
            require(
                address(token) != address(nonRecoverableTokens[i]) &&
                    tokenSymbolHash != keccak256(bytes(nonRecoverableTokens[i].symbol())),
                "ERR_RECOVER_NON_RECOVERABLE_TOKEN"
            );
        }

        /* Interactions */
        token.safeTransfer(admin, recoverAmount);

        emit Recover(admin, token, recoverAmount);
    }
}
