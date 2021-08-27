/**
 *Submitted for verification at polygonscan.com on 2021-08-27
*/

// File: @openzeppelin/contracts/introspection/ERC165Checker.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.2 <0.8.0;

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

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
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
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
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
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
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
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    /**
     * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return success true if the STATICCALL succeeded, false otherwise
     * @return result true if the STATICCALL succeeded and the contract at account
     * indicates support of the interface with identifier interfaceId, false otherwise
     */
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool, bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return (false, false);
        return (success, abi.decode(result, (bool)));
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity >=0.6.2 <0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity >=0.6.0 <0.8.0;




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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity >=0.6.2 <0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721Holder.sol



pragma solidity >=0.6.0 <0.8.0;


  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol



pragma solidity >=0.6.2 <0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * _Available since v3.1._
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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

// File: @openzeppelin/contracts/introspection/ERC165.sol



pragma solidity >=0.6.0 <0.8.0;


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

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
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

// File: @openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol



pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// File: @openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol



pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// File: contracts/marketplace/AuctionItemManager.sol

pragma solidity ^0.6.0;





contract AuctionItemManager is Ownable, ReentrancyGuard {
    struct AuctionItem {
        uint256 tokenId;
        address contractAddress;
        address sellerAddress;
        address currentBidder;
        IERC20 paymentToken;
        uint256 auctionPrice;
        uint256 auctionStartTime;
        uint256 auctionDurationDays;
        uint256 index;
    }

    struct AuctionItemsByContractAddress {
        address contractAddress;
        bytes32[] auctionItemIndex;
        mapping(bytes32 => uint256) auctionItemIndexMapping;
    }

    mapping(address => AuctionItemsByContractAddress) private auctionItemsByContract;

    mapping(bytes32 => AuctionItem) private auctionItems;
    bytes32[] private auctionItemIndex;

    event AuctionItemInserted(
        uint256 indexed tokenId,
        address contractAddress,
        uint256 price,
        uint256 auctionStartTime,
        uint256 auctionEndTime,
        bytes32 indexed id
    );
    event AuctionItemDeleted(uint256 indexed tokenId, address contractAddress, bytes32 indexed saleId);
    event AuctionItemPriceUpdated(bytes32 indexed id, uint256 oldPrice, uint256 newPrice, address bidder);

    /** @dev Checks if item for id exists
     * @param auctionItemId item id to check exists in the list of items
     */
    modifier onlyItemsOnAuction(bytes32 auctionItemId) {
        require(
            (auctionItemIndex[auctionItems[auctionItemId].index] == auctionItemId),
            "Id does not match any listing"
        );
        _;
    }

    constructor() public {}

    function itemIsOnAuction(bytes32 auctionItemId) public view returns (bool) {
        if (auctionItemIndex.length == 0) return false;
        return (auctionItemIndex[auctionItems[auctionItemId].index] == auctionItemId);
    }

    function insertAuctionItem(
        bytes32 auctionItemId,
        address tokenOwner,
        address tokenContractAddress,
        uint256 tokenId,
        uint256 startPriceInWei,
        uint256 auctionStartUnixEpoch,
        uint256 auctionDurationDays,
        IERC20 paymentToken
    ) public nonReentrant onlyOwner returns (uint256) {
        // require token is not already listed
        require(!itemIsOnAuction(auctionItemId), "Item is already on sale");

        // update sale index list
        auctionItemIndex.push(auctionItemId);
        uint256 _index = auctionItemIndex.length - 1;

        // add sale item to internal list
        AuctionItem memory _auctionItem = AuctionItem(
            tokenId,
            tokenContractAddress,
            tokenOwner,
            address(0),
            paymentToken,
            startPriceInWei,
            auctionStartUnixEpoch,
            auctionDurationDays,
            _index
        );

        // push the sale item to the mapping
        auctionItems[auctionItemId] = _auctionItem;

        insertAuctionItemToAuctionItemsByContract(auctionItemId, tokenContractAddress);

        //fire the event to say its inserted
        emit AuctionItemInserted(
            tokenId,
            tokenContractAddress,
            startPriceInWei,
            auctionStartUnixEpoch,
            auctionStartUnixEpoch + (auctionDurationDays * 1 days),
            auctionItemId
        );

        return _index;
    }

    function deleteAuctionItem(bytes32 auctionItemId)
        public
        nonReentrant
        onlyOwner
        onlyItemsOnAuction(auctionItemId)
        returns (uint256)
    {
        uint256 rowToDelete = auctionItems[auctionItemId].index;

        uint256 tokenId = auctionItems[auctionItemId].tokenId;
        address contractAddress = auctionItems[auctionItemId].contractAddress;

        bytes32 keyToMove = auctionItemIndex[auctionItemIndex.length - 1];
        auctionItemIndex[rowToDelete] = keyToMove;
        auctionItems[keyToMove].index = rowToDelete;
        auctionItemIndex.pop();
        removeAuctionItemFromAuctionItemsByContract(auctionItemId, contractAddress);
        emit AuctionItemDeleted(tokenId, contractAddress, auctionItemId);
        delete auctionItems[auctionItemId];
        return rowToDelete;
    }

    function updateAuctionItemPrice(
        bytes32 auctionItemId,
        uint256 priceInWei,
        address bidder
    ) public nonReentrant onlyOwner onlyItemsOnAuction(auctionItemId) returns (bool success) {
        // get sale item
        AuctionItem storage _auctionItem = auctionItems[auctionItemId];

        uint256 oldPrice = _auctionItem.auctionPrice;

        _auctionItem.auctionPrice = priceInWei;
        _auctionItem.currentBidder = bidder;

        emit AuctionItemPriceUpdated(auctionItemId, oldPrice, priceInWei, bidder);

        return true;
    }

    function getAuctionItem(bytes32 auctionItemId)
        public
        view
        onlyItemsOnAuction(auctionItemId)
        returns (
            uint256 tokenId,
            address contractAddress,
            address sellerAddress,
            address currentBidder,
            IERC20 paymentToken,
            uint256 auctionPrice,
            uint256 auctionStartTime,
            uint256 auctionDurationDays
        )
    {
        AuctionItem memory auctionItem = auctionItems[auctionItemId];
        return (
            auctionItem.tokenId,
            auctionItem.contractAddress,
            auctionItem.sellerAddress,
            auctionItem.currentBidder,
            auctionItem.paymentToken,
            auctionItem.auctionPrice,
            auctionItem.auctionStartTime,
            auctionItem.auctionDurationDays
        );
    }

    function getAuctionItemPaymentToken(bytes32 auctionItemId)
        public
        view
        onlyItemsOnAuction(auctionItemId)
        returns (IERC20 paymentToken)
    {
        return auctionItems[auctionItemId].paymentToken;
    }

    function getAuctionItemOwner(bytes32 auctionItemId)
        public
        view
        onlyItemsOnAuction(auctionItemId)
        returns (address owner)
    {
        return auctionItems[auctionItemId].sellerAddress;
    }

    function getAuctionItemPrice(bytes32 auctionItemId)
        public
        view
        onlyItemsOnAuction(auctionItemId)
        returns (uint256 price)
    {
        return auctionItems[auctionItemId].auctionPrice;
    }

    function getAuctionItemContractAddress(bytes32 auctionItemId)
        public
        view
        onlyItemsOnAuction(auctionItemId)
        returns (address contractAddress)
    {
        return auctionItems[auctionItemId].contractAddress;
    }

    function isAuctionActive(bytes32 auctionItemId) public view onlyItemsOnAuction(auctionItemId) returns (bool) {
        return
            block.timestamp <
            auctionItems[auctionItemId].auctionStartTime + (auctionItems[auctionItemId].auctionDurationDays * 1 days);
    }

    function remainingAuctionTime(bytes32 auctionItemId) public view returns (uint256) {
        uint256 auctionEndTime = auctionItems[auctionItemId].auctionStartTime +
            (auctionItems[auctionItemId].auctionDurationDays * 1 days);
        return auctionEndTime >= block.timestamp ? auctionEndTime - block.timestamp : 0;
    }

    function auctionEndTime(bytes32 auctionItemId) public view returns (uint256) {
        return
            auctionItems[auctionItemId].auctionStartTime + (auctionItems[auctionItemId].auctionDurationDays * 1 days);
    }

    function getAuctionItemCount() public view returns (uint256 count) {
        return auctionItemIndex.length;
    }

    function getAuctionItemIdAtIndex(uint256 index) public view returns (bytes32 auctionItemId) {
        return auctionItemIndex[index];
    }

    function getAllSaleItemIds() public view returns (bytes32[] memory) {
        return auctionItemIndex;
    }

    function getAuctionItemCountForContractAddress(address contractAddress) public view returns (uint256 count) {
        return auctionItemsByContract[contractAddress].auctionItemIndex.length;
    }

    function getAuctionItemIdAtIndexForContractAddress(address contractAddress, uint256 index)
        public
        view
        returns (bytes32 auctionItemId)
    {
        return auctionItemsByContract[contractAddress].auctionItemIndex[index];
    }

    function getAllAuctionItemIdsForContractAddress(address contractAddress) public view returns (bytes32[] memory) {
        return auctionItemsByContract[contractAddress].auctionItemIndex;
    }

    function insertAuctionItemToAuctionItemsByContract(bytes32 auctionItemId, address contractAddress) private {
        // if contract marketplace does not exist, create one
        if (auctionItemsByContract[contractAddress].contractAddress == address(0)) {
            auctionItemsByContract[contractAddress] = AuctionItemsByContractAddress(contractAddress, new bytes32[](0));
        }

        // update sale index list
        auctionItemsByContract[contractAddress].auctionItemIndex.push(auctionItemId);
        uint256 _index = auctionItemsByContract[contractAddress].auctionItemIndex.length - 1;
        auctionItemsByContract[contractAddress].auctionItemIndexMapping[auctionItemId] = _index;
    }

    function removeAuctionItemFromAuctionItemsByContract(bytes32 auctionItemId, address contractAddress) private {
        uint256 rowToDelete = auctionItemsByContract[contractAddress].auctionItemIndexMapping[auctionItemId];

        bytes32 keyToMove = auctionItemsByContract[contractAddress].auctionItemIndex[
            auctionItemsByContract[contractAddress].auctionItemIndex.length - 1
        ];
        auctionItemsByContract[contractAddress].auctionItemIndex[rowToDelete] = keyToMove;
        auctionItemsByContract[contractAddress].auctionItemIndexMapping[keyToMove] = rowToDelete;
        auctionItemsByContract[contractAddress].auctionItemIndex.pop();

        delete auctionItemsByContract[contractAddress].auctionItemIndexMapping[auctionItemId];
    }
}

// File: contracts/marketplace/AuctionMarketplace.sol


pragma solidity ^0.6.0;











contract AuctionMarketplace is Ownable, ERC721Holder, ERC1155Holder, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;
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

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /** @dev check supports erc721 or erc1155 using eip165
     * @param tokenContractAddress Contract address to check if is ERC721 or ERC1155
     */
    modifier onlySupportedNfts(address tokenContractAddress) {
        require(
            tokenContractAddress.supportsInterface(_INTERFACE_ID_ERC721) ||
                tokenContractAddress.supportsInterface(_INTERFACE_ID_ERC1155),
            "Contract is not ERC721 or ERC1155"
        );
        _;
    }

    /** @dev check seller exists
     */
    modifier onlySeller() {
        require(sellers[msg.sender].sellerAddress == msg.sender, "Address is not seller");
        _;
    }

    /** @dev Checks if msg.sender is the owner of a listed item
     * @param id  item id to check if msg.sender is the owner
     */
    modifier onlyItemListOwner(bytes32 id) {
        require(auctionItemManager.getAuctionItemOwner(id) == msg.sender, "You do not own the listing");
        _;
    }

    /** @dev Checks if sale item for id exists
     * @param id  item id to check exists in the list of items
     */
    modifier onlyItemsOnAuction(bytes32 id) {
        require(auctionItemManager.itemIsOnAuction(id), "id does not match any listing");
        _;
    }

    /** @dev Checks if sale item for id exists
     * @param id  item id to check exists in the list of items
     */
    modifier onlyActiveAuction(bytes32 id) {
        require(auctionItemManager.isAuctionActive(id), "auction at id has ended");
        _;
    }

    /** @dev check supports erc721 using eip165
     * @param tokenContractAddress Contract address to check if is ERC721
     */
    modifier onlyERC721(address tokenContractAddress) {
        require(isERC721(tokenContractAddress), "Contract is not ERC721");
        _;
    }

    /** @dev check supports erc1155 using eip165
     * @param tokenContractAddress Contract address to check if is ERC1155
     */
    modifier onlyERC1155(address tokenContractAddress) {
        require(isERC1155(tokenContractAddress), "Contract is not ERC1155");
        _;
    }

    event ItemListed(
        uint256 indexed tokenId,
        address indexed contractAddress,
        uint256 startPriceInWei,
        uint256 auctionStartUnixEpoch,
        uint256 auctionDurationDays,
        bytes32 indexed id
    );

    event ItemBidChanged(bytes32 indexed id, uint256 oldPrice, uint256 newPrice, address bidder);

    event ItemSold(bytes32 indexed id, uint256 price, address indexed oldOwner, address indexed newOwner);

    event ItemUnlisted(bytes32 indexed id);
    struct Seller {
        address sellerAddress;
        bytes32[] auctionItemIndex;
        mapping(bytes32 => uint256) auctionItemIndexMapping;
    }

    AuctionItemManager public auctionItemManager;
    mapping(address => Seller) private sellers;

    constructor() public {
        auctionItemManager = new AuctionItemManager();
    }

    function scheduleNftForAuction(
        address contractAddress,
        uint256 tokenId,
        uint256 startPriceInWei,
        uint256 auctionStartUnixEpoch,
        uint256 auctionDurationDays,
        IERC20 paymentToken
    ) public nonReentrant onlyOwner onlyERC721(contractAddress) {
        // require token is not already listed
        bytes32 saleItemId = keccak256(abi.encodePacked(tokenId, contractAddress));
        require(!auctionItemManager.itemIsOnAuction(saleItemId), "Item is already on auction");

        // use contract address to get contract instance as ERC721 instance
        if (isERC721(contractAddress)) {
            // transfer ownership of the token to this contract (will fail if contract is not approved prior to this)
            IERC721(contractAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        } else {
            // transfer ownership of the token to this contract (will fail if contract is not approved prior to this)
            IERC1155(contractAddress).safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
        }

        // if seller profile does not exist, create one
        if (sellers[msg.sender].sellerAddress == address(0)) {
            sellers[msg.sender] = Seller(msg.sender, new bytes32[](0));
        }

        // update seller sale index list
        insertSaleItemToSellerProfile(saleItemId, msg.sender);

        auctionItemManager.insertAuctionItem(
            saleItemId,
            payable(msg.sender),
            contractAddress,
            tokenId,
            startPriceInWei,
            auctionStartUnixEpoch,
            auctionDurationDays,
            paymentToken
        );

        emit ItemListed(
            tokenId,
            contractAddress,
            startPriceInWei,
            auctionStartUnixEpoch,
            auctionDurationDays,
            saleItemId
        );
    }

    function bidForNft(bytes32 id, uint256 priceInWei)
        public
        nonReentrant
        onlyItemsOnAuction(id)
        onlyActiveAuction(id)
    {
        uint256 oldPrice = auctionItemManager.getAuctionItemPrice(id);
        require(oldPrice < priceInWei, "Bid price must be higher than current price");

        // check address has enough funds to pay for the bid
        IERC20 paymentToken = auctionItemManager.getAuctionItemPaymentToken(id);
        require(paymentToken.balanceOf(msg.sender) >= priceInWei, "Not enough funds to pay for bid");

        auctionItemManager.updateAuctionItemPrice(id, priceInWei, msg.sender);

        emit ItemBidChanged(id, oldPrice, priceInWei, msg.sender);
    }

    function withdrawAuctionListing(bytes32 id) public nonReentrant onlyItemListOwner(id) onlyItemsOnAuction(id) {
        (uint256 tokenId, address contractAddress, , , , , , ) = auctionItemManager.getAuctionItem(id);

        // transfer ownership of the token from this contract to the buyer (will fail if address is not owner)
        // no need for delegate call as the owner of the token should be this contract address
        if (isERC721(contractAddress)) {
            IERC721(contractAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        } else {
            IERC1155(contractAddress).safeTransferFrom(address(this), msg.sender, tokenId, 1, "");
        }

        //delete sale item from manager
        auctionItemManager.deleteAuctionItem(id);

        // update seller profile
        removeSaleItemFromSellerProfile(id, msg.sender);

        emit ItemUnlisted(id);
    }

    function purchaseAuctionItem(bytes32 id) public payable nonReentrant onlyItemsOnAuction(id) {
        require(!auctionItemManager.isAuctionActive(id), "auction is still active");

        (
            uint256 tokenId,
            address contractAddress,
            address sellerAddress,
            address currentBidder,
            IERC20 paymentToken,
            uint256 auctionPrice,
            ,

        ) = auctionItemManager.getAuctionItem(id);
        require(msg.sender == currentBidder || msg.sender == sellerAddress, "Must be auction winner or seller");

        // check address has enough funds to pay for the bid
        require(paymentToken.balanceOf(currentBidder) >= auctionPrice, "Not enough funds to pay for sale");

        paymentToken.safeTransferFrom(currentBidder, sellerAddress, auctionPrice);

        // transfer ownership of the token from this contract to the buyer (will fail if address is not owner)
        // no need for delegate call as the owner of the token should be this contract address
        if (isERC721(contractAddress)) {
            IERC721(contractAddress).safeTransferFrom(address(this), currentBidder, tokenId);
        } else {
            IERC1155(contractAddress).safeTransferFrom(address(this), currentBidder, tokenId, 1, "");
        }

        //fire the event to say its sold
        emit ItemSold(id, auctionPrice, sellerAddress, currentBidder);

        //delete sale item from manager
        auctionItemManager.deleteAuctionItem(id);

        // update seller profile
        removeSaleItemFromSellerProfile(id, sellerAddress);
    }

    function withdrawTokens(address tokenAddress) public onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));

        IERC20(tokenAddress).safeTransferFrom(address(this), address(msg.sender), balance);
    }

    function totalAuctionItems() public view returns (uint256) {
        return auctionItemManager.getAuctionItemCount();
    }

    function totalAuctionItemsForSellerAddress(address sellerAddress) public view returns (uint256) {
        return sellers[sellerAddress].auctionItemIndex.length;
    }

    function totalAuctionItemsForContractAddress(address tokenContractAddress) public view returns (uint256) {
        return auctionItemManager.getAuctionItemCountForContractAddress(tokenContractAddress);
    }

    function itemIsOnAuction(bytes32 id) public view returns (bool) {
        return auctionItemManager.itemIsOnAuction(id);
    }

    function itemIsOnAuction(uint256 tokenId, address tokenContractAddress) public view returns (bool) {
        return auctionItemManager.itemIsOnAuction(keccak256(abi.encodePacked(tokenId, tokenContractAddress)));
    }

    function remainingAuctionTime(bytes32 id) public view onlyItemsOnAuction(id) returns (uint256) {
        return auctionItemManager.remainingAuctionTime(id);
    }

    function auctionEndTime(bytes32 id) public view onlyItemsOnAuction(id) returns (uint256) {
        return auctionItemManager.auctionEndTime(id);
    }

    function getAuctionItemAtIndexBySellerAddress(address sellerAddress, uint256 index)
        public
        view
        returns (bytes32 id)
    {
        return sellers[sellerAddress].auctionItemIndex[index];
    }

    function getAuctionItemAtIndexByContractAddress(address tokenContractAddress, uint256 index)
        public
        view
        returns (bytes32 id)
    {
        return auctionItemManager.getAuctionItemIdAtIndexForContractAddress(tokenContractAddress, index);
    }

    function getAuctionItem(bytes32 id)
        public
        view
        returns (
            uint256 tokenId,
            address contractAddress,
            address sellerAddress,
            address currentBidder,
            IERC20 paymentToken,
            uint256 auctionPrice,
            uint256 auctionStartTime,
            uint256 auctionDurationDays
        )
    {
        return auctionItemManager.getAuctionItem(id);
    }

    function getAuctionItemsLengthForAddress(address sellerAddress) public view returns (uint256) {
        return sellers[sellerAddress].auctionItemIndex.length;
    }

    function getAuctionItemForAddressAtIndex(address sellerAddress, uint256 index) public view returns (bytes32) {
        return sellers[sellerAddress].auctionItemIndex[index];
    }

    function insertSaleItemToSellerProfile(bytes32 saleItemId, address sellerAddress) private {
        // update sale index list
        sellers[sellerAddress].auctionItemIndex.push(saleItemId);
        uint256 _index = sellers[sellerAddress].auctionItemIndex.length - 1;
        sellers[sellerAddress].auctionItemIndexMapping[saleItemId] = _index;
    }

    function removeSaleItemFromSellerProfile(bytes32 saleItemId, address sellerAddress) private {
        uint256 rowToDelete = sellers[sellerAddress].auctionItemIndexMapping[saleItemId];

        bytes32 keyToMove = sellers[sellerAddress].auctionItemIndex[sellers[sellerAddress].auctionItemIndex.length - 1];
        sellers[sellerAddress].auctionItemIndex[rowToDelete] = keyToMove;
        sellers[sellerAddress].auctionItemIndexMapping[keyToMove] = rowToDelete;
        sellers[sellerAddress].auctionItemIndex.pop();

        delete sellers[sellerAddress].auctionItemIndexMapping[saleItemId];
    }

    function isERC721(address contractAddress) public view returns (bool) {
        return contractAddress.supportsInterface(_INTERFACE_ID_ERC721);
    }

    function isERC1155(address contractAddress) public view returns (bool) {
        return contractAddress.supportsInterface(_INTERFACE_ID_ERC1155);
    }
}