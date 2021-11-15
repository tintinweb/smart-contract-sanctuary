// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

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
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
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
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
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
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
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
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
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
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
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
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
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
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
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
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
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
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
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
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
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
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Abstract ownable contract that can be inherited by other contracts
 * @notice Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;
    address private _pendingOwner;

    /**
     * @dev Emitted when `_pendingOwner` has been changed.
     * @param pendingOwner new `_pendingOwner` address.
     */
    event OwnershipOffered(address indexed pendingOwner);

    /**
     * @dev Emitted when `_owner` has been changed.
     * @param previousOwner previous `_owner` address.
     * @param newOwner new `_owner` address.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /* ============ Deploy ============ */

    /**
     * @notice Initializes the contract setting `_initialOwner` as the initial owner.
     * @param _initialOwner Initial owner of the contract.
     */
    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Gets current `_pendingOwner`.
     * @return Current `_pendingOwner` address.
     */
    function pendingOwner() external view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @notice Renounce ownership of the contract.
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
    * @notice Allows current owner to set the `_pendingOwner` address.
    * @param _newOwner Address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Ownable/pendingOwner-not-zero-address");

        _pendingOwner = _newOwner;

        emit OwnershipOffered(_newOwner);
    }

    /**
    * @notice Allows the `_pendingOwner` address to finalize the transfer.
    * @dev This function is only callable by the `_pendingOwner`.
    */
    function claimOwnership() external onlyPendingOwner {
        _setOwner(_pendingOwner);
        _pendingOwner = address(0);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Internal function to set the `_owner` of the contract.
     * @param _newOwner New `_owner` address.
     */
    function _setOwner(address _newOwner) private {
        address _oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable/caller-not-owner");
        _;
    }

    /**
    * @dev Throws if called by any account other than the `pendingOwner`.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Ownable/caller-not-pendingOwner");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

/// @title Random Number Generator Interface
/// @notice Provides an interface for requesting random numbers from 3rd-party RNG services (Chainlink VRF, Starkware VDF, etc..)
interface RNGInterface {

  /// @notice Emitted when a new request for a random number has been submitted
  /// @param requestId The indexed ID of the request used to get the results of the RNG service
  /// @param sender The indexed address of the sender of the request
  event RandomNumberRequested(uint32 indexed requestId, address indexed sender);

  /// @notice Emitted when an existing request for a random number has been completed
  /// @param requestId The indexed ID of the request used to get the results of the RNG service
  /// @param randomNumber The random number produced by the 3rd-party service
  event RandomNumberCompleted(uint32 indexed requestId, uint256 randomNumber);

  /// @notice Gets the last request id used by the RNG service
  /// @return requestId The last request id used in the last request
  function getLastRequestId() external view returns (uint32 requestId);

  /// @notice Gets the Fee for making a Request against an RNG service
  /// @return feeToken The address of the token that is used to pay fees
  /// @return requestFee The fee required to be paid to make a request
  function getRequestFee() external view returns (address feeToken, uint256 requestFee);

  /// @notice Sends a request for a random number to the 3rd-party service
  /// @dev Some services will complete the request immediately, others may have a time-delay
  /// @dev Some services require payment in the form of a token, such as $LINK for Chainlink VRF
  /// @return requestId The ID of the request used to get the results of the RNG service
  /// @return lockBlock The block number at which the RNG service will start generating time-delayed randomness.  The calling contract
  /// should "lock" all activity until the result is available via the `requestId`
  function requestRandomNumber() external returns (uint32 requestId, uint32 lockBlock);

  /// @notice Checks if the request for randomness from the 3rd-party service has completed
  /// @dev For time-delayed requests, this function is used to check/confirm completion
  /// @param requestId The ID of the request used to get the results of the RNG service
  /// @return isCompleted True if the request has completed and a random number is available, false otherwise
  function isRequestComplete(uint32 requestId) external view returns (bool isCompleted);

  /// @notice Gets the random number produced by the 3rd-party service
  /// @param requestId The ID of the request used to get the results of the RNG service
  /// @return randomNum The random number
  function randomNumber(uint32 requestId) external returns (uint256 randomNum);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@pooltogether/pooltogether-rng-contracts/contracts/RNGInterface.sol";
import "@pooltogether/owner-manager-contracts/contracts/Ownable.sol";
import "./interfaces/IDrawBeacon.sol";
import "./interfaces/IDrawHistory.sol";
import "./libraries/DrawLib.sol";

/**
  * @title  PoolTogether V4 DrawBeacon
  * @author PoolTogether Inc Team
  * @notice Manages RNG (random number generator) requests and pushing Draws onto DrawHistory.
            The DrawBeacon has 3 major phases for requesting a random number: start, cancel and complete.
            Once the complete phase is executed a new Draw (using nextDrawId) is pushed to the currently
            set DrawHistory smart contracts. If the RNG service requires payment (i.e. ChainLink) the DrawBeacon
            should have an available balance to cover the fees associated with random number generation.
*/
contract DrawBeacon is IDrawBeacon,
                       Ownable {

  using SafeCast for uint256;
  using SafeERC20 for IERC20;
  using Address for address;
  using ERC165Checker for address;

  /* ============ Variables ============ */

  /// @notice RNG contract interface
  RNGInterface public rng;

  /// @notice Current RNG Request
  RngRequest internal rngRequest;

  /// @notice DrawHistory address
  IDrawHistory internal drawHistory;

  /**
    * @notice RNG Request Timeout.  In fact, this is really a "complete draw" timeout.
    * @dev If the rng completes the award can still be cancelled.
   */
  uint32 public rngTimeout;
  // first four words of mem end here

  /// @notice Seconds between beacon period request
  uint32 public beaconPeriodSeconds;

  /// @notice Epoch timestamp when beacon period can start
  uint64 public beaconPeriodStartedAt;

  /**
    * @notice Next Draw ID to use when pushing a Draw onto DrawHistory
    * @dev Starts at 1. This way we know that no Draw has been recorded at 0.
  */
  uint32 public nextDrawId;

  /* ============ Structs ============ */

  /**
    * @notice RNG Request
    * @param id          RNG request ID
    * @param lockBlock   Block number that the RNG request is locked
    * @param requestedAt Time when RNG is requested
  */
  struct RngRequest {
    uint32 id;
    uint32 lockBlock;
    uint64 requestedAt;
  }

  /* ============ Events ============ */

  /**
    * @notice Emit when the DrawBeacon is initialized.
    * @param drawHistory Address of the draw history to push draws to.
    * @param rng Address of RNG service.
    * @param nextDrawId Draw ID at which the DrawBeacon should start. Can't be inferior to 1.
    * @param beaconPeriodStartedAt Timestamp when beacon period starts.
    * @param beaconPeriodSeconds Minimum seconds between draw period.
  */
  event Deployed(
    IDrawHistory indexed drawHistory,
    RNGInterface indexed rng,
    uint32 nextDrawId,
    uint64 beaconPeriodStartedAt,
    uint32 beaconPeriodSeconds
  );

  /* ============ Modifiers ============ */

  modifier requireDrawNotInProgress() {
    _requireDrawNotInProgress();
    _;
  }

  modifier requireCanStartDraw() {
    require(_isBeaconPeriodOver(), "DrawBeacon/beacon-period-not-over");
    require(!isRngRequested(), "DrawBeacon/rng-already-requested");
    _;
  }

  modifier requireCanCompleteRngRequest() {
    require(isRngRequested(), "DrawBeacon/rng-not-requested");
    require(isRngCompleted(), "DrawBeacon/rng-not-complete");
    _;
  }

  /* ============ Constructor ============ */

  /**
    * @notice Deploy the DrawBeacon smart contract.
    * @param _owner Address of the DrawBeacon owner
    * @param _drawHistory The address of the draw history to push draws to
    * @param _rng The RNG service to use
    * @param _nextDrawId Draw ID at which the DrawBeacon should start. Can't be inferior to 1.
    * @param _beaconPeriodStart The starting timestamp of the beacon period.
    * @param _beaconPeriodSeconds The duration of the beacon period in seconds
  */
  constructor (
    address _owner,
    IDrawHistory _drawHistory,
    RNGInterface _rng,
    uint32 _nextDrawId,
    uint64 _beaconPeriodStart,
    uint32 _beaconPeriodSeconds
  ) Ownable(_owner) {
    require(_beaconPeriodStart > 0, "DrawBeacon/beacon-period-greater-than-zero");
    require(address(_rng) != address(0), "DrawBeacon/rng-not-zero");
    rng = _rng;

    _setBeaconPeriodSeconds(_beaconPeriodSeconds);
    beaconPeriodStartedAt = _beaconPeriodStart;

    _setDrawHistory(_drawHistory);

    // 30 min timeout
    _setRngTimeout(1800);

    require(_nextDrawId >= 1, "DrawBeacon/next-draw-id-gte-one");
    nextDrawId = _nextDrawId;

    emit Deployed(
      _drawHistory,
      _rng,
      _nextDrawId,
      _beaconPeriodStart,
      _beaconPeriodSeconds
    );

    emit BeaconPeriodStarted(msg.sender, _beaconPeriodStart);
  }

  /* ============ Public Functions ============ */

  /**
    * @notice Returns whether the random number request has completed.
    * @return True if a random number request has completed, false otherwise.
   */
  function isRngCompleted() public view override returns (bool) {
    return rng.isRequestComplete(rngRequest.id);
  }

  /**
    * @notice Returns whether a random number has been requested
    * @return True if a random number has been requested, false otherwise.
   */
  function isRngRequested() public view override returns (bool) {
    return rngRequest.id != 0;
  }

  /**
    * @notice Returns whether the random number request has timed out.
    * @return True if a random number request has timed out, false otherwise.
   */
  function isRngTimedOut() public view override returns (bool) {
    if (rngRequest.requestedAt == 0) {
      return false;
    } else {
      uint64 time = _currentTime();
      return rngTimeout + rngRequest.requestedAt < time;
    }
  }

  /* ============ External Functions ============ */

  /// @inheritdoc IDrawBeacon
  function canStartDraw() external view override returns (bool) {
    return _isBeaconPeriodOver() && !isRngRequested();
  }

  /// @inheritdoc IDrawBeacon
  function canCompleteDraw() external view override returns (bool) {
    return isRngRequested() && isRngCompleted();
  }

  /// @inheritdoc IDrawBeacon
  function calculateNextBeaconPeriodStartTime(uint256 currentTime) external view override returns (uint64) {
    return _calculateNextBeaconPeriodStartTime(beaconPeriodStartedAt, beaconPeriodSeconds, uint64(currentTime));
  }

  /// @inheritdoc IDrawBeacon
  function cancelDraw() external override {
    require(isRngTimedOut(), "DrawBeacon/rng-not-timedout");
    uint32 requestId = rngRequest.id;
    uint32 lockBlock = rngRequest.lockBlock;
    delete rngRequest;
    emit DrawCancelled(msg.sender, requestId, lockBlock);
  }

  /// @inheritdoc IDrawBeacon
  function completeDraw() external override requireCanCompleteRngRequest {
    uint256 randomNumber = rng.randomNumber(rngRequest.id);
    uint32 _nextDrawId = nextDrawId;
    uint64 _beaconPeriodStartedAt = beaconPeriodStartedAt;
    uint32 _beaconPeriodSeconds = beaconPeriodSeconds;
    uint64 _time = _currentTime();

    /**
      * A new DrawLib.Draw contains minimal data regarding the state "core" draw state.
      * Ultimately a Draw.drawId(s) is linked with DrawLib.PrizeDistribution(s) creating
      * the complete draw prize payout model: prize tiers, payouts, pick indices, etc...
      * A single Draw struct can have a ONE-TO-MANY relationship with PrizeDistribution settings.
      * Minimizing the total random numbers required to fairly distribute protocol pool payouts.
     */
    DrawLib.Draw memory _draw = DrawLib.Draw({
      winningRandomNumber: randomNumber,
      drawId: _nextDrawId,
      timestamp: _time,
      beaconPeriodStartedAt: _beaconPeriodStartedAt,
      beaconPeriodSeconds: _beaconPeriodSeconds
    });

    /**
      * The DrawBeacon (deployed on L1) will have a Manager role authorized to push history onto DrawHistory.
     */
    drawHistory.pushDraw(_draw);
    
    // to avoid clock drift, we should calculate the start time based on the previous period start time.
    _beaconPeriodStartedAt = _calculateNextBeaconPeriodStartTime(_beaconPeriodStartedAt, _beaconPeriodSeconds, _time);
    beaconPeriodStartedAt = _beaconPeriodStartedAt;
    nextDrawId = _nextDrawId + 1;


    // Reset the rngReqeust state so Beacon period can start again.
    delete rngRequest;

    emit DrawCompleted(msg.sender, randomNumber);
    emit BeaconPeriodStarted(msg.sender, _beaconPeriodStartedAt);
  }

  /// @inheritdoc IDrawBeacon
  function beaconPeriodRemainingSeconds() external view override returns (uint32) {
    return _beaconPeriodRemainingSeconds();
  }

  /// @inheritdoc IDrawBeacon
  function beaconPeriodEndAt() external view override returns (uint64) {
    return _beaconPeriodEndAt();
  }

  function getBeaconPeriodSeconds() external view returns (uint32) {
    return beaconPeriodSeconds;
  }

  function getBeaconPeriodStartedAt() external view returns (uint64) {
    return beaconPeriodStartedAt;
  }

  function getDrawHistory() external view returns (IDrawHistory) {
    return drawHistory;
  }

  function getNextDrawId() external view returns (uint32) {
    return nextDrawId;
  }

  /// @inheritdoc IDrawBeacon
  function getLastRngLockBlock() external view override returns (uint32) {
    return rngRequest.lockBlock;
  }

  function getLastRngRequestId() external view override returns (uint32) {
    return rngRequest.id;
  }

  function getRngService() external view returns (RNGInterface) {
    return rng;
  }
  function getRngTimeout() external view returns (uint32) {
    return rngTimeout;
  }

  /// @inheritdoc IDrawBeacon
  function isBeaconPeriodOver() external view override returns (bool) {
    return _isBeaconPeriodOver();
  }

  /// @inheritdoc IDrawBeacon
  function setDrawHistory(IDrawHistory newDrawHistory) external override onlyOwner returns (IDrawHistory) {
    return _setDrawHistory(newDrawHistory);
  }

   /// @inheritdoc IDrawBeacon
  function startDraw() external override requireCanStartDraw {
    (address feeToken, uint256 requestFee) = rng.getRequestFee();
    if (feeToken != address(0) && requestFee > 0) {
      IERC20(feeToken).safeApprove(address(rng), requestFee);
    }

    (uint32 requestId, uint32 lockBlock) = rng.requestRandomNumber();
    rngRequest.id = requestId;
    rngRequest.lockBlock = lockBlock;
    rngRequest.requestedAt = _currentTime();

    emit DrawStarted(msg.sender, requestId, lockBlock);
  }

  /// @inheritdoc IDrawBeacon
  function setBeaconPeriodSeconds(uint32 _beaconPeriodSeconds) external override onlyOwner requireDrawNotInProgress {
    _setBeaconPeriodSeconds (_beaconPeriodSeconds);
  }

   /// @inheritdoc IDrawBeacon
  function setRngTimeout(uint32 _rngTimeout) external override onlyOwner requireDrawNotInProgress {
    _setRngTimeout(_rngTimeout);
  }

  /// @inheritdoc IDrawBeacon
  function setRngService(RNGInterface rngService) external override onlyOwner requireDrawNotInProgress {
    require(!isRngRequested(), "DrawBeacon/rng-in-flight");
    rng = rngService;
    emit RngServiceUpdated(rngService);
  }

  /* ============ Internal Functions ============ */

  /**
    * @notice Calculates when the next beacon period will start
    * @param _beaconPeriodStartedAt The timestamp at which the beacon period started
    * @param _beaconPeriodSeconds The duration of the beacon period in seconds
    * @param _time The timestamp to use as the current time
    * @return The timestamp at which the next beacon period would start
   */
  function _calculateNextBeaconPeriodStartTime(
    uint64 _beaconPeriodStartedAt,
    uint32 _beaconPeriodSeconds,
    uint64 _time
  ) internal pure returns (uint64) {
    uint64 elapsedPeriods = (_time - _beaconPeriodStartedAt) / _beaconPeriodSeconds;
    return _beaconPeriodStartedAt + (elapsedPeriods * _beaconPeriodSeconds);
  }

  /**
    * @notice returns the current time.  Used for testing.
    * @return The current time (block.timestamp)
   */
  function _currentTime() internal virtual view returns (uint64) {
    return uint64(block.timestamp);
  }

  /**
    * @notice Returns the timestamp at which the beacon period ends
    * @return The timestamp at which the beacon period ends
   */
  function _beaconPeriodEndAt() internal view returns (uint64) {
    return beaconPeriodStartedAt + beaconPeriodSeconds;
  }

  /**
    * @notice Returns the number of seconds remaining until the prize can be awarded.
    * @return The number of seconds remaining until the prize can be awarded.
   */
  function _beaconPeriodRemainingSeconds() internal view returns (uint32) {
    uint64 endAt = _beaconPeriodEndAt();
    uint64 time = _currentTime();
    if (endAt <= time) {
      return 0;
    }
    return uint256(endAt - time).toUint32();
  }

  /**
    * @notice Returns whether the beacon period is over.
    * @return True if the beacon period is over, false otherwise
   */
  function _isBeaconPeriodOver() internal view returns (bool) {
    uint64 time = _currentTime();
    return _beaconPeriodEndAt() <= time;
  }

  /**
    * @notice Check to see award is in progress.
   */
  function _requireDrawNotInProgress() internal view {
    uint256 currentBlock = block.number;
    require(rngRequest.lockBlock == 0 || currentBlock < rngRequest.lockBlock, "DrawBeacon/rng-in-flight");
  }

  /**
    * @notice Set global DrawHistory variable.
    * @dev    All subsequent Draw requests/completions will be pushed to the new DrawHistory.
    * @param _newDrawHistory  DrawHistory address
    * @return DrawHistory
  */
  function _setDrawHistory(IDrawHistory _newDrawHistory) internal returns (IDrawHistory) {
    IDrawHistory _previousDrawHistory = drawHistory;
    require(address(_newDrawHistory) != address(0), "DrawBeacon/draw-history-not-zero-address");
    require(address(_newDrawHistory) != address(_previousDrawHistory), "DrawBeacon/existing-draw-history-address");
    drawHistory = _newDrawHistory;
    emit DrawHistoryTransferred(_newDrawHistory);
    return _newDrawHistory;
  }

  /**
    * @notice Sets the beacon period in seconds.
    * @param _beaconPeriodSeconds The new beacon period in seconds.  Must be greater than zero.
   */
  function _setBeaconPeriodSeconds(uint32 _beaconPeriodSeconds) internal {
    require(_beaconPeriodSeconds > 0, "DrawBeacon/beacon-period-greater-than-zero");
    beaconPeriodSeconds = _beaconPeriodSeconds;

    emit BeaconPeriodSecondsUpdated(_beaconPeriodSeconds);
  }

  /**
    * @notice Sets the RNG request timeout in seconds.  This is the time that must elapsed before the RNG request can be cancelled and the pool unlocked.
    * @param _rngTimeout The RNG request timeout in seconds.
   */
  function _setRngTimeout(uint32 _rngTimeout) internal {
    require(_rngTimeout > 60, "DrawBeacon/rng-timeout-gt-60-secs");
    rngTimeout = _rngTimeout;
    emit RngTimeoutSet(_rngTimeout);
  }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/pooltogether-rng-contracts/contracts/RNGInterface.sol";
import "./IDrawHistory.sol";
import "../libraries/DrawLib.sol";

interface IDrawBeacon {

  /**
    * @notice Emit when a new DrawHistory has been set.
    * @param newDrawHistory       The new DrawHistory address
  */
  event DrawHistoryTransferred(IDrawHistory indexed newDrawHistory);

  /**
    * @notice Emit when a draw has opened.
    * @param operator             User address responsible for opening draw
    * @param startedAt Start timestamp
  */
  event BeaconPeriodStarted(
    address indexed operator,
    uint64 indexed startedAt
  );

  /**
    * @notice Emit when a draw has started.
    * @param operator      User address responsible for starting draw
    * @param rngRequestId  draw id
    * @param rngLockBlock  Block when draw becomes invalid
  */
  event DrawStarted(
    address indexed operator,
    uint32 indexed rngRequestId,
    uint32 rngLockBlock
  );

  /**
    * @notice Emit when a draw has been cancelled.
    * @param operator      User address responsible for cancelling draw
    * @param rngRequestId  draw id
    * @param rngLockBlock  Block when draw becomes invalid
  */
  event DrawCancelled(
    address indexed operator,
    uint32 indexed rngRequestId,
    uint32 rngLockBlock
  );

  /**
    * @notice Emit when a draw has been completed.
    * @param operator      User address responsible for completing draw
    * @param randomNumber  Random number generated from draw
  */
  event DrawCompleted(
    address indexed operator,
    uint256 randomNumber
  );

  /**
    * @notice Emit when a RNG service address is set.
    * @param rngService  RNG service address
  */
  event RngServiceUpdated(
    RNGInterface indexed rngService
  );

  /**
    * @notice Emit when a draw timeout param is set.
    * @param rngTimeout  draw timeout param in seconds
  */
  event RngTimeoutSet(
    uint32 rngTimeout
  );

  /**
    * @notice Emit when the drawPeriodSeconds is set.
    * @param drawPeriodSeconds Time between draw
  */
  event BeaconPeriodSecondsUpdated(
    uint32 drawPeriodSeconds
  );

  /**
    * @notice Returns the number of seconds remaining until the beacon period can be complete.
    * @return The number of seconds remaining until the beacon period can be complete.
   */
  function beaconPeriodRemainingSeconds() external view returns (uint32);

  /**
    * @notice Returns the timestamp at which the beacon period ends
    * @return The timestamp at which the beacon period ends.
   */
  function beaconPeriodEndAt() external view returns (uint64);


  /**
    * @notice Returns whether an Draw request can be started.
    * @return True if a Draw can be started, false otherwise.
   */
  function canStartDraw() external view returns (bool);
  
  /**
    * @notice Returns whether an Draw request can be completed.
    * @return True if a Draw can be completed, false otherwise.
   */
  function canCompleteDraw() external view returns (bool);
  
  /**
    * @notice Calculates when the next beacon period will start.
    * @param currentTime The timestamp to use as the current time
    * @return The timestamp at which the next beacon period would start
   */
  function calculateNextBeaconPeriodStartTime(uint256 currentTime) external view returns (uint64);
  
  /**
    * @notice Can be called by anyone to cancel the draw request if the RNG has timed out.
   */
  function cancelDraw() external;

  /**
    * @notice Completes the Draw (RNG) request and pushes a Draw onto DrawHistory.
   */
  function completeDraw() external;
  
  /**
    * @notice Returns the block number that the current RNG request has been locked to.
    * @return The block number that the RNG request is locked to
   */
  function getLastRngLockBlock() external view returns (uint32);
  /**
    * @notice Returns the current RNG Request ID.
    * @return The current Request ID
   */
  function getLastRngRequestId() external view returns (uint32);
  /**
    * @notice Returns whether the beacon period is over
    * @return True if the beacon period is over, false otherwise
   */
  function isBeaconPeriodOver() external view returns (bool);

  /**
    * @notice Returns whether the random number request has completed.
    * @return True if a random number request has completed, false otherwise.
   */
  function isRngCompleted() external view returns (bool);

  /**
    * @notice Returns whether a random number has been requested
    * @return True if a random number has been requested, false otherwise.
   */
  function isRngRequested() external view returns (bool);

  /**
    * @notice Returns whether the random number request has timed out.
    * @return True if a random number request has timed out, false otherwise.
   */
  function isRngTimedOut() external view returns (bool);
  /**
    * @notice Allows the owner to set the beacon period in seconds.
    * @param beaconPeriodSeconds The new beacon period in seconds.  Must be greater than zero.
   */
  function setBeaconPeriodSeconds(uint32 beaconPeriodSeconds) external;
  /**
    * @notice Allows the owner to set the RNG request timeout in seconds. This is the time that must elapsed before the RNG request can be cancelled and the pool unlocked.
    * @param _rngTimeout The RNG request timeout in seconds.
   */
  function setRngTimeout(uint32 _rngTimeout) external;
  /**
    * @notice Sets the RNG service that the Prize Strategy is connected to
    * @param rngService The address of the new RNG service interface
   */
  function setRngService(RNGInterface rngService) external;
  /**
    * @notice Starts the Draw process by starting random number request. The previous beacon period must have ended.
    * @dev The RNG-Request-Fee is expected to be held within this contract before calling this function
   */
  function startDraw() external;
  /**
    * @notice Set global DrawHistory variable.
    * @dev    All subsequent Draw requests/completions will be pushed to the new DrawHistory.
    * @param newDrawHistory DrawHistory address
    * @return DrawHistory
  */
  function setDrawHistory(IDrawHistory newDrawHistory) external returns (IDrawHistory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "../libraries/DrawLib.sol";

interface IDrawHistory {

  /**
    * @notice Emit when a new draw has been created.
    * @param drawId Draw id
    * @param draw The Draw struct
  */
  event DrawSet (
    uint32 indexed drawId,
    DrawLib.Draw draw
  );

  /**
    * @notice Read a Draw from the draws ring buffer.
    * @dev    Read a Draw using the Draw.drawId to calculate position in the draws ring buffer.
    * @param drawId Draw.drawId
    * @return DrawLib.Draw
  */
  function getDraw(uint32 drawId) external view returns (DrawLib.Draw memory);

  /**
    * @notice Read multiple Draws from the draws ring buffer.
    * @dev    Read multiple Draws using each Draw.drawId to calculate position in the draws ring buffer.
    * @param drawIds Array of Draw.drawIds
    * @return DrawLib.Draw[]
  */
  function getDraws(uint32[] calldata drawIds) external view returns (DrawLib.Draw[] memory);
  /**
    * @notice Read newest Draw from the draws ring buffer.
    * @dev    Uses the nextDrawIndex to calculate the most recently added Draw.
    * @return DrawLib.Draw
  */
  function getNewestDraw() external view returns (DrawLib.Draw memory);
  /**
    * @notice Read oldest Draw from the draws ring buffer.
    * @dev    Finds the oldest Draw by comparing and/or diffing totalDraws with the cardinality.
    * @return DrawLib.Draw
  */
  function getOldestDraw() external view returns (DrawLib.Draw memory);

  /**
    * @notice Push Draw onto draws ring buffer history.
    * @dev    Push new draw onto draws history via authorized manager or owner.
    * @param draw DrawLib.Draw
    * @return Draw.drawId
  */
  function pushDraw(DrawLib.Draw calldata draw) external returns(uint32);

  /**
    * @notice Set existing Draw in draws ring buffer with new parameters.
    * @dev    Updating a Draw should be used sparingly and only in the event an incorrect Draw parameter has been stored.
    * @param newDraw DrawLib.Draw
    * @return Draw.drawId
  */
  function setDraw(DrawLib.Draw calldata newDraw) external returns(uint32);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

library DrawLib {

    struct Draw {
        uint256 winningRandomNumber;
        uint32 drawId;
        uint64 timestamp;
        uint64 beaconPeriodStartedAt;
        uint32 beaconPeriodSeconds;
    }

    uint8 public constant DISTRIBUTIONS_LENGTH = 16;

    ///@notice Draw settings for the tsunami draw calculator
    ///@param bitRangeSize Decimal representation of bitRangeSize
    ///@param matchCardinality The bitRangeSize's to consider in the 256 random numbers. Must be > 1 and < 256/bitRangeSize
    ///@param startTimestampOffset The starting time offset in seconds from which Ticket balances are calculated.
    ///@param endTimestampOffset The end time offset in seconds from which Ticket balances are calculated.
    ///@param maxPicksPerUser Maximum number of picks a user can make in this Draw
    ///@param numberOfPicks Number of picks this Draw has (may vary network to network)
    ///@param distributions Array of prize distributions percentages, expressed in fraction form with base 1e18. Max sum of these <= 1 Ether. ordering: index0: grandPrize, index1: runnerUp, etc.
    ///@param prize Total prize amount available in this draw calculator for this Draw (may vary from network to network)
    struct PrizeDistribution {
        uint8 bitRangeSize;
        uint8 matchCardinality;
        uint32 startTimestampOffset;
        uint32 endTimestampOffset;
        uint32 maxPicksPerUser;
        uint136 numberOfPicks;
        uint32[DISTRIBUTIONS_LENGTH] distributions;
        uint256 prize;
    }

}

