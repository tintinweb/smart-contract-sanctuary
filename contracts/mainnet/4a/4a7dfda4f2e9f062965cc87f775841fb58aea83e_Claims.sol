/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.5;

// @notice Used to create Radicle Link identity claims
contract Claims {
    /// @notice Emitted on every Radicle Link identity claim
    /// @param addr The account address which made the claim
    event Claimed(address indexed addr);

    /// @notice Creates a new claim of a Radicle Link identity.
    /// Every new claim invalidates previous ones made with the same account.
    /// The claims have no expiration date and don't need to be renewed.
    /// If either `format` is unsupported or `payload` is malformed as per `format`,
    /// the previous claim is revoked, but a new one isn't created.
    /// Don't send a malformed transactions on purpose, to properly revoke a claim see `format`.
    /// @param format The format of `payload`, currently supported values:
    /// - `1` - `payload` is exactly 20 bytes and contains an SHA-1 Radicle Identity root hash
    /// - `2` - `payload` is exactly 32 bytes and contains an SHA-256 Radicle Identity root hash
    /// To revoke a claim without creating a new one, pass payload `0`,
    /// which is guaranteed to not match any existing identity.
    /// @param payload The claim payload
    function claim(uint256 format, bytes calldata payload) public {
        format;
        payload;
        emit Claimed(msg.sender);
    }
}