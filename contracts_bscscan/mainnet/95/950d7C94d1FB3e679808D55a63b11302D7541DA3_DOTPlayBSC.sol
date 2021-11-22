/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

/**
 * Name/Symbol - DOTPlayBSC - DPLAY
 * TG - https://t.me/dotplaybsc
 */

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.4;

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
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity >=0.6.0 <0.8.4;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

pragma solidity >=0.6.0 <0.8.4;

interface IPANCAKERouter {
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

pragma solidity 0.8.3;

contract DOT_DISTRIBUTOR is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 DOT = IBEP20(0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IPANCAKERouter router;

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
    uint256 public minDistribution = 1 * (10 ** 14);

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
            ? IPANCAKERouter(_router)
            : IPANCAKERouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
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
        uint256 balanceBefore = DOT.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(DOT);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = DOT.balanceOf(address(this)).sub(balanceBefore);

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
            DOT.transfer(shareholder, amount);
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

pragma solidity >=0.6.0 <0.8.4;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor ()  {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

contract DOTPlayBSC is Context, IBEP20, Ownable, ReentrancyGuard{ 
    using SafeMath for uint256;

    address DOT = (0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address zeroAddress = 0x0000000000000000000000000000000000000000;
    address burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public marketingAddress = 0xf9114f7c0016CBDD16B6DBA5601dFE90bf560fde; 
    address public autoLiquidityReceiver = 0x31E2972852e92169a86D5718F78F5Ff620950685;

    string constant _name = "DOTPlayBSC";
    string constant _symbol = "DPLAY";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 1000 *10**6 * (10 ** _decimals);
            
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => uint256) private _transactionCheckpoint;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isBlacklisted;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDOTDividendExempt;
    mapping (address => bool) private isExcludedFromAntiWhale;
    mapping (address => bool) private isExcludedFromTransactionlock;


    uint256 public marketingFee = 600;
    
    uint256 public reflectionFee = 600;
    uint256 private _previousreflectionFee = reflectionFee;

    uint256 public liquidityFee = 300;
    uint256 private _previousliquidityFee = liquidityFee;

    uint256 public totalBNBFee = reflectionFee.add(marketingFee).add(liquidityFee);
    uint256 private _previoustotalBNBFee = totalBNBFee;

    uint256 public _buyLiquidityFee = 300;
    uint256 public _buyreflectionFee = 600;
    
    uint256 public _sellLiquidityFee = 300;
    uint256 public _sellreflectionFee = 600;

    uint256 private _buytotalBNBFee = _buyreflectionFee.add(marketingFee).add(_buyLiquidityFee);
    uint256 private _selltotalBNBFee =_sellreflectionFee.add(marketingFee).add(_sellLiquidityFee);

    uint256 private feeDenominator = 10000;

    IPANCAKERouter public router;
    address public pair;

    uint256 private _transactionLockTime = 0;

    DOT_DISTRIBUTOR distributor; 
    uint256 distributorGas = 1000000;

    bool public swapEnabled = true;
    uint256 public _maxTxAmount = 5 * 10**6 * 10**_decimals; // 0.5%
    uint256 public minTokensBeforeSwapThreshold = _totalSupply / 500000; // 0.005%
    
    event AutoLiquify(uint256 bnbAmount, uint256 tokensAmount);

    bool private inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () {
        router = IPANCAKERouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IPancakeFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);

        distributor = new DOT_DISTRIBUTOR(address(router));

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isDOTDividendExempt[pair] = true;
        isDOTDividendExempt[address(this)] = true;
        isDOTDividendExempt[burnAddress] = true;
        isDOTDividendExempt[zeroAddress] = true;

        isExcludedFromTransactionlock[pair]            = true;
        isExcludedFromTransactionlock[msg.sender]      = true;
        isExcludedFromTransactionlock[address(this)]   = true;
        isExcludedFromTransactionlock[marketingAddress] = true;
        isExcludedFromTransactionlock[address(router)] = true;

        isExcludedFromAntiWhale[pair]            = true;
        isExcludedFromAntiWhale[msg.sender]      = true;
        isExcludedFromAntiWhale[burnAddress]     = true;
        isExcludedFromAntiWhale[zeroAddress]     = true;
        isExcludedFromAntiWhale[address(this)]   = true;
        isExcludedFromAntiWhale[marketingAddress] = true;
        isExcludedFromAntiWhale[address(router)] = true;
        
        autoLiquidityReceiver = msg.sender;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

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

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        require(isBlacklisted[sender] == false, "You are banned");
        require(isBlacklisted[recipient] == false, "The recipient is banned");

        require(isExcludedFromTransactionlock[sender] || block.timestamp >= _transactionCheckpoint[sender] + _transactionLockTime,
        "Wait for transaction cool down time to end before making a transaction");
        require(isExcludedFromTransactionlock[recipient] || block.timestamp >= _transactionCheckpoint[recipient] + _transactionLockTime,
        "Wait for transaction cool down time to end before making a transaction");

        _transactionCheckpoint[sender] = block.timestamp;
        _transactionCheckpoint[recipient] = block.timestamp;
        
        if(sender == pair){
            removeAllFee();
            liquidityFee = _buyLiquidityFee;
            totalBNBFee  = _buytotalBNBFee;
            reflectionFee = _buyreflectionFee;

        }
        
        if(recipient == pair){
            removeAllFee();
            liquidityFee = _sellLiquidityFee;
            totalBNBFee  = _selltotalBNBFee;
            reflectionFee = _sellreflectionFee;
        }

        if(sender != pair && !inSwap && swapEnabled 
        && _balances[address(this)] >= minTokensBeforeSwapThreshold)
        { swapBack(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDOTDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDOTDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

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

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalBNBFee).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function swapBack() internal swapping {
        uint256 amountToLiquify = minTokensBeforeSwapThreshold.mul(liquidityFee/2).div(totalBNBFee);
        uint256 amountToSwap = minTokensBeforeSwapThreshold.sub(amountToLiquify);

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

        uint256 receivedBNB = address(this).balance.sub(balanceBefore);

        uint256 swapPercent = totalBNBFee.sub(liquidityFee.div(2));
        
        uint256 amountBNBLiquidity = receivedBNB.mul(liquidityFee/2).div(swapPercent);
        uint256 amountBNBReflection = receivedBNB.mul(reflectionFee).div(swapPercent);
        uint256 amountBNBMarketing = receivedBNB.mul(marketingFee).div(swapPercent);

        try distributor.deposit{value: amountBNBReflection.add(balanceBefore)}() {} catch {}
            (bool tmpSuccess,) = payable(marketingAddress).call{value: amountBNBMarketing, gas: 30000}("");

        tmpSuccess = false;

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

    function setTransactionCooldownTime(uint256 transactiontime) public onlyOwner {
        _transactionLockTime = transactiontime;
    }

    function setMaxTxLimit(uint256 amount) external onlyOwner {
        _maxTxAmount = amount.mul(10**_decimals);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        minTokensBeforeSwapThreshold = _amount.mul(10**_decimals);
    }

    function setIsDividendExempt(address holder, bool exempt) public onlyOwner {
        require(holder != address(this) && holder != pair);
        isDOTDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setLiquidityFees(uint256 _liquidityFee) external onlyOwner {
        liquidityFee = _liquidityFee;
        totalBNBFee = liquidityFee.add(reflectionFee).add(marketingFee);
    }

    function removeAllFee() private {
        if( totalBNBFee == 0 && reflectionFee == 0 && liquidityFee == 0) return;
        
        _previousliquidityFee = liquidityFee;
        _previoustotalBNBFee = totalBNBFee;
        _previousreflectionFee = reflectionFee;
        
        liquidityFee = 0;
        totalBNBFee = 0;
        reflectionFee = 0;
    }
    
    function restoreAllFee() private {
        
        liquidityFee = _previousliquidityFee;
        totalBNBFee =_previoustotalBNBFee;
        reflectionFee = _previousreflectionFee;
    }

    function setRewardFees(uint256 _rewardFee) external onlyOwner {
        reflectionFee = _rewardFee;
        totalBNBFee = liquidityFee.add(reflectionFee).add(marketingFee);
    }

    function seMarketingFees(uint256 _marketingFee) external onlyOwner {
        marketingFee = _marketingFee;
        totalBNBFee = liquidityFee.add(reflectionFee).add(marketingFee);
    }

    function setLiquidityAddress(address wallet) external onlyOwner {
        autoLiquidityReceiver = wallet;
    }

    function setMarketingAddress(address wallet) external onlyOwner {
        marketingAddress = wallet;
    }

    function setDOTDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDOTDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }

    function setIsExcludedFromAntiWhale(address account, bool excluded) public onlyOwner {
        isExcludedFromAntiWhale[account] = excluded;
    }

    function setIsExcludedFromTransactionCooldown(address account, bool excluded) public onlyOwner {
        isExcludedFromTransactionlock[account] = excluded;
    }
    
    function blacklistSingleWallet(address account) external onlyOwner {
        if(isBlacklisted[account] == true) return;
        isBlacklisted[account] = true;
        setIsDividendExempt(account, true); 
    }

    function blacklistMultipleWallets(address[] calldata accounts) external onlyOwner {
        require(accounts.length < 600, "Can not blacklist more then 600 address in one transaction");
        for (uint256 i; i < accounts.length; ++i) {
            isBlacklisted[accounts[i]] = true;
            setIsDividendExempt(accounts[i], true);
        }
    }
    
    function unBlacklistSingleWallet(address account) external onlyOwner {
         if(isBlacklisted[account] == false) return;
        isBlacklisted[account] = false;
        setIsDividendExempt(account, false);
    }

    function unBlacklistMultipleWallets(address[] calldata accounts) external onlyOwner {
        require(accounts.length < 600, "Can not Unblacklist more then 600 address in one transaction");
        for (uint256 i; i < accounts.length; ++i) {
            isBlacklisted[accounts[i]] = false;
            setIsDividendExempt(accounts[i], false);
        }
    }

    function recoverTokens(address tokenAddress, uint256 amountToRecover) external onlyOwner {
        IBEP20 token = IBEP20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amountToRecover, "Not Enough Tokens in contract to recover");

        if(amountToRecover > 0)
            token.transfer(msg.sender, amountToRecover);
    }

    function recoverETH() external onlyOwner {
        address payable recipient = payable(msg.sender);
        if(address(this).balance > 0)
            recipient.transfer(address(this).balance);
    }
}