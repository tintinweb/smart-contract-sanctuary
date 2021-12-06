/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

// File: @openzeppelin\contracts\math\SafeMath.sol

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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

// File: @openzeppelin\contracts\utils\ReentrancyGuard.sol

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

    constructor() internal {
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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}



// File: node_modules\@openzeppelin\contracts\introspection\IERC165.solhint
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

// File: @openzeppelin\contracts\token\ERC721\IERC721.sol

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    ); 

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

// File: @openzeppelin\contracts\token\ERC721\IERC721Enumerable.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts\interfaces\ICoterieERC721.sol

interface ICoterieERC721 {
    function referredBy(address) external returns (address);

    function isMinter(address) external returns (bool);
}

library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

interface IERC721Metadata is IERC721 {
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

// File: contracts\interfaces\IERC721MarketPlace.sol

pragma solidity >=0.6.12;

interface IERC721MarketPlace {
    struct PaymentsTo {
        address payable to;
        uint256 percent;
    }

    struct Auction {
        address payable owner;
        address token;
        address buyer;
        uint256 tokenId;
        uint256 basePrice;
        // uint256 lastBidVal;
        address paymentMethod; // address(0) for eth/bnb and contract address for ERC20 token
        uint256 createdAt;
        uint256 id;
        Status status;
        uint256 closedAt;
    }
    
    struct Bid{
        uint256 currentBid;
        address bidder;
        uint256 createdAt;
    }

    enum Status {
        OPEN,
        CANCELLED,
        SOLD
    }

    function createAuction(
        PaymentsTo[] calldata paymentsTo,
        address _token,
        uint256 _tokenId,
        uint256 _basePrice,
        address paymentMethod
    ) external;

    function makeBid(uint256 _id, uint256 bidValue) external payable;

    function cancelAuction(uint256 _auctionId) external returns (bool);

    function closeAuction(uint256 _auctionId) external returns (bool);

   function updateBasePriceAndPaymentMethod(uint256 _auctionId, uint256 _newBasePrice, address newPaymentMtd)
        external returns(bool);
        


    

    event AuctionCreated(
        address owner,
        uint256 id,
        address token,
        uint256 tokenId,
        uint256 _basePrice,
        address paymentMethod
    );
    event Cancelled(uint256 id, address token, uint256 _tokenId);
    event UpdatePayTo(uint256 auctionId, address to, uint256 share);
    event BidMade(
        address bidder,
        uint256 id,
        address token,
        uint256 tokenId,
        uint256 bidValue,
        uint256 newClosing
    );
    event OutBid(address lBidder, uint256 auctionId, uint256 lValue, address paymentMethod);
    event Executed(
        uint256 auctionId,
        address token,
        uint256 tokenId,
        uint256 ownerPayment,
        uint256 total,
        uint256 closingValue
    );
    event PriceAndPaymentMethodUpdated(uint256 auctionId, uint256 basePrice, address paymentMethod);
    event AdminCancelAuction(address admin, uint256 auctionId);

    event OwnersPayment(uint256 id, address to, uint256 value);
     event ServiceFees(address vault, uint256 auctionId, address paymtMethod, uint256 serviceAndRef);
    event RoyaltyPaid(
        uint256 auctionId,
        address to,
        uint256 value,
        address paymentMethod
    );
    event ReferralDue(
        uint256 auctionId,
        address to,
        uint256 value,
        address paymentMethod
    );

    event OwnerChangedAddress(
        uint256 auctionId,
        address oldAddress,
        address newAddress
    );
    event AdminTransferred(
        address indexed previousAdmin,
        address indexed newOwner
    );
    
}


interface IRegistry is IERC165 {
    event RoyaltyOverride(
        address owner,
        address tokenAddress,
        address royaltyAddress
    );

    /**
     * Get the royalty for a given token (address, id) and value amount.  Never cache the result, as the recipients and values can change.
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        external
        view
        returns (address payable[] memory recipients, uint256[] memory amounts);

    /**
     * Override the location of where to look up royalty information for a given token contract.
     * Allows for backwards compatibility and implementation of royalty logic for contracts that did not previously support them.
     *
     * @param tokenAddress    - The token address you wish to override
     * @param royaltyAddress  - The royalty override address
     */
    function overrideAddress(address tokenAddress, address royaltyAddress)
        external;
}

abstract contract MarketStorage is IERC721MarketPlace{
    using Counters for Counters.Counter;

    mapping(uint256 => Auction) public getAuction; // get auction by ID

    mapping(address => bool) public isSupportedPaymentMethod; // Coterie native tokens
    mapping(address => bool) public isMinter; // mappiing for authorized minter
    mapping(address => mapping(address => uint256)) public getRefBonusPaidCount; // this can be used to fetch number of referral bonus paid
    mapping(uint256 => address) public getRef; // get ref address from auction Id it calls to the CoterieERC721 contract to fetch the content creator referredBy
    mapping(uint256 => PaymentsTo[4]) public payTo; // mapping auction ID to paymentTos
    mapping(uint256 => Bid[]) internal  getBids; // mapping auction ID to Bid array
    mapping(address=> bool) public isCoterieERC721; // mapping for coterie NFTs
    mapping(address=> uint256) internal withdrawable; 
    uint256[] internal auctionIds; // auction IDs
    address[] internal supportedPaymentMethods; //supported payment methods
    address [] public coterieERC721s; //CoterieNFTs addresses

    uint256 public constant bidWindow = 24 hours; // 24 hours open period after the first bid
    uint256 public constant bidExtension = 20 minutes; // extension period for late bids
    uint256 public constant refBonus = 5; // 0.5% ref bonus for minter referrers
    uint256 public constant refBonusLimit = 5; // maximum ref bonus that can be earned per minter referred

    
    Counters.Counter internal _auctionIds; // Counter
   
    IRegistry public ROYALTY_REGISTRY; // royalty registry variable
    
    address payable public platformVault; // for platform fees
    address payable public minterVault;
    


    uint256 public platformCut = 25; // 2.5% platform fees
  
    uint256 public increaseBidFactor = 10; // minimum percentage required to outbid existing bid
}

abstract contract Ownable  is Context{


    uint256 public constant delay = 172_800; // delay for admin change
    address private admin;
    address public pendingAdmin; // pending admin variable
    uint256 public changeAdminDelay; // admin change delay variable

    event ChangeAdmin(address sender, address newOwner);
    event RejectPendingAdmin(address sender, address newOwner);
    event AcceptPendingAdmin(address sender, address newOwner);

    function onlyOwner() internal view {
        require(_msgSender() == admin, "Ownable: caller is not the owner");
        
    }

    constructor () internal {
        admin = _msgSender();
    }

    function changeAdmin(address _admin) external  {
    onlyOwner();
        pendingAdmin = _admin;
        changeAdminDelay = block.timestamp + delay;
        emit ChangeAdmin(_msgSender(), pendingAdmin);
    }

    function rejectPendingAdmin() external  {
        onlyOwner();
        if (pendingAdmin != address(0)) {
            pendingAdmin = address(0);
            changeAdminDelay = 0;
        }
        emit RejectPendingAdmin(_msgSender(), pendingAdmin);
    }

    function owner () external  view returns (address){
        return admin;
    }

    function acceptPendingAdmin() external    {
        onlyOwner();
        if (changeAdminDelay > 0 && pendingAdmin != address(0)) {
            require(
               block.timestamp > changeAdminDelay,
                "CoterieMarket: owner apply too early"
            );
            admin = pendingAdmin;
            changeAdminDelay = 0;
            pendingAdmin = address(0);
        }
        emit AcceptPendingAdmin(_msgSender(), admin);
    }
}


abstract contract Pausable is Ownable {

    bool private _paused = false; // state variable to check paused state

    function whenNotPaused() internal view {
        require(_paused == false, "CoterieMarket: only_when_not_paused");
        
    }

     function pause() public virtual  {
         onlyOwner();
        _paused = true;
    }

    function unpause() public virtual  {
        onlyOwner();
        _paused = false;
    }

    function paused () external view virtual returns(bool){
        return _paused;
    }

}

abstract contract Utils is MarketStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

   function ERC20TransferHelper(
        address token,
        address to,
        uint256 amount
    ) internal {
        IERC20(token).safeTransfer(to, amount);
    }

    function EthTransferHelper(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "ETH_transfer_failed");
    }


    function notAddressZero(address addr) internal pure {
        require(addr != address(0), "address_zero");
    }


    function getPercent(uint256 val, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        return val.mul(percentage).div(100);
    }

    function getFractionPercent(uint256 amount, uint256 fraction)
        internal
        pure
        returns (uint256)
    {
        return amount.mul(fraction).div(1000);
    }
    
     function _blocktime() internal view returns (uint256) {
        return block.timestamp;
    }


     /* 
     * @dev Coterie Market place support collaborative listing 
     * this function encsures all the conditions are satisfied
     * with a percentage share of 0.1 
     * not more than 4 collaborators 
     * 
     */

    function validatePayTo(PaymentsTo[] memory _payTo)
        internal
        pure
        returns (bool)
    {
        require(_payTo.length <= 4, "CoterieMarket: invalid payto length");
        uint256 total;
        for (uint256 i; i < _payTo.length; i++) {
            total += _payTo[i].percent;
        }
        return total == 1000;
    }
    

}

abstract contract AdminCalls is Pausable, Utils {

     function addSupportedpaymentMethods(address[] calldata _tokens)
        external
        
    {
        onlyOwner();
        for (uint256 i = 0; i < _tokens.length; i++) {
            notAddressZero(_tokens[i]);
            supportedPaymentMethods.push(_tokens[i]);
            isSupportedPaymentMethod[_tokens[i]] = true;
        }
    }

    function removePaymentMethod(address _token) external {
          onlyOwner();
          notAddressZero(_token);
          isSupportedPaymentMethod[_token] = false;
    }

    function addCoterieERC721(address ERC721Token) external  {
        onlyOwner();
        whenNotPaused();
        notAddressZero(ERC721Token);
        isCoterieERC721[ERC721Token] = true;
        coterieERC721s.push(ERC721Token);
    }
    
    function removeCoterieERC721(address ERC721Token) external  {
        onlyOwner();
        whenNotPaused();
        notAddressZero(ERC721Token);
        isCoterieERC721[ERC721Token] = false;
    }

    function updatePlatformCut(uint256 newCut) external {
        onlyOwner();
        whenNotPaused();
        platformCut = newCut;
    }
  

    function withdraw(address token) external {
        onlyOwner();
        uint256 availabeBal = withdrawable[token];
        withdrawable[token] = 0;
        if(availabeBal > 0 ){
            if(token == address(0)){
                EthTransferHelper(platformVault, availabeBal);
            }else {
                ERC20TransferHelper(token, platformVault, availabeBal);
            }
        }
        
    }

    function getWithdrawable(address token) external view returns(uint256){
        return withdrawable[token];
    }

    function updatePlatformVault(address payable feesReceiver) external{
        onlyOwner();
         whenNotPaused();
         notAddressZero(feesReceiver);
        platformVault = feesReceiver;
    }

    function updateMinterVault(address payable refReceiver) external{
        onlyOwner();
        whenNotPaused();
        notAddressZero(refReceiver);
        minterVault = refReceiver;
    }

    

     function adminCancelAuction(uint256 auctionId) external  {
        onlyOwner();
        pause();
        Auction storage auction = getAuction[auctionId];
        Bid [] storage bids = getBids[auctionId];
       
        auction.status = Status.CANCELLED;

        if(bids.length > 0){

            Bid storage latestBid = bids[bids.length - 1];
            if (auction.closedAt != 0 && latestBid.currentBid != 0) {
                if (auction.paymentMethod != address(0)) {
                    ERC20TransferHelper(
                        auction.paymentMethod,
                        latestBid.bidder,
                        latestBid.currentBid
                    );
                } else EthTransferHelper(latestBid.bidder, latestBid.currentBid);
           
            }
        }
       
        IERC721 _token = IERC721(auction.token);
        _token.safeTransferFrom(address(this), auction.owner, auction.tokenId);
        unpause();
        emit AdminCancelAuction(_msgSender(), auctionId);
    }


        /****************************** only admin Restricted Functions **************************************/
    
    function updateIncreaseBidFactor(uint256 factor) external 
    {
        onlyOwner();
        require(factor > 0, "factor can not be 0");
        increaseBidFactor = factor;
    }

    function addRoyaltyRegistry(address royaltyRegisty) external  {
        onlyOwner();
        notAddressZero(royaltyRegisty);
        ROYALTY_REGISTRY = IRegistry(royaltyRegisty);
    }

  
}



pragma experimental ABIEncoderV2;

// import "@openzeppelin/contracts/utils/Pausable.sol";

contract ERC721Marketplace is ReentrancyGuard, AdminCalls {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

     bytes4 private constant _ERC721_RECEIVED = 0x150b7a02; // inter-operability interface for ERC721

     function onlyAuctionOwner(uint256 auctionId) private view{
        Auction storage auction = getAuction[auctionId];
        require(
            _msgSender() == auction.owner,
            "CoterieMarket: only_auction_owner"
        );
        
    }

    function onlyBeforeBid(uint256 auctionId) internal view {
        Bid [] storage bids = getBids[auctionId];
        require(
            bids.length == 0 ,
            "CoterieMarket: only_before_first_bid"
        );
        
    }
    
     

    constructor(address payable vault) public {
        isSupportedPaymentMethod[address(0)] = true;
        platformVault = vault;
        
        emit AdminTransferred(address(0), _msgSender());
    }
    
       
   
    /*********************** Auction Functions  ************************/
    function createAuction(
        PaymentsTo[] memory paymentsTo,
        address _token,
        uint256 _tokenId,
        uint256 _basePrice,
        address _paymentMethod
    ) external override  {
     whenNotPaused();
        IERC721 token = IERC721(_token);
        
        // assert payto requirements
        require(
            validatePayTo(paymentsTo),
            "CoterieMarket: invalid payment distribution"
        );
        // assert payment method is supported
        require(
            isSupportedPaymentMethod[_paymentMethod],
            "CoterieMarket: only supported payment methods"
        );
        
        token.safeTransferFrom(_msgSender(), address(this), _tokenId);
        // assert the deposit was successful
        require(
            token.ownerOf(_tokenId) == address(this),
            "CoterieMarket: Transfer Failed"
        );
        // create auction struct
        _auctionIds.increment();
        Auction memory auction = Auction({
             id: _auctionIds.current(),
             token: _token,
             tokenId: _tokenId,
             basePrice: _basePrice,
             paymentMethod: _paymentMethod,
             closedAt: 0,
             createdAt: _blocktime(),
             owner: _msgSender(),
             status: Status.OPEN,
             buyer: address(0)
             
        });
         // push auction id to the array of auction id
        auctionIds.push(auction.id);
       
        // map auction to an Id
        getAuction[auction.id] = auction;
        // update the paytos
         _updatePayTo(auction.id, paymentsTo);


        // if token is Coterie native token get the minter and the referredBy
        if (
            isCoterieERC721[_token] 
        ) {
            if(ICoterieERC721(_token).isMinter(_msgSender())){
                isMinter[_msgSender()] = true;
                getRef[auction.id] = ICoterieERC721(_token).referredBy(auction.owner);
                
            }
        }

        // emit auction created event
        emit AuctionCreated(
            _msgSender(),
            auction.id,
            auction.token,
            auction.tokenId,
            auction.basePrice,
            _paymentMethod
        );
    }
    // event UpdatePayTo(uint256 auctionId, address to, uint256 share);

    // setter function to set the pay to for a particular auction
    
    function _updatePayTo(uint256 auctionId, PaymentsTo[] memory paymentsTo) internal {
        
        for (uint256 i = 0; i < paymentsTo.length; i++) {
            // payTo[auctionId].push(paymentsTo[i]);
            payTo[auctionId][i] = paymentsTo[i];
            emit UpdatePayTo(auctionId, paymentsTo[i].to, paymentsTo[i].percent);
        }
        
        
    }

    /* 
    allow auction owner to modify the payTo 
    modifier{
        onlyAuctionOwner: assert caller is the auction owner

    }
    params: {
        auctionId: the auction ID
        paymentsTo: PaymentsTo struct array
    }
    calls internal function _updatePayTo
     */
    
    function updatePayTo(uint256 auctionId, PaymentsTo[]memory paymentsTo) external {
        onlyAuctionOwner(auctionId);
        validatePayTo(paymentsTo);
        _updatePayTo(auctionId, paymentsTo);
    }
    /* 
    * params:{
        _id: auction ID
        bidValue: the bid amount in uint256
    }
    Slither may yell for reentracy but it's pre-handled with the modifier
    modifiers: {
        whenNotPaused: assert auction is not paused
        nonReentrant: assert no reentrance
    }

     */
     function makeBid(uint256 _id, uint256 bidValue)
        external
        payable
        override
        
        nonReentrant
    {
         whenNotPaused();
        Auction storage _auction = getAuction[_id];
        Bid[] storage bids = getBids[_id];



        uint256 msgValue = _auction.paymentMethod == address(0)? msg.value : bidValue;
        // create a new bid struct
        Bid memory bid = Bid({
            createdAt: _blocktime(),
            currentBid: msgValue,
            bidder: _msgSender()
            
        });
        
    // if it is the first bid
        if (bids.length == 0 && _auction.closedAt == 0) {
            
            _auction.closedAt = _blocktime().add(bidWindow);
            
            if (_auction.paymentMethod == address(0)) {
                // assert value is greater than or equal the minimum bid value
                require(
                    msgValue >= _auction.basePrice,
                    "CoterieMarket: Bid_value_must_be_>=current_bid_value"
                );
                getBids[_id].push(bid);
            } else if (_auction.paymentMethod != address(0)) {
                require(
                    msgValue >= _auction.basePrice,
                    "CoterieMarket: Bid_value_must_be_>=current_bid_value"
                );
                getBids[_id].push(bid);
                // withdraw token from bidder
                IERC20(_auction.paymentMethod).safeTransferFrom(
                    _msgSender(),
                    address(this),
                    bidValue
                );
            }
            // set closing time for the auction
            
            // if it is not the first bid
        } else if (bids.length != 0 && _auction.closedAt != 0) {
            // activeBid = bids[bids.length - 1];
            Bid storage lastBid = bids[bids.length -1];
             if (
                _auction.closedAt > 0 &&
                _auction.closedAt.sub(_blocktime()) <= bidExtension &&
                _auction.closedAt.sub(_blocktime()) >= 1
            ) {
                _auction.closedAt = _auction.closedAt.add(bidExtension);
            }
            if (_auction.paymentMethod == address(0)) {
                require(
                    msgValue >=
                        lastBid.currentBid.add(
                            getPercent(lastBid.currentBid, increaseBidFactor)
                        ),
                    "CoterieMarket: Bid_value_must_be_>current_bid_value"
                ); 
                getBids[_id].push(bid);

                // refund previous bidder and emit Outbid
                EthTransferHelper(lastBid.bidder, lastBid.currentBid);
                emit  OutBid(lastBid.bidder, _id, lastBid.currentBid, address(0));
                
            } else {
                require(
                    msgValue >=
                        lastBid.currentBid.add(
                            getPercent(lastBid.currentBid, increaseBidFactor)
                        ),
                    "CoterieMarket: Bid_value_must_be_>current_bid_value"
                );
                getBids[_id].push(bid);
                IERC20(_auction.paymentMethod).safeTransferFrom(
                    _msgSender(),
                    address(this),
                    msgValue
                );
                  // refund previous bidder and emit Outbid
                IERC20(_auction.paymentMethod).safeTransfer(
                    lastBid.bidder,
                    lastBid.currentBid
                );
                
                emit  OutBid(lastBid.bidder, _id, lastBid.currentBid, _auction.paymentMethod);
            }
            // check for extension 
           
        }
        
        
// emit bid made
        emit BidMade(
            _msgSender(),
            _auction.id,
            _auction.token,
            _auction.tokenId,
            msgValue,
            _auction.closedAt
        );
    }

    
   
    /* 
    * allow auction owner to cancel auction 
    * modifiers {
        whenNotPaused: ensure the auction is not paused
        onlyAuctionOwner: assert the caller is the auction owner
        onlyBeforeBid: ensure the auction has not received any bid
        returns bool
        emitd Cancelled
    }
     */
    function cancelAuction(uint256 _auctionId)
        external
        override
        
        
        returns (bool)
    {   
        onlyBeforeBid(_auctionId);
         whenNotPaused();
        onlyAuctionOwner(_auctionId);
        Auction storage _auction = getAuction[_auctionId];
        _auction.status = Status.CANCELLED;

        IERC721(_auction.token).safeTransferFrom(
            address(this),
            _auction.owner,
            _auction.tokenId
        );


        emit Cancelled(_auctionId, _auction.token, _auction.tokenId);
        return true;
    }


  
    /* 
    * The function called to release funds to the auction owner and token to the highest bidder
    * note: slither may yell for reentrance it is already handled with the noReentrant modifier
    * modifiers{
        whenNotPaused: for security check
        nonReentrant: reentrancy check
    }
    params {
        _auctionId: the ID of the auction to close
    }
    returns true
     */
    function closeAuction(uint256 _auctionId)
        public
        override
        
        nonReentrant
        returns (bool)
    {
         whenNotPaused();
        Auction storage auction = getAuction[_auctionId];
        Bid [] storage bids = getBids[_auctionId];
        if(bids.length >0){

        Bid storage lastBid = bids[bids.length -1];
        // check if the caller is the auction owner or the highest bidder
        require(
            _msgSender() == auction.owner ||
                _msgSender() == lastBid.bidder,
            "CoterieMarket: only_auction_owner_and_lastBidder"
        );
        // check if the auction bid 
        require(
            lastBid.currentBid >= auction.basePrice,
            "CoterieMarket: close_sale_by_cancel_auction"
        );
        // check if the auction can be closed
        require(
            _blocktime() >= auction.closedAt,
            "CoterieMarket: Auction_not_closed"
        );
        auction.buyer = lastBid.bidder;
        auction.status = Status.SOLD;
        
        // get the platform deduction from the bid value
        (uint256 pfmCut, uint256 refCut, uint256 platformAndRefBonus) = getPlatformCut(
            _auctionId,
            auction.owner,
           lastBid.currentBid
        );
        withdrawable[auction.paymentMethod] = withdrawable[auction.paymentMethod].add(pfmCut);
        emit ServiceFees(platformVault, _auctionId, auction.paymentMethod, pfmCut);
        // if payment method is native coin (BNB or ETH or FTM)
        if (auction.paymentMethod == address(0)) {
            
            if (refCut > 0) {
                
                // EthTransferHelper(getRef[auction.id], refCut);
                // We increase the amount of ref claimed and make withdrawable for multichain purpose
                
                getRefBonusPaidCount[getRef[auction.id]][auction.owner]++;
                getRefBonusPaidCount[auction.owner][getRef[auction.id]]++;
                EthTransferHelper(minterVault, refCut);
                emit ReferralDue(
                    _auctionId,
                    getRef[auction.id],
                    refCut,
                    auction.paymentMethod
                );
            }
            // Transfer total to platform vault, ref bonus will be claimable 
            // emit ServiceFees(platformVault, _auctionId, auction.paymentMethod, pfmCut);

           // if payment method is an ERC 20
        } else {
            if (refCut > 0) {
                
                // We increase the amount of ref claimed and make withdrawable for multichain purpose
                // ERC20TransferHelper(
                //     auction.paymentMethod,
                //     getRef[auction.id],
                //     refCut
                // );
                
                getRefBonusPaidCount[getRef[auction.id]][auction.owner]++;
                getRefBonusPaidCount[auction.owner][getRef[auction.id]]++;
                 ERC20TransferHelper(
                auction.paymentMethod,
                minterVault,
                refCut
            );
                emit ReferralDue(
                    _auctionId,
                    getRef[auction.id],
                    refCut,
                    auction.paymentMethod
                );
            }

            
        }
            
        // pay royalty
        processRoyaltyPayments(
            auction.id,
            auction.token,
            auction.tokenId,
            lastBid.currentBid,
            auction.paymentMethod
        );
        uint256 ownerPayment = getOwnerPayment(
            auction.token,
            auction.tokenId,
            lastBid.currentBid
        );

        

        // pay owner(s)
        paymentSpliter(_auctionId, auction.paymentMethod, ownerPayment);
        // transfer token to highest/last bidder
        IERC721 _token = IERC721(auction.token);
        _token.safeTransferFrom(
            address(this),
            lastBid.bidder,
            auction.tokenId
        );
        
        // emit Executed event
        emit Executed(
            auction.id,
            auction.token,
            auction.tokenId,
            ownerPayment,
            platformAndRefBonus,
            lastBid.currentBid
        );
        return true;
        }
    }
    
    /* 
    allow the auction owner to change auction basePrice and/or paymentMethod before the first bid
    onlyAuctionOwner: assert caller is the owner of the auction
    onlyBeforeBid: assert function call is before the first bid
    params:{
        _auctionId:  the auction ID
        _newBasePrice: the new minimum value acceptable for this auction
        newPaymentMtd: the new payment method (ERC tokens or native coin)
    } 

    emits PriceAndPaymentMethodUpdated
    returns true

     */
    
    
    function updateBasePriceAndPaymentMethod(uint256 _auctionId, 
    uint256 _newBasePrice, address newPaymentMtd)
        external    
        override
        returns (bool)
    {
        onlyBeforeBid(_auctionId);
        whenNotPaused();
        onlyAuctionOwner(_auctionId);
        Auction storage _auction = getAuction[_auctionId];
        _auction.basePrice = _newBasePrice;
        _auction.paymentMethod = newPaymentMtd;
        emit PriceAndPaymentMethodUpdated(_auction.id, _newBasePrice, newPaymentMtd);
        return true;
    }

    

    /* 
    * state mutating function
    * allow auction owner to change his wallet address in case of hack/ wallet compromise
    *onlyAuctionOwner:  modifier function for access management
    * params: {
        auctionId: auction ID in uint256
        newOwner: new address for the auction owner
    } 
    emits event OwnerChangedAddress
    */
    function changeAuctionOwnerAddress(
        uint256 auctionId,
        address payable newOwner
    ) external  {
    onlyAuctionOwner(auctionId);
        Auction storage auction = getAuction[auctionId];
        address oldAddress = auction.owner;
        auction.owner = newOwner;
        emit OwnerChangedAddress(auctionId, oldAddress, newOwner);
    }

     /*********************** Payment Helper Functions  ************************/
    /* 
    * getter function to determine the total amount to be paid to the auction owner
    * token: token contract address
    * tokenId: token ID
    * currentBidValue: the bid value when this function is called
    * returns payment, the amount  to be splitted between collaborators (every auction is assumed a collaborative auction)
     */
    function getOwnerPayment(
        address token,
        uint256 tokenId,
        uint256 currentBidValue
    ) public view returns (uint256 payment) {
        uint256 _platformCut = getFractionPercent(currentBidValue, platformCut);
        (, , uint256 total) = viewRoyaltyPayments(
            token,
            tokenId,
            currentBidValue
        );
        payment = currentBidValue.sub(total).sub(_platformCut);
        return payment;
    }

    
    /* 
    * _auctionId: the auction ID
    * auctionOwner: the address of the auction creator
    * currentBidValue: the current bid worth when this function is called
    * returns{
        cutValue: the actual worth of platform share
        refCut: if the auction creator is an authorized minter, 0.5% of this auction goes to the existing minter who gave him access 
        _total: the sum of cutValue and refCut
    }
    */
    function getPlatformCut(
        uint256 _auctionId,
        address auctionOwner,
        uint256 currentBidValue
    )
        public
        view
        returns (
            uint256 cutValue,
            uint256 refCut,
            uint256 _total
        )
    {
        uint256 amount = currentBidValue;
        uint256 refCount = getRefBonusPaidCount[getRef[_auctionId]][
            auctionOwner
        ];

        if (isMinter[auctionOwner] && refCount < refBonusLimit) {
            refCut = getFractionPercent(amount, refBonus);
            cutValue = getFractionPercent(amount, platformCut).sub(refCut);
        } else {
            cutValue = getFractionPercent(amount, platformCut);
        }
        _total = cutValue.add(refCut);
        return (cutValue, refCut, _total);
    }
    
    /* 
    * helper function to check royalty value
    * royalty value is precalculated in the royalty registry contract. see RoyaltyRegistry.sol 
    * auctionToken:  is the ERC721 contract address
    * auctionTokenId: is the TokenId 
    * currentBidValue: is the bid value when this function is called
    * returns:{
        * recipients: addresses of royalty receivers
        * amounts: royalty share for each address, sorted
        * total: the amount of royalty to be deducted fro auction owner's earning
    }
     */
    function viewRoyaltyPayments(
        address auctionToken,
        uint256 auctionTokenId,
        uint256 currentBidValue
    )
        public
        view
        returns (
            address payable[] memory recipients,
            uint256[] memory amounts,
            uint256 total
        )
    {
        (recipients, amounts) = ROYALTY_REGISTRY.getRoyalty(
            auctionToken,
            auctionTokenId,
            currentBidValue
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            total = total.add(amounts[i]);
        }
        return (recipients, amounts, total);
    }
    
    // distribute payment to collaborators
    /* id: auction ID
    * paymentMtd: is the payment method
    * value: is the selling price of the auction -(platform fees + royalty token royalty)
    * process payment according to the payment to the owner's preference (native coins or ERC20 tokens)
    *
     */
    function paymentSpliter(
        uint256 id,
        address paymentMtd,
        uint256 value
    ) internal {
        uint256 totalVal = value;
        // array length is capped at 4
        if (value > 0){
            for (uint256 i = 0; i < payTo[id].length; i++) {
                uint256 val = 0;
                if (i < payTo[id].length - 1) {
                    val = getFractionPercent(value, payTo[id][i].percent);
                    totalVal = totalVal.sub(val);
                } else {
                    val = totalVal;
                }
                if (paymentMtd == address(0) && payTo[id][i].to != address(0)) {
                    EthTransferHelper(payTo[id][i].to, val);
                    emit OwnersPayment(id, payTo[id][i].to, val);
                } else if (paymentMtd != address(0) && payTo[id][i].to != address(0)) {
                    ERC20TransferHelper(paymentMtd, payTo[id][i].to, val);
                    emit OwnersPayment(id, payTo[id][i].to, val);
                }
            }
        }
    }
    

    /* 
    * @dev handles royalty payment distribution. please se the royalty registy file
    *  auctionId: the auction ID
    * auctionToken: the token contract address
    * auctionTokenId: the tokenId to pay roayalty for
    * currentBidValue: is the closing/present value for the auction
    * the paymentMethod: is the token address for payment, address(0) for native coins and token address for usdt, busd, etc
     */
     function processRoyaltyPayments(
        uint256 auctionId,
        address auctionToken,
        uint256 auctionTokenId,
        uint256 currentBidValue,
        address paymentMethod
    ) internal {
        (
            address payable[] memory recipients,
            uint256[] memory amounts,

        ) = viewRoyaltyPayments(auctionToken, auctionTokenId, currentBidValue);
        if(recipients.length > 0  && amounts.length > 0)
        for (uint256 i = 0; i < recipients.length; i++) {
            if (paymentMethod == address(0)) {
                EthTransferHelper(recipients[i], amounts[i]);
            } else {
                ERC20TransferHelper(paymentMethod, recipients[i], amounts[i]);
            }

            emit RoyaltyPaid(
                auctionId,
                recipients[i],
                amounts[i],
                paymentMethod
            );
        }
    }
    
     /*********************** Utils Functions  ************************/

 
    
    
    

    
    

 
    /*********************** View Functions  ************************/
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return _ERC721_RECEIVED;
    }
    
    function getAuctionBids (uint256 auctionId) external view returns(Bid[] memory){
        return getBids[auctionId];
    }

    function getPaymentTo(uint256 auctionId)
        external
        view
        returns (PaymentsTo[4] memory)
    {
        return payTo[auctionId];
    }
    
    

    function getAuctionIds() external view returns (uint256[] memory) {
        return auctionIds;
    }

}