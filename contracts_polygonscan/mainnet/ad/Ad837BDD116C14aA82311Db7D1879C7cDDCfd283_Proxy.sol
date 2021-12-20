// SPDX-License-Identifier: MIT

// NOTE: taken from Openzeppelin Proxy contract

pragma solidity 0.8.9;

import "BytesLib.sol";

contract Proxy {
    uint8 constant STATIC_ARG = 0;
    uint8 constant CALL_DATA_ARG = 1;
    uint8 constant ENV_ARG = 2;

    uint8 constant ENV_CHAINID = 0;
    uint8 constant ENV_COINBASE = 1;
    uint8 constant ENV_DIFFICULTY = 2;
    uint8 constant ENV_GASLIMIT = 3;
    uint8 constant ENV_NUMBER = 4;
    uint8 constant ENV_TIMESTAMP = 5;
    uint8 constant ENV_GASLEFT = 6;
    uint8 constant ENV_SENDER = 7;
    uint8 constant ENV_SIG = 8;
    uint8 constant ENV_VALUE = 9;
    uint8 constant ENV_GASPRICE = 10;
    uint8 constant ENV_ORIGIN = 11;

    /// @dev data should be encoded as follow
    ///
    /// |  0 - 4    |       5     |      6 --
    /// | signature |  args count |    args
    ///
    /// each arg should be encoded as follow
    ///
    /// |    0    |   1 -
    /// | argType |  argData
    ///
    /// and argData should be encoded as follow
    /// argType == 0 (Static) -> number of bytes (uint16) and raw data for argument
    /// argType == 1 (CallData) -> offset and length of data in callData as uint16 (e.g. 0x000400a0 will be the first address in the call data)
    /// argType == 2 (Env) -> single byte corresponding to the following
    /// * 1  -> block.coinbase (address): current block miner’s address
    /// * 2  -> block.difficulty (uint): current block difficulty
    /// * 3  -> block.gaslimit (uint): current block gaslimit
    /// * 4  -> block.number (uint): current block number
    /// * 5  -> block.timestamp (uint): current block timestamp as seconds since unix epoch
    /// * 6  -> gasleft() returns (uint256): remaining gas
    /// * 7  -> msg.gas (uint): remaining gas - deprecated in version 0.4.21 and to be replaced by gasleft()
    /// * 8  -> msg.sender (address): sender of the message (current call)
    /// * 9  -> msg.sig (bytes4): first four bytes of the calldata (i.e. function identifier)
    /// * 10 -> msg.value (uint): number of wei sent with the message
    /// * 11 -> now (uint): current block timestamp (alias for block.timestamp)
    /// * 12 -> tx.gasprice (uint): gas price of the transaction
    /// * 13 -> tx.origin (address): sender of the transaction (full call chain)
    struct CheckCall {
        address targetContract;
        bytes data;
    }

    uint256[100] __gap;

    address[] public implementations;

    /// @notice maps a function signature to a set of checks
    mapping(bytes4 => CheckCall[]) public functionsChecks;

    error RevertDelegation(bool success, bytes revertData, bytes32 checksHash);

    function addImplementation(address implementation, bytes memory data) public {
        if (data.length > 0) {
            (bool success, ) = implementation.delegatecall(data);
            require(success, "initial data call failed");
        }
        implementations.push(implementation);
    }

    function allImplementations() external view returns (address[] memory) {
        return implementations;
    }

    function registerCheck(
        bytes4 functionSignature,
        address targetContract,
        bytes calldata data
    ) external {
        CheckCall[] storage calls = functionsChecks[functionSignature];
        CheckCall storage checkCall = calls.push();
        checkCall.targetContract = targetContract;
        checkCall.data = data;
    }

    function delegateAndCheck(
        address _implementation,
        bytes calldata data,
        CheckCall[] memory checks,
        bool revertExecution
    )
        public
        payable
        returns (
            bool success,
            bytes memory returnData,
            bytes32 checksHash
        )
    {
        (success, returnData) = _implementation.delegatecall(data);
        checksHash = keccak256(abi.encodePacked(success, returnData));
        for (uint256 i = 0; i < checks.length; i++) {
            CheckCall memory checkCall = checks[i];
            bytes memory callData = _encodeCalldata(checkCall, data);
            (bool checkSuccess, bytes memory checkData) = checkCall.targetContract.call(callData);
            require(checkSuccess, "check failed");
            checksHash = keccak256(abi.encodePacked(checksHash, checkSuccess, checkData));
        }
        if (revertExecution) {
            revert RevertDelegation(success, returnData, checksHash);
        } else {
            return (success, returnData, checksHash);
        }
    }

    function getErrorMessage(
        address _implementation,
        bytes memory data,
        CheckCall[] memory checks
    )
        external
        returns (
            bool,
            bytes memory,
            bytes32
        )
    {
        (bool success, bytes memory returnData) = address(this).delegatecall(
            abi.encodeWithSignature(
                "delegateAndCheck(address,bytes,(address,bytes)[],bool)",
                _implementation,
                data,
                checks,
                true
            )
        );
        require(!success, "should have failed");
        return _parseDelegatedCall(success, returnData);
    }

    function getChecks(bytes4 signature) external view returns (CheckCall[] memory) {
        return functionsChecks[signature];
    }

    /**
     * @dev Delegates the current call to all registered implementations
     * and persists state only on the last call
     * If any of the implementation is inconsistent, this reverts
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        bool success;
        bytes memory returnData;
        bytes32 checksHash;

        CheckCall[] memory checks = functionsChecks[msg.sig];

        uint256 len = implementations.length;
        for (uint256 i = 0; i < len; i++) {
            address implementation = implementations[i];
            bool shouldRevert = i != len - 1;
            (bool delegateSuccess, bytes memory delegateData) = address(this).delegatecall(
                abi.encodeWithSignature(
                    "delegateAndCheck(address,bytes,(address,bytes)[],bool)",
                    implementation,
                    msg.data,
                    checks,
                    shouldRevert
                )
            );

            if (!delegateSuccess && !shouldRevert) {
                revert("delegateCall should have succeeded but failed");
            } else if (delegateSuccess && shouldRevert) {
                revert("delegateCall should have failed but succeeded");
            }

            (bool callSuccess, bytes memory callData, bytes32 callChecksHash) = _parseDelegatedCall(
                delegateSuccess,
                delegateData
            );

            if (i == 0) {
                success = callSuccess;
                returnData = callData;
                checksHash = callChecksHash;
                continue;
            }

            require(success == callSuccess, "all implementations must return the same success");
            require(
                _bytesEq(returnData, callData),
                "all implementations must return the same return data"
            );
            require(
                checksHash == callChecksHash,
                "all implementations must return the same checks"
            );
        }

        uint256 returnDataSize = returnData.length;

        assembly {
            // Copy the return data to the Solidity scratch pad.
            if iszero(call(gas(), 0x04, 0, add(returnData, 0x20), returnDataSize, 0, 0)) {
                invalid()
            }
            returndatacopy(0, 0, returnDataSize)

            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }

    function _bytesEq(bytes memory a, bytes memory b) internal pure returns (bool) {
        uint256 len = a.length;
        if (len != b.length) {
            return false;
        }
        for (uint256 i = 0; i < len; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }

    function _parseDelegatedCall(bool success, bytes memory returnData)
        internal
        pure
        returns (
            bool,
            bytes memory,
            bytes32
        )
    {
        if (!success) {
            assembly {
                returnData := add(returnData, 4) // drop signature
            }
        }

        (bool delegatedSuccess, bytes memory delegatedreturnData, bytes32 checksHash) = abi.decode(
            returnData,
            (bool, bytes, bytes32)
        );

        return (delegatedSuccess, delegatedreturnData, checksHash);
    }

    function _encodeCalldata(CheckCall memory check, bytes calldata msgData)
        internal
        view
        returns (bytes memory result)
    {
        result = BytesLib.slice(check.data, 0, 4);
        uint8 argsCount = uint8(check.data[4]);
        uint256 currentOffset = 5;
        for (uint256 i = 0; i < argsCount; i++) {
            uint8 argType = uint8(check.data[currentOffset++]);

            bytes memory arg;
            if (argType == STATIC_ARG) {
                uint16 argLength = parseUint16(check.data, currentOffset);
                arg = BytesLib.slice(check.data, currentOffset + 2, argLength);
                currentOffset += argLength + 2;
            } else if (argType == CALL_DATA_ARG) {
                uint16 offset = parseUint16(check.data, currentOffset);
                uint16 length = parseUint16(check.data, currentOffset + 2);
                arg = msgData[offset:offset + length];
                currentOffset += 4;
            } else if (argType == ENV_ARG) {
                uint8 varType = uint8(check.data[currentOffset++]);
                if (varType == ENV_CHAINID) arg = abi.encode(block.chainid);
                else if (varType == ENV_COINBASE) arg = abi.encode(block.coinbase);
                else if (varType == ENV_DIFFICULTY) arg = abi.encode(block.difficulty);
                else if (varType == ENV_GASLIMIT) arg = abi.encode(block.gaslimit);
                else if (varType == ENV_NUMBER) arg = abi.encode(block.number);
                else if (varType == ENV_TIMESTAMP) arg = abi.encode(block.timestamp);
                else if (varType == ENV_GASLEFT) arg = abi.encode(gasleft());
                else if (varType == ENV_SENDER) arg = abi.encode(msg.sender);
                else if (varType == ENV_SIG) arg = abi.encode(msg.sig);
                else if (varType == ENV_VALUE) arg = abi.encode(msg.value);
                else if (varType == ENV_GASPRICE) arg = abi.encode(tx.gasprice);
                else if (varType == ENV_ORIGIN) arg = abi.encode(tx.origin);
                else revert("unknown environment variable");
            } else {
                revert("unknown argument type");
            }
            result = BytesLib.concat(result, arg);
        }
    }

    function parseUint16(bytes memory data, uint256 offset) internal pure returns (uint16) {
        return uint16(uint8(data[offset]) << 8) | uint16(uint8(data[offset + 1]));
    }

    /**
     * @dev Fallback function that delegates calls to `implementation`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the `implementation`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
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

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

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
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}