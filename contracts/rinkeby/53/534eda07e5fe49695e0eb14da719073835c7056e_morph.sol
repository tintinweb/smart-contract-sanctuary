/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

/*
2.5% marketing 
2.5% dev
10% buyback

1% transaction limit first five minutes 

1 trillion supply

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


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

contract morph is Context, IERC20, IERC20Extented, Ownable {
    using SafeMath for uint256;
    string private constant _name = "morph token";
    string private constant _symbol = "morph";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant _tTotal = 1000000000000 * 10**9;
    uint256 private _tFeeTotal;

    uint256 private _firstBlock;
    uint256 private _botBlocks;

    uint256 public _buybackFee = 50; 
    uint256 private _previousBuybackFee = _buybackFee;
    uint256 public _marketingFee = 25; 
    uint256 private _previousMarketingFee = _marketingFee;
    uint256 public _devFee = 25; 
    uint256 private _previousDevFee = _devFee;
 
    uint256 public _marketingPercent = 50;
    uint256 public _buybackPercent = 50;
    
    mapping(address => bool) private bots;
    address payable private _marketingAddress = payable(0xE7a1a9027613CCF3b63cF5773DdCEf3107DE8966);
    address payable private _buybackAddress = payable(0xe692CD512Fa70FCbcACF984C6a210B1A992152Ec);

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    uint256 private _maxTxAmount;
  
    bool private tradingOpen = false;
    bool private inSwap = false;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event PercentsUpdated(uint256 _marketingPercent, uint256 _buybackPercent);
    event FeesUpdated(uint256 _buybackFee, uint256 _marketingFee, uint256 _devFee);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);

        _maxTxAmount = _tTotal; // start off transaction limit at 100% of total supply

        balances[_msgSender()] = _tTotal;
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
        return balances[account];
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
    
    function removeAllFee() private {
        if (_marketingFee == 0 && _buybackFee == 0 && _devFee == 0) return;
        _previousMarketingFee = _marketingFee;
        _previousBuybackFee = _buybackFee;
        _previousDevFee = _devFee;
        
        _marketingFee = 0;
        _buybackFee = 0;
        _devFee = 0;
    }
    
    function restoreAllFee() private {
        _marketingFee = _previousMarketingFee;
        _buybackFee = _previousBuybackFee;
        _devFee = _previousDevFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
   
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            require(tradingOpen);
            require(amount <= _maxTxAmount);
            
            if (block.timestamp <= _firstBlock + (5 minutes)) { 
                require(amount <= _tTotal.div(100));
            }
            
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) { 
                if (block.timestamp <= _firstBlock.add(_botBlocks)) {
                    bots[to] = true;            
                }
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) { 
                require(!bots[to] && !bots[from]); 

                if (contractTokenBalance > 0) {
                    swapTokensForEth(contractTokenBalance);
                }
                
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
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
    
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function sendETHToFee(uint256 amount) private {
        _marketingAddress.transfer(amount.mul(_marketingPercent).div(100));
        _buybackAddress.transfer(amount.mul(_buybackPercent).div(100));
    }
    
    function openTrading(uint256 botBlocks) external onlyOwner() {
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

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        (uint256 tTransferAmount, uint256 tBuyback, uint256 tMarketing, uint256 tDev) = _getValues(tAmount);
        balances[sender] = balances[sender].sub(tAmount);
        balances[recipient] = balances[recipient].add(tTransferAmount);
        _takeBuyback(tBuyback);
        _takeMarketing(tMarketing);
        _takeDev(tDev);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeBuyback(uint256 tBuyback) private {
        balances[address(this)] = balances[address(this)].add(tBuyback);
    }
    
    function _takeMarketing(uint256 tMarketing) private {
        balances[address(this)] = balances[address(this)].add(tMarketing);
    }
    
    function _takeDev(uint256 tDev) private {
        balances[address(this)] = balances[address(this)].add(tDev);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tBuyback = tAmount.mul(_buybackFee).div(1000);
        uint256 tMarketing = tAmount.mul(_marketingFee).div(1000);
        uint256 tDev = tAmount.mul(_devFee).div(1000);
        uint256 tTransferAmount = tAmount.sub(tBuyback).sub(tMarketing);
        tTransferAmount -= tDev;
        return (tTransferAmount, tBuyback, tMarketing, tDev);
    }
  
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
  
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    function removeBot(address account) public onlyOwner() {
        bots[account] = false;
    }
  
    function addBot(address account) public onlyOwner() {
        bots[account] = true;
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
    
    function setTaxes(uint256 marketingFee, uint256 buybackFee, uint256 devFee) external onlyOwner() {
        require(marketingFee.add(buybackFee).add(devFee) <= 1000, "Sum of sell fees must be less than 1000");
        _marketingFee = marketingFee;
        _buybackFee = buybackFee;
        _devFee = devFee;
        
        _previousMarketingFee =  _marketingFee;
        _previousBuybackFee = _buybackFee;
        _previousDevFee = _devFee;
        
        emit FeesUpdated(_marketingFee, _buybackFee, _devFee);
    }

}