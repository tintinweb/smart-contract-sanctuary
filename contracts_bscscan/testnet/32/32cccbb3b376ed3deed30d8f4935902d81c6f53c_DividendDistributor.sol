/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

/**
 remove txlimit and max wallet to remove lp
 swapThreshold determines auto lp and conversion to dividend
 feeMultipliersDuration - 180 min
 anti bot - unable to buy at 2 block after launch
 to add LP exclude and lp pair for maxwallet
 to send token to other wallet, exempt max wallet for new wallet to receive token if over limit. 
 to exempt from fee receiver wallet must be exempted
 accuracy for liquidity backing is 100. 
 buyback and burn uses bnb in contract. need to change to 18 decimal
dividend is verified by deploying and verify the dividenddistributor.sol immediately after deploy main contract. bscscan will find a match auto. 
lottery fee in busd
Mindistribution - 3x10**13 = 0.00003 btcb

to test:
combination of buy and sell tax
Sell tax didn’t drop

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

    address BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address BTCB = 0x8BaBbB98678facC7342735486C851ABD7A0d17Ca;
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "bit11";
    string constant _symbol = "bit11";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 200; // 0.5%
    uint256 public maxWallet = _totalSupply / 50; // 2%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isMaxWalletExempt;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isWhitelistedForLimitedTrading;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isBlacklisted;

    uint256 public liquidityFee = 250; //added public
    uint256 public buybackFee = 50;//added public
    uint256 public reflectionFee = 500;//added public
    uint256 public marketingFee = 300;//added public
    uint256 public lotteryFee = 500;//added public
    uint256 public devFee = 100;//added public
    uint256 public founderFee = 50; //added public
    uint256 public totalfixedBuyFee = liquidityFee.add(buybackFee).add(reflectionFee).add(marketingFee).add(lotteryFee).add(devFee).add(founderFee);
    uint256 public totalBuyFee = 1775;
    uint256 public totalSellFee = 1700;
    uint256 public greenwallBuyFee = totalBuyFee;
    uint256 public redwallSellFee = totalSellFee;
    uint256 feeDenominator = 10000;
/**
    uint256 public lotterydraw = 2000 * (10 ** 18);
    uint256 public dailyratio = 50;
    uint256 public weeklyratio = 30;
    uint256 public monthlyratio = 20;
    uint256 lotterydenominator = 100;
    address public dailyLotteryReceiver;
    address public weeklyLotteryReceiver;
    address public monthlyLotteryReceiver;
    dailyLotteryReceiver = 0xfe7048cC89a787C16822fADb156D4D736c4D2D5B;
    weeklyLotteryReceiver = 0xF1cB2Dce01E9E58a327FCB48BAad3c2DEE116BE5;
    monthlyLotteryReceiver= 0x58f811E8Dd77469E93ceCE0089fF06bbE6399FC8;
    
*/
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
    uint256 public feeMultipliersDenominator = 100;
    uint256 public feeMultipliersTriggeredAt;
    uint256 public feeMultipliersDuration = 180 minutes; // change to 24 hours
    
  
    bool public greenwallEnabled = true; 
    uint256 public greenwallTriggeredAt = 0;
    uint256 public greenwallNumerator = 25; 
    uint256 public greenwallDuration = 10 minutes; 
    uint256 public greenwallLimit = 1200;
    
    bool public redwallEnabled = true; 
    uint256 public redwallTriggeredAt = 0;
    uint256 public redwallNumerator = 50; 
    uint256 public redwallDuration = 20 minutes; 
    uint256 public redwallLimit = 2480;
    
    bool public tradingLimited = true;
   
    bool autoBuybackEnabled = false;
    uint256 autoBuybackCap; 
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

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

        autoLiquidityReceiver = 0x8CBB5Ed5dA07c32Bfa693BCD9ff5078FCDcEc8f7;//msg.sender;
        marketingFeeReceiver = 0x0205b4D6905461B73Fd054B310aa7E2Fe777171c; //msg.sender;
        lotteryFeeReceiver = 0xd9671dd6BA1D15Ed0afBbAe58778B7f088E1D9d0;//msg.sender;
        devFeeReceiver = 0x983514e31583a9e3Cd61a7B06be325D3Ed81F48A;//msg.sender;
        founderFeeReceiver = 0x81d3815092D45F2271DA501f35eE5Eca677f9757;//msg.sender;

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
        
        if(shouldSwapBack()){ swapBack(); }
     //   if(IBEP20(BUSD).balanceOf(lotteryFeeReceiver) > lotterydraw){sendLottery();}
        if(block.timestamp > greenwallTriggeredAt.add(greenwallDuration)){greenwallBuyFee = totalBuyFee;}
        if(block.timestamp > redwallTriggeredAt.add(redwallDuration)){redwallSellFee = totalSellFee;}
        
        if(shouldAutoBuyback()){ triggerAutoBuyback(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        address _address = isSell(recipient) ? sender : recipient; 
    
        uint256 amountReceived = shouldTakeFee(_address) ? takeFee(sender, recipient, amount) : amount; //changed to _address
        
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

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view { //added recipient
        require(amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded"); //added txlimitexempt[recipient]
    }
    
    function checkMaxWallet(address recipient, uint256 amount) internal view { 
        require(balanceOf(recipient)+amount <= maxWallet || isMaxWalletExempt[recipient], "Max Wallet Exceeded 2%"); //added for maxWallet
    }

    function checkAllowedToTrade(address sender, address recipient) public view returns (bool){ //added returns (bool)
        require(isWhitelistedForLimitedTrading[sender] || isWhitelistedForLimitedTrading[recipient], "Not whitelisted while trading is limited.");
        return isWhitelistedForLimitedTrading[sender]; //added to return the address
    }

    function shouldTakeFee(address _address) public view returns (bool) { // original internal //added recipient
        return !isFeeExempt[_address];
       // return !isFeeExempt[sender]; // replaced with top line
    }
    
    function getTotalFee(bool selling) public view returns (uint256) { 
        if (launchedAt + 2 >= block.number){ return feeDenominator.sub(1); }
        if (selling && feeMultipliersTriggeredAt.add(feeMultipliersDuration) > block.timestamp) {return getPaperHandFee();}
        if (!selling && feeMultipliersTriggeredAt.add(feeMultipliersDuration) > block.timestamp) {return getDiamondHandFee();}
        if (!selling && greenwallTriggeredAt.add(greenwallDuration) > block.timestamp) {return getgreenwallbuyFee();}  
        if (selling && redwallTriggeredAt.add(redwallDuration) > block.timestamp) {return getredwallsellFee();} 
        return selling ? totalSellFee : totalBuyFee;
    }
    
    function getgreenwallbuyFee() public view returns (uint256) { 
        uint256 totalFee = greenwallBuyFee;
        return totalFee;
    }
    
    function getredwallsellFee() public view returns (uint256) { 
        uint256 totalFee = redwallSellFee;
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

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        isBuy(sender) == true ? greenwall() : redwall(); //trigger wall
        uint256 feeAmount = amount.mul(getTotalFee(isSell(recipient))).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }
    function greenwall () internal {
        greenwallTriggeredAt = block.timestamp;
      //  redwallSellFee = totalSellFee;
        greenwallBuyFee > greenwallLimit ? greenwallBuyFee -= greenwallNumerator : greenwallBuyFee = greenwallBuyFee.sub(0);
        redwallSellFee < redwallLimit ? redwallSellFee += redwallNumerator : redwallSellFee = redwallSellFee.add(0);
    }
    
     function redwall () internal {
        redwallTriggeredAt = block.timestamp;
        redwallSellFee < redwallLimit ? redwallSellFee += redwallNumerator : redwallSellFee = redwallSellFee.add(0);
        greenwallBuyFee > greenwallLimit ? greenwallBuyFee -= greenwallNumerator : greenwallBuyFee = greenwallBuyFee.sub(0);
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
      //  payable(lotteryFeeReceiver).call{value: amountBNBLottery, gas: 30000}("");
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
    
/**added for lottery busd
    function sendLottery() private {
        uint256 daily = lotterydraw.mul(dailyratio).div(lotterydenominator);
        uint256 weekly = lotterydraw.mul(weeklyratio).div(lotterydenominator);
        uint256 monthly = lotterydraw.mul(monthlyratio).div(lotterydenominator);
        IBEP20(BUSD).transfer(dailyLotteryReceiver,daily);
        IBEP20(BUSD).transfer(weeklyLotteryReceiver,weekly);
        IBEP20(BUSD).transfer(monthlyLotteryReceiver, monthly);
    }
    */
    function swapAndSendToFee(uint256 tokens) private  {

        uint256 initialBUSDBalance = IBEP20(BUSD).balanceOf(address(this));
        swapToBUSD(tokens);
        uint256 newBalance = (IBEP20(BUSD).balanceOf(address(this))).sub(initialBUSDBalance);
        IBEP20(BUSD).transfer(lotteryFeeReceiver, newBalance);
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

   function setgreenwall(bool _greenwallenabled, uint256 _greenwallperiod, uint256 _greenwallnumerator, uint256 _greenwallLimit) external authorized { // removed uint _greenwalldenominator
        greenwallEnabled = _greenwallenabled;
        greenwallDuration = _greenwallperiod;
        greenwallNumerator = _greenwallnumerator;
        greenwallLimit = _greenwallLimit;
    }
    
    function setredwall(bool _redwallenabled, uint256 _redwallperiod, uint256 _redwallnumerator, uint256 _redwallLimit) external authorized {
        redwallEnabled = _redwallenabled;
        redwallDuration = _redwallperiod;
        redwallNumerator = _redwallnumerator;
        redwallLimit = _redwallLimit;
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

    function setMaxWallet(uint256 newmaxWallet) public authorized { 
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

    function setFees(uint256 _lotteryFee, uint256 _devFee, uint256 _founderFee, uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator, uint256 _totalSellFee) external authorized {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        lotteryFee = _lotteryFee;
        devFee = _devFee;
        founderFee = _founderFee;
        totalBuyFee = liquidityFee.add(_buybackFee).add(_reflectionFee).add(_marketingFee).add(_lotteryFee).add(_devFee).add(_founderFee);
        totalSellFee = _totalSellFee;
        feeDenominator = _feeDenominator;
        require(totalBuyFee <= feeDenominator * 35 / 100, "Buy fee too high");
        require(totalSellFee <= feeDenominator * 35 / 100, "Sell fee too high");
        
        require(_liquidityFee <= feeDenominator * 10 / 100, "Liq fee too high");
        require(_buybackFee <= feeDenominator * 10 / 100, "Buyback fee too high");
        require(_reflectionFee <= feeDenominator * 15 / 100, "Reward fee too high");
        require(_marketingFee <= feeDenominator * 15 / 100, "Marketing fee too high");
        require(_lotteryFee <= feeDenominator * 15 / 100, "Lottery fee too high");
        require(_devFee <= feeDenominator * 10 / 100, "Dev fee too high");
        require(_founderFee <= feeDenominator * 10 / 100, "Founder fee too high");
    }
    /**
    function setLotteryFee (uint256 _lotterydraw, uint256 _dailyratio, uint256 _weeklyratio, uint256 _monthlyratio) external authorized{
        lotterydraw = _lotterydraw;
        dailyratio = _dailyratio;
        weeklyratio = _weeklyratio;
        monthlyratio = _monthlyratio;
    }
*/
    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _lotteryFeeReceiver, address _devFeeReceiver, address _founderFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        lotteryFeeReceiver = _lotteryFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
        founderFeeReceiver = _founderFeeReceiver;
    }
    /**
    function setLotteryReceivers (address _dailyLotteryReceiver, address _weeklyLotteryReceiver, address _monthlyLotteryReceiver) external authorized {
        dailyLotteryReceiver = _dailyLotteryReceiver;
        weeklyLotteryReceiver = _weeklyLotteryReceiver;
        monthlyLotteryReceiver = _monthlyLotteryReceiver;
    }
*/
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
    
    //additional 
    function getisFeeExempt(address holder) public view returns (bool) {
        return isFeeExempt[holder];
    }
    function getIsDividendExempt(address holder) public view returns (bool) {
        return isDividendExempt[holder];
    }
    function getisTxLimitExempt(address holder) public view returns (bool) {
        return isTxLimitExempt[holder];
    }
    function getisMaxWalletExempt(address holder) public view returns (bool) {
        return isMaxWalletExempt[holder];
    }
//added for lottery busd
    function getBUSDinlotteryFeeReceiver() public view returns (uint256) {
        return IBEP20(BUSD).balanceOf(lotteryFeeReceiver);
    }
    /**
    function getBUSDindailyLotteryReceiver() public view returns (uint256) {
        return IBEP20(BUSD).balanceOf(dailyLotteryReceiver);
    }
    function getBUSDinweeklyLotteryReceiver() public view returns (uint256) {
        return IBEP20(BUSD).balanceOf(weeklyLotteryReceiver);
    }
      function getBUSDinmonthlyLotteryReceiver() public view returns (uint256) {
        return IBEP20(BUSD).balanceOf(monthlyLotteryReceiver);
    }
    */
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event JackpotActive(uint256 duration);
    event BuyMultiplierActive(uint256 duration);
    event Launched(uint256 blockNumber, uint256 timestamp);
}