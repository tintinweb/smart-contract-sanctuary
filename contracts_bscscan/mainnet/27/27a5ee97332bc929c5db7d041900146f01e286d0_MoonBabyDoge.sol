/**
 *Submitted for verification at BscScan.com on 2021-11-07
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// Telegram :  https://t.me/moonbabydoge

/**
 * BEP20 standard interface
 */
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


/**
 * Ownable Contract
 */
abstract contract Ownable {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }


    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

/**
 * Router code
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
 * Contract implementation
 */

contract MoonBabyDoge is IBEP20, Ownable {

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address autoLiquidityReceiver = msg.sender;
    address marketingFeeReceiver = 0x4dcBCc86Fc697a563164016e2423CF0f9922EF1B;

    string constant _name = "MoonBabyDoge";
    string constant _symbol = "MBD";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1 * 10**15 * (10 ** _decimals);
    uint256 public _maxWalletSize = (_totalSupply * 3) / 100; 

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    uint256 liquidityFee;
    uint256 marketingFee;
    uint256 totalFee;
    uint256 feeDenominator = 100;

    uint256 _BUYliquidityFee = 5;
    uint256 _BUYmarketingFee = 5;
    uint256 _BUYtotalFee = 10;

    uint256 _SELLliquidityFee = 15;
    uint256 _SELLmarketingFee = 15;
    uint256 _SELLtotalFee = 30;
    
    IDEXRouter public router;
    address public pair;

    bool public takeFee = false;
    
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000 * 1; // 0.1%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[owner] = true;
        isTxLimitExempt[owner] = true;
        
        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    receive() external payable { }

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
        
        if (recipient != pair && recipient != DEAD) {
            require(isTxLimitExempt[recipient] || _balances[recipient] + amount <= _maxWalletSize, "Transfer amount exceeds the bag size.");
        }
        
        if(shouldSwapBack()){ swapBack(); }

        _balances[sender] = _balances[sender] - (amount);

        takeFee = true;

        if(sender == pair){
            liquidityFee = _BUYliquidityFee;
            marketingFee = _BUYmarketingFee;
            totalFee = _BUYtotalFee;
        }

        if(recipient == pair){
            liquidityFee = _SELLliquidityFee;
            marketingFee = _SELLmarketingFee;
            totalFee = _SELLtotalFee;
        }
        
        if(isFeeExempt[sender] || isFeeExempt[recipient]) {
            takeFee = false;
        }

        if(takeFee){
        uint256 feeAmount = amount * totalFee / feeDenominator;
        
        _balances[address(this)] = _balances[address(this)] + feeAmount;
        
        amount = amount - feeAmount;
        
        emit Transfer(sender, address(this), feeAmount);
        }

        _balances[recipient] = _balances[recipient] + amount;
        
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToLiquify = contractTokenBalance * liquidityFee / totalFee/2;
        uint256 amountToSwap = contractTokenBalance - amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
                
        uint256 amountBNB = address(this).balance - balanceBefore;
        uint256 totalBNBFee = totalFee - (liquidityFee/2);
        uint256 amountBNBLiquidity = amountBNB * liquidityFee / totalBNBFee/2;
        uint256 amountBNBMarketing = amountBNB - amountBNBLiquidity;
        
        (bool MarketingSuccess, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");
        
        addLiquidity(amountToLiquify, amountBNBLiquidity);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    if(tokenAmount > 0){
            router.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(ethAmount, tokenAmount);
        }
    }


   function setMaxWallet(uint256 amount) external onlyOwner() {
        require(amount >= _totalSupply / 1000 );
        _maxWalletSize = amount;
    }    

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }
    
    function setBuyFees(uint256 _liquidityFee, uint256 _marketingFee) external onlyOwner {
        _BUYliquidityFee = _liquidityFee;
        _BUYmarketingFee = _marketingFee;
        _BUYtotalFee = _BUYliquidityFee + _BUYmarketingFee;
    }
    
    function setSellFees(uint256 _liquidityFee, uint256 _marketingFee) external onlyOwner {
        _SELLliquidityFee = _liquidityFee;
        _SELLmarketingFee = _marketingFee;
        _SELLtotalFee = _SELLliquidityFee + _SELLmarketingFee;
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function manualSend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(marketingFeeReceiver).transfer(contractETHBalance);
    }

    function transferStuckToken(address _token) public onlyOwner {
        uint256 _contractBalance = IBEP20(_token).balanceOf(address(this));
        payable(marketingFeeReceiver).transfer(_contractBalance);
    }
    
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}