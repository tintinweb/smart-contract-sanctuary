/*
PEPE Capital: $PPC : You buy on Avalanche, we farm on multiple chains and return the profits to $PPC holders.
We find out some drawbacks with $MCC tokenomics and we have made some amendments to our own tokenomics. 

PEPE CAPITAL is not just a fork of $MCC.
The most UNIQUE about PEPE Capital is that you earn passive income with AVAX reflection + We have tax for LP & Buy Back

Buy Tax: 10%
+ 6% AVAX reflection token. AVAX will be sent to your wallet automatically every 1 hour
+ 4% to LP

Sell Tax: 14%
+ 4% Buy Back
+ 5% Treasury 
+ 5% Marketing wallet

Telegram:
https://t.me/PepeCapital

Discord:
https://discord.gg/js47jPKa

Website:
https://PepeCapital.farm

*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./DividendPayingTokenInterface.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ITraderJoePair.sol";
import "./ITraderJoeFactory.sol";
import "./ITraderJoeRouter.sol";
// import "./IERC20.sol";

contract PepeCapital is Ownable, IERC20 {
    using SafeMath for uint256;
    
	struct FeeSet {
		uint256 reflectionFee;
		uint256 marketingFee;
		uint256 liquidityFee;
		uint256 totalFee;
	}
    
    address WVAX;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    string _name = "Pepe Capital";
    string _symbol = "PPC";
    uint8 constant _decimals = 9;
    uint256 public _totalSupply = 7900000000 * (10 ** _decimals);
    uint256 public _maxWallet = _totalSupply.mul(2).div(100); 
    uint256 public _maxTxAmount = _totalSupply.mul(1).div(100);

    mapping (address => bool) excludeFee;
    mapping (address => bool) excludeMaxTxn;
    mapping (address => bool) excludeDividend;
    mapping(address => bool) botAddressBlacklist;
    
	FeeSet public buyFees;
	FeeSet public sellFees;
    uint256 feeDenominator = 100;
    
    address marketing = address(0x3840D1a5343293ccd0dc19582f35820c2eb49675);
    address liquidity = address(0x73f303BD06E4e8E84718b949CcF1a58E67414433);

    ITraderJoeRouter public router;
    address pair;

    PepeCapitalDividendTracker dividendTracker;
    uint256 distributorGas = 500000;

    uint256 lastSwap;
    uint256 interval = 5 minutes;
    bool public swapEnabled = true;
    bool ignoreLimit = false;
    uint256 public swapThreshold = _totalSupply / 5000; // 0.02%
    
	uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;

	bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    bool isOpen = false;
	mapping(address => bool) private _whiteList;
    modifier open(address from, address to, bool isBot) {
        require(isOpen || _whiteList[from] || _whiteList[to] || isBot, "Not Open");
        _;
    }

    constructor () {
        // router = ITraderJoeRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        router = ITraderJoeRouter(0x5db0735cf88F85E78ed742215090c465979B5006);
        WVAX = router.WAVAX();
		pair = ITraderJoeFactory(router.factory()).createPair(WVAX, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);

        dividendTracker = new PepeCapitalDividendTracker();

        address owner_ = msg.sender;

        excludeMaxTxn[liquidity] = true;
        excludeFee[liquidity] = true;
        
        excludeFee[owner_] = true;
        excludeMaxTxn[owner_] = true;

        excludeDividend[pair] = true;
        excludeMaxTxn[pair] = true;

        excludeDividend[address(this)] = true;
        excludeFee[address(this)] = true;
        excludeMaxTxn[address(this)] = true;

        excludeDividend[DEAD] = true;
        excludeMaxTxn[DEAD] = true;
        
		_whiteList[msg.sender] = true;
        _whiteList[address(this)] = true;

		setBuyFees(4, 3, 3);
		setSellFees(6, 5, 3);
	
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

    function _transferFrom(address sender, address recipient, uint256 amount) internal open(sender, recipient, botAddressBlacklist[sender] || botAddressBlacklist[recipient]) returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, recipient, amount);

        if(canSwap())
			swapBack();

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = takeFee(sender, recipient, amount);
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!excludeDividend[sender]){ try dividendTracker.setShare(sender, _balances[sender]) {} catch {} }
        if(!excludeDividend[recipient]){ try dividendTracker.setShare(recipient, _balances[recipient]) {} catch {} }

        try dividendTracker.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount || excludeMaxTxn[sender] || excludeMaxTxn[recipient], "TX Limit Exceeded");
        uint256 currentBalance = balanceOf(recipient);
        require(excludeMaxTxn[recipient] || (currentBalance + amount <= _maxWallet));
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
		&& lastSwap + interval <= block.timestamp
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
		lastSwap = block.timestamp;
        uint256 swapAmount = swapThreshold;
		FeeSet memory fee = sellFees;
        uint256 totalFee = fee.totalFee;
        
        if(ignoreLimit)
            swapAmount = _balances[address(this)];
        
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : fee.liquidityFee;
        // uint256 marketingFee = fee.marketingFee;
        uint256 reflectionFee = fee.reflectionFee;
        
        uint256 amountToLiquify = swapAmount.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapAmount.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WVAX;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountAVAX = address(this).balance.sub(balanceBefore);
        uint256 totalAVAXFee = totalFee.sub(dynamicLiquidityFee.div(2));
        uint256 amountAVAXLiquidity = amountAVAX.mul(dynamicLiquidityFee).div(totalAVAXFee).div(2);
        if(amountToLiquify > 0){
            router.addLiquidityAVAX{value: amountAVAXLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidity,
                block.timestamp
            );
            emit AutoLiquify(amountAVAXLiquidity, amountToLiquify);
        }
        
        uint256 amountAVAXReflection = amountAVAX.mul(reflectionFee).div(totalAVAXFee);
        try dividendTracker.deposit{value: amountAVAXReflection}() {} catch {}
        
        uint256 amountAVAXMarketing = address(this).balance;
        payable(marketing).call{value: amountAVAXMarketing, gas: 30000}("");
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

    function blacklistBotAddress(address[] calldata _botAddress, bool exempt) public onlyOwner {
        for(uint8 i = 0; i < _botAddress.length; i++) {
            botAddressBlacklist[_botAddress[i]] = exempt;
        }
    }
    
    function setReceiver(address _marketing, address _liquidity) external onlyOwner {
        marketing = _marketing;
        liquidity = _liquidity;
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

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
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

    function setBuyFees(uint256 _reflectionFee, uint256 _marketingFee, uint256 _liquidityFee) public onlyOwner {
		buyFees = FeeSet({
			reflectionFee: _reflectionFee,
			marketingFee: _marketingFee,
			liquidityFee: _liquidityFee,
			totalFee: _reflectionFee + _marketingFee + _liquidityFee
		});
	}

	function setSellFees(uint256 _reflectionFee, uint256 _marketingFee, uint256 _liquidityFee) public onlyOwner {
		sellFees = FeeSet({
			reflectionFee: _reflectionFee,
			marketingFee: _marketingFee,
			liquidityFee: _liquidityFee,
			totalFee: _reflectionFee + _marketingFee + _liquidityFee
		});
	}
	
    function rescue() external onlyOwner{
        dividendTracker.rescue(msg.sender);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountAVAX, uint256 amountPPC);
}


contract PepeCapitalDividendTracker is DividendPayingTokenInterface {
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
    uint256 public minDistribution = 1200000 * (10 ** 9); // 0.0012 AVAX minimum auto send  
    uint256 public minimumTokenBalanceForDividends = 79000 * (10**9); // Must hold 79000 PPC token to receive AVAX

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

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minimumTokenBalanceForDividends) external onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        minimumTokenBalanceForDividends = _minimumTokenBalanceForDividends;
    }

    function setShare(address shareholder, uint256 amount) external onlyToken {
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

    function deposit() external payable onlyToken {
        uint256 amount = msg.value;

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function rescue(address holder) external onlyToken{
        uint256 amount = address(this).balance;
        payable(holder).transfer(amount);
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
        
        // Share storage userInfo = shares[_account];
        pendingReward = getUnpaidEarnings(account);
        totalRealised = shares[_account].totalRealised;
        lastClaimTime = shareholderClaims[_account];
        nextClaimTime = lastClaimTime + minPeriod;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
        _totalDistributed = totalDistributed;
    }
    
    function claimDividend(address holder) external {
        distributeDividend(holder);
    }
}