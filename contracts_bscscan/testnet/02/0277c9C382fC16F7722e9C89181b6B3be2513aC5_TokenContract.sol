/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address internal owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!YOU ARE NOT THE OWNER"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function OwnershipLock(uint256 time) public virtual onlyOwner {
        _previousOwner = owner;
        owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(owner, address(0));
    }

    function OwnershipUnlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked");
        emit OwnershipTransferred(owner, _previousOwner);
        owner = _previousOwner;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

contract TokenContract is IBEP20, Ownable {
        
    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
    event SetSwapBackSettings(bool enabled, uint256 swapThreshold);
    event SetFeeReceivers(address marketingReceiver);
    event StuckBalanceSent(uint256 amountBNB, address recipient);
    event ForeignTokenTransfer(address tokenAddress, uint256 quantity);
    event ExcludeFromFee(address Address, bool Excluded);
    event SetFees(uint256 liquidityFee, uint256 marketingFee, uint256 reflectFee);

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1 * 10**9 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    
    string private constant _name = "NAME";
    string private constant _symbol = "SYMBOL";
    uint8 private constant _decimals = 9;

    IDEXRouter public router;
    address public pair;

    uint256 public _liquidityFee = 2;
    uint256 public _marketingFee = 2;
    uint256 public _taxFee = 3;

    uint256 _previousTaxFee;
    uint256 _previousLiquidityFee;
    uint256 _previousMarketingFee;

    uint256 private _tFeeTotal;  
    
    address public marketingFeeReceiver = msg.sender;

    bool inSwap;
    bool public swapEnabled = true;
    uint256 public swapThreshold = _tTotal / 1000 * 3; // 0.3%

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor () Ownable(msg.sender) {
        router = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        pair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());
        _allowances[address(this)][address(router)] = type(uint256).max;

        _isExcludedFromFee[owner] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingFeeReceiver] = true;

        _rOwned[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function name() external pure override returns (string memory) { return _name; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function getOwner() external view override returns (address) { return owner; }
    function totalSupply() external pure override returns (uint256) { return _tTotal; }
    function balanceOf(address account) public view returns (uint256) { return tokenFromReflection(_rOwned[account]);}

    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender]-(amount));
        return true;
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / (currentRate);
    }

    receive() external payable {}

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;}

        if(shouldSwapBack()){ swapBack(); }

        _tokenTransfer(sender, recipient, amount, takeFee);
        
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();
            _transferStandard(sender, recipient, amount);
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeFees(tLiquidity, tMarketing, rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeFees(uint256 tLiquidity, uint256 tMarketing, uint256 rFee, uint256 tFee) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity * (currentRate);
        uint256 rMarketing = tMarketing * (currentRate);
        _rOwned[address(this)] = _rOwned[address(this)] + (rLiquidity) + (rMarketing);
        _rTotal = _rTotal - (rFee);
        _tFeeTotal = _tFeeTotal + (tFee);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && balanceOf(address(this)) >= swapThreshold;
    }

    function swapBack() internal swapping {       
        uint256 totalFee = _marketingFee + _liquidityFee;
        uint256 contractTokenBalance = balanceOf(address(this));

        uint256 amountToLiquify = contractTokenBalance * _liquidityFee / totalFee / (2);
        uint256 amountToSwap = contractTokenBalance - amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountBNB = address(this).balance;
        uint256 totalBNBFee = totalFee - (_liquidityFee / (2));
        uint256 amountBNBLiquidity = amountBNB * _liquidityFee / totalBNBFee / (2);
        uint256 amountBNBMarketing = amountBNB - amountBNBLiquidity;

        if(amountBNBMarketing > 0) {payable(marketingFeeReceiver).transfer(amountBNBMarketing);
        }

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                marketingFeeReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _calculateTokenValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _calculateRateValues(tAmount, tFee, tLiquidity, tMarketing, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tMarketing);
    }

    function _calculateTokenValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = tAmount * (_taxFee) / (10**2);
        uint256 tLiquidity = tAmount * (_liquidityFee) / (10**2);
        uint256 tMarketing = tAmount * (_marketingFee) / (10**2);
        uint256 tTransferAmount = tAmount - (tFee) - (tLiquidity) - (tMarketing);
        return (tTransferAmount, tFee, tLiquidity, tMarketing);
    }

    function _calculateRateValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * (currentRate);
        uint256 rFee = tFee * (currentRate);
        uint256 rLiquidity = tLiquidity * (currentRate);
        uint256 rMarketing = tMarketing * (currentRate);
        uint256 rTransferAmount = rAmount - (rFee) - (rLiquidity) - (rMarketing);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / (tSupply);
    }
    
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        if (rSupply < _rTotal / (_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0 && _marketingFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _marketingFee;

        _taxFee = 0;
        _liquidityFee = 0;
        _marketingFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
    }

    function excludeFromFee(address account, bool exempt) external onlyOwner {
        _isExcludedFromFee[account] = exempt;
        emit ExcludeFromFee(account, exempt);
    }

    function setSwapBackSettings(bool _enabled, uint256 _swapThreshold) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _swapThreshold;
        emit SetSwapBackSettings(_enabled, swapThreshold);
    }

    function setFeeReceiver(address _marketingFeeReceiver) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
        emit SetFeeReceivers(marketingFeeReceiver);
    }

    function setFees(uint16 liq, uint16 market, uint16 tax) external onlyOwner {
        require(liq + market + tax <= 30, "Total fees must be below 30%");
        _liquidityFee = liq;
        _marketingFee = market;
        _taxFee = tax;
        emit SetFees(liq,market,tax);
    }
    
    function ClearStuckBalance() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        payable(marketingFeeReceiver).transfer(contractBalance);
        emit StuckBalanceSent(contractBalance, marketingFeeReceiver);
    }

    function transferForeignToken(address _token) public onlyOwner {
        require(_token != address(this), "Can't let you take all native token");
        uint256 _contractBalance = IBEP20(_token).balanceOf(address(this));
        payable(marketingFeeReceiver).transfer(_contractBalance);
        emit ForeignTokenTransfer(_token, _contractBalance);
    }
}