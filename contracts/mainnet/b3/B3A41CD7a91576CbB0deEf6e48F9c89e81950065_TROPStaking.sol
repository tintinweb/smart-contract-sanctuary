/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

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

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
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
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

pragma solidity ^0.6.0;


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

// File: contracts/TROPStaking.sol

pragma solidity 0.6.12;






// TROPVault distributes fees equally amongst staked pools
// Have fun reading it. Hopefully it's bug-free. God bless.

contract TimeLockLPTokenStaking {
    using SafeMath for uint256;
    using Address for address;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many  tokens the user currently has.
        uint256 rewardAllocPoint; //this is used for computing user rewards, depending on the staked amount and locked time
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardLocked;
        uint256 releaseTime;
        //
        // We do some fancy math here. Basically, any point in time, the amount of TROPs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accTROPPerRAP) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws  tokens to a pool. Here's what happens:
        //   1. The pool's `accTROPPerRAP` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.

        uint256 lpReleaseTime;
        uint256 lockedPeriod;
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 allocPoint; // How many allocation points assigned to this pool. TROPs to distribute per block.
        uint256 accTROPPerRAP; // Accumulated TROPs per rewardAllocPoint RAP, times 1e18. See below.
        uint256 totalRewardAllocPoint;
        mapping(address => mapping(address => uint256)) allowance;
        bool emergencyWithdrawable;
        uint256 rewardsInThisEpoch;
        uint256 cumulativeRewardsSinceStart;
        uint256 startBlock;
        uint256 startTime;
        uint256 totalStake;
        // For easy graphing historical epoch rewards
        mapping(uint256 => uint256) epochRewards;
        uint256 epochCalculationStartBlock;
    }

    // Info of each pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes  tokens.
    mapping(address => UserInfo) public userInfo;

    // The TROP TOKEN!
    IERC20 public trop;

    function computeReleasableLP(address _addr) public view returns (uint256) {
        if (block.timestamp < userInfo[_addr].lpReleaseTime) {
            return 0;
        }

        return userInfo[_addr].amount;
    }
}

contract TROPStaking is OwnableUpgradeSafe, TimeLockLPTokenStaking {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Dev address.
    address public devaddr;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    //// pending rewards awaiting anyone to massUpdate
    uint256 public pendingRewards;

    uint256 public epoch;

    uint256 public constant REWARD_LOCKED_PERIOD = 14 days;
    uint256 public constant REWARD_RELEASE_PERCENTAGE = 40;
    uint256 public contractStartBlock;

    uint256 private tropBalance;

    // Sets the dev fee for this contract
    // defaults at 7.24%
    // Note contract owner is meant to be a governance contract allowing TROP governance consensus
    uint16 DEV_FEE;

    uint256 public pending_DEV_rewards;

    // Returns fees generated since start of this contract
    function averageFeesPerBlockSinceStart()
        external
        view
        returns (uint256 averagePerBlock)
    {
        averagePerBlock = poolInfo
            .cumulativeRewardsSinceStart
            .add(poolInfo.rewardsInThisEpoch)
            .add(pendingRewards)
            .div(block.number.sub(poolInfo.startBlock));
    }

    // Returns averge fees in this epoch
    function averageFeesPerBlockEpoch()
        external
        view
        returns (uint256 averagePerBlock)
    {
        averagePerBlock = poolInfo.rewardsInThisEpoch.add(pendingRewards).div(
            block.number.sub(poolInfo.epochCalculationStartBlock)
        );
    }

    function getEpochReward(uint256 _epoch) public view returns (uint256) {
        return poolInfo.epochRewards[_epoch];
    }

    //Starts a new calculation epoch
    // Because averge since start will not be accurate
    function startNewEpoch() public {
        require(
            poolInfo.epochCalculationStartBlock + 50000 < block.number,
            "New epoch not ready yet"
        ); // About a week
        poolInfo.epochRewards[epoch] = poolInfo.rewardsInThisEpoch;
        poolInfo.cumulativeRewardsSinceStart = poolInfo
            .cumulativeRewardsSinceStart
            .add(poolInfo.rewardsInThisEpoch);
        poolInfo.rewardsInThisEpoch = 0;
        poolInfo.epochCalculationStartBlock = block.number;
        ++epoch;
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function initialize(address _devFundAddress) public initializer {
        OwnableUpgradeSafe.__Ownable_init();
        DEV_FEE = 1000; //10%
        trop = IERC20(0x2eC75589856562646afE393455986CaD26c4Cc5f);
        devaddr = _devFundAddress;
        contractStartBlock = block.number;
        poolInfo.startBlock = block.number;
        poolInfo.startTime = block.timestamp;
        poolInfo.epochCalculationStartBlock = block.number;
    }

    modifier validLockTime(uint256 _time) {
        require(
            _time == 10 days ||
                _time == 20 days ||
                _time == 25 days ||
                _time == 50 days ||
                _time == 75 days ||
                _time == 100 days,
            "Lock time is not valid"
        );
        _;
    }

    //to avoid exploit in time lock
    function checkLockTiming(address _user, uint256 _time) internal {
        uint256 lpReleaseTime = userInfo[_user].lpReleaseTime;
        require(lpReleaseTime <= block.timestamp.add(_time), "timing invalid");
    }

    function setEmergencyWithdrawable(bool _withdrawable) public onlyOwner {
        poolInfo.emergencyWithdrawable = _withdrawable;
    }

    function setDevFee(uint16 _DEV_FEE) public onlyOwner {
        require(_DEV_FEE <= 1000, "Dev fee clamped at 10%");
        DEV_FEE = _DEV_FEE;
    }

    // View function to see pending TROPs on frontend.
    function pendingTROP(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accTROPPerRAP = poolInfo.accTROPPerRAP;
        uint256 rewardAllocPoint = user.rewardAllocPoint;

        uint256 totalRAP = poolInfo.totalRewardAllocPoint;

        if (totalRAP == 0) return 0;

        uint256 rewardWhole = pendingRewards;
        uint256 rewardFee = rewardWhole.mul(DEV_FEE).div(10000);
        uint256 rewardToDistribute = rewardWhole.sub(rewardFee);
        uint256 inc = rewardToDistribute.mul(1e18).div(totalRAP);
        accTROPPerRAP = accTROPPerRAP.add(inc);

        return
            rewardAllocPoint.mul(accTROPPerRAP).div(1e18).sub(user.rewardDebt);
    }

    function getLockedReward(address _user) public view returns (uint256) {
        return userInfo[_user].rewardLocked;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        updatePool();

        pendingRewards = 0;
    }

    // ----
    // Function that adds pending rewards, called by the TROP token.
    // ----
    function updatePendingRewards() public {
        uint256 newRewards = trop.balanceOf(address(this)).sub(tropBalance).sub(
            poolInfo.totalStake
        );

        if (newRewards > 0) {
            tropBalance = trop.balanceOf(address(this)).sub(
                poolInfo.totalStake
            ); // If there is no change the balance didn't change
            pendingRewards = pendingRewards.add(newRewards);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() internal returns (uint256 tropRewardWhole) {
        uint256 totalRAP = poolInfo.totalRewardAllocPoint;

        if (totalRAP == 0) {
            // avoids division by 0 errors
            return 0;
        }
        tropRewardWhole = pendingRewards;

        uint256 rewardFee = tropRewardWhole.mul(DEV_FEE).div(10000);
        uint256 rewardToDistribute = tropRewardWhole.sub(rewardFee);

        uint256 inc = rewardToDistribute.mul(1e18).div(totalRAP);
        pending_DEV_rewards = pending_DEV_rewards.add(rewardFee);

        poolInfo.accTROPPerRAP = poolInfo.accTROPPerRAP.add(inc);
        poolInfo.rewardsInThisEpoch = poolInfo.rewardsInThisEpoch.add(
            rewardToDistribute
        );
    }

    function withdrawReward() public {
        withdraw(0);
    }

    // Deposit  tokens to TROPVault for TROP allocation.
    function deposit(uint256 _amount, uint256 _lockTime)
        public
        validLockTime(_lockTime)
    {
        checkLockTiming(msg.sender, _lockTime);
        UserInfo storage user = userInfo[msg.sender];

        massUpdatePools();

        // Transfer pending tokens
        // to user
        updateAndPayOutPending(msg.sender);

        //Transfer in the amounts from user
        // save gas
        if (_amount > 0) {
            uint256 balBefore = trop.balanceOf(address(this));
            trop.safeTransferFrom(address(msg.sender), address(this), _amount);
            require(
                trop.balanceOf(address(this)).sub(balBefore) == _amount,
                "stake should not have fee"
            );
            updateRewardAllocPoint(msg.sender, _amount, _lockTime);
            user.amount = user.amount.add(_amount);
            poolInfo.totalStake += _amount;
        }

        user.rewardDebt = user.rewardAllocPoint.mul(poolInfo.accTROPPerRAP).div(
            1e18
        );
        emit Deposit(msg.sender, _amount);
    }

    function updateRewardAllocPoint(
        address _addr,
        uint256 _depositAmount,
        uint256 _lockTime
    ) internal {
        UserInfo storage user = userInfo[_addr];
        PoolInfo storage pool = poolInfo;
        if (user.amount == 0) {
            user.rewardAllocPoint = _depositAmount.mul(_lockTime);
            pool.totalRewardAllocPoint = pool.totalRewardAllocPoint.add(
                user.rewardAllocPoint
            );
            user.lockedPeriod = _lockTime;
            user.lpReleaseTime = block.timestamp.add(_lockTime);
        } else {
            user.lockedPeriod = _lockTime;
            user.lpReleaseTime = block.timestamp.add(_lockTime);

            uint256 pointMinus = user.rewardAllocPoint;
            uint256 amountAfterDeposit = user.amount.add(_depositAmount);
            user.rewardAllocPoint = amountAfterDeposit.mul(_lockTime);
            pool.totalRewardAllocPoint = pool
                .totalRewardAllocPoint
                .add(user.rewardAllocPoint)
                .sub(pointMinus);
        }
    }

    // Test coverage
    // [x] Does user get the deposited amounts?
    // [x] Does user that its deposited for update correcty?
    // [x] Does the depositor get their tokens decreased
    function depositFor(
        address _depositFor,
        uint256 _amount,
        uint256 _lockTime
    ) public validLockTime(_lockTime) {
        checkLockTiming(_depositFor, _lockTime);
        // requires no allowances
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_depositFor];

        massUpdatePools();

        // Transfer pending tokens
        // to user
        updateAndPayOutPending(_depositFor); // Update the balances of person that amount is being deposited for

        if (_amount > 0) {
            uint256 balBefore = trop.balanceOf(address(this));
            trop.safeTransferFrom(address(msg.sender), address(this), _amount);
            require(
                trop.balanceOf(address(this)).sub(balBefore) == _amount,
                "stake should not have fee"
            );
            updateRewardAllocPoint(_depositFor, _amount, _lockTime);
            user.amount = user.amount.add(_amount); // This is depositedFor address
            poolInfo.totalStake += _amount;
        }

        user.rewardDebt = user.rewardAllocPoint.mul(pool.accTROPPerRAP).div(
            1e18
        ); /// This is deposited for address
        emit Deposit(_depositFor, _amount);
    }

    // Test coverage
    // [x] Does allowance update correctly?
    function setAllowanceForPoolToken(address spender, uint256 value) public {
        PoolInfo storage pool = poolInfo;
        pool.allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }

    function quitPool() public {
        require(
            block.timestamp > userInfo[msg.sender].lpReleaseTime,
            "cannot withdraw all lp tokens before"
        );

        uint256 withdrawnableAmount = computeReleasableLP(msg.sender);
        withdraw(withdrawnableAmount);
    }

    // Test coverage
    // [x] Does allowance decrease?
    // [x] Do oyu need allowance
    // [x] Withdraws to correct address
    function withdrawFrom(address owner, uint256 _amount) public {
        PoolInfo storage pool = poolInfo;
        require(
            pool.allowance[owner][msg.sender] >= _amount,
            "withdraw: insufficient allowance"
        );
        pool.allowance[owner][msg.sender] = pool.allowance[owner][msg.sender]
            .sub(_amount);
        _withdraw(_amount, owner, msg.sender);
    }

    // Withdraw  tokens from TROPVault.
    function withdraw(uint256 _amount) public {
        _withdraw(_amount, msg.sender, msg.sender);
    }

    // Low level withdraw function
    function _withdraw(
        uint256 _amount,
        address from,
        address to
    ) internal {
        PoolInfo storage pool = poolInfo;
        //require(pool.withdrawable, "Withdrawing from this pool is disabled");
        UserInfo storage user = userInfo[from];

        uint256 withdrawnableAmount = computeReleasableLP(from);
        require(withdrawnableAmount >= _amount, "withdraw: not good");

        massUpdatePools();
        updateAndPayOutPending(from); // Update balances of from this is not withdrawal but claiming TROP farmed

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            user.rewardAllocPoint = user.amount.mul(user.lockedPeriod);
            pool.totalRewardAllocPoint = pool.totalRewardAllocPoint.sub(
                _amount.mul(user.lockedPeriod)
            );
            trop.safeTransfer(address(to), _amount);
            if (user.amount == 0) {
                user.lockedPeriod = 0;
                user.lpReleaseTime = 0;
            }
        }
        user.rewardDebt = user.rewardAllocPoint.mul(pool.accTROPPerRAP).div(
            1e18
        );
        emit Withdraw(to, _amount);
    }

    function updateAndPayOutPending(address from) internal {
        UserInfo storage user = userInfo[from];
        if (user.releaseTime == 0) {
            user.releaseTime = block.timestamp.add(REWARD_LOCKED_PERIOD);
        }
        if (block.timestamp > user.releaseTime) {
            //compute withdrawnable amount
            uint256 lockedAmount = user.rewardLocked;
            user.rewardLocked = 0;
            safeTROPTransfer(from, lockedAmount);
            user.releaseTime = block.timestamp.add(REWARD_LOCKED_PERIOD);
        }

        uint256 pending = pendingTROP(from);
        uint256 paid = pending.mul(REWARD_RELEASE_PERCENTAGE).div(100);
        uint256 _lockedReward = pending.sub(paid);
        if (_lockedReward > 0) {
            user.rewardLocked = user.rewardLocked.add(_lockedReward);
        }

        if (paid > 0) {
            safeTROPTransfer(from, paid);
        }
    }

    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo;
        require(
            pool.emergencyWithdrawable,
            "Withdrawing from this pool is disabled"
        );
        UserInfo storage user = userInfo[msg.sender];
        trop.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        if (
            user.amount.mul(user.rewardAllocPoint) <= pool.totalRewardAllocPoint
        ) {
            pool.totalRewardAllocPoint = pool.totalRewardAllocPoint.sub(
                user.amount.mul(user.rewardAllocPoint)
            );
        }
        user.rewardAllocPoint = 0;
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function safeTROPTransfer(address _to, uint256 _amount) internal {
        uint256 tropBal = trop.balanceOf(address(this));

        if (_amount > tropBal) {
            trop.transfer(_to, tropBal);
            tropBalance = trop.balanceOf(address(this)).sub(
                poolInfo.totalStake
            );
        } else {
            trop.transfer(_to, _amount);
            tropBalance = trop.balanceOf(address(this)).sub(
                poolInfo.totalStake
            );
        }
        transferDevFee();
    }

    function transferDevFee() public {
        if (pending_DEV_rewards == 0) return;

        uint256 tropBal = trop.balanceOf(address(this));
        if (pending_DEV_rewards > tropBal) {
            trop.transfer(devaddr, tropBal);
            tropBalance = trop.balanceOf(address(this)).sub(
                poolInfo.totalStake
            );
        } else {
            trop.transfer(devaddr, pending_DEV_rewards);
            tropBalance = trop.balanceOf(address(this)).sub(
                poolInfo.totalStake
            );
        }

        pending_DEV_rewards = 0;
    }

    function setDevFeeReciever(address _devaddr) public {
        require(devaddr == msg.sender, "only dev can change");
        devaddr = _devaddr;
    }

    event Restake(address indexed user, uint256 amount);

    function claimAndRestake() public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0);
        massUpdatePools();

        if (user.releaseTime == 0) {
            user.releaseTime = block.timestamp.add(REWARD_LOCKED_PERIOD);
        }
        uint256 _rewards = 0;
        if (block.timestamp > user.releaseTime) {
            //compute withdrawnable amount
            uint256 lockedAmount = user.rewardLocked;
            user.rewardLocked = 0;
            user.releaseTime = block.timestamp.add(REWARD_LOCKED_PERIOD);
            _rewards = _rewards.add(lockedAmount);
        }

        uint256 pending = pendingTROP(msg.sender);
        uint256 paid = pending.mul(REWARD_RELEASE_PERCENTAGE).div(100);
        uint256 _lockedReward = pending.sub(paid);
        if (_lockedReward > 0) {
            user.rewardLocked = user.rewardLocked.add(_lockedReward);
        }

        _rewards = _rewards.add(paid);

        user.lpReleaseTime = user.lpReleaseTime.add(1 days);

        uint256 pointMinus = user.rewardAllocPoint;
        uint256 amountAfterDeposit = user.amount.add(_rewards);
        user.rewardAllocPoint = amountAfterDeposit.mul(user.lockedPeriod);
        poolInfo.totalRewardAllocPoint = poolInfo
            .totalRewardAllocPoint
            .add(user.rewardAllocPoint)
            .sub(pointMinus);
        user.amount = amountAfterDeposit; // This is depositedFor address
        user.rewardDebt = user.rewardAllocPoint.mul(poolInfo.accTROPPerRAP).div(
            1e18
        );
        poolInfo.totalStake += _rewards;
        transferDevFee();
        emit Restake(msg.sender, _rewards);
    }
}