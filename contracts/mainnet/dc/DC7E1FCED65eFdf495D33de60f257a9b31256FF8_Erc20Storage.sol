/* SPDX-License-Identifier: MIT */
pragma solidity ^0.7.0;

/**
 * @title ExponentialStorage
 * @author Paul Razvan Berg
 * @notice The storage interface ancillary to an Erc20 contract.
 */
abstract contract Erc20Storage {
    /**
     * @notice Returns the number of decimals used to get its user representation.
     */
    uint8 public decimals;

    /**
     * @notice Returns the name of the token.
     */
    string public name;

    /**
     * @notice Returns the symbol of the token, usually a shorter version of
     * the name.
     */
    string public symbol;

    /**
     * @notice Returns the amount of tokens in existence.
     */
    uint256 public totalSupply;

    mapping(address => mapping(address => uint256)) internal allowances;

    mapping(address => uint256) internal balances;
}
