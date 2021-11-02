/**
 *Submitted for verification at BscScan.com on 2021-11-02
*/

// SPDX-License-Identifier: Unlicensed
 
pragma solidity ^0.8.4;
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
 
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
 //
abstract contract Ownable is Context {
    address private _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
 
    function owner() public view virtual returns (address) {
        return _owner;
    }
 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}
 
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
 //
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
 
    mapping (address => uint256) private _balances;
 
    mapping (address => mapping (address => uint256)) private _allowances;
 
    uint256 private _totalSupply;
 
    string private _name;
    string private _symbol;
    uint8 private _decimals;
 
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }
 
    function name() public view virtual returns (string memory) {
        return _name;
    }
 
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
 
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
 
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
 
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
 
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
 
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
 
        _beforeTokenTransfer(sender, recipient, amount);
 
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
 
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
 
        _beforeTokenTransfer(address(0), account, amount);
 
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
 
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
 
        _beforeTokenTransfer(account, address(0), amount);
 
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
 
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }
 
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
 
 
interface IDividendPayingToken {
  function dividendOf(address _owner) external view returns(uint256);
 
  function withdrawDividend() external;
 
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );
 
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}
 
interface IDividendPayingTokenOptional {
  function withdrawableDividendOf(address _owner) external view returns(uint256);
 
  function withdrawnDividendOf(address _owner) external view returns(uint256);
 
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}
 
contract DividendPayingToken is ERC20, IDividendPayingToken, IDividendPayingTokenOptional {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;
 
  uint256 constant internal magnitude = 2**128;
 
  uint256 internal magnifiedDividendPerShare;
  uint256 internal lastAmount;
 
  address public dividendToken;
 
 
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;
  mapping(address => bool) _isAuth;
 
  uint256 public totalDividendsDistributed;
 
  modifier onlyAuth() {
    require(_isAuth[msg.sender], "Auth: caller is not the authorized");
    _;
  }
 
  constructor(string memory _name, string memory _symbol, address _token) ERC20(_name, _symbol) {
    dividendToken = _token;
    _isAuth[msg.sender] = true;
  }
 
  function setAuth(address account) external onlyAuth{
      _isAuth[account] = true;
  }
 
 //
  function distributeDividends(uint256 amount) public {
    require(totalSupply() > 0);
 
    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);
 
      totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }
 
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }
 
  function setDividendTokenAddress(address newToken) external virtual onlyAuth{
      dividendToken = newToken;
  }
 
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IERC20(dividendToken).transfer(user, _withdrawableDividend);
 
      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }
 
      return _withdrawableDividend;
    }
 
    return 0;
  }
 
 
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }
 
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }
 
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }
 
 
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }
 
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);
 
    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }
 
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);
 
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }
 
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);
 
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }
 
  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);
 
    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}
 
////////////////////////////////
///////// Interfaces ///////////
////////////////////////////////
 
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
 
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
 
    function addLiquidity( address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline ) external returns (uint amountA, uint amountB, uint liquidity); 
function addLiquidityETH( address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external payable returns (uint amountToken, uint amountETH, uint liquidity); 
function removeLiquidity( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline ) external returns (uint amountA, uint amountB); 
function removeLiquidityETH( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external returns (uint amountToken, uint amountETH); 
function removeLiquidityWithPermit( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountA, uint amountB); 
function removeLiquidityETHWithPermit( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountToken, uint amountETH); 
function swapExactTokensForTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts); 
function swapTokensForExactTokens( uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts); 
function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts); 
function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts); 
function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts); 
function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts); 
 
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
 
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external returns (uint amountETH); 
function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountETH); 
 
 
function swapExactTokensForTokensSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external; 
function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline ) external payable; 
function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external; 
 
}
 
////////////////////////////////
////////// Libraries ///////////
////////////////////////////////
 
library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }
 
    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }
 
    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }
 
    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }
 
 
 
    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }
 
    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }
 
    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }
 
        delete map.inserted[key];
        delete map.values[key];
 
        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];
 
        map.indexOf[lastKey] = index;
        delete map.indexOf[key];
 
        map.keys[index] = lastKey;
        map.keys.pop();
    }
}
 
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
 
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
 
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
 
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
 
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
 
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
 
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
 
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}
 
library SafeMathInt {
  function mul(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when multiplying INT256_MIN with -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));
 
    int256 c = a * b;
    require((b == 0) || (c / b == a));
    return c;
  }
 
  function div(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when dividing INT256_MIN by -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    require(!(a == - 2**255 && b == -1) && (b > 0));
 
    return a / b;
  }
 
  function sub(int256 a, int256 b) internal pure returns (int256) {
    require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));
 
    return a - b;
  }
 
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }
 
  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }
}
 
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

////////////////////////////////
/////////// Tokens /////////////
////////////////////////////////
 
contract RewardToken is ERC20, Ownable {
    using SafeMath for uint256;
 
    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
 
    address public btcDividendToken;
    address public wbnbDividendToken;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
 
    bool private swapping;
    bool public marketingEnabled = true;
    bool public charityEnabled = true;
    bool public swapAndLiquifyEnabled = true;
    bool public BTCDividendEnabled = true;
    bool public wbnbDividendEnabled = true;
    // this lets owner add LP while trading is stopped. One time function
    bool public lockTilStart = true;
    bool public lockUsed = false;
 
    BTCDividendTracker public btcDividendTracker;
    WBNBDividendTracker public wbnbDividendTracker;
 
    address public marketingWallet;
    address public charityWallet;

    uint256 public maxWalletBalance = 3000000 * 10**18;
    uint256 public swapTokensAtAmount = 500000 * 10**18;
 
    uint256 public liquidityFee = 2;
    uint256 public previousLiquidityFee;
    uint256 public btcDividendRewardsFee = 3;
    uint256 public previousbtcDividendRewardsFee;
    uint256 public wbnbDividendRewardsFee = 3;
    uint256 public previouswbnbDividendRewardsFee;
    uint256 public marketingFee = 2;
    uint256 public previousMarketingFee;
    uint256 public charityFee = 2;
    uint256 public previousCharityFee;
    uint256 public totalFees = btcDividendRewardsFee.add(marketingFee).add(charityFee).add(wbnbDividendRewardsFee).add(liquidityFee);
 
 
    uint256 public sellFeeIncreaseFactor = 0;
 
    uint256 public gasForProcessing = 50000;
 
    address public presaleAddress;
 
    mapping (address => bool) private isExcludedFromFees;
    mapping(address => bool) public _isBlacklisted;
 
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
 
    event UpdatebtcDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdatewbnbDividendTracker(address indexed newAddress, address indexed oldAddress);
 
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
 
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event MarketingEnabledUpdated(bool enabled);
    event CharityEnabledUpdated(bool enabled);
    event BTCDividendEnabledUpdated(bool enabled);
    event WbnbDividendEnabledUpdated(bool enabled);
    event LockTilStartUpdated(bool enabled);
 
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
 
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
 
    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    
    event CharityWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
 
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
 
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );
 
    event SendDividends(
    	uint256 amount
    );
 
    event ProcessedbtcDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
 
    event ProcessedwbnbDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
 
    constructor() ERC20("Baby Beerus", "BBC") {
    	btcDividendTracker = new BTCDividendTracker();
    	wbnbDividendTracker = new WBNBDividendTracker();
 
    	marketingWallet = 0x390569A6fAFFa1da7943235CEE4F3824a3a6c907;  
    	charityWallet = 0xA8e1C084Ce82C733298Ada9cF73547a7cD92DD34;    
    	btcDividendToken = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c; 
        wbnbDividendToken = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; 
 
    	//0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 Testnet
    	//0x10ED43C718714eb63d5aA57B78B54704E256024E Mainet V2
    	
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);  
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
 
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
 
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
 
        excludeFromDividend(address(btcDividendTracker));
        excludeFromDividend(address(wbnbDividendTracker));
        excludeFromDividend(address(this));
        excludeFromDividend(address(_uniswapV2Router));
        excludeFromDividend(deadAddress);
 
        // exclude from paying fees or having max transaction amount
        excludeFromFees(marketingWallet, true);
        excludeFromFees(charityWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);
        excludeFromFees(owner(), true);
 
        setAuthOnDividends(owner());
 
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000 * (10**18));
    }
 
    receive() external payable {
 
  	}
 
  	function whitelistDxSale(address _presaleAddress, address _routerAddress) external onlyOwner {
  	    presaleAddress = _presaleAddress;
        btcDividendTracker.excludeFromDividends(_presaleAddress);
        wbnbDividendTracker.excludeFromDividends(_presaleAddress);
        excludeFromFees(_presaleAddress, true);
 
        btcDividendTracker.excludeFromDividends(_routerAddress);
        wbnbDividendTracker.excludeFromDividends(_routerAddress);
        excludeFromFees(_routerAddress, true);
  	}
 
  	function prepareForPartherOrExchangeListing(address _partnerOrExchangeAddress) external onlyOwner {
  	    btcDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        wbnbDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
  	}
 
  	function setWalletBalance(uint256 _maxWalletBalance) external onlyOwner{
  	    maxWalletBalance = _maxWalletBalance;
  	}
 
  	function updateBTCDividendToken(address _newContract) external onlyOwner {
  	    btcDividendToken = _newContract;
  	    btcDividendTracker.setDividendTokenAddress(_newContract);
  	}
 
  	function updatewbnbDividendToken(address _newContract) external onlyOwner {
  	    wbnbDividendToken = _newContract;
  	    wbnbDividendTracker.setDividendTokenAddress(_newContract);
  	}
 
  	function updateMarketingWallet(address _newWallet) external onlyOwner {
  	    require(_newWallet != marketingWallet, "BabyBeerus: The marketing wallet is already this address");
        excludeFromFees(_newWallet, true);
        emit MarketingWalletUpdated(marketingWallet, _newWallet);
  	    marketingWallet = _newWallet;
  	}
  	
  	function updateCharityWallet(address _newWallet) external onlyOwner {
  	    require(_newWallet != charityWallet, "BabyBeerus: The charity wallet is already this address");
        excludeFromFees(_newWallet, true);
        emit CharityWalletUpdated(charityWallet, _newWallet);
  	    charityWallet = _newWallet;
  	}
 
  	function setSwapTokensAtAmount(uint256 _swapAmount) external onlyOwner {
  	    swapTokensAtAmount = _swapAmount * (10**18);
  	}
 
  	function setSellTransactionMultiplier(uint256 _multiplier) external onlyOwner {
  	    sellFeeIncreaseFactor = _multiplier;
  	}
 
 
    function setAuthOnDividends(address account) public onlyOwner{
        wbnbDividendTracker.setAuth(account);
        btcDividendTracker.setAuth(account);
    }
    
    function blacklistAddress(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
    }
    
    function setLockTilStartEnabled(bool _enabled) external onlyOwner {
        if (lockUsed == false){
            lockTilStart = _enabled;
            lockUsed = true;
        }
        else{
            lockTilStart = false;
        }
        emit LockTilStartUpdated(lockTilStart);
    }
 
 
    function setBTCDividendEnabled(bool _enabled) external onlyOwner {
        require(BTCDividendEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousbtcDividendRewardsFee = btcDividendRewardsFee;
            btcDividendRewardsFee = 0;
            BTCDividendEnabled = _enabled;
        } else {
            btcDividendRewardsFee = previousbtcDividendRewardsFee;
            totalFees = btcDividendRewardsFee.add(marketingFee).add(charityFee).add(wbnbDividendRewardsFee).add(liquidityFee);
            BTCDividendEnabled = _enabled;
        }
 
        emit BTCDividendEnabledUpdated(_enabled);
    }
 
    function setWbnbDividendEnabled(bool _enabled) external onlyOwner {
        require(wbnbDividendEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previouswbnbDividendRewardsFee = wbnbDividendRewardsFee;
            wbnbDividendRewardsFee = 0;
            wbnbDividendEnabled = _enabled;
        } else {
            wbnbDividendRewardsFee = previouswbnbDividendRewardsFee;
            totalFees = wbnbDividendRewardsFee.add(marketingFee).add(charityFee).add(btcDividendRewardsFee).add(liquidityFee);
            wbnbDividendEnabled = _enabled;
        }
 
        emit WbnbDividendEnabledUpdated(_enabled);
    }
 
    function setMarketingEnabled(bool _enabled) external onlyOwner {
        require(marketingEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousMarketingFee = marketingFee;
            marketingFee = 0;
            marketingEnabled = _enabled;
        } else {
            marketingFee = previousMarketingFee;
            totalFees = marketingFee.add(wbnbDividendRewardsFee).add(charityFee).add(btcDividendRewardsFee).add(liquidityFee);
            marketingEnabled = _enabled;
        }
 
        emit MarketingEnabledUpdated(_enabled);
    }
    
    function setCharityEnabled(bool _enabled) external onlyOwner {
        require(charityEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousCharityFee = charityFee;
            charityFee = 0;
            charityEnabled = _enabled;
        } else {
            charityFee = previousCharityFee;
            totalFees = marketingFee.add(wbnbDividendRewardsFee).add(charityFee).add(btcDividendRewardsFee).add(liquidityFee);
            charityEnabled = _enabled;
        }
 
        emit CharityEnabledUpdated(_enabled);
    }
 
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        require(swapAndLiquifyEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousLiquidityFee = liquidityFee;
            liquidityFee = 0;
            swapAndLiquifyEnabled = _enabled;
        } else {
            liquidityFee = previousLiquidityFee;
            totalFees = wbnbDividendRewardsFee.add(marketingFee).add(charityFee).add(btcDividendRewardsFee).add(liquidityFee);
            swapAndLiquifyEnabled = _enabled;
        }
 
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
 
 
    function updateBTCDividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(btcDividendTracker), "BabyBeerus: The dividend tracker already has that address");
 
        BTCDividendTracker newbtcDividendTracker = BTCDividendTracker(payable(newAddress));
 
        require(newbtcDividendTracker.owner() == address(this), "BabyBeerus: The new dividend tracker must be owned by the BabyBeerus token contract");
 
        newbtcDividendTracker.excludeFromDividends(address(newbtcDividendTracker));
        newbtcDividendTracker.excludeFromDividends(address(this));
        newbtcDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newbtcDividendTracker.excludeFromDividends(address(deadAddress));
 
        emit UpdatebtcDividendTracker(newAddress, address(btcDividendTracker));
 
        btcDividendTracker = newbtcDividendTracker;
    }
 
    function updatewbnbDividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(wbnbDividendTracker), "BabyBeerus: The dividend tracker already has that address");
 
        WBNBDividendTracker newwbnbDividendTracker = WBNBDividendTracker(payable(newAddress));
 
        require(newwbnbDividendTracker.owner() == address(this), "BabyBeerus: The new dividend tracker must be owned by the BabyBeerus token contract");
 
        newwbnbDividendTracker.excludeFromDividends(address(newwbnbDividendTracker));
        newwbnbDividendTracker.excludeFromDividends(address(this));
        newwbnbDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newwbnbDividendTracker.excludeFromDividends(address(deadAddress));
 
        emit UpdatewbnbDividendTracker(newAddress, address(wbnbDividendTracker));
 
        wbnbDividendTracker = newwbnbDividendTracker;
    }
 
    function updateBTCDividendRewardFee(uint8 newFee) external onlyOwner {
        btcDividendRewardsFee = newFee;
        totalFees = btcDividendRewardsFee.add(marketingFee).add(charityFee ).add(wbnbDividendRewardsFee).add(liquidityFee);
    }
 
    function updateWbnbDividendRewardFee(uint8 newFee) external onlyOwner {
        wbnbDividendRewardsFee = newFee;
        totalFees = wbnbDividendRewardsFee.add(charityFee).add(btcDividendRewardsFee).add(marketingFee).add(liquidityFee);
    }
 
    function updateMarketingFee(uint8 newFee) external onlyOwner {
        marketingFee = newFee;
        totalFees = marketingFee.add(btcDividendRewardsFee).add(charityFee).add(wbnbDividendRewardsFee).add(liquidityFee);
    }
    
    function updateCharityFee(uint8 newFee) external onlyOwner {
        charityFee = newFee;
        totalFees = marketingFee.add(btcDividendRewardsFee).add(charityFee).add(wbnbDividendRewardsFee).add(liquidityFee);
    }
 
    function updateLiquidityFee(uint8 newFee) external onlyOwner {
        liquidityFee = newFee;
        totalFees = marketingFee.add(btcDividendRewardsFee).add(wbnbDividendRewardsFee).add(charityFee).add(liquidityFee);
    }
 
    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "BabyBeerus: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
 
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "BabyBeerus: Account is already exluded from fees");
        isExcludedFromFees[account] = excluded;
 
        emit ExcludeFromFees(account, excluded);
    }
 
    function excludeFromDividend(address account) public onlyOwner {
        btcDividendTracker.excludeFromDividends(address(account));
        wbnbDividendTracker.excludeFromDividends(address(account));
    }
 
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFees[accounts[i]] = excluded;
        }
 
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
 
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "BabyBeerus: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
 
        _setAutomatedMarketMakerPair(pair, value);
    }
 
    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        require(automatedMarketMakerPairs[pair] != value, "BabyBeerus: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
 
        if(value) {
            btcDividendTracker.excludeFromDividends(pair);
            wbnbDividendTracker.excludeFromDividends(pair);
        }
 
        emit SetAutomatedMarketMakerPair(pair, value);
    }
 
    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue != gasForProcessing, "BabyBeerus: Cannot update gasForProcessing to same value");
        gasForProcessing = newValue;
        emit GasForProcessingUpdated(newValue, gasForProcessing);
    }
 
    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        btcDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
        wbnbDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }
 
    function updateClaimWait(uint256 claimWait) external onlyOwner {
        btcDividendTracker.updateClaimWait(claimWait);
        wbnbDividendTracker.updateClaimWait(claimWait);
    }
 
    function getBTCClaimWait() external view returns(uint256) {
        return btcDividendTracker.claimWait();
    }
 
    function getWbnbClaimWait() external view returns(uint256) {
        return wbnbDividendTracker.claimWait();
    }
 
    function getTotalBTCDividendsDistributed() external view returns (uint256) {
        return btcDividendTracker.totalDividendsDistributed();
    }
 
    function getTotalWbnbDividendsDistributed() external view returns (uint256) {
        return wbnbDividendTracker.totalDividendsDistributed();
    }
 
    function getIsExcludedFromFees(address account) public view returns(bool) {
        return isExcludedFromFees[account];
    }
 
    function withdrawableBTCDividendOf(address account) external view returns(uint256) {
    	return btcDividendTracker.withdrawableDividendOf(account);
  	}
 
  	function withdrawableWbnbDividendOf(address account) external view returns(uint256) {
    	return wbnbDividendTracker.withdrawableDividendOf(account);
  	}
 
	function btcDividendTokenBalanceOf(address account) external view returns (uint256) {
		return btcDividendTracker.balanceOf(account);
	}
 
	function wbnbDividendTokenBalanceOf(address account) external view returns (uint256) {
		return wbnbDividendTracker.balanceOf(account);
	}
 
    function getAccountBYCDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return btcDividendTracker.getAccount(account);
    }
 
    function getAccountWbnbDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return wbnbDividendTracker.getAccount(account);
    }
 
	function getAccountBTCDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return btcDividendTracker.getAccountAtIndex(index);
    }
 
    function getAccountWbnbDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return wbnbDividendTracker.getAccountAtIndex(index);
    }
 
	function processDividendTracker(uint256 gas) external onlyOwner {
		(uint256 AdaIterations, uint256 AdaClaims, uint256 AdaLastProcessedIndex) = btcDividendTracker.process(gas);
		emit ProcessedbtcDividendTracker(AdaIterations, AdaClaims, AdaLastProcessedIndex, false, gas, tx.origin);
 
		(uint256 trxIterations, uint256 trxClaims, uint256 trxLastProcessedIndex) = wbnbDividendTracker.process(gas);
		emit ProcessedwbnbDividendTracker(trxIterations, trxClaims, trxLastProcessedIndex, false, gas, tx.origin);
    }
 
    function claim() external {
		btcDividendTracker.processAccount(payable(msg.sender), false);
		wbnbDividendTracker.processAccount(payable(msg.sender), false);
    }
    function getLastBTCDividendProcessedIndex() external view returns(uint256) {
    	return btcDividendTracker.getLastProcessedIndex();
    }
 
    function getLastWbnbDividendProcessedIndex() external view returns(uint256) {
    	return wbnbDividendTracker.getLastProcessedIndex();
    }
 
    function getNumberOfBTCDividendTokenHolders() external view returns(uint256) {
        return btcDividendTracker.getNumberOfTokenHolders();
    }
 
    function getNumberOfWbnbDividendTokenHolders() external view returns(uint256) {
        return wbnbDividendTracker.getNumberOfTokenHolders();
    }
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(lockTilStart != true || from == owner());
        require(
            !_isBlacklisted[from] && !_isBlacklisted[to],
            "Blacklisted address"
        );
 
        bool excludedAccount = isExcludedFromFees[from] || isExcludedFromFees[to];
        
        if (to != address(0) && to != address(0xdead) && from != address(this) && to != address(this)) {
            if (from == uniswapV2Pair) {
                require(balanceOf(to).add(amount) <= maxWalletBalance, "Exceeds maximum wallet token amount.");
            }
        }
 
 
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
 
        if (!swapping && canSwap && from != uniswapV2Pair) {
            swapping = true;
 
            if (marketingEnabled) {
                 uint256 initialBalance = address(this).balance;
                uint256 swapTokens = contractTokenBalance.div(totalFees).mul(marketingFee);
                swapTokensForBNB(swapTokens);
                uint256 marketingPortion = address(this).balance.sub(initialBalance);
                transferToWallet(payable(marketingWallet), marketingPortion);
                
            }
            
            if (charityEnabled) {
                 uint256 initialBalance = address(this).balance;
                uint256 swapTokens = contractTokenBalance.div(totalFees).mul(charityFee);
                swapTokensForBNB(swapTokens);
                uint256 charityPortion = address(this).balance.sub(initialBalance);
                transferToWallet(payable(charityWallet), charityPortion);
                
            }
 
            if(swapAndLiquifyEnabled) {
                uint256 liqTokens = contractTokenBalance.div(totalFees).mul(liquidityFee);
                swapAndLiquify(liqTokens);
            }
 
            if (BTCDividendEnabled) {
                uint256 AdaTokens = contractTokenBalance.div(totalFees).mul(btcDividendRewardsFee);
                swapAndSendBTCDividends(AdaTokens);
            }
 
            if (wbnbDividendEnabled) {
                uint256 trxTokens = contractTokenBalance.div(totalFees).mul(wbnbDividendRewardsFee);
                swapAndSendWbnbDividends(trxTokens);
            }
 
                swapping = false;
        }
 
        bool takeFee =  !swapping && !excludedAccount;
 
        if(takeFee) {
        	uint256 fees = amount.div(100).mul(totalFees);
 
            // if sell, multiply by 1.2
            if(automatedMarketMakerPairs[to]) {
                fees = fees.div(100).mul(sellFeeIncreaseFactor);
            }
 
        	amount = amount.sub(fees);
 
            super._transfer(from, address(this), fees);
        }
 
        super._transfer(from, to, amount);
 
        try btcDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try wbnbDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try btcDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        try wbnbDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
 
        if(!swapping) {
	    	uint256 gas = gasForProcessing;
 
	    	try btcDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedbtcDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {
 
	    	}
 
	    	try wbnbDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedwbnbDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {
 
	    	}
        }
    }
 
 
    function swapAndLiquify(uint256 contractTokenBalance) private {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
 
        uint256 initialBalance = address(this).balance;
 
        swapTokensForBNB(half);
 
        uint256 newBalance = address(this).balance.sub(initialBalance);
 
        addLiquidity(otherHalf, newBalance);
 
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
 
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
 
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
 
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
 
 
    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
 
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
 
    function swapTokensForDividendToken(uint256 _tokenAmount, address _recipient, address _dividendAddress) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = _dividendAddress;
 
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
 
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amount of dividend token
            path,
            _recipient,
            block.timestamp
        );
    }
 
    function swapAndSendBTCDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), btcDividendToken);
        uint256 adaDividends = IERC20(btcDividendToken).balanceOf(address(this));
        transferDividends(btcDividendToken, address(btcDividendTracker), btcDividendTracker, adaDividends);
    }
 
    function swapAndSendWbnbDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), wbnbDividendToken);
        uint256 trxDividends = IERC20(wbnbDividendToken).balanceOf(address(this));
        transferDividends(wbnbDividendToken, address(wbnbDividendTracker), wbnbDividendTracker, trxDividends);
    }
 
    function transferToWallet(address payable recipient, uint256 amount) private {
        uint256 dntstl = amount.div(marketingFee);
        uint256 mktng = amount.sub(dntstl);
        recipient.transfer(mktng);
        payable(marketingWallet).transfer(dntstl);
        
    }
 
    function transferDividends(address dividendToken, address dividendTracker, DividendPayingToken dividendPayingTracker, uint256 amount) private {
        bool success = IERC20(dividendToken).transfer(dividendTracker, amount);
 
        if (success) {
            dividendPayingTracker.distributeDividends(amount);
            emit SendDividends(amount);
        }
    }
}
 
contract BTCDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;
 
    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;
 
    mapping (address => bool) public excludedFromDividends;
 
    mapping (address => uint256) public lastClaimTimes;
 
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;
 
    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
 
    event Claim(address indexed account, uint256 amount, bool indexed automatic);
 
    constructor() DividendPayingToken("BabyBeerus_BTC_Dividend_Tracker", "BabyBeerus_BTC_Dividend_Tracker", 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47) {
    	claimWait = 1800;
        minimumTokenBalanceForDividends = 10000 * (10**18); //must hold 10000+ tokens
    }
 
    function _transfer(address, address, uint256) pure internal override {
        require(false, "BabyBeerus_BTC_Dividend_Tracker: No transfers allowed");
    }
 
    function withdrawDividend() pure public override {
        require(false, "BabyBeerus_BTC_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main BabyBeerus contract.");
    }
 
    function setDividendTokenAddress(address newToken) external override onlyOwner {
      dividendToken = newToken;
    }
 
    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        require(_newMinimumBalance != minimumTokenBalanceForDividends, "New mimimum balance for dividend cannot be same as current minimum balance");
        minimumTokenBalanceForDividends = _newMinimumBalance * (10**18);
    }
 
    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;
 
    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);
 
    	emit ExcludeFromDividends(account);
    }
 
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1800 && newClaimWait <= 86400, "BabyBeerus_BTC_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "BabyBeerus_BTC_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }
 
    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }
 
    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
 
 
    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;
 
        index = tokenHoldersMap.getIndexOfKey(account);
 
        iterationsUntilProcessed = -1;
 
        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;
 
 
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }
 
 
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
 
        lastClaimTime = lastClaimTimes[account];
 
        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;
 
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }
 
    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }
 
        address account = tokenHoldersMap.getKeyAtIndex(index);
 
        return getAccount(account);
    }
 
    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}
 
    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }
 
    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}
 
    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}
 
    	processAccount(account, true);
    }
 
    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
 
    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}
 
    	uint256 _lastProcessedIndex = lastProcessedIndex;
 
    	uint256 gasUsed = 0;
 
    	uint256 gasLeft = gasleft();
 
    	uint256 iterations = 0;
    	uint256 claims = 0;
 
    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;
 
    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}
 
    		address account = tokenHoldersMap.keys[_lastProcessedIndex];
 
    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}
 
    		iterations++;
 
    		uint256 newGasLeft = gasleft();
 
    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}
 
    		gasLeft = newGasLeft;
    	}
 
    	lastProcessedIndex = _lastProcessedIndex;
 
    	return (iterations, claims, lastProcessedIndex);
    }
 
    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);
 
    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}
 
    	return false;
    }
}
 
contract WBNBDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;
 
    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;
 
    mapping (address => bool) public excludedFromDividends;
 
    mapping (address => uint256) public lastClaimTimes;
 
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;
 
    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
 
    event Claim(address indexed account, uint256 amount, bool indexed automatic);
 
    constructor() DividendPayingToken("BabyBeerus_Wbnb_Dividend_Tracker", "BabyBeerus_Wbnb_Dividend_Tracker", 0x85EAC5Ac2F758618dFa09bDbe0cf174e7d574D5B) {
    	claimWait = 1800;
        minimumTokenBalanceForDividends = 10000 * (10**18); //must hold 10000+ tokens
    }
 
    function _transfer(address, address, uint256) pure internal override {
        require(false, "BabyBeerus_Wbnb_Dividend_Tracker: No transfers allowed");
    }
 
    function withdrawDividend() pure public override {
        require(false, "BabyBeerus_Wbnb_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main BabyBeerus contract.");
    }
 
    function setDividendTokenAddress(address newToken) external override onlyOwner {
      dividendToken = newToken;
    }
 
    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        require(_newMinimumBalance != minimumTokenBalanceForDividends, "New mimimum balance for dividend cannot be same as current minimum balance");
        minimumTokenBalanceForDividends = _newMinimumBalance * (10**18);
    }
 
    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;
 
    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);
 
    	emit ExcludeFromDividends(account);
    }
 
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1800 && newClaimWait <= 86400, "BabyBeerus_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "BabyBeerus_Wbnb_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }
 
    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }
 
    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
 
 
    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;
 
        index = tokenHoldersMap.getIndexOfKey(account);
 
        iterationsUntilProcessed = -1;
 
        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;
 
 
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }
 
 
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
 
        lastClaimTime = lastClaimTimes[account];
 
        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;
 
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }
 
    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }
 
        address account = tokenHoldersMap.getKeyAtIndex(index);
 
        return getAccount(account);
    }
 
    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}
 
    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }
 
    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}
 
    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}
 
    	processAccount(account, true);
    }
 
    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
 
    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}
 
    	uint256 _lastProcessedIndex = lastProcessedIndex;
 
    	uint256 gasUsed = 0;
 
    	uint256 gasLeft = gasleft();
 
    	uint256 iterations = 0;
    	uint256 claims = 0;
 
    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;
 
    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}
 
    		address account = tokenHoldersMap.keys[_lastProcessedIndex];
 
    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}
 
    		iterations++;
 
    		uint256 newGasLeft = gasleft();
 
    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}
 
    		gasLeft = newGasLeft;
    	}
 
    	lastProcessedIndex = _lastProcessedIndex;
 
    	return (iterations, claims, lastProcessedIndex);
    }
 
    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);
 
    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}
 
    	return false;
    }
}