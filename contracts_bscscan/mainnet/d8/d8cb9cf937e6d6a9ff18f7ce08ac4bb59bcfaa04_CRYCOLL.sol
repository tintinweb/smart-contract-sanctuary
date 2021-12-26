/**
 *Submitted for verification at BscScan.com on 2021-12-26
*/

/**
Designed and implemented by Crycoll Team
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
    
    function getAmountsOut(
        uint amountIn, 
        address[] calldata path
        ) external view returns (uint[] memory amounts);
    
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minTokens, uint256 _annualMulipler, uint256 _penaltyPercentage, uint256 _dividendBUSDtrigger, uint256 _IntervalEstablishPool, uint256 _lowerLimiter, uint256 _upperLimiter) external;
    function setShare(address shareholder, uint256 amount) external;
    function getMultipleShare(address shareholder, uint256 lockTime, bool auto_Lock) external;
    function withdrawTokens(address shareholder) external;
    function unlockTokensWithBreak(address shareholder) external;
    function claimDividend(address shareholder) external;    
    function deposit() external payable;
    function process(uint256 gas) external;
    function establishPool() external;    
    function shouldEstablishPool() external view returns(bool);
    function getInfo(bool hideDecimal) external view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256); 
    function getSharesInfo(address shareholder) external view returns(uint256, uint256, uint256, bool);
    function getLockerInfo(address shareholder) external view returns(uint256, uint256, uint256, bool);    
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    IBEP20 bep_token;

    struct Share {
        uint256 amount;
        uint256 totalRealised;
    }

    struct TokensLocker {
        uint256 unlockTime;
        uint256 tokensLocked;
        uint256 tokensUnlocked;
        uint256 lastLockTime;
        bool autoLock;
    }

    IBEP20 BUSD = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => bool) dividendReceived;

    mapping (address => Share) public shares;
    mapping (address => TokensLocker) public locker;

    uint256 public lastDividendPool;
    uint256 public dividendPool;
    uint256 public nextDividendPool;   
    uint256 public excludedShares;
    uint256 public totalDistributed;

    uint256 public minTokens = 10000 * (10 ** 18); // hold 10,000+ CRY tokens to receive dividends
    uint256 public annualMulipler = 365;
    uint256 public penaltyPercentage = 40;
    uint256 public dividendBUSDtrigger = 100 * (10 ** 18);
    uint256 public IntervalEstablishPool = 7 days;
    uint256 public dividendPoolTimestamp;
    uint256 public lowerLimiter = 7;
    uint256 public upperLimiter = 180;

    
    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
       require(msg.sender == address(bep_token)); _;
    }

    constructor (address _router) {
        router = _router != address(0)
        ? IDEXRouter(_router)
        : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        bep_token = IBEP20(msg.sender);
            
    }

    function setDistributionCriteria(uint256 _minTokens, uint256 _annualMulipler, uint256 _penaltyPercentage, uint256 _dividendBUSDtrigger, uint256 _IntervalEstablishPool, uint256 _lowerLimiter, uint256 _upperLimiter) external override onlyToken {
        require(_penaltyPercentage < 90 && _penaltyPercentage > 10, "Invalid penalty percentage");
        require(_lowerLimiter < _upperLimiter, "Invalid locker limiter");
        minTokens = _minTokens;
        annualMulipler = _annualMulipler;
        penaltyPercentage = _penaltyPercentage;
        dividendBUSDtrigger = _dividendBUSDtrigger;
        IntervalEstablishPool = _IntervalEstablishPool;
        lowerLimiter = _lowerLimiter;
        upperLimiter = _upperLimiter;
    }

    function getMultipleShare(address shareholder, uint256 lockTime, bool auto_Lock) external override onlyToken {
         lockTokens(shareholder, lockTime);
         locker[shareholder].autoLock = auto_Lock;
    }

    function lockTokens(address shareholder, uint256 lockTime) internal {
        uint256 amount = locker[shareholder].tokensUnlocked;
        require(amount > 0, "No unlocked tokens on the smart contract");
        uint256 localUpperLimiter = upperLimiter;
        //if locking more than 100,000 tokens, the locking time limit changes
        if(amount >= minTokens.mul(10)){ localUpperLimiter = upperLimiter.mul(2); }
        if(lockTime < lowerLimiter ){ lockTime = lowerLimiter; }
        else if(lockTime > localUpperLimiter ){ lockTime = localUpperLimiter; }

        locker[shareholder].lastLockTime = lockTime;
      
        uint256 mulAmount = amount.div(100) * ((lockTime.mul(annualMulipler)).div(365));
        mulAmount = amount.add(mulAmount);
        lockTime = lockTime * 1 days;

        if (locker[shareholder].unlockTime <= block.timestamp 
             || block.timestamp + lockTime > locker[shareholder].unlockTime){
             locker[shareholder].unlockTime = block.timestamp + lockTime;
        }

        locker[shareholder].tokensLocked += locker[shareholder].tokensUnlocked; 
        locker[shareholder].tokensUnlocked = 0;               
        shares[shareholder].amount += mulAmount;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {       
        if(amount >= minTokens && locker[shareholder].tokensUnlocked + locker[shareholder].tokensLocked == 0){
            addShareholder(shareholder);
        }
        locker[shareholder].tokensUnlocked += amount;
    }

    function withdrawTokens(address shareholder) external override onlyToken {
        if(locker[shareholder].unlockTime < block.timestamp){
        locker[shareholder].tokensUnlocked += locker[shareholder].tokensLocked;
        locker[shareholder].tokensLocked = 0; 
        locker[shareholder].unlockTime = 0;   
        shares[shareholder].amount = 0;            
        }
        require(locker[shareholder].tokensUnlocked > 0, "No unlocked tokens on the smart contract");

        bep_token.transfer(shareholder, locker[shareholder].tokensUnlocked);
        locker[shareholder].tokensUnlocked = 0;
        
        if(locker[shareholder].tokensLocked == 0){
            removeShareholder(shareholder);
        }
    }

    function unlockTokensWithBreak(address shareholder) external override onlyToken {
        require(locker[shareholder].tokensUnlocked + locker[shareholder].tokensLocked > 0, "No tokens on the smart contract");
        uint256 penaltyAmount;
        if(locker[shareholder].unlockTime > block.timestamp && locker[shareholder].tokensLocked > 0){
            //penalty for withdrawing locked tokens
            penaltyAmount = locker[shareholder].tokensLocked.mul(penaltyPercentage).div(100);
            locker[shareholder].tokensLocked = locker[shareholder].tokensLocked.sub(penaltyAmount);
            shares[shareholder].amount = 0;
            bep_token.transfer(address(bep_token), penaltyAmount);       
        }
        locker[shareholder].tokensUnlocked += locker[shareholder].tokensLocked;  
        locker[shareholder].tokensLocked = 0;   
        bep_token.transfer(shareholder, locker[shareholder].tokensUnlocked);
        locker[shareholder].tokensUnlocked = 0;   
        removeShareholder(shareholder);
    }

    function getTotalShares() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < shareholders.length; i++) {
            total += shares[shareholders[i]].amount;
        }
        return total;
    }

    function getTotalLockedTokens() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < shareholders.length; i++) {
            total += locker[shareholders[i]].tokensLocked;
        }
        return total;
    }

    function clearDividendReceived() internal {
        for (uint256 i = 0; i < shareholders.length; i++) {
            dividendReceived[shareholders[i]] = false;
        }
    }    

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = BUSD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(BUSD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BUSD.balanceOf(address(this)).sub(balanceBefore);
        nextDividendPool = nextDividendPool.add(amount);
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

    function establishPool() external override onlyToken {
        nextDividendPool = 0;
        dividendPool = BUSD.balanceOf(address(this));
        lastDividendPool = dividendPool;
        excludedShares = 0;
        clearDividendReceived();
        dividendPoolTimestamp = block.timestamp + IntervalEstablishPool;    
    }

    function shouldDistribute(address shareholder) internal view returns  (bool) {
        return !dividendReceived[shareholder]
        && forecastDividend(shareholder) > 5 * (10 ** 17);
    }

    function shouldEstablishPool() public view returns (bool) {
        return BUSD.balanceOf(address(this)) >= dividendBUSDtrigger
        && dividendPoolTimestamp <= block.timestamp;
    }    

    function forecastDividend(address shareholder) internal view returns (uint256) {
        if(excludedShares >= getTotalShares()){ return 0;} 
        uint256 totalSharesPool = getTotalShares().sub(excludedShares);
        return shares[shareholder].amount.mul(dividendPool).div(totalSharesPool);
    }

    function distributeDividend(address shareholder) internal {
        if(locker[shareholder].unlockTime < block.timestamp && locker[shareholder].tokensLocked > 0){
            locker[shareholder].tokensUnlocked += locker[shareholder].tokensLocked;
            locker[shareholder].tokensLocked = 0;
            shares[shareholder].amount = 0;
            if(locker[shareholder].autoLock) {lockTokens(shareholder, locker[shareholder].lastLockTime);}
        } 

        uint256 amount = forecastDividend(shareholder);
        if(amount > 0 && amount <= dividendPool){
            totalDistributed = totalDistributed.add(amount);
            BUSD.transfer(shareholder, amount);
            dividendPool = dividendPool.sub(amount);
            excludedShares = excludedShares.add(shares[shareholder].amount);
            dividendReceived[shareholder] = true;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
        }
    }

    function claimDividend(address shareholder) external override onlyToken {
        if(shouldDistribute(shareholder)) { distributeDividend(shareholder); }
    }

    function getSharesInfo(address shareholder) public view returns (uint256, uint256, uint256, bool) {
        return (
            shares[shareholder].amount, 
            shares[shareholder].totalRealised, 
            forecastDividend(shareholder), 
            dividendReceived[shareholder]
            );
    }    

    function getLockerInfo(address shareholder) public view returns (uint256, uint256, uint256, bool) {
        return (
            locker[shareholder].tokensUnlocked,           
            locker[shareholder].tokensLocked, 
            locker[shareholder].unlockTime, 
            locker[shareholder].autoLock
        );
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
    
    function getInfo(bool hideDecimal) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 shareholderCount = shareholders.length;
        uint256 pool = dividendPool;
        uint256 total_shares = getTotalShares();
        if(excludedShares < total_shares) { total_shares = total_shares.sub(excludedShares); }
        if(lastDividendPool > pool){ pool = lastDividendPool; }
        else if(nextDividendPool > pool){ pool = nextDividendPool; }
        uint256 dividendsPerShare = pool.div(total_shares);
        if(hideDecimal){ return (
            getTotalShares().div(10 ** 18), 
            getTotalLockedTokens().div(10 ** 18), 
            lastDividendPool.div(10 ** 18),
            dividendPool.div(10 ** 18), 
            nextDividendPool.div(10 ** 18), 
            totalDistributed.div(10 ** 18), 
            dividendsPerShare, 
            minTokens.div(10 ** 18), 
            annualMulipler, 
            penaltyPercentage, 
            shareholderCount
            );
        } 
        else return (
            getTotalShares(),
            getTotalLockedTokens(), 
            lastDividendPool,
            dividendPool, 
            nextDividendPool,
            totalDistributed, 
            dividendsPerShare, 
            minTokens, 
            annualMulipler, 
            penaltyPercentage, 
            shareholderCount
            );
    }

}

interface IAirdropFundWallet {
    function sendToken(address bridgeAirdropAddress, uint256 tokenToSend) external;
}

contract AirdropFundWallet is IAirdropFundWallet {
    using SafeMath for uint256;

    IBEP20 bep_token;
    
    modifier onlyToken() {
       require(msg.sender == address(bep_token)); _;
    }

    constructor () {
        bep_token = IBEP20(msg.sender);
             }

    function sendToken(address bridgeAirdropAddress, uint256 tokenToSend) external override onlyToken {
                bep_token.transfer(bridgeAirdropAddress, tokenToSend);
    }
}

interface IResenderWallet {

    function resend() external payable;
}

contract ResenderWallet is IResenderWallet {
    using SafeMath for uint256;

    IBEP20 bep_token;

    modifier onlyToken() {
       require(msg.sender == address(bep_token)); _;
    }

    constructor () {
        bep_token = IBEP20(msg.sender);
             }

    function resend() external payable override onlyToken {
            uint256 token_balance = bep_token.balanceOf(address(this));
            if (token_balance > 0){
                bep_token.transfer(address(bep_token), token_balance);
            }
    }
}

contract CRYCOLL is IBEP20, Auth {
    using SafeMath for uint256;

    uint256 public constant MASK = type(uint128).max;
    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Crycoll";
    string constant _symbol = "CRY";    
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.div(100); // 1%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;

    uint256 liquidityFee = 0;
    uint256 buybackFee = 30;
    uint256 dividendFee = 20;
    uint256 airdropFee = 10;
    uint256 totalFee = 60;
    uint256 feeDenominator = 1000;
    uint256 totalFeesCollected;
    
    IBEP20 LPtokens;

	bool public volumeLoops = false; 
	bool public dynamicFees = true;
    bool public priceRescueEnabled = false;  

    address public autoLiquidityReceiver;
    address public bridgeAirdropAddress;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;
    address dexRouter_;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;
    uint256 public lockLPTime;
    
    uint256 setPriceTimestamp;
    uint256 setPriceTimestampInterval = 7 days;
    uint256 previousPrice;
    uint256 currentPrice;
    uint256 priceChange;
    
    uint256 public minTokenBalance = 20000 * (10 ** 18);
    uint256 public temp_lock_time;
    uint256 public lockDuration = 1 days;

    bool public autoBuybackEnabled = false;
    mapping (address => bool) buyBacker;
    uint256 autoBuybackAmount = 20 * (10 ** 18);

    DividendDistributor distributor;
    address public distributorAddress;
    uint256 distributorGas = 700000;

    AirdropFundWallet airdropfund;
    address public airdropfundAddress;
    
    ResenderWallet resender;
    address public resenderAddress;
    
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 100000; // 0.05%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        dexRouter_ = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        router = IDEXRouter(dexRouter_);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        WBNB = router.WETH();
        distributor = new DividendDistributor(dexRouter_);
        distributorAddress = address(distributor);

        airdropfund = new AirdropFundWallet();
        airdropfundAddress = address(airdropfund);
        
        resender = new ResenderWallet();
        resenderAddress = address(resender);

        LPtokens = IBEP20(pair);

        autoLiquidityReceiver = msg.sender;
        bridgeAirdropAddress = 0x760489D41041E809d57638f8c778B669804CD1b5; 
        
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[distributorAddress] = true;
        isFeeExempt[airdropfundAddress] = true;
        isFeeExempt[bridgeAirdropAddress] = true;
        isFeeExempt[resenderAddress] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[distributorAddress] = true;
        isTxLimitExempt[airdropfundAddress] = true;
        isTxLimitExempt[resenderAddress] = true;
        
        isDividendExempt[pair] = true;
        isDividendExempt[distributorAddress] = true;
        isDividendExempt[airdropfundAddress] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[bridgeAirdropAddress] = true;
        isDividendExempt[resenderAddress] = true;
        isDividendExempt[DEAD] = true;
        
        buyBacker[msg.sender] = true;

        approve(dexRouter_, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply.mul(50).div(100);
        emit Transfer(address(0), msg.sender, _totalSupply.mul(50).div(100));       
        _balances[address(this)] = _totalSupply.mul(30).div(100);
        emit Transfer(address(0), address(this), _totalSupply.mul(30).div(100));           
        _balances[address(airdropfundAddress)] = _totalSupply.mul(20).div(100);             
        emit Transfer(address(0), address(airdropfundAddress), _totalSupply.mul(20).div(100));           
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    modifier onlyBuybacker() { require(buyBacker[msg.sender] == true, ""); _; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, amount);
        
        if(shouldSwapBack()){ swapBack(); }
        if(shouldAutoBuyback()){ triggerAutoBuyback(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender] && recipient == distributorAddress){ try distributor.setShare(sender, amountReceived) {} catch {} }        
        
        checkMarketCondition();

        if(distributor.shouldEstablishPool()){ try distributor.establishPool() {} catch {} }
        try distributor.process(distributorGas) {} catch {}

        if(shouldSendTokenFromAirdropFund()){ sendTokenFromAirdropFund(); }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
//        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require((amount <= _maxTxAmount && launched()) || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(address sender, address receiver) public view returns (uint256) {
        if (dynamicFees && receiver == pair) { 
            if (priceChange <= 60) { return totalFee.mul(400).div(100);  } //very strong downtrend
            else if (priceChange <= 70) { return totalFee.mul(300).div(100);  } //strong downtrend
            else if (priceChange <= 80 ) { return totalFee.mul(200).div(100);  } //downtrend
            else if (priceChange <= 100) { return totalFee.mul(150).div(100);  }
         }
       // a downtrend offers opportunities to buy tokens with very low fees
         else if (dynamicFees && sender == pair) {
            if (priceChange <= 70) { return totalFee.mul(10).div(100);  }
            else if (priceChange <= 80) { return totalFee.mul(20).div(100);  }
            else if (priceChange <= 100) { return totalFee.mul(50).div(100);  } 
         }
        return totalFee;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(sender, receiver)).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        
        totalFeesCollected = totalFeesCollected.add(feeAmount);
        return amount.sub(feeAmount);
    }
    
    function checkMarketCondition() internal {
        if(launched()) { updateCurrentPrice(); }
        if(setPriceTimestamp <= block.timestamp && currentPrice > 0){ updatePreviousPrice(); }
        if(previousPrice > 0 ) { priceChange = currentPrice.mul(100).div(previousPrice);}    
    }   

    function updateCurrentPrice() internal {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);
        setCurrentPrice(router.getAmountsOut(1, path)); 
    }
    
    function setCurrentPrice(uint256[] memory amounts) internal {
        uint256 amountWBNB = amounts[0];
        uint256 amountTOKEN = amounts[1];
        currentPrice = amountWBNB.mul(10**18).div(amountTOKEN);
    }

    function updatePreviousPrice() internal {
        if (previousPrice < currentPrice) { previousPrice = currentPrice; } //force a price increase
        setPriceTimestamp = block.timestamp + setPriceTimestampInterval;
    }
    
    function shouldSendTokenFromAirdropFund() internal view returns (bool) {
        return balanceOf(bridgeAirdropAddress) < minTokenBalance
        && temp_lock_time <= block.timestamp //for security reasons, the contract may send one transaction per day
        && balanceOf(airdropfundAddress) > 0;
    }  
    
    function sendTokenFromAirdropFund() internal {
        uint256 tokenToSend = minTokenBalance.mul(5).sub(balanceOf(bridgeAirdropAddress));
        try airdropfund.sendToken(bridgeAirdropAddress, tokenToSend) {} catch {}
        temp_lock_time = block.timestamp + lockDuration; //temporary blocking of transfers
    }

    function priceRescue() internal view returns (bool) {
        return priceChange < 80
        && dynamicFees
        && priceRescueEnabled;
    }
    
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && launched()
        && !priceRescue()
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
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

        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));

		// if volumeLoops then use bnb only for buyback
        if(!volumeLoops){
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBDividend = amountBNB.mul(dividendFee).div(totalBNBFee);
        uint256 amountBNBAirdrop = amountBNB.mul(airdropFee).div(totalBNBFee);

        try distributor.deposit{value: amountBNBDividend}() {} catch {}
        payable(bridgeAirdropAddress).transfer(amountBNBAirdrop);

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
    }

    function triggerManualBuyback(uint256 amount, address to) external authorized {
        buyTokens(amount, to);
    }
    
    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && autoBuybackEnabled
        && address(this).balance >= autoBuybackAmount;
    }

    function triggerAutoBuyback() internal {
        if(volumeLoops) {        
            buyTokens(autoBuybackAmount, resenderAddress); //  if volumeloops is enabled send to RESENDER
            try resender.resend() {} catch {} // resend tokens to this contract
        } 
        else  buyTokens(autoBuybackAmount, airdropfundAddress); 
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

    function setAutoBuybackSettings(bool _enabled, uint256 _amount) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackAmount = _amount * (10 ** 18); //set in bnb
    }
	
    function setVolumeLoops(bool _enabled) external authorized {
		volumeLoops = _enabled;
    }

    function updatePriceTimestampInterval(uint256 _setPriceTimestampInterval) external authorized {
        setPriceTimestampInterval = _setPriceTimestampInterval * 1 days; //e.g if set to 10 then check price every 10 days
        setPriceTimestamp = block.timestamp;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function updateRouter(address newAddress) external authorized {
        require(newAddress != address(router), "The router already has that address");
        router = IDEXRouter(newAddress);
    }

    function launch() internal {
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }

    function provideFirstLP() external authorized {
        require(!launched(), "Already launched");
		uint256 amountBNBLiquidity = address(this).balance;
        uint256 amountTokenLiquidity = amountBNBLiquidity * 30000;  
        if(amountTokenLiquidity > balanceOf(address(this))) {amountTokenLiquidity = balanceOf(address(this));}      		
        //if any tokens remain on the smart contract then send them to the airdrop fund
        else if(amountTokenLiquidity < balanceOf(address(this))) { 
        this.transfer(airdropfundAddress, balanceOf(address(this)).sub(amountTokenLiquidity));
        }		
        router.addLiquidityETH{value: amountBNBLiquidity}(
        address(this),
        amountTokenLiquidity,
        0,
        0,
        address(this),
        block.timestamp);    

        lockLPTime = block.timestamp + 400 days; //lock LP for 400 days
        launch();

        emit firstLPprovided(amountBNBLiquidity, amountTokenLiquidity);
    }    

    function unlockLP() external authorized {
        require(block.timestamp >= lockLPTime, "The liquidity pool is still locked");	
		if(LPtokens.balanceOf(address(this)) > 0){  
        LPtokens.transfer(owner, LPtokens.balanceOf(address(this)));
        }
    }    

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 10000); //min 0.01%
        _maxTxAmount = amount * (10 ** _decimals); // max Tx amount in tokens
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.unlockTokensWithBreak(holder);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _dividendFee, uint256 _airdropFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        dividendFee = _dividendFee;
        airdropFee = _airdropFee;
        totalFee = _liquidityFee.add(_buybackFee).add(_dividendFee).add(_airdropFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/4);
    }

    function setNewFeeReceiver(address _autoLiquidityReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
    }
    
    function setNewBridgeAirdropAddress(address _bridgeAirdropAddress) external authorized {
        bridgeAirdropAddress = _bridgeAirdropAddress;
    }
    
    function updatePreviousPrice(uint256 _previousPrice) external authorized {
        previousPrice = _previousPrice;
    }

    function manualDividendDistribution() external authorized {
        try distributor.process(distributorGas) {} catch {}
    }

    function depositToDistributor(uint256 amountDeposit) external authorized {
        try distributor.deposit{value: amountDeposit}() {} catch {}
    }    
    
    function setSwapBackSettings(bool _enabled, bool _priceRescueEnabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        priceRescueEnabled = _priceRescueEnabled;
        swapThreshold = _amount * (10 ** _decimals);  //the threshold in tokens
    }
    
    function DynamicFees(bool _enabled) external authorized {
        dynamicFees = _enabled;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function multiplyShares(uint256 lockTime, bool auto_Lock) external {
         distributor.getMultipleShare(msg.sender, lockTime, auto_Lock);
    }    

    function unlockTokensFromDistributor() external {
         distributor.withdrawTokens(msg.sender);
    }  

    function claimDividend() external {
         distributor.claimDividend(msg.sender);
    }  

    function forcedUnlockTokensFromDistributor() external {
        //a penalty will be charged for withdrawing locked tokens
         distributor.unlockTokensWithBreak(msg.sender);
    }  

    function setDistributionCriteria(uint256 _minTokens, uint256 _annualMulipler, uint256 _penaltyPercentage, uint256 _dividendBUSDtrigger, uint256 _IntervalEstablishPool, uint256 _lowerLimiter, uint256 _upperLimiter) external authorized {
        // the minimum number of tokens to receive a share in the dividend
        // set the annual share multiplier 
        distributor.setDistributionCriteria(_minTokens * (10 ** _decimals), _annualMulipler, _penaltyPercentage, _dividendBUSDtrigger  * (10 ** 18), _IntervalEstablishPool * 1 days, _lowerLimiter, _upperLimiter); 
    }
    
    function setLockSettings(uint256 _minTokenBalance, uint256 _lockDuration) external authorized {
        minTokenBalance = _minTokenBalance * (10 ** _decimals); // if the balance is smaller then send tokens from AirdropFundWallet
        lockDuration = _lockDuration * 1 days;
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 1200000);
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
    
    function feeInfo() public view returns (uint256 Liquidity_fee, uint256 Buyback_fee, uint256 Dividend_fee, uint256 Airdrop_fee, uint256 Total_fee, uint256 totalFeeForBuyers, uint256 totalFeeForSellers, uint256 Total_fees_collected) {
        return (liquidityFee, buybackFee, dividendFee, airdropFee, totalFee, getTotalFee(pair, msg.sender), getTotalFee(msg.sender, pair), totalFeesCollected.div(10 ** 18));
    }    

    function priceInfo() public view returns (uint256 previous_price, uint256 current_price, uint256 price_change, uint256 setPrice_TimestampInterval, uint256 setPrice_Timestamp) {
        return (previousPrice, currentPrice, priceChange, setPriceTimestampInterval.div(86400), setPriceTimestamp);
    }  

    function getDistributorInfo(bool hideDecimal) public view returns (uint256 totalShares, uint256 totalLockedTokens, uint256 lastDividendPool, uint256 dividendPool, uint256 nextDividendPool, uint256 totalDistributed, uint256 dividendsPerShare, uint256 minTokens, uint256 annualMulipler, uint256 penaltyPercentage, uint256 shareholderCount) {
        return distributor.getInfo(hideDecimal); 
    }

    function getSharesInfo(address shareholder) public view returns (uint256 shares, uint256 totalDividend, uint256 forecastDividend, bool dividendReceived) {
        return distributor.getSharesInfo(shareholder); 
    }   

    function getLockerInfo(address shareholder) public view returns (uint256 tokensUnlocked, uint256 tokensLocked, uint256 unlockTime, bool autoLock) {
        return distributor.getLockerInfo(shareholder); 
    } 

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountCRY);
    event firstLPprovided(uint256 amountBNB, uint256 amountCRY);
}
// Designed and implemented by Crycoll Team