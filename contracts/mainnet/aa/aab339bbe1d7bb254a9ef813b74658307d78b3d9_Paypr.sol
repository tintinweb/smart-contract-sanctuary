// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/EnumerableSet.sol

pragma solidity ^0.6.0;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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

// File: @openzeppelin/contracts-ethereum-package/contracts/introspection/IERC165.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


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
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/introspection/ERC165.sol

pragma solidity ^0.6.0;



/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165UpgradeSafe is Initializable, IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;


    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {


        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);

    }


    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
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

    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.6.0;


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

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.6.0;






/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
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

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {


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
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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

    uint256[44] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/introspection/ERC165Checker.sol

pragma solidity ^0.6.2;

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

// File: contracts/core/consumable/IConsumable.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;



interface IConsumable is IERC165, IERC20 {
  struct ConsumableAmount {
    IConsumable consumable;
    uint256 amount;
  }

  /**
   * @dev Returns the symbol for the ERC20 token, which is usually a shorter
   * version of the name
   */
  //  function symbol() external view returns (string memory);

  /**
   * @dev Returns the number of decimals that this consumable uses.
   *
   * NOTE: The standard number of decimals is 18, to match ETH
   */
  //  function decimals() external pure returns (uint8);

  /**
   * @dev Returns the amount of tokens owned by caller.
   */
  function myBalance() external view returns (uint256);

  /**
   * @dev Returns the remaining number of tokens that caller will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {increaseAllowance}, {decreaseAllowance} or {transferFrom} are called.
   */
  function myAllowance(address owner) external view returns (uint256);

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   */
  //  function increaseAllowance(address spender, uint256 addedValue) public returns (bool);

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   */
  //  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool);
}

// File: contracts/core/consumable/ConsumableInterfaceSupport.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;



library ConsumableInterfaceSupport {
  using ERC165Checker for address;

  bytes4 internal constant CONSUMABLE_INTERFACE_ID = 0x0d6673db;

  function supportsConsumableInterface(IConsumable account) internal view returns (bool) {
    return address(account).supportsInterface(CONSUMABLE_INTERFACE_ID);
  }
}

// File: contracts/core/IBaseContract.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;


interface IBaseContract is IERC165 {
  function contractName() external view returns (string memory);

  function contractDescription() external view returns (string memory);

  function contractUri() external view returns (string memory);
}

// File: contracts/core/BaseContractInterfaceSupport.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;



library BaseContractInterfaceSupport {
  using ERC165Checker for address;

  bytes4 internal constant BASE_CONTRACT_INTERFACE_ID = 0x321f350b;

  function supportsBaseContractInterface(IBaseContract account) internal view returns (bool) {
    return address(account).supportsInterface(BASE_CONTRACT_INTERFACE_ID);
  }
}

// File: contracts/core/BaseContract.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;




contract BaseContract is Initializable, IBaseContract, ERC165UpgradeSafe {
  struct ContractInfo {
    string name;
    string description;
    string uri;
  }

  ContractInfo private _info;

  function _initializeBaseContract(ContractInfo memory info) internal initializer {
    __ERC165_init();
    _registerInterface(BaseContractInterfaceSupport.BASE_CONTRACT_INTERFACE_ID);

    _info = info;
  }

  function contractName() external override view returns (string memory) {
    return _info.name;
  }

  function contractDescription() external override view returns (string memory) {
    return _info.description;
  }

  function contractUri() external override view returns (string memory) {
    return _info.uri;
  }

  uint256[50] private ______gap;
}

// File: contracts/core/IDisableable.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;

interface IDisableable {
  /**
   * Emitted when the contract is disabled
   */
  event Disabled();

  /**
   * Emitted when the contract is enabled
   */
  event Enabled();

  /**
   * @dev Returns whether or not the contract is disabled
   */
  function disabled() external view returns (bool);

  /**
   * @dev Returns whether or not the contract is enabled
   */
  function enabled() external view returns (bool);

  modifier onlyEnabled() virtual {
    require(!this.disabled(), 'Contract is disabled');
    _;
  }

  /**
   * @dev Disables the contract
   */
  function disable() external;

  /**
   * @dev Enables the contract
   */
  function enable() external;
}

// File: contracts/core/Disableable.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;


abstract contract Disableable is IDisableable {
  bool private _disabled;

  function disabled() external override view returns (bool) {
    return _disabled;
  }

  function enabled() external override view returns (bool) {
    return !_disabled;
  }

  /**
   * @dev Disables the contract
   */
  function _disable() internal {
    if (_disabled) {
      return;
    }

    _disabled = true;
    emit Disabled();
  }

  /**
   * @dev Enables the contract
   */
  function _enable() internal {
    if (!_disabled) {
      return;
    }

    _disabled = false;
    emit Enabled();
  }

  uint256[50] private ______gap;
}

// File: contracts/core/transfer/TransferringInterfaceSupport.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;


library TransferringInterfaceSupport {
  using ERC165Checker for address;

  bytes4 internal constant TRANSFERRING_INTERFACE_ID = 0x6fafa3a8;

  function supportsTransferInterface(address account) internal view returns (bool) {
    return account.supportsInterface(TRANSFERRING_INTERFACE_ID);
  }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.6.2;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// File: contracts/core/transfer/ITransferring.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;





interface ITransferring is IERC165, IERC721Receiver {
  /**
   * @dev Transfer the given amount of an ERC20 token to the given recipient address.
   */
  function transferToken(
    IERC20 token,
    uint256 amount,
    address recipient
  ) external;

  /**
   * @dev Transfer the given item of an ERC721 token to the given recipient address.
   */
  function transferItem(
    IERC721 artifact,
    uint256 itemId,
    address recipient
  ) external;
}

// File: contracts/core/consumable/IConvertibleConsumable.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;


interface IConvertibleConsumable is IConsumable {
  /**
   * @dev the token that can be exchanged to/from
   */
  function exchangeToken() external view returns (IERC20);

  /**
   * @dev whether or not this consumable has a different purchase price than intrinsic value
   */
  function asymmetricalExchangeRate() external view returns (bool);

  /**
   * @dev the amount of this consumable needed to convert to 1 of `exchangeToken`
   *
   * eg if `intrinsicValueExchangeRate` is 1000, then 1000 this --> 1 `conversionToken`
   */
  function intrinsicValueExchangeRate() external view returns (uint256);

  /**
   * @dev the amount that 1 of `exchangeToken` will convert into this consumable
   *
   * eg if `purchasePriceExchangeRate` is 1000, then 1 `conversionToken` --> 1000 this
   */
  function purchasePriceExchangeRate() external view returns (uint256);

  /**
   * @dev amount of exchange token available, given total supply
   */
  function amountExchangeTokenAvailable() external view returns (uint256);

  /**
   * @dev mint `consumableAmount` tokens by converting from `exchangeToken`
   */
  function mintByExchange(uint256 consumableAmount) external;

  /**
   * @dev amount of exchange token needed to mint the given amount of consumable
   */
  function amountExchangeTokenNeeded(uint256 consumableAmount) external view returns (uint256);

  /**
   * @dev burn `consumableAmount` tokens by converting to `exchangeToken`
   */
  function burnByExchange(uint256 consumableAmount) external;

  /**
   * @dev amount of exchange token provided by burning the given amount of consumable
   */
  function amountExchangeTokenProvided(uint256 consumableAmount) external view returns (uint256);
}

// File: contracts/core/consumable/ConvertibleConsumableInterfaceSupport.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;



library ConvertibleConsumableInterfaceSupport {
  using ERC165Checker for address;

  bytes4 internal constant CONVERTIBLE_CONSUMABLE_INTERFACE_ID = 0x1574139e;

  function supportsConvertibleConsumableInterface(IConvertibleConsumable consumable) internal view returns (bool) {
    return address(consumable).supportsInterface(CONVERTIBLE_CONSUMABLE_INTERFACE_ID);
  }

  function calcConvertibleConsumableInterfaceId(IConvertibleConsumable consumable) internal pure returns (bytes4) {
    return
      consumable.exchangeToken.selector ^
      consumable.asymmetricalExchangeRate.selector ^
      consumable.intrinsicValueExchangeRate.selector ^
      consumable.purchasePriceExchangeRate.selector ^
      consumable.amountExchangeTokenAvailable.selector ^
      consumable.mintByExchange.selector ^
      consumable.amountExchangeTokenNeeded.selector ^
      consumable.burnByExchange.selector ^
      consumable.amountExchangeTokenProvided.selector;
  }
}

// File: contracts/core/transfer/TransferLogic.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;






library TransferLogic {
  using ConvertibleConsumableInterfaceSupport for IConvertibleConsumable;

  function transferToken(
    address, /*account*/
    IERC20 token,
    uint256 amount,
    address recipient
  ) internal {
    token.transfer(recipient, amount);
  }

  function transferTokenWithExchange(
    address account,
    IERC20 token,
    uint256 amount,
    address recipient
  ) internal {
    uint256 myBalance = token.balanceOf(account);
    if (myBalance < amount && IConvertibleConsumable(address(token)).supportsConvertibleConsumableInterface()) {
      // increase allowance as needed, but only if it's a convertible consumable
      IConvertibleConsumable convertibleConsumable = IConvertibleConsumable(address(token));

      uint256 amountConsumableNeeded = amount - myBalance; // safe since we checked < above
      uint256 amountExchangeToken = convertibleConsumable.amountExchangeTokenNeeded(amountConsumableNeeded);

      ERC20UpgradeSafe exchange = ERC20UpgradeSafe(address(convertibleConsumable.exchangeToken()));
      exchange.increaseAllowance(address(token), amountExchangeToken);
    }

    token.transfer(recipient, amount);
  }

  function transferItem(
    address account,
    IERC721 artifact,
    uint256 itemId,
    address recipient
  ) internal {
    artifact.safeTransferFrom(account, recipient, itemId);
  }

  function onERC721Received(
    address, /*operator*/
    address, /*from*/
    uint256, /*tokenId*/
    bytes memory /*data*/
  ) internal pure returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }
}

// File: contracts/core/consumable/Consumable.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;










abstract contract Consumable is
  IDisableable,
  Initializable,
  ITransferring,
  ContextUpgradeSafe,
  IConsumable,
  ERC165UpgradeSafe,
  BaseContract,
  ERC20UpgradeSafe
{
  using TransferLogic for address;

  function _initializeConsumable(ContractInfo memory info, string memory symbol) internal initializer {
    _initializeBaseContract(info);
    _registerInterface(ConsumableInterfaceSupport.CONSUMABLE_INTERFACE_ID);

    __ERC20_init(info.name, symbol);
    _registerInterface(TransferringInterfaceSupport.TRANSFERRING_INTERFACE_ID);
  }

  function myBalance() external override view returns (uint256) {
    return balanceOf(_msgSender());
  }

  function myAllowance(address owner) external override view returns (uint256) {
    return allowance(owner, _msgSender());
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override onlyEnabled {
    super._transfer(sender, recipient, amount);
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external virtual override returns (bytes4) {
    return TransferLogic.onERC721Received(operator, from, tokenId, data);
  }

  uint256[50] private ______gap;
}

// File: contracts/core/consumable/IConsumableExchange.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;



interface IConsumableExchange is IConsumable {
  struct ExchangeRate {
    uint256 purchasePrice;
    uint256 intrinsicValue;
  }

  /**
   * @dev Emitted when the exchange rate changes for `token`.
   * `purchasePriceExchangeRate` is the new purchase price exchange rate
   * `intrinsicValueExchangeRate` is the new intrinsic value exchange rate
   */
  event ExchangeRateChanged(
    IConvertibleConsumable indexed token,
    uint256 indexed purchasePriceExchangeRate,
    uint256 indexed intrinsicValueExchangeRate
  );

  /**
   * @dev Returns the total number of convertibles registered asn part of this exchange.
   */
  function totalConvertibles() external view returns (uint256);

  /**
   * @dev Returns the convertible with the given index. Reverts if index is higher than totalConvertibles.
   */
  function convertibleAt(uint256 index) external view returns (IConvertibleConsumable);

  /**
   * @dev Returns whether or not the token at the given address is convertible
   */
  function isConvertible(IConvertibleConsumable token) external view returns (bool);

  /**
   * @dev Returns exchange rate of the given token
   *
   * eg if exchange rate is 1000, then 1 this consumable == 1000 associated tokens
   */
  function exchangeRateOf(IConvertibleConsumable token) external view returns (ExchangeRate memory);

  /**
   * @dev Exchanges the given amount of this consumable to the given token for the sender
   *
   * The sender must have enough of this consumable to make the exchange.
   *
   * When complete, the sender should transfer the new tokens into their account.
   */
  function exchangeTo(IConvertibleConsumable tokenAddress, uint256 amount) external;

  /**
   * @dev Exchanges the given amount of the given token to this consumable for the sender
   *
   * Before calling, the sender must provide allowance of the given token for the appropriate amount.this
   *
   * When complete, the sender will have the correct amount of this consumable.
   */
  function exchangeFrom(IConvertibleConsumable token, uint256 tokenAmount) external;

  /**
   * @dev Registers a token with this exchange, using the given `purchasePriceExchangeRate` and `intrinsicValueExchangeRate`.
   *
   * NOTE: Can only be called when the token has no current exchange rate
   */
  function registerToken(uint256 purchasePriceExchangeRate, uint256 intrinsicValueExchangeRate) external;
}

// File: contracts/core/consumable/ConsumableExchangeInterfaceSupport.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;



library ConsumableExchangeInterfaceSupport {
  using ERC165Checker for address;

  bytes4 internal constant CONSUMABLE_EXCHANGE_INTERFACE_ID = 0x1e34ecc8;

  function supportsConsumableExchangeInterface(IConsumableExchange exchange) internal view returns (bool) {
    return address(exchange).supportsInterface(CONSUMABLE_EXCHANGE_INTERFACE_ID);
  }

  function calcConsumableExchangeInterfaceId(IConsumableExchange exchange) internal pure returns (bytes4) {
    return
      exchange.totalConvertibles.selector ^
      exchange.convertibleAt.selector ^
      exchange.isConvertible.selector ^
      exchange.exchangeRateOf.selector ^
      exchange.exchangeTo.selector ^
      exchange.exchangeFrom.selector ^
      exchange.registerToken.selector;
  }
}

// File: contracts/core/consumable/ConsumableConversionMath.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;





library ConsumableConversionMath {
  using SafeMath for uint256;
  using ConvertibleConsumableInterfaceSupport for IConvertibleConsumable;

  function exchangeTokenNeeded(IConsumable.ConsumableAmount memory consumableAmount) internal view returns (uint256) {
    IConvertibleConsumable consumable = IConvertibleConsumable(address(consumableAmount.consumable));
    require(
      consumable.supportsConvertibleConsumableInterface(),
      'ConsumableConversionMath: consumable not convertible'
    );

    uint256 purchasePriceExchangeRate = consumable.purchasePriceExchangeRate();
    return exchangeTokenNeeded(consumableAmount.amount, purchasePriceExchangeRate);
  }

  function exchangeTokenProvided(IConsumable.ConsumableAmount memory consumableAmount) internal view returns (uint256) {
    IConvertibleConsumable consumable = IConvertibleConsumable(address(consumableAmount.consumable));
    require(
      consumable.supportsConvertibleConsumableInterface(),
      'ConsumableConversionMath: consumable not convertible'
    );

    uint256 intrinsicValueExchangeRate = consumable.intrinsicValueExchangeRate();
    return exchangeTokenProvided(consumableAmount.amount, intrinsicValueExchangeRate);
  }

  function exchangeTokenNeeded(uint256 consumableAmount, uint256 purchasePriceExchangeRate)
    internal
    pure
    returns (uint256)
  {
    return _toExchangeToken(consumableAmount, purchasePriceExchangeRate, true);
  }

  function exchangeTokenProvided(uint256 consumableAmount, uint256 intrinsicValueExchangeRate)
    internal
    pure
    returns (uint256)
  {
    return _toExchangeToken(consumableAmount, intrinsicValueExchangeRate, false);
  }

  function _toExchangeToken(
    uint256 consumableAmount,
    uint256 exchangeRate,
    bool purchasing
  ) private pure returns (uint256) {
    uint256 amountExchangeToken = consumableAmount.div(exchangeRate);
    if (purchasing && consumableAmount.mod(exchangeRate) != 0) {
      amountExchangeToken += 1;
    }
    return amountExchangeToken;
  }

  function convertibleTokenNeeded(uint256 exchangeTokenAmount, uint256 intrinsicValueExchangeRate)
    internal
    pure
    returns (uint256)
  {
    return _fromExchangeToken(exchangeTokenAmount, intrinsicValueExchangeRate);
  }

  function convertibleTokenProvided(uint256 exchangeTokenAmount, uint256 purchasePriceExchangeRate)
    internal
    pure
    returns (uint256)
  {
    return _fromExchangeToken(exchangeTokenAmount, purchasePriceExchangeRate);
  }

  function _fromExchangeToken(uint256 exchangeTokenAmount, uint256 exchangeRate) private pure returns (uint256) {
    return exchangeTokenAmount.mul(exchangeRate);
  }

  function exchangeTokenNeeded(IConsumableExchange exchange, IConsumable.ConsumableAmount[] memory consumableAmounts)
    internal
    view
    returns (uint256)
  {
    return _toExchangeToken(exchange, consumableAmounts, true);
  }

  function exchangeTokenProvided(IConsumableExchange exchange, IConsumable.ConsumableAmount[] memory consumableAmounts)
    internal
    view
    returns (uint256)
  {
    return _toExchangeToken(exchange, consumableAmounts, false);
  }

  function _toExchangeToken(
    IConsumableExchange exchange,
    IConsumable.ConsumableAmount[] memory consumableAmounts,
    bool purchasing
  ) private view returns (uint256) {
    uint256 totalAmount = 0;

    for (uint256 consumableIndex = 0; consumableIndex < consumableAmounts.length; consumableIndex++) {
      IConsumable.ConsumableAmount memory consumableAmount = consumableAmounts[consumableIndex];
      IConsumable consumable = consumableAmount.consumable;
      IConvertibleConsumable convertibleConsumable = IConvertibleConsumable(address(consumable));
      uint256 amount = consumableAmount.amount;

      require(
        exchange.isConvertible(convertibleConsumable),
        'ConsumableConversionMath: Consumable must be convertible by exchange'
      );

      IConsumableExchange.ExchangeRate memory exchangeRate = exchange.exchangeRateOf(convertibleConsumable);
      uint256 exchangeAmount;
      if (purchasing) {
        exchangeAmount = _toExchangeToken(amount, exchangeRate.purchasePrice, true);
      } else {
        exchangeAmount = _toExchangeToken(amount, exchangeRate.intrinsicValue, false);
      }

      totalAmount = totalAmount.add(exchangeAmount);
    }

    return totalAmount;
  }
}

// File: contracts/core/consumable/ConsumableExchange.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;








abstract contract ConsumableExchange is IConsumableExchange, Consumable {
  using EnumerableSet for EnumerableSet.AddressSet;
  using ConsumableConversionMath for uint256;
  using SafeMath for uint256;

  // amount that 1 of this consumable will convert into the associated token
  // eg if exchange rate is 1000, then 1 this consumable == 1000 associated tokens
  mapping(address => ExchangeRate) private _exchangeRates;
  EnumerableSet.AddressSet private _convertibles;

  function _initializeConsumableExchange(ContractInfo memory info, string memory symbol) internal initializer {
    _initializeConsumable(info, symbol);
    _registerInterface(ConsumableExchangeInterfaceSupport.CONSUMABLE_EXCHANGE_INTERFACE_ID);
  }

  function totalConvertibles() external override view returns (uint256) {
    return _convertibles.length();
  }

  function convertibleAt(uint256 index) external override view returns (IConvertibleConsumable) {
    return IConvertibleConsumable(_convertibles.at(index));
  }

  function isConvertible(IConvertibleConsumable token) external override view returns (bool) {
    return _exchangeRates[address(token)].purchasePrice > 0;
  }

  function exchangeRateOf(IConvertibleConsumable token) external override view returns (ExchangeRate memory) {
    return _exchangeRates[address(token)];
  }

  function exchangeTo(IConvertibleConsumable token, uint256 tokenAmount) external override {
    _exchangeTo(_msgSender(), token, tokenAmount);
  }

  function _exchangeTo(
    address account,
    IConvertibleConsumable consumable,
    uint256 amount
  ) internal onlyEnabled {
    ExchangeRate memory exchangeRate = _exchangeRates[address(consumable)];

    require(exchangeRate.purchasePrice != 0, 'ConsumableExchange: consumable is not convertible');

    uint256 tokenAmount = amount.convertibleTokenProvided(exchangeRate.purchasePrice);

    _transfer(account, address(this), amount);
    this.increaseAllowance(address(consumable), amount);

    consumable.mintByExchange(tokenAmount);

    ERC20UpgradeSafe token = ERC20UpgradeSafe(address(consumable));
    token.increaseAllowance(account, tokenAmount);
  }

  function exchangeFrom(IConvertibleConsumable token, uint256 tokenAmount) external override {
    _exchangeFrom(_msgSender(), token, tokenAmount);
  }

  function _exchangeFrom(
    address account,
    IConvertibleConsumable token,
    uint256 tokenAmount
  ) internal onlyEnabled {
    ExchangeRate memory exchangeRate = _exchangeRates[address(token)];

    require(exchangeRate.intrinsicValue != 0, 'ConsumableExchange: token is not convertible');

    token.transferFrom(account, address(this), tokenAmount);

    token.burnByExchange(tokenAmount);

    uint256 myAmount = tokenAmount.exchangeTokenProvided(exchangeRate.intrinsicValue);
    this.transferFrom(address(token), address(this), myAmount);

    _transfer(address(this), account, myAmount);
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override onlyEnabled {
    super._transfer(sender, recipient, amount);

    // check to ensure there is enough of this token left over to exchange if the sender is registered
    ExchangeRate memory senderExchangeRate = _exchangeRates[sender];
    if (senderExchangeRate.intrinsicValue != 0) {
      uint256 senderBalance = balanceOf(sender);
      uint256 tokenAmountAllowed = senderBalance.convertibleTokenProvided(senderExchangeRate.intrinsicValue);

      IERC20 token = IERC20(sender);
      require(token.totalSupply() <= tokenAmountAllowed, 'ConsumableExchange: not enough left to cover exchange');
    }
  }

  function registerToken(uint256 purchasePriceExchangeRate, uint256 intrinsicValueExchangeRate) external override {
    IConvertibleConsumable token = IConvertibleConsumable(_msgSender());
    require(purchasePriceExchangeRate > 0, 'ConsumableExchange: must register with a purchase price exchange rate');
    require(intrinsicValueExchangeRate > 0, 'ConsumableExchange: must register with an intrinsic value exchange rate');
    require(
      _exchangeRates[address(token)].purchasePrice == 0,
      'ConsumableExchange: cannot register already registered token'
    );

    _updateExchangeRate(
      token,
      ExchangeRate({ purchasePrice: purchasePriceExchangeRate, intrinsicValue: intrinsicValueExchangeRate })
    );
  }

  function _updateExchangeRate(IConvertibleConsumable token, ExchangeRate memory exchangeRate) internal onlyEnabled {
    require(token != IConvertibleConsumable(0), 'ConsumableExchange: updateExchangeRate for the zero address');

    if (exchangeRate.purchasePrice != 0 && exchangeRate.intrinsicValue != 0) {
      _convertibles.add(address(token));
    } else {
      _convertibles.remove(address(token));
    }

    _exchangeRates[address(token)] = exchangeRate;
    emit ExchangeRateChanged(token, exchangeRate.purchasePrice, exchangeRate.intrinsicValue);
  }

  uint256[50] private ______gap;
}

// File: contracts/core/consumable/ConvertibleConsumable.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;







abstract contract ConvertibleConsumable is IConvertibleConsumable, Consumable {
  using SafeMath for uint256;
  using ConsumableConversionMath for uint256;

  IERC20 private _exchangeToken;

  // amount that 1 of exchangeToken will convert into this consumable
  // eg if purchasePriceExchangeRate is 1000, then 1 exchangeToken will purchase 1000 of this token
  uint256 private _purchasePriceExchangeRate;

  // amount of this token needed to exchange for 1 exchangeToken
  // eg if intrinsicValueExchangeRate is 1000, then 1000 of this is needed to exchange for 1 exchangeToken
  uint256 private _intrinsicValueExchangeRate;

  function _initializeConvertibleConsumable(
    ContractInfo memory info,
    string memory symbol,
    IERC20 exchangeToken,
    uint256 purchasePriceExchangeRate,
    uint256 intrinsicValueExchangeRate,
    bool registerWithExchange
  ) internal initializer {
    _initializeConsumable(info, symbol);
    _registerInterface(ConvertibleConsumableInterfaceSupport.CONVERTIBLE_CONSUMABLE_INTERFACE_ID);

    require(purchasePriceExchangeRate > 0, 'ConvertibleConsumable: purchase price exchange rate must be > 0');
    require(intrinsicValueExchangeRate > 0, 'ConvertibleConsumable: intrinsic value exchange rate must be > 0');
    require(
      purchasePriceExchangeRate <= intrinsicValueExchangeRate,
      'ConvertibleConsumable: purchase price exchange must be <= intrinsic value exchange rate'
    );

    // enhance: when ERC20 supports ERC165, check token here

    _exchangeToken = exchangeToken;
    _purchasePriceExchangeRate = purchasePriceExchangeRate;
    _intrinsicValueExchangeRate = intrinsicValueExchangeRate;

    if (registerWithExchange) {
      _registerWithExchange();
    }
  }

  function exchangeToken() external override view returns (IERC20) {
    return _exchangeToken;
  }

  function asymmetricalExchangeRate() external override view returns (bool) {
    return _purchasePriceExchangeRate != _intrinsicValueExchangeRate;
  }

  function purchasePriceExchangeRate() external override view returns (uint256) {
    return _purchasePriceExchangeRate;
  }

  function intrinsicValueExchangeRate() external override view returns (uint256) {
    return _intrinsicValueExchangeRate;
  }

  function amountExchangeTokenAvailable() external override view returns (uint256) {
    uint256 amountNeeded = totalSupply().exchangeTokenNeeded(_intrinsicValueExchangeRate);
    uint256 amountExchangeToken = _exchangeToken.balanceOf(address(this));
    if (amountNeeded >= amountExchangeToken) {
      return 0;
    }
    return amountExchangeToken - amountNeeded;
  }

  function _registerWithExchange() internal onlyEnabled {
    IConsumableExchange consumableExchange = IConsumableExchange(address(_exchangeToken));
    consumableExchange.registerToken(_purchasePriceExchangeRate, _intrinsicValueExchangeRate);
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override onlyEnabled {
    _exchangeIfNeeded(sender, amount);

    super._transfer(sender, recipient, amount);
  }

  function _exchangeIfNeeded(address sender, uint256 consumableAmount) internal onlyEnabled {
    uint256 senderBalance = this.balanceOf(sender);
    if (senderBalance < consumableAmount) {
      // no need to use SafeMath since we know that the sender balance < amount
      uint256 consumableAmountNeeded = consumableAmount - senderBalance;

      // assume that they wanted to convert since they knew they didn't have enough to transfer
      _mintByExchange(sender, consumableAmountNeeded);
    }
  }

  function mintByExchange(uint256 consumableAmount) external override {
    _mintByExchange(_msgSender(), consumableAmount);
  }

  /**
   * @dev Converts exchange token into `consumableAmount` of this consumable
   */
  function _mintByExchange(address account, uint256 consumableAmount) internal onlyEnabled {
    uint256 amountExchangeToken = this.amountExchangeTokenNeeded(consumableAmount);

    _exchangeToken.transferFrom(account, address(this), amountExchangeToken);

    _mint(account, consumableAmount);
  }

  function amountExchangeTokenNeeded(uint256 consumableAmount) external override view returns (uint256) {
    return consumableAmount.exchangeTokenNeeded(_purchasePriceExchangeRate);
  }

  function _mint(address account, uint256 amount) internal virtual override {
    super._mint(account, amount);

    uint256 amountNeeded = totalSupply().exchangeTokenNeeded(_intrinsicValueExchangeRate);
    uint256 amountExchangeToken = _exchangeToken.balanceOf(address(this));
    require(amountExchangeToken >= amountNeeded, 'ConvertibleConsumable: Not enough exchange token available to mint');
  }

  function burnByExchange(uint256 consumableAmount) external virtual override {
    _burnByExchange(_msgSender(), consumableAmount);
  }

  /**
   * @dev Converts `consumableAmount` of this consumable into exchange token
   */
  function _burnByExchange(address receiver, uint256 consumableAmount) internal onlyEnabled {
    _burn(receiver, consumableAmount);

    ERC20UpgradeSafe token = ERC20UpgradeSafe(address(_exchangeToken));

    uint256 exchangeTokenAmount = this.amountExchangeTokenProvided(consumableAmount);
    token.increaseAllowance(receiver, exchangeTokenAmount);
  }

  function amountExchangeTokenProvided(uint256 consumableAmount) external override view returns (uint256) {
    return consumableAmount.exchangeTokenProvided(_intrinsicValueExchangeRate);
  }

  uint256[50] private ______gap;
}

// File: contracts/core/access/IRoleDelegate.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;

interface IRoleDelegate {
  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function isInRole(bytes32 role, address account) external view returns (bool);
}

// File: contracts/core/access/RoleDelegateInterfaceSupport.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;



library RoleDelegateInterfaceSupport {
  using ERC165Checker for address;

  bytes4 internal constant ROLE_DELEGATE_INTERFACE_ID = 0x7cef57ea;

  function supportsRoleDelegateInterface(IRoleDelegate roleDelegate) internal view returns (bool) {
    return address(roleDelegate).supportsInterface(ROLE_DELEGATE_INTERFACE_ID);
  }
}

// File: contracts/core/access/RoleSupport.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;

library RoleSupport {
  bytes32 public constant SUPER_ADMIN_ROLE = 0x00;
  bytes32 public constant MINTER_ROLE = keccak256('Minter');
  bytes32 public constant ADMIN_ROLE = keccak256('Admin');
  bytes32 public constant TRANSFER_AGENT_ROLE = keccak256('Transfer');
}

// File: contracts/core/access/DelegatingRoles.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.0;






contract DelegatingRoles is Initializable, ContextUpgradeSafe {
  using EnumerableSet for EnumerableSet.AddressSet;
  using RoleDelegateInterfaceSupport for IRoleDelegate;

  EnumerableSet.AddressSet private _roleDelegates;

  function isRoleDelegate(IRoleDelegate roleDelegate) public view returns (bool) {
    return _roleDelegates.contains(address(roleDelegate));
  }

  /**
   * @dev Adds the given role delegate
   */
  function _addRoleDelegate(IRoleDelegate roleDelegate) internal {
    require(address(roleDelegate) != address(0), 'Role delegate cannot be zero address');
    require(roleDelegate.supportsRoleDelegateInterface(), 'Role delegate must implement interface');

    _roleDelegates.add(address(roleDelegate));
    emit RoleDelegateAdded(roleDelegate);
  }

  /**
   * @dev Removes the given role delegate
   */
  function _removeRoleDelegate(IRoleDelegate roleDelegate) internal {
    _roleDelegates.remove(address(roleDelegate));
    emit RoleDelegateRemoved(roleDelegate);
  }

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function _hasRole(bytes32 role, address account) internal virtual view returns (bool) {
    uint256 roleDelegateLength = _roleDelegates.length();
    for (uint256 roleDelegateIndex = 0; roleDelegateIndex < roleDelegateLength; roleDelegateIndex++) {
      IRoleDelegate roleDelegate = IRoleDelegate(_roleDelegates.at(roleDelegateIndex));
      if (roleDelegate.isInRole(role, account)) {
        return true;
      }
    }

    return false;
  }

  // Admin
  modifier onlyAdmin() {
    require(isAdmin(_msgSender()), 'Caller does not have the Admin role');
    _;
  }

  function isAdmin(address account) public view returns (bool) {
    return _hasRole(RoleSupport.ADMIN_ROLE, account);
  }

  // Minter
  modifier onlyMinter() {
    require(isMinter(_msgSender()), 'Caller does not have the Minter role');
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return _hasRole(RoleSupport.MINTER_ROLE, account);
  }

  // Transfer Agent
  modifier onlyTransferAgent() {
    require(isTransferAgent(_msgSender()), 'Caller does not have the Transfer Agent role');
    _;
  }

  function isTransferAgent(address account) public view returns (bool) {
    return _hasRole(RoleSupport.TRANSFER_AGENT_ROLE, account);
  }

  /**
   * @dev Emitted when `roleDelegated` is added.
   */
  event RoleDelegateAdded(IRoleDelegate indexed roleDelegate);

  /**
   * @dev Emitted when `roleDelegated` is removed.
   */
  event RoleDelegateRemoved(IRoleDelegate indexed roleDelegate);

  uint256[50] private ______gap;
}

// File: contracts/consumables/Paypr.sol

/*
 * Copyright (c) 2020 The Paypr Company, LLC
 *
 * This file is NOT part of Paypr Ethereum Contracts and CANNOT be redistributed.
 */

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;





contract Paypr is
  Initializable,
  ContextUpgradeSafe,
  ERC165UpgradeSafe,
  BaseContract,
  Consumable,
  ConvertibleConsumable,
  ConsumableExchange,
  Disableable,
  DelegatingRoles
{
  using SafeMath for uint256;
  using TransferLogic for address;

  function initializePaypr(
    IConsumableExchange baseToken,
    uint256 basePurchasePriceExchangeRate,
    uint256 baseIntrinsicValueExchangeRate,
    IRoleDelegate roleDelegate
  ) public initializer {
    ContractInfo memory info = ContractInfo({
      name: 'Paypr',
      description: 'Paypr exchange token',
      uri: 'https://paypr.money/'
    });

    string memory symbol = 'ℙ';

    _initializeConvertibleConsumable(
      info,
      symbol,
      baseToken,
      basePurchasePriceExchangeRate,
      baseIntrinsicValueExchangeRate,
      false
    );
    _initializeConsumableExchange(info, symbol);

    _addRoleDelegate(roleDelegate);
  }

  /**
   * @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   */
  function mint(address account, uint256 amount) external onlyMinter {
    _mint(account, amount);
  }

  function _mint(address account, uint256 amount) internal override(ERC20UpgradeSafe, ConvertibleConsumable) {
    ERC20UpgradeSafe._mint(account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   */
  function burn(address account, uint256 amount) external onlyMinter {
    _burn(account, amount);
  }

  // TODO: remove onlyMinter when ready to exchange
  function burnByExchange(uint256 payprAmount) external override onlyEnabled onlyMinter {
    _burnByExchange(_msgSender(), payprAmount);
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal override(Consumable, ConsumableExchange, ConvertibleConsumable) onlyEnabled {
    ConvertibleConsumable._transfer(sender, recipient, amount);
  }

  function transferToken(
    IERC20 token,
    uint256 amount,
    address recipient
  ) external override onlyTransferAgent onlyEnabled {
    address(this).transferToken(token, amount, recipient);
  }

  function transferItem(
    IERC721 artifact,
    uint256 itemId,
    address recipient
  ) external override onlyTransferAgent onlyEnabled {
    address(this).transferItem(artifact, itemId, recipient);
  }

  function disable() external override onlyAdmin {
    _disable();
  }

  function enable() external override onlyAdmin {
    _enable();
  }
}