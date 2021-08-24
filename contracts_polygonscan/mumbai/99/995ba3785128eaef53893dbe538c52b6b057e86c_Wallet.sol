/**
 *Submitted for verification at polygonscan.com on 2021-08-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// # Version
//
// This is version 2 of the Telcoin wallet contract.
//
// # Entrypoints
//
// This contract directly exposes 4 functions:
// - isOwner(address) *read-only*
// - state() *read-only*
// - execute(uint256,address,uint256,bytes,uint8,bytes32,bytes32,uint8,bytes32,bytes32)
// - transferErc20(uint256,address,address,uint256,uint256,address,uint256,uint256,address,uint8,bytes32,bytes32,uint8,bytes32,bytes32,uint8,bytes32,bytes32)
//
// It also indirectly exposes 3 other functions that can only be called by using execute():
// - addOwner(address)
// - removeOwner(address)
// - replaceGatekeeper(address,address)
//
// # Naming conventions
//
// Variables:
// - Data sent by the user is named starting with one underscore.
//   Example: `_gatekeeper`
// - Internal data or data coming from the contract storage is named without prefix.
//   Example: `state`
//
// Functions:
// - Private functions are named starting with two underscores.
//   Example: `__ecrecover`
// - Externally callable functions are named without prefix.
//   Example: `isOwner`
//
// # ABI
//
// Even though this contract uses assembly to implement method calls manually, it uses the
// standard Solidity ABI for computing method signatures and passing arguments.
//
// # Storage
//
// Storage slot 0 is used to store the wallet state. By construction, its value should always be >3.
// Storage slots N != 0 are used to mark the address N as:
// - owner if the value is 1
// - gatekeeper if the value is 3
//
// # Gatekeepers and owners
//
// If the contract is constructed with a valid state, then there will always be 2 and exactly 2
// different gatekeepers. Usually one of them with be controlled by the user's operator, and the
// other will be controlled by Telcoin.
//
// At the same time, there can be any number of owners, with the expectation that there will be at
// least one in most cases.
//
// An address can never be owner and gatekeeper at the same time.
//
// All operations need to be signed by at least one gatekeeper, and either the other gatekeeper or
// an owner. Normal operations should be signed by one gatekeeper and one owner, but in case where
// there is no valid owner (like an account recovery operation), the 2 gatekeepers can be used to
// sign operations.
//
// # State
//
// State is stored in one 256 bit word, encoded as:
// ----------------------------------------------------------------------
// | wallet id | reserved |  slot 9 |  slot 8 | ... |  slot 1 |  slot 0 |
// |  64 bits  |  12 bits | 18 bits | 18 bits | ... | 18 bits | 18 bits |
// ----------------------------------------------------------------------
//
// The top 64+12==76 bits should uniquely identify this wallet instance among all other deployed
// instances in all networks.
//
// Note that for the various checks to work, it is necessary that state > 3. Hence it is required
// that new wallets are deployed with at least one of "wallet id" or "reserved" being non-zero.
//
// # Identifiers
//
// State-modifying operations execute() and transferErc20() both take a 256 bit identifier
// encoded as:
// -----------------------------------------------------------
// | wallet id | reserved |  expiry  |  nonce  | slot number |
// |  64 bits  |  12 bits | 154 bits | 18 bits |    8 bits   |
// -----------------------------------------------------------
//
// To be valid, this identifier must satisfy all the following conditions:
// 1. The identifier wallet id must match the state wallet id, and the identifier reserved bits must
//    match the state reserved bits.
// 2. The identifier nonce must be strictly greater than the value of the slot in the state
//    corresponding to the identifier slot number. (For example, if `identifier.nonce` == 20 and
//    `identifier.slotNumber` == 3, then `state.slot[3]` must be < 20.)
// 3. The expiry timestamp must not be lower than the block's timestamp.
//
// After the operation is executed, the corresponding state's slot value will be modified to be
// that of the value of the identifier.
//
// The first condition ensure that signed operations can only be executed against this very
// specific wallet instance, even if the same contract is deployed at the same address with the
// same owners & gatekeepers on a different blockchain. In a way, it serves a similar role to
// the chain id in EIP155 transactions.
//
// The second condition ensure that signed operations can be executed **only once** against this
// wallet instance, while still keeping the option to have 10 different signed operations valid at
// the same point in time (which is important since our operations can be executed quite long after
// they are signed).

/// @title Telcoin Wallet v1
/// @author Telcoin
contract Wallet is Initializable {
    /// @notice Construct a new wallet.
    ///
    /// @dev Does not check the validity of arguments.
    ///
    /// @param _state uint256 Initial state of the wallet.
    /// @param _gatekeeperA address First gatekeeper.
    /// @param _gatekeeperB address Second gatekeeper.
    /// @param _owner address Initial owner.
    function initialize(
        uint256 _state,
        address _gatekeeperA,
        address _gatekeeperB,
        address _owner
    ) public payable initializer() {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // The constructor does not check the validity of its arguments. It is up to the
            // deployer of the contract to construct one with a valid state.
            //
            // In particular, the following should hold true for the initial state of the contract
            // to be valid:
            // (1) _gatekeeperA != 0
            // (2) _gatekeeperB != 0
            // (3) _gatekeeperA != _gatekeeperB != _owner
            // (4) _gatekeeperA, gatekeeperB and _owner should be 160 bit addresses with the higher
            //      96 bits set to zero
            // (5) _state higher 76 bits should be non-zero, and different from all the other
            //     deployments of the wallet
            // (6) _state lower 180 bits should be non-all-ones (and preferably all zeroes)
            //
            // We order the operations this way to explicitly support the case where _owner == 0,
            // which will result in a wallet deployed without any owner. This is a valid state for
            // the wallet, even though of course we probably want to add an owner before doing any
            // execute() or transferErc20() operation on it.

            sstore(_owner, 1) // 1 signifies an owner.
            sstore(0, _state) // The 0th slot always contains the state.
            sstore(_gatekeeperA, 3) // 3 signifies a gatekeeper.
            sstore(_gatekeeperB, 3) // 3 signifies a gatekeeper.
        }
    }

    /// @notice Dispatch to one of the functions defined in the contract.
    ///
    /// @dev Uses the first 4 bytes of calldata (encoded as Solidity ABI) to select the target
    /// function.
    fallback () external payable {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // Operations are sorted such that most common operations are at
            // the top, to make sure they don't waste gas. Read-only
            // operations are placed last as they're free to call anyway.
            switch div(calldataload(0), exp(2, 224))
            case 0xf063042d /* bytes4(keccak256("transferErc20(uint256,address,address,uint256,uint256,address,uint256,uint256,address,uint8,bytes32,bytes32,uint8,bytes32,bytes32,uint8,bytes32,bytes32)")) */ {
                transferErc20()
                stop()
            }
            case 0x9d55b53f /* bytes4(keccak256("execute(uint256,address,uint256,bytes,uint8,bytes32,bytes32,uint8,bytes32,bytes32)")) */ {
                execute()
                stop()
            }
            case 0x7065cb48 /* bytes4(keccak256("addOwner(address)")) */ {
                addOwner()
                stop()
            }
            case 0x173825d9 /* bytes4(keccak256("removeOwner(address)")) */ {
                removeOwner()
                stop()
            }
            case 0x7fb372b0 /* bytes4(keccak256("replaceGatekeeper(address,address)")) */ {
                replaceGatekeeper()
                stop()
            }
            case 0x2f54bf6e /* bytes4(keccak256("isOwner(address)")) */ {
                isOwner()
                stop()
            }
            case 0xc19d93fb /* bytes4(keccak256("state()")) */ {
                state()
                stop()
            }
            default {
                // We stop the transaction here and accept any ETH that was passed in.
                stop()
            }

            // ================= END OF function() =================

            /// This function should only be called with the understanding that
            /// it's going to use the lowest 4 memory slots. The caller should
            /// not store its own state in those slots.
            function __ecrecover(h, v, r, s) -> a {
                // The builtin ecrecover() function is stored in a builtin contract deployed at
                // address 0x1, with a gas cost hard-coded to 3000 Gas. It expects to be passed
                // exactly 4 words:
                // (offset 0x00) keccak256 hash of the signed data
                // (offset 0x20) v value of the ECDSA signature, with v==27 or v==28
                // (offset 0x40) r value of the ECDSA signature
                // (offset 0x60) s value of the ECDSA signature

                // Since we will receive signatures with v values of 0 or 1, we can unconditionally
                // add 27 to transform them into the format expected by ecrecover().
                v := add(v, 27)

                mstore(0, h)
                mstore(0x20, v)
                mstore(0x40, r)
                mstore(0x60, s)

                // Instead of sending 3000 == 0x0bb8 Gas, we will send a little more with 0x0c00
                // since this will have the same result and save us some Gas when deploying the
                // contract (0x00 bytes are cheaper to deploy).
                if iszero(staticcall(0x0c00, 0x1, 0, 0x80, 0, 0x20)) {
                    invalid()
                }

                a := mload(0)
            }

            /// Verifies and updates the wallet state based on a user-provided identifier.
            ///
            /// See the top level documentation for the format of the state and the identifier.
            ///
            /// This will either succeed and update the wallet state with the new nonce, or
            /// stop the execution.
            function __verifyAndUpdateState(_identifier) {
                let _state := sload(0)

                // Mask to check that the the top 76 bits of the _state and of the identifier are
                // equal.
                //
                // It's cheaper to construct the mask than a constant. Since shift instructions are
                // not available yet in mainnet, we use multiplications and divisions to achieve
                // the same effect.
                //
                // Value is 0b11..1100..00 ie. 76 ones followed by 180 zeroes
                let mask := mul(not(0), exp(2, 180))

                // Slot number stored in the identifier.
                let slot := and(_identifier, 0xFF)

                // Shift that allows to read/write in this slot.
                let shift := exp(2, mul(slot, 18))

                // New value of the nonce present in the identifier.
                // Old version of the nonce present in the current _state.
                //
                // Both nonces are shifted to the left by (18 * slot).
                //
                // Note that 0x3FFFF is 18 bits all set to 1, which is the mask for a slot content.
                let newNonce := mul(and(div(_identifier, 0x100), 0x3FFFF), shift)
                let oldNonce := and(_state, mul(0x3FFFF, shift))

                // Invalid if:
                //   `(_state & mask) != (_identifier & mask)
                //    || slot > 9
                //    || newNonce <= oldNonce
                //    || timestamp() > (!mask & _identifier) >> 26)`
                if or(or(or(
                    // The initial 76 bits of the identifier must match those of
                    // the wallet _state.
                    iszero(eq(and(_state, mask), and(_identifier, mask))),

                    // Though a full byte is used to encode the slot number, only 10 slots
                    // (numbered 0 to 9) are actually available.
                    gt(slot, 9)),

                    // The new nonce must be greater than the old nonce, but skipping
                    // individual values is fine - it's a way of invalidating pending
                    // transactions.
                    iszero(gt(newNonce, oldNonce))),

                    // Expiry is a timestamp (stored as a 154 bits) after which
                    // the transaction is no longer valid. This provides a strong
                    // guarantee to the sender that once-signed transactions do not
                    // remain valid forever.
                    //
                    // To extract expiry from the identifier, first we mask out the top 76 bits,
                    // then we shift the rest 26 bits to the right, which leaves us with only the
                    // middle 154 bits containing the expiry.
                    gt(timestamp(), div(and(not(mask), _identifier), 0x4000000))
                ) {
                    invalid()
                }

                // By substracting the correctly bit-positioned old nonce from the
                // _state, we effectively reset the nonce bits to zero. Since only
                // bits within the slot are set, it's not possible for this
                // operation to change any other bit in the _state. For the same
                // reason, adding the new nonce to the reset _state replaces the
                // old nonce while leaving the rest of the _state untouched.
                //
                // Overflow cannot happen due to both nonces being at most 18 bit values.
                _state := add(sub(_state, oldNonce), newNonce)

                sstore(0, _state)
            }

            // Safely performs an ERC20 `transfer(address,uint256)` call while ensuring
            // that legacy tokens are handled properly, too. Any error will terminate
            // execution.
            //
            /// This function should only be called with the understanding that
            /// it's going to use the lowest 3 memory slots. The caller should
            /// not store its own state in those slots.
            function __safeTransfer(_token, _beneficiary, _value) {
                // The data for this call will be 4 bytes of method signature, followed by two
                // 0x20 byte arguments. We use the lower 4 bytes of the memory word at 0x0 for
                // the method signature, since this is the most gas-effective way to store it.
                mstore(0, 0xa9059cbb) // bytes4(keccak256("transfer(address,uint256)"))
                mstore(0x20, _beneficiary)
                mstore(0x40, _value)

                // Do the call. If the call reverts, we'll bail.
                if iszero(call(gas(), _token, 0, 0x1c, 0x44, 0, 0x20)) {
                    invalid()
                }

                // Safety checks for legacy tokens.
                //
                // This is essentially a negation of:
                //   `returndatasize() == 0 || (mload(0) == 1 && returndatasize() == 0x20)`
                // turned into:
                //   `returndatasize() != 0 && (mload(0) != 1 || returndatasize() != 0x20)`
                if and(
                    // If there's no return data at all, we're interacting with a legacy token
                    // that relies on revert() (or similar) only. Let it through by having the
                    // following evaluate to false. For every other size this'll evaluate to
                    // true, letting the other branch to decide.
                    iszero(iszero(returndatasize())),

                    // If there's one word of return data, make sure that it's true. We may
                    // be dealing with a legacy token that only returns a boolean.
                    or(
                        // The only acceptable return value is true.
                        iszero(eq(mload(0), 1)),

                        // The only acceptable data size is 0x20.
                        iszero(eq(returndatasize(), 0x20))
                    )
                ) {
                    invalid()
                }
            }

            /// @notice Check if a given address is an owner of this wallet.
            ///
            /// @param _address address The address to check.
            ///
            /// @return uint256 1 if the address is an owner, 0 otherwise.
            function isOwner() {
                let _address := calldataload(0x4)

                // Only a non-zero address can be an owner. However, we don't need to check that
                // _address != 0 since if that's the case, we would load storage at 0x0 which is
                // the wallet state which can never have value 1 anyway.

                mstore(0, eq(sload(_address), 1)) // 1 signifies an owner.
                return(0, 0x20)
            }

            /// @notice Add a new owner to the wallet.
            ///
            /// @dev This cannot be called directly. You must call through execute().
            ///
            /// @param _owner address The address to add as owner.
            function addOwner() {
                let _owner := calldataload(0x4)

                // Invalid if:
                //   `caller() != address() || state[_owner] != 0`
                if or(
                    // Checks whether the currently executing code was called by the
                    // contract itself, and reverts if that's not the case.
                    iszero(eq(caller(), address())),

                    // _owner must not have any previous role (i.e. owner or gatekeeper).
                    //
                    // Note that if _owner == 0 this will always trip since state is
                    // guaranteed to be >3.
                    iszero(eq(sload(_owner), 0))
                ) {
                    invalid()
                }

                sstore(_owner, 1) // 1 signifies an owner.

                stop()
            }

            /// @notice Remove an existing owner from the wallet.
            ///
            /// @dev This cannot be called directly. You must call through execute().
            ///
            /// @dev This could leave the wallet with no owner. In this case, both gatekeepers will
            /// be required to sign further operations.
            ///
            /// @param _owner address The address to remove from owners.
            function removeOwner() {
                let _owner := calldataload(0x4)

                // Invalid if:
                //   `caller() != address() || state[_owner] != 1`
                if or(
                    // Checks whether the currently executing code was called by the
                    // contract itself, and reverts if that's not the case.
                    iszero(eq(caller(), address())),

                    // _owner must currently be an owner.
                    //
                    // Note that if _owner == 0 this will always trip since state is
                    // guaranteed to be >3.
                    iszero(eq(sload(_owner), 1))
                ) {
                    invalid()
                }

                sstore(_owner, 0) // Delete the mapping.

                stop()
            }

            /// @notice Replace a gatekeeper with another address.
            ///
            /// @dev This cannot be called directly. You must call through execute().
            ///
            /// @dev This will always leave the wallet with two different valid gatekeepers.
            ///
            /// @param _old address The address to remove from gatekeepers.
            /// @param _new address The address to add to gatekeepers.
            function replaceGatekeeper() {
                let _old := calldataload(0x4)
                let _new := calldataload(0x24)

                // Invalid if:
                //   `caller() != address() || state[_old] != 3 || state[_new] != 0`
                if or(or(
                    // Checks whether the currently executing code was called by the
                    // contract itself, and reverts if that's not the case.
                    iszero(eq(caller(), address())),

                    // _old must currently be a gatekeeper.
                    //
                    // Note that if _old == 0 this will always trip since state is
                    // guaranteed to be >3.
                    iszero(eq(sload(_old), 3))),

                    // _new must not have any previous role (i.e. owner or gatekeeper).
                    //
                    // Note that if _new == 0 this will always trip since state is
                    // guaranteed to be >3.
                    iszero(eq(sload(_new), 0)
                )) {
                    invalid()
                }

                // Note that at this point we are guaranteed that _old != _new since we could
                // not have both storage[_old] == 3 and storage[_new] == 0 at the same time.

                sstore(_old, 0) // Delete the old mapping.
                sstore(_new, 3) // Add the new mapping.

                stop()
            }

            /// @notice Executes a simple, inflexible multi-signed transaction.
            ///
            /// @dev The first signer can be an owner or a gatekeeper; the second signer must be a
            /// gatekeeper.
            ///
            /// @param _identifier uint256 A valid transaction identifier.
            /// @param _destination address The destination to call.
            /// @param _value uint256 The ETH value to include in the call.
            /// @param _data bytes The data to include in the call.
            /// @param _sig1V uint8 Part `v` of the first signer's signature.
            /// @param _sig1R bytes32 Part `r` of the first signer's signature.
            /// @param _sig1S bytes32 Part `s` of the first signer's signature.
            /// @param _sig2V uint8 Part `v` of the second signer's signature.
            /// @param _sig2R bytes32 Part `r` of the second signer's signature.
            /// @param _sig2S bytes32 Part `s` of the second signer's signature.
            function execute() {
                // When executing this function, the calldata is intended to be:
                //
                //   start | description                   | length in bytes
                // --------+-------------------------------+------------------
                //   0x00  | Method signature              | 0x4
                //   0x04  | _identifier                   | 0x20
                //   0x24  | _destination                  | 0x20
                //   0x44  | _value                        | 0x20
                //   0x64  | _dataOffset                   | 0x20
                //   0x84  | _sig1V                        | 0x20
                //   0xa4  | _sig1R                        | 0x20
                //   0xc4  | _sig1S                        | 0x20
                //   0xe4  | _sig2V                        | 0x20
                //   0x104 | _sig2R                        | 0x20
                //   0x124 | _sig2S                        | 0x20
                //   0x144 | _dataLength                   | 0x20
                //   0x164 | _data                         | _dataLength
                //
                // We will copy these in memory using the following layout:
                //
                //   start | description                   | length in bytes
                // --------+-------------------------------+------------------
                //   0x00  | Scratch space for __ecrecover | 0x80
                //   0x80  | EIP191 prefix 0x1900          | 0x2          \
                //   0x82  | EIP191 address                | 0x20         |
                //   0xa2  | _methodSignature              | 0x4          |
                //   0xa6  | _identifier                   | 0x20         | sig1 & sig2
                //   0xc6  | _destination                  | 0x20         |
                //   0xe6  | _value                        | 0x20         |
                //   0x106 | _data                         | _dataLength  /
                //
                // This memory layout is set up so that we can hash all the operation data directly.
                //
                // Note that the hash includes the method signature itself, so that a blob signed
                // for execute() cannot be used for transferErc20(), or the opposite.
                //
                // Note that the hash also includes the wallet address() so that an operation signed
                // for this wallet cannot be applied to another wallet that would happen to have the
                // same owners/gatekeepers.

                let _dataOffset := calldataload(0x64)
                let _dataLength := calldataload(0x144)
                // Invalid if:
                //   `_dataOffset != 0x140 || _dataLength > 0xffff`
                if or(
                    // _dataLength should always be 0x140 bytes after the first parameter.
                    // Make sure this is the case.
                    iszero(eq(0x140, _dataOffset)),

                    // Limit data length to a reasonable size so that
                    // we don't have to worry about overflow later.
                    gt(_dataLength, 0xffff)
                ) {
                    invalid()
                }

                // Set up EIP191 prefix.
                mstore8(0x80, 0x19)
                mstore8(0x81, 0x00)
                mstore(0x82, address())

                // Copy method signature + _identifier + _destination + _value to memory.
                calldatacopy(0xa2, 0, 0x64)

                // Copy _data (without offset or length) after that.
                calldatacopy(0x106, 0x164, _dataLength)

                // Hash all user data except the signatures.
                //
                // The second argument cannot overflow due to an
                // earlier check limiting the maximum value of the
                // length variable.
                let hash := keccak256(0x80, add(0x86, _dataLength))

                // First signature.
                let _sigV := calldataload(0x84)
                let _sigR := calldataload(0xa4)
                let _sigS := calldataload(0xc4)

                // Recover the first signer. Calling this function
                // is going to overwrite the first 4 memory slots,
                // but we haven't stored anything there.
                let signer := __ecrecover(hash, _sigV, _sigR, _sigS)

                // Invalid if:
                //   `signer == 0 || state[signer] == 0`
                if or(
                    // The first signer should not be zero.
                    iszero(signer),

                    // The first signer must be an owner or a gatekeeper.
                    //
                    // Since we know that `signer != 0` at this point, we know that `sload(signer)`
                    // cannot be the state, and thus it can only be 0, 1 or 3 depending on
                    // the role of `signer`.
                    iszero(sload(signer))
                ) {
                    invalid()
                }

                // Second signature. Reuse variables to avoid stack depth issues.
                _sigV := calldataload(0xe4)
                _sigR := calldataload(0x104)
                _sigS := calldataload(0x124)

                // Recover the second signer.
                signer := __ecrecover(hash, _sigV, _sigR, _sigS)

                // Invalid if:
                //   `signer == 0 || state[signer] != 3`
                if or(
                    // The second signer should not be zero.
                    iszero(signer),

                    // The second signer must be a gatekeeper.
                    //
                    // Since we know that `signer != 0` at this point, we know that `sload(signer)`
                    // cannot be the state, and thus it can only be 0, 1 or 3 depending on
                    // the role of `signer`.
                    iszero(eq(sload(signer), 3))
                ) {
                    invalid()
                }

                // Now make sure the nonce is valid, and consume it if that's the case.
                let _identifier := calldataload(0x4)
                __verifyAndUpdateState(_identifier)

                // Finally, run the call, passing the _destination, _value and _data that we
                // have verified.
                let _destination := calldataload(0x24)
                let _value := calldataload(0x44)
                if iszero(call(gas(), _destination, _value, 0x106, _dataLength, 0, 0)) {
                    invalid()
                }

                stop()
            }

            /// @notice Executes a flexible ERC20 transfer. Use execute() for other types of
            /// transactions.
            ///
            /// @dev The first signer can be an owner or a gatekeeper; the second signer must be a
            /// gatekeeper.
            ///
            /// @dev This transfer can be forwarded by the beneficiary, in which case this will be
            /// signed by an owner of the **receiving** wallet too.
            ///
            /// @param _identifier uint256 A valid transaction identifier.
            /// @param _token address The token address.
            /// @param _beneficiary address The intended beneficiary of the transfer from the
            /// sender's point of view.
            /// @param _limit uint256 The upper limit of the transfer, chosen by the first signer.
            /// Up to this many tokens may be sent.
            /// @param _feeLimit uint256 The upper limit of fees, chosen by the first signer.
            /// Up to this much can be taken as a fee.
            /// @param _forward1 address The address to forward the transfer to, if any, chosen by
            /// the intended beneficiary.
            /// @param _value uint256 The actual number of tokens to be sent, chosen by the second
            /// signer.
            /// @param _fee uint256 The actual fee, chosen by the second signer.
            /// @param _feeRecipient address The recipient of the fee, chosen by the second signer.
            /// @param _sig1V uint8 Part `v` of the first signer's signature.
            /// @param _sig1R bytes32 Part `r` of the first signer's signature.
            /// @param _sig1S bytes32 Part `s` of the first signer's signature.
            /// @param _forward1V uint8 Part `v` of the forwarder's signature.
            /// Ignored if _forward1 == 0.
            /// @param _forward1R bytes32 Part `r` of the forwarder's signature.
            /// Ignored if _forward1 == 0.
            /// @param _forward1S bytes32 Part `s` of the forwarder's signature.
            /// Ignored if _forward1 == 0.
            /// @param _sig2V uint8 Part `v` of the second signer's signature.
            /// @param _sig2R bytes32 Part `r` of the second signer's signature.
            /// @param _sig2S bytes32 Part `s` of the second signer's signature.
            function transferErc20() {
                // When executing this function, the calldata is intended to be:
                //
                //   start | description                   | length in bytes
                // --------+-------------------------------+------------------
                //   0x00  | Method signature              | 0x4
                //   0x04  | _identifier                   | 0x20
                //   0x24  | _token                        | 0x20
                //   0x44  | _beneficiary                  | 0x20
                //   0x64  | _limit                        | 0x20
                //   0x84  | _feeLimit                     | 0x20
                //   0xa4  | _forward1                     | 0x20
                //   0xc4  | _value                        | 0x20
                //   0xe4  | _fee                          | 0x20
                //   0x104 | _feeRecipient                 | 0x20
                //   0x124 | _sig1V                        | 0x20
                //   0x144 | _sig1R                        | 0x20
                //   0x164 | _sig1S                        | 0x20
                //   0x184 | _forward1V                    | 0x20
                //   0x1a4 | _forward1R                    | 0x20
                //   0x1c4 | _forward1S                    | 0x20
                //   0x1e4 | _sig2V                        | 0x20
                //   0x204 | _sig2R                        | 0x20
                //   0x224 | _sig2S                        | 0x20
                //
                // We will copy these in memory using the following layout:
                //
                //   start | description                   | length in bytes
                // --------+-------------------------------+------------------
                //   0x00  | Scratch space                 | 0x80
                //   0x80  | EIP191 prefix 0x1900          | 0x2   \      \      \
                //   0x82  | EIP191 address                | 0x20  |      |      |
                //   0xa2  | _methodSignature              | 0x4   |      |      |
                //   0xa6  | _identifier                   | 0x20  | sig1 |      |
                //   0xc6  | _token                        | 0x20  |      | sig2 | forward
                //   0xe6  | _beneficiary                  | 0x20  |      |      |
                //   0x106 | _limit                        | 0x20  |      |      |
                //   0x126 | _feeLimit                     | 0x20  /      |      |
                //   0x146 | _forward1                     | 0x20         |      /
                //   0x166 | _value                        | 0x20         |
                //   0x186 | _fee                          | 0x20         |
                //   0x1a6 | _feeRecipient                 | 0x20         /
                //
                // This memory layout is set up so that we can hash all the operation data directly.
                //
                // Note that the hash includes the method signature itself, so that a blob signed
                // for execute() cannot be used for transferErc20(), or the opposite.
                //
                // Note that the hash also includes the wallet address() so that an operation signed
                // for this wallet cannot be applied to another wallet that would happen to have the
                // same owners/gatekeepers.

                // Set up EIP191 prefix.
                mstore8(0x80, 0x19)
                mstore8(0x81, 0x00)
                mstore(0x82, address())

                // Follow with calldata.
                calldatacopy(0xa2, 0, 0x124) // 9x 0x20 byte arguments + the 4 byte method signature.

                // Hash user data up to _feeLimit (included)
                let hash := keccak256(0x80, 0xc6)
                let _sigV := calldataload(0x124)
                let _sigR := calldataload(0x144)
                let _sigS := calldataload(0x164)

                // Recover the first signer. Calling this function
                // is going to overwrite the first 4 memory slots,
                // but we haven't stored anything there.
                let signer := __ecrecover(hash, _sigV, _sigR, _sigS)

                // Invalid if:
                //   `signer == 0 || state[signer] == 0`
                if or(
                    // The first signer should not be zero.
                    iszero(signer),

                    // The first signer must be an owner or a gatekeeper.
                    //
                    // Since we know that `signer != 0` at this point, we know that `sload(signer)`
                    // cannot be the state, and thus it can only be 0, 1 or 3 depending on
                    // the role of `signer`.
                    iszero(sload(signer))
                ) {
                    invalid()
                }

                // Now re-hash user data up to _feeRecipient (included)
                // We reuse variables to avoid stack depth issues.
                hash := keccak256(0x80, 0x146)
                _sigV := calldataload(0x1e4)
                _sigR := calldataload(0x204)
                _sigS := calldataload(0x224)

                // Recover the second signer.
                signer := __ecrecover(hash, _sigV, _sigR, _sigS)

                // Invalid if:
                //   `signer == 0 || state[signer] != 3`
                if or(
                    // The second signer should not be zero.
                    iszero(signer),

                    // The second signer must be a gatekeeper.
                    //
                    // Since we know that `signer != 0` at this point, we know that `sload(signer)`
                    // cannot be the state, and thus it can only be 0, 1 or 3 depending on
                    // the role of `signer`.
                    iszero(eq(sload(signer), 3))
                ) {
                    invalid()
                }

                // Now make sure the nonce is valid.
                // We do that BEFORE maybe calling the _beneficiary contract's isOwner(address)
                // in order to avoid re-entrancy issues.
                let _identifier := calldataload(0x4)
                __verifyAndUpdateState(_identifier)

                let _beneficiary := calldataload(0x44)
                let _forward1 := calldataload(0xa4)
                if _forward1 {
                    // Now re-re-hash user data up to _forward1 (included)
                    // We reuse variables to avoid stack depth issues.
                    hash := keccak256(0x80, 0xe6)
                    _sigV := calldataload(0x184)
                    _sigR := calldataload(0x1a4)
                    _sigS := calldataload(0x1c4)

                    // Recover the forward signer.
                    signer := __ecrecover(hash, _sigV, _sigR, _sigS)

                    // The forward signer must be an owner of the beneficiary wallet.
                    //
                    // We use the memory scratch space here, but it's ok since we no longer
                    // use `__ecrecover()` at this point.
                    mstore(0, 0x2f54bf6e) // bytes4(keccak256("isOwner(address)"))
                    mstore(0x20, signer)

                    // Call `isOwner(address)` on the beneficiary wallet.
                    // We use `staticcall()` to ensure we have no side effects from this call.
                    if iszero(staticcall(gas(), _beneficiary, 0x1c, 0x24, 0, 0x20)) {
                        invalid()
                    }

                    // Stop if the signer wasn't an owner. Note that even if no value was
                    // returned, the memory slot at 0 will still contain its original data,
                    // the method signature, which will also trip this check.
                    if iszero(eq(1, mload(0))) {
                        invalid()
                    }

                    // At this point we know the signer is an owner, so can
                    // safely change the beneficiary to the stated address.
                    _beneficiary := _forward1
                }

                // Only up to the originally chosen limit can be transferred.
                let _value := calldataload(0xc4)
                let _limit := calldataload(0x64)
                if gt(_value, _limit) {
                    invalid()
                }

                // Finally, run the call. If the call reverts, we'll bail.
                let _token := calldataload(0x24)
                __safeTransfer(_token, _beneficiary, _value)

                // Only up to the originally chosen fee can be taken.
                let _fee := calldataload(0xe4)
                let _feeLimit := calldataload(0x84)
                if gt(_fee, _feeLimit) {
                    invalid()
                }

                if _fee {
                    let _feeRecipient := calldataload(0x104)
                    __safeTransfer(_token, _feeRecipient, _fee)
                }

                // We're good.
                stop()
            }

            /// @notice Get the current state of the wallet.
            ///
            /// @return uint256 State of the wallet.
            function state() {
                mstore(0, sload(0))
                return(0, 0x20)
            }
        }
    }

    receive() external payable {}
}