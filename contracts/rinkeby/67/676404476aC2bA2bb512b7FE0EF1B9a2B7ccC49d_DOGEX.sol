/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

/*

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
    function decimals() public view virtual returns (uint8);
    function name() public view virtual returns (string memory);
    function symbol() public view virtual returns (string memory);
}

contract DOGEX is Context, IERC20, IERC20Extented, Ownable {
    using SafeMath for uint256;
    string private constant _name = "test";
    string private constant _symbol = "test";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public _priceImpact = 2;
    uint256 private currentPrice;
    uint256 private currentDay;
    uint256 private previousClose;
    uint256 private previousPrice;
    uint256 private previousDay;
    uint256 private firstBlock;

    //  buy fees
    uint256 public _buyBuybackFee = 6;
    uint256 private _previousBuyBuybackFee = _buyBuybackFee;
    uint256 public _buyMarketingFee = 4;
    uint256 private _previousBuyMarketingFee = _buyMarketingFee;
    uint256 public _buyReflectionFee = 3;
    uint256 private _previousBuyReflectionFee = _buyReflectionFee;

    // sell fees
    uint256 public _sellBuybackFee = 6;
    uint256 private _previousSellBuybackFee = _sellBuybackFee;
    uint256 public _sellMarketingFee = 4;
    uint256 private _previousSellMarketingFee = _sellMarketingFee;
    uint256 public _sellReflectionFee = 7;
    uint256 private _previousSellReflectionFee = _sellReflectionFee;
 
    uint256 public _marketingPercent = 40;
    uint256 public _buybackPercent = 60;
    
    struct BuyBreakdown {
        uint256 tTransferAmount;
        uint256 tBuyback;
        uint256 tMarketing;
        uint256 tReflection;
    }
    
    struct SellBreakdown {
        uint256 tTransferAmount;
        uint256 tBuyback;
        uint256 tMarketing;
        uint256 tReflection;
    }
    
    mapping(address => bool) private bots;
    address payable private _marketingAddress = payable(0xA5347334AF09Bbc6C2456AB435F54ef8189FA709);
    address payable private _buybackAddress = payable(0x64Ce548B7fe68E7e23892F1f8Ff600595D74484e);
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    uint256 private _maxTxAmount;
  
    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private sellCooldownEnabled = false;
    
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event SellOnlyUpdated(bool sellOnly);
    event PercentsUpdated(uint256 _marketingPercent, uint256 _buybackPercent);
    event FeesUpdated(uint256 _buyBuybackFee, uint256 _sellBuybackFee, uint256 _buyMarketingFee, uint256 _sellMarketingFee, uint256 _buyReflectionFee, uint256 _sellReflectionFee);
    event PriceImpactUpdated(uint256 _priceImpact);

    AggregatorV3Interface internal priceFeed;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//main net 0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //main net 0x10ED43C718714eb63d5aA57B78B54704E256024E
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);

        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);// bnb pricefeed 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);

        currentPrice = 0;
        currentDay = block.timestamp.div(86400);
        previousClose = currentPrice;
        previousPrice = currentPrice;
        previousDay = currentDay;
        
        firstBlock = block.timestamp;

        sellCooldownEnabled = true;

        _maxTxAmount = _tTotal.div(100); // start off transaction limit at 1% of total supply

        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[_buybackAddress] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() override public pure returns (string memory) {
        return _name;
    }

    function symbol() override public pure returns (string memory) {
        return _symbol;
    }

    function decimals() override public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function setSellCooldownEnabled(bool onoff) external onlyOwner() {
        sellCooldownEnabled = onoff;
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    
    function removeAllFee() private {
        if (_buyMarketingFee == 0 && _buyBuybackFee == 0 && _buyReflectionFee == 0 && _sellMarketingFee == 0 && _sellBuybackFee == 0 && _sellReflectionFee == 0) return;
        _previousBuyMarketingFee = _buyMarketingFee;
        _previousBuyBuybackFee = _buyBuybackFee;
        _previousBuyReflectionFee = _buyReflectionFee;
        
        _previousSellMarketingFee = _sellMarketingFee;
        _previousSellBuybackFee = _sellBuybackFee;
        _previousSellReflectionFee = _sellReflectionFee;
        
        _buyMarketingFee = 0;
        _buyBuybackFee = 0;
        _buyReflectionFee = 0;
        
        _sellMarketingFee = 0;
        _sellBuybackFee = 0;
        _sellReflectionFee = 0;
    }

    function restoreAllFee() private {
        _buyMarketingFee = _previousBuyMarketingFee;
        _buyBuybackFee = _previousBuyBuybackFee;
        _buyReflectionFee = _previousBuyReflectionFee;
        
        _sellMarketingFee = _previousSellMarketingFee;
        _sellBuybackFee = _previousSellBuybackFee;
        _sellReflectionFee = _previousSellReflectionFee;
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
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        
        return price;
    }
    
    // calculate price based on pair reserves
    function getTokenPrice() public view returns(uint256) {
        IERC20Extented token1 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token1());
        (uint256 Res0, uint256 Res1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();

        return(uint256(getLatestPrice())/((Res0*(10**uint256(token1.decimals())))/(Res1))); // return amount of token0 needed to buy token1
    }
   
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {//buys
                require(tradingOpen);
                require(amount <= _maxTxAmount);
                require(amount <= balanceOf(uniswapV2Pair).mul(_priceImpact).div(100));
                if (block.timestamp == firstBlock) {
                    bots[to] = true;            
                }
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && sellCooldownEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) { //sells, transfers (except for buys)
                require(amount <= _maxTxAmount);
                currentPrice = getTokenPrice();
                currentDay = block.timestamp.div(86400); // 86400 seconds per day
                if(currentDay > previousDay) {
                    previousClose = previousPrice;
                    previousDay = currentDay;
                }
                else {
                    previousPrice = currentPrice;
                    previousDay = currentDay;
                }
                if (currentDay % 7 == 0) { //TODO on 7th day, at random time, allow price decrease up to 30% below previousCLose
                    require(currentPrice >= previousClose.mul(70).div(100), "cannot sell 30% below previous closing price");
                }
                else {
                    require(currentPrice >= previousClose, "cannot sell below previous closing price!");
                }

                if (contractTokenBalance > 0) {
                    swapTokensForETH(contractTokenBalance);
                }
                uint256 contractETHBalance = address(this).balance; //get ETH balance
                if (contractETHBalance > 0) {
                    sendETHToFee(contractETHBalance);
                }
            }
        }
        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        _tokenTransfer(from, to, amount, takeFee);
        restoreAllFee();
    }

    function swapTokensForETH(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function sendETHToFee(uint256 amount) private {
        _marketingAddress.transfer(amount.mul(_marketingPercent).div(100));
        _buybackAddress.transfer(amount.mul(_buybackPercent).div(100));
    }
    
    function openTrading() public onlyOwner {
        tradingOpen = true;
    }

    function manualswap() external {
        require(_msgSender() == _marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForETH(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _marketingAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        if (sender == uniswapV2Pair){ //buy order, reflection, and lottery
            _transferStandardBuy(sender, recipient, amount);
        }
        else {
            _transferStandardSell(sender, recipient, amount); //take team and whale (no reflection, or lottery)
        }
        if (!takeFee) restoreAllFee();
    }

    function _transferStandardBuy(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tBuyback, uint256 tMarketing, uint256 tReflection) = _getValuesBuy(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeBuyback(tBuyback);
        _takeMarketing(tMarketing);
        _reflectFee(rReflection, tReflection);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferStandardSell(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tBuyback, uint256 tMarketing, uint256 tReflection) = _getValuesSell(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeBuyback(tBuyback);
        _takeMarketing(tMarketing);
        _reflectFee(rReflection, tReflection);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rReflection, uint256 tReflection) private {
        _rTotal = _rTotal.sub(rReflection);
        _tFeeTotal = _tFeeTotal.add(tReflection);
    }

    function _takeBuyback(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }
    
    function _takeMarketing(uint256 tWhale) private {
        uint256 currentRate = _getRate();
        uint256 rWhale = tWhale.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rWhale);
    }

    receive() external payable {}

    // Sell GetValues
    function _getValuesSell(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        SellBreakdown memory sellFees;
        (sellFees.tTransferAmount, sellFees.tBuyback, sellFees.tMarketing, sellFees.tReflection) = _getTValuesSell(tAmount, _sellBuybackFee, _sellMarketingFee, _sellReflectionFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection) = _getRValuesSell(tAmount, sellFees.tBuyback, sellFees.tMarketing, sellFees.tReflection, currentRate);
        return (rAmount, rTransferAmount, rReflection, sellFees.tTransferAmount, sellFees.tBuyback, sellFees.tMarketing, sellFees.tReflection);
    }

    function _getTValuesSell(uint256 tAmount, uint256 buybackFee, uint256 marketingFee, uint256 reflectionFee) private pure returns (uint256, uint256, uint256, uint256) {
        uint256 tBuyback = tAmount.mul(buybackFee).div(100);
        uint256 tMarketing = tAmount.mul(marketingFee).div(100);
        uint256 tReflection = tAmount.mul(reflectionFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tBuyback).sub(tMarketing);
        tTransferAmount -= tReflection;
        return (tTransferAmount, tBuyback, tMarketing, tReflection);
    }

    function _getRValuesSell(uint256 tAmount, uint256 tBuyback, uint256 tMarketing, uint256 tReflection, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rBuyback = tBuyback.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rReflection = tReflection.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rBuyback).sub(rMarketing).sub(rReflection);
        return (rAmount, rTransferAmount, rReflection);
    }

    // Buy GetValues
    function _getValuesBuy(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        BuyBreakdown memory buyFees;
        (buyFees.tTransferAmount, buyFees.tBuyback, buyFees.tMarketing, buyFees.tReflection) = _getTValuesBuy(tAmount, _buyBuybackFee, _buyMarketingFee, _buyReflectionFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection) = _getRValuesBuy(tAmount, buyFees.tBuyback, buyFees.tMarketing, buyFees.tReflection, currentRate);
        return (rAmount, rTransferAmount, rReflection, buyFees.tTransferAmount, buyFees.tBuyback, buyFees.tMarketing, buyFees.tReflection);
    }

    function _getTValuesBuy(uint256 tAmount, uint256 buybackFee, uint256 marketingFee, uint256 reflectionFee) private pure returns (uint256, uint256, uint256, uint256) {
        uint256 tBuyback = tAmount.mul(buybackFee).div(100);
        uint256 tMarketing = tAmount.mul(marketingFee).div(100);
        uint256 tReflection = tAmount.mul(reflectionFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tBuyback).sub(tMarketing);
        tTransferAmount -= tReflection;
        return (tTransferAmount, tBuyback, tMarketing, tReflection);
    }

    function _getRValuesBuy(uint256 tAmount, uint256 tBuyback, uint256 tMarketing, uint256 tReflection, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rBuyback = tBuyback.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rReflection = tReflection.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rBuyback).sub(rMarketing).sub(rReflection);
        return (rAmount, rTransferAmount, rReflection);
    }
    
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
  
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
        emit MaxTxAmountUpdated(_maxTxAmount);
    }
    
    function setPercents(uint256 marketingPercent, uint256 buybackPercent) external onlyOwner() {
        require(marketingPercent.add(buybackPercent) == 100, "Sum of percents must equal 100");
        _marketingPercent = marketingPercent;
        _buybackPercent = buybackPercent;
        emit PercentsUpdated(_marketingPercent, _buybackPercent);
    }
    
    function setTaxes(uint256 buyMarketingFee, uint256 buyBuybackFee, uint256 buyReflectionFee, uint256 sellMarketingFee, uint256 sellBuybackFee, uint256 sellReflectionFee) external onlyOwner() {
        require(buyMarketingFee.add(buyBuybackFee).add(buyReflectionFee) < 50, "Sum of sell fees must be less than 50");
        require(sellMarketingFee.add(sellBuybackFee).add(sellReflectionFee) < 50, "Sum of buy fees must be less than 50");
        _buyMarketingFee = buyMarketingFee;
        _buyBuybackFee = buyBuybackFee;
        _buyReflectionFee = buyReflectionFee;
        _sellMarketingFee = sellMarketingFee;
        _sellBuybackFee = sellBuybackFee;
        _sellReflectionFee = sellReflectionFee;
        emit FeesUpdated(_buyMarketingFee, _buyBuybackFee, _buyReflectionFee, _sellMarketingFee, _sellBuybackFee, _sellReflectionFee);
    }
    
    function setPriceImpact(uint256 priceImpact) external onlyOwner() {
        require(priceImpact < 10, "max price impact must be less than 10");
        _priceImpact = priceImpact;
        emit PriceImpactUpdated(_priceImpact);
    }
}