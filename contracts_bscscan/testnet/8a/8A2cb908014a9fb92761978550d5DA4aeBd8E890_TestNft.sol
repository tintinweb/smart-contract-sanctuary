/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// File: @pefish/solidity-lib/contracts/contract/Ownable.sol

// SPDX-License-Identifier: MIT

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

// File: @pefish/solidity-lib/contracts/library/AddressUtil.sol

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


/** @title string util */
library StringUtil {

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

// File: contracts/interface/IErc721Receiver.sol

interface IErc721Receiver {
  function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) external returns (bytes4);
}

// File: contracts/token/TestNft.sol





/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 {
  /**
   * @dev Mapping of interface ids to whether or not it's supported.
   */
  mapping(bytes4 => bool) private _supportedInterfaces;

  /**
   * @dev See {IERC165-supportsInterface}.
   *
   * Time complexity O(1), guaranteed to always use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool) {
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

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is ERC165 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  // Mapping from token ID to owner
  mapping (uint256 => address) private _tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private _tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) private _ownedTokensCount;  // 用户拥有的 NFT 的数量

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal _operatorApprovals;

  /*
   *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
   *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
   *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
   *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
   *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
   *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
   *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
   *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
   *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
   *
   *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
   *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
   */
  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

  function __ERC721_init () internal {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(_INTERFACE_ID_ERC721);
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");

    return _ownedTokensCount[owner];
  }

  /**
   * @dev Gets the owner of the specified token ID.
   * @param tokenId uint256 ID of the token to query the owner of
   * @return address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _tokenOwner[tokenId];
    require(owner != address(0), "ERC721: owner query for nonexistent token");

    return owner;
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param to address to be approved for the given token ID
   * @param tokenId uint256 ID of the token to be approved
   */
  function approve(address to, uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
      "ERC721: approve caller is not owner nor approved for all"
    );

    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * Reverts if the token ID does not exist.
   * @param tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf.
   * @param to operator address to set the approval
   * @param approved representing the status of the approval to be set
   */
  function setApprovalForAll(address to, bool approved) public {
    require(to != msg.sender, "ERC721: approve to caller");

    _operatorApprovals[msg.sender][to] = approved;
    emit ApprovalForAll(msg.sender, to, approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner.
   * @param owner owner address which you want to query the approval of
   * @param operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address.
   * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   * Requires the msg.sender to be the owner, approved, or operator.
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   */
  function transferFrom(address from, address to, uint256 tokenId) public {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

    _transferFrom(from, to, tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg.sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
    _transferFrom(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  /**
   * @dev Returns whether the specified token exists.
   * @param tokenId uint256 ID of the token to query the existence of
   * @return bool whether the token exists
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID.
   * @param spender address of the spender to query
   * @param tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   * is an operator of the owner, or is the owner of the token
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  /**
   * @dev Internal function to safely mint a new token.
   * Reverts if the given token ID already exists.
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted
   */
  function _safeMint(address to, uint256 tokenId) internal {
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Internal function to safely mint a new token.
   * Reverts if the given token ID already exists.
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted
   * @param _data bytes data to send along with a safe transfer check
   */
  function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
    _mint(to, tokenId);
    require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  /**
   * @dev Internal function to mint a new token.
   * Reverts if the given token ID already exists.
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted
   */
  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");

    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to] += 1;

    emit Transfer(address(0), to, tokenId);
  }

  /**
   * @dev Internal function to burn a specific token.
   * Reverts if the token does not exist.
   * Deprecated, use {_burn} instead.
   * @param owner owner of the token to burn
   * @param tokenId uint256 ID of the token being burned
   */
  function _burn(address owner, uint256 tokenId) internal virtual {
    require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

    _clearApproval(tokenId);

    _ownedTokensCount[owner] -= 1;
    _tokenOwner[tokenId] = address(0);

    emit Transfer(owner, address(0), tokenId);
  }

  /**
   * @dev Internal function to burn a specific token.
   * Reverts if the token does not exist.
   * @param tokenId uint256 ID of the token being burned
   */
  function _burn(uint256 tokenId) internal {
    _burn(ownerOf(tokenId), tokenId);
  }

  /**
   * @dev Internal function to transfer ownership of a given token ID to another address.
   * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   */
  function _transferFrom(address from, address to, uint256 tokenId) internal virtual {
    require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
    require(to != address(0), "ERC721: transfer to the zero address");

    _clearApproval(tokenId);

    _ownedTokensCount[from] -= 1;
    _ownedTokensCount[to] += 1;

    _tokenOwner[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * This is an internal detail of the `ERC721` contract and its use is deprecated.
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
  internal returns (bool)
  {
    if (!AddressUtil.isContract(to)) {
      return true;
    }
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
        IErc721Receiver(to).onERC721Received.selector,
        msg.sender,
        from,
        tokenId,
        _data
      ));
    if (!success) {
      if (returndata.length > 0) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert("ERC721: transfer to non ERC721Receiver implementer");
      }
    } else {
      bytes4 retval = abi.decode(returndata, (bytes4));
      return (retval == _ERC721_RECEIVED);
    }
  }

  /**
   * @dev Private function to clear current approval of a given token ID.
   * @param tokenId uint256 ID of the token to be transferred
   */
  function _clearApproval(uint256 tokenId) private {
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }
}


/**
 * @title ERC-721 Non-Fungible Token with optional enumeration extension logic
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Enumerable is ERC721 {
  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] private _allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) private _allTokensIndex;

  /*
   *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
   *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
   *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
   *
   *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
   */
  bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

  /**
   * @dev Constructor function.
   */
  function __ERC721Enumerable_init () internal {
    __ERC721_init();
    // register the supported interface to conform to ERC721Enumerable via ERC165
    _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner.
   * @param owner address owning the tokens list to be accessed
   * @param index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
    require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
    return _ownedTokens[owner][index];
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract.
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * Reverts if the index is greater or equal to the total number of tokens.
   * @param index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
    return _allTokens[index];
  }

  /**
   * @dev Internal function to transfer ownership of a given token ID to another address.
   * As opposed to transferFrom, this imposes no restrictions on msg.sender.
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   */
  function _transferFrom(address from, address to, uint256 tokenId) internal override {
    super._transferFrom(from, to, tokenId);

    _removeTokenFromOwnerEnumeration(from, tokenId);

    _addTokenToOwnerEnumeration(to, tokenId);
  }

  /**
   * @dev Internal function to mint a new token.
   * Reverts if the given token ID already exists.
   * @param to address the beneficiary that will own the minted token
   * @param tokenId uint256 ID of the token to be minted
   */
  function _mint(address to, uint256 tokenId) internal override {
    super._mint(to, tokenId);

    _addTokenToOwnerEnumeration(to, tokenId);

    _addTokenToAllTokensEnumeration(tokenId);
  }

  /**
   * @dev Internal function to burn a specific token.
   * Reverts if the token does not exist.
   * Deprecated, use {ERC721-_burn} instead.
   * @param owner owner of the token to burn
   * @param tokenId uint256 ID of the token being burned
   */
  function _burn(address owner, uint256 tokenId) internal virtual override {
    super._burn(owner, tokenId);

    _removeTokenFromOwnerEnumeration(owner, tokenId);
    // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
    _ownedTokensIndex[tokenId] = 0;

    _removeTokenFromAllTokensEnumeration(tokenId);
  }

  /**
   * @dev Gets the list of token IDs of the requested owner.
   * @param owner address owning the tokens
   * @return uint256[] List of token IDs owned by the requested address
   */
  function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
    return _ownedTokens[owner];
  }

  /**
   * @dev Private function to add a token to this extension's ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
    _ownedTokens[to].push(tokenId);
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

    uint256 lastTokenIndex = _ownedTokens[from].length - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    _ownedTokens[from].pop();

    // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
    // lastTokenId, or just over the end of the array if the token was the last one).
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
    _allTokens.pop();
    _allTokensIndex[tokenId] = 0;
  }
}

contract HasContractURI is ERC165 {

  string public contractURI;

  /*
   * bytes4(keccak256('contractURI()')) == 0xe8a3d485
   */
  bytes4 private constant _INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

  function __HasContractURI_init (string memory _contractURI) internal {
    contractURI = _contractURI;
    _registerInterface(_INTERFACE_ID_CONTRACT_URI);
  }

  /**
   * @dev Internal function to set the contract URI
   * @param _contractURI string URI prefix to assign
   */
  function _setContractURI(string memory _contractURI) internal {
    contractURI = _contractURI;
  }
}

contract HasTokenURI {

  //Token URI prefix
  string public tokenURIPrefix;

  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;

  function __HasTokenURI_init (string memory _tokenURIPrefix) internal {
    tokenURIPrefix = _tokenURIPrefix;
  }

  /**
   * @dev Returns an URI for a given token ID.
   * Throws if the token ID does not exist. May return an empty string.
   * @param tokenId uint256 ID of the token to query
   */
  function _tokenURI(uint256 tokenId) internal view returns (string memory) {
    return StringUtil.append(tokenURIPrefix, _tokenURIs[tokenId]);
  }

  /**
   * @dev Internal function to set the token URI for a given token.
   * Reverts if the token ID does not exist.
   * @param tokenId uint256 ID of the token to set its URI
   * @param uri string URI to assign
   */
  function _setTokenURI(uint256 tokenId, string memory uri) internal virtual {
    _tokenURIs[tokenId] = uri;
  }

  /**
   * @dev Internal function to set the token URI prefix.
   * @param _tokenURIPrefix string URI prefix to assign
   */
  function _setTokenURIPrefix(string memory _tokenURIPrefix) internal {
    tokenURIPrefix = _tokenURIPrefix;
  }

  function _clearTokenURI(uint256 tokenId) internal {
    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
  }
}

abstract contract HasSecondarySaleFees is ERC165 {

  event SecondarySaleFees(uint256 tokenId, address[] recipients, uint[] bps);

  /*
   * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
   * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
   *
   * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
   */
  bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

  function __HasSecondarySaleFees_init () internal {
    _registerInterface(_INTERFACE_ID_FEES);
  }

  function getFeeRecipients(uint256 id) public virtual view returns (address payable[] memory);
  function getFeeBps(uint256 id) public virtual view returns (uint[] memory);
}

/**
 * @title Full ERC721 Token with support for tokenURIPrefix
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Base is HasSecondarySaleFees, HasContractURI, HasTokenURI, ERC721Enumerable {
  // Token name
  string public name;

  // Token symbol
  string public symbol;

  struct Fee {
    address payable recipient;
    uint256 value;
  }

  // id => fees
  mapping (uint256 => Fee[]) public fees;

  /*
   *     bytes4(keccak256('name()')) == 0x06fdde03
   *     bytes4(keccak256('symbol()')) == 0x95d89b41
   *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
   *
   *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
   */
  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

  /**
   * @dev Constructor function
   */
  function __ERC721Base_init (string memory _name, string memory _symbol, string memory contractURI, string memory _tokenURIPrefix) internal {
    __ERC721Enumerable_init();
    __HasContractURI_init(contractURI);
    __HasTokenURI_init(_tokenURIPrefix);
    __HasSecondarySaleFees_init();

    name = _name;
    symbol = _symbol;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(_INTERFACE_ID_ERC721_METADATA);
  }

  function getFeeRecipients(uint256 id) public override view returns (address payable[] memory) {
    Fee[] memory _fees = fees[id];
    address payable[] memory result = new address payable[](_fees.length);
    for (uint i = 0; i < _fees.length; i++) {
      result[i] = _fees[i].recipient;
    }
    return result;
  }

  function getFeeBps(uint256 id) public override view returns (uint[] memory) {
    Fee[] memory _fees = fees[id];
    uint[] memory result = new uint[](_fees.length);
    for (uint i = 0; i < _fees.length; i++) {
      result[i] = _fees[i].value;
    }
    return result;
  }

  function _mint(address to, uint256 tokenId, Fee[] memory _fees) internal {
    super._mint(to, tokenId);
    address[] memory recipients = new address[](_fees.length);
    uint[] memory bps = new uint[](_fees.length);
    for (uint i = 0; i < _fees.length; i++) {
      require(_fees[i].recipient != address(0x0), "Recipient should be present");
      require(_fees[i].value != 0, "Fee value should be positive");
      fees[tokenId].push(_fees[i]);
      recipients[i] = _fees[i].recipient;
      bps[i] = _fees[i].value;
    }
    if (_fees.length > 0) {
      emit SecondarySaleFees(tokenId, recipients, bps);
    }
  }

  /**
   * @dev Returns an URI for a given token ID.
   * Throws if the token ID does not exist. May return an empty string.
   * @param tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return super._tokenURI(tokenId);
  }

  /**
   * @dev Internal function to set the token URI for a given token.
   * Reverts if the token ID does not exist.
   * @param tokenId uint256 ID of the token to set its URI
   * @param uri string URI to assign
   */
  function _setTokenURI(uint256 tokenId, string memory uri) internal override {
    require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
    super._setTokenURI(tokenId, uri);
  }

  /**
   * @dev Internal function to burn a specific token.
   * Reverts if the token does not exist.
   * Deprecated, use _burn(uint256) instead.
   * @param owner owner of the token to burn
   * @param tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address owner, uint256 tokenId) override internal {
    super._burn(owner, tokenId);
    _clearTokenURI(tokenId);
  }
}



/**
 * @title MintableToken
 * @dev anyone can mint token.
 */
contract TestNft is Ownable, ERC721Base {


  constructor (
    string memory name,
    string memory symbol,
    string memory contractURI,
    string memory tokenURIPrefix
  ) {
    __Ownable_init();
    __ERC721Base_init(name, symbol, contractURI, tokenURIPrefix);

    _registerInterface(bytes4(keccak256('MINT_WITH_ADDRESS')));
  }

  function mint(uint256 tokenId, Fee[] memory _fees, string memory tokenURI) public {
    _mintTo(msg.sender, tokenId, _fees, tokenURI);
  }

  function _mintTo(address to, uint256 tokenId, Fee[] memory _fees, string memory tokenURI) internal {
    super._mint(to, tokenId, _fees);
    _setTokenURI(tokenId, tokenURI);
  }

  /**
 * @dev Burns a specific ERC721 token.
 * @param tokenId uint256 id of the ERC721 token to be burned.
 */
  function burn(uint256 tokenId) public {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(msg.sender, tokenId), "NFT: caller is not owner nor approved");
    _burn(tokenId);
  }

  function setTokenURIPrefix(string memory tokenURIPrefix) external onlyOwner {
    _setTokenURIPrefix(tokenURIPrefix);
  }

  function setContractURI(string memory contractURI) external onlyOwner {
    _setContractURI(contractURI);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
    require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
    _safeTransferFrom(from, to, tokenId, _data);
  }
}