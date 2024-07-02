/**
 *Submitted for verification at cronoscan.com on 2022-05-31
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}



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


/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}




library SingleSafeMath {
  using SafeMath for uint;

  /// @dev Computes round-up division.
  function ceilDiv(uint a, uint b) internal pure returns (uint) {
    return a.add(b).sub(1).div(b);
  }
}

library SingleMath {
  // implementation from https://github.com/Uniswap/uniswap-lib/commit/99f3f28770640ba1bb1ff460ac7c5292fb8291a0
  // original implementation: https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
  function sqrt(uint x) internal pure returns (uint) {
    if (x == 0) return 0;
    uint xx = x;
    uint r = 1;

    if (xx >= 0x100000000000000000000000000000000) {
      xx >>= 128;
      r <<= 64;
    }

    if (xx >= 0x10000000000000000) {
      xx >>= 64;
      r <<= 32;
    }
    if (xx >= 0x100000000) {
      xx >>= 32;
      r <<= 16;
    }
    if (xx >= 0x10000) {
      xx >>= 16;
      r <<= 8;
    }
    if (xx >= 0x100) {
      xx >>= 8;
      r <<= 4;
    }
    if (xx >= 0x10) {
      xx >>= 4;
      r <<= 2;
    }
    if (xx >= 0x8) {
      r <<= 1;
    }

    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1; // Seven iterations should be enough
    uint r1 = x / r;
    return (r < r1 ? r : r1);
  }
}


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



interface ILocker {
    function lock(address _user, uint256 _amount, uint256 pid) external;
    function pendingTokens(uint256 pid, address user) external returns (uint256);
    function release(uint256 pid, address user) external;
}



/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


/**
       _____ _             __     _______                           
      / ___/(_)___  ____ _/ /__  / ____(_)___  ____ _____  ________ 
      \__ \/ / __ \/ __ `/ / _ \/ /_  / / __ \/ __ `/ __ \/ ___/ _ \
     ___/ / / / / / /_/ / /  __/ __/ / / / / / /_/ / / / / /__/  __/
    /____/_/_/ /_/\__, /_/\___/_/   /_/_/ /_/\__,_/_/ /_/\___/\___/ 
                 /____/                                             
*/


/**
 * Single Finance token with Governance.
 */
contract SingleToken is ERC20("SINGLE Token", "SINGLE"), Ownable {
  using SafeMath for uint256;

  uint256 private constant CAP = 1000_000_000e18;

  uint256 public constant INVESTOR_MINT_CAP = 137_000_000e18;
  uint256 public constant LIQUIDITY_MINT_CAP = 20_000_000e18;

  uint256 public startMiningTimestamp;
  // uint256 public startReleaseTimestamp;
  uint256 public launchPeriodEndTimestamp;
  uint256 public nextAdjustTimestamp;

  uint256 public INITIAL_SUPPLY_PER_BLOCK;
  uint256 public SUPPLY_PER_BLOCK;
  uint256 public constant LAUNCH_PERIOD_ADJUST_WINDOW = 365 days / 12;
  uint256 public constant SUPPLY_HALVING_WINDOW = 365 days / 2;

  uint256 public constant ECOSYSTEM_TGE_RELEASE = 11_150_000e18;
  uint256 public constant ECOSYSTEM_VESTING_AMT = 211_850_000e18;
  uint256 public constant ECOSYSTEM_VESTING_PERIOD = 365 days *2; // 24 months

  uint256 public constant TEAM_TGE_RELEASE = 2_200_000e18;
  uint256 public constant TEAM_VESTING_AMT = 217_800_000e18;
  uint256 public constant TEAM_VESTING_PERIOD = 365 days *2; // 24 months

  uint256 public investorMinted = 0;
  uint256 public liquidityMinted = 0;
  uint256 public teamMinted = 0;
  uint256 public ecosystemMinted = 0;

  
  event SupplyAdjusted(uint256 supplyPerBlock, uint256 nextAdjustTs);


  constructor(
    uint256 initialSupplyPerBlock,
    uint256 _startMiningTimestamp
  ) {

    if(_startMiningTimestamp == 0){
      _startMiningTimestamp = block.timestamp;
    }

    require(block.timestamp <= _startMiningTimestamp, "cannot set past block number");

    startMiningTimestamp = _startMiningTimestamp;
    
    launchPeriodEndTimestamp = startMiningTimestamp.add(SUPPLY_HALVING_WINDOW);

    // available for first adjustment after mining started
    nextAdjustTimestamp = startMiningTimestamp;

    INITIAL_SUPPLY_PER_BLOCK = initialSupplyPerBlock;
    SUPPLY_PER_BLOCK = 0;

  }

  function cap() public pure returns (uint256) {
    return CAP;
  }



  
  function mint(address _to, uint256 _amount) public onlyOwner {
    require(totalSupply().add(_amount) <= cap(), "cap exceeded");
    _mint(_to, _amount);
    _moveDelegates(address(0), _delegates[_to], _amount);
  }

  function mintForLiquidity(address _to, uint256 _amount) public onlyOwner {
    require(liquidityMinted.add(_amount) <= LIQUIDITY_MINT_CAP, "mint limit exceeded");
    liquidityMinted = liquidityMinted.add(_amount);
    mint(_to, _amount);
  }

  function mintForInvestor(address _to, uint256 _amount) public onlyOwner {
    require(investorMinted.add(_amount) <= INVESTOR_MINT_CAP, "mint limit exceeded");
    investorMinted = investorMinted.add(_amount);
    mint(_to, _amount);
  }


  function mintForEcosystem(address _to, uint256 _amount) public onlyOwner {
    require(ecosystemMinted.add(_amount) <= ECOSYSTEM_VESTING_AMT.add(ECOSYSTEM_TGE_RELEASE), "mint limit exceeded");
    require(_amount <= pendingEcosystemTokens(), "available limit exceeded");
    ecosystemMinted = ecosystemMinted.add(_amount);
    mint(_to, _amount);
  }

  function mintForTeam(address _to, uint256 _amount) public onlyOwner {
    require(teamMinted.add(_amount) <= TEAM_VESTING_AMT.add(TEAM_TGE_RELEASE), "mint limit exceeded");
    require(_amount <= pendingTeamTokens(), "available limit exceeded");
    teamMinted = teamMinted.add(_amount);
    mint(_to, _amount);
  }


  function burn(address _account, uint256 _amount) external onlyOwner {
    _burn(_account, _amount);
    _moveDelegates(_delegates[_account], address(0), _amount);
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(recipient != address(this), "ERC20: transfer to the token contract");

    _transfer(_msgSender(), recipient, amount);
    _moveDelegates(_delegates[_msgSender()], _delegates[recipient], amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(recipient != address(this), "ERC20: transfer to the token contract");

    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
    _moveDelegates(_delegates[sender], _delegates[recipient], amount);
    return true;
  }


  function pendingEcosystemTokens() public view returns (uint256)
  {
    if(block.timestamp < startMiningTimestamp){
      return 0;
    }

    uint256 singlePerSec = ECOSYSTEM_VESTING_AMT.div(ECOSYSTEM_VESTING_PERIOD);

    uint256 timePast = uint256(block.timestamp).sub(startMiningTimestamp);

    if(timePast >= ECOSYSTEM_VESTING_PERIOD){
      return ECOSYSTEM_VESTING_AMT.add(ECOSYSTEM_TGE_RELEASE).sub(ecosystemMinted);
    }

    return timePast.mul(singlePerSec).add(ECOSYSTEM_TGE_RELEASE).sub(ecosystemMinted);
  }


  function pendingTeamTokens() public view returns (uint256)
  {
    if(block.timestamp < startMiningTimestamp){
      return 0;
    }

    uint256 singlePerSec = TEAM_VESTING_AMT.div(TEAM_VESTING_PERIOD);

    uint256 timePast = uint256(block.timestamp).sub(startMiningTimestamp);

    if(timePast >= TEAM_VESTING_PERIOD){
      return TEAM_VESTING_AMT.add(TEAM_TGE_RELEASE).sub(teamMinted);
    }

    return timePast.mul(singlePerSec).add(TEAM_TGE_RELEASE).sub(teamMinted);
  }


  /**
   * Perform adjust on token supply once invoked
   */
  function supplyAdjust() public onlyOwner
  {

    require(block.timestamp >= nextAdjustTimestamp, "SingleToken: not yet");


    if(block.timestamp < launchPeriodEndTimestamp)
    {
      launchPeriodSupplyAdjust();
    }else
    {

      // first halving
      if( (block.timestamp - launchPeriodEndTimestamp) < SUPPLY_HALVING_WINDOW ){
        SUPPLY_PER_BLOCK = INITIAL_SUPPLY_PER_BLOCK.div(2);
      }else{
        // halving
        SUPPLY_PER_BLOCK = SUPPLY_PER_BLOCK.div(2);
      }

      nextAdjustTimestamp = nextAdjustTimestamp.add(SUPPLY_HALVING_WINDOW);

      emit SupplyAdjusted(SUPPLY_PER_BLOCK, nextAdjustTimestamp);

    }

  }


  function launchPeriodSupplyAdjust() internal{

    uint256 N = 6 - (launchPeriodEndTimestamp - block.timestamp).mul(100).div(LAUNCH_PERIOD_ADJUST_WINDOW).div(100);

    // multiplier = ( 32 + p(3.5-N) ) / 32
    // p = 5
    uint256 multiplier = uint256(3200).add(1750).sub(N.mul(500)).mul(1e12).div(3200);

    SUPPLY_PER_BLOCK = INITIAL_SUPPLY_PER_BLOCK.mul(multiplier).div(1e12);

    // advance the next adjust time
    nextAdjustTimestamp = nextAdjustTimestamp.add(LAUNCH_PERIOD_ADJUST_WINDOW);

    emit SupplyAdjusted(SUPPLY_PER_BLOCK, nextAdjustTimestamp);

  }



  // Copied and modified from YAM code:
  // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
  // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
  // Which is copied and modified from COMPOUND:
  // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

  /// @notice A record of each accounts delegate
  mapping (address => address) internal _delegates;

  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }

  /// @notice A record of votes checkpoints for each account, by index
  mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

  /// @notice The number of checkpoints for each account
  mapping (address => uint32) public numCheckpoints;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /// @notice The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  /// @notice A record of states for signing / validating signatures
  mapping (address => uint) public nonces;

  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

  /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegator The address to get delegatee for
    */
  function delegates(address delegator)
      external
      view
      returns (address)
  {
      return _delegates[delegator];
  }

  /**
  * @notice Delegate votes from `msg.sender` to `delegatee`
  * @param delegatee The address to delegate votes to
  */
  function delegate(address delegatee) external {
    return _delegate(msg.sender, delegatee);
  }

  /**
    * @notice Delegates votes from signatory to `delegatee`
    * @param delegatee The address to delegate votes to
    * @param nonce The contract state required to match the signature
    * @param expiry The time at which to expire the signature
    * @param v The recovery byte of the signature
    * @param r Half of the ECDSA signature pair
    * @param s Half of the ECDSA signature pair
    */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
      external
  {
      bytes32 domainSeparator = keccak256(
          abi.encode(
              DOMAIN_TYPEHASH,
              keccak256(bytes(name())),
              // getChainId(),
              block.chainid,
              address(this)
          )
      );

      bytes32 structHash = keccak256(
          abi.encode(
              DELEGATION_TYPEHASH,
              delegatee,
              nonce,
              expiry
          )
      );

      bytes32 digest = keccak256(
          abi.encodePacked(
              "\x19\x01",
              domainSeparator,
              structHash
          )
      );

      address signatory = ecrecover(digest, v, r, s);
      require(signatory != address(0), "SINGLE::delegateBySig: invalid signature");
      require(nonce == nonces[signatory]++, "SINGLE::delegateBySig: invalid nonce");
      require(block.timestamp <= expiry, "SINGLE::delegateBySig: signature expired");
      return _delegate(signatory, delegatee);
  }

  /**
    * @notice Gets the current votes balance for `account`
    * @param account The address to get votes balance
    * @return The number of current votes for `account`
    */
  function getCurrentVotes(address account)
      external
      view
      returns (uint256)
  {
      uint32 nCheckpoints = numCheckpoints[account];
      return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  /**
    * @notice Determine the prior number of votes for an account as of a block number
    * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
    * @param account The address of the account to check
    * @param blockNumber The block number to get the vote balance at
    * @return The number of votes the account had as of the given block
    */
  function getPriorVotes(address account, uint blockNumber)
      external
      view
      returns (uint256)
  {
    require(blockNumber < block.number, "SINGLE::getPriorVotes: not yet determined");

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
        return 0;
    }

    // First check most recent balance
    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
        return checkpoints[account][nCheckpoints - 1].votes;
    }

    // Next check implicit zero balance
    if (checkpoints[account][0].fromBlock > blockNumber) {
        return 0;
    }

    uint32 lower = 0;
    uint32 upper = nCheckpoints - 1;
    while (upper > lower) {
        uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
        Checkpoint memory cp = checkpoints[account][center];
        if (cp.fromBlock == blockNumber) {
            return cp.votes;
        } else if (cp.fromBlock < blockNumber) {
            lower = center;
        } else {
            upper = center - 1;
        }
    }
    return checkpoints[account][lower].votes;
  }

  function _delegate(address delegator, address delegatee)
      internal
  {
    address currentDelegate = _delegates[delegator];
    uint256 delegatorBalance = balanceOf(delegator); // balance of underlying YAMs (not scaled);
    _delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        // decrease old representative
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint256 srcRepNew = srcRepOld.sub(amount);
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        // increase new representative
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint256 dstRepNew = dstRepOld.add(amount);
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint256 oldVotes,
    uint256 newVotes
  ) internal
  {
    uint32 blockNumber = safe32(block.number, "SINGLE::_writeCheckpoint: block number exceeds 32 bits");

    if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
        checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
        checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
        numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }


}



contract IBigBang {

  struct UserInfo {
    uint256 amount; // How many Staking tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    address fundedBy; // Funded by who?
  }

  struct PoolInfo {
    uint256 allocPoint; // How many allocation points assigned to this pool. SINGLEs to distribute per block.
    uint256 lastRewardBlock; // Last block number that SINGLEs distribution occurs.
    uint256 accRewardPerShare; // Accumulated SINGLEs per share, times 1e12. See below.
  }

  mapping (uint256 => mapping (address => UserInfo)) public userInfo;

  PoolInfo[] public poolInfo;
  IERC20Upgradeable[] public stakeTokens;
  SingleToken public single;
  IERC20 public SINGLE;
  function poolLength() external view returns (uint256) {}
  function totalAllocPoint() external view returns (uint256) {}
  function singlePerBlock() external view returns (uint256) {}
  function bonusSinglePerBlock() external view returns (uint256) {}
  function bonusEndBlock() external view returns (uint256) {}
  function bonusStartBlock() external view returns (uint256) {}
  
  // function addPool(
  //   uint256 _allocPoint,
  //   address _stakeToken,
  //   bool _withUpdate
  // ) external;

  function addPool(
      uint256 allocPoint, 
      IERC20Upgradeable _stakeToken, 
      ILocker _locker, 
      uint256 _startBlock
  ) external {}

  // function setPool(
  //   uint256 _pid,
  //   uint256 _allocPoint,
  //   bool _withUpdate
  // ) external;

  function setPool(
      uint256 _pid, 
      uint256 _allocPoint, 
      ILocker _locker, 
      bool overwrite
  ) external {}

  function pendingSingle(uint256 _pid, address _user) external view returns (uint256) {}

  // function updatePool(uint256 _pid) external;
  function updatePool(uint256 pid) external returns (PoolInfo memory) {}

  function deposit(address _for, uint256 _pid, uint256 _amount) external {}

  function withdraw(address _for, uint256 _pid, uint256 _amount) external {}

  // function withdrawAll(address _for, uint256 _pid) external;

  function harvest(uint256 _pid) external {}
}



/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
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



contract Governable is Initializable {
  event SetGovernor(address governor);
  event SetPendingGovernor(address pendingGovernor);
  event AcceptGovernor(address governor);

  address public governor; // The current governor.
  address public pendingGovernor; // The address pending to become the governor once accepted.

  bytes32[64] _gap; // reserve space for upgrade

  modifier onlyGov() {
    require(msg.sender == governor, 'not the governor');
    _;
  }

  /// @dev Initialize using msg.sender as the first governor.
  function __Governable__init() internal initializer {
    governor = msg.sender;
    pendingGovernor = address(0);
    emit SetGovernor(msg.sender);
  }

  /// @dev Set the pending governor, which will be the governor once accepted.
  /// @param _pendingGovernor The address to become the pending governor.
  function setPendingGovernor(address _pendingGovernor) external onlyGov {
    pendingGovernor = _pendingGovernor;
    emit SetPendingGovernor(_pendingGovernor);
  }

  /// @dev Accept to become the new governor. Must be called by the pending governor.
  function acceptGovernor() external {
    require(msg.sender == pendingGovernor, 'not the pending governor');
    pendingGovernor = address(0);
    governor = msg.sender;
    emit AcceptGovernor(msg.sender);
  }
}



/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}



contract ERC1155NaiveReceiver is IERC1155Receiver {
  bytes32[64] __gap; // reserve space for upgrade

  function onERC1155Received(
    address, /* operator */
    address, /* from */
    uint256, /* id */
    uint256, /* value */
    bytes calldata /* data */
  ) external override pure returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address, /* operator */
    address, /* from */
    uint256[] calldata, /* ids */
    uint256[] calldata, /* values */
    bytes calldata /* data */
  ) external override pure returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function supportsInterface(bytes4 interfaceId) external override view returns (bool) {}
}



interface IVaultConfig {
  /// @dev Return minimum BaseToken debt size per position.
  function minDebtSize() external view returns (uint256);

  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256);

  /// @dev Return the address of wrapped native token.
  function getWrappedNativeAddr() external view returns (address);

  /// @dev Return the address of wNative relayer.
  function getWNativeRelayer() external view returns (address);

  /// @dev Return the address of fair launch contract.
  function getBigBangAddr() external view returns (address);

   /// @dev Return the bps rate for reserve pool.
  function getReservePoolBps() external view returns (uint256);

  // /// @dev Return the bps rate for Avada Kill caster.
  // function getKillBps() external view returns (uint256);

  /// @dev Return if the caller is whitelisted.
  function whitelistedCallers(address caller) external returns (bool);

  /// @dev Return if the caller is whitelisted.
  // function whitelistedLiquidators(address caller) external returns (bool);

  // /// @dev Return if the given strategy is approved.
  // function approvedAddStrategies(address addStrats) external returns (bool);

  // /// @dev Return whether the given address is a worker.
  // function isWorker(address worker) external view returns (bool);

  // /// @dev Return whether the given worker accepts more debt. Revert on non-worker.
  // function acceptDebt(address worker) external view returns (bool);

  // /// @dev Return the work factor for the worker + BaseToken debt, using 1e4 as denom. Revert on non-worker.
  // function workFactor(address worker, uint256 debt) external view returns (uint256);

  // /// @dev Return the kill factor for the worker + BaseToken debt, using 1e4 as denom. Revert on non-worker.
  // function killFactor(address worker, uint256 debt) external view returns (uint256);

  // /// @dev Return the kill factor for the worker + BaseToken debt without checking isStable, using 1e4 as denom. Revert on non-worker.
  // function rawKillFactor(address worker, uint256 debt) external view returns (uint256);

  // /// @dev Return the portion of reward that will be transferred to treasury account after successfully killing a position.
  // function getKillTreasuryBps() external view returns (uint256);

  /// @dev Return the address of treasury account
  function getTreasuryAddr() external view returns (address);

  // /// @dev Return if worker is stable
  // function isWorkerStable(address worker) external view returns (bool);

  /// @dev Return if reserve that worker is working with is consistent
  // function isWorkerReserveConsistent(address worker) external view returns (bool);

}



interface IVault {

  /// @dev Return the total ERC20 entitled to the token holders. Be careful of unaccrued interests.
  function totalToken() external view returns (uint256);

  /// @dev Add more ERC20 to the bank. Hope to get some good returns.
  function deposit(uint256 amountToken) external payable;

  /// @dev Withdraw ERC20 from the bank by burning the share tokens.
  function withdraw(uint256 share) external;

  function token() external view returns (address);

  function debtToken() external view returns (address);

  function config() external view returns (IVaultConfig);
  function debtShareToVal(uint256 debtShare) external view returns (uint256);
  function debtValToShare(uint256 debtVal) external view returns (uint256);
  function borrow(uint256 debtVal) external returns (uint256);
  function repay(uint256 debtVal) external returns (uint256 debtShare);
  function currentDebtVal() external returns (uint256);
  function vaultDebtShare() external returns (uint256);
  function pendingInterest(uint256 value) external view returns (uint256);

}



interface IPositionMonitor {
  function finalEquities(uint256 id) external view returns (uint256, uint256);
  function positions(uint256 id) external view returns (uint256 value, address token0, address token1, uint16 stopLossRatio);
  // function addPosition  ( uint256 id, address[2] calldata tokens, uint256[2] calldata amounts ) external ;
  function adjustStopLossRatio ( uint256 id, uint16 _stopLossRatio) external;
  
  function closePosition (
      uint256 id,
      address[2] calldata tokens,
      uint256[2] calldata tokensBack
    ) external ;
  function adjustPosition (uint256 id, uint256 token0Amt, uint256 token1Amt,address token0, address token1) external ;
  function adjustFinalEquity ( uint256 id, address[2] calldata tokens, uint256[2] calldata tokensBack) external ;
  function hasReachedStopLossRatio (uint256 id, uint256 token0Amount, uint256 token1Amount, address token0, address token1) external view returns (bool);
  
  function hasReachedStopLossRatioDexYield (uint256 id, uint256[] memory amounts, address[] memory tokens, uint256 pendingReward, address rewardToken) external view returns (bool);
  function recordHarvest (uint256 id, uint256 reward, address rewardToken) external;
  
  // function getFinalEquityValue(uint256 id) external view returns (uint256);
  function getStopLossAmt(address token) external returns (uint256) ;
}



interface IBank {
  /// The governor adds a new bank gets added to the system.
  event AddBank(address token, address cToken);
  /// The governor removes a new bank removed added to the system.
  event RemoveBank(address token, address cToken);
  event SetFeeBps(uint16 stopLossBps, uint16 killBps);
  event SetPositionMonitor (IPositionMonitor positionMonitor);
  /// The governor withdraw tokens from the reserve of a bank.
  event WithdrawReserve(address indexed user, address token, uint amount);
  event SendToArk (uint256 indexed POSITION_ID, address caller, address token, uint amount);
  /// Someone borrows tokens from a bank via a spell caller.
  event Borrow(uint indexed positionId, address caller, address token, uint amount, uint share);
  /// Someone repays tokens to a bank via a spell caller.
  event Repay(uint indexed positionId, address caller, address token, uint amount, uint share);
  /// Someone puts tokens as collateral via a spell caller.
  event PutCollateral(uint indexed positionId, address caller, address token, uint id, uint amount);
  /// Someone takes tokens from collateral via a spell caller.
  event TakeCollateral(uint indexed positionId, address caller, address token, uint id, uint amount);
  /// Someone calls liquidatation on a position, paying debt and taking collateral tokens.
  event Liquidate(
    uint indexed positionId,
    uint collateralSize,
    address collToken,
    uint collId
  );

  event StopLoss(
    uint indexed positionId,
    uint collateralSize,
    address collToken,
    uint collId
  );

  event LongShortPosition(uint indexed positionId);

  /// @dev Return the current position while under execution.
  function POSITION_ID() external view returns (uint);

  /// @dev Return the current target while under execution.
  function WORKER() external view returns (address);

  /// @dev Return the current executor (the owner of the current position).
  function EXECUTOR() external view returns (address);
  function RECEIVER() external view returns (address);
  function stopLossBps() external view returns (uint);
  function killBps() external view returns (uint);
  /// @dev Return bank information for the given token.
  function getBankInfo(address token)
    external
    view
    returns (
      bool isListed,
      address cToken,
      // uint reserve,
      uint totalDebt,
      uint totalShare
    );

  /// @dev Return position information for the given position id.
  function getPositionInfo(uint positionId)
    external
    view
    returns (
      address owner,
      address collToken,
      uint collId,
      uint collateralSize
    );
  /// @dev Return position debts for the given position id.
  function getPositionDebts(uint positionId)
    external view 
    returns (address[] memory tokens, uint[] memory debts);
  
  function getCurrentPositionDebts()
    external view
    returns (address[] memory tokens, uint[] memory debts);

  /// @dev Return the borrow balance for given positon and token without trigger interest accrual.
  function borrowBalanceStored(uint positionId, address token) external view returns (uint);

  /// @dev Trigger interest accrual and return the current borrow balance.
  function borrowBalanceCurrent(uint positionId, address token) external returns (uint);


  function executeByStrategy(
    uint positionId,
    address worker,
    address user,
    bytes[] memory data
  ) external payable returns (uint);

  /// @dev Borrow tokens from the bank.
  function borrow(address token, uint amount) external;

  /// @dev Repays tokens to the bank.
  function repay(address token, uint amountCall) external;

  /// @dev Transmit user assets to the spell.
  function transmit(address token, uint amount) external;

  /// @dev Put more collateral for users.
  function putCollateral(
    address collToken,
    uint collId,
    uint amountCall
  ) external;

  /// @dev Take some collateral back.
  function takeCollateral(
    address collToken,
    uint collId,
    uint amount
  ) external;

  /// @dev Liquidate a position.
  function liquidate( uint positionID) external;

  /// @dev StopLoss a position.
  function stopLoss( uint positionID) external;

  
  function nextPositionId() external view returns (uint);

  /// @dev Return current position information.
  function getCurrentPositionInfo()
    external
    view
    returns (
      address owner,
      address collToken,
      uint collId,
      uint collateralSize
    );

  // function support(address token) external view returns (bool);
  function banks(address token ) external view returns (bool, uint8, IVault, uint256, uint,uint);
  
}



interface IWorker {
    struct AmountsV1 {
        uint amtAUser; // Supplied tokenA amount
        uint amtBUser; // Supplied tokenB amount
        // uint amtLPUser; // Supplied LP token amount
        uint amtABorrow; // Borrow tokenA amount
        uint amtBBorrow; // Borrow tokenB amount
        // uint amtLPBorrow; // Borrow LP token amount
        uint amtAMin; // Desired tokenA amount (slippage control)
        uint amtBMin; // Desired tokenB amount (slippage control)
    } 
    struct Amounts {
        uint256 amtAUser; // Supplied tokenA amount
        uint256 amtBUser; // Supplied tokenB amount
        // uint amtLPUser; // Supplied LP token amount
        uint256 amtABorrow; // Borrow tokenA amount
        uint256 amtBBorrow; // Borrow tokenB amount
        uint256 amtARepay; // Borrow tokenA amount
        uint256 amtBRepay; // Borrow tokenB amount
        // uint256 amtLPBorrow; // Borrow LP token amount
        uint256 amtAMin; // Desired tokenA amount (slippage control)
        uint256 amtBMin; // Desired tokenB amount (slippage control)
    } 

    struct RepayAmountsV1 {
        uint256 collSizeWithdraw; // Take out LP token amount (from Homora)
        // uint256 amtLPWithdraw; // Withdraw LP token amount (back to caller)
        uint256 amtARepay; // Repay tokenA amount
        uint256 amtBRepay; // Repay tokenB amount
        // uint256 positionReduced; // amount of position reduced
        uint256 amtAMin; // Desired tokenA amount
        uint256 amtBMin; // Desired tokenB amount
    }

    struct RepayAmounts {
        uint256 collSizeWithdraw; // Take out LP token amount (from Homora)
        // uint256 amtLPWithdraw; // Withdraw LP token amount (back to caller)
        uint256 amtARepay; // Repay tokenA amount
        uint256 amtBRepay; // Repay tokenB amount
        uint256 amtABorrow; // Repay tokenA amount
        uint256 amtBBorrow;
        // uint256 positionReduced; // amount of position reduced
        uint256 amtAMin; // Desired tokenA amount
        uint256 amtBMin; // Desired tokenB amount
    }
    function liquidate() external; 
    function stopLoss() external;
}


interface IArk {
  // function depositMultiple(
  //       address owner, 
  //       address[] memory tokens, 
  //       uint256[] memory amounts
  //   ) external;

  function depositOnStopLoss(
        // uint256 posId,
        address owner, 
        address token, 
        uint256 amount
    ) external;
  
  function deposit(
        address owner, 
        address token, 
        uint256 amount
    ) external;
  
}



interface IBooster {
    // this function basically replaces the old amount in Pool with the new Amount;
    function updateUserFactor (address _for, uint256 pid) external ;
    function updateFactor (address _for, uint256 _newVeSingleBalance) external;
    // function harvestFor(uint256 pid, address _for) external;
}


/**
       _____ _             __     _______                           
      / ___/(_)___  ____ _/ /__  / ____(_)___  ____ _____  ________ 
      \__ \/ / __ \/ __ `/ / _ \/ /_  / / __ \/ __ `/ __ \/ ___/ _ \
     ___/ / / / / / /_/ / /  __/ __/ / / / / / /_/ / / / / /__/  __/
    /____/_/_/ /_/\__, /_/\___/_/   /_/_/ /_/\__,_/_/ /_/\___/\___/ 
                 /____/                                             
*/



/**
 * Handle borrow from lending pools and repay of debt
 */
contract SingleBank is Governable, ERC1155NaiveReceiver, IBank {
  using SafeMath for uint;
  using SingleSafeMath for uint;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  uint private constant _NOT_ENTERED = 1;
  uint private constant _ENTERED = 2;
  uint private constant _NO_ID = type(uint256).max;
  address private constant _NO_ADDRESS = address(1);
  // address STRATEGY;

  struct Bank {
    bool isListed; // Whether this market exists.
    uint8 index; // Reverse look up index for this bank.
    IVault vault; // The vault to draw liquidity from.
    uint256 bigBangPoolId; // debtToken Pool Id
    uint totalDebt; // The last recorded total debt since last action.
    uint totalShare; // The total debt share count across all open positions.
  }

  struct Position {
    address owner; // The owner of this position.
    address collToken; // The ERC1155 token used as collateral for this position.
    uint collId; // The token id used as collateral.
    uint collateralSize; // The size of collateral token for this position.
    uint debtMap; // Bitmap of nonzero debt. i^th bit is set iff debt share of i^th bank is nonzero.
    address worker;
    mapping(address => uint) debtShareOf; // The debt share for each token.
    address user; // the user of debtToken in bigBang
  }

  uint public _GENERAL_LOCK; // TEMPORARY: re-entrancy lock guard.
  uint public _IN_EXEC_LOCK; // TEMPORARY: exec lock guard.
  uint public override POSITION_ID; // TEMPORARY: position ID currently under execution.
  address public override WORKER; // TEMPORARY: worker currently under execution.
  uint public override killBps; 
  uint public override stopLossBps; 
  uint public override nextPositionId; // Next available position ID, starting from 1 (see initialize).
  IBigBang public bigbang;
  address[] public allBanks; // The list of all listed banks.
  mapping(address => Bank) public override banks; // Mapping from token to bank data.
  mapping(uint => Position) public positions; // Mapping from position ID to position data.
  IArk public ark; // no use atm
  mapping(address => bool) public whiteListedWorkers; // Mapping from worker to whitelist status
  mapping(address => bool) public whitelistedUsers; // Mapping from user to whitelist status
  mapping(address => bool) public whitelistedContracts;// Mapping from contracts to whitelist status
  IBooster public booster;
  
  /// @dev Ensure that the function is called from EOA when allowContractCalls is set to false and caller is not whitelisted
  modifier onlyEOA() {
    require(msg.sender == tx.origin, 'not eoa');
    _;
  }

  modifier onlyWorkers() {
      require(whiteListedWorkers[msg.sender], 'not valid worker');
    _;
  }

  /// @dev Reentrancy lock guard.
  modifier lock() {
    require(_GENERAL_LOCK == _NOT_ENTERED, 'general lock');
    _GENERAL_LOCK = _ENTERED;
    _;
    _GENERAL_LOCK = _NOT_ENTERED;
  }

  /// @dev Ensure that the function is called from within the execution scope.
  modifier inExec() {
    require(POSITION_ID != _NO_ID, 'not within execution');
    require(WORKER == msg.sender && WORKER == positions[POSITION_ID].worker, 'not from pos worker');
    require(_IN_EXEC_LOCK == _NOT_ENTERED, 'in exec lock');
    _IN_EXEC_LOCK = _ENTERED;
    _;
    _IN_EXEC_LOCK = _NOT_ENTERED;
  }

  /// @dev Ensure that the interest rate of the given token is accrued.
  modifier poke(address token) {
    accrue(token);
    _;
  }

  // FIXME to let swappathsetter entry
  function onlyWhitelisted(uint256 id) internal view {
    address posOwner = positions[id].owner;

    // Case 1: Strategy Pos
    // must call from whitelisted contract for strategy positions
    if(whitelistedContracts[posOwner]) {
      require (msg.sender == posOwner, "!call from position strategy");
    }

    // Case 2: Non-Strategy Pos
    // EOA and whitelisted users only
    if(!whitelistedContracts[posOwner]) {
      require(!whitelistedContracts[msg.sender], "ban access from strat contract");
      require(whitelistedUsers[msg.sender] && msg.sender == tx.origin, "!whitelistedEOA");
    }
  }

  /// @dev Initialize the bank smart contract, using msg.sender as the first governor.
  function initialize(
    IBigBang _bigBang,
    uint16 _killBps,
    uint16 _stopLossBps,
    IArk _ark
    ) external initializer {
    __Governable__init();
    _GENERAL_LOCK = _NOT_ENTERED;
    _IN_EXEC_LOCK = _NOT_ENTERED;
    POSITION_ID = _NO_ID;
    WORKER = _NO_ADDRESS;
    bigbang = _bigBang;
    killBps = _killBps;
    stopLossBps = _stopLossBps;
    nextPositionId = 1;
    ark = _ark;
    emit SetFeeBps(_stopLossBps,_killBps);
  }

  /// @dev Return the current executor (the owner of the current position).
  function EXECUTOR() external view override returns (address) {
    uint positionId = POSITION_ID;
    require(positionId != _NO_ID, 'not under execution');
    return positions[positionId].owner;
  }

  function RECEIVER() external view override returns (address) {
    uint positionId = POSITION_ID;
    require(positionId != _NO_ID, 'not under execution');
    return positions[positionId].user;
  }

  
  /// @dev Set whitelist worker status
  function setWhitelistWorkers(address[] calldata workers, bool status) external onlyGov{
    for (uint idx = 0; idx < workers.length; idx++) {
      whiteListedWorkers[workers[idx]] = status;
    }
  }

  
  /// @dev Set whitelist user status
  /// @param users list of users to change status
  /// @param statuses list of statuses to change to
  function setWhitelistUsers(address[] calldata users, bool[] calldata statuses) external onlyGov {
    require(users.length == statuses.length, 'users & statuses length mismatched');
    for (uint idx = 0; idx < users.length; idx++) {
      whitelistedUsers[users[idx]] = statuses[idx];
    }
  }

  /// @dev Set whitelist contracts status
  /// @param contracts list of users to change status
  /// @param status list of statuses to change to
  function setWhitelistedContracts(address[] calldata contracts, bool status) external onlyGov {
    for (uint idx = 0; idx < contracts.length; idx++) {
      whitelistedContracts[contracts[idx]] = status;
    }
  }

  
  /// @dev Trigger interest accrual for the given bank.
  /// @param token The underlying token to trigger the interest accrual.
  function accrue(address token) public {
    Bank storage bank = banks[token];
    require(bank.isListed, 'bank not exist');
    uint totalDebt = bank.totalDebt;
    uint debt = bank.vault.currentDebtVal();
    if (debt > totalDebt) {
      bank.totalDebt = debt;
    } else if (totalDebt != debt) {
      bank.totalDebt = debt;
    }
  }

  /// @dev Convenient function to trigger interest accrual for a list of banks.
  /// @param tokens The list of banks to trigger interest accrual.
  function accrueAll(address[] memory tokens) external {
    for (uint idx = 0; idx < tokens.length; idx++) {
      accrue(tokens[idx]);
    }
  }

  /// @dev Return the borrow balance for given position and token without triggering interest accrual.
  /// @param positionId The position to query for borrow balance.
  /// @param token The token to query for borrow balance.
  function borrowBalanceStored(uint positionId, address token) public view override returns (uint) {
    uint totalDebt = banks[token].totalDebt;
    uint totalShare = banks[token].totalShare;
    uint share = positions[positionId].debtShareOf[token];
    if (share == 0 || totalDebt == 0) {
      return 0;
    } else {
      return share.mul(totalDebt).ceilDiv(totalShare);
    }
  }

  /// @dev Trigger interest accrual and return the current borrow balance.
  /// @param positionId The position to query for borrow balance.
  /// @param token The token to query for borrow balance.
  function borrowBalanceCurrent(uint positionId, address token) public override returns (uint) {
    if (banks[token].isListed) {
      accrue(token);
      return borrowBalanceStored(positionId, token);
    }else {
      return 0;
    }
  }

  /// @dev Return bank information for the given token.
  /// @param token The token address to query for bank information.
  function getBankInfo(address token)
    external
    view
    override
    returns (
      bool isListed,
      address vault,
      uint totalDebt,
      uint totalShare
    )
  {
    Bank storage bank = banks[token];
    return (bank.isListed, address(bank.vault), /*bank.reserve,*/ bank.totalDebt, bank.totalShare);
  }

  /// @dev Return position information for the given position id.
  /// @param positionId The position id to query for position information.
  function getPositionInfo(uint positionId)
    public
    view
    override
    returns (
      address owner,
      address collToken,
      uint collId,
      uint collateralSize
    )
  {
    Position storage pos = positions[positionId];
    return (pos.owner, pos.collToken, pos.collId, pos.collateralSize);
  }

  /// @dev Return current position information
  function getCurrentPositionInfo()
    external
    view
    override
    returns (
      address owner,
      address collToken,
      uint collId,
      uint collateralSize
    )
  {
    require(POSITION_ID != _NO_ID, 'no id');
    return getPositionInfo(POSITION_ID);
  }

  function getCurrentPositionDebts()
    external
    view
    override
    returns (address[] memory tokens, uint[] memory debts)
  {
    require(POSITION_ID != _NO_ID, 'no id');
    return getPositionDebts(POSITION_ID);
  }

  /// @dev Return the debt share of the given bank token for the given position id.
  /// @param positionId position id to get debt of
  /// @param token ERC20 debt token to query
  function getPositionDebtShareOf(uint positionId, address token) external view returns (uint) {
    return positions[positionId].debtShareOf[token];
  }

  
  //All debts on that position with updated interest
  function getPositionDebts(uint positionId) public override view returns (address[] memory tokens, uint[] memory debts) {
    Position storage pos = positions[positionId];
    uint count = 0;
    uint bitMap = pos.debtMap;
    while (bitMap > 0) {
      if ((bitMap & 1) != 0) {
        count++;
      }
      bitMap >>= 1;
    }
    tokens = new address[](count);
    debts = new uint[](count);
    bitMap = pos.debtMap;
    count = 0;
    uint idx = 0;
    while (bitMap > 0) {
      if ((bitMap & 1) != 0) {
        address token = allBanks[idx];
        Bank storage bank = banks[token];
        tokens[count] = token;
        uint totalDebt = bank.totalDebt.add(bank.vault.pendingInterest(0));
        debts[count] = pos.debtShareOf[token].mul(totalDebt).ceilDiv(bank.totalShare);
        count++;
      }
      idx++;
      bitMap >>= 1;
    }
  }




  /// @dev Add a new bank to the ecosystem.
  /// @param token The underlying token for the bank.
  /// @param vault The address of the vault smart contract.
  function addBank(address token, IVault vault, uint256 _bigBangPoolId) external onlyGov {
    Bank storage bank = banks[token];
    require(!bank.isListed, 'bank already exists');
    bank.isListed = true;
    require(allBanks.length < 256, 'reach bank limit');
    bank.index = uint8(allBanks.length);
    bank.vault = vault;
    IERC20Upgradeable(token).safeApprove(address(vault), type(uint256).max);
    bank.bigBangPoolId = _bigBangPoolId;
    allBanks.push(token);
    emit AddBank(token, address(vault));
  }

  function removeBank(address token, IVault vault) external onlyGov {
    Bank storage bank = banks[token];
    require(bank.isListed, 'bank does not exists');
    require(bank.totalDebt == 0, "debt exists");
    bank.isListed = false;
    bank.vault = IVault(address(0));
    IERC20Upgradeable(token).safeApprove(address(vault), 0);
    emit RemoveBank(token, address(vault));
  }

  /// @dev Set the fee bps value that Homora bank charges.
  function setFeeBps (uint16 _stopLossBps, uint16 _killBps) external onlyGov {
    require(_stopLossBps <= 10000 && _killBps <=10000,  'fee too high');
    killBps = _killBps;
    stopLossBps = _stopLossBps;
    emit SetFeeBps(_stopLossBps , _killBps);
  }

  /// liquidate non strategy position can be called by whitelistedUsers
  /// liquidate strategy position can be called by stratey itself = pos.owner
  function liquidate( uint positionId) external override lock {
    onlyWhitelisted(positionId);
    
    Position storage pos = positions[positionId];
    
    IWorker worker = IWorker(pos.worker);
    require (pos.debtMap > 0, "position no debt");
    POSITION_ID = positionId;
    WORKER = pos.worker;

    worker.liquidate();
    
    POSITION_ID = _NO_ID;
    WORKER = _NO_ADDRESS;
    emit Liquidate( positionId, pos.collateralSize, pos.collToken, pos.collId);
  }

  /// stoploss non strategy position can be called by whitelistedUsers
  /// stoploss strategy position can be called by stratey itself = pos.owner
  function stopLoss(uint positionId) external override lock {
    onlyWhitelisted(positionId);

    Position storage pos = positions[positionId];

    IWorker worker = IWorker(pos.worker);
    POSITION_ID = positionId;
    WORKER = pos.worker;
    worker.stopLoss();
    POSITION_ID = _NO_ID;
    WORKER = _NO_ADDRESS;

    emit StopLoss(positionId,pos.collateralSize,pos.collToken,pos.collId);
  }

  
  /// @dev Execute the action, calling worker's function with the supplied data.
  // this function is called by whitelistedContracts only -- the strategies
  /// @param positionId The position ID to execute the action, or zero for new position.
  /// @param worker The target worker to invoke the execution via HomoraCaster.
  /// @param _user The strategy position owner, the user of debtToken on bigBang 
  /// @param data Extra data to pass to the target for the execution.
  function executeByStrategy(
    uint positionId,
    address worker,
    address _user,
    bytes[] calldata data
  ) external payable override lock returns (uint) {

    require(whitelistedContracts[msg.sender],"!contract");
    require(whiteListedWorkers[worker], 'worker not whitelisted');

    if (positionId == 0) {
      positionId = nextPositionId++;
      positions[positionId].owner = msg.sender;
      positions[positionId].worker = worker;
      positions[positionId].user = _user;
    } else {
      require(positionId < nextPositionId, 'position id not exists');
      require(msg.sender == positions[positionId].owner, 'not position owner');
      require(_user == positions[positionId].user,"not position user");
      require(worker == positions[positionId].worker, '!worker');
    }

    POSITION_ID = positionId;
    WORKER = worker;
    _execute(worker,data);

    POSITION_ID = _NO_ID;
    WORKER = _NO_ADDRESS;
    return positionId;
  }


  /// @dev Execute the action, calling worker's function with the supplied data.
  /// @param positionId The position ID to execute the action, or zero for new position.
  /// @param worker The target worker to invoke the execution via HomoraCaster.
  /// @param data Extra data to pass to the target for the execution.
  function execute(
    uint positionId,
    address worker,
    bytes[] calldata data
  ) public payable onlyEOA lock {

    require(whiteListedWorkers[worker], 'worker not whitelisted');
    if (positionId == 0) {
      positionId = nextPositionId++;
      positions[positionId].owner = msg.sender;
      positions[positionId].worker = worker;
      positions[positionId].user = msg.sender;
    } else {
      require(positionId < nextPositionId, 'position id not exists');
      require(msg.sender == positions[positionId].owner, 'not position owner');
      require(msg.sender == positions[positionId].user, 'not position user');
      require(worker == positions[positionId].worker, '!worker');
    }
    POSITION_ID = positionId;
    WORKER = worker;
    _execute(worker,data);
    POSITION_ID = _NO_ID;
    WORKER = _NO_ADDRESS;
  }

  // exactly the same as execute, only one more event created
  function executeLongShort(
    uint positionId,
    address worker,
    bytes[] calldata data
  ) external payable{

    execute(positionId, worker, data);

    if(positionId == 0) {
      emit LongShortPosition(nextPositionId-1);
    }
  }
  

  /// @dev Borrow tokens from that bank. Must only be called while under execution.
  /// @param token The token to borrow from the bank.
  /// @param amount The amount of tokens to borrow.
  function borrow(address token, uint amount) external override inExec poke(token) {
    require(banks[token].isListed, 'token not listed');
    Bank storage bank = banks[token];
    Position storage pos = positions[POSITION_ID];
    
    IERC20Upgradeable(token).safeTransfer(msg.sender, doBorrow(token, amount));
    uint share = IERC20Upgradeable(bank.vault.debtToken()).balanceOf(address(this));
    bank.totalShare = bank.totalShare.add(share);
    pos.debtShareOf[token] = pos.debtShareOf[token].add(share);
    if (pos.debtShareOf[token] > 0) {
      pos.debtMap |= (1 << uint(bank.index));
    }
    //staking debtToken on behalf of owner to gain singleToken
    if(IERC20Upgradeable(bank.vault.debtToken()).allowance(address(this), address(bigbang)) < share){
      IERC20Upgradeable(bank.vault.debtToken()).safeApprove( address(bigbang), 0);
      IERC20Upgradeable(bank.vault.debtToken()).safeApprove( address(bigbang), type(uint256).max);
    }
    bigbang.deposit(pos.user, bank.bigBangPoolId, share);
    if (address(booster) != address(0)) {
      booster.updateUserFactor(pos.user, bank.bigBangPoolId);
    }
    // console.log("borrow", amount);
    require(IERC20(bank.vault.debtToken()).balanceOf(address(this)) == 0, "wrong shares");
    emit Borrow(POSITION_ID, msg.sender, token, amount, share);
  }

  /// @dev Repay tokens to the bank. Must only be called while under execution.
  /// @param token The token to repay to the bank.
  /// @param amountCall The amount of tokens to repay via transferFrom.
  function repay(address token, uint amountCall) external override inExec poke(token) {
    require(banks[token].isListed, 'token not whitelisted');
    (uint amount, uint share) = repayInternal(POSITION_ID, token, amountCall);
    emit Repay(POSITION_ID, msg.sender, token, amount, share);
  }
  
  //for users to repay the debts by transferring tokens to vault
  // msg.sender does not have to be the user/owner of the position
  function repayOnly(uint posId, address token, uint amountCall) external poke(token) lock {
    require(banks[token].isListed, 'token not whitelisted');
    if (amountCall > 0 ) {
      (uint amount, uint share) = repayInternal(posId, token, amountCall);
      emit Repay(POSITION_ID, msg.sender, token, amount, share);
    }
  }

  /// @dev Perform repay action. Return the amount actually taken and the debt share reduced.
  /// @param positionId The position ID to repay the debt.
  /// @param token The bank token to pay the debt.
  /// @param amountCall The amount to repay by calling transferFrom, or -1 for debt size.
  function repayInternal(
    uint positionId,
    address token,
    uint amountCall
  ) internal returns (uint, uint) {
    
    Bank storage bank = banks[token];
    Position storage pos = positions[positionId];
    
    uint totalShareBef = bank.totalShare;
    uint totalDebt = bank.totalDebt;
    uint oldShare = pos.debtShareOf[token];
    uint oldDebt = oldShare.mul(totalDebt).ceilDiv(totalShareBef);
    
    amountCall = Math.min(oldDebt,amountCall);
    (uint256 amount,,) = bigbang.userInfo(bank.bigBangPoolId,pos.user);
    
    bigbang.withdraw(pos.user, bank.bigBangPoolId, Math.min(oldShare,amount));
    
    uint paid = doRepay(token, doERC20TransferIn(token, amountCall));
    
    require(paid == amountCall, 'wrong paid amount');
    require(paid <= oldDebt, 'paid exceeds debt'); // prevent share overflow attack
    
    bigbang.deposit(pos.user, bank.bigBangPoolId, IERC20(bank.vault.debtToken()).balanceOf(address(this)));
    
    if (address(booster) != address(0)) {
      booster.updateUserFactor(pos.user, bank.bigBangPoolId);
    }
    pos.debtShareOf[token] = oldShare > totalShareBef.sub(bank.totalShare) ? 
          oldShare.sub(totalShareBef.sub(bank.totalShare)) : 0 ;

    if (pos.debtShareOf[token] == 0) {
      pos.debtMap &= ~(1 << uint(bank.index));
    }
    return (paid, oldShare.sub(pos.debtShareOf[token]));
  }

  /// @dev Transmit user assets to the caller, so users only need to approve Bank for spending.
  /// @param token The token to transfer from user to the caller.
  /// @param amount The amount to transfer.
  function transmit(address token, uint amount) external override inExec {
    Position storage pos = positions[POSITION_ID];
    IERC20Upgradeable(token).safeTransferFrom(pos.owner, msg.sender, amount);
  }

  /// @dev Put more collateral for users. Must only be called during execution.
  /// @param collToken The ERC1155 token to collateral.
  /// @param collId The token id to collateral.
  /// @param amountCall The amount of tokens to put via transferFrom.
  function putCollateral(
    address collToken,
    uint collId,
    uint amountCall
  ) external override inExec {
    Position storage pos = positions[POSITION_ID];
    if (pos.collToken != collToken || pos.collId != collId) {
      require(pos.collateralSize == 0, 'another type of collateral already exists');
      pos.collToken = collToken;
      pos.collId = collId;
    }
    uint amount = doERC1155TransferIn(collToken, collId, amountCall);
    pos.collateralSize = pos.collateralSize.add(amount);
    emit PutCollateral(POSITION_ID, msg.sender, collToken, collId, amount);
  }

  /// @dev Take some collateral back. Must only be called during execution.
  /// @param collToken The ERC1155 token to take back.
  /// @param collId The token id to take back.
  /// @param amount The amount of tokens to take back via transfer.
  function takeCollateral(
    address collToken,
    uint collId,
    uint amount
  ) external override inExec {
    Position storage pos = positions[POSITION_ID];
    require(collToken == pos.collToken, 'invalid collateral token');
    require(collId == pos.collId, 'invalid underlying token');
    if (amount == type(uint256).max) {
      amount = pos.collateralSize;
    }
    require(pos.collateralSize >= amount , "not enough collSize");
    pos.collateralSize = pos.collateralSize.sub(amount);
    IERC1155(collToken).safeTransferFrom(address(this), msg.sender, collId, amount, '');
    emit TakeCollateral(POSITION_ID, msg.sender, collToken, collId, amount);
  }

  /// @dev Internal function to perform borrow from the bank and return the amount received.
  /// @param token The token to perform borrow action.
  /// @param amountCall The amount use in the transferFrom call.
  /// NOTE: Caller must ensure that vault interest was already accrued up to this block.
  function doBorrow(address token, uint amountCall) internal returns (uint) {
    Bank storage bank = banks[token]; // assume the input is already sanity checked.
    uint balanceBefore = IERC20(token).balanceOf(address(this));
    require(bank.vault.borrow(amountCall) == 0, 'bad borrow');
    uint balanceAfter = IERC20(token).balanceOf(address(this));
    bank.totalDebt = bank.totalDebt.add(amountCall);
    return balanceAfter.sub(balanceBefore);
  }

  /// @dev Internal function to perform repay to the bank and return the amount actually repaid.
  /// @param token The token to perform repay action.
  /// @param amountCall The amount to use in the repay call.
  /// NOTE: Caller must ensure that vault interest was already accrued up to this block.
  function doRepay(address token, uint amountCall) internal returns (uint) {
    Bank storage bank = banks[token]; // assume the input is already sanity checked.
    IVault vault = bank.vault;
    uint oldDebt = bank.totalDebt;
    require(vault.repay(amountCall) == 0, 'bad repay');
    uint newDebt = vault.currentDebtVal();
    bank.totalDebt = newDebt;
    require(vault.vaultDebtShare() <= bank.totalShare, "shares incorrect");
    bank.totalShare = vault.vaultDebtShare();
    return oldDebt.sub(newDebt);
  }

  /// @dev Internal function to perform ERC20 transfer in and return amount actually received.
  /// @param token The token to perform transferFrom action.
  /// @param amountCall The amount use in the transferFrom call.
  function doERC20TransferIn(address token, uint amountCall) internal returns (uint) {
    uint balanceBefore = IERC20(token).balanceOf(address(this));
    IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amountCall);
    uint balanceAfter = IERC20(token).balanceOf(address(this));
    return balanceAfter.sub(balanceBefore);
  }

  /// @dev Internal function to perform ERC1155 transfer in and return amount actually received.
  /// @param token The token to perform transferFrom action.
  /// @param id The id to perform transferFrom action.
  /// @param amountCall The amount use in the transferFrom call.
  function doERC1155TransferIn(
    address token,
    uint id,
    uint amountCall
  ) internal returns (uint) {
    uint balanceBefore = IERC1155(token).balanceOf(address(this), id);
    IERC1155(token).safeTransferFrom(msg.sender, address(this), id, amountCall, '');
    uint balanceAfter = IERC1155(token).balanceOf(address(this), id);
    return balanceAfter.sub(balanceBefore);
  }

  function _execute(address target, bytes[] calldata data) internal {
    for (uint256 i = 0; i < data.length; i++) {
      bool ok;
      bytes memory returndata;
      if (i == 0){
        (ok, returndata) = target.call{value: msg.value}(data[i]);
      }else {
        (ok, returndata) = target.call(data[i]);
      }

      if (!ok) {
        if (returndata.length > 0) {
          // The easiest way to bubble the revert reason is using memory via assembly
          // solhint-disable-next-line no-inline-assembly
          assembly {
            let returndata_size := mload(returndata)
            revert(add(32, returndata), returndata_size)
          }
        } else {
          revert('bad cast call');
        }
      }
    }
  }

  function harvestSingleFor(uint debtPid) external {
    (uint256 amount ,,address fundedBy) = bigbang.userInfo(debtPid, msg.sender);
    require (fundedBy == address(this) && amount > 0, "not owned by bank");
    bigbang.deposit(msg.sender, debtPid, 0);
    
    if (address(booster) != address(0)){
      booster.updateUserFactor(msg.sender, debtPid);
    }
  }

  function setBooster(address _booster) external onlyGov {
    booster = IBooster(_booster);
  }
  
}