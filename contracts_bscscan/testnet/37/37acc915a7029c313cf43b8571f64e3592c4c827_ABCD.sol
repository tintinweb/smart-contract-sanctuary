/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
library EnumerableSet {

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
}
 
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address /*payable*/) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;//TODO
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
     * - the calling contract must have an BNB balance of at least `value`.
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    // uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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


//// pancakeswap
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

//// main contract
contract ABCD is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    //// ERC-20 init
    string private constant _name = "final";
    string private constant _symbol = "final";  //TODO
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 5 * 10**8 * 10**9;  //TODO
    address private constant _devAddress = 0xd36545A454C162AC44eB153f29253aD9FC38be1D;  //TODO
    address public constant _swapRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;  //TODO
    // tokens own
    mapping (address => uint256) private _tOwned;
    // allow owner to use spender's token 
    mapping (address => mapping (address => uint256)) private _allowances;
    // max transaction amount
    uint256 public _maxTxAmount = 100 * 10**9; //TODO
    uint256 private _previousMaxTxAmount = _maxTxAmount;
    event TransferDetailBeforeReflection(
        uint256 tAmount,
        uint256 tTransferAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tDev,
        uint256 tReferrer,
        uint256 tReferree
    );
    uint256 _totalHolders = 1;


    //// Launch
    uint256 public immutable contractInitializeDeadline; // make sure the contract is not changeble by owner after initialized deadline
    uint256 public immutable contractReleaseTime;  // make sure the contract is not changeble by owner for certain period for stability and transparency
    uint256 public immutable launchReleaseTime;
    uint256 public immutable launchDate;
    bool private launchReleaseFlag = false;
    bool private initFlag = false;
    
    
    //// account exclusion
    mapping (address => bool) private _isExcludedFromFee;
    EnumerableSet.AddressSet private _isExcludedFromTxConstrant;
    EnumerableSet.AddressSet private _isExcluded;


    //// TAX
    // tax reduction
    uint256 taxReductionLv = 0;
    uint256[3] _devFeeLv = [7, 4, 0];

    // total tax
    uint256 public _taxFee = 4;
    uint256 private _previousTaxFee = _taxFee;
    uint256 public _liquidityFee = 4;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public _devFee = _devFeeLv[taxReductionLv];
    uint256 private _previousDevFee = _devFee;
    bool private _inRemoveTax = false;
    bool private _inRemoveConstraint = false;


    //// referral system 
    mapping (address => address) private referrer;
    mapping (address => uint256) private totalReferredToken;
    mapping (address => uint256) private referralRewardToken;  // not inculding the reflection from referral reward
    mapping (address => uint256) private originalTToken;
    uint256 private constant _level1MinReferredToken = 50 * 10**9; //TODO
    uint256 private constant _level2MinReferredToken = 100 * 10**9; //TODO
    uint256 private constant _level3MinReferredToken = 200 * 10**9; //TODO
    // thousandth
    uint256 public _referrerFee = 0;
    uint256 private _previousReferrerFee = _referrerFee;
    uint256 public _referreeFee = 0;
    uint256 private _previousReferreeFee = _referreeFee;

    uint256[3] public _referrerFeePonyLv = [5, 3, 0];
    uint256[3] public _referrerFeeHorseLv = [10, 5, 0];
    uint256[3] public _referrerFeeFireHorseLv = [20, 10, 0];
    uint256[3] public _referrerFeeUnicornLv = [40, 20, 0];
    uint256[3] public _referreeFeePonyLv = [5, 2, 0];
    uint256[3] public _referreeFeeHorseLv = [10, 5, 0];

    uint256 public _referrerFeePony = _referrerFeePonyLv[taxReductionLv];
    uint256 public _referrerFeeHorse = _referrerFeeHorseLv[taxReductionLv];
    uint256 public _referrerFeeFireHorse = _referrerFeeFireHorseLv[taxReductionLv];
    uint256 public _referrerFeeUnicorn = _referrerFeeUnicornLv[taxReductionLv];
    uint256 public _referreeFeePony = _referreeFeePonyLv[taxReductionLv];
    uint256 public _referreeFeeHorse = _referreeFeeHorseLv[taxReductionLv];
    event DevAndReferralFee(
        uint256 devFee,
        uint256 referrerFeePony,
        uint256 referrerFeeHorse,
        uint256 referrerFeeFireHorse,
        uint256 referrerFeeUnicorn,
        uint256 referreeFeePony,
        uint256 referreeFeeHorse
    );
    event refLevel(uint8 level);


    //// reflection system
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal)); // ~10^77
    uint256 private _tFeeTotal = 0;
    // reflection own
    mapping (address => uint256) private _rOwned;   


    //// liquidity pool 
    uint256 private constant numTokensSellToAddToLiquidity = 2 * 10**2 * 10**9;  //TODO
    // time lock
    uint256 public immutable minReleaseTime;
    uint256[] public _dynamicLockedLiquidity;
    uint256[] public _dynamicReleaseTime;  //lock 3 months from date of swap and liquify
    uint256 public _unlockedTotalLiquidity = 0;  //total unlockerd liquidity can be remove from pool
    // pancakeswap liquidity pool init
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    // enable pancakeswap liquidity pool
    bool public swapAndLiquifyEnabled = true;
    bool private _previousSwapAndLiquifyEnabled = swapAndLiquifyEnabled;
    bool inSwapAndLiquify;
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    event AddLiquidity(
        uint256 amountToekn,
        uint256 amountBNB,
        uint256 liquidity
    ); 
    event RemoveLiquidity(
        uint256 amountToken,
        uint256 amountBNB
    );
    
    
    constructor () {
        // init uniswap router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_swapRouter);
        // create a uniswap pair for ABCD (WBNB/ABCD)
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        // exclude owner, dev wallet, and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromTxConstrant.add(owner());
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_devAddress] = true;
        // init tokens
        _rOwned[_msgSender()] = _rTotal;
        originalTToken[_msgSender()] = originalTToken[_msgSender()].add(_tTotal);
        emit Transfer(address(0), _msgSender(), _tTotal);
        // init time lock
        minReleaseTime = block.timestamp + (60);  //TODO: start date + 1.5 years
        contractReleaseTime = block.timestamp + (60);  //TODO: start date + 6 months
        launchReleaseTime = block.timestamp + (60);  //TODO

        contractInitializeDeadline = block.timestamp + 60; //TODO: shoule be <= launchDate
        launchDate = block.timestamp + 60;  //TODO
        // TODO: add Dxsale address in exclusion
    }

    // get dev address
    function devAddress() public pure returns (address) {
        return _devAddress;
    }

    //// ERC-20
    // name of tokens
    function name() public pure returns (string memory) {
        return _name;
    }
    // abbreviation of tokens
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    // unit of tokens
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    // total supply of tokens
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    // get tokens amount own by account
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded.contains(account)) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    // transfer tokens from msg sender to recipient address
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    // approve/autorized spender to use current address's (contract writer) tokens
    // not requires current address to have number of autorized tokens 
    function approve(address spender, uint256 amount) public override returns (bool) {
            _approve(_msgSender(), spender, amount);
            return true;
        }
    // return the total tokens the spender can spend from owner
    // not requires current owner to have number of autorized tokens
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    // transfer from sender to recipient if _allowances[sender][contract writer] >= amount
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    // approve() enhancement
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    

    //// main ERC-20 function
    // transfer
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        // init
        require(from != address(0), "ERC20: Transfer from the zero address");
        require(to != address(0), "ERC20: Transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");
        bool takeFee = true;

        // check remove contraints
        if (_isExcludedFromTxConstrant.contains(from) || _isExcludedFromTxConstrant.contains(to)) {
            removeAllTxConstraint();
        }

        // check fee 
        if(from == uniswapV2Pair || to == uniswapV2Pair) {
            // limit transaction amount only on uniswap to prevent the drastic price impact
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        } else {
            // no fee between account
            takeFee = false;
        }
        // no fee if account is excluded
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        // swap and liquify
        // check contract whether token balacne is enough to swap and add it to liquidity
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&  // pass if swap and liquify is locked by contract. Avoid circular liquidity event
            from != uniswapV2Pair &&  // don't swap & liquify if sender is uniswap pair.
            swapAndLiquifyEnabled    
        ) {
            // remove max tx amount contraint during liquifying
            _previousMaxTxAmount = _maxTxAmount;
            _maxTxAmount = _tTotal;
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
            _maxTxAmount = _previousMaxTxAmount;  // add max transation amount constraint back
        }
        
        // transfer
        _tokenTransfer(from,to,amount,takeFee);

        // check restore contraints
        if (_isExcludedFromTxConstrant.contains(from) || _isExcludedFromTxConstrant.contains(to)) {
            restoreAllTxConstraint();
        }
    }
    // this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee) {
            removeAllFee();
        } else if(sender == uniswapV2Pair && referrer[recipient] != address(0)) {
            address referrerAddr = referrer[recipient];
            totalReferredToken[referrerAddr] = totalReferredToken[referrerAddr].add(amount); //TODO: consider total amount as part of calculation of rank
            customizeFeeForReferral(referrerAddr);
        }
        
        if (_isExcluded.contains(sender) && !_isExcluded.contains(recipient)) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded.contains(sender) && _isExcluded.contains(recipient)) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded.contains(sender) && _isExcluded.contains(recipient)) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        } 
        // TODO: remove SSL-02 redundant code
        // else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
        //     _transferStandard(sender, recipient, amount);
        // } 
        
        if(!takeFee) {
            restoreAllFee();
        } else if(sender == uniswapV2Pair && referrer[recipient] != address(0)) { //the sender has a referrer
            restoreForReferralFee();
        }
    }
    function _transferStandard(address sender, address recipient, uint256 tAmount) private { //tAmount = 1000      1
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev, uint256 tReferrer, uint256 tReferree) = _getTValues(tAmount, recipient); // 880, 50, 50, 20     0.88 0.05, 0.05, 0.02
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDev, tReferrer, tReferree, _getRate()); // 1000*10^53, 880*10^53, 50*10^53     10, 8.8, 0.5
        // update log
        emit TransferDetailBeforeReflection(tAmount, tTransferAmount, tFee, tLiquidity, tDev, tReferrer, tReferree);
        _updateOriginalTokens(tAmount, tTransferAmount, sender, recipient);
        // update balance
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        if (_rOwned[sender] == 0) _totalHolders = _totalHolders.sub(1);
        if (_rOwned[recipient] == 0) _totalHolders = _totalHolders.add(1);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        // update fee
        _takeLiquidity(tLiquidity);
        _takeDevFee(tDev);
        if(tReferree != 0) {
            address referreeAddr;
            if(sender == uniswapV2Pair) {
                referreeAddr = recipient;
            } else {
                referreeAddr = sender;
            }
            _takeReferralFee(tReferrer, referrer[referreeAddr]);
            _takeReferralFee(tReferree, referreeAddr);
        }
        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev, uint256 tReferrer, uint256 tReferree) = _getTValues(tAmount, recipient);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDev, tReferrer, tReferree, _getRate());
        // update log
        emit TransferDetailBeforeReflection(tAmount, tTransferAmount, tFee, tLiquidity, tDev, tReferrer, tReferree);
        _updateOriginalTokens(tAmount, tTransferAmount, sender, recipient);
        // update balance
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        if (_rOwned[sender] == 0) _totalHolders = _totalHolders.sub(1);
        if (_tOwned[recipient] == 0) _totalHolders = _totalHolders.add(1);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);     
        // update fee      
        _takeLiquidity(tLiquidity);
        _takeDevFee(tDev);
        if(tReferree != 0) {
            address referreeAddr;
            if(sender == uniswapV2Pair) {
                referreeAddr = recipient;
            } else {
                referreeAddr = sender;
            }
            _takeReferralFee(tReferrer, referrer[referreeAddr]);
            _takeReferralFee(tReferree, referreeAddr);
        }
        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev, uint256 tReferrer, uint256 tReferree) = _getTValues(tAmount, recipient);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDev, tReferrer, tReferree, _getRate());
        // update log
        emit TransferDetailBeforeReflection(tAmount, tTransferAmount, tFee, tLiquidity, tDev, tReferrer, tReferree);
        _updateOriginalTokens(tAmount, tTransferAmount, sender, recipient);
        // update balance
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        if (_tOwned[sender] == 0) _totalHolders = _totalHolders.sub(1);
        if (_rOwned[recipient] == 0) _totalHolders = _totalHolders.add(1);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        // update fee
        _takeLiquidity(tLiquidity);
        _takeDevFee(tDev);
        if(tReferree != 0) {
            address referreeAddr;
            if(sender == uniswapV2Pair) {
                referreeAddr = recipient;
            } else {
                referreeAddr = sender;
            }
            _takeReferralFee(tReferrer, referrer[referreeAddr]);
            _takeReferralFee(tReferree, referreeAddr);
        }
        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev, uint256 tReferrer, uint256 tReferree) = _getTValues(tAmount, recipient);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDev, tReferrer, tReferree, _getRate());
        // update log
        emit TransferDetailBeforeReflection(tAmount, tTransferAmount, tFee, tLiquidity, tDev, tReferrer, tReferree);
        _updateOriginalTokens(tAmount, tTransferAmount, sender, recipient);
        // update balance
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        if (_tOwned[sender] == 0) _totalHolders = _totalHolders.sub(1);
        if (_tOwned[recipient] == 0) _totalHolders = _totalHolders.add(1);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);     
        // update fee   
        _takeLiquidity(tLiquidity);
        _takeDevFee(tDev);
        if(tReferree != 0) {
            address referreeAddr;
            if(sender == uniswapV2Pair) {
                referreeAddr = recipient;
            } else {
                referreeAddr = sender;
            }
            _takeReferralFee(tReferrer, referrer[referreeAddr]);
            _takeReferralFee(tReferree, referreeAddr);
        }
        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    // approve
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    //// Fee and Transfer Amount Calculation Helper
    // get transfer token amount and tax
    function _getTValues(uint256 tAmount, address to) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount, to); // 1000 * 5% = 50
        uint256 tLiquidity = calculateLiquidityFee(tAmount); // 1000 * 5% = 50
        uint256 tReferrer = calculateReferrerFee(tAmount);
        uint256 tReferree = calculateReferreeFee(tAmount);
        // tdev = original tdev - r referral
        uint256 tDev = calculateDevFee(tAmount);
        if (tDev < tReferrer.add(tReferree)){
            tDev = 0;
        } else {
            tDev = tDev.sub(tReferrer).sub(tReferree); // 1000 * 2% = 20
        }
        uint256 tTransferAmount = tAmount.sub(tFee);
                tTransferAmount = tTransferAmount.sub(tLiquidity);
                tTransferAmount = tTransferAmount.sub(tDev);
                tTransferAmount = tTransferAmount.sub(tReferrer);
                tTransferAmount = tTransferAmount.sub(tReferree);
        return (tTransferAmount, tFee, tLiquidity, tDev, tReferrer, tReferree);
    }
    // get transfert reflection token amount and tax
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev, uint256 tReferrer, uint256 tReferree, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate); // 1000 * 10^53
        uint256 rFee = tFee.mul(currentRate); // 50 * 10^53
        uint256 rLiquidity = tLiquidity.mul(currentRate); // 50 * 10^53
        uint256 rReferrer = tReferrer.mul(currentRate);
        uint256 rReferree = tReferree.mul(currentRate);
        // no need to adjust rDev since treferral is excluded in tDev
        uint256 rDev = tDev.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
                rTransferAmount = rTransferAmount.sub(rLiquidity);
                rTransferAmount = rTransferAmount.sub(rDev);
                rTransferAmount = rTransferAmount.sub(rReferrer);
                rTransferAmount = rTransferAmount.sub(rReferree);

        return (rAmount, rTransferAmount, rFee);
    }
    // referrer fee in token space (thousandth)
    function calculateReferrerFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_referrerFee).div(
            10**3
        );
    }
    // referree fee in token space (thousandth)
    function calculateReferreeFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_referreeFee).div(
            10**3
        );
    }
    // liquidity fee in token space
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }
    // reflection fee in token space
    function calculateTaxFee(uint256 _amount, address to) private view returns (uint256) {
        if (launchDate > block.timestamp || _taxFee == 0 || to != uniswapV2Pair) {
            return _amount.mul(_taxFee).div(
                10**2
            );
        }
        //TODO: 28 days - start from 88%, drop 3% per day
        // so the total tax of launch date = 88 + 4 + 7 = 99%
        // the total tax at 28th days after launch = 4 + 4 + 7 = 15
        // use 2 days for testing
        uint256 dayCount = (block.timestamp - launchDate) / 60 / 5;
        uint256 startRate = 38;
        if (dayCount < 3) {
            uint256 _newTaxFee = startRate.sub(dayCount.mul(17));
            return _amount.mul(_newTaxFee).div(
                10**2
            );
        }
        return _amount.mul(_taxFee).div(
            10**2
        );
    }
    // dev & marketing fee in token space
    function calculateDevFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_devFee).div(
            10**2
        );
    }
    // add liquidity fee to contract's balance  
    function _takeLiquidity(uint256 tLiquidity) private {
        // update log
        originalTToken[address(this)] = originalTToken[address(this)].add(tLiquidity);
        // update token
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded.contains(address(this)))
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    // add dev/marketing fee to dev's balance  
    function _takeDevFee(uint256 tDev) private {
        // update log
        originalTToken[_devAddress] = originalTToken[_devAddress].add(tDev);
        // update token
        uint256 currentRate =  _getRate();
        uint256 rDev = tDev.mul(currentRate);
        _rOwned[_devAddress] = _rOwned[_devAddress].add(rDev);
        if(_isExcluded.contains(_devAddress))
            _tOwned[_devAddress] = _tOwned[_devAddress].add(tDev);
    }
    // add referral fee 
    function _takeReferralFee(uint256 tReferral, address referralAddr) private {
        // update log
        referralRewardToken[referralAddr] = referralRewardToken[referralAddr].add(tReferral);  // not include reflection
        // update bonus
        uint256 currentRate =  _getRate();
        uint256 rReferral = tReferral.mul(currentRate);
        // add holder if referrer hasn't purchased any ABCD yet
        if (_rOwned[referralAddr] == 0) _totalHolders = _totalHolders.add(1);
        // update rOwned
        _rOwned[referralAddr] = _rOwned[referralAddr].add(rReferral);
        // update tOwned
        if(_isExcluded.contains(referralAddr)) _tOwned[referralAddr] = _tOwned[referralAddr].add(tReferral);
    }
    // remove all fee before the transaction
    function removeAllFee() private {
        if(_inRemoveTax) return;
        if(_taxFee == 0 && _liquidityFee == 0 && _devFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousDevFee = _devFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
        _devFee = 0;
        _inRemoveTax = true;
    }
    // restore fee after the transaction is completed if it's updated in this contract
    function restoreAllFee() private {
        if(!_inRemoveTax) return;
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _devFee = _previousDevFee;

        _inRemoveTax = false;
    }
    // remove all constraint
    function removeAllTxConstraint() private {
        if(_inRemoveConstraint) return;
        if(_maxTxAmount==_tTotal && swapAndLiquifyEnabled==false) return;
    
        _previousMaxTxAmount = _maxTxAmount;
        _previousSwapAndLiquifyEnabled = swapAndLiquifyEnabled;

        _maxTxAmount = _tTotal;
        swapAndLiquifyEnabled = false;

        _inRemoveConstraint = true;
    }
    // restore all constraint
    function restoreAllTxConstraint() private {
        if(!_inRemoveConstraint) return;
        if (_maxTxAmount!=_tTotal && swapAndLiquifyEnabled!=false) return;
        _maxTxAmount = _previousMaxTxAmount;
        swapAndLiquifyEnabled = _previousSwapAndLiquifyEnabled;

        _inRemoveConstraint = false;
    }
    // restore referral fee after the transaction is completed if it's updated in this contract
    function restoreForReferralFee() private {
        _referrerFee = _previousReferrerFee;
        _referreeFee = _previousReferreeFee;
    }
    // update the max transaction amount limit in pancakeswap
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        require(block.timestamp > contractReleaseTime || block.timestamp < contractInitializeDeadline, "Owner can't modify contract until release time");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }
    // update original t token for logging
    function _updateOriginalTokens(uint256 tAmount, uint256 tTransferAmount, address sender, address recipient) private {
        // update sender
        if (tAmount < originalTToken[sender]) 
        {
            originalTToken[sender] = originalTToken[sender].sub(tAmount);
            tAmount = 0;
        } else {
            tAmount = tAmount.sub(originalTToken[sender]);
            originalTToken[sender] = 0;  // all token left in wallet is coming from reflection or referral reward
        }

        if (tAmount < referralRewardToken[sender]) {
            referralRewardToken[sender] = referralRewardToken[sender].sub(tAmount);
        } else {
            referralRewardToken[sender] = 0;  // all token left in wallet is coming from reflection
        }

        // update recipient
        originalTToken[recipient] = originalTToken[recipient].add(tTransferAmount);
    }
    function distributionOfTokens(address account) public view returns (uint256 transferedToken, uint256 referralToken, uint256 reflectionToken){
        uint256 totalToken = balanceOf(account);
        uint256 _referralToken = referralRewardToken[account];
        uint256 _transferedToken = originalTToken[account];
        // prevent underflow
        uint256 _reflectionToken;
        if (totalToken > _referralToken.add(_transferedToken)) _reflectionToken = totalToken.sub(_referralToken).sub(_transferedToken);
        else _reflectionToken = 0;
        return (_transferedToken, _referralToken, _reflectionToken);
    }
    function totalHolders() public view returns (uint256) {
        return _totalHolders;
    } 


    //// Reflection 
    function get_rTotal() public view returns (uint256) {
        return _rTotal;
    }
    // get current value of reflection tokens in ABCD token space
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    // update reflection tokens space and total fee
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    // get current reflection ratio for mapping reflection tokens to ABCD tokens
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply); //10^53
    }
    // get current supply for calculating reflection ratio
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal; //10^77
        uint256 tSupply = _tTotal; //10^25     
        for (uint256 i = 0; i < _isExcluded.length(); i++) {
            address tempAddress = _isExcluded.at(i);
            if (_rOwned[tempAddress] > rSupply || _tOwned[tempAddress] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[tempAddress]);
            tSupply = tSupply.sub(_tOwned[tempAddress]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    // get current total reflection fee. 
    // this fee should be distributed back to holders(include lquidity pool) fairly based on the amount of ABCD tokens they are holding
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    // update reflection fee
    function setTaxFeePercent(uint256 newTaxFee) external onlyOwner {
        require(block.timestamp > contractReleaseTime || block.timestamp < contractInitializeDeadline, "Owner can't modify contract until release time");
        require(newTaxFee < _taxFee, "New reflection fee must be less than current reflection fee");
        _taxFee = newTaxFee;
    }


    //// Referral
    // update referral fee based on rank
    function customizeFeeForReferral(address referrerAddr) private {
        uint8 referrerLevel = getReferrerLevel(referrerAddr);
        emit refLevel(referrerLevel);
        // pass if no dev Fee
        if (_devFee == 0) return;
        
        _previousReferrerFee = _referrerFee; //should always be 0
        _previousReferreeFee = _referreeFee; //should always be 0

        if(referrerLevel == 0) {
            _referrerFee = _referrerFeePony;
            _referreeFee = _referreeFeePony;
        } else if(referrerLevel == 1) {
            _referrerFee = _referrerFeeHorse;
            _referreeFee = _referreeFeeHorse;
        } else if(referrerLevel == 2) {
            _referrerFee = _referrerFeeFireHorse;
            _referreeFee = _referreeFeeHorse;
        } else if(referrerLevel == 3) {
            _referrerFee = _referrerFeeUnicorn;
            _referreeFee = _referreeFeeHorse;
        }
    }
    // return current referrer level for calculating referral fee
    function getReferrerLevel(address account) public view returns(uint8) {
        uint256 currentTotalReferredToken = totalReferredToken[account];
        uint8 level = 0;

        if(currentTotalReferredToken >= _level3MinReferredToken) {
            level = 3;
        } else if(currentTotalReferredToken >= _level2MinReferredToken) {
            level = 2;
        } else if(currentTotalReferredToken >= _level1MinReferredToken) {
            level = 1;
        }
        return level;
    }
    // set referrer
    function setReferrer(address account) public {
        require(referrer[_msgSender()] == address(0), "Referrer existing");
        require(account != _msgSender(), "Rferrer cant be same as referree.");
        referrer[_msgSender()] = account;
    }
    // get current acount's referrer
    function getReferrer(address account) public view returns(address) {
        return referrer[account];
    }
    // get total ABCD tokens from referral bonus
    function getTotalReferredToken(address account) public view returns(uint256) {
        return totalReferredToken[account];
    }
    // update dev pct (community driven)
    // will reduce referral bonus if we update dev fee
    function setdevFeePercent() external onlyOwner {
        require(block.timestamp > contractReleaseTime || block.timestamp < contractInitializeDeadline, "Owner can't modify contract until release time");
        require(taxReductionLv < 2, "Reach to the max Level");
        // update level
        taxReductionLv = taxReductionLv.add(1);
        // update referral fee
        _referrerFeePony = _referrerFeePonyLv[taxReductionLv];
        _referrerFeeHorse = _referrerFeeHorseLv[taxReductionLv];
        _referrerFeeFireHorse = _referrerFeeFireHorseLv[taxReductionLv];
        _referrerFeeUnicorn = _referrerFeeUnicornLv[taxReductionLv];
        _referreeFeePony = _referreeFeePonyLv[taxReductionLv];
        _referreeFeeHorse = _referreeFeeHorseLv[taxReductionLv];
        // update dev fee
        _devFee = _devFeeLv[taxReductionLv];
        emit DevAndReferralFee(_devFee, _referrerFeePony, _referrerFeeHorse, _referrerFeeFireHorse, _referrerFeeUnicorn, _referreeFeePony, _referreeFeeHorse);
    }


    //// Liquidity
    // to receive BNB from pancakeswap when swapping
    receive() external payable {}
    // lock the swap and liquify to prevent circular liquidity event
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    // update liquidity pct (community driven)
    function setLiquidityFeePercent(uint256 newLiquidityFee) external onlyOwner {
        require(block.timestamp > contractReleaseTime || block.timestamp < contractInitializeDeadline, "Owner can't modify contract until release time");
        require(newLiquidityFee < _liquidityFee, "New liquidity fee must be less than current liquidity fee");
        _liquidityFee = newLiquidityFee;
    }
    // enable swap and liquify 
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        require(block.timestamp > contractReleaseTime || block.timestamp < contractInitializeDeadline, "Owner can't modify contract until release time");
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    // main function of swap and liquify
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap half tokens for BNB and add to address(thit) 
        swapTokensForBNB(half); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

        // amount of BNB we just swap into this address
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    // swap half of ABCD tokens to BNB
    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }
    // add BNB(WBNB) and ABCD to liquidity pool
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uint256 amountToken;
        uint256 amountBNB;
        uint256 liquidity;
        (amountToken, amountBNB, liquidity) = uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),  //send LP tokens to this contract
            block.timestamp
        );

        // save current liquidity amount
        _dynamicLockedLiquidity.push(liquidity);
        _dynamicReleaseTime.push(block.timestamp + (60 * 10));  //TODO
        emit AddLiquidity(amountToken, amountBNB, liquidity);
    }
    // check current total liquidity added by liquidity fee
    function liquidityTokens() public view returns (uint256 liquidity) {
        return IUniswapV2Pair(uniswapV2Pair).balanceOf(address(this));
    }
    // get unlocked community liquidity
    function unlockedTotalLiquidity() public view returns (uint256) {
        return _unlockedTotalLiquidity;
    }
    // unlock liquidity. 
    // We are not removing liquidity here, decision will be made by the team and community.
    function unlockLiquidity() external onlyOwner {
        require(block.timestamp > minReleaseTime, "Release time is after current time");
        uint256 newStart = 0;
        uint256 swap = 0;
        // update unlocked liquidity
        for (uint256 i = 0; i < _dynamicLockedLiquidity.length; i++) {
            // if time >= release time then release
            if (block.timestamp > _dynamicReleaseTime[i]) {
                _unlockedTotalLiquidity = _unlockedTotalLiquidity.add(_dynamicLockedLiquidity[i]);
                newStart = newStart.add(1);
            // else swap the elements to front and pop the unused elements
            } else {
                if (i == 0) break;
                _dynamicLockedLiquidity[swap] = _dynamicLockedLiquidity[i];
                _dynamicReleaseTime[swap] = _dynamicLockedLiquidity[i];
                swap = swap.add(1);
            }
        }
        // update length
        for (uint256 i = 0; i < newStart; i++) {
            _dynamicLockedLiquidity.pop();
            _dynamicReleaseTime.pop();
        }
    }
    // remove BNB and ABCD from liquidity pool with time lock
    // TODO: onlyOwner or onlyOwner()
    function removeLiquidity(uint256 liquidity) external onlyOwner {
        // check whether liqudity is locked
        require(block.timestamp > minReleaseTime, "Release time is after current time");
        require(liquidity <= _unlockedTotalLiquidity, "Liquidity to remove should be less than unlocked liquidity");
        // check total liquidity
        if (liquidity > liquidityTokens()) liquidity = liquidityTokens();
        // remove all fee and disable swap and liquify to prevent safetrasfer issue
        removeAllFee();
        bool preSwapAndLiquifyEnabled = swapAndLiquifyEnabled;
        swapAndLiquifyEnabled = false;
        // approve pancakeswap router to transfer liquidity in this contract
        IUniswapV2Pair(uniswapV2Pair).approve(address(uniswapV2Router), liquidity);
        // remove liquidity
        uint256 amountToken;
        uint256 amountBNB;
        (amountToken, amountBNB) = uniswapV2Router.removeLiquidityETH(
            address(this), 
            liquidity, 
            0, 
            0, 
            payable(0x97DFD432a9c35BE4e04461F774D0256164724Cc0),  //TODO: can be another contract has it's own lock machenism 
            block.timestamp + 360
        );
        // update unlocked liquidity
        _unlockedTotalLiquidity = _unlockedTotalLiquidity.sub(liquidity);
        emit RemoveLiquidity(amountToken, amountBNB);
        // restore all fee and enable swap and liquify back
        restoreAllFee();
        swapAndLiquifyEnabled = preSwapAndLiquifyEnabled;
    }


    //// Account exclusion    
    // check whether account is excluded from reward
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded.contains(account);
    }
    // exclude account from reward 
    function excludeFromReward(address account) public onlyOwner {
        require(block.timestamp > contractReleaseTime || block.timestamp < contractInitializeDeadline, "Owner can't modify contract until release time");
        require(!_isExcluded.contains(account), "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded.add(account);
    }
    // inlculde account from reward
    function includeInReward(address account) external onlyOwner {
        require(block.timestamp > contractReleaseTime || block.timestamp < contractInitializeDeadline, "Owner can't modify contract until release time");
        require(_isExcluded.contains(account), "Account is already included");
        // get currenty rSupply
        uint256 rSupply;
        uint256 tSupply;
        (rSupply, tSupply) = _getCurrentSupply();
        // get new R amount: The current user shoudn't get any reflection when the includeInReward is completed
        uint256 currentRate = _getRate();
        uint256 newRAmount = _tOwned[account].mul(currentRate);
        // update new rTotal s.t. all holders tokens amount won't change due to the change in rate
        if (rSupply != _rTotal) {
            _rTotal = _rTotal - _rOwned[account] + newRAmount;
        }
        // rOwned = newRamount s.t. balanceOf(account) = current tTokens when the includeInReward is completed
        _rOwned[account] = newRAmount;
        // remove account
        _isExcluded.remove(account);
        _tOwned[account] = 0;
    }
    // check whether account is excluded from fee
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    // exclude acount from fee
    function excludeFromFee(address account) public onlyOwner {
        require(block.timestamp > contractReleaseTime || block.timestamp < contractInitializeDeadline, "Owner can't modify contract until release time");
        _isExcludedFromFee[account] = true;
    }
    // include account from fee
    function includeInFee(address account) public onlyOwner {
        require(block.timestamp > contractReleaseTime || block.timestamp < contractInitializeDeadline, "Owner can't modify contract until release time");
        _isExcludedFromFee[account] = false;
    }
    // exclude acount from Tx constraint
    function excludeFromTxConstraint(address account) public onlyOwner {
        require(block.timestamp > contractReleaseTime || block.timestamp < contractInitializeDeadline, "Owner can't modify contract until release time");
        require(!_isExcludedFromTxConstrant.contains(account), "Account is already excluded");
        _isExcludedFromTxConstrant.add(account);
    }
    // include account from fee
    function includeInTxConstraint(address account) public onlyOwner {
        require(block.timestamp > contractReleaseTime || block.timestamp < contractInitializeDeadline, "Owner can't modify contract until release time");
        require(_isExcludedFromTxConstrant.contains(account), "Account is already included");
        _isExcludedFromTxConstrant.remove(account);
    }


    //// Launch
    // release the limit of transaction on pancakeswap
    function releaseMaxTxPercent() external {
        require(launchReleaseFlag == false, "this function is disabled");
        require(block.timestamp > launchReleaseTime, "Limit sale on launch date");
        _maxTxAmount = 10**5 * 10**9; //TODO    
        launchReleaseFlag = true;
    }
    // init liquidity (can only be called once) TODO: keep it just for test net
    function initLiquidity(uint256 tokenAmount) payable external onlyOwner {
        require(initFlag == false, "this function is disabled");
        uint256 weiTokenAmount = tokenAmount.mul(10**9);
        // remove max tx amount, liquify and fee
        removeAllTxConstraint();
        removeAllFee();
        // transfer tokens to contract
        _transfer(_msgSender(), address(this), weiTokenAmount);
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), weiTokenAmount);
        // add the liquidity
        uint256 amountToken;
        uint256 amountBNB;
        uint256 liquidity;
        (amountToken, amountBNB, liquidity) = uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            weiTokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _devAddress,  //send LP tokens to dev wallet
            block.timestamp
        );
        restoreAllFee();
        restoreAllTxConstraint();
        emit AddLiquidity(amountToken, amountBNB, liquidity);
        initFlag = true;
    }


    //// milestone buyback
    // TODO: SSL-03 fix
    event BuybackABCDAmount(uint256[]);
    function superReflection() external onlyOwner {
        require(block.timestamp > minReleaseTime, "Release time is after current time");
        // remove all fee and disable swap and liquify to prevent safetrasfer issue
        removeAllFee();
        removeAllTxConstraint();

        // buyback ABCD
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        uint256[] memory swapTokens;
        // swap BNB for ABCD
        if (address(this).balance > 0) {
            swapTokens = uniswapV2Router.swapExactETHForTokens{value: address(this).balance}(
            0, // accept any amount
            path,
            address(this),
            block.timestamp + 60
            );
        }
        emit BuybackABCDAmount(swapTokens);

        // reflect back to holders
        uint256 currentRate = _getRate();
        uint256 tReflection = balanceOf(address(this));
        uint256 rReflection = tReflection.mul(currentRate);
        _tOwned[address(this)] = 0;
        _rOwned[address(this)] = 0;
        _reflectFee(rReflection, tReflection);

        // restore all fee and enable swap and liquify back
        restoreAllFee();
        restoreAllTxConstraint();
    }
}