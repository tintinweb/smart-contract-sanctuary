/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

/**
 remove txlimit and max wallet to remove lp
 swapThreshold determines auto lp and conversion to dividend
 TaxMultipliersDuration - 180 min
 anti bot - unable to buy at 2 block after launch
 to add LP exclude and lp pair for maxwallet
 to send token to other wallet, exempt max wallet for new wallet to receive token if over limit. 
 to exempt from Tax receiver wallet must be exempted
 accuracy for liquidity backing is 100. 
 buyback and burn uses bnb in contract. need to change to 18 decimal
dividend is verified by deploying and verify the dividenddistributor.sol immediately after deploy main contract. bscscan will find a match auto. 
lottery Tax in busd
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

    function swapExactTokensForTokensSupportingTaxOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingTaxOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingTaxOnTransferTokens(
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
    uint256 public minDistribution = 1 * (10 ** 18);

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

        router.swapExactETHForTokensSupportingTaxOnTransferTokens{value: msg.value}(
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

    string constant _name = "bit4";
    string constant _symbol = "bit4";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1000000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 200; // 0.5%
    uint256 public maxWallet = _totalSupply / 50; // 2%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isMaxWalletExempt;
    mapping (address => bool) isTaxExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isWhitelistedForLimitedTrading;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isBlacklisted;

    uint256 public liquidityTax = 250; //added public
    uint256 public excaliburTax = 50;//added public
    uint256 public reflectionTax = 500;//added public
    uint256 public marketingTax = 300;//added public
    uint256 public lotteryTax = 500;//added public
    uint256 public kingTax = 100;//added public
    uint256 public lordTax = 50; //added public
    uint256 public totalfixedBuyTax = liquidityTax.add(excaliburTax).add(reflectionTax).add(marketingTax).add(lotteryTax).add(kingTax).add(lordTax);
    uint256 public totalBuyTax = 1750;
    uint256 public totalSellTax = 1750;
    uint256 public greenwallBuyTax = totalBuyTax;
    uint256 public redwallSellTax = totalSellTax;
    uint256 TaxDenominator = 10000;

 //   uint256 public lotterydraw = 2000 * (10 ** 18);
    uint256 public dailyratio = 50;
    uint256 public weeklyratio = 30;
    uint256 public monthlyratio = 20;
    uint256 lotterydenominator = 100;

    address public autoLiquidityReceiver;
    address public marketingTaxReceiver;
    address public lotteryTaxReceiver;
    address public kingTaxReceiver;
    address public lordTaxReceiver;
    address public dailyLotteryReceiver;
    address public weeklyLotteryReceiver;
    address public monthlyLotteryReceiver;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public PCSpair;
    address[] public pairs;

    uint256 public launchedAt;
    
    uint256 public PaperHandNumerator = 200;
    uint256 public DiamondHandNumerator = 50;
    uint256 public TaxMultipliersDenominator = 100;
    uint256 public TaxMultipliersTriggeredAt;
    uint256 public TaxMultipliersDuration = 180 minutes; // change to 24 hours
    
  
    bool public greenwallEnabled = true; 
    uint256 public greenwallTriggeredAt = 0;
    uint256 public greenwallNumerator = 25; 
    uint256 public greenwallDuration = 2 minutes; 
    uint256 public greenwallLimit = 1000;
    
    bool public redwallEnabled = true; 
    uint256 public redwallTriggeredAt = 0;
    uint256 public redwallNumerator = 100; 
    uint256 public redwallDuration = 10 minutes; 
    uint256 public redwallLimit = 3000;
    
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
        isTaxExempt[owner_] = true;
        isTxLimitExempt[owner_] = true;
        isTaxExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true;
        isDividendExempt[address(this)] = true;
        isWhitelistedForLimitedTrading[owner_] = true;
        isWhitelistedForLimitedTrading[address(this)] = true;
        isDividendExempt[PCSpair] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = 0x8CBB5Ed5dA07c32Bfa693BCD9ff5078FCDcEc8f7;//msg.sender;
        marketingTaxReceiver = 0x0205b4D6905461B73Fd054B310aa7E2Fe777171c; //msg.sender;
        lotteryTaxReceiver = 0xd9671dd6BA1D15Ed0afBbAe58778B7f088E1D9d0;//msg.sender;
        kingTaxReceiver = 0x983514e31583a9e3Cd61a7B06be325D3Ed81F48A;//msg.sender;
        lordTaxReceiver = 0x81d3815092D45F2271DA501f35eE5Eca677f9757;//msg.sender;
        dailyLotteryReceiver = 0xfe7048cC89a787C16822fADb156D4D736c4D2D5B;
        weeklyLotteryReceiver = 0xF1cB2Dce01E9E58a327FCB48BAad3c2DEE116BE5;
        monthlyLotteryReceiver= 0x58f811E8Dd77469E93ceCE0089fF06bbE6399FC8;
        

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
  
        if(block.timestamp > greenwallTriggeredAt.add(greenwallDuration)){greenwallBuyTax = totalBuyTax;}
        
        if(shouldAutoBuyback()){ triggerAutoBuyback(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        address _address = isSell(recipient) ? sender : recipient; 
    
        uint256 amountReceived = shouldTakeTax(_address) ? takeTax(sender, recipient, amount) : amount; //changed to _address
        
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

    function shouldTakeTax(address _address) public view returns (bool) { // original internal //added recipient
        return !isTaxExempt[_address];
       // return !isTaxExempt[sender]; // replaced with top line
    }
    
    function getTotalTax(bool selling) public view returns (uint256) { 
        if (launchedAt + 2 >= block.number){ return TaxDenominator.sub(1); }
        if (selling && TaxMultipliersTriggeredAt.add(TaxMultipliersDuration) > block.timestamp) {return getPaperHandTax();}
        if (!selling && TaxMultipliersTriggeredAt.add(TaxMultipliersDuration) > block.timestamp) {return getDiamondHandTax();}
        if (!selling && greenwallTriggeredAt.add(greenwallDuration) > block.timestamp) {return getgreenwallbuyTax();}  
        if (selling && redwallTriggeredAt.add(redwallDuration) > block.timestamp) {return getredwallsellTax();} 
        return selling ? totalSellTax : totalBuyTax;
    }
    
    function getgreenwallbuyTax() public view returns (uint256) { 
        uint256 totalTax = greenwallBuyTax;
        return totalTax;
    }
    
    function getredwallsellTax() public view returns (uint256) { 
        uint256 totalTax = redwallSellTax;
        return totalTax;
    }
 
    function getPaperHandTax() public view returns (uint256) {
        uint256 totalTax = totalSellTax;
        uint256 remainingTime = TaxMultipliersTriggeredAt.add(TaxMultipliersDuration).sub(block.timestamp);
        uint256 TaxIncrease = totalTax.mul(PaperHandNumerator).div(TaxMultipliersDenominator).sub(totalTax);
        return totalTax.add(TaxIncrease.mul(remainingTime).div(TaxMultipliersDuration));
    }

    function getDiamondHandTax() public view returns (uint256) {
        uint256 totalTax = totalBuyTax;
        uint256 remainingTime = TaxMultipliersTriggeredAt.add(TaxMultipliersDuration).sub(block.timestamp);
        uint256 TaxDecrease = totalTax.sub(totalTax.mul(DiamondHandNumerator).div(TaxMultipliersDenominator));
        return totalTax.sub(TaxDecrease.mul(remainingTime).div(TaxMultipliersDuration));
    }

    function takeTax(address sender, address recipient, uint256 amount) internal returns (uint256) {
        isBuy(sender) == true ? greenwall() : redwall(); //trigger wall
        
        uint256 TaxAmount = amount.mul(getTotalTax(isSell(recipient))).div(TaxDenominator);
        _balances[address(this)] = _balances[address(this)].add(TaxAmount);
        emit Transfer(sender, address(this), TaxAmount);

        return amount.sub(TaxAmount);
    }
    function greenwall () internal {
        greenwallTriggeredAt = block.timestamp;
        redwallSellTax = totalSellTax;
        greenwallBuyTax > greenwallLimit ? greenwallBuyTax -= greenwallNumerator : greenwallBuyTax = greenwallBuyTax.sub(0);
    }
    
     function redwall () internal {
        redwallTriggeredAt = block.timestamp;
        redwallSellTax < redwallLimit ? redwallSellTax += redwallNumerator : redwallSellTax = redwallSellTax.add(0);
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
        uint256 dynamicLiquidityTax = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityTax;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityTax).div(totalfixedBuyTax).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingTaxOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 totalBNBTax = totalfixedBuyTax.sub(dynamicLiquidityTax.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityTax).div(totalBNBTax).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionTax).div(totalBNBTax);
        uint256 amountBNBMarketing = amountBNB.mul(marketingTax).div(totalBNBTax);
        uint256 amountBNBLottery = amountBNB.mul(lotteryTax).div(totalBNBTax);
        uint256 amountBNBKing = amountBNB.mul(kingTax).div(totalBNBTax);
        uint256 amountBNBLord = amountBNB.mul(lordTax).div(totalBNBTax);
        
        swapAndSendToTax(amountBNBLottery);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        payable(marketingTaxReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        payable(kingTaxReceiver).call{value: amountBNBKing, gas: 30000}("");
        payable(lordTaxReceiver).call{value: amountBNBLord, gas: 30000}("");
        
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
    
    function swapAndSendToTax(uint256 tokens) private  {

        uint256 initialBUSDBalance = IBEP20(BUSD).balanceOf(address(this));
        swapToBUSD(tokens);
        uint256 newBalance = (IBEP20(BUSD).balanceOf(address(this))).sub(initialBUSDBalance);
       
        uint256 amountdailylottery = newBalance.mul(dailyratio).div(lotterydenominator);//50% of lottery  
        uint256 amountweeklylottery = newBalance.mul(weeklyratio).div(lotterydenominator);//30% of lottery 
        uint256 amountmonthlylottery = newBalance.mul(monthlyratio).div(lotterydenominator);//20% of lottery 
        
        IBEP20(BUSD).transfer(dailyLotteryReceiver, amountdailylottery);
        IBEP20(BUSD).transfer(weeklyLotteryReceiver, amountweeklylottery);
        IBEP20(BUSD).transfer(monthlyLotteryReceiver, amountmonthlylottery);
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

    function triggerExcalibur(uint256 amount, bool triggerJackpotMultiplier) external authorized {
        buyTokens(amount, DEAD);
        if(triggerJackpotMultiplier){
            TaxMultipliersTriggeredAt = block.timestamp;
            emit JackpotMultiplierActive(TaxMultipliersDuration);
        }
    }
    
    function triggerJackpot(bool triggerJackpotMultiplier) external authorized {
        if(triggerJackpotMultiplier){
            TaxMultipliersTriggeredAt = block.timestamp;
            emit JackpotMultiplierActive(TaxMultipliersDuration);
        }
    }
    
    function clearJackpotMultiplier() external authorized {
        TaxMultipliersTriggeredAt = 0;
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

        router.swapExactETHForTokensSupportingTaxOnTransferTokens{value: amount}(
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
        TaxMultipliersDenominator = denominator;
        TaxMultipliersDuration = length;
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

    function setIsTaxExempt(address holder, bool exempt) external authorized {
        isTaxExempt[holder] = exempt;
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

    function setTax(uint256 _lotteryTax, uint256 _kingTax, uint256 _lordTax, uint256 _liquidityTax, uint256 _excaliburTax, uint256 _reflectionTax, uint256 _marketingTax, uint256 _TaxDenominator, uint256 _totalSellTax) external authorized {
        liquidityTax = _liquidityTax;
        excaliburTax = _excaliburTax;
        reflectionTax = _reflectionTax;
        marketingTax = _marketingTax;
        lotteryTax = _lotteryTax;
        kingTax = _kingTax;
        lordTax = _lordTax;
        totalBuyTax = liquidityTax.add(_excaliburTax).add(_reflectionTax).add(_marketingTax).add(_lotteryTax).add(_kingTax).add(_lordTax);
        totalSellTax = _totalSellTax;
        TaxDenominator = _TaxDenominator;
        require(totalBuyTax <= TaxDenominator * 30 / 100, "Buy Tax too high");
        require(totalSellTax <= TaxDenominator * 30 / 100, "Sell Tax too high");
        
        require(_liquidityTax <= TaxDenominator * 10 / 100, "Liq Tax too high");
        require(_excaliburTax <= TaxDenominator * 10 / 100, "Excalibur Tax too high");
        require(_reflectionTax <= TaxDenominator * 10 / 100, "Reward Tax too high");
        require(_marketingTax <= TaxDenominator * 10 / 100, "Marketing Tax too high");
        require(_lotteryTax <= TaxDenominator * 10 / 100, "Lottery Tax too high");
        require(_kingTax <= TaxDenominator * 10 / 100, "King Tax too high");
        require(_lordTax <= TaxDenominator * 10 / 100, "Lord Tax too high");
    }

    function setLotteryTax (uint256 _dailyratio, uint256 _weeklyratio, uint256 _monthlyratio) external authorized{
        dailyratio = _dailyratio;
        weeklyratio = _weeklyratio;
        monthlyratio = _monthlyratio;
    }

    function setTaxReceivers(address _autoLiquidityReceiver, address _marketingTaxReceiver, address _lotteryTaxReceiver, address _kingTaxReceiver, address _lordTaxReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingTaxReceiver = _marketingTaxReceiver;
        lotteryTaxReceiver = _lotteryTaxReceiver;
        kingTaxReceiver = _kingTaxReceiver;
        lordTaxReceiver = _lordTaxReceiver;
    }
    
    function setLotteryReceivers (address _dailyLotteryReceiver, address _weeklyLotteryReceiver, address _monthlyLotteryReceiver) external authorized {
        dailyLotteryReceiver = _dailyLotteryReceiver;
        weeklyLotteryReceiver = _weeklyLotteryReceiver;
        monthlyLotteryReceiver = _monthlyLotteryReceiver;
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
    
    //additional 
    function getisTaxExempt(address holder) public view returns (bool) {
        return isTaxExempt[holder];
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
/**
    function getBUSDinlotteryTaxReceiver() public view returns (uint256) {
        return IBEP20(BUSD).balanceOf(lotteryTaxReceiver);
    }
    */
    function getBUSDindailyLotteryReceiver() public view returns (uint256) {
        return IBEP20(BUSD).balanceOf(dailyLotteryReceiver);
    }
    function getBUSDinweeklyLotteryReceiver() public view returns (uint256) {
        return IBEP20(BUSD).balanceOf(weeklyLotteryReceiver);
    }
      function getBUSDinmonthlyLotteryReceiver() public view returns (uint256) {
        return IBEP20(BUSD).balanceOf(monthlyLotteryReceiver);
    }
    
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event JackpotMultiplierActive(uint256 duration);
    event BuyMultiplierActive(uint256 duration);
    event Launched(uint256 blockNumber, uint256 timestamp);
}