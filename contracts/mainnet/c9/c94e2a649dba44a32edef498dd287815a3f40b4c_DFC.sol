/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// SPDX-License-Identifier: Unlicensed

/**
 *  
 *  You buy $DFC. We farm on Degen protocols with insanely high APR across multiple chains and return profits to holders.
 *  
 *  https://t.me/DegenFarmCapital
 *  
 *  https://degenfarm.capital
 *  
 *  13% Slippage
 *  
 */

pragma solidity ^0.8.9;

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

contract DFC is Context, IERC20, Auth {
    using SafeMath for uint256;
    string private constant _name = "Degen Farm Capital | t.me/DegenFarmCapital";
    string private constant _symbol = "DFC";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000 * (10**_decimals); // 1T Supply
    uint256 public swapLimit;
    uint256 public maxSwapLimit = _tTotal / 2000;
    bool private swapEnabled = true;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _launchBlock;
    uint256 private _protectionBlocks;

    uint256 private _buyLPFee = 4;
    uint256 private _buyMarketingFee = 4;
    uint256 private _buyReflectionFee = 4;

    uint256 private _sellLPFee = 4;
    uint256 private _sellMarketingFee = 4;
    uint256 private _sellReflectionFee = 4;

    struct FeeBreakdown {
        uint256 tTransferAmount;
        uint256 tLP;
        uint256 tMarketing;
        uint256 tReflection;
    }
    
    struct Fee {
        uint256 buyMarketingFee;
        uint256 buyReflectionFee;
        uint256 buyLPFee;
        
        uint256 sellMarketingFee;
        uint256 sellReflectionFee;
        uint256 sellLPFee;
    }
    
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
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);

        address owner = _msgSender();
        
        _marketingAddress = payable(owner);
        _LPAddress = payable(owner);
        
        swapLimit = _tTotal.div(100).mul(100 - perc);
        
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

    function name() override external pure returns (string memory) {return _name;}
    function symbol() override external pure returns (string memory) {return _symbol;}
    function decimals() override external pure returns (uint8) {return _decimals;}
    function totalSupply() external pure override returns (uint256) {return _tTotal;}
    function balanceOf(address account) public view override returns (uint256) {return tokenFromReflection(_rOwned[account]);}
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) external view override returns (uint256) {return _allowances[owner][spender];}
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
    
    function getFee() internal view returns (Fee memory) {
        Fee memory currentFee;
        
        currentFee.buyMarketingFee = _buyMarketingFee;
        currentFee.buyLPFee = _buyLPFee;
        currentFee.buyReflectionFee = _buyReflectionFee;
        
        currentFee.sellMarketingFee = _sellMarketingFee;
        currentFee.sellLPFee = _sellLPFee;
        currentFee.sellReflectionFee = _sellReflectionFee;
        
        return currentFee;
    }

    function removeAllFee() internal pure returns (Fee memory) {
        Fee memory currentFee;
        
        currentFee.buyMarketingFee = 0;
        currentFee.buyLPFee = 0;
        currentFee.buyReflectionFee = 0;
        
        currentFee.sellMarketingFee = 0;
        currentFee.sellLPFee = 0;
        currentFee.sellReflectionFee = 0;
        
        return currentFee;
    }
    
    function setWreckFee() internal pure returns (Fee memory) {
        Fee memory currentFee;
        
        currentFee.buyMarketingFee = 98;
        currentFee.buyLPFee = 1;
        currentFee.buyReflectionFee = 0;
        
        currentFee.sellMarketingFee = 98;
        currentFee.sellLPFee = 1;
        currentFee.sellReflectionFee = 0;
        
        return currentFee;
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
        
        Fee memory currentFee = getFee();
            
        if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
            require(amount <= _maxBuyTxAmount, "Max Buy Limit");
            
            if (block.number <= _launchBlock.add(_protectionBlocks) || !tradingOpen) {
                wreck[to] = true;
            }
        } else if (!inSwap && from != uniswapV2Pair && !_isExcludedFromFee[from]) { //sells, transfers (except for buys)
            require(amount <= _maxSellTxAmount, "Max Sell Limit");
            
            if (block.number <= _launchBlock.add(_protectionBlocks) || !tradingOpen) {
                wreck[from] = true;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            
            if (contractTokenBalance > swapLimit && swapEnabled) {
                if (contractTokenBalance >= swapLimit + maxSwapLimit) {
                    convertTokensForFee(maxSwapLimit);
                } else {
                    convertTokensForFee(contractTokenBalance.sub(swapLimit));
                }
            }

            
            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0) {
                distributeFee(address(this).balance);
            }
        }  else {
            takeFee = false;
        }

        if (wreck[from] || wreck[to]) {
            currentFee = setWreckFee();
            takeFee = true;
        }

        _tokenTransfer(from, to, amount, takeFee, currentFee);
    }

    function convertTokensForFee(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function distributeFee(uint256 amount) private {
        _marketingAddress.transfer(amount.div(2));
        _LPAddress.transfer(amount.div(2));
    }

    function openTrading(uint256 protectionBlocks) external onlyOwner {
        _launchBlock = block.number;
        _protectionBlocks = protectionBlocks;
        tradingOpen = true;
    }
    
    function updateProtection(uint256 protectionBlocks) external onlyOwner {
        _protectionBlocks = protectionBlocks;
    }

    function triggerSwap(uint256 perc) external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        convertTokensForFee(contractBalance.mul(perc).div(100));
        swapLimit = contractBalance.mul(100-perc).div(100);
    }
    
    function manuallyCollectFee(uint256 amount) external onlyOwner {
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
        _processFee(tLP, tMarketing);
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
        _processFee(tLP, tMarketing);
        _rTotal = _rTotal.sub(rReflection);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _processFee(uint256 tLP, uint256 tMarketing) internal {
        uint256 currentRate = _getRate();
        uint256 rLP = tLP.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLP).add(rMarketing);
    }

    receive() external payable {}
    
    function _getValuesBuy(uint256 tAmount, Fee memory currentFee) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        FeeBreakdown memory buyFees;
        (buyFees.tTransferAmount, buyFees.tLP, buyFees.tMarketing, buyFees.tReflection) = _getTValues(tAmount, currentFee.buyLPFee, currentFee.buyMarketingFee, currentFee.buyReflectionFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection) = _getRValues(tAmount, buyFees.tLP, buyFees.tMarketing, buyFees.tReflection, currentRate);
        return (rAmount, rTransferAmount, rReflection, buyFees.tTransferAmount, buyFees.tLP, buyFees.tMarketing);
    }

    function _getValuesSell(uint256 tAmount, Fee memory currentFee) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        FeeBreakdown memory sellFees;
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

    function setIsExcludedFromFee(address account, bool toggle) external onlyOwner {
        _isExcludedFromFee[account] = toggle;
    }

    function manageWreck(address account, bool isWreck) external onlyOwner {
        wreck[account] = isWreck;
    }

    function setMaxBuyTxLimit(uint256 maxTxLimit) external onlyOwner {
        _maxBuyTxAmount = maxTxLimit;
    }

    function updateSwapLimit(uint256 amount, uint256 maxAmount) external onlyOwner {
        swapLimit = amount;
        maxSwapLimit = maxAmount;
    }    
    
    function setMaxSellTxLimit(uint256 maxTxLimit) external onlyOwner {
        _maxSellTxAmount = maxTxLimit;
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
    
    function updateSwapLimit(uint256 amount) external onlyOwner {
        swapLimit = amount;
    }
    
    function updateSwap(bool _swapEnabled) external onlyOwner {
        swapEnabled = _swapEnabled;
    }
    
    function setFeeReceivers(address payable LPAddress, address payable marketingAddress) external onlyOwner {
        _LPAddress = LPAddress;
        _marketingAddress = marketingAddress;
    }
    
    function transferOtherTokens(address addr, uint amount) external onlyOwner {
        IERC20(addr).transfer(_msgSender(), amount);
    }
}