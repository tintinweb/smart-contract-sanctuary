/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File @openzeppelin/contracts/security/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

/**
 * @title Interface for Nifty Island's Market
 */
interface IMarketMaker {
    struct Market {
        uint256 marketId;
        address tokenContract;
        uint256 tokenId;
        address tokenOwner;
        uint256 tokenCount;
        Ask ask;
        Bid[] bids;
        Stakeholder[] stakeholders;
    }

    // Stakeholders receive a percentage of the sale price when the market ends
    struct Stakeholder {
        // Address of the stakeholder
        address stakeholder;
        //  The percentage the stakeholer receives
        uint8 stakePercentage;
    }

    struct Ask {
        // Amount of the currency being asked
        uint256 amount;
        // Address to the ERC20 token being asked
        address currency;
    }

    struct Bid {
        // Amount of the currency being bid
        uint256 amount;
        // Address of the bidder
        address bidder;
        // Address to the ERC20 token being bid
        address currency;
        // The number of tokens this bid is for
        uint256 tokenCount;
    }


    // Allows a seller to set a desired price
    function setAsk(uint256 marketId, address currency, uint256 amount)
        external;
    
    // Allows a seller to remove the desired price
    function removeAsk(uint256 marketId)
        external;

    function removeMarket(uint256 marketId) external;

    function removeBid(
        uint256 marketId,
        uint256 bidIndex
    ) external;

    function acceptBid(
        uint256 marketId,
        uint256 bidIndex
    ) external payable;

    function getBids(uint256 marketId)
        external
        view
        returns (Bid[] memory);

    function getStakeholders(uint256 marketId)
        external
        view
        returns (Stakeholder[] memory);

    event MarketCreated(uint256 indexed marketId, address indexed tokenContract, uint256 indexed tokenId, uint256 tokenCount, address owner);
    event TransferFinalized(uint256 indexed marketId, address indexed tokenContract, uint256 indexed tokenId, uint256 tokenCount, address marketCurrency, uint256 amount, address buyer);
    event MarketRemoved(uint256 indexed marketId, address indexed tokenContract, uint256 indexed tokenId, uint256 tokenCount, address owner);
    event BidCreated(uint256 indexed marketId, address indexed tokenContract, uint256 indexed tokenId, uint256 bidIndex, uint256 tokenCount, address marketCurrency, uint256 amount, address bidder);
    event BidRemoved(uint256 indexed marketId, address indexed tokenContract, uint256 indexed tokenId, uint256 bidIndex, uint256 tokenCount, address marketCurrency, uint256 amount, address bidder);
    event AskCreated(uint256 indexed marketId, address indexed tokenContract, uint256 indexed tokenId, address marketCurrency, uint256 amount);
    event AskRemoved(uint256 indexed marketId, address indexed tokenContract, uint256 indexed tokenId, address marketCurrency, uint256 amount);
    event MarketStakeholderAdded(uint256 indexed marketId, address indexed tokenContract, uint256 indexed tokenId, address stakeholder, uint8 stakePercentage);
}

interface INftMarketMaker is IMarketMaker {
    function createMarket(address tokenContract, uint256 tokenId, Stakeholder[] calldata stakeholders)
        external
        returns (uint256);

    // When a buyer purchases at the desired price
    function createBid(
        uint256 marketId,
        uint256 amount,
        address currency
    ) external payable;
}

interface IMtMarketMaker is IMarketMaker {
    function createMarket(address tokenContract, uint256 tokenId, uint256 tokenCount, Stakeholder[] calldata stakeholders)
        external
        returns (uint256);

    // When a buyer purchases at the desired price
    function createBid(
        uint256 marketId,
        uint256 tokenCount,
        uint256 amount,
        address currency
    ) external payable;
}

/**
 * @title An open auction house, enabling collectors and curators to run their own auctions
 */
contract NonFungibleTokenMarket is INftMarketMaker, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    mapping(uint256 => IMarketMaker.Market) public markets;

    bytes4 constant private ERC721_INTERFACE_ID = 0x80ac58cd; // 721 interface id
    Counters.Counter private _marketIdTracker;

    modifier marketExists(uint256 marketId) {
        require(markets[marketId].tokenOwner != address(0), "Market does not exist");
        _;
    }

    modifier isOwner(uint256 marketId, address sender) {
      require(markets[marketId].tokenOwner == sender,  "Caller must be owner for token");
      _;
    }

    modifier bidExists(uint256 marketId, uint256 bidIndex) {
      require(bidIndex < markets[marketId].bids.length && markets[marketId].bids[bidIndex].bidder != address(0), "Bid does not exist");
      _;
    }

    /*
     * Constructor
     */
    constructor() {
    }

    function createMarket(address tokenContract, uint256 tokenId, Stakeholder[] calldata stakeholders)
      public
      override
      nonReentrant
      returns (uint256) {
        require(IERC165(tokenContract).supportsInterface(ERC721_INTERFACE_ID), "tokenContract does not support ERC721 interface");
        require(address(this) == IERC721(tokenContract).getApproved(tokenId), "This contract must be approved for token id");
        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        require(msg.sender == tokenOwner, "Caller must be owner for token");
        uint256 marketId = _marketIdTracker.current();
        
        markets[marketId].marketId = marketId;
        markets[marketId].tokenContract = tokenContract;
        markets[marketId].tokenId = tokenId;
        markets[marketId].tokenOwner = tokenOwner;
        markets[marketId].tokenCount = 1;
        _marketIdTracker.increment();

        emit MarketCreated(marketId, tokenContract, tokenId, 1, msg.sender);

        uint8 totalPct = 0;
        for (uint i = 0; i < stakeholders.length; i++) {
          markets[marketId].stakeholders.push(stakeholders[i]);
          totalPct = totalPct + stakeholders[i].stakePercentage;
          emit MarketStakeholderAdded(marketId, tokenContract, tokenId, stakeholders[i].stakeholder, stakeholders[i].stakePercentage);
        }
        require(totalPct < 100, "Invalid stake percentages");

        // add curators here
        return marketId;
    }

    function removeMarket(uint256 marketId)
      external
      override
      marketExists(marketId)
      isOwner(marketId, msg.sender)
      nonReentrant {
        _removeMarket(marketId);
    }
    
    function setAsk(uint256 marketId, address currency, uint256 amount)
      external
      override
      marketExists(marketId)
      isOwner(marketId, msg.sender)
      nonReentrant {
        require(amount > 0, "Cannot set an ask of 0");

        if (markets[marketId].ask.currency != address(0) || markets[marketId].ask.amount != 0) {
          emit AskRemoved(marketId, markets[marketId].tokenContract, markets[marketId].tokenId, markets[marketId].ask.currency, markets[marketId].ask.amount);
        }

        markets[marketId].ask.currency = currency;
        markets[marketId].ask.amount = amount;
        emit AskCreated(marketId, markets[marketId].tokenContract, markets[marketId].tokenId, markets[marketId].ask.currency, markets[marketId].ask.amount);
    }

    function removeAsk(uint256 marketId)
      external
      override
      marketExists(marketId)
      isOwner(marketId, msg.sender)
      nonReentrant {
        emit AskRemoved(marketId, markets[marketId].tokenContract, markets[marketId].tokenId, markets[marketId].ask.currency, markets[marketId].ask.amount);
        markets[marketId].ask.currency = address(0);
        markets[marketId].ask.amount = 0;
    }

    function createBid(uint256 marketId, uint256 amount, address currency)
      external
      override
      payable
      marketExists(marketId)
      nonReentrant {
          _validateIncomingBid(amount, currency);

          // If there is an ask, and if the bid matches the ask, then finalize the auction
          if (markets[marketId].ask.amount > 0  && markets[marketId].ask.currency != address(0) && currency == markets[marketId].ask.currency && amount >= markets[marketId].ask.amount) {
            _finalizeMarket(marketId, currency, msg.sender, amount);
            return;
          }

          Bid memory bid = Bid({ amount: amount, currency: currency, bidder: msg.sender, tokenCount: 1 });
          markets[marketId].bids.push(bid);

          emit BidCreated(marketId, markets[marketId].tokenContract, markets[marketId].tokenId, markets[marketId].bids.length -1, bid.tokenCount, bid.currency, bid.amount, bid.bidder);
    }

  function removeBid(uint256 marketId, uint256 bidIndex)
      external
      override
      marketExists(marketId)
      bidExists(marketId, bidIndex)
      {
        require(markets[marketId].bids[bidIndex].bidder == msg.sender, "Caller is not the same as bidder");
        Bid memory bid = markets[marketId].bids[bidIndex];
        emit BidRemoved(marketId, markets[marketId].tokenContract, markets[marketId].tokenId, bidIndex, bid.tokenCount, bid.currency, bid.amount, bid.bidder);
        // future code golf check -- check Results. Commented code takes 100 more gas
        // markets[marketId].bids[bidIndex].bidder = address(0);
        // markets[marketId].bids[bidIndex].amount = 0;
        markets[marketId].bids[bidIndex] = Bid({ bidder: address(0), currency: address(0), amount: 0, tokenCount: 0 });
    }

    function acceptBid(uint256 marketId, uint256 bidIndex)
      external
      override
      marketExists(marketId)
      bidExists(marketId, bidIndex)
      isOwner(marketId, msg.sender)
      payable {
        // Code golf results: using memory variable saves gas
        Bid memory bid = markets[marketId].bids[bidIndex];
        _finalizeMarket(marketId, bid.currency, bid.bidder, bid.amount);
      }

    function _validateIncomingBid(uint256 amount, address currency) internal view {
        IERC20 token = IERC20(currency);
        require(token.balanceOf(msg.sender) >= amount, "Caller's token balance is insufficient for bid");
        require(token.allowance(msg.sender, address(this)) >= amount, "Caller must approve market for currency");
    }

    // Ends the market with the given buyer and amount.
    function _finalizeMarket(uint256 marketId, address currency, address buyer, uint256 amount)
        private
      {
        IERC20 currencyToken = IERC20(currency);

        // We must check the balance that was actually transferred to the auction,
        // as some tokens impose a transfer fee and would not actually transfer the
        // full amount to the market, resulting in potentally locked funds
        uint256 beforeBalance = currencyToken.balanceOf(address(this));
        currencyToken.transferFrom(buyer, address(this), amount);
        uint256 afterBalance = currencyToken.balanceOf(address(this));
        require(beforeBalance.add(amount) == afterBalance, "Token transfer call did not transfer expected amount");
      
        // Using memory variable: reduces gas usage
        Market memory market = markets[marketId];

        try IERC721(market.tokenContract).safeTransferFrom(market.tokenOwner, buyer, market.tokenId) {} catch {
            _removeMarket(marketId);
            return;
        }

        uint256 tokenOwnerProfit = amount;

        for (uint i = 0; i < market.stakeholders.length; i++) {
          uint256 cut = amount.mul(market.stakeholders[i].stakePercentage).div(100);
          currencyToken.transfer(market.stakeholders[i].stakeholder, cut);
          tokenOwnerProfit = tokenOwnerProfit - cut;
        }

        currencyToken.transfer(market.tokenOwner, tokenOwnerProfit);
        emit TransferFinalized(marketId, market.tokenContract, market.tokenId, 1, currency, amount, buyer);
        _removeMarket(marketId);
      }
    
    function _removeMarket(uint256 marketId) 
      private
      {
        emit MarketRemoved(marketId, markets[marketId].tokenContract, markets[marketId].tokenId, markets[marketId].tokenCount, markets[marketId].tokenOwner);
        delete markets[marketId];
    }

    function getBids(uint256 marketId)
      external
      view
      override
      marketExists(marketId)
      returns (Bid[] memory) {
        return markets[marketId].bids;
      }

    function getStakeholders(uint256 marketId)
      external
      view
      override
      marketExists(marketId)
      returns (Stakeholder[] memory) {
        return markets[marketId].stakeholders;
      }
}