/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

/*

🇸🇻 EI Salvador Dollar Fair Launch SOON - NEW ATH every hour - DogeX tokenomic

🟢 BUY TAX - 13%🟢
5.5% Buyback
4% Marketing
3% Reflection
0.5% Project maintenance

🔴 SELL TAX - 18%🔴 
7% Reflection
6% Buyback
4.5% Marketing
0.5% Project maintenance

- BUY BACK
It's programmed to automatically buy the floor via multiple transactions

- SELL COOLDOWN MECHANISM
Unlike DogeX, In EI Salvador Dollar - ATH will be updated every hour and price can not be lower than the previous ATH. 

- HAPPY HOUR
Every time we reach the floor, whether on the way up or the way down, there will be 0% tax on all buys for 15 minutes


Telegram: https://t.me/EiSalvadorDollar
Twitter: https://twitter.com/Salvador_Dollar
Website: Coming Soon
 
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
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
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

contract EISalvadorDollar is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "EISalvadorDollar";
    string private constant _symbol = "EISalvadorDollar";
    string private freeTax = "";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 public _maxTxAmount = (_tTotal * 2) / 100; // Max Transaction is 2%
    uint256 public _maxWalletAmount = (_tTotal * 2) / 100; // Max wallet 2% 
    
    uint256 private _tFeeTotal;
    uint256 public _priceImpact = 1;
    uint256 public blockWindow = 60 minutes; // ATH every hour
    uint256 public previousATH;
    uint256 public previousTime;
    uint256 private _firstBlock;
    uint256 private _botBlocks;
    uint256 public _taxFreeBlocks = 15 minutes; // 15 minutes
    bool public _hitFloor = false;
    uint256 public _taxFreeWindowEnd; // block.timestamp + _taxFreeBlocks
    bool public windowStarted = false;

    //  buy fees
    uint256 public _buyBuybackFee = 6;
    uint256 private _previousBuyBuybackFee = _buyBuybackFee;
    uint256 public _buyMarketingFee = 4;
    uint256 private _previousBuyMarketingFee = _buyMarketingFee;
    uint256 public _buyReflectionFee = 3;
    uint256 private _previousBuyReflectionFee = _buyReflectionFee;

    // sell fees
    uint256 public _sellBuybackFee = 7;
    uint256 private _previousSellBuybackFee = _sellBuybackFee;
    uint256 public _sellMarketingFee = 4;
    uint256 private _previousSellMarketingFee = _sellMarketingFee;
    uint256 public _sellReflectionFee = 4;
    uint256 private _previousSellReflectionFee = _sellReflectionFee;

    uint256 constant public _projectMaintainencePercent = 5;
    uint256 public _marketingPercent = 35;
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
    address payable private _marketingAddress = payable(0xD9b9fCA41d4d7257642ddE21F311044C5D9FC87c);
    address payable private _buybackAddress = payable(0x2E520d6e885ec5904019E5BDd2d5212e30b543D1);
    address payable private _projectMaintainence = payable(0x5176828a6e02c546938Fc3513B65D3D16E93c147);
    address payable private _burnAddress = payable(0x000000000000000000000000000000000000dEaD);

    address private WBNB;
    
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;

    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private pairSwapped = false;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        WBNB = _uniswapV2Router.WETH();
        
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), WBNB);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
        
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[_buybackAddress] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() override external view returns (string memory) { 
        return string(abi.encodePacked(_name, freeTax));
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

    function setBotFee() private {
        _previousBuyMarketingFee = _buyMarketingFee;
        _previousBuyBuybackFee = _buyBuybackFee;
        _previousBuyReflectionFee = _buyReflectionFee;

        _previousSellMarketingFee = _sellMarketingFee;
        _previousSellBuybackFee = _sellBuybackFee;
        _previousSellReflectionFee = _sellReflectionFee;

        _buyMarketingFee = 45;
        _buyBuybackFee = 45;
        _buyReflectionFee = 0;

        _sellMarketingFee = 45;
        _sellBuybackFee = 45;
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
    
    function getTokenPrice() external view returns(uint256){
        IERC20 BNB = IERC20(WBNB);
        uint256 wbnbdinLP = BNB.balanceOf(uniswapV2Pair);
        uint256 tokensInLP = balanceOf(uniswapV2Pair);
        uint256 priceInBNB = (wbnbdinLP.mul(10**18)).div(tokensInLP);
        return priceInBNB;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;

        if (from != owner() && to != owner()) {
            require(tradingOpen && amount <= _maxTxAmount);

            uint256 currentPrice = this.getTokenPrice();
            uint256 currentTime = block.timestamp;
            
            if(previousTime + blockWindow <= currentTime) {
                updateNewATH(currentTime, currentPrice);
            }
                
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {//buys
                require(balanceOf(to) + amount <= _maxWalletAmount); //Can not hold more than Max Wallet

                if (block.timestamp <= _firstBlock.add(_botBlocks)) {
                    bots[to] = true;
                }
                
                if(currentPrice <= previousATH && !_hitFloor) { // no buy tax if price is at or below floor
                    _taxFreeWindowEnd = block.timestamp.add(_taxFreeBlocks);
                    _hitFloor = true;
                }

                if(block.timestamp <= _taxFreeWindowEnd) {
                    takeFee = false;
                    freeTax = " - HAPPY HOUR NOW !!!";
                }
                else { 
                    _hitFloor = false;
                    freeTax = "";
                }
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) { //sells, transfers (except for buys)
                if (bots[from]) {
                    require(to != uniswapV2Pair); //bots cannot sell
                }

                require(amount <= balanceOf(uniswapV2Pair).mul(_priceImpact).div(100)); // price impact limit
                require(currentPrice > previousATH, "cannot sell below previous closing price!");

                if (contractTokenBalance > 0) {
                    swapTokensForEth(contractTokenBalance);
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        if (bots[from] || bots[to]) {
            setBotFee();
            takeFee = true;
        }

        _tokenTransfer(from, to, amount, takeFee);

        restoreAllFee();
    }

    function updateNewATH(uint256 currentTime, uint256 price) internal {
        previousATH = price;
        previousTime = currentTime;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function sendETHToFee(uint256 amount) private {
        _marketingAddress.transfer(amount.mul(_marketingPercent).div(100));
        _buybackAddress.transfer(amount.mul(_buybackPercent).div(100));
        _projectMaintainence.transfer(amount.mul(_projectMaintainencePercent).div(100));
    }

    function openTrading(uint256 botBlocks) external onlyOwner {
        uint256 currentPrice = this.getTokenPrice();
        updateNewATH(block.timestamp, currentPrice);
        _firstBlock = block.timestamp;
        _botBlocks = botBlocks;
        tradingOpen = true;
    }

    function manualswap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        if (sender == uniswapV2Pair){
            _transferStandardBuy(sender, recipient, amount);
        }
        else {
            _transferStandardSell(sender, recipient, amount);
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
        if (recipient == _burnAddress) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        }
        _takeBuyback(tBuyback);
        _takeMarketing(tMarketing);
        _reflectFee(rReflection, tReflection);
        emit Transfer(sender, recipient, tTransferAmount);
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
        if (_rOwned[_burnAddress] > rSupply || _tOwned[_burnAddress] > tSupply) return (_rTotal, _tTotal);
        rSupply = rSupply.sub(_rOwned[_burnAddress]);
        tSupply = tSupply.sub(_tOwned[_burnAddress]);
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function setExcludeFeeMultiple(address[] calldata _users, bool exempt) external onlyOwner {
        for(uint8 i = 0; i < _users.length; i++) {
            _isExcludedFromFee[_users[i]] = exempt;
        }
    }
    
    function removeBot(address account) external onlyOwner {
        bots[account] = false;
    }

    function addBot(address account) external onlyOwner{
        bots[account] = true;
    }

    function setMaxWallet(uint256 maxWallet) external onlyOwner {
        _maxWalletAmount = maxWallet;
    }
    
    function setMaxTx(uint256 maxTxAmount) external onlyOwner {
        require(maxTxAmount >= (_tTotal * 1) / 1000); //At least 0.1%, can not set 0
        _maxTxAmount = maxTxAmount;
    }

    function setPercents(uint256 marketingPercent, uint256 buybackPercent) external onlyOwner {
        require(marketingPercent.add(buybackPercent) == 95, "Sum of percents must equal 95");
        _marketingPercent = marketingPercent;
        _buybackPercent = buybackPercent;
    }

    function setTaxes(uint256 buyMarketingFee, uint256 buyBuybackFee, uint256 buyReflectionFee, uint256 sellMarketingFee, uint256 sellBuybackFee, uint256 sellReflectionFee) external onlyOwner {
        require(buyMarketingFee.add(buyBuybackFee).add(buyReflectionFee) < 50, "Sum of sell fees must be less than 50");
        require(sellMarketingFee.add(sellBuybackFee).add(sellReflectionFee) < 50, "Sum of buy fees must be less than 50");
        _buyMarketingFee = buyMarketingFee;
        _buyBuybackFee = buyBuybackFee;
        _buyReflectionFee = buyReflectionFee;
        _sellMarketingFee = sellMarketingFee;
        _sellBuybackFee = sellBuybackFee;
        _sellReflectionFee = sellReflectionFee;

        _previousBuyMarketingFee =  _buyMarketingFee;
        _previousBuyBuybackFee = _buyBuybackFee;
        _previousBuyReflectionFee = _buyReflectionFee;
        _previousSellMarketingFee = _sellMarketingFee;
        _previousSellBuybackFee = _sellBuybackFee;
        _previousSellReflectionFee = _sellReflectionFee;
    }

    function setPriceImpact(uint256 priceImpact) external onlyOwner {
        require(priceImpact <= 100, "max price impact must be less than or equal to 100");
        require(priceImpact > 0, "cant prevent sells, choose value greater than 0");
        _priceImpact = priceImpact;
    }

    function setBlockWindow(uint256 _blockwindow) external onlyOwner {
        blockWindow = _blockwindow;
    }

    function setFloor() external onlyOwner() {
        uint256 price =  this.getTokenPrice();
        previousATH = price;
    }

    function updateTaxFreeBlocks(uint256 taxFreeBlocks) external onlyOwner{
        _taxFreeBlocks = taxFreeBlocks;
    }
    
    function updateWallet(address marketingAddress, address buybackAddress, address projectMaintainence) external onlyOwner{
        _marketingAddress = payable(marketingAddress);
        _buybackAddress = payable(buybackAddress);
        _projectMaintainence = payable(projectMaintainence); 
    }
}