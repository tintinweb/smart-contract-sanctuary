/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

/*
KEVLAR FINANCE (KVLR)

Twitter- @Kevlarfinance

Instagram- Kevlarfinance

Tiktok- @Kevlarfinance

Email- [email protected]

In Order To Withdraw Rewards Visit The Token on https://bscscan.com/token/0xa7b6874fc2a3602bc351fa3ece9ad10631f05fef#writeContract
go to contracts and visit the write section
connect your wallet that's holding Kevlar Finance Token to the website
find AAAWITHDRAW enter a contract address that you want to redeem your rewards too and click write
If you have any rewards you will receive them.

Example of Contract Address Rewards
0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c //Binance Pegged BTC
0x2170Ed0880ac9A755fd29B2688956BD959F933F8 //Binance Pegged ETH Is the default reward
0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 //Binance Pegged BUSD
0x55d398326f99059fF775485246999027B3197955 //Binance Pegged USDT

ALTERNATIVELY

You can transfer 0.001-0.00001 of Kevlar to a random wallet to redeem your rewards as well. This will on default redeem your staking rewards to ETH

*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBEP20 {

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);

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


abstract contract Ownable {
    address private _owner;

    //Strickly for testing purposes; team functions for function calls when contract fees are set permanently and no further edits of the contract are needed.
    //Function renounceOwnership() will be used for permanent renouncing of contract in the future.
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    //Strickly for testing purposes; team functions for function calls when contract fees are set permanently and no further edits of the contract are needed.
    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Strickly for testing purposes; team functions for function calls when contract fees are set permanently and no further edits of the contract are needed.
    //Locks the contract for owner for the amount of time provided
    function lock(uint256 timeSeconds) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + timeSeconds;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Strickly for testing purposes; team functions for function calls when contract fees are set permanently and no further edits of the contract are needed.
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked for 14 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

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

/*
*
*Kevlar Finance Contract
*
*/

contract Howdy is IBEP20, Ownable
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _sellLock;

    EnumerableSet.AddressSet private _excluded;
    EnumerableSet.AddressSet private _whiteList;

    //Everyone is to be subjected to the same restrictions, zero admins wallets will be part of the _excludedFromSellLock. Only exception will be Contract, and future exchanges
    EnumerableSet.AddressSet private _excludedFromSellLock;
    EnumerableSet.AddressSet private _excludedFromStaking;
    
    //TOKEN INFO
    string private constant _name = 'Howdy';
    string private constant _symbol = 'HWDY';
    uint8 private constant _decimals = 9;
    uint256 public constant InitialSupply = 888888888888888 * 1**1 * 10**_decimals;//equals 100.000.000.000.000 token 100 Trillion Tokens

    //Max Balance and Max Sell will be edited as Token Milestones are reached
    //Divider for the MaxBalance based on circulating Supply (2%) Starting Max Wallets
    uint8 public constant BalanceLimitDivider = 50;
    //Divider for the Whitelist MaxBalance based on initial Supply(0.2%)
    uint16 public constant WhiteListBalanceLimitDivider = 500;
    //Divider for sellLimit based on circulating Supply (0.2%)
    uint16 public constant SellLimitDivider = 500;
    //Sellers get locked for MaxSellLockTime so they can't dump repeatedly
    uint16 public constant MaxSellLockTime = 30 minutes;
    //The time Liquidity gets locked at start and prolonged once it gets released
    uint256 private constant DefaultLiquidityLockTime = 8 hours;

    //WALLET INFORMATION LOG
    //Address' for database
    //The Team Wallet which will be accessable to only the Founding Members
    address public constant TeamWallet = 0xCA8FB9235BAC9428113c011144ae877E92CC16d1;
    //TestNet
    //address private constant PancakeRouter=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //MainNet
    address private constant PancakeRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    //Dead Wallet for BuyBack and Burn
    address private constant DeadWallet = 0x000000000000000000000000000000000000dEaD;
    //Default Reward
    address private constant DefaultRewardAddress = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8; //Binanced Pegged ETH

    //TAXATION INFO
    //variables that track balanceLimit and sellLimit,
    //can be updated based on circulating supply and Sell- and BalanceLimitDividers
    uint256 private _circulatingSupply = InitialSupply;
    uint256 public  balanceLimit = _circulatingSupply;
    uint256 public  sellLimit = _circulatingSupply;

    //Limits max tax, only gets applied for tax changes, doesn't affect inital Tax - Tax can only ever go as high as 20%
    uint8 public constant MaxTax = 20;

    //Tracks the current Taxes, different Taxes can be applied for buy/sell/transfer
    uint8 private _buyTax;
    uint8 private _sellTax;
    uint8 private _transferTax;

    uint8 private _burnTax;
    uint8 private _liquidityTax;
    uint8 private _stakingTax;

    address private _pancakePairAddress; 
    IPancakeRouter02 private  _pancakeRouter;

    //modifier for functions only the team can call
    modifier onlyTeam() {
        require(_isTeam(msg.sender), "Caller not in Team");
        _;
    }

    //Checks if address is in Team, is needed to give Team access even if contract is renounced
    //Team doesn't have access to critical Functions that could turn this into a Rugpull(Exept liquidity unlocks)
    function _isTeam(address addr) private view returns (bool){
        return addr == owner() || addr == TeamWallet;
    }

    /*
    *
    *Constructor
    *
    */

    constructor () {
        uint256 deployerBalance = _circulatingSupply;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);

        // Pancake Router
        _pancakeRouter = IPancakeRouter02(PancakeRouter);
        //Creates a Pancake Pair
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());

        //Sets Buy/Sell limits
        balanceLimit = InitialSupply / BalanceLimitDivider;
        sellLimit = InitialSupply / SellLimitDivider;

       //Sets sellLockTime to be max by default
        sellLockTime = MaxSellLockTime;

        //any change in tax rate needs to be below maxTax(20%)
        _buyTax = 10;//Buy Tax is lower, as otherwise slippage would be too high to sell
        _sellTax = 20;
        _transferTax = 30;

        //a small percentage gets added to the Contract token as 10% of token are already injected to 
        //be converted to LP and MarketingBNB
        _burnTax = 0;
        _liquidityTax = 90;
        _stakingTax = 10;

        //Team wallet and deployer are excluded from Taxes
        _excluded.add(TeamWallet);
        _excluded.add(msg.sender);
        _excluded.add(0x000000000000000000000000000000000000dEaD);

        //excludes Pancake Router, pair, contract and burn address from staking
        _excludedFromStaking.add(address(_pancakeRouter));
        _excludedFromStaking.add(_pancakePairAddress);
        _excludedFromStaking.add(address(this));
        _excludedFromStaking.add(0x000000000000000000000000000000000000dEaD);
    }

    /*
    *
    *Transfer Functionality
    *
    */

    //transfer function, every transfer runs through this function
    function _transfer(address sender, address recipient, uint256 amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        
        //Manually Excluded adresses are transfering tax and lock free
        bool isExcluded = (_excluded.contains(sender) || _excluded.contains(recipient));
        
        //Transactions from and to the contract are always tax and lock free
        bool isContractTransfer = (sender == address(this) || recipient == address(this));
        
        //transfers between PancakeRouter and PancakePair are tax and lock free
        address pancakeRouter = address(_pancakeRouter);
        bool isLiquidityTransfer = ((sender == _pancakePairAddress && recipient == pancakeRouter) || (recipient == _pancakePairAddress && sender == pancakeRouter));

        //differentiate between buy/sell/transfer to apply different taxes/restrictions
        bool isBuy = sender == _pancakePairAddress || sender == pancakeRouter;
        bool isSell = recipient == _pancakePairAddress || recipient == pancakeRouter;

        //Pick transfer
        if(isContractTransfer || isLiquidityTransfer || isExcluded){
            _feelessTransfer(sender, recipient, amount);
        }
        else{ 
            //once trading is enabled, it can't be turned off again
            require(tradingEnabled,"trading not yet enabled");
            _taxedTransfer(sender,recipient,amount,isBuy,isSell);
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
            require((_balances[recipient] + amount <= InitialSupply / WhiteListBalanceLimitDivider),"amount exceeds whitelist max");    
        }
        _taxedTransfer(sender,recipient,amount,isBuy,isSell);
    } 
    //applies taxes, checks for limits, locks generates autoLP and stakingBNB, and autostakes
    function _taxedTransfer(address sender, address recipient, uint256 amount,bool isBuy,bool isSell) private{
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        uint8 tax;
        if(isSell){
            if(!_excludedFromSellLock.contains(sender)){
                //If seller sold less than sellLockTime(1h) ago, sell is declined, can be disabled by Team         
                require(_sellLock[sender] <= block.timestamp || sellLockDisabled,"Seller in sellLock");
                //Sets the time sellers get locked(1 hours by default)
                _sellLock[sender] = block.timestamp + sellLockTime;
            }

            //Sells can't exceed the sell limit(50.000 Tokens at start, can be updated to circulating supply)
            require(amount <= sellLimit,"Dump protection");
            tax = _sellTax;

        } else if(isBuy){
            //Checks If the recipient balance(excluding Taxes) would exceed Balance Limit
            require(recipientBalance + amount <= balanceLimit,"Whale protection");
            tax = _buyTax;

        } else {//Transfer
            //withdraws BNB when sending less or equal to 1 Token
            //that way you can withdraw without connecting to any dApp.
            //might needs higher gas limit
            if(amount <= 10**(_decimals)) Claim(sender, DefaultRewardAddress);
            //Checks If the recipient balance(excluding Taxes) would exceed Balance Limit
            require(recipientBalance + amount <= balanceLimit,"whale protection");
            //Transfers are disabled in sell lock, this doesn't stop someone from transfering before
            //selling, but there is no satisfying solution for that, and you would need to pax additional tax
            if(!_excludedFromSellLock.contains(sender))
                require(_sellLock[sender] <= block.timestamp || sellLockDisabled,"Sender in Lock");
            tax = _transferTax;
        }

        //Swapping AutoLP and MarketingBNB is only possible if sender is not pancake pair, 
        //if its not manually disabled, if its not already swapping and if its a Sell to avoid
        //people from causing a large price impact from repeatedly transfering when theres a large backlog of Tokens
        if((sender != _pancakePairAddress) && (!manualConversion) && (!_isSwappingContractModifier) && isSell)
            _swapContractToken();
        //Calculates the exact token amount for each tax
        uint256 tokensToBeBurnt = _calculateFee(amount, tax, _burnTax);
        //staking and liquidity Tax get treated the same, only during conversion they get split
        uint256 contractToken = _calculateFee(amount, tax, _stakingTax + _liquidityTax);
        //Subtract the Taxed Tokens from the amount
        uint256 taxedAmount = amount - (tokensToBeBurnt + contractToken);

        //Removes token and handles staking
        _removeToken(sender,amount);

        //Adds the taxed tokens to the contract wallet
        _balances[address(this)] += contractToken;

        //Burns tokens
        _circulatingSupply -= tokensToBeBurnt;

        //Adds token and handles staking
        _addToken(recipient, taxedAmount);

        emit Transfer(sender,recipient,taxedAmount);
    }

    //Feeless transfer only transfers and autostakes
    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        //Removes token and handles staking
        _removeToken(sender, amount);
        //Adds token and handles staking
        _addToken(recipient, amount);

        emit Transfer(sender,recipient,amount);
    }
    //Calculates the token that should be taxed
    function _calculateFee(uint256 amount, uint8 tax, uint8 taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / 10000;
    }

    /*
    *
    *Passive Staking
    *
    */

    //PassiveStaking uses the balances of each holder to redistribute auto generated BNB.
    //Each transaction _addToken and _removeToken gets called for the transaction amount
    //WithdrawBNB can be used for any holder to withdraw BNB at any time, like true Staking,
    //so unlike MRAT clones you can leave and forget your Token and claim after a while

    //lock for the withdraw
    bool private _isWithdrawing;
    //Multiplier to add some accuracy to profitPerShare
    uint256 private constant DistributionMultiplier = 2**64;
    //profit for each share a holder holds, a share equals a token.
    uint256 public profitPerShare;
    //the total reward distributed through staking, for tracking purposes
    uint256 public totalStakingReward;
    //the total payout through staking, for tracking purposes
    uint256 public totalPayouts;
    
    //marketing share starts at 85% to push initial marketing, after start
    //its capped to 60% max, the percentage of the staking that gets used for
    //marketing/paying the team
    uint8 public marketingShare = 85;
    //balance that is claimable by the team
    uint256 public marketingBalance;
    uint256 public buybackBalance;

    //Mapping of the already paid out(or missed) shares of each staker
    mapping(address => uint256) private alreadyPaidShares;
    //Mapping of shares that are reserved for payout
    mapping(address => uint256) private toBePaid;

    //Contract, pancake and burnAddress are excluded, other addresses like CEX
    //can be manually excluded, excluded list is limited to 30 entries to avoid a
    //out of gas exeption during sells
    function isExcludedFromStaking(address addr) public view returns (bool){
        return _excludedFromStaking.contains(addr);
    }

    //Total shares equals circulating supply minus excluded Balances
    function _getTotalShares() public view returns (uint256){
        uint256 shares=_circulatingSupply;
        //substracts all excluded from shares, excluded list is limited to 30
        // to avoid creating a Honeypot through OutOfGas exeption
        for(uint i = 0; i < _excludedFromStaking.length(); i++){
            shares -= _balances[_excludedFromStaking.at(i)];
        }
        return shares;
    }

    //adds Token to balances, adds new BNB to the toBePaid mapping and resets staking
    function _addToken(address addr, uint256 amount) private {
        //the amount of token after transfer
        uint256 newAmount = _balances[addr]+amount;

        if(isExcludedFromStaking(addr)){
           _balances[addr] = newAmount;
           return;
        }

        //gets the payout before the change
        uint256 payment = _newDividentsOf(addr);
        //resets dividents to 0 for newAmount
        alreadyPaidShares[addr] = profitPerShare * newAmount;
        //adds dividents to the toBePaid mapping
        toBePaid[addr] += payment; 
        //sets newBalance
        _balances[addr] = newAmount;
    }

    //removes Token, adds BNB to the toBePaid mapping and resets staking
    function _removeToken(address addr, uint256 amount) private {
        //the amount of token after transfer
        uint256 newAmount = _balances[addr] - amount;

        if(isExcludedFromStaking(addr)){
           _balances[addr] = newAmount;
           return;
        }

        //gets the payout before the change
        uint256 payment = _newDividentsOf(addr);
        //sets newBalance
        _balances[addr] = newAmount;
        //resets dividents to 0 for newAmount
        alreadyPaidShares[addr] = profitPerShare * newAmount;
        //adds dividents to the toBePaid mapping
        toBePaid[addr] += payment; 
    }

    //gets the not dividents of a staker that aren't in the toBePaid mapping 
    //returns wrong value for excluded accounts
    function _newDividentsOf(address staker) private view returns (uint256) {
        uint256 fullPayout = profitPerShare * _balances[staker];
        // if theres an overflow for some unexpected reason, return 0, instead of 
        // an exeption to still make trades possible
        if(fullPayout<alreadyPaidShares[staker]) return 0;
        return (fullPayout - alreadyPaidShares[staker]) / DistributionMultiplier;
    }

    //distributes bnb between marketing share and dividents 
    function _distributeStake(uint256 BNBamount) private {
        // Deduct marketing Tax
        uint256 marketingSplit = (BNBamount * marketingShare) / 100;
        uint256 buybackSplit = marketingSplit / 10;
        marketingSplit -= buybackSplit;
        uint256 amount = BNBamount - marketingSplit;

       marketingBalance += marketingSplit;
       buybackBalance += buybackSplit;

        if (amount > 0) {
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
    }

    event OnWithdraw(uint256 amount, address recipient);

    //withdraws all dividents of address
    function Claim(address addr, address contractaddress) private{
        require(!_isWithdrawing);
        _isWithdrawing = true;
        uint256 amount;
        if(isExcludedFromStaking(addr)){
            //if excluded just withdraw remaining toBePaid BNB
            amount = toBePaid[addr];
            toBePaid[addr] = 0;
        }

        else{
            uint256 newAmount=_newDividentsOf(addr);
            //sets payout mapping to current amount
            alreadyPaidShares[addr] = profitPerShare * _balances[addr];
            //the amount to be paid 
            amount = toBePaid[addr] + newAmount;
            toBePaid[addr] = 0;
        }

        if(amount == 0){//no withdraw if 0 amount
            _isWithdrawing = false;
            return;
        }

        totalPayouts += amount;
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH(); //BNB
        path[1] = contractaddress;

        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
        0,
        path,
        addr,
        block.timestamp);
        
        emit OnWithdraw(amount, addr);
        _isWithdrawing = false;
    }

    /*
    *
    *Swap Contract Tokens
    *
    */

    //tracks auto generated BNB, useful for ticker etc
    uint256 public totalLPBNB;
    //Locks the swap if already swapping
    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    //swaps the token on the contract for Marketing BNB and LP Token.
    //always swaps the sellLimit of token to avoid a large price impact
    function _swapContractToken() private lockTheSwap{
        uint256 contractBalance = _balances[address(this)];
        uint16 totalTax = _liquidityTax+_stakingTax;
        uint256 tokenToSwap = sellLimit;

        //only swap if contractBalance is larger than tokenToSwap, and totalTax is unequal to 0
        if(contractBalance < tokenToSwap || totalTax == 0){
            return;
        }
    
        //splits the token in TokenForLiquidity and tokenForMarketing
        uint256 tokenForLiquidity = (tokenToSwap * _liquidityTax) / totalTax;
        uint256 tokenForMarketing = tokenToSwap - tokenForLiquidity;

        //splits tokenForLiquidity in 2 halves
        uint256 liqToken = tokenForLiquidity / 2;
        uint256 liqBNBToken = tokenForLiquidity - liqToken;

        //swaps marktetingToken and the liquidity token half for BNB
        uint256 swapToken = liqBNBToken + tokenForMarketing;
        //Gets the initial BNB balance, so swap won't touch any staked BNB
        uint256 initialBNBBalance = address(this).balance;
        _swapTokenForBNB(swapToken);
        uint256 newBNB = (address(this).balance - initialBNBBalance);
        //calculates the amount of BNB belonging to the LP-Pair and converts them to LP
        uint256 liqBNB = (newBNB * liqBNBToken) / swapToken;
        _addLiquidity(liqToken, liqBNB);
        //Get the BNB balance after LP generation to get the
        //exact amount of token left for Staking
        uint256 distributeBNB = (address(this).balance - initialBNBBalance);
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

    /*
    *
    *Public Functions
    *
    */

    function getLiquidityReleaseTimeInSeconds() public view returns (uint256){
        if(block.timestamp < _liquidityUnlockTime){
            return _liquidityUnlockTime - block.timestamp;
        }
        return 0;
    }

    function getBurnedTokens() public view returns(uint256){
        return (InitialSupply - _circulatingSupply) / 10 ** _decimals;
    }

    function getLimits() public view returns(uint256 balance, uint256 sell){
        return(balanceLimit / 10 ** _decimals, sellLimit / 10 ** _decimals);
    }

    function getTaxes() public view returns(uint256 burnTax,uint256 liquidityTax,uint256 marketingTax, uint256 buyTax, uint256 sellTax, uint256 transferTax){
        return (_burnTax,_liquidityTax,_stakingTax,_buyTax,_sellTax,_transferTax);
    }

    function getWhitelistedStatus(address AddressToCheck) public view returns(bool){
        return _whiteList.contains(AddressToCheck);
    }

    //How long is a given address still locked from selling
    function getAddressSellLockTimeInSeconds(address AddressToCheck) public view returns (uint256){
       uint256 lockTime = _sellLock[AddressToCheck];
       if(lockTime <= block.timestamp)
       {
           return 0;
       }
       return lockTime - block.timestamp;
    }

    function getSellLockTimeInSeconds() public view returns(uint256){
        return sellLockTime;
    }

    //Functions every wallet can call
    //Resets sell lock of caller to the default sellLockTime should something go very wrong
    function AddressResetSellLock() public{
        _sellLock[msg.sender] = block.timestamp + sellLockTime;
    }

    //withdraws dividents of sender
    function AAAWithdraw(address contractaddress) public{
        Claim(msg.sender, contractaddress);
    }

    function getDividents(address addr) public view returns (uint256){
        if(isExcludedFromStaking(addr)) return toBePaid[addr];
        return _newDividentsOf(addr) + toBePaid[addr];
    }

    /*
    *
    *Settings
    *
    */

    bool public sellLockDisabled;
    uint256 public sellLockTime;
    bool public manualConversion;

    event BuyingBack(uint256 amount, address recipient);

    function TeamBuyBack() public onlyTeam{
        uint256 amount = buybackBalance;
        buybackBalance = 0;

        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH(); //BNB
        path[1] = address(this);

        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
        0,
        path,
        DeadWallet,
        block.timestamp);
        emit BuyingBack(amount, DeadWallet);
    }

    function TeamBuyBack(uint256 amount) public onlyTeam{
        require(amount <= buybackBalance);
        buybackBalance -= amount;

        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH(); //BNB
        path[1] = address(this);

        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
        0,
        path,
        DeadWallet,
        block.timestamp);
        emit BuyingBack(amount, DeadWallet);
    }

    //Excludes account from Staking
    function TeamExcludeFromStaking(address addr) public onlyTeam{
        //a long exluded list could lead to a Honeypot, therefore limit entries
        require(_excludedFromStaking.length() < 30);
        require(!isExcludedFromStaking(addr));
        uint256 newDividents = _newDividentsOf(addr);
        alreadyPaidShares[addr] = _balances[addr] * profitPerShare;
        toBePaid[addr] += newDividents;
        _excludedFromStaking.add(addr);
    }

    //Includes excluded Account to staking
    function TeamIncludeToStaking(address addr) public onlyTeam{
        require(isExcludedFromStaking(addr));
        _excludedFromStaking.remove(addr);
        //sets alreadyPaidShares to the current amount
        alreadyPaidShares[addr] = _balances[addr]*profitPerShare;
    }

    function TeamWithdrawMarketingBNB() public onlyTeam{
        uint256 amount = marketingBalance;
        marketingBalance = 0;
        (bool sent,) = TeamWallet.call{value: (amount)}("");
        require(sent,"withdraw failed");
    }

    function TeamWithdrawMarketingBNB(uint256 amount) public onlyTeam{
        require(amount <= marketingBalance);
        marketingBalance -= amount;
        (bool sent,) = TeamWallet.call{value: (amount)}("");
        require(sent,"withdraw failed");
    }

    //switches autoLiquidity and marketing BNB generation during transfers
    function TeamSwitchManualBNBConversion(bool manual) public onlyTeam{
        manualConversion = manual;
    }

    //Disables the timeLock after selling for everyone
    function TeamDisableSellLock(bool disabled) public onlyTeam{
        sellLockDisabled=disabled;
    }

    //Sets SellLockTime, needs to be lower than MaxSellLockTime
    function TeamSetSellLockTime(uint256 sellLockSeconds)public onlyTeam{
            require(sellLockSeconds <= MaxSellLockTime,"Sell Lock time too high");
            sellLockTime = sellLockSeconds;
    }

    //Sets Taxes, is limited by MaxTax (20%) to make it impossible to create honeypot
    function TeamSetTaxes(uint8 burnTaxes, uint8 liquidityTaxes, uint8 stakingTaxes,uint8 buyTax, uint8 sellTax, uint8 transferTax) public onlyTeam{
        uint8 totalTax = burnTaxes + liquidityTaxes + stakingTaxes;
        require(totalTax == 100, "burn+liq+marketing needs to equal 100%");
        require(buyTax <= MaxTax && sellTax <= MaxTax && transferTax <= MaxTax,"taxes higher than max tax");

        _burnTax = burnTaxes;
        _liquidityTax = liquidityTaxes;
        _stakingTax = stakingTaxes;

        _buyTax = buyTax;
        _sellTax = sellTax;
        _transferTax = transferTax;
    }

    //How much of the staking tax should be allocated for marketing
    function TeamChangeMarketingShare(uint8 newShare) public onlyTeam{
        require(newShare <= 60); 
        marketingShare = newShare;
    }

    //manually converts contract token to LP and staking BNB
    function TeamCreateLPandBNB() public onlyTeam{
        _swapContractToken();
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
        //SellLimit needs to be below current Max Wallet to avoid a Large Price impact when generating auto LP
        require(newSellLimit < _circulatingSupply/100);
        //Adds decimals to limits
        newBalanceLimit = newBalanceLimit * 10 ** _decimals;
        newSellLimit = newSellLimit * 10 ** _decimals;
        //Calculates the target Limits based on supply
        uint256 targetBalanceLimit = _circulatingSupply / BalanceLimitDivider;
        uint256 targetSellLimit = _circulatingSupply / SellLimitDivider;

        require((newBalanceLimit >= targetBalanceLimit),
        "newBalanceLimit needs to be at least target");
        require((newSellLimit >= targetSellLimit),
        "newSellLimit needs to be at least target");

        balanceLimit = newBalanceLimit;
        sellLimit = newSellLimit;
    }

    /*
    *
    *Trading Setup
    *
    */

    bool public tradingEnabled;
    address private _liquidityTokenAddress;
    //Enables trading for everyone
    function SetupEnableTrading() public onlyTeam{
        tradingEnabled = true;
        _liquidityUnlockTime = block.timestamp + 7 days;
    }

    //Sets up the LP-Token Address required for LP Release
    function SetupLiquidityTokenAddress(address liquidityTokenAddress) public onlyTeam{
        _liquidityTokenAddress = liquidityTokenAddress;
    }

    /*
    *
    *Liquidity Protection
    *
    */

    //the timestamp when Liquidity unlocks
    uint256 private _liquidityUnlockTime;

    //Sets Liquidity Release to 20% at a time and prolongs liquidity Lock for a Week after Release. 
    //Should be called once start was successful.
    bool public liquidityRelease20Percent;
    function TeamlimitLiquidityReleaseTo20Percent() public onlyTeam{
        liquidityRelease20Percent = true;
    }

    function TeamUnlockLiquidityInSeconds(uint256 secondsUntilUnlock) public onlyOwner{
        _prolongLiquidityLock(secondsUntilUnlock + block.timestamp);
    }

    function _prolongLiquidityLock(uint256 newUnlockTime) private{
        // require new unlock time to be longer than old one
        require(newUnlockTime > _liquidityUnlockTime);
        _liquidityUnlockTime = newUnlockTime;
    }

    //Release Liquidity Tokens once unlock time is over
    function TeamReleaseLiquidity() public onlyTeam {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        
        IPancakeERC20 liquidityToken = IPancakeERC20(_liquidityTokenAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
        if(liquidityRelease20Percent)
        {
            _liquidityUnlockTime = block.timestamp+DefaultLiquidityLockTime;
            //regular liquidity release, only releases 20% at a time and locks liquidity for another 5 days
            amount = amount * 2 / 10;
            liquidityToken.transfer(TeamWallet, amount);
        }
        else
        {
            //Liquidity release if something goes wrong at start
            //liquidityRelease20Percent should be called once everything is clear
            liquidityToken.transfer(TeamWallet, amount);
        }
    }

    //Removes Liquidity once unlock Time is over, 
    function TeamRemoveLiquidity(bool addToStaking) public onlyTeam {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        _liquidityUnlockTime = block.timestamp + DefaultLiquidityLockTime;
        IPancakeERC20 liquidityToken = IPancakeERC20(_liquidityTokenAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
        if(liquidityRelease20Percent){
            amount = amount * 2 / 10; //only remove 20% each
        }
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
        if(addToStaking){
            _distributeStake(newBNBBalance);
        }
        else{
            marketingBalance += newBNBBalance;
        }
    }

    //Releases all remaining BNB on the contract wallet, so BNB wont be burned
    function TeamRemoveRemainingBNB() public onlyTeam{
        require(block.timestamp >= _liquidityUnlockTime + 5 days, "Not yet unlocked");
        _liquidityUnlockTime = block.timestamp + DefaultLiquidityLockTime;
        (bool sent,) = TeamWallet.call{value: (address(this).balance)}("");
        require(sent);
    }

    /*
    *
    *External
    *
    */

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