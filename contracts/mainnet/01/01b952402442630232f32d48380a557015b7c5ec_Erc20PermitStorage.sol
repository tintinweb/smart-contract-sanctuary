/* SPDX-License-Identifier: MIT */
/* solhint-disable var-name-mixedcase */
pragma solidity ^0.7.0;

/**
 * @notice Erc20PermitStorage
 * @author Paul Razvan Berg
 */
abstract contract Erc20PermitStorage {
    /**
     * @notice The Eip712 domain's keccak256 hash.
     */
    bytes32 public DOMAIN_SEPARATOR;

    /**
     * @notice keccak256("Permit(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)");
     */
    bytes32 public constant PERMIT_TYPEHASH = 0xfc77c2b9d30fe91687fd39abb7d16fcdfe1472d065740051ab8b13e4bf4a617f;

    /**
     * @notice Provides replay protection.
     */
    mapping(address => uint256) public nonces;

    /**
     * @notice Eip712 version of this implementation.
     */
    string public constant version = "1";
}
