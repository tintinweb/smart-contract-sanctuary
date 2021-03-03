/**
 *Submitted for verification at Etherscan.io on 2021-03-03
*/

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;


library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


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


pragma solidity ^0.6.0;


library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
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
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
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
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
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
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


pragma solidity ^0.6.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



pragma solidity ^0.6.0;

contract Ownable is Context {
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
}


pragma solidity ^0.6.0;

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity 0.6.12;



// 具有治理功能的SushiToken 地址 0x6b3595068778dd592e39a122f4f5a5cf09c90fe2
// SushiToken with Governance.
contract SushiToken is ERC20("SushiToken", "SUSHI"), Ownable {
    /// @notice 为_to创建`_amount`令牌。只能由所有者（MasterChef）调用
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        // ERC20的铸币方法
        _mint(_to, _amount);
        // 移动委托,将amount的数额的票数转移到to地址的委托人
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    // 从YAM的代码复制过来的
    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // 从COMPOUND代码复制过来的
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    // @notice 每个账户的委托人记录
    // @notice A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice 一个检查点，用于标记给定块中的投票数
    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice 按索引记录每个帐户的选票检查点 地址=>索引=>检查点构造体
    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
    /// @notice 每个帐户的检查点数映射,地址=>数额
    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice EIP-712的合约域hash
    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice EIP-712的代理人构造体的hash
    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice 用于签名/验证签名的状态记录
    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice 帐户更改其委托时发出的事件
      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice 当代表帐户的投票余额更改时发出的事件
    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice 查询delegator的委托人
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator 被委托的地址
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        // 返回委托人地址
        return _delegates[delegator];
    }

   /**
    * @notice 转移当然用户的委托人
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee 委托人地址
    */
    function delegate(address delegatee) external {
        // 将`msg.sender` 的委托人更换为 `delegatee`
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice 从签署人到delegatee的委托投票
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee 委托人地址
     * @param nonce nonce值,匹配签名所需的合同状态
     * @param expiry 签名到期的时间 
     * @param v 签名的恢复字节
     * @param r ECDSA签名对的一半 
     * @param s ECDSA签名对的一半 
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        // 域分割 = hash(域hash + 名字hash + chainId + 当前合约地址)
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        // 构造体hash = hash(构造体的hash + 委托人地址 + nonce值 + 过期时间)
        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        // 签名前数据 = hash(域分割 + 构造体hash)
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );
        
        // 签署人地址 = 恢复地址方法(签名前数据,v,r,s) v,r,s就是签名,通过签名和签名前数据恢复出签名人的地址
        address signatory = ecrecover(digest, v, r, s);
        // 确认签署人地址 != 0地址
        require(signatory != address(0), "SUSHI::delegateBySig: invalid signature");
        // 确认 nonce值 == nonce值映射[签署人]++
        require(nonce == nonces[signatory]++, "SUSHI::delegateBySig: invalid nonce");
        // 确认 当前时间戳 <= 过期时间
        require(now <= expiry, "SUSHI::delegateBySig: signature expired");
        // 返回更换委托人
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice 获取`account`的当前剩余票数
     * @notice Gets the current votes balance for `account`
     * @param account 账户地址
     * @return 剩余票数
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        // 检查点数 = 每个帐户的检查点数映射[账户地址]
        uint32 nCheckpoints = numCheckpoints[account];
        // 返回 检查点 > 0 ? 选票检查点[账户地址][检查点数 - 1(最后一个,索引从0开始,检查点数从1开始)].票数 : 0
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice 确定帐户在指定区块前的投票数
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev 块号必须是已完成的块，否则此功能将还原以防止出现错误信息
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account 账户地址
     * @param blockNumber 区块号
     * @return 帐户在给定区块中所拥有的票数
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        // 确认 区块号 < 当前区块号
        require(blockNumber < block.number, "SUSHI::getPriorVotes: not yet determined");

        // 检查点数 = 每个帐户的检查点数映射[账户地址]
        uint32 nCheckpoints = numCheckpoints[account];
        // 如果检查点 == 0 返回 0
        if (nCheckpoints == 0) {
            return 0;
        }

        // 首先检查最近的余额
        // First check most recent balance
        // 如果 选票检查点[账户地址][检查点数 - 1(最后一个,索引从0开始,检查点数从1开始)].from块号 <= 区块号
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            // 返回 选票检查点[账户地址][检查点数 - 1(最后一个,索引从0开始,检查点数从1开始)].票数
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // 下一步检查隐式零余额
        // Next check implicit zero balance
        // 如果 选票检查点[账户地址][0].from块号 > 区块号 返回 0
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        // 通过二分查找找到检查点映射中from区块为给入区块号的检查点构造体中的票数
        // 如果没有则返回给入区块号之前最临近区块的检查点构造体的检查点数字
        uint32 lower = 0; //最小值0
        uint32 upper = nCheckpoints - 1; // 最大值(最后一个,索引从0开始,检查点数从1开始)
        while (upper > lower) { // 当最大值>最小值
            // 最大数与最小数之间的中间数 = 最大数 - (最大数 - 最小数) / 2
            uint32 center = upper - (upper - lower) / 2; // 防止溢出// ceil, avoiding overflow
            // 实例化检查点映射中用户索引值中间数对应的检查点构造体
            Checkpoint memory cp = checkpoints[account][center];
            // 如果 中间数构造体中的开始区块号 等于 传入的区块号
            if (cp.fromBlock == blockNumber) {
                // 返回中间数构造体中的票数
                return cp.votes;
            // 否则如果 中间数构造体中的开始区块号 小于 传入的区块号
            } else if (cp.fromBlock < blockNumber) {
                // 最小值 = 中间值
                lower = center;
                // 否则
            } else {
                // 最大值 = 中间数 - 1
                upper = center - 1;
            }
        }
        // 返回检查点映射中用户索引值为检查点数字的检查点构造体的票数
        return checkpoints[account][lower].votes;
    }

    /**
    * @dev 更换委托人
    * @param delegator 被委托人
    * @param delegatee 新委托人
     */
    function _delegate(address delegator, address delegatee)
        internal
    {
        // 被委托人的当前委托人
        address currentDelegate = _delegates[delegator];
        // 获取基础SUSHI的余额（未缩放）
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying SUSHIs (not scaled);
        // 修改被委托人的委托人为新委托人
        _delegates[delegator] = delegatee;

        // 触发更换委托人事件
        emit DelegateChanged(delegator, currentDelegate, delegatee);

        // 转移委托票数
        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    /**
    * @dev 转移委托票数
    * @param srcRep 源地址
    * @param dstRep 目标地址
    * @param amount 转移的票数
     */
    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        // 如果源地址 != 目标地址 && 转移的票数 > 0
        if (srcRep != dstRep && amount > 0) {
            // 如果源地址 != 0地址 源地址不是0地址说明不是铸造方法
            if (srcRep != address(0)) {
                // 减少旧的代表
                // decrease old representative
                // 源地址的检查点数
                uint32 srcRepNum = numCheckpoints[srcRep];
                // 旧的源地址票数 = 源地址的检查点数 > 0 ? 选票检查点[源地址][源地址的检查点数 - 1(最后一个,索引从0开始,检查点数从1开始)].票数 : 0
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                // 新的源地址票数 = 旧的源地址票数 - 转移的票数
                uint256 srcRepNew = srcRepOld.sub(amount);
                // 写入检查点,修改委托人票数
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }
            // 如果目标地址 != 0地址 目标地址不是0地址说明不是销毁方法
            if (dstRep != address(0)) {
                // 增加新的代表
                // increase new representative
                // 目标地址检查点数
                uint32 dstRepNum = numCheckpoints[dstRep];
                // 旧目标地址票数 = 目标地址检查点数 > 0 ? 选票检查点[目标地址][目标地址的检查点数 - 1(最后一个,索引从0开始,检查点数从1开始)].票数 : 0
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                // 新目标地址票数 = 旧目标地址票数 + 转移的票数
                uint256 dstRepNew = dstRepOld.add(amount);
                // 写入检查点,修改委托人票数
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    /**
    * @dev 写入检查点
    * @param delegatee 委托人地址
    * @param nCheckpoints 检查点数
    * @param oldVotes 旧票数
    * @param newVotes 新票数
     */
    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        // 区块号 = 限制在32位2进制之内(当前区块号)
        uint32 blockNumber = safe32(block.number, "SUSHI::_writeCheckpoint: block number exceeds 32 bits");
        // 如果 检查点数 > 0 && 检查点映射[委托人][检查点数 - 1(最后一个,索引从0开始,检查点数从1开始)].from块号 == 当前区块号
        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            // 检查点映射[委托人][检查点数 - 1(最后一个,索引从0开始,检查点数从1开始)].票数 = 新票数
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            // 检查点映射[委托人][检查点] = 检查点构造体(当前区块号, 新票数)
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            // 每个帐户的检查点数映射[委托人] = 检查点数 + 1
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }
        // 触发委托人票数更改事件
        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /**
    * @dev 安全的32位数字
    * @param n 输入数字
    * @param errorMessage 报错信息
     */
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        // 确认 n < 2**32
        require(n < 2**32, errorMessage);
        // 返回n
        return uint32(n);
    }

    /**
    * @dev 获取链id
     */
    function getChainId() internal pure returns (uint) {
        // 定义chainId变量
        uint256 chainId;
        // 内联汇编取出chainId
        assembly { chainId := chainid() }
        // 返回chainId
        return chainId;
    }
}

// File: contracts/MasterChef.sol

pragma solidity 0.6.12;







//主厨合约地址 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd

// 迁移合约接口
interface IMigratorChef {
    // 执行从旧版UniswapV2到SushiSwap的LP令牌迁移
    // Perform LP token migration from legacy UniswapV2 to SushiSwap.
    // 获取当前的LP令牌地址并返回新的LP令牌地址
    // Take the current LP token address and return the new LP token address.
    // 迁移者应该对调用者的LP令牌具有完全访问权限
    // Migrator should have full access to the caller's LP token.
    // 返回新的LP令牌地址
    // Return the new LP token address.
    //
    // XXX Migrator必须具有对UniswapV2 LP令牌的权限访问权限
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    //
    // SushiSwap必须铸造完全相同数量的SushiSwap LP令牌，否则会发生不良情况。
    // 传统的UniswapV2不会这样做，所以要小心！
    // SushiSwap must mint EXACTLY the same amount of SushiSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// MasterChef是Sushi的主人。他可以做寿司，而且他是个好人。
//
// 请注意，它是可拥有的，所有者拥有巨大的权力。
// 一旦SUSHI得到充分分配，所有权将被转移到治理智能合约中，
// 并且社区可以展示出自我治理的能力
//
// 祝您阅读愉快。希望它没有错误。上帝保佑。

// MasterChef is the master of Sushi. He can make Sushi and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SUSHI is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // 用户信息
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.用户提供了多少个LP令牌。
        uint256 rewardDebt; // Reward debt. See explanation below.已奖励数额。请参阅下面的说明。
        //
        // 我们在这里做一些有趣的数学运算。基本上，在任何时间点，授予用户但待分配的SUSHI数量为：
        // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
        // entitled to a user but is pending to be distributed is:
        //
        //   待处理的奖励 =（user.amount * pool.accSushiPerShare）-user.rewardDebt
        //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
        //
        // 每当用户将lpToken存入到池子中或提取时。这是发生了什么：
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. 池子的每股累积SUSHI(accSushiPerShare)和分配发生的最后一个块号(lastRewardBlock)被更新
        //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
        //   2. 用户收到待处理奖励。
        //   2. User receives the pending reward sent to his/her address.
        //   3. 用户的“amount”数额被更新
        //   3. User's `amount` gets updated.
        //   4. 用户的`rewardDebt`已奖励数额得到更新
        //   4. User's `rewardDebt` gets updated.
    }

    // 池子信息
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.LP代币合约的地址
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.分配给该池的分配点数。 SUSHI按块分配
        uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.SUSHIs分配发生的最后一个块号
        uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.每股累积SUSHI乘以1e12。见下文
    }

    // The SUSHI TOKEN!
    SushiToken public sushi;
    // Dev address.开发人员地址
    address public devaddr;
    // 奖励结束块号
    // Block number when bonus SUSHI period ends.
    uint256 public bonusEndBlock;
    // 每块创建的SUSHI令牌
    // SUSHI tokens created per block.
    uint256 public sushiPerBlock;
    // 早期寿司的奖金乘数
    // Bonus muliplier for early sushi makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // 迁移者合同。它具有很大的力量。只能通过治理（所有者）进行设置
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;

    // 池子信息数组
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // 池子ID=>用户地址=>用户信息 的映射
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // 总分配点。必须是所有池中所有分配点的总和
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // SUSHI挖掘开始时的块号
    // The block number when SUSHI mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    ); //紧急情况

    /**
     * @dev 构造函数
     * @param _sushi 寿司币地址
     * @param _devaddr 开发人员地址
     * @param _sushiPerBlock 每块创建的SUSHI令牌
     * @param _startBlock SUSHI挖掘开始时的块号
     * @param _bonusEndBlock 奖励结束块号
     */
    // 以下是sushiswap主厨合约布署时的参数
    // _sushi: '0x6B3595068778DD592e39A122f4f5a5cF09C90fE2',
    // _devaddr: '0xF942Dba4159CB61F8AD88ca4A83f5204e8F4A6bd',
    // _sushiPerBlock: '100000000000000000000',
    // _startBlock: '10750000',
    // _bonusEndBlock: '10850000'
    constructor(
        SushiToken _sushi,
        address _devaddr,
        uint256 _sushiPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        sushi = _sushi;
        devaddr = _devaddr;
        sushiPerBlock = _sushiPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    /**
     * @dev 返回池子数量
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @dev 将新的lp添加到池中,只能由所有者调用
     * @param _allocPoint 分配给该池的分配点数。 SUSHI按块分配
     * @param _lpToken LP代币合约的地址
     * @param _withUpdate 触发更新所有池的奖励变量。注意gas消耗！
     */
    // Add a new lp to the pool. Can only be called by the owner.
    // XXX请勿多次添加同一LP令牌。如果您这样做，奖励将被搞砸
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        // 触发更新所有池的奖励变量
        if (_withUpdate) {
            massUpdatePools();
        }
        // 分配发生的最后一个块号 = 当前块号 > SUSHI挖掘开始时的块号 > 当前块号 : SUSHI挖掘开始时的块号
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        // 总分配点添加分配给该池的分配点数
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        // 池子信息推入池子数组
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accSushiPerShare: 0
            })
        );
    }

    /**
     * @dev 更新给定池的SUSHI分配点。只能由所有者调用
     * @param _pid 池子ID,池子数组中的索引
     * @param _allocPoint 新的分配给该池的分配点数。 SUSHI按块分配
     * @param _withUpdate 触发更新所有池的奖励变量。注意gas消耗！
     */
    // Update the given pool's SUSHI allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        // 触发更新所有池的奖励变量
        if (_withUpdate) {
            massUpdatePools();
        }
        // 总分配点 = 总分配点 - 池子数组[池子id].分配点数 + 新的分配给该池的分配点数
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        // 池子数组[池子id].分配点数 = 新的分配给该池的分配点数
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /**
     * @dev 设置迁移合约地址,只能由所有者调用
     * @param _migrator 合约地址
     */
    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    /**
     * @dev 将lp令牌迁移到另一个lp合约。可以被任何人呼叫。我们相信迁移合约是正确的
     * @param _pid 池子id,池子数组中的索引
     */
    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        // 确认迁移合约已经设置
        require(address(migrator) != address(0), "migrate: no migrator");
        // 实例化池子信息构造体
        PoolInfo storage pool = poolInfo[_pid];
        // 实例化LP token
        IERC20 lpToken = pool.lpToken;
        // 查询LP token的余额
        uint256 bal = lpToken.balanceOf(address(this));
        // LP token 批准迁移合约控制余额数量
        lpToken.safeApprove(address(migrator), bal);
        // 新LP token地址 = 执行迁移合约的迁移方法
        IERC20 newLpToken = migrator.migrate(lpToken);
        // 确认余额 = 新LP token中的余额
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        // 修改池子信息中的LP token地址为新LP token地址
        pool.lpToken = newLpToken;
    }

    /**
     * @dev 给出from和to的块号,返回奖励乘积
     * @param _from from块号
     * @param _to to块号
     * @return 奖励乘积
     */
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        // 如果to块号 <= 奖励结束块号
        if (_to <= bonusEndBlock) {
            // 返回 (to块号 - from块号) * 奖金乘数
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
            // 否则如果 from块号 >= 奖励结束块号
        } else if (_from >= bonusEndBlock) {
            // 返回to块号 - from块号
            return _to.sub(_from);
            // 否则
        } else {
            // 返回 (奖励结束块号 - from块号) * 奖金乘数 + (to块号 - 奖励结束块号)
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    /**
     * @dev 查看功能以查看用户的处理中尚未领取的SUSHI
     * @param _pid 池子id
     * @param _user 用户地址
     * @return 处理中尚未领取的SUSHI数额
     */
    // View function to see pending SUSHIs on frontend.
    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        // 实例化池子信息
        PoolInfo storage pool = poolInfo[_pid];
        // 根据池子id和用户地址,实例化用户信息
        UserInfo storage user = userInfo[_pid][_user];
        // 每股累积SUSHI
        uint256 accSushiPerShare = pool.accSushiPerShare;
        // LPtoken的供应量 = 当前合约在`池子信息.lpToken地址`的余额
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        // 如果当前区块号 > 池子信息.分配发生的最后一个块号 && LPtoken的供应量 != 0
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            // 奖金乘积 = 获取奖金乘积(分配发生的最后一个块号, 当前块号)
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            // sushi奖励 = 奖金乘积 * 每块创建的SUSHI令牌 * 池子分配点数 / 总分配点数
            uint256 sushiReward = multiplier
                .mul(sushiPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            // 每股累积SUSHI = 每股累积SUSHI + sushi奖励 * 1e12 / LPtoken的供应量
            accSushiPerShare = accSushiPerShare.add(
                sushiReward.mul(1e12).div(lpSupply)
            );
        }
        // 返回 用户.已添加的数额 * 每股累积SUSHI / 1e12 - 用户.已奖励数额
        return user.amount.mul(accSushiPerShare).div(1e12).sub(user.rewardDebt);
    }

    /**
     * @dev 更新所有池的奖励变量。注意汽油消耗
     */
    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        // 池子数量
        uint256 length = poolInfo.length;
        // 遍历所有池子
        for (uint256 pid = 0; pid < length; ++pid) {
            // 升级池子(池子id)
            updatePool(pid);
        }
    }

    /**
     * @dev 将给定池的奖励变量更新为最新
     * @param _pid 池子id
     */
    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        // 实例化池子信息
        PoolInfo storage pool = poolInfo[_pid];
        // 如果当前区块号 <= 池子信息.分配发生的最后一个块号
        if (block.number <= pool.lastRewardBlock) {
            // 直接返回
            return;
        }
        // LPtoken的供应量 = 当前合约在`池子信息.lotoken地址`的余额
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        // 如果 LPtoken的供应量 == 0
        if (lpSupply == 0) {
            // 池子信息.分配发生的最后一个块号 = 当前块号
            pool.lastRewardBlock = block.number;
            // 返回
            return;
        }
        // 奖金乘积 = 获取奖金乘积(分配发生的最后一个块号, 当前块号)
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        // sushi奖励 = 奖金乘积 * 每块创建的SUSHI令牌 * 池子分配点数 / 总分配点数
        uint256 sushiReward = multiplier
            .mul(sushiPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        // 调用sushi的铸造方法, 为管理团队铸造 (`sushi奖励` / 10) token
        sushi.mint(devaddr, sushiReward.div(10));
        // 调用sushi的铸造方法, 为当前合约铸造 `sushi奖励` token
        sushi.mint(address(this), sushiReward);
        // 每股累积SUSHI = 每股累积SUSHI + sushi奖励 * 1e12 / LPtoken的供应量
        pool.accSushiPerShare = pool.accSushiPerShare.add(
            sushiReward.mul(1e12).div(lpSupply)
        );
        // 池子信息.分配发生的最后一个块号 = 当前块号
        pool.lastRewardBlock = block.number;
    }

    /**
     * @dev 将LP令牌存入MasterChef进行SUSHI分配
     * @param _pid 池子id
     * @param _amount 数额
     */
    // Deposit LP tokens to MasterChef for SUSHI allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        // 实例化池子信息
        PoolInfo storage pool = poolInfo[_pid];
        // 根据池子id和当前用户地址,实例化用户信息
        UserInfo storage user = userInfo[_pid][msg.sender];
        // 将给定池的奖励变量更新为最新
        updatePool(_pid);
        // 如果用户已添加的数额>0
        if (user.amount > 0) {
            // 待定数额 = 用户.已添加的数额 * 池子.每股累积SUSHI / 1e12 - 用户.已奖励数额
            uint256 pending = user
                .amount
                .mul(pool.accSushiPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            // 向当前用户安全发送待定数额的sushi
            safeSushiTransfer(msg.sender, pending);
        }
        // 调用池子.lptoken的安全发送方法,将_amount数额的lp token从当前用户发送到当前合约
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        // 用户.已添加的数额  = 用户.已添加的数额 + _amount数额
        user.amount = user.amount.add(_amount);
        // 用户.已奖励数额 = 用户.已添加的数额 * 池子.每股累积SUSHI / 1e12
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        // 触发存款事件
        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
     * @dev 从MasterChef提取LP令牌
     * @param _pid 池子id
     * @param _amount 数额
     */
    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        // 实例化池子信息
        PoolInfo storage pool = poolInfo[_pid];
        // 根据池子id和当前用户地址,实例化用户信息
        UserInfo storage user = userInfo[_pid][msg.sender];
        // 确认用户.已添加数额 >= _amount数额
        require(user.amount >= _amount, "withdraw: not good");
        // 将给定池的奖励变量更新为最新
        updatePool(_pid);
        // 待定数额 = 用户.已添加的数额 * 池子.每股累积SUSHI / 1e12 - 用户.已奖励数额
        uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(
            user.rewardDebt
        );
        // 向当前用户安全发送待定数额的sushi
        safeSushiTransfer(msg.sender, pending);
        // 用户.已添加的数额  = 用户.已添加的数额 - _amount数额
        user.amount = user.amount.sub(_amount);
        // 用户.已奖励数额 = 用户.已添加的数额 * 池子.每股累积SUSHI / 1e12
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        // 调用池子.lptoken的安全发送方法,将_amount数额的lp token从当前合约发送到当前用户
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        // 触发提款事件
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
     * @dev 提款而不关心奖励。仅紧急情况
     * @param _pid 池子id
     */
    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        // 实例化池子信息
        PoolInfo storage pool = poolInfo[_pid];
        // 根据池子id和当前用户地址,实例化用户信息
        UserInfo storage user = userInfo[_pid][msg.sender];
        // 调用池子.lptoken的安全发送方法,将_amount数额的lp token从当前合约发送到当前用户
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        // 触发紧急提款事件
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        // 用户.已添加数额 = 0
        user.amount = 0;
        // 用户.已奖励数额 = 0
        user.rewardDebt = 0;
    }

    /**
     * @dev 安全的寿司转移功能，以防万一舍入错误导致池中没有足够的寿司
     * @param _to to地址
     * @param _amount 数额
     */
    // Safe sushi transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
    function safeSushiTransfer(address _to, uint256 _amount) internal {
        // sushi余额 = 当前合约在sushi的余额
        uint256 sushiBal = sushi.balanceOf(address(this));
        // 如果数额 > sushi余额
        if (_amount > sushiBal) {
            // 按照sushi余额发送sushi到to地址
            sushi.transfer(_to, sushiBal);
        } else {
            // 按照_amount数额发送sushi到to地址
            sushi.transfer(_to, _amount);
        }
    }

    /**
     * @dev 通过先前的开发者地址更新开发者地址
     * @param _devaddr 开发者地址
     */
    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        // 确认当前账户是开发者地址
        require(msg.sender == devaddr, "dev: wut?");
        // 赋值新地址
        devaddr = _devaddr;
    }
}