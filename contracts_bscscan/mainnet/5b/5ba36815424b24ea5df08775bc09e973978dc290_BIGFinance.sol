/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

pragma solidity ^0.8.5;



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

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

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

contract BTC_DISTRIBUTOR is IDividendDistributor { // TO-DO change contract name
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 BTC = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // Reward address
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB address
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
    uint256 public minDistribution = 1 * (10 ** 16);

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
        uint256 balanceBefore = BTC.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(BTC);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BTC.balanceOf(address(this)).sub(balanceBefore);

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
            BTC.transfer(shareholder, amount);
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

contract BIGFinance is IBEP20, Auth { // TO-DO change contract name
    using SafeMath for uint256;

    address public BTC = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //Reward address
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address zeroAddress = 0x0000000000000000000000000000000000000000;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public externalAddress = 0x418FB79D6CF0F0bF1011654aeb14ddC1B84413f8; //TO-DO change external address
    address public autoLiquidityReceiver = 0x418FB79D6CF0F0bF1011654aeb14ddC1B84413f8; //TO-DO change liquidty owner address

    string constant _name = "BIGFinance";
    string constant _symbol = "BIG";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100000000 *10**6 * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => uint256) private _transactionCheckpoint;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isBlacklisted;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isBTCDividendExempt;
    mapping (address => bool) public isExcludedFromAntiWhale; // Limits how many tokens can an address hold
    mapping (address => bool) public isExcludedFromTransactionlock; // Address to be excluded from transaction cooldown

    // all fee values are upto 2 decimal points. so 5 is 0.05 and 10 is 0.1 and so on...

    uint256 public reflectionFee = 1100;
    uint256 public externalFee = 500;
    uint256 public liquidityFee = 300;
    uint256 public burnFee = 100;
    uint256 private totalBNBFee = reflectionFee.add(externalFee).add(liquidityFee);
    uint256 private feeDenominator = 10000;

    IPANCAKERouter public router;
    address public pair;

    uint256 private _transactionLockTime = 0; //Cool down time between each transaction per address

    BTC_DISTRIBUTOR distributor; 
    uint256 distributorGas = 5000000;

    bool public swapEnabled = true;
    uint256 public _maxTxAmount = _totalSupply; // 0.5%
    uint256 public minTokensBeforeSwapThreshold = _totalSupply / 20000; // 0.005%
    uint256 public _maxTokensPerAddress         = 2000000000 * 10**8 * 10**_decimals; // Max number of tokens that an address can hold

    event AutoLiquify(uint256 bnbAmount, uint256 tokensAmount);

    bool private inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IPANCAKERouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IPancakeFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);

        distributor = new BTC_DISTRIBUTOR(address(router));

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isBTCDividendExempt[pair] = true;
        isBTCDividendExempt[address(this)] = true;
        isBTCDividendExempt[burnAddress] = true;
        isBTCDividendExempt[zeroAddress] = true;

        isExcludedFromTransactionlock[pair]            = true;
        isExcludedFromTransactionlock[msg.sender]      = true;
        isExcludedFromTransactionlock[address(this)]   = true;
        isExcludedFromTransactionlock[externalAddress] = true;
        isExcludedFromTransactionlock[address(router)] = true;

        isExcludedFromAntiWhale[pair]            = true;
        isExcludedFromAntiWhale[msg.sender]      = true;
        isExcludedFromAntiWhale[burnAddress]     = true;
        isExcludedFromAntiWhale[zeroAddress]     = true;
        isExcludedFromAntiWhale[address(this)]   = true;
        isExcludedFromAntiWhale[externalAddress] = true;
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
    function getOwner() external view override returns (address) { return owner; }
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
    
     function  burn(address account, uint256 amount) onlyOwner  public virtual {
        require(account != address(0), "ERC20: burn to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        
     }
     
     function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        require(isBlacklisted[sender] == false, "You are banned");
        require(isBlacklisted[recipient] == false, "The recipient is banned");

        require(isExcludedFromAntiWhale[recipient] || balanceOf(recipient) + amount <= _maxTokensPerAddress,
        "Max tokens limit for this account exceeded. Or try lower amount");
        require(isExcludedFromTransactionlock[sender] || block.timestamp >= _transactionCheckpoint[sender] + _transactionLockTime,
        "Wait for transaction cooldown time to end before making a tansaction");
        require(isExcludedFromTransactionlock[recipient] || block.timestamp >= _transactionCheckpoint[recipient] + _transactionLockTime,
        "Wait for transaction cooldown time to end before making a tansaction");

        _transactionCheckpoint[sender] = block.timestamp;
        _transactionCheckpoint[recipient] = block.timestamp;
        
        if(sender != pair && !inSwap && swapEnabled 
        && _balances[address(this)] >= minTokensBeforeSwapThreshold)
        { swapBack(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isBTCDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isBTCDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    /**
    * @dev  Transfer function when in swap and liquify
    * so we don't take fee or do any checks when
    * swapping tokens from tokens address for auto liquidity
    * it reduces gas when auto liquidity is triggered 
    */
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /**
    * @dev  should take fee or not
    */
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    /**
    * @dev  take's all fee and add to contract address and burn tokens
    */
    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalBNBFee).div(feeDenominator);
        uint256 burnAmount = amount.mul(burnFee).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        
        if(burnAmount > 0) {
            _totalSupply = _totalSupply.sub(burnAmount);
            emit Transfer(sender, burnAddress, burnAmount);
        }

        return amount.sub(feeAmount.add(burnAmount));
    }

    /**
    * @dev  swap's tokens to BNB for auto liquidity and external
    */
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
        uint256 amountBNBExternal = receivedBNB.mul(externalFee).div(swapPercent);

        try distributor.deposit{value: amountBNBReflection.add(balanceBefore)}() {} catch {}
            payable(externalAddress).call{value: amountBNBExternal, gas: 30000}("");

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

    /**
	* @dev Sets transactions on time periods or cooldowns.
	* Can only be set by owner set in seconds.
	*/
	function setTransactionCooldownTime(uint256 transactiontime) public onlyOwner {
		_transactionLockTime = transactiontime;
	}

    /**  
     * @dev set max amount per transaction
     */
    function setMaxTxLimit(uint256 amount) external authorized {
        _maxTxAmount = amount.mul(10**_decimals);
    }

    /**  
     * @dev set swap to BNB settings
     */
    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        minTokensBeforeSwapThreshold = _amount.mul(10**_decimals);
    }

    /**  
     * @dev Remove/add an address from BTC reward
     */
    function setIsDividendExempt(address holder, bool exempt) public authorized {
        require(holder != address(this) && holder != pair);
        isBTCDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    /**  
     * @dev Remove/add an address from fee deduction
     */
    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    /**  
     * @dev Remove/add an address from max txn amount
     */
    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    /**  
     * @dev set liquidity fee
     */
    function setLiquidityFees(uint256 _liquidityFee) external authorized {
        liquidityFee = _liquidityFee;
        totalBNBFee = liquidityFee.add(reflectionFee).add(externalFee);
    }

    /**  
     * @dev set BTC reward fee
     */
    function setRewardFees(uint256 _rewardFee) external authorized {
        reflectionFee = _rewardFee;
        totalBNBFee = liquidityFee.add(reflectionFee).add(externalFee);
    }

    /**  
     * @dev set external fee
     */
    function setExternalFees(uint256 _externalFee) external authorized {
        externalFee = _externalFee;
        totalBNBFee = liquidityFee.add(reflectionFee).add(externalFee);
    }

    /**  
     * @dev set burn fee
     */
    function setBurnFees(uint256 _burnFee) external authorized {
        burnFee = _burnFee;
    }

    /**  
     * @dev set liquidity owner address
     */
    function setLiquidityAddress(address wallet) external authorized {
        autoLiquidityReceiver = wallet;
    }

    /**  
     * @dev set external address
     */
    function setExternalAddress(address wallet) external authorized {
        externalAddress = wallet;
    }

    /**  
     * @dev set BTC distribution criteria
     * _minPeriod--> minimum time to wait before send
     * _minDistribution--> minimum amount of BTC reward before send to address
     */
    function setBTCDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    /**  
     * @dev set BTC distributor's setting
     * gas--> gas fee to be used from sender's gas fee to send BTC reward
     */
    function setBTCDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }

    /**  
     * @dev includes/excludes an address from per address tokens limit
     */
    function setIsExcludedFromAntiWhale(address account, bool excluded) public onlyOwner {
        isExcludedFromAntiWhale[account] = excluded;
    }
    /**
    * @dev includes/excludes an address from transactions from cooldowns.
	* Can only be set by owner.
	*/
	function setIsExcludedFromTransactionCooldown(address account, bool excluded) public onlyOwner {
		isExcludedFromTransactionlock[account] = excluded;
	}

    /**  
     * @dev Blacklist a singel wallet from buying and selling
     */
    function blacklistSingleWallet(address account) external authorized {
        if(isBlacklisted[account] == true) return;
        isBlacklisted[account] = true;
        setIsDividendExempt(account, true); // also remove BTC reward for address
    }

    /**  
     * @dev Blacklist multiple wallets from buying and selling
     */
    function blacklistMultipleWallets(address[] calldata accounts) external authorized {
        require(accounts.length < 600, "Can not blacklist more then 600 address in one transaction");
        for (uint256 i; i < accounts.length; ++i) {
            isBlacklisted[accounts[i]] = true;
            setIsDividendExempt(accounts[i], true); // also remove BTC reward for address
        }
    }
    
    /**  
     * @dev un blacklist a singel wallet from buying and selling
     */
    function unBlacklistSingleWallet(address account) external authorized {
         if(isBlacklisted[account] == false) return;
        isBlacklisted[account] = false;
        setIsDividendExempt(account, false); // also includes in BTC reward for address
    }

    /**  
     * @dev un blacklist multiple wallets from buying and selling
     */
    function unBlacklistMultipleWallets(address[] calldata accounts) external authorized {
        require(accounts.length < 600, "Can not Unblacklist more then 600 address in one transaction");
        for (uint256 i; i < accounts.length; ++i) {
            isBlacklisted[accounts[i]] = false;
            setIsDividendExempt(accounts[i], false); // also includes in BTC reward for address
        }
    }

    /**  
     * @dev recovers any tokens stuck in Contract's balance
     * NOTE! if ownership is renounced then it will not work
     */
    function recoverTokens(address tokenAddress, uint256 amountToRecover) external onlyOwner {
        IBEP20 token = IBEP20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amountToRecover, "Not Enough Tokens in contract to recover");

        if(amountToRecover > 0)
            token.transfer(msg.sender, amountToRecover);
    }

    /**  
     * @dev recovers any ETH stuck in Contract's balance
     * NOTE! if ownership is renounced then it will not work
     */
    function recoverETH() external authorized {
        address payable recipient = payable(msg.sender);
        if(address(this).balance > 0)
            recipient.transfer(address(this).balance);
    }
}