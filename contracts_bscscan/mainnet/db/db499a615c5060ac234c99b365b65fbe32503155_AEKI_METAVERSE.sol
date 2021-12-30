/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * IERC20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * ReentrancyGuard
 */
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

/**
 * SafeMath
 * Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 */
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * Context
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

/**
 * Address
 * Collection of functions related to the address type
 */
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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
 * Ownable
 * Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 */
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

/**
 * IUniswapV2Factory
 */
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

/**
 * IUniswapV2Pair
 */
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

/**
 * IUniswapV2Router01
 */
interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

/**
 * IUniswapV2Router02
 */
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

library EnumerableSet {
    

    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
      
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { 
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = valueIndex;

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set
    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet
    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet
    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


contract AEKI_METAVERSE is Context, IERC20, Ownable, ReentrancyGuard {
    // Import our libraries
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    // Mapping and addressSets
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromReward;
    EnumerableSet.AddressSet private _excludedFromSellLock;
    mapping (address => uint256) private _sellLock;
    EnumerableSet.AddressSet private _excludedFromBuyLock;
    mapping (address => uint256) private _buyLock;
    address[] private _excludedFromReward;

    // Addresses
    address devWallet_Address = 0x62EAD344Fa320D16752c125c78517B3e3de41d71 ; 
    address MARKETING_ADDRESS = 0xC42158fE735591701040Ed0a7f2fE9594a357241;
    address Burn_ADDRESS = 0x000000000000000000000000000000000000dEaD ; 
    address private constant ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    // Token name
    string private _name = "AEKI METAVERSE";
    string private _symbol = "$AEKI" ; 
     
    // Decimals
    uint256 private _decimals = 8;

    // Max supply
    // @note: 10**9 means a 1 with 9 zeroes.  
    // @note: 1 * 10**9 is 1 with 9 decimals.
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000000000 * 10**8;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint public maxTransferAmountRate = 10;
    // Max TX in tokens
    uint256 public _maxSellTxAmount ; 
     function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(1000);
    }
mapping(address => bool) private _excludedFromAntiWhale;

    // ANTI WHALE 
     modifier antiWhale(address sender, address recipient, uint256 amount) {
        if (maxTransferAmount()>= 0) {
            if (
                _excludedFromAntiWhale[sender] == false
                && _excludedFromAntiWhale[recipient] == false
            ) {				
                require(amount <= maxTransferAmount(), "$AEKI::antiWhale: Transfer amount exceeds the maxTransferAmount");
                 
            }
        }
        _;
    }
    function changeMaxTransferAmountRate(uint _maxtransferAmount) public onlyOwner{
                  maxTransferAmountRate = _maxtransferAmount ; 
    }
     // Buy tax in percentage
    uint256 private BurnFeeBuy = 2;
    uint256 private MarketingFeeBuy = 5;
    uint256 private rewardFeeBuy = 3;
    uint256 private totalFeeBuy = 10;

    // Sell tax in percentage
    uint256 private BurnFeeSell = 7;
    uint256 private MarketingFeeSell = 10;
    uint256 private rewardFeeSell = 3;
    uint256 private totalFeeSell = 20;

    // Cooldowns
    uint public constant  MaxSellLockTime = 1 days;
    
    // tax variables #TODO: Implement devFee or give it another name
    uint256 private _tHODLrRewardsTotal;
    uint256 private _rewardFee;
    uint256 private _previousRewardFee;
    uint256 private _MarketingFee;
    uint256 private _previousMarketingFee;
    uint256 private _BurnFee;
    uint256 private _previousBurnFee;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    event TransferMarketing(address indexed from, address indexed MarketingAddress, uint256 value);

    /* Constructor */
    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        // Setup Router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(ROUTER_ADDRESS);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        // Exclude
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromReward[address(this)] = true;
        _isExcludedFromFee[MARKETING_ADDRESS] = true;
        _isExcludedFromFee[devWallet_Address] = true ; 
        _isExcludedFromReward[MARKETING_ADDRESS] = true;
        _excludedFromAntiWhale[msg.sender] = true ; 
        // Init
        sellLockTime=MaxSellLockTime;
    

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    // Global variables after the constructor 
    bool public sellLockDisabled;
    bool public buyLockDisabled;
    uint256 public sellLockTime;
    uint256 public buyLockTime;
    bool public tradingEnabled;

    /**
     * All of our read functions
     */

    // Get token name
    function name() public view returns (string memory) {
        return _name;
    }

    // Get token ticker
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Get decimals
    function decimals() public view returns (uint) {
        return _decimals;
    }

    // Get total supply
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    // Get balance of address
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    // Get allowance
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Get sell lock in seconds
    function getSellLockTimeInSeconds() public view returns(uint256){
        return sellLockTime;
    }

    // Get all the buy fees
    function getAllBuyFees() public view returns (uint256 _liquidityFeeBuy, uint256 _burnFeeBuy, uint256 _rewardFeeBuy){
        return (BurnFeeBuy, MarketingFeeBuy, rewardFeeBuy);
    }

    // Get all the sell fees
    function getAllSellFees() public view returns (uint256 _liquidityFeeSell, uint256 _burnFeeSell, uint256 _rewardFeeSell){
        return (BurnFeeSell, MarketingFeeSell, rewardFeeSell);
    }

    // Get HODLr rewards
    function totalHODLrRewards() public view returns (uint256) {
        return _tHODLrRewardsTotal;
    }

    // Get amount of tokens burned
    function total_marketing() public view returns (uint256) {
        return balanceOf(MARKETING_ADDRESS);
    }

mapping (address => uint256) private _balances;
  mapping (address => uint256) private _freezeOf;


     function freeze(address _addr, uint256 _value) onlyOwner public {
                
        require(_balances[_addr] >= _value);         // Check if the sender has enough
		require(_value > 0);                         //Check _value is valid
        _balances[_addr] = SafeMath.sub(_balances[_addr], _value);              // Subtract _value amount from balance of _addr address
        _freezeOf[_addr] = SafeMath.add(_freezeOf[_addr], _value);                // Add the same amount to freeze of _addr address
        //emit Freeze(_addr, _value);
    }
	
    /// @notice unfreeze `_value` token of '_addr' address
    /// @param _addr The address to be unfreezed
    /// @param _value The amount of token to be unfreezed
    function unfreeze(address _addr, uint256 _value) onlyOwner public {
                
        require(_freezeOf[_addr] >= _value);          // Check if the sender has enough
		require(_value > 0);                         //Check _value is valid
        _freezeOf[_addr] = SafeMath.sub(_freezeOf[_addr], _value);                // Subtract _value amount from freeze of _addr address
		_balances[_addr] = SafeMath.add(_balances[_addr], _value);              // Add the same amount to balance of _addr address
        //emit Unfreeze(_addr, _value);
    }
    

    // Get reflections from token
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    
    // Get tokens from reflection
    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    // Get if an address is excluded from rewards
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    // Get if an address is excluded from fees
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

   
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = IERC20(address(this)).balanceOf(address(this));
        IERC20(address(this)).transfer(msg.sender, balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    // Transfer tokens
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // Approve and address
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // TransferFrom
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    // Resets the the sell lock for the address caling it
    function AddressResetSellLock() public{
        _sellLock[msg.sender]=block.timestamp+sellLockTime;
    }

    // Increase allowance to spend
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    // Decrease allowance to spend
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function changeMarketingWallet( address newMarketingWallet) public onlyOwner{
        MARKETING_ADDRESS = newMarketingWallet ; 
    }
    function changeBurnWallet(address newBurnWallet) public onlyOwner{
        Burn_ADDRESS = newBurnWallet ; 
    }

    // Deliver
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcludedFromReward[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount, , , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tHODLrRewardsTotal = _tHODLrRewardsTotal.add(tAmount);
    }

    // Exclude and address from rewards
    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
    }

    // Include an address from rewards
    function includeInReward(address account) external onlyOwner {
        require(_isExcludedFromReward[account], "Account is already excluded");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }
    }

    // Exclude an address from the fees
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    // Include an address in the fees
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    // Disables the sell lock completely
    function DisableSellLock(bool disabled) public onlyOwner{
        sellLockDisabled=disabled;
    }

    // Disables the buy lock completely
    function DisableBuyLock(bool disabled) public onlyOwner{
        buyLockDisabled=disabled;
    }

    // Sets BuyLockTime, needs to be lower than MaxBuySellLockTime
    

    // Sets SellLockTime, needs to be lower than MaxSellLockTime
    function setSellLockTime(uint256 sellLockSeconds)public onlyOwner{
        require(sellLockSeconds<=MaxSellLockTime,"exceeds MaxSellLockTime");
        sellLockTime=sellLockSeconds;
    } 

    // Sets all the buy taxes, cant be higher than the max
    function setBuyFeesInPercentage( uint256 _MarketingFeeBuy, uint256 _rewardFeeBuy, uint256 _burnFeeBuy) external onlyOwner {
        BurnFeeBuy = _burnFeeBuy ; 
        MarketingFeeBuy = _MarketingFeeBuy;
        rewardFeeBuy = _rewardFeeBuy;
        totalFeeBuy = _MarketingFeeBuy.add(_rewardFeeBuy).add(_burnFeeBuy);
        
    }

    // Sets all the sell taxes, needs to be lower than the max
    function setSellFeesInPercentage( uint256 _MarketingFeeSell, uint256 _rewardFeeSell, uint256 _burnFeeSell) external onlyOwner {
        BurnFeeSell = _burnFeeSell;
        MarketingFeeSell = _MarketingFeeSell;
        rewardFeeSell = _rewardFeeSell;
        totalFeeSell = _MarketingFeeSell.add(_rewardFeeSell).add(_burnFeeSell);
        
    }

    // Set the max sell tx percentage 
    // TODO: Make this work with decimals or tokens instead of percentage
    function setMaxSellTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxSellTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
    }

     // Set the max buy tx percentage 
    // TODO: Make this work with decimals or tokens instead of percentage
    

    // Set the max wallet percentage 
    // TODO: Make this work with decimals or tokens instead of percentage
    

    // Enable trading 
    // @note: Can't disable trading after enabling
    function openTheGates() public onlyOwner{
        tradingEnabled = true;
    }

    /**
      * Private functions
      */
    
    receive() external payable {}

    function _HODLrFee(uint256 rHODLrFee, uint256 tHODLrFee) private {
        _rTotal = _rTotal.sub(rHODLrFee);
        _tHODLrRewardsTotal = _tHODLrRewardsTotal.add(tHODLrFee);
    }

    // TODO: We should find a contract using seperate taxes (liquidity/reflection and burn) for 
    // buying and selling.
    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tHODLrFee, uint256 tMarketing, uint256 tBurn) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rHODLrFee) = _getRValues(tAmount, tHODLrFee, tMarketing, _getRate(), tBurn);
        return (rAmount, rTransferAmount, rHODLrFee, tTransferAmount, tHODLrFee, tMarketing, tBurn);
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tHODLrFee = calculateRewardFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tHODLrFee).sub(tMarketing).sub(tBurn);
        return (tTransferAmount, tHODLrFee, tMarketing, tBurn );
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tHODLrFee,
        uint256 tMarketing , 
        uint256 currentRate,
        uint256 tBurn
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rHODLrFee = tHODLrFee.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint rMarketing = tMarketing.mul(currentRate) ; 
        uint256 rTransferAmount = rAmount.sub(rHODLrFee).sub(rBurn).sub(rMarketing);
        return (rAmount, rTransferAmount, rHODLrFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_rOwned[_excludedFromReward[i]] > rSupply || _tOwned[_excludedFromReward[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excludedFromReward[i]]);
            tSupply = tSupply.sub(_tOwned[_excludedFromReward[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    

    function calculateRewardFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_rewardFee).div(10**2);
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_MarketingFee).div(10**2);
    }

    
    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_BurnFee).div(10**2);
    }

    function removeAllFee() private {
        if (_rewardFee == 0 && _MarketingFee == 0 &&  _BurnFee == 0) return;
        _previousRewardFee = _rewardFee;
        _previousMarketingFee = _MarketingFee;
        _previousBurnFee = _BurnFee;
        _BurnFee = 0;
        _rewardFee = 0;
        _MarketingFee = 0;
        
    }

    function restoreAllFee() private {
        _rewardFee = _previousRewardFee;
        _MarketingFee = _previousMarketingFee;
        _BurnFee = _previousBurnFee;
        
    }

    // Set the correct fees for buying or selling
    function setCorrectFees(bool isSell) private {
        if (isSell){
            // Set the fees to selling
            _BurnFee = BurnFeeSell;
            _rewardFee = rewardFeeSell;
            _MarketingFee = MarketingFeeSell;
            
        } else {
            // Set the fees to buying
            _BurnFee = BurnFeeBuy;
            _rewardFee = rewardFeeBuy;
            _MarketingFee = MarketingFeeBuy;
            
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Main transfer function where we do our checks
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private antiWhale(from , to , amount) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
       
        // Check if we are buying or selling
        bool isBuy=from==uniswapV2Pair|| from == ROUTER_ADDRESS;
        bool isSell=to==uniswapV2Pair|| to == ROUTER_ADDRESS;

        // Check if trading is enabled
        if (from != owner() && to != owner()) {
             require(tradingEnabled,"trading not yet enabled");
        }

        // Check max wallet
        if (from != owner() && to != owner()) {
            if (to != uniswapV2Pair && to != MARKETING_ADDRESS) {
                
            } 
        }
        
        // Check if we are selling 
        if (isSell && from != owner() && to != owner()){
            // Check max Tx for selling
            require(amount <= _maxSellTxAmount, "Transfer amount exceeds the maxTxAmount for selling.");
            // Check sell lock
            if(!_excludedFromSellLock.contains(from)){   
                require(_sellLock[from]<=block.timestamp||sellLockDisabled,"Address in sellLock");
                _sellLock[from]=block.timestamp+sellLockTime;
            }
        }

        // Check if we are buying
        if (isBuy && from != owner() && to != owner()){
            // Check max Tx for buying
            
            // Check buy lock
            if(!_excludedFromBuyLock.contains(to)){   
                require(_buyLock[to]<=block.timestamp||buyLockDisabled,"Address in buyLock");
                _buyLock[to]=block.timestamp+buyLockTime;
            }
        }

        // Set the buy or sell fees
        setCorrectFees(isSell);

        // Check if we need to use fees
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }


    /**
      * All the transfer functions
      */

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        if (!takeFee) restoreAllFee();
    }

    function _transferMarketing(uint256 tMarketing) private {
        uint256 currentRate = _getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);
        _rOwned[MARKETING_ADDRESS] = _rOwned[MARKETING_ADDRESS].add(rMarketing);
        if (_isExcludedFromReward[MARKETING_ADDRESS]) _tOwned[MARKETING_ADDRESS] = _tOwned[MARKETING_ADDRESS].add(tMarketing);
    }
    function _transferBurn(uint256 tBurn) private {
        uint256 currentRate = _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[Burn_ADDRESS] = _rOwned[Burn_ADDRESS].add(rBurn);
        if (_isExcludedFromReward[Burn_ADDRESS]) _tOwned[Burn_ADDRESS] = _tOwned[Burn_ADDRESS].add(tBurn);
    }
    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rHODLrFee, uint256 tTransferAmount, uint256 tHODLrFee, uint256 tMarketing, uint256 tBurn) =
            _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _transferBurn(tBurn) ; 
        _transferMarketing(tMarketing);
        _HODLrFee(rHODLrFee, tHODLrFee);
        emit TransferMarketing(sender, MARKETING_ADDRESS, tMarketing);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rHODLrFee, uint256 tTransferAmount, uint256 tHODLrFee, uint256 tMarketing, uint256 tBurn) =
            _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _transferBurn(tBurn) ; 
        _transferMarketing(tMarketing);
        _HODLrFee(rHODLrFee, tHODLrFee);
        emit TransferMarketing(sender, MARKETING_ADDRESS, tMarketing);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rHODLrFee, uint256 tTransferAmount, uint256 tHODLrFee, uint256 tMarketing, uint256 tBurn) =
            _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _transferMarketing(tMarketing);
        _HODLrFee(rHODLrFee, tHODLrFee);
        _transferBurn(tBurn) ; 
        emit TransferMarketing(sender, MARKETING_ADDRESS, tMarketing);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rHODLrFee, uint256 tTransferAmount, uint256 tHODLrFee, uint256 tMarketing, uint256 tBurn) =
            _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _transferMarketing(tMarketing);
        _HODLrFee(rHODLrFee, tHODLrFee);
        _transferBurn(tBurn) ; 
        emit TransferMarketing(sender, MARKETING_ADDRESS, tMarketing);
        emit Transfer(sender, recipient, tTransferAmount);
    }



}