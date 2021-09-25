/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// Sources flattened with hardhat v2.6.2 https://hardhat.org

// File contracts/StakeSet.sol



pragma solidity ^0.8.0;

library StakeSet {

    struct Item {
        uint id;
        uint createTime;
        uint power;
        uint aTokenAmount;
        uint payTokenAmount;
        address payTokenAddr;
        address owner;
    }

    struct Set {
        Item[] _values;
        // id => index
        mapping (uint => uint) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Set storage set, Item memory value) internal returns (bool) {
        if (!contains(set, value.id)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value.id] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Set storage set, Item memory value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value.id];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            Item memory lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue.id] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value.id];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Set storage set, uint valueId) internal view returns (bool) {
        return set._indexes[valueId] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Set storage set, uint256 index) internal view returns (Item memory) {
        require(set._values.length > index, "StakeSet: index out of bounds");
        return set._values[index];
    }

    function idAt(Set storage set, uint256 valueId) internal view returns (Item memory) {
        require(set._indexes[valueId] != 0, "StakeSet: set._indexes[valueId] != 0");
        uint index = set._indexes[valueId] - 1;
        require(set._values.length > index, "StakeSet: index out of bounds");
        return set._values[index];
    }

}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]



pragma solidity ^0.8.0;


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


// File contracts/IPancakePair.sol



pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File contracts/StakePool.sol



pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
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


contract StakePool is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using StakeSet for StakeSet.Set;


    ///////////////////////////////// constant /////////////////////////////////
    uint constant DECIMALS = 10 ** 18;

    uint[] STAKE_PER = [90, 80, 70, 50, 10];
    uint[] STAKE_POWER_RATE = [80, 100, 130, 210, 500];

    // todo
    address constant RECIPIENT_ADDRESS = 0x280Bb6174622959F2044e807D6deE71cD74b32c0;
    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint constant VIP_NUM = 10;
    uint[VIP_NUM] VIP_BURN = [0 ether, 100 ether, 300 ether, 500 ether, 700 ether, 1200 ether, 1500 ether, 1800 ether, 3000 ether, 5000 ether];
    uint[VIP_NUM] VIP_STATIC_POWER = [100 ether, 300 ether, 800 ether, 1500 ether, 3000 ether, 8000 ether, 15000 ether, 20000 ether, 30000 ether, 50000 ether];

    // todo: wethToken address
    address constant WETH_ADDRESS = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant USDT_ADDRESS = 0x55d398326f99059fF775485246999027B3197955;
    address public aToken;
    address public secretSigner;
    uint private totalMine = 28900000000000000000000000;
    uint private _alreadyMine = 0;
    uint private dayMine = 18800000000000000000000;
    uint private _dayAlreadySum = 0;
    ///////////////////////////////// storage /////////////////////////////////
    uint public currentId;
    uint private _totalSupply;
    uint private _totalWeight;
    bool private _invitedByStake = true;

    mapping(address => uint) private _balances;
    mapping(address => uint) private _weights;
    mapping(address => StakeSet.Set) private _stakeOf;

    // withdrawn stakeId
    uint[] public withdrawIdOf;
    // withdrawRewardId => status
    mapping(uint => bool) public withdrawRewardIdOf;
    uint public totalWithdrawReward;
    mapping(address => uint) public withdrawRewardOf;

    // tokenAddress => lpAddress
    mapping(address => address) public lpAddress;
    // type => status
    mapping(uint => bool) public typeStatus;
    // (type, address) => status
    mapping(uint => mapping(address => bool)) public includeTypeAccount;

    mapping(address => uint) public burnAmountOf;

    mapping(address => address) public invitedBy;
    mapping(address => address[]) public inviteLvOne;


    event Stake(address indexed user, address indexed payToken, uint indexed stakeType, uint stakeId, uint payTokenAmount, uint amount);
    event Withdraw(address indexed user, uint indexed stakeId, uint payTokenAmount, uint amount);
    event WithdrawReward(address indexed user, uint amount, uint withdrawRewardId);
    event BurnToken(address indexed from, uint acmount);
    event Invite(address indexed from, address indexed inviter);

    constructor (address _aToken) {
        aToken = _aToken;
    }

    function changeMine() external onlyOwner {
        require(0 < totalMine, "withdrawReward: 0 < totalMine");
        if(totalMine < dayMine){
            _alreadyMine += totalMine;
            totalMine = 0;
        }else{
            _alreadyMine += dayMine;
            totalMine -= dayMine;
        }
        _dayAlreadySum += 1;
    }

    function setAToken(address _aToken) external onlyOwner {
        aToken = _aToken;
    }

    /**
     * @dev set swap pair address (aka. Lp Token address)
     */
    function setLpAddress(address _token, address _lp) external onlyOwner {
        lpAddress[_token] = _lp;
    }

    function setSecretSigner(address _secretSigner) external onlyOwner {
        require(_secretSigner != address(0), "address invalid");
        secretSigner = _secretSigner;
    }
    

    function setTypeStatus(uint _index, bool _value) external onlyOwner {
        typeStatus[_index] = _value;
    }

    function setIncludeTypeAccount(uint _index, address _index1, bool _value) external onlyOwner {
        includeTypeAccount[_index][_index1] = _value;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint) {
        return _stakeOf[account]._values.length;
    }

    function totalWeight() public view returns (uint) {
        return _totalWeight;
    }
    
    //_invitedByStake
    function setInvitedByStake(bool _value) external onlyOwner {
        _invitedByStake = _value;
    }
    
    function invitedByStake()public view returns (bool){
        return _invitedByStake;
    }
    
	function alreadyMine() public view returns (uint) {
        return _alreadyMine;
    }
    
    function dayAlreadySum() public view returns (uint) {
        return _dayAlreadySum;
    }
    
    function weightOf(address account) public view returns (uint) {
        return _weights[account];
    }

    /**
     * @dev get stake item by '_account' and '_index'
     */
    function getStakeOf(address _account, uint _index) external view returns (StakeSet.Item memory) {
        require(_stakeOf[_account].length() > _index, "getStakeOf: _stakeOf[_account].length() > _index");
        return _stakeOf[_account].at(_index);
    }

    /**
     * @dev get '_account' stakes by page
     */
    function getStakes(address _account, uint _index, uint _offset) external view returns (StakeSet.Item[] memory items) {
        uint totalSize = balanceOf(_account);
        if (0 == totalSize || totalSize <= _index) return items;
        uint offset = _offset;
        if (totalSize < _index + offset) {
            offset = totalSize - _index;
        }

        items = new StakeSet.Item[](offset);
        for (uint i = 0; i < offset; i++) {
            items[i] = _stakeOf[_account].at(_index + i);
        }
    }

    function withdrawLen() public view returns (uint) {
        return withdrawIdOf.length;
    }

    function getWithdrawIds(uint _index, uint _offset) external view returns (uint[] memory res) {
        uint totalSize = withdrawLen();
        if (0 == totalSize || totalSize <= _index) return res;
        uint offset = totalSize < _index + _offset ? totalSize - _index : _offset;

        res = new uint[](offset);
        for (uint i = 0; i < offset; i++) {
            res[i] = withdrawIdOf[_index + i];
        }
    }

    function stake(address _payToken, uint _stakeType, uint _payTokenAmount) external payable {
        require(isOpen(_stakeType, msg.sender), "stake: isOpen(_stakeType, msg.sender)");
        require(_payToken != aToken, "stake: _payTokenAmount != aToken");
        if(_invitedByStake){
            require(address(0) != invitedBy[msg.sender], "invite: address(0) != invitedBy[msg.sender]");
        }

        uint payTokenValue = getUSDTPrice(_payToken) * _payTokenAmount / DECIMALS;
        uint aTokenValue = payTokenValue * 100 / STAKE_PER[_stakeType - 1] - payTokenValue;
        uint aTokenAmount = aTokenValue * DECIMALS / getUSDTPrice(aToken);

        // transfer to this
        if (0 < msg.value) { // pay with ETH
            require(_payToken == WETH_ADDRESS, "stake: _payToken = WETH_ADDRESS");
            require(_payTokenAmount == msg.value, "stake: payTokenAmount == msg.value");
        } else { // pay with payToken
            IERC20(_payToken).safeTransferFrom(msg.sender, address(this), _payTokenAmount);
        }
        IERC20(aToken).safeTransferFrom(msg.sender, address(this), aTokenAmount);

        // calculate power
        uint power = aTokenValue.add(payTokenValue).mul(STAKE_POWER_RATE[_stakeType - 1]).div(100);

        _totalSupply = _totalSupply.add(1);
        _balances[msg.sender] = _balances[msg.sender].add(1);
        _totalWeight = _totalWeight.add(power);
        _weights[msg.sender] = _weights[msg.sender].add(power);

        // update _stakeOf
        StakeSet.Item memory item;
        item.id = ++currentId;
        item.createTime = block.timestamp;
        item.aTokenAmount = aTokenAmount;
        item.payTokenAmount = _payTokenAmount;
        item.payTokenAddr = _payToken;
        item.power = power;
        item.owner = msg.sender;
        _stakeOf[msg.sender].add(item);
        _stakeOf[address(0)].add(item);

        emit Stake(msg.sender, _payToken, _stakeType, item.id, _payTokenAmount, aTokenAmount);
    }

    /**
     * @dev withdraw stake
     * @param _stakeId  stakeId
     */
    function withdraw(uint _stakeId) external {
        require(currentId >= _stakeId, "withdraw: currentId >= _stakeId");

        // get _stakeOf
        StakeSet.Item memory item = _stakeOf[msg.sender].idAt(_stakeId);

        // transfer to msg.sender
        uint aTokenAmount = getATokenAmount(item.aTokenAmount, item.createTime);
        uint burnATokenAmount = item.aTokenAmount - aTokenAmount;
        uint payTokenAmount = item.payTokenAmount;
        if (WETH_ADDRESS == item.payTokenAddr) { // pay with ETH
            payable(msg.sender).transfer(payTokenAmount);
        } else { // pay with payToken
            IERC20(item.payTokenAddr).safeTransfer(msg.sender, payTokenAmount);
        }
        if (0 < aTokenAmount) {
            IERC20(aToken).safeTransfer(msg.sender, aTokenAmount);
        }
        if (0 < burnATokenAmount) {
            IERC20(aToken).safeTransfer(BURN_ADDRESS, burnATokenAmount);
        }

        _totalSupply = _totalSupply.sub(1);
        _balances[msg.sender] = _balances[msg.sender].sub(1);
        _totalWeight = _totalWeight.sub(item.power);
        _weights[msg.sender] = _weights[msg.sender].sub(item.power);

        // update _stakeOf
        _stakeOf[msg.sender].remove(item);
        _stakeOf[address(0)].remove(item);
        // update withdrawIdOf
        withdrawIdOf.push(_stakeId);

        emit Withdraw(msg.sender, _stakeId, payTokenAmount, aTokenAmount);
    }

    function withdrawReward(uint _withdrawRewardId, address _to, uint _amount, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(!withdrawRewardIdOf[_withdrawRewardId], "withdrawReward: invalid withdrawRewardId");
        require(address(0) != _to, "withdrawReward: address(0) != _to");
        require(0 < _amount, "withdrawReward: 0 < _amount");
        require(_alreadyMine > _amount, "withdrawReward: alreadyMine > _amount");
        require(address(0) != secretSigner, "withdrawReward: address(0) != secretSigner");
        bytes32 msgHash = keccak256(abi.encodePacked(_withdrawRewardId, _to, _amount));
        require(ecrecover(msgHash, _v, _r, _s) == secretSigner, "withdrawReward: incorrect signer");

        uint fee = _amount * 5 / 100;
        // transfer reward token
        IERC20(aToken).safeTransfer(_to, _amount - fee);
        // transfer fee
        IERC20(aToken).safeTransfer(RECIPIENT_ADDRESS, fee);

        // update totalWithdrawReward & withdrawRewardOf & alreadyMine
        withdrawRewardOf[_to] += _amount;
        totalWithdrawReward += _amount;
        _alreadyMine -= _amount;

        // update _withdrawRewardId
        withdrawRewardIdOf[_withdrawRewardId] = true;
        
        //

        emit WithdrawReward(_to, _amount, _withdrawRewardId);
    }


    function getUSDTPrice(address _token) private view returns (uint) {

        if (USDT_ADDRESS == _token) {return 1 ether;}
        address _lp = lpAddress[_token];
        require(address(0) != _lp, "address(0) != _lp");

        (uint112 reserve0, uint112 reserve1,) = IPancakePair(_lp).getReserves();
        if (IPancakePair(_lp).token0() == USDT_ADDRESS) {
            return uint(reserve0).mul(DECIMALS).div(uint(reserve1));
        }
        if (IPancakePair(_lp).token1() == USDT_ADDRESS) {
            return uint(reserve1).mul(DECIMALS).div(uint(reserve0));
        }

        return 0;
    }

    function getPrice(address _lp) public view returns (uint) {
        (uint112 reserve0, uint112 reserve1,) = IPancakePair(_lp).getReserves();
        if (IPancakePair(_lp).token0() == USDT_ADDRESS) {
            return uint(reserve0).mul(DECIMALS).div(uint(reserve1));
        }
        if (IPancakePair(_lp).token1() == USDT_ADDRESS) {
            return uint(reserve1).mul(DECIMALS).div(uint(reserve0));
        }

        return 0;
    }

    function isOpen(uint _type, address _account) private view returns (bool) {
        return typeStatus[_type] || includeTypeAccount[_type][_account];
    }

    function getATokenAmount(uint _aTokenAmount, uint _stakeTime) private view returns (uint) {
        uint stakeDays = block.timestamp / 24 hours - _stakeTime / 24 hours;
        uint rate = 3 * stakeDays > 100 ? 100 : 3 * stakeDays;
        return _aTokenAmount * rate / 100;
    }

    ///////////////////////////////// vip /////////////////////////////////
    function getVip(address _account) public view returns (uint) {
        uint staticPower = weightOf(_account);
        for(uint i = 0; i < VIP_NUM; i++) {
            if (burnAmountOf[_account] >= VIP_BURN[i] && staticPower >= VIP_STATIC_POWER[i]) {
                continue;
            }
            return i;
        }
        return VIP_NUM;
    }

    function burnToken(uint _amount) external {
        // transfer to burn_address
        IERC20(aToken).transferFrom(msg.sender, BURN_ADDRESS, _amount);
        // update burnAmountOf
        uint burnValue = _amount * getUSDTPrice(aToken) / DECIMALS;
        burnAmountOf[msg.sender] += burnValue;
    }

    ///////////////////////////////// inviter /////////////////////////////////
    function inviteLen(address _account) public view returns (uint) {
        return inviteLvOne[_account].length;
    }

    function getInviteLvOne(address _account, uint _index, uint _offset) external view returns (address[] memory res) {
        uint totalSize = balanceOf(_account);
        if (0 == totalSize || totalSize <= _index) return res;
        uint offset = _offset;
        if (totalSize < _index + offset) {
            offset = totalSize - _index;
        }

        res = new address[](offset);
        for(uint i = 0; i < offset; i++) {
            res[i] = inviteLvOne[_account][_index + i];
        }
    }

    function invite(address _account) external {
        require(address(0) == invitedBy[msg.sender], "invite: address(0) == invitedBy[msg.sender]");
        require(0 == inviteLen(_account), "invite: 0 == inviteLen[_account].length");
        //require(getVip(msg.sender) > 0, "invite: IVip(vip).getVip(msg.sender) > 0");
		require(getVip(_account) > 0, "invite: IVip(vip).getVip(msg.sender) > 0");

        invitedBy[msg.sender] = _account;
        inviteLvOne[_account].push(msg.sender);

        emit Invite(msg.sender, _account);
    }



    ///////////////////////////////// admin function /////////////////////////////////
    event AdminWithdrawToken(address operator, address indexed tokenAddress, address indexed to, uint amount);
    event AdminWithdraw(address operator, address indexed to, uint amount);


    /**
     * @dev adminWithdrawToken
     */
    function adminWithdrawToken(address _token, address _to, uint _amount) external onlyOwner returns (bool) {
        IERC20(_token).safeTransfer(_to, _amount);

        emit AdminWithdrawToken(msg.sender, _token, _to, _amount);
        return true;
    }

    /**
     * @dev adminWithdraw
     */
    function adminWithdraw(address payable _to, uint _amount) external onlyOwner returns (bool) {
        _to.transfer(_amount);

        emit AdminWithdraw(msg.sender, _to, _amount);
        return true;
    }


    receive() external payable {}
    fallback() external {}

}