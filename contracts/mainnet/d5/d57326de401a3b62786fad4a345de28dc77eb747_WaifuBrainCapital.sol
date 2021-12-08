/**

Waifu Brain Capital: $WBC
- Let Waifu Brain Capital handle your portfolio and earn reflection in $ETH. (◠﹏◠✿)
- Deflationary DeFi-as-a-Service (DaaS) Token, with 50% supply burned to 0x0dEaD

Tokenomics:
- Buy Tax / Sell Tax: 15%
    - 7% of each buy goes to ETH reflections
    - 5% to $WBC treasury for multi-chain investing
    - 3% Auto Liquidity to $WBC LP Pool

Website:
https://waifubrain.capital/

Telegram:
https://t.me/WaifuBrain

Twitter:
https://twitter.com/WaifuBrain

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minimumTokenBalanceForDividends) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function claimDividend(address holder) external;
    function manualSendDividend(uint256 amount, address holder) external;
}


contract WaifuBrainCapitalDividendTracker is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 200000000000000; // 0.0002 ETH minimum auto send  
    uint256 public minimumTokenBalanceForDividends = 1000000 * (10**9); // Must hold 1000,000 token to receive ETH

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor () {
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minimumTokenBalanceForDividends) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        minimumTokenBalanceForDividends = _minimumTokenBalanceForDividends;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > minimumTokenBalanceForDividends && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount <= minimumTokenBalanceForDividends && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function manualSendDividend(uint256 amount, address holder) external override onlyToken {
        uint256 contractETHBalance = address(this).balance;
        payable(holder).transfer(amount > 0 ? amount : contractETHBalance);
    }

    function deposit() external payable override onlyToken {
        uint256 amount = msg.value;

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            payable(shareholder).transfer(amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
    
    function getAccount(address _account) public view returns(
        address account,
        uint256 pendingReward,
        uint256 totalRealised,
        uint256 lastClaimTime,
        uint256 nextClaimTime,
        uint256 secondsUntilAutoClaimAvailable,
        uint256 _totalDistributed){
        account = _account;
        
        Share storage userInfo = shares[_account];
        pendingReward = getUnpaidEarnings(account);
        totalRealised = shares[_account].totalRealised;
        lastClaimTime = shareholderClaims[_account];
        nextClaimTime = lastClaimTime + minPeriod;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
        _totalDistributed = totalDistributed;
    }
    
    function claimDividend(address holder) external override {
        distributeDividend(holder);
    }
}

contract WaifuBrainCapital is Ownable, IERC20 {
    using SafeMath for uint256;
    
	struct FeeSet {
		uint256 reflectionFee;
		uint256 treasuryFee;
		uint256 liquidityFee;
		uint256 totalFee;
	}
    
    address WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    string _name = "Waifu Brain Capital";
    string _symbol = "$WBC";
    uint8 constant _decimals = 9;
    uint256 public _totalSupply = 100000000000 * (10 ** _decimals);
    uint256 public _maxWallet = _totalSupply.mul(3).div(100); 
    uint256 public _maxTxAmount = _totalSupply.mul(1).div(100);

    mapping (address => bool) excludeFee;
    mapping (address => bool) excludeMaxTxn;
    mapping (address => bool) excludeDividend;
    
	FeeSet public buyFees;
	FeeSet public sellFees;
    uint256 feeDenominator = 100;
    
    address treasuryWallet = address(0xE111dFa9D7aF3087aec50d1C354817e8A91E7518);
    address liquidityWallet;

    IUniswapV2Router02 public router;
    address pair;

    WaifuBrainCapitalDividendTracker public dividendTracker;

    uint256 lastSwap;
    uint256 interval = 5 minutes;
    bool public swapEnabled = true;
    bool ignoreLimit = true;

    bool isOpen = false;

    uint256 public swapThreshold = _totalSupply / 5000; // 0.02%
    bool inSwap;
    
    modifier swapping() { inSwap = true; _; inSwap = false; }
    modifier open(address from, address to) {
        require(isOpen || from == owner() || to == owner(), "Not Open");
        _;
    }

    constructor () {

        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IUniswapV2Factory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);

        dividendTracker = new WaifuBrainCapitalDividendTracker();

        address owner_ = msg.sender;
        liquidityWallet = owner_;

        excludeFee[liquidityWallet] = true;
        excludeFee[owner_] = true;
        excludeFee[address(this)] = true;

        excludeMaxTxn[liquidityWallet] = true;
        excludeMaxTxn[owner_] = true;
        excludeMaxTxn[address(this)] = true;

        excludeDividend[pair] = true;
        excludeDividend[address(this)] = true;
        excludeDividend[DEAD] = true;
        
		setBuyFees(7, 5, 3);
		setSellFees(7, 5, 3);
	
        _balances[owner_] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);
    }

    receive() external payable { }

    function setName(string memory newName, string memory newSymbol) public onlyOwner{
        _name = newName;
        _symbol = newSymbol;
    }
    
    function totalSupply() external override view returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external returns (string memory) { 
        return _symbol; 
    }
    function name() external returns (string memory) { 
        return _name; 
    }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
	
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, ~uint256(0));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != ~uint256(0)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function openTrade() external onlyOwner {
        isOpen = true;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal open(sender, recipient) returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, recipient, amount);

        if(lastSwap + interval <= block.timestamp){
            if(canSwap())
                swapBack();
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = takeFee(sender, recipient, amount);
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!excludeDividend[sender]){ try dividendTracker.setShare(sender, _balances[sender]) {} catch {} }
        if(!excludeDividend[recipient]){ try dividendTracker.setShare(recipient, _balances[recipient]) {} catch {} }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function manualSendDividend(uint256 amount, address holder) external onlyOwner {
        dividendTracker.manualSendDividend(amount, holder);
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount || excludeMaxTxn[sender], "TX Limit Exceeded");
        
        if (sender != owner() && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != treasuryWallet && recipient != liquidityWallet){
            uint256 currentBalance = balanceOf(recipient);
            require(excludeMaxTxn[recipient] || (currentBalance + amount <= _maxWallet));
        }
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (excludeFee[sender] || excludeFee[recipient]) 
            return amount;
        
        uint256 totalFee;
        if(sender == pair)
            totalFee = buyFees.totalFee;
        else
            totalFee = sellFees.totalFee;
            
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function canSwap() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 swapAmount = _balances[address(this)];
        if(!ignoreLimit)
            swapAmount = swapThreshold;

        lastSwap = block.timestamp;
        FeeSet memory fee = sellFees;
        uint256 totalFee = fee.totalFee;
        uint256 dynamicLiquidityFee = fee.liquidityFee;
        uint256 treasuryFee = fee.treasuryFee;
        uint256 reflectionFee = fee.reflectionFee;
        
        uint256 amountToLiquify = swapAmount.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapAmount.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2));
        
        uint256 amountETHLiquidity = amountETH.mul(dynamicLiquidityFee).div(totalETHFee).div(2);
        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityWallet,
                block.timestamp
            );
        }
        
        uint256 amountETHReflection = amountETH.mul(reflectionFee).div(totalETHFee);
        try dividendTracker.deposit{value: amountETHReflection}() {} catch {}
        
        uint256 amountETHTreasury = address(this).balance;
        payable(treasuryWallet).transfer(amountETHTreasury);
    }

    function setExcludeDividend(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        excludeDividend[holder] = exempt;
        if(exempt){
            dividendTracker.setShare(holder, 0);
        }else{
            dividendTracker.setShare(holder, _balances[holder]);
        }
    }

    function setExcludeFeeMultiple(address[] calldata _users, bool exempt) external onlyOwner {
        for(uint8 i = 0; i < _users.length; i++) {
            excludeFee[_users[i]] = exempt;
        }
    }
    
    function setExcludeTxMultiple(address[] calldata _users, bool exempt) external onlyOwner {
        for(uint8 i = 0; i < _users.length; i++) {
            excludeMaxTxn[_users[i]] = exempt;
        }
    }
    
    function setReceiver(address _treasuryWallet, address _liquidityWallet) external onlyOwner {
        treasuryWallet = _treasuryWallet;
        liquidityWallet = _liquidityWallet;
    }

    function rescueToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function rescueETH(uint256 _amount) external onlyOwner{
        payable(msg.sender).transfer(_amount);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount, bool _ignoreLimit, uint256 _interval) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        ignoreLimit = _ignoreLimit;
        interval = _interval;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minimumTokenBalanceForDividends) external onlyOwner {
        dividendTracker.setDistributionCriteria(_minPeriod, _minDistribution, _minimumTokenBalanceForDividends);
    }
    
    function setTxLimit(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 2000);
        _maxTxAmount = amount;
    }
    
    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }
    
    function claim() public {
        dividendTracker.claimDividend(msg.sender);
    }

    function setBuyFees(uint256 _reflectionFee, uint256 _treasuryFee, uint256 _liquidityFee) public onlyOwner {
		buyFees = FeeSet({
			reflectionFee: _reflectionFee,
			treasuryFee: _treasuryFee,
			liquidityFee: _liquidityFee,
			totalFee: _reflectionFee + _treasuryFee + _liquidityFee
		});
	}

	function setSellFees(uint256 _reflectionFee, uint256 _treasuryFee, uint256 _liquidityFee) public onlyOwner {
		sellFees = FeeSet({
			reflectionFee: _reflectionFee,
			treasuryFee: _treasuryFee,
			liquidityFee: _liquidityFee,
			totalFee: _reflectionFee + _treasuryFee + _liquidityFee
		});
	}
}