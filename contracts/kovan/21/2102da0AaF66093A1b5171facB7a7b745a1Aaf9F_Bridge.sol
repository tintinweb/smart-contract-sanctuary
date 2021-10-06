/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;
pragma abicoder v2;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Address {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

library ProtobufLib {
    /// @notice Protobuf wire types.
    enum WireType {
        Varint,
        Bits64,
        LengthDelimited,
        StartGroup,
        EndGroup,
        Bits32,
        WIRE_TYPE_MAX
    }

    /// @dev Maximum number of bytes for a varint.
    /// @dev 64 bits, in groups of base-128 (7 bits).
    uint64 internal constant MAX_VARINT_BYTES = 10;

    ////////////////////////////////////
    // Decoding
    ////////////////////////////////////

    /// @notice Decode key.
    /// @dev https://developers.google.com/protocol-buffers/docs/encoding#structure
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Field number
    /// @return Wire type
    function decode_key(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64,
            WireType
        )
    {
        // The key is a varint with encoding
        // (field_number << 3) | wire_type
        (bool success, uint64 pos, uint64 key) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0, WireType.WIRE_TYPE_MAX);
        }

        uint64 field_number = key >> 3;
        uint64 wire_type_val = key & 0x07;
        // Check that wire type is bounded
        if (wire_type_val >= uint64(WireType.WIRE_TYPE_MAX)) {
            return (false, pos, 0, WireType.WIRE_TYPE_MAX);
        }
        WireType wire_type = WireType(wire_type_val);

        // Start and end group types are deprecated, so forbid them
        if (
            wire_type == WireType.StartGroup || wire_type == WireType.EndGroup
        ) {
            return (false, pos, 0, WireType.WIRE_TYPE_MAX);
        }

        return (true, pos, field_number, wire_type);
    }

    /// @notice Decode varint.
    /// @dev https://developers.google.com/protocol-buffers/docs/encoding#varints
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_varint(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        uint64 val;
        uint64 i;

        for (i = 0; i < MAX_VARINT_BYTES; i++) {
            // Check that index is within bounds
            if (i + p >= buf.length) {
                return (false, p, 0);
            }

            // Get byte at offset
            uint8 b = uint8(buf[p + i]);

            // Highest bit is used to indicate if there are more bytes to come
            // Mask to get 7-bit value: 0111 1111
            uint8 v = b & 0x7F;

            // Groups of 7 bits are ordered least significant first
            val |= uint64(v) << uint64(i * 7);

            // Mask to get keep going bit: 1000 0000
            if (b & 0x80 == 0) {
                // [STRICT]
                // Check for trailing zeroes if more than one byte is used
                // (the value 0 still uses one byte)
                if (i > 0 && v == 0) {
                    return (false, p, 0);
                }

                break;
            }
        }

        // Check that at most MAX_VARINT_BYTES are used
        if (i >= MAX_VARINT_BYTES) {
            return (false, p, 0);
        }

        // [STRICT]
        // If all 10 bytes are used, the last byte (most significant 7 bits)
        // must be at most 0000 0001, since 7*9 = 63
        if (i == MAX_VARINT_BYTES - 1) {
            if (uint8(buf[p + i]) > 1) {
                return (false, p, 0);
            }
        }

        return (true, p + i + 1, val);
    }

    /// @notice Decode varint int32.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_int32(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            int32
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        // [STRICT]
        // Highest 4 bytes must be 0 if positive
        if (val >> 63 == 0) {
            if (val & 0xFFFFFFFF00000000 != 0) {
                return (false, pos, 0);
            }
        }

        return (true, pos, int32(uint32(val)));
    }

    /// @notice Decode varint int64.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_int64(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            int64
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, int64(val));
    }

    /// @notice Decode varint uint32.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_uint32(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint32
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        // [STRICT]
        // Highest 4 bytes must be 0
        if (val & 0xFFFFFFFF00000000 != 0) {
            return (false, pos, 0);
        }

        return (true, pos, uint32(val));
    }

    /// @notice Decode varint uint64.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_uint64(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, val);
    }

    // /// @notice Decode varint sint32.
    // /// @param p Position
    // /// @param buf Buffer
    // /// @return Success
    // /// @return New position
    // /// @return Decoded int
    // function decode_sint32(uint64 p, bytes memory buf)
    //     internal
    //     pure
    //     returns (
    //         bool,
    //         uint64,
    //         int32
    //     )
    // {
    //     (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
    //     if (!success) {
    //         return (false, pos, 0);
    //     }

    //     // [STRICT]
    //     // Highest 4 bytes must be 0
    //     if (val & 0xFFFFFFFF00000000 != 0) {
    //         return (false, pos, 0);
    //     }

    //     // https://stackoverflow.com/questions/2210923/zig-zag-decoding/2211086#2211086
    //     uint64 zigzag_val = (val >> 1) ^ (-(val & 1));

    //     return (true, pos, int32(uint32(zigzag_val)));
    // }

    // /// @notice Decode varint sint64.
    // /// @param p Position
    // /// @param buf Buffer
    // /// @return Success
    // /// @return New position
    // /// @return Decoded int
    // function decode_sint64(uint64 p, bytes memory buf)
    //     internal
    //     pure
    //     returns (
    //         bool,
    //         uint64,
    //         int64
    //     )
    // {
    //     (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
    //     if (!success) {
    //         return (false, pos, 0);
    //     }

    //     // https://stackoverflow.com/questions/2210923/zig-zag-decoding/2211086#2211086
    //     uint64 zigzag_val = (val >> 1) ^ (-(val & 1));

    //     return (true, pos, int64(zigzag_val));
    // }

    /// @notice Decode Boolean.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded bool
    function decode_bool(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            bool
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, false);
        }

        // [STRICT]
        // Value must be 0 or 1
        if (val > 1) {
            return (false, pos, false);
        }

        if (val == 0) {
            return (true, pos, false);
        }

        return (true, pos, true);
    }

    /// @notice Decode enumeration.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded enum as raw int
    function decode_enum(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            int32
        )
    {
        return decode_int32(p, buf);
    }

    /// @notice Decode fixed 64-bit int.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_bits64(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        uint64 val;

        // Check that index is within bounds
        if (8 + p > buf.length) {
            return (false, p, 0);
        }

        for (uint64 i = 0; i < 8; i++) {
            uint8 b = uint8(buf[p + i]);

            // Little endian
            val |= uint64(b) << uint64(i * 8);
        }

        return (true, p + 8, val);
    }

    /// @notice Decode fixed uint64.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_fixed64(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_bits64(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, val);
    }

    /// @notice Decode fixed int64.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_sfixed64(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            int64
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_bits64(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, int64(val));
    }

    /// @notice Decode fixed 32-bit int.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_bits32(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint32
        )
    {
        uint32 val;

        // Check that index is within bounds
        if (4 + p > buf.length) {
            return (false, p, 0);
        }

        for (uint64 i = 0; i < 4; i++) {
            uint8 b = uint8(buf[p + i]);

            // Little endian
            val |= uint32(b) << uint32(i * 8);
        }

        return (true, p + 4, val);
    }

    /// @notice Decode fixed uint32.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_fixed32(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint32
        )
    {
        (bool success, uint64 pos, uint32 val) = decode_bits32(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, val);
    }

    /// @notice Decode fixed int32.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_sfixed32(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            int32
        )
    {
        (bool success, uint64 pos, uint32 val) = decode_bits32(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, int32(val));
    }

    /// @notice Decode length-delimited field.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position (after size)
    /// @return Size in bytes
    function decode_length_delimited(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        // Length-delimited fields begin with a varint of the number of bytes that follow
        (bool success, uint64 pos, uint64 size) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        // Check for overflow
        if (pos + size < pos) {
            return (false, pos, 0);
        }

        // Check that index is within bounds
        if (size + pos > buf.length) {
            return (false, pos, 0);
        }

        return (true, pos, size);
    }

    /// @notice Decode string.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Size in bytes
    function decode_string(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            string memory
        )
    {
        (bool success, uint64 pos, uint64 size) =
            decode_length_delimited(p, buf);
        if (!success) {
            return (false, pos, "");
        }

        bytes memory field = new bytes(size);
        for (uint64 i = 0; i < size; i++) {
            field[i] = buf[pos + i];
        }

        return (true, pos + size, string(field));
    }

    /// @notice Decode bytes array.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position (after size)
    /// @return Size in bytes
    function decode_bytes(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        return decode_length_delimited(p, buf);
    }

    /// @notice Decode embedded message.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position (after size)
    /// @return Size in bytes
    function decode_embedded_message(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        return decode_length_delimited(p, buf);
    }

    /// @notice Decode packed repeated field.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position (after size)
    /// @return Size in bytes
    function decode_packed_repeated(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        return decode_length_delimited(p, buf);
    }

    ////////////////////////////////////
    // Encoding
    ////////////////////////////////////

    /// @notice Encode key.
    /// @dev https://developers.google.com/protocol-buffers/docs/encoding#structure
    /// @param field_number Field number
    /// @param wire_type Wire type
    /// @return Marshaled bytes
    function encode_key(uint64 field_number, uint64 wire_type)
        internal
        pure
        returns (bytes memory)
    {
        uint64 key = (field_number << 3) | wire_type;

        bytes memory buf = encode_varint(key);

        return buf;
    }

    /// @notice Encode varint.
    /// @dev https://developers.google.com/protocol-buffers/docs/encoding#varints
    /// @param n Number
    /// @return Marshaled bytes
    function encode_varint(uint64 n) internal pure returns (bytes memory) {
        // Count the number of groups of 7 bits
        // We need this pre-processing step since Solidity doesn't allow dynamic memory resizing
        uint64 tmp = n;
        uint64 num_bytes = 1;
        while (tmp > 0x7F) {
            tmp = tmp >> 7;
            num_bytes += 1;
        }

        bytes memory buf = new bytes(num_bytes);

        tmp = n;
        for (uint64 i = 0; i < num_bytes; i++) {
            // Set the first bit in the byte for each group of 7 bits
            buf[i] = bytes1(0x80 | uint8(tmp & 0x7F));
            tmp = tmp >> 7;
        }
        // Unset the first bit of the last byte
        buf[num_bytes - 1] &= 0x7F;

        return buf;
    }

    /// @notice Encode varint int32.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_int32(int32 n) internal pure returns (bytes memory) {
        return encode_varint(uint64(uint32(n)));
    }

    /// @notice Decode varint int64.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_int64(int64 n) internal pure returns (bytes memory) {
        return encode_varint(uint64(n));
    }

    /// @notice Encode varint uint32.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_uint32(uint32 n) internal pure returns (bytes memory) {
        return encode_varint(n);
    }

    /// @notice Encode varint uint64.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_uint64(uint64 n) internal pure returns (bytes memory) {
        return encode_varint(n);
    }

    /// @notice Encode varint sint32.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_sint32(int32 n) internal pure returns (bytes memory) {
        // https://developers.google.com/protocol-buffers/docs/encoding#signed_integers
        uint32 mask = 0;
        if (n < 0) {
            mask -= 1;
        }
        uint32 zigzag_val = (uint32(n) << 1) ^ mask;

        return encode_varint(zigzag_val);
    }

    /// @notice Encode varint sint64.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_sint64(int64 n) internal pure returns (bytes memory) {
        // https://developers.google.com/protocol-buffers/docs/encoding#signed_integers
        uint64 mask = 0;
        if (n < 0) {
            mask -= 1;
        }
        uint64 zigzag_val = (uint64(n) << 1) ^ mask;

        return encode_varint(zigzag_val);
    }

    /// @notice Encode Boolean.
    /// @param b Boolean
    /// @return Marshaled bytes
    function encode_bool(bool b) internal pure returns (bytes memory) {
        uint64 n = b ? 1 : 0;

        return encode_varint(n);
    }

    /// @notice Encode enumeration.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_enum(int32 n) internal pure returns (bytes memory) {
        return encode_int32(n);
    }

    /// @notice Encode fixed 64-bit int.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_bits64(uint64 n) internal pure returns (bytes memory) {
        bytes memory buf = new bytes(8);

        uint64 tmp = n;
        for (uint64 i = 0; i < 8; i++) {
            // Little endian
            buf[i] = bytes1(uint8(tmp & 0xFF));
            tmp = tmp >> 8;
        }

        return buf;
    }

    /// @notice Encode fixed uint64.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_fixed64(uint64 n) internal pure returns (bytes memory) {
        return encode_bits64(n);
    }

    /// @notice Encode fixed int64.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_sfixed64(int64 n) internal pure returns (bytes memory) {
        return encode_bits64(uint64(n));
    }

    /// @notice Decode fixed 32-bit int.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_bits32(uint32 n) internal pure returns (bytes memory) {
        bytes memory buf = new bytes(4);

        uint64 tmp = n;
        for (uint64 i = 0; i < 4; i++) {
            // Little endian
            buf[i] = bytes1(uint8(tmp & 0xFF));
            tmp = tmp >> 8;
        }

        return buf;
    }

    /// @notice Encode fixed uint32.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_fixed32(uint32 n) internal pure returns (bytes memory) {
        return encode_bits32(n);
    }

    /// @notice Encode fixed int32.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_sfixed32(int32 n) internal pure returns (bytes memory) {
        return encode_bits32(uint32(n));
    }

    /// @notice Encode length-delimited field.
    /// @param b Bytes
    /// @return Marshaled bytes
    function encode_length_delimited(bytes memory b)
        internal
        pure
        returns (bytes memory)
    {
        // Length-delimited fields begin with a varint of the number of bytes that follow
        bytes memory length_buf = encode_uint64(uint64(b.length));
        bytes memory buf = new bytes(b.length + length_buf.length);

        for (uint64 i = 0; i < length_buf.length; i++) {
            buf[i] = length_buf[i];
        }

        for (uint64 i = 0; i < b.length; i++) {
            buf[i + length_buf.length] = b[i];
        }

        return buf;
    }

    /// @notice Encode string.
    /// @param s String
    /// @return Marshaled bytes
    function encode_string(string memory s)
        internal
        pure
        returns (bytes memory)
    {
        return encode_length_delimited(bytes(s));
    }

    /// @notice Encode bytes array.
    /// @param b Bytes
    /// @return Marshaled bytes
    function encode_bytes(bytes memory b) internal pure returns (bytes memory) {
        return encode_length_delimited(b);
    }

    /// @notice Encode embedded message.
    /// @param m Message
    /// @return Marshaled bytes
    function encode_embedded_message(bytes memory m)
        internal
        pure
        returns (bytes memory)
    {
        return encode_length_delimited(m);
    }

    /// @notice Encode packed repeated field.
    /// @param b Bytes
    /// @return Marshaled bytes
    function encode_packed_repeated(bytes memory b)
        internal
        pure
        returns (bytes memory)
    {
        return encode_length_delimited(b);
    }
}

library Utils {
    /// @dev Returns the hash of a Merkle leaf node.
    function merkleLeafHash(bytes memory value)
        internal
        pure
        returns (bytes32)
    {
        return sha256(abi.encodePacked(uint8(0), value));
    }

    /// @dev Returns the hash of internal node, calculated from child nodes.
    function merkleInnerHash(bytes32 left, bytes32 right)
        internal
        pure
        returns (bytes32)
    {
        return sha256(abi.encodePacked(uint8(1), left, right));
    }

    /// @dev Returns the encoded bytes using signed varint encoding of the given input.
    function encodeVarintSigned(uint256 value)
        internal
        pure
        returns (bytes memory)
    {
        return encodeVarintUnsigned(value * 2);
    }

    /// @dev Returns the encoded bytes using unsigned varint encoding of the given input.
    function encodeVarintUnsigned(uint256 value)
        internal
        pure
        returns (bytes memory)
    {
        // Computes the size of the encoded value.
        uint256 tempValue = value;
        uint256 size = 0;
        while (tempValue > 0) {
            ++size;
            tempValue >>= 7;
        }
        // Allocates the memory buffer and fills in the encoded value.
        bytes memory result = new bytes(size);
        tempValue = value;
        for (uint256 idx = 0; idx < size; ++idx) {
            result[idx] = bytes1(uint8(128) | uint8(tempValue & 127));
            tempValue >>= 7;
        }
        result[size - 1] &= bytes1(uint8(127)); // Drop the first bit of the last byte.
        return result;
    }

    /// @dev Returns the encoded bytes follow how tendermint encode time.
    function encodeTime(uint64 second, uint32 nanoSecond)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory result =
            abi.encodePacked(hex"08", encodeVarintUnsigned(uint256(second)));
        if (nanoSecond > 0) {
            result = abi.encodePacked(
                result,
                hex"10",
                encodeVarintUnsigned(uint256(nanoSecond))
            );
        }
        return result;
    }
}


library BlockHeaderMerkleParts {
    struct Data {
        bytes32 versionAndChainIdHash; // [1A]
        uint64 height; // [2]
        uint64 timeSecond; // [3]
        uint32 timeNanoSecondFraction; // between 0 to 10^9 [3]
        bytes32 lastBlockIdAndOther; // [2B]
        bytes32 nextValidatorHashAndConsensusHash; // [1E]
        bytes32 lastResultsHash; // [B]
        bytes32 evidenceAndProposerHash; // [2D]
    }

    /// @dev Returns the block header hash after combining merkle parts with necessary data.
    /// @param appHash The Merkle hash of BandChain application state.
    function getBlockHeader(Data memory self, bytes32 appHash)
        internal
        pure
        returns (bytes32)
    {
        return
            Utils.merkleInnerHash( // [BlockHeader]
                Utils.merkleInnerHash( // [3A]
                    Utils.merkleInnerHash( // [2A]
                        self.versionAndChainIdHash, // [1A]
                        Utils.merkleInnerHash( // [1B]
                            Utils.merkleLeafHash( // [2]
                                abi.encodePacked(
                                    uint8(8),
                                    Utils.encodeVarintUnsigned(self.height)
                                )
                            ),
                            Utils.merkleLeafHash( // [3]
                                Utils.encodeTime(
                                    self.timeSecond,
                                    self.timeNanoSecondFraction
                                )
                            )
                        )
                    ),
                    self.lastBlockIdAndOther // [2B]
                ),
                Utils.merkleInnerHash( // [3B]
                    Utils.merkleInnerHash( // [2C]
                        self.nextValidatorHashAndConsensusHash, // [1E]
                        Utils.merkleInnerHash( // [1F]
                            Utils.merkleLeafHash( // [A]
                                abi.encodePacked(uint8(10), uint8(32), appHash)
                            ),
                            self.lastResultsHash // [B]
                        )
                    ),
                    self.evidenceAndProposerHash // [2D]
                )
            );
    }
}


library MultiStore {
    struct Data {
        bytes32 authToFeeGrantStoresMerkleHash; // [I12]
        bytes32 govToIbcCoreStoresMerkleHash; // [I4]
        bytes32 mintStoreMerkleHash; // [A]
        bytes32 oracleIAVLStateHash; // [B]
        bytes32 paramsToTransferStoresMerkleHash; // [I11]
        bytes32 upgradeStoreMerkleHash; // [G]
    }

    function getAppHash(Data memory self) internal pure returns (bytes32) {
        return
            Utils.merkleInnerHash( // [AppHash]
                Utils.merkleInnerHash( // [I14]
                    self.authToFeeGrantStoresMerkleHash, // [I10]
                    Utils.merkleInnerHash( // [I13]
                        Utils.merkleInnerHash( // [I10]
                            self.govToIbcCoreStoresMerkleHash, // [I4]
                            Utils.merkleInnerHash( // [I5]
                                self.mintStoreMerkleHash, // [A]
                                Utils.merkleLeafHash( // [B]
                                    abi.encodePacked(
                                        hex"066f7261636c6520", // oracle prefix (uint8(6) + "oracle" + uint8(32))
                                        sha256(
                                            abi.encodePacked(
                                                self.oracleIAVLStateHash
                                            )
                                        )
                                    )
                                )
                            )
                        ),
                        self.paramsToTransferStoresMerkleHash // [I11]
                    )
                ),
                self.upgradeStoreMerkleHash // [G]
            );
    }
}


library IAVLMerklePath {
    struct Data {
        bool isDataOnRight;
        uint8 subtreeHeight;
        uint256 subtreeSize;
        uint256 subtreeVersion;
        bytes32 siblingHash;
    }

    /// @dev Returns the upper Merkle hash given a proof component and hash of data subtree.
    /// @param dataSubtreeHash The hash of data subtree up until this point.
    function getParentHash(Data memory self, bytes32 dataSubtreeHash)
        internal
        pure
        returns (bytes32)
    {
        bytes32 leftSubtree =
            self.isDataOnRight ? self.siblingHash : dataSubtreeHash;
        bytes32 rightSubtree =
            self.isDataOnRight ? dataSubtreeHash : self.siblingHash;
        return
            sha256(
                abi.encodePacked(
                    self.subtreeHeight << 1, // Tendermint signed-int8 encoding requires multiplying by 2
                    Utils.encodeVarintSigned(self.subtreeSize),
                    Utils.encodeVarintSigned(self.subtreeVersion),
                    uint8(32), // Size of left subtree hash
                    leftSubtree,
                    uint8(32), // Size of right subtree hash
                    rightSubtree
                )
            );
    }
}


library TMSignature {
    struct Data {
        bytes32 r;
        bytes32 s;
        uint8 v;
        bytes signedDataPrefix;
        bytes signedDataSuffix;
    }

    /// @dev Returns the address that signed on the given block hash.
    /// @param blockHash The block hash that the validator signed data on.
    function recoverSigner(Data memory self, bytes32 blockHash)
        internal
        pure
        returns (address)
    {
        return
            ecrecover(
                sha256(
                    abi.encodePacked(
                        self.signedDataPrefix,
                        blockHash,
                        self.signedDataSuffix
                    )
                ),
                self.v,
                self.r,
                self.s
            );
    }
}

library ResultCodec {
    function encode(IBridge.Result memory instance)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory finalEncoded;

        // Omit encoding clientID if default value
        if (bytes(instance.clientID).length > 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(
                    1,
                    uint64(ProtobufLib.WireType.LengthDelimited)
                ),
                ProtobufLib.encode_uint64(
                    uint64(bytes(instance.clientID).length)
                ),
                bytes(instance.clientID)
            );
        }

        // Omit encoding oracleScriptID if default value
        if (uint64(instance.oracleScriptID) != 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(2, uint64(ProtobufLib.WireType.Varint)),
                ProtobufLib.encode_uint64(instance.oracleScriptID)
            );
        }

        // Omit encoding params if default value
        if (bytes(instance.params).length > 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(
                    3,
                    uint64(ProtobufLib.WireType.LengthDelimited)
                ),
                ProtobufLib.encode_uint64(
                    uint64(bytes(instance.params).length)
                ),
                bytes(instance.params)
            );
        }

        // Omit encoding askCount if default value
        if (uint64(instance.askCount) != 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(4, uint64(ProtobufLib.WireType.Varint)),
                ProtobufLib.encode_uint64(instance.askCount)
            );
        }

        // Omit encoding minCount if default value
        if (uint64(instance.minCount) != 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(5, uint64(ProtobufLib.WireType.Varint)),
                ProtobufLib.encode_uint64(instance.minCount)
            );
        }

        // Omit encoding requestID if default value
        if (uint64(instance.requestID) != 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(6, uint64(ProtobufLib.WireType.Varint)),
                ProtobufLib.encode_uint64(instance.requestID)
            );
        }

        // Omit encoding ansCount if default value
        if (uint64(instance.ansCount) != 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(7, uint64(ProtobufLib.WireType.Varint)),
                ProtobufLib.encode_uint64(instance.ansCount)
            );
        }

        // Omit encoding requestTime if default value
        if (uint64(instance.requestTime) != 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(8, uint64(ProtobufLib.WireType.Varint)),
                ProtobufLib.encode_uint64(instance.requestTime)
            );
        }

        // Omit encoding resolveTime if default value
        if (uint64(instance.resolveTime) != 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(9, uint64(ProtobufLib.WireType.Varint)),
                ProtobufLib.encode_uint64(instance.resolveTime)
            );
        }

        // Omit encoding resolveStatus if default value
        if (uint64(instance.resolveStatus) != 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(10, uint64(ProtobufLib.WireType.Varint)),
                ProtobufLib.encode_int32(int32(uint32(instance.resolveStatus)))
            );
        }

        // Omit encoding result if default value
        if (bytes(instance.result).length > 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(
                    11,
                    uint64(ProtobufLib.WireType.LengthDelimited)
                ),
                ProtobufLib.encode_uint64(
                    uint64(bytes(instance.result).length)
                ),
                bytes(instance.result)
            );
        }

        return finalEncoded;
    }
}



interface IBridge {
    enum ResolveStatus {
        RESOLVE_STATUS_OPEN_UNSPECIFIED,
        RESOLVE_STATUS_SUCCESS,
        RESOLVE_STATUS_FAILURE,
        RESOLVE_STATUS_EXPIRED
    }
    /// Result struct is similar packet on Bandchain using to re-calculate result hash.
    struct Result {
        string clientID;
        uint64 oracleScriptID;
        bytes params;
        uint64 askCount;
        uint64 minCount;
        uint64 requestID;
        uint64 ansCount;
        uint64 requestTime;
        uint64 resolveTime;
        ResolveStatus resolveStatus;
        bytes result;
    }

    /// Performs oracle state relay and oracle data verification in one go. The caller submits
    /// the encoded proof and receives back the decoded data, ready to be validated and used.
    /// @param data The encoded data for oracle state relay and data verification.
    function relayAndVerify(bytes calldata data)
        external
        returns (Result memory);

    /// Performs oracle state relay and many times of oracle data verification in one go. The caller submits
    /// the encoded proof and receives back the decoded data, ready to be validated and used.
    /// @param data The encoded data for oracle state relay and an array of data verification.
    function relayAndMultiVerify(bytes calldata data)
        external
        returns (Result[] memory);

    // Performs oracle state relay and requests count verification in one go. The caller submits
    /// the encoded proof and receives back the decoded data, ready tobe validated and used.
    /// @param data The encoded data for oracle state relay and requests count verification.
    function relayAndVerifyCount(bytes calldata data)
        external
        returns (uint64, uint64); // block time, requests count
}



contract Bridge is IBridge, Ownable {
    using BlockHeaderMerkleParts for BlockHeaderMerkleParts.Data;
    using MultiStore for MultiStore.Data;
    using IAVLMerklePath for IAVLMerklePath.Data;
    using TMSignature for TMSignature.Data;

    struct ValidatorWithPower {
        address addr;
        uint256 power;
    }

    struct BlockDetail {
        bytes32 oracleState;
        uint64 timeSecond;
        uint32 timeNanoSecondFraction; // between 0 to 10^9
    }

    /// Mapping from block height to the struct that contains block time and hash of "oracle" iAVL Merkle tree.
    mapping(uint256 => BlockDetail) public blockDetails;
    /// Mapping from an address to its voting power.
    mapping(address => uint256) public validatorPowers;
    /// The total voting power of active validators currently on duty.
    uint256 public totalValidatorPower;

    /// Initializes an oracle bridge to BandChain.
    /// @param validators The initial set of BandChain active validators.
    constructor(ValidatorWithPower[] memory validators) {
        for (uint256 idx = 0; idx < validators.length; ++idx) {
            ValidatorWithPower memory validator = validators[idx];
            require(
                validatorPowers[validator.addr] == 0,
                "DUPLICATION_IN_INITIAL_VALIDATOR_SET"
            );
            validatorPowers[validator.addr] = validator.power;
            totalValidatorPower += validator.power;
        }
    }

    /// Update validator powers by owner.
    /// @param validators The changed set of BandChain validators.
    function updateValidatorPowers(ValidatorWithPower[] calldata validators)
        external
        onlyOwner
    {
        for (uint256 idx = 0; idx < validators.length; ++idx) {
            ValidatorWithPower memory validator = validators[idx];
            totalValidatorPower -= validatorPowers[validator.addr];
            validatorPowers[validator.addr] = validator.power;
            totalValidatorPower += validator.power;
        }
    }

    /// Relays a detail of Bandchain block to the bridge contract.
    /// @param multiStore Extra multi store to compute app hash. See MultiStore lib.
    /// @param merkleParts Extra merkle parts to compute block hash. See BlockHeaderMerkleParts lib.
    /// @param signatures The signatures signed on this block, sorted alphabetically by address.
    function relayBlock(
        MultiStore.Data calldata multiStore,
        BlockHeaderMerkleParts.Data calldata merkleParts,
        TMSignature.Data[] calldata signatures
    ) public {
        if (
            blockDetails[merkleParts.height].oracleState == multiStore.oracleIAVLStateHash &&
            blockDetails[merkleParts.height].timeSecond == merkleParts.timeSecond &&
            blockDetails[merkleParts.height].timeNanoSecondFraction == merkleParts.timeNanoSecondFraction
        ) return;

        // Computes Tendermint's block header hash at this given block.
        bytes32 blockHeader = merkleParts.getBlockHeader(multiStore.getAppHash());
        // Counts the total number of valid signatures signed by active validators.
        address lastSigner = address(0);
        uint256 sumVotingPower = 0;
        for (uint256 idx = 0; idx < signatures.length; ++idx) {
            address signer = signatures[idx].recoverSigner(blockHeader);
            require(signer > lastSigner, "INVALID_SIGNATURE_SIGNER_ORDER");
            sumVotingPower += validatorPowers[signer];
            lastSigner = signer;
        }
        // Verifies that sufficient validators signed the block and saves the oracle state.
        require(
            sumVotingPower * 3 > totalValidatorPower * 2,
            "INSUFFICIENT_VALIDATOR_SIGNATURES"
        );
        blockDetails[merkleParts.height] = BlockDetail({
            oracleState: multiStore.oracleIAVLStateHash,
            timeSecond: merkleParts.timeSecond,
            timeNanoSecondFraction: merkleParts.timeNanoSecondFraction
        });
    }

    /// Verifies that the given data is a valid data on BandChain as of the relayed block height.
    /// @param blockHeight The block height. Someone must already relay this block.
    /// @param result The result of this request.
    /// @param version Lastest block height that the data node was updated.
    /// @param merklePaths Merkle proof that shows how the data leave is part of the oracle iAVL.
    function verifyOracleData(
        uint256 blockHeight,
        Result calldata result,
        uint256 version,
        IAVLMerklePath.Data[] calldata merklePaths
    ) public view returns (Result memory) {
        bytes32 oracleStateRoot = blockDetails[blockHeight].oracleState;
        require(
            oracleStateRoot != bytes32(uint256(0)),
            "NO_ORACLE_ROOT_STATE_DATA"
        );
        // Computes the hash of leaf node for iAVL oracle tree.
        bytes32 dataHash = sha256(ResultCodec.encode(result));

        // Verify proof
        require(
            verifyProof(
                oracleStateRoot,
                version,
                abi.encodePacked(
                    uint8(255),
                    result.requestID
                ),
                dataHash,
                merklePaths
            ),
            "INVALID_ORACLE_DATA_PROOF"
        );

        return result;
    }

    /// Verifies that the given data is a valid data on BandChain as of the relayed block height.
    /// @param blockHeight The block height. Someone must already relay this block.
    /// @param count The requests count on the block.
    /// @param version Lastest block height that the data node was updated.
    /// @param merklePaths Merkle proof that shows how the data leave is part of the oracle iAVL.
    function verifyRequestsCount(
        uint256 blockHeight,
        uint256 count,
        uint256 version,
        IAVLMerklePath.Data[] memory merklePaths
    ) public view returns (uint64, uint64) {
        BlockDetail memory blockDetail = blockDetails[blockHeight];
        bytes32 oracleStateRoot = blockDetail.oracleState;
        require(
            oracleStateRoot != bytes32(uint256(0)),
            "NO_ORACLE_ROOT_STATE_DATA"
        );

        // Encode and calculate hash of count
        bytes32 dataHash = sha256(abi.encodePacked(uint64(count)));

        // Verify proof
        require(
            verifyProof(
                oracleStateRoot,
                version,
                hex"0052657175657374436f756e74",
                dataHash,
                merklePaths
            ),
            "INVALID_ORACLE_DATA_PROOF"
        );

        return (blockDetail.timeSecond, uint64(count));
    }

    /// Performs oracle state relay and oracle data verification in one go. The caller submits
    /// the encoded proof and receives back the decoded data, ready to be validated and used.
    /// @param data The encoded data for oracle state relay and data verification.
    function relayAndVerify(bytes calldata data)
        external
        override
        returns (Result memory)
    {
        (bytes memory relayData, bytes memory verifyData) = abi.decode(
            data, 
            (bytes, bytes)
        );
        (bool relayOk, ) = address(this).call(
            abi.encodePacked(this.relayBlock.selector, relayData)
        );
        require(relayOk, "RELAY_BLOCK_FAILED");
        (bool verifyOk, bytes memory verifyResult) = address(this).staticcall(
            abi.encodePacked(this.verifyOracleData.selector, verifyData)
        );
        require(verifyOk, "VERIFY_ORACLE_DATA_FAILED");
        return abi.decode(verifyResult, (Result));
    }

    /// Performs oracle state relay and many times of oracle data verification in one go. The caller submits
    /// the encoded proof and receives back the decoded data, ready to be validated and used.
    /// @param data The encoded data for oracle state relay and an array of data verification.
    function relayAndMultiVerify(bytes calldata data)
        external
        override
        returns (Result[] memory)
    {
        (bytes memory relayData, bytes[] memory manyVerifyData) = abi.decode(
            data, 
            (bytes, bytes[])
        );
        (bool relayOk, ) = address(this).call(
            abi.encodePacked(this.relayBlock.selector, relayData)
        );
        require(relayOk, "RELAY_BLOCK_FAILED");

        Result[] memory results = new Result[](manyVerifyData.length);
        for (uint256 i = 0; i < manyVerifyData.length; i++) {
            (bool verifyOk, bytes memory verifyResult) =
                address(this).staticcall(
                    abi.encodePacked(
                        this.verifyOracleData.selector,
                        manyVerifyData[i]
                    )
                );
            require(verifyOk, "VERIFY_ORACLE_DATA_FAILED");
            results[i] = abi.decode(verifyResult, (Result));
        }

        return results;
    }

    /// Performs oracle state relay and requests count verification in one go. The caller submits
    /// the encoded proof and receives back the decoded data, ready to be validated and used.
    /// @param data The encoded data
    function relayAndVerifyCount(bytes calldata data)
        external
        override
        returns (uint64, uint64) 
    {
        (bytes memory relayData, bytes memory verifyData) = abi.decode(
            data,
            (bytes, bytes)
        );
        (bool relayOk, ) = address(this).call(
            abi.encodePacked(this.relayBlock.selector, relayData)
        );
        require(relayOk, "RELAY_BLOCK_FAILED");

        (bool verifyOk, bytes memory verifyResult) = address(this).staticcall(
            abi.encodePacked(this.verifyRequestsCount.selector, verifyData)
        );
        require(verifyOk, "VERIFY_REQUESTS_COUNT_FAILED");

        return abi.decode(verifyResult, (uint64, uint64));
    }
    
    /// Verifies validity of the given data in the Oracle store. This function is used for both
    /// querying an oracle request and request count.
    /// @param rootHash The expected rootHash of the oracle store.
    /// @param version Lastest block height that the data node was updated.
    /// @param key The encoded key of an oracle request or request count. 
    /// @param dataHash Hashed data corresponding to the provided key.
    /// @param merklePaths Merkle proof that shows how the data leave is part of the oracle iAVL.
    function verifyProof(
        bytes32 rootHash,
        uint256 version,
        bytes memory key,
        bytes32 dataHash,
        IAVLMerklePath.Data[] memory merklePaths
    ) internal pure returns (bool) {
        bytes memory encodedVersion = Utils.encodeVarintSigned(version);

        bytes32 currentMerkleHash = sha256(
            abi.encodePacked(
                uint8(0), // Height of tree (only leaf node) is 0 (signed-varint encode)
                uint8(2), // Size of subtree is 1 (signed-varint encode)
                encodedVersion,
                uint8(key.length), // Size of data key
                key,
                uint8(32), // Size of data hash
                dataHash
            )
        );

        // Goes step-by-step computing hash of parent nodes until reaching root node.
        for (uint256 idx = 0; idx < merklePaths.length; ++idx) {
            currentMerkleHash = merklePaths[idx].getParentHash(
                currentMerkleHash
            );
        }

        // Verifies that the computed Merkle root matches what currently exists.
        return currentMerkleHash == rootHash;
    }
}