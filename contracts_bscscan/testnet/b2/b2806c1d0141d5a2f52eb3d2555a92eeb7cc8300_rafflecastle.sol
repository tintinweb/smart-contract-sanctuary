/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * BEP20 standard interface.
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
 * Allows for contract ownership along with multi-address authorization
 */
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair); // is this correct? pair or pcspair?
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
    
//added for lottery busd
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

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

    IBEP20 BTCB = IBEP20(0x8BaBbB98678facC7342735486C851ABD7A0d17Ca);
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    IDEXRouter router;

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
    uint256 public minDistribution = 3 * (10 ** 13);

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
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
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
        uint256 balanceBefore = BTCB.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(BTCB);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BTCB.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
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

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            BTCB.transfer(shareholder, amount);
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

contract rafflecastle is IBEP20, Auth {
    using SafeMath for uint256;

    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address BTCB = 0x8BaBbB98678facC7342735486C851ABD7A0d17Ca;
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "bit21";
    string constant _symbol = "bit21";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 1000000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 200; // 0.5%
    uint256 public maxWallet = _totalSupply / 100; // 1%
    uint256 public minRaffle = _totalSupply / 1000; // 0.1%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isMaxWalletExempt;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isWhitelistedForLimitedTrading;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isBlacklisted;

    uint256 liquidityFee = 250; 
    uint256 buybackFee = 50;
    uint256 reflectionFee = 500;
    uint256 marketingFee = 300;
    uint256 lotteryFee = 500;
    uint256 devFee = 100;
    uint256 founderFee = 50; 
    uint256 totalfixedBuyFee = liquidityFee.add(buybackFee).add(reflectionFee).add(marketingFee).add(lotteryFee).add(devFee).add(founderFee);
    uint256 totalBuyFee = 1775;
    uint256 totalSellFee = 1700;
    uint256 feeDenominator = 10000;
    
    uint256 dailyratio = 50;
    uint256 weeklyratio = 30;
    uint256 monthlyratio = 20;
    uint256 lotterydenominator = 100;
    address public dailyLotteryReceiver;
    address public weeklyLotteryReceiver;
    
    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public lotteryFeeReceiver;
    address public devFeeReceiver;
    address public founderFeeReceiver;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public PCSpair;
    address[] public pairs;

    uint256 public launchedAt;
    
    uint256 public PaperHandNumerator = 200;
    uint256 public DiamondHandNumerator = 50;
    uint256 feeMultipliersDenominator = 100;
    uint256 public feeMultipliersTriggeredAt;
    uint256 public feeMultipliersDuration = 180 minutes;
    
    uint256 SlidingBuyFee = totalBuyFee;
    uint256 SlidingSellFee = totalSellFee;
    uint256 SlidingTriggeredAt = 0;
    uint256 SlidingBuyNumerator = 25; 
    uint256 SlidingSellNumerator = 50; 
    uint256 SlidingBuyDuration = 10 minutes; 
    uint256 SlidingSellDuration = 20 minutes;
    uint256 SlidingBuyLimit = 1200;
    uint256 SlidingSellLimit = 2600;
    
    bool public tradingLimited = true;
   
    bool autoBuybackEnabled = false;
    uint256 autoBuybackCap; 
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    // Cooldown & timer functionality
    bool public buyCooldownEnabled = true;
    uint8 public cooldownTimerInterval = 45;
    mapping (address => uint) private cooldownTimer;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 2000; // 0.05%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (
    ) Auth(msg.sender) {
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        PCSpair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);
        
        pairs.push(PCSpair);
        
        distributor = new DividendDistributor(address(router));
        
        address owner_ = msg.sender;
        
        isMaxWalletExempt[owner_] = true;
        isMaxWalletExempt[address(this)] = true;
        isMaxWalletExempt[PCSpair] = true;
        isFeeExempt[owner_] = true;
        isTxLimitExempt[owner_] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true;
        isDividendExempt[address(this)] = true;
        isWhitelistedForLimitedTrading[owner_] = true;
        isWhitelistedForLimitedTrading[address(this)] = true;
        isDividendExempt[PCSpair] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = msg.sender;//gnosis wallet
        marketingFeeReceiver = msg.sender; //gnosis wallet
        lotteryFeeReceiver = msg.sender;//gnosis wallet
        devFeeReceiver = msg.sender;//gnosis wallet
        founderFeeReceiver = msg.sender;//gnosis wallet
        dailyLotteryReceiver = msg.sender; //gnosis wallet
        weeklyLotteryReceiver = msg.sender; // gnosis wallet
        
        _balances[owner_] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);
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
        return approve(spender, uint256(-1));
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
        if (tradingLimited) {
            checkAllowedToTrade(sender, recipient);
        }
        
        require(!isBlacklisted[sender] && !isBlacklisted[recipient] && !isBlacklisted[msg.sender], "Sender or recipient is blacklisted");

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender,recipient, amount);
        checkMaxWallet(recipient, amount); 
        checkBot(sender,recipient);
        
        if(shouldSwapBack()){ swapBack(); }
        if(block.timestamp > SlidingTriggeredAt.add(SlidingBuyDuration)){SlidingBuyFee = totalBuyFee;}
        if(block.timestamp > SlidingTriggeredAt.add(SlidingSellDuration)){SlidingSellFee = totalSellFee;}
        
        if(shouldAutoBuyback()){ triggerAutoBuyback(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        address _address = isSell(recipient) ? sender : recipient; 
        
        uint256 amountReceived = shouldTakeFee(_address) ? takeFee(sender, recipient, amount) : amount; 
        
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    // cooldown timer, so a bot doesnt do quick trades! 1min gap between 2 trades.
    function checkBot(address sender, address recipient) internal {
        if (sender == PCSpair &&
            buyCooldownEnabled) {
            require(cooldownTimer[recipient] < block.timestamp,"Please wait for 45s between two buys");
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
        }
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view { 
        require(amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded"); 
    }
    
    function checkMaxWallet(address recipient, uint256 amount) internal view { 
        require(balanceOf(recipient)+amount <= maxWallet || isMaxWalletExempt[recipient], "Max Wallet Exceeded 2%"); 
    }

    function checkAllowedToTrade(address sender, address recipient) public view returns (bool){ 
        require(isWhitelistedForLimitedTrading[sender] || isWhitelistedForLimitedTrading[recipient], "Not whitelisted while trading is limited.");
        return isWhitelistedForLimitedTrading[sender]; 
    }

    function shouldTakeFee(address _address) internal view returns (bool) { 
        return !isFeeExempt[_address];
    }
    
    function getTotalFee(bool selling) public view returns (uint256) { 
        if (launchedAt + 2 >= block.number){ return feeDenominator.sub(1); }
        if (selling && feeMultipliersTriggeredAt.add(feeMultipliersDuration) > block.timestamp) {return getPaperHandFee();}
        if (!selling && feeMultipliersTriggeredAt.add(feeMultipliersDuration) > block.timestamp) {return getDiamondHandFee();}
        if (!selling && SlidingTriggeredAt.add(SlidingBuyDuration) > block.timestamp) {return getSlidingBuyFee();}  
        if (selling && SlidingTriggeredAt.add(SlidingSellDuration) > block.timestamp) {return getSlidingSellFee();} 
        return selling ? totalSellFee : totalBuyFee;
    }
    
    function getSlidingBuyFee() internal view returns (uint256) { 
        uint256 totalFee = SlidingBuyFee;
        return totalFee;
    }
    
    function getSlidingSellFee() internal view returns (uint256) { 
        uint256 totalFee = SlidingSellFee;
        return totalFee;
    }
 
    function getPaperHandFee() public view returns (uint256) {
        uint256 totalFee = totalSellFee;
        uint256 remainingTime = feeMultipliersTriggeredAt.add(feeMultipliersDuration).sub(block.timestamp);
        uint256 feeIncrease = totalFee.mul(PaperHandNumerator).div(feeMultipliersDenominator).sub(totalFee);
        return totalFee.add(feeIncrease.mul(remainingTime).div(feeMultipliersDuration));
    }

    function getDiamondHandFee() public view returns (uint256) {
        uint256 totalFee = totalBuyFee;
        uint256 remainingTime = feeMultipliersTriggeredAt.add(feeMultipliersDuration).sub(block.timestamp);
        uint256 feeDecrease = totalFee.sub(totalFee.mul(DiamondHandNumerator).div(feeMultipliersDenominator));
        return totalFee.sub(feeDecrease.mul(remainingTime).div(feeMultipliersDuration));
    }

    function checkEligibleRaffle(address _holder) public view returns (bool) {
        if (balanceOf(_holder) >= minRaffle) {
        return true;
        }
        return false;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        if(isSell(recipient) == true || isBuy(sender) == true){sliding();}
      
        uint256 feeAmount = amount.mul(getTotalFee(isSell(recipient))).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }
    
    function sliding() internal {
        SlidingTriggeredAt = block.timestamp;
        SlidingSellFee < SlidingSellLimit ? SlidingSellFee += SlidingSellNumerator : SlidingSellFee = SlidingSellFee.add(0);
        SlidingBuyFee > SlidingBuyLimit ? SlidingBuyFee -= SlidingBuyNumerator : SlidingBuyFee = SlidingBuyFee.sub(0);
    }
    
    function isSell(address recipient) internal view returns (bool) {
        address[] memory liqPairs = pairs;
        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (recipient == liqPairs[i]) return true;
        }
        return false;
    }

    function isBuy(address sender) internal view returns (bool) {
        address[] memory liqPairs = pairs;
        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i]) return true;
        }
        return false;
    }
    
    // enable cooldown between trades
    function cooldownEnabled(bool _status, uint8 _interval) external authorized {
        buyCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != PCSpair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalfixedBuyFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

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

        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 totalBNBFee = totalfixedBuyFee.sub(dynamicLiquidityFee.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
        uint256 amountBNBLottery = amountBNB.mul(lotteryFee).div(totalBNBFee);
        uint256 amountBNBDev = amountBNB.mul(devFee).div(totalBNBFee);
        uint256 amountBNBFounder = amountBNB.mul(founderFee).div(totalBNBFee);
        swapAndSendToFee(amountBNBLottery);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        payable(devFeeReceiver).call{value: amountBNBDev, gas: 30000}("");
        payable(founderFeeReceiver).call{value: amountBNBFounder, gas: 30000}("");
        
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
    
    function swapAndSendToFee(uint256 tokens) private  {

        uint256 initialBUSDBalance = IBEP20(BUSD).balanceOf(address(this));
        swapToBUSD(tokens);
        uint256 newBalance = (IBEP20(BUSD).balanceOf(address(this))).sub(initialBUSDBalance);
        IBEP20(BUSD).transfer(dailyLotteryReceiver,newBalance.mul(dailyratio).div(lotterydenominator));
        IBEP20(BUSD).transfer(weeklyLotteryReceiver,newBalance.mul(weeklyratio).div(lotterydenominator));
        IBEP20(BUSD).transfer(lotteryFeeReceiver,newBalance.mul(monthlyratio).div(lotterydenominator));
    }

    function swapToBUSD(uint256 amount) internal returns (uint256 resultingAmt) {
        uint256 BUSDBefore = IBEP20(BUSD).balanceOf(address(this));

        address[] memory BUSDPath = new address[](2);
        BUSDPath[0] = WBNB;
        BUSDPath[1] = BUSD;

        try router.swapExactETHForTokens{ value: amount }(
            0,
            BUSDPath,
            address(this),
            block.timestamp
        ) {} catch {}

        return IBEP20(BUSD).balanceOf(address(this)).sub(BUSDBefore);
    }


    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != PCSpair
            && !inSwap
            && autoBuybackEnabled
            && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number
            && address(this).balance >= autoBuybackAmount;
    }

    function triggerBuyback(uint256 amount, bool triggerBuybackJackpot) external authorized {
        buyTokens(amount, DEAD);
        if(triggerBuybackJackpot){
            feeMultipliersTriggeredAt = block.timestamp;
            emit JackpotActive(feeMultipliersDuration);
        }
    }
    
    function triggerJackpot(bool _triggerJackpot) external authorized {
        if(_triggerJackpot){
            feeMultipliersTriggeredAt = block.timestamp;
            emit JackpotActive(feeMultipliersDuration);
        }
    }
    
    function clearJackpot() external authorized {
        feeMultipliersTriggeredAt = 0;
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
    }
  
    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

   function setSlidingBuy(uint256 _slidingbuyperiod, uint256 _slidingbuynumerator, uint256 _slidingbuylimit) external authorized { // removed uint _greenwalldenominator
        SlidingBuyDuration = _slidingbuyperiod;
        SlidingBuyNumerator = _slidingbuynumerator;
        SlidingBuyLimit = _slidingbuylimit;
    }
    
    function setSlidingSell(uint256 _slidingsellperiod, uint256 _slidingsellnumerator, uint256 _slidingselllimit) external authorized {
        SlidingSellDuration = _slidingsellperiod;
        SlidingSellNumerator = _slidingsellnumerator;
        SlidingSellLimit = _slidingselllimit;
    }
   function setMultiplierSettings(uint256 PaperHandNum, uint256 DiamondHandNum, uint256 denominator, uint256 length) external authorized{
        require(PaperHandNum / denominator <= 2 && PaperHandNum >= denominator);
        require(DiamondHandNum <= denominator);

        PaperHandNumerator = PaperHandNum;
        DiamondHandNumerator = DiamondHandNum;
        feeMultipliersDenominator = denominator;
        feeMultipliersDuration = length;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() external authorized {
        launchedAt = block.number;
        tradingLimited = false;
        emit Launched(block.number, block.timestamp);
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount != _maxTxAmount, "bitcastle:the max tx amount is already this amount");
        _maxTxAmount = amount;
    }

    function setMaxWallet(uint256 newmaxWallet) external authorized { 
        maxWallet = newmaxWallet;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != PCSpair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt; // true
    }
    
    function setIsMaxWalletExempt(address holder, bool exempt) external authorized {
        isMaxWalletExempt[holder] = exempt; // true
    }
    
    function setIsWhitelistedForLimitedTrading(address holder, bool whitelisted) external authorized{
        isWhitelistedForLimitedTrading[holder] = whitelisted; // true
    }
    
    function setIsBlacklisted(address holder, bool blacklisted) external authorized{
        isBlacklisted[holder] = blacklisted;
    }

    function setFees(uint256 _lotteryFee, uint256 _devFee, uint256 _founderFee, uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator, uint256 _totalSellFee, uint256 _totalBuyFee) external authorized {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        lotteryFee = _lotteryFee;
        devFee = _devFee;
        founderFee = _founderFee;
        totalBuyFee = _totalBuyFee;
        totalSellFee = _totalSellFee;
        feeDenominator = _feeDenominator;
        require(totalBuyFee <= feeDenominator * 35 / 100, "Buy fee too high");
        require(totalSellFee <= feeDenominator * 35 / 100, "Sell fee too high");
        
        require(_liquidityFee <= feeDenominator * 15 / 100, "Liq fee too high");
        require(_buybackFee <= feeDenominator * 10 / 100, "Buyback fee too high");
        require(_reflectionFee <= feeDenominator * 15 / 100, "Reward fee too high");
        require(_marketingFee <= feeDenominator * 15 / 100, "Marketing fee too high");
        require(_lotteryFee <= feeDenominator * 15 / 100, "Lottery fee too high");
        require(_devFee <= feeDenominator * 5 / 100, "Dev fee too high");
        require(_founderFee <= feeDenominator * 2 / 100, "Founder fee too high");
    }

    function setLotteryFee (uint256 _dailyratio, uint256 _weeklyratio, uint256 _monthlyratio) external authorized{
        dailyratio = _dailyratio;
        weeklyratio = _weeklyratio;
        monthlyratio = _monthlyratio;
    }
    
    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _devFeeReceiver, address _founderFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
        founderFeeReceiver = _founderFeeReceiver;
    }

    function setLotteryReceivers (address _dailyLotteryReceiver, address _weeklyLotteryReceiver, address _lotteryFeeReceiver) external authorized {
        dailyLotteryReceiver = _dailyLotteryReceiver;
        weeklyLotteryReceiver = _weeklyLotteryReceiver;
        lotteryFeeReceiver = _lotteryFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(PCSpair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }
    
    function getBUSDinlotteryFeeReceiver() public view returns (uint256) {
        return IBEP20(BUSD).balanceOf(lotteryFeeReceiver);
    }
    
    function getBUSDindailyLotteryReceiver() public view returns (uint256) {
        return IBEP20(BUSD).balanceOf(dailyLotteryReceiver);
    }
    
    function getBUSDinweeklyLotteryReceiver() public view returns (uint256) {
        return IBEP20(BUSD).balanceOf(weeklyLotteryReceiver);
    }
    
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event JackpotActive(uint256 duration);
    event BuyMultiplierActive(uint256 duration);
    event Launched(uint256 blockNumber, uint256 timestamp);
}