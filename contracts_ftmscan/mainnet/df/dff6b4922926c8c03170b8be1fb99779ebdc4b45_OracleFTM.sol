/**
 *Submitted for verification at FtmScan.com on 2022-01-03
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: IMooniFactory

interface IMooniFactory {
  function isPool(address token) external view returns(bool);
  function getAllPools() external view returns(address[] memory);
  function pools(address tokenA, address tokenB) external view returns(address);
}

// Part: IMooniswap

interface IMooniswap {
  function getBalanceForRemoval(address token) external view returns(uint256);
  function token0() external view returns(address);
  function token1() external view returns(address);
  function totalSupply() external view returns(uint256);
}

// Part: IPancakeFactory

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// Part: IPancakePair

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

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

// Part: OpenZeppelin/[email protected]/EnumerableSet

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

// Part: Storage

contract Storage {

  address public governance;
  address public controller;

  constructor() public {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

// Part: thegismar/[email protected]/Address

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
        assembly {
            codehash := extcodehash(account)
        }
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

// Part: thegismar/[email protected]/IBEP20

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// Part: thegismar/[email protected]/SafeMath

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
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// Part: Governable

contract Governable {

  Storage public store;

  constructor(address _store) public {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
  }
}

// Part: thegismar/[email protected]/SafeBEP20

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

// File: OracleFTM.sol

contract OracleFTM is Governable {

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private stableTokens;
    using SafeBEP20 for IBEP20;
    using Address for address;
    using SafeMath for uint256;

    //Addresses for factories and registries for different DEX platforms. Functions will be added to allow to alter these when needed.
    address public pancakeFactoryAddress = 0x152eE697f2E276fA89E96742e9bB9aB1F2E61bE3;

    uint256 public precisionDecimals = 18;

    IPancakeFactory pancakeFactory = IPancakeFactory(pancakeFactoryAddress);

    // registry for stable token -> sc address -> calldata to retrive price

    mapping(address => registry) tokenToPrice;

    struct registry {
        address _address;
        bytes _calldata;
    }

    mapping(address => address) replacementTokens;


    //Key tokens are used to find liquidity for any given token on Pancakeswap and 1INCH.
    address[] public keyTokens = [
    0x04068DA6C83AFCFA0e13ba15A6696662335D5B75, //USDC
    0x658b0c7613e890EE50B8C4BC6A3f41ef411208aD, //FETH
    0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E, //DAI
    0x940F41F0ec9ba1A34CF001cc03347ac092F5F6B5, //GUSDT
    0xe1146b9AC456fCbB60644c36Fd3F868A9072fc6E, //FBTC
    0x321162Cd933E2Be498Cd2267a90534A804051b11, //BTC
    0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83 //WFTM
    ];
    //Pricing tokens are Key tokens with good liquidity with the defined output token on Pancakeswap.
    address[] public pricingTokens = [
    0x04068DA6C83AFCFA0e13ba15A6696662335D5B75, //USDC
    0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E, //DAI
    0x940F41F0ec9ba1A34CF001cc03347ac092F5F6B5 //GUSDT
    ];
    //The defined output token is the unit in which prices of input tokens are given.
    address public definedOutputToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //BUSD

    modifier validKeyToken(address keyToken){
        require(checkKeyToken(keyToken), "Not a Key Token");
        _;
    }
    modifier validPricingToken(address pricingToken){
        require(checkPricingToken(pricingToken), "Not a Pricing Token");
        _;
    }

    event FactoryChanged(address newFactory, address oldFactory);
    event KeyTokenAdded(address newKeyToken);
    event PricingTokenAdded(address newPricingToken);
    event KeyTokenRemoved(address keyToken);
    event PricingTokenRemoved(address pricingToken);
    event DefinedOutuptChanged(address newOutputToken, address oldOutputToken);

    constructor(address _storage)
    Governable(_storage) public {}

    function changePancakeFactory(address newFactory) external onlyGovernance {
        address oldFactory = pancakeFactoryAddress;
        pancakeFactoryAddress = newFactory;
        pancakeFactory = IPancakeFactory(pancakeFactoryAddress);
        emit FactoryChanged(newFactory, oldFactory);
    }


    function addKeyToken(address newToken) external onlyGovernance {
        require((checkKeyToken(newToken) == false), "Already a key token");
        keyTokens.push(newToken);
        emit KeyTokenAdded(newToken);
    }

    function addPricingToken(address newToken) public onlyGovernance validKeyToken(newToken) {
        require((checkPricingToken(newToken) == false), "Already a pricing token");
        pricingTokens.push(newToken);
        emit PricingTokenAdded(newToken);
    }

    function removeKeyToken(address keyToken) external onlyGovernance validKeyToken(keyToken) {
        uint256 i;
        for (i = 0; i < keyTokens.length; i++) {
            if (keyToken == keyTokens[i]) {
                break;
            }
        }
        while (i < keyTokens.length - 1) {
            keyTokens[i] = keyTokens[i + 1];
            i++;
        }
        keyTokens.pop();
        emit KeyTokenRemoved(keyToken);

        if (checkPricingToken(keyToken)) {
            removePricingToken(keyToken);
        }
    }

    function removePricingToken(address pricingToken) public onlyGovernance validPricingToken(pricingToken) {
        uint256 i;
        for (i = 0; i < pricingTokens.length; i++) {
            if (pricingToken == pricingTokens[i]) {
                break;
            }
        }
        while (i < pricingTokens.length - 1) {
            pricingTokens[i] = pricingTokens[i + 1];
            i++;
        }
        pricingTokens.pop();
        emit PricingTokenRemoved(pricingToken);
    }

    function changeDefinedOutput(address newOutputToken) external onlyGovernance validKeyToken(newOutputToken) {
        address oldOutputToken = definedOutputToken;
        definedOutputToken = newOutputToken;
        emit DefinedOutuptChanged(newOutputToken, oldOutputToken);
    }

    function modifyReplacementTokens(address _inputToken, address _replacementToken)
    external onlyGovernance
    {
        replacementTokens[_inputToken] = _replacementToken;
    }


    //Main function of the contract. Gives the price of a given token in the defined output token.
    //The contract allows for input tokens to be LP tokens from Pancakeswap and 1Inch.
    //In case of LP token, the underlying tokens will be found and valued to get the price.
    function getPrice(address token) external view returns (uint256) {
        if (token == definedOutputToken) {
            return (10 ** precisionDecimals);
        }

        // if the token exists in the mapping, we'll swapp it for the replacement
        // example btcb/renbtc pool -> btcb
        if (replacementTokens[token] != address(0)) {
            token = replacementTokens[token];
        }

        // jump out if it's a stable
        if (isStableToken(token)) {
            return getStablesPrice(token);
        }

        bool pancakeLP;
        bool oneInchLP;
        (pancakeLP, oneInchLP) = isLPCheck(token);
        uint256 priceToken;
        uint256 tokenValue;
        uint256 price;
        uint256 i;
        if (pancakeLP || oneInchLP) {
            address[2] memory tokens;
            uint256[2] memory amounts;
            (tokens, amounts) = getPancakeUnderlying(token);
            for (i = 0; i < 2; i++) {
                priceToken = computePrice(tokens[i]);
                if (priceToken == 0) {
                    price = 0;
                    return price;
                }
                tokenValue = priceToken * amounts[i] / 10 ** precisionDecimals;
                price = price + tokenValue;
            }
            return price;
        } else {
            return computePrice(token);
        }
    }

    function isLPCheck(address token) public view returns (bool, bool) {
        bool isPancake = isPancakeCheck(token);
        return (isPancake, false);
    }

    //Checks if address is 1Inch LP
    function isOneInchCheck(address token) internal view returns (bool) {
        return (false);
    }

    //Checks if address is Pancake LP. This is done in two steps, because the second step seems to cause errors for some tokens.
    //Only the first step is not deemed accurate enough, as any token could be called Cake-LP.
    function isPancakeCheck(address token) internal view returns (bool) {
        IPancakePair pair = IPancakePair(token);
        IBEP20 pairToken = IBEP20(token);
        string memory pancakeSymbol = "Cake-LP";
        string memory symbol = pairToken.symbol();
        if (isEqualString(symbol, pancakeSymbol)) {
            return checkFactory(pair, pancakeFactoryAddress);
        } else {
            return false;
        }
    }

    function isEqualString(string memory arg1, string memory arg2) internal view returns (bool) {
        bool check = (keccak256(abi.encodePacked(arg1)) == keccak256(abi.encodePacked(arg2))) ? true : false;
        return check;
    }

    function checkFactory(IPancakePair pair, address compareFactory) internal view returns (bool) {
        try pair.factory{gas : 3000}() returns (address factory) {
            bool check = (factory == compareFactory) ? true : false;
            return check;
        } catch {
            return false;
        }
    }

    //Get underlying tokens and amounts for Pancake LPs
    function getPancakeUnderlying(address token) public view returns (address[2] memory, uint256[2] memory) {
        IPancakePair pair = IPancakePair(token);
        IBEP20 pairToken = IBEP20(token);
        address[2] memory tokens;
        uint256[2] memory amounts;
        tokens[0] = pair.token0();
        tokens[1] = pair.token1();
        uint256 token0Decimals = IBEP20(tokens[0]).decimals();
        uint256 token1Decimals = IBEP20(tokens[1]).decimals();
        uint256 supplyDecimals = IBEP20(token).decimals();
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        uint256 totalSupply = pairToken.totalSupply();
        if (reserve0 == 0 || reserve1 == 0 || totalSupply == 0) {
            amounts[0] = 0;
            amounts[1] = 0;
            return (tokens, amounts);
        }
        amounts[0] = reserve0 * 10 ** (supplyDecimals - token0Decimals + precisionDecimals) / totalSupply;
        amounts[1] = reserve1 * 10 ** (supplyDecimals - token1Decimals + precisionDecimals) / totalSupply;
        return (tokens, amounts);
    }


    //General function to compute the price of a token vs the defined output token.
    function computePrice(address token) public view returns (uint256) {
        uint256 price;
        if (token == definedOutputToken) {
            price = 10 ** precisionDecimals;
        } else if (token == address(0)) {
            price = 0;
        } else {
            (address keyToken, bool pancake) = getLargestPool(token, keyTokens);
            uint256 priceVsKeyToken;
            uint256 keyTokenPrice;
            if (keyToken == address(0)) {
                price = 0;
            } else  {
                priceVsKeyToken = getPriceVsTokenPancake(token, keyToken);
                keyTokenPrice = getKeyTokenPrice(keyToken);
                price = priceVsKeyToken * keyTokenPrice / 10 ** precisionDecimals;
            } 
        }
        return (price);
    }

    //Checks the results of the different largest pool functions and returns the largest.
    function getLargestPool(address token, address[] memory tokenList) public view returns (address, bool) {
        (address pancakeKeyToken, uint256 pancakeLiquidity) = getPancakeLargestPool(token, tokenList);
        return (pancakeKeyToken, true);
    }

    //Gives the Pancakeswap pool with largest liquidity for a given token and a given tokenset (either keyTokens or pricingTokens)
    function getPancakeLargestPool(address token, address[] memory tokenList) internal view returns (address, uint256) {
        uint256 largestPoolSize = 0;
        address largestKeyToken;
        uint256 poolSize;
        uint256 i;
        for (i = 0; i < tokenList.length; i++) {
            address pairAddress = pancakeFactory.getPair(token, tokenList[i]);
            if (pairAddress != address(0)) {
                poolSize = getPancakePoolSize(pairAddress, token);
            } else {
                poolSize = 0;
            }
            if (poolSize > largestPoolSize) {
                largestPoolSize = poolSize;
                largestKeyToken = tokenList[i];
            }
        }
        return (largestKeyToken, largestPoolSize);
    }

    function getPancakePoolSize(address pairAddress, address token) internal view returns (uint256) {
        IPancakePair pair = IPancakePair(pairAddress);
        address token0 = pair.token0();
        (uint112 poolSize0, uint112 poolSize1,) = pair.getReserves();
        uint256 poolSize = (token == token0) ? poolSize0 : poolSize1;
        return poolSize;
    }



    //Generic function giving the price of a given token vs another given token on Pancakeswap.
    function getPriceVsTokenPancake(address token0, address token1) internal view returns (uint256) {
        address pairAddress = pancakeFactory.getPair(token0, token1);
        IPancakePair pair = IPancakePair(pairAddress);
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        uint256 token0Decimals = IBEP20(token0).decimals();
        uint256 token1Decimals = IBEP20(token1).decimals();
        uint256 price;
        if (token0 == pair.token0()) {
            price = (reserve1 * 10 ** (token0Decimals - token1Decimals + precisionDecimals)) / reserve0;
        } else {
            price = (reserve0 * 10 ** (token0Decimals - token1Decimals + precisionDecimals)) / reserve1;
        }
        return price;
    }


    //Gives the price of a given keyToken.
    function getKeyTokenPrice(address token) internal view returns (uint256) {
        bool isPricingToken = checkPricingToken(token);
        uint256 price;
        uint256 priceVsPricingToken;
        if (token == definedOutputToken) {
            price = 10 ** precisionDecimals;
        } else if (isPricingToken) {
            price = getPriceVsTokenPancake(token, definedOutputToken);
        } else {
            uint256 pricingTokenPrice;
            (address pricingToken, bool pancake) = getLargestPool(token, pricingTokens);
            
            priceVsPricingToken = getPriceVsTokenPancake(token, pricingToken);
            pricingTokenPrice = (pricingToken == definedOutputToken) ? 10 ** precisionDecimals : getPriceVsTokenPancake(pricingToken, definedOutputToken);
            price = priceVsPricingToken * pricingTokenPrice / 10 ** precisionDecimals;
        }
        return price;
    }

    //Checks if a given token is in the pricingTokens list.
    function checkPricingToken(address token) public view returns (bool) {
        uint256 i;
        for (i = 0; i < pricingTokens.length; i++) {
            if (token == pricingTokens[i]) {
                return true;
            }
        }
        return false;
    }

    //Checks if a given token is in the keyTokens list.
    function checkKeyToken(address token) public view returns (bool) {
        uint256 i;
        for (i = 0; i < keyTokens.length; i++) {
            if (token == keyTokens[i]) {
                return true;
            }
        }
        return false;
    }

    // @param _token token to be queried
    // @param _address sc address in registry
    // @param _calldata abi encoded function signature with parameters to be called
    function modifyRegistry(address _token, address _address, bytes calldata _calldata)
    external onlyGovernance
    returns (bool)
    {
        registry memory r;
        r._address = _address;
        r._calldata = _calldata;
        tokenToPrice[_token] = r;
        return true;
    }

    //@param _token token to be added to stable token set
    function addStableToken(address _token)
    external onlyGovernance
    returns (bool)
    {
        stableTokens.add(_token);
        return true;
    }

    //@param _token token to be removed from stable token set
    function removeStableToken(address _token)
    external onlyGovernance
    returns (bool)
    {
        stableTokens.remove(_token);
        return true;
    }

    //@param _token to check if is stable token
    function isStableToken(address _token)
    internal view
    returns (bool)
    {
        return stableTokens.contains(_token);
    }

    //@dev queries the struct registry that has previously been loaded with smart contract address,
    // calldata that retrieves the price for that particular token, this can be changed via modifyRegistry
    //@param _token token to return price for
    function getStablesPrice(address _token)
    internal view
    returns (uint256)
    {
        registry memory r = tokenToPrice[_token];
        (bool success, bytes memory returnData) = r._address.staticcall(r._calldata);
        require(success, "couldn't call for price data"); // this is very unlikely to not succeed
        return abi.decode(returnData, (uint256));

    }


}