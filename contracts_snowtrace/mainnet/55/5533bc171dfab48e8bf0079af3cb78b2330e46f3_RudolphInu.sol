/**
 *Submitted for verification at snowtrace.io on 2021-12-16
*/

/**
$Rudolph Inu, rewarding holders in $Rudolph Inu just for holding!
Join our telegram community at -> @RudolphInu_Chat

TOKENOMICS-> 11% tax
1% max transaction
2% max wallet
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

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
    function WAVAX() external pure returns (address);

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

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
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

contract RudolphInu is IBEP20, Ownable {

    // Events
    event AutoLiquify(uint256 amountAVAX, uint256 amountTokens);
    event SetFees(uint256 liquidityFee, uint256 marketingFee, uint256 reflectionFee, uint256 teamFee, uint256 totalFee);
    event SetSwapBackSettings(bool enabled, uint256 swapThreshold);
    event SetIsFeeExempt(address holder, bool enabled);
    event SetFeeReceivers(address marketingReceiver, address teamFeeReceiver);
    event StuckBalanceSent(uint256 amountAVAX, address recipient);
    event SetMaxTx(uint256 maxTX);
    event SetMaxWallet(uint256 maxWallet);
    event MarketingFunds(uint256 amountAVAX, address recipient);
    event TeamFunds(uint256 amountAVAX, address recipient);
    event CanTransferBeforeLaunch(address holder, bool exempt);
    event ForeignTokenTransfer(address tokenAddress, uint256 quantity);

    // Mappings
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private isFeeExempt;
    mapping (address => bool) private isTxLimitExempt;
    mapping (address => bool) private canAddLiquidityBeforeLaunch;

    // Supply
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10 * 10**6 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    // Max Wallet & TX Limits
    uint256 public _maxWalletSize = _tTotal / 100 * 2;
    uint256 public _maxTX = _tTotal / 100 * 1;

    // Basic Contract Info
    string constant _name = 'Rudolph Inu';
    string constant _symbol = 'Rudolph Inu';
    uint8 constant _decimals = 9;
    
    // Detailed Fees
    uint256 private _reflectionFee = 2; 
    uint256 private _marketingFee = 4; 
    uint256 private _liquidityFee = 3;
    uint256 private _teamFee = 2;

    uint256 private totalFees = _marketingFee + _reflectionFee + _liquidityFee + _teamFee;
    uint256 private contractFees = _marketingFee + _liquidityFee + _teamFee;

    uint256 private _previousReflectionFee = _reflectionFee;
    uint256 private _previousMarketingFee = _marketingFee;
    uint256 private _previousliquidityFee = _liquidityFee;
    uint256 private _previousteamFee = _teamFee;

    // Fee Receiver
    address private marketingFeeReceiver = 0x922176271a5469D11f7F7C1a5A51fF75188d5379;
    address private teamFeeReceiver = 0x4f4c3962A60b6aD611aF4B3BaA97c240b695137B;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _tTotal / 1000 * 1; // 0.1% 
    
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    
    constructor () Ownable(msg.sender) {
        router = IDEXRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4); 
        pair = IDEXFactory(router.factory()).createPair(address(this), router.WAVAX());
        _allowances[address(this)][address(router)] = type(uint256).max;
        
        isFeeExempt[owner] = true;
        isTxLimitExempt[owner] = true;
        canAddLiquidityBeforeLaunch[owner] = true;
        
        _balances[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    receive() external payable {}
     
    // Basic Functions
    function name() external pure override returns (string memory) { return _name; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function getOwner() external view override returns (address) { return owner; }
    function totalSupply() external view override returns (uint256) { return _tTotal; }
    function balanceOf(address account) public view override returns (uint256) { return tokenFromReflection(_balances[account]);}
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
        _approve(sender, msg.sender, _allowances[sender][msg.sender]- (amount));
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / (currentRate);
    }

    // Internal Functions
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!launched() && recipient == pair){
            require(canAddLiquidityBeforeLaunch[sender]);
            launch(); 
        }

        checkTxLimit(sender, amount);

        if (recipient != pair &&
            recipient != owner) {
            require(isTxLimitExempt[recipient] || tokenFromReflection(_balances[recipient]) + amount <= _maxWalletSize, "Transfer amount exceeds the bag size.");
        }
        
        if(shouldSwapBack()){ swapBack(); }
        
        _tokenTransfer(sender,recipient,amount);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if(!shouldTakeFee(sender) || !shouldTakeFee(recipient)) removeAllFee();
            _transferStandard(sender, recipient, amount);
        if(!shouldTakeFee(sender) || !shouldTakeFee(recipient)) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tFees) = _getValues(tAmount);
        _balances[sender] = _balances[sender] - (rAmount);
        _balances[recipient] = _balances[recipient] + (rTransferAmount); 
        _takeFees(tFees, rReflection); 
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _takeFees(uint256 tFees, uint256 rReflection) private {
        _rTotal = _rTotal - (rReflection);
        uint256 currentRate =  _getRate();
        uint256 rFees = tFees * (currentRate);
        _balances[address(this)] = _balances[address(this)] + (rFees);
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTX || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function removeAllFee() private {
        if(_reflectionFee == 0 && _marketingFee == 0 && _liquidityFee == 0) return;
        
        _previousReflectionFee = _reflectionFee;
        _previousMarketingFee = _marketingFee;
        _previousliquidityFee = _liquidityFee;
        _previousteamFee = _teamFee;
        
        _reflectionFee = 0;
        _marketingFee = 0;
        _liquidityFee = 0;
        _teamFee = 0;
        contractFees = _marketingFee + _liquidityFee + _teamFee;
    }

    function restoreAllFee() private {
        _reflectionFee = _previousReflectionFee;
        _teamFee = _previousteamFee;
        _marketingFee = _previousMarketingFee;
        _liquidityFee = _previousliquidityFee;
        contractFees = _marketingFee + _liquidityFee + _teamFee;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function swapBack() internal swapping {       
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToLiquify = contractTokenBalance * _liquidityFee / contractFees / (2);
        uint256 amountToSwap = contractTokenBalance - amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WAVAX();

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountAVAX = address(this).balance;
        uint256 totalAVAXFee = contractFees - (_liquidityFee / (2));
        uint256 amountAVAXLiquidity = amountAVAX * _liquidityFee / totalAVAXFee / (2);
        uint256 amountAVAXMarketing = amountAVAX * _marketingFee / totalAVAXFee;
        uint256 amountAVAXTeam = amountAVAX - amountAVAXMarketing - amountAVAXLiquidity;

        if(amountAVAXMarketing > 0) {payable(marketingFeeReceiver).transfer(amountAVAXMarketing);
            emit MarketingFunds(amountAVAXMarketing, marketingFeeReceiver);
        }
        if(amountAVAXTeam > 0) {payable(teamFeeReceiver).transfer(amountAVAXTeam);
            emit TeamFunds(amountAVAXTeam, teamFeeReceiver);
        }

        if(amountToLiquify > 0){
            router.addLiquidityAVAX{value: amountAVAXLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                marketingFeeReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountAVAXLiquidity, amountToLiquify);
        }
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.timestamp;
    }
    
    // Reflections code
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tReflection, uint256 tFees) = _calculateTokenValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection) = _calculateRateValues(tAmount, tReflection, tFees, currentRate);
        return (rAmount, rTransferAmount, rReflection, tTransferAmount, tFees);
    }
    
    function _calculateTokenValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 feeAmount = tAmount * (totalFees) / 100;
        uint256 tReflection = feeAmount * (_reflectionFee) / totalFees;
        uint256 tFees = feeAmount * (contractFees) / totalFees;
        uint256 tTransferAmount = tAmount - tReflection - tFees;
        return (tTransferAmount, tReflection, tFees);
    }
    
    function _calculateRateValues(uint256 tAmount, uint256 tReflection, uint256 tFees, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * (currentRate);
        uint256 rReflection = tReflection * (currentRate);
        uint256 rFees = tFees * (currentRate);
        uint256 rTransferAmount = rAmount - (rReflection) - (rFees);
        return (rAmount, rTransferAmount, rReflection);
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

    // External Functions
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        emit SetIsFeeExempt(holder, exempt);
    }

    function setFees(uint256 liquidityFee, uint256 marketingFee, uint256 reflectionFee, uint256 teamFee) external onlyOwner {
        require(liquidityFee + marketingFee + reflectionFee + teamFee < 33, "Total fees must be below 33%");
        _liquidityFee = liquidityFee;
        _marketingFee = marketingFee;
        _reflectionFee = reflectionFee;
        _teamFee = teamFee;
        totalFees = _liquidityFee + _marketingFee + _reflectionFee + _teamFee;
        contractFees = _liquidityFee + _marketingFee + _teamFee;
        emit SetFees(_liquidityFee, _marketingFee, _reflectionFee, _teamFee, totalFees);
    }

    function setFeeReceiver(address _marketingFeeReceiver, address _teamFeeReceiver) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
        teamFeeReceiver = _teamFeeReceiver;
        emit SetFeeReceivers(marketingFeeReceiver, teamFeeReceiver);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Can't set SwapThreshold to ZERO");
        swapEnabled = _enabled;
        swapThreshold = _amount;
        emit SetSwapBackSettings(swapEnabled, swapThreshold);
    }

    function setMaxTx(uint256 maxTX) external onlyOwner {
        require(maxTX > _tTotal / 1000, "Can't set maxTX below 0.1%");
        _maxTX = maxTX;
        emit SetMaxTx(maxTX);
    }

    function setMaxWallet(uint256 maxWallet) external onlyOwner {
        require(maxWallet > _tTotal / 1000, "Can't set maxTX below 0.1%");
        _maxWalletSize = maxWallet;
        emit SetMaxWallet(maxWallet);
    }

    function setCanTransferBeforeLaunch(address holder, bool exempt) external onlyOwner {
        canAddLiquidityBeforeLaunch[holder] = exempt; //Presale Address will be added as Exempt
        isFeeExempt[holder] = exempt;
        isTxLimitExempt[holder] = exempt;
        emit CanTransferBeforeLaunch(holder, exempt);
    }

    // Stuck Balance Functions
    function ClearStuckBalance() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        payable(marketingFeeReceiver).transfer(contractBalance);
        emit StuckBalanceSent(contractBalance, marketingFeeReceiver);
    }

    function transferForeignToken(address _token) public onlyOwner {
        uint256 _contractBalance = IBEP20(_token).balanceOf(address(this));
        payable(marketingFeeReceiver).transfer(_contractBalance);
        emit ForeignTokenTransfer(_token, _contractBalance);
    }
}