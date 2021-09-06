/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

//Innovatus.finance we are going to innov8 the crypto world

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.4;

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
        if (a == 0) { return 0; }
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

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {

    using SafeMath for uint256;
    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IDEXRouter router;
    address routerAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    IBEP20 RewardToken = IBEP20(0xbA2aE424d960c26247Dd6c32edC70B295c744C43);

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
    uint256 public minDistribution = 1 * (10 ** 8);

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

    constructor (address _router) {
        router = _router != address(0) ? IDEXRouter(_router) : IDEXRouter(routerAddress);
        _token = msg.sender;
    }
    
    function getClaimWait() public view returns (uint256) {
        return minPeriod;
    }
    
    function getMinDistribution() public view returns (uint256) {
        return minDistribution;
    }
    
	function getPaidEarnings(address account) external view returns (uint256) {
		return shares[account].totalRealised;
	}

    function getTotalDividendsDistributed() external view returns (uint256) {
        return totalDistributed;
    }
    
    function setDistributionCriteria(uint256 newMinPeriod, uint256 newMinDistribution) external override onlyToken {
        minPeriod = newMinPeriod;
        minDistribution = newMinDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {

        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {

        uint256 balanceBefore = RewardToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(RewardToken);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = RewardToken.balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 iterations = 0;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        while(gasUsed < gas && iterations < shareholderCount) {

            if(currentIndex >= shareholderCount){ currentIndex = 0; }

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

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            RewardToken.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external {
        distributeDividend(msg.sender);
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
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract Innovatus is IBEP20, Auth {
    
    using SafeMath for uint256;

    string constant _name = "Innovatus";
    string constant _symbol = "innov8";
    uint8 constant _decimals = 8;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address routerAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address RewardToken = 0xbA2aE424d960c26247Dd6c32edC70B295c744C43;


    uint256 _totalSupply = 3140 * 10**9 * (10 ** _decimals);
    uint256 public _maxTxAmount = 20 * 10**6 * (10 ** _decimals);
    uint256 public _walletMax = 100 * 10**6 * (10 ** _decimals);
    
    bool public checkWalletLimit = true;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public isTimelockExempt;

    uint256 public charityFee = 5;
    uint256 public marketingFee = 1;
    uint256 public rewardsFee = 2;
    uint256 public burnFee = 1;
    uint256 public extraFeeOnSell = 7;

    uint256 public totalFee = 0;
    uint256 public totalFeeIfSelling = 0;

    address public marketingWallet;
    address public charityWallet;

    IDEXRouter public router;
    address public pair;

    DividendDistributor public dividendDistributor;
    uint256 distributorGas = 500000;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;

    uint256 public swapThreshold = 500 * 10**3 * (10 ** _decimals);
    
    bool public cooldownEnabled = true;
    uint8 public cooldownTimerInterval = 1 minutes;
    mapping (address => uint) private cooldownTimer;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () Auth(msg.sender) {
        
        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        dividendDistributor = new DividendDistributor(address(router));

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[pair] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[msg.sender] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;
        
        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[address(this)] = true;
        isTimelockExempt[0x000000000000000000000000000000000000dEaD] = true;

        marketingWallet = 0x31E2f5f5A6A15B4659889Ef7C5Be2b1491d59FBD;
        charityWallet = 0x99935672CAee8598d5CCc472Bd3F480117F45d51;
        
        totalFee = charityFee.add(marketingFee).add(rewardsFee);
        totalFeeIfSelling = totalFee.add(extraFeeOnSell).add(burnFee);

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function name() external pure override returns (string memory) { return _name; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function getOwner() external view override returns (address) { return owner; }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }

    function changeTxLimit(uint256 newLimit) external authorized {
        _maxTxAmount = newLimit;
    }

    function changeWalletLimit(uint256 newLimit) external authorized {
        _walletMax  = newLimit;
    }

    function changeCheckWalletLimit(bool newValue) external authorized {
       checkWalletLimit = newValue;
    }
    
    function changeIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function changeIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        
        if(exempt){
            dividendDistributor.setShare(holder, 0);
        }else{
            dividendDistributor.setShare(holder, _balances[holder]);
        }
    }

    function changeFees(uint256 newCharityFee, uint256 newRewardFee, uint256 newMarketingFee, uint256 newExtraSellFee, uint256 newBurnFee) external authorized {
        charityFee = newCharityFee;
        rewardsFee = newRewardFee;
        marketingFee = newMarketingFee;
        extraFeeOnSell = newExtraSellFee;
        burnFee = newBurnFee;
        
        totalFee = charityFee.add(marketingFee).add(rewardsFee);
        totalFeeIfSelling = totalFee.add(extraFeeOnSell).add(burnFee);
    }
    
    function changeCooldownSettings(bool newStatus, uint8 newInterval) external onlyOwner {
        require(newInterval <= 10 minutes, "Exceeds the limit");
        cooldownEnabled = newStatus;
        cooldownTimerInterval = newInterval;
    }

    function setIsTimelockExempt(address holder, bool exempt) external onlyOwner {
        isTimelockExempt[holder] = exempt;
    }

    function changeMarketingWallet(address newMarketingWallet) external authorized {
        marketingWallet = newMarketingWallet;
    }

    function changeCharityWallet(address newCharityWallet) external authorized {
        charityWallet = newCharityWallet;
    }

    function changeSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit, bool swapByLimitOnly) external authorized {
        swapAndLiquifyEnabled  = enableSwapBack;
        swapThreshold = newSwapBackLimit;
        swapAndLiquifyByLimitOnly = swapByLimitOnly;
    }

    function changeDistributionCriteria(uint256 newinPeriod, uint256 newMinDistribution) external authorized {
        dividendDistributor.setDistributionCriteria(newinPeriod, newMinDistribution);
    }

    function changeDistributorGas(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        if(inSwapAndLiquify){ return _basicTransfer(sender, recipient, amount); }

        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        
        if(!isTxLimitExempt[recipient] && checkWalletLimit)
            require(_balances[recipient].add(amount) <= _walletMax);
            
        if(cooldownEnabled && recipient == pair && !isTimelockExempt[sender]){
            require(cooldownTimer[sender] < block.timestamp, "Please wait for cooldown between buys");
            cooldownTimer[sender] = block.timestamp + cooldownTimerInterval;
        }
        
        if(msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold){ swapBack(); }

        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);

        // Dividend tracker
        if(!isDividendExempt[sender]) {
            try dividendDistributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try dividendDistributor.setShare(recipient, _balances[recipient]) {} catch {} 
        }

        try dividendDistributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        if(totalFee <= 0) { return amount; }
        
        uint256 feeApplicable = pair == recipient ? totalFeeIfSelling.sub(burnFee) : totalFee;
        uint256 feeAmount = amount.mul(feeApplicable).div(100);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        
        uint256 tBurn = 0;
        if(pair == recipient)
        {
            tBurn = amount.mul(burnFee).div(100);
            _balances[DEAD] = _balances[DEAD].add(tBurn);
            emit Transfer(sender, address(DEAD), tBurn);
        }

        return amount.sub(feeAmount).sub(tBurn);
    }

    function swapBack() internal lockTheSwap {
        
        uint256 tokensToLiquify = _balances[address(this)];
        
        if(swapAndLiquifyByLimitOnly)
            tokensToLiquify = swapThreshold;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToLiquify,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance;

        uint256 bnbReflection = amountBNB.mul(rewardsFee).div(totalFee);
        uint256 bnbCharity = amountBNB.mul(charityFee).div(totalFee);
        uint256 bnbMarketing = amountBNB.sub(bnbReflection).sub(bnbCharity);

        try dividendDistributor.deposit{value: bnbReflection}() {} catch {}
        
        (bool tmpSuccess,) = payable(marketingWallet).call{value: bnbMarketing, gas: 30000}("");
        (bool tmpSuccess1,) = payable(charityWallet).call{value: bnbCharity, gas: 30000}("");
        
        // only to supress warning msg
        tmpSuccess = false;
        tmpSuccess1 = false;
    }
    
    function getClaimWait() external view returns(uint256) {
        return dividendDistributor.getClaimWait();
    }

    function getMinDistribution() external view returns(uint256) {
        return dividendDistributor.getMinDistribution();
    }

    function getUnpaidEarnings(address account) external view returns(uint256) {
    	return dividendDistributor.getUnpaidEarnings(account);
  	}

	function getPaidEarnings(address account) external view returns (uint256) {
		return dividendDistributor.getPaidEarnings(account);
	}

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendDistributor.getTotalDividendsDistributed();
    }

    function claimDividend() external {
		dividendDistributor.claimDividend();
    }

	function processDividendTracker(uint256 gas) external {
		dividendDistributor.process(gas);
    }

    function setDistributionCriteria(uint256 newMinPeriod, uint256 newMinDistribution) external onlyOwner {
        dividendDistributor.setDistributionCriteria(newMinPeriod, newMinDistribution);
    }
    
    function prepareForPreSale() external onlyOwner {
        swapAndLiquifyEnabled = false;
        checkWalletLimit = false;
        cooldownEnabled = false;
        
        totalFee = 0;
        totalFeeIfSelling = 0;
        _maxTxAmount = 3 * 10**9 * (10 ** _decimals);
    }
    
    function afterPresale() external onlyOwner {
        swapAndLiquifyEnabled = true;
        checkWalletLimit = true;
        cooldownEnabled = true;
        
        totalFee = 0;
        totalFeeIfSelling = 0;
        _maxTxAmount = 3 * 10**9 * (10 ** _decimals);
    }
    
    function prepareForLaunch(uint256 newLCharityFee, uint256 newRewardFee, uint256 newMarketingFee, uint256 newExtraSellFee, uint256 newBurnFee) external onlyOwner {
        swapAndLiquifyEnabled = true;
        checkWalletLimit = true;
        cooldownEnabled = true;
        
        charityFee = newLCharityFee;
        rewardsFee = newRewardFee;
        marketingFee = newMarketingFee;
        extraFeeOnSell = newExtraSellFee;
        burnFee = newBurnFee;
        
        totalFee = charityFee.add(marketingFee).add(rewardsFee);
        totalFeeIfSelling = totalFee.add(extraFeeOnSell).add(burnFee);
        
        _maxTxAmount = 20 * 10**6 * (10 ** _decimals);
    }

}