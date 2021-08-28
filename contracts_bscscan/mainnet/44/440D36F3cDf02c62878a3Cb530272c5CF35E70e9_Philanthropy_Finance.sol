/**
 *Submitted for verification at BscScan.com on 2021-08-28
*/

/**
 * Name: Philanthropy_Finance
 * Symbol: $PHIFI
 * 
 * Website: https://www.philanthropy-finance.com 
 * Telegram: https://t.me/Philanthropy_Finance
 * Twitter: https://twitter.com/PhilanthropyFi
 * 
 * Total Supply: 1,000,000,000,000,000
 * 
 * Token Economics
 * 
 * $PHIFI is a BTCB Token reflection token (a BEP2 token pegged to Bitcoin)
 * 
 * BUY Tax
 * 2% marketing ~ 6% liquidity ~ 6% reflection in BTCb
 * 
 * SELL Tax
 * 2% marketing ~ 6% liquidity ~ 8% reflection in BTCb
 * 
 * Reflections will be redistributed in BTCB (pegged to Bitcoin) to the holders by an 
 * automatic claim mechanism: every hour BTCB rewards will be send automatically to the holders.
 */

pragma solidity ^0.8.5;

//SPDX-License-Identifier: MIT


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
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function removeMinter(address account) public onlyMinter {
        _removeMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * Allows for contract ownership along with one-address authorization
 */
abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

    IBEP20 BTC = IBEP20(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c); // Reward address
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

contract Philanthropy_Finance is Context, IBEP20, MinterRole, Ownable { 
    using SafeMath for uint256;

    address public BTC = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c; //Reward address
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address zeroAddress = 0x0000000000000000000000000000000000000000;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public externalAddress = 0x6a1e70CCa4bC714FABA679E3DA77593477Ef266c; 
    address public autoLiquidityReceiver = 0x0000000000000000000000000000000000000000;

    string constant _name = "Philanthropy_Finance";
    string constant _symbol = "PHIFI";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 1000000000 *10**6 * (10 ** _decimals);
            
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => uint256) private _transactionCheckpoint;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isBlacklisted;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isBTCDividendExempt;
    mapping (address => bool) public isExcludedFromAntiWhale; // Limits how many tokens can an address hold
    mapping (address => bool) public isExcludedFromTransactionlock; // Address to be excluded from transaction cool down

    // all fee values are upto 2 decimal points. so 5 is 0.05 and 10 is 0.1 and so on...

    uint256 public externalFee = 200;
    
    uint256 public reflectionFee = 600;
    uint256 private _previousreflectionFee = reflectionFee;

    uint256 public liquidityFee = 600;
    uint256 private _previousliquidityFee = liquidityFee;

    uint256 public totalBNBFee = reflectionFee.add(externalFee).add(liquidityFee);
    uint256 private _previoustotalBNBFee = totalBNBFee;

    uint256 public _buyLiquidityFee = 600;
    uint256 public _buyreflectionFee = 600;
    
    uint256 public _sellLiquidityFee = 600;
    uint256 public _sellreflectionFee = 800;

    uint256 private _buytotalBNBFee = _buyreflectionFee.add(externalFee).add(_buyLiquidityFee);
    uint256 private _selltotalBNBFee =_sellreflectionFee.add(externalFee).add(_sellLiquidityFee);

    uint256 private feeDenominator = 10000;

    IPANCAKERouter public router;
    address public pair;

    uint256 private _transactionLockTime = 0; //Cool down time between each transaction per address

    BTC_DISTRIBUTOR distributor; 
    uint256 distributorGas = 1000000;

    bool public swapEnabled = true;
    uint256 public _maxTxAmount = 5000000 * 10**6 * 10**_decimals; // 0.5%
    uint256 public minTokensBeforeSwapThreshold = _totalSupply / 20000; // 0.005%
    // uint256 public _maxTokensPerAddress         = 5000000 * 10**6 * 10**_decimals; // Max number of tokens that an address can hold

    event AutoLiquify(uint256 bnbAmount, uint256 tokensAmount);

    bool private inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () {
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

    function mint(address _to, uint256 _amount) public onlyMinter {
        _balances[_to] = _balances[_to].add(_amount);
        _totalSupply = _totalSupply.add(_amount);
        emit Transfer(address(0), _to, _amount);
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

        // require(isExcludedFromAntiWhale[recipient] || balanceOf(recipient) + amount <= _maxTokensPerAddress,
        // "Max tokens limit for this account exceeded. Or try lower amount");
        require(isExcludedFromTransactionlock[sender] || block.timestamp >= _transactionCheckpoint[sender] + _transactionLockTime,
        "Wait for transaction cool down time to end before making a transaction");
        require(isExcludedFromTransactionlock[recipient] || block.timestamp >= _transactionCheckpoint[recipient] + _transactionLockTime,
        "Wait for transaction cool down time to end before making a transaction");

        _transactionCheckpoint[sender] = block.timestamp;
        _transactionCheckpoint[recipient] = block.timestamp;
        
        //Buy
        if(sender == pair){
            removeAllFee();
            liquidityFee = _buyLiquidityFee;
            totalBNBFee  = _buytotalBNBFee;
            reflectionFee = _buyreflectionFee;

        }
        // Sell
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

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
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
    * @dev Sets transactions on time periods or cool downs.
    * Can only be set by owner set in seconds.
    */
    function setTransactionCooldownTime(uint256 transactiontime) public onlyOwner {
        _transactionLockTime = transactiontime;
    }

    /**  
     * @dev set max amount per transaction
     */
    function setMaxTxLimit(uint256 amount) external onlyOwner {
        _maxTxAmount = amount.mul(10**_decimals);
    }

    /**  
     * @dev set swap to BNB settings
     */
    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        minTokensBeforeSwapThreshold = _amount.mul(10**_decimals);
    }

    /**  
     * @dev Remove/add an address from BTC reward
     */
    function setIsDividendExempt(address holder, bool exempt) public onlyOwner {
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
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    /**  
     * @dev Remove/add an address from max txn amount
     */
    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    /**  
     * @dev set liquidity fee
     */
    function setLiquidityFees(uint256 _liquidityFee) external onlyOwner {
        liquidityFee = _liquidityFee;
        totalBNBFee = liquidityFee.add(reflectionFee).add(externalFee);
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

    /**  
     * @dev set BTC reward fee
     */
    function setRewardFees(uint256 _rewardFee) external onlyOwner {
        reflectionFee = _rewardFee;
        totalBNBFee = liquidityFee.add(reflectionFee).add(externalFee);
    }

    /**  
     * @dev set external fee
     */
    function setExternalFees(uint256 _externalFee) external onlyOwner {
        externalFee = _externalFee;
        totalBNBFee = liquidityFee.add(reflectionFee).add(externalFee);
    }

    /**  
     * @dev set liquidity owner address
     */
    function setLiquidityAddress(address wallet) external onlyOwner {
        autoLiquidityReceiver = wallet;
    }

    /**  
     * @dev set external address
     */
    function setExternalAddress(address wallet) external onlyOwner {
        externalAddress = wallet;
    }

    /**  
     * @dev set BTC distribution criteria
     * _minPeriod--> minimum time to wait before send
     * _minDistribution--> minimum amount of BTC reward before send to address
     */
    function setBTCDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    /**  
     * @dev set BTC distributor's setting
     * gas--> gas fee to be used from sender's gas fee to send BTC reward
     */
    function setBTCDistributorSettings(uint256 gas) external onlyOwner {
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
    * @dev includes/excludes an address from transactions from cool downs.
    * Can only be set by owner.
    */
    function setIsExcludedFromTransactionCooldown(address account, bool excluded) public onlyOwner {
        isExcludedFromTransactionlock[account] = excluded;
    }

    /**  
     * @dev Blacklist a single wallet from buying and selling
     */
    function blacklistSingleWallet(address account) external onlyOwner {
        if(isBlacklisted[account] == true) return;
        isBlacklisted[account] = true;
        setIsDividendExempt(account, true); // also remove BTC reward for address
    }

    /**  
     * @dev Blacklist multiple wallets from buying and selling
     */
    function blacklistMultipleWallets(address[] calldata accounts) external onlyOwner {
        require(accounts.length < 600, "Can not blacklist more then 600 address in one transaction");
        for (uint256 i; i < accounts.length; ++i) {
            isBlacklisted[accounts[i]] = true;
            setIsDividendExempt(accounts[i], true); // also remove BTC reward for address
        }
    }
    
    /**  
     * @dev un blacklist a single wallet from buying and selling
     */
    function unBlacklistSingleWallet(address account) external onlyOwner {
         if(isBlacklisted[account] == false) return;
        isBlacklisted[account] = false;
        setIsDividendExempt(account, false); // also includes in BTC reward for address
    }

    /**  
     * @dev un blacklist multiple wallets from buying and selling
     */
    function unBlacklistMultipleWallets(address[] calldata accounts) external onlyOwner {
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
    function recoverETH() external onlyOwner {
        address payable recipient = payable(msg.sender);
        if(address(this).balance > 0)
            recipient.transfer(address(this).balance);
    }
}