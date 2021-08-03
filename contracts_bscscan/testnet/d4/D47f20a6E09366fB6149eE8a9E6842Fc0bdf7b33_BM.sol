/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IPancakeERC20 {
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
}

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

interface IPancakeRouter01 {
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

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msg.sender;
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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




////////////////////////////////////////////////////////////////////////////////////////////////////////
//BURNINGMOON Contract ////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////
contract BM is IBEP20, Ownable
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _sellLock;

    EnumerableSet.AddressSet private _excluded;
    EnumerableSet.AddressSet private _excludedFromLocks;
    EnumerableSet.AddressSet private _excludedFromStaking;
    EnumerableSet.AddressSet private _whiteList;
    EnumerableSet.AddressSet private _automatedMarketMakers;
    
    //Token Info
    string private constant _name = 'TBM5';
    string private constant _symbol = 'TBM5';
    uint8 private constant _decimals = 9;
    uint256 public constant InitialSupply= 100 * 10**6 * 10**_decimals;//equals 100.000.000 token

    //Lower limit for the balance Limit, can't be set lower
    uint8 public constant BalanceLimitDivider=100;
    //Lower limit for the sell Limit, can't be set lower
    uint16 public constant MinSellLimitDivider=2000;
    //Sellers get locked for sellLockTime so they can't dump repeatedly
    uint16 public constant MaxSellLockTime= 2 hours;
    //TODO: Change to 7 days
    //The time Liquidity gets locked at start and prolonged once it gets released
    uint256 private constant DefaultLiquidityLockTime=1 hours;
    //The Team Wallet is a Multisig wallet that reqires 3 signatures for each action
    address public TeamWallet=0x921Ff3A7A6A3cbdF3332781FcE03d2f4991c7868;

    address private constant burnAddress=       0x000000000000000000000000000000000000dEaD;
    address private constant lotteryAddress=    0x7777777777777777777777777777777777777777;
    //variables that track balanceLimit and sellLimit,
    //can be updated based on circulating supply and Sell- and BalanceLimitDividers
    uint256 private _circulatingSupply;
    uint256 private  balanceLimit;
    uint256 private  sellLimit;

    //Limits max tax, only gets applied for tax changes, doesn't affect inital Tax
    uint8 public constant MaxTax=20;
    
    //Tracks the current Taxes, different Taxes can be applied for buy/sell/transfer
    //Taxes can never exceed MaxTax
    uint8 private _buyTax;
    uint8 private _sellTax;
    uint8 private _transferTax;
    
    //BotProtection values
    bool private _botProtection;
    uint8 constant BotMaxTax=99;
    uint256 constant BotTaxTime=10 minutes;
    uint256 constant WLTaxTime=4 minutes;
    uint256 public launchTimestamp;
    
    
    //The shares of the specific Taxes, always needs to equal 100%
    uint8 private _burnTax;
    uint8 private _liquidityTax;
    uint8 private _stakingTax;
    //The shares of the staking Tax that get used for Marketing/lotterySplit
    uint8 public marketingShare=50;
    //Lottery share is used for Lottery draws, addresses can buy lottery tickets for Token
    uint8 public LotteryShare=10;
    
    //_pancakePairAddress is also equal to the liquidity token address
    //LP token are locked in the contract
    address private _pancakePairAddress; 
    IPancakeRouter02 private  _pancakeRouter; 
    
    //TODO: Change to Mainnet
    //TestNet
    address private constant PancakeRouter=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //MainNet
    //address private constant PancakeRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    //modifier for functions only the team can call
    modifier onlyTeam() {
        require(_isTeam(msg.sender), "Caller not in Team");
        _;
    }
    //Checks if address is in Team, is needed to give Team access even if contract is renounced
    //Team doesn't have access to critical Functions that could turn this into a Rugpull(Exept liquidity unlocks)
    function _isTeam(address addr) private view returns (bool){
        return addr==owner()||addr==TeamWallet;
    }
    function TeamChangeTeamWallet(address newTeamWallet) public onlyTeam{
        TeamWallet=newTeamWallet;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Constructor///////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    constructor () {
        // Pancake Router
        _pancakeRouter = IPancakeRouter02(PancakeRouter);
        //Creates a Pancake Pair
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        _automatedMarketMakers.add(_pancakePairAddress);
        //excludes Pancake Router, pair, contract and burn address from staking
        _excludedFromStaking.add(address(_pancakeRouter));
        _excludedFromStaking.add(_pancakePairAddress);
        _excludedFromStaking.add(address(this));
        _excludedFromStaking.add(burnAddress);
        //contract gets 100% of the supply to create LP
        _addToken(address(this),InitialSupply);
        emit Transfer(address(0), address(this), InitialSupply);
        
        //Sets Buy/Sell limits to min
        balanceLimit=InitialSupply/BalanceLimitDivider;
        sellLimit=InitialSupply/MinSellLimitDivider;

       //Sets sellLockTime to be max by default
        sellLockTime=MaxSellLockTime;
        //buy tax will be affected by Bot protection at start
        _buyTax=10;
        _sellTax=20;
        //Transfers get heavily taxed at start, to avoid transfers from whitelisted wallets
        _transferTax=50;
        //95% of the tax goes to liquidity, 5% gets burned
        _burnTax=5;
        _liquidityTax=95;
        _stakingTax=0;
        //Team wallet deployer and contract are excluded from Taxes
        _excluded.add(TeamWallet);
        _excluded.add(msg.sender);
        _excluded.add(address(this));
    }

    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Transfer functionality////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    uint8 LiquifyTreshold=50;
    address oneTimeExcluded;
    //picks the transfer function
    function _transfer(address sender, address recipient, uint256 amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        //If recipient is burnAddress, token will be sacrificed, resulting in 2x rewards, but burned token
        if(recipient==burnAddress){
            _sacrifice(sender,amount);
            return;
        }
        //If recipient is lotteryAddress, token will be used to buy lottery tickets
        if(recipient==lotteryAddress){
            _buyLotteryTickets(sender,amount);
            return;
        }
        
        bool isExcluded=_excluded.contains(sender) || _excluded.contains(recipient);
        //one time excluded (compound) transfer without limits
        if(oneTimeExcluded==recipient){
            isExcluded=true;
            oneTimeExcluded=address(0);
        }

        //excluded adresses are transfering tax and lock free
        if(isExcluded){
            _feelessTransfer(sender, recipient, amount);
            return;
        }
        //once trading is enabled, it can't be turned off again
        require(tradingEnabled,"trading not yet enabled"); 
        _regularTransfer(sender,recipient,amount);
    }
    //applies taxes, checks for limits, locks generates autoLP and stakingBNB, and autostakes
    function _regularTransfer(address sender, address recipient, uint256 amount) private{
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "exceeds balance");
        //checks all registered AMM if it's a buy or sell.
        bool isBuy=_automatedMarketMakers.contains(sender);
        bool isSell=_automatedMarketMakers.contains(recipient);
        uint8 tax;
        if(isSell){
            if(!_excludedFromLocks.contains(sender)&&!sellLockDisabled){
                //If seller sold less than sellLockTime(2h) ago, sell is declined, can be disabled by Team         
                require(_sellLock[sender]<=block.timestamp,"sellLock");
                //Sets the time sellers get locked(2 hours by default)
                _sellLock[sender]=block.timestamp+sellLockTime;
                //Sells can't exceed the sell limit(50.000 Tokens at start, can be updated to circulating supply)
                require(amount<=sellLimit,"Dump");
            }

            tax=_getTaxWithBonus(sender,_sellTax);

        } else if(isBuy){
            //Checks If the recipient balance(excluding Taxes) would exceed Balance Limit
            require(_excludedFromLocks.contains(recipient)||(recipientBalance+amount<=balanceLimit),"whale");
            tax=_getBuyTax(recipient);

        } else {//Transfer
            //withdraws BNB when sending less or equal to 1 Token
            //that way you can withdraw without connecting to any dApp.
            if(amount<=10**(_decimals)&&getDividents(sender)>0) _claimBNBTo(sender,sender,getDividents(sender));
            //Checks If the recipient balance(excluding Taxes) would exceed Balance Limit
            require(_excludedFromLocks.contains(recipient)||recipientBalance+amount<=balanceLimit,"whale");
            tax=_getTaxWithBonus(sender,_transferTax);

        }     
        
        //Swapping AutoLP and MarketingBNB is only possible if sender is not pancake pair, 
        //if its not manually disabled, if its not already swapping
        if((sender!=_pancakePairAddress)&&(!swapAndLiquifyDisabled)&&(!_isSwappingContractModifier))
            _swapContractToken(LiquifyTreshold,false);
            
        _transferTaxed(sender,recipient,amount,tax);
    }
    
    function _transferTaxed(address sender, address recipient, uint256 amount, uint8 tax) private{
        uint256 totalTaxedToken=_calculateFee(amount, tax, 100);
        uint256 tokenToBeBurnt=_calculateFee(amount, tax, _burnTax);
        uint256 taxedAmount=amount-totalTaxedToken;
        //Removes token and handles staking
        _removeToken(sender,amount);
        //Adds the taxed tokens -burnedToken to the contract
        _addToken(address(this), (totalTaxedToken-tokenToBeBurnt));
        //Adds token and handles staking
        _addToken(recipient, taxedAmount);
        emit Transfer(sender,recipient,taxedAmount);
    }
    //Feeless transfer only transfers and autostakes
    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "exceeds balance");
        //Removes token and handles staking
        _removeToken(sender,amount);
        //Adds token and handles staking
        _addToken(recipient, amount);
        
        emit Transfer(sender,recipient,amount);

    }
    //gets the tax for buying, tax is different during the bot protection
    function _getBuyTax(address recipient) private returns (uint8){
        if(!_botProtection) return _getTaxWithBonus(recipient,_buyTax);
        bool isWhitelisted=_whiteList.contains(recipient);
        uint256 duration;
        //Whitelist has a shorter Bot Protection Time
        if(isWhitelisted) duration=WLTaxTime;
        else duration=BotTaxTime;
        uint8 Tax;
        if(block.timestamp>launchTimestamp+duration){
            Tax=_buyTax;
            if(!isWhitelisted){
                _burnTax=25;
                _liquidityTax=25;
                _stakingTax=50;
                _botProtection=false;
            }
        }
        else Tax=_getBotTax(duration);
        return _getTaxWithBonus(recipient, Tax);

    }
    
    function _getBotTax(uint256 duration) private view returns (uint8){
        uint256 timeSinceLaunch=block.timestamp-launchTimestamp;
        return uint8(BotMaxTax-((BotMaxTax-_buyTax)*timeSinceLaunch/duration));
    }
    //Gets the promotion Bonus if enough promotion Token are held
    function _getTaxWithBonus(address bonusFor, uint8 tax) private view returns(uint8){
        if(_isEligibleForPromotionBonus(bonusFor)){
            if(tax<=promotionTaxBonus) return 0;
            return tax-promotionTaxBonus;
        }
        return tax;
    }
    function _isEligibleForPromotionBonus(address bonusFor)private view returns(bool){
        if(address(promotionToken) == address(0)) return false;
        uint256 tokenBalance;
        //tries to get the balance of the address the bonus is for, catches possible errors that could make the token untradeable
        try promotionToken.balanceOf(bonusFor) returns (uint256 promotionTokenBalance){ 
            tokenBalance=promotionTokenBalance;
        }catch{return false;}
        
        return (tokenBalance>=promotionMinHold);
    }
    
    //Calculates the token that should be taxed
    function _calculateFee(uint256 amount, uint8 tax, uint8 taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / 10000;
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //BNB Autostake/////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////// 
    //Autostake uses the balances of each holder to redistribute auto generated BNB.
    //Each transaction _addToken and _removeToken gets called for the transaction amount
    //Withdraw can be used for any holder to withdraw at any time, like true Staking,
    //so unlike MRAT clones you can leave and forget your Token and claim after a while
    
    //lock for the withdraw, only one withdraw can happen at a time
    bool private _isWithdrawing;
    //Multiplier to add some accuracy to profitPerShare
    uint256 private constant DistributionMultiplier = 2**64;
    //profit for each share a holder holds, a share equals a decimal.
    uint256 public profitPerShare;
    //totalShares in circulation +InitialSupply to avoid underflow 
    //getTotalShares returns the correct amount
    uint256 private _totalShares=InitialSupply;
    //the total reward distributed through staking, for tracking purposes
    uint256 public totalStakingReward;
    //the total payout through staking, for tracking purposes
    uint256 public totalPayouts;
    //balance that is claimable by the team
    uint256 public marketingBalance;
    //The current Lottery Balance
    uint256 public lotteryBNB;
     mapping(address => uint256) private additionalShares;   
    //Mapping of the already paid out(or missed) shares of each staker
    mapping(address => uint256) private alreadyPaidShares;
    //Mapping of shares that are reserved for payout
    mapping(address => uint256) private toBePaid;
    
    uint256 public sacrificedToken;
    bool private isSacrificing;
    event OnSacrifice(uint256 amount, address sender);
    //Sacrifices BurningMoon, BurningMoon get burned, nothing remains exept 2x rewards for the one bringing the sacrifice
    function _sacrifice(address account,uint256 amount) private{
        require(!_excludedFromStaking.contains(account), "Excluded!");
        require(amount<=_balances[account]);
        require(!isSacrificing);
        isSacrificing=true;
        //Removes token and burns them
        _removeToken(account, amount);
        sacrificedToken+=amount;
        //The new shares will be 2x the burned shares
        uint256 newShares=amount*2;
        _totalShares+=newShares;

        additionalShares[account]+=newShares;
        //Resets the paid mapping to the new amount
        alreadyPaidShares[account] = profitPerShare * getShares(account);
        emit Transfer(account,burnAddress,amount);
        emit OnSacrifice(newShares, account);
        isSacrificing=false;
    }
    
    

    function Sacrifice(uint256 amount) public{
        _sacrifice(msg.sender,amount);
    }
    event OnTransferSacrifice(uint256 amount, address sender,address recipient);
    function TransferSacrifice(address target, uint256 amount) public{
        require(!_excludedFromStaking.contains(target)&&!_excludedFromStaking.contains(msg.sender),
        "Excluded!");
        uint256 senderShares=additionalShares[msg.sender];
        require(amount<=senderShares,"exceeds shares");
        require(!isSacrificing);
        isSacrificing=true;
        
        //Handles the removal of the shares from the sender
        uint256 paymentSender=_newDividentsOf(msg.sender);
        additionalShares[msg.sender]=senderShares-amount;
        alreadyPaidShares[msg.sender] = profitPerShare * getShares(msg.sender);
        toBePaid[msg.sender]+=paymentSender;
        
        //Handles the addition of the shares to the recipient
        uint256 paymentReceiver=_newDividentsOf(target);
        uint256 newAdditionalShares=additionalShares[target]+amount;
        alreadyPaidShares[target] = profitPerShare * (_balances[target]+newAdditionalShares);
        toBePaid[target]+=paymentReceiver;
        additionalShares[target]=newAdditionalShares;
        
        emit OnTransferSacrifice(amount, msg.sender, target);
        isSacrificing=false;
    }

    //gets shares of an address, returns 0 if excluded
    function getShares(address addr) private view returns(uint256){
        if(_excludedFromStaking.contains(addr)) return 0;
        return (_balances[addr]+additionalShares[addr]);
    }

    //Total shares equals circulating supply minus excluded Balances
    function _getTotalShares() public view returns (uint256){
        return _totalShares-InitialSupply;
    }

    //adds Token to balances, adds new BNB to the toBePaid mapping and resets staking
    function _addToken(address addr, uint256 amount) private {
        //the amount of token after transfer
        uint256 newAmount=_balances[addr]+amount;
        _circulatingSupply+=amount;
        //if excluded, don't change staking amount
        if(_excludedFromStaking.contains(addr)){
           _balances[addr]=newAmount;
           return;
        }
        _totalShares+=amount;
        //gets the payout before the change
        uint256 payment=_newDividentsOf(addr);
        //resets dividents to 0 for newAmount
        alreadyPaidShares[addr] = profitPerShare * (newAmount+additionalShares[addr]);
        //adds dividents to the toBePaid mapping
        toBePaid[addr]+=payment; 
        //sets newBalance
        _balances[addr]=newAmount;


    }
    
    //removes Token, adds BNB to the toBePaid mapping and resets staking
    function _removeToken(address addr, uint256 amount) private {
        //the amount of token after transfer
        uint256 newAmount=_balances[addr]-amount;
        _circulatingSupply-=amount;
        if(_excludedFromStaking.contains(addr)){
           _balances[addr]=newAmount;
           return;
        }

        //gets the payout before the change
        uint256 payment=_newDividentsOf(addr);
        //sets newBalance
        _balances[addr]=newAmount;
        //resets dividents to 0 for newAmount
        alreadyPaidShares[addr] = profitPerShare * getShares(addr);
        //adds dividents to the toBePaid mapping
        toBePaid[addr]+=payment; 
        _totalShares-=amount;
    }
    
    
    //gets the dividents of a staker that aren't in the toBePaid mapping 
    function _newDividentsOf(address staker) private view returns (uint256) {
        uint256 fullPayout = profitPerShare * getShares(staker);
        //if excluded from staking or some error return 0
        if(fullPayout<=alreadyPaidShares[staker]) return 0;
        return (fullPayout - alreadyPaidShares[staker]) / DistributionMultiplier;
    }
    
    //distributes bnb between marketing share and dividents 
    function _distributeStake(uint256 AmountWei) private {
        // Deduct marketing Tax
        if(AmountWei==0) return;
        uint256 marketingSplit = (AmountWei * marketingShare) / 100;
        uint256 lotterySplit = (AmountWei*LotteryShare) / 100;
        uint256 amount = AmountWei - (marketingSplit+lotterySplit);

        lotteryBNB+=lotterySplit;
        marketingBalance+=marketingSplit;
       

        totalStakingReward += amount;
        uint256 totalShares=_getTotalShares();
        //when there are 0 shares, add everything to marketing budget
        if (totalShares == 0) {
            marketingBalance += amount;
        }else{
            //Increases profit per share based on current total shares
            profitPerShare += ((amount * DistributionMultiplier) / totalShares);
        }
    }
    //Substracts the amount from dividents, fails if amount exceeds dividents
    function _substractDividents(address addr,uint256 amount) private{
        if(amount==0) return;
        require(amount<=getDividents(addr),"exceeds divident");

        if(_excludedFromStaking.contains(addr)){
            //if excluded just withdraw remaining toBePaid BNB
            toBePaid[addr]-=amount;
        }
        else{
            uint256 newAmount=_newDividentsOf(addr);
            //sets payout mapping to current amount
            alreadyPaidShares[addr] = profitPerShare * getShares(addr);
            //the amount to be paid 
            toBePaid[addr]+=newAmount;
            toBePaid[addr]-=amount;
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Claim Functions///////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////// 

    //PromotionToken
    IBEP20 public promotionToken;
    //Boost BNB are added to the dividents based on the Boost Percentage
    uint256 public BoostBNB;
    uint8 public promotionBNBBoostPercentage;
    //Boost Token are sent after transfer, based on the Percentage and the amount received
    uint8 public promotionTokenBoostPercentage;
    //promotion can be delayed
    uint256 private promotionStartTimestamp;
    //Allows to claim token via the contract. this makes it possible To
    //make special Rules for the Promotion token
    bool public ClaimPromotionTokenViaContract;
    //Holders of the promotion token get a Tax bonus
    uint8 public promotionTaxBonus;
    uint256 public promotionMinHold;
    //Sets new promotion Token
    function TeamSetPromotionToken (
        address token, 
        uint8 BNBboostPercentage,
        uint8 TokenBoostPercentage, 
        bool claimViaContract, 
        uint256 secondsUntilStart,
        uint8 TaxBonus,
        uint256 MinHold) public onlyTeam{
        require(token!=address(this)&&token!=_pancakePairAddress,"Invalid token");
        promotionToken=IBEP20(token);
        //check if token implements balanceOf
        promotionToken.balanceOf(address(this));
        
        promotionBNBBoostPercentage=BNBboostPercentage;
        promotionTokenBoostPercentage=TokenBoostPercentage;
        //claim via contract makes it possible to make special offers for the contract
        ClaimPromotionTokenViaContract=claimViaContract;
        promotionStartTimestamp=block.timestamp+secondsUntilStart;
        promotionMinHold=MinHold;
        promotionTaxBonus=TaxBonus;
    }
    event OnClaimPromotionToken(address AddressTo, uint256 amount);
    //Claims the promotion Token with 100% of the dividents
    function ClaimPromotionToken() public payable{
        ClaimPromotionToken(getDividents(msg.sender));
    }
    //Claims the promotion token, boost and special rules Apply to promotion token
    //No boost does apply to payable amount
    bool private _isClaimingPromotionToken;
    function ClaimPromotionToken(uint256 amountWei) public payable{
        require(!_isClaimingPromotionToken,"already Claiming Token");
        _isClaimingPromotionToken=true;
        uint256 totalAmount=amountWei+msg.value;
        require(totalAmount>0,"Nothing to claim");
        //Gets the token and the initial balance
        IBEP20 tokenToClaim=IBEP20(promotionToken);
        uint256 initialBalance=tokenToClaim.balanceOf(msg.sender);
        //Claims token using dividents
        if(amountWei>0){
            //only boosts the amount, not the payable amount
            uint256 boost=amountWei*promotionBNBBoostPercentage/100;
            //if boost exceeds boost funds, clamp the boost
            if(boost>BoostBNB) boost=BoostBNB;
            BoostBNB-=boost;
            
            if(ClaimPromotionTokenViaContract){
                _claimTokenViaContract(msg.sender, address(promotionToken), amountWei,boost);
            }else _claimToken(msg.sender, address(promotionToken), amountWei,boost);
            
            //Apply the tokenBoost
            uint256 contractBalance=tokenToClaim.balanceOf(address(this));
            if(promotionTokenBoostPercentage>0&&contractBalance>0)
            {
                //the actual amount of claimed token
                uint256 claimedToken=tokenToClaim.balanceOf(msg.sender)-initialBalance;
                //calculates the tokenBoost
                uint256 tokenBoost=claimedToken*promotionTokenBoostPercentage/100;
                if(tokenBoost>contractBalance)tokenBoost=contractBalance;
                //transfers the tokenBoost
                tokenToClaim.transfer(msg.sender,tokenBoost);   
            }
        }
        //claims promotion Token with the payable amount, no boost applies
        if(msg.value>0)_claimToken(msg.sender,address(promotionToken),0,msg.value);
        
        //gets the total claimed token and emits the event
        uint256 totalClaimed=tokenToClaim.balanceOf(msg.sender)-initialBalance;
        emit OnClaimPromotionToken(msg.sender,totalClaimed);
        _isClaimingPromotionToken=false;
    }
    
    event OnCompound(address AddressTo, uint256 amount);
    //Compounds BNB to buy BM, Compound is tax free
    function Compound() public{
        uint256 initialBalance=_balances[msg.sender];
        //Compound is tax free and can exceed max hold
        oneTimeExcluded=msg.sender;
        _claimToken(msg.sender, address(this), getDividents(msg.sender),0);
        uint256 claimedToken=_balances[msg.sender]-initialBalance;
        emit OnCompound(msg.sender,claimedToken);
    }
    
    event OnClaimBNB(address AddressFrom,address AddressTo, uint256 amount);
    function ClaimBNB() public{
        _claimBNBTo(msg.sender,msg.sender,getDividents(msg.sender));
    }
    function ClaimBNBTo(address to) public{
         _claimBNBTo(msg.sender,to,getDividents(msg.sender));
    }

    event OnClaimToken(address AddressTo,address Token, uint256 amount);
    //Claims any token can add BNB to purchase more
    function ClaimAnyToken(address token) public payable{
        ClaimAnyToken(token,getDividents(msg.sender));
    }
    function ClaimAnyToken(address tokenAddress,uint256 amountWei) public payable{
        IBEP20 token=IBEP20(tokenAddress);
        uint256 initialBalance=token.balanceOf(msg.sender);
        _claimToken(msg.sender, tokenAddress,amountWei,msg.value);
        uint256 claimedToken=token.balanceOf(msg.sender)-initialBalance;
        emit OnClaimToken(msg.sender,tokenAddress,claimedToken);
    }
    
    //Helper functions to claim Token or BNB
    //claims the amount of BNB from "from" and withdraws them "to"
    function _claimBNBTo(address from, address to,uint256 amountWei) private{
        require(!_isWithdrawing,"Withdrawing");
        require(amountWei!=0,"Amount=0");    
        _isWithdrawing=true;
        //Substracts the amount from the dividents
        _substractDividents(from, amountWei);
        totalPayouts+=amountWei;
        (bool sent,) =to.call{value: (amountWei)}("");
        require(sent,"withdraw failed");
        _isWithdrawing=false;
        emit OnClaimBNB(from,to,amountWei);
    }
 
    //claims any token and sends it to addr for the amount in BNB
    function _claimToken(address addr, address token, uint256 amountWei,uint256 boostWei) private{
        require(!_isWithdrawing,"Withdrawing");
        require(amountWei!=0||boostWei!=0,"Amount=0");        
        _isWithdrawing=true;
        //Substracts the amount from the dividents
        _substractDividents(addr, amountWei);
        uint256 totalAmount=amountWei+boostWei;
        totalPayouts+=amountWei;
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH(); //BNB
        path[1] = token;  
        
        //purchases token and sends them to the target address
        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: totalAmount}(
        0,
        path,
        addr,
        block.timestamp);
        
        _isWithdrawing=false;
    }

    //Claims token via the contract, enables to make special offers for the contract
    function _claimTokenViaContract(address addr, address token, uint256 amountWei,uint256 boostWei) private{
        require(!_isWithdrawing,"Withdrawing");
        require(amountWei!=0||boostWei!=0,"Amount=0");      
        _isWithdrawing=true;
        //Substracts the amount from the dividents
        _substractDividents(addr, amountWei);
        //total amount is amount+boost
        uint256 totalAmount=amountWei+boostWei;
        totalPayouts+=amountWei;
        
        //Purchases token and sends them to the contract
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH(); //BNB
        path[1] = token;  
        IBEP20 claimToken=IBEP20(token);
        uint256 initialBalance=claimToken.balanceOf(address(this));
        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: totalAmount}(
        0,
        path,
        address(this),
        block.timestamp);
        //newBalance captures only new token
        uint256 newBalance=claimToken.balanceOf(address(this))-initialBalance;
        //transfers all new token from the contract to the address
        claimToken.transfer(addr, newBalance);
        _isWithdrawing=false;
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Lottery///////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    uint256 public lotteryTicketPrice=100*(10**_decimals); //StartPrize Lottery 100 token
    //The Lottery tickets array, each address stored is a ticket
    address[] private lotteryTickets;
    //The Amount of Lottery tickets in the current round
    uint256 public LotteryParticipants;
    
    event OnBuyLotteryTickets(uint256 FirstTicketID, uint256 LastTicketID, address account);
    //Buys entry to the Lottery, burns token
    function _buyLotteryTickets(address account,uint256 token) private{
        uint256 tickets=token/lotteryTicketPrice;
        uint256 totalPrice=tickets*lotteryTicketPrice;
        require(_balances[account]>=totalPrice,"exceeds balance");
        require(tickets>0,"<1 ticket");
        uint256 FirstTicketID=LotteryParticipants;
        //Removes the token from the sender
        _removeToken(account,totalPrice);
        //Adds tickets to the tickets array
        for(uint256 i=0; i<tickets; i++){
            if(lotteryTickets.length>LotteryParticipants)
                lotteryTickets[LotteryParticipants]=account;
            else lotteryTickets.push(account);    
            LotteryParticipants++;
        }        
        emit Transfer(account,lotteryAddress,totalPrice);
        emit  OnBuyLotteryTickets(FirstTicketID,LotteryParticipants-1,account);
    }
    function BuyLotteryTickets(uint256 token) public{
        _buyLotteryTickets(msg.sender,token);
    }
    
    function _getPseudoRandomNumber(uint256 modulo) private view returns(uint256) {
        //uses WBNB-Balance to add a bit unpredictability
        uint256 WBNBBalance = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).balance;
        
        //generates a PseudoRandomNumber
        uint256 randomResult = uint256(keccak256(abi.encodePacked(
            _circulatingSupply +
            _balances[_pancakePairAddress] +
            WBNBBalance + 
            block.timestamp + 
            block.difficulty +
            block.gaslimit
            ))) % modulo;
            
        return randomResult;    
    }
    event DrawLotteryWinner(address winner, uint256 amount);
    function TeamDrawLotteryWinner(uint256 newLotteryTicketPrice) public onlyTeam{
        require(LotteryParticipants>0);
        uint256 prize=lotteryBNB;
        lotteryBNB=0;
        uint256 winner=_getPseudoRandomNumber(LotteryParticipants);
        address winnerAddress=lotteryTickets[winner];
        LotteryParticipants=0;
        lotteryTicketPrice=newLotteryTicketPrice;

       (bool sent,) = winnerAddress.call{value: (prize)}("");
        require(sent);
        emit DrawLotteryWinner(winnerAddress, prize);
    }

    function getLotteryTicketHolder(uint256 TicketID) public view returns(address){
        require(TicketID<LotteryParticipants,"Doesn't exist");
        return lotteryTickets[TicketID];
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Swap Contract Tokens//////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //tracks auto generated BNB, useful for ticker etc
    uint256 public totalLPBNB;
    //Locks the swap if already swapping
    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    function _swapContractToken(uint16 permilleOfPancake,bool ignoreLimits) private lockTheSwap{
        uint256 contractBalance=_balances[address(this)];
        uint16 totalTax=_liquidityTax+_stakingTax;
        if(totalTax==0) return;

        uint256 tokenToSwap=_balances[_pancakePairAddress]*permilleOfPancake/1000;
        if(tokenToSwap>sellLimit&&!ignoreLimits) tokenToSwap=sellLimit;
        
        //only swap if contractBalance is larger than tokenToSwap, and totalTax is unequal to 0
        bool NotEnoughToken=contractBalance<tokenToSwap;
        if(NotEnoughToken){
            if(ignoreLimits)
                tokenToSwap=contractBalance;
            else return;
        }

        //splits the token in TokenForLiquidity and tokenForMarketing
        uint256 tokenForLiquidity=(tokenToSwap*_liquidityTax)/totalTax;
        uint256 tokenForMarketing= tokenToSwap-tokenForLiquidity;

        //splits tokenForLiquidity in 2 halves
        uint256 liqToken=tokenForLiquidity/2;
        uint256 liqBNBToken=tokenForLiquidity-liqToken;

        //swaps marktetingToken and the liquidity token half for BNB
        uint256 swapToken=liqBNBToken+tokenForMarketing;
        //Gets the initial BNB balance, so swap won't touch any staked BNB
        uint256 initialBNBBalance = address(this).balance;
        _swapTokenForBNB(swapToken);
        uint256 newBNB=(address(this).balance - initialBNBBalance);
        //calculates the amount of BNB belonging to the LP-Pair and converts them to LP
        uint256 liqBNB = (newBNB*liqBNBToken)/swapToken;
        _addLiquidity(liqToken, liqBNB);
        //Get the BNB balance after LP generation to get the
        //exact amount of token left for Staking, as LP generation leaves some BNB untouched
        uint256 distributeBNB=(address(this).balance - initialBNBBalance);
        //distributes remaining BNB between stakers and Marketing
        _distributeStake(distributeBNB);
    }
    //swaps tokens on the contract for BNB
    function _swapTokenForBNB(uint256 amount) private {
        _approve(address(this), address(_pancakeRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();

        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    //Adds Liquidity directly to the contract where LP are locked(unlike safemoon forks, that transfer it to the owner)
    function _addLiquidity(uint256 tokenamount, uint256 bnbamount) private {
        totalLPBNB+=bnbamount;
        _approve(address(this), address(_pancakeRouter), tokenamount);
        _pancakeRouter.addLiquidityETH{value: bnbamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //public functions /////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////// 
    function getLiquidityLockSeconds() public view returns (uint256 LockedSeconds){
        if(block.timestamp<_liquidityUnlockTime)
            return _liquidityUnlockTime-block.timestamp;
        return 0;
    }
    
    function getPromotionStartTimeInSeconds() public view returns (uint256){
        if(block.timestamp<promotionStartTimestamp)
            return promotionStartTimestamp-block.timestamp;
        return 0;
    }
    
    function getBurnedTokens() public view returns(uint256){
        return (InitialSupply-_circulatingSupply);
    }

    function getTaxes() public view returns(
    uint256 buyTax, 
    uint256 sellTax, 
    uint256 transferTax, 
    uint8 whitelistBuyTax,
    uint256 burnTax,
    uint256 liquidityTax,
    uint256 stakingTax){
            if(block.timestamp>launchTimestamp+BotTaxTime)
            buyTax=_buyTax;
            else buyTax=_getBotTax(BotTaxTime);

            if(block.timestamp>launchTimestamp+WLTaxTime)
            whitelistBuyTax=_buyTax;
            else whitelistBuyTax=_getBotTax(WLTaxTime);

            sellTax=_sellTax;
            transferTax=_transferTax;

            burnTax=_burnTax;
            liquidityTax=_liquidityTax;
            stakingTax=_stakingTax;


    }
    
    function getStatus(address AddressToCheck) public view returns(
        bool Whitelisted, 
        bool Excluded, 
        bool ExcludedFromLock, 
        bool ExcludedFromStaking, 
        uint256 SellLock,
        bool eligibleForPromotionBonus,
        uint256 shares){
        uint256 lockTime=_sellLock[AddressToCheck];
       if(lockTime<=block.timestamp) lockTime=0;
       else lockTime-=block.timestamp;
       
        return(
            _whiteList.contains(AddressToCheck),
            _excluded.contains(AddressToCheck),
            _excludedFromLocks.contains(AddressToCheck),
            _excludedFromStaking.contains(AddressToCheck),
            lockTime,
            _isEligibleForPromotionBonus(AddressToCheck),
            getShares(AddressToCheck)
            );
    }
    
    //Returns the not paid out dividents of an address in wei
    function getDividents(address addr) public view returns (uint256){
        return _newDividentsOf(addr)+toBePaid[addr];
    }
    
    //Adds BNB to the contract to either boost the Promotion Token, or add to stake, everyone can add Funds
    function addFunds(bool boost, bool stake)public payable{
        if(boost) BoostBNB+=msg.value;
        else if(stake) _distributeStake(msg.value);
        else marketingBalance+=msg.value;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Settings//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    bool public sellLockDisabled;
    uint256 public sellLockTime;
    bool public swapAndLiquifyDisabled;
    event  OnAddAMM(address AMM,bool Add);
    function TeamAddOrRemoveAMM(address AMMPairAddress, bool Add) public onlyTeam{
        require(AMMPairAddress!=_pancakePairAddress,"can't change Pancake");
        if(Add){
            if(!_excludedFromStaking.contains(AMMPairAddress))
                TeamSetStakingExcluded(AMMPairAddress, true);
            _automatedMarketMakers.add(AMMPairAddress);
        } 
        else{
            _automatedMarketMakers.remove(AMMPairAddress);
        }
        emit OnAddAMM(AMMPairAddress, Add);
    }
    event  OnChangeLiquifyTreshold(uint8 TresholdPermille);
    function TeamSetLiquifyTreshold(uint8 TresholdPermille) public onlyTeam{
        require(TresholdPermille<=50,"Max 50");
        LiquifyTreshold=TresholdPermille;
        emit OnChangeLiquifyTreshold(TresholdPermille);
    }


    function TeamWithdrawMarketingBNB() public onlyTeam{
        TeamWithdrawMarketingBNB(marketingBalance);
    } 
    function TeamWithdrawMarketingBNB(uint256 amount) public onlyTeam{
        require(amount<=marketingBalance);
        marketingBalance-=amount;
        (bool sent,) =TeamWallet.call{value: (amount)}("");
        require(sent,"withdraw failed");
    } 

    event  OnSwitchSwapAndLiquify(bool Disabled);
    //switches autoLiquidity and marketing BNB generation during transfers
    function TeamDisableSwapAndLiquify(bool disabled) public onlyTeam{
        swapAndLiquifyDisabled=disabled;
        emit OnSwitchSwapAndLiquify(disabled);
    }
    event OnSwitchSellLock(bool disabled);
    //Disables the timeLock after selling for everyone
    function TeamDisableSellLock(bool disabled) public onlyTeam{
        sellLockDisabled=disabled;
        emit OnSwitchSellLock(disabled);
    }
    event OnChangeSellLockTime(uint256 newSellLockTime);
    //Sets SellLockTime, needs to be lower than MaxSellLockTime
    function TeamSetSellLockTime(uint256 sellLockSeconds)public onlyTeam{
        require(sellLockSeconds<=MaxSellLockTime,"Sell Lock time too high");
        sellLockTime=sellLockSeconds;
        emit OnChangeSellLockTime(sellLockSeconds);
    } 
    event OnChangeTaxes(uint8 burnTaxes, uint8 liquidityTaxes, uint8 stakingTaxes,uint8 buyTax, uint8 sellTax, uint8 transferTax, uint8 marketing,uint8 lottery);
    //Sets Taxes, is limited by MaxTax(20%) to make it impossible to create honeypot
    function TeamSetTaxes(uint8 burnTaxes, uint8 liquidityTaxes, uint8 stakingTaxes,uint8 buyTax, uint8 sellTax, uint8 transferTax, uint8 marketing,uint8 lottery) public onlyTeam{
        uint8 totalTax=burnTaxes+liquidityTaxes+stakingTaxes;
        require(totalTax==100, "burn+liq+marketing needs to equal 100%");
        require(buyTax<=MaxTax&&sellTax<=MaxTax&&transferTax<=MaxTax,"taxes higher than max tax");
        require(marketing+lottery<=50,"staking share needs to be at least 50%"); 
    
        marketingShare=marketing;
        LotteryShare=lottery;
    
        _burnTax=burnTaxes;
        _liquidityTax=liquidityTaxes;
        _stakingTax=stakingTaxes;
        
        _buyTax=buyTax;
        _sellTax=sellTax;
        _transferTax=transferTax;
        emit OnChangeTaxes(burnTaxes, liquidityTaxes, stakingTaxes, buyTax, sellTax,  transferTax, marketing, lottery);
    }

    //manually converts contract token to LP and staking BNB
    function TeamTriggerLiquify(uint16 pancakePermille, bool ignoreLimits) public onlyTeam{
        _swapContractToken(pancakePermille,ignoreLimits);
    }
    
    event OnExcludeFromStaking(address addr, bool exclude);
    //Excludes account from Staking
    function TeamSetStakingExcluded(address addr, bool exclude) public onlyTeam{
        uint256 shares;
        if(exclude){
            require(!_excludedFromStaking.contains(addr));
            uint256 newDividents=_newDividentsOf(addr);
            shares=getShares(addr);
            _excludedFromStaking.add(addr); 
            _totalShares-=shares;
            alreadyPaidShares[addr]=shares*profitPerShare;
            toBePaid[addr]+=newDividents;

        } else _includeToStaking(addr);
        emit OnExcludeFromStaking(addr, exclude);
    }    

    //function to Include own account to staking, should it be excluded
    function IncludeMeToStaking() public{
        _includeToStaking(msg.sender);
    }
    function _includeToStaking(address addr) private{
        require(_excludedFromStaking.contains(addr));
        _excludedFromStaking.remove(addr);
        uint256 shares=getShares(addr);
        _totalShares+=shares;
        //sets alreadyPaidShares to the current amount
        alreadyPaidShares[addr]=shares*profitPerShare;
    }
    event OnExclude(address addr, bool exclude);
    //Exclude/Include account from fees and locks (eg. CEX)
    function TeamTeamSetExcludedStatus(address account,bool excluded) public onlyTeam {
        if(excluded){
            _excluded.add(account);
        }
        else{
            require(account!=address(this),"can't Include the contract");
            _excluded.remove(account);
        }

        emit OnExclude(account, excluded);
    }
    event OnExcludeFromSellLock(address addr, bool exclude);
    //Exclude/Include account from fees (eg. CEX)
    function TeamSetExcludedFromSellLock(address account,bool excluded) public onlyTeam {
        if(excluded) _excludedFromLocks.add(account);
        else _excludedFromLocks.remove(account);
       emit OnExcludeFromSellLock(account, excluded);
    }
    event OnChangeLimits(uint256 newBalanceLimit, uint256 newSellLimit);
     //Limits need to be at least target, to avoid setting value to 0(avoid potential Honeypot)
    function TeamChangeLimits(uint256 newBalanceLimit, uint256 newSellLimit) public onlyTeam{

        require((newBalanceLimit>=_circulatingSupply/BalanceLimitDivider)
            &&(newSellLimit>=_circulatingSupply/MinSellLimitDivider), 
        "new Values needs to be at least target");
        balanceLimit = newBalanceLimit;
        sellLimit = newSellLimit;     
        emit OnChangeLimits(newBalanceLimit, newSellLimit);
    }
    event ContractBurn(uint256 amount);
    //Burns token on the contract, like when there is a very large backlog of token
    //or for scheudled BurnEvents
    function TeamBurnContractToken(uint8 percent) public onlyTeam{
        require(percent<=100,"Over 100%");
        uint256 burnAmount=_balances[address(this)]*percent/100;
        _removeToken(address(this),burnAmount);
        emit Transfer(address(this), address(0), burnAmount);
        emit ContractBurn(burnAmount);
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Setup Functions///////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    //Creates LP using Payable Amount, LP automatically land on the contract where they get locked
    //once Trading gets enabled
    bool public tradingEnabled;
    function SetupCreateLP(uint8 ContractTokenPercent, uint8 TeamTokenPercent) public payable onlyTeam{
        require(IBEP20(_pancakePairAddress).totalSupply()==0);
        
        uint256 Token=_balances[address(this)];
        
        uint256 TeamToken=Token*TeamTokenPercent/100;
        uint256 ContractToken=Token*ContractTokenPercent/100;
        uint256 LPToken=Token-(TeamToken+ContractToken);
        
        _removeToken(address(this),TeamToken);  
        _addToken(msg.sender, TeamToken);
        emit Transfer(address(this), msg.sender, TeamToken);
        
        _addLiquidity(LPToken, msg.value);
        
    }
    
    event OnTradingOpen();
    //Enables trading. Turns on bot protection and Locks LP for default Lock time
    function SetupEnableTrading() public onlyTeam{
        require(IBEP20(_pancakePairAddress).totalSupply()>0,"No LP");
        require(!tradingEnabled);
        tradingEnabled=true;
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime; 
        
        launchTimestamp=block.timestamp;
        _botProtection=true;
        emit OnTradingOpen();
    }
    
    //Adds or removes a List of addresses to Whitelist
    function SetupWhitelist(address[] memory addresses, bool Add) public onlyTeam{
        if(Add)
            for(uint i=0; i<addresses.length; i++)
                _whiteList.add(addresses[i]);
        else
            for(uint i=0; i<addresses.length; i++)
                _whiteList.remove(addresses[i]);
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Liquidity Lock////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //the timestamp when Liquidity unlocks
    uint256 private _liquidityUnlockTime;
    bool public liquidityRelease20Percent;

    //Sets Liquidity Release to 20% at a time and prolongs liquidity Lock for a Week after Release. 
    //Should be called once start was successful.
    function TeamlimitLiquidityReleaseTo20Percent() public onlyTeam{
        liquidityRelease20Percent=true;
    }
    
    //Prolongs the Liquidity Lock. Lock can't be reduced
    event ProlongLiquidityLock(uint256 secondsUntilUnlock);
    function TeamLockLiquidityForSeconds(uint256 secondsUntilUnlock) public onlyTeam{
        _prolongLiquidityLock(secondsUntilUnlock+block.timestamp);
        emit ProlongLiquidityLock(secondsUntilUnlock);
    }
    function _prolongLiquidityLock(uint256 newUnlockTime) private{
        // require new unlock time to be longer than old one
        require(newUnlockTime>_liquidityUnlockTime);
        _liquidityUnlockTime=newUnlockTime;
    }


    event OnReleaseLiquidity();
    //Release Liquidity Tokens once unlock time is over
    function TeamReleaseLiquidity() public onlyTeam {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Locked");
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;       
        IPancakeERC20 liquidityToken = IPancakeERC20(_pancakePairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
        if(liquidityRelease20Percent) amount=amount*2/10;
        liquidityToken.transfer(TeamWallet, amount);
        emit OnReleaseLiquidity();
    }

    event OnRemoveLiquidity(bool AddToStaking);
    //Removes Liquidity once unlock Time is over, can add LP to staking or to Marketing
    //Add to staking can be used as promotion, or as reward/refund for good holders if Project dies.
    function TeamRemoveLiquidity(bool addToStaking) public onlyTeam {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Locked");
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;
        IPancakeERC20 liquidityToken = IPancakeERC20(_pancakePairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
        if(liquidityRelease20Percent) amount=amount*2/10; //only remove 20% each
        liquidityToken.approve(address(_pancakeRouter),amount);
        //Removes Liquidity and either distributes liquidity BNB to stakers, or 
        // adds them to marketing Balance
        //Token will be converted
        //to Liquidity and Staking BNB again
        uint256 initialBNBBalance = address(this).balance;
        _pancakeRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            amount,
            0,
            0,
            address(this),
            block.timestamp
            );
        uint256 newBNBBalance = address(this).balance-initialBNBBalance;
        if(addToStaking) _distributeStake(newBNBBalance);
        else marketingBalance+=newBNBBalance;
        
        emit OnRemoveLiquidity(addToStaking);
    }
    event OnRemoveRemainingBNB();
    //Releases all remaining BNB on the contract wallet, so BNB wont be burned
    //Can only be called 30 days after Liquidity unlocks so staked BNB stay safe
    //Once called it breaks staking
    function TeamRemoveRemainingBNB() public onlyTeam{
        require(block.timestamp >= _liquidityUnlockTime+30 days, "Locked");
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;
        (bool sent,) =TeamWallet.call{value: (address(this).balance)}("");
        require(sent);
        emit OnRemoveRemainingBNB();
    }
    
    //Allows the team to withdraw token that get's accidentally sent to the contract(happens way too often)
    //Can't withdraw the LP token, this token or the promotion token
    function TeamWithdrawStrandedToken(address strandedToken) public onlyTeam{
        require((strandedToken!=_pancakePairAddress)&&strandedToken!=address(this)&&strandedToken!=address(promotionToken));
        IBEP20 token=IBEP20(strandedToken);
        token.transfer(TeamWallet,token.balanceOf(address(this)));
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //external//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    receive() external payable {}
    fallback() external payable {}
    // IBEP20

    function getOwner() external view override returns (address) {
        return owner();
    }
    function name() external pure override returns (string memory) {
        return _name;
    }
    function symbol() external pure override returns (string memory) {
        return _symbol;
    }
    function decimals() external pure override returns (uint8) {
        return _decimals;
    }
    function totalSupply() external view override returns (uint256) {
        return _circulatingSupply;
    }
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount);

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }
    // IBEP20 - Helpers
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue);

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }
}