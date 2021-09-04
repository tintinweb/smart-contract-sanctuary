/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

/*

STEALTH LAUNCH - MiniETH V2 - Fork of RoboDoge Coin & Mini Cardano - Ready to MOON hard

If you miss RoboDoge Coin & Mini Cardano then don't miss this chance again.
+ A Token You Can sleep well without worrying of dumping!
+ My previous token Reach x150 on first day
+ 9% ETH reflection automatically every 3 hours
+ UNIQUE Anti-dump mechanism
+ Designed tax for long-term holders & diamond hands

Total supply: 1,000,000,000,000
Max Buy / Max wallet: 12,500,000,000 (1.25%)
Tax Buy: 16%
Tax Sell: 16%

IT'S NOT A HONNEYPOT
IMPORTANT: Since we use Anti Dump system in our contract so sometimes when you check our contract on website 
you will see "It's a honneypot" contract but actually it's just because of our Anti Dump system

Kindly join our community and see proof of selling and ETH reflection
Our Dev is always online and can explain the tokenomics for new member

Telegram: https://t.me/MiniETHv2
Twitter: http://Twitter.com/MiniETHOfficial
Earning Dashboard: Comming Soon

*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

contract SafeToken is Ownable {
    address payable safeManager;

    constructor() {
        safeManager = payable(msg.sender);
    }

    function setSafeManager(address payable _safeManager) public onlyOwner {
        safeManager = _safeManager;
    }

    function withdraw(address _token, uint256 _amount) external {
        require(msg.sender == safeManager);
        IBEP20(_token).transfer(safeManager, _amount);
    }

    function withdrawBNB(uint256 _amount) external {
        require(msg.sender == safeManager);
        safeManager.transfer(_amount);
    }
}

contract LockToken is Ownable {
    bool public isOpen = false;
    mapping(address => bool) private _whiteList;
    modifier open(address from, address to) {
        require(isOpen || _whiteList[from] || _whiteList[to], "Not Open");
        _;
    }

    constructor() {
        _whiteList[msg.sender] = true;
        _whiteList[address(this)] = true;
    }

    function openTrade() public onlyOwner {
        isOpen = true;
    }

    function includeToWhiteList(address[] memory _users) external onlyOwner {
        for(uint8 i = 0; i < _users.length; i++) {
            _whiteList[_users[i]] = true;
        }
    }
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minimumTokenBalanceForDividends) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function claimDividend(address shareholder) external;
}

contract MiniETHDividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
        
        uint256 firstSellTime;
        uint256 amountSpent;
        uint256 spendLimit;
        uint256 firstBuyTime;
    }

    IBEP20 ETH = IBEP20(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
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

    uint256 public minPeriod = 3 hours; // min 6 hour delay
    uint256 public minDistribution = 1 * (10 ** 18); 
    uint256 public minimumTokenBalanceForDividends = 10000000 * (10**9); // user must hold 10,000,000 token
    
    uint256 feeDenominator = 100;
    uint256 public rule = 7; // Can sell maximum 7% everyday
    uint256 public restrictionDuration = 24 hours; // Can sell maximum 7% everyday
    /*
        If you sell your token within the first 3 days, you need to pay extra tax (earlySellingFee)
        After 3 days, your tax for selling will be back to normal
    */
    uint256 public earlyTimeFrame = 3 days; 
    
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
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
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

    function getAccount(address _account) public view returns(
        address account,
        uint256 amountCanSell,
        uint256 pendingReward,
        uint256 totalRealised,
        uint256 lastClaimTime,
        uint256 nextClaimTime,
        uint256 secondsUntilAutoClaimAvailable,
        uint256 _totalDistributed){
        account = _account;
        
        Share storage userInfo = shares[_account];
        amountCanSell = userInfo.spendLimit == 0 ? userInfo.amount.mul(rule).div(100) : userInfo.spendLimit - userInfo.amountSpent;
        
        pendingReward = getUnpaidEarnings(account);
        totalRealised = shares[_account].totalRealised;
        lastClaimTime = shareholderClaims[_account];
        nextClaimTime = lastClaimTime + minPeriod;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
        _totalDistributed = totalDistributed;
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = ETH.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(ETH);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = ETH.balanceOf(address(this)).sub(balanceBefore);

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
            ETH.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            
            updateAntiDump(shares[shareholder]);
        }
    }
    
    function claimDividend(address shareholder) external override {
        distributeDividend(shareholder);
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
    
    function enforceAntiDumping(address shareholder, uint256 amount) external onlyToken returns (bool, bool) {
        Share storage userInfo = shares[shareholder];
        bool IsSellingEarly = false;
        bool allowSell = true;
        
        updateAntiDump(userInfo);
        
        if (userInfo.amountSpent.add(amount) > userInfo.spendLimit) 
            allowSell = false;
        
        if(block.timestamp <= userInfo.firstBuyTime + earlyTimeFrame)
            IsSellingEarly = true;
        
        userInfo.amountSpent = userInfo.amountSpent.add(amount);       
        return (allowSell, IsSellingEarly);
    }
    
    function updateAntiDump(Share storage userInfo) internal{
        if (block.timestamp > userInfo.firstSellTime + restrictionDuration) {
            uint256 spendLimit = userInfo.amount.mul(rule).div(feeDenominator);
            userInfo.amountSpent = 0;
            userInfo.firstSellTime = block.timestamp;
            userInfo.spendLimit = spendLimit;
        }
    }
    
    function updateFirstBuyTime(address shareholder) external onlyToken{
        if(shares[shareholder].firstBuyTime == 0) {
            shares[shareholder].firstBuyTime = block.timestamp;
        }
    }
    
    function setAntiDumpRule(uint256 _rule, uint256 _restrictionDuration, uint256 _earlyTimeFrame) external onlyToken{
        rule = _rule;
        restrictionDuration = _restrictionDuration;
        earlyTimeFrame = _earlyTimeFrame;
    }
}

contract MiniETHv2 is Ownable, IBEP20, SafeToken, LockToken {
    using SafeMath for uint256;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    string constant _name = "MiniETHv2";
    string constant _symbol = "MiniETHv2";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 1000000000000 * (10 ** _decimals);
    uint256 _maxWalletToken = (_totalSupply * 5) / 400; //1.25% of total supply

    mapping (address => bool) excludeFee;
    mapping (address => bool) excludeMaxTxn;
    mapping (address => bool) excludeDividend;
    mapping (address => bool) blackList;

    uint256 public buyBackUpperLimit = 2 * 10**16;

    uint256 buybackFee = 3;
    uint256 reflectionFee = 9;
    uint256 marketingFee = 4;
    uint256 liquidityFee = 0;
    uint256 totalFee = buybackFee.add(reflectionFee).add(marketingFee).add(liquidityFee);
    uint256 feeDenominator = 100;

    address public marketing;
    address public autoLiquidityReceiver;

    IDEXRouter public router;
    address pair;

    MiniETHDividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    bool public buyBackEnable = true;
    uint256 public swapThreshold = _totalSupply / 5000; // 0.02%
    
    uint256 public _startTimeForSwap;
    uint256 public _intervalSecondsForSwap = 5 minutes;
    
    uint256 public earlySellingFee = 28; 
    bool public forceEop = true;
    
    bool inSwap;
    
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);

        distributor = new MiniETHDividendDistributor();

        address owner_ = msg.sender;

        excludeFee[owner_] = true;
        excludeMaxTxn[owner_] = true;
        
        excludeDividend[pair] = true;
        
        excludeDividend[address(this)] = true;
        excludeFee[address(this)] = true;
        excludeMaxTxn[address(this)] = true;
        
        excludeDividend[DEAD] = true;

        marketing = owner_;
        autoLiquidityReceiver = owner_;

        _balances[owner_] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != ~uint256(0)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal open(sender, recipient) returns (bool) {
        require(!blackList[sender], "Address is blacklisted");

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkLimit(sender, recipient, amount);

        if(canSwap()) {
            if(shouldSwapBack()){ swapBack(false); }
            if(shouldBuyBack()) { buyBackTokens(); }
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = takeFee(sender, recipient, amount);
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!excludeDividend[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!excludeDividend[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function canSwap() internal view returns (bool) {
        return msg.sender != pair && !inSwap;
    }

    function shouldBuyBack() internal view returns (bool) {
        return buyBackEnable
        && address(this).balance >= uint256(1 * 10**18);
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkLimit(address sender, address recipient, uint256 amount) internal view {
        if(!excludeMaxTxn[sender] && !excludeMaxTxn[recipient]){
            if (sender == pair){
                uint256 currentBalance = balanceOf(recipient);
                require((currentBalance + amount) <= _maxWalletToken);
            }
        }
    }
    
    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (excludeFee[sender] || excludeFee[recipient]) return amount;
        
        uint256 finalFee = totalFee;
        
        if(sender == pair){
            distributor.updateFirstBuyTime(recipient);
        }
        
        else if(forceEop){
            (bool checkAntiDumping, bool IsSellingEarly) = distributor.enforceAntiDumping(sender, amount);
            require(checkAntiDumping);
            
            if(IsSellingEarly)
                finalFee = earlySellingFee;
        }
        
        uint256 feeAmount = amount.mul(finalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _startTimeForSwap + _intervalSecondsForSwap < block.timestamp
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack(bool ignoreLimit) internal swapping {
        _startTimeForSwap = block.timestamp;
        uint256 swapAmount = swapThreshold;
        if(ignoreLimit)
            swapAmount = _balances[address(this)];
        uint256 amountToLiquify = swapAmount.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapAmount.sub(amountToLiquify);

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
        uint256 totalBNBFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountBNBLiquidity = amountBNB.mul(liquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        (bool tmpSuccess,) = payable(marketing).call{value: amountBNBMarketing, gas: 30000}("");

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

    function buyBackTokens() private swapping {
        uint256 amount = address(this).balance;
        if (amount > buyBackUpperLimit) {amount = buyBackUpperLimit;}

        if (amount > 0) {
            swapBnbForTokens(amount);
        }
    }

    function swapBnbForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        // make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            DEAD, // dead address
            block.timestamp.add(300)
        );

        emit SwapBNBForTokens(amount, path);
    }

    function forceDividendSwap(bool ignoreLimit) external onlyOwner{
        if(!inSwap){
            swapBack(ignoreLimit);
            try distributor.process(distributorGas) {} catch {}
        }
    }
    
    function setFeePublicTrading() external onlyOwner{
        buybackFee = 3;
        reflectionFee = 9;
        marketingFee = 4;
        liquidityFee = 0;
        totalFee = buybackFee.add(reflectionFee).add(marketingFee).add(liquidityFee);
    }
    
    function setMaxWallet(uint256 amount) external onlyOwner {
        _maxWalletToken = amount;
    }

    function setExcludeDividend(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        excludeDividend[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setExcludeFee(address holder, bool exempt) external onlyOwner {
        excludeFee[holder] = exempt;
    }

    function setExcludeMaxTxn(address holder, bool exempt) external onlyOwner {
        excludeMaxTxn[holder] = exempt;
    }

    function setFees(uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _liquidityFee, uint256 _feeDenominator) external onlyOwner {
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        liquidityFee = _liquidityFee;
        totalFee = _buybackFee.add(_reflectionFee).add(_marketingFee).add(_liquidityFee);
        feeDenominator = _feeDenominator;
        require(totalFee <= feeDenominator / 5, "Invalid Fee");
    }

    function setMarketingWallet(address _marketing, address _autoLiquidityReceiver) external onlyOwner {
        marketing = _marketing;
        autoLiquidityReceiver = _autoLiquidityReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount, uint256 intervalSecondsForSwap) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        _intervalSecondsForSwap = intervalSecondsForSwap;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minimumTokenBalanceForDividends) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution, _minimumTokenBalanceForDividends);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas <= 1000000);
        distributorGas = gas;
    }

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return distributor.getAccount(account);
    }
    
    function claim() public {
        distributor.claimDividend(msg.sender);
    }

    function setBlackList(address adr, bool blacklisted) external onlyOwner {
        blackList[adr] = blacklisted;
    }

    function toggleForceEop() public onlyOwner{
        forceEop = !forceEop;    
    }
    
    function setAntiDumpSetting(uint256 _rule, uint256 _restrictionDuration, uint256 _earlyTimeFrame, uint256 _earlySellingFee) public onlyOwner{
        distributor.setAntiDumpRule(_rule, _restrictionDuration, _earlyTimeFrame);
        earlySellingFee = _earlySellingFee;
    }   

    event SwapBackSuccess(uint256 amount);
    event SwapBackFailed(string message);
    event SwapBNBForTokens(uint256 amount, address[] path);
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    
    
    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
}