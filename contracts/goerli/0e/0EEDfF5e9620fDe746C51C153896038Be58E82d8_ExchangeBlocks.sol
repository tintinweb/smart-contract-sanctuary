/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
// File: contracts/lib/AddressUtil.sol

// Copyright 2017 Loopring Technology Limited.


/// @title Utility Functions for addresses
/// @author Daniel Wang - <[email protected]>
/// @author Brecht Devos - <[email protected]>
library AddressUtil
{
    using AddressUtil for *;

    function isContract(
        address addr
        )
        internal
        view
        returns (bool)
    {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(addr) }
        return (codehash != 0x0 &&
                codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }

    function toPayable(
        address addr
        )
        internal
        pure
        returns (address payable)
    {
        return payable(addr);
    }

    // Works like address.send but with a customizable gas limit
    // Make sure your code is safe for reentrancy when using this function!
    function sendETH(
        address to,
        uint    amount,
        uint    gasLimit
        )
        internal
        returns (bool success)
    {
        if (amount == 0) {
            return true;
        }
        address payable recipient = to.toPayable();
        /* solium-disable-next-line */
        (success, ) = recipient.call{value: amount, gas: gasLimit}("");
    }

    // Works like address.transfer but with a customizable gas limit
    // Make sure your code is safe for reentrancy when using this function!
    function sendETHAndVerify(
        address to,
        uint    amount,
        uint    gasLimit
        )
        internal
        returns (bool success)
    {
        success = to.sendETH(amount, gasLimit);
        require(success, "TRANSFER_FAILURE");
    }

    // Works like call but is slightly more efficient when data
    // needs to be copied from memory to do the call.
    function fastCall(
        address to,
        uint    gasLimit,
        uint    value,
        bytes   memory data
        )
        internal
        returns (bool success, bytes memory returnData)
    {
        if (to != address(0)) {
            assembly {
                // Do the call
                success := call(gasLimit, to, value, add(data, 32), mload(data), 0, 0)
                // Copy the return data
                let size := returndatasize()
                returnData := mload(0x40)
                mstore(returnData, size)
                returndatacopy(add(returnData, 32), 0, size)
                // Update free memory pointer
                mstore(0x40, add(returnData, add(32, size)))
            }
        }
    }

    // Like fastCall, but throws when the call is unsuccessful.
    function fastCallAndVerify(
        address to,
        uint    gasLimit,
        uint    value,
        bytes   memory data
        )
        internal
        returns (bytes memory returnData)
    {
        bool success;
        (success, returnData) = fastCall(to, gasLimit, value, data);
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }
    }
}

// File: contracts/lib/MathUint.sol

// Copyright 2017 Loopring Technology Limited.


/// @title Utility Functions for uint
/// @author Daniel Wang - <[email protected]>
library MathUint
{
    using MathUint for uint;

    function mul(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b, "MUL_OVERFLOW");
    }

    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }

    function add(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }

    function add64(
        uint64 a,
        uint64 b
        )
        internal
        pure
        returns (uint64 c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }
}

// File: contracts/thirdparty/BytesUtil.sol

//Mainly taken from https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol

library BytesUtil {

    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function slice(
        bytes memory _bytes,
        uint _start,
        uint _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint _start) internal  pure returns (address) {
        require(_bytes.length >= (_start + 20));
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint _start) internal  pure returns (uint8) {
        require(_bytes.length >= (_start + 1));
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint _start) internal  pure returns (uint16) {
        require(_bytes.length >= (_start + 2));
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint24(bytes memory _bytes, uint _start) internal  pure returns (uint24) {
        require(_bytes.length >= (_start + 3));
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint _start) internal  pure returns (uint32) {
        require(_bytes.length >= (_start + 4));
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint _start) internal  pure returns (uint64) {
        require(_bytes.length >= (_start + 8));
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint _start) internal  pure returns (uint96) {
        require(_bytes.length >= (_start + 12));
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint _start) internal  pure returns (uint128) {
        require(_bytes.length >= (_start + 16));
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint _start) internal  pure returns (uint256) {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes4(bytes memory _bytes, uint _start) internal  pure returns (bytes4) {
        require(_bytes.length >= (_start + 4));
        bytes4 tempBytes4;

        assembly {
            tempBytes4 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes4;
    }

    function toBytes20(bytes memory _bytes, uint _start) internal  pure returns (bytes20) {
        require(_bytes.length >= (_start + 20));
        bytes20 tempBytes20;

        assembly {
            tempBytes20 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes20;
    }

    function toBytes32(bytes memory _bytes, uint _start) internal  pure returns (bytes32) {
        require(_bytes.length >= (_start + 32));
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }


    function toAddressUnsafe(bytes memory _bytes, uint _start) internal  pure returns (address) {
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8Unsafe(bytes memory _bytes, uint _start) internal  pure returns (uint8) {
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16Unsafe(bytes memory _bytes, uint _start) internal  pure returns (uint16) {
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint24Unsafe(bytes memory _bytes, uint _start) internal  pure returns (uint24) {
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function toUint32Unsafe(bytes memory _bytes, uint _start) internal  pure returns (uint32) {
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64Unsafe(bytes memory _bytes, uint _start) internal  pure returns (uint64) {
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96Unsafe(bytes memory _bytes, uint _start) internal  pure returns (uint96) {
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128Unsafe(bytes memory _bytes, uint _start) internal  pure returns (uint128) {
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUintUnsafe(bytes memory _bytes, uint _start) internal  pure returns (uint256) {
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes4Unsafe(bytes memory _bytes, uint _start) internal  pure returns (bytes4) {
        bytes4 tempBytes4;

        assembly {
            tempBytes4 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes4;
    }

    function toBytes20Unsafe(bytes memory _bytes, uint _start) internal  pure returns (bytes20) {
        bytes20 tempBytes20;

        assembly {
            tempBytes20 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes20;
    }

    function toBytes32Unsafe(bytes memory _bytes, uint _start) internal  pure returns (bytes32) {
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }


    function fastSHA256(
        bytes memory data
        )
        internal
        view
        returns (bytes32)
    {
        bytes32[] memory result = new bytes32[](1);
        bool success;
        assembly {
             let ptr := add(data, 32)
             success := staticcall(sub(gas(), 2000), 2, ptr, mload(data), add(result, 32), 32)
        }
        require(success, "SHA256_FAILED");
        return result[0];
    }
}

// File: contracts/core/iface/IAgentRegistry.sol

// Copyright 2017 Loopring Technology Limited.

interface IAgent{}

abstract contract IAgentRegistry
{
    /// @dev Returns whether an agent address is an agent of an account owner
    /// @param owner The account owner.
    /// @param agent The agent address
    /// @return True if the agent address is an agent for the account owner, else false
    function isAgent(
        address owner,
        address agent
        )
        external
        virtual
        view
        returns (bool);

    /// @dev Returns whether an agent address is an agent of all account owners
    /// @param owners The account owners.
    /// @param agent The agent address
    /// @return True if the agent address is an agent for the account owner, else false
    function isAgent(
        address[] calldata owners,
        address            agent
        )
        external
        virtual
        view
        returns (bool);

    /// @dev Returns whether an agent address is a universal agent.
    /// @param agent The agent address
    /// @return True if the agent address is a universal agent, else false
    function isUniversalAgent(address agent)
        public
        virtual
        view
        returns (bool);
}

// File: contracts/lib/Ownable.sol

// Copyright 2017 Loopring Technology Limited.


/// @title Ownable
/// @author Brecht Devos - <[email protected]>
/// @dev The Ownable contract has an owner address, and provides basic
///      authorization control functions, this simplifies the implementation of
///      "user permissions".
contract Ownable
{
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev The Ownable constructor sets the original `owner` of the contract
    ///      to the sender.
    constructor()
    {
        owner = msg.sender;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a
    ///      new owner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        virtual
        onlyOwner
    {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

// File: contracts/lib/Claimable.sol

// Copyright 2017 Loopring Technology Limited.



/// @title Claimable
/// @author Brecht Devos - <[email protected]>
/// @dev Extension for the Ownable contract, where the ownership needs
///      to be claimed. This allows the new owner to accept the transfer.
contract Claimable is Ownable
{
    address public pendingOwner;

    /// @dev Modifier throws if called by any account other than the pendingOwner.
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to set the pendingOwner address.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        override
        onlyOwner
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

    /// @dev Allows the pendingOwner address to finalize the transfer.
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// File: contracts/core/iface/IBlockVerifier.sol

// Copyright 2017 Loopring Technology Limited.



/// @title IBlockVerifier
/// @author Brecht Devos - <[email protected]>
abstract contract IBlockVerifier is Claimable
{
    // -- Events --

    event CircuitRegistered(
        uint8  indexed blockType,
        uint16         blockSize,
        uint8          blockVersion
    );

    event CircuitDisabled(
        uint8  indexed blockType,
        uint16         blockSize,
        uint8          blockVersion
    );

    // -- Public functions --

    /// @dev Sets the verifying key for the specified circuit.
    ///      Every block permutation needs its own circuit and thus its own set of
    ///      verification keys. Only a limited number of block sizes per block
    ///      type are supported.
    /// @param blockType The type of the block
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @param vk The verification key
    function registerCircuit(
        uint8    blockType,
        uint16   blockSize,
        uint8    blockVersion,
        uint[18] calldata vk
        )
        external
        virtual;

    /// @dev Disables the use of the specified circuit.
    /// @param blockType The type of the block
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    function disableCircuit(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        virtual;

    /// @dev Verifies blocks with the given public data and proofs.
    ///      Verifying a block makes sure all requests handled in the block
    ///      are correctly handled by the operator.
    /// @param blockType The type of block
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @param publicInputs The hash of all the public data of the blocks
    /// @param proofs The ZK proofs proving that the blocks are correct
    /// @return True if the block is valid, false otherwise
    function verifyProofs(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion,
        uint[] calldata publicInputs,
        uint[] calldata proofs
        )
        external
        virtual
        view
        returns (bool);

    /// @dev Checks if a circuit with the specified parameters is registered.
    /// @param blockType The type of the block
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @return True if the circuit is registered, false otherwise
    function isCircuitRegistered(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        virtual
        view
        returns (bool);

    /// @dev Checks if a circuit can still be used to commit new blocks.
    /// @param blockType The type of the block
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @return True if the circuit is enabled, false otherwise
    function isCircuitEnabled(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        virtual
        view
        returns (bool);
}

// File: contracts/core/iface/IDepositContract.sol

// Copyright 2017 Loopring Technology Limited.


/// @title IDepositContract.
/// @dev   Contract storing and transferring funds for an exchange.
///
///        ERC1155 tokens can be supported by registering pseudo token addresses calculated
///        as `address(keccak256(real_token_address, token_params))`. Then the custom
///        deposit contract can look up the real token address and paramsters with the
///        pseudo token address before doing the transfers.
/// @author Brecht Devos - <[email protected]>
interface IDepositContract
{
    /// @dev Returns if a token is suppoprted by this contract.
    function isTokenSupported(address token)
        external
        view
        returns (bool);

    /// @dev Transfers tokens from a user to the exchange. This function will
    ///      be called when a user deposits funds to the exchange.
    ///      In a simple implementation the funds are simply stored inside the
    ///      deposit contract directly. More advanced implementations may store the funds
    ///      in some DeFi application to earn interest, so this function could directly
    ///      call the necessary functions to store the funds there.
    ///
    ///      This function needs to throw when an error occurred!
    ///
    ///      This function can only be called by the exchange.
    ///
    /// @param from The address of the account that sends the tokens.
    /// @param token The address of the token to transfer (`0x0` for ETH).
    /// @param amount The amount of tokens to transfer.
    /// @param extraData Opaque data that can be used by the contract to handle the deposit
    /// @return amountReceived The amount to deposit to the user's account in the Merkle tree
    function deposit(
        address from,
        address token,
        uint96  amount,
        bytes   calldata extraData
        )
        external
        payable
        returns (uint96 amountReceived);

    /// @dev Transfers tokens from the exchange to a user. This function will
    ///      be called when a withdrawal is done for a user on the exchange.
    ///      In the simplest implementation the funds are simply stored inside the
    ///      deposit contract directly so this simply transfers the requested tokens back
    ///      to the user. More advanced implementations may store the funds
    ///      in some DeFi application to earn interest so the function would
    ///      need to get those tokens back from the DeFi application first before they
    ///      can be transferred to the user.
    ///
    ///      This function needs to throw when an error occurred!
    ///
    ///      This function can only be called by the exchange.
    ///
    /// @param from The address from which 'amount' tokens are transferred.
    /// @param to The address to which 'amount' tokens are transferred.
    /// @param token The address of the token to transfer (`0x0` for ETH).
    /// @param amount The amount of tokens transferred.
    /// @param extraData Opaque data that can be used by the contract to handle the withdrawal
    function withdraw(
        address from,
        address to,
        address token,
        uint    amount,
        bytes   calldata extraData
        )
        external
        payable;

    /// @dev Transfers tokens (ETH not supported) for a user using the allowance set
    ///      for the exchange. This way the approval can be used for all functionality (and
    ///      extended functionality) of the exchange.
    ///      Should NOT be used to deposit/withdraw user funds, `deposit`/`withdraw`
    ///      should be used for that as they will contain specialised logic for those operations.
    ///      This function can be called by the exchange to transfer onchain funds of users
    ///      necessary for Agent functionality.
    ///
    ///      This function needs to throw when an error occurred!
    ///
    ///      This function can only be called by the exchange.
    ///
    /// @param from The address of the account that sends the tokens.
    /// @param to The address to which 'amount' tokens are transferred.
    /// @param token The address of the token to transfer (ETH is and cannot be suppported).
    /// @param amount The amount of tokens transferred.
    function transfer(
        address from,
        address to,
        address token,
        uint    amount
        )
        external
        payable;

    /// @dev Checks if the given address is used for depositing ETH or not.
    ///      Is used while depositing to send the correct ETH amount to the deposit contract.
    ///
    ///      Note that 0x0 is always registered for deposting ETH when the exchange is created!
    ///      This function allows additional addresses to be used for depositing ETH, the deposit
    ///      contract can implement different behaviour based on the address value.
    ///
    /// @param addr The address to check
    /// @return True if the address is used for depositing ETH, else false.
    function isETH(address addr)
        external
        view
        returns (bool);
}

// File: contracts/core/iface/ILoopringV3.sol

// Copyright 2017 Loopring Technology Limited.



/// @title ILoopringV3
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang  - <[email protected]>
abstract contract ILoopringV3 is Claimable
{
    // == Events ==
    event ExchangeStakeDeposited(address exchangeAddr, uint amount);
    event ExchangeStakeWithdrawn(address exchangeAddr, uint amount);
    event ExchangeStakeBurned(address exchangeAddr, uint amount);
    event SettingsUpdated(uint time);

    // == Public Variables ==
    mapping (address => uint) internal exchangeStake;

    uint    public totalStake;
    address public blockVerifierAddress;
    uint    public forcedWithdrawalFee;
    uint    public tokenRegistrationFeeLRCBase;
    uint    public tokenRegistrationFeeLRCDelta;
    uint8   public protocolTakerFeeBips;
    uint8   public protocolMakerFeeBips;

    address payable public protocolFeeVault;

    // == Public Functions ==

    /// @dev Returns the LRC token address
    /// @return the LRC token address
    function lrcAddress()
        external
        view
        virtual
        returns (address);

    /// @dev Updates the global exchange settings.
    ///      This function can only be called by the owner of this contract.
    ///
    ///      Warning: these new values will be used by existing and
    ///      new Loopring exchanges.
    function updateSettings(
        address payable _protocolFeeVault,   // address(0) not allowed
        address _blockVerifierAddress,       // address(0) not allowed
        uint    _forcedWithdrawalFee
        )
        external
        virtual;

    /// @dev Updates the global protocol fee settings.
    ///      This function can only be called by the owner of this contract.
    ///
    ///      Warning: these new values will be used by existing and
    ///      new Loopring exchanges.
    function updateProtocolFeeSettings(
        uint8 _protocolTakerFeeBips,
        uint8 _protocolMakerFeeBips
        )
        external
        virtual;

    /// @dev Gets the amount of staked LRC for an exchange.
    /// @param exchangeAddr The address of the exchange
    /// @return stakedLRC The amount of LRC
    function getExchangeStake(
        address exchangeAddr
        )
        public
        virtual
        view
        returns (uint stakedLRC);

    /// @dev Burns a certain amount of staked LRC for a specific exchange.
    ///      This function is meant to be called only from exchange contracts.
    /// @return burnedLRC The amount of LRC burned. If the amount is greater than
    ///         the staked amount, all staked LRC will be burned.
    function burnExchangeStake(
        uint amount
        )
        external
        virtual
        returns (uint burnedLRC);

    /// @dev Stakes more LRC for an exchange.
    /// @param  exchangeAddr The address of the exchange
    /// @param  amountLRC The amount of LRC to stake
    /// @return stakedLRC The total amount of LRC staked for the exchange
    function depositExchangeStake(
        address exchangeAddr,
        uint    amountLRC
        )
        external
        virtual
        returns (uint stakedLRC);

    /// @dev Withdraws a certain amount of staked LRC for an exchange to the given address.
    ///      This function is meant to be called only from within exchange contracts.
    /// @param  recipient The address to receive LRC
    /// @param  requestedAmount The amount of LRC to withdraw
    /// @return amountLRC The amount of LRC withdrawn
    function withdrawExchangeStake(
        address recipient,
        uint    requestedAmount
        )
        external
        virtual
        returns (uint amountLRC);

    /// @dev Gets the protocol fee values for an exchange.
    /// @return takerFeeBips The protocol taker fee
    /// @return makerFeeBips The protocol maker fee
    function getProtocolFeeValues(
        )
        public
        virtual
        view
        returns (
            uint8 takerFeeBips,
            uint8 makerFeeBips
        );
}

// File: contracts/core/iface/ExchangeData.sol

// Copyright 2017 Loopring Technology Limited.






/// @title ExchangeData
/// @dev All methods in this lib are internal, therefore, there is no need
///      to deploy this library independently.
/// @author Daniel Wang  - <[email protected]>
/// @author Brecht Devos - <[email protected]>
library ExchangeData
{
    // -- Enums --
    enum TransactionType
    {
        NOOP,
        DEPOSIT,
        WITHDRAWAL,
        TRANSFER,
        SPOT_TRADE,
        ACCOUNT_UPDATE,
        AMM_UPDATE,
        SIGNATURE_VERIFICATION,
        NFT_MINT, // L2 NFT mint or L1-to-L2 NFT deposit
        NFT_DATA
    }

    enum NftType
    {
        ERC1155,
        ERC721
    }

    // -- Structs --
    struct Token
    {
        address token;
    }

    struct ProtocolFeeData
    {
        uint32 syncedAt; // only valid before 2105 (85 years to go)
        uint8  takerFeeBips;
        uint8  makerFeeBips;
        uint8  previousTakerFeeBips;
        uint8  previousMakerFeeBips;
    }

    // General auxiliary data for each conditional transaction
    struct AuxiliaryData
    {
        uint  txIndex;
        bool  approved;
        bytes data;
    }

    // This is the (virtual) block the owner  needs to submit onchain to maintain the
    // per-exchange (virtual) blockchain.
    struct Block
    {
        uint8      blockType;
        uint16     blockSize;
        uint8      blockVersion;
        bytes      data;
        uint256[8] proof;

        // Whether we should store the @BlockInfo for this block on-chain.
        bool storeBlockInfoOnchain;

        // Block specific data that is only used to help process the block on-chain.
        // It is not used as input for the circuits and it is not necessary for data-availability.
        // This bytes array contains the abi encoded AuxiliaryData[] data.
        bytes auxiliaryData;

        // Arbitrary data, mainly for off-chain data-availability, i.e.,
        // the multihash of the IPFS file that contains the block data.
        bytes offchainData;
    }

    struct BlockInfo
    {
        // The time the block was submitted on-chain.
        uint32  timestamp;
        // The public data hash of the block (the 28 most significant bytes).
        bytes28 blockDataHash;
    }

    // Represents an onchain deposit request.
    struct Deposit
    {
        uint96 amount;
        uint64 timestamp;
    }

    // A forced withdrawal request.
    // If the actual owner of the account initiated the request (we don't know who the owner is
    // at the time the request is being made) the full balance will be withdrawn.
    struct ForcedWithdrawal
    {
        address owner;
        uint64  timestamp;
    }

    struct Constants
    {
        uint SNARK_SCALAR_FIELD;
        uint MAX_OPEN_FORCED_REQUESTS;
        uint MAX_AGE_FORCED_REQUEST_UNTIL_WITHDRAW_MODE;
        uint TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS;
        uint MAX_NUM_ACCOUNTS;
        uint MAX_NUM_TOKENS;
        uint MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED;
        uint MIN_TIME_IN_SHUTDOWN;
        uint TX_DATA_AVAILABILITY_SIZE;
        uint MAX_AGE_DEPOSIT_UNTIL_WITHDRAWABLE_UPPERBOUND;
    }

    // This is the prime number that is used for the alt_bn128 elliptic curve, see EIP-196.
    uint public constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    uint public constant MAX_OPEN_FORCED_REQUESTS = 4096;
    uint public constant MAX_AGE_FORCED_REQUEST_UNTIL_WITHDRAW_MODE = 15 days;
    uint public constant TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS = 7 days;
    uint public constant MAX_NUM_ACCOUNTS = 2 ** 32;
    uint public constant MAX_NUM_TOKENS = 2 ** 16;
    uint public constant MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED = 7 days;
    uint public constant MIN_TIME_IN_SHUTDOWN = 30 days;
    // The amount of bytes each rollup transaction uses in the block data for data-availability.
    // This is the maximum amount of bytes of all different transaction types.
    uint32 public constant MAX_AGE_DEPOSIT_UNTIL_WITHDRAWABLE_UPPERBOUND = 15 days;
    uint32 public constant ACCOUNTID_PROTOCOLFEE = 0;

    uint public constant TX_DATA_AVAILABILITY_SIZE = 68;
    uint public constant TX_DATA_AVAILABILITY_SIZE_PART_1 = 29;
    uint public constant TX_DATA_AVAILABILITY_SIZE_PART_2 = 39;

    uint public constant NFT_TOKEN_ID_START = 2 ** 15;

    struct AccountLeaf
    {
        uint32   accountID;
        address  owner;
        uint     pubKeyX;
        uint     pubKeyY;
        uint32   nonce;
        uint     feeBipsAMM;
    }

    struct BalanceLeaf
    {
        uint16   tokenID;
        uint96   balance;
        uint     weightAMM;
        uint     storageRoot;
    }

    struct Nft
    {
        address minter;             // Minter address for a L2 mint or
                                    // the NFT's contract address in the case of a L1-to-L2 NFT deposit.
        NftType nftType;
        address token;
        uint256 nftID;
        uint8   creatorFeeBips;
    }

    struct MerkleProof
    {
        ExchangeData.AccountLeaf accountLeaf;
        ExchangeData.BalanceLeaf balanceLeaf;
        ExchangeData.Nft         nft;
        uint[48]                 accountMerkleProof;
        uint[24]                 balanceMerkleProof;
    }

    struct BlockContext
    {
        bytes32 DOMAIN_SEPARATOR;
        uint32  timestamp;
        Block   block;
        uint    txIndex;
    }

    // Represents the entire exchange state except the owner of the exchange.
    struct State
    {
        uint32  maxAgeDepositUntilWithdrawable;
        bytes32 DOMAIN_SEPARATOR;

        ILoopringV3      loopring;
        IBlockVerifier   blockVerifier;
        IAgentRegistry   agentRegistry;
        IDepositContract depositContract;


        // The merkle root of the offchain data stored in a Merkle tree. The Merkle tree
        // stores balances for users using an account model.
        bytes32 merkleRoot;

        // List of all blocks
        mapping(uint => BlockInfo) blocks;
        uint  numBlocks;

        // List of all tokens
        Token[] tokens;

        // A map from a token to its tokenID + 1
        mapping (address => uint16) tokenToTokenId;

        // A map from an accountID to a tokenID to if the balance is withdrawn
        mapping (uint32 => mapping (uint16 => bool)) withdrawnInWithdrawMode;

        // A map from an account to a token to the amount withdrawable for that account.
        // This is only used when the automatic distribution of the withdrawal failed.
        mapping (address => mapping (uint16 => uint)) amountWithdrawable;

        // A map from an account to a token to the forced withdrawal (always full balance)
        // The `uint16' represents ERC20 token ID (if < NFT_TOKEN_ID_START) or
        // NFT balance slot (if >= NFT_TOKEN_ID_START)
        mapping (uint32 => mapping (uint16 => ForcedWithdrawal)) pendingForcedWithdrawals;

        // A map from an address to a token to a deposit
        mapping (address => mapping (uint16 => Deposit)) pendingDeposits;

        // A map from an account owner to an approved transaction hash to if the transaction is approved or not
        mapping (address => mapping (bytes32 => bool)) approvedTx;

        // A map from an account owner to a destination address to a tokenID to an amount to a storageID to a new recipient address
        mapping (address => mapping (address => mapping (uint16 => mapping (uint => mapping (uint32 => address))))) withdrawalRecipient;


        // Counter to keep track of how many of forced requests are open so we can limit the work that needs to be done by the owner
        uint32 numPendingForcedTransactions;

        // Cached data for the protocol fee
        ProtocolFeeData protocolFeeData;

        // Time when the exchange was shutdown
        uint shutdownModeStartTime;

        // Time when the exchange has entered withdrawal mode
        uint withdrawalModeStartTime;

        // Last time the protocol fee was withdrawn for a specific token
        mapping (address => uint) protocolFeeLastWithdrawnTime;

        // Duplicated loopring address
        address loopringAddr;
        // AMM fee bips
        uint8   ammFeeBips;
        // Enable/Disable `onchainTransferFrom`
        bool    allowOnchainTransferFrom;

        // owner => NFT type => token address => nftID => Deposit
        mapping (address => mapping (NftType => mapping (address => mapping(uint256 => Deposit)))) pendingNFTDeposits;

        // owner => minter => NFT type => token address => nftID => amount withdrawable
        // This is only used when the automatic distribution of the withdrawal failed.
        mapping (address => mapping (address => mapping (NftType => mapping (address => mapping(uint256 => uint))))) amountWithdrawableNFT;
    }
}

// File: contracts/core/impl/libtransactions/BlockReader.sol

// Copyright 2017 Loopring Technology Limited.



/// @title BlockReader
/// @author Brecht Devos - <[email protected]>
/// @dev Utility library to read block data.
library BlockReader {
    using BlockReader       for ExchangeData.Block;
    using BytesUtil         for bytes;

    uint public constant OFFSET_TO_TRANSACTIONS = 20 + 32 + 32 + 4 + 1 + 1 + 4 + 4;

    struct BlockHeader
    {
        address exchange;
        bytes32 merkleRootBefore;
        bytes32 merkleRootAfter;
        uint32  timestamp;
        uint8   protocolTakerFeeBips;
        uint8   protocolMakerFeeBips;
        uint32  numConditionalTransactions;
        uint32  operatorAccountID;
    }

    function readHeader(
        bytes memory _blockData
        )
        internal
        pure
        returns (BlockHeader memory header)
    {
        uint offset = 0;
        header.exchange = _blockData.toAddress(offset);
        offset += 20;
        header.merkleRootBefore = _blockData.toBytes32(offset);
        offset += 32;
        header.merkleRootAfter = _blockData.toBytes32(offset);
        offset += 32;
        header.timestamp = _blockData.toUint32(offset);
        offset += 4;
        header.protocolTakerFeeBips = _blockData.toUint8(offset);
        offset += 1;
        header.protocolMakerFeeBips = _blockData.toUint8(offset);
        offset += 1;
        header.numConditionalTransactions = _blockData.toUint32(offset);
        offset += 4;
        header.operatorAccountID = _blockData.toUint32(offset);
        offset += 4;
        assert(offset == OFFSET_TO_TRANSACTIONS);
    }

    function readTransactionData(
        bytes memory data,
        uint txIdx,
        uint blockSize,
        bytes memory txData
        )
        internal
        pure
    {
        require(txIdx < blockSize, "INVALID_TX_IDX");

        // The transaction was transformed to make it easier to compress.
        // Transform it back here.
        // Part 1
        uint txDataOffset = OFFSET_TO_TRANSACTIONS +
            txIdx * ExchangeData.TX_DATA_AVAILABILITY_SIZE_PART_1;
        assembly {
            mstore(add(txData, 32), mload(add(data, add(txDataOffset, 32))))
        }
        // Part 2
        txDataOffset = OFFSET_TO_TRANSACTIONS +
            blockSize * ExchangeData.TX_DATA_AVAILABILITY_SIZE_PART_1 +
            txIdx * ExchangeData.TX_DATA_AVAILABILITY_SIZE_PART_2;
        assembly {
            mstore(add(txData, 61 /*32 + 29*/), mload(add(data, add(txDataOffset, 32))))
            mstore(add(txData, 68            ), mload(add(data, add(txDataOffset, 39))))
        }
    }
}

// File: contracts/lib/EIP712.sol

// Copyright 2017 Loopring Technology Limited.


library EIP712
{
    struct Domain {
        string  name;
        string  version;
        address verifyingContract;
    }

    bytes32 constant internal EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    string constant internal EIP191_HEADER = "\x19\x01";

    function hash(Domain memory domain)
        internal
        pure
        returns (bytes32)
    {
        uint _chainid;
        assembly { _chainid := chainid() }

        return keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(domain.name)),
                keccak256(bytes(domain.version)),
                _chainid,
                domain.verifyingContract
            )
        );
    }

    function hashPacked(
        bytes32 domainSeparator,
        bytes32 dataHash
        )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                domainSeparator,
                dataHash
            )
        );
    }
}

// File: contracts/thirdparty/SafeCast.sol

// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/SafeCast.sol



/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value < 2**96, "SafeCast: value doesn\'t fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value < 2**40, "SafeCast: value doesn\'t fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// File: contracts/lib/FloatUtil.sol

// Copyright 2017 Loopring Technology Limited.




/// @title Utility Functions for floats
/// @author Brecht Devos - <[email protected]>
library FloatUtil
{
    using MathUint for uint;
    using SafeCast for uint;

    // Decodes a decimal float value that is encoded like `exponent | mantissa`.
    // Both exponent and mantissa are in base 10.
    // Decoding to an integer is as simple as `mantissa * (10 ** exponent)`
    // Will throw when the decoded value overflows an uint96
    /// @param f The float value with 5 bits for the exponent
    /// @param numBits The total number of bits (numBitsMantissa := numBits - numBitsExponent)
    /// @return value The decoded integer value.
    function decodeFloat(
        uint f,
        uint numBits
        )
        internal
        pure
        returns (uint96 value)
    {
        if (f == 0) {
            return 0;
        }
        uint numBitsMantissa = numBits.sub(5);
        uint exponent = f >> numBitsMantissa;
        // log2(10**77) = 255.79 < 256
        require(exponent <= 77, "EXPONENT_TOO_LARGE");
        uint mantissa = f & ((1 << numBitsMantissa) - 1);
        value = mantissa.mul(10 ** exponent).toUint96();
    }

    // Decodes a decimal float value that is encoded like `exponent | mantissa`.
    // Both exponent and mantissa are in base 10.
    // Decoding to an integer is as simple as `mantissa * (10 ** exponent)`
    // Will throw when the decoded value overflows an uint96
    /// @param f The float value with 5 bits exponent, 11 bits mantissa
    /// @return value The decoded integer value.
    function decodeFloat16(
        uint16 f
        )
        internal
        pure
        returns (uint96)
    {
        uint value = ((uint(f) & 2047) * (10 ** (uint(f) >> 11)));
        require(value < 2**96, "SafeCast: value doesn\'t fit in 96 bits");
        return uint96(value);
    }

    // Decodes a decimal float value that is encoded like `exponent | mantissa`.
    // Both exponent and mantissa are in base 10.
    // Decoding to an integer is as simple as `mantissa * (10 ** exponent)`
    // Will throw when the decoded value overflows an uint96
    /// @param f The float value with 5 bits exponent, 19 bits mantissa
    /// @return value The decoded integer value.
    function decodeFloat24(
        uint24 f
        )
        internal
        pure
        returns (uint96)
    {
        uint value = ((uint(f) & 524287) * (10 ** (uint(f) >> 19)));
        require(value < 2**96, "SafeCast: value doesn\'t fit in 96 bits");
        return uint96(value);
    }
}

// File: contracts/lib/ERC1271.sol

// Copyright 2017 Loopring Technology Limited.

abstract contract ERC1271 {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 constant internal ERC1271_MAGICVALUE = 0x1626ba7e;

    function isValidSignature(
        bytes32      _hash,
        bytes memory _signature)
        public
        view
        virtual
        returns (bytes4 magicValueB32);

}

// File: contracts/lib/SignatureUtil.sol

// Copyright 2017 Loopring Technology Limited.






/// @title SignatureUtil
/// @author Daniel Wang - <[email protected]>
/// @dev This method supports multihash standard. Each signature's last byte indicates
///      the signature's type.
library SignatureUtil
{
    using BytesUtil     for bytes;
    using MathUint      for uint;
    using AddressUtil   for address;

    enum SignatureType {
        ILLEGAL,
        INVALID,
        EIP_712,
        ETH_SIGN,
        WALLET   // deprecated
    }

    bytes4 constant internal ERC1271_MAGICVALUE = 0x1626ba7e;

    function verifySignatures(
        bytes32          signHash,
        address[] memory signers,
        bytes[]   memory signatures
        )
        internal
        view
        returns (bool)
    {
        require(signers.length == signatures.length, "BAD_SIGNATURE_DATA");
        address lastSigner;
        for (uint i = 0; i < signers.length; i++) {
            require(signers[i] > lastSigner, "INVALID_SIGNERS_ORDER");
            lastSigner = signers[i];
            if (!verifySignature(signHash, signers[i], signatures[i])) {
                return false;
            }
        }
        return true;
    }

    function verifySignature(
        bytes32        signHash,
        address        signer,
        bytes   memory signature
        )
        internal
        view
        returns (bool)
    {
        if (signer == address(0)) {
            return false;
        }

        return signer.isContract()?
            verifyERC1271Signature(signHash, signer, signature):
            verifyEOASignature(signHash, signer, signature);
    }

    function recoverECDSASigner(
        bytes32      signHash,
        bytes memory signature
        )
        internal
        pure
        returns (address)
    {
        if (signature.length != 65) {
            return address(0);
        }

        bytes32 r;
        bytes32 s;
        uint8   v;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := and(mload(add(signature, 0x41)), 0xff)
        }
        // See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }
        if (v == 27 || v == 28) {
            return ecrecover(signHash, v, r, s);
        } else {
            return address(0);
        }
    }

    function verifyEOASignature(
        bytes32        signHash,
        address        signer,
        bytes   memory signature
        )
        private
        pure
        returns (bool success)
    {
        if (signer == address(0)) {
            return false;
        }

        uint signatureTypeOffset = signature.length.sub(1);
        SignatureType signatureType = SignatureType(signature.toUint8(signatureTypeOffset));

        // Strip off the last byte of the signature by updating the length
        assembly {
            mstore(signature, signatureTypeOffset)
        }

        if (signatureType == SignatureType.EIP_712) {
            success = (signer == recoverECDSASigner(signHash, signature));
        } else if (signatureType == SignatureType.ETH_SIGN) {
            bytes32 hash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", signHash)
            );
            success = (signer == recoverECDSASigner(hash, signature));
        } else {
            success = false;
        }

        // Restore the signature length
        assembly {
            mstore(signature, add(signatureTypeOffset, 1))
        }

        return success;
    }

    function verifyERC1271Signature(
        bytes32 signHash,
        address signer,
        bytes   memory signature
        )
        private
        view
        returns (bool)
    {
        bytes memory callData = abi.encodeWithSelector(
            ERC1271.isValidSignature.selector,
            signHash,
            signature
        );
        (bool success, bytes memory result) = signer.staticcall(callData);
        return (
            success &&
            result.length == 32 &&
            result.toBytes4(0) == ERC1271_MAGICVALUE
        );
    }
}

// File: contracts/core/impl/libexchange/ExchangeSignatures.sol

// Copyright 2017 Loopring Technology Limited.




/// @title ExchangeSignatures.
/// @dev All methods in this lib are internal, therefore, there is no need
///      to deploy this library independently.
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang  - <[email protected]>
library ExchangeSignatures
{
    using SignatureUtil for bytes32;

    function requireAuthorizedTx(
        ExchangeData.State storage S,
        address signer,
        bytes memory signature,
        bytes32 txHash
        )
        internal // inline call
    {
        require(signer != address(0), "INVALID_SIGNER");
        // Verify the signature if one is provided, otherwise fall back to an approved tx
        if (signature.length > 0) {
            require(txHash.verifySignature(signer, signature), "INVALID_SIGNATURE");
        } else {
            require(S.approvedTx[signer][txHash], "TX_NOT_APPROVED");
            delete S.approvedTx[signer][txHash];
        }
    }
}

// File: contracts/core/impl/libtransactions/AccountUpdateTransaction.sol

// Copyright 2017 Loopring Technology Limited.







/// @title AccountUpdateTransaction
/// @author Brecht Devos - <[email protected]>
library AccountUpdateTransaction
{
    using BytesUtil            for bytes;
    using FloatUtil            for uint16;
    using ExchangeSignatures   for ExchangeData.State;

    bytes32 constant public ACCOUNTUPDATE_TYPEHASH = keccak256(
        "AccountUpdate(address owner,uint32 accountID,uint16 feeTokenID,uint96 maxFee,uint256 publicKey,uint32 validUntil,uint32 nonce)"
    );

    struct AccountUpdate
    {
        address owner;
        uint32  accountID;
        uint16  feeTokenID;
        uint96  maxFee;
        uint96  fee;
        uint    publicKey;
        uint32  validUntil;
        uint32  nonce;
    }

    // Auxiliary data for each account update
    struct AccountUpdateAuxiliaryData
    {
        bytes  signature;
        uint96 maxFee;
        uint32 validUntil;
    }

    function process(
        ExchangeData.State        storage S,
        ExchangeData.BlockContext memory  ctx,
        bytes                     memory  data,
        uint                              offset,
        bytes                     memory  auxiliaryData
        )
        internal
    {
        // Read the account update
        AccountUpdate memory accountUpdate;
        readTx(data, offset, accountUpdate);
        AccountUpdateAuxiliaryData memory auxData = abi.decode(auxiliaryData, (AccountUpdateAuxiliaryData));

        // Fill in withdrawal data missing from DA
        accountUpdate.validUntil = auxData.validUntil;
        accountUpdate.maxFee = auxData.maxFee == 0 ? accountUpdate.fee : auxData.maxFee;
        // Validate
        require(ctx.timestamp < accountUpdate.validUntil, "ACCOUNT_UPDATE_EXPIRED");
        require(accountUpdate.fee <= accountUpdate.maxFee, "ACCOUNT_UPDATE_FEE_TOO_HIGH");

        // Calculate the tx hash
        bytes32 txHash = hashTx(ctx.DOMAIN_SEPARATOR, accountUpdate);

        // Check onchain authorization
        S.requireAuthorizedTx(accountUpdate.owner, auxData.signature, txHash);
    }

    function readTx(
        bytes memory data,
        uint         offset,
        AccountUpdate memory accountUpdate
        )
        internal
        pure
    {
        uint _offset = offset;

        require(data.toUint8Unsafe(_offset) == uint8(ExchangeData.TransactionType.ACCOUNT_UPDATE), "INVALID_TX_TYPE");
        _offset += 1;

        // Check that this is a conditional offset
        require(data.toUint8Unsafe(_offset) == 1, "INVALID_AUXILIARYDATA_DATA");
        _offset += 1;

        // Extract the data from the tx data
        // We don't use abi.decode for this because of the large amount of zero-padding
        // bytes the circuit would also have to hash.
        accountUpdate.owner = data.toAddressUnsafe(_offset);
        _offset += 20;
        accountUpdate.accountID = data.toUint32Unsafe(_offset);
        _offset += 4;
        accountUpdate.feeTokenID = data.toUint16Unsafe(_offset);
        _offset += 2;
        accountUpdate.fee = data.toUint16Unsafe(_offset).decodeFloat16();
        _offset += 2;
        accountUpdate.publicKey = data.toUintUnsafe(_offset);
        _offset += 32;
        accountUpdate.nonce = data.toUint32Unsafe(_offset);
        _offset += 4;
    }

    function hashTx(
        bytes32 DOMAIN_SEPARATOR,
        AccountUpdate memory accountUpdate
        )
        internal
        pure
        returns (bytes32)
    {
        return EIP712.hashPacked(
            DOMAIN_SEPARATOR,
            keccak256(
                abi.encode(
                    ACCOUNTUPDATE_TYPEHASH,
                    accountUpdate.owner,
                    accountUpdate.accountID,
                    accountUpdate.feeTokenID,
                    accountUpdate.maxFee,
                    accountUpdate.publicKey,
                    accountUpdate.validUntil,
                    accountUpdate.nonce
                )
            )
        );
    }
}

// File: contracts/core/impl/libtransactions/AmmUpdateTransaction.sol

// Copyright 2017 Loopring Technology Limited.








/// @title AmmUpdateTransaction
/// @author Brecht Devos - <[email protected]>
library AmmUpdateTransaction
{
    using BytesUtil            for bytes;
    using MathUint             for uint;
    using ExchangeSignatures   for ExchangeData.State;

    bytes32 constant public AMMUPDATE_TYPEHASH = keccak256(
        "AmmUpdate(address owner,uint32 accountID,uint16 tokenID,uint8 feeBips,uint96 tokenWeight,uint32 validUntil,uint32 nonce)"
    );

    struct AmmUpdate
    {
        address owner;
        uint32  accountID;
        uint16  tokenID;
        uint8   feeBips;
        uint96  tokenWeight;
        uint32  validUntil;
        uint32  nonce;
        uint96  balance;
    }

    // Auxiliary data for each AMM update
    struct AmmUpdateAuxiliaryData
    {
        bytes  signature;
        uint32 validUntil;
    }

    function process(
        ExchangeData.State        storage S,
        ExchangeData.BlockContext memory  ctx,
        bytes                     memory  data,
        uint                              offset,
        bytes                     memory  auxiliaryData
        )
        internal
    {
        // Read in the AMM update
        AmmUpdate memory update;
        readTx(data, offset, update);
        AmmUpdateAuxiliaryData memory auxData = abi.decode(auxiliaryData, (AmmUpdateAuxiliaryData));

        // Check validUntil
        require(ctx.timestamp < auxData.validUntil, "AMM_UPDATE_EXPIRED");
        update.validUntil = auxData.validUntil;

        // Calculate the tx hash
        bytes32 txHash = hashTx(ctx.DOMAIN_SEPARATOR, update);

        // Check the on-chain authorization
        S.requireAuthorizedTx(update.owner, auxData.signature, txHash);
    }

    function readTx(
        bytes memory data,
        uint         offset,
        AmmUpdate memory update
        )
        internal
        pure
    {
        uint _offset = offset;

        require(data.toUint8Unsafe(_offset) == uint8(ExchangeData.TransactionType.AMM_UPDATE), "INVALID_TX_TYPE");
        _offset += 1;

        // We don't use abi.decode for this because of the large amount of zero-padding
        // bytes the circuit would also have to hash.
        update.owner = data.toAddressUnsafe(_offset);
        _offset += 20;
        update.accountID = data.toUint32Unsafe(_offset);
        _offset += 4;
        update.tokenID = data.toUint16Unsafe(_offset);
        _offset += 2;
        update.feeBips = data.toUint8Unsafe(_offset);
        _offset += 1;
        update.tokenWeight = data.toUint96Unsafe(_offset);
        _offset += 12;
        update.nonce = data.toUint32Unsafe(_offset);
        _offset += 4;
        update.balance = data.toUint96Unsafe(_offset);
        _offset += 12;
    }

    function hashTx(
        bytes32 DOMAIN_SEPARATOR,
        AmmUpdate memory update
        )
        internal
        pure
        returns (bytes32)
    {
        return EIP712.hashPacked(
            DOMAIN_SEPARATOR,
            keccak256(
                abi.encode(
                    AMMUPDATE_TYPEHASH,
                    update.owner,
                    update.accountID,
                    update.tokenID,
                    update.feeBips,
                    update.tokenWeight,
                    update.validUntil,
                    update.nonce
                )
            )
        );
    }
}

// File: contracts/lib/MathUint96.sol

// Copyright 2017 Loopring Technology Limited.


/// @title Utility Functions for uint
/// @author Daniel Wang - <[email protected]>
library MathUint96
{
    function add(
        uint96 a,
        uint96 b
        )
        internal
        pure
        returns (uint96 c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }

    function sub(
        uint96 a,
        uint96 b
        )
        internal
        pure
        returns (uint96 c)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }
}

// File: contracts/core/impl/libtransactions/DepositTransaction.sol

// Copyright 2017 Loopring Technology Limited.







/// @title DepositTransaction
/// @author Brecht Devos - <[email protected]>
library DepositTransaction
{
    using BytesUtil   for bytes;
    using MathUint96  for uint96;

    struct Deposit
    {
        address to;
        uint32  toAccountID;
        uint16  tokenID;
        uint96  amount;
    }

    function process(
        ExchangeData.State        storage S,
        ExchangeData.BlockContext memory  /*ctx*/,
        bytes                     memory  data,
        uint                              offset,
        bytes                     memory  /*auxiliaryData*/
        )
        internal
    {
        // Read in the deposit
        Deposit memory deposit;
        readTx(data, offset, deposit);
        if (deposit.amount == 0) {
            return;
        }

        // Process the deposit
        ExchangeData.Deposit memory pendingDeposit = S.pendingDeposits[deposit.to][deposit.tokenID];
        // Make sure the deposit was actually done
        require(pendingDeposit.timestamp > 0, "DEPOSIT_NOT_EXIST");

        // Processing partial amounts of the deposited amount is allowed.
        // This is done to ensure the user can do multiple deposits after each other
        // without invalidating work done by the exchange owner for previous deposit amounts.

        require(pendingDeposit.amount >= deposit.amount, "INVALID_AMOUNT");
        pendingDeposit.amount = pendingDeposit.amount.sub(deposit.amount);

        // If the deposit was fully consumed, reset it so the storage is freed up
        // and the owner receives a gas refund.
        if (pendingDeposit.amount == 0) {
            delete S.pendingDeposits[deposit.to][deposit.tokenID];
        } else {
            S.pendingDeposits[deposit.to][deposit.tokenID] = pendingDeposit;
        }
    }

    function readTx(
        bytes   memory data,
        uint           offset,
        Deposit memory deposit
        )
        internal
        pure
    {
        uint _offset = offset;

        require(data.toUint8Unsafe(_offset) == uint8(ExchangeData.TransactionType.DEPOSIT), "INVALID_TX_TYPE");
        _offset += 1;

        // We don't use abi.decode for this because of the large amount of zero-padding
        // bytes the circuit would also have to hash.
        deposit.to = data.toAddressUnsafe(_offset);
        _offset += 20;
        deposit.toAccountID = data.toUint32Unsafe(_offset);
        _offset += 4;
        deposit.tokenID = data.toUint16Unsafe(_offset);
        _offset += 2;
        deposit.amount = data.toUint96Unsafe(_offset);
        _offset += 12;
    }
}

// File: contracts/core/impl/libtransactions/TransferTransaction.sol

// Copyright 2017 Loopring Technology Limited.








/// @title TransferTransaction
/// @author Brecht Devos - <[email protected]>
library TransferTransaction
{
    using BytesUtil            for bytes;
    using FloatUtil            for uint24;
    using FloatUtil            for uint16;
    using MathUint             for uint;
    using ExchangeSignatures   for ExchangeData.State;

    bytes32 constant public TRANSFER_TYPEHASH = keccak256(
        "Transfer(address from,address to,uint16 tokenID,uint96 amount,uint16 feeTokenID,uint96 maxFee,uint32 validUntil,uint32 storageID)"
    );

    struct Transfer
    {
        uint32  fromAccountID;
        uint32  toAccountID;
        address from;
        address to;
        uint16  tokenID;
        uint96  amount;
        uint16  feeTokenID;
        uint96  maxFee;
        uint96  fee;
        uint32  validUntil;
        uint32  storageID;
    }

    // Auxiliary data for each transfer
    struct TransferAuxiliaryData
    {
        bytes  signature;
        uint96 maxFee;
        uint32 validUntil;
    }

    function process(
        ExchangeData.State        storage S,
        ExchangeData.BlockContext memory  ctx,
        bytes                     memory  data,
        uint                              offset,
        bytes                     memory  auxiliaryData
        )
        internal
    {
        // Read the transfer
        Transfer memory transfer;
        readTx(data, offset, transfer);
        TransferAuxiliaryData memory auxData = abi.decode(auxiliaryData, (TransferAuxiliaryData));

        // Fill in withdrawal data missing from DA
        transfer.validUntil = auxData.validUntil;
        transfer.maxFee = auxData.maxFee == 0 ? transfer.fee : auxData.maxFee;
        // Validate
        require(ctx.timestamp < transfer.validUntil, "TRANSFER_EXPIRED");
        require(transfer.fee <= transfer.maxFee, "TRANSFER_FEE_TOO_HIGH");

        // Calculate the tx hash
        bytes32 txHash = hashTx(ctx.DOMAIN_SEPARATOR, transfer);

        // Check the on-chain authorization
        S.requireAuthorizedTx(transfer.from, auxData.signature, txHash);
    }

    function readTx(
        bytes memory data,
        uint         offset,
        Transfer memory transfer
        )
        internal
        pure
    {
        uint _offset = offset;

        require(data.toUint8Unsafe(_offset) == uint8(ExchangeData.TransactionType.TRANSFER), "INVALID_TX_TYPE");
        _offset += 1;

        // Check that this is a conditional transfer
        require(data.toUint8Unsafe(_offset) == 1, "INVALID_AUXILIARYDATA_DATA");
        _offset += 1;

        // Extract the transfer data
        // We don't use abi.decode for this because of the large amount of zero-padding
        // bytes the circuit would also have to hash.
        transfer.fromAccountID = data.toUint32Unsafe(_offset);
        _offset += 4;
        transfer.toAccountID = data.toUint32Unsafe(_offset);
        _offset += 4;
        transfer.tokenID = data.toUint16Unsafe(_offset);
        _offset += 2;
        transfer.amount = data.toUint24Unsafe(_offset).decodeFloat24();
        _offset += 3;
        transfer.feeTokenID = data.toUint16Unsafe(_offset);
        _offset += 2;
        transfer.fee = data.toUint16Unsafe(_offset).decodeFloat16();
        _offset += 2;
        transfer.storageID = data.toUint32Unsafe(_offset);
        _offset += 4;
        transfer.to = data.toAddressUnsafe(_offset);
        _offset += 20;
        transfer.from = data.toAddressUnsafe(_offset);
        _offset += 20;
    }

    function hashTx(
        bytes32 DOMAIN_SEPARATOR,
        Transfer memory transfer
        )
        internal
        pure
        returns (bytes32)
    {
        return EIP712.hashPacked(
            DOMAIN_SEPARATOR,
            keccak256(
                abi.encode(
                    TRANSFER_TYPEHASH,
                    transfer.from,
                    transfer.to,
                    transfer.tokenID,
                    transfer.amount,
                    transfer.feeTokenID,
                    transfer.maxFee,
                    transfer.validUntil,
                    transfer.storageID
                )
            )
        );
    }
}

// File: contracts/core/impl/libexchange/ExchangeMode.sol

// Copyright 2017 Loopring Technology Limited.




/// @title ExchangeMode.
/// @dev All methods in this lib are internal, therefore, there is no need
///      to deploy this library independently.
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang  - <[email protected]>
library ExchangeMode
{
    using MathUint  for uint;

    function isInWithdrawalMode(
        ExchangeData.State storage S
        )
        internal // inline call
        view
        returns (bool result)
    {
        result = S.withdrawalModeStartTime > 0;
    }

    function isShutdown(
        ExchangeData.State storage S
        )
        internal // inline call
        view
        returns (bool)
    {
        return S.shutdownModeStartTime > 0;
    }

    function getNumAvailableForcedSlots(
        ExchangeData.State storage S
        )
        internal
        view
        returns (uint)
    {
        return ExchangeData.MAX_OPEN_FORCED_REQUESTS - S.numPendingForcedTransactions;
    }
}

// File: contracts/lib/ERC20SafeTransfer.sol

// Copyright 2017 Loopring Technology Limited.


/// @title ERC20 safe transfer
/// @dev see https://github.com/sec-bit/badERC20Fix
/// @author Brecht Devos - <[email protected]>
library ERC20SafeTransfer
{
    function safeTransferAndVerify(
        address token,
        address to,
        uint    value
        )
        internal
    {
        safeTransferWithGasLimitAndVerify(
            token,
            to,
            value,
            gasleft()
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint    value
        )
        internal
        returns (bool)
    {
        return safeTransferWithGasLimit(
            token,
            to,
            value,
            gasleft()
        );
    }

    function safeTransferWithGasLimitAndVerify(
        address token,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
    {
        require(
            safeTransferWithGasLimit(token, to, value, gasLimit),
            "TRANSFER_FAILURE"
        );
    }

    function safeTransferWithGasLimit(
        address token,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
        returns (bool)
    {
        // A transfer is successful when 'call' is successful and depending on the token:
        // - No value is returned: we assume a revert when the transfer failed (i.e. 'call' returns false)
        // - A single boolean is returned: this boolean needs to be true (non-zero)

        // bytes4(keccak256("transfer(address,uint256)")) = 0xa9059cbb
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0xa9059cbb),
            to,
            value
        );
        (bool success, ) = token.call{gas: gasLimit}(callData);
        return checkReturnValue(success);
    }

    function safeTransferFromAndVerify(
        address token,
        address from,
        address to,
        uint    value
        )
        internal
    {
        safeTransferFromWithGasLimitAndVerify(
            token,
            from,
            to,
            value,
            gasleft()
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint    value
        )
        internal
        returns (bool)
    {
        return safeTransferFromWithGasLimit(
            token,
            from,
            to,
            value,
            gasleft()
        );
    }

    function safeTransferFromWithGasLimitAndVerify(
        address token,
        address from,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
    {
        bool result = safeTransferFromWithGasLimit(
            token,
            from,
            to,
            value,
            gasLimit
        );
        require(result, "TRANSFER_FAILURE");
    }

    function safeTransferFromWithGasLimit(
        address token,
        address from,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
        returns (bool)
    {
        // A transferFrom is successful when 'call' is successful and depending on the token:
        // - No value is returned: we assume a revert when the transfer failed (i.e. 'call' returns false)
        // - A single boolean is returned: this boolean needs to be true (non-zero)

        // bytes4(keccak256("transferFrom(address,address,uint256)")) = 0x23b872dd
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0x23b872dd),
            from,
            to,
            value
        );
        (bool success, ) = token.call{gas: gasLimit}(callData);
        return checkReturnValue(success);
    }

    function checkReturnValue(
        bool success
        )
        internal
        pure
        returns (bool)
    {
        // A transfer/transferFrom is successful when 'call' is successful and depending on the token:
        // - No value is returned: we assume a revert when the transfer failed (i.e. 'call' returns false)
        // - A single boolean is returned: this boolean needs to be true (non-zero)
        if (success) {
            assembly {
                switch returndatasize()
                // Non-standard ERC20: nothing is returned so if 'call' was successful we assume the transfer succeeded
                case 0 {
                    success := 1
                }
                // Standard ERC20: a single boolean value is returned which needs to be true
                case 32 {
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
                // None of the above: not successful
                default {
                    success := 0
                }
            }
        }
        return success;
    }
}

// File: contracts/core/impl/libexchange/ExchangeTokens.sol

// Copyright 2017 Loopring Technology Limited.






/// @title ExchangeTokens.
/// @author Daniel Wang  - <[email protected]>
/// @author Brecht Devos - <[email protected]>
library ExchangeTokens
{
    using MathUint          for uint;
    using ERC20SafeTransfer for address;
    using ExchangeMode      for ExchangeData.State;

    event TokenRegistered(
        address token,
        uint16  tokenId
    );

    function getTokenAddress(
        ExchangeData.State storage S,
        uint16 tokenID
        )
        public
        view
        returns (address)
    {
        require(tokenID < S.tokens.length, "INVALID_TOKEN_ID");
        return S.tokens[tokenID].token;
    }

    function registerToken(
        ExchangeData.State storage S,
        address tokenAddress
        )
        public
        returns (uint16 tokenID)
    {
        require(!S.isInWithdrawalMode(), "INVALID_MODE");
        require(S.tokenToTokenId[tokenAddress] == 0, "TOKEN_ALREADY_EXIST");
        require(S.tokens.length < ExchangeData.NFT_TOKEN_ID_START, "TOKEN_REGISTRY_FULL");

        // Check if the deposit contract supports the new token
        if (S.depositContract != IDepositContract(0)) {
            require(
                S.depositContract.isTokenSupported(tokenAddress),
                "UNSUPPORTED_TOKEN"
            );
        }

        // Assign a tokenID and store the token
        ExchangeData.Token memory token = ExchangeData.Token(
            tokenAddress
        );
        tokenID = uint16(S.tokens.length);
        S.tokens.push(token);
        S.tokenToTokenId[tokenAddress] = tokenID + 1;

        emit TokenRegistered(tokenAddress, tokenID);
    }

    function getTokenID(
        ExchangeData.State storage S,
        address tokenAddress
        )
        internal  // inline call
        view
        returns (uint16 tokenID)
    {
        tokenID = S.tokenToTokenId[tokenAddress];
        require(tokenID != 0, "TOKEN_NOT_FOUND");
        tokenID = tokenID - 1;
    }

    function isNFT(uint16 tokenID)
        internal  // inline call
        pure
        returns (bool)
    {
        return tokenID >= ExchangeData.NFT_TOKEN_ID_START;
    }
}

// File: contracts/lib/Poseidon.sol

// Copyright 2017 Loopring Technology Limited.


/// @title Poseidon hash function
///        See: https://eprint.iacr.org/2019/458.pdf
///        Code auto-generated by generate_poseidon_EVM_code.py
/// @author Brecht Devos - <[email protected]>
library Poseidon
{
    //
    // hash_t4f6p52
    //

    struct HashInputs4
    {
        uint t0;
        uint t1;
        uint t2;
        uint t3;
    }

    function mix(HashInputs4 memory i, uint q) internal pure
    {
        HashInputs4 memory o;
        o.t0 = mulmod(i.t0, 11739432287187184656569880828944421268616385874806221589758215824904320817117, q);
        o.t0 = addmod(o.t0, mulmod(i.t1, 4977258759536702998522229302103997878600602264560359702680165243908162277980, q), q);
        o.t0 = addmod(o.t0, mulmod(i.t2, 19167410339349846567561662441069598364702008768579734801591448511131028229281, q), q);
        o.t0 = addmod(o.t0, mulmod(i.t3, 14183033936038168803360723133013092560869148726790180682363054735190196956789, q), q);
        o.t1 = mulmod(i.t0, 16872301185549870956030057498946148102848662396374401407323436343924021192350, q);
        o.t1 = addmod(o.t1, mulmod(i.t1, 107933704346764130067829474107909495889716688591997879426350582457782826785, q), q);
        o.t1 = addmod(o.t1, mulmod(i.t2, 17034139127218860091985397764514160131253018178110701196935786874261236172431, q), q);
        o.t1 = addmod(o.t1, mulmod(i.t3, 2799255644797227968811798608332314218966179365168250111693473252876996230317, q), q);
        o.t2 = mulmod(i.t0, 18618317300596756144100783409915332163189452886691331959651778092154775572832, q);
        o.t2 = addmod(o.t2, mulmod(i.t1, 13596762909635538739079656925495736900379091964739248298531655823337482778123, q), q);
        o.t2 = addmod(o.t2, mulmod(i.t2, 18985203040268814769637347880759846911264240088034262814847924884273017355969, q), q);
        o.t2 = addmod(o.t2, mulmod(i.t3, 8652975463545710606098548415650457376967119951977109072274595329619335974180, q), q);
        o.t3 = mulmod(i.t0, 11128168843135959720130031095451763561052380159981718940182755860433840154182, q);
        o.t3 = addmod(o.t3, mulmod(i.t1, 2953507793609469112222895633455544691298656192015062835263784675891831794974, q), q);
        o.t3 = addmod(o.t3, mulmod(i.t2, 19025623051770008118343718096455821045904242602531062247152770448380880817517, q), q);
        o.t3 = addmod(o.t3, mulmod(i.t3, 9077319817220936628089890431129759976815127354480867310384708941479362824016, q), q);
        i.t0 = o.t0;
        i.t1 = o.t1;
        i.t2 = o.t2;
        i.t3 = o.t3;
    }

    function ark(HashInputs4 memory i, uint q, uint c) internal pure
    {
        HashInputs4 memory o;
        o.t0 = addmod(i.t0, c, q);
        o.t1 = addmod(i.t1, c, q);
        o.t2 = addmod(i.t2, c, q);
        o.t3 = addmod(i.t3, c, q);
        i.t0 = o.t0;
        i.t1 = o.t1;
        i.t2 = o.t2;
        i.t3 = o.t3;
    }

    function sbox_full(HashInputs4 memory i, uint q) internal pure
    {
        HashInputs4 memory o;
        o.t0 = mulmod(i.t0, i.t0, q);
        o.t0 = mulmod(o.t0, o.t0, q);
        o.t0 = mulmod(i.t0, o.t0, q);
        o.t1 = mulmod(i.t1, i.t1, q);
        o.t1 = mulmod(o.t1, o.t1, q);
        o.t1 = mulmod(i.t1, o.t1, q);
        o.t2 = mulmod(i.t2, i.t2, q);
        o.t2 = mulmod(o.t2, o.t2, q);
        o.t2 = mulmod(i.t2, o.t2, q);
        o.t3 = mulmod(i.t3, i.t3, q);
        o.t3 = mulmod(o.t3, o.t3, q);
        o.t3 = mulmod(i.t3, o.t3, q);
        i.t0 = o.t0;
        i.t1 = o.t1;
        i.t2 = o.t2;
        i.t3 = o.t3;
    }

    function sbox_partial(HashInputs4 memory i, uint q) internal pure
    {
        HashInputs4 memory o;
        o.t0 = mulmod(i.t0, i.t0, q);
        o.t0 = mulmod(o.t0, o.t0, q);
        o.t0 = mulmod(i.t0, o.t0, q);
        i.t0 = o.t0;
    }

    function hash_t4f6p52(HashInputs4 memory i, uint q) internal pure returns (uint)
    {
        // validate inputs
        require(i.t0 < q, "INVALID_INPUT");
        require(i.t1 < q, "INVALID_INPUT");
        require(i.t2 < q, "INVALID_INPUT");
        require(i.t3 < q, "INVALID_INPUT");

        // round 0
        ark(i, q, 14397397413755236225575615486459253198602422701513067526754101844196324375522);
        sbox_full(i, q);
        mix(i, q);
        // round 1
        ark(i, q, 10405129301473404666785234951972711717481302463898292859783056520670200613128);
        sbox_full(i, q);
        mix(i, q);
        // round 2
        ark(i, q, 5179144822360023508491245509308555580251733042407187134628755730783052214509);
        sbox_full(i, q);
        mix(i, q);
        // round 3
        ark(i, q, 9132640374240188374542843306219594180154739721841249568925550236430986592615);
        sbox_partial(i, q);
        mix(i, q);
        // round 4
        ark(i, q, 20360807315276763881209958738450444293273549928693737723235350358403012458514);
        sbox_partial(i, q);
        mix(i, q);
        // round 5
        ark(i, q, 17933600965499023212689924809448543050840131883187652471064418452962948061619);
        sbox_partial(i, q);
        mix(i, q);
        // round 6
        ark(i, q, 3636213416533737411392076250708419981662897009810345015164671602334517041153);
        sbox_partial(i, q);
        mix(i, q);
        // round 7
        ark(i, q, 2008540005368330234524962342006691994500273283000229509835662097352946198608);
        sbox_partial(i, q);
        mix(i, q);
        // round 8
        ark(i, q, 16018407964853379535338740313053768402596521780991140819786560130595652651567);
        sbox_partial(i, q);
        mix(i, q);
        // round 9
        ark(i, q, 20653139667070586705378398435856186172195806027708437373983929336015162186471);
        sbox_partial(i, q);
        mix(i, q);
        // round 10
        ark(i, q, 17887713874711369695406927657694993484804203950786446055999405564652412116765);
        sbox_partial(i, q);
        mix(i, q);
        // round 11
        ark(i, q, 4852706232225925756777361208698488277369799648067343227630786518486608711772);
        sbox_partial(i, q);
        mix(i, q);
        // round 12
        ark(i, q, 8969172011633935669771678412400911310465619639756845342775631896478908389850);
        sbox_partial(i, q);
        mix(i, q);
        // round 13
        ark(i, q, 20570199545627577691240476121888846460936245025392381957866134167601058684375);
        sbox_partial(i, q);
        mix(i, q);
        // round 14
        ark(i, q, 16442329894745639881165035015179028112772410105963688121820543219662832524136);
        sbox_partial(i, q);
        mix(i, q);
        // round 15
        ark(i, q, 20060625627350485876280451423010593928172611031611836167979515653463693899374);
        sbox_partial(i, q);
        mix(i, q);
        // round 16
        ark(i, q, 16637282689940520290130302519163090147511023430395200895953984829546679599107);
        sbox_partial(i, q);
        mix(i, q);
        // round 17
        ark(i, q, 15599196921909732993082127725908821049411366914683565306060493533569088698214);
        sbox_partial(i, q);
        mix(i, q);
        // round 18
        ark(i, q, 16894591341213863947423904025624185991098788054337051624251730868231322135455);
        sbox_partial(i, q);
        mix(i, q);
        // round 19
        ark(i, q, 1197934381747032348421303489683932612752526046745577259575778515005162320212);
        sbox_partial(i, q);
        mix(i, q);
        // round 20
        ark(i, q, 6172482022646932735745595886795230725225293469762393889050804649558459236626);
        sbox_partial(i, q);
        mix(i, q);
        // round 21
        ark(i, q, 21004037394166516054140386756510609698837211370585899203851827276330669555417);
        sbox_partial(i, q);
        mix(i, q);
        // round 22
        ark(i, q, 15262034989144652068456967541137853724140836132717012646544737680069032573006);
        sbox_partial(i, q);
        mix(i, q);
        // round 23
        ark(i, q, 15017690682054366744270630371095785995296470601172793770224691982518041139766);
        sbox_partial(i, q);
        mix(i, q);
        // round 24
        ark(i, q, 15159744167842240513848638419303545693472533086570469712794583342699782519832);
        sbox_partial(i, q);
        mix(i, q);
        // round 25
        ark(i, q, 11178069035565459212220861899558526502477231302924961773582350246646450941231);
        sbox_partial(i, q);
        mix(i, q);
        // round 26
        ark(i, q, 21154888769130549957415912997229564077486639529994598560737238811887296922114);
        sbox_partial(i, q);
        mix(i, q);
        // round 27
        ark(i, q, 20162517328110570500010831422938033120419484532231241180224283481905744633719);
        sbox_partial(i, q);
        mix(i, q);
        // round 28
        ark(i, q, 2777362604871784250419758188173029886707024739806641263170345377816177052018);
        sbox_partial(i, q);
        mix(i, q);
        // round 29
        ark(i, q, 15732290486829619144634131656503993123618032247178179298922551820261215487562);
        sbox_partial(i, q);
        mix(i, q);
        // round 30
        ark(i, q, 6024433414579583476444635447152826813568595303270846875177844482142230009826);
        sbox_partial(i, q);
        mix(i, q);
        // round 31
        ark(i, q, 17677827682004946431939402157761289497221048154630238117709539216286149983245);
        sbox_partial(i, q);
        mix(i, q);
        // round 32
        ark(i, q, 10716307389353583413755237303156291454109852751296156900963208377067748518748);
        sbox_partial(i, q);
        mix(i, q);
        // round 33
        ark(i, q, 14925386988604173087143546225719076187055229908444910452781922028996524347508);
        sbox_partial(i, q);
        mix(i, q);
        // round 34
        ark(i, q, 8940878636401797005293482068100797531020505636124892198091491586778667442523);
        sbox_partial(i, q);
        mix(i, q);
        // round 35
        ark(i, q, 18911747154199663060505302806894425160044925686870165583944475880789706164410);
        sbox_partial(i, q);
        mix(i, q);
        // round 36
        ark(i, q, 8821532432394939099312235292271438180996556457308429936910969094255825456935);
        sbox_partial(i, q);
        mix(i, q);
        // round 37
        ark(i, q, 20632576502437623790366878538516326728436616723089049415538037018093616927643);
        sbox_partial(i, q);
        mix(i, q);
        // round 38
        ark(i, q, 71447649211767888770311304010816315780740050029903404046389165015534756512);
        sbox_partial(i, q);
        mix(i, q);
        // round 39
        ark(i, q, 2781996465394730190470582631099299305677291329609718650018200531245670229393);
        sbox_partial(i, q);
        mix(i, q);
        // round 40
        ark(i, q, 12441376330954323535872906380510501637773629931719508864016287320488688345525);
        sbox_partial(i, q);
        mix(i, q);
        // round 41
        ark(i, q, 2558302139544901035700544058046419714227464650146159803703499681139469546006);
        sbox_partial(i, q);
        mix(i, q);
        // round 42
        ark(i, q, 10087036781939179132584550273563255199577525914374285705149349445480649057058);
        sbox_partial(i, q);
        mix(i, q);
        // round 43
        ark(i, q, 4267692623754666261749551533667592242661271409704769363166965280715887854739);
        sbox_partial(i, q);
        mix(i, q);
        // round 44
        ark(i, q, 4945579503584457514844595640661884835097077318604083061152997449742124905548);
        sbox_partial(i, q);
        mix(i, q);
        // round 45
        ark(i, q, 17742335354489274412669987990603079185096280484072783973732137326144230832311);
        sbox_partial(i, q);
        mix(i, q);
        // round 46
        ark(i, q, 6266270088302506215402996795500854910256503071464802875821837403486057988208);
        sbox_partial(i, q);
        mix(i, q);
        // round 47
        ark(i, q, 2716062168542520412498610856550519519760063668165561277991771577403400784706);
        sbox_partial(i, q);
        mix(i, q);
        // round 48
        ark(i, q, 19118392018538203167410421493487769944462015419023083813301166096764262134232);
        sbox_partial(i, q);
        mix(i, q);
        // round 49
        ark(i, q, 9386595745626044000666050847309903206827901310677406022353307960932745699524);
        sbox_partial(i, q);
        mix(i, q);
        // round 50
        ark(i, q, 9121640807890366356465620448383131419933298563527245687958865317869840082266);
        sbox_partial(i, q);
        mix(i, q);
        // round 51
        ark(i, q, 3078975275808111706229899605611544294904276390490742680006005661017864583210);
        sbox_partial(i, q);
        mix(i, q);
        // round 52
        ark(i, q, 7157404299437167354719786626667769956233708887934477609633504801472827442743);
        sbox_partial(i, q);
        mix(i, q);
        // round 53
        ark(i, q, 14056248655941725362944552761799461694550787028230120190862133165195793034373);
        sbox_partial(i, q);
        mix(i, q);
        // round 54
        ark(i, q, 14124396743304355958915937804966111851843703158171757752158388556919187839849);
        sbox_partial(i, q);
        mix(i, q);
        // round 55
        ark(i, q, 11851254356749068692552943732920045260402277343008629727465773766468466181076);
        sbox_full(i, q);
        mix(i, q);
        // round 56
        ark(i, q, 9799099446406796696742256539758943483211846559715874347178722060519817626047);
        sbox_full(i, q);
        mix(i, q);
        // round 57
        ark(i, q, 10156146186214948683880719664738535455146137901666656566575307300522957959544);
        sbox_full(i, q);
        mix(i, q);

        return i.t0;
    }


    //
    // hash_t5f6p52
    //

    struct HashInputs5
    {
        uint t0;
        uint t1;
        uint t2;
        uint t3;
        uint t4;
    }

    function hash_t5f6p52_internal(
        uint t0,
        uint t1,
        uint t2,
        uint t3,
        uint t4,
        uint q
        )
        internal
        pure
        returns (uint)
    {
        assembly {
            function mix(_t0, _t1, _t2, _t3, _t4, _q) -> nt0, nt1, nt2, nt3, nt4 {
                nt0 := mulmod(_t0, 4977258759536702998522229302103997878600602264560359702680165243908162277980, _q)
                nt0 := addmod(nt0, mulmod(_t1, 19167410339349846567561662441069598364702008768579734801591448511131028229281, _q), _q)
                nt0 := addmod(nt0, mulmod(_t2, 14183033936038168803360723133013092560869148726790180682363054735190196956789, _q), _q)
                nt0 := addmod(nt0, mulmod(_t3, 9067734253445064890734144122526450279189023719890032859456830213166173619761, _q), _q)
                nt0 := addmod(nt0, mulmod(_t4, 16378664841697311562845443097199265623838619398287411428110917414833007677155, _q), _q)
                nt1 := mulmod(_t0, 107933704346764130067829474107909495889716688591997879426350582457782826785, _q)
                nt1 := addmod(nt1, mulmod(_t1, 17034139127218860091985397764514160131253018178110701196935786874261236172431, _q), _q)
                nt1 := addmod(nt1, mulmod(_t2, 2799255644797227968811798608332314218966179365168250111693473252876996230317, _q), _q)
                nt1 := addmod(nt1, mulmod(_t3, 2482058150180648511543788012634934806465808146786082148795902594096349483974, _q), _q)
                nt1 := addmod(nt1, mulmod(_t4, 16563522740626180338295201738437974404892092704059676533096069531044355099628, _q), _q)
                nt2 := mulmod(_t0, 13596762909635538739079656925495736900379091964739248298531655823337482778123, _q)
                nt2 := addmod(nt2, mulmod(_t1, 18985203040268814769637347880759846911264240088034262814847924884273017355969, _q), _q)
                nt2 := addmod(nt2, mulmod(_t2, 8652975463545710606098548415650457376967119951977109072274595329619335974180, _q), _q)
                nt2 := addmod(nt2, mulmod(_t3, 970943815872417895015626519859542525373809485973005165410533315057253476903, _q), _q)
                nt2 := addmod(nt2, mulmod(_t4, 19406667490568134101658669326517700199745817783746545889094238643063688871948, _q), _q)
                nt3 := mulmod(_t0, 2953507793609469112222895633455544691298656192015062835263784675891831794974, _q)
                nt3 := addmod(nt3, mulmod(_t1, 19025623051770008118343718096455821045904242602531062247152770448380880817517, _q), _q)
                nt3 := addmod(nt3, mulmod(_t2, 9077319817220936628089890431129759976815127354480867310384708941479362824016, _q), _q)
                nt3 := addmod(nt3, mulmod(_t3, 4770370314098695913091200576539533727214143013236894216582648993741910829490, _q), _q)
                nt3 := addmod(nt3, mulmod(_t4, 4298564056297802123194408918029088169104276109138370115401819933600955259473, _q), _q)
                nt4 := mulmod(_t0, 8336710468787894148066071988103915091676109272951895469087957569358494947747, _q)
                nt4 := addmod(nt4, mulmod(_t1, 16205238342129310687768799056463408647672389183328001070715567975181364448609, _q), _q)
                nt4 := addmod(nt4, mulmod(_t2, 8303849270045876854140023508764676765932043944545416856530551331270859502246, _q), _q)
                nt4 := addmod(nt4, mulmod(_t3, 20218246699596954048529384569730026273241102596326201163062133863539137060414, _q), _q)
                nt4 := addmod(nt4, mulmod(_t4, 1712845821388089905746651754894206522004527237615042226559791118162382909269, _q), _q)
            }

            function ark(_t0, _t1, _t2, _t3, _t4, _q, c) -> nt0, nt1, nt2, nt3, nt4 {
                nt0 := addmod(_t0, c, _q)
                nt1 := addmod(_t1, c, _q)
                nt2 := addmod(_t2, c, _q)
                nt3 := addmod(_t3, c, _q)
                nt4 := addmod(_t4, c, _q)
            }

            function sbox_full(_t0, _t1, _t2, _t3, _t4, _q) -> nt0, nt1, nt2, nt3, nt4 {
                nt0 := mulmod(_t0, _t0, _q)
                nt0 := mulmod(nt0, nt0, _q)
                nt0 := mulmod(_t0, nt0, _q)
                nt1 := mulmod(_t1, _t1, _q)
                nt1 := mulmod(nt1, nt1, _q)
                nt1 := mulmod(_t1, nt1, _q)
                nt2 := mulmod(_t2, _t2, _q)
                nt2 := mulmod(nt2, nt2, _q)
                nt2 := mulmod(_t2, nt2, _q)
                nt3 := mulmod(_t3, _t3, _q)
                nt3 := mulmod(nt3, nt3, _q)
                nt3 := mulmod(_t3, nt3, _q)
                nt4 := mulmod(_t4, _t4, _q)
                nt4 := mulmod(nt4, nt4, _q)
                nt4 := mulmod(_t4, nt4, _q)
            }

            function sbox_partial(_t, _q) -> nt {
                nt := mulmod(_t, _t, _q)
                nt := mulmod(nt, nt, _q)
                nt := mulmod(_t, nt, _q)
            }

            // round 0
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 14397397413755236225575615486459253198602422701513067526754101844196324375522)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 1
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 10405129301473404666785234951972711717481302463898292859783056520670200613128)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 2
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 5179144822360023508491245509308555580251733042407187134628755730783052214509)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 3
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 9132640374240188374542843306219594180154739721841249568925550236430986592615)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 4
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20360807315276763881209958738450444293273549928693737723235350358403012458514)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 5
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 17933600965499023212689924809448543050840131883187652471064418452962948061619)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 6
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 3636213416533737411392076250708419981662897009810345015164671602334517041153)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 7
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2008540005368330234524962342006691994500273283000229509835662097352946198608)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 8
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 16018407964853379535338740313053768402596521780991140819786560130595652651567)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 9
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20653139667070586705378398435856186172195806027708437373983929336015162186471)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 10
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 17887713874711369695406927657694993484804203950786446055999405564652412116765)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 11
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 4852706232225925756777361208698488277369799648067343227630786518486608711772)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 12
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 8969172011633935669771678412400911310465619639756845342775631896478908389850)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 13
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20570199545627577691240476121888846460936245025392381957866134167601058684375)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 14
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 16442329894745639881165035015179028112772410105963688121820543219662832524136)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 15
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20060625627350485876280451423010593928172611031611836167979515653463693899374)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 16
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 16637282689940520290130302519163090147511023430395200895953984829546679599107)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 17
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15599196921909732993082127725908821049411366914683565306060493533569088698214)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 18
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 16894591341213863947423904025624185991098788054337051624251730868231322135455)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 19
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 1197934381747032348421303489683932612752526046745577259575778515005162320212)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 20
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 6172482022646932735745595886795230725225293469762393889050804649558459236626)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 21
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 21004037394166516054140386756510609698837211370585899203851827276330669555417)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 22
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15262034989144652068456967541137853724140836132717012646544737680069032573006)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 23
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15017690682054366744270630371095785995296470601172793770224691982518041139766)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 24
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15159744167842240513848638419303545693472533086570469712794583342699782519832)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 25
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 11178069035565459212220861899558526502477231302924961773582350246646450941231)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 26
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 21154888769130549957415912997229564077486639529994598560737238811887296922114)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 27
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20162517328110570500010831422938033120419484532231241180224283481905744633719)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 28
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2777362604871784250419758188173029886707024739806641263170345377816177052018)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 29
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15732290486829619144634131656503993123618032247178179298922551820261215487562)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 30
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 6024433414579583476444635447152826813568595303270846875177844482142230009826)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 31
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 17677827682004946431939402157761289497221048154630238117709539216286149983245)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 32
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 10716307389353583413755237303156291454109852751296156900963208377067748518748)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 33
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 14925386988604173087143546225719076187055229908444910452781922028996524347508)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 34
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 8940878636401797005293482068100797531020505636124892198091491586778667442523)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 35
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 18911747154199663060505302806894425160044925686870165583944475880789706164410)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 36
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 8821532432394939099312235292271438180996556457308429936910969094255825456935)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 37
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20632576502437623790366878538516326728436616723089049415538037018093616927643)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 38
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 71447649211767888770311304010816315780740050029903404046389165015534756512)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 39
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2781996465394730190470582631099299305677291329609718650018200531245670229393)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 40
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 12441376330954323535872906380510501637773629931719508864016287320488688345525)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 41
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2558302139544901035700544058046419714227464650146159803703499681139469546006)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 42
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 10087036781939179132584550273563255199577525914374285705149349445480649057058)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 43
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 4267692623754666261749551533667592242661271409704769363166965280715887854739)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 44
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 4945579503584457514844595640661884835097077318604083061152997449742124905548)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 45
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 17742335354489274412669987990603079185096280484072783973732137326144230832311)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 46
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 6266270088302506215402996795500854910256503071464802875821837403486057988208)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 47
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2716062168542520412498610856550519519760063668165561277991771577403400784706)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 48
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 19118392018538203167410421493487769944462015419023083813301166096764262134232)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 49
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 9386595745626044000666050847309903206827901310677406022353307960932745699524)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 50
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 9121640807890366356465620448383131419933298563527245687958865317869840082266)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 51
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 3078975275808111706229899605611544294904276390490742680006005661017864583210)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 52
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 7157404299437167354719786626667769956233708887934477609633504801472827442743)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 53
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 14056248655941725362944552761799461694550787028230120190862133165195793034373)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 54
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 14124396743304355958915937804966111851843703158171757752158388556919187839849)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 55
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 11851254356749068692552943732920045260402277343008629727465773766468466181076)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 56
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 9799099446406796696742256539758943483211846559715874347178722060519817626047)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 57
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 10156146186214948683880719664738535455146137901666656566575307300522957959544)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
        }
        return t0;
    }

    function hash_t5f6p52(HashInputs5 memory i, uint q) internal pure returns (uint)
    {
        // validate inputs
        require(i.t0 < q, "INVALID_INPUT");
        require(i.t1 < q, "INVALID_INPUT");
        require(i.t2 < q, "INVALID_INPUT");
        require(i.t3 < q, "INVALID_INPUT");
        require(i.t4 < q, "INVALID_INPUT");

        return hash_t5f6p52_internal(i.t0, i.t1, i.t2, i.t3, i.t4, q);
    }


    //
    // hash_t7f6p52
    //

    struct HashInputs7
    {
        uint t0;
        uint t1;
        uint t2;
        uint t3;
        uint t4;
        uint t5;
        uint t6;
    }

    function mix(HashInputs7 memory i, uint q) internal pure
    {
        HashInputs7 memory o;
        o.t0 = mulmod(i.t0, 14183033936038168803360723133013092560869148726790180682363054735190196956789, q);
        o.t0 = addmod(o.t0, mulmod(i.t1, 9067734253445064890734144122526450279189023719890032859456830213166173619761, q), q);
        o.t0 = addmod(o.t0, mulmod(i.t2, 16378664841697311562845443097199265623838619398287411428110917414833007677155, q), q);
        o.t0 = addmod(o.t0, mulmod(i.t3, 12968540216479938138647596899147650021419273189336843725176422194136033835172, q), q);
        o.t0 = addmod(o.t0, mulmod(i.t4, 3636162562566338420490575570584278737093584021456168183289112789616069756675, q), q);
        o.t0 = addmod(o.t0, mulmod(i.t5, 8949952361235797771659501126471156178804092479420606597426318793013844305422, q), q);
        o.t0 = addmod(o.t0, mulmod(i.t6, 13586657904816433080148729258697725609063090799921401830545410130405357110367, q), q);
        o.t1 = mulmod(i.t0, 2799255644797227968811798608332314218966179365168250111693473252876996230317, q);
        o.t1 = addmod(o.t1, mulmod(i.t1, 2482058150180648511543788012634934806465808146786082148795902594096349483974, q), q);
        o.t1 = addmod(o.t1, mulmod(i.t2, 16563522740626180338295201738437974404892092704059676533096069531044355099628, q), q);
        o.t1 = addmod(o.t1, mulmod(i.t3, 10468644849657689537028565510142839489302836569811003546969773105463051947124, q), q);
        o.t1 = addmod(o.t1, mulmod(i.t4, 3328913364598498171733622353010907641674136720305714432354138807013088636408, q), q);
        o.t1 = addmod(o.t1, mulmod(i.t5, 8642889650254799419576843603477253661899356105675006557919250564400804756641, q), q);
        o.t1 = addmod(o.t1, mulmod(i.t6, 14300697791556510113764686242794463641010174685800128469053974698256194076125, q), q);
        o.t2 = mulmod(i.t0, 8652975463545710606098548415650457376967119951977109072274595329619335974180, q);
        o.t2 = addmod(o.t2, mulmod(i.t1, 970943815872417895015626519859542525373809485973005165410533315057253476903, q), q);
        o.t2 = addmod(o.t2, mulmod(i.t2, 19406667490568134101658669326517700199745817783746545889094238643063688871948, q), q);
        o.t2 = addmod(o.t2, mulmod(i.t3, 17049854690034965250221386317058877242629221002521630573756355118745574274967, q), q);
        o.t2 = addmod(o.t2, mulmod(i.t4, 4964394613021008685803675656098849539153699842663541444414978877928878266244, q), q);
        o.t2 = addmod(o.t2, mulmod(i.t5, 15474947305445649466370538888925567099067120578851553103424183520405650587995, q), q);
        o.t2 = addmod(o.t2, mulmod(i.t6, 1016119095639665978105768933448186152078842964810837543326777554729232767846, q), q);
        o.t3 = mulmod(i.t0, 9077319817220936628089890431129759976815127354480867310384708941479362824016, q);
        o.t3 = addmod(o.t3, mulmod(i.t1, 4770370314098695913091200576539533727214143013236894216582648993741910829490, q), q);
        o.t3 = addmod(o.t3, mulmod(i.t2, 4298564056297802123194408918029088169104276109138370115401819933600955259473, q), q);
        o.t3 = addmod(o.t3, mulmod(i.t3, 6905514380186323693285869145872115273350947784558995755916362330070690839131, q), q);
        o.t3 = addmod(o.t3, mulmod(i.t4, 4783343257810358393326889022942241108539824540285247795235499223017138301952, q), q);
        o.t3 = addmod(o.t3, mulmod(i.t5, 1420772902128122367335354247676760257656541121773854204774788519230732373317, q), q);
        o.t3 = addmod(o.t3, mulmod(i.t6, 14172871439045259377975734198064051992755748777535789572469924335100006948373, q), q);
        o.t4 = mulmod(i.t0, 8303849270045876854140023508764676765932043944545416856530551331270859502246, q);
        o.t4 = addmod(o.t4, mulmod(i.t1, 20218246699596954048529384569730026273241102596326201163062133863539137060414, q), q);
        o.t4 = addmod(o.t4, mulmod(i.t2, 1712845821388089905746651754894206522004527237615042226559791118162382909269, q), q);
        o.t4 = addmod(o.t4, mulmod(i.t3, 13001155522144542028910638547179410124467185319212645031214919884423841839406, q), q);
        o.t4 = addmod(o.t4, mulmod(i.t4, 16037892369576300958623292723740289861626299352695838577330319504984091062115, q), q);
        o.t4 = addmod(o.t4, mulmod(i.t5, 19189494548480259335554606182055502469831573298885662881571444557262020106898, q), q);
        o.t4 = addmod(o.t4, mulmod(i.t6, 19032687447778391106390582750185144485341165205399984747451318330476859342654, q), q);
        o.t5 = mulmod(i.t0, 13272957914179340594010910867091459756043436017766464331915862093201960540910, q);
        o.t5 = addmod(o.t5, mulmod(i.t1, 9416416589114508529880440146952102328470363729880726115521103179442988482948, q), q);
        o.t5 = addmod(o.t5, mulmod(i.t2, 8035240799672199706102747147502951589635001418759394863664434079699838251138, q), q);
        o.t5 = addmod(o.t5, mulmod(i.t3, 21642389080762222565487157652540372010968704000567605990102641816691459811717, q), q);
        o.t5 = addmod(o.t5, mulmod(i.t4, 20261355950827657195644012399234591122288573679402601053407151083849785332516, q), q);
        o.t5 = addmod(o.t5, mulmod(i.t5, 14514189384576734449268559374569145463190040567900950075547616936149781403109, q), q);
        o.t5 = addmod(o.t5, mulmod(i.t6, 19038036134886073991945204537416211699632292792787812530208911676638479944765, q), q);
        o.t6 = mulmod(i.t0, 15627836782263662543041758927100784213807648787083018234961118439434298020664, q);
        o.t6 = addmod(o.t6, mulmod(i.t1, 5655785191024506056588710805596292231240948371113351452712848652644610823632, q), q);
        o.t6 = addmod(o.t6, mulmod(i.t2, 8265264721707292643644260517162050867559314081394556886644673791575065394002, q), q);
        o.t6 = addmod(o.t6, mulmod(i.t3, 17151144681903609082202835646026478898625761142991787335302962548605510241586, q), q);
        o.t6 = addmod(o.t6, mulmod(i.t4, 18731644709777529787185361516475509623264209648904603914668024590231177708831, q), q);
        o.t6 = addmod(o.t6, mulmod(i.t5, 20697789991623248954020701081488146717484139720322034504511115160686216223641, q), q);
        o.t6 = addmod(o.t6, mulmod(i.t6, 6200020095464686209289974437830528853749866001482481427982839122465470640886, q), q);
        i.t0 = o.t0;
        i.t1 = o.t1;
        i.t2 = o.t2;
        i.t3 = o.t3;
        i.t4 = o.t4;
        i.t5 = o.t5;
        i.t6 = o.t6;
    }

    function ark(HashInputs7 memory i, uint q, uint c) internal pure
    {
        HashInputs7 memory o;
        o.t0 = addmod(i.t0, c, q);
        o.t1 = addmod(i.t1, c, q);
        o.t2 = addmod(i.t2, c, q);
        o.t3 = addmod(i.t3, c, q);
        o.t4 = addmod(i.t4, c, q);
        o.t5 = addmod(i.t5, c, q);
        o.t6 = addmod(i.t6, c, q);
        i.t0 = o.t0;
        i.t1 = o.t1;
        i.t2 = o.t2;
        i.t3 = o.t3;
        i.t4 = o.t4;
        i.t5 = o.t5;
        i.t6 = o.t6;
    }

    function sbox_full(HashInputs7 memory i, uint q) internal pure
    {
        HashInputs7 memory o;
        o.t0 = mulmod(i.t0, i.t0, q);
        o.t0 = mulmod(o.t0, o.t0, q);
        o.t0 = mulmod(i.t0, o.t0, q);
        o.t1 = mulmod(i.t1, i.t1, q);
        o.t1 = mulmod(o.t1, o.t1, q);
        o.t1 = mulmod(i.t1, o.t1, q);
        o.t2 = mulmod(i.t2, i.t2, q);
        o.t2 = mulmod(o.t2, o.t2, q);
        o.t2 = mulmod(i.t2, o.t2, q);
        o.t3 = mulmod(i.t3, i.t3, q);
        o.t3 = mulmod(o.t3, o.t3, q);
        o.t3 = mulmod(i.t3, o.t3, q);
        o.t4 = mulmod(i.t4, i.t4, q);
        o.t4 = mulmod(o.t4, o.t4, q);
        o.t4 = mulmod(i.t4, o.t4, q);
        o.t5 = mulmod(i.t5, i.t5, q);
        o.t5 = mulmod(o.t5, o.t5, q);
        o.t5 = mulmod(i.t5, o.t5, q);
        o.t6 = mulmod(i.t6, i.t6, q);
        o.t6 = mulmod(o.t6, o.t6, q);
        o.t6 = mulmod(i.t6, o.t6, q);
        i.t0 = o.t0;
        i.t1 = o.t1;
        i.t2 = o.t2;
        i.t3 = o.t3;
        i.t4 = o.t4;
        i.t5 = o.t5;
        i.t6 = o.t6;
    }

    function sbox_partial(HashInputs7 memory i, uint q) internal pure
    {
        HashInputs7 memory o;
        o.t0 = mulmod(i.t0, i.t0, q);
        o.t0 = mulmod(o.t0, o.t0, q);
        o.t0 = mulmod(i.t0, o.t0, q);
        i.t0 = o.t0;
    }

    function hash_t7f6p52(HashInputs7 memory i, uint q) internal pure returns (uint)
    {
        // validate inputs
        require(i.t0 < q, "INVALID_INPUT");
        require(i.t1 < q, "INVALID_INPUT");
        require(i.t2 < q, "INVALID_INPUT");
        require(i.t3 < q, "INVALID_INPUT");
        require(i.t4 < q, "INVALID_INPUT");
        require(i.t5 < q, "INVALID_INPUT");
        require(i.t6 < q, "INVALID_INPUT");

        // round 0
        ark(i, q, 14397397413755236225575615486459253198602422701513067526754101844196324375522);
        sbox_full(i, q);
        mix(i, q);
        // round 1
        ark(i, q, 10405129301473404666785234951972711717481302463898292859783056520670200613128);
        sbox_full(i, q);
        mix(i, q);
        // round 2
        ark(i, q, 5179144822360023508491245509308555580251733042407187134628755730783052214509);
        sbox_full(i, q);
        mix(i, q);
        // round 3
        ark(i, q, 9132640374240188374542843306219594180154739721841249568925550236430986592615);
        sbox_partial(i, q);
        mix(i, q);
        // round 4
        ark(i, q, 20360807315276763881209958738450444293273549928693737723235350358403012458514);
        sbox_partial(i, q);
        mix(i, q);
        // round 5
        ark(i, q, 17933600965499023212689924809448543050840131883187652471064418452962948061619);
        sbox_partial(i, q);
        mix(i, q);
        // round 6
        ark(i, q, 3636213416533737411392076250708419981662897009810345015164671602334517041153);
        sbox_partial(i, q);
        mix(i, q);
        // round 7
        ark(i, q, 2008540005368330234524962342006691994500273283000229509835662097352946198608);
        sbox_partial(i, q);
        mix(i, q);
        // round 8
        ark(i, q, 16018407964853379535338740313053768402596521780991140819786560130595652651567);
        sbox_partial(i, q);
        mix(i, q);
        // round 9
        ark(i, q, 20653139667070586705378398435856186172195806027708437373983929336015162186471);
        sbox_partial(i, q);
        mix(i, q);
        // round 10
        ark(i, q, 17887713874711369695406927657694993484804203950786446055999405564652412116765);
        sbox_partial(i, q);
        mix(i, q);
        // round 11
        ark(i, q, 4852706232225925756777361208698488277369799648067343227630786518486608711772);
        sbox_partial(i, q);
        mix(i, q);
        // round 12
        ark(i, q, 8969172011633935669771678412400911310465619639756845342775631896478908389850);
        sbox_partial(i, q);
        mix(i, q);
        // round 13
        ark(i, q, 20570199545627577691240476121888846460936245025392381957866134167601058684375);
        sbox_partial(i, q);
        mix(i, q);
        // round 14
        ark(i, q, 16442329894745639881165035015179028112772410105963688121820543219662832524136);
        sbox_partial(i, q);
        mix(i, q);
        // round 15
        ark(i, q, 20060625627350485876280451423010593928172611031611836167979515653463693899374);
        sbox_partial(i, q);
        mix(i, q);
        // round 16
        ark(i, q, 16637282689940520290130302519163090147511023430395200895953984829546679599107);
        sbox_partial(i, q);
        mix(i, q);
        // round 17
        ark(i, q, 15599196921909732993082127725908821049411366914683565306060493533569088698214);
        sbox_partial(i, q);
        mix(i, q);
        // round 18
        ark(i, q, 16894591341213863947423904025624185991098788054337051624251730868231322135455);
        sbox_partial(i, q);
        mix(i, q);
        // round 19
        ark(i, q, 1197934381747032348421303489683932612752526046745577259575778515005162320212);
        sbox_partial(i, q);
        mix(i, q);
        // round 20
        ark(i, q, 6172482022646932735745595886795230725225293469762393889050804649558459236626);
        sbox_partial(i, q);
        mix(i, q);
        // round 21
        ark(i, q, 21004037394166516054140386756510609698837211370585899203851827276330669555417);
        sbox_partial(i, q);
        mix(i, q);
        // round 22
        ark(i, q, 15262034989144652068456967541137853724140836132717012646544737680069032573006);
        sbox_partial(i, q);
        mix(i, q);
        // round 23
        ark(i, q, 15017690682054366744270630371095785995296470601172793770224691982518041139766);
        sbox_partial(i, q);
        mix(i, q);
        // round 24
        ark(i, q, 15159744167842240513848638419303545693472533086570469712794583342699782519832);
        sbox_partial(i, q);
        mix(i, q);
        // round 25
        ark(i, q, 11178069035565459212220861899558526502477231302924961773582350246646450941231);
        sbox_partial(i, q);
        mix(i, q);
        // round 26
        ark(i, q, 21154888769130549957415912997229564077486639529994598560737238811887296922114);
        sbox_partial(i, q);
        mix(i, q);
        // round 27
        ark(i, q, 20162517328110570500010831422938033120419484532231241180224283481905744633719);
        sbox_partial(i, q);
        mix(i, q);
        // round 28
        ark(i, q, 2777362604871784250419758188173029886707024739806641263170345377816177052018);
        sbox_partial(i, q);
        mix(i, q);
        // round 29
        ark(i, q, 15732290486829619144634131656503993123618032247178179298922551820261215487562);
        sbox_partial(i, q);
        mix(i, q);
        // round 30
        ark(i, q, 6024433414579583476444635447152826813568595303270846875177844482142230009826);
        sbox_partial(i, q);
        mix(i, q);
        // round 31
        ark(i, q, 17677827682004946431939402157761289497221048154630238117709539216286149983245);
        sbox_partial(i, q);
        mix(i, q);
        // round 32
        ark(i, q, 10716307389353583413755237303156291454109852751296156900963208377067748518748);
        sbox_partial(i, q);
        mix(i, q);
        // round 33
        ark(i, q, 14925386988604173087143546225719076187055229908444910452781922028996524347508);
        sbox_partial(i, q);
        mix(i, q);
        // round 34
        ark(i, q, 8940878636401797005293482068100797531020505636124892198091491586778667442523);
        sbox_partial(i, q);
        mix(i, q);
        // round 35
        ark(i, q, 18911747154199663060505302806894425160044925686870165583944475880789706164410);
        sbox_partial(i, q);
        mix(i, q);
        // round 36
        ark(i, q, 8821532432394939099312235292271438180996556457308429936910969094255825456935);
        sbox_partial(i, q);
        mix(i, q);
        // round 37
        ark(i, q, 20632576502437623790366878538516326728436616723089049415538037018093616927643);
        sbox_partial(i, q);
        mix(i, q);
        // round 38
        ark(i, q, 71447649211767888770311304010816315780740050029903404046389165015534756512);
        sbox_partial(i, q);
        mix(i, q);
        // round 39
        ark(i, q, 2781996465394730190470582631099299305677291329609718650018200531245670229393);
        sbox_partial(i, q);
        mix(i, q);
        // round 40
        ark(i, q, 12441376330954323535872906380510501637773629931719508864016287320488688345525);
        sbox_partial(i, q);
        mix(i, q);
        // round 41
        ark(i, q, 2558302139544901035700544058046419714227464650146159803703499681139469546006);
        sbox_partial(i, q);
        mix(i, q);
        // round 42
        ark(i, q, 10087036781939179132584550273563255199577525914374285705149349445480649057058);
        sbox_partial(i, q);
        mix(i, q);
        // round 43
        ark(i, q, 4267692623754666261749551533667592242661271409704769363166965280715887854739);
        sbox_partial(i, q);
        mix(i, q);
        // round 44
        ark(i, q, 4945579503584457514844595640661884835097077318604083061152997449742124905548);
        sbox_partial(i, q);
        mix(i, q);
        // round 45
        ark(i, q, 17742335354489274412669987990603079185096280484072783973732137326144230832311);
        sbox_partial(i, q);
        mix(i, q);
        // round 46
        ark(i, q, 6266270088302506215402996795500854910256503071464802875821837403486057988208);
        sbox_partial(i, q);
        mix(i, q);
        // round 47
        ark(i, q, 2716062168542520412498610856550519519760063668165561277991771577403400784706);
        sbox_partial(i, q);
        mix(i, q);
        // round 48
        ark(i, q, 19118392018538203167410421493487769944462015419023083813301166096764262134232);
        sbox_partial(i, q);
        mix(i, q);
        // round 49
        ark(i, q, 9386595745626044000666050847309903206827901310677406022353307960932745699524);
        sbox_partial(i, q);
        mix(i, q);
        // round 50
        ark(i, q, 9121640807890366356465620448383131419933298563527245687958865317869840082266);
        sbox_partial(i, q);
        mix(i, q);
        // round 51
        ark(i, q, 3078975275808111706229899605611544294904276390490742680006005661017864583210);
        sbox_partial(i, q);
        mix(i, q);
        // round 52
        ark(i, q, 7157404299437167354719786626667769956233708887934477609633504801472827442743);
        sbox_partial(i, q);
        mix(i, q);
        // round 53
        ark(i, q, 14056248655941725362944552761799461694550787028230120190862133165195793034373);
        sbox_partial(i, q);
        mix(i, q);
        // round 54
        ark(i, q, 14124396743304355958915937804966111851843703158171757752158388556919187839849);
        sbox_partial(i, q);
        mix(i, q);
        // round 55
        ark(i, q, 11851254356749068692552943732920045260402277343008629727465773766468466181076);
        sbox_full(i, q);
        mix(i, q);
        // round 56
        ark(i, q, 9799099446406796696742256539758943483211846559715874347178722060519817626047);
        sbox_full(i, q);
        mix(i, q);
        // round 57
        ark(i, q, 10156146186214948683880719664738535455146137901666656566575307300522957959544);
        sbox_full(i, q);
        mix(i, q);

        return i.t0;
    }

}

// File: contracts/core/impl/libexchange/ExchangeBalances.sol

// Copyright 2017 Loopring Technology Limited.






/// @title ExchangeBalances.
/// @author Daniel Wang  - <[email protected]>
/// @author Brecht Devos - <[email protected]>
library ExchangeBalances
{
    using ExchangeTokens  for uint16;
    using MathUint        for uint;

    function verifyAccountBalance(
        uint                              merkleRoot,
        ExchangeData.MerkleProof calldata merkleProof
        )
        public
        pure
    {
        require(
            isAccountBalanceCorrect(merkleRoot, merkleProof),
            "INVALID_MERKLE_TREE_DATA"
        );
    }

    function isAccountBalanceCorrect(
        uint                            merkleRoot,
        ExchangeData.MerkleProof memory merkleProof
        )
        public
        pure
        returns (bool)
    {
        // Calculate the Merkle root using the Merkle paths provided
        uint calculatedRoot = getBalancesRoot(
            merkleProof.balanceLeaf.tokenID,
            merkleProof.balanceLeaf.balance,
            merkleProof.balanceLeaf.weightAMM,
            merkleProof.balanceLeaf.storageRoot,
            merkleProof.balanceMerkleProof
        );
        calculatedRoot = getAccountInternalsRoot(
            merkleProof.accountLeaf.accountID,
            merkleProof.accountLeaf.owner,
            merkleProof.accountLeaf.pubKeyX,
            merkleProof.accountLeaf.pubKeyY,
            merkleProof.accountLeaf.nonce,
            merkleProof.accountLeaf.feeBipsAMM,
            calculatedRoot,
            merkleProof.accountMerkleProof
        );

        if (merkleProof.balanceLeaf.tokenID.isNFT()) {
            // Verify the NFT data
            uint minter = uint(merkleProof.nft.minter);
            uint nftType = uint(merkleProof.nft.nftType);
            uint token = uint(merkleProof.nft.token);
            uint nftIDLo = merkleProof.nft.nftID & 0xffffffffffffffffffffffffffffffff;
            uint nftIDHi = merkleProof.nft.nftID >> 128;
            uint creatorFeeBips = merkleProof.nft.creatorFeeBips;
            Poseidon.HashInputs7 memory inputs = Poseidon.HashInputs7(
                minter,
                nftType,
                token,
                nftIDLo,
                nftIDHi,
                creatorFeeBips,
                0
            );
            uint nftData = Poseidon.hash_t7f6p52(inputs, ExchangeData.SNARK_SCALAR_FIELD);
            if (nftData != merkleProof.balanceLeaf.weightAMM) {
                return false;
            }
        }

        // Check against the expected Merkle root
        return (calculatedRoot == merkleRoot);
    }

    function getBalancesRoot(
        uint16   tokenID,
        uint     balance,
        uint     weightAMM,
        uint     storageRoot,
        uint[24] memory balanceMerkleProof
        )
        private
        pure
        returns (uint)
    {
        // Hash the balance leaf
        uint balanceItem = hashImpl(balance, weightAMM, storageRoot, 0);
        // Calculate the Merkle root of the balance quad Merkle tree
        uint _id = tokenID;
        for (uint depth = 0; depth < 8; depth++) {
            uint base = depth * 3;
            if (_id & 3 == 0) {
                balanceItem = hashImpl(
                    balanceItem,
                    balanceMerkleProof[base],
                    balanceMerkleProof[base + 1],
                    balanceMerkleProof[base + 2]
                );
            } else if (_id & 3 == 1) {
                balanceItem = hashImpl(
                    balanceMerkleProof[base],
                    balanceItem,
                    balanceMerkleProof[base + 1],
                    balanceMerkleProof[base + 2]
                );
            } else if (_id & 3 == 2) {
                balanceItem = hashImpl(
                    balanceMerkleProof[base],
                    balanceMerkleProof[base + 1],
                    balanceItem,
                    balanceMerkleProof[base + 2]
                );
            } else if (_id & 3 == 3) {
                balanceItem = hashImpl(
                    balanceMerkleProof[base],
                    balanceMerkleProof[base + 1],
                    balanceMerkleProof[base + 2],
                    balanceItem
                );
            }
            _id = _id >> 2;
        }
        return balanceItem;
    }

    function getAccountInternalsRoot(
        uint32   accountID,
        address  owner,
        uint     pubKeyX,
        uint     pubKeyY,
        uint     nonce,
        uint     feeBipsAMM,
        uint     balancesRoot,
        uint[48] memory accountMerkleProof
        )
        private
        pure
        returns (uint)
    {
        // Hash the account leaf
        uint accountItem = hashAccountLeaf(uint(owner), pubKeyX, pubKeyY, nonce, feeBipsAMM, balancesRoot);
        // Calculate the Merkle root of the account quad Merkle tree
        uint _id = accountID;
        for (uint depth = 0; depth < 16; depth++) {
            uint base = depth * 3;
            if (_id & 3 == 0) {
                accountItem = hashImpl(
                    accountItem,
                    accountMerkleProof[base],
                    accountMerkleProof[base + 1],
                    accountMerkleProof[base + 2]
                );
            } else if (_id & 3 == 1) {
                accountItem = hashImpl(
                    accountMerkleProof[base],
                    accountItem,
                    accountMerkleProof[base + 1],
                    accountMerkleProof[base + 2]
                );
            } else if (_id & 3 == 2) {
                accountItem = hashImpl(
                    accountMerkleProof[base],
                    accountMerkleProof[base + 1],
                    accountItem,
                    accountMerkleProof[base + 2]
                );
            } else if (_id & 3 == 3) {
                accountItem = hashImpl(
                    accountMerkleProof[base],
                    accountMerkleProof[base + 1],
                    accountMerkleProof[base + 2],
                    accountItem
                );
            }
            _id = _id >> 2;
        }
        return accountItem;
    }

    function hashAccountLeaf(
        uint t0,
        uint t1,
        uint t2,
        uint t3,
        uint t4,
        uint t5
        )
        public
        pure
        returns (uint)
    {
        Poseidon.HashInputs7 memory inputs = Poseidon.HashInputs7(t0, t1, t2, t3, t4, t5, 0);
        return Poseidon.hash_t7f6p52(inputs, ExchangeData.SNARK_SCALAR_FIELD);
    }

    function hashImpl(
        uint t0,
        uint t1,
        uint t2,
        uint t3
        )
        private
        pure
        returns (uint)
    {
        Poseidon.HashInputs5 memory inputs = Poseidon.HashInputs5(t0, t1, t2, t3, 0);
        return Poseidon.hash_t5f6p52(inputs, ExchangeData.SNARK_SCALAR_FIELD);
    }
}

// File: contracts/core/iface/IL2MintableNFT.sol

// Copyright 2017 Loopring Technology Limited.


interface IL2MintableNFT
{
    /// @dev This function is called when an NFT minted on L2 is withdrawn from Loopring.
    ///      That means the NFTs were burned on L2 and now need to be minted on L1.
    ///
    ///      This function can only be called by the Loopring exchange.
    ///
    /// @param to The owner of the NFT
    /// @param tokenId The token type 'id`
    /// @param amount The amount of NFTs to mint
    /// @param minter The minter on L2, which can be used to decide if the NFT is authentic
    /// @param data Opaque data that can be used by the contract
    function mintFromL2(
        address          to,
        uint256          tokenId,
        uint             amount,
        address          minter,
        bytes   calldata data
        )
        external;

    /// @dev Returns a list of all address that are authorized to mint NFTs on L2.
    /// @return The list of authorized minter on L2
    function minters()
        external
        view
        returns (address[] memory);
}

// File: contracts/thirdparty/erc165/IERC165.sol



/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: contracts/thirdparty/erc165/ERC165.sol




/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: contracts/thirdparty/erc1155/IERC1155.sol




/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// File: contracts/thirdparty/erc721/IERC721.sol




/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: contracts/core/impl/libexchange/ExchangeNFT.sol

// Copyright 2017 Loopring Technology Limited.







/// @title ExchangeNFT
/// @author Brecht Devos - <[email protected]>
library ExchangeNFT
{
    using ExchangeNFT for ExchangeData.State;
    using AddressUtil for address;

    function deposit(
        ExchangeData.State storage S,
        address                    from,
        ExchangeData.NftType       nftType,
        address                    token,
        uint256                    nftID,
        uint                       amount,
        bytes              memory  extraData
        )
        internal
    {
        if (amount == 0) {
            return;
        }

        // Disable calls to certain contracts
        require(S.isTokenAddressAllowed(token), "TOKEN_ADDRESS_NOT_ALLOWED");

        if (nftType == ExchangeData.NftType.ERC1155) {
            IERC1155(token).safeTransferFrom(
                from,
                address(this),
                nftID,
                amount,
                extraData
            );
        } else if (nftType == ExchangeData.NftType.ERC721) {
            require(amount == 1, "INVALID_AMOUNT");
            IERC721(token).safeTransferFrom(
                from,
                address(this),
                nftID,
                extraData
            );
        } else {
            revert("UNKNOWN_NFTTYPE");
        }
    }

    function withdraw(
        ExchangeData.State storage S,
        address              /*from*/,
        address              to,
        ExchangeData.NftType nftType,
        address              token,
        uint256              nftID,
        uint                 amount,
        bytes   memory       extraData,
        uint                 gasLimit
        )
        internal
        returns (bool success)
    {
        if (amount == 0) {
            return true;
        }

        // Disable calls to certain contracts
        if(!S.isTokenAddressAllowed(token)) {
            return false;
        }

        if (nftType == ExchangeData.NftType.ERC1155) {
            try IERC1155(token).safeTransferFrom{gas: gasLimit}(
                address(this),
                to,
                nftID,
                amount,
                extraData
            ) {
                success = true;
            } catch {
                success = false;
            }
        } else if (nftType == ExchangeData.NftType.ERC721) {
            try IERC721(token).safeTransferFrom{gas: gasLimit}(
                address(this),
                to,
                nftID,
                extraData
            ) {
                success = true;
            } catch {
                success = false;
            }
        } else {
            revert("UNKNOWN_NFTTYPE");
        }
    }

    function mintFromL2(
        ExchangeData.State storage S,
        address                    to,
        address                    token,
        uint256                    nftID,
        uint                       amount,
        address                    minter,
        bytes              memory  extraData,
        uint                       gasLimit
        )
        internal
        returns (bool success)
    {
        if (amount == 0) {
            return true;
        }

        // Disable calls to certain contracts
        if(!S.isTokenAddressAllowed(token)) {
            return false;
        }

        try IL2MintableNFT(token).mintFromL2{gas: gasLimit}(
            to,
            nftID,
            amount,
            minter,
            extraData
        ) {
            success = true;
        } catch {
            success = false;
        }
    }

    function isTokenAddressAllowed(
        ExchangeData.State storage S,
        address                    token
        )
        internal
        view
        returns (bool valid)
    {
        return (token != address(this) && token != address(S.depositContract)) && token.isContract();
    }
}

// File: contracts/core/impl/libexchange/ExchangeWithdrawals.sol

// Copyright 2017 Loopring Technology Limited.









/// @title ExchangeWithdrawals.
/// @author Brecht Devos - <[email protected]oopring.org>
/// @author Daniel Wang  - <[email protected]>
library ExchangeWithdrawals
{
    enum WithdrawalCategory
    {
        DISTRIBUTION,
        FROM_MERKLE_TREE,
        FROM_DEPOSIT_REQUEST,
        FROM_APPROVED_WITHDRAWAL
    }

    using AddressUtil       for address;
    using AddressUtil       for address payable;
    using BytesUtil         for bytes;
    using MathUint          for uint;
    using ExchangeBalances  for ExchangeData.State;
    using ExchangeMode      for ExchangeData.State;
    using ExchangeTokens    for ExchangeData.State;
    using ExchangeTokens    for uint16;

    event ForcedWithdrawalRequested(
        address owner,
        uint16  tokenID,    // ERC20 token ID ( if < NFT_TOKEN_ID_START) or
                            // NFT balance slot (if >= NFT_TOKEN_ID_START)
        uint32  accountID
    );

    event WithdrawalCompleted(
        uint8   category,
        address from,
        address to,
        address token,
        uint    amount
    );

    event WithdrawalFailed(
        uint8   category,
        address from,
        address to,
        address token,
        uint    amount
    );

    event NftWithdrawalCompleted(
        uint8   category,
        address from,
        address to,
        uint16  tokenID,
        address token,
        uint256 nftID,
        uint    amount
    );

    event NftWithdrawalFailed(
        uint8   category,
        address from,
        address to,
        uint16  tokenID,
        address token,
        uint256 nftID,
        uint    amount
    );

    function forceWithdraw(
        ExchangeData.State storage S,
        address                    owner,
        uint16                     tokenID, // ERC20 token ID ( if < NFT_TOKEN_ID_START) or
                                            // NFT balance slot (if >= NFT_TOKEN_ID_START)
        uint32                     accountID
        )
        public
    {
        require(!S.isInWithdrawalMode(), "INVALID_MODE");
        // Limit the amount of pending forced withdrawals so that the owner cannot be overwhelmed.
        require(S.getNumAvailableForcedSlots() > 0, "TOO_MANY_REQUESTS_OPEN");
        require(accountID < ExchangeData.MAX_NUM_ACCOUNTS, "INVALID_ACCOUNTID");
        // Only allow withdrawing from registered ERC20 tokens or NFT tokenIDs
        require(
            tokenID < S.tokens.length ||                 // ERC20
            tokenID.isNFT(),  // NFT
            "INVALID_TOKENID"
        );

        // A user needs to pay a fixed ETH withdrawal fee, set by the protocol.
        uint withdrawalFeeETH = S.loopring.forcedWithdrawalFee();

        // Check ETH value sent, can be larger than the expected withdraw fee
        require(msg.value >= withdrawalFeeETH, "INSUFFICIENT_FEE");

        // Send surplus of ETH back to the sender
        uint feeSurplus = msg.value.sub(withdrawalFeeETH);
        if (feeSurplus > 0) {
            msg.sender.sendETHAndVerify(feeSurplus, gasleft());
        }

        // There can only be a single forced withdrawal per (account, token) pair.
        require(
            S.pendingForcedWithdrawals[accountID][tokenID].timestamp == 0,
            "WITHDRAWAL_ALREADY_PENDING"
        );

        // Store the forced withdrawal request data
        S.pendingForcedWithdrawals[accountID][tokenID] = ExchangeData.ForcedWithdrawal({
            owner: owner,
            timestamp: uint64(block.timestamp)
        });

        // Increment the number of pending forced transactions so we can keep count.
        S.numPendingForcedTransactions++;

        emit ForcedWithdrawalRequested(
            owner,
            tokenID,
            accountID
        );
    }

    // We alow anyone to withdraw these funds for the account owner
    function withdrawFromMerkleTree(
        ExchangeData.State       storage  S,
        ExchangeData.MerkleProof calldata merkleProof
        )
        public
    {
        require(S.isInWithdrawalMode(), "NOT_IN_WITHDRAW_MODE");

        address owner = merkleProof.accountLeaf.owner;
        uint32 accountID = merkleProof.accountLeaf.accountID;
        uint16 tokenID = merkleProof.balanceLeaf.tokenID;
        uint96 balance = merkleProof.balanceLeaf.balance;

        // Make sure the funds aren't withdrawn already.
        require(S.withdrawnInWithdrawMode[accountID][tokenID] == false, "WITHDRAWN_ALREADY");

        // Verify that the provided Merkle tree data is valid by using the Merkle proof.
        ExchangeBalances.verifyAccountBalance(
            uint(S.merkleRoot),
            merkleProof
        );

        // Make sure the balance can only be withdrawn once
        S.withdrawnInWithdrawMode[accountID][tokenID] = true;

        if (!tokenID.isNFT()) {
            require(
                merkleProof.nft.nftID == 0 && merkleProof.nft.minter == address(0),
                "NOT_AN_NFT"
            );
            // Transfer the tokens to the account owner
            transferTokens(
                S,
                uint8(WithdrawalCategory.FROM_MERKLE_TREE),
                owner,
                owner,
                tokenID,
                balance,
                new bytes(0),
                gasleft(),
                false
            );
        } else {
            transferNFTs(
                S,
                uint8(WithdrawalCategory.DISTRIBUTION),
                owner,
                owner,
                tokenID,
                balance,
                merkleProof.nft,
                new bytes(0),
                gasleft(),
                false
            );
        }
    }

    function withdrawFromDepositRequest(
        ExchangeData.State storage S,
        address                    owner,
        address                    token
        )
        public
    {
        uint16 tokenID = S.getTokenID(token);
        ExchangeData.Deposit storage deposit = S.pendingDeposits[owner][tokenID];
        require(deposit.timestamp != 0, "DEPOSIT_NOT_WITHDRAWABLE_YET");

        // Check if the deposit has indeed exceeded the time limit of if the exchange is in withdrawal mode
        require(
            block.timestamp >= deposit.timestamp + S.maxAgeDepositUntilWithdrawable ||
            S.isInWithdrawalMode(),
            "DEPOSIT_NOT_WITHDRAWABLE_YET"
        );

        uint amount = deposit.amount;

        // Reset the deposit request
        delete S.pendingDeposits[owner][tokenID];

        // Transfer the tokens
        transferTokens(
            S,
            uint8(WithdrawalCategory.FROM_DEPOSIT_REQUEST),
            owner,
            owner,
            tokenID,
            amount,
            new bytes(0),
            gasleft(),
            false
        );
    }

    function withdrawFromNFTDepositRequest(
        ExchangeData.State storage S,
        address                    owner,
        address                    token,
        ExchangeData.NftType       nftType,
        uint256                    nftID
        )
        public
    {
        ExchangeData.Deposit storage deposit = S.pendingNFTDeposits[owner][nftType][token][nftID];
        require(deposit.timestamp != 0, "DEPOSIT_NOT_WITHDRAWABLE_YET");

        // Check if the deposit has indeed exceeded the time limit of if the exchange is in withdrawal mode
        require(
            block.timestamp >= deposit.timestamp + S.maxAgeDepositUntilWithdrawable ||
            S.isInWithdrawalMode(),
            "DEPOSIT_NOT_WITHDRAWABLE_YET"
        );

        uint amount = deposit.amount;

        // Reset the deposit request
        delete S.pendingNFTDeposits[owner][nftType][token][nftID];

        ExchangeData.Nft memory nft = ExchangeData.Nft({
            minter: token,
            nftType: nftType,
            token: token,
            nftID: nftID,
            creatorFeeBips: 0
        });

        // Transfer the NFTs
        transferNFTs(
            S,
            uint8(WithdrawalCategory.FROM_DEPOSIT_REQUEST),
            owner,
            owner,
            0,
            amount,
            nft,
            new bytes(0),
            gasleft(),
            false
        );
    }

    function withdrawFromApprovedWithdrawals(
        ExchangeData.State storage S,
        address[]          memory  owners,
        address[]          memory  tokens
        )
        public
    {
        require(owners.length == tokens.length, "INVALID_INPUT_DATA");
        for (uint i = 0; i < owners.length; i++) {
            address owner = owners[i];
            uint16 tokenID = S.getTokenID(tokens[i]);
            uint amount = S.amountWithdrawable[owner][tokenID];

            // Make sure this amount can't be withdrawn again
            delete S.amountWithdrawable[owner][tokenID];

            // Transfer the tokens to the owner
            transferTokens(
                S,
                uint8(WithdrawalCategory.FROM_APPROVED_WITHDRAWAL),
                owner,
                owner,
                tokenID,
                amount,
                new bytes(0),
                gasleft(),
                false
            );
        }
    }

    function withdrawFromApprovedWithdrawalsNFT(
        ExchangeData.State     storage S,
        address[]              memory  owners,
        address[]              memory  minters,
        ExchangeData.NftType[] memory  nftTypes,
        address[]              memory  tokens,
        uint256[]              memory  nftIDs
        )
        public
    {
        require(owners.length == minters.length, "INVALID_INPUT_DATA_MINTERS");
        require(owners.length == nftTypes.length, "INVALID_INPUT_DATA_NFTTYPES");
        require(owners.length == tokens.length, "INVALID_INPUT_DATA_TOKENS");
        require(owners.length == nftIDs.length, "INVALID_INPUT_DATA_CONTENT_URIS");
        for (uint i = 0; i < owners.length; i++) {
            address owner = owners[i];
            address minter = minters[i];
            ExchangeData.NftType nftType = nftTypes[i];
            address token = tokens[i];
            uint256 nftID = nftIDs[i];
            uint amount = S.amountWithdrawableNFT[owner][minter][nftType][token][nftID];

            // Make sure this amount can't be withdrawn again
            delete S.amountWithdrawableNFT[owner][minter][nftType][token][nftID];

            ExchangeData.Nft memory nft = ExchangeData.Nft({
                minter: minter,
                nftType: nftType,
                token: token,
                nftID: nftID,
                creatorFeeBips: 0
            });

            // Transfer the NFTs to the owner
            transferNFTs(
                S,
                uint8(WithdrawalCategory.DISTRIBUTION),
                owner,
                owner,
                0,
                amount,
                nft,
                new bytes(0),
                gasleft(),
                false
            );
        }
    }

    function distributeWithdrawal(
        ExchangeData.State storage S,
        address                    from,
        address                    to,
        uint16                     tokenID,
        uint                       amount,
        bytes              memory  extraData,
        uint                       gasLimit,
        ExchangeData.Nft   memory  nft
        )
        public
    {
        if (!tokenID.isNFT()) {
            // Try to transfer the tokens
            if (!transferTokens(
                S,
                uint8(WithdrawalCategory.DISTRIBUTION),
                from,
                to,
                tokenID,
                amount,
                extraData,
                gasLimit,
                true
            )) {
                // If the transfer was successful there's nothing left to do.
                // However, if the transfer failed the tokens are still in the contract and can be
                // withdrawn later to `to` by anyone by using `withdrawFromApprovedWithdrawal.
                S.amountWithdrawable[to][tokenID] = S.amountWithdrawable[to][tokenID].add(amount);
            }
        } else {
            // Try to transfer the tokens
            if (!transferNFTs(
                S,
                uint8(WithdrawalCategory.DISTRIBUTION),
                from,
                to,
                tokenID,
                amount,
                nft,
                extraData,
                gasLimit,
                true
            )) {
                // If the transfer was successful there's nothing left to do.
                // However, if the transfer failed the tokens are still in the contract and can be
                // withdrawn later to `to` by anyone by using `withdrawFromApprovedNftWithdrawal.
                S.amountWithdrawableNFT[to][nft.minter][nft.nftType][nft.token][nft.nftID] =
                    S.amountWithdrawableNFT[to][nft.minter][nft.nftType][nft.token][nft.nftID].add(amount);
            }
        }
    }

    // == Internal and Private Functions ==

    // If allowFailure is true the transfer can fail because of a transfer error or
    // because the transfer uses more than `gasLimit` gas. The function
    // will return true when successful, false otherwise.
    // If allowFailure is false the transfer is guaranteed to succeed using
    // as much gas as needed, otherwise it throws. The function always returns true.
    function transferTokens(
        ExchangeData.State storage S,
        uint8                      category,
        address                    from,
        address                    to,
        uint16                     tokenID,
        uint                       amount,
        bytes              memory  extraData,
        uint                       gasLimit,
        bool                       allowFailure
        )
        private
        returns (bool success)
    {
        // Redirect withdrawals to address(0) to the protocol fee vault
        if (to == address(0)) {
            to = S.loopring.protocolFeeVault();
        }
        address token = S.getTokenAddress(tokenID);

        // Transfer the tokens from the deposit contract to the owner
        if (gasLimit > 0) {
            try S.depositContract.withdraw{gas: gasLimit}(from, to, token, amount, extraData) {
                success = true;
            } catch {
                success = false;
            }
        } else {
            success = false;
        }

        require(allowFailure || success, "TRANSFER_FAILURE");

        if (success) {
            emit WithdrawalCompleted(category, from, to, token, amount);

            // Keep track of when the protocol fees were last withdrawn
            // (only done to make this data easier available).
            if (from == address(0)) {
                S.protocolFeeLastWithdrawnTime[token] = block.timestamp;
            }
        } else {
            emit WithdrawalFailed(category, from, to, token, amount);
        }
    }

    // If allowFailure is true the transfer can fail because of a transfer error or
    // because the transfer uses more than `gasLimit` gas. The function
    // will return true when successful, false otherwise.
    // If allowFailure is false the transfer is guaranteed to succeed using
    // as much gas as needed, otherwise it throws. The function always returns true.
    function transferNFTs(
        ExchangeData.State storage S,
        uint8                      category,
        address                    from,
        address                    to,
        uint16                     tokenID,
        uint                       amount,
        ExchangeData.Nft   memory  nft,
        bytes              memory  extraData,
        uint                       gasLimit,
        bool                       allowFailure
        )
        private
        returns (bool success)
    {
        if (gasLimit > 0) {
            if (nft.token == nft.minter) {
                // This is an existing thirdparty NFT contract
                success = ExchangeNFT.withdraw(
                    S,
                    from,
                    to,
                    nft.nftType,
                    nft.token,
                    nft.nftID,
                    amount,
                    extraData,
                    gasLimit
                );
            } else {
                // This is an NFT contract with L2 minting support
                success = ExchangeNFT.mintFromL2(
                    S,
                    to,
                    nft.token,
                    nft.nftID,
                    amount,
                    nft.minter,
                    extraData,
                    gasLimit
                );
            }
        } else {
            success = false;
        }

        require(allowFailure || success, "NFT_TRANSFER_FAILURE");

        if (success) {
            emit NftWithdrawalCompleted(category, from, to, tokenID, nft.token, nft.nftID, amount);
        } else {
            emit NftWithdrawalFailed(category, from, to, tokenID, nft.token, nft.nftID, amount);
        }
    }
}

// File: contracts/core/impl/libtransactions/NftDataTransaction.sol

// Copyright 2017 Loopring Technology Limited.





/// @title NftDataTransaction
/// @author Brecht Devos - <[email protected]>
library NftDataTransaction
{
    using BlockReader          for bytes;
    using BytesUtil            for bytes;

    // Read the data in two transactions, each containing partial data.
    // Each tx contains largely the same data (`nftID`, `nftType`, `creatorFeeBips`)
    // except when
    // type == SCHEME_WITH_TOKEN_ADDRESS -> bring `tokenAddress` to L1,
    // type == SCHEME_WITH_MINTER_ADDRESS -> bring `minter` to L1.
    enum NftDataScheme
    {
        SCHEME_WITH_MINTER_ADDRESS,
        SCHEME_WITH_TOKEN_ADDRESS
    }

    struct NftData
    {
        uint8                scheme;
        uint32               accountID;         // the `to` or `from` account's ID.
        uint16               tokenID;
        ExchangeData.Nft     nft;
    }

    function readTx(
        bytes   memory data,
        uint           offset,
        NftData memory nftData
        )
        internal
        pure
    {
        uint _offset = offset;

        require(
            data.toUint8Unsafe(_offset) == uint8(ExchangeData.TransactionType.NFT_DATA),
            "INVALID_TX_TYPE"
        );
        _offset += 1;

        nftData.scheme = data.toUint8Unsafe(_offset);
        _offset += 1;

        // Extract the transfer data
        // We don't use abi.decode for this because of the large amount of zero-padding
        // bytes the circuit would also have to hash.
        nftData.accountID = data.toUint32Unsafe(_offset);
        _offset += 4;
        nftData.tokenID = data.toUint16Unsafe(_offset);
        _offset += 2;
        nftData.nft.nftID = data.toUintUnsafe(_offset);
        _offset += 32;
        nftData.nft.creatorFeeBips = data.toUint8Unsafe(_offset);
        _offset += 1;
        nftData.nft.nftType = ExchangeData.NftType(data.toUint8Unsafe(_offset));
        _offset += 1;

        if (nftData.scheme == uint8(NftDataScheme.SCHEME_WITH_MINTER_ADDRESS)) {
            nftData.nft.minter = data.toAddressUnsafe(_offset);
        } else if (nftData.scheme == uint8(NftDataScheme.SCHEME_WITH_TOKEN_ADDRESS)) {
            nftData.nft.token = data.toAddressUnsafe(_offset);
        } else {
            revert("INVALID_NFT_DATA_SUBTYPE");
        }
        _offset += 20;
    }

    function readDualNftData(
        ExchangeData.BlockContext  memory ctx,
        uint32                            accountID,
        uint16                            tokenID,
        uint                              txIdx,
        NftDataTransaction.NftData memory nftData
        )
        internal
        pure
    {
        // There's 68 bytes we can use per transaction. The NFT data now contains
        // `hash(minter, nftType, tokenAddress, nftID, creatorFeeBips)`. So this data
        // needs txType + (1 byte) + minter (20 bytes) + nftType (1 byte) +
        // tokenAddress (20 bytes) + nftID (32 bytes) + creatorFeeBips (1 byte) = 76 bytes.
        // So 8 bytes too much to fit inside the available space in a single tx.
        readNftData(
            ctx,
            accountID,
            tokenID,
            txIdx,
            NftDataScheme.SCHEME_WITH_MINTER_ADDRESS,
            nftData
        );

        readNftData(
            ctx,
            accountID,
            tokenID,
            txIdx + 1,
            NftDataScheme.SCHEME_WITH_TOKEN_ADDRESS,
            nftData
        );
    }

    function readNftData(
        ExchangeData.BlockContext  memory ctx,
        uint32                            accountID,
        uint16                            tokenID,
        uint                              txOffset,
        NftDataScheme                     expectedScheme,
        NftDataTransaction.NftData memory nftData
        )
        private
        pure
    {
        // Read the NFT_DATA transaction
        bytes memory txData = new bytes(ExchangeData.TX_DATA_AVAILABILITY_SIZE);
        ctx.block.data.readTransactionData(txOffset, ctx.block.blockSize, txData);
        NftDataTransaction.readTx(txData, 0, nftData);

        // Make sure the NFT_DATA transaction pushes data on-chain
        // that matches the the tokens that are getting withdrawn
        require(
            nftData.scheme == uint8(expectedScheme) &&
            nftData.accountID == accountID &&
            nftData.tokenID == tokenID,
            "INVALID_NFT_DATA"
        );
    }
}

// File: contracts/core/impl/libtransactions/WithdrawTransaction.sol

// Copyright 2017 Loopring Technology Limited.














/// @title WithdrawTransaction
/// @author Brecht Devos - <[email protected]>
/// @dev The following 4 types of withdrawals are supported:
///      - withdrawType = 0: offchain withdrawals with EdDSA signatures
///      - withdrawType = 1: offchain withdrawals with ECDSA signatures or onchain appprovals
///      - withdrawType = 2: onchain valid forced withdrawals (owner and accountID match), or
///                          offchain operator-initiated withdrawals for protocol fees or for
///                          users in shutdown mode
///      - withdrawType = 3: onchain invalid forced withdrawals (owner and accountID mismatch)
library WithdrawTransaction
{
    using BlockReader          for bytes;
    using BytesUtil            for bytes;
    using FloatUtil            for uint16;
    using MathUint             for uint;
    using ExchangeMode         for ExchangeData.State;
    using ExchangeSignatures   for ExchangeData.State;
    using ExchangeTokens       for uint16;
    using ExchangeWithdrawals  for ExchangeData.State;

    bytes32 constant public WITHDRAWAL_TYPEHASH = keccak256(
        "Withdrawal(address owner,uint32 accountID,uint16 tokenID,uint96 amount,uint16 feeTokenID,uint96 maxFee,address to,bytes extraData,uint256 minGas,uint32 validUntil,uint32 storageID)"
    );

    struct Withdrawal
    {
        uint    withdrawalType;
        address from;
        uint32  fromAccountID;
        uint16  tokenID;
        uint96  amount;
        uint16  feeTokenID;
        uint96  maxFee;
        uint96  fee;
        address to;
        bytes   extraData;
        uint    minGas;
        uint32  validUntil;
        uint32  storageID;
        bytes20 onchainDataHash;
    }

    // Auxiliary data for each withdrawal
    struct WithdrawalAuxiliaryData
    {
        bool  storeRecipient;
        uint  gasLimit;
        bytes signature;

        uint    minGas;
        address to;
        bytes   extraData;
        uint96  maxFee;
        uint32  validUntil;
    }

    function process(
        ExchangeData.State        storage S,
        ExchangeData.BlockContext memory  ctx,
        bytes                     memory  data,
        uint                              offset,
        bytes                     memory  auxiliaryData
        )
        internal
    {
        Withdrawal memory withdrawal;
        readTx(data, offset, withdrawal);

        // Read the NFT data if we're withdrawing an NFT
        NftDataTransaction.NftData memory nftData;
        if (withdrawal.tokenID.isNFT() && withdrawal.amount > 0) {
            NftDataTransaction.readDualNftData(
                ctx,
                withdrawal.fromAccountID,
                withdrawal.tokenID,
                ctx.txIndex.sub(2),
                nftData
            );
        }

        WithdrawalAuxiliaryData memory auxData = abi.decode(auxiliaryData, (WithdrawalAuxiliaryData));

        // Validate the withdrawal data not directly part of the DA
        bytes20 onchainDataHash = hashOnchainData(
            auxData.minGas,
            auxData.to,
            auxData.extraData
        );
        // Only the 20 MSB are used, which is still 80-bit of security, which is more
        // than enough, especially when combined with validUntil.
        require(withdrawal.onchainDataHash == onchainDataHash, "INVALID_WITHDRAWAL_DATA");

        // Fill in withdrawal data missing from DA
        withdrawal.to = auxData.to;
        withdrawal.minGas = auxData.minGas;
        withdrawal.extraData = auxData.extraData;
        withdrawal.maxFee = auxData.maxFee == 0 ? withdrawal.fee : auxData.maxFee;
        withdrawal.validUntil = auxData.validUntil;

        // If the account has an owner, don't allow withdrawing to the zero address
        // (which will be the protocol fee vault contract).
        require(withdrawal.from == address(0) || withdrawal.to != address(0), "INVALID_WITHDRAWAL_RECIPIENT");

        if (withdrawal.withdrawalType == 0) {
            // Signature checked offchain, nothing to do
        } else if (withdrawal.withdrawalType == 1) {
            // Validate
            require(ctx.timestamp < withdrawal.validUntil, "WITHDRAWAL_EXPIRED");
            require(withdrawal.fee <= withdrawal.maxFee, "WITHDRAWAL_FEE_TOO_HIGH");

            // Check appproval onchain
            // Calculate the tx hash
            bytes32 txHash = hashTx(ctx.DOMAIN_SEPARATOR, withdrawal);
            // Check onchain authorization
            S.requireAuthorizedTx(withdrawal.from, auxData.signature, txHash);
        } else if (withdrawal.withdrawalType == 2 || withdrawal.withdrawalType == 3) {
            // Forced withdrawals cannot make use of certain features because the
            // necessary data is not authorized by the account owner.
            // For protocol fee withdrawals, `owner` and `to` are both address(0).
            require(withdrawal.from == withdrawal.to, "INVALID_WITHDRAWAL_ADDRESS");

            // Forced withdrawal fees are charged when the request is submitted.
            require(withdrawal.fee == 0, "FEE_NOT_ZERO");

            require(withdrawal.extraData.length == 0, "AUXILIARY_DATA_NOT_ALLOWED");

            ExchangeData.ForcedWithdrawal memory forcedWithdrawal =
                S.pendingForcedWithdrawals[withdrawal.fromAccountID][withdrawal.tokenID];

            if (forcedWithdrawal.timestamp != 0) {
                if (withdrawal.withdrawalType == 2) {
                    require(withdrawal.from == forcedWithdrawal.owner, "INCONSISENT_OWNER");
                } else { //withdrawal.withdrawalType == 3
                    require(withdrawal.from != forcedWithdrawal.owner, "INCONSISENT_OWNER");
                    require(withdrawal.amount == 0, "UNAUTHORIZED_WITHDRAWAL");
                }

                // delete the withdrawal request and free a slot
                delete S.pendingForcedWithdrawals[withdrawal.fromAccountID][withdrawal.tokenID];
                S.numPendingForcedTransactions--;
            } else {
                // Allow the owner to submit full withdrawals without authorization
                // - when in shutdown mode
                // - to withdraw protocol fees
                require(
                    withdrawal.fromAccountID == ExchangeData.ACCOUNTID_PROTOCOLFEE ||
                    S.isShutdown(),
                    "FULL_WITHDRAWAL_UNAUTHORIZED"
                );
            }
        } else {
            revert("INVALID_WITHDRAWAL_TYPE");
        }

        // Check if there is a withdrawal recipient
        address recipient = S.withdrawalRecipient[withdrawal.from][withdrawal.to][withdrawal.tokenID][withdrawal.amount][withdrawal.storageID];
        if (recipient != address(0)) {
            // Auxiliary data is not supported
            require (withdrawal.extraData.length == 0, "AUXILIARY_DATA_NOT_ALLOWED");

            // Set the new recipient address
            withdrawal.to = recipient;
            // Allow any amount of gas to be used on this withdrawal (which allows the transfer to be skipped)
            withdrawal.minGas = 0;

            // Do NOT delete the recipient to prevent replay attack
            // delete S.withdrawalRecipient[withdrawal.owner][withdrawal.to][withdrawal.tokenID][withdrawal.amount][withdrawal.storageID];
        } else if (auxData.storeRecipient) {
            // Store the destination address to mark the withdrawal as done
            require(withdrawal.to != address(0), "INVALID_DESTINATION_ADDRESS");
            S.withdrawalRecipient[withdrawal.from][withdrawal.to][withdrawal.tokenID][withdrawal.amount][withdrawal.storageID] = withdrawal.to;
        }

        // Validate gas provided
        require(auxData.gasLimit >= withdrawal.minGas, "OUT_OF_GAS_FOR_WITHDRAWAL");

        // Try to transfer the tokens with the provided gas limit
        S.distributeWithdrawal(
            withdrawal.from,
            withdrawal.to,
            withdrawal.tokenID,
            withdrawal.amount,
            withdrawal.extraData,
            auxData.gasLimit,
            nftData.nft
        );
    }

    function readTx(
        bytes      memory data,
        uint              offset,
        Withdrawal memory withdrawal
        )
        internal
        pure
    {
        uint _offset = offset;

        require(data.toUint8Unsafe(_offset) == uint8(ExchangeData.TransactionType.WITHDRAWAL), "INVALID_TX_TYPE");
        _offset += 1;

        // Extract the transfer data
        // We don't use abi.decode for this because of the large amount of zero-padding
        // bytes the circuit would also have to hash.
        withdrawal.withdrawalType = data.toUint8Unsafe(_offset);
        _offset += 1;
        withdrawal.from = data.toAddressUnsafe(_offset);
        _offset += 20;
        withdrawal.fromAccountID = data.toUint32Unsafe(_offset);
        _offset += 4;
        withdrawal.tokenID = data.toUint16Unsafe(_offset);
        _offset += 2;
        withdrawal.amount = data.toUint96Unsafe(_offset);
        _offset += 12;
        withdrawal.feeTokenID = data.toUint16Unsafe(_offset);
        _offset += 2;
        withdrawal.fee = data.toUint16Unsafe(_offset).decodeFloat16();
        _offset += 2;
        withdrawal.storageID = data.toUint32Unsafe(_offset);
        _offset += 4;
        withdrawal.onchainDataHash = data.toBytes20Unsafe(_offset);
        _offset += 20;
    }

    function hashTx(
        bytes32 DOMAIN_SEPARATOR,
        Withdrawal memory withdrawal
        )
        internal
        pure
        returns (bytes32)
    {
        return EIP712.hashPacked(
            DOMAIN_SEPARATOR,
            keccak256(
                abi.encode(
                    WITHDRAWAL_TYPEHASH,
                    withdrawal.from,
                    withdrawal.fromAccountID,
                    withdrawal.tokenID,
                    withdrawal.amount,
                    withdrawal.feeTokenID,
                    withdrawal.maxFee,
                    withdrawal.to,
                    keccak256(withdrawal.extraData),
                    withdrawal.minGas,
                    withdrawal.validUntil,
                    withdrawal.storageID
                )
            )
        );
    }

    function hashOnchainData(
        uint    minGas,
        address to,
        bytes   memory extraData
        )
        internal
        pure
        returns (bytes20)
    {
        // Only the 20 MSB are used, which is still 80-bit of security, which is more
        // than enough, especially when combined with validUntil.
        return bytes20(keccak256(
            abi.encodePacked(
                minGas,
                to,
                extraData
            )
        ));
    }
}

// File: contracts/core/impl/libtransactions/NftMintTransaction.sol

// Copyright 2017 Loopring Technology Limited.












/// @title NftMintTransaction
/// @author Brecht Devos - <[email protected]>
library NftMintTransaction
{
    using BlockReader          for bytes;
    using BytesUtil            for bytes;
    using ExchangeSignatures   for ExchangeData.State;
    using FloatUtil            for uint16;
    using MathUint96           for uint96;
    using MathUint             for uint;

    bytes32 constant public NFTMINT_TYPEHASH = keccak256(
        "NftMint(address minter,address to,uint8 nftType,address token,uint256 nftID,uint8 creatorFeeBips,uint96 amount,uint16 feeTokenID,uint96 maxFee,uint32 validUntil,uint32 storageID)"
    );

    // This structure represents either a L2 NFT mint or a L1-to-L2 NFT deposit.
    struct NftMint
    {
        uint                 mintType;
        uint32               minterAccountID;
        uint32               toAccountID;
        uint16               toTokenID;   // slot
        uint96               amount;
        uint16               feeTokenID;
        uint96               maxFee;
        uint96               fee;
        uint32               validUntil;
        uint32               storageID;
        address              to;
        ExchangeData.Nft     nft;
    }

    // Auxiliary data for each NFT mint
    struct NftMintAuxiliaryData
    {
        bytes  signature;
        uint96 maxFee;
        uint32 validUntil;
    }

    function process(
        ExchangeData.State        storage S,
        ExchangeData.BlockContext memory  ctx,
        bytes                     memory  data,
        uint                              offset,
        bytes                     memory  auxiliaryData
        )
        internal
    {
        // Read in the mint
        NftMint memory mint;
        readTx(data, offset, mint);

        // Read the NFT data if we're minting or depositing an NFT
        //
        // Note that EdDSA-based minting has the following restrictions due
        // to storage limit:
        //  1) It's only possible to mint to the minter's own account.
        //  2) The max amount that can be minted is limited to 65535 (2**16 - 1) per mint.
        //
        // ECDSA and onchain approval hash-based minting do not have the above restrictions.
        {
            // Read the NFT data
            NftDataTransaction.NftData memory nftData;
            NftDataTransaction.readDualNftData(
                ctx,
                mint.toAccountID,
                mint.toTokenID,
                ctx.txIndex.add(1),
                nftData
            );
            // Copy the data to the mint struct
            mint.nft = nftData.nft;
        }

        if (mint.mintType == 2) {
            // No fee allowed for deposits
            require(mint.fee == 0, "DEPOSIT_FEE_DISALLOWED");
            require(mint.nft.creatorFeeBips == 0, "CREATORFEEBIPS_NONZERO");

            // The minter should be the NFT token contract for deposits
            require(mint.nft.minter == mint.nft.token, "MINTER_NOT_TOKEN_CONTRACT");

            // Process the deposit
            ExchangeData.Deposit memory pendingDeposit = S.pendingNFTDeposits[mint.to][mint.nft.nftType][mint.nft.token][mint.nft.nftID];

            // Make sure the deposit was actually done
            require(pendingDeposit.timestamp > 0, "DEPOSIT_NOT_EXIST");

            // Processing partial amounts of the deposited amount is allowed.
            // This is done to ensure the user can do multiple deposits after each other
            // without invalidating work done by the exchange owner for previous deposit amounts.

            require(pendingDeposit.amount >= mint.amount, "INVALID_AMOUNT");
            pendingDeposit.amount = pendingDeposit.amount.sub(mint.amount);

            // If the deposit was fully consumed, reset it so the storage is freed up
            // and the owner receives a gas refund.
            if (pendingDeposit.amount == 0) {
                delete S.pendingNFTDeposits[mint.to][mint.nft.nftType][mint.nft.token][mint.nft.nftID];
            } else {
                S.pendingNFTDeposits[mint.to][mint.nft.nftType][mint.nft.token][mint.nft.nftID] = pendingDeposit;
            }
        } else {
            // The minter should NOT be the NFT token contract for L2 mints
            require(mint.nft.minter != mint.nft.token, "MINTER_EQUALS_TOKEN_CONTRACT");

            NftMintAuxiliaryData memory auxData = abi.decode(auxiliaryData, (NftMintAuxiliaryData));

            // Fill in withdrawal data missing from DA or only available in the NftData
            // Fill in withdrawal data missing from DA
            mint.validUntil = auxData.validUntil;
            mint.maxFee = auxData.maxFee == 0 ? mint.fee : auxData.maxFee;
            // Validate
            require(ctx.timestamp < mint.validUntil, "NFTMINT_EXPIRED");
            require(mint.fee <= mint.maxFee, "NFTMINT_FEE_TOO_HIGH");

            // Calculate the tx hash
            bytes32 txHash = hashTx(ctx.DOMAIN_SEPARATOR, mint);

            // Check the on-chain authorization
            S.requireAuthorizedTx(mint.nft.minter, auxData.signature, txHash);
        }
    }

    function readTx(
        bytes   memory data,
        uint           offset,
        NftMint memory mint
        )
        internal
        pure
    {
        uint _offset = offset;

        require(
            data.toUint8Unsafe(_offset) == uint8(ExchangeData.TransactionType.NFT_MINT),
            "INVALID_TX_TYPE"
        );
        _offset += 1;

        mint.mintType = data.toUint8Unsafe(_offset);
        _offset += 1;
        // Check that this is a conditional mint
        require(mint.mintType > 0, "INVALID_AUXILIARY_DATA");

        // We don't use abi.decode for this because of the large amount of zero-padding
        // bytes the circuit would also have to hash.
        mint.minterAccountID = data.toUint32Unsafe(_offset);
        _offset += 4;
        mint.toTokenID = data.toUint16Unsafe(_offset);
        _offset += 2;
        mint.feeTokenID = data.toUint16Unsafe(_offset);
        _offset += 2;
        mint.fee = data.toUint16Unsafe(_offset).decodeFloat16();
        _offset += 2;
        mint.amount = data.toUint96Unsafe(_offset);
        _offset += 12;
        mint.storageID = data.toUint32Unsafe(_offset);
        _offset += 4;
        mint.toAccountID = data.toUint32Unsafe(_offset);
        _offset += 4;
        mint.to = data.toAddressUnsafe(_offset);
        _offset += 20;
    }

    function hashTx(
        bytes32        DOMAIN_SEPARATOR,
        NftMint memory mint
        )
        internal
        pure
        returns (bytes32)
    {
        return EIP712.hashPacked(
            DOMAIN_SEPARATOR,
            keccak256(
                abi.encode(
                    NFTMINT_TYPEHASH,
                    mint.nft.minter,
                    mint.to,
                    mint.nft.nftType,
                    mint.nft.token,
                    mint.nft.nftID,
                    mint.nft.creatorFeeBips,
                    mint.amount,
                    mint.feeTokenID,
                    mint.maxFee,
                    mint.validUntil,
                    mint.storageID
                )
            )
        );
    }
}

// File: contracts/core/impl/libexchange/ExchangeBlocks.sol

// Copyright 2017 Loopring Technology Limited.
















/// @title ExchangeBlocks.
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang  - <[email protected]>
library ExchangeBlocks
{
    using AddressUtil          for address;
    using AddressUtil          for address payable;
    using BlockReader          for bytes;
    using BytesUtil            for bytes;
    using MathUint             for uint;
    using ExchangeMode         for ExchangeData.State;
    using ExchangeWithdrawals  for ExchangeData.State;
    using SignatureUtil        for bytes32;

    event BlockSubmitted(
        uint    indexed blockIdx,
        bytes32         merkleRoot,
        bytes32         publicDataHash
    );

    event ProtocolFeesUpdated(
        uint8 takerFeeBips,
        uint8 makerFeeBips,
        uint8 previousTakerFeeBips,
        uint8 previousMakerFeeBips
    );

    function submitBlocks(
        ExchangeData.State   storage S,
        ExchangeData.Block[] memory  blocks
        )
        public
    {
        // Exchange cannot be in withdrawal mode
        require(!S.isInWithdrawalMode(), "INVALID_MODE");

        // Commit the blocks
        bytes32[] memory publicDataHashes = new bytes32[](blocks.length);
        for (uint i = 0; i < blocks.length; i++) {
            // Hash all the public data to a single value which is used as the input for the circuit
            publicDataHashes[i] = blocks[i].data.fastSHA256();
            // Commit the block
            commitBlock(S, blocks[i], publicDataHashes[i]);
        }

        // Verify the blocks - blocks are verified in a batch to save gas.
        verifyBlocks(S, blocks, publicDataHashes);
    }

    // == Internal Functions ==

    function commitBlock(
        ExchangeData.State storage S,
        ExchangeData.Block memory  _block,
        bytes32                    _publicDataHash
        )
        private
    {
        // Read the block header
        BlockReader.BlockHeader memory header = _block.data.readHeader();

        // Validate the exchange
        require(header.exchange == address(this), "INVALID_EXCHANGE");
        // Validate the Merkle roots
        require(header.merkleRootBefore == S.merkleRoot, "INVALID_MERKLE_ROOT");
        require(header.merkleRootAfter != header.merkleRootBefore, "EMPTY_BLOCK_DISABLED");
        require(uint(header.merkleRootAfter) < ExchangeData.SNARK_SCALAR_FIELD, "INVALID_MERKLE_ROOT");
        // Validate the timestamp
        require(
            header.timestamp > block.timestamp - ExchangeData.TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS &&
            header.timestamp < block.timestamp + ExchangeData.TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS,
            "INVALID_TIMESTAMP"
        );
        // Validate the protocol fee values
        require(
            validateAndSyncProtocolFees(S, header.protocolTakerFeeBips, header.protocolMakerFeeBips),
            "INVALID_PROTOCOL_FEES"
        );

        // Process conditional transactions
        processConditionalTransactions(
            S,
            _block,
            header
        );

        // Emit an event
        uint numBlocks = S.numBlocks;
        emit BlockSubmitted(numBlocks, header.merkleRootAfter, _publicDataHash);

        S.merkleRoot = header.merkleRootAfter;

        if (_block.storeBlockInfoOnchain) {
            S.blocks[numBlocks] = ExchangeData.BlockInfo(
                uint32(block.timestamp),
                bytes28(_publicDataHash)
            );
        }

        S.numBlocks = numBlocks + 1;
    }

    function verifyBlocks(
        ExchangeData.State   storage S,
        ExchangeData.Block[] memory  blocks,
        bytes32[]            memory  publicDataHashes
        )
        private
        view
    {
        IBlockVerifier blockVerifier = S.blockVerifier;
        uint numBlocksVerified = 0;
        bool[] memory blockVerified = new bool[](blocks.length);
        ExchangeData.Block memory firstBlock;
        uint[] memory batch = new uint[](blocks.length);

        while (numBlocksVerified < blocks.length) {
            // Find all blocks of the same type
            uint batchLength = 0;
            for (uint i = 0; i < blocks.length; i++) {
                if (blockVerified[i] == false) {
                    if (batchLength == 0) {
                        firstBlock = blocks[i];
                        batch[batchLength++] = i;
                    } else {
                        ExchangeData.Block memory _block = blocks[i];
                        if (_block.blockType == firstBlock.blockType &&
                            _block.blockSize == firstBlock.blockSize &&
                            _block.blockVersion == firstBlock.blockVersion) {
                            batch[batchLength++] = i;
                        }
                    }
                }
            }

            // Prepare the data for batch verification
            uint[] memory publicInputs = new uint[](batchLength);
            uint[] memory proofs = new uint[](batchLength * 8);

            for (uint i = 0; i < batchLength; i++) {
                uint blockIdx = batch[i];
                // Mark the block as verified
                blockVerified[blockIdx] = true;
                // Strip the 3 least significant bits of the public data hash
                // so we don't have any overflow in the snark field
                publicInputs[i] = uint(publicDataHashes[blockIdx]) >> 3;
                // Copy proof
                ExchangeData.Block memory _block = blocks[blockIdx];
                for (uint j = 0; j < 8; j++) {
                    proofs[i*8 + j] = _block.proof[j];
                }
            }

            // Verify the proofs
            require(
                blockVerifier.verifyProofs(
                    uint8(firstBlock.blockType),
                    firstBlock.blockSize,
                    firstBlock.blockVersion,
                    publicInputs,
                    proofs
                ),
                "INVALID_PROOF"
            );

            numBlocksVerified += batchLength;
        }
    }

    function processConditionalTransactions(
        ExchangeData.State      storage S,
        ExchangeData.Block      memory _block,
        BlockReader.BlockHeader memory header
        )
        private
    {
        if (header.numConditionalTransactions > 0) {
            // Cache the domain separator to save on SLOADs each time it is accessed.
            ExchangeData.BlockContext memory ctx = ExchangeData.BlockContext({
                DOMAIN_SEPARATOR: S.DOMAIN_SEPARATOR,
                timestamp: header.timestamp,
                block: _block,
                txIndex: 0
            });

            ExchangeData.AuxiliaryData[] memory block_auxiliaryData;
            bytes memory blockAuxData = _block.auxiliaryData;
            assembly {
                block_auxiliaryData := add(blockAuxData, 64)
            }

            require(
                block_auxiliaryData.length == header.numConditionalTransactions,
                "AUXILIARYDATA_INVALID_LENGTH"
            );

            // Run over all conditional transactions
            uint minTxIndex = 0;
            bytes memory txData = new bytes(ExchangeData.TX_DATA_AVAILABILITY_SIZE);
            for (uint i = 0; i < block_auxiliaryData.length; i++) {
                // Load the data from auxiliaryData, which is still encoded as calldata
                uint txIndex;
                bool approved;
                bytes memory auxData;
                assembly {
                    // Offset to block_auxiliaryData[i]
                    let auxOffset := mload(add(block_auxiliaryData, add(32, mul(32, i))))
                    // Load `txIndex` (pos 0) and `approved` (pos 1) in block_auxiliaryData[i]
                    txIndex := mload(add(add(32, block_auxiliaryData), auxOffset))
                    approved := mload(add(add(64, block_auxiliaryData), auxOffset))
                    // Load `data` (pos 2)
                    let auxDataOffset := mload(add(add(96, block_auxiliaryData), auxOffset))
                    auxData := add(add(32, block_auxiliaryData), add(auxOffset, auxDataOffset))
                }
                ctx.txIndex = txIndex;

                // Each conditional transaction needs to be processed from left to right
                require(txIndex >= minTxIndex, "AUXILIARYDATA_INVALID_ORDER");

                minTxIndex = txIndex + 1;

                if (approved) {
                    continue;
                }

                // Get the transaction data
                _block.data.readTransactionData(txIndex, _block.blockSize, txData);

                // Process the transaction
                ExchangeData.TransactionType txType = ExchangeData.TransactionType(
                    txData.toUint8(0)
                );
                uint txDataOffset = 0;

                if (txType == ExchangeData.TransactionType.DEPOSIT) {
                    DepositTransaction.process(
                        S,
                        ctx,
                        txData,
                        txDataOffset,
                        auxData
                    );
                } else if (txType == ExchangeData.TransactionType.WITHDRAWAL) {
                    WithdrawTransaction.process(
                        S,
                        ctx,
                        txData,
                        txDataOffset,
                        auxData
                    );
                } else if (txType == ExchangeData.TransactionType.TRANSFER) {
                    TransferTransaction.process(
                        S,
                        ctx,
                        txData,
                        txDataOffset,
                        auxData
                    );
                } else if (txType == ExchangeData.TransactionType.ACCOUNT_UPDATE) {
                    AccountUpdateTransaction.process(
                        S,
                        ctx,
                        txData,
                        txDataOffset,
                        auxData
                    );
                } else if (txType == ExchangeData.TransactionType.AMM_UPDATE) {
                    AmmUpdateTransaction.process(
                        S,
                        ctx,
                        txData,
                        txDataOffset,
                        auxData
                    );
                } else if (txType == ExchangeData.TransactionType.NFT_MINT) {
                    NftMintTransaction.process(
                        S,
                        ctx,
                        txData,
                        txDataOffset,
                        auxData
                    );
                } else {
                    // ExchangeData.TransactionType.NOOP,
                    // ExchangeData.TransactionType.SPOT_TRADE and
                    // ExchangeData.TransactionType.SIGNATURE_VERIFICATION
                    // are not supported
                    revert("UNSUPPORTED_TX_TYPE");
                }
            }
        }
    }

    function validateAndSyncProtocolFees(
        ExchangeData.State storage S,
        uint8 takerFeeBips,
        uint8 makerFeeBips
        )
        private
        returns (bool)
    {
        ExchangeData.ProtocolFeeData memory data = S.protocolFeeData;
        if (block.timestamp > data.syncedAt + ExchangeData.MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED) {
            // Store the current protocol fees in the previous protocol fees
            data.previousTakerFeeBips = data.takerFeeBips;
            data.previousMakerFeeBips = data.makerFeeBips;
            // Get the latest protocol fees for this exchange
            (data.takerFeeBips, data.makerFeeBips) = S.loopring.getProtocolFeeValues();
            data.syncedAt = uint32(block.timestamp);

            if (data.takerFeeBips != data.previousTakerFeeBips ||
                data.makerFeeBips != data.previousMakerFeeBips) {
                emit ProtocolFeesUpdated(
                    data.takerFeeBips,
                    data.makerFeeBips,
                    data.previousTakerFeeBips,
                    data.previousMakerFeeBips
                );
            }

            // Update the data in storage
            S.protocolFeeData = data;
        }
        // The given fee values are valid if they are the current or previous protocol fee values
        return (takerFeeBips == data.takerFeeBips && makerFeeBips == data.makerFeeBips) ||
            (takerFeeBips == data.previousTakerFeeBips && makerFeeBips == data.previousMakerFeeBips);
    }
}