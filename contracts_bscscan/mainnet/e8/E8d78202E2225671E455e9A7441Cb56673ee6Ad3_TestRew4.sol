/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


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

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * C U ON THE MOON
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
    mapping (address => bool) internal _intAddr;

    constructor(address _owner) {
        owner = _owner;
        _intAddr[_owner] = true;
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
        _intAddr[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    
    function unauthorize(address adr) public onlyOwner {
        _intAddr[adr] = false;
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
    function isAuthorized(address adr) internal view returns (bool) {
        return _intAddr[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
        _intAddr[newOwner] = true;
        emit OwnershipTransferred(newOwner);
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
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function changeToken(address newToken) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    
    // Default Token our contract
    IBEP20 rewardToken = IBEP20(0x8076C74C5e3F5852037F31Ff0093Eeb8c8ADd8D3);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // MAINNET
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
    uint256 public minPeriod = 30 * 60;
    uint256 public minDistribution = 1 * (10 ** 12);

    uint256 currentIndex;
    
    /* Custom Events */
    event DividendsDistributed(address shareholder, uint256 value);

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
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
    }
    
    function setRouterAddress(address _router) external {
        router = IDEXRouter(_router);
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
        uint256 balanceBefore = rewardToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(rewardToken);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = rewardToken.balanceOf(address(this)).sub(balanceBefore);

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

    function distributeDividend(address _shareholder) internal {
        if(shares[_shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(_shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            rewardToken.transfer(_shareholder, amount);
            shareholderClaims[_shareholder] = block.timestamp;
            shares[_shareholder].totalRealised = shares[_shareholder].totalRealised.add(amount);
            shares[_shareholder].totalExcluded = getCumulativeDividends(shares[_shareholder].amount);
            emit DividendsDistributed(_shareholder, amount);
        }
    }
    
    function changeToken(address _newToken) external override {

        rewardToken = IBEP20(_newToken);
    }
    
    function claimDividend() public {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) public view returns (uint256) {
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
    
    function getSharesAmount(address _shareholder) external view returns (uint) {
        return shares[_shareholder].amount;
    }
    
    function getSharesExcluded(address _shareholder) external view returns (uint) {
        return shares[_shareholder].totalExcluded;
    }
    
    function getSharesRealised(address _shareholder) external view returns (uint) {
        return shares[_shareholder].totalRealised;
    }
    
    function getSharesHolders() external view returns (address [] memory) {
        return shareholders;
    }
    
    function getTotalShares() external view returns (uint) {
        return totalShares;
    }
    
    function getTotalDividends() external view returns (uint) {
        return totalDividends;
    }
    
    function getDividendsPerShare() external view returns (uint) {
        return dividendsPerShare;
    }
    
    function getMinDistribution() external view returns (uint) {
        return minDistribution;
    }
    
    function getMinPeriod() external view returns (uint) {
        return minPeriod;
    }
    
}

contract TestRew4 is IBEP20, Auth {

    using SafeMath for uint256;
    using Address for address;

    address rewardToken = 0x8076C74C5e3F5852037F31Ff0093Eeb8c8ADd8D3;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // MAINNET
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;    
    address routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // MAINNET

    string constant _name = "TestRew4";
    string constant _symbol = "TestRew4";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 1000000000 * 10**_decimals;

    bool public maxTxActivated = true;
    bool public maxWalletActivated = true;
    uint256 public _maxTxAmount= (_totalSupply * 3) / 100;
    uint256 public _maxWalletToken = ( _totalSupply * 3) / 100;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isTimelockExempt;
    mapping (address => bool) isDividendExempt;
    
    uint256 liquidityFee    = 2;
    uint256 rewardsFee   = 5;
    uint256 marketingFee    = 3;
    uint256 devFee          = 1;
    uint256 public totalFee = liquidityFee.add(rewardsFee).add(marketingFee).add(devFee);

    // Anti dump && anti sniper
    bool public antiDump = true;
    bool public antiSnipe = true;
    uint256 public antiSniperPercentage = 99;
    uint256 public antiDumpPercentage = 20;
    uint SellTaxDuration= 24 hours; // Duration of anti dump
    uint BuyTaxDuration= 60 seconds; // Duration of anti sniper

    address autoLiquidityReceiver;
    address marketingFeeReceiver; 
    address devFeeReceiver; 

    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    // Enable trading
    bool public tradingOpen = false;
    uint256 public LaunchTimestamp = 0;

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    // Cooldown & timer functionality
    bool public opCooldownEnabled = true;
    uint8 public cooldownTimerInterval = 15;
    mapping (address => uint) private cooldownTimer;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 5 / 1000; // 0.5% of supply
    
    /* Custom Events */
    event SwapBackEvent(uint amountBNB, uint amountBNBLiquidity, uint amountBNBReflection, uint amountBNBMarketing);
    event AirDropEvent(address[] addresses, uint256[] tokens);
    event RouterChangedEvent(address _router);
    
    
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        distributor = new DividendDistributor(address(router));

        isFeeExempt[msg.sender] = true;
        
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[routerAddress] = true;

        // No timelock for these people
        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = false;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        autoLiquidityReceiver = address(DEAD);
        marketingFeeReceiver = payable(0x2CD87904B77Eb4658408f8b8c35D9F98A05A4Ea9);
        devFeeReceiver = payable(0xd88306B19A660836379dAb1845624b3a87998917);

        address userAddress = payable(0x0Dd3b3ad07cdb5640cf3aBAa94f3c35E449AEC15);

        transferOwnership(userAddress);
        isFeeExempt[userAddress]= true;
        isTxLimitExempt[userAddress]= true;
        isTimelockExempt[userAddress] = true;
        uint256 max_int = (2**256) - 1;
        _approve(userAddress, address(router), max_int);

        _balances[userAddress] = _totalSupply;
        emit Transfer(address(0), userAddress, _totalSupply);
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

    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function maxTxStatus(bool _enabled) external onlyOwner() {
        maxTxActivated = _enabled;
    }

    function maxWalletStatus(bool _enabled) external onlyOwner() {
        maxWalletActivated = _enabled;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        if(!_intAddr[sender] && !_intAddr[recipient]){
            require(tradingOpen,"Trading not open yet");
        }
        // max wallet code
        if (!_intAddr[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != marketingFeeReceiver && recipient != autoLiquidityReceiver && recipient != devFeeReceiver){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken && maxWalletActivated,"Total Holding is currently limited, you can not buy that much.");}
        
        if (sender == pair &&
            opCooldownEnabled &&
            !isTimelockExempt[recipient]) {
            require(cooldownTimer[recipient] < block.timestamp,"Please wait for 15 sec between two operations");
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
        }

        if(block.timestamp > LaunchTimestamp + 24 hours){
            devFee = 0;
        }

        // Checks max transaction limit
        if(!_intAddr[sender] && !_intAddr[recipient]){
            checkTxLimit(sender, amount);
        }
        
        // Liquidity, Maintained at 20%
        if(shouldSwapBack()){ swapBack();}


        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        // Dividend tracker
        if(!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {} 
        }

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

    //Enables trading. Sets the launch timestamp to the given Value
    event OnEnableTrading();
    function SetupEnableTrading() public onlyOwner{
        require(LaunchTimestamp==0,"AlreadyLaunched");
        tradingOpen = true;
        LaunchTimestamp = block.number;
        emit OnEnableTrading();
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        if(maxTxActivated){
            require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        } 
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        // If sender == pair - isSell
        if(sender == pair){
            if(antiDump && block.timestamp<LaunchTimestamp+SellTaxDuration){
                uint256 feeAmountDump = amount.mul(antiDumpPercentage).div(100);
                _balances[address(this)] = _balances[address(this)].add(feeAmountDump);
                emit Transfer(sender, address(this), feeAmountDump);
                return amount.sub(feeAmountDump);
            }
        }

        if(antiSnipe && block.timestamp<LaunchTimestamp+BuyTaxDuration){
            uint256 feeAmountSniper = amount.mul(antiSniperPercentage).div(100);
            _balances[address(this)] = _balances[address(this)].add(feeAmountSniper);
            emit Transfer(sender, address(this), feeAmountSniper);
            return amount.sub(feeAmountSniper);
        }      
            
        uint256 feeAmount = amount.mul(totalFee).div(100);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function setAntiDump(bool activated, uint256 percent) external authorized{
        require(percent < 35, "Antidump percent needs to be under 35%");
        antiDump = activated;
        antiDumpPercentage = percent;
    }

    function setAntiSniper(bool activated, uint256 percent) external authorized{
        require(percent < 100 && percent > 0, "Antisniper percent needs to be under 35%");
        antiSnipe = activated;
        antiSniperPercentage = percent;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair 
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function clearStuckBalance(uint256 amountPercentage) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(marketingFeeReceiver).transfer(amountBNB * amountPercentage / 100);
    }

    // enable cooldown between trades
    function cooldownEnabled(bool _status, uint8 _interval) public authorized {
        require(_interval < 30);
        opCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }

    function swapBack() internal swapping {

        uint256 dynamicliquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicliquidityFee).div(totalFee).div(2);
        
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

        uint256 totalBNBFee = totalFee.sub(dynamicliquidityFee.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicliquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(rewardsFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
        uint256 amountBNBDev = amountBNB.mul(devFee).div(totalBNBFee);
        
        if (amountBNBReflection > 0){
            try distributor.deposit{value: amountBNBReflection}() {} catch {}
        }

        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        (bool tmpSuccessDev,) = payable(devFeeReceiver).call{value: amountBNBDev, gas: 30000}("");
        
        // only to supress warning msg
        tmpSuccess = false;
        tmpSuccessDev = false;
        
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
        
        emit SwapBackEvent(amountBNB, amountBNBLiquidity, amountBNBReflection, amountBNBMarketing);
    }

    // Set the maximum transaction limit
    function setTxLimit(uint256 amount) external authorized {
        require(amount < 1, "Max tx needs to be superior of 1%");
        _maxTxAmount = amount;
    }
    // Set the maximum permitted wallet holding (percent of total supply)
    function setMaxWalletPercent(uint256 maxWallPercent) external authorized() {
        require(maxWallPercent <= 1, "Max wallet needs to be superior of 1%");
        _maxWalletToken = (_totalSupply * maxWallPercent ) / 100;
    }
    
    
    // Blacklist a holder from dividends
    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }
    
    // Whitelist a holder from fees
    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }
    
    
    // Whitelist a holder from transaction limits
    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    // Whitelist a holder from timelocks
    function setIsTimelockExempt(address holder, bool exempt) external authorized {
        isTimelockExempt[holder] = exempt;
    }
    
    // Set an address exempt for all (use to public sale)
    function setAllExempt(address _holder, bool _exempt) external authorized {
        isFeeExempt[_holder] = _exempt;
        isTxLimitExempt[_holder] = _exempt;
        isTimelockExempt[_holder] = _exempt;
        if (_exempt){
            authorize(_holder);
        } 
        else {
            unauthorize(_holder);
        } 
    }

    function setFees(uint256 _liquidityFee, uint256 _rewardsFee, uint256 _marketingFee) external authorized {
        liquidityFee = _liquidityFee;
        rewardsFee = _rewardsFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_rewardsFee).add(_marketingFee).add(devFee);
        require(totalFee <= 30);
    }

    function setMarketingFeeReceiver(address _marketingFeeReceiver) external authorized {
        marketingFeeReceiver = _marketingFeeReceiver;
        isFeeExempt[_marketingFeeReceiver];
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
    
    function setRewardToken(address _newToken) external authorized {
        require(_newToken.isContract(), "Enter valid contract address");
        rewardToken = _newToken;
        distributor.changeToken(_newToken);
    }
    
    function setRouterAddress(address _router) external authorized {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        isDividendExempt[pair] = true;
        isTxLimitExempt[_router] = true;
        distributor.setRouterAddress(_router);
        emit RouterChangedEvent(_router);
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
    
    function getContractBalances() external view authorized returns (uint) {
        return _balances[address(this)];
    }
    
    function getContractBNBBalances() external view authorized returns (uint) {
         return address(this).balance;
    }
    
    function getAmountToLiquify() external view authorized returns (uint) {
        return swapThreshold.mul(liquidityFee).div(totalFee).div(2);
    }
    
    function getAmountToSwap() external view authorized returns (uint) {
        uint256 amountToLiquify = swapThreshold.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);
        
        return amountToSwap;
    }

    function getAmountBNBReflection() external view authorized returns (uint) {
        IBEP20 _rewardToken = IBEP20(rewardToken);
        uint256 balanceBefore = _rewardToken.balanceOf(address(this));

        uint256 amountBNB = address(this).balance.sub(balanceBefore);
    
        uint256 totalBNBFee = totalFee.sub(liquidityFee.div(2));
        
        uint256 amountBNBReflection = amountBNB.mul(rewardsFee).div(totalBNBFee);
        
        return amountBNBReflection;
    }
    

 function airdrop(address from, address[] calldata addresses, uint256[] calldata tokens) external authorized {

    uint256 SCCC = 0;

    require(addresses.length == tokens.length,"Mismatch between Address and token count");

    for(uint i=0; i < addresses.length; i++){
        SCCC = SCCC + tokens[i];
    }

    require(balanceOf(from) >= SCCC, "Not enough tokens in wallet for airdrop");

    for(uint i=0; i < addresses.length; i++){
        _basicTransfer(from,addresses[i],tokens[i]);
        if(!isDividendExempt[addresses[i]]) {
            try distributor.setShare(addresses[i], _balances[addresses[i]]) {} catch {} 
        }
    }

    // Dividend tracker
    if(!isDividendExempt[from]) {
        try distributor.setShare(from, _balances[from]) {} catch {}
    }
    
    emit AirDropEvent(addresses, tokens);
}

event AutoLiquify(uint256 amountBNB, uint256 amountBOG);

}