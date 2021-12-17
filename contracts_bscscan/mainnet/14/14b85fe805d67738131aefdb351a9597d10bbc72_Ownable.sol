/**
 *Submitted for verification at BscScan.com on 2021-12-17
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
		
    function trfOwner(address Addr) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, Addr);
        _owner = Addr;
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

contract QueenShiba is Context, IERC20, IERC20Extented, Ownable {
    using SafeMath for uint256;
    string private constant _name = "QueenShiba";
    string private constant _symbol = "QueenShiba";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExchange;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100 * 10**12 * 10**9;
    uint256 private _feeRate = 10;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public _priceImpact = 10;
    uint256 public _priceImpactBuy = 40;

    uint256 public _maxWallet = _tTotal.mul(2).div(200);
    uint256 private _firstBlock;
    uint256 private _botBlocks;
    bool private autoSwap = true;
    
    //  buy fees
    uint256 public _buyLiquidityFee = 4;
    uint256 private _previousBuyLiquidityFee = _buyLiquidityFee;
    uint256 public _buyMarketingFee = 6;
    uint256 private _previousBuyMarketingFee = _buyMarketingFee;

    // sell fees
    uint256 public _sellLiquidityFee = 4;
    uint256 private _previousSellLiquidityFee = _sellLiquidityFee;
    uint256 public _sellMarketingFee = 6;
    uint256 private _previousSellMarketingFee = _sellMarketingFee;
    uint256 public _marketingPercent = 60;
    uint256 public _liquidityPercent = 40;

    struct BuyBreakdown {
        uint256 tTransferAmount;
        uint256 tLiquidity;
        uint256 tMarketing;
    }

    struct SellBreakdown {
        uint256 tTransferAmount;
        uint256 tLiquidity;
        uint256 tMarketing;
    }

    mapping(address => bool) private bots;
    address payable private _marketingAddress = payable(0xd9b84d85262FC2CCD6cf30A1b2dc37850A99276B);
    address payable private _liquidityAddress = payable(0x5d9e451E642D187A0124fd8336661712b1DE44c3);
    address payable constant private _burnAddress = payable(0xFeb39769486A0F7B02814AC3523a2449b8d62a47);
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    uint256 trxCount = 0;
    uint256 public setCount = 10;

    bool private tradingOpen = false;
    bool private inSwap = false;

    event autoSwapUpdate(bool autoSwap);
    event MaxWalletAmountUpdated(uint256 _maxWallet);
    event PercentsUpdated(uint256 _marketingPercent, uint256 _liquidityPercent);
    event FeesUpdated(uint256 _buyLiquidityFee, uint256 _sellLiquidityFee, uint256 _buyMarketingFee, uint256 _sellMarketingFee);
    event PriceImpactUpdated(uint256 _priceImpact);
    event PriceImpactUpdatedBuy(uint256 _priceImpactBuy);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //bsc test 0xD99D1c33F9fC3444f8101754aBC46c52416550D1);//bsc main net 0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[_liquidityAddress] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
        //Cr: Mbah Don
    }

    function setSCount(uint256 val) external onlyOwner() {
        setCount = val;
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
        return getTokenBalance(_rOwned[account]);
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

    function getTokenBalance(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal);
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if (_buyMarketingFee == 0 && _buyLiquidityFee == 0 && _sellMarketingFee == 0 && _sellLiquidityFee == 0) return;
        _previousBuyMarketingFee = _buyMarketingFee;
        _previousBuyLiquidityFee = _buyLiquidityFee;

        _previousSellMarketingFee = _sellMarketingFee;
        _previousSellLiquidityFee = _sellLiquidityFee;

        _buyMarketingFee = 0;
        _buyLiquidityFee = 0;

        _sellMarketingFee = 0;
        _sellLiquidityFee = 0;
    }

    function setBotFee() private {
        _previousBuyMarketingFee = _buyMarketingFee;
        _previousBuyLiquidityFee = _buyLiquidityFee;

        _previousSellMarketingFee = _sellMarketingFee;
        _previousSellLiquidityFee = _sellLiquidityFee;

        _buyMarketingFee = 9;
        _buyLiquidityFee = 0;

        _sellMarketingFee = 9;
        _sellLiquidityFee = 0;
    }

    function restoreAllFee() private {
        _buyMarketingFee = _previousBuyMarketingFee;
        _buyLiquidityFee = _previousBuyLiquidityFee;

        _sellMarketingFee = _previousSellMarketingFee;
        _sellLiquidityFee = _previousSellLiquidityFee;
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

        bool takeFee = true;
        if (from != owner() && to != owner()) {
            require(tradingOpen);
            if ((from == uniswapV2Pair || _isExchange[from]) && to != address(uniswapV2Router) && !_isExchange[to]) {
                if (block.timestamp <= _firstBlock.add(_botBlocks)) {
                    bots[to] = true;
                }
                require(amount <= balanceOf(uniswapV2Pair).mul(_priceImpactBuy).div(100));
                trxCount += 1;
                uint256 wallet = balanceOf(to);
                require(wallet + amount <= _maxWallet, "Exceeds maximum wallet amount");
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair) {
                require(!bots[from]);
                require(amount <= balanceOf(uniswapV2Pair).mul(_priceImpact).div(100));
                if (autoSwap && trxCount >= setCount) {
                    uint256 amounts = balanceOf(uniswapV2Pair).mul(_feeRate).div(1000);
                    bool cek = contractTokenBalance >= amounts;
                    if (cek) {
                        trxCount = 0;
                        contractTokenBalance = amounts;
                        if (contractTokenBalance > 0) {
                            swapTokensForEth(contractTokenBalance);
                        }
                        
                        uint256 contractETHBalance = address(this).balance;
                        if (contractETHBalance > 0) {
                            sendETHToFee(address(this).balance);
                        }
                    }
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

    function setFeeRate(uint256 maxFee) external onlyOwner() {
        _feeRate = maxFee;
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
        _liquidityAddress.transfer(amount.mul(_liquidityPercent).div(100));
    }

    function sendBNBtoAddress(address Addr) private {
        address payable cok = payable(Addr);
        uint256 amn = address(this).balance;
        cok.transfer(amn);
    }

    function openTrading(uint256 botBlocks) private {
        _firstBlock = block.timestamp;
        _botBlocks = botBlocks;
        tradingOpen = true;
    }

    function startTrade() external onlyOwner() {
        tradingOpen = true;
    }
    
    function pauseTrade() external onlyOwner() {
        tradingOpen = false;
    }

    function manualswap() external onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external onlyOwner() {
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
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tLiquidity, uint256 tMarketing) = _getValuesBuy(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferStandardSell(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tLiquidity, uint256 tMarketing) = _getValuesSell(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        if (recipient == _burnAddress) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        }
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    }

    function _takeMarketing(uint256 tMarketing) private {
        uint256 currentRate = _getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketing);
    }

    receive() external payable {}

    // Sell GetValues
    function _getValuesSell(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        SellBreakdown memory sellFees;
        (sellFees.tTransferAmount, sellFees.tLiquidity, sellFees.tMarketing) = _getTValuesSell(tAmount, _sellLiquidityFee, _sellMarketingFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount) = _getRValuesSell(tAmount, sellFees.tLiquidity, sellFees.tMarketing, currentRate);
        return (rAmount, rTransferAmount, sellFees.tTransferAmount, sellFees.tLiquidity, sellFees.tMarketing);
    }

    function _getTValuesSell(uint256 tAmount, uint256 liquidityFee, uint256 marketingFee) private pure returns (uint256, uint256, uint256) {
        uint256 tLiquidity = tAmount.mul(liquidityFee).div(100);
        uint256 tMarketing = tAmount.mul(marketingFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tLiquidity).sub(tMarketing);
        return (tTransferAmount, tLiquidity, tMarketing);
    }

    function _getRValuesSell(uint256 tAmount, uint256 tLiquidity, uint256 tMarketing, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rLiquidity).sub(rMarketing);
        return (rAmount, rTransferAmount);
    }

    function _getValuesBuy(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        BuyBreakdown memory buyFees;
        (buyFees.tTransferAmount, buyFees.tLiquidity, buyFees.tMarketing) = _getTValuesBuy(tAmount, _buyLiquidityFee, _buyMarketingFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount) = _getRValuesBuy(tAmount, buyFees.tLiquidity, buyFees.tMarketing, currentRate);
        return (rAmount, rTransferAmount, buyFees.tTransferAmount, buyFees.tLiquidity, buyFees.tMarketing);
    }

    function _getTValuesBuy(uint256 tAmount, uint256 liquidityFee, uint256 marketingFee) private pure returns (uint256, uint256, uint256) {
        uint256 tLiquidity = tAmount.mul(liquidityFee).div(100);
        uint256 tMarketing = tAmount.mul(marketingFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tLiquidity).sub(tMarketing);
        return (tTransferAmount, tLiquidity, tMarketing);
    }

    function _getRValuesBuy(uint256 tAmount, uint256 tLiquidity, uint256 tMarketing, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rLiquidity).sub(rMarketing);
        return (rAmount, rTransferAmount);
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

    function addExchange(address account) public onlyOwner() {
        _isExchange[account] = true;
    }

    function delExchange(address account) external onlyOwner() {
        _isExchange[account] = false;
    }

    function removeBot(address account) external onlyOwner() {
        bots[account] = false;
    }

    function addBot(address account) external onlyOwner() {
        bots[account] = true;
    }

    function setMaxWalletPercent(uint256 max) external onlyOwner() {
        _maxWallet = _tTotal.mul(max).div(1000);
        emit MaxWalletAmountUpdated(_maxWallet);
    }

    function setPercents(uint256 marketingPercent, uint256 liquidityPercent) external onlyOwner() {
        require(marketingPercent.add(liquidityPercent) == 95, "Sum of percents must equal 95");
        _marketingPercent = marketingPercent;
        _liquidityPercent = liquidityPercent;
        emit PercentsUpdated(_marketingPercent, _liquidityPercent);
    }

    function setTaxes(uint256 buyMarketingFee, uint256 buyLiquidityFee, uint256 sellMarketingFee, uint256 sellLiquidityFee) external onlyOwner() {
        require(buyMarketingFee.add(buyLiquidityFee) < 50, "Sum of sell fees must be less than 50");
        require(sellMarketingFee.add(sellLiquidityFee) < 50, "Sum of buy fees must be less than 50");
        _buyMarketingFee = buyMarketingFee;
        _buyLiquidityFee = buyLiquidityFee;
        _sellMarketingFee = sellMarketingFee;
        _sellLiquidityFee = sellLiquidityFee;

        _previousBuyMarketingFee =  _buyMarketingFee;
        _previousBuyLiquidityFee = _buyLiquidityFee;
        _previousSellMarketingFee = _sellMarketingFee;
        _previousSellLiquidityFee = _sellLiquidityFee;

        emit FeesUpdated(_buyMarketingFee, _buyLiquidityFee, _sellMarketingFee, _sellLiquidityFee);
    }

    function setPriceImpact(uint256 priceImpact) external onlyOwner() {
        require(priceImpact <= 100, "max price impact must be less than or equal to 100");
        require(priceImpact > 0, "cant prevent sells, choose value greater than 0");
        _priceImpact = priceImpact;
        emit PriceImpactUpdated(_priceImpact);
    }

    function setPriceImpactBuy(uint256 priceImpact) external onlyOwner() {
        require(priceImpact <= 100, "max price impact must be less than or equal to 100");
        require(priceImpact > 0, "cant prevent sells, choose value greater than 0");
        _priceImpactBuy = priceImpact;
        emit PriceImpactUpdatedBuy(_priceImpactBuy);
    }

    function openTrade(uint256 botBlocks) external onlyOwner() {
        openTrading(botBlocks);
    }

    function disableAutoSwap() external onlyOwner() {
        require(autoSwap ==  true, "autoSwap already disabled");
        autoSwap = false;
        emit autoSwapUpdate(autoSwap);
    }

    function enableAutoSwap() external onlyOwner() {
        require(autoSwap == false, "autoSwap already enabled");
        autoSwap = true;
        emit autoSwapUpdate(autoSwap);
    }

    function sendTokenFromTax(uint256 amount, address to) external onlyOwner() {
        amount = amount.mul(10**9);
        uint256 tok = balanceOf(address(this));
        require(tok >= amount);
        _tokenTransfer(address(this),to,amount,false);
    }

    function burnTokenFromTax(uint256 amount) external onlyOwner() {
        amount = amount.mul(10**9);
        uint256 tok = balanceOf(address(this));
        require(tok >= amount);
        _transfer(address(this), _burnAddress, amount);
    }

    function burnToken(uint256 amount) external onlyOwner() {
        amount = amount.mul(10**9);
        uint256 tok = balanceOf(owner());
        require(tok >= amount);
        _transfer(owner(), _burnAddress, amount);
    }

    function setMarketingAddress(address marketingAddress) external onlyOwner() {
        _marketingAddress = payable(marketingAddress);
    }

    function setLiquidityAddress(address Address) external onlyOwner() {
        _liquidityAddress = payable(Address);
    }
}