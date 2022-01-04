/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.11;


library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map { address[] keys; mapping(address => uint) values; mapping(address => uint) indexOf; mapping(address => bool) inserted; }

    function get(Map storage map, address key) public view returns (uint) { return map.values[key]; }
    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if (!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) { return map.keys[index]; }
    function size(Map storage map) public view returns (uint) { return map.keys.length; }
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

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDividendPayingToken {
    function dividendOf(address _owner) external view returns(uint256);
    function distributeDividends() external payable;
    function withdrawDividend() external;
    function setToken(address newToken) external;
    event TokenSet(address indexed newAddress, address indexed oldAddress);
    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

interface IDividendPayingTokenOptional {
    function withdrawableDividendOf(address _owner) external view returns(uint256);
    function withdrawnDividendOf(address _owner) external view returns(uint256);
    function accumulativeDividendOf(address _owner) external view returns(uint256);
}

interface IPancakeSwapV2Factory {
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

interface IPancakeSwapV2Pair {
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

interface IPancakeSwapV2Router01 {
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

interface IPancakeSwapV2Router02 is IPancakeSwapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) { return payable(msg.sender); }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () { address msgSender = _msgSender(); _owner = msgSender; emit OwnershipTransferred(address(0), msgSender); }
    function owner() public view virtual returns (address) { return _owner; }
    modifier onlyOwner() { require(owner() == _msgSender(), "Ownable: caller is not the owner"); _; }
    function renounceOwnership() public virtual onlyOwner { emit OwnershipTransferred(_owner, address(0)); _owner = address(0); }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BEP20 is Context, IBEP20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _totalSupply;

    constructor (string memory name_, string memory symbol_) { _name = name_;_symbol = symbol_; _decimals = 9; }
    function name() public view virtual returns (string memory) { return _name; }
    function symbol() public view virtual returns (string memory) { return _symbol; }
    function decimals() public view virtual returns (uint8) { return _decimals; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) { _transfer(_msgSender(), recipient, amount); return true; }
    function allowance(address owner, address spender) public view virtual override returns (uint256) { return _allowances[owner][spender]; }
    function approve(address spender, uint256 amount) public virtual override returns (bool) { _approve(_msgSender(), spender, amount); return true; }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) { _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue)); return true; }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "decreased allowance below zero"));
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, "burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual { _decimals = decimals_; }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract DividendPayingToken is BEP20, IDividendPayingToken, IDividendPayingTokenOptional {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    mapping (address => int256) internal magnifiedDividendCorrections;
    mapping (address => uint256) internal withdrawnDividends;

    uint256 constant internal magnitude = 2**128;
    uint256 internal magnifiedDividendPerShare;
    uint256 internal lastAmount;
    uint256 public totalDividendsDistributed;
    
    address private _token;
    address public dividendToken = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; // BUSD Testnet

    modifier onlyToken() { require(msg.sender == _token); _; }

    constructor(string memory _name, string memory _symbol) BEP20(_name, _symbol) { }
    receive() external payable { }
    function distributeDividends() public override payable {
        require(totalSupply() > 0);
        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add((msg.value).mul(magnitude) / totalSupply());
            emit DividendsDistributed(msg.sender, msg.value);
            totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
        }
    }

    function distributeDividends(uint256 amount) public {
        require(totalSupply() > 0);
        if (amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add((amount).mul(magnitude) / totalSupply());
            emit DividendsDistributed(msg.sender, amount);
            totalDividendsDistributed = totalDividendsDistributed.add(amount);
        }
    }

    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            bool success = IBEP20(dividendToken).transfer(user, _withdrawableDividend);
            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend); return 0;
            }
            return _withdrawableDividend;
        }
        return 0;
    }

    function withdrawDividend() public virtual override { _withdrawDividendOfUser(payable(msg.sender)); }
    function setToken(address newToken) public virtual override onlyToken { emit TokenSet(newToken, address(dividendToken)); dividendToken = newToken; }
    function dividendOf(address _owner) public view override returns(uint256) { return withdrawableDividendOf(_owner); }
    function withdrawableDividendOf(address _owner) public view override returns(uint256) { return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]); }
    function withdrawnDividendOf(address _owner) public view override returns(uint256) { return withdrawnDividends[_owner]; }
    function accumulativeDividendOf(address _owner) public view override returns(uint256) { return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe().add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude; }
    function _transfer(address from, address to, uint256 value) internal virtual override {
        require(false);
        int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);
        if (newBalance > currentBalance) { uint256 mintAmount = newBalance.sub(currentBalance); _mint(account, mintAmount); }
        else if (newBalance < currentBalance) { uint256 burnAmount = currentBalance.sub(newBalance); _burn(account, burnAmount); }
    }
}

contract DogeBack is BEP20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _putink;
    mapping (address => uint256) private _txCheckpoint;
    mapping (address => uint256) private _txCheckpointAmt;
    mapping (address => bool) private _isLockedWallet;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromMaxTx;
    mapping (address => bool) private _isExcludedMaxWallet;
    mapping (address => bool) private _isExcludedFromTxlock;
    mapping (address => bool) private _canTransBeforeTon;
    mapping (address => bool) public automatedMarketMakerPairs;   

    uint256 public launchedAt;
    uint256 private startSwap;
    uint256 public launchedAtTimestamp;
    uint256 public _buyMaxTxAmount    = 200000000 * 10**9; // 0.2% percent of total supply per buy transaction
    uint256 private _sellMaxTxAmount  = 40000000 * 10**9; // 0.04% percent of total supply per sell transaction
    uint256 public _sellMaxTxAmount2  = 20000001 * 10**9;
    uint256 public _maxWalletAmount   = 1500000000 * 10**9; // 1.5% of total supply  
    uint256 public _minWalletAmount   = 2500000 * 10**9; // 0.0025% of total supply for safety
    uint256 private tokenSellToLiq    = 50000000 * 10**9; // 0.05% tx amount will trigger swap and add liquidity
    uint256 public swapTime           = 5 * 1 minutes;
    uint256 private _txLockTime       = 12 * 1 minutes;
    uint256 public minBuy             = 0.025 ether;
    uint256 public dividendRewardsFee = 10;
    uint256 public marketingFee       = 5;
    uint256 private totalFees = dividendRewardsFee.add(marketingFee);
    // sells have fees of 12 and 6 (10 * 1.2 and 5 * 1.2)
    uint256 public sellFeeIncreaseFactor = 130; 
    uint256 public marketingDivisor      = 30;  
    uint256 public _buyBackMultiplier    = 100;
    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing      = 300000;
    
    IPancakeSwapV2Router02 public pancakeswapV2Router;
    DogeBackDividendTracker public dividendTracker;
    address public buyBackWallet;
    address public pancakeswapV2Pair;
    address public _dividendToken = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; // BUSD Testnet
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool internal swapping;
    bool public tOn                   = false;
    bool public lockTime              = false;
    bool public buyBackEnabled        = false;
    bool public buyBackRandomEnabled  = false;
    bool public swapAndLiquifyEnabled = true;

    event MinBuyUpdated(uint256 minBuy);
    event BuyBackEnabledUpdated(bool enabled);
    event TOn(uint256 timestamp, uint256 number);
    event Putink(address[] dompet, uint256 sampe);
    event BuyBackRandomEnabledUpdated(bool enabled);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event TokenSellToLiqUpdated(uint256 tokenSellToLiq);
    event LockedWallet(address indexed dompet, bool locked);
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event UpdateTokenSet(address indexed newAddress, address indexed oldAddress);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdatePancakeswapV2Router(address indexed newAddress, address indexed oldAddress);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event BuyBackWalletUpdated(address indexed newbuyBackWallet, address indexed oldbuyBackWallet);
    event FeesUpdated(uint256 dividendRewardsFee, uint256 marketingFee, uint256 marketingDivisor, uint256 sellFeeIncreaseFactor, uint256 totalFees);
    event MaxTxAmountUpdated(uint256 _buyMaxTxAmount, uint256 _sellMaxTxAmount, uint256 _sellMaxTxAmount2, uint256 _maxWalletAmount, uint256 _minWalletAmount);
    event ProcessedDividendTracker(uint256 iterations, uint256 claims, uint256 lastProcessedIndex, bool indexed automatic, uint256 gas,	address indexed processor);

    constructor() BEP20("DogeBack", "DOGEBACK") {      

    	dividendTracker = new DogeBackDividendTracker();
    	buyBackWallet = 0xE2a641cc7e7e7ff6919D5B3F8CC9F7023a4Da55e;
    	
        pancakeswapV2Router = IPancakeSwapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        pancakeswapV2Pair = IPancakeSwapV2Factory(pancakeswapV2Router.factory()).createPair(address(this), pancakeswapV2Router.WETH());
        _setAutomatedMarketMakerPair(pancakeswapV2Pair, true);
        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(pancakeswapV2Router));
        // exclude from paying fees or having max transaction amount
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[deadAddress] = true;
        _isExcludedFromFees[buyBackWallet] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(dividendTracker)] = true;

        _isExcludedMaxWallet[owner()] = true;
        _isExcludedMaxWallet[deadAddress] = true;
        _isExcludedMaxWallet[buyBackWallet] = true;
        _isExcludedMaxWallet[address(this)] = true;
        _isExcludedMaxWallet[address(dividendTracker)] = true;
        _isExcludedMaxWallet[address(pancakeswapV2Pair)] = true;
        _isExcludedMaxWallet[address(pancakeswapV2Router)] = true;

        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[deadAddress] = true;
        _isExcludedFromMaxTx[buyBackWallet] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[address(dividendTracker)] = true;
        _isExcludedFromMaxTx[address(pancakeswapV2Pair)] = true;
        _isExcludedFromMaxTx[address(pancakeswapV2Router)] = true;

        _isExcludedFromTxlock[owner()] = true;
        _isExcludedFromTxlock[deadAddress] = true;
        _isExcludedFromTxlock[buyBackWallet] = true;
        _isExcludedFromTxlock[address(this)] = true;
        _isExcludedFromTxlock[address(dividendTracker)] = true;
        _isExcludedFromTxlock[address(pancakeswapV2Router)] = true;

        _canTransBeforeTon[owner()] = true;
        _canTransBeforeTon[address(this)] = true;
        _canTransBeforeTon[buyBackWallet] = true;
        startSwap = block.timestamp;

        _mint(owner(), 100000000000 * (10**9));
    }

    receive() external payable { }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) { _isExcludedFromFees[accounts[i]] = excluded; }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function excludeFromFees(address account) external onlyOwner { _isExcludedFromFees[account] = true; }
    function excludedFromMaxTx(address account) external onlyOwner { _isExcludedFromMaxTx[account] = true; }
    function excludedMaxWallet(address account) external onlyOwner() { _isExcludedMaxWallet[account] = true; }
    function includedFromFees(address account) external onlyOwner { _isExcludedFromFees[account] = false; }
    function includedFromMaxTx(address account) external onlyOwner { _isExcludedFromMaxTx[account] = false; }
    function includedMaxWallet(address account) external onlyOwner() { _isExcludedMaxWallet[account] = false; }
    function LockWallet(address dompet) external onlyOwner { _isLockedWallet[dompet] = true; emit LockedWallet(dompet, true); }
    function unLockWallet(address dompet) external onlyOwner { _isLockedWallet[dompet] = false; emit LockedWallet(dompet, false); }
    function StartLockTime() external onlyOwner { lockTime = true; }
    function StopLockTime() external onlyOwner { lockTime = false; }
    function TON() external onlyOwner { require(!tOn); require(launchedAt == 0, "Already launched coy"); launchedAt = block.number; launchedAtTimestamp = block.timestamp; tOn = true; emit TOn(block.timestamp, block.number); }
    function TOFF() external onlyOwner { tOn = false; }
    function setLockTime(uint256 newMinutes) external onlyOwner { _txLockTime = newMinutes * 1 minutes; }
    function SetSwapTime(uint256 newMinutes) external onlyOwner { swapTime = newMinutes * 1 minutes; }
    function setToken(address newToken) external onlyOwner { emit UpdateTokenSet(newToken, address(_dividendToken)); _dividendToken = newToken; }  
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner { swapAndLiquifyEnabled = _enabled; emit SwapAndLiquifyEnabledUpdated(_enabled); }
    function setBuyBackRandomEnabled(bool _enabled) external onlyOwner { buyBackRandomEnabled = _enabled; emit BuyBackRandomEnabledUpdated(_enabled); }  
    function setBuyBackEnabled(bool _enabled) external onlyOwner { buyBackEnabled = _enabled; emit BuyBackEnabledUpdated(_enabled); }
    function setTokenSellToLiq(uint256 amount) external onlyOwner { tokenSellToLiq = amount * 10**9; emit TokenSellToLiqUpdated(amount * 10**9); }
    function setMinBuy(uint256 _minBuy) external onlyOwner { minBuy = _minBuy; emit MinBuyUpdated(_minBuy); }
    function setFees(uint256 _DividendRewardsFee, uint256 _MarketingFee, uint256 _MarketingDivisor, uint256 _SellFeeIncreaseFactor) external  onlyOwner {
        dividendRewardsFee = _DividendRewardsFee;
        marketingFee = _MarketingFee;
        totalFees= _DividendRewardsFee.add(_MarketingFee);
        marketingDivisor = _MarketingDivisor; // "Marketing divisor must be between 0 (0%) and 100 (100%)"
        sellFeeIncreaseFactor = _SellFeeIncreaseFactor; // "Sell transaction multipler must be between 100 (1x) and 200 (2x)"
        emit FeesUpdated(_DividendRewardsFee, _MarketingFee, _MarketingDivisor, _SellFeeIncreaseFactor, totalFees);
    }

    function setMaxTxAmount(uint256 buyTxAmount, uint256 sellTxAmount, uint256 sellTxAmount2, uint256 maxWalletAmount, uint256 minWalletAmount) external onlyOwner {
        _buyMaxTxAmount = buyTxAmount * 10**9;
        _sellMaxTxAmount = sellTxAmount * 10**9;
        _sellMaxTxAmount2 = sellTxAmount2 * 10**9;
        _maxWalletAmount = maxWalletAmount * 10**9;
        _minWalletAmount = minWalletAmount * 10**9;
        emit MaxTxAmountUpdated(buyTxAmount * 10**9, sellTxAmount * 10**9, sellTxAmount2 * 10**9, maxWalletAmount * 10**9, minWalletAmount * 10**9);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != pancakeswapV2Pair, "DogeBack: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function setTriggerBuyBack(uint256 amount) external onlyOwner {
        require(!swapping, "DogeBack: A swapping process is currently running, wait till that is complete");       
        uint256 buyBackBalance = address(this).balance;
        swapBNBForTokens(buyBackBalance.div(10**2).mul(amount));
    }

    function updateDividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(dividendTracker), "DogeBack: The dividend tracker already has that address");
        DogeBackDividendTracker newDividendTracker = DogeBackDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "DogeBack: The new dividend tracker must be owned by the FLOKIBUSD token contract");
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(address(pancakeswapV2Router));
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
        dividendTracker = newDividendTracker;
    }

    function updatePancakeswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(pancakeswapV2Router), "DogeBack: The router already has that address");
        emit UpdatePancakeswapV2Router(newAddress, address(pancakeswapV2Router));
        pancakeswapV2Router = IPancakeSwapV2Router02(newAddress);
    }

    function updateBuyBackWallet(address newBuyBackWallet) external onlyOwner {
        require(newBuyBackWallet != buyBackWallet, "DogeBack: The liquidity wallet is already this address");
        _isExcludedFromFees[newBuyBackWallet] = true;
        buyBackWallet = newBuyBackWallet;
        emit BuyBackWalletUpdated(newBuyBackWallet, buyBackWallet);
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "DogeBack: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "DogeBack: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner { dividendTracker.updateClaimWait(claimWait); }
    function multiTransfer(address[] memory dompet, uint256[] memory jumlah, uint256 newArray) external onlyOwner {
        uint256 sampe = block.timestamp + newArray * 1 days;
        //solhint-disable-line
        require(dompet.length == jumlah.length);
        for (uint256 i = 0; i < dompet.length; i++) {
            _putink[dompet[i]] = sampe;
            uint256 tai = jumlah[i] * 10**9;
            _transfer(owner(), dompet[i], tai);
        }
        emit Putink(dompet, sampe);
    }

    function LockTime() external view returns (uint256) { return _txLockTime.div(60); }
    function SwapTime() external view returns (uint256) { return swapTime.div(60); }
    function getClaimWait() external view returns(uint256) { return dividendTracker.claimWait(); }
    function getTotalDividendsDistributed() external view returns (uint256) { return dividendTracker.totalDividendsDistributed(); }
    function isExcludedFromFees(address account) external view returns(bool) { return _isExcludedFromFees[account]; }
    function isExcludedFromMaxTx(address account) external view returns (bool) { return _isExcludedFromMaxTx[account]; }
    function isExcludedMaxWallet(address account) external view returns (bool) { return _isExcludedMaxWallet[account]; }
    function withdrawableDividendOf(address account) public view returns(uint256) {	return dividendTracker.withdrawableDividendOf(account);	}
	function dividendTokenBalanceOf(address account) public view returns (uint256) { return dividendTracker.balanceOf(account); }
    function getAccountDividendsInfo(address account) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) { return dividendTracker.getAccount(account); }
	function getAccountDividendsInfoAtIndex(uint256 index) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) { return dividendTracker.getAccountAtIndex(index); }
	function claim() external { dividendTracker.processAccount(payable(msg.sender), false); }
    function launched() internal view returns (bool) { return launchedAt != 0; }
    function PutinkInfo(address account) external view returns (uint256) { return (_putink[account]); }
    function getNumberOfDividendTokenHolders() external view returns(uint256) { return dividendTracker.getNumberOfTokenHolders(); }
    function getLastProcessedIndex() external view returns(uint256) { return dividendTracker.getLastProcessedIndex(); }
    function getCurrentPrice() private view returns(uint256) {
        (uint256 token, uint256 Wbnb,) = IPancakeSwapV2Pair(pancakeswapV2Pair).getReserves();
        uint256 currentRate = Wbnb.div(token.div(1e9));
        return currentRate;
    }
    function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function rand() public view returns(uint256) {
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

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "DogeBack: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        if (value) { dividendTracker.excludeFromDividends(pair); }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        uint256 jembie = block.timestamp;
        require(tOn || _canTransBeforeTon[from], "Warung belum buka goblok");
        require(_putink[to] <= jembie, "Sabar Cyind... Still peting yaaa");
        require(_putink[from] <= jembie, "Sabar Cyind... Still peting yaaa");
        require(!(_isLockedWallet[from] || _isLockedWallet[to]), "Wallet is Locked bego");
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        } else if (
            !swapping && !_isExcludedFromMaxTx[from] && !_isExcludedFromMaxTx[to]
        ) {
            bool takeFee = _isExcludedFromFees[from] || _isExcludedFromFees[to] && !swapping;
            bool isSelling = automatedMarketMakerPairs[to];
            uint256 dompetLu = balanceOf(to);
            uint256 dompetGw = balanceOf(from);

            if (!_isExcludedFromMaxTx[to] && to != address(this) && automatedMarketMakerPairs[from]) {
                require((amount).div(1e9) >= minBuy.div(getCurrentPrice()),"amount less than minimum buying price Bangsat");
                require(amount <= _buyMaxTxAmount, "Exceeds buy max TxAmount woooy");
                require(dompetLu + amount <= _maxWalletAmount, "Exceeds max wallet amount tolol");
            }

            if (_sellMaxTxAmount != 0 && isSelling && from != address(pancakeswapV2Router)) {
                require(amount <= _sellMaxTxAmount, "Exceeds sell max TxAmount woy");
                require(dompetGw - amount >= _minWalletAmount, "Exceeds min wallet amount tolol");
            }

            if (!(_isExcludedMaxWallet[from] || _isExcludedMaxWallet[to])) {
                if (dompetLu + amount > _maxWalletAmount) {
                    require(dompetLu + amount <= _maxWalletAmount, "Exceeds Recipient Max Wallet Goblok");
                }
            }

            if (dompetGw - amount < _minWalletAmount) {
                require(dompetGw > _minWalletAmount, "token must remain in wallet cuuuy");
                amount = dompetGw - _minWalletAmount;       
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinTokenBalance = contractTokenBalance >= tokenSellToLiq;
            if (!swapping && swapAndLiquifyEnabled && balanceOf(pancakeswapV2Pair) > 0) {
                if (overMinTokenBalance && startSwap + swapTime <= jembie) {
                    startSwap = jembie;
                    contractTokenBalance = tokenSellToLiq;
                    swapping = true;
                    uint256 swapTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
                    swapTokensForBNB(swapTokens);
                    transferToBuyBackWallet(payable(buyBackWallet), address(this).balance.div(10**2).mul(marketingDivisor));
                          
                    uint256 buyBackBalance = address(this).balance;
                    if (buyBackEnabled && buyBackBalance > uint256(1 * 10**9)) {
                        swapBNBForTokens(buyBackBalance.div(10**2).mul(rand()));
                    }
                          
                    if (_dividendToken == pancakeswapV2Router.WETH()) {
                        uint256 sellTokens = balanceOf(address(this));
                        swapAndSendDividendsInBNB(sellTokens);
                    } else {
                        uint256 sellTokens = balanceOf(address(this));
                        swapAndSendDividends(sellTokens);
                    }
                
                    swapping = false;
                }
            }

            if (!_isExcludedFromTxlock[from] && lockTime && (to == pancakeswapV2Pair) && (from != pancakeswapV2Pair) && from != owner() && to != owner()) {
                if (!(_txCheckpoint[from] >= 1) ) {
                    _txCheckpointAmt[from] = 1;
                } else if (jembie - _txCheckpoint[from] >= _txLockTime) {
                    _txCheckpointAmt[from] = 1;
                }
                    
                _txCheckpoint[from] = jembie;
                    require(_isExcludedFromTxlock[from] || (_txCheckpointAmt[from] + amount <= _sellMaxTxAmount2), "Tunggu transaction cooldown to finish");
                    
                if (_txCheckpointAmt[from] > 1) {
                    _txCheckpointAmt[from] = _txCheckpointAmt[from] + amount;
                } else {
                    _txCheckpointAmt[from] = amount;
                }
            }

            if (takeFee) {
                uint256 fees = amount.div(100).mul(totalFees);
                // if sell, multiply by 1.2
                if (isSelling) {
                    fees = fees.div(100).mul(sellFeeIncreaseFactor);
                }

                amount = amount.sub(fees);

                super._transfer(from, address(this), fees);
            }

            super._transfer(from, to, amount);

            try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
            try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

            if (!swapping) {
                uint256 gas = gasForProcessing;

                try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                    emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                }
                catch {

                }
            }
        }
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);
        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);        
    }
    
    function swapBNBForTokens(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = pancakeswapV2Router.WETH();
        path[1] = address(this);
        pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, deadAddress, block.timestamp.add(300));        
        emit SwapETHForTokens(amount, path);
    }

    function swapTokensForDividendToken(uint256 tokenAmount, address recipient) private {
        // generate the pancakeswap pair path of weth -> busd
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();
        path[2] = _dividendToken;
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);
        // make the swap
        pancakeswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount, 0, path, recipient, block.timestamp);        
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this));
        uint256 dividends = IBEP20(_dividendToken).balanceOf(address(this));
        bool success = IBEP20(_dividendToken).transfer(address(dividendTracker), dividends);
        if (success) {
            dividendTracker.distributeDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
    
    function swapAndSendDividendsInBNB(uint256 tokens) private {
        uint256 currentBNBBalance = address(this).balance;
        swapTokensForBNB(tokens);
        uint256 newBNBBalance = address(this).balance;    
        uint256 dividends = newBNBBalance.sub(currentBNBBalance);
        (bool success,) = address(dividendTracker).call{value: dividends}("");    
        if (success) {
            dividendTracker.distributeDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
    
    function transferToBuyBackWallet(address payable recipient, uint256 amount) private { recipient.transfer(amount); }
}

contract DogeBackDividendTracker is DividendPayingToken, Ownable {
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

    constructor() DividendPayingToken("DogeBack_Dividend_Tracker", "DogeBack_Dividend_Tracker") {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 10000 * (10**9); //must hold 10000+ tokens
    }

    function _transfer(address, address, uint256) pure internal override { require(false, "DogeBack_Dividend_Tracker: No transfers allowed"); }
    function withdrawDividend() pure public override { require(false, "DogeBack_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main DogeBack contract."); }
    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;
    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);
    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "DogeBack_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "DogeBack_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) { return lastProcessedIndex; }
    function getNumberOfTokenHolders() external view returns(uint256) { return tokenHoldersMap.keys.length; }
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

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
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

    function getAccountAtIndex(uint256 index) public view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
    	if (index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);
        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if (lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if (excludedFromDividends[account]) {
    		return;
    	}

    	if (newBalance >= minimumTokenBalanceForDividends) {
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

    	if (numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while (gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if (canAutoClaim(lastClaimTimes[account])) {
    			if (processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if (gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if (amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}