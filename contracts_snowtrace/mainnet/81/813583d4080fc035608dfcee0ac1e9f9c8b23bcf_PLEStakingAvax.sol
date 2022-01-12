/**
 *Submitted for verification at snowtrace.io on 2022-01-11
*/

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: Initializable.sol



pragma solidity ^0.8.6;


abstract contract Initializable is Context {

    event Initialized(address account);

    bool private _initialized;

    constructor() {
        _initialized = false;
    }

    function initialized() public view virtual returns (bool) {
        return _initialized;
    }

    modifier notInitialized() {
        require(!initialized(), "Initializable: Already initialized");
        _;
    }

    modifier onlyInitialized() {
        require(initialized(), "Initializable: Not initialized");
        _;
    }

    function _init() internal virtual notInitialized {
        _initialized = true;
        emit Initialized(_msgSender());
    }
}


// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// File: PLE Avalanche Staking/PLE AVAX staking.sol



pragma solidity ^0.8.6;







interface IStakingAvax {
    // Views
    function balanceOf(address account) external view returns (uint256);

    function totalClaimedRewardsOf(address account)
        external
        view
        returns (uint256);

    function numberOfStakeHolders() external view returns (uint256);

    function unclaimedRewardsOf(address account)
        external
        view
        returns (uint256);

    function unclaimedRewardsOfUsers(uint256 begin, uint256 end)
        external
        view
        returns (uint256);

    // Mutative
    function stake(uint256 amount) external;

    function unstake(uint256 amount) external;

    function restakeRewards() external;

    function claimRewards() external;

    // Only Owner
    function switchFees(
        bool _takeStakeFee,
        bool _takeUnstakeFee,
        bool _takeRestakeFee
    ) external;

    function switchRewards(bool enableRewards) external;

    function emergencyWithdrawRewards(address emergencyAddress, uint256 amount)
        external;

    // Events
    event Staked(address account, uint256 amount);
    event Unstaked(address account, uint256 amount);
    event RestakedRewards(address account, uint256 amount);
    event ClaimedRewards(address account, uint256 amount);
    event PayedFee(address account, uint256 amount);
    event SwitchedFees(
        bool _takeStakeFee,
        bool _takeUnstakeFee,
        bool _takeRestakeFee
    );
    event SwitchedRewards(bool enableRewards);
    event RewardsWithdrawnEmergently(address emergencyAddress, uint256 amount);
}

contract PLEStakingAvax is Ownable, Pausable, Initializable, IStakingAvax {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 public token = IERC20(0x47aA3650CFF9930f277D4670dB138DA818E1a3CA);
    address public feeAddress = 0x8B176d1D547aFd831E5c74787e4ec6d184a5078E;

    // rewards & fees
    uint256 public constant REWARD_RATE = 4000; // 40.00% APY
    uint256 public constant BLOCKS_IN_YEAR_MULTIPLIED = 173448e6;
    uint256 public constant STAKE_FEE_RATE = 150; // 1.50% staking fee
    uint256 public constant UNSTAKE_FEE_RATE = 50; // 0.50% unstaking fee
    uint256 public constant RESTAKE_FEE_RATE = 50; // 0.50% restaking fee
    bool public takeStakeFee;
    bool public takeUnstakeFee;
    bool public takeRestakeFee;
    uint256 public stopRewardsBlock;
    uint256 public availableRewards;

    // stake holders
    struct StakeHolder {
        uint256 stakedTokens;
        uint256 lastClaimedBlock;
        uint256 totalEarnedTokens;
        uint256 totalFeesPayed;
    }
    uint256 public totalStaked;
    mapping(address => StakeHolder) public stakeHolders;
    EnumerableSet.AddressSet private holders;

    // Views
    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return stakeHolders[account].stakedTokens;
    }

    function totalClaimedRewardsOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return stakeHolders[account].totalEarnedTokens;
    }

    function numberOfStakeHolders() external view override returns (uint256) {
        return holders.length();
    }

    function unclaimedRewardsOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _calculateUnclaimedRewards(account);
    }

    function unclaimedRewardsOfUsers(uint256 begin, uint256 end)
        external
        view
        override
        returns (uint256)
    {
        uint256 totalUnclaimedRewards = 0;
        for (uint256 i = begin; i < end && i < holders.length(); i++) {
            totalUnclaimedRewards = totalUnclaimedRewards.add(
                _calculateUnclaimedRewards(holders.at(i))
            );
        }
        return totalUnclaimedRewards;
    }

    /**
     * Rewards Calculation:
     * rewards = (stakedTokens * blockDiff * rewardRatePerBlock)
     * rewardRatePerBlock =
     * 4000 (REWARD_RATE)
     * ------------------
     * 10000 * 365 (days/Y) * 24 (H/day) * 60 (M/H) * 33 (Blocks/M) = 173448e6 (BLOCKS_IN_YEAR_MULTIPLIED)
     */
    function _calculateUnclaimedRewards(address account)
        private
        view
        returns (uint256)
    {
        uint256 stakedTokens = stakeHolders[account].stakedTokens;
        if (stakedTokens == 0) return 0;
        // block diff calculation
        uint256 blockDiff = stakeHolders[account].lastClaimedBlock;
        if (stopRewardsBlock == 0) {
            blockDiff = block.number.sub(blockDiff);
        } else {
            if (stopRewardsBlock <= blockDiff) return 0;
            blockDiff = stopRewardsBlock.sub(blockDiff);
        }
        // rewards calculation
        uint256 unclaimedRewards = stakedTokens.mul(blockDiff).mul(REWARD_RATE);
        unclaimedRewards = unclaimedRewards.div(BLOCKS_IN_YEAR_MULTIPLIED); // Audit: for gas efficieny
        if (unclaimedRewards > availableRewards) return 0;
        return unclaimedRewards;
    }

    // Mutative
    function stake(uint256 amount)
        external
        override
        whenNotPaused
        onlyInitialized
    {
        require(amount > 0, "Cannot stake 0 tokens");
        if (stakeHolders[msg.sender].stakedTokens > 0) {
            _restakeRewards(); // Audit: return value not check purposely
        } else {
            stakeHolders[msg.sender].lastClaimedBlock = block.number;
        }
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Could not transfer tokens from msg.sender to staking contract"
        );
        uint256 amountAfterFees = _takeFees(
            amount,
            takeStakeFee,
            STAKE_FEE_RATE
        );
        stakeHolders[msg.sender].stakedTokens = stakeHolders[msg.sender]
            .stakedTokens
            .add(amountAfterFees);
        totalStaked = totalStaked.add(amountAfterFees);
        holders.add(msg.sender);
        emit Staked(msg.sender, amountAfterFees);
    }

    function unstake(uint256 amount)
        external
        override
        whenNotPaused
        onlyInitialized
    {
        require(amount > 0, "Cannot unstake 0 tokens");
        require(
            stakeHolders[msg.sender].stakedTokens >= amount,
            "Not enough tokens to unstake"
        );
        uint256 unclaimedRewards = _getRewards();
        stakeHolders[msg.sender].stakedTokens = stakeHolders[msg.sender]
            .stakedTokens
            .sub(amount);
        totalStaked = totalStaked.sub(amount);
        if (stakeHolders[msg.sender].stakedTokens == 0)
            holders.remove(msg.sender);
        uint256 amountAfterFees = _takeFees(
            amount,
            takeUnstakeFee,
            UNSTAKE_FEE_RATE
        );
        if (unclaimedRewards > 0) {
            amountAfterFees = amountAfterFees.add(unclaimedRewards);
            emit ClaimedRewards(msg.sender, unclaimedRewards);
        }
        require(
            token.transfer(msg.sender, amountAfterFees),
            "Could not transfer tokens from staking contract to msg.sender"
        );
        emit Unstaked(msg.sender, amountAfterFees.sub(unclaimedRewards));
    }

    function restakeRewards() external override whenNotPaused onlyInitialized {
        require(_restakeRewards(), "No rewards to restake");
    }

    function claimRewards() external override whenNotPaused onlyInitialized {
        uint256 unclaimedRewards = _getRewards();
        require(unclaimedRewards > 0, "No rewards to claim");
        require(
            token.transfer(msg.sender, unclaimedRewards),
            "Could not transfer rewards from staking contract to msg.sender"
        );
        emit ClaimedRewards(msg.sender, unclaimedRewards);
    }

    // Mutative & Private
    function _restakeRewards() private returns (bool) {
        uint256 unclaimedRewards = _getRewards();
        if (unclaimedRewards == 0) return false;
        unclaimedRewards = _takeFees(
            unclaimedRewards,
            takeRestakeFee,
            RESTAKE_FEE_RATE
        );
        stakeHolders[msg.sender].stakedTokens = stakeHolders[msg.sender]
            .stakedTokens
            .add(unclaimedRewards);
        totalStaked = totalStaked.add(unclaimedRewards);
        emit RestakedRewards(msg.sender, unclaimedRewards);
        return true;
    }

    function _getRewards() private returns (uint256) {
        uint256 unclaimedRewards = _calculateUnclaimedRewards(msg.sender);
        if (unclaimedRewards == 0) return 0;
        availableRewards = availableRewards.sub(unclaimedRewards);
        stakeHolders[msg.sender].lastClaimedBlock = block.number;
        stakeHolders[msg.sender].totalEarnedTokens = stakeHolders[msg.sender]
            .totalEarnedTokens
            .add(unclaimedRewards);
        return unclaimedRewards;
    }

    function _takeFees(
        uint256 amount,
        bool takeFee,
        uint256 feeRate
    ) private returns (uint256) {
        if (takeFee) {
            uint256 fee = (amount.mul(feeRate)).div(1e4);
            require(token.transfer(feeAddress, fee), "Could not transfer fees");
            stakeHolders[msg.sender].totalFeesPayed = stakeHolders[msg.sender]
                .totalFeesPayed
                .add(fee);
            emit PayedFee(msg.sender, fee);
            return amount.sub(fee);
        }
        return amount;
    }

    // Only Owner
    function init() external onlyOwner whenNotPaused notInitialized {
        require(
            token.transferFrom(msg.sender, address(this), 4e6 * 1e18),
            "Could not transfer 4,000,000 as rewards"
        );
        availableRewards = 4e6 * 1e18;
        stopRewardsBlock = 0;
        takeStakeFee = true;
        takeUnstakeFee = true;
        takeRestakeFee = true;
        _init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function switchFees(
        bool _takeStakeFee,
        bool _takeUnstakeFee,
        bool _takeRestakeFee
    ) external override onlyOwner onlyInitialized {
        takeStakeFee = _takeStakeFee;
        takeUnstakeFee = _takeUnstakeFee;
        takeRestakeFee = _takeRestakeFee;
        emit SwitchedFees(_takeStakeFee, _takeUnstakeFee, _takeRestakeFee);
    }

    function switchRewards(bool enableRewards)
        external
        override
        onlyOwner
        onlyInitialized
    {
        if (enableRewards) {
            stopRewardsBlock = 0;
        } else {
            stopRewardsBlock = block.number;
        }
        emit SwitchedRewards(enableRewards);
    }

    function emergencyWithdrawRewards(address emergencyAddress, uint256 amount)
        external
        override
        onlyOwner
        onlyInitialized
    {
        require(
            availableRewards >= amount,
            "No available rewards for emergent withdrawal"
        );
        require(
            token.transfer(emergencyAddress, amount),
            "Could not transfer tokens"
        );
        availableRewards = availableRewards.sub(amount);
        emit RewardsWithdrawnEmergently(emergencyAddress, amount);
    }
}