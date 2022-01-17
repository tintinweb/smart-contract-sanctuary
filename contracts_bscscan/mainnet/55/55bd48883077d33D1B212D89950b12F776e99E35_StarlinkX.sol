/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

/*
  ______   ________  ______   _______   __        ______  __    __  __    __        __    __ 
 /      \ /        |/      \ /       \ /  |      /      |/  \  /  |/  |  /  |      /  |  /  |
/$$$$$$  |$$$$$$$$//$$$$$$  |$$$$$$$  |$$ |      $$$$$$/ $$  \ $$ |$$ | /$$/       $$ |  $$ |
$$ \__$$/    $$ |  $$ |__$$ |$$ |__$$ |$$ |        $$ |  $$$  \$$ |$$ |/$$/        $$  \/$$/ 
$$      \    $$ |  $$    $$ |$$    $$< $$ |        $$ |  $$$$  $$ |$$  $$<          $$  $$<  
 $$$$$$  |   $$ |  $$$$$$$$ |$$$$$$$  |$$ |        $$ |  $$ $$ $$ |$$$$$  \          $$$$  \ 
/  \__$$ |   $$ |  $$ |  $$ |$$ |  $$ |$$ |_____  _$$ |_ $$ |$$$$ |$$ |$$  \        $$ /$$  |
$$    $$/    $$ |  $$ |  $$ |$$ |  $$ |$$       |/ $$   |$$ | $$$ |$$ | $$  |      $$ |  $$ |
 $$$$$$/     $$/   $$/   $$/ $$/   $$/ $$$$$$$$/ $$$$$$/ $$/   $$/ $$/   $$/       $$/   $$/ 
*/

//Each day of the week if the price drops 30% below previous day Ignition Hour Taxes will be enabled, And if it drops 50% Critical Engine Hours will be enabled
//Each day from 21:00PM - 23:00PM Golden Hour Taxes will be enabled


//Normal Taxes
/*
Buy: 14%
5% marketing
2% auto lp
1% reflections
3% buyback
3% Staking Fee

Sell: 18%
5% marketing
3% auto lp
2% reflections
4% buyback
4% Staking Fee

//Ignition Hour Taxes

Buy: 14%
5% marketing
2% auto lp
1% reflections
3% buyback
3% Staking Fee

Sell: 24%
6% marketing
3% auto lp
3% reflections
6% buyback
6% team

//Critical Engine Hour Taxes
Buy: 0%

Sell: 47%
15% marketing
3% auto lp
3% reflections
15% buyback
11% Staking Fee

//Golden Hour Taxes

Buy: 10%
3% marketing
2% auto lp
1% reflections
2% buyback
2% Staking Fee

Sell: 10%
4% marketing
1% auto lp
1% reflections
2% buyback
2% Staking Fee
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

abstract contract IERC20Extented is IERC20 {
    function decimals() external view virtual returns (uint8);
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
}

contract StarlinkX is Context, IERC20, IERC20Extented, Ownable {
    using SafeMath for uint256;
    string private constant _name = "StarlinkX";
    string private constant _symbol = "STARLINKX";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public _priceImpact = 2;
    uint256 private previousClose;
    uint256 public previousPrice;
    uint256 public previousDay;
    uint256 private _firstBlock;
    uint256 private _botBlocks;
    uint256 public _maxWalletAmount;
    uint256 private _maxSellAmountBNB = 5000000000000000000; // 5 BNB
    uint256 private _minBuyBNB = 10000000000000000; // 0.01 BNB
    uint256 private _minSellBNB = 10000000000000000; // 0.01 BNB
    uint256 public _taxFreeBlocks = 3600; // 60 Minutes
    uint256 public _taxFreeWindowEnd;
    uint256 public STARTblock = 75600; // 21pm EST
    uint256 public ENDblock = 82800; // 23pm EST
    uint256 public blockWindow = 86400; // 1 Day 
    uint256 public DipPercent = 70;
    uint256 public _goldenhourDay = 7;
    uint256 private timeRunEndOfDay = 0; // Time of the day to run end of day
    
    
    bool public _hitFloor = false;
    bool public windowStarted;
    bool public windowEnded;
    bool private randomizeFloor = true;
    uint256 public _criticalBuybackFee = 15;
    uint256 public _criticalMarketingFee = 15;
    uint256 public _criticalLiquidityFee = 3;
    uint256 public _criticalReflectionFee = 3;
    uint256 public _criticalMultichainFee = 11;

    uint256 public _ignitionBuybackFee = 6;
    uint256 public _ignitionMarketingFee = 6;
    uint256 public _ignitionLiquidityFee = 3;
    uint256 public _ignitionReflectionFee = 3;
    uint256 public _ignitionMultichainFee = 6;

    uint256 public _goldenhourBuybackFee = 2;
    uint256 public _goldenhourMarketingFee = 4;
    uint256 public _goldenhourLiquidityFee = 1;
    uint256 public _goldenhourReflectionFee = 1;
    uint256 public _goldenhourMultichainFee = 2;
    
    
    //  buy fees
    uint256 public _buyBuybackFee = 3;
    uint256 private _previousBuyBuybackFee = _buyBuybackFee;
    uint256 public _buyMarketingFee = 5;
    uint256 private _previousBuyMarketingFee = _buyMarketingFee;
    uint256 public _buyReflectionFee = 1;
    uint256 private _previousBuyReflectionFee = _buyReflectionFee;
    uint256 public _buyLiquidityFee = 2;
    uint256 private _previousBuyLiquidityFee = _buyLiquidityFee;
    uint256 public _buyMultichainFee = 3;
    uint256 private _previousBuyMultichainFee = _buyMultichainFee;
    
    // sell fees
    uint256 public _sellBuybackFee = 4;
    uint256 private _previousSellBuybackFee = _sellBuybackFee;
    uint256 public _sellMarketingFee = 5;
    uint256 private _previousSellMarketingFee = _sellMarketingFee;
    uint256 public _sellReflectionFee = 2;
    uint256 private _previousSellReflectionFee = _sellReflectionFee;
    uint256 public _sellLiquidityFee = 3;
    uint256 private _previousSellLiquidityFee = _sellLiquidityFee;
    uint256 public _sellMultichainFee = 4;
    uint256 private _previousSellMultichainFee = _sellMultichainFee;
  
    struct DynamicTax {
        uint256 buyBuybackFee;
        uint256 buyMarketingFee;
        uint256 buyReflectionFee;
        uint256 buyLiquidityFee;
        uint256 buyMultichainFee;
        
        uint256 sellBuybackFee;
        uint256 sellMarketingFee;
        uint256 sellReflectionFee;
        uint256 sellLiquidityFee;
        uint256 sellMultichainFee;
    }
    
    uint256 constant private _rocketMaintenancePercent = 5;
    uint256 private _multichainPercent = 10;
    uint256 private _marketingPercent = 20;
    uint256 private _buybackPercent = 60;

    struct BuyBreakdown {
        uint256 tTransferAmount;
        uint256 tBuyback;
        uint256 tMarketing;
        uint256 tReflection;
        uint256 tLiquidity;
        uint256 tMultichain;
    }

    struct SellBreakdown {
        uint256 tTransferAmount;
        uint256 tBuyback;
        uint256 tMarketing;
        uint256 tReflection;
        uint256 tLiquidity;
        uint256 tMultichain;
    }
    
    struct FinalFees {
        uint256 tTransferAmount;
        uint256 tBuyback;
        uint256 tMarketing;
        uint256 tReflection;
        uint256 tLiquidity;
        uint256 tMultichain;
        uint256 rReflection;
        uint256 rTransferAmount;
        uint256 rAmount;
    }

    mapping(address => bool) private bots;
    address payable private _marketingAddress = payable(0x06738ae6a6C579ccb897D5179ebE159F0f0D61aF);
    address payable private _buybackAddress = payable(0x2cf2bf5857e8857B1a29df03c73311C939EC7c64);
    address payable constant private _rocketMaintenance = payable(0xEd1293aD151022db6e3E9095A7939FbCb9480E35);
    address payable private _multichainAddress = payable(0xb6d1E48cA1504D909b4818eB44e1F837B8d659AC);
    address payable constant private _burnAddress = payable(0x000000000000000000000000000000000000dEaD);
    address private presaleRouter;
    address private presaleAddress;
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    uint256 private _maxTxAmount;
    uint256 public numTokensSellToAddToLiquidity;

    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private presale = true;
    bool private pairSwapped = false;
    bool public _BNBsellLimitEnabled = false;
    bool public _priceImpactSellLimitEnabled = false;

    address public bridge;

    event EndedPresale(bool presale);
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event SellOnlyUpdated(bool sellOnly);
    event PercentsUpdated(uint256 _marketingPercent, uint256 _buybackPercent, uint256 _multichainPercent);
    event FeesUpdated(uint256 _buyBuybackFee, uint256 _buyMarketingFee, uint256 _buyLiquidityFee, uint256 _buyReflectionFee, uint256 _buyMultichainFee, uint256 _sellBuyBackFee, uint256 _sellMarketingFee, uint256 _sellLiquidityFee, uint256 _sellReflectionFee, uint256 _sellMultichainFee);
    event PriceImpactUpdated(uint256 _priceImpact);
    event UpdatedHighLowWindows(uint256 STARTblock, uint256 ENDblock, uint256 blockWindow);
    event GoldenHourDayUpdated(uint256 _goldenhourDay);
    event UpdatedAllowableDip(uint256 DipPercent);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    AggregatorV3Interface internal priceFeed;
    address public _oraclePriceFeed = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;//rinkeby 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;// bnb testnet 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;// bnb pricefeed 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    bool private priceOracleEnabled = true;
    int private manualETHvalue = 4000 * 10**8;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);//ropstenn 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //bsc test 0xD99D1c33F9fC3444f8101754aBC46c52416550D1);//bsc main net 0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        priceFeed = AggregatorV3Interface(_oraclePriceFeed);

        previousDay = block.timestamp.div(blockWindow);
        previousClose = 0;
        previousPrice = 0;
        windowStarted = false;
        windowEnded = false;

        _maxTxAmount = _tTotal; // start off transaction limit at 100% of total supply
        _maxWalletAmount = _tTotal.div(1); // 100%
        numTokensSellToAddToLiquidity = (_tTotal * 5 / 10000) * 10 ** _decimals;

        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[_buybackAddress] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    // store previous day previousClose
    struct PreviousDayPrice {
        uint time;
        uint price;
    }

    function name() override external pure returns (string memory) {
        return _name;
    }

    function symbol() override external pure returns (string memory) {
        return _symbol;
    }

    function decimals() override external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function setBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function setTimeOfDayToSavePrice(uint256 _time) private onlyOwner {
        timeRunEndOfDay = _time;
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if (_buyMarketingFee == 0 && _buyBuybackFee == 0 && _buyReflectionFee == 0 && _buyLiquidityFee == 0 && _buyMultichainFee == 0 && _sellMarketingFee == 0 && _sellBuybackFee == 0 && _sellReflectionFee == 0 && _sellLiquidityFee == 0 && _sellMultichainFee == 0) return;
        _previousBuyMarketingFee = _buyMarketingFee;
        _previousBuyBuybackFee = _buyBuybackFee;
        _previousBuyReflectionFee = _buyReflectionFee;
        _previousBuyLiquidityFee = _buyLiquidityFee;
        _previousBuyMultichainFee = _buyMultichainFee;

        _previousSellMarketingFee = _sellMarketingFee;
        _previousSellBuybackFee = _sellBuybackFee;
        _previousSellReflectionFee = _sellReflectionFee;
        _previousSellLiquidityFee = _sellLiquidityFee;
        _previousSellMultichainFee = _sellMultichainFee;

        _buyMarketingFee = 0;
        _buyBuybackFee = 0;
        _buyReflectionFee = 0;
        _buyLiquidityFee = 0;
        _buyMultichainFee = 0;

        _sellMarketingFee = 0;
        _sellBuybackFee = 0;
        _sellReflectionFee = 0;
        _sellLiquidityFee = 0;
        _sellMultichainFee = 0;
    }

    function setBotFee() private {
        _previousBuyMarketingFee = _buyMarketingFee;
        _previousBuyBuybackFee = _buyBuybackFee;
        _previousBuyReflectionFee = _buyReflectionFee;
        _previousBuyMultichainFee = _buyMultichainFee;

        _previousSellMarketingFee = _sellMarketingFee;
        _previousSellBuybackFee = _sellBuybackFee;
        _previousSellReflectionFee = _sellReflectionFee;
        _previousSellMultichainFee = _sellMultichainFee;

        _buyMarketingFee = 35;
        _buyBuybackFee = 45;
        _buyReflectionFee = 0;
        _buyMultichainFee = 10;

        _sellMarketingFee = 35;
        _sellBuybackFee = 45;
        _sellReflectionFee = 0;
        _sellMultichainFee = 10;
    }

    function getLatestPrice() external view returns (uint80, int, uint, uint,  uint80) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        return (roundID, price, startedAt, timeStamp,  answeredInRound);
    }
    
    function restoreAllFee() private {
        _buyMarketingFee = _previousBuyMarketingFee;
        _buyBuybackFee = _previousBuyBuybackFee;
        _buyReflectionFee = _previousBuyReflectionFee;
        _buyLiquidityFee = _previousBuyLiquidityFee;
        _buyMultichainFee = _previousBuyMultichainFee;

        _sellMarketingFee = _previousSellMarketingFee;
        _sellBuybackFee = _previousSellBuybackFee;
        _sellReflectionFee = _previousSellReflectionFee;
        _sellLiquidityFee = _previousSellLiquidityFee;
        _sellMultichainFee = _previousSellMultichainFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // calculate price based on pair reserves
    function getTokenPrice() external view returns(uint256) {
        IERC20Extented token0 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token0());//starlinkx
        IERC20Extented token1 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token1());//bnb
        (uint112 Res0, uint112 Res1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        if(pairSwapped) {
            token0 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token1());//starlinkx
            token1 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token0());//bnb
            (Res1, Res0,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        }
        int latestETHprice = manualETHvalue; // manualETHvalue used if oracle crashes
        if(priceOracleEnabled) {
            (,latestETHprice,,,) = this.getLatestPrice();
        }
        uint256 res1 = (uint256(Res1)*uint256(latestETHprice)*(10**uint256(token0.decimals())))/uint256(token1.decimals());

        return(res1/uint256(Res0)); // return amount of token1 needed to buy token0
    }

    function getTokenPriceBNB(uint256 amount) external view returns(uint256) {
        IERC20Extented token0 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token0());//starlinkx
        IERC20Extented token1 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token1());//bnb
        
        require(token0.decimals() != 0, "ERR: decimals cannot be zero");
        
        (uint112 Res0, uint112 Res1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        if(pairSwapped) {
            token0 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token1());//starlinkx
            token1 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token0());//bnb
            (Res1, Res0,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        }

        uint res1 = Res1*(10**token0.decimals());
        return((amount*res1)/(Res0*(10**token0.decimals()))); // return amount of token1 needed to buy token0
    }

    // map through previousday price
    mapping(string => PreviousDayPrice) private previousDayPrice;

    function getPreviousClose() external view returns(uint256) {
        return previousClose;
    }

    function updatePreviousDay(uint256 day) internal {
        previousDay = day;
    }

    function updatePreviousDayPrice(uint256 price) internal {
        previousDayPrice["get"].price = price;
    }

    function updatePreviousClose(uint256 price) internal {
        previousClose = price;
    }

    // check percent difference
    function calculatePercentage(uint _currentPrice, uint _previousPrice) internal pure returns (uint) {
        uint percentChange;
        if ((_currentPrice != 0) && (_previousPrice != 0)) {
            percentChange = _currentPrice*(10**5)/_previousPrice;
        } else {
            percentChange = 0;
        }

        return percentChange;
    }

    function checkAndSetTaxOnTransfer(uint currentPrice) internal returns (DynamicTax memory currentTax) {
        if(previousDayPrice["get"].price != 0) {
            if(calculatePercentage(currentPrice, previousDayPrice["get"].price) <= 30000) {
                // this is below 30%
                startIgnitionHour();
            } else if (calculatePercentage(currentPrice, previousDayPrice["get"].price) <= 50000 
                        && calculatePercentage(currentPrice, previousDayPrice["get"].price) > 30000) {
                // this is below 50%
                startCriticalEngineHour();
            } else {
                // this is all good
                NormalEngineHours();
            }
        }

        

        // Everyday, from 21pm-23pm EST, GoldenHour activates and allows investors to sell on 10% tax
        bool isGT21 = block.timestamp % blockWindow >= STARTblock;
        bool isLT23 = block.timestamp % blockWindow <= ENDblock;
        bool isGT23 =  block.timestamp % blockWindow > ENDblock;

        if (isGT21 && isLT23) { //if between 21-23 EST
            windowStarted = true;
            startGoldenHour();
        }

        if (isGT23 && windowStarted) { // update previousClose with new price after 30% allowable dip window ends
            windowStarted = false;
            previousClose = currentPrice;
        }
        
        if (isGT23 && windowEnded) {
            windowEnded = true;
            endGoldenHour();
        }

        // reset fees
        currentTax.buyBuybackFee = _buyBuybackFee;
        currentTax.buyMarketingFee = _buyMarketingFee;
        currentTax.buyLiquidityFee = _buyLiquidityFee;
        currentTax.buyReflectionFee = _buyReflectionFee;
        currentTax.buyMultichainFee = _buyMultichainFee;

        currentTax.sellBuybackFee = _sellBuybackFee;
        currentTax.sellMarketingFee = _sellMarketingFee;
        currentTax.sellLiquidityFee = _sellLiquidityFee;
        currentTax.sellReflectionFee = _sellReflectionFee;
        currentTax.sellMultichainFee = _sellMultichainFee;

        return currentTax;
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;
        uint256 currentPrice;

        if(tradingOpen){
             currentPrice = this.getTokenPrice();
        } else {
            currentPrice = 0;
        }

        if (from != owner() && to != owner() && !presale && from != bridge && to != bridge) {
            require(tradingOpen, "Trading not open yet");
            if (from != presaleRouter && from != presaleAddress) {
                require(amount <= _maxTxAmount);
            }
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {//buys

                if (block.timestamp <= _firstBlock.add(_botBlocks) && from != presaleRouter && from != presaleAddress) {
                    bots[to] = true;
                }
                
                uint256 bnbAmount = this.getTokenPriceBNB(amount);
                
                require(bnbAmount >= _minBuyBNB, "you must buy at least min BNB worth of token");
                require(balanceOf(to).add(amount) <= _maxWalletAmount, "wallet balance after transfer must be less than max wallet amount");

                if(block.timestamp <= _taxFreeWindowEnd) { 
                    takeFee = false;
                }
                else { 
                    _hitFloor = false;
                }

                if(previousClose == 0 && tradingOpen) { // after presale ends, at launch, set previousClose to 70% of starting price
                    previousDayPrice["get"].time = block.timestamp;
                    updatePreviousDayPrice(currentPrice.mul(7).div(10));
                    updatePreviousClose(1);
                }
            }

            if (!inSwap && from != uniswapV2Pair) { //sells, transfers
                require(!bots[from] && !bots[to]);
                
                uint256 bnbAmount = this.getTokenPriceBNB(amount);
                
                require(bnbAmount >= _minSellBNB, "you must sell at least the min BNB worth of token");

                if (_BNBsellLimitEnabled) {
                    
                   require(bnbAmount <= _maxSellAmountBNB, "you cannot sell more than the max BNB amount per transaction");

                }
                
                else if (_priceImpactSellLimitEnabled) {
                    
                    require(amount <= balanceOf(uniswapV2Pair).mul(_priceImpact).div(100)); // price impact limit

                }
                
                if(to != uniswapV2Pair) {
                    
                    require(balanceOf(to).add(amount) <= _maxWalletAmount, "wallet balance after transfer must be less than max wallet amount");

                }
 
                if(previousClose == 0 && tradingOpen) { // after presale ends, at launch, set previousClose to 70% of starting price
                    previousDayPrice["get"].time = block.timestamp;
                    updatePreviousDayPrice(currentPrice.mul(7).div(10));
                    updatePreviousClose(1);
                }
                
                uint256 contractTokenBalance = balanceOf(address(this));
        
                if(contractTokenBalance >= _maxTxAmount)
                {
                    contractTokenBalance = _maxTxAmount;
                }
                
                bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
                if (overMinTokenBalance && !inSwap && from != uniswapV2Pair) {
                    contractTokenBalance = numTokensSellToAddToLiquidity;
                    swapAndLiquify(contractTokenBalance);
                    //swapTokensForEth(contractTokenBalance.sub(autoLPamount));
                }
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
                    
            }
        }

        // check and set tax
        DynamicTax memory currentTax = checkAndSetTaxOnTransfer(currentPrice);

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || presale || from == bridge || to == bridge) {
            takeFee = false;
        }

        else if (bots[from] || bots[to]) {
            setBotFee();
            takeFee = true;
        }

        if (presale) {
            require(from == owner() || from == presaleRouter || from == presaleAddress, "Presale has not ended");
        }
        
        _tokenTransfer(from, to, amount, takeFee, currentTax);
        restoreAllFee();
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
              address(this),
              tokenAmount,
              0, // slippage is unavoidable
              0, // slippage is unavoidable
              owner(),
              block.timestamp
          );
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half); 
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }


    function openTrading(uint256 botBlocks) private {
        _firstBlock = block.timestamp;
        _botBlocks = botBlocks;
        tradingOpen = true;
    }

    function manualswap() external {
        require(_msgSender() == _marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _marketingAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, DynamicTax memory currentTax) private {
        if (!takeFee) {
            currentTax.buyBuybackFee = 0;
            currentTax.buyMarketingFee = 0;
            currentTax.buyLiquidityFee = 0;
            currentTax.buyReflectionFee = 0;
            currentTax.buyMultichainFee = 0;

            currentTax.sellBuybackFee = 0;
            currentTax.sellMarketingFee = 0;
            currentTax.sellLiquidityFee = 0;
            currentTax.sellReflectionFee = 0;
            currentTax.sellMultichainFee = 0;
        }
        if (sender == uniswapV2Pair){
            _transferStandardBuy(sender, recipient, amount, currentTax);
        }
        else {
            _transferStandardSell(sender, recipient, amount, currentTax);
        }
        if (!takeFee) restoreAllFee();
    }

    function _transferStandardBuy(address sender, address recipient, uint256 tAmount, DynamicTax memory currentTax) private {
        FinalFees memory buyFees;
        buyFees = _getValuesBuy(tAmount, currentTax);
        _rOwned[sender] = _rOwned[sender].sub(buyFees.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(buyFees.rTransferAmount);
        _takeBuyback(buyFees.tBuyback);
        _takeMarketing(buyFees.tMarketing);
        _reflectFee(buyFees.rReflection, buyFees.tReflection);
        _takeLiquidity(buyFees.tLiquidity);
        _takeMultichain(buyFees.tMultichain);
        emit Transfer(sender, recipient, buyFees.tTransferAmount);
    }

    receive() external payable {}

    function _transferStandardSell(address sender, address recipient, uint256 tAmount, DynamicTax memory currentTax) private {
        FinalFees memory sellFees;
        sellFees = _getValuesSell(tAmount, currentTax);
        _rOwned[sender] = _rOwned[sender].sub(sellFees.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(sellFees.rTransferAmount);
        if (recipient == _burnAddress) {
            _tOwned[recipient] = _tOwned[recipient].add(sellFees.tTransferAmount);
        }
        _takeBuyback(sellFees.tBuyback);
        _takeMarketing(sellFees.tMarketing);
        _reflectFee(sellFees.rReflection, sellFees.tReflection);
        _takeLiquidity(sellFees.tLiquidity);
        _takeMultichain(sellFees.tMultichain);
        emit Transfer(sender, recipient, sellFees.tTransferAmount);
    }

    function _reflectFee(uint256 rReflection, uint256 tReflection) private {
        _rTotal = _rTotal.sub(rReflection);
        _tFeeTotal = _tFeeTotal.add(tReflection);
    }

    function _takeBuyback(uint256 tBuyback) private {
        uint256 currentRate = _getRate();
        uint256 rBuyback = tBuyback.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rBuyback);
    }

    function _takeMarketing(uint256 tMarketing) private {
        uint256 currentRate = _getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketing);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    }
    
    function _takeMultichain(uint256 tMultichain) private  {
        uint256 currentRate = _getRate();
        uint256 rMultichain = tMultichain.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rMultichain);
    }

    // Sell GetValues
    function _getValuesSell(uint256 tAmount, DynamicTax memory currentTax) private view returns (FinalFees memory) {
        SellBreakdown memory sellFees = _getTValuesSell(tAmount, currentTax.sellBuybackFee, currentTax.sellMarketingFee, currentTax.sellReflectionFee, currentTax.sellLiquidityFee, currentTax.sellMultichainFee);
        FinalFees memory finalFees;
        uint256 currentRate = _getRate();
        (finalFees.rAmount, finalFees.rTransferAmount, finalFees.rReflection) = _getRValuesSell(tAmount, sellFees.tBuyback, sellFees.tMarketing, sellFees.tReflection, sellFees.tLiquidity, sellFees.tMultichain, currentRate);
        finalFees.tBuyback = sellFees.tBuyback;
        finalFees.tMarketing = sellFees.tMarketing;
        finalFees.tReflection = sellFees.tReflection;
        finalFees.tLiquidity = sellFees.tLiquidity;
        finalFees.tMultichain = sellFees.tMultichain;
        finalFees.tTransferAmount = sellFees.tTransferAmount;
        return (finalFees);
    }

    function _getTValuesSell(uint256 tAmount, uint256 buybackFee, uint256 marketingFee, uint256 reflectionFee, uint256 liquidityFee, uint256 multichainFee) private pure returns (SellBreakdown memory) {
        SellBreakdown memory tsellFees;
        tsellFees.tBuyback = tAmount.mul(buybackFee).div(100);
        tsellFees.tMarketing = tAmount.mul(marketingFee).div(100);
        tsellFees.tReflection = tAmount.mul(reflectionFee).div(100);
        tsellFees.tLiquidity = tAmount.mul(liquidityFee).div(100);
        tsellFees.tMultichain = tAmount.mul(multichainFee).div(100);
        tsellFees.tTransferAmount = tAmount.sub(tsellFees.tBuyback).sub(tsellFees.tMarketing);
        tsellFees.tTransferAmount -= tsellFees.tReflection;
        tsellFees.tTransferAmount -= tsellFees.tLiquidity;
        tsellFees.tTransferAmount -= tsellFees.tMultichain;
        return (tsellFees);
    }

    function _getRValuesSell(uint256 tAmount, uint256 tBuyback, uint256 tMarketing, uint256 tReflection, uint256 tLiquidity, uint256 tMultichain, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rBuyback = tBuyback.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rReflection = tReflection.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rMultichain = tMultichain.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rBuyback).sub(rMarketing).sub(rReflection);
        rTransferAmount -= rLiquidity;
        rTransferAmount -= rMultichain;
        return (rAmount, rTransferAmount, rReflection);
    }

    // Buy GetValues
    function _getValuesBuy(uint256 tAmount, DynamicTax memory currentTax) private view returns (FinalFees memory) {
        BuyBreakdown memory buyFees = _getTValuesBuy(tAmount, currentTax.buyBuybackFee, currentTax.buyMarketingFee, currentTax.buyReflectionFee, currentTax.buyLiquidityFee, currentTax.buyMultichainFee);
        FinalFees memory finalFees;
        uint256 currentRate = _getRate();
        (finalFees.rAmount, finalFees.rTransferAmount, finalFees.rReflection) = _getRValuesBuy(tAmount, buyFees.tBuyback, buyFees.tMarketing, buyFees.tReflection, buyFees.tLiquidity, buyFees.tMultichain, currentRate);
        finalFees.tBuyback = buyFees.tBuyback;
        finalFees.tMarketing = buyFees.tMarketing;
        finalFees.tReflection = buyFees.tReflection;
        finalFees.tLiquidity = buyFees.tLiquidity;
        finalFees.tMultichain = buyFees.tMultichain;
        finalFees.tTransferAmount = buyFees.tTransferAmount;
        return (finalFees);
    }

    function _getTValuesBuy(uint256 tAmount, uint256 buybackFee, uint256 marketingFee, uint256 reflectionFee, uint256 liquidityFee, uint256 multichainFee) private pure returns (BuyBreakdown memory) {
        BuyBreakdown memory tbuyFees;
        tbuyFees.tBuyback = tAmount.mul(buybackFee).div(100);
        tbuyFees.tMarketing = tAmount.mul(marketingFee).div(100);
        tbuyFees.tReflection = tAmount.mul(reflectionFee).div(100);
        tbuyFees.tLiquidity = tAmount.mul(liquidityFee).div(100);
        tbuyFees.tMultichain = tAmount.mul(multichainFee).div(100);
        tbuyFees.tTransferAmount = tAmount.sub(tbuyFees.tBuyback).sub(tbuyFees.tMarketing);
        tbuyFees.tTransferAmount -= tbuyFees.tReflection;
        tbuyFees.tTransferAmount -= tbuyFees.tLiquidity;
        tbuyFees.tTransferAmount -= tbuyFees.tMultichain;
        return (tbuyFees);
    }

    function _getRValuesBuy(uint256 tAmount, uint256 tBuyback, uint256 tMarketing, uint256 tReflection, uint256 tLiquidity, uint256 tMultichain, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rBuyback = tBuyback.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rReflection = tReflection.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rMultichain = tMultichain.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rBuyback).sub(rMarketing).sub(rReflection);
        rTransferAmount -= rLiquidity;
        rTransferAmount -= rMultichain;
        return (rAmount, rTransferAmount, rReflection);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (_rOwned[_burnAddress] > rSupply || _tOwned[_burnAddress] > tSupply) return (_rTotal, _tTotal);
        rSupply = rSupply.sub(_rOwned[_burnAddress]);
        tSupply = tSupply.sub(_tOwned[_burnAddress]);
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function excludeFromFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = false;
    }

    function removeBot(address account) external onlyOwner() {
        bots[account] = false;
    }

    function addBot(address account) external onlyOwner() {
        bots[account] = true;
    }
    
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        require(maxTxAmount > _tTotal.div(10000), "Amount must be greater than 0.01% of supply");
        require(maxTxAmount <= _tTotal, "Amount must be less than or equal to totalSupply");
        _maxTxAmount = maxTxAmount;
        emit MaxTxAmountUpdated(_maxTxAmount);
    }

    function setMaxWalletAmount(uint256 maxWalletAmount) external onlyOwner() {
        require(maxWalletAmount > _tTotal.div(200), "Amount must be greater than 0.5% of supply");
        require(maxWalletAmount <= _tTotal, "Amount must be less than or equal to totalSupply");
        _maxWalletAmount = maxWalletAmount;
    }
    
    function setPercents(uint256 marketingPercent, uint256 buybackPercent, uint256 multichainPercent) external onlyOwner() {
        require(marketingPercent.add(buybackPercent).add(multichainPercent) == 95, "Sum of percents must equal 95");
        _marketingPercent = marketingPercent;
        _buybackPercent = buybackPercent;
        _multichainPercent = multichainPercent;
        emit PercentsUpdated(_marketingPercent, _buybackPercent, _multichainPercent);
    }

    function setTaxes(uint256 buyMarketingFee, uint256 buyBuybackFee, uint256 buyReflectionFee, uint256 buyLiquidityFee, uint256 buyMultichainFee, uint256 sellMarketingFee, uint256 sellBuybackFee, uint256 sellReflectionFee, uint256 sellLiquidityFee, uint256 sellMultichainFee) external onlyOwner() {
        uint256 buyTax = buyMarketingFee.add(buyBuybackFee).add(buyReflectionFee);
        buyTax += buyLiquidityFee.add(buyMultichainFee);
        uint256 sellTax = sellMarketingFee.add(sellBuybackFee).add(sellReflectionFee);
        sellTax += sellLiquidityFee.add(sellMultichainFee);
        require(buyTax < 50, "Sum of sell fees must be less than 50");
        require(sellTax < 50, "Sum of buy fees must be less than 50");
        _buyMarketingFee = buyMarketingFee;
        _buyBuybackFee = buyBuybackFee;
        _buyReflectionFee = buyReflectionFee;
        _buyLiquidityFee = buyLiquidityFee;
        _buyMultichainFee = buyMultichainFee;
        _sellMarketingFee = sellMarketingFee;
        _sellBuybackFee = sellBuybackFee;
        _sellReflectionFee = sellReflectionFee;
        _sellLiquidityFee = sellLiquidityFee;
        _sellMultichainFee = sellMultichainFee;
        
        _previousBuyMarketingFee = _buyMarketingFee;
        _previousBuyBuybackFee = _buyBuybackFee;
        _previousBuyReflectionFee = _buyReflectionFee;
        _previousBuyLiquidityFee = _buyLiquidityFee;
        _previousBuyMultichainFee = _buyMultichainFee;
        _previousSellMarketingFee = _sellMarketingFee;
        _previousSellBuybackFee = _sellBuybackFee;
        _previousSellReflectionFee = _sellReflectionFee;
        _previousSellLiquidityFee = _sellLiquidityFee;
        _previousSellMultichainFee = _sellMultichainFee;
        
        emit FeesUpdated(_buyBuybackFee, _buyMarketingFee, _buyLiquidityFee, _buyReflectionFee, _buyMultichainFee, _sellBuybackFee, _sellMarketingFee, _sellLiquidityFee, _sellReflectionFee, _sellMultichainFee);
    }

    function setPriceImpact(uint256 priceImpact) external onlyOwner() {
        require(priceImpact <= 100, "max price impact must be less than or equal to 100");
        require(priceImpact > 0, "cant prevent sells, choose value greater than 0");
        _priceImpact = priceImpact;
        emit PriceImpactUpdated(_priceImpact);
    }

    function setPresaleRouterAndAddress(address router, address wallet) external onlyOwner() {
        presaleRouter = router;
        presaleAddress = wallet;
        excludeFromFee(presaleRouter);
        excludeFromFee(presaleAddress);
    }

    function endPresale(uint256 botBlocks) external onlyOwner() {
        require(presale == true, "presale already ended");
        presale = false;
        openTrading(botBlocks);
        emit EndedPresale(presale);
    }

    function updatePairSwapped(bool swapped) external onlyOwner() {
        pairSwapped = swapped;
    }
    
    function updateMinBuySellBNB(uint256 minBuyBNB, uint256 minSellBNB) external onlyOwner() {
        _minBuyBNB = minBuyBNB;
        _minSellBNB = minSellBNB;
    }
    
    function updateMaxSellAmountBNB(uint256 maxSellBNB) external onlyOwner() {
        _maxSellAmountBNB = maxSellBNB;
    }
    
    function updateBuyBackAddress(address payable buybackAddress) external onlyOwner() {
        _buybackAddress = buybackAddress;
    }
    
    function updateMarketingAddress(address payable marketingAddress) external onlyOwner() {
        _marketingAddress = marketingAddress;
    }
    
    function updatemultichainAddress(address payable multichainAddress) external onlyOwner() {
        _multichainAddress = multichainAddress;
    }

    function enableBNBsellLimit() external onlyOwner() {
        require(_BNBsellLimitEnabled == false, "already enabled");
        _BNBsellLimitEnabled = true;
        _priceImpactSellLimitEnabled = false;
    }

    // set time at 00:00 utc for next day trade
    function setEndOfDay() external {
        require(block.timestamp % blockWindow >= timeRunEndOfDay && block.timestamp % blockWindow <= timeRunEndOfDay + 600, "Not time to do that yet"); // should happen in a 6 minute window
        previousDayPrice["get"].time = block.timestamp;
        previousDayPrice["get"].price = this.getTokenPrice();
    }

    function getPreviousDayData() view public onlyOwner returns(uint) {
        return previousDayPrice["get"].price;
    }

    function disableBNBsellLimit() external onlyOwner() {
        require(_BNBsellLimitEnabled == true, "already disabled");
        _BNBsellLimitEnabled = false;
    }

    function enablePriceImpactSellLimit() external onlyOwner() {
        require(_priceImpactSellLimitEnabled == false, "already enabled");
        _priceImpactSellLimitEnabled = true;
        _BNBsellLimitEnabled = false;
    }
    
    function disablePriceImpactSellLimit() external onlyOwner() {
        require(_priceImpactSellLimitEnabled == true, "already disabled");
        _priceImpactSellLimitEnabled = false;
    }

    function startIgnitionHour() internal {
        _buyMarketingFee = 5;
        _buyBuybackFee = 3;
        _buyReflectionFee = 1;
        _buyLiquidityFee = 2;
        _buyMultichainFee = 3;

        _sellMarketingFee = 6;
        _sellBuybackFee = 6;
        _sellReflectionFee = 3;
        _sellLiquidityFee = 3;
        _sellMultichainFee = 6;

    emit FeesUpdated(_buyBuybackFee, _buyMarketingFee, _buyLiquidityFee, _buyReflectionFee, _buyMultichainFee, _sellBuybackFee, _sellMarketingFee, _sellLiquidityFee, _sellReflectionFee, _sellMultichainFee);

    }

    function endGoldenHour() internal {
        _buyMarketingFee = 5;
        _buyBuybackFee = 3;
        _buyReflectionFee = 1;
        _buyLiquidityFee = 2;
        _buyMultichainFee = 3;

        _sellMarketingFee = 5;
        _sellBuybackFee = 4;
        _sellReflectionFee = 2;
        _sellLiquidityFee = 3;
        _sellMultichainFee = 4;

    emit FeesUpdated(_buyBuybackFee, _buyMarketingFee, _buyLiquidityFee, _buyReflectionFee, _buyMultichainFee, _sellBuybackFee, _sellMarketingFee, _sellLiquidityFee, _sellReflectionFee, _sellMultichainFee);

    }

function startCriticalEngineHour() internal {
        _buyMarketingFee = 0;
        _buyBuybackFee = 0;
        _buyReflectionFee = 0;
        _buyLiquidityFee = 0;
        _buyMultichainFee = 0;

        _sellMarketingFee = 15;
        _sellBuybackFee = 15;
        _sellReflectionFee = 3;
        _sellLiquidityFee = 3;
        _sellMultichainFee = 11;

    emit FeesUpdated(_buyBuybackFee, _buyMarketingFee, _buyLiquidityFee, _buyReflectionFee, _buyMultichainFee, _sellBuybackFee, _sellMarketingFee, _sellLiquidityFee, _sellReflectionFee, _sellMultichainFee);

    }
function NormalEngineHours() internal {
        _buyMarketingFee = 5;
        _buyBuybackFee = 3;
        _buyReflectionFee = 1;
        _buyLiquidityFee = 2;
        _buyMultichainFee = 3;

        _sellMarketingFee = 5;
        _sellBuybackFee = 4;
        _sellReflectionFee = 2;
        _sellLiquidityFee = 3;
        _sellMultichainFee = 4;

    emit FeesUpdated(_buyBuybackFee, _buyMarketingFee, _buyLiquidityFee, _buyReflectionFee, _buyMultichainFee, _sellBuybackFee, _sellMarketingFee, _sellLiquidityFee, _sellReflectionFee, _sellMultichainFee);

    }

    function startGoldenHour() internal {
        _buyMarketingFee = 3;
        _buyBuybackFee = 2;
        _buyReflectionFee = 1;
        _buyLiquidityFee = 2;
        _buyMultichainFee = 2;

        _sellMarketingFee = 4;
        _sellBuybackFee = 2;
        _sellReflectionFee = 1;
        _sellLiquidityFee = 1;
        _sellMultichainFee = 2;

    emit FeesUpdated(_buyBuybackFee, _buyMarketingFee, _buyLiquidityFee, _buyReflectionFee, _buyMultichainFee, _sellBuybackFee, _sellMarketingFee, _sellLiquidityFee, _sellReflectionFee, _sellMultichainFee);

    }

    function updateFee() private view returns(DynamicTax memory) {
        
        DynamicTax memory currentTax;
        
        currentTax.buyBuybackFee = _buyBuybackFee;
        currentTax.buyMarketingFee = _buyMarketingFee;
        currentTax.buyLiquidityFee = _buyLiquidityFee;
        currentTax.buyReflectionFee = _buyReflectionFee;
        currentTax.buyMultichainFee = _buyMultichainFee;
        
        currentTax.sellBuybackFee = _sellBuybackFee;
        currentTax.sellMarketingFee = _sellMarketingFee;
        currentTax.sellLiquidityFee = _sellLiquidityFee;
        currentTax.sellReflectionFee = _sellReflectionFee;
        currentTax.sellMultichainFee = _sellMultichainFee;
    return currentTax;    
    }

    function sendETHToFee(uint256 amount) private {
        _marketingAddress.transfer(amount.mul(_marketingPercent).div(100));
        _buybackAddress.transfer(amount.mul(_buybackPercent).div(100));
        _multichainAddress.transfer(amount.mul(_multichainPercent).div(100));
        _rocketMaintenance.transfer(amount.mul(_rocketMaintenancePercent).div(100));
    }

    function updateTaxFreeBlocks(uint256 taxFreeBlocks) external onlyOwner() {
        _taxFreeBlocks = taxFreeBlocks;
    }

    function initializePriceandClose(uint256 price) private {
        previousPrice = price;
        previousClose = price;
    }

    function disableRandomizedFloor() external onlyOwner() {
        require(randomizeFloor ==  true, "randomizeFloor already disabled");
        randomizeFloor = false;
    }

    function enableRandomizedFloor() external onlyOwner() {
        require(randomizeFloor == false, "randomizeFloor already enabled");
        randomizeFloor = true;
    }

    function setFloor() external onlyOwner() {
        require(randomizeFloor == true, "must enable randomizeFloor");
        uint256 price =  this.getTokenPrice();
        previousClose = price;
    }

    function setBlockWindow(uint256 _startblock, uint256 _endblock, uint256 _blockwindow) external onlyOwner() {
        require(_startblock <= _blockwindow && _endblock <= _blockwindow, "startblock and endblock must be within the window");
        STARTblock = _startblock;
        ENDblock = _endblock;
        blockWindow = _blockwindow;
        emit UpdatedHighLowWindows(STARTblock, ENDblock, blockWindow);
    }

    function setAllowableDip(uint256 _dipPercent) external onlyOwner() {
        require(_dipPercent <= 95, "percent must be less than or equal to 95");
        DipPercent = _dipPercent;
        emit UpdatedAllowableDip(DipPercent);
    }

    function setGoldenHourDay(uint256 GoldenHourDay) external onlyOwner() {
        _goldenhourDay = GoldenHourDay;
        emit GoldenHourDayUpdated(_goldenhourDay);
    }

    function updateOraclePriceFeed(address feed) external onlyOwner() {
        _oraclePriceFeed = feed;
    }

    function enablePriceOracle() external onlyOwner() {
        require(priceOracleEnabled == false, "price oracle already enabled");
        priceOracleEnabled = true;
    }

    function disablePriceOracle() external onlyOwner() {
        require(priceOracleEnabled == true, "price oracle already disabled");
        priceOracleEnabled = false;
    }

    function setCriticalFees(uint256 criticalMarketingFee, uint256 criticalBuybackFee, uint256 criticalReflectionFee, uint256 criticalLiquidityFee, uint256 criticalMultichainFee) external onlyOwner() {
        require(criticalMarketingFee.add(criticalBuybackFee).add(criticalReflectionFee).add(criticalLiquidityFee).add(criticalMultichainFee) < 50, "sum of fees must be less than 50");
        _criticalMarketingFee = criticalMarketingFee;
        _criticalBuybackFee = criticalBuybackFee;
        _criticalReflectionFee = criticalReflectionFee;
        _criticalLiquidityFee = criticalLiquidityFee;
        _criticalMultichainFee = criticalMultichainFee;
    }

    function setIgnitionFees(uint256 ignitionMarketingFee, uint256 ignitionBuybackFee, uint256 ignitionReflectionFee, uint256 ignitionLiquidityFee, uint256 ignitionMultichainFee) external onlyOwner() {
        require(ignitionMarketingFee.add(ignitionBuybackFee).add(ignitionReflectionFee).add(ignitionLiquidityFee).add(ignitionMultichainFee) < 50, "sum of fees must be less than 50");
        _ignitionMarketingFee = ignitionMarketingFee;
        _ignitionBuybackFee = ignitionBuybackFee;
        _ignitionReflectionFee = ignitionReflectionFee;
        _ignitionLiquidityFee = ignitionLiquidityFee;
        _ignitionMultichainFee = ignitionMultichainFee;
    }

    function setGoldenhourFees(uint256 goldenhourMarketingFee, uint256 goldenhourBuybackFee, uint256 goldenhourReflectionFee, uint256 goldenhourLiquidityFee, uint256 goldenhourMultichainFee) external onlyOwner() {
        require(goldenhourMarketingFee.add(goldenhourBuybackFee).add(goldenhourReflectionFee).add(goldenhourLiquidityFee).add(goldenhourMultichainFee) < 50, "sum of fees must be less than 50");
        _goldenhourMarketingFee = goldenhourMarketingFee;
        _goldenhourBuybackFee = goldenhourBuybackFee;
        _goldenhourReflectionFee = goldenhourReflectionFee;
        _goldenhourLiquidityFee = goldenhourLiquidityFee;
        _goldenhourMultichainFee = goldenhourMultichainFee;
    }

    function startNormalEngineHours() external onlyOwner {
        _buyMarketingFee = 5;
        _buyBuybackFee = 3;
        _buyReflectionFee = 1;
        _buyLiquidityFee = 2;
        _buyMultichainFee = 3;

        _sellMarketingFee = 5;
        _sellBuybackFee = 4;
        _sellReflectionFee = 2;
        _sellLiquidityFee = 3;
        _sellMultichainFee = 4;

    emit FeesUpdated(_buyBuybackFee, _buyMarketingFee, _buyLiquidityFee, _buyReflectionFee, _buyMultichainFee, _sellBuybackFee, _sellMarketingFee, _sellLiquidityFee, _sellReflectionFee, _sellMultichainFee);

    }

    function beginCriticalEngineHour() external onlyOwner {
        _buyMarketingFee = 0;
        _buyBuybackFee = 0;
        _buyReflectionFee = 0;
        _buyLiquidityFee = 0;
        _buyMultichainFee = 0;

        _sellMarketingFee = 15;
        _sellBuybackFee = 15;
        _sellReflectionFee = 3;
        _sellLiquidityFee = 3;
        _sellMultichainFee = 11;

    emit FeesUpdated(_buyBuybackFee, _buyMarketingFee, _buyLiquidityFee, _buyReflectionFee, _buyMultichainFee, _sellBuybackFee, _sellMarketingFee, _sellLiquidityFee, _sellReflectionFee, _sellMultichainFee);

    }

    function beginGoldenHours() external onlyOwner {
        _buyMarketingFee = 3;
        _buyBuybackFee = 2;
        _buyReflectionFee = 1;
        _buyLiquidityFee = 2;
        _buyMultichainFee = 2;

        _sellMarketingFee = 4;
        _sellBuybackFee = 2;
        _sellReflectionFee = 1;
        _sellLiquidityFee = 1;
        _sellMultichainFee = 2;

    emit FeesUpdated(_buyBuybackFee, _buyMarketingFee, _buyLiquidityFee, _buyReflectionFee, _buyMultichainFee, _sellBuybackFee, _sellMarketingFee, _sellLiquidityFee, _sellReflectionFee, _sellMultichainFee);

    }

    function setRouterAddress(address newRouter) external onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
    }

    function beginIgnitionHours() external onlyOwner {
        _buyMarketingFee = 5;
        _buyBuybackFee = 3;
        _buyReflectionFee = 1;
        _buyLiquidityFee = 2;
        _buyMultichainFee = 3;

        _sellMarketingFee = 6;
        _sellBuybackFee = 6;
        _sellReflectionFee = 3;
        _sellLiquidityFee = 3;
        _sellMultichainFee = 6;

    emit FeesUpdated(_buyBuybackFee, _buyMarketingFee, _buyLiquidityFee, _buyReflectionFee, _buyMultichainFee, _sellBuybackFee, _sellMarketingFee, _sellLiquidityFee, _sellReflectionFee, _sellMultichainFee);

    }
}