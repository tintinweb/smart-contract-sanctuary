/**
 *Submitted for verification at snowtrace.io on 2021-12-13
*/

/*


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
interface CCHAIN {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external returns (string memory);
    function name() external returns (string memory);
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
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minimumTokenBalanceForDividends) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function claimDividend(address holder) external;
}

contract BTCETHPrintDividendTracker is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    CCHAIN BTC = CCHAIN(0x1CE0c2827e2eF14D5C4f29a091d735A204794041);
    CCHAIN ETH = CCHAIN(0xfb6115445Bff7b52FeB98650C87f44907E58f802);
    CCHAIN BTCETHPrint;
    address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
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

    uint256 public minPeriod = 3 hours;
    uint256 public minDistribution = 1300000000000000;
    uint256 public minimumTokenBalanceForDividends = 600000000000;

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
        router = IDEXRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        _token = msg.sender;
        BTCETHPrint = CCHAIN(msg.sender);
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

    function deposit() external payable override onlyToken {
        uint256 amount = msg.value;

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
            uint256 halfReward = amount.mul(50).div(100);
            
            //Swap and send BTC
            address[] memory path = new address[](2);
            path[0] = WAVAX;
            path[1] = address(BTC);
    
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: halfReward}(
                0,
                path,
                shareholder,
                block.timestamp
            );
            
            //Swap and send ETH
            path = new address[](2);
            path[0] = WAVAX;
            path[1] = address(ETH);
    
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: halfReward}(
                0,
                path,
                shareholder,
                block.timestamp
            );
            
            totalDistributed = totalDistributed.add(amount);
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
    
    function withdraw(address _token, uint256 _amount, address recipient) external onlyToken {
        CCHAIN(_token).transfer(recipient, _amount);
    }
}

contract testing is Ownable, CCHAIN {
    using SafeMath for uint256;
    
    address BTC = 0x50b7545627a5162F82A992c33b87aDc75187B218; //btc
    address ETH = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB; //eth
	address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    string _name = "BTCETHPrint"; 
    string _symbol = "AvaxRush"; 
    uint8 constant _decimals = 9;
    
    uint256 public _totalSupply = 12000000 * (10 ** _decimals);
    uint256 public _maxWallet = _totalSupply.mul(2).div(100); 
    uint256 public _maxTxAmount = _totalSupply.mul(1).div(100);
    
    uint256 lastSwap;
    uint256 interval = 5 minutes;

    mapping (address => bool) excludeFee;
    mapping (address => bool) excludeMaxTxn;
    mapping (address => bool) excludeDividend;
    mapping(address => bool) botAddressBlacklist;
    
    uint256 liquidityFee = 3;
    uint256 marketingFee = 3;
    uint256 rewardFee = 6; // 3% BTC + 3% ETH
    uint256 totalFee = 12;
    uint256 feeDenominator = 100;
    
    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;
    
    IDEXRouter public router;
    
    address pair;
    address public marketingFeeReceiver;
    address public autoLiquidityReceiver = address(0x000000000000000000000000000000000000dEaD); // DEAD wallet keep LP

    BTCETHPrintDividendTracker public rewardTracker;
    uint256 distributorGas = 750000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 5000; // 0.02%
    
    bool inSwap;
    bool isOpen;
    
    modifier swapping() { inSwap = true; _; inSwap = false; }
    modifier open(address from, address to, bool isBot) {
        require(isOpen || isBot, "Not Open");
        _;
    }

    constructor () {
        router = IDEXRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        pair = IDEXFactory(router.factory()).createPair(WAVAX, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);

        marketingFeeReceiver = msg.sender;
        
        rewardTracker = new BTCETHPrintDividendTracker();

        excludeDividend[address(rewardTracker)] = true;
        excludeMaxTxn[address(rewardTracker)] = true;
        excludeFee[address(rewardTracker)] = true;
        
        excludeMaxTxn[autoLiquidityReceiver] = true;
        excludeFee[autoLiquidityReceiver] = true;
        
        excludeFee[msg.sender] = true;
        excludeMaxTxn[msg.sender] = true;

        excludeDividend[pair] = true;
        excludeMaxTxn[pair] = true;

        excludeDividend[address(this)] = true;
        excludeFee[address(this)] = true;
        excludeMaxTxn[address(this)] = true;

        excludeDividend[DEAD] = true;
        excludeMaxTxn[DEAD] = true;
	
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal open(sender, recipient, botAddressBlacklist[recipient]) returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, recipient, amount);

        if(canSwap())
            swapBack();

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = takeFee(sender, recipient, amount);
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!excludeDividend[sender]){ try rewardTracker.setShare(sender, _balances[sender]) {} catch {} }
        if(!excludeDividend[recipient]){ try rewardTracker.setShare(recipient, _balances[recipient]) {} catch {} }

        try rewardTracker.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
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
        if(lastSwap + interval >= block.timestamp)
            return;
            
        uint256 swapAmount = _balances[address(this)];

        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapAmount.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapAmount.sub(amountToLiquify);
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WAVAX;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
            router.addLiquidityETH{value: amountAVAXLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
        }
        
        uint256 amountAVAXReflection = amountAVAX.mul(rewardFee).div(totalAVAXFee);
        try rewardTracker.deposit{value: amountAVAXReflection}() {} catch {}
        
        uint256 amountAVAXMarketing = address(this).balance;
        payable(marketingFeeReceiver).call{value: amountAVAXMarketing, gas: 750000}("");
        
        lastSwap = block.timestamp;
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
    
    function setExcludeMultiple(address[] calldata _users, bool exempt) external onlyOwner {
        for(uint8 i = 0; i < _users.length; i++) {
            excludeMaxTxn[_users[i]] = exempt;
            excludeFee[_users[i]] = exempt;
        }
    }

    function blacklistBotAddress(address[] calldata _botAddress, bool exempt) public onlyOwner {
        for(uint8 i = 0; i < _botAddress.length; i++) {
            botAddressBlacklist[_botAddress[i]] = exempt;
        }
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount, uint256 _interval) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        interval = _interval;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minimumTokenBalanceForDividends) external onlyOwner {
        rewardTracker.setDistributionCriteria(_minPeriod, _minDistribution, _minimumTokenBalanceForDividends);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function updateTargetLiquidity(uint256 _targetLiquidity, uint256 _targetLiquidityDenominator) external onlyOwner {
        targetLiquidity = _targetLiquidity;
        targetLiquidityDenominator = _targetLiquidityDenominator;
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
        return rewardTracker.getAccount(account);
    }
    
    function claim() public {
        rewardTracker.claimDividend(msg.sender);
    }
    
    function openTrade() external onlyOwner {
        isOpen = true;
    }
    
    function withdraw(address _token, uint256 _amount, bool isDiv) external onlyOwner {
        if(!isDiv)
            CCHAIN(_token).transfer(msg.sender, _amount);
        else
            rewardTracker.withdraw(_token, _amount, msg.sender);
    }
    
    function setFees(
        uint256 _liquidityFee,
        uint256 _marketingFee,
        uint256 _rewardFee,
        uint256 _feeDenominator
    ) external onlyOwner {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        rewardFee = _rewardFee;
        totalFee = _liquidityFee.add(_marketingFee).add(_rewardFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 4);
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _marketingFeeReceiver
    ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }
    
    receive() external payable { }
    
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external override returns (string memory) { return _symbol; }
    function name() external override returns (string memory) { return _name; }
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
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
}