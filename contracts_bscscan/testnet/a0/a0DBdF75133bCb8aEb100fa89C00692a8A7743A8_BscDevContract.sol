/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

// SPDX-License-Identifier: MIT

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
        emit OwnershipTransferred(address(0), _owner);
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

    function geUnlockTime() public view returns (uint256) {
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

interface ILocker {
    function lockTokens(uint256 _amount, uint256 _daysLocked) external payable;
    function withdrawTokens() external payable;
    function extendLock(uint256 _extendLockTime) external;
}

contract Locker is ILocker {
    
    address tokenAddress;
    address withdrawalAddress;
    uint256 day = 86400;
    uint256 tokenAmount;
    uint256 unlockTime;
    uint256 addDays;
    bool withdrawn;

    modifier onlyToken() {
        require(msg.sender == tokenAddress); _;
    }
    
    mapping(address => mapping(address => uint256)) public walletTokenBalance;

    event TokensLocked(address indexed tokenAddress, address indexed sender, uint256 amount, uint256 unlockTime);
    event TokensWithdrawn(address indexed tokenAddress, address indexed receiver, uint256 amount);

    constructor () {
        tokenAddress = msg.sender;
    }

    function lockTokens(uint256 _amount, uint256 _daysLocked) external payable override onlyToken {
        unlockTime = block.timestamp + (_daysLocked * day);
        require(_amount > 0, 'Tokens amount must be greater than 0');
        require(_daysLocked > 0, 'Days locked must be greater than 0');
        require(unlockTime > block.timestamp, 'Unlock time must be in future');

        require(IBEP20(tokenAddress).approve(address(this), _amount), 'Failed to approve tokens');
        require(IBEP20(tokenAddress).transferFrom(msg.sender, address(this), _amount), 'Failed to transfer tokens to locker');
        
        walletTokenBalance[tokenAddress][msg.sender] = walletTokenBalance[tokenAddress][msg.sender] + (_amount);

        emit TokensLocked(tokenAddress, msg.sender, _amount, unlockTime);
    }

    function withdrawTokens() external payable override onlyToken {
        require(block.timestamp >= unlockTime, 'Tokens are locked');
        require(!withdrawn, 'Tokens already withdrawn');

        uint256 amount = tokenAmount;

        require(IBEP20(tokenAddress).transfer(msg.sender, amount), 'Failed to transfer tokens');

        withdrawn = true;
        uint256 previousBalance = walletTokenBalance[tokenAddress][msg.sender];
        walletTokenBalance[tokenAddress][msg.sender] = previousBalance - (amount);

        emit TokensWithdrawn(tokenAddress, msg.sender, amount);
    }

    function extendLock(uint256 _extendLockTime) external onlyToken {
        addDays = _extendLockTime * day;
        require(addDays > 0 , "Cannot set an unlock time in past!");
        unlockTime = unlockTime + addDays;
    }

    function getLockedTokenBalance() view public returns (uint256){
        return IBEP20(tokenAddress).balanceOf(address(this));
    }

    function getDaysUntilUnlock() view public returns (uint256){
        return ((block.timestamp - unlockTime) / day);
    }

    function getTimeInSecondsUntilUnlock() view public returns (uint256){
        return (block.timestamp - unlockTime);
    }
}


contract BscDevContract is IBEP20, Ownable {

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address PRIZE = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    
    address public autoLiquidityReceiver = DEAD;
    address public marketingFeeReceiver = msg.sender; // TO DO
    address public devFeeReceiver = msg.sender; // TO DO
    address public teamWallet = msg.sender; // TO DO
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public canAddLiquidity;

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
    event SwapBNBForPRIZE(uint256 amountIn, address[] path);
    event SetPrizeToken(address indexed token);
    event SetSwapBackSettings(uint256 swapThresholdMax, uint256 swapThreshold);
    event SetSwapBackEnabled(bool enabled);
    event SetFees(uint256 liquidityFee, uint256 prizeFee, uint256 marketingFee, uint256 devFee);
    event SetIsFeeExempt(address holder, bool enabled);
    event SetIsTxLimitExempt(address holder, bool enabled);
    event SetPresaleAddress(address holder);
    event SetMaxWallet(uint256 maxWalletToken);
    event SetMaxTx(uint256 maxTxAmount);
    event EnabledPrize(bool enabled);
    event ClaimedPrize(bool enabled);
    
    string constant _name = "Name"; // TO DO
    string constant _symbol = "Symbol"; // TO DO
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 10**9 * 10**_decimals; // 1,000,000,000
    uint256 public swapThreshold = _totalSupply / 10000 * 5; // 0,05%
    uint256 public swapThresholdMax = _totalSupply / 1000 * 5; // 0,5%

    uint256 public liquidityFee = 3;
    uint256 public prizeFee     = 5;
    uint256 public marketingFee = 5;
    uint256 public devFee       = 2;
    uint256 public totalFee     = marketingFee + prizeFee + liquidityFee + devFee;

    uint256 public minimumTokensClaim = _totalSupply / 1000 * 5; // 0,5% - 5,000,000

    IDEXRouter public router;
    address public pair;
    Locker public locker;
    
    uint256 public launchedAt;

    bool public canClaimPrize = false;
    bool public swapEnabled = true;
    bool public claimedPrize;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    modifier onlyTeam() {
        require(msg.sender == teamWallet); _;    }

    uint256 public maxTxAmount = _totalSupply / 100 * 2;
    uint256 public maxWalletToken = _totalSupply / 100 * 3;
  
    constructor () Ownable(msg.sender) {
        router = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        locker = new Locker();

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
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
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(!launched() && recipient == pair){ require(canAddLiquidity[sender]); launch(); }

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if (sender != owner &&
            recipient != owner &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != pair){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
            }
        
        checkTxLimit(sender, amount);

        if(shouldSwapBack()){ swapBack(); }

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = (!shouldTakeFee(sender) || !shouldTakeFee(recipient)) ? amount : takeFee(sender, amount);
        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
      
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount / 100 * totalFee;

        _balances[address(this)] = _balances[address(this)] + feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 tokensToSell = balanceOf(address(this));
        if (tokensToSell >= swapThresholdMax){
            tokensToSell = swapThresholdMax;
        }

        uint256 amountToLiquify = tokensToSell / totalFee * liquidityFee/2;
        uint256 amountToSwap = tokensToSell - amountToLiquify;

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

        uint256 totalBNBFee = totalFee - liquidityFee/2;
        
        uint256 amountBNBLiquidity = amountBNB * liquidityFee / totalBNBFee/2;
        uint256 amountBNBPrize = amountBNB * prizeFee / totalBNBFee;
        uint256 amountBNBMarketing = amountBNB * marketingFee / totalBNBFee;
        uint256 amountBNBDev = amountBNB - (amountBNBMarketing + amountBNBPrize + amountBNBLiquidity);

        (bool marketingSuccess,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        require(marketingSuccess, "receiver rejected ETH transfer");
        (bool devSuccess,) = payable(devFeeReceiver).call{value: amountBNBDev, gas: 30000}("");
        require(devSuccess, "receiver rejected ETH transfer");

        swapBNBForPRIZE(amountBNBPrize);

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function swapBNBForPRIZE(uint256 amountBNBPrize) internal {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = PRIZE;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountBNBPrize}(
            0,
            path,
            address(this),
            block.timestamp
        );
        emit SwapBNBForPRIZE(amountBNBPrize, path);
    }
    
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        emit SetIsFeeExempt(holder, exempt);
    }
    
    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
        emit SetIsTxLimitExempt(holder, exempt);
    }
    
    function setPresaleAddress(address holder) external onlyOwner {
        canAddLiquidity[holder] = true;
        isFeeExempt[holder] = true;
        isTxLimitExempt[holder] = true;
        emit SetPresaleAddress(holder);
    }

    function setFees(uint256 _liquidityFee, uint256 _prizeFee, uint256 _marketingFee, uint256 _devFee) external onlyOwner {
        liquidityFee = _liquidityFee;
        prizeFee = _prizeFee;
        marketingFee = _marketingFee;
        devFee = _devFee;
        totalFee = _liquidityFee + _prizeFee + _marketingFee + _devFee;
        require(totalFee <= 33);
        emit SetFees(_liquidityFee, _prizeFee, _marketingFee, _devFee);
    }

    function setPrizeToken(address _newPrize) external onlyTeam {
        require(_newPrize != address(this) && !claimedPrize);
        PRIZE = _newPrize;
        claimedPrize = false;
        emit SetPrizeToken(PRIZE);
    }
    
    function setSwapBack(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
        emit SetSwapBackEnabled(_enabled);
    }

    function setSwapBackSettings(uint256 _min_base10000, uint256 _max_base10000) external onlyOwner {
        require(_min_base10000 >= 1 && _max_base10000 >= 1, "Can't set the SwapBack below 1");
        swapThresholdMax = _totalSupply / 10000 * _max_base10000;
        swapThreshold = _totalSupply / 10000 * _min_base10000;
        emit SetSwapBackSettings(swapThresholdMax, swapThreshold);
    }
    
    function setMaxWalletPercent_base1000(uint256 maxWallPercent_base100) external onlyOwner() {
        require (maxWallPercent_base100 >= _totalSupply/100, "Can't set MaxWallet below 1%");
        maxWalletToken = _totalSupply /100 * maxWallPercent_base100;
        emit SetMaxWallet(maxWalletToken);
    }

    function setMaxTxPercent_base1000(uint256 maxTXPercentage_base1000) external onlyOwner() {
        require (maxTXPercentage_base1000 >= _totalSupply/1000, "Can't set MaxTx below 0,1%");
        maxTxAmount = _totalSupply /1000 * maxTXPercentage_base1000;
        emit SetMaxTx(maxTxAmount);
    }

    function lockTokens(uint256 _amount, uint256 _daysLocked) external onlyTeam{
        locker.lockTokens(_amount, _daysLocked);
    }

    function extendLock(uint256 _extendLockTime) external onlyTeam{
        locker.extendLock(_extendLockTime);
    }
    function withdrawTokens() external onlyTeam{
        locker.withdrawTokens();
    }
    
    function EnablePrize() external onlyTeam {
        canClaimPrize = true;
        emit EnabledPrize(true);
    }
    
    function ClaimPrize() external{
        uint256 Prize = IBEP20(PRIZE).balanceOf(address(this));
        require(canClaimPrize == true &&
                msg.sender != owner &&
                _balances[msg.sender] >= minimumTokensClaim,"You need to hold more tokens to claim the prize");
        IBEP20(PRIZE).transfer(msg.sender, Prize);
        canClaimPrize = false;
        claimedPrize = true;
        emit ClaimedPrize(true);
    }

    function rescueToken(address tokenAddress) external onlyOwner returns (bool success) {
        uint256 Token = IBEP20(tokenAddress).balanceOf(address(this));
        require (tokenAddress != address(this) &&
                 tokenAddress != PRIZE, "Can't let you take the prize or the native token");
        return IBEP20(tokenAddress).transfer(msg.sender, Token);
    }
    
    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(marketingFeeReceiver).transfer(amountBNB * amountPercentage / 100);
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function checkSwapThreshold() external view returns (uint256) {
        return swapThreshold;
    }   
    
    function checkMaxWalletToken() external view returns (uint256) {
        return maxWalletToken;
    }

    function checkMaxTxAmount() external view returns (uint256) {
        return maxTxAmount;
    }
    
    function checkMinimumTokensToClaim() external view returns (uint256) {
        return minimumTokensClaim;
    }
    
    function checkPrizeEnabled() external view returns (bool) {
        return canClaimPrize;
    }
}