/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

// File: @pefish/solidity-lib/contracts/contract/Erc165/Erc165Base.sol

pragma solidity >=0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract Erc165Base {
  /*
   * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
   */
  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  /**
   * @dev Mapping of interface ids to whether or not it's supported.
   */
  mapping(bytes4 => bool) private _supportedInterfaces;

  function __Erc165Base_init () internal {
    // Derived contracts need only register support for their own interfaces,
    // we register support for ERC165 itself here
    _registerInterface(_INTERFACE_ID_ERC165);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   *
   * Time complexity O(1), guaranteed to always use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) public virtual view returns (bool) {
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
  function _registerInterface(bytes4 interfaceId) internal {
    require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
    _supportedInterfaces[interfaceId] = true;
  }
}

// File: @pefish/solidity-lib/contracts/interface/IErc721Receiver.sol

pragma solidity ^0.8.0;

interface IErc721Receiver {
  function onErc721Received(address operator, address from, uint256 tokenId, bytes memory data) external returns (bytes4);
}

// File: @pefish/solidity-lib/contracts/library/AddressUtil.sol

pragma solidity >=0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUtil {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @pefish/solidity-lib/contracts/library/Uint256Util.sol

pragma solidity >=0.8.0;

/** @title string util */
library Uint256Util {
    /**
     * @dev uint256 -> string
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (true) {
            buffer[index] = bytes1(uint8(48 + temp % 10));
            if (index > 0) {
                index = index - 1;
                temp /= 10;
            } else {
                break;
            }
        }
        return string(buffer);
    }

}

// File: @pefish/solidity-lib/contracts/library/BytesUtil.sol

pragma solidity >=0.8.0;


library BytesUtil {
  using BytesUtil for bytes;
  /// @dev Gets the memory address for a byte array.
  /// @param input Byte array to lookup.
  /// @return memoryAddress Memory address of byte array. This
  ///         points to the header of the byte array which contains
  ///         the length.
  function pointAddress(bytes memory input)
  internal
  pure
  returns (uint256 memoryAddress)
  {
    assembly {
      memoryAddress := input
    }
    return memoryAddress;
  }

  /// @dev Gets the memory address for the contents of a byte array.
  /// @param input Byte array to lookup.
  /// @return memoryAddress Memory address of the contents of the byte array.
  function contentPointAddress(bytes memory input)
  internal
  pure
  returns (uint256 memoryAddress)
  {
    assembly {
      memoryAddress := add(input, 32)
    }
    return memoryAddress;
  }

  /// @dev Copies `length` bytes from memory location `source` to `dest`.
  /// @param dest memory address to copy bytes to.
  /// @param source memory address to copy bytes from.
  /// @param length number of bytes to copy.
  function memCopy(
    uint256 dest,
    uint256 source,
    uint256 length
  )
  internal
  pure
  {
    if (length < 32) {
      // Handle a partial word by reading destination and masking
      // off the bits we are interested in.
      // This correctly handles overlap, zero lengths and source == dest
      assembly {
        let mask := sub(exp(256, sub(32, length)), 1)
        let s := and(mload(source), not(mask))
        let d := and(mload(dest), mask)
        mstore(dest, or(s, d))
      }
    } else {
      // Skip the O(length) loop when source == dest.
      if (source == dest) {
        return;
      }

      // For large copies we copy whole words at a time. The final
      // word is aligned to the end of the range (instead of after the
      // previous) to handle partial words. So a copy will look like this:
      //
      //  ####
      //      ####
      //          ####
      //            ####
      //
      // We handle overlap in the source and destination range by
      // changing the copying direction. This prevents us from
      // overwriting parts of source that we still need to copy.
      //
      // This correctly handles source == dest
      //
      if (source > dest) {
        assembly {
        // We subtract 32 from `sEnd` and `dEnd` because it
        // is easier to compare with in the loop, and these
        // are also the addresses we need for copying the
        // last bytes.
          length := sub(length, 32)
          let sEnd := add(source, length)
          let dEnd := add(dest, length)

        // Remember the last 32 bytes of source
        // This needs to be done here and not after the loop
        // because we may have overwritten the last bytes in
        // source already due to overlap.
          let last := mload(sEnd)

        // Copy whole words front to back
        // Note: the first check is always true,
        // this could have been a do-while loop.
        // solhint-disable-next-line no-empty-blocks
          for {} lt(source, sEnd) {} {
            mstore(dest, mload(source))
            source := add(source, 32)
            dest := add(dest, 32)
          }

        // Write the last 32 bytes
          mstore(dEnd, last)
        }
      } else {
        assembly {
        // We subtract 32 from `sEnd` and `dEnd` because those
        // are the starting points when copying a word at the end.
          length := sub(length, 32)
          let sEnd := add(source, length)
          let dEnd := add(dest, length)

        // Remember the first 32 bytes of source
        // This needs to be done here and not after the loop
        // because we may have overwritten the first bytes in
        // source already due to overlap.
          let first := mload(source)

        // Copy whole words back to front
        // We use a signed comparisson here to allow dEnd to become
        // negative (happens when source and dest < 32). Valid
        // addresses in local memory will never be larger than
        // 2**255, so they can be safely re-interpreted as signed.
        // Note: the first check is always true,
        // this could have been a do-while loop.
        // solhint-disable-next-line no-empty-blocks
          for {} slt(dest, dEnd) {} {
            mstore(dEnd, mload(sEnd))
            sEnd := sub(sEnd, 32)
            dEnd := sub(dEnd, 32)
          }

        // Write the first 32 bytes
          mstore(dest, first)
        }
      }
    }
  }

  /// @dev Returns a slices from a byte array.
  /// @param b The byte array to take a slice from.
  /// @param from The starting index for the slice (inclusive).
  /// @param to The final index for the slice (exclusive).
  /// @return result The slice containing bytes at indices [from, to)
  function slice(
    bytes memory b,
    uint256 from,
    uint256 to
  )
  internal
  pure
  returns (bytes memory result)
  {
    // Ensure that the from and to positions are valid positions for a slice within
    // the byte array that is being used.
    require(from <= to, "FromLessThanOrEqualsToRequired");
    require(to <= b.length, "ToLessThanOrEqualsLengthRequired");

    // Create a new bytes structure and copy contents
    result = new bytes(to - from);
    memCopy(
      result.contentPointAddress(),
      b.contentPointAddress() + from,
      result.length
    );
    return result;
  }

  /// @dev Returns a slice from a byte array without preserving the input.
  ///      When `from == 0`, the original array will match the slice.
  ///      In other cases its state will be corrupted.
  /// @param b The byte array to take a slice from. Will be destroyed in the process.
  /// @param from The starting index for the slice (inclusive).
  /// @param to The final index for the slice (exclusive).
  /// @return result The slice containing bytes at indices [from, to)
  function sliceDestructive(
    bytes memory b,
    uint256 from,
    uint256 to
  )
  internal
  pure
  returns (bytes memory result)
  {
    // Ensure that the from and to positions are valid positions for a slice within
    // the byte array that is being used.
    require(from <= to, "FromLessThanOrEqualsToRequired");
    require(to <= b.length, "ToLessThanOrEqualsLengthRequired");

    // Create a new bytes structure around [from, to) in-place.
    assembly {
      result := add(b, from)
      mstore(result, sub(to, from))
    }
    return result;
  }

  /// @dev Pops the last byte off of a byte array by modifying its length.
  /// @param b Byte array that will be modified.
  /// @return result The byte that was popped off.
  function popLastByte(bytes memory b)
  internal
  pure
  returns (bytes1 result)
  {
    require(b.length != 0, "LengthGreaterThanZeroRequired");

    // Store last byte.
    result = b[b.length - 1];

    assembly {
    // Decrement length of byte array.
      let newLen := sub(mload(b), 1)
      mstore(b, newLen)
    }
    return result;
  }

  /// @dev Tests equality of two byte arrays.
  /// @param lhs First byte array to compare.
  /// @param rhs Second byte array to compare.
  /// @return equal True if arrays are the same. False otherwise.
  function equals(
    bytes memory lhs,
    bytes memory rhs
  )
  internal
  pure
  returns (bool equal)
  {
    // Keccak gas cost is 30 + numWords * 6. This is a cheap way to compare.
    // We early exit on unequal lengths, but keccak would also correctly
    // handle this.
    return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
  }

  /// @dev Reads an address from a position in a byte array.
  /// @param b Byte array containing an address.
  /// @param index Index in byte array of address.
  /// @return result address from byte array.
  function readAddress(
    bytes memory b,
    uint256 index
  )
  internal
  pure
  returns (address result)
  {
    require(b.length >= index + 20, "LengthGreaterThanOrEqualsTwentyRequired");

    // Add offset to index:
    // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
    // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
    index += 20;

    // Read address from array memory
    assembly {
    // 1. Add index to address of bytes array
    // 2. Load 32-byte word from memory
    // 3. Apply 20-byte mask to obtain address
      result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
    }
    return result;
  }

  /// @dev Writes an address into a specific position in a byte array.
  /// @param b Byte array to insert address into.
  /// @param index Index in byte array of address.
  /// @param input Address to put into byte array.
  function writeAddress(
    bytes memory b,
    uint256 index,
    address input
  )
  internal
  pure
  {
    require(b.length >= index + 20, "LengthGreaterThanOrEqualsTwentyRequired");

    // Add offset to index:
    // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
    // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
    index += 20;

    // Store address into array memory
    assembly {
    // The address occupies 20 bytes and mstore stores 32 bytes.
    // First fetch the 32-byte word where we'll be storing the address, then
    // apply a mask so we have only the bytes in the word that the address will not occupy.
    // Then combine these bytes with the address and store the 32 bytes back to memory with mstore.

    // 1. Add index to address of bytes array
    // 2. Load 32-byte word from memory
    // 3. Apply 12-byte mask to obtain extra bytes occupying word of memory where we'll store the address
      let neighbors := and(
      mload(add(b, index)),
      0xffffffffffffffffffffffff0000000000000000000000000000000000000000
      )

    // Make sure input address is clean.
    // (Solidity does not guarantee this)
      input := and(input, 0xffffffffffffffffffffffffffffffffffffffff)

    // Store the neighbors and address into memory
      mstore(add(b, index), xor(input, neighbors))
    }
  }

  /// @dev Reads a bytes32 value from a position in a byte array.
  /// @param b Byte array containing a bytes32 value.
  /// @param index Index in byte array of bytes32 value.
  /// @return result bytes32 value from byte array.
  function readBytes32(
    bytes memory b,
    uint256 index
  )
  internal
  pure
  returns (bytes32 result)
  {
    require(b.length >= index + 32, "LengthGreaterThanOrEqualsThirtyTwoRequired");

    // Arrays are prefixed by a 256 bit length parameter
    index += 32;

    // Read the bytes32 from array memory
    assembly {
      result := mload(add(b, index))
    }
    return result;
  }

  /// @dev Writes a bytes32 into a specific position in a byte array.
  /// @param b Byte array to insert <input> into.
  /// @param index Index in byte array of <input>.
  /// @param input bytes32 to put into byte array.
  function writeBytes32(
    bytes memory b,
    uint256 index,
    bytes32 input
  )
  internal
  pure
  {
    require(b.length >= index + 32, "LengthGreaterThanOrEqualsThirtyTwoRequired");

    // Arrays are prefixed by a 256 bit length parameter
    index += 32;

    // Read the bytes32 from array memory
    assembly {
      mstore(add(b, index), input)
    }
  }

  /// @dev Reads a uint256 value from a position in a byte array.
  /// @param b Byte array containing a uint256 value.
  /// @param index Index in byte array of uint256 value.
  /// @return result uint256 value from byte array.
  function readUint256(
    bytes memory b,
    uint256 index
  )
  internal
  pure
  returns (uint256 result)
  {
    result = uint256(readBytes32(b, index));
    return result;
  }

  /// @dev Writes a uint256 into a specific position in a byte array.
  /// @param b Byte array to insert <input> into.
  /// @param index Index in byte array of <input>.
  /// @param input uint256 to put into byte array.
  function writeUint256(
    bytes memory b,
    uint256 index,
    uint256 input
  )
  internal
  pure
  {
    writeBytes32(b, index, bytes32(input));
  }

  /// @dev Reads an unpadded bytes4 value from a position in a byte array.
  /// @param b Byte array containing a bytes4 value.
  /// @param index Index in byte array of bytes4 value.
  /// @return result bytes4 value from byte array.
  function readBytes4(
    bytes memory b,
    uint256 index
  )
  internal
  pure
  returns (bytes4 result)
  {
    require(b.length >= index + 4, "LengthGreaterThanOrEqualsFourRequired");

    // Arrays are prefixed by a 32 byte length field
    index += 32;

    // Read the bytes4 from array memory
    assembly {
      result := mload(add(b, index))
    // Solidity does not require us to clean the trailing bytes.
    // We do it anyway
      result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
    }
    return result;
  }

  /// @dev Writes a new length to a byte array.
  ///      Decreasing length will lead to removing the corresponding lower order bytes from the byte array.
  ///      Increasing length may lead to appending adjacent in-memory bytes to the end of the byte array.
  /// @param b Bytes array to write new length to.
  /// @param length New length of byte array.
  function writeLength(bytes memory b, uint256 length)
  internal
  pure
  {
    assembly {
      mstore(b, length)
    }
  }

  function recover(bytes memory _msgBytes, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
    bytes memory fullMessage = concat(
      bytes("\x19Ethereum Signed Message:\n"),
      bytes(Uint256Util.toString(_msgBytes.length)),
      _msgBytes,
      new bytes(0), new bytes(0), new bytes(0), new bytes(0)
    );
    return ecrecover(keccak256(fullMessage), _v, _r, _s);
  }


  function concat(bytes memory ba, bytes memory bb, bytes memory bc, bytes memory bd, bytes memory be, bytes memory bf, bytes memory bg) internal pure returns (bytes memory) {
    bytes memory resultBytes = new bytes(ba.length + bb.length + bc.length + bd.length + be.length + bf.length + bg.length);
    uint k = 0;
    for (uint i = 0; i < ba.length; i++) resultBytes[k++] = ba[i];
    for (uint i = 0; i < bb.length; i++) resultBytes[k++] = bb[i];
    for (uint i = 0; i < bc.length; i++) resultBytes[k++] = bc[i];
    for (uint i = 0; i < bd.length; i++) resultBytes[k++] = bd[i];
    for (uint i = 0; i < be.length; i++) resultBytes[k++] = be[i];
    for (uint i = 0; i < bf.length; i++) resultBytes[k++] = bf[i];
    for (uint i = 0; i < bg.length; i++) resultBytes[k++] = bg[i];
    return resultBytes;
  }

  function toHexString(bytes memory _value) internal pure returns (string memory) {
    bytes memory alphabet = "0123456789abcdef";
    bytes memory str = new bytes(64);
    for (uint256 i = 0; i < _value.length; i++) {
      str[i*2] = alphabet[uint8(_value[i] >> 4)];
      str[1+i*2] = alphabet[uint8(_value[i] & 0x0f)];
    }
    return string(str);
  }
}

// File: @pefish/solidity-lib/contracts/library/StringUtil.sol

pragma solidity >=0.8.0;


/** @title string util */
library StringUtil {

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function isEqual(string memory _v1, string memory _v2) internal pure returns (bool) {
        return uint(keccak256(abi.encodePacked(_v1))) == uint(keccak256(abi.encodePacked(_v2)));
    }

    function append(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bab = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

    function append(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory bbb = new bytes(_ba.length + _bb.length + _bc.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bbb[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bbb[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) bbb[k++] = _bc[i];
        return string(bbb);
    }

    function recover(string memory _msg, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
        return BytesUtil.recover(bytes(_msg), _v, _r, _s);
    }
}

// File: @pefish/solidity-lib/contracts/interface/IErc165.sol

pragma solidity >=0.8.0;


interface IErc165 {
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

// File: @pefish/solidity-lib/contracts/interface/IErc721.sol

pragma solidity >=0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IErc721 is IErc165 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Returns the number of NFTs in `owner`'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the NFT specified by `tokenId`.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /**
   * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
   * another (`to`).
   *
   *
   *
   * Requirements:
   * - `from`, `to` cannot be zero.
   * - `tokenId` must be owned by `from`.
   * - `tokenId` must be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this
   * NFT by either {approve} or {setApprovalForAll}.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  /**
   * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
   * another (`to`).
   *
   * Requirements:
   * - If the caller is not `from`, it must be approved to move this NFT by
   * either {approve} or {setApprovalForAll}.
   */
  function transferFrom(address from, address to, uint256 tokenId) external;
  function approve(address to, uint256 tokenId) external;
  function getApproved(uint256 tokenId) external view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) external;
  function isApprovedForAll(address owner, address operator) external view returns (bool);


  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
}

// File: @pefish/solidity-lib/contracts/interface/IErc721Metadata.sol

interface IErc721Metadata is IErc721 {
  /**
   * @dev Returns the token collection name.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @pefish/solidity-lib/contracts/contract/erc721/Erc165.sol

abstract contract Erc165 is IErc165 {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IErc165).interfaceId;
  }
}

// File: @pefish/solidity-lib/contracts/contract/erc721/Erc721.sol

pragma solidity >=0.8.0;









contract Erc721 is Erc165, IErc721, IErc721Metadata {

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to owner address
  mapping(uint256 => address) private _owners;

  // Mapping owner address to token count
  mapping(address => uint256) private _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev See {IErc165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(Erc165, IErc165) returns (bool) {
    return
    interfaceId == type(IErc721).interfaceId ||
    interfaceId == type(IErc721Metadata).interfaceId ||
    super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IErc721-balanceOf}.
   */
  function balanceOf(address owner) public view virtual override returns (uint256) {
    require(owner != address(0), "Erc721: balance query for the zero address");
    return _balances[owner];
  }

  /**
   * @dev See {IErc721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "Erc721: owner query for nonexistent token");
    return owner;
  }

  /**
   * @dev See {IErc721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IErc721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IErc721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "Erc721Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, StringUtil.toString(tokenId))) : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev See {IErc721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = Erc721.ownerOf(tokenId);
    require(to != owner, "Erc721: approval to current owner");

    require(
      msg.sender == owner || isApprovedForAll(owner, msg.sender),
      "Erc721: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IErc721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view virtual override returns (address) {
    require(_exists(tokenId), "Erc721: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IErc721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    _setApprovalForAll(msg.sender, operator, approved);
  }

  /**
   * @dev See {IErc721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IErc721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(msg.sender, tokenId), "Erc721: transfer caller is not owner nor approved");

    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IErc721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IErc721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    require(_isApprovedOrOwner(msg.sender, tokenId), "Erc721: transfer caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the Erc721 protocol to prevent tokens from being forever locked.
   *
   * `_data` is additional data, it has no specified format and it is sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as signature-based.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If `to` refers to a smart contract, it must implement {IErc721Receiver-onErc721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(_checkOnErc721Received(from, to, tokenId, _data), "Erc721: transfer to non Erc721Receiver implementer");
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
    require(_exists(tokenId), "Erc721: operator query for nonexistent token");
    address owner = Erc721.ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  /**
   * @dev Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement {IErc721Receiver-onErc721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Same as {xref-Erc721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IErc721Receiver-onErc721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _mint(to, tokenId);
    require(
      _checkOnErc721Received(address(0), to, tokenId, _data),
      "Erc721: transfer to non Erc721Receiver implementer"
    );
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), "Erc721: mint to the zero address");
    require(!_exists(tokenId), "Erc721: token already minted");

    _beforeTokenTransfer(address(0), to, tokenId);

    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal virtual {
    address owner = Erc721.ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);

    _balances[owner] -= 1;
    delete _owners[tokenId];

    emit Transfer(owner, address(0), tokenId);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(Erc721.ownerOf(tokenId) == from, "Erc721: transfer of token that is not own");
    require(to != address(0), "Erc721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(Erc721.ownerOf(tokenId), to, tokenId);
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits a {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    require(owner != operator, "Erc721: approve to caller");
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Internal function to invoke {IErc721Receiver-onErc721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnErc721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (AddressUtil.isContract(to)) {
      try IErc721Receiver(to).onErc721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
        return retval == IErc721Receiver.onErc721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("Erc721: transfer to non Erc721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

// File: @pefish/solidity-lib/contracts/interface/IErc721Enumerable.sol

pragma solidity >=0.8.0;


interface IErc721Enumerable is IErc721 {

  /**
   * @dev Returns the total amount of tokens stored by the contract.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
   * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

  /**
   * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
   * Use along with {totalSupply} to enumerate all tokens.
   */
  function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @pefish/solidity-lib/contracts/contract/erc721/Erc721Enumerable.sol

pragma solidity >=0.8.0;



abstract contract Erc721Enumerable is Erc721, IErc721Enumerable {
  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] private _allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) private _allTokensIndex;

  /**
   * @dev See {IErc165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(IErc165, Erc721) returns (bool) {
    return interfaceId == type(IErc721Enumerable).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IErc721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
    require(index < Erc721.balanceOf(owner), "Erc721Enumerable: owner index out of bounds");
    return _ownedTokens[owner][index];
  }

  /**
   * @dev See {IErc721Enumerable-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _allTokens.length;
  }

  /**
   * @dev See {IErc721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
    require(index < Erc721Enumerable.totalSupply(), "Erc721Enumerable: global index out of bounds");
    return _allTokens[index];
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    if (from == address(0)) {
      _addTokenToAllTokensEnumeration(tokenId);
    } else if (from != to) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to == address(0)) {
      _removeTokenFromAllTokensEnumeration(tokenId);
    } else if (to != from) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }

  /**
   * @dev Private function to add a token to this extension's ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = Erc721.balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev Private function to add a token to this extension's token tracking data structures.
   * @param tokenId uint256 ID of the token to be added to the tokens list
   */
  function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  /**
   * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
   * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
   * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
   * This has O(1) time complexity, but alters the order of the _ownedTokens array.
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = Erc721.balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }

  /**
   * @dev Private function to remove a token from this extension's token tracking data structures.
   * This has O(1) time complexity, but alters the order of the _allTokens array.
   * @param tokenId uint256 ID of the token to be removed from the tokens list
   */
  function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = _allTokens.length - 1;
    uint256 tokenIndex = _allTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
    // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
    // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
    uint256 lastTokenId = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
    _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

    // This also deletes the contents at the last position of the array
    delete _allTokensIndex[tokenId];
    _allTokens.pop();
  }
}

// File: @pefish/solidity-lib/contracts/contract/Ownable.sol

pragma solidity >=0.8.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev init function sets the original `owner` of the contract to the sender
     * account.
     */
    function __Ownable_init () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "only owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Nft.sol

pragma solidity >=0.8.0;




/**
 * @title Full ERC721 Token with support for tokenURIPrefix
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract Nft is Erc721Enumerable, Ownable {
    string public baseURI;
    uint256 public cost = 1000 ether;
    uint256 public whitelistCost = 0 ether;
    uint256 public maxSupply;
    uint256 public maxMintNum = 20;
    bool public paused = false;
    address[] public whitelistedAddresses;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        string memory _baseURI
    ) Erc721(_name, _symbol) {
        Ownable.__Ownable_init();

        maxSupply = _maxSupply;
        baseURI = _baseURI;
    }

    // public
    function mint(uint256 _mintNum) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(_mintNum > 0, "need to mint at least 1 NFT");
        require(_mintNum <= maxMintNum, "max mint amount per session exceeded");
        require(supply + _mintNum <= maxSupply, "max NFT limit exceeded");

        if (msg.sender != owner()) {
            if(isWhitelisted(msg.sender)) {
                require(msg.value >= whitelistCost * _mintNum, "insufficient funds");
            } else {
                require(msg.value >= cost * _mintNum, "insufficient funds");
            }
        }

        for (uint256 i = 1; i <= _mintNum; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, StringUtil.toString(tokenId), ".json"))
        : "";
    }

    function setCost(uint256 _newCost, uint256 _newWhitelistCost) public onlyOwner {
        cost = _newCost;
        whitelistCost = _newWhitelistCost;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxMintNum(uint256 _newMaxMintNum) public onlyOwner {
        maxMintNum = _newMaxMintNum;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function withdraw() public payable onlyOwner {
        (bool maco, ) = payable(owner()).call{value: address(this).balance}("");
        require(maco);
    }
}