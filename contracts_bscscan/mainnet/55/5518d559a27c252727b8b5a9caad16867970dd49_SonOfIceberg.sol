/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

/**
	
 Telegram : https://t.me/sonoficeberg
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * BEP20 standard interface
 */

interface BEP20 {
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

/**
 * Basic access control mechanism
 */

abstract contract Ownable {
    address internal owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
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

    function Ownershiplock(uint256 time) public virtual onlyOwner {
        _previousOwner = owner;
        owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(owner, address(0));
    }

    function Ownershipunlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(owner, _previousOwner);
        owner = _previousOwner;
    }
}

/**
 * Router Interfaces
 */

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

/**
 * Contract Code
 */

contract SonOfIceberg is BEP20, Ownable {

    // Events
    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
    event SetMaxWallet(uint256 maxWalletToken);
    event SetMaxTxAmount(uint256 maxTxAmount);
    event SetBuyFees(uint256 liquidityFee, uint256 marketingFee, uint256 buybackFee, uint256 totalFee);
    event SetSellFees(uint256 liquidityFee, uint256 marketingFee, uint256 buybackFee, uint256 totalFee);
    event SetSwapBackSettings(bool enabled, uint256 swapThreshold);
    event SetTargetLiquidity(uint256 PercentageLiquidity);
    event SetIsFeeExempt(address holder, bool enabled);
    event SetIsTxLimitExempt(address holder, bool enabled);
    event SetFeeReceivers(address marketingReceiver, address buybackFeeReceiver);
    event StuckBalanceSent(uint256 amountBNB, address recipient);
    event ForeignTokenTransfer(address tokenAddress, uint256 quantity);

    // Mappings
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    // Basic Contract Info
    string constant _name = "SonOfIceberg";
    string constant _symbol = "SOI";
    uint8 constant _decimals = 9;

    // Supply
    uint256 _totalSupply = 10000000 * (10 ** _decimals); // 10,000,000 Tokens
    uint256 _burntSupply = (_totalSupply * 50) /100;
    uint256 _liqSupply = (_totalSupply - _burntSupply);

    // Max wallet
    uint256 public _maxWalletSize = (_totalSupply * 2) / 100;  // 2% MaxWallet - 200,000 Tokens
    uint256 public _maxTxAmount = (_totalSupply * 1) / 100;  // 1% Max Transaction - 100,000 Tokens  

    // Detailed Fees
    uint256 liquidityFee;
    uint256 marketingFee;
    uint256 buybackFee;
    uint256 totalFee;

    uint256 _buyLiquidityFee = 3;
    uint256 _buyMarketingFee = 8;
    uint256 _buyBuybackFee = 5;
    uint256 _buyTotalFee = _buyLiquidityFee + _buyBuybackFee + _buyMarketingFee;

    uint256 _initialSellLiquidityFee = 5;
    uint256 _initialSellMarketingFee = 15;
    uint256 _initialSellBuybackFee = 10;
    uint256 _initialSellTotalFee = _initialSellBuybackFee + _initialSellMarketingFee + _initialSellLiquidityFee;

    uint256 public _sellLiquidityFee;
    uint256 public _sellMarketingFee;
    uint256 public _sellBuybackFee;
    uint256 public _sellTotalFee; 
    
    // Fee receivers
    address private marketingFeeReceiver = 0x0417a000B894A9c4D6Bf207CD94dCBaE6B4c72Bc;
    address private buybackFeeReceiver = 0x0417a000B894A9c4D6Bf207CD94dCBaE6B4c72Bc;
    address constant private DEAD = 0x000000000000000000000000000000000000dEaD;

    // Dynamic Liquidity Fee
    uint256 targetLiquidity = 25;

    // Router
    IDEXRouter public router;
    address public pair;
    
    uint256 public launchedAt;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000 * 1; // 0.1% 

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E  );
        pair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());
        _allowances[address(this)][address(router)] = type(uint256).max;
        
        address _owner = owner;
        address _DEAD = DEAD;

        isFeeExempt[_owner] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isFeeExempt[buybackFeeReceiver] = true;

        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[buybackFeeReceiver] = true;

        _balances[_owner] = _liqSupply;
        _balances[_DEAD] = _burntSupply;
        emit Transfer(address(0), _owner, _liqSupply);
        emit Transfer(address(0), _DEAD, _burntSupply);
    }

    receive() external payable { }

    // Basic Internal Functions

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - (amount);
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        // Checks max transaction limit and actual sell fees
        getActualSellFee();
        checkTxLimit(sender, amount);

        if (sender != owner &&
            recipient != owner &&
            recipient != pair) {
            
            require(isTxLimitExempt[recipient] || _balances[recipient] + amount <= _maxWalletSize, "Transfer amount exceeds the MaxWallet size.");
        }

        // Buy Taxes
            if(sender == pair){
                liquidityFee = _buyLiquidityFee;
                marketingFee = _buyMarketingFee;
                buybackFee = _buyBuybackFee;
                totalFee = _buyTotalFee;
            }

        // Sell Taxes
            if(recipient == pair){
                liquidityFee = _sellLiquidityFee;
                marketingFee = _sellMarketingFee;
                buybackFee = _sellBuybackFee;
                totalFee = _sellTotalFee;
            }
        
        //Exchange tokens
        if(shouldSwapBack()){ swapBack(); }

        if(!launched() && recipient == pair){ require(_balances[sender] > 0); launch(); }

        _balances[sender] = _balances[sender] - amount;

        //Check if should Take Fee
        uint256 amountReceived = (!shouldTakeFee(sender) || !shouldTakeFee(recipient)) ? amount : takeFee(sender, amount);
        _balances[recipient] = _balances[recipient] + (amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Internal Functions

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getActualSellFee() internal {
        uint256 days_since_start = (block.timestamp - launchedAt) / 1 days;
        if(days_since_start > 0 &&
           days_since_start < 10) {
            _sellLiquidityFee = _initialSellLiquidityFee;
            _sellBuybackFee = _initialSellBuybackFee - days_since_start;
            _sellMarketingFee = _initialSellMarketingFee - days_since_start;
            _sellTotalFee = _sellMarketingFee + _sellLiquidityFee + _sellBuybackFee;
        }
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = (amount * totalFee) / 100;
        
        _balances[address(this)] = _balances[address(this)] + (feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount - (feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {       
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, 100) ? 0 : liquidityFee;
        uint256 amountToLiquify = contractTokenBalance * dynamicLiquidityFee / totalFee / (2);
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
        uint256 totalBNBFee = totalFee - (dynamicLiquidityFee / (2));
        uint256 amountBNBLiquidity = amountBNB * dynamicLiquidityFee / totalBNBFee / (2);
        uint256 amountBNBMarketing = amountBNB * marketingFee / totalBNBFee;
        uint256 amountBNBbuyback = amountBNB - amountBNBLiquidity - amountBNBMarketing;

        (bool MarketingSuccess, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected BNB transfer");
        (bool buybackSuccess, /* bytes memory data */) = payable(buybackFeeReceiver).call{value: amountBNBbuyback, gas: 30000}("");
        require(buybackSuccess, "receiver rejected BNB transfer");

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

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.timestamp;
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy * (balanceOf(pair) * (2)) / (_liqSupply);
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    // External Functions

    function setMaxWallet(uint256 percentageBase100) external onlyOwner {
        uint256 percentage = _totalSupply * percentageBase100 / 100;
        require(percentage >= _totalSupply / 100, "Can't set MaxWallet below 1%" );
        _maxWalletSize = percentage;
        emit SetMaxWallet(_maxWalletSize);
    }

    function setMaxTx(uint256 percentageBase1000) external onlyOwner {
        uint256 percentage = _totalSupply * percentageBase1000 / 1000;
        require(percentage >= _totalSupply / 1000, "Can't set MaxTX below 0.1%" );
        _maxTxAmount = percentage;
        emit SetMaxTxAmount(_maxTxAmount);
    }

    function setTargetLiquidity(uint256 _target) external onlyOwner {
        targetLiquidity = _target;
        emit SetTargetLiquidity(_target);
    }    

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        emit SetIsFeeExempt(holder, exempt);
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
        emit SetIsTxLimitExempt(holder, exempt);
    }

    function setBuyFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _buybackFee) external onlyOwner {
        require(_liquidityFee + _marketingFee + _buybackFee < 33, "Total fees must be below 33%");
        _buyLiquidityFee = _liquidityFee;
        _buyMarketingFee = _marketingFee;
        _buyBuybackFee = _buybackFee;
        _buyTotalFee = _liquidityFee + _marketingFee + _buybackFee;
        emit SetBuyFees(_liquidityFee, _marketingFee, _buybackFee, totalFee);
    }

    function setSellFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _buybackFee) external onlyOwner {
        require(_liquidityFee + _marketingFee + _buybackFee < 33, "Total fees must be below 33%");
        _sellLiquidityFee = _liquidityFee;
        _sellMarketingFee = _marketingFee;
        _sellBuybackFee = _buybackFee;
        _sellTotalFee = _liquidityFee + _marketingFee + _buybackFee;
        emit SetSellFees(_liquidityFee, _marketingFee, _buybackFee, totalFee);
    }

    function setFeeReceiver(address _marketingFeeReceiver, address _buybackFeeReceiver) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
        buybackFeeReceiver = _buybackFeeReceiver;
        emit SetFeeReceivers(marketingFeeReceiver, buybackFeeReceiver);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Can't set SwapThreshold to ZERO");
        swapEnabled = _enabled;
        swapThreshold = _amount;
        emit SetSwapBackSettings(swapEnabled, swapThreshold);
    }

    // Stuck Balance Function

    function ClearStuckBalance() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(marketingFeeReceiver).transfer(contractETHBalance);
        emit StuckBalanceSent(contractETHBalance, marketingFeeReceiver);
    }

    function transferForeignToken(address _token) public onlyOwner {
        uint256 _contractBalance = BEP20(_token).balanceOf(address(this));
        payable(marketingFeeReceiver).transfer(_contractBalance);
        emit ForeignTokenTransfer(_token, _contractBalance);
    }
}