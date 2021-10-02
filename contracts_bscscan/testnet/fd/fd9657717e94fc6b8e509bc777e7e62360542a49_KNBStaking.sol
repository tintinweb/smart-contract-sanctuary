/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

pragma solidity 0.6.11;

// SPDX-License-Identifier: BSD-3-Clause

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface Token {
    function approve(address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

interface OldIERC20 {
    function transfer(address, uint) external;
}

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
}

/**
 * @dev Staking Smart Contract
 * 
 *  - Users stake Uniswap LP Tokens to receive WETH and KNB Tokens as Rewards
 * 
 *  - Reward Tokens (KNB) are added to contract balance upon deployment by deployer
 * 
 *  - After Adding the KNB rewards, admin is supposed to transfer ownership to Governance contract
 * 
 *  - Users deposit Set (Predecided) Uniswap LP Tokens and get a share of the farm
 * 
 *  - The smart contract disburses `disburseAmount` KNB as rewards over `disburseDuration`
 * 
 *  - A swap is attempted periodically at atleast a set delay from last swap
 * 
 *  - The swap is attempted according to SWAP_PATH for difference deployments of this contract
 * 
 *  - For 4 different deployments of this contract, the SWAP_PATH will be:
 *      - KNB-WETH
 *      - KNB-WBTC-WETH (assumes appropriate liquidity is available in WBTC-WETH pair)
 *      - KNB-USDT-WETH (assumes appropriate liquidity is available in USDT-WETH pair)
 *      - KNB-USDC-WETH (assumes appropriate liquidity is available in USDC-WETH pair)
 * 
 *  - Any swap may not have a price impact on KNB price of more than approx ~2.49% for the related KNB pair
 *      KNB-WETH swap may not have a price impact of more than ~2.49% on KNB price in KNB-WETH pair
 *      KNB-WBTC-WETH swap may not have a price impact of more than ~2.49% on KNB price in KNB-WBTC pair
 *      KNB-USDT-WETH swap may not have a price impact of more than ~2.49% on KNB price in KNB-USDT pair
 *      KNB-USDC-WETH swap may not have a price impact of more than ~2.49% on KNB price in KNB-USDC pair
 * 
 *  - After the swap,converted WETH is distributed to stakers at pro-rata basis, according to their share of the staking pool
 *    on the moment when the WETH distribution is done. And remaining KNB is added to the amount to be distributed or burnt.
 *    The remaining KNB are also attempted to be swapped to WETH in the next swap if the price impact is ~2.49% or less
 * 
 *  - At a set delay from last execution, Governance contract (owner) may execute disburse or burn features
 * 
 *  - Burn feature should send the KNB tokens to set BURN_ADDRESS
 * 
 *  - Disburse feature should disburse the KNB 
 *    (which would have a max price impact ~2.49% if it were to be swapped, at disburse time 
 *    - remaining KNB are sent to BURN_ADDRESS) 
 *    to stakers at pro-rata basis according to their share of
 *    the staking pool at the moment the disburse is done
 * 
 *  - Users may claim their pending WETH and KNB anytime
 * 
 *  - Pending rewards are auto-claimed on any deposit or withdraw
 * 
 *  - Users need to wait `cliffTime` duration since their last deposit before withdrawing any LP Tokens
 * 
 *  - Owner may not transfer out LP Tokens from this contract anytime
 * 
 *  - Owner may transfer out WETH and KNB Tokens from this contract once `adminClaimableTime` is reached
 * 
 *  - CONTRACT VARIABLES must be changed to appropriate values before live deployment
 */
contract KNBStaking is Ownable {
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
    
    // Contracts are not allowed to deposit, claim or withdraw
    modifier noContractsAllowed() {
        require(!(address(msg.sender).isContract()) && tx.origin == msg.sender, "No Contracts Allowed!");
        _;
    }

    event RewardsTransferred(address holder, uint amount);
    event EthRewardsTransferred(address holder, uint amount);
    
    event RewardsDisbursed(uint amount);
    event EthRewardsDisbursed(uint amount);
    
    // ============ START CONTRACT VARIABLES ==========================

    // deposit token contract address and reward token contract address
    // these contracts (and uniswap pair & router) are "trusted" 
    // and checked to not contain re-entrancy pattern
    // to safely avoid checks-effects-interactions where needed to simplify logic
    address public constant trustedDepositTokenAddress = 0x87A2125b2799f0eAE0436E74cc065a1537c706fD;
    address public constant trustedRewardTokenAddress = 0xf666B2DeFCC02874576707B8924854e44135aFDb;
    
    // Make sure to double-check BURN_ADDRESS
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    // cliffTime - withdraw is not possible within cliffTime of deposit
    uint public constant cliffTime = 10 minutes;

    // Amount of tokens
    uint public constant disburseAmount = 432000e18;
    // To be disbursed continuously over this duration
    uint public constant disburseDuration = 1 days;
    
    // If there are any undistributed or unclaimed tokens left in contract after this time
    // Admin can claim them
    uint public constant adminCanClaimAfter = 30 minutes;
    
    // delays between attempted swaps
    uint public constant swapAttemptPeriod = 10 minutes;
    // delays between attempted burns or token disbursement
    uint public constant burnOrDisburseTokensPeriod = 30 minutes;

    

    // do not change this => disburse 100% rewards over `disburseDuration`
    uint public constant disbursePercentX100 = 100e2;
    
    uint public constant MAGIC_NUMBER = 25641025641025772;
    
    // slippage tolerance
    uint public constant SLIPPAGE_TOLERANCE_X_100 = 300;
    
    //  ============ END CONTRACT VARIABLES ==========================
    
    event ClaimableTokenAdded(address indexed tokenAddress);
    event ClaimableTokenRemoved(address indexed tokenAddress);
    mapping (address => bool) public trustedClaimableTokens;
    function addTrustedClaimableToken(address trustedClaimableTokenAddress) external onlyOwner {
        trustedClaimableTokens[trustedClaimableTokenAddress] = true;
        emit ClaimableTokenAdded(trustedClaimableTokenAddress);
    }
    function removeTrustedClaimableToken(address trustedClaimableTokenAddress) external onlyOwner {
        trustedClaimableTokens[trustedClaimableTokenAddress] = false;
        emit ClaimableTokenRemoved(trustedClaimableTokenAddress);
    }

    uint public contractDeployTime;
    uint public adminClaimableTime;
    uint public lastDisburseTime;
    uint public lastSwapExecutionTime;
    uint public lastBurnOrTokenDistributeTime;
    
    IUniswapV2Router02 public uniswapRouterV2;
    IUniswapV2Pair public uniswapV2Pair;
    address[] public SWAP_PATH;
    
    constructor(address[] memory swapPath) public {
        contractDeployTime = now;
        adminClaimableTime = contractDeployTime.add(adminCanClaimAfter);
        lastDisburseTime = contractDeployTime;
        lastSwapExecutionTime = lastDisburseTime;
        lastBurnOrTokenDistributeTime = lastDisburseTime;
        
        uniswapRouterV2 = IUniswapV2Router02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
        uniswapV2Pair = IUniswapV2Pair(trustedDepositTokenAddress);
        SWAP_PATH = swapPath;
    }

    uint public totalClaimedRewards = 0;
    uint public totalClaimedRewardsEth = 0;

    EnumerableSet.AddressSet private holders;

    mapping (address => uint) public depositedTokens;
    mapping (address => uint) public depositTime;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarnedTokens;
    mapping (address => uint) public totalEarnedEth;
    mapping (address => uint) public lastDivPoints;
    mapping (address => uint) public lastEthDivPoints;

    uint public contractBalance = 0;

    uint public totalDivPoints = 0;
    uint public totalEthDivPoints = 0;
    uint public totalTokens = 0;
    
    uint public tokensToBeDisbursedOrBurnt = 0;
    uint public tokensToBeSwapped = 0;

    uint internal constant pointMultiplier = 1e18;

    // To be executed by admin after deployment to add KNB to contract
    function addContractBalance(uint amount) public onlyOwner {
        require(Token(trustedRewardTokenAddress).transferFrom(msg.sender, address(this), amount), "Cannot add balance!");
        contractBalance = contractBalance.add(amount);
    }

    
    // Private function to update account information and auto-claim pending rewards
    function updateAccount(address account, address claimAsToken) private {
        disburseTokens();
        attemptSwap();
        uint pendingDivs = getPendingDivs(account);
        if (pendingDivs > 0) {
            require(Token(trustedRewardTokenAddress).transfer(account, pendingDivs), "Could not transfer tokens.");
            totalEarnedTokens[account] = totalEarnedTokens[account].add(pendingDivs);
            totalClaimedRewards = totalClaimedRewards.add(pendingDivs);
            emit RewardsTransferred(account, pendingDivs);
        }
        
        uint pendingDivsEth = getPendingDivsEth(account);
        if (pendingDivsEth > 0) {
            
            if (claimAsToken == address(0)) {
                require(Token(uniswapRouterV2.WETH()).transfer(account, pendingDivsEth), "Could not transfer WETH!");
            } else {
                require(trustedClaimableTokens[claimAsToken], "cannot claim as this token!");
                
                Token(uniswapRouterV2.WETH()).approve(address(uniswapRouterV2), pendingDivsEth);
                address[] memory path = new address[](2);
                path[0] = uniswapRouterV2.WETH();
                path[1] = claimAsToken;
                uint estimatedAmountOut = uniswapRouterV2.getAmountsOut(pendingDivsEth, path)[1];
                uint amountOutMin = estimatedAmountOut.mul(uint(100e2).sub(SLIPPAGE_TOLERANCE_X_100)).div(100e2);
                
                uniswapRouterV2.swapExactTokensForTokens(pendingDivsEth, amountOutMin, path, account, block.timestamp);
                
            }
            
            totalEarnedEth[account] = totalEarnedEth[account].add(pendingDivsEth);
            totalClaimedRewardsEth = totalClaimedRewardsEth.add(pendingDivsEth);
            emit EthRewardsTransferred(account, pendingDivsEth);
        }
        
        lastClaimedTime[account] = now;
        lastDivPoints[account] = totalDivPoints;
        lastEthDivPoints[account] = totalEthDivPoints;
    }
    
    function updateAccount(address account) private {
        updateAccount(account, address(0));
    }

    // view function to check last updated KNB pending rewards
    function getPendingDivs(address _holder) public view returns (uint) {
        if (!holders.contains(_holder)) return 0;
        if (depositedTokens[_holder] == 0) return 0;

        uint newDivPoints = totalDivPoints.sub(lastDivPoints[_holder]);

        uint depositedAmount = depositedTokens[_holder];

        uint pendingDivs = depositedAmount.mul(newDivPoints).div(pointMultiplier);

        return pendingDivs;
    }
    
    // view function to check last updated WETH pending rewards
    function getPendingDivsEth(address _holder) public view returns (uint) {
        if (!holders.contains(_holder)) return 0;
        if (depositedTokens[_holder] == 0) return 0;

        uint newDivPoints = totalEthDivPoints.sub(lastEthDivPoints[_holder]);

        uint depositedAmount = depositedTokens[_holder];

        uint pendingDivs = depositedAmount.mul(newDivPoints).div(pointMultiplier);

        return pendingDivs;
    }

    
    // view functon to get number of stakers
    function getNumberOfHolders() public view returns (uint) {
        return holders.length();
    }


    // deposit function to stake LP Tokens
    function deposit(uint amountToDeposit) public noContractsAllowed {
        require(amountToDeposit > 0, "Cannot deposit 0 Tokens");

        updateAccount(msg.sender);

        require(Token(trustedDepositTokenAddress).transferFrom(msg.sender, address(this), amountToDeposit), "Insufficient Token Allowance");

        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(amountToDeposit);
        totalTokens = totalTokens.add(amountToDeposit);

        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
        }
        depositTime[msg.sender] = now;
    }

    // withdraw function to unstake LP Tokens
    function withdraw(uint amountToWithdraw) public noContractsAllowed {
        require(amountToWithdraw > 0, "Cannot withdraw 0 Tokens!");

        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");
        require(now.sub(depositTime[msg.sender]) > cliffTime, "You recently deposited, please wait before withdrawing.");
        
        updateAccount(msg.sender);

        require(Token(trustedDepositTokenAddress).transfer(msg.sender, amountToWithdraw), "Could not transfer tokens.");

        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);
        totalTokens = totalTokens.sub(amountToWithdraw);

        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }

    // withdraw without caring about Rewards
    function emergencyWithdraw(uint amountToWithdraw) public noContractsAllowed {
        require(amountToWithdraw > 0, "Cannot withdraw 0 Tokens!");

        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");
        require(now.sub(depositTime[msg.sender]) > cliffTime, "You recently deposited, please wait before withdrawing.");
        
        // manual update account here without withdrawing pending rewards
        disburseTokens();
        // do not attempt swap here
        lastClaimedTime[msg.sender] = now;
        lastDivPoints[msg.sender] = totalDivPoints;
        lastEthDivPoints[msg.sender] = totalEthDivPoints;

        require(Token(trustedDepositTokenAddress).transfer(msg.sender, amountToWithdraw), "Could not transfer tokens.");

        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);
        totalTokens = totalTokens.sub(amountToWithdraw);

        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }
    
    // claim function to claim pending rewards
    function claim() public noContractsAllowed {
        updateAccount(msg.sender);
    }
    
    function claimAs(address claimAsToken) public noContractsAllowed {
        require(trustedClaimableTokens[claimAsToken], "cannot claim as this token!");
        updateAccount(msg.sender, claimAsToken);
    }
    
    // private function to distribute KNB rewards
    function distributeDivs(uint amount) private {
        require(amount > 0 && totalTokens > 0, "distributeDivs failed!");
        totalDivPoints = totalDivPoints.add(amount.mul(pointMultiplier).div(totalTokens));
        emit RewardsDisbursed(amount);
    }
    
    // private function to distribute WETH rewards
    function distributeDivsEth(uint amount) private {
        require(amount > 0 && totalTokens > 0, "distributeDivsEth failed!");
        totalEthDivPoints = totalEthDivPoints.add(amount.mul(pointMultiplier).div(totalTokens));
        emit EthRewardsDisbursed(amount);
    }

    // private function to allocate KNB to be disbursed calculated according to time passed
    function disburseTokens() private {
        uint amount = getPendingDisbursement();

        if (contractBalance < amount) {
            amount = contractBalance;
        }
        if (amount == 0 || totalTokens == 0) return;

        tokensToBeSwapped = tokensToBeSwapped.add(amount);        

        contractBalance = contractBalance.sub(amount);
        lastDisburseTime = now;
    }
    
    function attemptSwap() private {
        doSwap();
    }
    
    function doSwap() private {
        // do not attemptSwap if no one has staked
        if (totalTokens == 0) {
            return;
        }
        
        // Cannot execute swap so quickly
        if (now.sub(lastSwapExecutionTime) < swapAttemptPeriod) {
            return;
        }
    
        // force reserves to match balances
        uniswapV2Pair.sync();
    
        uint _tokensToBeSwapped = tokensToBeSwapped.add(tokensToBeDisbursedOrBurnt);
        
        uint maxSwappableAmount = getMaxSwappableAmount();
        
        // don't proceed if no liquidity
        if (maxSwappableAmount == 0) return;
    
        if (maxSwappableAmount < tokensToBeSwapped) {
            
            uint diff = tokensToBeSwapped.sub(maxSwappableAmount);
            _tokensToBeSwapped = tokensToBeSwapped.sub(diff);
            tokensToBeDisbursedOrBurnt = tokensToBeDisbursedOrBurnt.add(diff);
            tokensToBeSwapped = 0;
    
        } else if (maxSwappableAmount < _tokensToBeSwapped) {
    
            uint diff = _tokensToBeSwapped.sub(maxSwappableAmount);
            _tokensToBeSwapped = _tokensToBeSwapped.sub(diff);
            tokensToBeDisbursedOrBurnt = diff;
            tokensToBeSwapped = 0;
    
        } else {
            tokensToBeSwapped = 0;
            tokensToBeDisbursedOrBurnt = 0;
        }
    
        // don't execute 0 swap tokens
        if (_tokensToBeSwapped == 0) {
            return;
        }
    
        // cannot execute swap at insufficient balance
        if (Token(trustedRewardTokenAddress).balanceOf(address(this)) < _tokensToBeSwapped) {
            return;
        }
    
        require(Token(trustedRewardTokenAddress).approve(address(uniswapRouterV2), _tokensToBeSwapped), 'approve failed!');
    
        uint oldWethBalance = Token(uniswapRouterV2.WETH()).balanceOf(address(this));
                
        uint amountOutMin;
        
        uint estimatedAmountOut = uniswapRouterV2.getAmountsOut(_tokensToBeSwapped, SWAP_PATH)[SWAP_PATH.length.sub(1)];
        amountOutMin = estimatedAmountOut.mul(uint(100e2).sub(SLIPPAGE_TOLERANCE_X_100)).div(100e2);
        
        uniswapRouterV2.swapExactTokensForTokens(_tokensToBeSwapped, amountOutMin, SWAP_PATH, address(this), block.timestamp);
    
        uint newWethBalance = Token(uniswapRouterV2.WETH()).balanceOf(address(this));
        uint wethReceived = newWethBalance.sub(oldWethBalance);
        require(wethReceived >= amountOutMin, "Invalid SWAP!");
        
        if (wethReceived > 0) {
            distributeDivsEth(wethReceived);    
        }

        lastSwapExecutionTime = now;
    }
    
    // Owner is supposed to be a Governance Contract
    function disburseRewardTokens() public onlyOwner {
        require(now.sub(lastBurnOrTokenDistributeTime) > burnOrDisburseTokensPeriod, "Recently executed, Please wait!");
        
        // force reserves to match balances
        uniswapV2Pair.sync();
        
        uint maxSwappableAmount = getMaxSwappableAmount();
        
        uint _tokensToBeDisbursed = tokensToBeDisbursedOrBurnt;
        uint _tokensToBeBurnt;
        
        if (maxSwappableAmount < _tokensToBeDisbursed) {
            _tokensToBeBurnt = _tokensToBeDisbursed.sub(maxSwappableAmount);
            _tokensToBeDisbursed = maxSwappableAmount;
        }
        
        distributeDivs(_tokensToBeDisbursed);
        if (_tokensToBeBurnt > 0) {
            require(Token(trustedRewardTokenAddress).transfer(BURN_ADDRESS, _tokensToBeBurnt), "disburseRewardTokens: burn failed!");
        }
        tokensToBeDisbursedOrBurnt = 0;
        lastBurnOrTokenDistributeTime = now;
    }
    
    
    // Owner is suposed to be a Governance Contract
    function burnRewardTokens() public onlyOwner {
        require(now.sub(lastBurnOrTokenDistributeTime) > burnOrDisburseTokensPeriod, "Recently executed, Please wait!");
        require(Token(trustedRewardTokenAddress).transfer(BURN_ADDRESS, tokensToBeDisbursedOrBurnt), "burnRewardTokens failed!");
        tokensToBeDisbursedOrBurnt = 0;
        lastBurnOrTokenDistributeTime = now;
    }
    
    
    // get token amount which has a max price impact of 2.5% for sells
    // !!IMPORTANT!! => Any functions using return value from this
    // MUST call `sync` on the pair before calling this function!
    function getMaxSwappableAmount() public view returns (uint) {
        uint tokensAvailable = Token(trustedRewardTokenAddress).balanceOf(trustedDepositTokenAddress);
        uint maxSwappableAmount = tokensAvailable.mul(MAGIC_NUMBER).div(1e18);
        return maxSwappableAmount;
    }

    // view function to calculate amount of KNB pending to be allocated since `lastDisburseTime` 
    function getPendingDisbursement() public view returns (uint) {
        uint timeDiff;
        uint _now = now;
        uint _stakingEndTime = contractDeployTime.add(disburseDuration);
        if (_now > _stakingEndTime) {
            _now = _stakingEndTime;
        }
        if (lastDisburseTime >= _now) {
            timeDiff = 0;
        } else {
            timeDiff = _now.sub(lastDisburseTime);
        }

        uint pendingDisburse = disburseAmount
                                    .mul(disbursePercentX100)
                                    .mul(timeDiff)
                                    .div(disburseDuration)
                                    .div(10000);
        return pendingDisburse;
    }

    // view function to get depositors list
    function getDepositorsList(uint startIndex, uint endIndex)
        public
        view
        returns (address[] memory stakers,
            uint[] memory stakingTimestamps,
            uint[] memory lastClaimedTimeStamps,
            uint[] memory stakedTokens) {
        require (startIndex < endIndex);

        uint length = endIndex.sub(startIndex);
        address[] memory _stakers = new address[](length);
        uint[] memory _stakingTimestamps = new uint[](length);
        uint[] memory _lastClaimedTimeStamps = new uint[](length);
        uint[] memory _stakedTokens = new uint[](length);

        for (uint i = startIndex; i < endIndex; i = i.add(1)) {
            address staker = holders.at(i);
            uint listIndex = i.sub(startIndex);
            _stakers[listIndex] = staker;
            _stakingTimestamps[listIndex] = depositTime[staker];
            _lastClaimedTimeStamps[listIndex] = lastClaimedTime[staker];
            _stakedTokens[listIndex] = depositedTokens[staker];
        }

        return (_stakers, _stakingTimestamps, _lastClaimedTimeStamps, _stakedTokens);
    }


    // function to allow owner to claim *other* modern ERC20 tokens sent to this contract
    function transferAnyERC20Token(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        require(_tokenAddr != trustedDepositTokenAddress, "Admin cannot transfer out deposit tokens from this vault!");
        require((_tokenAddr != trustedRewardTokenAddress && _tokenAddr != uniswapRouterV2.WETH()) || (now > adminClaimableTime), "Admin cannot Transfer out Reward Tokens or WETH Yet!");
        require(Token(_tokenAddr).transfer(_to, _amount), "Could not transfer out tokens!");
    }

    // function to allow owner to claim *other* legacy ERC20 tokens sent to this contract
    function transferAnyOldERC20Token(address _tokenAddr, address _to, uint _amount) public onlyOwner {
       
        require(_tokenAddr != trustedDepositTokenAddress, "Admin cannot transfer out deposit tokens from this vault!");
        require((_tokenAddr != trustedRewardTokenAddress && _tokenAddr != uniswapRouterV2.WETH()) || (now > adminClaimableTime), "Admin cannot Transfer out Reward Tokens or WETH Yet!");

        OldIERC20(_tokenAddr).transfer(_to, _amount);
    }
}