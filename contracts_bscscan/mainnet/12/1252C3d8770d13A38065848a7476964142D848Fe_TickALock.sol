/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.3 <0.9.0;

/**
* _______ _____ _____ _  __             _      ____   _____ _  __
* |__   __|_   _/ ____| |/ /     /\     | |    / __ \ / ____| |/ /
*    | |    | || |    | ' /     /  \    | |   | |  | | |    | ' / 
*    | |    | || |    |  <     / /\ \   | |   | |  | | |    |  <  
*    | |   _| || |____| . \   / ____ \  | |___| |__| | |____| . \ 
*    |_|  |_____\_____|_|\_\ /_/    \_\ |______\____/ \_____|_|\_\
*
*    The Question https://tickalock.app/
*    Solve the question, win the prize.
*    
*    The Crossword: https://crossword.tickalock.app/
*    Play the weekly crossword!
*    
*    Socials
*    Telegram: https://t.me/tickalock
*    Twitter: https://twitter.com/mrtialo
*    Discord: https://discord.gg/wCMpBzBpfE
*/

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

contract TickALock is Ownable, IBEP20 {
    uint256 private constant _initialSupply = 24000000000 * 10**9;
    uint256 public _totalSupply = _initialSupply;
    //get 5% of the total supply
    uint256 public _totalSupply5 = _totalSupply * 500 / 10000;
    //get 24% of the total supply
    uint256 public _totalSupply24 = _totalSupply * 2400 / 10000;
    /* Trading */
    uint256 private _antiBotTimer;
    bool public _canTrade;
    /* SwapAndLiquify */
    bool private _isWithdrawing;
    bool private _isSwappingContractModifier;
    bool public swapAndLiquifyEnabled = true;
    uint256 public _numTokensSellToAddToLiquidity = 60000000 * 10**9;
    /* Sell Delay & Token Vesting (Locking) */
    uint256 private _maxSellDelay = 1 hours;
    uint256 public _sellDelay = 0;
    uint256 private _totalTokensHeld;
    /* Tracking Tokens for LP on Contract   */
    uint256 public _totalAllocatedLiquidityContract;
    /* Tracking Tokens for Marketing on Contract   */
    uint256 public _totalAllocatedMarketingContract;
    /* Tracking Tokens for Crossword Pot on Contract */
    uint256 public _totalAllocatedCrosswordPotContract;
    /* Burn Mechanism */
    uint256 public _tokensToBurn;
    /* LP tax represented as a percentage */
    uint256 private constant _maxTax = 1225; // 12.25% max percent for total tax - no honeypots here!
    uint256 public _liquidityTax = 1224; // 12.24% ie 100 * 1224 / 10000
    bool private _addingLiquidity;
    /* "Buyback" Burn Tax */
    uint256 public _maxBurnTax = 724;
    uint256 public _minBurnTax = 24;
    /* Marketing */
    address public _marketingWalletAddress = 0x9b53C12226e0B46Ac7e4f21De7bC0A5357EF822A;
    uint256 public _marketingTax = 200;
    /* Balance & Sell Limits */
    uint256 public _maxWalletSize = _initialSupply / 100; // 1 % of total supply
    uint256 public _maxSellSize = _initialSupply / 100;
    /* PancakeSwap */
    IPancakeRouter02 private _pancakeRouter;
    address public _pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public _pancakePairAddress;

    /* Multi-Sig Team Wallet */
    address public _devWallet = 0x82De1c2B2f6DD4aa6eACD3f170357aC4E982C2dd;
    address public _burnWallet = 0x000000000000000000000000000000000000dEaD;
    //create a property to track the current weeks  puzzle
    uint256 public _currentPuzzleWeek = 0;
    //create a property to track minimum guess holding fee
    uint256 public _minHoldingsForGuess = 1000 * 10**9;
    //create a property to track the minimum letter submission fee
    uint256 public _crosswordLetterCost = 1000 * 10**9;
    uint256 public _minGuessLength = 24;

    uint256 public _crosswordGuessesPerCoordinate = 3;

    bool public _crosswordEnabled = true;
    bool public _puzzleEnabled = true;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _automatedMarketMakers;
    mapping(address => Holder) private _holders;
    struct Holder {
        // Used for sell delay & token vesting (locking)
        uint256 nextSell;
        uint256 pancakeswapTotalPurchased;
        bool excludeFromFees;
    }
    event OwnerCreateLP(uint8 teamPercent, uint8 contractPercent);
    event OwnerChangeSellDelay(uint256 sellDelay);
    event OwnerUpdateAMM(address indexed AMMAdress, bool enabled);
    event OwnerUpdateMarketingWallet(address indexed marketingWalletAddress);
    event OwnerSwitchSwapAndLiquify(bool disabled);
    event OwnerChangeLPTaxes(uint256 liquidityTax);
    event OwnerChangeBurnTaxes(uint256 maxBurnTax, uint256 minBurnTax);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 amountToken,
        uint256 amountBNB
    );
    event GuessSubmitted(string guess);
    event LetterSubmitted(string letter);
    event OwnerEnableCrossword(bool enable);
    event OwnerEnablePuzzle(bool enable);
    event OwnerSetGridLength(uint256 gridLength);
    modifier lockTheSwap() {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }
    modifier onlyDev() {
        require(msg.sender == _devWallet);
        _;
    }

    constructor() {
        uint256 pancakeSupply = _initialSupply - _totalSupply24 - _totalSupply5;
        // Mint initial supply to contract
        _updateBalance(msg.sender, pancakeSupply);
        _updateBalance(address(this), _totalSupply24);
        _updateBalance(_devWallet, _totalSupply5);
        emit Transfer(address(0), address(msg.sender), pancakeSupply);
        emit Transfer(address(0), address(this), _totalSupply24);
        emit Transfer(address(0), _devWallet, _totalSupply5);
        // Init & approve PCSR
        _pancakeRouter = IPancakeRouter02(_pancakeRouterAddress);
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        _automatedMarketMakers[_pancakePairAddress] = true;
        
        // Exclude from fees
        _holders[msg.sender].excludeFromFees = true;
        _holders[address(this)].excludeFromFees = true;
        _holders[_devWallet].excludeFromFees = true;
    }

    function forceAddingLiquidityReset() public onlyDev {
        //if for some reason addingLiquidity were to get "stuck"
        _addingLiquidity = false;
    }

    ///////////////////////////////////////////
    // Transfer Functions
    ///////////////////////////////////////////
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(
            sender != address(0) && recipient != address(0),
            "Cannot be zero address."
        );
        bool isBuy = _automatedMarketMakers[sender];
        bool isSell = _automatedMarketMakers[recipient];
        bool isExcluded = _holders[sender].excludeFromFees ||
            _holders[recipient].excludeFromFees || _addingLiquidity;
        if (isExcluded) {
            _transferExcluded(sender, recipient, amount);
        } else {
            // Trading can only be enabled once
            require(_canTrade, "Trading isn't enabled.");
            //swap and liquify
            bool overMinTokenBalance = _totalAllocatedLiquidityContract >=
            _numTokensSellToAddToLiquidity;
            if (
                overMinTokenBalance &&
                !_isSwappingContractModifier &&
                msg.sender != _pancakePairAddress &&
                swapAndLiquifyEnabled
            ) {
                swapContractTokens();
            }

            if (isBuy) {
                _buyTokens(recipient, amount);
            }
            else if (isSell) { 
                _sellTokens(sender, amount);
            }
            else {
                // Dev Wallet cannot transfer tokens until lock has expired
                if (sender == _devWallet) {
                    require(block.timestamp >= _holders[_devWallet].nextSell);
                }
                require(_balances[recipient] + amount <= _maxWalletSize);
                _transferExcluded(sender, recipient, amount);
                // Recipient will incur sell delay to prevent pump & dump
                _holders[recipient].nextSell = block.timestamp + _sellDelay;
            }
        }
    }

    function _buyTokens(address recipient, uint256 amount) private {
        if (block.timestamp < _antiBotTimer) {
            _totalAllocatedLiquidityContract += amount;
            // 100 % of tokens sent to contract for LP
            _transferExcluded(_pancakePairAddress, address(this), amount);
        } else {
            // Balance + amount cannot exceed 1 % of circulating supply (_maxWalletSize)
            require(_balances[recipient] + amount <= _maxWalletSize, "Balance + amount cannot exceed 1 % of circulating supply.");
            // Amount of tokens to be sent to contract
            uint256 taxedTokensLP = 0;
            uint256 taxedTokensMarketing = 0;
            if (_liquidityTax > 0) {
                // Amount of tokens to be sent to contract
                taxedTokensLP = (amount * _liquidityTax) / 10000;
                _totalAllocatedLiquidityContract += taxedTokensLP;
            }
            if (_marketingTax > 0) {
                // Amount of tokens to be sent to contract
                taxedTokensMarketing = (amount * _marketingTax) / 10000;
                _totalAllocatedMarketingContract += taxedTokensMarketing;
            }
            _transferIncluded(
                _pancakePairAddress,
                recipient,
                amount,
                taxedTokensLP + taxedTokensMarketing
            );
            _totalTokensHeld += amount - taxedTokensLP - taxedTokensMarketing;
            // Reset sell delay
            _holders[recipient].nextSell = block.timestamp + _sellDelay;
            //Set pancake total purchased amount
            _holders[recipient].pancakeswapTotalPurchased = _holders[recipient].pancakeswapTotalPurchased + amount - taxedTokensLP - taxedTokensMarketing;
        }
    }

    function _sellTokens(address sender, uint256 amount) private {
        // Cannot sell before nextSell
        require(block.timestamp >= _holders[sender].nextSell, "Sell delay not over.");
        require(amount <= _maxSellSize && amount <= _balances[sender], "Amount is too large.");
        // Amount of tokens to be sent to contract
        uint256 taxedTokensBurn = 0;
        uint256 burnTax = calculateBurnTax(sender);
        uint256 taxedTokensMarketing = 0;
        if (burnTax > 0) {
            // Amount of tokens to be sent to contract
            taxedTokensBurn = (amount * burnTax) / 10000;
            _tokensToBurn += taxedTokensBurn;
        }
        if (_marketingTax > 0) {
            // Amount of tokens to be sent to contract
            taxedTokensMarketing = (amount * _marketingTax) / 10000;
            _totalAllocatedMarketingContract += taxedTokensMarketing;
        }
        _transferIncluded(sender, _pancakePairAddress, amount, taxedTokensBurn + taxedTokensMarketing);
        _totalTokensHeld -= amount - taxedTokensBurn - taxedTokensMarketing;
        // Reset sell delay
        _holders[sender].nextSell = block.timestamp + _sellDelay;
    }

    //Burn tax is calculated as a percentage of the senders tokens
    function calculateBurnTax(address sender) public view returns (uint256) {
        uint256 burnTax = 0;
        //get senders balance
        uint256 senderBalance = _balances[sender];
        //max burn tax defaults to %7.24
        uint256 maxBurnTax = _maxBurnTax;
        //min burn tax defaults to %0.24
        uint256 minBurnTax = _minBurnTax;
        uint256 percentageOfHoldings = (senderBalance * 10000) / _totalSupply;
        //given that the percentageOfHoldings can only ever be max 1% of the circulating supply, make this a percentage where the max is 100%
        uint256 relativePercentageValue = percentageOfHoldings * 100;
        //given the range of min minBurnTax and max maxBurnTax, find the relative percentage of the percentage of holdings.  This is the burn tax.
        burnTax = ((maxBurnTax - minBurnTax) * relativePercentageValue) / 10000 + minBurnTax;

        return burnTax;
    }

    function setMarketingTax(uint256 marketingTax) public onlyOwner {
        require(_marketingTax >= 0 && _marketingTax <= 400, "Marketing tax must be between 0 and 400");
        _marketingTax = marketingTax;
    }

    function _transferIncluded(
        address sender,
        address recipient,
        uint256 amount,
        uint256 taxedTokens
    ) private {
        uint256 newAmount = amount - taxedTokens;
        _updateBalance(sender, _balances[sender] - amount);
        // Taxed tokens are sent to contract
        _updateBalance(address(this), _balances[address(this)] + taxedTokens);
        emit Transfer(sender, address(this), taxedTokens);
        _updateBalance(recipient, _balances[recipient] + newAmount);
        emit Transfer(sender, recipient, newAmount);
    }

    function _transferExcluded(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _updateBalance(sender, _balances[sender] - amount);
        _updateBalance(recipient, _balances[recipient] + amount);
        emit Transfer(sender, recipient, amount);
    }

    function _updateBalance(address account, uint256 newBalance) private {
        _balances[account] = newBalance;
    }

    ///////////////////////////////////////////
    // Liquidity Functions
    ///////////////////////////////////////////
    function _contractSwapAndLiquify() public onlyDev {
        bool overMinTokenBalance = _totalAllocatedLiquidityContract >=
            _numTokensSellToAddToLiquidity;
        require(
            overMinTokenBalance &&
            !_isSwappingContractModifier &&
            msg.sender != _pancakePairAddress &&
            swapAndLiquifyEnabled, "Must be over min token balance, not inSwappingContract and swapAndLiquifyEnabled."
        );
        swapContractTokens();
    }

    function swapContractTokens() private lockTheSwap {
        uint256 prizeTokens = getPrizeTokens();
        uint256 remainingBalance = _balances[address(this)] - prizeTokens - _tokensToBurn - _totalAllocatedMarketingContract - _totalAllocatedCrosswordPotContract;
        require(
            _totalAllocatedLiquidityContract >= remainingBalance,
            "totalAllocatedLiquidityContract must be greater than or equal to the remainder of the contract balance and tokens to burn"
        );

        uint256 tokensForLP = remainingBalance;
        uint256 tokensForMarketing = _totalAllocatedMarketingContract;

        (uint256 tokensLiquidity, uint256 BNBLiquidity) = swapAndLiquify(tokensForLP, tokensForMarketing); 
   
        // remove allocated tokens from tally
        _totalAllocatedLiquidityContract = 0;
        _totalAllocatedMarketingContract = 0;
        emit SwapAndLiquify(tokensLiquidity, BNBLiquidity);
    }
    
    function getPrizeTokens() public view returns (uint256) {
        return _balances[address(this)] - _totalAllocatedLiquidityContract - _tokensToBurn - _totalAllocatedMarketingContract - _totalAllocatedCrosswordPotContract;
    }

    function swapAndLiquify(uint256 tokensForLP, uint256 tokensForMarketing) private returns (uint256, uint256) {
        if(tokensForMarketing > 0) {
            //swap tokens for Marketing to BNB and send to marketing wallet
            // swap the tokens for BNB
            _swapTokensForBNB(tokensForMarketing, _marketingWalletAddress);
        }
        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // split the tokensForLP into halves
        uint256 half = tokensForLP / 2;
        uint256 otherHalf = tokensForLP - half;
        
        // swap tokens for BNB
        _swapTokensForBNB(half, address(this));

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to pancakeswap
        _addLiquidity(otherHalf, newBalance);
        return (half, newBalance);
    }

    function _addLiquidity(uint256 amountTokens, uint256 amountBNB) private {
        _approve(address(this), address(_pancakeRouter), amountTokens);

        _addingLiquidity = true;
        _pancakeRouter.addLiquidityETH{value: amountBNB}(
            address(this), 
            amountTokens, 
            0, 
            0, 
            _burnWallet, 
            block.timestamp
        );
        _addingLiquidity = false;
    }

    function _swapTokensForBNB(uint256 amount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        //WBNB
        path[1] = address(_pancakeRouter.WETH());
        
        _approve(address(this), address(_pancakeRouter), amount);
        
        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            // Receiver address
            to,
            block.timestamp
        );
    }

    function getPancakeRouter() public view returns (address) {
        return address(_pancakeRouter);
    }

    function getThisAddress() public view returns (address) {
        return address(this);
    }

    //reduce LP tax
    function reduceLPTax() private {
        if (_liquidityTax >= 24) {
            _liquidityTax = _liquidityTax - 24;
        }
    }

    ///////////////////////////////////////////
    // Owner Public Functions
    ///////////////////////////////////////////
    function ownerChangeLPTaxes(uint256 liquidityTax) public onlyOwner {
        require((liquidityTax) <= _maxTax);
        _liquidityTax = liquidityTax;
        emit OwnerChangeLPTaxes(_liquidityTax);
    }

    function ownerChangeBurnTaxes(uint256 maxBurnTax,  uint256 minBurnTax) public onlyOwner {
        require((maxBurnTax) <= _maxTax);
        require((minBurnTax) <= _maxTax);
        _maxBurnTax = maxBurnTax;
        _minBurnTax = minBurnTax;
        emit OwnerChangeBurnTaxes(_maxBurnTax, _minBurnTax);
    }

    function enableTrading() public onlyOwner {
        // This function can only be called once
        require(!_canTrade);
        _canTrade = true; // true
        // Team tokens are vested (locked) for 60 days
        _holders[_devWallet].nextSell = block.timestamp + 60 days;
        // All buys in the next 5 minutes are burned and added to LP
        _antiBotTimer = block.timestamp + 5 minutes;
    }

    // 0 disables sellDelay.  sellDelay is in seconds
    function changeSellDelay(uint256 sellDelay) public onlyOwner {
        // Cannot exceed 1 hour.
        require(sellDelay <= _maxSellDelay);
        _sellDelay = sellDelay;
        emit OwnerChangeSellDelay(sellDelay);
    }

    function switchSwapAndLiquify() public onlyOwner {
        swapAndLiquifyEnabled = !swapAndLiquifyEnabled;
        emit OwnerSwitchSwapAndLiquify(swapAndLiquifyEnabled);
    }

    // Disable anti-snipe manually, if needed
    function disableAntiSnipe() public onlyOwner {
        _antiBotTimer = 0;
    }

    //update _marketingWalletAddress
    function updateMarketingWallet(address marketingWalletAddress) public onlyOwner {
        _marketingWalletAddress = marketingWalletAddress;
        emit OwnerUpdateMarketingWallet(marketingWalletAddress);
    }

    ///////////////////////////////////////////
    // BEP-2O Functions
    ///////////////////////////////////////////
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 allowance_ = _allowances[sender][msg.sender];
        _transfer(sender, recipient, amount);
        require(allowance_ >= amount);
        _approve(sender, msg.sender, allowance_ - amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    receive() external payable {
        require(
            msg.sender == _pancakeRouterAddress ||
                msg.sender == owner() ||
                msg.sender == _devWallet
        );
    }

    function allTaxes() external view returns (uint256 liquidityTax) {
        liquidityTax = _liquidityTax;
    }

    function antiBotTimeLeft() external view returns (uint256) {
        return
            _antiBotTimer > block.timestamp
                ? _antiBotTimer - block.timestamp
                : 0;
    }

    function nextSellOf(address account) external view returns (uint256) {
        return
            _holders[account].nextSell > block.timestamp
                ? _holders[account].nextSell - block.timestamp
                : 0;
    }

    function totalTokensHeld() external view returns (uint256) {
        return _totalTokensHeld;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function name() external pure override returns (string memory) {
        return "Tick a Lock";
    }

    function symbol() external pure override returns (string memory) {
        return "TIALO";
    }

    //totalSupply() pure function returns _initialSupply
    function totalSupply() external pure override returns (uint256) {
        return _initialSupply;
    }

    function decimals() external pure override returns (uint8) {
        return 9;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    //Puzzle Functions
    struct Guess {
        address guesser;
        string guess;
        uint256 timestamp;
        bool hasBeenSubmitted;
    }

    struct PuzzleWeek {
        uint256 puzzleId;
        string solution;
        address walletThatSolved; //defaults to burnAddress if puzzle not solved
        bool puzzleSolved;
    }

    struct LetterGuessed {
        address guesser;
        string letter;
        uint256 timestamp;
        bool isLetterGuessed;
    }

    struct Coordinate {
        uint256 x;
        uint256 y;
    }

    //create a list of PuzzleGuesses tied to the current puzzleWeek and the wallet address
    //week - address - int - Guess count
    mapping(uint256 => mapping(address => uint256)) public _addressGuessCount;
    //week - string (guess hash) - Guess
    mapping(uint256 => mapping(bytes32 => Guess)) public _puzzleGuesses;
    //week - address - guesses
    mapping(uint256 => mapping(address => string[])) public _puzzleGuessesForAddress;
    //Store a full array of puzzleGuesses for each puzzleWeek
    mapping(uint256 => Guess[]) public _puzzleWeekFullGuessList;
    //Store a counter for each weeks total guesses
    mapping(uint256 => uint256) public _puzzleWeekGuessCount;
    //create a list of PuzzleWeeks
    mapping(uint256 => PuzzleWeek) public _puzzleWeek;
    uint256 public _guessCount = 3;

    //CROSSWORD
    //create an array of all letters of the alphabet
    string[] public _alphabet = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"];
    
    //function to return a deterministic hash given an x and y coordinate
    function getDeterministicCoordinateHash(uint256 x, uint256 y) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(x, y));
    } 
    mapping(uint256 => mapping(bytes32 => Coordinate)) public _coordinatesForWeek;
    //week - coordinate hash - letter
    mapping(uint256 => mapping(bytes32 => mapping(string => LetterGuessed))) public _crossWordLetterGuesses;
    //week - coordinate hash - address
    mapping(uint256 => mapping(bytes32 => mapping(address => uint256))) public _guessCountOfCoordinate; 

    function setGuessCount(uint256 guessCount) public onlyDev {
        _guessCount = guessCount;
    }

    function setCoordinatesForWeek(uint256 week, Coordinate[] memory coordinates) public onlyDev {
        for (uint256 i = 0; i < coordinates.length; i++) {
            _coordinatesForWeek[week][getDeterministicCoordinateHash(coordinates[i].x, coordinates[i].y)] = coordinates[i];
        }
    }

    function setCrosswordLetterCost(uint256 cost) public onlyDev {
        _crosswordLetterCost = cost * 10**9;
    }

    function enableCrossWord(bool enable) public onlyDev {
        _crosswordEnabled = enable;
        emit OwnerEnableCrossword(enable);
    }

    function setCrosswordGuessesPerCoordinate(uint256 guesses) public onlyDev {
        _crosswordGuessesPerCoordinate = guesses;
    }

    function enablePuzzle(bool enable) public onlyDev {
        _puzzleEnabled = enable;
        emit OwnerEnablePuzzle(enable);
    }

    function submitCrosswordLetter(uint256 xCoordinate, uint256 yCoordinate, string memory letter) public payable {
        require(_crosswordEnabled, "Crossword is not enabled");
        //Must have enough to pay the cost of the letter
        require(_balances[msg.sender] >= _crosswordLetterCost, "You do not have enough to pay the cost of the letter.");
        _transferExcluded(msg.sender, address(this), _crosswordLetterCost);
        //50% goes to crossword-pot
        _totalAllocatedCrosswordPotContract += _crosswordLetterCost / 2;
        //25% goes to the marketing wallet
        _totalAllocatedMarketingContract += _crosswordLetterCost / 4;
        //25% goes to the LP
        _totalAllocatedLiquidityContract += _crosswordLetterCost / 4;
        //cast letter to lowercase
        string memory lowercaseLetter = _toLower(letter);
        //bool if letter is in the alphabet
        bool isInAlphabet = false;
        //iterate through letters and see if lowercaseLetter is in the array
        for(uint256 i = 0; i < _alphabet.length; i++) {
            if(compareStrings(lowercaseLetter, _alphabet[i])) {
                isInAlphabet = true;
            }
        }
        require(
            isInAlphabet,
            "Letter does not exist in the alphabet"
        );
        bool isInCoordinates = false;
        //see if mapping exists
        if(_coordinatesForWeek[_currentPuzzleWeek][getDeterministicCoordinateHash(xCoordinate, yCoordinate)].x != 0 && _coordinatesForWeek[_currentPuzzleWeek][getDeterministicCoordinateHash(xCoordinate, yCoordinate)].y != 0) {
            isInCoordinates = true;
        }
        require(
            isInCoordinates,
            "Coordinates are not part of the current weeks crossword"
        );
        //see if letter has already been submitted
        bool isLetterAlreadySubmitted = false;
        if(_crossWordLetterGuesses[_currentPuzzleWeek][getDeterministicCoordinateHash(xCoordinate, yCoordinate)][lowercaseLetter].isLetterGuessed) {
            isLetterAlreadySubmitted = true;
        }
        require(_guessCountOfCoordinate[_currentPuzzleWeek][getDeterministicCoordinateHash(xCoordinate, yCoordinate)][msg.sender] < _crosswordGuessesPerCoordinate, "You have exceeded your guesses for this coordinate.");
        require(
            !isLetterAlreadySubmitted,
            "Letter has already been submitted"
        );
        //set the letter
        _crossWordLetterGuesses[_currentPuzzleWeek][getDeterministicCoordinateHash(xCoordinate, yCoordinate)][lowercaseLetter] = LetterGuessed(
            msg.sender,
            lowercaseLetter,
            block.timestamp,
            true
        );
        //increase guess count for sender on this coordinate
        _guessCountOfCoordinate[_currentPuzzleWeek][getDeterministicCoordinateHash(xCoordinate, yCoordinate)][msg.sender]++;
        emit LetterSubmitted(lowercaseLetter);
    }

    //create a function to return an index between 0 and 25 given a letter
    function _getIndexOfLetter(string memory letter) public view returns (uint256 index) {
        string memory lowercaseLetter = _toLower(letter);
        bool isInAlphabet = false;
        for(uint256 i = 0; i < _alphabet.length; i++) {
            if(compareStrings(lowercaseLetter, _alphabet[i])) {
                isInAlphabet = true;
            }
        }
        require(
            isInAlphabet,
            "Letter does not exist in the alphabet"
        );
        for(uint256 i = 0; i < _alphabet.length; i++) {
            if(compareStrings(letter, _alphabet[i])) {
                return i;
            }
        }
    }
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    

    function setMinHoldingsForGuess(uint256 minHoldingsForGuess) public onlyDev {
        _minHoldingsForGuess = minHoldingsForGuess * 10**9;
    }

    function setMinGuessLength(uint256 minGuessLength) public onlyDev {
        _minGuessLength = minGuessLength;
    }

    function submitGuess(string memory _guess) public {
        require(_puzzleEnabled, "Puzzle is not enabled");
        //require msg sender to have enough tokens to submit a guess from their current balance and those tokens purchased through pancakeswap
        require(_balances[msg.sender] >= _minHoldingsForGuess && _holders[msg.sender].pancakeswapTotalPurchased >= _minHoldingsForGuess, "You must hold and have purchased the minimum amount of tokens.");
        //if the wallet has submitted three guesses for the current puzzleWeek, guesses cannot be submitted
        require(
            _addressGuessCount[_currentPuzzleWeek][msg.sender] < _guessCount,
            "Guesses for the current puzzle week cannot be submitted after three have been submitted for the current puzzle week."
        );
        //guess can only be up to 60 characters
        require(
            bytes(_guess).length <= _minGuessLength,
            "Guess cannot exceeds character length _minGuessLength."
        );
        //convert _guess to lowercase letters
        string memory lowercaseGuess = _toLower(_guess);
        bytes32 guessHash = getHashOfGuess(lowercaseGuess);
        require(!_puzzleGuesses[_currentPuzzleWeek][guessHash].hasBeenSubmitted, "Guess has already been submitted");

        _puzzleGuesses[_currentPuzzleWeek][guessHash] = Guess({
                guesser: msg.sender,
                guess: _guess,
                timestamp: block.timestamp,
                hasBeenSubmitted: true
            });
        _puzzleWeekFullGuessList[_currentPuzzleWeek].push(
            Guess({
                guesser: msg.sender,
                guess: _guess,
                timestamp: block.timestamp, 
                hasBeenSubmitted: true
            })
        );
        _puzzleGuessesForAddress[_currentPuzzleWeek][msg.sender].push(_guess);
        //increate _guessCount for sender by 1
        _addressGuessCount[_currentPuzzleWeek][msg.sender]++;
        //increate _puzzleWeekGuessCount by 1
        _puzzleWeekGuessCount[_currentPuzzleWeek]++;
        emit GuessSubmitted(_guess);
    }

    function getHashOfGuess(string memory guess) public pure returns (bytes32) {
        return keccak256(abi.encodePacked((guess)));
    }

    function setPuzzleWeek() private {
        //increment the current puzzleWeek by 1
        _currentPuzzleWeek = _currentPuzzleWeek + 1;
    }

    //set puzzle solved, should be burn address if the puzzle was not solved, also set solved for crossword
    function setPuzzleSolved(
        bool isSolved,
        bool isSolvedCrossword,
        string memory answer,
        address[] memory crossWordWinningWallets,
        address addressThatSolved
    ) public onlyDev {
        //0.24% of the prizeTokens are sent to the winner
        uint256 prizeTokens = getPrizeTokens();
        uint256 prizeAllotment = _totalSupply24 / 48; //48 weeks of prizes
        uint256 crossWordBonusPrizeTokens = 0;
        require(
            prizeTokens >= prizeAllotment,
            "Not enough tokens to distribute prize."
        );
        address _addressThatSolved = addressThatSolved;
        if(isSolvedCrossword) {
            reduceLPTax();
        }
        if (isSolved) {
            reduceLPTax();
            _addressThatSolved = addressThatSolved;
        } else {
            _addressThatSolved = _burnWallet;
        }
        //if the crossword was solved, split prizeAllotment in half
        if(isSolvedCrossword) {
            uint256 halfOfPrizeAllotment = prizeAllotment / 2;
            //prizeAllotment gets split in half
            prizeAllotment = prizeAllotment - halfOfPrizeAllotment;
            crossWordBonusPrizeTokens = halfOfPrizeAllotment;
            //divide the crossWordBonusPrizeTokens among crossWordWinningWallets
            uint256 crossWordBonusPrizeAllotment = (crossWordBonusPrizeTokens + _totalAllocatedCrosswordPotContract) / crossWordWinningWallets.length;
            for(uint256 i = 0; i < crossWordWinningWallets.length; i++) {
                _transferExcluded(address(this), crossWordWinningWallets[i], crossWordBonusPrizeAllotment);
            }
            _totalAllocatedCrosswordPotContract = 0;
        }
        //send prize tokens to the wallet that solved the puzzle
        _transferExcluded(address(this), _addressThatSolved, prizeAllotment);

        //burn the contracts alloted burn tokens
        if(_tokensToBurn > 0) {
            burnTokenContractTokens();
        }
        //create a PuzzleWeek object and assign it to the current puzzleWeek
        PuzzleWeek memory puzzleWeek = PuzzleWeek({
            puzzleId: _currentPuzzleWeek,
            solution: answer,
            walletThatSolved: _addressThatSolved,
            puzzleSolved: isSolved
        });
        _puzzleWeek[_currentPuzzleWeek] = puzzleWeek;

        //increment the current puzzle week
        setPuzzleWeek();
    }

    function burnTokenContractTokens() private {
        //burn the tokens that were allocated to the contract
        _transferExcluded(
            address(this),
            _burnWallet,
            _tokensToBurn
        );
        _tokensToBurn = 0;
    }
}