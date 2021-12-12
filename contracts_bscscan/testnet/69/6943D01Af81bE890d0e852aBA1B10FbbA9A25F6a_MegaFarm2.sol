/**
 *Submitted for verification at BscScan.com on 2021-12-12
*/

/**
 * Mega Farm Token / MEGAFARM
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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
    function initialize(address, address) external;
}

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract MegaFarm2 is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    string private _name = "MegaFarm2";
    string private _symbol = "MEGAFARM2";
    uint8 private _decimals = 18;
    
    bool public isTradingEnabled;
    uint256 private _tradingPausedTimestamp;
    // initialSupply is 100 billion
    uint256 constant initialSupply = 100000000000 * (10**18);
    // max wallet is 2% of initialSupply 
    uint256 public maxWalletAmount = initialSupply * 200 / 10000;  
    // max buy and sell tx is 0.2% of initialSupply
    uint256 public maxTxAmount = initialSupply * 20 / 10000; //200_000_000 
    bool private _swapping;
    uint256 public minimumTokensBeforeSwap = 25000 * (10**18); 
    uint256 public gasForProcessing = 300000;
    uint256 private _liquidityTokensToSwap;
    uint256 private _marketingTokensToSwap;
    uint256 private _buyBackTokensToSwap;
    uint256 private _salaryTokensToSwap;
    uint256 private _equipmentTokensToSwap;
    
    address public marketingWallet;
    address public liquidityWallet;
    address public buyBackWallet;
    address public salaryWallet;
    address public equipmentWallet;
    
    struct CustomTaxPeriod {
        bytes23 periodName;
        uint8 blocksInPeriod;
        uint256 timeInPeriod;
        uint256 liquidityFeeOnBuy;
        uint256 liquidityFeeOnSell;
        uint256 marketingFeeOnBuy;
        uint256 marketingFeeOnSell;
        uint256 buyBackFeeOnBuy;
        uint256 buyBackFeeOnSell;
        uint256 salaryFeeOnBuy;
        uint256 salaryFeeOnSell;
        uint256 equipmentFeeOnBuy;
        uint256 equipmentFeeOnSell;
    }
    // Launch taxes
    bool private _isLanched;
    uint256 private _launchStartTimestamp;
    uint256 private _launchBlockNumber;
    uint256 private _launchSellMaximum =  initialSupply * 20 / 10000;
    CustomTaxPeriod private _launch1 = CustomTaxPeriod('launch1',3,0,     10000,  0,  0,0,  0,0,    0,0,0,0);
    CustomTaxPeriod private _launch2 = CustomTaxPeriod('launch2',0,3600,  0,      500,0,500,0,1500, 0,0,0,0);
    CustomTaxPeriod private _launch3 = CustomTaxPeriod('launch3',0,82800, 0,      500,0,500,0,500,  0,0,0,0); 

    // Base taxes
    uint256 public liquidityFeeOnBuy = 100;
    uint256 public marketingFeeOnBuy = 200;
    uint256 public salaryFeeOnBuy = 200;
    uint256 public buyBackFeeOnBuy = 300;
    uint256 public equipmentFeeOnBuy = 600;

    uint256 public liquidityFeeOnSell = 200;
    uint256 public marketingFeeOnSell = 200;
    uint256 public salaryFeeOnSell = 200;
    uint256 public buyBackFeeOnSell = 300;
    uint256 public equipmentFeeOnSell = 600;
   
    // Roar taxes
    uint256 private _roarStartTimestamp;
    CustomTaxPeriod private _roar1 = CustomTaxPeriod('roar1', 0,3600,0,0,100,750,0,750,0,0,600,600);
    CustomTaxPeriod private _roar2 = CustomTaxPeriod('roar2', 0,3600,0,0,0,600,0,600,0,0,600,600);
    CustomTaxPeriod private _roar3 = CustomTaxPeriod('roar3', 0,3600,0,0,0,450,0,450,0,0,600,600);
    
    uint256 private _blacklistTimeLimit = 21600;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxTransactionLimit;
    mapping (address => bool) private _isExcludedFromMaxWalletLimit;
    mapping (address => bool) private _isBlacklisted;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => uint256) private _buyTimesInLaunch;

    event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
    event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
    event LiquidityWalletChange(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event MarketingWalletChange(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event BuyBackWalletChange(address indexed newBuyBackWallet, address indexed oldBuyBackWallet);
    event SalaryWalletChange(address indexed newSalaryWallet, address indexed oldSalaryWallet);
    event GasForProcessingChange(uint256 indexed newValue, uint256 indexed oldValue);
    event FeeOnSellChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType);
    event FeeOnBuyChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType);
    event CustomTaxPeriodChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType, bytes23 period);
    event BlacklistChange(address indexed holder, bool indexed status);
    event MegaFarmRoarChange(bool indexed newValue, bool indexed oldValue);
    event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
    event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
    
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived,uint256 tokensIntoLiqudity);
    
    constructor() ERC20("MEGAFARM", "MEGAFARM") {
        liquidityWallet = address(0xAF1a6c830c2f68e52703804138090Eb6e475108e); // Testnet
        marketingWallet = address(0xf10619F489e0ee3fd37d0eFf861bAbA775cAb333); // Testnet
        salaryWallet = address(0x075598Cd42EEC6B760D2C4c1Ea3dBF06563A5C75); // Testnet
        buyBackWallet = address(0x07d63Df664fBf679595D15D45D096Ec6F3A6204B); // Testnet
        equipmentWallet = address(0xBc429E24d949852Eb5FF6EdCF2F263600E3AE0cb); // Testnet
    
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // Testnet
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Mainnet
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
    
        _isExcludedFromMaxTransactionLimit[address(this)] = true;
        
        _isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[owner()] = true;
        
        _mint(owner(), initialSupply);
    }
    
    receive() external payable {}
    
    // Setters
    function _getNow() private view returns (uint256) {
        return block.timestamp;
    }
    function launch() public onlyOwner {
        _launchStartTimestamp = _getNow();
        _launchBlockNumber = block.number;
         isTradingEnabled = true;
        _isLanched = true;
    }
    function cancelLaunch() public onlyOwner {
        require(this.isInLaunch(), "MEGAFARM: Launch is not set");
        _launchStartTimestamp = 0;
        _launchBlockNumber = 0;
    }
    function activateTrading() public onlyOwner {
        isTradingEnabled = true;
    }
    function deactivateTrading() public onlyOwner {
        isTradingEnabled = false;
        _tradingPausedTimestamp = _getNow();
    }
    function setMegaFarmRoar() public onlyOwner {
        require(!this.isInRoar(), "MEGAFARM: Roar is already set");
        require(isTradingEnabled, "MEGAFARM: Trading must be enabled first");
        require(!this.isInLaunch(), "MEGAFARM: Must not be in launch period");
        emit MegaFarmRoarChange(true, false);
        _roarStartTimestamp = _getNow();
    }
    function cancelMegaFarmRoar() public onlyOwner {
        require(this.isInRoar(), "MEGAFARM: Roar is not set");
        emit MegaFarmRoarChange(false, true);
        _roarStartTimestamp = 0;
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "MEGAFARM: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit AutomatedMarketMakerPairChange(pair, value);
    }
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFee[account] != excluded, "MEGAFARM: Account is already the value of 'excluded'");
        _isExcludedFromFee[account] = excluded;
        emit ExcludeFromFeesChange(account, excluded);
    }
    function excludeFromMaxTransactionLimit(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromMaxTransactionLimit[account] != excluded, "MEGAFARM: Account is already the value of 'excluded'");
        _isExcludedFromMaxTransactionLimit[account] = excluded;
        emit ExcludeFromMaxTransferChange(account, excluded);
    }
    function excludeFromMaxWalletLimit(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromMaxWalletLimit[account] != excluded, "MEGAFARM: Account is already the value of 'excluded'");
        _isExcludedFromMaxWalletLimit[account] = excluded;
        emit ExcludeFromMaxWalletChange(account, excluded);
    }
    function blacklistAccount(address account) public onlyOwner {
        uint256 currentTimestamp = _getNow();
        require(!_isBlacklisted[account], "MEGAFARM: Account is already blacklisted");
        if (_isLanched) {
            require(currentTimestamp.sub(_launchStartTimestamp) < _blacklistTimeLimit, "MEGAFARM: Time to blacklist accounts has expired");
        }
        _isBlacklisted[account] = true;
        emit BlacklistChange(account, true);
    }
    function unBlacklistAccount(address account) public onlyOwner {
        require(_isBlacklisted[account], "MEGAFARM: Account is not blacklisted");
        _isBlacklisted[account] = false;
        emit BlacklistChange(account, false);
    }
    function setLiquidityWallet(address newAddress) public onlyOwner {
        require(liquidityWallet != newAddress, "MEGAFARM: The liquidityWallet is already that address");
        emit LiquidityWalletChange(newAddress, liquidityWallet);
        liquidityWallet = newAddress;
    }
    function setMarketingWallet(address newAddress) public onlyOwner {
        require(marketingWallet != newAddress, "MEGAFARM: The marketingWallet is already that address");
        emit MarketingWalletChange(newAddress, marketingWallet);
        marketingWallet = newAddress;
    }
    function setBuyBackWallet(address newAddress) public onlyOwner {
        require(buyBackWallet != newAddress, "MEGAFARM: The buyBackWallet is already that address");
        emit BuyBackWalletChange(newAddress, buyBackWallet);
        buyBackWallet = newAddress;
    }
    function setSalaryWallet(address newAddress) public onlyOwner {
        require(salaryWallet != newAddress, "MEGAFARM: The salaryWallet is already that address");
        emit SalaryWalletChange(newAddress, salaryWallet);
        salaryWallet = newAddress;
    }
    function setLiquidityFeeOnBuy(uint256 newvalue) public onlyOwner {
        require(liquidityFeeOnBuy != newvalue, "MEGAFARM: The liquidityFeeOnBuy is already that value");
        emit FeeOnBuyChange(newvalue, liquidityFeeOnBuy, "liquidityFeeOnBuy");
        liquidityFeeOnBuy = newvalue;
    }
    function setMarketingFeeOnBuy(uint256 newvalue) public onlyOwner {
        require(marketingFeeOnBuy != newvalue, "MEGAFARM: The marketingFeeOnBuy is already that value");
        emit FeeOnBuyChange(newvalue, marketingFeeOnBuy, "marketingFeeOnBuy");
        marketingFeeOnBuy = newvalue;
    }
    function setBuyBackFeeOnBuy(uint256 newvalue) public onlyOwner {
        require(buyBackFeeOnBuy != newvalue, "MEGAFARM: The buyBackFeeOnBuy is already that value");
        emit FeeOnBuyChange(newvalue, buyBackFeeOnBuy, "buyBackFeeOnBuy");
        buyBackFeeOnBuy = newvalue;
    }
    function setSalaryFeeOnBuy(uint256 newvalue) public onlyOwner {
        require(salaryFeeOnBuy != newvalue, "MEGAFARM: The salaryFeeOnBuy is already that value");
        emit FeeOnBuyChange(newvalue, salaryFeeOnBuy, "salaryFeeOnBuy");
        salaryFeeOnBuy = newvalue;
    }
    function setLiquidityFeeOnSell(uint256 newvalue) public onlyOwner {
        require(liquidityFeeOnSell != newvalue, "MEGAFARM: The liquidityFeeOnSell is already that value");
        emit FeeOnSellChange(newvalue, liquidityFeeOnSell, "liquidityFeeOnSell");
        liquidityFeeOnSell = newvalue;
    }
    function setMarketingFeeOnSell(uint256 newvalue) public onlyOwner {
        require(marketingFeeOnSell != newvalue, "MEGAFARM: The marketingFeeOnSell is already that value");
        emit FeeOnSellChange(newvalue, marketingFeeOnSell, "marketingFeeOnSell");
        marketingFeeOnSell = newvalue;
    }
    function setBuyBackFeeOnSell(uint256 newvalue) public onlyOwner {
        require(buyBackFeeOnSell != newvalue, "MEGAFARM: The buyBackFeeOnSell is already that value");
        emit FeeOnSellChange(newvalue, buyBackFeeOnSell, "buyBackFeeOnSell");
        buyBackFeeOnSell = newvalue;
    }
    function setSalaryFeeOnSell(uint256 newvalue) public onlyOwner {
        require(salaryFeeOnSell != newvalue, "MEGAFARM: The salaryFeeOnSell is already that value");
        emit FeeOnSellChange(newvalue, salaryFeeOnSell, "salaryFeeOnSell");
        salaryFeeOnSell = newvalue;
    }
    function setRoar1BuyFees(uint256 _liquidityFeeOnBuy,uint256 _marketingFeeOnBuy,uint256 _buyBackFeeOnBuy,uint256 _salaryFeeOnBuy,uint256 _equipmentFeeOnBuy) public onlyOwner {
        _setCustomBuyTaxPeriod(_roar1,_liquidityFeeOnBuy, _marketingFeeOnBuy,_buyBackFeeOnBuy,_salaryFeeOnBuy, _equipmentFeeOnBuy);
    }
    function setRoar1SellFees(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell,uint256 _buyBackFeeOnSell,uint256 _salaryFeeOnSell,uint256 _equipmentFeeOnSell) public onlyOwner {
        _setCustomSellTaxPeriod(_roar1,_liquidityFeeOnSell, _marketingFeeOnSell,_buyBackFeeOnSell,_salaryFeeOnSell, _equipmentFeeOnSell);
    }
    function setRoar2BuyFees(uint256 _liquidityFeeOnBuy,uint256 _marketingFeeOnBuy,uint256 _buyBackFeeOnBuy,uint256 _salaryFeeOnBuy,uint256 _equipmentFeeOnBuy) public onlyOwner {
        _setCustomBuyTaxPeriod(_roar2,_liquidityFeeOnBuy, _marketingFeeOnBuy,_buyBackFeeOnBuy,_salaryFeeOnBuy, _equipmentFeeOnBuy);
    }
    function setRoar2SellFees(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell,uint256 _buyBackFeeOnSell,uint256 _salaryFeeOnSell,uint256 _equipmentFeeOnSell) public onlyOwner {
        _setCustomSellTaxPeriod(_roar2,_liquidityFeeOnSell, _marketingFeeOnSell,_buyBackFeeOnSell,_salaryFeeOnSell, _equipmentFeeOnSell);
    }
    function setRoar3BuyFees(uint256 _liquidityFeeOnBuy,uint256 _marketingFeeOnBuy,uint256 _buyBackFeeOnBuy,uint256 _salaryFeeOnBuy,uint256 _equipmentFeeOnBuy) public onlyOwner {
        _setCustomBuyTaxPeriod(_roar3,_liquidityFeeOnBuy, _marketingFeeOnBuy,_buyBackFeeOnBuy,_salaryFeeOnBuy, _equipmentFeeOnBuy);
    }
    function setRoar3SellFees(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell,uint256 _buyBackFeeOnSell,uint256 _salaryFeeOnSell,uint256 _equipmentFeeOnSell) public onlyOwner {
        _setCustomSellTaxPeriod(_roar3,_liquidityFeeOnSell, _marketingFeeOnSell,_buyBackFeeOnSell,_salaryFeeOnSell, _equipmentFeeOnSell);
    }
    function setUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "MEGAFARM: The router already has that address");
        emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
    function setGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "MEGAFARM: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "MEGAFARM: Cannot update gasForProcessing to same value");
        emit GasForProcessingChange(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }
    function setMaxTxAmount(uint256 newValue) public onlyOwner {
        require(newValue != maxTxAmount, "MEGAFARM: Cannot update maxTxAmount to same value");
        emit MaxTransactionAmountChange(newValue, maxTxAmount);
        maxTxAmount = newValue;
    }
    function setMaxWalletAmount(uint256 newValue) public onlyOwner {
        require(newValue != maxWalletAmount, "MEGAFARM: Cannot update maxWalletAmount to same value");
        emit MaxWalletAmountChange(newValue, maxWalletAmount);
        maxWalletAmount = newValue;
    }
    function setMinimumTokensBeforeSwap(uint256 newValue) public onlyOwner {
        require(newValue != minimumTokensBeforeSwap, "MEGAFARM: Cannot update minimumTokensBeforeSwap to same value");
        emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
        minimumTokensBeforeSwap = newValue;
    }
    
    // Getters
    function isInRoar() external view returns (bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _roarStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 totalRoarTime = _roar1.timeInPeriod.add(_roar2.timeInPeriod).add(_roar3.timeInPeriod);
        uint256 timeSinceRoar = currentTimestamp.sub(_roarStartTimestamp);
        if(timeSinceRoar < totalRoarTime) {
            return true;
        } else {
            return false;
        }
    }
    function isInLaunch() external view returns (bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 timeSinceLaunch = currentTimestamp.sub(_launchStartTimestamp);
        uint256 blocksSinceLaunch = block.number.sub(_launchBlockNumber);
        uint256 totalLaunchTime =  _launch1.timeInPeriod.add(_launch2.timeInPeriod).add(_launch3.timeInPeriod);
        
        if(_isLanched && (timeSinceLaunch < totalLaunchTime || blocksSinceLaunch < _launch1.blocksInPeriod )) {
            return true;
        } else {
            return false;
        }
    }
    function getRoar1BuyFees() external view returns (uint256, uint256, uint256,uint256){
        return (_roar1.liquidityFeeOnBuy,_roar1.marketingFeeOnBuy, _roar1.buyBackFeeOnBuy, _roar1.salaryFeeOnBuy);
    }
    function getRoar1SellFees() external view returns (uint256, uint256, uint256,uint256){
        return (_roar1.liquidityFeeOnSell,_roar1.marketingFeeOnSell, _roar1.buyBackFeeOnSell, _roar1.salaryFeeOnSell);
    }
    function getRoar2BuyFees() external view returns (uint256, uint256, uint256,uint256){
        return (_roar2.liquidityFeeOnBuy,_roar2.marketingFeeOnBuy, _roar2.buyBackFeeOnBuy, _roar2.salaryFeeOnBuy);
    }
    function getRoar2SellFees() external view returns (uint256, uint256, uint256,uint256){
        return (_roar2.liquidityFeeOnSell,_roar2.marketingFeeOnSell, _roar2.buyBackFeeOnSell, _roar2.salaryFeeOnSell);
    }
    function getRoar3BuyFees() external view returns (uint256, uint256, uint256,uint256){
        return (_roar3.liquidityFeeOnBuy,_roar3.marketingFeeOnBuy, _roar3.buyBackFeeOnBuy, _roar3.salaryFeeOnBuy);
    }
    function getRoar3SellFees() external view returns (uint256, uint256, uint256,uint256){
        return (_roar3.liquidityFeeOnSell,_roar3.marketingFeeOnSell, _roar3.buyBackFeeOnSell, _roar3.salaryFeeOnSell);
    }
    
    // Main
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        bool isBuyFromLp = automatedMarketMakerPairs[from];
        bool _isInLaunch = this.isInLaunch();
        
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        
        if(from != owner() && to != owner()) {
            require(isTradingEnabled, "MEGAFARM: Trading is currently disabled.");
            require(!_isBlacklisted[to], "MEGAFARM: Account is blacklisted");
            require(!_isBlacklisted[from], "MEGAFARM: Account is blacklisted");
            if (_isInLaunch && currentTimestamp.sub(_launchStartTimestamp) <= 300 && isBuyFromLp) {
                require(currentTimestamp.sub(_buyTimesInLaunch[to]) > 60, "MEGAFARM: Cannot buy more than once per min in first 5min of launch");
            }
            if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
                require(amount <= maxTxAmount, "MEGAFARM: Buy amount exceeds the maxTxBuyAmount.");
            }
            if (!_isExcludedFromMaxWalletLimit[to]) {
                require(balanceOf(to).add(amount) <= maxWalletAmount, "MEGAFARM: Expected wallet amount exceeds the maxWalletAmount.");
            }
        }
        
        bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;
        
        if (
            isTradingEnabled && 
            canSwap &&
            !_swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet && to != liquidityWallet &&
            from != marketingWallet && to != marketingWallet &&
            from != buyBackWallet && to != buyBackWallet &&
            from != salaryWallet && to != salaryWallet
        ) {
            _swapping = true;
            _swapAndLiquify();
            _swapping = false;
        }
        
        bool takeFee = !_swapping && isTradingEnabled;
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        if (takeFee) {
            (uint256 returnAmount, uint256 fee) = _getCurrentTotalFee(isBuyFromLp, amount);
            amount = returnAmount;
            super._transfer(from, address(this), fee);
        }
        
        if (_isInLaunch && currentTimestamp.sub(_launchStartTimestamp) <= 300) {
            if (to != owner() && isBuyFromLp  && currentTimestamp.sub(_buyTimesInLaunch[to]) > 60) {
                _buyTimesInLaunch[to] = currentTimestamp;
            }
        }
        
        super._transfer(from, to, amount);
    }
    function _getCurrentTotalFee(bool isBuyFromLp, uint256 amount) internal returns (uint256 returnAmount, uint256 fee) {
        uint256 _liquidityFee = isBuyFromLp ? liquidityFeeOnBuy : liquidityFeeOnSell;
        uint256 _marketingFee = isBuyFromLp ? marketingFeeOnBuy : marketingFeeOnSell;
        uint256 _salaryFee = isBuyFromLp ? salaryFeeOnBuy : salaryFeeOnSell;
        uint256 _buyBackFee = isBuyFromLp ? buyBackFeeOnBuy : buyBackFeeOnSell;
        uint256 _equipmentFee = isBuyFromLp ? equipmentFeeOnBuy : equipmentFeeOnSell;
        
        if (this.isInLaunch()) {
            bool _isInLaunch1Period = _isInLaunch1();
            bool _isInLaunch2Period = _isInLaunch2();
           
            if (isBuyFromLp) {
                _liquidityFee = _isInLaunch1Period ? _launch1.liquidityFeeOnBuy : _liquidityFee;
            }
            else {
                _liquidityFee = _isInLaunch1Period ? _liquidityFee : _isInLaunch2Period ? _launch2.liquidityFeeOnSell : _launch3.liquidityFeeOnSell;
                _marketingFee = _isInLaunch1Period ? _marketingFee : _isInLaunch2Period ? _launch2.marketingFeeOnSell : _launch3.marketingFeeOnSell;
                _buyBackFee = _isInLaunch1Period ? _buyBackFee : _isInLaunch2Period ? _launch2.buyBackFeeOnSell : _launch3.buyBackFeeOnSell;
            }
        }
        if (this.isInRoar()) {
            if (_isInRoar1()) {
                _liquidityFee = isBuyFromLp && _roar1.liquidityFeeOnBuy > 0 ? _roar1.liquidityFeeOnBuy : !isBuyFromLp && _roar1.liquidityFeeOnSell > 0 ? _roar1.liquidityFeeOnSell : _liquidityFee;
                _marketingFee = isBuyFromLp && _roar1.marketingFeeOnBuy > 0 ? _roar1.marketingFeeOnBuy : !isBuyFromLp && _roar1.marketingFeeOnSell > 0 ? _roar1.marketingFeeOnSell : _marketingFee;
                _buyBackFee = isBuyFromLp && _roar1.buyBackFeeOnBuy > 0 ? _roar1.buyBackFeeOnBuy : !isBuyFromLp && _roar1.buyBackFeeOnSell > 0 ? _roar1.buyBackFeeOnSell : _buyBackFee;
                _salaryFee = isBuyFromLp && _roar1.salaryFeeOnBuy > 0 ? _roar1.salaryFeeOnBuy : !isBuyFromLp && _roar1.salaryFeeOnSell > 0 ? _roar1.salaryFeeOnSell : _salaryFee;
            }
            else if (_isInRoar2()) {
                _liquidityFee = isBuyFromLp && _roar2.liquidityFeeOnBuy > 0 ? _roar2.liquidityFeeOnBuy : !isBuyFromLp && _roar2.liquidityFeeOnSell > 0 ? _roar2.liquidityFeeOnSell : _liquidityFee;
                _marketingFee = isBuyFromLp && _roar2.marketingFeeOnBuy > 0 ? _roar2.marketingFeeOnBuy : !isBuyFromLp && _roar2.marketingFeeOnSell > 0 ? _roar2.marketingFeeOnSell : _marketingFee;
                _buyBackFee = isBuyFromLp && _roar2.buyBackFeeOnBuy > 0 ? _roar2.buyBackFeeOnBuy : !isBuyFromLp && _roar2.buyBackFeeOnSell > 0 ? _roar2.buyBackFeeOnSell : _buyBackFee;
                _salaryFee = isBuyFromLp && _roar2.salaryFeeOnBuy > 0 ? _roar2.salaryFeeOnBuy : !isBuyFromLp && _roar2.salaryFeeOnSell > 0 ? _roar2.salaryFeeOnSell : _salaryFee;
            }
            else {
                _liquidityFee = isBuyFromLp && _roar3.liquidityFeeOnBuy > 0 ? _roar3.liquidityFeeOnBuy : !isBuyFromLp && _roar3.liquidityFeeOnSell > 0 ? _roar3.liquidityFeeOnSell : _liquidityFee;
                _marketingFee = isBuyFromLp && _roar3.marketingFeeOnBuy > 0 ? _roar3.marketingFeeOnBuy : !isBuyFromLp && _roar3.marketingFeeOnSell > 0 ? _roar3.marketingFeeOnSell : _marketingFee;
                _buyBackFee = isBuyFromLp && _roar3.buyBackFeeOnBuy > 0 ? _roar3.buyBackFeeOnBuy : !isBuyFromLp && _roar3.buyBackFeeOnSell > 0 ? _roar3.buyBackFeeOnSell : _buyBackFee;
                _salaryFee = isBuyFromLp && _roar3.salaryFeeOnBuy > 0 ? _roar3.salaryFeeOnBuy : !isBuyFromLp && _roar3.salaryFeeOnSell > 0 ? _roar3.salaryFeeOnSell : _salaryFee;
            }
        }

        uint256 _totalFee = _liquidityFee.add(_marketingFee).add(_salaryFee).add(_buyBackFee).add(_equipmentFee);

        fee = amount.mul(_totalFee).div(10000);
        returnAmount = amount.sub(fee);
        _updateTokensToSwap(amount, _liquidityFee,_marketingFee, _buyBackFee, _salaryFee, _equipmentFee);
        return (returnAmount, fee);
    }
    function _updateTokensToSwap(uint256 amount, uint256 liquidityFee,uint256 marketingFee, uint256 buyBackFee, uint256 salaryFee, uint256 equipmentFee) private {
        _liquidityTokensToSwap = _liquidityTokensToSwap.add(amount.mul(liquidityFee).div(10000));
        _marketingTokensToSwap = _marketingTokensToSwap.add(amount.mul(marketingFee).div(10000));
        _buyBackTokensToSwap = _buyBackTokensToSwap.add(amount.mul(buyBackFee).div(10000));
        _salaryTokensToSwap = _salaryTokensToSwap.add(amount.mul(salaryFee).div(10000));
        _equipmentTokensToSwap = _equipmentTokensToSwap.add(amount.mul(equipmentFee).div(10000));
    }
    function _isInLaunch1() internal view returns(bool) {
        uint256 blocksSinceLaunch = block.number.sub(_launchBlockNumber);
        if(blocksSinceLaunch < _launch1.blocksInPeriod) {
            return true;
        } else {
            return false;
        }
    }
    function _isInLaunch2() internal view returns(bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 blocksSinceLaunch = block.number.sub(_launchBlockNumber);
        uint256 timeSinceLaunch = currentTimestamp.sub(_launchStartTimestamp);
        if (timeSinceLaunch < _launch1.timeInPeriod && blocksSinceLaunch > _launch1.blocksInPeriod ) {
            return true;
        } else {
            return false;
        }
    }
    function _isInLaunch3() internal view returns(bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 timeSinceLaunch = currentTimestamp.sub(_launchStartTimestamp);
        uint256 blocksSinceLaunch = block.number.sub(_launchBlockNumber);
        uint256 timeInLaunch = _launch3.timeInPeriod.add(_launch2.timeInPeriod);
        if (timeSinceLaunch > _launch2.timeInPeriod && timeSinceLaunch < timeInLaunch && blocksSinceLaunch > _launch1.blocksInPeriod) {
            return true;
        } else {
            return false;
        }
    }
    function _isInRoar1() internal view returns (bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _roarStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 timeSinceRoar = currentTimestamp.sub(_roarStartTimestamp);
        if(timeSinceRoar < _roar1.timeInPeriod) {
            return true;
        } else {
            return false;
        }
    }
    function _isInRoar2() internal view returns (bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _roarStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 timeSinceRoar = currentTimestamp.sub(_roarStartTimestamp);
        if(timeSinceRoar > _roar1.timeInPeriod && timeSinceRoar < _roar1.timeInPeriod.add(_roar2.timeInPeriod)) {
            return true;
        } else {
            return false;
        }
    }
    function _isInRoar3() internal view returns (bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _roarStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 timeSinceRoar = currentTimestamp.sub(_roarStartTimestamp);
        uint256 totalTimeInRoar1 = _roar1.timeInPeriod.add(_roar2.timeInPeriod);
        uint256 totalTimeInRoar2 = _roar1.timeInPeriod.add(_roar2.timeInPeriod).add(_roar3.timeInPeriod);
        if(timeSinceRoar > totalTimeInRoar1 && timeSinceRoar < totalTimeInRoar2) {
            return true;
        } else {
            return false;
        }
    }
    function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,
        uint256 _liquidityFeeOnSell,
        uint256 _marketingFeeOnSell,
        uint256 _buyBackFeeOnSell,
        uint256 _salaryFeeOnSell,
        uint256 _equipmentFeeOnSell
        ) private {
        if (map.liquidityFeeOnSell != _liquidityFeeOnSell) {
            emit CustomTaxPeriodChange(_liquidityFeeOnSell, map.liquidityFeeOnSell, 'liquidityFeeOnSell', map.periodName);
            map.liquidityFeeOnSell = _liquidityFeeOnSell;
        }
        if (map.marketingFeeOnSell != _marketingFeeOnSell) {
            emit CustomTaxPeriodChange(_marketingFeeOnSell, map.marketingFeeOnSell, 'marketingFeeOnSell', map.periodName);
            map.marketingFeeOnSell = _marketingFeeOnSell;
        }
        if (map.buyBackFeeOnSell != _buyBackFeeOnSell) {
            emit CustomTaxPeriodChange(_buyBackFeeOnSell, map.buyBackFeeOnSell, 'buyBackFeeOnSell', map.periodName);
            map.buyBackFeeOnSell = _buyBackFeeOnSell;
        }
        if (map.salaryFeeOnSell != _salaryFeeOnSell) {
            emit CustomTaxPeriodChange(_salaryFeeOnSell, map.salaryFeeOnSell, 'salaryFeeOnSell', map.periodName);
            map.salaryFeeOnSell = _salaryFeeOnSell;
        }
        if (map.equipmentFeeOnSell != _equipmentFeeOnSell) {
            emit CustomTaxPeriodChange(_equipmentFeeOnSell, map.equipmentFeeOnSell, 'equipmentFeeOnSell', map.periodName);
            map.equipmentFeeOnSell = _equipmentFeeOnSell;
        }
    }
    function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map,
        uint256 _liquidityFeeOnBuy,
        uint256 _marketingFeeOnBuy,
        uint256 _buyBackFeeOnBuy,
        uint256 _salaryFeeOnBuy,
        uint256 _equipmentFeeOnBuy
        ) private {
        if (map.liquidityFeeOnBuy != _liquidityFeeOnBuy) {
            emit CustomTaxPeriodChange(_liquidityFeeOnBuy, map.liquidityFeeOnBuy, 'liquidityFeeOnBuy', map.periodName);
            map.liquidityFeeOnBuy = _liquidityFeeOnBuy;
        }
        if (map.marketingFeeOnBuy != _marketingFeeOnBuy) {
            emit CustomTaxPeriodChange(_marketingFeeOnBuy, map.marketingFeeOnBuy, 'marketingFeeOnBuy', map.periodName);
            map.marketingFeeOnBuy = _marketingFeeOnBuy;
        }
        if (map.buyBackFeeOnBuy != _buyBackFeeOnBuy) {
            emit CustomTaxPeriodChange(_buyBackFeeOnBuy, map.buyBackFeeOnBuy, 'buyBackFeeOnBuy', map.periodName);
            map.buyBackFeeOnBuy = _buyBackFeeOnBuy;
        }
        if (map.salaryFeeOnBuy != _salaryFeeOnBuy) {
            emit CustomTaxPeriodChange(_salaryFeeOnBuy, map.salaryFeeOnBuy, 'salaryFeeOnBuy', map.periodName);
            map.salaryFeeOnBuy = _salaryFeeOnBuy;
        }
        if (map.equipmentFeeOnBuy != _equipmentFeeOnBuy) {
            emit CustomTaxPeriodChange(_equipmentFeeOnBuy, map.equipmentFeeOnBuy, 'equipmentFeeOnBuy', map.periodName);
            map.equipmentFeeOnBuy = _equipmentFeeOnBuy;
        }
    }
    function _swapAndLiquify() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _liquidityTokensToSwap.add(_marketingTokensToSwap).add(_salaryTokensToSwap).add(_buyBackTokensToSwap).add(_equipmentTokensToSwap);
        
        // Halve the amount of liquidity tokens
        uint256 tokensInMegaFarmForLiquidity = _liquidityTokensToSwap.div(2);
        uint256 amountToSwapForBNB = contractBalance.sub(tokensInMegaFarmForLiquidity);
        
        // initial BNB balance
        uint256 initialBNBBalance = address(this).balance;
        // Swap the MegaFarm for BNB
        _swapTokensForBNB(amountToSwapForBNB); 
        // Get the balance, minus what we started with
        uint256 bnbBalance = address(this).balance.sub(initialBNBBalance);
        // Divvy up the BNB based on accrued tokens as % of total accrued
        uint256 bnbForMarketing = bnbBalance.mul(_marketingTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForBuyBack = bnbBalance.mul(_buyBackTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForSalary = bnbBalance.mul(_salaryTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForEquipment = bnbBalance.mul(_equipmentTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForLiquidity = bnbBalance.sub(bnbForMarketing).sub(bnbForBuyBack).sub(bnbForSalary).sub(bnbForEquipment);
        
        _liquidityTokensToSwap = 0;
        _marketingTokensToSwap = 0;
        _salaryTokensToSwap = 0;
        _buyBackTokensToSwap = 0;
        _equipmentTokensToSwap = 0;
        
        payable(buyBackWallet).transfer(bnbForBuyBack);
        payable(salaryWallet).transfer(bnbForSalary);
        payable(marketingWallet).transfer(bnbForMarketing);
        payable(equipmentWallet).transfer(bnbForEquipment);
        
        _addLiquidity(tokensInMegaFarmForLiquidity, bnbForLiquidity);
        emit SwapAndLiquify(amountToSwapForBNB, bnbForLiquidity, tokensInMegaFarmForLiquidity);
    }
    function _swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }
}