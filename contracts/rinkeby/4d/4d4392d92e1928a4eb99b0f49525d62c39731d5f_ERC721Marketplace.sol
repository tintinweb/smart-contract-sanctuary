/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// File: node_modules\@openzeppelin\contracts\utils\Context.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin\contracts\access\Ownable.sol



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

// File: @openzeppelin\contracts\utils\Address.sol



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

// File: @openzeppelin\contracts\math\SafeMath.sol



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

// File: @openzeppelin\contracts\utils\ReentrancyGuard.sol



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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol



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



// File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol



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

// File: node_modules\@openzeppelin\contracts\introspection\IERC165.sol



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

// File: @openzeppelin\contracts\token\ERC721\IERC721.sol



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

// File: node_modules\@openzeppelin\contracts\token\ERC721\IERC721.sol



// File: @openzeppelin\contracts\token\ERC721\IERC721Enumerable.sol



pragma solidity >=0.6.2 <0.8.0;


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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts\interfaces\IDelfyERC721.sol



pragma solidity >=0.6.12;

interface IDelfyERC721 {
    function royalty(uint256) external returns (address);

    function referredBy(address) external returns (address);

    function isMinter(address) external returns (bool);
}

// File: contracts\interfaces\IERC721MarketPlace.sol



pragma solidity >=0.6.12;

interface IERC721MarketPlace {
    enum Category {
        ART,
        MUSIC,
        SPORT,
        MEME,
        PHOTO,
        GAME,
        ANIMAL,
        LICENSE,
        LEGENDARY,
        OTHERS
    }
    
    event AuctionCreated(
        bytes32 id,
        address indexed token,
        uint256 tokenId,
        uint256 _basePrice,
        uint256 secondaryFees,
        address paymentMethod,
        address indexed royalty,
        uint256 royaltyFees,
        Category category
    );
    event Cancelled(bytes32 id, address indexed token, uint256 _tokenId);
    event BidMade(bytes32 id, address indexed token, uint256 tokenId, uint256 bidValue);
    event Executed(bytes32 auctionId, address indexed token, uint256 tokenId, uint256 creatorPayment, uint256 ownerPayment, uint256 total);
    event UpdatePaymentMethod(
        bytes32 auctionId,
        address oldPaymentMtd,
        address newPaymentMtd
    );
    event PriceUpdated(
        bytes32 auctionId,
        address indexed token,
        uint256 tokenId,
        uint256 oldPrice,
        uint256 newPrice
    );
    event FeesUpdated(
        bytes32 auctionId,
        address indexed token,
        uint256 tokenId,
        uint256 oldFees,
        uint256 newFees
    );

    function createAuction(
        address _token,
        uint256 _tokenId,
        uint256 _basePrice,
        uint256 _secondaryFees,
        address paymentMethod,
        uint8 _category
    ) external;

    function makeBid(bytes32 _id, uint256 bidValue) external payable;

    function cancelAuction(bytes32 _auctionId) external returns (bool);

    function closeAuction(bytes32 _auctionId) external payable returns (bool);

    function updateBasePrice(bytes32 _auctionId, uint256 _newBaseFees)
        external
        returns (bool);

    function updateRoyaltyFees(bytes32 _auctionId, uint256 _newSecFees)
        external
        returns (bool);

    function getOwnerTokenIds(address owner, address _token)
        external
        view
        returns (uint256[] memory ownerTokens);
}

// File: contracts\ERC721MKTPStorage.sol



pragma solidity >=0.6.12;


    
contract ERC721Storage {
    
    enum Status{
    
        OPEN,
        CANCELLED,
        SOLD
    }
    
    struct Auction {
        address owner;
        address token;
        address currentBidder;
        uint256 tokenId;
        address royalty;
        uint256 basePrice;
        uint256 lastBidVal;
        // uint256 executedPrice;
        address paymentMethod; // address(0) for eth and address for ERC20 token
        uint256 createdAt;
        uint256 royaltyFees;
        bytes32 id;
        Status status;
        uint256 closedAt;
    }

    // struct Bid {
    //     address bidder;
    //     uint256 bidPrice;
    //     uint256 createdAt;
    //     uint256 closedAt;
    //     bytes32 auctionId;
    //     bool dropped;
    //     bool accepted;
    // }

    // struct History {
    //     address token;
    //     uint256 tokenId;
    //     address lastBuyer;
    //     address lastSeller;
    //     uint256 timestamp;
    //     uint256 price;
    //     address paymentMethod;
    // }
    
    
}

// File: contracts\ERC721Marketplace.sol

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

// import "@openzeppelin/contracts/utils/Pausable.sol";

contract ERC721Marketplace is
    ReentrancyGuard,
    ERC721Storage,
    Ownable,
    IERC721MarketPlace
{
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    mapping(bytes32 => Auction) public getAuction; // get auction by ID
    // mapping(bytes32 => Bid[]) public getBidHistory; // collection of all bid activities
    // mapping(address => mapping(uint256 => History[])) public getTokenHistory; // search for token History on marketplace

    mapping(address => mapping(uint256 => uint256)) public creatorCut; // check if secondary fees is applicable
    // mapping(address => uint256) public userAmountMade;
    mapping(address => bytes32[]) ownerAuctions; // mapping owner to all his active auctions
    mapping(address => Auction[]) userCollection; // mapping buyer to array of art collections
    mapping(address => bool) public isSupportedERC721; // check if a platform contract is supported
    mapping(address => bool) public isPlatformToken; // delfy native tokens
    mapping(address => bool) public isMinter;
    mapping(bytes32 => Category) public category;

    bytes32[] auctionIds;
    address[] platformTokens;
    address[] supportedERC721;
    address public delfyERC721;
    address public platformVault; // for platform fees
    // uint256 public ethBalance;
    uint256 public bidWindow = 24 hours;
    uint256 public bidExtension = 20 minutes;

    uint256 public platformCut = 50;
    uint256 public cashBack = 5;
    uint256 public refBonus = 5;
    bool public giveCashBack = true;
    function getOwnerAuctions(address _creator)
        external
        view
        returns (bytes32[] memory)
    {
        return ownerAuctions[_creator];
    }

    function getUserCollections(address collector)
        external
        view
        returns (Auction[] memory)
    {
        return userCollection[collector];
    }

    bool public paused = false;

    modifier whenNotPaused() {
        require(paused == false);
        _;
    }
    bool public initialized = false;

    function initialize(address vault) public {
        require(initialized == false, "already initialized");
        platformVault = vault;
        initialized = true;
    }

    function createAuction(
        address _token,
        uint256 _tokenId,
        uint256 _basePrice,
        uint256 _secondaryFees,
        address _paymentMethod,
        uint8 _category
    ) external override whenNotPaused {
        require(_category <= uint8(Category.OTHERS), "DelfyMarket: invalid category");
        IERC721 token = IERC721(_token);
        Auction storage auction;
        address _creator;
        address _owner = token.ownerOf(_tokenId);
        require(msg.sender == _owner, "DelfyMarket: only_token_owner");
        require(
            token.getApproved(_tokenId) == address(this),
            "DelfyMarket: requires approval"
        );
        token.safeTransferFrom(_owner, address(this), _tokenId);
        require(
            token.ownerOf(_tokenId) == address(this),
            "DelfyMarket: Transfer Failed"
        );
        auction.token = _token;
        auction.owner = _owner;
        auction.tokenId = _tokenId;
        auction.basePrice = _basePrice;
        auction.paymentMethod = _paymentMethod;
        auction.closedAt = 0;
        if (isSupportedERC721[_token]) {
            _creator = IDelfyERC721(_token).royalty(_tokenId);
            if (creatorCut[_token][_tokenId] == 0)
                creatorCut[_token][_tokenId] = _secondaryFees;
            auction.royaltyFees = _secondaryFees;
        }
        auction.lastBidVal = 0;
        auction.royalty = _creator;
        auction.status = Status.OPEN;
        auction.createdAt = block.timestamp;
        auction.id = keccak256(
            abi.encodePacked(
                auction.owner,
                _token,
                _tokenId,
                _basePrice,
                _secondaryFees,
                auction.createdAt
            )
        );
        auctionIds.push(auction.id);
        getAuction[auction.id] = auction;
        category[auction.id] = Category(_category);
        ownerAuctions[auction.owner].push(auction.id);
        if (IDelfyERC721(delfyERC721).isMinter(_owner)) {
            isMinter[_owner] = true;
        }
        
        emit AuctionCreated(
            auction.id,
            auction.token,
            auction.tokenId,
            auction.basePrice,
            auction.royaltyFees,
            _paymentMethod,
            auction.royalty,
            auction.royaltyFees,
            category[auction.id]
        );
    }

    // function auctionArrayCollector(address user, Auction storage newAuc)
    //     internal
    //     returns (Auction[] storage userAuctions)
    // {
    //     userAuctions = ownerAuctions[user];
    //     userAuctions.push(newAuc);
    //     return userAuctions;
    // }

    // function bidArrayCollector(bytes32 auctionId, Bid storage newBid)
    //     internal
    //     returns (Bid[] storage auctionBids)
    // {
    //     auctionBids = getBidHistory[auctionId];
    //     auctionBids.push(newBid);
    //     return auctionBids;
    // }

    receive() external payable {
        revert();
    }

    function makeBid(bytes32 _id, uint256 bidValue)
        external
        payable
        override
        whenNotPaused
        nonReentrant
    {
        Auction storage _auction = getAuction[_id];
        // Bid[] storage bids = getBidHistory[_id];
        // Bid storage activeBid;

        // Bid storage bid;

        if (_auction.lastBidVal == 0 && _auction.closedAt == 0) {
            if (_auction.paymentMethod == address(0)) {
                require(
                    msg.value >= _auction.basePrice,
                    "DelfyMarket: Bid_value_must_be_>current_bid_value"
                );
            } else if (_auction.paymentMethod != address(0)) {
                require(
                    bidValue >= _auction.basePrice,
                    "DelfyMarket: Bid_value_must_be_>current_bid_value"
                );

                IERC20(_auction.paymentMethod).safeTransferFrom(
                    _msgSender(),
                    address(this),
                    bidValue
                );
            }
            _auction.closedAt = block.timestamp.add(bidWindow);
        } else if (_auction.lastBidVal != 0 && _auction.closedAt != 0) {
            // activeBid = bids[bids.length - 1];
            if (_auction.paymentMethod == address(0)) {
                require(
                    msg.value > _auction.lastBidVal.add(1e17) ||
                        msg.value >
                        _auction.lastBidVal.add(
                            getPercent(_auction.lastBidVal, 10)
                        ),
                    "DelfyMarket: Bid_value_must_be_>current_bid_value"
                );
                ethTransferHelper(_auction.currentBidder, _auction.lastBidVal);
            } else {
                require(
                    bidValue >=
                        _auction.lastBidVal.add(
                            getPercent(_auction.lastBidVal, 10)
                        ),
                    "DelfyMarket: Bid_value_must_be_>current_bid_value"
                );
                IERC20(_auction.paymentMethod).safeTransferFrom(
                    _msgSender(),
                    address(this),
                    bidValue
                );
                IERC20(_auction.paymentMethod).safeTransfer(
                    _auction.currentBidder,
                    _auction.lastBidVal
                );
            }
            // activeBid.dropped = true;
            // activeBid.closedAt = block.timestamp;
            if (
                _auction.closedAt > 0 &&
                _auction.closedAt.sub(block.timestamp) <= bidExtension &&
                _auction.closedAt.sub(block.timestamp) >= 1
            ) {
                _auction.closedAt = _auction.closedAt.add(bidExtension);
            }
        }
        _auction.currentBidder = _msgSender();
        _auction.lastBidVal = bidValue;
        
        // bid.bidder = _msgSender();
        // bid.bidPrice = bidValue;
        // bid.createdAt = block.timestamp;
        // bid.auctionId = _auction.id;

        // bid.closedAt = _auction.closedAt;
        // // getBidHistory[_auction.id] = bidArrayCollector(_auction.id, bid);
        // // getBidHistory[_auction.id] = bidArrayCollector(_auction.id, bid);
        // getBidHistory[_auction.id].push(bid);
        emit BidMade(
            _auction.id,
            _auction.token,
            _auction.tokenId,
            _auction.lastBidVal
        );
    }

    function updatePaymentMethod(bytes32 auctionId, address newPaymentMtd)
        external
        whenNotPaused
    {
        Auction storage _auction = getAuction[auctionId];
        address oldPaymentMtd = _auction.paymentMethod;
        require(_auction.lastBidVal == 0, "DelfyMarket: only_before_first_bid");
        require(
            _msgSender() == _auction.owner,
            "DelfyMarket: only_auction_owner"
        );
        _auction.paymentMethod = newPaymentMtd;
        emit UpdatePaymentMethod(auctionId, oldPaymentMtd, newPaymentMtd);
    }

    function cancelAuction(bytes32 _auctionId)
        external
        override
        whenNotPaused
        returns (bool)
    {
        Auction storage _auction = getAuction[_auctionId];
        require(
            _msgSender() == _auction.owner,
            "DelfyMarket: only_auction_owner"
        );
        require(
            _auction.lastBidVal == 0 && _auction.closedAt == 0,
            "DelfyMarket: only_before_first_bid"
        );
        IERC721(_auction.token).safeTransferFrom(
            address(this),
            _auction.owner,
            _auction.tokenId
        );
        _auction.owner = address(0);
        _auction.id = bytes32(0);
        _auction.token = address(0);
        _auction.tokenId = 0;
        _auction.createdAt = 0;
        _auction.closedAt = 0;
        _auction.basePrice = 0;
        _auction.lastBidVal = 0;
        _auction.royaltyFees = 0;
        _auction.status = Status.CANCELLED;
        // auctions[_auction.index] = auctions[auctions.length - 1];

        // auctions.pop();
        emit Cancelled(_auction.id, _auction.token, _auction.tokenId);
        return true;
    }

    function closeAuction(bytes32 _auctionId)
        public
        payable
        override
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        Auction storage auction = getAuction[_auctionId];
        require(
            _msgSender() == auction.owner ||
                _msgSender() == auction.currentBidder,
            "DelfyMarket: only_auction_owner_and_lastBidder"
        );
        require(
            auction.lastBidVal >= auction.basePrice,
            "DelfyMarket: close_sale_by_cancel_auction"
        );
        require(
            block.timestamp >= auction.closedAt,
            "DelfyMarket: Auction_not_closed"
        );

        uint256 ownerPayment = getOwnerPayment(_auctionId);
        uint256 creatorPayment = getRoyaltyCut(_auctionId);
        (uint256 _platformCut, uint256 refCut, uint256 _cashBack, uint256 total) =
            getPlatformCut(_auctionId);
        address ref;
        address creator;
        if (auction.paymentMethod == address(0)) {
            ethTransferHelper(platformVault, _platformCut);
            ethTransferHelper(auction.owner, ownerPayment);
            if (auction.token == delfyERC721 && isMinter[auction.owner]) {
                ref = IDelfyERC721(delfyERC721).referredBy(auction.owner);
                // uint256 refFee = getFractionPercent(auction.lastBidVal, refBonus);
                ethTransferHelper(ref, refCut);
            }
            if (
                isSupportedERC721[auction.token] &&
                creatorCut[auction.token][auction.tokenId] > 0
            ) {
                creator = IDelfyERC721(auction.token).royalty(auction.tokenId);
                ethTransferHelper(creator, creatorPayment);
            }
        } else {
            ERC20TransferHelper(
                auction.paymentMethod,
                platformVault,
                _platformCut
            );
            ERC20TransferHelper(
                auction.paymentMethod,
                auction.owner,
                ownerPayment
            );
            if (auction.token == delfyERC721 && isMinter[auction.owner]) {
                ref = IDelfyERC721(delfyERC721).referredBy(auction.owner);
                // uint256 refFee = getFractionPercent(auction.lastBidVal, refCut);
                ERC20TransferHelper(auction.paymentMethod, ref, refCut);
            }
            if (
                isSupportedERC721[auction.token] &&
                creatorCut[auction.token][auction.tokenId] > 0
            ) {
                creator = IDelfyERC721(auction.token).royalty(auction.tokenId);
                ERC20TransferHelper(
                    auction.paymentMethod,
                    creator,
                    creatorPayment
                );
            }
            if (isPlatformToken[auction.paymentMethod] && giveCashBack)
                ERC20TransferHelper(
                    auction.paymentMethod,
                    auction.currentBidder,
                    _cashBack
                );
        }
        IERC721 _token = IERC721(auction.token);
        // _token.approve(auction.currentBidder, auction.tokenId);
        _token.safeTransferFrom(
            address(this),
            auction.currentBidder,
            auction.tokenId
        );
        auction.status = Status.SOLD;
        // updateTokeHistory(auction.id);
        emit Executed(auction.id, auction.token, auction.tokenId, creatorPayment, ownerPayment, total);
        return true;
    }

    // function updateTokeHistory(bytes32 auctionId) internal {
    //     Auction storage auction = getAuction[auctionId];
    //     History memory history;
    //     history.timestamp = block.timestamp;
    //     history.token = auction.token;
    //     history.tokenId = auction.tokenId;
    //     history.lastBuyer = auction.currentBidder;
    //     history.lastSeller = auction.owner;
    //     history.price = auction.lastBidVal;
    //     history.paymentMethod = auction.paymentMethod;
    //     // History[] storage records =
    //     //     getTokenHistory[auction.token][auction.tokenId];
    //     // records.push(history);
    //     // getTokenHistory[auction.token][auction.tokenId] = records;
    //     getTokenHistory[auction.token][auction.tokenId].push(history);
    // }

    function updateBasePrice(bytes32 _auctionId, uint256 _newBasePrice)
        external
        override
        whenNotPaused
        returns (bool)
    {
        Auction storage _auction = getAuction[_auctionId];
        uint256 oldPrice = _auction.basePrice;
        require(
            _msgSender() == _auction.owner,
            "DelfyMarket: only_auction_owner"
        );

        require(
            _auction.lastBidVal == 0 && _auction.closedAt == 0,
            "DelfyMarket: only_before_first_bid"
        );
        _auction.basePrice = _newBasePrice;
        emit PriceUpdated(
            _auction.id,
            _auction.token,
            _auction.tokenId,
            oldPrice,
            _auction.basePrice
        );
        return true;
    }

    function updateRoyaltyFees(bytes32 _auctionId, uint256 _newSecFees)
        external
        override
        whenNotPaused
        returns (bool)
    {
        Auction storage _auction = getAuction[_auctionId];
        require(
            isSupportedERC721[_auction.token],
            "only_delfy_supported_tokens"
        );
        uint256 oldFee = _auction.royaltyFees;
        address _royalty =
            IDelfyERC721(_auction.token).royalty(_auction.tokenId);

        require(
            _msgSender() == _auction.owner && _msgSender() == _royalty,
            "DelfyMarket: only_auction_owner"
        );
        require(
            _auction.lastBidVal == 0 && _auction.closedAt == 0,
            "DelfyMarket: only_before_first_bid"
        );
        if (isSupportedERC721[_auction.token])
            _auction.royaltyFees = _newSecFees;
        emit FeesUpdated(
            _auction.id,
            _auction.token,
            _auction.tokenId,
            oldFee,
            _auction.royaltyFees
        );
        return true;
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

    function getOwnerPayment(bytes32 _auctionId)
        public
        view
        returns (uint256 payment)
    {
        Auction storage auction = getAuction[_auctionId];
        (, , , uint256 _total) = getPlatformCut(_auctionId);
        if (isSupportedERC721[auction.token]) {
            if (creatorCut[auction.token][auction.tokenId] > 0) {
                payment = auction.lastBidVal.sub(getRoyaltyCut(_auctionId)).sub(
                    _total
                );
            }
        } else payment = auction.lastBidVal.sub(_total);
        return payment;
    }

    function getRoyaltyCut(bytes32 _auctionId)
        public
        view
        returns (uint256 cutValue)
    {
        Auction storage auction = getAuction[_auctionId];
        if (auction.owner != auction.royalty) {
            uint256 amount = auction.lastBidVal;
            uint256 rCut = creatorCut[auction.token][auction.tokenId];
            cutValue = getFractionPercent(amount, rCut);
        } else cutValue = 0;
        return cutValue;
    }

    function getPlatformCut(bytes32 _auctionId)
        public
        view
        returns (
            uint256 cutValue,
            uint256 refCut,
            uint256 _cashBack,
            uint256 _total
        )
    {
        Auction storage auction = getAuction[_auctionId];
        uint256 amount = auction.lastBidVal;
        uint256 cut;

        if (
            isPlatformToken[auction.paymentMethod] &&
            giveCashBack &&
            isMinter[auction.owner]
        ) {
            // deduct for refBonus and cashBack for buyer and seller
            uint256 subAmount = refBonus.add(cashBack).add(cashBack);

            refCut = getFractionPercent(amount, refBonus);
            _cashBack = getFractionPercent(amount, cashBack);

            cut = platformCut.sub(subAmount);

            cutValue = getFractionPercent(amount, cut);
        } else if (
            !isPlatformToken[auction.paymentMethod] && isMinter[auction.owner]
        ) {
            cut = platformCut.sub(refBonus);
            refCut = getFractionPercent(amount, refBonus);
            cutValue = getFractionPercent(amount, cut);
        } else if (
            giveCashBack &&
            isPlatformToken[auction.paymentMethod] &&
            !isMinter[auction.owner]
        ) {
            // deduct cashBack for seller and buyer
            cut = platformCut.sub(cashBack).sub(cashBack);
            _cashBack = getFractionPercent(amount, cashBack);
            cutValue = getFractionPercent(amount, cut);
        } else {
            cutValue = getFractionPercent(amount, platformCut);
        }

        _total = cutValue.add(refCut).add(_cashBack);
        return (cutValue, refCut, _cashBack, _total);
    }

    function ERC20TransferHelper(
        address token,
        address to,
        uint256 amount
    ) internal {
        IERC20(token).safeTransfer(to, amount);
    }

    function ethTransferHelper(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "ETH_transfer_failed");
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return _ERC721_RECEIVED;
    }

    // function onERC1155Received(address , address , uint256 , uint256 , bytes calldata ) external pure returns(bytes4){
    //     return this.onERC1155Received.selector;
    // }

    /*********************** View Functions  ************************/
    function getSupportedTokens() external view returns (address[] memory) {
        return supportedERC721;
    }

    // function getBidWindow() public view returns (uint256) {
    //     return bidWindow;
    // }

    function getAuctionIds() external view returns (bytes32[] memory) {
        return auctionIds;
    }

    function getOwnerTokenIds(address owner, address _token)
        public
        view
        override
        returns (uint256[] memory ownerTokens)
    {
        IERC721Enumerable token = IERC721Enumerable(_token);
        uint256 tokenCount = token.balanceOf(owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalSupply = token.totalSupply();
            uint256 resultIndex = 0;
            for (uint256 tokenId = 1; tokenId <= totalSupply; tokenId++) {
                if (token.ownerOf(tokenId) == owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    /****************************** Restricted Functions **************************************/

    function updateCashbackRefBonus(uint256 _cashBack, uint256 _refBonus)
        external
        onlyOwner
    {
        cashBack = _cashBack;
        refBonus = _refBonus;
    }

    function updateBidWindow(uint256 _bidW) external onlyOwner {
        bidWindow = _bidW;
    }

    function togglePause() external onlyOwner {
        if (paused == true) {
            paused = false;
        } else paused = true;
    }

    function addPlatformTokens(address[] calldata _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_tokens[i] != address(0), "address_0");
            platformTokens.push(_tokens[i]);
            isPlatformToken[_tokens[i]] = true;
        }
    }

    function addSupportedERC721(address ERC721Token) external onlyOwner {
        require(ERC721Token != address(0), "address_0");
        isSupportedERC721[ERC721Token] = true;
    }

    function updatePlatformCut(uint256 newCut) external onlyOwner {
        platformCut = newCut;
    }

    function addDelfyERC721(address delfyERC721Token) external onlyOwner {
        require(delfyERC721Token != address(0), "address_0");
        delfyERC721 = delfyERC721Token;
    }

    function updatePlatformVault(address feesReceiver) external onlyOwner {
        platformVault = feesReceiver;
    }
}