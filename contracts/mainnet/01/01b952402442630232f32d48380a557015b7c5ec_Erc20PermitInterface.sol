/* SPDX-License-Identifier: MIT */
/* solhint-disable var-name-mixedcase */
pragma solidity ^0.7.0;

import "./Erc20PermitStorage.sol";

/**
 * @notice Erc20PermitInterface
 * @author Paul Razvan Berg
 */
abstract contract Erc20PermitInterface is Erc20PermitStorage {
    /**
     * NON-CONSTANT FUNCTIONS
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual;
}
