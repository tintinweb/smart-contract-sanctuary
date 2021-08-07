/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

/**
- CMS
- Twitter Influencers onboard
- Big Chinese Community

Telegram: t.me/BabyCakeMoon

Why you should hold  BabyCakeMoon ?
- Dual reward: Cake & BabyCake
- Unique Anti Panic selling 

❇ TOKENOMICS
 • 8% Cake reflection
 • 2% BabyCake reflection
 • 2% for Marketing
 • 2% Liquidity Pool

Max Buy/Sell one transaction: 1,000,000,000

Telegram: t.me/BabyCakeMoon

*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.7.6;

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/TargetToken/solidity/issues/2691
        return msg.data;
    }
}


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


interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    // K8u#El(o)nG3a#t!e c&oP0Y
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/TargetToken/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}. k(u)3E;l'ong\at3e or'3g7i9n#a$l
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
        uint256 rewardPercentage;
    }

    IERC20 TargetToken;
    address WBNB;
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

    uint256 public minPeriod = 30 minutes;
    uint256 public minDistribution = 1 * (10 ** 18);
    
    uint256 public rewardPercentage = 70;

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

    constructor (address _router, address _eth) {
        router = IDEXRouter(_router);
        TargetToken = IERC20(_eth);
        WBNB = router.WETH();
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
        uint256 balanceBefore = TargetToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(TargetToken);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = TargetToken.balanceOf(address(this)).sub(balanceBefore);

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
                
                if(shares[shareholders[currentIndex]].rewardPercentage < 100)
                    shares[shareholders[currentIndex]].rewardPercentage += 10;
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

    function distributeDividend(address shareholder) public {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            TargetToken.transfer(shareholder, amount);
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
        shares[shareholder].rewardPercentage = rewardPercentage;
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract BabyCakeMoon is IERC20, Ownable {
    using SafeMath for uint256;

    address Cake;
    address BabyCake;
    address WBNB;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "BabyCakeMoon";
    string constant _symbol = "BabyCM";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100000000000 * (10 ** _decimals);
    uint256 public _maxTxFirst30Seconds = (_totalSupply * 1) / 200; //Max Buy/Sell first 30 seconds is 0.5%
    uint256 public _maxTxPublic = (_totalSupply * 1) / 100; //Max Buy/Sell public launch is 1% of total supply
    uint256 public _maxTxAmount = _maxTxFirst30Seconds; //Max Buy/Sell one time is 1% of total supply
    uint256 public _maxWalletWhitelist = (_totalSupply * 1) / 400; //0.25% of total supply
    uint256 public _maxWalletPublic = (_totalSupply * 2) / 100; //Max wallet is 2% of total supply for public launch
    uint256 public _maxWalletToken = _maxWalletWhitelist; //Max wallet is 0.25% of total supply for whitelist

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => uint256) lastEntryTimes;
    mapping (uint256 => mapping (address => bool)) whitelists;
    
    uint256 minBetweenTwoEntry = 3 seconds;
    uint256 minFirstTransaction = 2 seconds;

    uint256 cakeReflectionFee = 8;
    uint256 babyCakeReflectionFee = 2;
    uint256 liquidityFee = 2;
    uint256 marketingFee = 2;
    uint256 totalFee = 14;
    uint256 feeDenominator = 100;
    
    uint256 public sellFeeIncreaseFactor = 111; // Normal tax for buy and sell
    uint256 public panicSellFeeIncreaseFactor = 144; //Higher tax when people panic selling
    uint256 public previousPanicSellFeeIncreaseFactor = panicSellFeeIncreaseFactor;
    
    uint256 public numSellInARow;
    uint256 public numBuyInARow;
    bool public isPanicSelling;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver = address(0x80Ae5Da406E40a47ECbf309174F035C76D5987a7);

    IDEXRouter public router;
    address public pair;
    
    address currentLiqPair;
    uint256 blockchunk = 5;
    uint256 lastblocknumber = 0;
    uint256 lastPairBalance = 0;
    uint256 _startTimeForSwap;
    uint256 _intervalSecondsForSwap = 1 * 1 minutes;

    DividendDistributor public cakeDistributor;
    DividendDistributor public babycakeDistributor;
    uint256 distributorGas = 600000;

    bool swapEnabled = false;
    bool loadDone;
    
    uint256 public test;
    
    bool swapAll = true;
    uint256 public launchAt;
    uint256 public swapThreshold = _totalSupply / 1000; // 0.1%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () {
        Cake = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684;
        BabyCake = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        
        // Cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
        // BabyCake = 0xdB8D30b74bf098aF214e862C90E647bbB1fcC58c;
        // router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        WBNB = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        currentLiqPair = pair;
        _allowances[address(this)][address(router)] = uint256(-1);

        cakeDistributor = new DividendDistributor(address(router), Cake);
        babycakeDistributor = new DividendDistributor(address(router), BabyCake);

        isFeeExempt[autoLiquidityReceiver] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isFeeExempt[owner()] = true;
        isFeeExempt[address(this)] = true;

        isTxLimitExempt[autoLiquidityReceiver] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;
        
        isDividendExempt[pair] = true;
        isDividendExempt[address(router)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        autoLiquidityReceiver = owner();
        
        address devWallet = autoLiquidityReceiver;
        _balances[devWallet] = _totalSupply;
        emit Transfer(address(0), devWallet, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
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

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }
    
    function updateLaunchTime(uint256 time) external onlyOwner{
        _maxWalletToken = _maxWalletWhitelist;
        swapEnabled = false;
        launchAt =  time;     
    }
    
    function whiteListWinner(address[] calldata accounts, uint256 tier) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            whitelists[tier][accounts[i]] = true;
        }
    }
    
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 entryTime = block.timestamp;
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        checkTransfer(sender, recipient);
        
        bool isBuying = false;
        if (sender == pair || sender == address(router)){
            isBuying = true;
        }
        bool isSelling = false;
        if (recipient == pair || recipient == address(router)){
            isSelling = true;
        }
        
        checkTxLimit(sender, recipient, amount);

        if(shouldSwapBack(isBuying, isSelling))
            swapBack(); 

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount, isBuying, isSelling, entryTime) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ 
            try cakeDistributor.setShare(sender, _balances[sender]) {} catch {} 
            try babycakeDistributor.setShare(sender, _balances[sender]) {} catch {} 
        }
        if(!isDividendExempt[recipient]){ 
            try cakeDistributor.setShare(recipient, _balances[recipient]) {} catch {} 
            try babycakeDistributor.setShare(recipient, _balances[recipient]) {} catch {} 
        }

        try cakeDistributor.process(distributorGas) {} catch {}
        try babycakeDistributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTransfer(address sender, address recipient) internal{
        if(!swapEnabled && launchAt > 0 && launchAt <= block.timestamp){
            _maxWalletToken = _maxWalletPublic;
            swapEnabled = true;
        }
        if(!loadDone && launchAt + 15 seconds <= block.timestamp){
            loadDone = true;
            _maxTxAmount = _maxTxPublic;
        }
        if(!swapEnabled &&
            sender != owner() && 
            recipient != owner()) {
                
            bool canTransfer = false;
            if(launchAt - 1 minutes <= block.timestamp){
                canTransfer = whitelists[3][recipient] || whitelists[2][recipient] || whitelists[1][recipient] ||
                whitelists[3][sender] || whitelists[2][sender] || whitelists[1][sender];
            }
            else if(launchAt - 2 minutes <= block.timestamp){
                canTransfer = whitelists[2][recipient] || whitelists[1][recipient] ||
                whitelists[2][sender] || whitelists[1][sender];
            }
            else if(launchAt - 3 minutes <= block.timestamp)
                canTransfer = whitelists[1][recipient] || whitelists[1][sender];
            
            require(canTransfer, "This account cannot send tokens or buy token until trading is enabled");
        }
    }
    
    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        if (
            sender != owner() &&
            recipient != owner() &&
            recipient != ZERO &&
            recipient != DEAD &&
            !isTxLimitExempt[sender] &&
            !isTxLimitExempt[recipient]
        ) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            
            if(recipient != pair){
                uint256 contractBalanceRecepient = balanceOf(recipient);
                require(
                    contractBalanceRecepient + amount <= _maxWalletToken,
                    "Exceeds maximum wallet token amount."
                );
            }
        }
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if(isFeeExempt[sender] || isFeeExempt[recipient])
            return false;
        return true;
    }
    
    function takeFee(address sender, address recipient, uint256 amount, bool isBuying, bool isSelling, uint256 entryTime) internal returns (uint256) {
    	uint256 finalFee = totalFee;

        if(isBuying){
            bool isWhitelist = whitelists[1][recipient] || whitelists[2][recipient] || whitelists[3][recipient] ||
                            whitelists[1][sender] || whitelists[2][sender] || whitelists[3][sender];
            bool isBot = (!isWhitelist && launchAt + minFirstTransaction >= entryTime) ||
                        (lastEntryTimes[recipient] + minBetweenTwoEntry >= entryTime);
            if(isBot)
                finalFee = feeDenominator.sub(1);
            
            numBuyInARow++;
            if(isPanicSelling && numBuyInARow > 3){
                numBuyInARow = 0;
                numSellInARow = 0;
                previousPanicSellFeeIncreaseFactor = panicSellFeeIncreaseFactor;
                isPanicSelling = false;
            }
            lastEntryTimes[recipient] = block.timestamp;
        }

        else if(isSelling){
            test = 123;
            numBuyInARow = 0;
            if(isPanicSelling){
                finalFee = finalFee.mul(previousPanicSellFeeIncreaseFactor).div(feeDenominator);
                previousPanicSellFeeIncreaseFactor += 10;
            }
            else
                finalFee = finalFee.mul(sellFeeIncreaseFactor).div(feeDenominator);
            
            numSellInARow++;
            if(!isPanicSelling && numSellInARow >= 3){
                isPanicSelling = true;
                previousPanicSellFeeIncreaseFactor = panicSellFeeIncreaseFactor;
            }
        }

        uint256 feeAmount = amount.mul(finalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        
        return amount.sub(feeAmount);
    }

    function checkUptrend() public view returns(bool) {
        if(lastblocknumber.add(blockchunk) < block.number){
            if(balanceOf(currentLiqPair) < lastPairBalance){
                return true;
            }
        }
        return false;
    }
    
    function shouldSwapBack(bool isBuying, bool isSelling) internal returns (bool) {
        bool uptrendEstablished = checkUptrend();
        
        if(lastblocknumber.add(blockchunk) < block.number){
            lastblocknumber = block.number;
            lastPairBalance = balanceOf(currentLiqPair);
        }
        
        return msg.sender != pair
        && !inSwap
        && _startTimeForSwap + _intervalSecondsForSwap <= block.timestamp
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        _startTimeForSwap = block.timestamp;
        uint256 dynamicLiquidityFee = liquidityFee;
        uint256 amountToken = swapThreshold;
        if(swapAll)
            amountToken = _balances[address(this)];
        uint256 amountToLiquify = amountToken.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = amountToken.sub(amountToLiquify);

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

        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountCakeBNBReflection = amountBNB.mul(cakeReflectionFee).div(totalBNBFee);
        uint256 amountBabyCakeBNBReflection = amountBNB.mul(babyCakeReflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);

        try cakeDistributor.deposit{value: amountCakeBNBReflection}() {} catch {}
        try babycakeDistributor.deposit{value: amountBabyCakeBNBReflection}() {} catch {}
        payable(marketingFeeReceiver).transfer(amountBNBMarketing);

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

    function triggerManualBuyback(uint256 amount, address burnAddress) external onlyOwner {
        buyTokens(amount, burnAddress);
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

    function setTxLimit(uint256 amount) external onlyOwner {
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            cakeDistributor.setShare(holder, 0);
            babycakeDistributor.setShare(holder, 0);
        }else{
            cakeDistributor.setShare(holder, _balances[holder]);
            babycakeDistributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExemptMultiple(address[] calldata holders, bool exempt) external onlyOwner {
        for(uint256 i = 0; i < holders.length; i++) {
            isFeeExempt[holders[i]] = exempt;
        }
    }

    function setIsTxLimitExemptMultiple(address[] calldata holders, bool exempt) external onlyOwner {
        for(uint256 i = 0; i < holders.length; i++) {
            isTxLimitExempt[holders[i]] = exempt;
        }
    }
    
    function setFees(uint256 _liquidityFee, uint256 _cakeReflectionFee, uint256 _babyCakeReflectionFee, uint256 _marketingFee) external onlyOwner {
        liquidityFee = _liquidityFee;
        cakeReflectionFee = _cakeReflectionFee;
        babyCakeReflectionFee = _babyCakeReflectionFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_cakeReflectionFee).add(_babyCakeReflectionFee).add(_marketingFee);
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        
        isFeeExempt[autoLiquidityReceiver] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        
        isTxLimitExempt[autoLiquidityReceiver] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount, bool _swapAll) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        swapAll = _swapAll;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        cakeDistributor.setDistributionCriteria(_minPeriod, _minDistribution);
        babycakeDistributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        distributorGas = gas;
    }
    
    function claimCake() public {
        cakeDistributor.distributeDividend(msg.sender);
        babycakeDistributor.distributeDividend(msg.sender);
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
}