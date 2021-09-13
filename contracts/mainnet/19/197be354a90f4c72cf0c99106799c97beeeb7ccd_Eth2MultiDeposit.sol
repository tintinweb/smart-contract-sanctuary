/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// built by @nanexcool for his OCD friend
pragma solidity ^0.8.6;

interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;
}

contract Eth2MultiDeposit {
    IDepositContract constant dc =
        IDepositContract(0x00000000219ab540356cBB839Cbe05303d7705Fa);

    function deposit(
        bytes[] calldata pubkey,
        bytes[] calldata withdrawal_credentials,
        bytes[] calldata signature,
        bytes32[] calldata deposit_data_root
    ) external payable {
        unchecked {
            for (uint256 i = 0; i < pubkey.length; i++) {
                dc.deposit{value: 32 ether}(
                    pubkey[i],
                    withdrawal_credentials[i],
                    signature[i],
                    deposit_data_root[i]
                );
            }
        }
    }
}