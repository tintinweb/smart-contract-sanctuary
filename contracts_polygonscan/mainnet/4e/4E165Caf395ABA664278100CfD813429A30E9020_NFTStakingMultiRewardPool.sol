/**
 *Submitted for verification at polygonscan.com on 2021-08-12
*/

pragma solidity 0.6.12;


/**
 *Submitted for verification at BscScan.com on 2021-06-24
*/
// SPDX-License-Identifier: MIT
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

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
    using SafeMath for uint256;
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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
            // solhint-disable-next-line max-line-length
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

interface IDogeLandNFT is IERC721 {
    function getLandArea(uint256 _landID) external view returns (uint256);
}

contract NFTStakingMultiRewardPool is OwnableUpgradeSafe {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant BLOCKS_PER_DAY = 28800;

    // governance
    address public reserveFund;

    // flags
    uint256 private _locked = 0;
    mapping(uint256 => mapping(address => bool)) private _btxStatus;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256[] landIds;
        mapping(address => uint256) rewardDebt;
        mapping(address => uint256) reward;
    }

    // Info of each rewardPool funding.
    struct RewardPoolInfo {
        address rewardToken; // Address of rewardPool token contract.
        uint256 lastRewardBlock; // Last block number that rewardPool distribution occurs.
        uint256 rewardPerBlock; // Reward token amount to distribute per block.
        uint256 accRewardPerShare; // Accumulated rewardPool per share, times 1e18.
        uint256 startRewardBlock;
        uint256 endRewardBlock;
        uint256 totalPaidRewards;
    }

    address public dogeLand = address(0xB0cdeA9604b23Fa0b37eAE4646D78cB2f01b293A);

    address public stakeNFTToken = address(0x87D70315FEc0C782818ecd616F9a74f55d45F1Ef);
    uint256 public stakeLpSupply;

    mapping(address => RewardPoolInfo) public rewardPoolInfo;

    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;
    address[] public rewardTokens;

    event Deposit(address indexed user, uint256 landId);
    event Withdraw(address indexed user, uint256 landId);
    event EmergencyWithdraw(address indexed user, uint256 landId);
    event RewardPaid(address rewardToken, address indexed user, uint256 amount);

    /* ========== Modifiers =============== */

    modifier onlyReserveFund() {
        require(reserveFund == msg.sender || owner() == msg.sender, "caller is not the reserveFund");
        _;
    }

    modifier notContract() {
        uint256 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "contract not allowed");
        require(tx.origin == msg.sender, "contract not allowed");
        _;
    }

    modifier lock() {
        require(_locked == 0, "LOCKED");
        _locked = 1;
        _;
        _locked = 0;
    }

    modifier onlyOneBlock() {
        require(!_btxStatus[block.number][tx.origin] && !_btxStatus[block.number][msg.sender], "ContractGuard: one block, one function");

        _btxStatus[block.number][tx.origin] = true;
        _btxStatus[block.number][msg.sender] = true;

        _;
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        address _stakeNFTToken,
        address _dogeLand,
        address _reserveFund,
        uint256 _startRewardBlock
    ) public initializer {
        require(block.number < _startRewardBlock, "late");
        OwnableUpgradeSafe.__Ownable_init();

        stakeNFTToken = _stakeNFTToken;
        dogeLand = _dogeLand;
        reserveFund = _reserveFund;

        _locked = 0;

        addRewardPool(_dogeLand, _startRewardBlock);
    }

    function setReserveFund(address _reserveFund) external onlyReserveFund {
        reserveFund = _reserveFund;
    }

    function setRewardTokens(address[] memory _rewardTokens) external onlyOwner {
        rewardTokens = _rewardTokens;
    }

    function setStakeNFTToken(address _stakeNFTToken) external onlyOwner {
        stakeNFTToken = _stakeNFTToken;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getRewardTokenLength() external view returns (uint256) {
        return rewardTokens.length;
    }

    function getRewardPerBlock(
        address _rewardToken,
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
        RewardPoolInfo memory rewardPool = rewardPoolInfo[_rewardToken];
        uint256 _rewardPerBlock = rewardPool.rewardPerBlock;
        uint256 _startRewardBlock = rewardPool.startRewardBlock;
        uint256 _endRewardBlock = rewardPool.endRewardBlock;
        if (_from >= _to || _from >= _endRewardBlock) return 0;
        if (_to <= _startRewardBlock) return 0;
        if (_from <= _startRewardBlock) {
            if (_to <= _endRewardBlock) return _to.sub(_startRewardBlock).mul(_rewardPerBlock);
            else return _endRewardBlock.sub(_startRewardBlock).mul(_rewardPerBlock);
        }
        if (_to <= _endRewardBlock) return _to.sub(_from).mul(_rewardPerBlock);
        else return _endRewardBlock.sub(_from).mul(_rewardPerBlock);
    }

    function getRewardPerBlock(address _rewardToken) external view returns (uint256) {
        return getRewardPerBlock(_rewardToken, block.number, block.number + 1);
    }

    function pendingReward(address _rewardToken, address _account) external view returns (uint256) {
        UserInfo storage user = userInfo[_account];
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_rewardToken];
        uint256 _accRewardPerShare = rewardPool.accRewardPerShare;
        uint256 _lpSupply = stakeLpSupply;
        uint256 _endRewardBlock = rewardPool.endRewardBlock;
        uint256 _endRewardBlockApplicable = block.number > _endRewardBlock ? _endRewardBlock : block.number;
        uint256 _lastRewardBlock = rewardPool.lastRewardBlock;
        if (_endRewardBlockApplicable > _lastRewardBlock && _lpSupply != 0) {
            uint256 _incRewardPerShare = getRewardPerBlock(_rewardToken, _lastRewardBlock, _endRewardBlockApplicable).mul(1e18).div(_lpSupply);
            _accRewardPerShare = _accRewardPerShare.add(_incRewardPerShare);
        }
        return user.amount.mul(_accRewardPerShare).div(1e18).add(user.reward[_rewardToken]).sub(user.rewardDebt[_rewardToken]);
    }

    function getUserStakedCards(address _account) external view returns (uint256 _numLands, uint256[] memory _landIds) {
        UserInfo memory user = userInfo[_account];
        _numLands = user.landIds.length;
        _landIds = user.landIds;
    }

    function getUserRewardTokenInfo(address _account, address _rewardToken) external view returns (uint256 _rewardDebt, uint256 _reward) {
        UserInfo storage user = userInfo[_account];
        _rewardDebt = user.rewardDebt[_rewardToken];
        _reward = user.reward[_rewardToken];
    }

    function getLandArea(uint256 _landId) public view returns (uint256 landArea) {
        landArea = IDogeLandNFT(stakeNFTToken).getLandArea(_landId);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function addRewardPool(address _rewardToken, uint256 _startBlock) public lock onlyOwner {
        uint256 _length = rewardTokens.length;
        for (uint256 i = 0; i < _length; i++) {
            require(rewardTokens[i] != _rewardToken, "duplicated pool");
        }
        rewardTokens.push(_rewardToken);
        updateAllRewards();
        rewardPoolInfo[_rewardToken] = RewardPoolInfo({rewardToken: _rewardToken, lastRewardBlock: _startBlock, rewardPerBlock: 0, accRewardPerShare: 0, totalPaidRewards: 0, startRewardBlock: _startBlock, endRewardBlock: _startBlock});
    }

    function allocateMoreRewards(
        uint256 _dogeLandAmount,
        uint256 _days
    ) external onlyReserveFund {
        allocateMoreReward(dogeLand, _dogeLandAmount, _days);
    }

    function allocateMoreReward(
        address _rewardToken,
        uint256 _addedReward,
        uint256 _days
    ) public onlyReserveFund {
        updateReward(_rewardToken);
        IERC20(_rewardToken).safeTransferFrom(msg.sender, address(this), _addedReward);
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_rewardToken];
        uint256 _endRewardBlock = rewardPool.endRewardBlock;
        uint256 _pendingBlocks = (_endRewardBlock > block.number) ? _endRewardBlock.sub(block.number) : 0;
        if (_pendingBlocks > 0) {
            uint256 _newPendingReward = rewardPoolInfo[_rewardToken].rewardPerBlock.mul(_pendingBlocks).add(_addedReward);
            uint256 _newPendingBlocks = _pendingBlocks.add(_days.mul(BLOCKS_PER_DAY));
            rewardPool.rewardPerBlock = _newPendingReward.div(_newPendingBlocks);
            rewardPool.endRewardBlock = _endRewardBlock.add(_days.mul(BLOCKS_PER_DAY));
        } else {
            uint256 _newBlocks = _days.mul(BLOCKS_PER_DAY);
            rewardPool.startRewardBlock = block.number;
            rewardPool.endRewardBlock = block.number.add(_newBlocks);
            rewardPool.rewardPerBlock = _addedReward.div(_newBlocks);
        }
    }

    function updateAllRewards() public {
        uint256 _length = rewardTokens.length;
        for (uint256 i = 0; i < _length; i++) {
            updateReward(rewardTokens[i]);
        }
    }

    function updateReward(address _rewardToken) public {
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_rewardToken];
        uint256 _endRewardBlock = rewardPool.endRewardBlock;
        uint256 _endRewardBlockApplicable = block.number > _endRewardBlock ? _endRewardBlock : block.number;
        uint256 _lastRewardBlock = rewardPool.lastRewardBlock;
        if (_endRewardBlockApplicable > _lastRewardBlock) {
            uint256 _lpSupply = stakeLpSupply;
            if (_lpSupply > 0) {
                uint256 _incRewardPerShare = getRewardPerBlock(_rewardToken, _lastRewardBlock, _endRewardBlockApplicable).mul(1e18).div(_lpSupply);
                rewardPool.accRewardPerShare = rewardPool.accRewardPerShare.add(_incRewardPerShare);
            }
            rewardPool.lastRewardBlock = _endRewardBlockApplicable;
        }
    }

    function _addUserLand(address _account, uint256 _landId) internal returns (bool) {
        UserInfo storage user = userInfo[_account];
        user.landIds.push(_landId);
        return true;
    }

    function _removeUserLand(address _account, uint256 _landId) internal returns (bool) {
        UserInfo storage user = userInfo[_account];
        uint256 _numLands = user.landIds.length;
        for (uint256 i = 0; i < _numLands; i++) {
            if (user.landIds[i] == _landId) {
                if (i < _numLands - 1) {
                    user.landIds[i] = user.landIds[_numLands - 1];
                }
                delete user.landIds[_numLands - 1];
                user.landIds.pop();
                return true;
            }
        }
        return false;
    }

    function deposit(uint256 _landId) external lock notContract {
        IDogeLandNFT(stakeNFTToken).transferFrom(msg.sender, address(this), _landId);
        UserInfo storage user = userInfo[msg.sender];
        uint256 _landArea = getLandArea(_landId);
        require(_landArea > 0, "Land has no area");
        stakeLpSupply = stakeLpSupply.add(_landArea);
        getAllRewards(msg.sender);
        user.amount = user.amount.add(_landArea);
        _addUserLand(msg.sender, _landId);
        uint256 _length = rewardTokens.length;
        for (uint256 i = 0; i < _length; i++) {
            address _rtoken = rewardTokens[i];
            user.rewardDebt[_rtoken] = user.amount.mul(rewardPoolInfo[_rtoken].accRewardPerShare).div(1e18);
        }
        emit Deposit(msg.sender, _landId);
    }

    function withdraw(uint256 _landId) external lock notContract {
        UserInfo storage user = userInfo[msg.sender];
        uint256 _landArea = getLandArea(_landId);
        require(_landArea > 0, "Land has no area");
        stakeLpSupply = stakeLpSupply.sub(_landArea);
        getAllRewards(msg.sender);
        user.amount = user.amount.sub(_landArea);
        require(_removeUserLand(msg.sender, _landId), "This Land does not belong to you");
        IDogeLandNFT(stakeNFTToken).transferFrom(address(this), msg.sender, _landId);
        uint256 _length = rewardTokens.length;
        for (uint256 i = 0; i < _length; i++) {
            address _rtoken = rewardTokens[i];
            user.rewardDebt[_rtoken] = user.amount.mul(rewardPoolInfo[_rtoken].accRewardPerShare).div(1e18);
        }
        emit Withdraw(msg.sender, _landId);
    }

    function claimReward() external {
        getAllRewards(msg.sender);
    }

    function getAllRewards(address _account) public onlyOneBlock {
        uint256 _length = rewardTokens.length;
        for (uint256 i = 0; i < _length; i++) {
            getReward(rewardTokens[i], _account);
        }
    }

    function getReward(address _rewardToken, address _account) public notContract {
        updateReward(_rewardToken);
        UserInfo storage user = userInfo[_account];
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_rewardToken];
        uint256 _accRewardPerShare = rewardPool.accRewardPerShare;
        uint256 _pendingReward = user.amount.mul(_accRewardPerShare).div(1e18).sub(user.rewardDebt[_rewardToken]);
        if (_pendingReward > 0) {
            user.rewardDebt[_rewardToken] = user.amount.mul(_accRewardPerShare).div(1e18);
            uint256 _paidAmount = user.reward[_rewardToken].add(_pendingReward);
            // Safe reward transfer, just in case if rounding error causes pool to not have enough reward amount
            uint256 _rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
            if (_rewardBalance < _paidAmount) {
                user.reward[_rewardToken] = _paidAmount; // pending, dont claim yet
            } else {
                user.reward[_rewardToken] = 0;
                rewardPool.totalPaidRewards = rewardPool.totalPaidRewards.add(_paidAmount);
                _safeTokenTransfer(_rewardToken, _account, _paidAmount);
                emit RewardPaid(_rewardToken, _account, _paidAmount);
            }
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external lock {
        UserInfo storage user = userInfo[msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        uint256 _length = rewardTokens.length;
        for (uint256 i = 0; i < _length; i++) {
            address _rtoken = rewardTokens[i];
            user.rewardDebt[_rtoken] = 0;
            user.rewardDebt[_rtoken] = 0;
        }
        user.rewardDebt[dogeLand] = 0;
        user.reward[dogeLand] = 0;
        IERC20(stakeNFTToken).safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _amount);
    }

    function _safeTokenTransfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        uint256 _tokenBal = IERC20(_token).balanceOf(address(this));
        if (_amount > _tokenBal) {
            _amount = _tokenBal;
        }
        if (_amount > 0) {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    // This function allows governance to take unsupported tokens out of the contract. This is in an effort to make someone whole, should they seriously mess up.
    // There is no guarantee governance will vote to return these. It also allows for removal of airdropped tokens.
    function governanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address to
    ) external onlyOwner {
        require(_token != stakeNFTToken, "NFT");
        IERC20(_token).safeTransfer(to, _amount);
    }
}