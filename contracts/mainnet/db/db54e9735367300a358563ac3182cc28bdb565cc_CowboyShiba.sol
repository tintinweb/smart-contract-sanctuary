/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

/*
Submitted for verification at Etherscan.io on 2021-06-09

https://cowboyshiba.com

Tokenomics @ Launch:
1. 1,000,000,000,000 Total Supply
2. 20% - Burned
3. 3% - Marketing
4. 2.5% - Dev
5. 1% - Charity
6. 2% - AirDrops
7. 71.5% - Liquidity Locked Forever
8. 0.3% Buy Limit (until lifted)
9. Ownership Renounced

Tokenomics Taxation:
1. Sells limited to 2% of the Liquidity Pool, <1.9% price impact 
2. 3% - Pool
3. 2% - Redistribution sent to all holders for all buys
4. 2% - Marketing
5. 1% - Charity
6. 1% - Burned

SPDX-License-Identifier: MIT
*/

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
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
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

contract CowboyShiba is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "Cowboy Shiba";
    string private constant _symbol = "CBSHIB";
    uint8 private constant _decimals = 9;
    mapping(address => bool) private bots;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private  _tTotal = 1000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _dynamicFee = 3; //value used as "pool_fee", "marketing_fee" "tax_fee", "charity_fee", "burn_fee" respectfully using safemath in functions
    mapping(address => uint256) private buycooldown;
    address private _devAddress;
    address private _marketingAddress;
    address private _charityAddress;
    address private _burnAddress;
    address private _poolAddress;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    bool private liquidityAdded = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private _maxTxPct = 3;
    event MaxTxPctUpdated(uint256 _maxTxPct);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor () {
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
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

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    
    function removeAllFee() private {
        if (_dynamicFee == 0) return;
        _dynamicFee = 0;
    }

    function restoreAllFee() private {
        _dynamicFee = 3;
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
            require(!bots[from] && !bots[to]);
            uint256 maxTxAmount = _tTotal.mul(_maxTxPct).div(10**3);
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(tradingOpen);
                require(amount <= maxTxAmount);
                require(buycooldown[to] < block.timestamp);
                buycooldown[to] = block.timestamp + (30 seconds);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                require(amount <= balanceOf(uniswapV2Pair).mul(2).div(100));
                if (from != address(this) && to != address(this) && contractTokenBalance > 0) {
                    if (_msgSender() == address(uniswapV2Router) || _msgSender() == uniswapV2Pair) {
                        swapTokensForEth(contractTokenBalance);
                    }
                }
            }
        }
        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
        restoreAllFee;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
    
    function openTrading() public onlyOwner {
        require(liquidityAdded);
        tradingOpen = true;
    }
    
    function maxTxAmount() public view returns (uint256) {
       return _tTotal.mul(_maxTxPct).div(10**3);
    }
    
    function isMarketing(address account) public view returns (bool) {
        return account == _marketingAddress;
    }
    function isDev(address account) public view returns (bool) {
        return account == _devAddress;
    }
    function isCharity(address account) public view returns (bool) {
        return account == _charityAddress;
    }
    function isPool(address account) public view returns (bool) {
        return account == _poolAddress;
    }
    
    function setBotAddress(address account) external onlyOwner() {
        require(!bots[account], "Account is already identified as a bot");
        bots[account] = true;
    }
    function revertSetBotAddress(address account) external onlyOwner() {
        require(bots[account], "Account is not identified as a bot");
        bots[account] = false;
    }
    
    function setCharityAddress(address charityAddress) external onlyOwner {
        _isExcludedFromFee[_charityAddress] = false;
        _charityAddress = charityAddress;
        _isExcludedFromFee[_charityAddress] = true;
    }

    function setBurnAddress(address burnAddress) external onlyOwner {
        _isExcludedFromFee[_burnAddress] = false;
        _burnAddress = burnAddress;
        _isExcludedFromFee[_burnAddress] = true;
    }
    
    function setDevAddress(address devAddress) external onlyOwner {
        _isExcludedFromFee[_devAddress] = false;
        _devAddress = devAddress;
        _isExcludedFromFee[_devAddress] = true;
    }
    
    function setMarketingAddress(address marketingAddress) external onlyOwner {
        _isExcludedFromFee[_marketingAddress] = false;
        _marketingAddress = marketingAddress;
        _isExcludedFromFee[_marketingAddress] = true;
    }
    
    function setPoolAddress(address poolAddress) external onlyOwner {
        _isExcludedFromFee[_poolAddress] = false;
        _poolAddress = poolAddress;
        _isExcludedFromFee[_poolAddress] = true;
    }

    function addLiquidity() external onlyOwner() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        liquidityAdded = true;
        _maxTxPct = 3;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
    }

    function manualswap() external {
        require(_msgSender() == owner());
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tDynamic) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _transferFees(sender, tDynamic);
        _reflectFee(rFee, tDynamic);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFees(address sender, uint256 tDynamic) private {
        uint256 currentRate = _getRate();
        
        if (tDynamic == 0) return;
            
        uint256 tDynamicOneThird = tDynamic.div(3);
        
        uint256 tMarketing = tDynamic.sub(tDynamicOneThird);
        uint256 rMarketing = tMarketing.mul(currentRate);
        _tOwned[_marketingAddress] = _tOwned[_marketingAddress].add(tMarketing);
        _rOwned[_marketingAddress] = _rOwned[_marketingAddress].add(rMarketing);
        emit Transfer(sender, _marketingAddress, tMarketing);
        
        uint256 tCharity = tDynamic.sub(tDynamicOneThird).sub(tDynamicOneThird);
        uint256 rCharity = tCharity.mul(currentRate);
        _tOwned[_charityAddress] = _tOwned[_charityAddress].add(tCharity);
        _rOwned[_charityAddress] = _rOwned[_charityAddress].add(rCharity);
        emit Transfer(sender, _charityAddress, tCharity);
        
        uint256 rPool = tDynamic.mul(currentRate); // tDynamic == tPool == 3%
        _tOwned[_poolAddress] = _tOwned[_poolAddress].add(tDynamic);
        _rOwned[_poolAddress] = _rOwned[_poolAddress].add(rPool);
        emit Transfer(sender, _poolAddress, tDynamic);
        
        uint256 rBurn = rCharity;
        _tOwned[_burnAddress] = _tOwned[_burnAddress].add(tCharity);
        _rOwned[_burnAddress] = _rOwned[_burnAddress].add(rBurn);
        emit Transfer(sender, _burnAddress, tCharity); // tCharity == tBurn == 1%
        
    }
    
    function _reflectFee(uint256 rFee, uint256 tDynamic) private {
        _rTotal = _rTotal.sub(rFee);
        
        if (tDynamic != 0)
            _tFeeTotal = _tFeeTotal.add(tDynamic.sub(tDynamic.div(3)));
    }

    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tDynamic) = _getTValues(tAmount, _dynamicFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rDynamic) = _getRValues(tAmount, tDynamic, currentRate);
        return (rAmount, rTransferAmount, rDynamic, tTransferAmount, tDynamic);
    }

    function _getTValues(uint256 tAmount, uint256 dynamicFee) private pure returns (uint256, uint256) {
        if (dynamicFee == 0)
            return (tAmount, dynamicFee);
        uint256 tDynamic = tAmount.mul(dynamicFee).div(100);
        uint256 tTransferAmount = tAmount
        .sub(tDynamic)  //pool fee
        .sub(tDynamic)  //charity + marketing
        .sub(tDynamic); //burn + redistribution
        return (tTransferAmount, tDynamic);
    }

    function _getRValues(uint256 tAmount, uint256 tDynamic, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        
        if (tDynamic == 0)
            return (rAmount, rAmount, tDynamic);
        uint256 rDynamic = tDynamic.mul(currentRate);
        uint256 rTransferAmount = rAmount
        .sub(rDynamic) //pool fee
        .sub(rDynamic)  //charity + marketing
        .sub(rDynamic); //burn + redistribution
        return (rAmount, rTransferAmount, rDynamic);
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

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _maxTxPct = maxTxPercent * 10;
        emit MaxTxPctUpdated(_maxTxPct);
    }
}