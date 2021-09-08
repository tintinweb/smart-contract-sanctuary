/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

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
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minTokensForDividends) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract WaveDividendDistributor is IDividendDistributor {

    using SafeMath for uint256;
    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IDEXRouter router;
    address routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    IBEP20 RewardToken = IBEP20(0x8a9424745056Eb399FD19a0EC26A14316684e274);

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
    uint256 public minDistribution = 1 * (10 ** 16);
    uint256 public minTokensForDividends = 10000 * (10**9); //must hold 10000+ tokens

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
    
    function getMinTokensForDividends() public view returns (uint256) {
        return minTokensForDividends;
    }
    
	function getPaidEarnings(address account) external view returns (uint256) {
		return shares[account].totalRealised;
	}

    function getTotalDividendsDistributed() external view returns (uint256) {
        return totalDistributed;
    }
    
    function setDistributionCriteria(uint256 newMinPeriod, uint256 newMinDistribution, uint256 newMinTokensForDividends) external override onlyToken {
        minPeriod = newMinPeriod;
        minDistribution = newMinDistribution;
        minTokensForDividends = newMinTokensForDividends;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {

        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount >= minTokensForDividends && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount < minTokensForDividends && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount);
        shares[shareholder].amount = 0;
        
        if(amount >= minTokensForDividends)
        {
            totalShares = totalShares.add(amount);
            shares[shareholder].amount = amount;
        }
        
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

contract Wave is IBEP20, Auth {
    
    using SafeMath for uint256;

    string constant _name = "Wave";
    string constant _symbol = "Wave";
    uint8 constant _decimals = 9;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address RewardToken = 0x8a9424745056Eb399FD19a0EC26A14316684e274;

    uint256 _totalSupply = 1 * 10**9 * (10 ** _decimals);
    uint256 public swapThreshold = 50000 * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;

    uint256 public rewardsFee = 10;
    uint256 public liquidityFee = 5;
    uint256 public marketingFee = 5;
    uint256 public buyBackFee = 5;
    uint256 public extraFeeOnSell = 5;
    uint256 public feeDenominator = 100;

    uint256 public _maxTxPercent = 1;
    uint256 public _maxTxPercentDenominator = 1000;

    uint256 public totalFee = 0;
    uint256 public totalFeeIfSelling = 0;

    address public marketingWallet;
    address public buyBackWallet;

    IDEXRouter public router;
    address public pair;

    WaveDividendDistributor public dividendDistributor;
    uint256 public distributorGas = 300000;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () Auth(msg.sender) {
        
        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        dividendDistributor = new WaveDividendDistributor(address(router));

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[msg.sender] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        marketingWallet = 0xDe7796cc7F65F98a053Dba0215a75a7449b34e08;
        buyBackWallet = 0xd9Cb687EccC712A045eE3Af1542A4b057d8611C1;
        
        totalFee = liquidityFee.add(buyBackFee).add(marketingFee).add(rewardsFee);
        totalFeeIfSelling = totalFee.add(extraFeeOnSell);

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

    function changeMaxTxPercent(uint256 newValue, uint256 newDenominator) external authorized {
        _maxTxPercent = newValue;
        _maxTxPercentDenominator = newDenominator;
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

    function changeFees(uint256 newLiquidityFee, uint256 newBuyBackFee, uint256 newRewardFee, uint256 newMarketingFee, uint256 newExtraSellFee, uint256 newFeeDenominator) external authorized {
        liquidityFee = newLiquidityFee;
        buyBackFee = newBuyBackFee;
        rewardsFee = newRewardFee;
        marketingFee = newMarketingFee;
        extraFeeOnSell = newExtraSellFee;
        feeDenominator = newFeeDenominator;
        
        totalFee = liquidityFee.add(buyBackFee).add(marketingFee).add(rewardsFee);
        totalFeeIfSelling = totalFee.add(extraFeeOnSell);
    }

    function changeMarketingWallet(address newMarketingWallet) external authorized {
        marketingWallet = newMarketingWallet;
    }

    function changeBuyBackWallet(address newBuyBackWallet) external authorized {
        buyBackWallet = newBuyBackWallet;
    }

    function changeSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit, bool swapByLimitOnly) external authorized {
        swapAndLiquifyEnabled  = enableSwapBack;
        swapThreshold = newSwapBackLimit;
        swapAndLiquifyByLimitOnly = swapByLimitOnly;
    }

    function changeDistributionCriteria(uint256 newinPeriod, uint256 newMinDistribution, uint256 newMinTokensForDividends) external authorized {
        dividendDistributor.setDistributionCriteria(newinPeriod, newMinDistribution, newMinTokensForDividends);
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

        if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient]) {
            require(amount <= getCirculatingSupply().mul(_maxTxPercent).div(_maxTxPercentDenominator), "Transfer amount exceeds the maxTxAmount.");
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

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
        
        uint256 feeApplicable = pair == recipient ? totalFeeIfSelling : totalFee;
        uint256 feeAmount = amount.mul(feeApplicable).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        
        return amount.sub(feeAmount);
    }

    function swapBack() internal lockTheSwap {
        
        uint256 tokensToLiquify = _balances[address(this)];
        
        if(swapAndLiquifyByLimitOnly)
            tokensToLiquify = swapThreshold;
            
        uint256 tokensToLiquidity = tokensToLiquify.mul(liquidityFee).div(totalFee).div(2);
        uint256 tokensToSwap = tokensToLiquify.sub(tokensToLiquidity);    

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance;
        uint256 feeDivisor = totalFee.sub(liquidityFee.div(2));
        
        uint256 bnbLiquidity = amountBNB.mul(liquidityFee).div(feeDivisor).div(2);
        uint256 bnbReflection = amountBNB.mul(rewardsFee).div(feeDivisor);
        uint256 bnbBuyBack = amountBNB.mul(buyBackFee).div(feeDivisor);
        uint256 bnbMarketing = amountBNB.sub(bnbLiquidity).sub(bnbReflection).sub(bnbBuyBack);
        
        if(bnbReflection > 0)
            try dividendDistributor.deposit{value: bnbReflection}() {} catch {}
        
        if(bnbMarketing > 0)
        {
            (bool tmpSuccess,) = payable(marketingWallet).call{value: bnbMarketing, gas: 30000}("");
            tmpSuccess = false;
        }
        
        if(bnbBuyBack > 0)
        {
            (bool tmpSuccess1,) = payable(buyBackWallet).call{value: bnbBuyBack, gas: 30000}("");
            tmpSuccess1 = false;
        }
        
        if(tokensToLiquidity > 0){
            router.addLiquidityETH{value: bnbLiquidity}(
                address(this),
                tokensToLiquidity,
                0,
                0,
                owner,
                block.timestamp
            );
            emit AutoLiquify(bnbLiquidity, tokensToLiquidity);
        }
    }
    
    event AutoLiquify(uint256 bnbLiquidity, uint256 tokensToLiquidity);
    
    function getClaimWait() external view returns(uint256) {
        return dividendDistributor.getClaimWait();
    }

    function getMinDistribution() external view returns(uint256) {
        return dividendDistributor.getMinDistribution();
    }

    function getMinTokensForDividends() external view returns(uint256) {
        return dividendDistributor.getMinTokensForDividends();
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

    function prepareForPreSale() external onlyOwner {
        swapAndLiquifyEnabled = false;

        totalFee = 0;
        totalFeeIfSelling = 0;
    }
    
    function prepareForLaunch(uint256 newLiquidityFee, uint256 newBuyBackFee, uint256 newRewardFee, uint256 newMarketingFee, uint256 newExtraSellFee, uint256 newFeeDenominator) external onlyOwner {
        swapAndLiquifyEnabled = true;

        buyBackFee = newBuyBackFee;
        rewardsFee = newRewardFee;
        marketingFee = newMarketingFee;
        extraFeeOnSell = newExtraSellFee;
        liquidityFee = newLiquidityFee;
        feeDenominator = newFeeDenominator;
        
        totalFee = liquidityFee.add(buyBackFee).add(marketingFee).add(rewardsFee);
        totalFeeIfSelling = totalFee.add(extraFeeOnSell);
    }

}