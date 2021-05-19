/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// SPDX-License-Identifier: WTFPL
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

// This interface is designed to be compatible with the Vyper version.
/// @notice This is the Ethereum 2.0 deposit contract interface.
/// For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
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

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}

// Author: Sylvain Laurent
// Use Scribble https://docs.scribble.codes/tool/cli-usage#emitting-a-flat-instrumented-file to generate guards / arm the contract

contract BatchDeposit is IDepositContract {
    IDepositContract public deposit_contract;

    // https://github.com/ethereum/eth2.0-specs/blob/dev/specs/phase0/beacon-chain.md#gwei-values
    uint256 constant MAX_EFFECTIVE_DEPOSIT_AMOUNT = 32 ether;

    // Prevent transaction creation with gas usage too close to block gas limit
    uint256 constant MAX_VALIDATORS_VARIABLE = 100; // TODO Adjust to aims for 75% of block gas limit
    uint256 constant MAX_VALIDATORS = 100; // TODO Adjust to aims for 75% of block gas limit

    /// @notice Deploy a contract tied to selected deposit contract.
    /// @param _deposit_contract A deposit contract address (see IDepositContract).
    constructor(address _deposit_contract) public {
        // Network contract address
        // Mainnet 0x00000000219ab540356cbb839cbe05303d7705fa @chain id:1
        // Pyrmont 0x28aa7D30eb27b8955930beE3bC72255ab6a574D9 @chain id:5
        deposit_contract = IDepositContract(_deposit_contract);
    }

    /// @notice Submit multiple Phase 0 DepositData object with variable amount per deposit.
    /// @param pubkeys An array of BLS12-381 public key.
    /// @param withdrawal_credentials An array of commitment to public keys for withdrawals.
    /// @param signatures An array of BLS12-381 signature.
    /// @param deposit_data_roots An array of SHA-256 hash of the SSZ-encoded DepositData object.
    /// @param amounts An array of amount, must be above or equal 1 eth.
    /// Used as a protection against malformed input.
    /// if_succeeds {:msg "number of input elements too important"} old(pubkeys.length) <= MAX_VALIDATORS_VARIABLE;
    /// if_succeeds {:msg "number of withdrawal_credentials mismatch the number of public keys"} old(pubkeys.length) <= old(withdrawal_credentials.length);
    /// if_succeeds {:msg "number of signatures mismatch the number of public keys"} old(pubkeys.length) <= old(signatures.length);
    /// if_succeeds {:msg "number of amounts mismatch the number of public keys"} old(pubkeys.length) <= old(amounts.length);
    /// if_succeeds {:msg "number of deposit_data_roots mismatch the number of public keys"} old(pubkeys.length) <= old(deposit_data_roots.length);
    /// if_succeeds {:msg "supplied ether value mismatch the total deposited sum"} deposited_amount == msg.value;
    function batchDepositVariable(
        bytes[] calldata pubkeys,
        bytes[] calldata withdrawal_credentials,
        bytes[] calldata signatures,
        bytes32[] calldata deposit_data_roots,
        uint64[] calldata amounts
    ) external payable returns (uint256 deposited_amount) {
        require(
            pubkeys.length <= MAX_VALIDATORS_VARIABLE,
            "number of input elements too important"
        );
        require(
            pubkeys.length == withdrawal_credentials.length,
            "number of withdrawal_credentials mismatch the number of public keys"
        );
        require(
            pubkeys.length == signatures.length,
            "number of signatures mismatch the number of public keys"
        );
        require(
            pubkeys.length == amounts.length,
            "number of amounts mismatch the number of public keys"
        );
        require(
            pubkeys.length == deposit_data_roots.length,
            "number of deposit_data_roots mismatch the number of public keys"
        );

        for (uint256 i = 0; i < pubkeys.length; i++) {
            uint256 amount = uint256(amounts[i]) * 1 gwei;
            deposit_contract.deposit{value: amount}(
                pubkeys[i],
                withdrawal_credentials[i],
                signatures[i],
                deposit_data_roots[i]
            );
            deposited_amount += amount;
        }
        require(
            msg.value == deposited_amount,
            "supplied ether value mismatch the total deposited sum"
        );
    }

    /// @notice Submit multiple Phase 0 DepositData object with a fixed 32 eth amount.
    /// @param pubkeys An array of BLS12-381 public key.
    /// @param withdrawal_credentials An array of commitment to public keys for withdrawals.
    /// @param signatures An array of BLS12-381 signature.
    /// @param deposit_data_roots An array of SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    /// if_succeeds {:msg "number of input elements too important"} old(pubkeys.length) <= MAX_VALIDATORS_VARIABLE;
    /// if_succeeds {:msg "number of withdrawal_credentials mismatch the number of public keys"} old(pubkeys.length) <= old(withdrawal_credentials.length);
    /// if_succeeds {:msg "number of signatures mismatch the number of public keys"} old(pubkeys.length) <= old(signatures.length);
    /// if_succeeds {:msg "number of deposit_data_roots mismatch the number of public keys"} old(pubkeys.length) <= old(deposit_data_roots.length);
    /// if_succeeds {:msg "supplied ether value mismatch the total deposited sum"} old(pubkeys.length)*MAX_EFFECTIVE_DEPOSIT_AMOUNT == msg.value;
    function batchDeposit(
        bytes[] calldata pubkeys,
        bytes[] calldata withdrawal_credentials,
        bytes[] calldata signatures,
        bytes32[] calldata deposit_data_roots
    ) external payable {
        require(
            pubkeys.length <= MAX_VALIDATORS,
            "number of input elements too important"
        );
        require(
            pubkeys.length == withdrawal_credentials.length,
            "number of withdrawal_credentials mismatch the number of public keys"
        );
        require(
            pubkeys.length == signatures.length,
            "number of signatures mismatch the number of public keys"
        );
        require(
            pubkeys.length == deposit_data_roots.length,
            "number of deposit_data_roots mismatch the number of public keys"
        );
        require(
            pubkeys.length * MAX_EFFECTIVE_DEPOSIT_AMOUNT == msg.value,
            "supplied ether value mismatch the total deposited sum"
        );

        for (uint256 i = 0; i < pubkeys.length; i++) {
            deposit_contract.deposit{value: MAX_EFFECTIVE_DEPOSIT_AMOUNT}(
                pubkeys[i],
                withdrawal_credentials[i],
                signatures[i],
                deposit_data_roots[i]
            );
        }
    }

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
    ) external override payable {
        deposit_contract.deposit(
            pubkey,
            withdrawal_credentials,
            signature,
            deposit_data_root
        );
    }

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external override view returns (bytes32) {
        return deposit_contract.get_deposit_root();
    }

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external override view returns (bytes memory) {
        return deposit_contract.get_deposit_count();
    }
}