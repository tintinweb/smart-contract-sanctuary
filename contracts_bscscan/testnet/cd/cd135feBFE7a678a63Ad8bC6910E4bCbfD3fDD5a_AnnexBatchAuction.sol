/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/math/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/token/ERC20/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/access/[email protected]



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


// File @openzeppelin/contracts/math/[email protected]



pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


// File contracts/libraries/IterableOrderedOrderSet.sol


pragma solidity >=0.6.8;

/**
    ERROR_ZERO : Inserting zero is not supported
    INVALID_ELE : Inserting element is not valid
    ERROR_SAME_ORDER : user is not allowed to place same order twice
    EMPTY_SET : Trying to get first from empty set
    ERROR_NEXT : Trying to get next of last element
    NON_EXISTENT : Trying to get next of non-existent element

    
**/

library IterableOrderedOrderSet {
    using SafeMath for uint96;
    using IterableOrderedOrderSet for bytes32;

    // represents smallest possible value for an order under comparison of fn smallerThan()
    bytes32 internal constant QUEUE_START =
        0x0000000000000000000000000000000000000000000000000000000000000001;
    // represents highest possible value for an order under comparison of fn smallerThan()
    bytes32 internal constant QUEUE_END =
        0xffffffffffffffffffffffffffffffffffffffff000000000000000000000001;

    /// The struct is used to implement a modified version of a doubly linked
    /// list with sorted elements. The list starts from QUEUE_START to
    /// QUEUE_END, and each node keeps track of its predecessor and successor.
    /// Nodes can be added or removed.
    ///
    /// `next` and `prev` have a different role. The list is supposed to be
    /// traversed with `next`. If `next` is empty, the node is not part of the
    /// list. However, `prev` might be set for elements that are not in the
    /// list, which is why it should not be used for traversing. Having a `prev`
    /// set for elements not in the list is used to keep track of the history of
    /// the position in the list of a removed element.
    struct Data {
        mapping(bytes32 => bytes32) nextMap;
        mapping(bytes32 => bytes32) prevMap;
        uint256 counter;
        uint96 averagePrice;
    }

    struct Order {
        uint64 owner;
        uint96 buyAmount;
        uint96 sellAmount;
    }

    function initializeEmptyList(Data storage self) internal {
        self.nextMap[QUEUE_START] = QUEUE_END;
        self.prevMap[QUEUE_END] = QUEUE_START;
    }

    function average(Data storage self)
        internal
        view
        returns (uint96 averagePrice, uint256 counter)
    {
        return (self.averagePrice, self.counter);
    }

    function isEmpty(Data storage self) internal view returns (bool) {
        return self.nextMap[QUEUE_START] == QUEUE_END;
    }

    function insert(
        Data storage self,
        bytes32 elementToInsert,
        bytes32 elementBeforeNewOne
    ) internal returns (bool) {
        (, uint96 numerator, uint96 denominator) = decodeOrder(elementToInsert);
        require(denominator != uint96(0), "ERROR_ZERO");
        require(
            elementToInsert != QUEUE_START && elementToInsert != QUEUE_END,
            "INVALID_ELE"
        );
        if (contains(self, elementToInsert)) {
            return false;
        }
        if (
            elementBeforeNewOne != QUEUE_START &&
            self.prevMap[elementBeforeNewOne] == bytes32(0)
        ) {
            return false;
        }
        if (!elementBeforeNewOne.smallerThan(elementToInsert)) {
            return false;
        }

        // `elementBeforeNewOne` might have been removed during the time it
        // took to the transaction calling this function to be mined, so
        // the new order cannot be appended directly to this. We follow the
        // history of previous links backwards until we find an element in
        // the list from which to start our search.
        // Note that following the link backwards returns elements that are
        // before `elementBeforeNewOne` in sorted order.
        while (self.nextMap[elementBeforeNewOne] == bytes32(0)) {
            elementBeforeNewOne = self.prevMap[elementBeforeNewOne];
        }

        // `elementBeforeNewOne` belongs now to the linked list. We search the
        // largest entry that is smaller than the element to insert.
        bytes32 previous;
        bytes32 current = elementBeforeNewOne;
        do {
            previous = current;
            current = self.nextMap[current];
        } while (current.smallerThan(elementToInsert));
        // Note: previous < elementToInsert < current
        self.nextMap[previous] = elementToInsert;
        self.prevMap[current] = elementToInsert;
        self.prevMap[elementToInsert] = previous;
        self.nextMap[elementToInsert] = current;

        self.counter = self.counter + 1;
        self.averagePrice =
            self.averagePrice +
            ((denominator * 10**18) / numerator);

        return true;
    }

    /// The element is removed from the linked list, but the node retains
    /// information on which predecessor it had, so that a node in the chain
    /// can be reached by following the predecessor chain of deleted elements.
    function removeKeepHistory(Data storage self, bytes32 elementToRemove)
        internal
        returns (bool)
    {
        if (!contains(self, elementToRemove)) {
            return false;
        }

        bytes32 previousElement = self.prevMap[elementToRemove];
        bytes32 nextElement = self.nextMap[elementToRemove];
        self.nextMap[previousElement] = nextElement;
        self.prevMap[nextElement] = previousElement;
        self.nextMap[elementToRemove] = bytes32(0);

        return true;
    }

    /// Remove an element from the chain, clearing all related storage.
    /// Note that no elements should be inserted using as a reference point a
    /// node deleted after calling `remove`, since an element in the `prev`
    /// chain might be missing.
    function remove(Data storage self, bytes32 elementToRemove)
        internal
        returns (bool)
    {
        bool result = removeKeepHistory(self, elementToRemove);
        if (result) self.prevMap[elementToRemove] = bytes32(0);

        return result;
    }

    function contains(Data storage self, bytes32 value)
        internal
        view
        returns (bool)
    {
        if (value == QUEUE_START) {
            return false;
        }
        // Note: QUEUE_END is not contained in the list since it has no
        // successor.
        return self.nextMap[value] != bytes32(0);
    }

    // @dev orders are ordered by
    // 1. their price - buyAmount/sellAmount
    // 2. by the sellAmount
    // 3. their userId,
    function smallerThan(bytes32 orderLeft, bytes32 orderRight)
        internal
        pure
        returns (bool)
    {
        (
            uint64 userIdLeft,
            uint96 priceNumeratorLeft,
            uint96 priceDenominatorLeft
        ) = decodeOrder(orderLeft);
        (
            uint64 userIdRight,
            uint96 priceNumeratorRight,
            uint96 priceDenominatorRight
        ) = decodeOrder(orderRight);

        if (
            priceNumeratorLeft.mul(priceDenominatorRight) <
            priceNumeratorRight.mul(priceDenominatorLeft)
        ) return true;
        if (
            priceNumeratorLeft.mul(priceDenominatorRight) >
            priceNumeratorRight.mul(priceDenominatorLeft)
        ) return false;

        if (priceNumeratorLeft < priceNumeratorRight) return true;
        if (priceNumeratorLeft > priceNumeratorRight) return false;
        require(userIdLeft != userIdRight, "ERROR_SAME_ORDER");
        if (userIdLeft < userIdRight) {
            return true;
        }
        return false;
    }

    function first(Data storage self) internal view returns (bytes32) {
        require(!isEmpty(self), "EMPTY_SET");
        return self.nextMap[QUEUE_START];
    }

    function next(Data storage self, bytes32 value)
        internal
        view
        returns (bytes32)
    {
        require(value != QUEUE_END, "ERROR_NEXT");
        bytes32 nextElement = self.nextMap[value];
        require(nextElement != bytes32(0), "NON_EXISTENT");
        return nextElement;
    }

    function decodeOrder(bytes32 _orderData)
        internal
        pure
        returns (
            uint64 userId,
            uint96 buyAmount,
            uint96 sellAmount
        )
    {
        // Note: converting to uint discards the binary digits that do not fit
        // the type.
        userId = uint64(uint256(_orderData) >> 192);
        buyAmount = uint96(uint256(_orderData) >> 96);
        sellAmount = uint96(uint256(_orderData));
    }

    function encodeOrder(
        uint64 userId,
        uint96 buyAmount,
        uint96 sellAmount
    ) internal pure returns (bytes32) {
        return
            bytes32(
                (uint256(userId) << 192) +
                    (uint256(buyAmount) << 96) +
                    uint256(sellAmount)
            );
    }
}


// File contracts/interfaces/AllowListVerifier.sol


pragma solidity >=0.6.8;

library AllowListVerifierHelper {
    /// @dev Value returned by a call to `isAllowed` if the check
    /// was successful. The value is defined as:
    /// bytes4(keccak256("isAllowed(address,uint256,bytes)"))
    bytes4 internal constant MAGICVALUE = 0x19a05a7e;
}

///
/// @dev Standardized interface for an allowList manager for annexAuction
/// The interface was inspired by EIP-1271
interface AllowListVerifier {
    /// @dev Should return whether the a specific user has access to an auction
    /// by returning the magic value from AllowListVerifierHelper
    function isAllowed(
        address user,
        uint256 auctionId,
        bytes calldata callData
    ) external view returns (bytes4);
}


// File contracts/libraries/IdToAddressBiMap.sol


pragma solidity ^0.6.0;

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Contract does not have test coverage, as it was nearly copied from:
// https://github.com/gnosis/solidity-data-structures/blob/master/contracts/libraries/IdToAddressBiMap.sol
// The only change is uint16 -> uint64
///////////////////////////////////////////////////////////////////////////////////////////////////////////

/** 
    INVALID_ID: Must have ID to get Address
    INVALID_ADDRESS: Must have Address to get ID
    ERROR_ZERO : Cannot insert zero address
    ERROR_64 : Cannot insert max uint64
**/

library IdToAddressBiMap {
    struct Data {
        mapping(uint64 => address) idToAddress;
        mapping(address => uint64) addressToId;
    }

    function hasId(Data storage self, uint64 id) internal view returns (bool) {
        return self.idToAddress[id + 1] != address(0);
    }

    function hasAddress(Data storage self, address addr)
        internal
        view
        returns (bool)
    {
        return self.addressToId[addr] != 0;
    }

    function getAddressAt(Data storage self, uint64 id)
        internal
        view
        returns (address)
    {
        require(hasId(self, id), "INVALID_ID");
        return self.idToAddress[id + 1];
    }

    function getId(Data storage self, address addr)
        internal
        view
        returns (uint64)
    {
        require(hasAddress(self, addr), "INVALID_ADDRESS");
        return self.addressToId[addr] - 1;
    }

    function insert(
        Data storage self,
        uint64 id,
        address addr
    ) internal returns (bool) {
        require(addr != address(0), "ERROR_ZERO");
        require(id != uint64(-1), "ERROR_64");
        // Ensure bijectivity of the mappings
        if (
            self.addressToId[addr] != 0 ||
            self.idToAddress[id + 1] != address(0)
        ) {
            return false;
        }
        self.idToAddress[id + 1] = addr;
        self.addressToId[addr] = id + 1;
        return true;
    }
}


// File contracts/libraries/SafeCast.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Logic was copied and modified from here: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/SafeCast.sol
 */
library SafeCast {
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value < 2**96, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }
}


// File contracts/interfaces/IDocuments.sol


pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IDocuments {
    function _removeDocument(string calldata _name) external;

    function getDocumentCount() external view returns (uint256);

    function getAllDocuments() external view returns (bytes memory);

    function _setDocument(string calldata _name, string calldata _data)
        external;

    function getDocumentName(uint256 _index)
        external
        view
        returns (string memory);

    function getDocument(string calldata _name)
        external
        view
        returns (string memory, uint256);
}


// File contracts/interfaces/IPancakeswapV2Pair.sol


pragma solidity >=0.5.0;

interface IPancakeswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}


// File contracts/interfaces/IPancakeswapV2Factory.sol


pragma solidity >=0.5.0;

interface IPancakeswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}


// File contracts/interfaces/IPancakeswapV2Router02.sol


pragma solidity >=0.6.2;

interface IPancakeswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);
}

interface IPancakeswapV2Router02 is IPancakeswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// File contracts/AnnexBatchAuction.sol


pragma solidity ^0.6.0;


// import "hardhat/console.sol";
/**
Errors details
    ERROR_ORDER_PLACEMENT = no longer in order placement phase
    ERROR_ORDER_CANCELATION = no longer in order placement and cancelation phase
    ERROR_SOL_SUB = Auction not in solution submission phase
    ERROR_NOT_FINSIHED = Auction not yet finished
    ERROR_INVALID_FEE = Fee is not allowed to be set higher than 1.5%
    ERROR_MUST_GT_ZERO = _minBuyAmounts must be greater than 0
    NOT_ENOUGH_ANN = Auctioner does not have enough Ann
    TOO_SMALL = order too small
    INVALID_AUCTION_TOKENS = cannot auction zero tokens and must be less than threshold
    TOKENS_CANT_AUCTIONED_FREE = tokens cannot be auctioned for free
    MUST_NOT_ZERO = minimumBiddingAmountPerOrder is not allowed to be zero
    ERROR_TIME_PERIOD = time periods are not configured correctly
    INVALID_AUTION_END = auction end date must be in the future
    ONLY_USER_CAN_CANCEL = Only the user can cancel his orders
    REACHED_END = reached end of order list
    TOO_MANY_ORDERS = too many orders summed up
    NOT_SETTLED = not allowed to settle auction atomically 
    ERROR_PALCE_AUTOMATICALLY = Only one order can be placed atomically
    TOO_ADVANCED = precalculateSellAmountSum is already too advanced
    REGISTERED = User already registered
    NOT_ALLOWED= user not allowed to place order
    INVALID_LIMIT_PRICE = limit price not better than mimimal offer
    NOT_CLAIMABLE = order is no longer claimable
    SAME_USER_CAN_CLAIM= only allowed to claim for same user
    PENDING_PHASE = not started yet
    INVALID_AUCTION_START = invalid start date
**/

contract AnnexBatchAuction is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint64;
    using SafeMath for uint96;
    using SafeMath for uint256;
    using SafeCast for uint256;
    using IterableOrderedOrderSet for IterableOrderedOrderSet.Data;
    using IterableOrderedOrderSet for bytes32;
    using IdToAddressBiMap for IdToAddressBiMap.Data;

    struct AuctionAbout{
        string telegram;
        string discord;
        string medium;
        string twitter;
        string description;
    }

    struct AuctionReq {
        IERC20 _auctioningToken;
        IERC20 _biddingToken;
        address accessManagerContract;
        uint256 orderCancellationEndDate;
        uint256 auctionStartDate;
        uint256 auctionEndDate;
        uint256 minimumBiddingAmountPerOrder;
        uint256 minFundingThreshold;
        uint96 _auctionedSellAmount;
        uint96 _minBuyAmount;
        bool isAtomicClosureAllowed;
        bytes accessManagerContractData;
        uint8 router;
        AuctionAbout about;
    }

    struct AuctionData {
        // address of bidding token
        IERC20 auctioningToken;
        // address of auctioning token
        IERC20 biddingToken;
        // This will be the date after which the bidder cannot cancel his orders.
        uint256 orderCancellationEndDate;
        // auction end date at which auction will end
        uint256 auctionEndDate;
        // This will be the minimum amount of bidding tokens a bidder can bid
        uint256 minimumBiddingAmountPerOrder;
        // this will be the sum of bid amount during precalculateSellAmountSum()
        uint256 interimSumBidAmount;
        // auction fee for auctioneer
        uint256 feeNumerator;
        // this will be the minimum funding threshold of bidding tokens that auctioneer
        // wants in return of auctioning tokens.
        uint256 minFundingThreshold;
        // This will be the initial order during auction creation which will be consist of
        // minimum buy amount against all auctioned tokens and total auctioned tokens by auctioneer
        bytes32 initialAuctionOrder;
        // The last viewed order during precalculateSellAmountSum function.
        bytes32 interimOrder;
        // The last order at which auction will be concluded will be the clearingPriceOrder
        // bytes32 clearingPriceOrder;
        uint96 volumeClearingPriceOrder;
        // flag to check either auction get reached minimum funding threshold or not
        bool minFundingThresholdNotReached;
        // flag for automatically auction settlement
        bool isAtomicClosureAllowed;
    }

    mapping(uint256 => IterableOrderedOrderSet.Data) internal sellOrders; // Store total number of sell orders
    mapping(uint256 => AuctionData) public auctionData; // Store auctions details
    mapping(uint256 => address) public auctionAccessManager;
    mapping(uint256 => bytes) public auctionAccessData;
    // auctionId => order bytes
    mapping(uint256 => bytes32) public clearingPriceOrders; // clearing price orders
    // auctionId => starting date
    mapping(uint256 => uint256) public startingDate; // starting date
    // auctionId => IPancakeswapV2Pair (liquidity pool)
    //address of pancakeswap liquidity pools of pairs auctioningToken-biddingToken
    mapping(uint256 => address) public liquidityPools;
    mapping(uint256 => uint256) public poolLiquidities;
    // auctionId => pancakeswapV2Router address
    mapping(uint256 => address) public pancakeswapV2Router;
    // address for PancakeswapV2Router02
    address[] public routers;

    IDocuments public documents; // for storing documents
    IERC20 public annexToken;
    address public treasury;

    IdToAddressBiMap.Data private registeredUsers;
    uint256 public auctionCounter; // counter for auctions
    uint256 public feeNumerator = 0;
    uint256 public constant FEE_DENOMINATOR = 1000;
    uint256 public threshold = 100 ether; // 100 ANN

    uint64 public feeReceiverUserId = 1;
    uint64 public numUsers; // counter of users

    modifier atStageOrderPlacement(uint256 auctionId) {
        require(
            block.timestamp > startingDate[auctionId],
            "ERROR_NOT_STARTED" // not started yet
        );
        require(
            block.timestamp < auctionData[auctionId].auctionEndDate,
            "ERROR_ORDER_PLACEMENT" // no longer in order placement phase
        );
        _;
    }

    modifier atStageOrderPlacementAndCancelation(uint256 auctionId) {
        require(
            block.timestamp < auctionData[auctionId].orderCancellationEndDate,
            "ERROR_ORDER_CANCELATION"
        );
        _;
    }

    modifier atStageSolutionSubmission(uint256 auctionId) {
        {
            uint256 auctionEndDate = auctionData[auctionId].auctionEndDate;
            require(
                auctionEndDate != 0 &&
                    block.timestamp >= auctionEndDate &&
                    clearingPriceOrders[auctionId] == bytes32(0),
                "ERROR_SOL_SUB"
            );
        }
        _;
    }

    modifier atStageFinished(uint256 auctionId) {
        require(
            clearingPriceOrders[auctionId] != bytes32(0),
            "ERROR_NOT_FINSIHED"
        );
        _;
    }

    event NewSellOrder(
        uint256 indexed auctionId,
        uint64 indexed userId,
        uint96 buyAmount,
        uint96 sellAmount
    );
    event CancellationSellOrder(
        uint256 indexed auctionId,
        uint64 indexed userId,
        uint96 buyAmount,
        uint96 sellAmount
    );
    event ClaimedFromOrder(
        uint256 indexed auctionId,
        uint64 indexed userId,
        uint96 buyAmount,
        uint96 sellAmount
    );
    event ClaimedLPFromOrder(
        uint256 indexed auctionId,
        uint64 userId,
        uint256 sumBiddingTokenAmount,
        uint256 lps
    );

    event NewUser(uint64 indexed userId, address indexed userAddress);
    event NewAuction(
        uint256 indexed auctionId,
        IERC20 indexed _auctioningToken,
        IERC20 indexed _biddingToken,
        uint256 orderCancellationEndDate,
        uint256 auctionStartDate,
        uint256 auctionEndDate,
        uint64 userId,
        uint96 _auctionedSellAmount,
        uint96 _minBuyAmount,
        uint256 minimumBiddingAmountPerOrder
    );
    event AuctionCleared(
        uint256 indexed auctionId,
        uint96 soldAuctioningTokens,
        uint96 soldBiddingTokens,
        bytes32 clearingPriceOrder
    );
    event UserRegistration(address indexed user, uint64 userId);
    event AddRouters(address[] indexed routers);
    event AddLiquidity(uint256 indexed auctionId, uint256 liquidity);

    event CalculatedLP(
        uint256 indexed auctionId,
        uint256 biddingTokenAmount,
        uint256 totalBiddingTokenAmount,
        uint256 totalLP
    );

    event Bidder(
        uint256 indexed auctionId,
        uint96 buyAmount,
        uint96 sellAmount,
        uint64 userId,
        string status
    );

    event AuctionDetails(
        uint256 indexed auctionId,
        string telegram,
        string discord,
        string medium,
        string twitter,
        string description
    );

    constructor() public {}

    function setFeeParameters(
        uint256 newFeeNumerator,
        address newfeeReceiverAddress
    ) public onlyOwner() {
        require(
            newFeeNumerator <= 15,
            "ERROR_INVALID_FEE" // Fee is not allowed to be set higher than 1.5%
        );
        // caution: for currently running auctions, the feeReceiverUserId is changing as well.
        feeReceiverUserId = getUserId(newfeeReceiverAddress);
        feeNumerator = newFeeNumerator;
    }

    // @dev: function to intiate a new auction
    // Warning: In case the auction is expected to raise more than
    // 2^96 units of the biddingToken, don't start the auction, as
    // it will not be settlable. This corresponds to about 79
    // billion DAI.
    //
    // Prices between biddingToken and auctioningToken are expressed by a
    // fraction whose components are stored as uint96.
    // Amount transfered out is no larger than amount transfered in
    // auctioning Token = USDT
    // bidding Token    = ANN
    // pair             = USDT-ANN

    function initiateAuction(AuctionReq calldata auction)
        public
        returns (uint256)
    {
        // Auctioner can init an auction if he has 100 Ann
        require(
            annexToken.balanceOf(msg.sender) >= threshold,
            "NOT_ENOUGH_ANN"
        );
        annexToken.safeTransferFrom(msg.sender,treasury,100 ether);
        auction._auctioningToken.safeTransferFrom(
            msg.sender,
            address(this),
            auction
                ._auctionedSellAmount
                .mul(FEE_DENOMINATOR.add(feeNumerator))
                .div(FEE_DENOMINATOR) //[0]
        );
        require(auction._auctionedSellAmount > 0, "INVALID_AUCTION_TOKENS"); //
        require(auction._minBuyAmount > 0, "TOKENS_CANT_AUCTIONED_FREE"); // tokens cannot be auctioned for free
        require(auction.minimumBiddingAmountPerOrder > 0, "MUST_NOT_ZERO");
        require(
            auction.orderCancellationEndDate <= auction.auctionEndDate,
            "ERROR_TIME_PERIOD"
        );
        // require(auction.auctionStartDate > block.timestamp && auction.auctionStartDate < auction.auctionEndDate , "INVALID_AUCTION_START");
        require(auction.auctionEndDate > block.timestamp, "INVALID_AUTION_END");
        auctionCounter = auctionCounter.add(1);
        sellOrders[auctionCounter].initializeEmptyList();
        uint64 userId = getUserId(msg.sender);

        {
            auctionData[auctionCounter] = AuctionData(
                auction._auctioningToken,
                auction._biddingToken,
                auction.orderCancellationEndDate,
                auction.auctionEndDate,
                auction.minimumBiddingAmountPerOrder,
                0,
                feeNumerator,
                auction.minFundingThreshold,
                IterableOrderedOrderSet.encodeOrder(
                    userId,
                    auction._minBuyAmount,
                    auction._auctionedSellAmount
                ),
                IterableOrderedOrderSet.QUEUE_START,
                0,
                false,
                auction.isAtomicClosureAllowed
            );
            pancakeswapV2Router[auctionCounter] = routers[auction.router];
        }
        startingDate[auctionCounter] = auction.auctionStartDate;
        auctionAccessManager[auctionCounter] = auction.accessManagerContract;
        auctionAccessData[auctionCounter] = auction.accessManagerContractData;

        emit NewAuction(
            auctionCounter,
            auction._auctioningToken,
            auction._biddingToken,
            auction.orderCancellationEndDate,
            auction.auctionStartDate,
            auction.auctionEndDate,
            userId,
            auction._auctionedSellAmount,
            auction._minBuyAmount,
            auction.minimumBiddingAmountPerOrder
        );
        emit AuctionDetails(
            auctionCounter,
            auction.about.telegram,
            auction.about.discord,
            auction.about.medium,
            auction.about.twitter,
            auction.about.description
        );
        return auctionCounter;
    }

    function placeSellOrders(
        uint256 auctionId,
        uint96[] memory _minBuyAmounts,
        uint96[] memory _sellAmounts,
        bytes32[] memory _prevSellOrders,
        bytes calldata allowListCallData
    ) external atStageOrderPlacement(auctionId) returns (uint64 userId) {
        return
            _placeSellOrders(
                auctionId,
                _minBuyAmounts,
                _sellAmounts,
                _prevSellOrders,
                allowListCallData,
                msg.sender
            );
    }

    function placeSellOrdersOnBehalf(
        uint256 auctionId,
        uint96[] memory _minBuyAmounts,
        uint96[] memory _sellAmounts,
        bytes32[] memory _prevSellOrders,
        bytes calldata allowListCallData,
        address orderSubmitter
    ) external atStageOrderPlacement(auctionId) returns (uint64 userId) {
        return
            _placeSellOrders(
                auctionId,
                _minBuyAmounts,
                _sellAmounts,
                _prevSellOrders,
                allowListCallData,
                orderSubmitter
            );
    }

    function _placeSellOrders(
        uint256 auctionId,
        uint96[] memory _minBuyAmounts,
        uint96[] memory _sellAmounts,
        bytes32[] memory _prevSellOrders,
        bytes calldata allowListCallData,
        address orderSubmitter
    ) internal returns (uint64 userId) {
        {
            address allowListManager = auctionAccessManager[auctionId];
            if (allowListManager != address(0)) {
                require(
                    AllowListVerifier(allowListManager).isAllowed(
                        orderSubmitter,
                        auctionId,
                        allowListCallData
                    ) == AllowListVerifierHelper.MAGICVALUE,
                    "NOT_ALLOWED"
                );
            }
        }
        {
            (
                ,
                uint96 buyAmountOfInitialAuctionOrder,
                uint96 sellAmountOfInitialAuctionOrder
            ) = auctionData[auctionId].initialAuctionOrder.decodeOrder();
            for (uint256 i = 0; i < _minBuyAmounts.length; i++) {
                require(
                    _minBuyAmounts[i].mul(buyAmountOfInitialAuctionOrder) <
                        sellAmountOfInitialAuctionOrder.mul(_sellAmounts[i]),
                    "INVALID_LIMIT_PRICE"
                );
            }
        }
        uint256 sumOfSellAmounts = 0;
        userId = getUserId(orderSubmitter);
        uint256 minimumBiddingAmountPerOrder = auctionData[auctionId]
        .minimumBiddingAmountPerOrder;
        for (uint256 i = 0; i < _minBuyAmounts.length; i++) {
            require(
                _minBuyAmounts[i] > 0,
                "ERROR_MUST_GT_ZERO" //_minBuyAmounts must be greater than 0
            );
            // orders should have a minimum bid size in order to limit the gas
            // required to compute the final price of the auction.
            require(
                _sellAmounts[i] > minimumBiddingAmountPerOrder,
                "TOO_SMALL" // order too small
            );
            if (
                sellOrders[auctionId].insert(
                    IterableOrderedOrderSet.encodeOrder(
                        userId,
                        _minBuyAmounts[i],
                        _sellAmounts[i]
                    ),
                    _prevSellOrders[i]
                )
            ) {
                sumOfSellAmounts = sumOfSellAmounts.add(_sellAmounts[i]);
                emit NewSellOrder(
                    auctionId,
                    userId,
                    _minBuyAmounts[i],
                    _sellAmounts[i]
                );
            }
        }

        auctionData[auctionId].biddingToken.safeTransferFrom(
            msg.sender,
            address(this),
            sumOfSellAmounts
        ); //[1]
    }

    function cancelSellOrders(uint256 auctionId, bytes32[] memory _sellOrders)
        public
        atStageOrderPlacementAndCancelation(auctionId)
    {
        uint64 userId = getUserId(msg.sender);
        uint256 claimableAmount = 0;
        for (uint256 i = 0; i < _sellOrders.length; i++) {
            // Note: we keep the back pointer of the deleted element so that
            // it can be used as a reference point to insert a new node.
            bool success = sellOrders[auctionId].removeKeepHistory(
                _sellOrders[i]
            );
            if (success) {
                (
                    uint64 userIdOfIter,
                    uint96 buyAmountOfIter,
                    uint96 sellAmountOfIter
                ) = _sellOrders[i].decodeOrder();
                require(
                    userIdOfIter == userId,
                    "ONLY_USER_CAN_CANCEL" // Only the user can cancel his orders
                );
                claimableAmount = claimableAmount.add(sellAmountOfIter);
                emit CancellationSellOrder(
                    auctionId,
                    userId,
                    buyAmountOfIter,
                    sellAmountOfIter
                );
            }
        }
        auctionData[auctionId].biddingToken.safeTransfer(
            msg.sender,
            claimableAmount
        ); //[2]
    }

    // @note this function should be called before settling the acution
    // By calling this function you can pre calculate(before auction ending) sum of total
    // total token sold.This function will calculate sum by taking offsent of orders linked list.
    function precalculateSellAmountSum(
        uint256 auctionId,
        uint256 iterationSteps
    ) public atStageSolutionSubmission(auctionId) {
        (, , uint96 auctioneerSellAmount) = auctionData[auctionId].initialAuctionOrder.decodeOrder();
        uint256 sumBidAmount = auctionData[auctionId].interimSumBidAmount;
        bytes32 iterOrder = auctionData[auctionId].interimOrder;

        for (uint256 i = 0; i < iterationSteps; i++) {
            iterOrder = sellOrders[auctionId].next(iterOrder);
            (, , uint96 sellAmountOfIter) = iterOrder.decodeOrder();
            sumBidAmount = sumBidAmount.add(sellAmountOfIter);
        }

        require(
            iterOrder != IterableOrderedOrderSet.QUEUE_END,
            "REACHED_END" //reached end of order list
        );

        // it is checked that not too many iteration steps were taken:
        // require that the sum of SellAmounts times the price of the last order
        // is not more than initially sold amount
        (, uint96 buyAmountOfIter, uint96 sellAmountOfIter) = iterOrder
        .decodeOrder();
        require(
            sumBidAmount.mul(buyAmountOfIter) <
                auctioneerSellAmount.mul(sellAmountOfIter),
            "TOO_MANY_ORDERS" // too many orders summed up
        );

        auctionData[auctionId].interimSumBidAmount = sumBidAmount;
        auctionData[auctionId].interimOrder = iterOrder;
    }

    function settleAuctionAtomically(
        uint256 auctionId,
        uint96[] memory _minBuyAmount,
        uint96[] memory _sellAmount,
        bytes32[] memory _prevSellOrder,
        bytes calldata allowListCallData
    ) public atStageSolutionSubmission(auctionId) {
        require(
            auctionData[auctionId].isAtomicClosureAllowed,
            "NOT_SETTLED" // not allowed to settle auction atomically
        );
        require(
            _minBuyAmount.length == 1 && _sellAmount.length == 1,
            "ERROR_PALCE_AUTOMATICALLY" //Only one order can be placed atomically
        );
        uint64 userId = getUserId(msg.sender);
        require(
            auctionData[auctionId].interimOrder.smallerThan(
                IterableOrderedOrderSet.encodeOrder(
                    userId,
                    _minBuyAmount[0],
                    _sellAmount[0]
                )
            ),
            "TOO_ADVANCED" // precalculateSellAmountSum is already too advanced
        );
        _placeSellOrders(
            auctionId,
            _minBuyAmount,
            _sellAmount,
            _prevSellOrder,
            allowListCallData,
            msg.sender
        );
        settleAuction(auctionId);
    }

    // // @dev function settling the auction and calculating the price
    function settleAuction(uint256 auctionId)
        public
        atStageSolutionSubmission(auctionId)
        returns (bytes32 clearingOrder)
    {
        (
            uint64 auctioneerId,
            uint96 minAuctionedBuyAmount,
            uint96 fullAuctionedAmount
        ) = auctionData[auctionId].initialAuctionOrder.decodeOrder();

        uint256 currentBidSum = auctionData[auctionId].interimSumBidAmount;
        bytes32 currentOrder = auctionData[auctionId].interimOrder;
        uint256 buyAmountOfIter;
        uint256 sellAmountOfIter;
        uint96 fillVolumeOfAuctioneerOrder = fullAuctionedAmount;
        // Sum order up, until fullAuctionedAmount is fully bought or queue end is reached
        do {
            bytes32 nextOrder = sellOrders[auctionId].next(currentOrder);
            if (nextOrder == IterableOrderedOrderSet.QUEUE_END) {
                break;
            }
            currentOrder = nextOrder;
            (, buyAmountOfIter, sellAmountOfIter) = currentOrder.decodeOrder();
            currentBidSum = currentBidSum.add(sellAmountOfIter);
        } while (
            currentBidSum.mul(buyAmountOfIter) <
                fullAuctionedAmount.mul(sellAmountOfIter)
        );

        if (
            currentBidSum > 0 &&
            currentBidSum.mul(buyAmountOfIter) >=
            fullAuctionedAmount.mul(sellAmountOfIter)
        ) {
            // All considered/summed orders are sufficient to close the auction fully
            // at price between current and previous orders.
            uint256 uncoveredBids = currentBidSum.sub(
                fullAuctionedAmount.mul(sellAmountOfIter).div(buyAmountOfIter)
            );

            if (sellAmountOfIter >= uncoveredBids) {
                //[13]
                // Auction fully filled via partial match of currentOrder
                uint256 sellAmountClearingOrder = sellAmountOfIter.sub(
                    uncoveredBids
                );
                auctionData[auctionId]
                .volumeClearingPriceOrder = sellAmountClearingOrder.toUint96();
                currentBidSum = currentBidSum.sub(uncoveredBids);
                clearingOrder = currentOrder;
            } else {
                //[14]
                // Auction fully filled via price strictly between currentOrder and the order
                // immediately before. For a proof, see the security-considerations.md
                currentBidSum = currentBidSum.sub(sellAmountOfIter);
                clearingOrder = IterableOrderedOrderSet.encodeOrder(
                    0,
                    fullAuctionedAmount,
                    currentBidSum.toUint96()
                );
            }
        } else {
            // All considered/summed orders are not sufficient to close the auction fully at price of last order //[18]
            // Either a higher price must be used or auction is only partially filled

            if (currentBidSum > minAuctionedBuyAmount) {
                //[15]
                // Price higher than last order would fill the auction
                clearingOrder = IterableOrderedOrderSet.encodeOrder(
                    0,
                    fullAuctionedAmount,
                    currentBidSum.toUint96()
                );
            } else {
                //[16]
                // Even at the initial auction price, the auction is partially filled
                clearingOrder = IterableOrderedOrderSet.encodeOrder(
                    0,
                    fullAuctionedAmount,
                    minAuctionedBuyAmount
                );
                fillVolumeOfAuctioneerOrder = currentBidSum
                .mul(fullAuctionedAmount)
                .div(minAuctionedBuyAmount)
                .toUint96();
            }
        }
        clearingPriceOrders[auctionId] = clearingOrder;
        if (auctionData[auctionId].minFundingThreshold > currentBidSum) {
            auctionData[auctionId].minFundingThresholdNotReached = true;
        }

        processFeesAndAuctioneerFunds(
            auctionId,
            fillVolumeOfAuctioneerOrder,
            auctioneerId,
            fullAuctionedAmount
        );
        emit AuctionCleared(
            auctionId,
            fillVolumeOfAuctioneerOrder,
            uint96(currentBidSum),
            clearingOrder
        );
        // Gas refunds
        auctionAccessManager[auctionId] = address(0);
        delete auctionAccessData[auctionId];
        auctionData[auctionId].initialAuctionOrder = bytes32(0);
        auctionData[auctionId].interimOrder = bytes32(0);
        auctionData[auctionId].interimSumBidAmount = uint256(0);
        auctionData[auctionId].minimumBiddingAmountPerOrder = uint256(0);
    }

    /**

    First we will remove the given orders from contract sell orders list.
    **/
    function claimFromParticipantOrder(
        uint256 auctionId,
        bytes32[] memory orders
    )
        public
        atStageFinished(auctionId)
        returns (uint256 sumBiddingTokenAmount, uint256 rSumBiddingTokenAmount,uint256 lpTokens)
    {
        for (uint256 i = 0; i < orders.length; i++) {
            // Note: we don't need to keep any information about the node since
            // no new elements need to be inserted.
            require(sellOrders[auctionId].remove(orders[i]), "NOT_CLAIMABLE");
        }
        AuctionData memory auction = auctionData[auctionId];
        bytes32 clearingPriceOrder = clearingPriceOrders[auctionId];
        // (, uint96 priceNumerator, uint96 priceDenominator) = clearingPriceOrder
        // .decodeOrder();

        (uint64 userId, , ) = orders[0].decodeOrder();
        bool minFundingThresholdNotReached = auction
        .minFundingThresholdNotReached;
        for (uint256 i = 0; i < orders.length; i++) {
            (uint64 userIdOrder, uint96 buyAmount, uint96 sellAmount) = orders[
                i
            ]
            .decodeOrder();
            require(userIdOrder == userId, "SAME_USER_CAN_CLAIM");
            if (minFundingThresholdNotReached) {
                //[10]
                rSumBiddingTokenAmount = rSumBiddingTokenAmount.add(
                    sellAmount
                );
            } else {
                //[23]
                if (orders[i] == clearingPriceOrder) {
                    //[25]
                     {
                            sumBiddingTokenAmount = sumBiddingTokenAmount.add(
                                sellAmount
                            );

                            rSumBiddingTokenAmount = rSumBiddingTokenAmount.add(
                            sellAmount.sub(auction.volumeClearingPriceOrder)
                            );
                        }
                        emit Bidder(auctionId,buyAmount,sellAmount,userIdOrder,"SUCCESS");
                } else {
                    if (orders[i].smallerThan(clearingPriceOrder)) {
                        //[17]
                        // In case of successful order:
                        // Don't need to calculate sumAuctioningTokenAmount because we are not sending auctioning tokens to
                        // the bidder so here we will calculate sumBiddingTokenAmount and conside this order as a successful order
                        {
                            sumBiddingTokenAmount = sumBiddingTokenAmount.add(
                                sellAmount
                            );
                        }
                        emit Bidder(auctionId,buyAmount,sellAmount,userIdOrder,"SUCCESS");
                    } else {
                        //[24]
                        // In case of unsuccessful order we will calculate totalBiddingToken
                        //amount to return it to the bidder.
                        {
                            rSumBiddingTokenAmount = rSumBiddingTokenAmount
                            .add(sellAmount);
                        }
                        emit Bidder(auctionId,buyAmount,sellAmount,userIdOrder,"FAILED");
                    }
                }
            }
            emit ClaimedFromOrder(auctionId, userId, buyAmount, sellAmount);
        }   

        // here we will calculate user lp tokens using his bidding tokens
        // if minimum funding threshold is not reached then we will simply
        //send back his bidding tokens otherwise we will send his lp tokens.
        if (minFundingThresholdNotReached) {
            sendOutTokens(auctionId, 0, rSumBiddingTokenAmount, userId); //[3]
        }
        if (!minFundingThresholdNotReached) {
            sendOutTokens(auctionId, 0, rSumBiddingTokenAmount, userId); //[3]

            if (sumBiddingTokenAmount > 0) {
                lpTokens = calculateLPTokens(auctionId, sumBiddingTokenAmount);
                IPancakeswapV2Pair(liquidityPools[auctionId]).transfer(
                    registeredUsers.getAddressAt(userId),
                    lpTokens
                );
                emit ClaimedLPFromOrder(
                    auctionId,
                    userId,
                    sumBiddingTokenAmount,
                    lpTokens
                );
            }
        }
    }

    function processFeesAndAuctioneerFunds(
        uint256 auctionId,
        uint256 fillVolumeOfAuctioneerOrder,
        uint64 auctioneerId,
        uint96 fullAuctionedAmount
    ) internal {
        uint256 feeAmount = fullAuctionedAmount
        .mul(auctionData[auctionId].feeNumerator)
        .div(FEE_DENOMINATOR); //[20]
        // if minimum funding threshold is not reached we will send back all auctioning tokens
        // to the auctioneer
        if (auctionData[auctionId].minFundingThresholdNotReached) {
            sendOutTokens(
                auctionId,
                fullAuctionedAmount.add(feeAmount),
                0,
                auctioneerId
            ); //[4]
        } else {
            //[11]
            (
                ,
                uint96 priceNumerator,
                uint96 priceDenominator
            ) = clearingPriceOrders[auctionId].decodeOrder();
            // fillVolumeOfAuctioneerOrder is the amount of tokens that is filled
            // fullAuctionedAmount is the amount of tokens that is auctioned by auctioneer
            // unsettledAuctionTokens = fullAuctionedAmount - fillVolumeOfAuctioneerOrder
            // remaining auctioning tokens which are not sold
            uint256 unsettledAuctionTokens = fullAuctionedAmount.sub(
                fillVolumeOfAuctioneerOrder
            );
            // auctioningTokenAmount = unsettledAuctionTokens + ( ( feeAmount * unsettledAuctionTokens ) / fullAuctionedAmount)
            // unsettled auctioning tokens which will be sent back to the auctioneer
            uint256 auctioningTokenAmount = unsettledAuctionTokens.add(
                feeAmount.mul(unsettledAuctionTokens).div(fullAuctionedAmount)
            );
            // biddingTokenAmount = (fillVolumeOfAuctioneerOrder * priceDenominator) / priceNumerator
            // biddingTokenAmount is the amount of tokens which has been collected against sold auctioning tokens
            uint256 biddingTokenAmount = fillVolumeOfAuctioneerOrder
            .mul(priceDenominator)
            .div(priceNumerator);

            // instead of send bidding tokens to the auctioneer account we will add these bidding tokens
            // to the pool with total auctioned amount of tokens.
            uint256 liquidity = addLiquidity(
                auctionId,
                fillVolumeOfAuctioneerOrder, // just add the sold amount of auctioning tokens to the pool
                biddingTokenAmount
            );
            poolLiquidities[auctionId] = liquidity;
            emit AddLiquidity(auctionId, liquidity);
            sendOutTokens(auctionId, auctioningTokenAmount, 0, auctioneerId); //[5]
            // (feeAmount * fillVolumeOfAuctioneerOrder) / fullAuctionedAmount
            sendOutTokens(
                auctionId,
                feeAmount.mul(fillVolumeOfAuctioneerOrder).div(
                    fullAuctionedAmount
                ),
                0,
                feeReceiverUserId
            ); //[7]
        }
    }

    function calculateLPTokens(uint256 auctionId, uint256 biddingTokenAmount)
        public
        returns (uint256)
    {
        (, , uint256 totalBiddingTokenAmount) = clearingPriceOrders[auctionId]
        .decodeOrder(); // fetching total bidding amounts of tokens from clearing price order

        uint256 totalLP = poolLiquidities[auctionId];
        emit CalculatedLP(
            auctionId,
            biddingTokenAmount,
            totalBiddingTokenAmount,
            totalLP
        );
        return
            biddingTokenAmount
                .mul(10**18)
                .div(totalBiddingTokenAmount)
                .mul(totalLP.div(2))
                .div(10**18);
    }

    function addLiquidity(
        uint256 auctionId,
        uint256 auctionTokenAmount,
        uint256 biddingTokenAmount
    ) internal returns (uint256 liquidity) {
        // approve token transfer to cover all possible scenarios
        AuctionData storage auction = auctionData[auctionId];
        auction.auctioningToken.approve(
            address(pancakeswapV2Router[auctionId]),
            auctionTokenAmount
        );
        auction.biddingToken.approve(
            address(pancakeswapV2Router[auctionId]),
            biddingTokenAmount
        );
        // add the liquidity
        (, , liquidity) = IPancakeswapV2Router02(pancakeswapV2Router[auctionId])
        .addLiquidity(
            address(auction.auctioningToken),
            address(auction.biddingToken),
            auctionTokenAmount,
            biddingTokenAmount,
            0,
            0,
            address(this),
            block.timestamp + 600
        );
        liquidityPools[auctionId] = IPancakeswapV2Factory(
            IPancakeswapV2Router02(pancakeswapV2Router[auctionId]).factory()
        ).getPair(
            address(auction.auctioningToken),
            address(auction.biddingToken)
        );
    }

    /* send back either auctioning or bidding tokens to the given user.
    Transfers out occur on:
    1- order cancellation,giving back the amount bid by the user in an order.
    2- users claiming funds after the auction is concluded 
    3- auction closing and sending
        1-funds to the auctioneer
        2-fees to the dedicated address
    */
    function sendOutTokens(
        uint256 auctionId,
        uint256 auctioningTokenAmount,
        uint256 biddingTokenAmount,
        uint64 userId
    ) internal {
        address userAddress = registeredUsers.getAddressAt(userId);
        if (auctioningTokenAmount > 0) {
            auctionData[auctionId].auctioningToken.safeTransfer(
                userAddress,
                auctioningTokenAmount
            );
        }
        if (biddingTokenAmount > 0) {
            auctionData[auctionId].biddingToken.safeTransfer(
                userAddress,
                biddingTokenAmount
            );
        }
    }

    function registerUser(address user) public returns (uint64) {
        numUsers = numUsers.add(1).toUint64();
        require(
            registeredUsers.insert(numUsers, user),
            "REGISTERED" // User already registered
        );
        emit UserRegistration(user, numUsers);
        return numUsers;
    }

    function getUserAddress(uint256 userId) external view returns (address) {
        return
            registeredUsers.hasId(userId.toUint64()) == true
                ? registeredUsers.getAddressAt(userId.toUint64())
                : address(0);
    }

    function getUserId(address user) public returns (uint64 userId) {
        if (registeredUsers.hasAddress(user)) {
            userId = registeredUsers.getId(user);
        } else {
            userId = registerUser(user);
            emit NewUser(userId, user);
        }
    }

    function getSecondsRemainingInBatch(uint256 auctionId)
        public
        view
        returns (uint256)
    {
        if (auctionData[auctionId].auctionEndDate < block.timestamp) {
            return 0;
        }
        return auctionData[auctionId].auctionEndDate.sub(block.timestamp);
    }

    function containsOrder(uint256 auctionId, bytes32 order)
        public
        view
        returns (bool)
    {
        return sellOrders[auctionId].contains(order);
    }

    //--------------------------------------------------------
    // Getter & Setters
    //--------------------------------------------------------

    function setThreshold(uint256 _threshold) external onlyOwner {
        threshold = _threshold;
    }

    function setAnnexAddress(address _annexToken) external onlyOwner {
        annexToken = IERC20(_annexToken);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setRouters(address[] memory _routers) external onlyOwner {
        for (uint8 i = 0; i < _routers.length; i++) {
            routers.push(_routers[i]);
        }
        emit AddRouters(_routers);
    }

    function setDocumentAddress(address _document) external onlyOwner {
        documents = IDocuments(_document);
    }

    function getAuctionInfo(uint256 auctionId)
        external
        view
        atStageFinished(auctionId)
        returns (
            uint256 auctioningToken,
            uint256 biddingToken,
            uint112 reserve0,
            uint112 reserve1
        )
    {
        auctioningToken = auctionData[auctionId].auctioningToken.balanceOf(
            address(this)
        );
        biddingToken = auctionData[auctionId].biddingToken.balanceOf(
            address(this)
        );
        (reserve0, reserve1, ) = IPancakeswapV2Pair(liquidityPools[auctionId])
        .getReserves();
    }

    // Every successful bid will be the part of lp token price
    // If a bidder will cancel his order it will not effect the
    // lp token price.
    // function getLpPrice(uint256 auctionId)
    //     external
    //     view
    //     atStageFinished(auctionId)
    //     returns (uint96 averagePrice, uint256 counter)
    // {
    //     (averagePrice, counter) = sellOrders[auctionId].average();
    // }

    // function userAuctionStatus(uint256 auctionId, address user)
    //     external
    //     view
    //     returns (bool isAuctionSuccess, uint96 purchased)
    // {
    //     isAuctionSuccess = auctionData[auctionId].minFundingThresholdNotReached;

    // }

    //--------------------------------------------------------
    // Documents
    //--------------------------------------------------------

    function setDocument(string calldata _name, string calldata _data)
        external
        onlyOwner()
    {
        documents._setDocument(_name, _data);
    }

    function getDocumentCount() external view returns (uint256) {
        return documents.getDocumentCount();
    }

    function getAllDocuments() external view returns (bytes memory) {
        return documents.getAllDocuments();
    }

    function getDocumentName(uint256 _index)
        external
        view
        returns (string memory)
    {
        return documents.getDocumentName(_index);
    }

    function getDocument(string calldata _name)
        external
        view
        returns (string memory, uint256)
    {
        return documents.getDocument(_name);
    }

    function removeDocument(string calldata _name) external {
        documents._removeDocument(_name);
    }
}