/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

// SPDX-License-Identifier: MIT
/*
 * Care Pay Network  [CPN]
 * Web:             https://carepay.network
 * Medium:          https://carepaynetwork.medium.com    
 * Twitter:         https://twitter.com/carepaynetwork
 * Telegram:        https://t.me/carepaynetwork
 * Announcements:   https://t.me/carepaynetwork_news
 * GitHub:          https://github.com/carepaynetwork/cpn
 */


pragma solidity 0.8.4;

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


//pragma solidity ^0.8.0;

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
// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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


// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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

contract Ownable {
    
    address public owner;
    address public previousOwner;
    uint256 public unLockTime;
    
    address public careFundAddress;
    
    address public devFundAddress;
    address public marketingAddress;
    address public airDropAddress;
    
    //All CPN will be burned at this address.
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    
    uint256 public maxSupply;
    

    
    uint256 public careFundFeePercentage;
    uint256 public burnFeePercentage;
    uint256 public liquidityFeePercentage;
    
    uint256 public maxTxPercent;  // 100 means 1%   and 1 means 0.01% 
    

    //Interest to Holders
    uint256 public interestRatePerYear;
    
    //CPN Coin Price set for ICO.
    uint256 public cpnPrice;
    //ICO End Date in Unix Time Stamp.
    uint256 public icoEndDate;
    
    //Used to see , to which Stakeholder, Interest will be paid automatically in next transaction.
    uint256 public interestCounter;
    
    //To store the Unix Time Stamp , when Owner has Renounced the Ownership.
    uint256 public renouncedOwnershipAt;
    

  //  address[] public stakeholders;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event CareFundTransferred(
        address indexed previousCareFund,
        address indexed newCareFund
    );
    event DevFundTransferred(
        address indexed previousDevFund,
        address indexed newDevFund
    );

    event CareFeeChanged(uint256 previousCareFee, uint256 newCareFee);
    event BurnFeeChanged(uint256 previousBurnFee, uint256 newBurnFee);

    event InterestRateChanged(
        uint256 previousInterestRatePerYear,
        uint256 newInterestRatePerYear
    );
    
   event ChangeCPNPrice(uint256 previousCPNPrice, uint256 newCPNPrice);
    
    event ChangeICOEndDate(uint256 previousICOEndDate, uint256 newICOEndDate);
    
    event WorldPopulationChanged(uint256 previousWorldPopulation, uint256 newWorldPopulation);
    event MaxSupplyChanged(uint256 previousMaxSupply, uint256 newMaxSupply);

    event Bought(address buyer, uint256 tokens);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        renouncedOwnershipAt = block.timestamp;
    }

   function geUnlockTime() public view returns (uint256) {
        return unLockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        previousOwner = owner;
        owner = address(0);
        unLockTime =  time;
        emit OwnershipTransferred(owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(previousOwner == msg.sender, "You don't have permission to unlock");
        require(renouncedOwnershipAt == 0, "Owner Has Already Renounced ownership.");
        
        require(block.timestamp > unLockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(owner, previousOwner);
        owner = previousOwner;
    }
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

/**
     * @dev Allows the owner to Change CareFund Address to a New Address.
     * @param newCareFund The address that will be new CareFund.
     */
    function transferCareFund(address newCareFund) public onlyOwner {
        require(newCareFund != address(0));
        emit CareFundTransferred(careFundAddress, newCareFund);
        careFundAddress = newCareFund;
    }
    
    /**
     * @dev Allows the owner to Change Dev Fund Address to a New Address.
     * @param newDevFund The address that will be new DevFund.
     */
    function transferDevFund(address newDevFund) public onlyOwner {
        require(newDevFund != address(0));
        emit DevFundTransferred(devFundAddress, newDevFund);
        devFundAddress = newDevFund;
    }

/**
     * @dev Allows the owner to Change CareFund Fee Percentage.
     * @param newCareFundFeePercentage The Percentage that will be new CareFund Fee Percentage.
     */
    function changeCareFundFeePercentage(uint256 newCareFundFeePercentage) public onlyOwner {
        require(newCareFundFeePercentage >= 0);
        emit CareFeeChanged(careFundFeePercentage,newCareFundFeePercentage);
        careFundFeePercentage = newCareFundFeePercentage;
    }
    
    
/**
     * @dev Allows the owner to Change Burn Fee Percentage.
     * @param newBurnFee The Percentage that will be new Burn Fee Percentage.
     */
    function changeBurnFeePercentage(uint256 newBurnFee) public onlyOwner {
        require(newBurnFee >= 0);

        burnFeePercentage = newBurnFee;
    }
    
    /**
     * @dev Allows the owner to Change Liquidity Fee Percentage.
     * @param newLiquidityFeePercentage The Percentage that will be new Liquidity Fee Percentage.
     */
    function changeLiquidityFeePercentage(uint256 newLiquidityFeePercentage) public onlyOwner {
        require(newLiquidityFeePercentage >= 0);

        liquidityFeePercentage = newLiquidityFeePercentage;
    }
    
        /**
     * @dev Allows the owner to Change Max Transaction Percentage.
     * @param newMaxTxPercent The Percentage that will be new Liquidity Fee Percentage.
     */
    function changeMaxTxPercent(uint256 newMaxTxPercent) public onlyOwner {
        require(newMaxTxPercent >= 0);

        maxTxPercent = newMaxTxPercent;
    }

    
    
/**
     * @dev Allows the owner to Change Reward/ Interest Percentage.
     * @param newInterestRatePerYear The Percentage that will be new Reward/Interest Percentage used to reward stakeholders.
     */
    function changeInterestRatePerYear(uint256 newInterestRatePerYear)
        public
        onlyOwner
    {
        require(newInterestRatePerYear >= 0);
        emit InterestRateChanged(interestRatePerYear,newInterestRatePerYear);
        interestRatePerYear = newInterestRatePerYear;
    }


/**
     * @dev Allows the owner to Change Token ICO Price.
     * @param newCPNPrice The Price of Token, that will be used in ICO.
     */
    function changeCPNPrice(uint256 newCPNPrice) public onlyOwner {
        require(newCPNPrice >= 1);
        emit ChangeCPNPrice(cpnPrice,newCPNPrice);
        cpnPrice = newCPNPrice;
    }
    
    
/**
     * @dev Allows the owner to Change ICO End Date.
     * @param newICOEndDate The UnixTimeStamp that will be new ICO End Date.
     */
    function changeICOEndDate(uint256 newICOEndDate) public onlyOwner {
        require(newICOEndDate >= 1);
       emit ChangeICOEndDate(icoEndDate,newICOEndDate);
        icoEndDate = newICOEndDate;
    }
    

  
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused,"CPN is Paused.");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}


 contract ERC20 is Pausable {
    using SafeMath for uint256;
    using Address for address;

    uint256 public totalSupply;
    

    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => bool) tokenBlacklist;
    mapping(address => uint256) balances;
    mapping(address => uint256) public interestCollectedAt;
    
    
    

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    
    
    event Blacklist(address indexed blackListed, bool value);
    event Mint(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);

    event MintInterest(address indexed from, address indexed to, uint256 value);
    
    event MaxSupplyLeft(uint256 value);

//Gets the Balance of an Address.
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

//Approve spending of CPN by some other Address, on Your behalf.
    function approve(address _spender, uint256 _value) public returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }
    
    //Implement Approve Function with custom transaction initiator.
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

//Check how much CPN can other Address is allowed to spend on someone else behalf..
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

//Black List an address to perform transactions.
    function _blackList(address _address, bool _isBlackListed)
        internal
        returns (bool)
    {
        require(tokenBlacklist[_address] != _isBlackListed);
        tokenBlacklist[_address] = _isBlackListed;
        emit Blacklist(_address, _isBlackListed);
        return true;
    }

//Burn CPN.
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

//Implement Burn.
    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who].sub(_value);
        balances[burnAddress] = balances[burnAddress].add(_value);
        
        totalSupply = totalSupply.sub(_value);
        
        emit Burn(_who, _value);
        emit Transfer(_who, burnAddress, _value);
    }

//Mint new CPN Tokens. Tokens will always be less than or equal to Max Supply.
    function mint(address account, uint256 amount) public onlyOwner {
        if(maxSupply >= totalSupply.add(amount))
        {
        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Mint(address(0), account, amount);
        emit Transfer(address(0), account, amount);
        }
        else{
            
           emit MaxSupplyLeft(maxSupply.sub(totalSupply));
        }
    }
}

//Here begins the Care..
contract CARECOIN is ERC20  {
    using SafeMath for uint256;
    using Address for address;
    // Add the library methods
    using EnumerableSet for EnumerableSet.AddressSet;

    
    //Setting swap variables.
  IUniswapV2Router02 public immutable uniswapV2Router;
   address public immutable uniswapV2Pair;
   address public immutable uniswapV2Factory;
    
   bool inSwapAndLiquify;
   bool public swapAndLiquifyEnabled = false;
   bool public rewardAndFeeEnabled = false;
   bool public antiWhaleEnabled = false;
   
  mapping (address => bool) private _isExcludedFromFee;
  mapping(address => bool) private _isExcludedFromMaxTx;
  
   modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
 
    string public constant name = "Care Pay Network";
    string public constant symbol  = "CPN";
    uint256 public constant decimals = 18; 
    
    uint256 private constant billion = 10**9;
    
    // Declare a set state variable
    EnumerableSet.AddressSet private stakeholderSet;
        
uint256 public disruptiveCoverageFee = 1 ether; // antiwhale 
    
  
  //Current World Population, CPN will always be equal to worldPopulation X 1 Billion.
    uint256 public worldPopulation = 7874943450;
    
    //At the Time of launch , Total CPN created were eqaul to Active Corona Virus Cases X 1 Billion.
    uint256 private  activeCoronaCases = 11435946;
  
  
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event RewardAndFeeEnabledUpdated(bool enabled);
    event AntiWhaleEnabledUpdated(bool enabled);
    
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
   
    
    event Bought(uint256 amount);
    event Sold(uint256 amount);
    event DonatedToCareFund(address from, uint256 amount);
    event HelpedToCareFund(address from, uint256 amount);
    event BurnedForBetter(address from, uint256 amount);
    event LetsAddLiquidity(address from, address to,uint256 amount);
    
    event InterestPaid(address to, uint256 value);
    event NoInterestToPay(address to);
    event ItIsAnExcludedAddress(address to);
    event ExcludedAddressForFeeAndRewards(address _address);
    event IncludedAddressForFeeAndRewards(address _address);
    
    event StakeHolderAdded(address _address);
    event StakeHolderRemoved(address _address);
    
    event AntiWhaleCharges(uint256 totalAntiWhaleCharges);
    
    event ChangedInterestCounter(uint256 previousInterestCounter, uint256 newInterestCounter);

    constructor(address tokenOwner , address routerAddress) {
       
        //Total Supply is set to Active Corona Cases X 1 Billion.
        totalSupply = (activeCoronaCases*billion) * 10**decimals;
        
        //Max Supply is Total World Population X 1 Billion.
        maxSupply = (worldPopulation*billion) * 10**decimals;
        
         
        //Total Supply transferred  to Owner.
          balances[tokenOwner] = totalSupply;
          owner = tokenOwner;

//Fee Settings
        careFundFeePercentage = 1;
        burnFeePercentage = 2;
        liquidityFeePercentage = 2;
        maxTxPercent = 10000;  // 10000 means 100%  and  100 means 1%   and 1 means 0.01% 

//Interest / Reward Settings
        interestRatePerYear = 12;

//To distribute automatic interest. Counter starts at.
        interestCounter = 0;

//CPN Price for ICO Sale
        cpnPrice = 10000;

//ICO Sale will end on (Unix Time Stamp)
        icoEndDate = 1627669799;
        
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Factory = _uniswapV2Router.factory();
        
        
       //exclude Liquidity Router and Factory from Reward and fee
        _isExcludedFromFee[routerAddress] = true;
        _isExcludedFromFee[_uniswapV2Router.factory()] = true;
       
       //exclude this contract from Reward and Fee.
       _isExcludedFromFee[address(this)] = true;
       
       // exclude from max tx
        _isExcludedFromMaxTx[owner] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[burnAddress] = true;
        _isExcludedFromMaxTx[address(0)] = true;
       
       
        emit Transfer(address(0),tokenOwner,totalSupply);
      
    }
    
/**
     * @dev Allows the owner to Set all Address and transfer CPN to those address, This method can be called only once.
     * @param _devFundAddress Address of Dev Fund.
     * * @param _airDropAddress Address of Air Drop Fund.
     * * @param _marketingAddress Address of Marketing Fund.
     * * @param _careFundAddress Address of Care Fund.
     */
  function setAddresses(
        address _devFundAddress,
        address _airDropAddress,
        address _marketingAddress,
        address _careFundAddress
    ) public onlyOwner() {
        require(
            devFundAddress == address(0),
            "Dev Fund Address is already set!"
        );
        require(
            airDropAddress == address(0),
            "Airdrop Address is already set!"
        );
        require(
            marketingAddress == address(0),
            "Marketing Address is already set!"
        );
        require(
            careFundAddress == address(0),
            "Care Fund Address is already set!"
        );
        
        devFundAddress = _devFundAddress;
        airDropAddress = _airDropAddress;
        marketingAddress = _marketingAddress;
        careFundAddress = _careFundAddress;

        excludeFromFee(owner);
        
        excludeFromFee(devFundAddress);
        excludeFromFee(airDropAddress);
        excludeFromFee(marketingAddress);
        excludeFromFee(careFundAddress);
        
        
        
       // excludeFromFee(address(this));
    
    //Dev/Team Fund for Development is set to 2% only.
        transfer(devFundAddress, (totalSupply.mul(2)).div(10**2));
        
    //Air Drop for Initial Holder Gathering and as Gifts to Community.
        transfer(airDropAddress, (totalSupply.mul(1)).div(10**2));

    //Marking Fund for Promotion and Marketing is set to 2% only.
        transfer(marketingAddress, (totalSupply.mul(1)).div(10**2));
        
    }
    
/**
     * @dev Allows the owner to Change World Population. and which result in change of Max Supply of the Token.Our Target is to Keep Max Supply always equal to World Population X 1 Billion.
     * @param newWorldPopulation World Population based on which new Max Supply of the Token will be decided.
     */
function changeWorldPopulation(uint256 newWorldPopulation) public onlyOwner {
        require(newWorldPopulation >= 0);
        
        emit WorldPopulationChanged(worldPopulation, newWorldPopulation);
        
        worldPopulation = newWorldPopulation;
        
       uint256 newMaxSupply = (worldPopulation*billion) * 10**decimals;
        
        emit MaxSupplyChanged(maxSupply, newMaxSupply);
        maxSupply = newMaxSupply;
            
    }
    
        function setExcludeFromMaxTx(address _address, bool value) public onlyOwner { 
        _isExcludedFromMaxTx[_address] = value;
    } 
    
    
    function blackListAddress(address listAddress, bool isBlackListed)
        public
        whenNotPaused
        onlyOwner
        returns (bool success)
    {
        return super._blackList(listAddress, isBlackListed);
    }
    
    //Enable/Disable Automatic Swap and liquidity creation.
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
  
    //Enable/Disable Fee and Rewards.
    function setRewardsAndFeeEnabled(bool _enabled) public onlyOwner {
        rewardAndFeeEnabled = _enabled;
        emit RewardAndFeeEnabledUpdated(_enabled);
    }
        //Enable/Disable Anti Whale Mechanism.
    function setAntiWhaleEnabled(bool _enabled) public onlyOwner {
        antiWhaleEnabled = _enabled;
        emit AntiWhaleEnabledUpdated(_enabled);
    }
  

//To check if an Address can receive benefits and elegible for fees deductions.
function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

//Remove an Address to incure fees, and receive benefits.
  function excludeFromFee(address _address) public onlyOwner {
        _isExcludedFromFee[_address] = true;
        emit ExcludedAddressForFeeAndRewards(_address);
        
    }
    
    //Include an Address in fees, and benefits.
    function includeInFee(address _address) public onlyOwner {
        _isExcludedFromFee[_address] = false;
        emit IncludedAddressForFeeAndRewards(_address);
    }
    
    /**
     * @dev Allows the owner to Change Ineterest Counter.
     * @param newInterestCounter The Interest Counter to whom next Interest will be paid.
     */
    function changeInterestCounter(uint256 newInterestCounter) public onlyOwner {
        require(newInterestCounter >= 0);
       emit ChangedInterestCounter(interestCounter,newInterestCounter);
        interestCounter = newInterestCounter;
    }
    
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public whenNotPaused returns (bool) {
        //Mandatory Checks.
        require(tokenBlacklist[msg.sender] == false);
        require(_to != address(0));
        require(_to != address(this));
        require(_from != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        //Ensure Max Transfer will be only as per allowed maxTxpercent.
        _value = ensureMaxTxAmount(_from,_to,_value);
        
        //First Pay Reward/Interest to the Token Sender.
        ExecuteRewardFunctions(_from);
        
         //Special anti-whale tax fees on every transaction - helping holders, punishing whales.
       uint256 amtForAntiWhale =  ExecuteAntiWhaleFunctions(_from,_to,_value);
       
       //Updating initial Amount value after AntiWhale Functions.
       _value = _value.sub(amtForAntiWhale);

        //Transfer the Amount
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);


        //ExecuteCoreFunctions that will implement Burn, Care Fund Donation , Liquidity making.
        ExecuteCoreFunctions(_from, _to, _value);
 
        //Lets add transaction initiator as Stakeholder.
        addStakeholder(_to);

        //See if Balance is Zero , and needs to removed from Stakeholder list.
        removeStakeholder(_from);

        return true;
    }


    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
       address _from = msg.sender;
       
       //Mandatory Checks.
        require(tokenBlacklist[_from] == false);
        require(_to != address(0));
        require(_to != address(this));
        require(_from != address(0));
        require(_value <= balances[_from]);

        
          //Ensure Max Transfer will be only as per allowed maxTxpercent.
        _value = ensureMaxTxAmount(_from,_to,_value);
        
        //First Pay Reward/Interest to the Transaction Initiator.
        ExecuteRewardFunctions(_from);

        //Special anti-whale tax fees on every transaction - helping holders, punishing whales.
       uint256 amtForAntiWhale =  ExecuteAntiWhaleFunctions(_from,_to,_value);
       
       //Updating initial Amount value after AntiWhale Functions.
       _value = _value.sub(amtForAntiWhale);

        //Transfer the Amount
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);

        //ExecuteCoreFunctions that implement Burn, Care Fund Transfer , Liquidity making.
        ExecuteCoreFunctions(_from,_to,_value);
 
        //Lets add transaction initiator as Stakeholder.
        addStakeholder(_to);

        //See if Balance is Zero , and needs to removed from Stakeholder list.
        removeStakeholder(_from);

  

        return true;
    }

/**
     * @notice A simple method that Execute Anti Whale Mechanism.
     * Collects the amount to Deduct the Anti Whale functions.
     
     * * @param amount Tokens to be used to calculate the Anti Whale.
     */
function calculateAntiWhaleFee(uint256 amount) public view returns (uint256)
{
        //uint256 currentSupply = currentSupply();
        uint256 fee = 0;
        uint256 txSize = amount.mul(10 ** 4).div(currentSupply());
        if (txSize <= 1) {
            fee = 0;
        } else if (txSize <= 25) {
            fee = 2;
        } else if (txSize <= 50) {
            fee = 5;
        } else if (txSize <= 100) {
            fee = 10;
        } else if (txSize <= 250) {
            fee = 15;
        } else if (txSize <= 500) {
            fee = 20;
        } else if (txSize <= 1000) {
            fee = 25;
        } else{
            fee = 30;
        }
        
    
    return (fee);
}    
    /**
     * @notice A simple method that Execute Anti Whale Function.
     * Collects the amount to implement Anti Whale.
     * @param _from The stakeholder to calculate Functions Amount from.
     * * @param _to The stakeholder to which Transaction is going.
     * * @param _value Tokens to be used to calculate all functions.
     */

function ExecuteAntiWhaleFunctions(address _from,address _to, uint256 _value)
        internal
        returns (uint256)
{
    if(!antiWhaleEnabled)
          {
              return (0);
          }
          
      uint256 amtLiquified  = 0 ;
      uint256 amtBurned = 0;
      uint256 amtToCareFund = 0;
      uint256 totalAntiWhaleCharges = 0;
      
//You should not be UniswapPair.
       if( _from != uniswapV2Pair && _to != uniswapV2Pair && _from != address(this))
 {
    
      
      uint256 antiWhaleFee = calculateAntiWhaleFee(_value);
      if(antiWhaleFee > 0)
     {
         uint256 toBurn = antiWhaleFee.div(3);
         uint256 toLiquidity =  antiWhaleFee.div(2);
         uint256 toCareFund = antiWhaleFee.sub(toBurn.add(toLiquidity));
         
         
         //Collect and Burn CPN Token.
          amtBurned =  BurnForBetter(_from, _value, toBurn);
            
            
         // Donate to Care Fund.
          amtToCareFund =    HelpToCareFund(_from, _value,  toCareFund);
          

     
           //Creates liquidity.
            amtLiquified = swapAndLiquify(_from, _value, toLiquidity);
     
     
           totalAntiWhaleCharges = amtBurned.add(amtToCareFund).add(amtLiquified);
        
        emit AntiWhaleCharges(totalAntiWhaleCharges);
         
     }
     
     
        
       }
       
       
        return (totalAntiWhaleCharges);
}

function calculateMaxTxAmount() internal view returns(uint256)
{
    uint256 _currentSupply = currentSupply();
    uint256 _maxTxAmount = _currentSupply.mul(maxTxPercent).div(10000);
    
    return _maxTxAmount;
}

 function ensureMaxTxAmount(
        address from,
        address to,
        uint256 amount) internal view returns (uint256) 
        {
        if (
            _isExcludedFromMaxTx[from] == false && // default will be false
            _isExcludedFromMaxTx[to] == false // default will be false
        ) 
        {
            
               uint256 maxAmountAllowed = calculateMaxTxAmount();
                if(amount > maxAmountAllowed)
                {
                return maxAmountAllowed;
                }
                else
                { 
                return amount;        
                }
            
            
        }
        else{
            return amount;
        }
        
    }

    
    /**
     * @notice A simple method that Execute Core Functions i.e. Burn, Care Fund Donations, Liquidity Making.
     * Collects the amount to implement all functions.
     * @param _from The stakeholder to calculate Functions Amount from.
     * * @param _value Tokens to be used to calculate all functions.
     */

function ExecuteCoreFunctions(address _from, address _to, uint256 _value)
        internal
        returns (bool)
{
//You should not be excluded with benefits and fees.
       if(_isExcludedFromFee[_from] == false && _from != uniswapV2Pair && _to != uniswapV2Pair && _from != address(this))
 {
       if(rewardAndFeeEnabled)
          {
            if(interestRatePerYear > 0)
     {
         //Auto distribute Interest to a Stakeholder.
            autoDistributeInterest();
     }
          
     if(careFundFeePercentage > 0)
     {
         // Donate to Care Fund.
            HelpToCareFund(_from, _value, careFundFeePercentage);
     }

     if(burnFeePercentage > 0)
     {
         //Collect and Burn CPN Token.
            BurnForBetter(_from, _value, burnFeePercentage);
     }      
    }
          
     if(swapAndLiquifyEnabled  && !inSwapAndLiquify && liquidityFeePercentage > 0)
     {
           //Creates liquidity.
           swapAndLiquify(_from, _value, liquidityFeePercentage);
     }    
     
     
  
        }
        
        return true;
}


    /**
     * @notice A simple method that Calculates and Pays the Interest automatically on Transaction.
     * Interest is calculated based on Stakeholder current balance, and is paid after 1 Day.
     * @param _stakeholder The stakeholder to calculate Interest Amount from.
     
     */

function ExecuteRewardFunctions(address _stakeholder)
        internal
        returns (bool)
{
    if(!rewardAndFeeEnabled)
          {
              return true;
          }
//You should not be excluded with benefits and fees.
       if(_isExcludedFromFee[_stakeholder] == false && _stakeholder != address(this) && _stakeholder != uniswapV2Pair && interestRatePerYear != 0)
     {
            //Calculate the Interest to be paid.
            uint256 newInterests = calculateMyInterest(_stakeholder);
            if(newInterests > 0)
            {
                //lets pay Interest to Transaction initiator.
            autoCollectMyInterest(_stakeholder,newInterests);
            }
    }
            return true;
}
        
    /**
     * @notice A simple method that calculates the liquify Token Amount based on Transaction.
     * And Collects from Sender and Swap it for liquidity.
     * @param from The stakeholder to calculate liquidity Amount from.
     * * @param amount Tokens to liquify will be calculated based on this Amount.
     */

    function swapAndLiquify(address from,uint256 amount,uint256 _liquidityFeePercentage) private lockTheSwap 
    returns (uint256)
    {
       
       
        uint256 bal = balanceOf(from);

        uint256 swapAmount = (amount.mul(_liquidityFeePercentage)).div(10**2);

        if (bal >= (swapAmount)) 
        {
       
        // split the contract balance into halves
        uint256 half = swapAmount.div(2);
        uint256 otherHalf = swapAmount.sub(half);

         balances[from] = balances[from].sub(swapAmount);
         balances[address(this)] = balances[address(this)].add(swapAmount);

       emit LetsAddLiquidity(from, address(this), swapAmount);


        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);


        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    else
    {
        swapAmount = 0 ;
    }
    
    return(swapAmount);
        
    }
    


// Swap tokens collected for ETH , so liquidity can be created.
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

       // approve(address(uniswapV2Router), tokenAmount);
       _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

//Simple method to finally execute liquidity to pool.
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
            _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }


    /**
     * @notice A simple method that calculates the Burn Token Amount based on Transaction.
     * And Collects from Sender and Burns it.
     * @param from The stakeholder to calculate Burn Amount from.
     * * @param amount Tokens to Burn will be calculated based on this Amount.
     */

function BurnForBetter(address from, uint256 amount, uint256 _burnFeePercentage)
        internal
        returns (uint256)
{
        uint256 bal = balanceOf(from);

        uint256 burnAmount = (amount.mul(_burnFeePercentage)).div(10**2);

        if (bal >= (burnAmount)) 
        {
            balances[from] = balances[from].sub(burnAmount);
            totalSupply = totalSupply.sub(burnAmount);
            

            emit BurnedForBetter(from, burnAmount);
            emit Transfer(from, burnAddress, burnAmount);
            
        }
        else
        {
            burnAmount = 0;
        }
        return (burnAmount);
}
    
        /**
     * @notice A simple method that calculates the Donation Amount based on Transaction.
     * And Collects from Sender and submits the Donations to CareFund.
     * 
     * @param from The stakeholder to calculate donation from.
     * * @param amount Donation will be calculated based on this Amount.
     */

    function HelpToCareFund(address from, uint256 amount, uint256 _careFundFeePercentage)
        internal
        returns (uint256)
{
        uint256 bal = balanceOf(from);

        uint256 careFundAmount = (amount.mul(_careFundFeePercentage)).div(10**2);

        if (bal >= (careFundAmount)) 
        {
            balances[from] = balances[from].sub(careFundAmount);
            balances[careFundAddress] = balances[careFundAddress].add(careFundAmount);

            emit HelpedToCareFund(from, careFundAmount);
            emit Transfer(from, careFundAddress, careFundAmount);
        }
        else
        {
            careFundAmount = 0;
        }
        return (careFundAmount);
}

    /**
     * @notice A simple method that helps to Donate to careFund.
     
     */

    function DonateToCareFund(uint256 amount) public returns (bool) 
{
        address from = msg.sender;
        uint256 bal = balanceOf(from);

        require(bal >= amount, "You do not have enough CPN to donate.");

        balances[from] = balances[from].sub(amount);
        balances[careFundAddress] = balances[careFundAddress].add(amount);

        emit DonatedToCareFund(from, amount);
        emit Transfer(from, careFundAddress, amount);

        return true;
}

//A simple method that tells an Address is a Stakeholder or not.
    function isStakeholder(address _address)
        public
        view
        returns (bool)
{
    
        return (stakeholderSet.contains(_address));
}

    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder) internal  {
      
      if(_stakeholder != uniswapV2Pair && _stakeholder != address(this))
      {
          
      
            uint256 Bal = balanceOf(_stakeholder);

          
            if (Bal > 0) {
            
                    bool result = stakeholderSet.add(_stakeholder);
                    if(result == true)
                    {
                    interestCollectedAt[_stakeholder] = (block.timestamp - 1 days);
                    
                    emit StakeHolderAdded(_stakeholder);
                    }
     
            }
      }
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder) internal {
        uint256 Bal = balanceOf(_stakeholder);
        //require(Bal <= 0 , 'Balance is not Zero.');

        if (Bal <= 0) {
              
              bool result = stakeholderSet.remove(_stakeholder);  
              
              if(result == true)
              {
              emit StakeHolderRemoved(_stakeholder);
              }
            
        }
    }
    
    /**
     * @notice A simple method that calculates the Current Supply of Token. 
     
     */

    function currentSupply()
        public
        view
        returns (uint256)
        {
        uint256 _currentSupply = totalSupply.sub(balanceOf(burnAddress));
        return(_currentSupply);
        }

    /**
     * @notice A simple method that calculates the rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     */

    function calculateMyInterest(address _stakeholder)
        public
        view
        returns (uint256)
    {
        if (balanceOf(_stakeholder) == 0 || interestRatePerYear == 0 || isExcludedFromFee(_stakeholder))
        {
            return (0);
        } 
        else 
        {
            uint256 lastCollectedAt = interestCollectedAt[_stakeholder];
            if(lastCollectedAt == 0)
            {
                return (0);
            }
            else
            {
            uint256 daysSinceLastCollect = ((block.timestamp.sub(lastCollectedAt)).div(86400));

if(daysSinceLastCollect > 0)
{
            uint256 newInterests =
                daysSinceLastCollect.mul(
                    (
                        (
                            (balanceOf(_stakeholder).mul(interestRatePerYear))
                                .div(10**2)
                        )
                            .div(365)
                    )
                );

            return (newInterests);
        }
        else 
        {
            return(0);
        }
    }
        }
    }
    
    //Allows Auto Payment of Interest to Stakeholders. One at a time.
     function autoCollectMyInterest(address collector,uint256 newInterests) internal returns (bool)
 {
        
      if(maxSupply >= totalSupply.add(newInterests))
        {

//Minting Interest
        totalSupply = totalSupply.add(newInterests);
        balances[collector] = balances[collector].add(newInterests);
        emit MintInterest(address(0), collector, newInterests);

//Marking Date on which Interest collected
        interestCollectedAt[collector] = block.timestamp;
        emit Transfer(address(0), collector, newInterests);
        emit InterestPaid(collector, newInterests);
        
       }
       else{
           emit MaxSupplyLeft(maxSupply.sub(totalSupply));
           
       }
   return true;        
    
}
 


/**
     * @notice A simple method that allows stakeholder to collect there rewards.
     
     */
    function collectMyInterest() public whenNotPaused returns (bool) {
        require(interestRatePerYear>0,"Interest Rate Per Year is Zero.");
        
        address collector = msg.sender;
        require(collector != address(0));

       require(_isExcludedFromFee[collector]==false,"You are in Excluding List.");
 
        uint256 bal = balances[collector];
       require(bal > 0, "Balance is  Zero.");

        uint256 newInterests = calculateMyInterest(collector);
        require(newInterests > 0, "Interest will be available after 1 Day.");

      autoCollectMyInterest(collector,newInterests);
      
   return true;        
    }
 



/**
     * @notice A method to distribute rewards to all stakeholders. Can be executed only by Owner.
     */
  /*  function autoDistributeInterest()
        internal
        
        returns (bool)
    {
        
        uint256 totalStakeholders = stakeholders.length;
        if((interestCounter + 1) <= totalStakeholders)
        {
        
            address stakeholder = stakeholders[interestCounter];
           if(isExcludedFromFee(stakeholder) == false)
           {
            uint256 bal = balances[stakeholder];
            if (bal > 0) 
            {
                uint256 interest = calculateMyInterest(stakeholder);

                if (interest > 0) {
                   autoCollectMyInterest(stakeholder,interest);
                   
                }
                else {
                    emit NoInterestToPay(stakeholder);
                }
            }
           }
           else
           {
            emit ItIsAnExcludedAddress(stakeholder);
           }
          
        
        if((interestCounter + 1) == totalStakeholders)
            {
            interestCounter = 0;
                
            }
            else
            {
            interestCounter = interestCounter + 1;
                
            }
        }
        else
        {
            interestCounter = 0;
        }
    
            return true;
    }
    */    
      function autoDistributeInterest()
        internal
        
        returns (bool)
    {
        
        uint256 totalStakeholders = stakeholderSet.length();
        if((interestCounter + 1) <= totalStakeholders)
        {
        
            address stakeholder = stakeholderSet.at(interestCounter);
           if(isExcludedFromFee(stakeholder) == false)
           {
            uint256 bal = balances[stakeholder];
            if (bal > 0) 
            {
                uint256 interest = calculateMyInterest(stakeholder);

                if (interest > 0) {
                   autoCollectMyInterest(stakeholder,interest);
                   
                }
                else {
                    emit NoInterestToPay(stakeholder);
                }
            }
           }
           else
           {
            emit ItIsAnExcludedAddress(stakeholder);
           }
          
        
        if((interestCounter + 1) == totalStakeholders)
            {
            interestCounter = 0;
                
            }
            else
            {
            interestCounter = interestCounter + 1;
                
            }
        }
        else
        {
            interestCounter = 0;
        }
    
            return true;
    }
        
    
    /**
     * @notice A method to distribute rewards to all stakeholders. Can be executed only by Owner. Altough it is not required. As Interest will be paid automatically with each transaction in Network.
     */
/*    function manualDistributeInterest(uint256 from, uint256 to)
        public 
        onlyOwner
        returns (bool)
    {
        require(interestRatePerYear>0,"Interest Rate Per Year is Zero.");
        
        uint256 totalStakeholders = stakeholders.length;
        require(to < totalStakeholders, "Not enough stakeholders in To");
        require(from < totalStakeholders, "Not enough stakeholders in From");

        for (uint256 s = from; s <= to; s += 1) {
            
            address stakeholder = stakeholders[s];
            
            if(_isExcludedFromFee[stakeholder]==false)
            {
            uint256 bal = balances[stakeholder];
            if (bal > 0) {
                uint256 interest = calculateMyInterest(stakeholder);

                if (interest > 0) {
                    mint(stakeholder, interest);
                    emit InterestPaid(stakeholder, interest);

                    interestCollectedAt[stakeholder] = block.timestamp;
                } 
                else {
                    emit NoInterestToPay(stakeholder);
                }
            }
            }
            else{emit ItIsAnExcludedAddress(stakeholder);}
        }
        return true;
    }
*/
    receive() external payable {
        require(msg.value > 0);
    }

    //Allows Owner to Withdraw All ETH from Contract.
    function withdrawAll() public onlyOwner {
        address payable s = payable(msg.sender);
        require(s.send(address(this).balance));
    }

//Allows Owner to Withdraw some ETH from Contract.
    function withdrawETH(uint256 _amount) public onlyOwner {
        uint256 ethBal = address(this).balance;
        require(_amount <= ethBal, "Not enough ETH in Contract.");

        address payable s = payable(msg.sender);
        require(s.send(_amount));
    }

//Allows Owner to Withdraw some CPN from Contract.
    function withdrawToken(uint256 _amount) public onlyOwner {
      address contractAddress =address(this);
        uint256 tokenBal = balanceOf(contractAddress) ;
        require(_amount <= tokenBal, "Not enough CPN in Contract.");


        balances[contractAddress] = balances[contractAddress].sub(_amount);
        balances[owner] = balances[owner].add(_amount);

        
        emit Transfer(contractAddress, owner, _amount);
        
        
    }

//Helpful Method.
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

//Converts Eth To Token during ICO Sale.
    function EthToToken(uint256 weiAmount) public view returns (uint256 val) {
        require(icoEndDate > block.timestamp,"ICO Ended, Cannot Buy Now!!");
        require(weiAmount > 0, "You need to send some ether");

        uint256 tokenWeiAmount =
            ((multiply(weiAmount, (10**decimals)) / 1 ether) * cpnPrice);

        return (tokenWeiAmount);
    }

/**
     * @notice A simple method to sell ICO.
     
     */
    function buyTokens() public whenNotPaused payable returns (bool) {
        require(icoEndDate > block.timestamp,"ICO Ended, Cannot Buy Now!!");
        
        address buyer = msg.sender;
        require(buyer != address(0));
        require(tokenBlacklist[buyer] == false, "Buyer is blacklist address.");

        uint256 weiAmount = msg.value;
        require(weiAmount > 0, "You need to send some ether");

        uint256 tokenWeiAmount =
            ((multiply(weiAmount, (10**decimals)) / 1 ether) * cpnPrice);

        require(
            balances[owner] >= tokenWeiAmount,
            "Owner do not have enough Tokens."
        );

        balances[owner] = balances[owner].sub(tokenWeiAmount);
        balances[buyer] = balances[buyer].add(tokenWeiAmount);

        addStakeholder(buyer);

        emit Transfer(owner, buyer, tokenWeiAmount);

        return true;
    }
}