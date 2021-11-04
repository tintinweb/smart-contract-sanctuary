/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

/*
         
                                                           ╚╝╚╝╚╝
                                                           ╚╝╚╝╚╝
                                                                      ╚╝╚╝╚╝╚╝╚╝╚╝╚╝
                                                           ╚╝╚╝╚╝     ╚╝╚╝       ╚╝╚╝
         ╚╝  ╚╝ ╚╝      ╚╝ ╚╝ ╚╝ ╚╝       ╚╝        ╚╝     ╚╝  ╚╝     ╚╝╚╝        ╚╝╚╝
         ╚╝             ╚╝        ╚╝      ╚╝        ╚╝     ╚╝  ╚╝     ╚╝╚╝        ╚╝╚╝
         ╚╝ ╚╝  ╚╝      ╚╝     ╚╝ ╚╝      ╚╝        ╚╝     ╚╝  ╚╝     ╚╝╚╝       ╚╝╚╝
                ╚╝      ╚╝      ╚╝╚╝      ╚╝        ╚╝     ╚╝  ╚╝     ╚╝╚╝      ╚╝╚╝
         ╚╝ ╚╝  ╚╝        ╚╝ ╚╝ ╚╝╚╝        ╚╝ ╚╝ ╚╝       ╚╝╚╝╚╝     ╚╝╚╝╚╝╚╝╚╝╚╝
                                   ╚╝
                                    ╚╝
         

Buy tax: 14%
5% Buyback
2.5% Marketing
3% LP
2% Reflections
1% Development team
0.5% Project Maintenance

Sell Tax: 17%
6.5% Buyback
3% Marketing
4% LP
2% Reflections
1% Development team
0.5% Project Maintenance

☀️Golden Hour & Below Floor Taxes

Hour 1 (& below floor): 40%
20.5% Buyback
7% marketing
5% LP
4% Reflections
3% Development team
0.5% Project Maintenance

Hour 2: 24%
12.5% Buyback
5% Marketing
3% LP
2% Reflections
1% Development team
0.5% Project Maintenance


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

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

abstract contract IERC20Extented is IERC20 {
    function decimals() external view virtual returns (uint8);
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
}

contract SurfZilla is Context, IERC20, IERC20Extented, Ownable {
    using SafeMath for uint256;
    string private constant _name = "Surf Zilla";
    string private constant _symbol = "SurfZilla";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private sellcooldown;
    mapping(address => uint256) private _sellTotal;
    mapping(address => uint256) private _firstSell;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isContractWallet; // exclude contract wallets maxWalletAmount
    mapping(address => bool) private _isExchange; // used for whitelisting exchange hot wallets
    mapping(address => bool) private _isBridge; //used for whitelisting bridges
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public _priceImpact = 2;
    uint256 private previousClose;
    uint256 private _firstBlock;
    uint256 private _botBlocks;
    uint256 public _maxWalletAmount;
    uint256 private _maxSellAmountBNB = 20000000000000000000; // 20 BNB
    uint256 private _minBuyBNB = 10000000000000000; // 0.01 BNB
    uint256 private _minSellBNB = 10000000000000000; // 0.01 BNB
    uint256 private _taxFreeBlocks = 3600; // 1 hour
    uint256 private _cooldownBlocks = 3600; // 1 hour
    uint256 private _taxFreeWindowEnd; // block.timestamp + _taxFreeBlocks
    uint256 public _goldenHourStartBlock = 0;
    bool public _goldenHourStarted = false;
    uint256 private _slideEndBlock = 0;
    bool public _recovered = true;
    uint256 private _threshold = 10;
    uint256 private _floorPercent;
    uint256 private _ath = 0;
    
    uint256 public _floorBuybackFee = 21;
    uint256 public _floorMarketingFee = 7;
    uint256 public _floorLiquidityFee = 5;
    uint256 public _floorReflectionFee = 4;
    uint256 public _floorDevFee = 3;

    uint256 public _slideBuybackFee = 13;
    uint256 public _slideMarketingFee = 5;
    uint256 public _slideLiquidityFee = 3;
    uint256 public _slideReflectionFee = 2;
    uint256 public _slideDevFee = 1;

    //  buy fees
    uint256 public _buyBuybackFee = 5;
    uint256 private _previousBuyBuybackFee = _buyBuybackFee;
    uint256 public _buyMarketingFee = 3;
    uint256 private _previousBuyMarketingFee = _buyMarketingFee;
    uint256 public _buyReflectionFee = 2;
    uint256 private _previousBuyReflectionFee = _buyReflectionFee;
    uint256 public _buyLiquidityFee = 3;
    uint256 private _previousBuyLiquidityFee = _buyLiquidityFee;
    uint256 public _buyDevFee = 1;
    uint256 private _previousBuyDevFee = _buyDevFee;
    
    // sell fees
    uint256 public _sellBuybackFee = 7;
    uint256 private _previousSellBuybackFee = _sellBuybackFee;
    uint256 public _sellMarketingFee = 3;
    uint256 private _previousSellMarketingFee = _sellMarketingFee;
    uint256 public _sellReflectionFee = 2;
    uint256 private _previousSellReflectionFee = _sellReflectionFee;
    uint256 public _sellLiquidityFee = 4;
    uint256 private _previousSellLiquidityFee = _sellLiquidityFee;
    uint256 public _sellDevFee = 1;
    uint256 private _previousSellDevFee = _sellDevFee;
  
    struct DynamicTax {
        uint256 buyBuybackFee;
        uint256 buyMarketingFee;
        uint256 buyReflectionFee;
        uint256 buyLiquidityFee;
        uint256 buyDevFee;
        
        uint256 sellBuybackFee;
        uint256 sellMarketingFee;
        uint256 sellReflectionFee;
        uint256 sellLiquidityFee;
        uint256 sellDevFee;
    }
    
    uint256 constant private _projectMaintainencePercent = 5;
    uint256 private _devPercent = 10;
    uint256 private _marketingPercent = 25;
    uint256 private _buybackPercent = 60;

    struct BuyBreakdown {
        uint256 tTransferAmount;
        uint256 tBuyback;
        uint256 tMarketing;
        uint256 tReflection;
        uint256 tLiquidity;
        uint256 tDev;
    }

    struct SellBreakdown {
        uint256 tTransferAmount;
        uint256 tBuyback;
        uint256 tMarketing;
        uint256 tReflection;
        uint256 tLiquidity;
        uint256 tDev;
    }
    
    struct FinalFees {
        uint256 tTransferAmount;
        uint256 tBuyback;
        uint256 tMarketing;
        uint256 tReflection;
        uint256 tLiquidity;
        uint256 tDev;
        uint256 rReflection;
        uint256 rTransferAmount;
        uint256 rAmount;
    }

    mapping(address => bool) private bots;
    address payable private _marketingAddress = payable(0x29906c39c5362Ebc11cEA946009a89Bfa0bAef43);
    address payable private _buybackAddress = payable(0x29906c39c5362Ebc11cEA946009a89Bfa0bAef43);
    address payable constant private _projectMaintainence = payable(0x29906c39c5362Ebc11cEA946009a89Bfa0bAef43);
    address payable private _developmentAddress = payable(0x5B4C23a2d613D18aE221AEc81073eFE366536ad2);
    address payable constant private _burnAddress = payable(0x000000000000000000000000000000000000dEaD);
    address private presaleRouter;
    address private presaleAddress;
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    uint256 private _maxTxAmount;

    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private presale = true;
    bool private pairSwapped = false;
    bool private _sellCoolDownEnabled = true;
    bool private _dailyMaxEnabled = true;

    event EndedPresale(bool presale);
    event UpdatedAllowableDip(uint256 hundredMinusDipPercent);
    event UpdatedHighLowWindows(uint256 GTblock, uint256 LTblock, uint256 blockWindow);
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event SellOnlyUpdated(bool sellOnly);
    event PercentsUpdated(uint256 _marketingPercent, uint256 _buybackPercent, uint256 _devPercent);
    event FeesUpdated(uint256 _buyBuybackFee, uint256 _buyMarketingFee, uint256 _buyLiquidityFee, uint256 _buyReflectionFee, uint256 _buyDevFee, uint256 _sellBuyBackFee, uint256 _sellMarketingFee, uint256 _sellLiquidityFee, uint256 _sellReflectionFee, uint256 _sellDevFee);
    event PriceImpactUpdated(uint256 _priceImpact);

    AggregatorV3Interface internal priceFeed;
    address public _oraclePriceFeed = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;//rinkeby 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;// bnb testnet 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;// bnb pricefeed 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    bool private priceOracleEnabled = true;
    int private manualETHvalue = 4200 * 10**8;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);//ropstenn 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //bsc test 0xD99D1c33F9fC3444f8101754aBC46c52416550D1);//bsc main net 0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);

        priceFeed = AggregatorV3Interface(_oraclePriceFeed);

        previousClose = 0;

        _maxTxAmount = _tTotal; // start off transaction limit at 100% of total supply
        _maxWalletAmount = _tTotal.div(1); // 100%

        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[_buybackAddress] = true;
        _isContractWallet[_buybackAddress] = true;
        _isContractWallet[_marketingAddress] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if (_buyMarketingFee == 0 && _buyBuybackFee == 0 && _buyReflectionFee == 0 && _buyLiquidityFee == 0 && _buyDevFee == 0 && _sellMarketingFee == 0 && _sellBuybackFee == 0 && _sellReflectionFee == 0 && _sellLiquidityFee == 0 && _sellDevFee == 0) return;
        _previousBuyMarketingFee = _buyMarketingFee;
        _previousBuyBuybackFee = _buyBuybackFee;
        _previousBuyReflectionFee = _buyReflectionFee;
        _previousBuyLiquidityFee = _buyLiquidityFee;
        _previousBuyDevFee = _buyDevFee;

        _previousSellMarketingFee = _sellMarketingFee;
        _previousSellBuybackFee = _sellBuybackFee;
        _previousSellReflectionFee = _sellReflectionFee;
        _previousSellLiquidityFee = _sellLiquidityFee;
        _previousSellDevFee = _sellDevFee;

        _buyMarketingFee = 0;
        _buyBuybackFee = 0;
        _buyReflectionFee = 0;
        _buyLiquidityFee = 0;
        _buyDevFee = 0;

        _sellMarketingFee = 0;
        _sellBuybackFee = 0;
        _sellReflectionFee = 0;
        _sellLiquidityFee = 0;
        _sellDevFee = 0;
    }

    function setBotFee() private {
        _previousBuyMarketingFee = _buyMarketingFee;
        _previousBuyBuybackFee = _buyBuybackFee;
        _previousBuyReflectionFee = _buyReflectionFee;
        _previousBuyDevFee = _buyDevFee;

        _previousSellMarketingFee = _sellMarketingFee;
        _previousSellBuybackFee = _sellBuybackFee;
        _previousSellReflectionFee = _sellReflectionFee;
        _previousSellDevFee = _sellDevFee;

        _buyMarketingFee = 45;
        _buyBuybackFee = 45;
        _buyReflectionFee = 0;
        _buyDevFee = 0;

        _sellMarketingFee = 45;
        _sellBuybackFee = 45;
        _sellReflectionFee = 0;
        _sellDevFee = 0;
    }
    
    function restoreAllFee() private {
        _buyMarketingFee = _previousBuyMarketingFee;
        _buyBuybackFee = _previousBuyBuybackFee;
        _buyReflectionFee = _previousBuyReflectionFee;
        _buyLiquidityFee = _previousBuyLiquidityFee;
        _buyDevFee = _previousBuyDevFee;

        _sellMarketingFee = _previousSellMarketingFee;
        _sellBuybackFee = _previousSellBuybackFee;
        _sellReflectionFee = _previousSellReflectionFee;
        _sellLiquidityFee = _previousSellLiquidityFee;
        _sellDevFee = _previousSellDevFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * Returns the latest price
     */
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

    // calculate price based on pair reserves
    function getTokenPrice() external view returns(uint256) {
        IERC20Extented token0 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token0());//dogex
        IERC20Extented token1 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token1());//bnb
        (uint112 Res0, uint112 Res1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        if(pairSwapped) {
            token0 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token1());//dogex
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

    // calculate price based on pair reserves
    function getTokenPriceBNB(uint256 amount) external view returns(uint256) {
        IERC20Extented token0 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token0());//dogex
        IERC20Extented token1 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token1());//bnb
        (uint112 Res0, uint112 Res1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        if(pairSwapped) {
            token0 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token1());//dogex
            token1 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token0());//bnb
            (Res1, Res0,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        }

        uint res1 = Res1*(10**token0.decimals());
        return((amount*res1)/(Res0*(10**token0.decimals()))); // return amount of token1 needed to buy token0
    }
    
    function updateFee() private returns(DynamicTax memory) {
        
        DynamicTax memory currentTax;
        
        currentTax.buyBuybackFee = _buyBuybackFee;
        currentTax.buyMarketingFee = _buyMarketingFee;
        currentTax.buyLiquidityFee = _buyLiquidityFee;
        currentTax.buyReflectionFee = _buyReflectionFee;
        currentTax.buyDevFee = _buyDevFee;
        
        currentTax.sellBuybackFee = _sellBuybackFee;
        currentTax.sellMarketingFee = _sellMarketingFee;
        currentTax.sellLiquidityFee = _sellLiquidityFee;
        currentTax.sellReflectionFee = _sellReflectionFee;
        currentTax.sellDevFee = _sellDevFee;
        
        uint256 currentPrice = this.getTokenPrice();

        if(block.timestamp >= _goldenHourStartBlock && block.timestamp <= _taxFreeWindowEnd) {
            currentTax.buyBuybackFee = 0;
            currentTax.buyMarketingFee = 0;
            currentTax.buyLiquidityFee = 0;
            currentTax.buyReflectionFee = 0;
            currentTax.buyDevFee = 0;
            
            currentTax.sellBuybackFee = _floorBuybackFee;
            currentTax.sellMarketingFee = _floorMarketingFee;
            currentTax.sellLiquidityFee = _floorLiquidityFee;
            currentTax.sellReflectionFee = _floorReflectionFee;
            currentTax.sellDevFee = _floorDevFee;
        }
        else if (block.timestamp > _taxFreeWindowEnd && block.timestamp <= _slideEndBlock) {
            currentTax.buyBuybackFee = _buyBuybackFee;
            currentTax.buyMarketingFee = _buyMarketingFee;
            currentTax.buyLiquidityFee = _buyLiquidityFee;
            currentTax.buyReflectionFee = _buyReflectionFee;
            currentTax.buyDevFee = _buyDevFee;
            
            currentTax.sellBuybackFee = _slideBuybackFee;
            currentTax.sellMarketingFee = _slideMarketingFee;
            currentTax.sellLiquidityFee = _slideLiquidityFee;
            currentTax.sellReflectionFee = _slideReflectionFee;
            currentTax.sellDevFee = _slideDevFee;
        }
        if (block.timestamp > _taxFreeWindowEnd && _goldenHourStarted) {
            _goldenHourStarted = false;
        }
        if (currentPrice > previousClose.mul(uint256(100).add(_threshold)).div(100) && !_recovered && !_goldenHourStarted) {
            _recovered = true;
        }
        if (currentPrice <= previousClose) {
            currentTax.buyBuybackFee = _buyBuybackFee;
            currentTax.buyMarketingFee = _buyMarketingFee;
            currentTax.buyLiquidityFee = _buyLiquidityFee;
            currentTax.buyReflectionFee = _buyReflectionFee;
            currentTax.buyDevFee = _buyDevFee;
        
            currentTax.sellBuybackFee = _floorBuybackFee;
            currentTax.sellMarketingFee = _floorMarketingFee;
            currentTax.sellLiquidityFee = _floorLiquidityFee;
            currentTax.sellReflectionFee = _floorReflectionFee;
            currentTax.sellDevFee = _floorDevFee;
            
            if(block.timestamp >= _goldenHourStartBlock && block.timestamp <= _taxFreeWindowEnd) {
                currentTax.buyBuybackFee = 0;
                currentTax.buyMarketingFee = 0;
                currentTax.buyLiquidityFee = 0;
                currentTax.buyReflectionFee = 0;
                currentTax.buyDevFee = 0;
                
                currentTax.sellBuybackFee = _floorBuybackFee;
                currentTax.sellMarketingFee = _floorMarketingFee;
                currentTax.sellLiquidityFee = _floorLiquidityFee;
                currentTax.sellReflectionFee = _floorReflectionFee;
                currentTax.sellDevFee = _floorDevFee;
            }
            if(!_goldenHourStarted && _recovered) {
                startGoldenHour();
                currentTax.buyBuybackFee = 0;
                currentTax.buyMarketingFee = 0;
                currentTax.buyLiquidityFee = 0;
                currentTax.buyReflectionFee = 0;
                currentTax.buyDevFee = 0;
                
                currentTax.sellBuybackFee = _floorBuybackFee;
                currentTax.sellMarketingFee = _floorMarketingFee;
                currentTax.sellLiquidityFee = _floorLiquidityFee;
                currentTax.sellReflectionFee = _floorReflectionFee;
                currentTax.sellDevFee = _floorDevFee;
                _recovered = false;
            }
        }
        if (currentPrice > _ath) {
            _ath = currentPrice;
        }
        
        return currentTax;
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;
        
        DynamicTax memory currentTax;

        if (from != owner() && to != owner() && !presale && !_isContractWallet[from] && !_isContractWallet[to] && from != address(this) && to != address(this)) {
            require(tradingOpen);
            if (from != presaleRouter && from != presaleAddress) {
                require(amount <= _maxTxAmount);
            }
            if ((from == uniswapV2Pair || _isExchange[from]) && to != address(uniswapV2Router) && !_isExchange[to]) {//buys
                if (block.timestamp <= _firstBlock.add(_botBlocks) && from != presaleRouter && from != presaleAddress) {
                    bots[to] = true;
                }
                
                uint256 bnbAmount = this.getTokenPriceBNB(amount);
                
                require(bnbAmount >= _minBuyBNB, "you must buy at least min BNB worth of token");
                require(balanceOf(to).add(amount) <= _maxWalletAmount, "wallet balance after transfer must be less than max wallet amount");
                
                currentTax = updateFee();
                
            }
            
            if (!inSwap && from != uniswapV2Pair && !_isExchange[from]) { //sells, transfers
                require(!bots[from] && !bots[to]);
                
                if (!_isBridge[from] && !_isBridge[to]) {
                    if ((to == uniswapV2Pair || _isExchange[to]) && _sellCoolDownEnabled) {
                        require(sellcooldown[from] < block.timestamp);
                        sellcooldown[from] = block.timestamp.add(_cooldownBlocks);
                    }
                    
                    uint256 bnbAmount = this.getTokenPriceBNB(amount);
                    
                    require(bnbAmount >= _minSellBNB, "you must buy at least the min BNB worth of token");
                    
                    if(_dailyMaxEnabled) {
                        if(block.timestamp.sub(_firstSell[from]) > (1 days)) {
                            _firstSell[from] = block.timestamp;
                            _sellTotal[from] = 0;
                        }
                        require(_sellTotal[from].add(bnbAmount) <= _maxSellAmountBNB, "you cannot sell more than the max BNB amount per day");
                        _sellTotal[from] += bnbAmount;
                    }
                    else {
                        require(bnbAmount <= _maxSellAmountBNB, 'you cannot sell more than the max BNB amount per transaction');
                    }
                    
                    require(amount <= balanceOf(uniswapV2Pair).mul(_priceImpact).div(100)); // price impact limit
                    
                    if(to != uniswapV2Pair && !_isExchange[to]) {
                        require(balanceOf(to).add(amount) <= _maxWalletAmount, "wallet balance after transfer must be less than max wallet amount");
                    }

                    currentTax = updateFee();
                    
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance > 0) {

                        uint256 autoLPamount = _sellLiquidityFee.mul(contractTokenBalance).div(_sellBuybackFee.add(_sellMarketingFee).add(_sellLiquidityFee).add(_sellDevFee));
                        swapAndLiquify(autoLPamount);
                    
                        swapTokensForEth(contractTokenBalance.sub(autoLPamount));
                    }
                    uint256 contractETHBalance = address(this).balance;
                    if (contractETHBalance > 0) {
                        sendETHToFee(address(this).balance);
                    }
                    
                }
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || presale || _isBridge[to] || _isBridge[from]) {
            restoreAllFee();
            takeFee = false;
        }

        if (bots[from] || bots[to]) {
            restoreAllFee();
            setBotFee();
            takeFee = true;
        }

        if (presale) {
            require(from == owner() || from == presaleRouter || from == presaleAddress);
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

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForEth(half); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to pancakeswap
        addLiquidity(otherHalf, newBalance);
    }

    function sendETHToFee(uint256 amount) private {
        _marketingAddress.transfer(amount.mul(_marketingPercent).div(100));
        _buybackAddress.transfer(amount.mul(_buybackPercent).div(100));
        _developmentAddress.transfer(amount.mul(_devPercent).div(100));
        _projectMaintainence.transfer(amount.mul(_projectMaintainencePercent).div(100));
    }

    function openTrading(uint256 botBlocks, uint256 floorPercent) private {
        uint256 currentPrice = this.getTokenPrice();
        _floorPercent = floorPercent;
        _ath = currentPrice.mul(_floorPercent).div(100);
        previousClose = _ath;
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
                currentTax.buyDevFee = 0;
                
                currentTax.sellBuybackFee = 0;
                currentTax.sellMarketingFee = 0;
                currentTax.sellLiquidityFee = 0;
                currentTax.sellReflectionFee = 0;
                currentTax.sellDevFee = 0;
        }
        if (sender == uniswapV2Pair || _isExchange[sender]){
            _transferStandardBuy(sender, recipient, amount, currentTax);
        }
        else {
            _transferStandardSell(sender, recipient, amount, currentTax);
        }
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
        _takeDev(buyFees.tDev);
        emit Transfer(sender, recipient, buyFees.tTransferAmount);
    }

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
        _takeDev(sellFees.tDev);
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
    
    function _takeDev(uint256 tDev) private  {
        uint256 currentRate = _getRate();
        uint256 rDev = tDev.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rDev);
    }
    receive() external payable {}

    // Sell GetValues
    function _getValuesSell(uint256 tAmount, DynamicTax memory currentTax) private view returns (FinalFees memory) {
        SellBreakdown memory sellFees = _getTValuesSell(tAmount, currentTax.sellBuybackFee, currentTax.sellMarketingFee, currentTax.sellReflectionFee, currentTax.sellLiquidityFee, currentTax.sellDevFee);
        FinalFees memory finalFees;
        uint256 currentRate = _getRate();
        (finalFees.rAmount, finalFees.rTransferAmount, finalFees.rReflection) = _getRValuesSell(tAmount, sellFees.tBuyback, sellFees.tMarketing, sellFees.tReflection, sellFees.tLiquidity, sellFees.tDev, currentRate);
        finalFees.tBuyback = sellFees.tBuyback;
        finalFees.tMarketing = sellFees.tMarketing;
        finalFees.tReflection = sellFees.tReflection;
        finalFees.tLiquidity = sellFees.tLiquidity;
        finalFees.tDev = sellFees.tDev;
        finalFees.tTransferAmount = sellFees.tTransferAmount;
        return (finalFees);
    }

    function _getTValuesSell(uint256 tAmount, uint256 buybackFee, uint256 marketingFee, uint256 reflectionFee, uint256 liquidityFee, uint256 devFee) private pure returns (SellBreakdown memory) {
        SellBreakdown memory tsellFees;
        tsellFees.tBuyback = tAmount.mul(buybackFee).div(100);
        tsellFees.tMarketing = tAmount.mul(marketingFee).div(100);
        tsellFees.tReflection = tAmount.mul(reflectionFee).div(100);
        tsellFees.tLiquidity = tAmount.mul(liquidityFee).div(100);
        tsellFees.tDev = tAmount.mul(devFee).div(100);
        tsellFees.tTransferAmount = tAmount.sub(tsellFees.tBuyback).sub(tsellFees.tMarketing);
        tsellFees.tTransferAmount -= tsellFees.tReflection;
        tsellFees.tTransferAmount -= tsellFees.tLiquidity;
        tsellFees.tTransferAmount -= tsellFees.tDev;
        return (tsellFees);
    }

    function _getRValuesSell(uint256 tAmount, uint256 tBuyback, uint256 tMarketing, uint256 tReflection, uint256 tLiquidity, uint256 tDev, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rBuyback = tBuyback.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rReflection = tReflection.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rDev = tDev.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rBuyback).sub(rMarketing).sub(rReflection);
        rTransferAmount -= rLiquidity;
        rTransferAmount -= rDev;
        return (rAmount, rTransferAmount, rReflection);
    }

    // Buy GetValues
    function _getValuesBuy(uint256 tAmount, DynamicTax memory currentTax) private view returns (FinalFees memory) {
        BuyBreakdown memory buyFees = _getTValuesBuy(tAmount, currentTax.buyBuybackFee, currentTax.buyMarketingFee, currentTax.buyReflectionFee, currentTax.buyLiquidityFee, currentTax.buyDevFee);
        FinalFees memory finalFees;
        uint256 currentRate = _getRate();
        (finalFees.rAmount, finalFees.rTransferAmount, finalFees.rReflection) = _getRValuesBuy(tAmount, buyFees.tBuyback, buyFees.tMarketing, buyFees.tReflection, buyFees.tLiquidity, buyFees.tDev, currentRate);
        finalFees.tBuyback = buyFees.tBuyback;
        finalFees.tMarketing = buyFees.tMarketing;
        finalFees.tReflection = buyFees.tReflection;
        finalFees.tLiquidity = buyFees.tLiquidity;
        finalFees.tDev = buyFees.tDev;
        finalFees.tTransferAmount = buyFees.tTransferAmount;
        return (finalFees);
    }

    function _getTValuesBuy(uint256 tAmount, uint256 buybackFee, uint256 marketingFee, uint256 reflectionFee, uint256 liquidityFee, uint256 devFee) private pure returns (BuyBreakdown memory) {
        BuyBreakdown memory tbuyFees;
        tbuyFees.tBuyback = tAmount.mul(buybackFee).div(100);
        tbuyFees.tMarketing = tAmount.mul(marketingFee).div(100);
        tbuyFees.tReflection = tAmount.mul(reflectionFee).div(100);
        tbuyFees.tLiquidity = tAmount.mul(liquidityFee).div(100);
        tbuyFees.tDev = tAmount.mul(devFee).div(100);
        tbuyFees.tTransferAmount = tAmount.sub(tbuyFees.tBuyback).sub(tbuyFees.tMarketing);
        tbuyFees.tTransferAmount -= tbuyFees.tReflection;
        tbuyFees.tTransferAmount -= tbuyFees.tLiquidity;
        tbuyFees.tTransferAmount -= tbuyFees.tDev;
        return (tbuyFees);
    }

    function _getRValuesBuy(uint256 tAmount, uint256 tBuyback, uint256 tMarketing, uint256 tReflection, uint256 tLiquidity, uint256 tDev, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rBuyback = tBuyback.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rReflection = tReflection.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rDev = tDev.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rBuyback).sub(rMarketing).sub(rReflection);
        rTransferAmount -= rLiquidity;
        rTransferAmount -= rDev;
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
    
    function excludeFromContractWallet(address account) public onlyOwner() {
        _isContractWallet[account] = true;
    }

    function includeInContractWallet(address account) external onlyOwner() {
        _isContractWallet[account] = false;
    }
    
    function includeInExchange(address account) external onlyOwner() {
        _isExchange[account] = true;
    }
    
    function excludeFromExchange(address account) external onlyOwner() {
        _isExchange[account] = false;
    }

    function includeInBridge(address account) external onlyOwner() {
        _isBridge[account] = true;
    }
    
    function excludeFromBridge(address account) external onlyOwner() {
        _isBridge[account] = false;
    }
    
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        require(maxTxAmount > 0, "Amount must be greater than 0");
        require(maxTxAmount <= _tTotal, "Amount must be less than or equal to totalSupply");
        _maxTxAmount = maxTxAmount;
        emit MaxTxAmountUpdated(_maxTxAmount);
    }

    function setMaxWalletAmount(uint256 maxWalletAmount) external onlyOwner() {
        require(maxWalletAmount > 0, "Amount must be greater than 0");
        require(maxWalletAmount <= _tTotal, "Amount must be less than or equal to totalSupply");
        _maxWalletAmount = maxWalletAmount;
    }
    
    function setPercents(uint256 marketingPercent, uint256 buybackPercent, uint256 devPercent) external onlyOwner() {
        require(marketingPercent.add(buybackPercent).add(devPercent) == 95, "Sum of percents must equal 95");
        _marketingPercent = marketingPercent;
        _buybackPercent = buybackPercent;
        _devPercent = devPercent;
        emit PercentsUpdated(_marketingPercent, _buybackPercent, _devPercent);
    }

    function setTaxes(uint256 buyMarketingFee, uint256 buyBuybackFee, uint256 buyReflectionFee, uint256 buyLiquidityFee, uint256 buyDevFee, uint256 sellMarketingFee, uint256 sellBuybackFee, uint256 sellReflectionFee, uint256 sellLiquidityFee, uint256 sellDevFee) external onlyOwner() {
        uint256 buyTax = buyMarketingFee.add(buyBuybackFee).add(buyReflectionFee);
        buyTax += buyLiquidityFee.add(buyDevFee);
        uint256 sellTax = sellMarketingFee.add(sellBuybackFee).add(sellReflectionFee);
        sellTax += sellLiquidityFee.add(sellDevFee);
        require(buyTax < 50, "Sum of sell fees must be less than 50");
        require(sellTax < 50, "Sum of buy fees must be less than 50");
        _buyMarketingFee = buyMarketingFee;
        _buyBuybackFee = buyBuybackFee;
        _buyReflectionFee = buyReflectionFee;
        _buyLiquidityFee = buyLiquidityFee;
        _buyDevFee = buyDevFee;
        _sellMarketingFee = sellMarketingFee;
        _sellBuybackFee = sellBuybackFee;
        _sellReflectionFee = sellReflectionFee;
        _sellLiquidityFee = sellLiquidityFee;
        _sellDevFee = sellDevFee;
        
        _previousBuyMarketingFee = _buyMarketingFee;
        _previousBuyBuybackFee = _buyBuybackFee;
        _previousBuyReflectionFee = _buyReflectionFee;
        _previousBuyLiquidityFee = _buyLiquidityFee;
        _previousBuyDevFee = _buyDevFee;
        _previousSellMarketingFee = _sellMarketingFee;
        _previousSellBuybackFee = _sellBuybackFee;
        _previousSellReflectionFee = _sellReflectionFee;
        _previousSellLiquidityFee = _sellLiquidityFee;
        _previousSellDevFee = _sellDevFee;
        
        emit FeesUpdated(_buyBuybackFee, _buyMarketingFee, _buyLiquidityFee, _buyReflectionFee, _buyDevFee, _sellBuybackFee, _sellMarketingFee, _sellLiquidityFee, _sellReflectionFee, _sellDevFee);
    }

    function setPriceImpact(uint256 priceImpact) external onlyOwner() {
        require(priceImpact <= 100, "max price impact must be less than or equal to 100");
        require(priceImpact > 0, "cant prevent sells, choose value greater than 0");
        _priceImpact = priceImpact;
        emit PriceImpactUpdated(_priceImpact);
    }

    function setManualETHvalue(uint256 val) external onlyOwner() {
        manualETHvalue = int(val.mul(10**8));//18));
    }

    function updateOraclePriceFeed(address feed) external onlyOwner() {
        _oraclePriceFeed = feed;
    }

    function setPresaleRouterAndAddress(address router, address wallet) external onlyOwner() {
        presaleRouter = router;
        presaleAddress = wallet;
        excludeFromFee(presaleRouter);
        excludeFromFee(presaleAddress);
    }

    function endPresale(uint256 botBlocks, uint256 floorPercent) external onlyOwner() {
        require(presale == true, "presale already ended");
        presale = false;
        openTrading(botBlocks, floorPercent);
        emit EndedPresale(presale);
    }

    function enablePriceOracle() external onlyOwner() {
        require(priceOracleEnabled == false, "price oracle already enabled");
        priceOracleEnabled = true;
    }

    function disablePriceOracle() external onlyOwner() {
        require(priceOracleEnabled == true, "price oracle already disabled");
        priceOracleEnabled = false;
    }

    function setFloor() external onlyOwner() {
        previousClose = _ath.mul(_floorPercent).div(100);
        _ath = previousClose;
    }
    
    function setFloorPercent(uint256 floorPercent) external onlyOwner() {
        require(floorPercent > 0 && floorPercent <= 100, 'floorPercent needs to be between 0 and 100');
        _floorPercent = floorPercent;
    }
    function updateTaxFreeBlocks(uint256 taxFreeBlocks) external onlyOwner() {
        _taxFreeBlocks = taxFreeBlocks;
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
    
    function startGoldenHour() private {
        _goldenHourStartBlock = block.timestamp;
        _goldenHourStarted = true;
        _taxFreeWindowEnd = block.timestamp.add(_taxFreeBlocks);
        _slideEndBlock = _taxFreeWindowEnd.add(_taxFreeBlocks);
    }

    function enableSellCoolDown() external onlyOwner() {
        require(!_sellCoolDownEnabled, "already enabled");
        _sellCoolDownEnabled = true;
    }
    
    function disableSellCoolDown() external onlyOwner() {
        require(_sellCoolDownEnabled, "already disabled");
        _sellCoolDownEnabled = false;
    }
    
    function enableDailyMax() external onlyOwner() {
        require(!_dailyMaxEnabled, 'already enabled');
        _dailyMaxEnabled = true;
    }
    
    function disableDailyMax() external onlyOwner() {
        require(_dailyMaxEnabled, 'already diabled');
        _dailyMaxEnabled = false;
    }
    
    function setFloorFees(uint256 floorMarketingFee, uint256 floorBuybackFee, uint256 floorReflectionFee, uint256 floorLiquidityFee, uint256 floorDevFee) external onlyOwner() {
        require(floorMarketingFee.add(floorBuybackFee).add(floorReflectionFee).add(floorLiquidityFee).add(floorDevFee) < 50, "sum of fees must be less than 50");
        _floorMarketingFee = floorMarketingFee;
        _floorBuybackFee = floorBuybackFee;
        _floorReflectionFee = floorReflectionFee;
        _floorLiquidityFee = floorLiquidityFee;
        _floorDevFee = floorDevFee;
    }
    
    function setSlideFees(uint256 slideMarketingFee, uint256 slideBuybackFee, uint256 slideReflectionFee, uint256 slideLiquidityFee, uint256 slideDevFee) external onlyOwner() {
        require(slideMarketingFee.add(slideBuybackFee).add(slideReflectionFee).add(slideLiquidityFee).add(slideDevFee) < 50, "sum of fees must be less than 50");
        _slideMarketingFee = slideMarketingFee;
        _slideBuybackFee = slideBuybackFee;
        _slideReflectionFee = slideReflectionFee;
        _slideLiquidityFee = slideLiquidityFee;
        _slideDevFee = slideDevFee;
    }
    
    function setCoolDownBlocks(uint256 cooldownBlocks) external onlyOwner() {
        _cooldownBlocks = cooldownBlocks;
    }
    
    function updateBuyBackAddress(address payable buybackAddress) external onlyOwner() {
        _buybackAddress = buybackAddress;
    }
    
    function updateMarketingAddress(address payable marketingAddress) external onlyOwner() {
        _marketingAddress = marketingAddress;
    }
    
    function updateDevelopmentAddress(address payable developmentAddress) external onlyOwner() {
        _developmentAddress = developmentAddress;
    }
    
    function getRemainingSellLimit(address payable account) external view returns (uint256) {
        if (_dailyMaxEnabled) {
            return _maxSellAmountBNB.sub(_sellTotal[account]);
        }
        return _maxSellAmountBNB;
    }
    
    function getTimeLimit(address payable account) external view returns (uint256) {
        if (_sellCoolDownEnabled && !_dailyMaxEnabled) {
            if(sellcooldown[account] < block.timestamp) {
                return block.timestamp.sub(sellcooldown[account]); // seconds remaining until cooldown is over
            }
            return 0; // not in cooldown, can sell now
        }
        else if (_sellCoolDownEnabled && _dailyMaxEnabled) {
            if (_maxSellAmountBNB.sub(_sellTotal[account]) > 0) {
                if (sellcooldown[account] > block.timestamp) {
                    return sellcooldown[account].sub(block.timestamp); // seconds remaining until cooldown is over
                }
                else {
                    return 0; // not in cooldown, can sell now
                }
            }
            else {
                if (block.timestamp > _firstSell[account].add(1 days)) {
                    return 0; // it's been more than 24 hours, can sell now
                }
                else {
                    return (uint256(1 days).add(_firstSell[account])).sub(block.timestamp); // seconds remaining until 24 hours have passed
                }
            }
            
        }
        else {
            return 0; // can sell now
        }
    }
}