/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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




// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferNative(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: Native_TRANSFER_FAILED');
    }
}



/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
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

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
        return address(uint160(uint256(_at(set._inner, index))));
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

    constructor() {
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

interface MetaHeroCraftNFT {
    function getApproved(uint) external view returns (address);
    function ownerOf(uint) external view returns (address);

    function createHero(address _owner, uint _heroIndex ) external; 
}

interface ConfigHeroCraft{
    function getLevelInfo(uint _levelId ) external view returns (uint _level,  uint _energy, uint _gold, uint _titan, uint _itemId) ;

    function getHeroLevelInfo(uint _level ) external view returns (uint _gold, uint _titan, uint _failPoint, uint _goldTimes, uint _propertyPoint) ;

    function getHeroPoint(uint _star ) external view returns (uint _pointMin, uint _pointMax);

    function getHeroBaseInfo( uint _class ) external view returns (uint _career, string memory _imgUrl, string memory _story ) ;
}

interface HelperRandom {
    function getRandomNumber(uint256 _seedValue, uint256 _number, address _sender)
        external
        view
        returns (uint256);
}

//game core logic contract
contract MetaHeroCraftCore is Ownable , ReentrancyGuard{
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _governors;

    EnumerableSet.AddressSet private _blackList;

    MetaHeroCraftNFT public metaHeroCraftNFT ;

    ConfigHeroCraft public configHeroCraft;

    HelperRandom public helperRandom;

    address public titanToken ;
    address public heroGoldToken;

    //define hero  info
    struct HeroInfo {
        uint class;
        uint star;
        uint level;
        uint strength;
        uint dexterity;
        uint intelligence;
        uint constitution;
        uint wisdom;
        uint luck;

        uint basePoint;
        uint openUpdateProperty;

        bool free;
    }

    //define hero index : class*10000000000 + star * 1000000000 + heroindex of class
    mapping(uint => HeroInfo) public heroInfo;

    //store hero battle timestamp
    struct HeroBattleTime{
        uint time1;
        uint time2;
        uint time3;
    }
    mapping(uint => HeroBattleTime) public heroBattleTime;

    uint constant DAY = 1 days;

    //record hero nft count
	struct HeroNFTCount {
        uint totalCount;
        uint star1;
		uint star2;
        uint star3;
        uint star4;
        uint star5;
        uint star6;
        uint freeCount;
    }
	
    //class --> heornft count
	mapping(uint => HeroNFTCount) public heroAmount;

    //address -->free nft hero id
    mapping(address => uint) public freeHeroInfo;

    // Control gaming
    bool public paused = false;


    uint256 public openBoxTitanAmount = 1e18;

    //random parameters
    uint256 private maxClass = 8;
    uint256 private maxStar = 6;

    uint256 public ratioStar1 = 10000;
    uint256 public ratioStar2 = 500;
    uint256 public ratioStar3 = 100; 
    uint256 public ratioStar4 = 20; 
    uint256 public ratioStar5 = 4; 
    uint256 public ratioStar6 = 4;


    event newFreeHero(address _openUser , uint _class ,uint _star);
    event newHero(address _openUser , uint _class ,uint _star);
    event battleLevelStart(address _user, uint _heroIndex, uint _levelId);
    event heroLevelUpSuccess( address _user, uint _heroIndex, uint _newLevel);
    event heroLevelUpFailure( address _user, uint _heroIndex, uint _newLevel);
    event heroPropertyUpdated(address _user , uint _heroIndex,uint _strength,
        uint _dexterity,
        uint _intelligence,
        uint _constitution,
        uint _wisdom,
        uint _luck );
    
    event loginfo( uint log);

    constructor()  {
        // star1	75%	10--20
        // star2	20%	20--40
        // star3	4.39%	40--60
        // star4	0.50%	60--80
        // star5	0.10%	80--100
        // star6	0.01%	100--120
        ratioStar2 = 2000;
        ratioStar3 = 439;
        ratioStar4 = 50;
        ratioStar5 = 10;
        ratioStar6 = 1;

    }


    function setOpenBoxTitanAmount( uint256 _titanAmount ) public onlyOwner {
        openBoxTitanAmount = _titanAmount ;
    }

    function setMetaHeroCraftNFT( address _metaHeroCraftNFT ) public onlyOwner {
        metaHeroCraftNFT = MetaHeroCraftNFT(_metaHeroCraftNFT) ;
    }

    function setConfigHeroCraft( address _configHeroCraft ) public onlyOwner {
        configHeroCraft = ConfigHeroCraft(_configHeroCraft) ;
    }

    function setHelperRandom( address _helperRandom ) public onlyOwner {
        helperRandom = HelperRandom(_helperRandom) ;
    }

    function setTokenAddress( address _titanToken, address _heroGoldToken ) public onlyOwner {
        titanToken = _titanToken;
        heroGoldToken = _heroGoldToken;
    }

    function setMaxClass( uint256 _maxClass,uint256 _maxStar) public onlyGovernor{
        maxClass = _maxClass;
        maxStar = _maxStar;
    }

    function setRatioStar( uint256 _ratioStar1,uint256 _ratioStar2,uint256 _ratioStar3,uint256 _ratioStar4,uint256 _ratioStar5,uint256 _ratioStar6) public onlyGovernor{
        ratioStar1 = _ratioStar1;
        ratioStar2 = _ratioStar2;
        ratioStar3 = _ratioStar3;
        ratioStar4 = _ratioStar4;
        ratioStar5 = _ratioStar5;
        ratioStar6 = _ratioStar6;
    }

    function _isApprovedOrOwner(address _address, uint _heroIndex) internal view returns (bool) {
        return metaHeroCraftNFT.getApproved(_heroIndex) == _address || metaHeroCraftNFT.ownerOf(_heroIndex) == _address;
    }

    //core game logic
    function getHeroInfo(uint _heroIndex ) public view returns (uint _class,  uint _star,uint _level) {
        HeroInfo memory _heroInfo = heroInfo[ _heroIndex ];
        _class = _heroInfo.class;
        _star = _heroInfo.star;
        _level = _heroInfo.level;
    }

    function getHeroInfoExtend(uint _heroIndex ) public view returns (
        uint _strength,
        uint _dexterity,
        uint _intelligence,
        uint _constitution,
        uint _wisdom,
        uint _luck) {
        HeroInfo memory _heroInfo = heroInfo[ _heroIndex ];
        _strength = _heroInfo.strength;
        _dexterity = _heroInfo.dexterity;
        _intelligence = _heroInfo.intelligence;
        _constitution = _heroInfo.constitution;
        _wisdom = _heroInfo.wisdom;
        _luck = _heroInfo.luck;
    }

    function getHeroInfoOther(uint _heroIndex ) public view returns (
        uint _basePoint,
        uint _battleTimes,
        uint _openUpdateProperty) {
        HeroInfo memory _heroInfo = heroInfo[ _heroIndex ];
        _basePoint = _heroInfo.basePoint;
        _openUpdateProperty = _heroInfo.openUpdateProperty;


        HeroBattleTime memory _heroBattleTime = heroBattleTime[ _heroIndex ];
        uint _checkTime = block.timestamp - DAY;
        
        _battleTimes = 0;
        if( _heroBattleTime.time1 <  _checkTime ){
            _battleTimes ++;
        }

        if( _heroBattleTime.time2 <  _checkTime ){
            _battleTimes ++;
        }

        if( _heroBattleTime.time3 <  _checkTime ){
            _battleTimes ++;
        }

    }

    //check the hero is free
    function getHeroFree(uint _heroIndex ) public view returns ( bool _free) {
        HeroInfo memory _heroInfo = heroInfo[ _heroIndex ];
        _free = _heroInfo.free;
    }

    function setHeroInfo( uint _heroIndex, uint _class,  uint _star,uint _level, uint _strength,
        uint _dexterity,
        uint _intelligence,
        uint _constitution,
        uint _wisdom,
        uint _luck, uint _basePoint, uint _openUpdateProperty ) external onlyGovernor {
        HeroInfo storage _heroInfo = heroInfo[ _heroIndex ];
        _heroInfo.class = _class;
        _heroInfo.star = _star;
        _heroInfo.level = _level;
        _heroInfo.strength = _strength;
        _heroInfo.dexterity = _dexterity;
        _heroInfo.intelligence = _intelligence;
        _heroInfo.constitution = _constitution;
        _heroInfo.wisdom = _wisdom;
        _heroInfo.luck = _luck;
        _heroInfo.basePoint = _basePoint;
        _heroInfo.openUpdateProperty = _openUpdateProperty;
    }


    //check levelup resource
    function levelUp( uint _heroIndex) external notPause returns( uint _result){
        require(_isApprovedOrOwner( msg.sender, _heroIndex ),"hero is not your asset");

        HeroInfo storage _heroInfo = heroInfo[ _heroIndex ];

        uint _gold;
        uint _titan; 
        uint _failPoint;
        uint _propertyPoint ;

        (_gold,_titan,_failPoint,,_propertyPoint )  = configHeroCraft.getHeroLevelInfo( _heroInfo.level + 1 );
        
        require(_propertyPoint > 0 , "hero level is maximum");

        //check condition
        if( _gold > 0 ){
            uint256 amount = IERC20(heroGoldToken).balanceOf( msg.sender );
            require(_gold <= amount, "Gold is not enough");

            TransferHelper.safeTransferFrom( address(heroGoldToken), msg.sender, address(this), _gold);

        }

        if( _titan > 0 ){
            uint256 amount = IERC20(titanToken).balanceOf( msg.sender );
            require(_titan <= amount, "Titan is not enough");

            TransferHelper.safeTransferFrom( address(titanToken), msg.sender, address(this), _titan);
        }

        if( _failPoint > 0 ){
            uint _randomRatio = dn(100000, 10000, msg.sender);
            if( _failPoint < _randomRatio ){
                //burned the hero
                
                emit heroLevelUpFailure( msg.sender, _heroIndex, _heroInfo.level );
                return 0;
            }
        }

        //update 

        _heroInfo.level = _heroInfo.level + 1;
        _heroInfo.openUpdateProperty = 1;

        _result = 1;
        emit heroLevelUpSuccess( msg.sender, _heroIndex, _heroInfo.level );

    }

    //submit hero properties plus
    function UpgradeHeroProperties( uint _heroIndex, uint _strength,
        uint _dexterity,
        uint _intelligence,
        uint _constitution,
        uint _wisdom,
        uint _luck) public  notPause returns( uint _result){
        require(_isApprovedOrOwner( msg.sender, _heroIndex ),"hero is not your asset");

        HeroInfo storage _heroInfo = heroInfo[ _heroIndex ];

        require( _heroInfo.openUpdateProperty == 1 , "only have one time to update");
        require(_strength >= _heroInfo.strength && _dexterity >= _heroInfo.dexterity
                && _intelligence >= _heroInfo.intelligence 
                && _constitution >= _heroInfo.constitution 
                && _wisdom >= _heroInfo.wisdom 
                && _luck >= _heroInfo.luck , "hero property need up" );
        
        uint _propertyPoint ;

        (,,,,_propertyPoint )  = configHeroCraft.getHeroLevelInfo( _heroInfo.level );

        require( (_heroInfo.basePoint + _propertyPoint) == (_strength + _dexterity + _intelligence
            + _constitution + _wisdom + _luck), "need set all properties point" );

        _heroInfo.strength = _strength;
        _heroInfo.dexterity = _dexterity;
        _heroInfo.intelligence = _intelligence;
        _heroInfo.constitution = _constitution;
        _heroInfo.wisdom = _wisdom;
        _heroInfo.luck = _luck;

        _heroInfo.openUpdateProperty = 0;
        _result = 1;

        emit heroPropertyUpdated( msg.sender, _heroIndex, _strength, _dexterity, _intelligence,
         _constitution, _wisdom, _luck);

    }

    // free candy NFT Hero
    // limitation: 
    // 1. one free hero 
    // 2. free hero can't tranfer to others, sell/buy;
    // 3. free hero can battle level ,etc..
    function freePickHero( ) public  notPause returns (uint _heroIndex, uint _class, uint _star) {
    
        //check limit
        _heroIndex = freeHeroInfo[ msg.sender ];
        require( _heroIndex == 0 , "only one free hero");
    
        //get random class
        _class = dn( 100000, maxClass, msg.sender) + 1 ;
        
        //free hero star is 1
        _star = 1;

        HeroNFTCount storage _heroNftCount = heroAmount[_class];
        _heroIndex = _heroNftCount.totalCount + 1 + _class * 10000000000 + _star * 1000000000;
        _heroNftCount.totalCount = _heroNftCount.totalCount + 1;

        _heroNftCount.star1 = _heroNftCount.star1 + 1;
        _heroNftCount.freeCount ++;

        HeroInfo storage _heroInfo = heroInfo[ _heroIndex ];
        _heroInfo.class = _class;
        _heroInfo.star = _star;
        _heroInfo.level = 1;

        freeHeroInfo[msg.sender] = _heroIndex;
        _heroInfo.free = true;

        //random hero properties
        uint _minPoint ;
        uint _maxPoint ;

        (_minPoint,_maxPoint) = configHeroCraft.getHeroPoint( _star);

        require(_maxPoint > _minPoint, "maxPoint need bigger minPoint");
        uint _totalPoint = _minPoint + dn( 100000, _maxPoint - _minPoint, msg.sender);

        emit loginfo(_totalPoint);
        _heroInfo.basePoint = _totalPoint;

        uint _basePoint = _totalPoint/2+ dn( 100000, _totalPoint/3, msg.sender);

        uint _lastPoint = _totalPoint - _basePoint;

        uint _career ;
        
        (_career,,) = configHeroCraft.getHeroBaseInfo( _class );

        if( _career == 1 ) {
            _heroInfo.strength = _basePoint;

            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.dexterity = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.intelligence = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
        }else if( _career == 2 ) {
            _heroInfo.dexterity = _basePoint;

            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.strength = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.intelligence = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
        }else if( _career == 3 ) {
            _heroInfo.intelligence = _basePoint;

            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.strength = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.dexterity = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
        }

        if( _lastPoint > 0 ){
            uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
            _heroInfo.constitution = _randomPoint;
            _lastPoint = _lastPoint - _randomPoint;
        }
        if( _lastPoint > 0 ){
            uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
            _heroInfo.wisdom = _randomPoint;
            _lastPoint = _lastPoint - _randomPoint;
        }
        if( _lastPoint > 0 ){
            _heroInfo.luck = _lastPoint;
        }

        //
        metaHeroCraftNFT.createHero(msg.sender, _heroIndex);

        emit newFreeHero( msg.sender, _class , _star);

    }

    //use the titan to get random hero
    function openBlindBox( uint openType) external  notPause returns (uint _heroIndex, uint _class, uint _star) {
        
        //check resource
        uint256 amount = IERC20(titanToken).balanceOf( msg.sender );
        require( openType == 1, "only support opentype = 1");
        require( amount >= openBoxTitanAmount , "user token amount not enough");

        //get random class
        _class = dn( 100000, maxClass, msg.sender) + 1 ;
        
        //get random star
        uint _openRatio = dn(100000, 10000, msg.sender)+1;
        _star = 1;
        if( _openRatio <= ratioStar6 ){
            _star = 6;
        }else if( _openRatio <= ratioStar5 ){
            _star = 5;
        }else if( _openRatio <= ratioStar4 ){
            _star = 4;
        }else if( _openRatio <= ratioStar3 ){
            _star = 3;
        }else if( _openRatio <= ratioStar2 ){
            _star = 2;
        }


        HeroNFTCount storage _heroNftCount = heroAmount[_class];
        _heroIndex = _heroNftCount.totalCount + 1 + _class * 10000000000 + _star * 1000000000;
        _heroNftCount.totalCount = _heroNftCount.totalCount + 1;

        if( _star == 1 ){
            _heroNftCount.star1 = _heroNftCount.star1 + 1;
        }else if ( _star == 2 ){
            _heroNftCount.star2 = _heroNftCount.star2 + 1;
        }else if ( _star == 3 ){
            _heroNftCount.star3 = _heroNftCount.star3 + 1;
        }else if ( _star == 4 ){
            _heroNftCount.star4 = _heroNftCount.star4 + 1;
        }else if ( _star == 5 ){
            _heroNftCount.star5 = _heroNftCount.star5 + 1;
        }else if ( _star == 6 ){
            _heroNftCount.star6 = _heroNftCount.star6 + 1;
        }


        HeroInfo storage _heroInfo = heroInfo[ _heroIndex ];
        _heroInfo.class = _class;
        _heroInfo.star = _star;
        _heroInfo.level = 1;

        //random hero properties
        uint _minPoint ;
        uint _maxPoint ;

        (_minPoint,_maxPoint) = configHeroCraft.getHeroPoint( _star);

        require(_maxPoint > _minPoint, "maxPoint need bigger minPoint");
        uint _totalPoint = _minPoint + dn( 100000, _maxPoint - _minPoint, msg.sender);

        emit loginfo(_totalPoint);
        _heroInfo.basePoint = _totalPoint;

        uint _basePoint = _totalPoint/2+ dn( 100000, _totalPoint/3, msg.sender);

        uint _lastPoint = _totalPoint - _basePoint;

        uint _career ;
        
        (_career,,) = configHeroCraft.getHeroBaseInfo( _class );

        if( _career == 1 ) {
            _heroInfo.strength = _basePoint;

            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.dexterity = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.intelligence = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
        }else if( _career == 2 ) {
            _heroInfo.dexterity = _basePoint;

            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.strength = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.intelligence = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
        }else if( _career == 3 ) {
            _heroInfo.intelligence = _basePoint;

            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.strength = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.dexterity = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
        }

        if( _lastPoint > 0 ){
            uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
            _heroInfo.constitution = _randomPoint;
            _lastPoint = _lastPoint - _randomPoint;
        }
        if( _lastPoint > 0 ){
            uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
            _heroInfo.wisdom = _randomPoint;
            _lastPoint = _lastPoint - _randomPoint;
        }
        if( _lastPoint > 0 ){
            _heroInfo.luck = _lastPoint;
        }

        //
        TransferHelper.safeTransferFrom( address(titanToken), msg.sender, address(this), openBoxTitanAmount);

        metaHeroCraftNFT.createHero(msg.sender, _heroIndex);

        emit newHero( msg.sender, _class , _star);

    }

    function createHero(uint _class,uint _star, address _owner ) external onlyGovernor returns (uint _heroIndex){
        
        HeroNFTCount storage _heroNftCount = heroAmount[_class];
        _heroIndex = _heroNftCount.totalCount + 1 + _class * 10000000000 + _star * 1000000000;
        _heroNftCount.totalCount = _heroNftCount.totalCount + 1;

        if( _star == 1 ){
            _heroNftCount.star1 = _heroNftCount.star1 + 1;
        }else if ( _star == 2 ){
            _heroNftCount.star2 = _heroNftCount.star2 + 1;
        }else if ( _star == 3 ){
            _heroNftCount.star3 = _heroNftCount.star3 + 1;
        }else if ( _star == 4 ){
            _heroNftCount.star4 = _heroNftCount.star4 + 1;
        }else if ( _star == 5 ){
            _heroNftCount.star5 = _heroNftCount.star5 + 1;
        }


        HeroInfo storage _heroInfo = heroInfo[ _heroIndex ];
        _heroInfo.class = _class;
        _heroInfo.star = _star;
        _heroInfo.level = 1;

        //random hero properties
        uint _minPoint ;
        uint _maxPoint ;

        (_minPoint,_maxPoint) = configHeroCraft.getHeroPoint( _star);

        uint _totalPoint = _minPoint + dn( 100000, _maxPoint - _minPoint, msg.sender);

        uint _basePoint = _totalPoint/2+ dn( 100000, _totalPoint/3, msg.sender);

        uint _lastPoint = _totalPoint - _basePoint;

        uint _career ;
        
        (_career,,) = configHeroCraft.getHeroBaseInfo( _class );
        if( _career == 1 ) {
            _heroInfo.strength = _basePoint;

            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.dexterity = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.intelligence = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
        }else if( _career == 2 ) {
            _heroInfo.dexterity = _basePoint;

            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.strength = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.intelligence = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
        }else if( _career == 3 ) {
            _heroInfo.intelligence = _basePoint;

            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.strength = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
            if( _lastPoint > 0 ){
                uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
                _heroInfo.dexterity = _randomPoint;
                _lastPoint = _lastPoint - _randomPoint;
            }
        }

        if( _lastPoint > 0 ){
            uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
            _heroInfo.constitution = _randomPoint;
            _lastPoint = _lastPoint - _randomPoint;
        }
        if( _lastPoint > 0 ){
            uint _randomPoint = dn( 100000, _lastPoint, msg.sender);
            _heroInfo.wisdom = _randomPoint;
            _lastPoint = _lastPoint - _randomPoint;
        }
        if( _lastPoint > 0 ){
            _heroInfo.luck = _lastPoint;
        }

        metaHeroCraftNFT.createHero(_owner, _heroIndex);

        emit newHero( _owner, _class , _star);
        
    }

    //submit battle pve level
    function battleLevel(uint256 _heroIndex, uint256 _levelId )  public nonReentrant notPause {
        require(_isApprovedOrOwner( msg.sender, _heroIndex ),"hero is not your asset");

        require( address(configHeroCraft) != address(0),"herocraft Config is not ready!");

        //query the pve resource
        uint _level;
        uint _energy;
        uint _gold;
        uint _titan;
        uint _itemId;

        (_level,_energy,_gold,_titan,_itemId) = configHeroCraft.getLevelInfo(_levelId);

        HeroBattleTime storage _heroBattleTime = heroBattleTime[ _heroIndex ];
        uint _checkTime = block.timestamp - DAY;
        if( _energy > 0 ){
            //update & check battle time
            uint _battleTimes = 0;
            if( _heroBattleTime.time1 <  _checkTime ){
                _heroBattleTime.time1 = 0;
            }else{
                _battleTimes ++;
            }

            if( _heroBattleTime.time2 <  _checkTime ){
                _heroBattleTime.time2 = 0;
            }else{
                _battleTimes ++;
            }

            if( _heroBattleTime.time3 <  _checkTime ){
                _heroBattleTime.time3 = 0;
            }else{
                _battleTimes ++;
            }

            require( _battleTimes < 3 , "Hero exceed battle times");
        }

        //use the resource
        HeroInfo memory _heroInfo = heroInfo[ _heroIndex ];
        require( _heroInfo.level >= _level, "hero level is lower the Level limit");

        if( _gold > 0 ){
            uint256 amount = IERC20(heroGoldToken).balanceOf( msg.sender );
            require(_gold <= amount, "Gold is not enough");

            TransferHelper.safeTransferFrom( address(heroGoldToken), msg.sender, address(this), _gold);

        }

        if( _titan > 0 ){
            uint256 amount = IERC20(titanToken).balanceOf( msg.sender );
            require(_titan <= amount, "Titan is not enough");

            TransferHelper.safeTransferFrom( address(titanToken), msg.sender, address(this), _titan);
        }
        
        if( _energy > 0 ){
            //update battle times
            if( _heroBattleTime.time1 == 0 ){
                _heroBattleTime.time1 = block.timestamp;
            } else if( _heroBattleTime.time2 == 0 ){
                _heroBattleTime.time2 = block.timestamp;
            } else if( _heroBattleTime.time3 == 0 ){
                _heroBattleTime.time3 = block.timestamp;
            }
        }
        

        emit battleLevelStart( msg.sender, _heroIndex, _levelId );
    }

    //governor
    function addGovernor(address _governor) public onlyOwner returns (bool) {
        require(_governor != address(0), "_governor is the zero address");
        return EnumerableSet.add(_governors, _governor);
    }

    function delGovernor(address _governor) public onlyOwner returns (bool) {
        require(_governor != address(0), "_governor is the zero address");
        return EnumerableSet.remove(_governors, _governor);
    }

    function getGovernorLength() public view returns (uint256) {
        return EnumerableSet.length(_governors);
    }

    function isGovernor(address account) public view returns (bool) {
        return EnumerableSet.contains(_governors, account);
    }

    function getGovernor(uint256 _index) public view onlyOwner returns (address){
        require(_index <= getGovernorLength() - 1, "index out of bounds");
        return EnumerableSet.at(_governors, _index);
    }

    // modifier for governor function
    modifier onlyGovernor() {
        require(isGovernor(msg.sender), "caller is not the governor");
        _;
    }

    //blackList
    function addBlackList(address _blackAddress) public onlyOwner returns (bool) {
        require(_blackAddress != address(0), "_blackAddress is the zero address");
        return EnumerableSet.add(_blackList, _blackAddress);
    }

    function delBlackList(address _blackAddress) public onlyOwner returns (bool) {
        require(_blackAddress != address(0), "_blackAddress is the zero address");
        return EnumerableSet.remove(_blackList, _blackAddress);
    }

    function getBlackListLength() public view returns (uint256) {
        return EnumerableSet.length(_blackList);
    }

    function isBlackList(address account) public view returns (bool) {
        return EnumerableSet.contains(_blackList, account);
    }

    function getBlackList(uint256 _index) public view onlyOwner returns (address){
        require(_index <= getGovernorLength() - 1, "index out of bounds");
        return EnumerableSet.at(_blackList, _index);
    }

    // modifier for not in blacklist function
    modifier onlyNotBlackList() {
        require(!isBlackList(msg.sender), "caller is the black");
        _;
    }

    function setPause() public onlyOwner {
        paused = !paused;
    }

    modifier notPause() {
        require(paused == false, "Game has been suspended");
        _;
    }

    //call random 
    function dn(uint256 _seedValue, uint256 _number, address _sender)
        public
        view
        returns (uint256)
    {
        return helperRandom.getRandomNumber(_seedValue, _number, _sender);
    }

    function withdrawEmergency(address tokenaddress,address to) public onlyOwner{	
        IERC20(tokenaddress).transfer(to,IERC20(tokenaddress).balanceOf(address(this)));
    }

}