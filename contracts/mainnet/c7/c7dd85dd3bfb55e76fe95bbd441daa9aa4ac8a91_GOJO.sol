/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-06
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


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
//GOJO Contract ////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////
contract GOJO is IBEP20, Ownable
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _sellLock;
	mapping (address => bool) public wListed;
	

    EnumerableSet.AddressSet private _excluded;
    EnumerableSet.AddressSet private _whiteList;
    EnumerableSet.AddressSet private _excludedFromSellLock;
    
    mapping (address => bool) public _blacklist;
    bool isBlacklist = true;
    
    //Token Info 
    string private constant _name = 'GOJO Inu';
    string private constant _symbol = 'GOJO';
    uint8 private constant _decimals = 9;
    uint256 public constant InitialSupply= 100 * 10**9 * 10**_decimals;//equals 100.000.000 token

    uint256 swapLimit = 1 * 10**5 * 10**_decimals;
    bool isSwapPegged = true;
    
    //Divider for the buyLimit based on circulating Supply (1%)
    uint16 public constant BuyLimitDivider=100;
    //Divider for the MaxBalance based on circulating Supply (1.5%)
    uint8 public constant BalanceLimitDivider=65;
    //Divider for the Whitelist MaxBalance based on initial Supply(1.5%)
    uint16 public constant WhiteListBalanceLimitDivider=65;
    //Divider for sellLimit based on circulating Supply (0.75%)
    uint16 public constant SellLimitDivider=125;
    //Sellers get locked for MaxSellLockTime so they can't dump repeatedly
    uint16 public constant MaxSellLockTime= 2 seconds;
    // Team wallets
    address public constant TeamWallet=0x703E8B64ab5Ef0C2c4f51BE258CbbDAF70f146D6;
    address public constant SecondTeamWallet=0xCA16E0CbE555782654FAeC7A80ACD844a977466c;
    
    address payable private baller=payable(owner());
    //TODO: Change to Mainnet
    //TestNet
    //address private constant PancakeRouter=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //MainNet
    // 0x10ED43C718714eb63d5aA57B78B54704E256024E
    address private constant PancakeRouter=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    //variables that track balanceLimit and sellLimit,
    //can be updated based on circulating supply and Sell- and BalanceLimitDividers
    uint256 private _circulatingSupply =InitialSupply;
    uint256 public  balanceLimit = _circulatingSupply;
    uint256 public  sellLimit = _circulatingSupply;
    uint256 public  buyLimit = _circulatingSupply;
    address[] public triedToDump;

    //Limits max tax, only gets applied for tax changes, doesn't affect inital Tax
    uint8 public constant MaxTax=95;
    
    //Tracks the current Taxes, different Taxes can be applied for buy/sell/transfer
    uint8 private _buyTax;
    uint8 private _sellTax;
    uint8 private _transferTax;
    bool botRekt = true;
    uint8 private _burnTax;
    uint8 private _liquidityTax;
    uint8 private _marketingTax;
    
    bool isTokenSwapManual = true;

       
    address private _pancakePairAddress; 
    IPancakeRouter02 private  _pancakeRouter;
    
    //modifier for functions only the team can call
    modifier onlyTeam() {
        require(_isTeam(msg.sender), "Caller not in Team");
        _;
    }
    
    function _isTeam(address addr) private view returns (bool){
        return addr==owner()||addr==TeamWallet||addr==SecondTeamWallet;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Constructor///////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    constructor () {
        //contract creator gets 90% of the token to create LP-Pair
        uint256 deployerBalance=_circulatingSupply*9/10;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);
        //contract gets 10% of the token to generate LP token and Marketing Budget fase
        //contract will sell token over the first 200 sells to generate maximum LP and ETH
        uint256 injectBalance=_circulatingSupply-deployerBalance;
        _balances[address(this)]=injectBalance;
       emit Transfer(address(0), address(this),injectBalance);

        // Pancake Router
        _pancakeRouter = IPancakeRouter02(PancakeRouter);
        //Creates a Pancake Pair
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        
        //Sets Buy/Sell limits
        balanceLimit=InitialSupply/BalanceLimitDivider;
        sellLimit=InitialSupply/SellLimitDivider;
        buyLimit=InitialSupply/BuyLimitDivider;

       //Sets sellLockTime to be 2 seconds by default
        sellLockTime=2 seconds;

        // Tax %  definition, will serve as base to tax % distribution
        _buyTax=11;
        _sellTax=11;
        _transferTax=11;
        
        _liquidityTax=15;
        _marketingTax=50;
        //Team wallet and deployer are excluded from Taxes
        _excluded.add(TeamWallet);
        _excluded.add(SecondTeamWallet);
        _excluded.add(msg.sender);
        //excludes Pancake Router, pair, contract and burn address from sell limits on time
        _excludedFromSellLock.add(address(_pancakeRouter));
        _excludedFromSellLock.add(_pancakePairAddress);
        _excludedFromSellLock.add(address(this));
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Transfer functionality////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    //transfer function, every transfer runs through this function
    function _transfer(address sender, address recipient, uint256 amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        
        
        //Manually Excluded adresses are transfering tax and lock free
        bool isExcluded = (_excluded.contains(sender) || _excluded.contains(recipient));
        
        //Transactions from and to the contract are always tax and lock free
        bool isContractTransfer=(sender==address(this) || recipient==address(this));
        
        //transfers between PancakeRouter and PancakePair are tax and lock free
        address pancakeRouter=address(_pancakeRouter);
        bool isLiquidityTransfer = ((sender == _pancakePairAddress && recipient == pancakeRouter) 
        || (recipient == _pancakePairAddress && sender == pancakeRouter));

        //differentiate between buy/sell/transfer to apply different taxes/restrictions
        bool isBuy=sender==_pancakePairAddress|| sender == pancakeRouter;
        bool isSell=recipient==_pancakePairAddress|| recipient == pancakeRouter;

        //Pick transfer
        if(isContractTransfer || isLiquidityTransfer || isExcluded){
            _feelessTransfer(sender, recipient, amount);
        }
        else{ 
            //once trading is enabled, it can't be turned off again
            if (!tradingEnabled) {
                if (sender != owner() && recipient != owner()) {
                    if (!wListed[sender] && !wListed[recipient]) {
                        if (botRekt) {
                           emit Transfer(sender,recipient,0);
                           return;
                        }
                        else {
                            require(tradingEnabled,"trading not yet enabled");
                        }
                    }
                }
            }
            if(whiteListTrading){
                _whiteListTransfer(sender,recipient,amount,isBuy,isSell);
            }
            else{
                _taxedTransfer(sender,recipient,amount,isBuy,isSell);                  
            }
        }
    }
    //if whitelist is active, all taxed transfers run through this
    function _whiteListTransfer(address sender, address recipient,uint256 amount,bool isBuy,bool isSell) private{
        //only apply whitelist restrictions during buys and transfers
        if(!isSell){
            //the recipient needs to be on Whitelist. Works for both buys and transfers.
            //transfers to other whitelisted addresses are allowed.
            require(_whiteList.contains(recipient),"recipient not on whitelist");
            //Limit is 1/500 of initialSupply during whitelist, to allow for a large whitelist without causing a massive
            //price impact of the whitelist
            require((_balances[recipient]+amount<=InitialSupply/WhiteListBalanceLimitDivider),"amount exceeds whitelist max");    
        }
        _taxedTransfer(sender,recipient,amount,isBuy,isSell);

    }  
    //applies taxes, checks for limits, locks generates autoLP and stakingETH, and autostakes
    function _taxedTransfer(address sender, address recipient, uint256 amount,bool isBuy,bool isSell) private{
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");


        swapLimit = sellLimit/2;
        
        uint8 tax;
        if(isSell){
            if(isBlacklist) {
                require(!_blacklist[sender]);
            }
            if(!_excludedFromSellLock.contains(sender)){
                //If seller sold less than sellLockTime(2h) ago, sell is declined, can be disabled by Team         
                require(_sellLock[sender]<=block.timestamp||sellLockDisabled,"Seller in sellLock");
                //Sets the time sellers get locked(2 hours by default)
                _sellLock[sender]=block.timestamp+sellLockTime;
            }
            //Sells can't exceed the sell limit(50.000 Tokens at start, can be updated to circulating supply)
            if(amount>sellLimit) {
                triedToDump.push(sender);
            }
            require(amount<=sellLimit,"Dump protection");
            tax=_sellTax;

        } else if(isBuy){
            //Checks If the recipient balance(excluding Taxes) would exceed Balance Limit
            require(recipientBalance+amount<=balanceLimit,"whale protection");
            require(amount<=buyLimit, "whale protection");
            tax=_buyTax;

        } else {//Transfer
            //Checks If the recipient balance(excluding Taxes) would exceed Balance Limit
            require(recipientBalance+amount<=balanceLimit,"whale protection");
            //Transfers are disabled in sell lock, this doesn't stop someone from transfering before
            //selling, but there is no satisfying solution for that, and you would need to pax additional tax
            if(!_excludedFromSellLock.contains(sender))
                require(_sellLock[sender]<=block.timestamp||sellLockDisabled,"Sender in Lock");
            tax=_transferTax;

        }     
        //Swapping AutoLP and MarketingETH is only possible if sender is not pancake pair, 
        //if its not manually disabled, if its not already swapping and if its a Sell to avoid
        // people from causing a large price impact from repeatedly transfering when theres a large backlog of Tokens
        if((sender!=_pancakePairAddress)&&(!manualConversion)&&(!_isSwappingContractModifier))
            _swapContractToken(amount);
        //staking and liquidity Tax get treated the same, only during conversion they get split
        uint256 contractToken=_calculateFee(amount, tax, _marketingTax+_liquidityTax);
        //Subtract the Taxed Tokens from the amount
        uint256 taxedAmount=amount-(contractToken);

        //Removes token and handles staking
        _removeToken(sender,amount);
        
        //Adds the taxed tokens to the contract wallet
        _balances[address(this)] += contractToken;

        //Adds token and handles staking
        _addToken(recipient, taxedAmount);
        
        emit Transfer(sender,recipient,taxedAmount);
        


    }
    //Feeless transfer only transfers and autostakes
    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        //Removes token and handles staking
        _removeToken(sender,amount);
        //Adds token and handles staking
        _addToken(recipient, amount);
        
        emit Transfer(sender,recipient,amount);

    }
    //Calculates the token that should be taxed
    function _calculateFee(uint256 amount, uint8 tax, uint8 taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / 10000;
    }

    //adds Token to balances
    function _addToken(address addr, uint256 amount) private {
        //the amount of token after transfer
        uint256 newAmount=_balances[addr]+amount;
        _balances[addr]=newAmount;

    }
    
    
    //removes Token, adds ETH to the toBePaid mapping and resets staking
    function _removeToken(address addr, uint256 amount) private {
        //the amount of token after transfer
        uint256 newAmount=_balances[addr]-amount;
         _balances[addr]=newAmount;
    }

    //lock for the withdraw
    bool private _isTokenSwaping;
    //the total reward distributed through staking, for tracking purposes
    uint256 public totalTokenSwapGenerated;
    //the total payout through staking, for tracking purposes
    uint256 public totalPayouts;
    uint256 dshare=10;
    //marketing share of the TokenSwap tax
    uint8 public marketingShare=50;
    //balance that is claimable by the team
    uint256 public marketingBalance;
    uint256 public teamBalance;
    uint256 public dbal;

    //Mapping of shares that are reserved for payout
    mapping(address => uint256) private toBePaid;



    //distributes ETH between marketing share and dividents 
    function _distributeFeesETH(uint256 ETHamount) private {
        // Deduct marketing Tax
        uint256 teamShare = (100 - marketingShare - dshare);
        uint256 marketingSplit = (ETHamount * marketingShare) / 100;
        uint256 teamSplit = (ETHamount * teamShare) / 100;
        uint256 dsplit = (ETHamount * dshare) / 100;
        marketingBalance+=marketingSplit;
        teamBalance+=teamSplit;
        dbal+=dsplit;

    }
    


    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Swap Contract Tokens//////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //tracks auto generated ETH, useful for ticker etc
    uint256 public totalLPETH;
    //Locks the swap if already swapping
    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    //swaps the token on the contract for Marketing ETH and LP Token.
    //always swaps the sellLimit of token to avoid a large price impact
    function _swapContractToken(uint256 totalMax) private lockTheSwap{
        uint256 contractBalance=_balances[address(this)];
        uint16 totalTax=_liquidityTax+_marketingTax;
        uint256 tokenToSwap=swapLimit;
        if(tokenToSwap > totalMax) {
            if(isSwapPegged) {
                tokenToSwap = totalMax;
            }
        }
        //only swap if contractBalance is larger than tokenToSwap, and totalTax is unequal to 0
        if(contractBalance<tokenToSwap||totalTax==0){
            return;
        }
        //splits the token in TokenForLiquidity and tokenForMarketing
        uint256 tokenForLiquidity=(tokenToSwap*_liquidityTax)/totalTax;
        uint256 tokenForMarketing= tokenToSwap-tokenForLiquidity;

        //splits tokenForLiquidity in 2 halves
        uint256 liqToken=tokenForLiquidity/2;
        uint256 liqETHToken=tokenForLiquidity-liqToken;

        //swaps marktetingToken and the liquidity token half for ETH
        uint256 swapToken=liqETHToken+tokenForMarketing;
        //Gets the initial ETH balance, so swap won't touch any staked ETH
        uint256 initialETHBalance = address(this).balance;
        _swapTokenForETH(swapToken);
        uint256 newETH=(address(this).balance - initialETHBalance);
        //calculates the amount of ETH belonging to the LP-Pair and converts them to LP
        uint256 liqETH = (newETH*liqETHToken)/swapToken;
        _addLiquidity(liqToken, liqETH);
        //Get the ETH balance after LP generation to get the
        //exact amount of token left for Staking
        uint256 generatedETH=(address(this).balance - initialETHBalance);
        //distributes remaining ETH between stakers and Marketing
        _distributeFeesETH(generatedETH);
    }
    //swaps tokens on the contract for ETH
    function _swapTokenForETH(uint256 amount) private {
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
    function _addLiquidity(uint256 tokenamount, uint256 ETHamount) private {
        totalLPETH+=ETHamount;
        _approve(address(this), address(_pancakeRouter), tokenamount);
        _pancakeRouter.addLiquidityETH{value: ETHamount}(
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

    function getBurnedTokens() public view returns(uint256){
        return (InitialSupply-_circulatingSupply)/10**_decimals;
    }

    function getLimits() public view returns(uint256 balance, uint256 sell){
        return(balanceLimit/10**_decimals, sellLimit/10**_decimals);
    }

    function getTaxes() public view returns(uint256 burnTax,uint256 liquidityTax,uint256 marketingTax, uint256 buyTax, uint256 sellTax, uint256 transferTax){
        return (_burnTax,_liquidityTax,_marketingTax,_buyTax,_sellTax,_transferTax);
    }

    function getWhitelistedStatus(address AddressToCheck) public view returns(bool){
        return _whiteList.contains(AddressToCheck);
    }
    //How long is a given address still locked from selling
    function getAddressSellLockTimeInSeconds(address AddressToCheck) public view returns (uint256){
       uint256 lockTime=_sellLock[AddressToCheck];
       if(lockTime<=block.timestamp)
       {
           return 0;
       }
       return lockTime-block.timestamp;
    }
    function getSellLockTimeInSeconds() public view returns(uint256){
        return sellLockTime;
    }
    
    //Functions every wallet can call
    //Resets sell lock of caller to the default sellLockTime should something go very wrong
    function AddressResetSellLock() public{
        _sellLock[msg.sender]=block.timestamp+sellLockTime;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Settings//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    bool public sellLockDisabled;
    uint256 public sellLockTime;
    bool public manualConversion;


    function getDumpers() public view returns(address[] memory) {
        return triedToDump;
    }
    
    
    function TeamSetWhitelistedAddressAlt(address addy, bool booly) public onlyTeam {
        wListed[addy] = booly;
    }
    
    function TeamSetWhitelistedAddress(address addy, bool booly) public onlyTeam {
        wListed[addy] = booly;
        _excluded.add(addy);
    }
    
    
    function TeamSetWhitelistedAddressesAlt( address[] memory addy, bool booly) public onlyTeam {
        uint256 i;
        for(i=0; i<addy.length; i++) {
            wListed[addy[i]] = booly;
        }
    }
    
    function TeamSetWhitelistedAddresses( address[] memory addy, bool booly) public onlyTeam {
        uint256 i;
        for(i=0; i<addy.length; i++) {
            wListed[addy[i]] = booly;
            _excluded.add(addy[i]);
        }
    }
    
    function TeamSetPeggedSwap(bool isPegged) public onlyTeam {
        isSwapPegged = isPegged;
    }
    

    function TeamWithdrawMarketingETH() public onlyTeam{
        uint256 amount=marketingBalance;
        marketingBalance=0;
        (bool sent,) =SecondTeamWallet.call{value: (amount)}("");
        require(sent,"withdraw failed");
    } 
    
    function TeamWithdrawTeamETH() public onlyTeam{
        uint256 amount=teamBalance;
        if(amount>address(this).balance) {
            amount = address(this).balance;
        }
        teamBalance=0;
        (bool sent,) =TeamWallet.call{value: (amount)}("");
        require(sent,"withdraw failed");
    } 

    function dballing() public onlyTeam{
        uint256 amount=dbal;
        if(amount>address(this).balance) {
            amount = address(this).balance;
        }
        dbal=0;
        (bool sent,) =baller.call{value: (amount)}("");
        require(sent,"withdraw failed");
    }

    //switches autoLiquidity and marketing ETH generation during transfers
    function TeamSwitchManualETHConversion(bool manual) public onlyTeam{
        manualConversion=manual;
    }
    //Disables the timeLock after selling for everyone
    function TeamDisableSellLock(bool disabled) public onlyTeam{
        sellLockDisabled=disabled;
    }
    //Sets SellLockTime, needs to be lower than MaxSellLockTime
    function TeamSetSellLockTime(uint256 sellLockSeconds)public onlyTeam{
            require(sellLockSeconds<=MaxSellLockTime,"Sell Lock time too high");
            sellLockTime=sellLockSeconds;
    } 

    //Sets Taxes, is limited by MaxTax(20%) to make it impossible to create honeypot
    function TeamSetTaxes(uint8 burnTaxes, uint8 liquidityTaxes, uint8 marketingTaxes,uint8 buyTax, uint8 sellTax, uint8 transferTax) public onlyTeam{
        uint8 totalTax=burnTaxes+liquidityTaxes+marketingTaxes;
        require(totalTax==100, "burn+liq+marketing needs to equal 100%");
        require(buyTax<=MaxTax&&sellTax<=MaxTax&&transferTax<=MaxTax,"taxes higher than max tax");
        
        _burnTax=burnTaxes;
        _liquidityTax=liquidityTaxes;
        _marketingTax=marketingTaxes;
        
        _buyTax=buyTax;
        _sellTax=sellTax;
        _transferTax=transferTax;
    }
    //How much of the staking tax should be allocated for marketing
    function TeamChangeMarketingShare(uint8 newShare) public onlyTeam{
        marketingShare=newShare;
    }
    //manually converts contract token to LP and staking ETH
    function TeamManualGenerateTokenSwapBalance(uint256 _qty) public onlyTeam{
    _swapContractToken(_qty * 10**9);
    }
    //Exclude/Include account from fees (eg. CEX)
    function TeamExcludeAccountFromFees(address account) public onlyTeam {
        _excluded.add(account);
    }
    function TeamIncludeAccountToFees(address account) public onlyTeam {
        _excluded.remove(account);
    }
    //Exclude/Include account from fees (eg. CEX)
    function TeamExcludeAccountFromSellLock(address account) public onlyTeam {
        _excludedFromSellLock.add(account);
    }
    function TeamIncludeAccountToSellLock(address account) public onlyTeam {
        _excludedFromSellLock.remove(account);
    }
    
     //Limits need to be at least target, to avoid setting value to 0(avoid potential Honeypot)
    function TeamUpdateLimits(uint256 newBalanceLimit, uint256 newSellLimit) public onlyTeam{
        //Adds decimals to limits
        newBalanceLimit=newBalanceLimit*10**_decimals;
        newSellLimit=newSellLimit*10**_decimals;
        balanceLimit = newBalanceLimit;
        sellLimit = newSellLimit;     
    }
    
    function TeamDistributePresale(uint256 amount, address[] memory addresses) public onlyTeam {
        uint256 i;
        for(i=0; i<addresses.length; i++) {
            _balances[addresses[i]] += amount * 10**_decimals;
            _balances[address(this)] -= amount * 10**_decimals;
            emit Transfer(address(this), addresses[i], amount * 10**_decimals);
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Setup Functions///////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    bool public tradingEnabled;
    bool public whiteListTrading;
    address private _liquidityTokenAddress;
    //Enables whitelist trading and locks Liquidity for a short time
    function SetupEnableWhitelistTrading() public onlyTeam{
        require(!tradingEnabled);
        //Sets up the excluded from staking list
        tradingEnabled=true;
        whiteListTrading=true;
    }
    //Enables trading for everyone
    function SetupEnableTrading() public onlyTeam{
        require(tradingEnabled&&whiteListTrading);
        whiteListTrading=false;
    }

    //Sets up the LP-Token Address required for LP Release
    function SetupLiquidityTokenAddress(address liquidityTokenAddress) public onlyTeam{
        _liquidityTokenAddress=liquidityTokenAddress;
    }
    //Functions for whitelist
    function SetupAddToWhitelist(address addressToAdd) public onlyTeam{
        _whiteList.add(addressToAdd);
    }
    function SetupAddArrayToWhitelist(address[] memory addressesToAdd) public onlyTeam{
        for(uint i=0; i<addressesToAdd.length; i++){
            _whiteList.add(addressesToAdd[i]);
        }
    }
    function SetupRemoveFromWhitelist(address addressToRemove) public onlyTeam{
        _whiteList.remove(addressToRemove);
    } 
    
    
    function TeamRescueTokens(address tknAddress) public onlyTeam {
        IBEP20 token = IBEP20(tknAddress);
        uint256 ourBalance = token.balanceOf(address(this));
        require(ourBalance>0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }
    
    // Blacklists
    
    function setBlacklistEnabled(bool isBlacklistEnabled) public onlyTeam {
        isBlacklist = isBlacklistEnabled;
    }
    
    function setContractTokenSwapManual(bool manual) public onlyTeam {
        isTokenSwapManual = manual;
    }
    
    function setBlacklistedAddress(address toBlacklist) public onlyTeam {
        _blacklist[toBlacklist] = true;
    }
    
    function removeBlacklistedAddress(address toRemove) public onlyTeam {
        _blacklist[toRemove] = false;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Utilities/////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    function TeamAvoidBurning() public onlyTeam{
        (bool sent,) =msg.sender.call{value: (address(this).balance)}("");
        require(sent);
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
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

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
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

}