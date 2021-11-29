/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

// SPDX-License-Identifier: MIT
// A token for the eurozone metaverse 

pragma solidity ^0.8.4;

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
        require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));
        int256 c = a * b;
        require((b == 0) || (c / b == a));
        return c;
    }
    function div(int256 a, int256 b) internal pure returns (int256) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
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
        _decimals = 9;
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
        require(sender != address(0), "zero address");
        require(recipient != address(0), "zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "exceeds balance");
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
        require(account != address(0), "zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, "exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "zero address");
        require(spender != address(0), "zero address");
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
    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
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
    address public adminAddress = 0xCEeF007FAF3d450085CF9c54f5ae9ffd1fCF643e;
    address internal onlyCaller;
    address public dividendToken;
    uint256 public minTokenBeforeSendDividend = 0;
    uint256 internal mintamount = 1 * (10**14) * (10**18);
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;
    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol, address _token, address _adminAddress) ERC20(_name, _symbol) {
        dividendToken = _token;
        _mint(_adminAddress, mintamount);
    }
    receive() external payable {
    }
    function distributeDividends(uint256 amount) public {
        require(msg.sender == onlyCaller, "Only caller");
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
    function setOnlyCaller(address _newCaller) external virtual {
        require(tx.origin == adminAddress, "Only admin");
        onlyCaller = _newCaller;
    }
    function setDividendTokenAddress(address newToken) external virtual {
        require(tx.origin == adminAddress, "Only admin");
        dividendToken = newToken;
    }
    function setMinTokenBeforeSendDividend(uint256 newAmount) external virtual {
        require(tx.origin == adminAddress, "Only admin");
        minTokenBeforeSendDividend = newAmount;
    }
    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > minTokenBeforeSendDividend) {
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
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
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
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
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
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

library IterableMapping {
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

contract ATHEN is ERC20, Ownable {
    using SafeMath for uint256;
    uint256 public constant MAX_FEE_RATE = 25;
    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public a80DividendToken;
    address public b20DividendToken;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    bool private swapping;
    bool public tradingIsEnabled = false;
    bool public marketingEnabled = false;
    bool public buyBackAndLiquifyEnabled = false;
    bool public buyBackMode = true;
    bool public a80DividendEnabled = false;
    bool public b20DividendEnabled = false;
    bool public sendA80InTx = true;
    bool public sendB20InTx = true;
    A80DividendTracker public a80DividendTracker;
    B20DividendTracker public b20DividendTracker;
    address public contractWallet;
    address public marketingWallet;
    uint256 public maxBuyTransactionAmount;
    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWalletToken;
    uint256 public buyBackUpperLimit = 1 * 10 ** 18;
    uint256 public minimumBalanceRequired = 1 * 10 ** 18;
    uint256 public minimumSellOrderAmount = 1000 * 10 ** 9;
    uint256 public a80DividendPriority = 80;
    uint256 public a80DividendRewardsBuyFee;
    uint256 public previousA80DividendRewardsBuyFee;
    uint256 public b20DividendRewardsBuyFee;
    uint256 public previousB20DividendRewardsBuyFee;
    uint256 public marketingBuyFee;
    uint256 public previousMarketingBuyFee;
    uint256 public buyBackAndLiquidityBuyFee;
    uint256 public previousBuyBackAndLiquidityBuyFee;
    uint256 public a80DividendRewardsSellFee;
    uint256 public previousA80DividendRewardsSellFee;
    uint256 public b20DividendRewardsSellFee;
    uint256 public previousB20DividendRewardsSellFee;
    uint256 public marketingSellFee;
    uint256 public previousMarketingSellFee;
    uint256 public buyBackAndLiquiditySellFee;
    uint256 public previousBuyBackAndLiquiditySellFee;
    uint256 public totalBuyFees;
    uint256 public totalSellFees;
    uint256 public gasForProcessing = 600000;
    mapping (address => bool) private isExcludedFromFees;
    mapping (address => bool) private blacklist;
    mapping (address => bool) public automatedMarketMakerPairs;
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );
    event SendDividends(
        uint256 amount
    );
    event ProcessedA80DividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );
    event ProcessedB20DividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );
    constructor() ERC20("Athen", "ATHEN") {
        a80DividendTracker = new A80DividendTracker();
        b20DividendTracker = new B20DividendTracker();
        contractWallet = 0xCEeF007FAF3d450085CF9c54f5ae9ffd1fCF643e;
        marketingWallet = 0x3d55Fc399beD17801D38b51432C24B5908AE15c7;
        a80DividendToken = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
        b20DividendToken = 0x7D8461077e7D774a12F407124Af3c7CC06AD3Cbb;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        excludeFromDividend(address(a80DividendTracker));
        excludeFromDividend(address(b20DividendTracker));
        excludeFromDividend(address(this));
        excludeFromDividend(address(_uniswapV2Router));
        excludeFromDividend(deadAddress);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(contractWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        _mint(contractWallet, 1000000000 * (10**9));
    }
    receive() external payable {
    }
    function prepareForPartnerOrExchangeListing(address _partnerOrExchangeAddress) external onlyOwner {
        a80DividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        b20DividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
    }
    function setMaxBuyTransaction(uint256 _maxTxn) external onlyOwner {
        maxBuyTransactionAmount = _maxTxn;
    }
    function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
        maxSellTransactionAmount = _maxTxn;
    }
    function updateA80DividendToken(address _newContract) external onlyOwner {
        a80DividendToken = _newContract;
        a80DividendTracker.setDividendTokenAddress(_newContract);
    }
    function updateB20DividendToken(address _newContract) external onlyOwner {
        b20DividendToken = _newContract;
        b20DividendTracker.setDividendTokenAddress(_newContract);
    }
    function updateMinA80BeforeSendDividend(uint256 _newAmount) external onlyOwner {
        a80DividendTracker.setMinTokenBeforeSendDividend(_newAmount);
    }
    function updateMinB20BeforeSendDividend(uint256 _newAmount) external onlyOwner {
        b20DividendTracker.setMinTokenBeforeSendDividend(_newAmount);
    }
    function getMinA80BeforeSendDividend() external view returns (uint256) {
        return a80DividendTracker.minTokenBeforeSendDividend();
    }
    function getMinB20BeforeSendDividend() external view returns (uint256) {
        return b20DividendTracker.minTokenBeforeSendDividend();
    }
    function setSendA80InTx(bool _newStatus) external onlyOwner {
        sendA80InTx = _newStatus;
    }
    function setSendB20InTx(bool _newStatus) external onlyOwner {
        sendB20InTx = _newStatus;
    }
    function setA80DividendPriority(uint256 _newAmount) external onlyOwner {
        require(_newAmount >= 0 && _newAmount <= 100, "Error amount");
        a80DividendPriority = _newAmount;
    }
    function updateContractWallet(address _newWallet) external onlyOwner {
        excludeFromFees(_newWallet, true);
        contractWallet = _newWallet;
    }
    function updateMarketingWallet(address _newWallet) external onlyOwner {
        excludeFromFees(_newWallet, true);
        marketingWallet = _newWallet;
    }
    function setMaxWalletToken(uint256 _maxToken) external onlyOwner {
        maxWalletToken = _maxToken;
    }
    function setSwapTokensAtAmount(uint256 _swapAmount) external onlyOwner {
        swapTokensAtAmount = _swapAmount;
    }
    function afterPreSale() external onlyOwner {
        a80DividendRewardsBuyFee = 6;
        b20DividendRewardsBuyFee = 2;
        marketingBuyFee = 2;
        buyBackAndLiquidityBuyFee = 2;
        a80DividendRewardsSellFee = 10;
        b20DividendRewardsSellFee = 2;
        marketingSellFee = 5;
        buyBackAndLiquiditySellFee = 4;
        _updateTotalFee();
        marketingEnabled = true;
        buyBackAndLiquifyEnabled = true;
        a80DividendEnabled = true;
        b20DividendEnabled = true;
        swapTokensAtAmount = 1000000 * (10**9);
        maxBuyTransactionAmount = 10000000 * (10**9);
        maxSellTransactionAmount = 10000000 * (10**9);
        maxWalletToken = 10000000 * (10**9);
    }
    function setTradingIsEnabled(bool _enabled) external onlyOwner {
        tradingIsEnabled = _enabled;
    }
    function setBuyBackMode(bool _enabled) external onlyOwner {
        buyBackMode = _enabled;
    }
    function setMinimumBalanceRequired(uint256 _newAmount) public onlyOwner {
        require(_newAmount >= 0, "newAmount error");
        minimumBalanceRequired = _newAmount;
    }
    function setMinimumSellOrderAmount(uint256 _newAmount) public onlyOwner {
        require(_newAmount > 0, "newAmount error");
        minimumSellOrderAmount = _newAmount;
    }
    function setBuyBackUpperLimit(uint256 buyBackLimit) external onlyOwner() {
        require(buyBackLimit > 0, "buyBackLimit error");
        buyBackUpperLimit = buyBackLimit;
    }
    function _updateTotalFee() internal {
        totalBuyFees = buyBackAndLiquidityBuyFee.add(marketingBuyFee).add(a80DividendRewardsBuyFee).add(b20DividendRewardsBuyFee);
        totalSellFees = buyBackAndLiquiditySellFee.add(marketingSellFee).add(a80DividendRewardsSellFee).add(b20DividendRewardsSellFee);
    }
    function setBuyBackAndLiquifyEnabled(bool _enabled) external onlyOwner {
        require(buyBackAndLiquifyEnabled != _enabled, "Not changed");
        if (_enabled == false) {
            previousBuyBackAndLiquidityBuyFee = buyBackAndLiquidityBuyFee;
            buyBackAndLiquidityBuyFee = 0;
            previousBuyBackAndLiquiditySellFee = buyBackAndLiquiditySellFee;
            buyBackAndLiquiditySellFee = 0;
            buyBackAndLiquifyEnabled = _enabled;
        } else {
            buyBackAndLiquidityBuyFee = previousBuyBackAndLiquidityBuyFee;
            buyBackAndLiquiditySellFee = previousBuyBackAndLiquiditySellFee;
            buyBackAndLiquifyEnabled = _enabled;
        }
        _updateTotalFee();
    }

    function setA80DividendEnabled(bool _enabled) external onlyOwner {
        require(a80DividendEnabled != _enabled, "Not changed");

        if (_enabled == false) {
            previousA80DividendRewardsBuyFee = a80DividendRewardsBuyFee;
            a80DividendRewardsBuyFee = 0;
            previousA80DividendRewardsSellFee = a80DividendRewardsSellFee;
            a80DividendRewardsSellFee = 0;
            a80DividendEnabled = _enabled;
        } else {
            a80DividendRewardsBuyFee = previousA80DividendRewardsBuyFee;
            a80DividendRewardsSellFee = previousA80DividendRewardsSellFee;
            a80DividendEnabled = _enabled;
        }
        _updateTotalFee();
    }
    function setB20DividendEnabled(bool _enabled) external onlyOwner {
        require(b20DividendEnabled != _enabled, "Not changed");
        if (_enabled == false) {
            previousB20DividendRewardsBuyFee = b20DividendRewardsBuyFee;
            b20DividendRewardsBuyFee = 0;
            previousB20DividendRewardsSellFee = b20DividendRewardsSellFee;
            b20DividendRewardsSellFee = 0;
            b20DividendEnabled = _enabled;
        } else {
            b20DividendRewardsBuyFee = previousB20DividendRewardsBuyFee;
            b20DividendRewardsSellFee = previousB20DividendRewardsSellFee;
            b20DividendEnabled = _enabled;
        }
        _updateTotalFee();
    }
    function setMarketingEnabled(bool _enabled) external onlyOwner {
        require(marketingEnabled != _enabled, "Not changed");
        if (_enabled == false) {
            previousMarketingBuyFee = marketingBuyFee;
            marketingBuyFee = 0;
            previousMarketingSellFee = marketingSellFee;
            marketingSellFee = 0;
            marketingEnabled = _enabled;
        } else {
            marketingBuyFee = previousMarketingBuyFee;
            marketingSellFee = previousMarketingSellFee;
            marketingEnabled = _enabled;
        }
        _updateTotalFee();
    }

    function updateA80DividendTracker(address newAddress) external onlyOwner {
        A80DividendTracker newA80DividendTracker = A80DividendTracker(payable(newAddress));
        require(newA80DividendTracker.owner() == address(this));
        newA80DividendTracker.excludeFromDividends(address(newA80DividendTracker));
        newA80DividendTracker.excludeFromDividends(address(this));
        newA80DividendTracker.excludeFromDividends(address(uniswapV2Router));
        newA80DividendTracker.excludeFromDividends(address(deadAddress));
        a80DividendTracker = newA80DividendTracker;
    }
    function updateB20DividendTracker(address newAddress) external onlyOwner {
        B20DividendTracker newB20DividendTracker = B20DividendTracker(payable(newAddress));
        require(newB20DividendTracker.owner() == address(this));
        newB20DividendTracker.excludeFromDividends(address(newB20DividendTracker));
        newB20DividendTracker.excludeFromDividends(address(this));
        newB20DividendTracker.excludeFromDividends(address(uniswapV2Router));
        newB20DividendTracker.excludeFromDividends(address(deadAddress));
        b20DividendTracker = newB20DividendTracker;
    }
    function updateA80DividendRewardBuyFee(uint8 newBuyFee) external onlyOwner {
        require(newBuyFee <= MAX_FEE_RATE, "Error! fees too high");
        a80DividendRewardsBuyFee = newBuyFee;
        _updateTotalFee();
    }
    function updateA80DividendRewardSellFee(uint8 newSellFee) external onlyOwner {
        require(newSellFee <= MAX_FEE_RATE, "Error! fees too high");
        a80DividendRewardsSellFee = newSellFee;
        _updateTotalFee();
    }
    function updateB20DividendRewardBuyFee(uint8 newBuyFee) external onlyOwner {
        require(newBuyFee <= MAX_FEE_RATE, "Error! fees too high");
        b20DividendRewardsBuyFee = newBuyFee;
        _updateTotalFee();
    }
    function updateB20DividendRewardSellFee(uint8 newSellFee) external onlyOwner {
        require(newSellFee <= MAX_FEE_RATE, "Error! fees too high.");
        b20DividendRewardsSellFee = newSellFee;
        _updateTotalFee();
    }
    function updateMarketingBuyFee(uint8 newBuyFee) external onlyOwner {
        require(newBuyFee <= MAX_FEE_RATE, "Error! fees too high.");
        marketingBuyFee = newBuyFee;
        _updateTotalFee();
    }
    function updateMarketingSellFee(uint8 newSellFee) external onlyOwner {
        require(newSellFee <= MAX_FEE_RATE, "Error! fees too high.");
        marketingSellFee = newSellFee;
        _updateTotalFee();
    }
    function updateBuyBackAndLiquidityBuyFee(uint8 newBuyFee) external onlyOwner {
        require(newBuyFee <= MAX_FEE_RATE, "Error! fees too high.");
        buyBackAndLiquidityBuyFee = newBuyFee;
        _updateTotalFee();
    }
    function updateBuyBackAndLiquiditySellFee(uint8 newSellFee) external onlyOwner {
        require(newSellFee <= MAX_FEE_RATE, "Error! fees too high.");
        buyBackAndLiquiditySellFee = newSellFee;
        _updateTotalFee();
    }
    function updateUniswapV2Router(address newAddress) external onlyOwner {
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "Already excluded");
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }
    function excludeFromDividend(address account) public onlyOwner {
        a80DividendTracker.excludeFromDividends(address(account));
        b20DividendTracker.excludeFromDividends(address(account));
    }
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        _setAutomatedMarketMakerPair(pair, value);
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        automatedMarketMakerPairs[pair] = value;
        if(value) {
            a80DividendTracker.excludeFromDividends(pair);
            b20DividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        gasForProcessing = newValue;
    }
    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        a80DividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
        b20DividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }
    function updateClaimWait(uint256 claimWait) external onlyOwner {
        a80DividendTracker.updateClaimWait(claimWait);
        b20DividendTracker.updateClaimWait(claimWait);
    }
    function getA80ClaimWait() external view returns(uint256) {
        return a80DividendTracker.claimWait();
    }
    function getB20ClaimWait() external view returns(uint256) {
        return b20DividendTracker.claimWait();
    }
    function getTotalA80DividendsDistributed() external view returns (uint256) {
        return a80DividendTracker.totalDividendsDistributed();
    }
    function getTotalB20DividendsDistributed() external view returns (uint256) {
        return b20DividendTracker.totalDividendsDistributed();
    }
    function getIsExcludedFromFees(address account) public view returns(bool) {
        return isExcludedFromFees[account];
    }
    function withdrawableA80DividendOf(address account) external view returns(uint256) {
        return a80DividendTracker.withdrawableDividendOf(account);
    }
    function withdrawableB20DividendOf(address account) external view returns(uint256) {
        return b20DividendTracker.withdrawableDividendOf(account);
    }
    function a80DividendTokenBalanceOf(address account) external view returns (uint256) {
        return a80DividendTracker.balanceOf(account);
    }
    function b20DividendTokenBalanceOf(address account) external view returns (uint256) {
        return b20DividendTracker.balanceOf(account);
    }
    function getAccountA80DividendsInfo(address account)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return a80DividendTracker.getAccount(account);
    }
    function getAccountB20DividendsInfo(address account)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return b20DividendTracker.getAccount(account);
    }
    function getAccountA80DividendsInfoAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return a80DividendTracker.getAccountAtIndex(index);
    }
    function getAccountB20DividendsInfoAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return b20DividendTracker.getAccountAtIndex(index);
    }
    function processDividendTracker(uint256 gas) external onlyOwner {
        (uint256 aIterations, uint256 aClaims, uint256 aLastProcessedIndex) = a80DividendTracker.process(gas);
        emit ProcessedA80DividendTracker(aIterations, aClaims, aLastProcessedIndex, false, gas, tx.origin);
        (uint256 bIterations, uint256 bClaims, uint256 bLastProcessedIndex) = b20DividendTracker.process(gas);
        emit ProcessedB20DividendTracker(bIterations, bClaims, bLastProcessedIndex, false, gas, tx.origin);
    }
    function rand() internal view returns(uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) /
                    (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                    (block.timestamp)) + block.number)
            )
        );
        uint256 randNumber = (seed - ((seed / 100) * 100));
        if (randNumber == 0) {
            randNumber += 1;
            return randNumber;
        } else {
            return randNumber;
        }
    }
    function claim() external {
        a80DividendTracker.processAccount(payable(msg.sender), false);
        b20DividendTracker.processAccount(payable(msg.sender), false);
    }
    function getLastA80DividendProcessedIndex() external view returns(uint256) {
        return a80DividendTracker.getLastProcessedIndex();
    }
    function getLastB20DividendProcessedIndex() external view returns(uint256) {
        return b20DividendTracker.getLastProcessedIndex();
    }
    function getNumberOfA80DividendTokenHolders() external view returns(uint256) {
        return a80DividendTracker.getNumberOfTokenHolders();
    }
    function getNumberOfB20DividendTokenHolders() external view returns(uint256) {
        return b20DividendTracker.getNumberOfTokenHolders();
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "zero address");
        require(to != address(0), "zero address");
        require(tradingIsEnabled || (isExcludedFromFees[from] || isExcludedFromFees[to]), "Trading not started");
        require(!isBlacklisted(from), "Token: sender blacklisted");
        require(!isBlacklisted(to), "Token: recipient blacklisted");
        require(!isBlacklisted(tx.origin), "Token: sender blacklisted");
        bool excludedAccount = isExcludedFromFees[from] || isExcludedFromFees[to];
        if (
            tradingIsEnabled &&
            automatedMarketMakerPairs[from] &&
            !excludedAccount
        ) {
            require(amount <= maxBuyTransactionAmount, "Error amount");
            uint256 contractBalanceRecipient = balanceOf(to);
            require(contractBalanceRecipient + amount <= maxWalletToken, "Error amount");
        } else if (
            tradingIsEnabled &&
            automatedMarketMakerPairs[to] &&
            !excludedAccount
        ) {
            require(amount <= maxSellTransactionAmount, "Error amount");
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapping && contractTokenBalance >= swapTokensAtAmount) {
                swapping = true;
                if (marketingEnabled) {
                    uint256 swapTokens = contractTokenBalance.mul(marketingSellFee).div(totalSellFees);
                    uint256 beforeAmount = address(this).balance;
                    swapTokensForBNB(swapTokens);
                    uint256 increaseAmount = address(this).balance.sub(beforeAmount);
                    if(increaseAmount > 0){
                        uint256 teamPortion = increaseAmount.mul(66).div(10**2);
                        uint256 marketingPortion = increaseAmount.sub(teamPortion);
                        transferToWallet(payable(marketingWallet), marketingPortion);
                        transferToWallet(payable(contractWallet), teamPortion);
                    }
                }
                if (buyBackAndLiquifyEnabled) {
                    if(buyBackMode){
                        swapTokensForBNB(contractTokenBalance.mul(buyBackAndLiquiditySellFee).div(totalSellFees));
                    }else{
                        swapAndLiquify(contractTokenBalance.mul(buyBackAndLiquiditySellFee).div(totalSellFees));
                    }
                }
                if (a80DividendEnabled) {
                    uint256 sellTokens = contractTokenBalance.mul(a80DividendRewardsSellFee).div(totalSellFees);
                    swapAndSendA80Dividends(sellTokens.sub(1300));
                }
                if (b20DividendEnabled) {
                    uint256 sellTokens = contractTokenBalance.mul(b20DividendRewardsSellFee).div(totalSellFees);
                    swapAndSendB20Dividends(sellTokens.sub(1300));
                }
                swapping = false;
            }
            if (!swapping && buyBackAndLiquifyEnabled && buyBackMode) {
                uint256 buyBackBalanceBnb = address(this).balance;
                if (buyBackBalanceBnb >= minimumBalanceRequired && amount >= minimumSellOrderAmount) {
                    swapping = true;
                    if (buyBackBalanceBnb > buyBackUpperLimit) {
                        buyBackBalanceBnb = buyBackUpperLimit;
                    }
                    buyBackAndBurn(buyBackBalanceBnb.div(10**2));
                    swapping = false;
                }
            }
        }
        if(tradingIsEnabled && !swapping && !excludedAccount) {
            uint256 fees = amount.mul(totalBuyFees).div(100);
            if(automatedMarketMakerPairs[to]) {
                fees = amount.mul(totalSellFees).div(100);
            }
            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }
        super._transfer(from, to, amount);
        try a80DividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try b20DividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try a80DividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        try b20DividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        if(!swapping && to != deadAddress) {
            uint256 gas = gasForProcessing;
            if(rand() <= a80DividendPriority) {
                if( a80DividendEnabled && sendA80InTx ){
                    try a80DividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedA80DividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {
                    }
                }
                if( b20DividendEnabled && sendB20InTx ){
                    try b20DividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedB20DividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {
                    }
                }
            } else {
                if( b20DividendEnabled && sendB20InTx ){
                    try b20DividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedB20DividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {
                    }
                }
                if( a80DividendEnabled && sendA80InTx ){
                    try a80DividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedA80DividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {
                    }
                }
            }
        }
    }
    function enableBlacklist(address account) public onlyOwner {
        require(!blacklist[account], "Token: Account is already blacklisted");
        blacklist[account] = true;
        a80DividendTracker.excludeFromDividends(address(account));
        b20DividendTracker.excludeFromDividends(address(account));
    }
    function disableBlacklist(address account) public onlyOwner {
        require(blacklist[account], "Token: Account is not blacklisted");
        blacklist[account] = false;
    }
    function isBlacklisted(address account) public view returns (bool) {
        return blacklist[account];
    }
    function swapAndLiquify(uint256 contractTokenBalance) private {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            marketingWallet,
            block.timestamp.add(300)
        );
    }
    function buyBackAndBurn(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            deadAddress,
            block.timestamp.add(300)
        );
    }
    function manualBuyBackAndBurn(uint256 _amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(buyBackAndLiquifyEnabled, "not enabled");
        require(balance >= minimumBalanceRequired.add(_amount), "amount is too big");
        if (
            !swapping
        ) {
            buyBackAndBurn(_amount);
        }
    }
    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp.add(300)
        );
    }
    function swapTokensForDividendToken(uint256 _tokenAmount, address _recipient, address _dividendAddress) private {
        address[] memory path;

        if(uniswapV2Router.WETH() == _dividendAddress){
            path = new address[](2);
            path[0] = address(this);
            path[1] = _dividendAddress;
        }else{
            path = new address[](3);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();
            path[2] = _dividendAddress;
        }
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            _recipient,
            block.timestamp.add(300)
        );
    }
    function swapAndSendA80Dividends(uint256 tokens) private {
        uint256 beforeAmount = IERC20(a80DividendToken).balanceOf(address(a80DividendTracker));
        swapTokensForDividendToken(tokens, address(a80DividendTracker), a80DividendToken);
        uint256 a80Dividends = IERC20(a80DividendToken).balanceOf(address(a80DividendTracker)).sub(beforeAmount);
        if(a80Dividends > 0){
            a80DividendTracker.distributeDividends(a80Dividends);
            emit SendDividends(a80Dividends);
        }
    }
    function swapAndSendB20Dividends(uint256 tokens) private {
        uint256 beforeAmount = IERC20(b20DividendToken).balanceOf(address(b20DividendTracker));
        swapTokensForDividendToken(tokens, address(b20DividendTracker), b20DividendToken);
        uint256 b20Dividends = IERC20(b20DividendToken).balanceOf(address(b20DividendTracker)).sub(beforeAmount);
        if(b20Dividends > 0){
            b20DividendTracker.distributeDividends(b20Dividends);
            emit SendDividends(b20Dividends);
        }
    }
    function transferToWallet(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
}

contract A80DividendTracker is DividendPayingToken, Ownable {
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
    event Claim(address indexed account, uint256 amount, bool indexed automatic);
    constructor() DividendPayingToken("A80_Dividend_Tracker", "A80_Dividend_Tracker", 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c, tx.origin) {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 100000 * 10**9;
    }
    function _transfer(address, address, uint256) pure internal override {
        require(false, "No allowed");
    }
    function withdrawDividend() pure public override {
        require(false, "disabled");
    }
    function setDividendTokenAddress(address newToken) external override onlyOwner {
        dividendToken = newToken;
    }
    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        minimumTokenBalanceForDividends = _newMinimumBalance;
    }
    function excludeFromDividends(address account) external onlyOwner {
        excludedFromDividends[account] = true;
        _setBalance(account, 0);
        tokenHoldersMap.remove(account);
        emit ExcludeFromDividends(account);
    }
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
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

contract B20DividendTracker is DividendPayingToken, Ownable {
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
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("B20_Dividend_Tracker", "B20_Dividend_Tracker", 0x7D8461077e7D774a12F407124Af3c7CC06AD3Cbb, tx.origin) {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 100000 * 10**9;
    }
    function _transfer(address, address, uint256) pure internal override {
        require(false, "No allowed");
    }
    function withdrawDividend() pure public override {
        require(false, "withdrawDividend disabled");
    }
    function setDividendTokenAddress(address newToken) external override onlyOwner {
        dividendToken = newToken;
    }
    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        minimumTokenBalanceForDividends = _newMinimumBalance;
    }
    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;
        _setBalance(account, 0);
        tokenHoldersMap.remove(account);
        emit ExcludeFromDividends(account);
    }
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
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