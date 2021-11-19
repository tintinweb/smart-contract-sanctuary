/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

/*
Santa Girl

Total Supply         : 100,000,000,000

Taxes:

Buy Tax 10%
    🌀 4% Marketing
    🥯 2% Auto Liquidity
    💰 4% Buyback

Sell Tax 14%
    🌀 6% Marketing
    🥯 2% Auto Liquidity
    💰 6% Buyback
    
Tokenomics
    💵 1.0% Max Buy Tx ( 1,000,000,000 $STG )
    💵 0.20% Max Sell Tx ( 200,000,000 $STG )
    💰 5% Max Bag ( 5,000,000,000 $STG )
    🔃 10 Seconds TX Cooldown ( Buy & Sell )

XMAS MODE
When it is Xmass, the Xmass mode is activated: 
    📖 Buy tax to 5%
    📖 Sell tax to 30%

Anti-Sniper Protocols
    🌀 Manual Blacklist Function
    🤭 Buy/Sell Cooldown
    😡 Max TX amount
    
 *
 */

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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
 * Allows for contract ownership for multiple adressess
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
    function authorize(address account) public onlyOwner {
        authorizations[account] = true;
    }

    /**
     * Remove address authorization. Owner only
     */
    function unauthorize(address account) public onlyOwner {
        authorizations[account] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address authorization status
     */
    function isAuthorized(address account) public view returns (bool) {
        return authorizations[account];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable account) public onlyOwner {
        owner = account;
        authorizations[account] = true;
        emit OwnershipTransferred(account);
    }

    event OwnershipTransferred(address owner);
}

/* Standard IDEXFactory */
interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

/* Standard IDEXRouter */
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

/* Interface for the DividendDistributor */
interface IDividendDistributor {
    function setDistributionCriteria(uint256 minPeriod, uint256 minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

/* Our DividendDistributor contract responsible for distributing the earn token */
contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    
    address _token;
    
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    
    // EARN
    IBEP20 CAKE = IBEP20(0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684);
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    IDEXRouter _router;
    
    address[] _shareholders;
    mapping (address => uint256) _shareholderIndexes;
    mapping (address => uint256) _shareholderClaims;
    
    mapping (address => Share) public _shares;
    
    uint256 public _totalShares;
    uint256 public _totalDividends;
    uint256 public _totalDistributed;
    uint256 public _dividendsPerShare;
    uint256 public _dividendsPerShareAccuracyFactor = 10 ** 36;
    
    uint256 public _minPeriod = 30 * 60;
    uint256 public _minDistribution = 1 * (10 ** 12);
    
    uint256 _currentIndex;
    
    bool _initialized;
    modifier initialization() {
        require(!_initialized);
        _;
        _initialized = true;
    }
    
    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }
    
    constructor (address router) {
        _router = router != address(0)
            ? IDEXRouter(router)
            : IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        _token = msg.sender;
    }
    
    function setDistributionCriteria(uint256 minPeriod, uint256 minDistribution) external override onlyToken {
        _minPeriod = minPeriod;
        _minDistribution = minDistribution;
    }
    
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (_shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && _shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        }
        else if (amount == 0 && _shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        _totalShares = _totalShares.sub(_shares[shareholder].amount).add(amount);
        _shares[shareholder].amount = amount;
        _shares[shareholder].totalExcluded = getCumulativeDividends(_shares[shareholder].amount);
    }
    
    function deposit() external payable override onlyToken {
        uint256 balanceBefore = CAKE.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(CAKE);

        _router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = CAKE.balanceOf(address(this)).sub(balanceBefore);

        _totalDividends = _totalDividends.add(amount);
        _dividendsPerShare = _dividendsPerShare.add(_dividendsPerShareAccuracyFactor.mul(amount).div(_totalShares));
    }
    
    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = _shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (_currentIndex >= shareholderCount) {
                _currentIndex = 0;
            }

            if (shouldDistribute(_shareholders[_currentIndex])) {
                distributeDividend(_shareholders[_currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            _currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return _shareholderClaims[shareholder] + _minPeriod < block.timestamp && getUnpaidEarnings(shareholder) > _minDistribution;
    }
    
    function distributeDividend(address shareholder) internal {
        if (_shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            _totalDistributed = _totalDistributed.add(amount);
            CAKE.transfer(shareholder, amount);
            _shareholderClaims[shareholder] = block.timestamp;
            _shares[shareholder].totalRealised = _shares[shareholder].totalRealised.add(amount);
            _shares[shareholder].totalExcluded = getCumulativeDividends(_shares[shareholder].amount);
        }
    }
    
    function claimDividend(address shareholder) external onlyToken{
        distributeDividend(shareholder);
    }
    
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if (_shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(_shares[shareholder].amount);
        uint256 shareholderTotalExcluded = _shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }
    
    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(_dividendsPerShare).div(_dividendsPerShareAccuracyFactor);
    }
    
    function addShareholder(address shareholder) internal {
        _shareholderIndexes[shareholder] = _shareholders.length;
        _shareholders.push(shareholder);
    }
    
    function removeShareholder(address shareholder) internal {
        _shareholders[_shareholderIndexes[shareholder]] = _shareholders[_shareholders.length-1];
        _shareholderIndexes[_shareholders[_shareholders.length-1]] = _shareholderIndexes[shareholder];
        _shareholders.pop();
    }
}

/* Token contract */
contract SantaGirl is IBEP20, Auth {
    using SafeMath for uint256;
    
    // Addresses
    address CAKE = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684; 
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEV = 0x0000000000000000000000000000000000000000;
    
    // These are owner by default
    address public _autoLiquidityReceiver;
    address public _marketingFeeReceiver;
    
    // Name and symbol
    string constant _name = "STG";
    string constant _symbol = "STG";
    uint8 constant _decimals = 18;
    
    // Total supply
    uint256 _totalSupply = 100_000_000_000 * (10 ** _decimals); // 100Md
    
    // Max wallet and TX
    uint256 public _maxBuyTxAmount = _totalSupply * 100 / 10000; // 1.0% on launch or 1Md tokens
    uint256 public _maxSellTxAmount = _totalSupply * 20 / 10000; // 0.20% or 250M tokens
    uint256 public _maxWalletToken = (_totalSupply * 500) / 10000; // 5% or 5Md tokens
    
    // Mappings
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) _isFeeExempt;
    mapping (address => bool) _isTxLimitExempt;
    mapping (address => bool) _isTimelockExempt;
    mapping (address => bool) _isDividendExempt;
    mapping (address => bool) public _isBlacklisted;
    
    // Buy Fees
    uint256 _liquidityFeeBuy = 200; 
    uint256 _buybackFeeBuy = 400;
    uint256 _reflectionFeeBuy = 0;
    uint256 _marketingFeeBuy = 400;
    uint256 _devFeeBuy = 0;
    uint256 _totalFeeBuy = 1000;
    
    // Sell fees
    uint256 _liquidityFeeSell = 200;
    uint256 _buybackFeeSell = 600;
    uint256 _reflectionFeeSell = 0;
    uint256 _marketingFeeSell = 600;
    uint256 _devFeeSell = 0;
    uint256 _totalFeeSell = 1400;
    
    // Fee variables
    uint256 _liquidityFee;
    uint256 _buybackFee;
    uint256 _reflectionFee;
    uint256 _marketingFee;
    uint256 _devFee;
    uint256 _totalFee;
    uint256 _feeDenominator = 10000;
    
    // Xmass Mode
    uint256 _xmassModeTriggeredAt;
    uint256 _xmassModeDuration = 3600;
    uint256 _xmassModeFeeBuy = 500;
    uint256 _xmassModeFeeSell = 3000;
    
    // Dead blocks
    uint256 _deadBlocks = 0;
    
    // Sell amount of tokens when a sell takes place
    uint256 public _swapThreshold = _totalSupply * 10 / 10000; // 0.1% of supply
    
    // Liquidity
    uint256 _targetLiquidity = 20;
    uint256 _targetLiquidityDenominator = 100;
    
    // Buyback settings
    uint256 _buybackMultiplierNumerator = 200;
    uint256 _buybackMultiplierDenominator = 100;
    uint256 _buybackMultiplierTriggeredAt;
    uint256 _buybackMultiplierLength = 30 minutes;
    
    bool public _autoBuybackEnabled = false;
    bool public _autoBuybackMultiplier = true;
    uint256 _autoBuybackCap;
    uint256 _autoBuybackAccumulator;
    uint256 _autoBuybackAmount;
    uint256 _autoBuybackBlockPeriod;
    uint256 _autoBuybackBlockLast;
    
    DividendDistributor _distributor;
    uint256 _distributorGas = 500000;
    
    // Cooldown & timer functionality
    bool public _buyCooldownEnabled = true;
    uint8 public _cooldownTimerInterval = 10;
    mapping (address => uint) private _cooldownTimer;
    
    // Other variables
    IDEXRouter public _router;
    address public _pair;
    uint256 public _launchedAt;
    bool public _tradingOpen = false;
    bool public _swapEnabled = true;
    bool _inSwap;
    modifier swapping()
    {
        _inSwap = true;
        _;
        _inSwap = false;
    }
    
    /* Token constructor */
    constructor () Auth(msg.sender) {
        _router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        _pair = IDEXFactory(_router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(_router)] = type(uint256).max;
        
        _distributor = new DividendDistributor(address(_router));
        
        // Should be the owner wallet/token distributor
        address _presaler = msg.sender;
        _isFeeExempt[_presaler] = true;
        _isTxLimitExempt[_presaler] = true;
        
        // No timelock for these people
        _isTimelockExempt[msg.sender] = true;
        _isTimelockExempt[DEAD] = true;
        _isTimelockExempt[address(this)] = true;
        _isTimelockExempt[DEV] = true;
        
        // Exempt from dividend
        _isDividendExempt[_pair] = true;
        _isDividendExempt[address(this)] = true;
        _isDividendExempt[DEAD] = true;
        
        // Set the marketing and liquidity receiver to the owner as default
        _autoLiquidityReceiver = msg.sender;
        _marketingFeeReceiver = msg.sender;
        
        _balances[_presaler] = _totalSupply;
        emit Transfer(address(0), _presaler, _totalSupply);
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
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    // setting the max wallet in percentages
    // NOTE: 1% = 100
     function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = _totalSupply.mul(maxWallPercent).div(10000);
    }

    // Main transfer function
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (_inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        
        // Check if trading is enabled
        if (!authorizations[sender] && !authorizations[recipient]) {
            require(_tradingOpen,"Trading not enabled yet");
        }
        
        // Check if address is blacklisted
        require(!_isBlacklisted[recipient] && !_isBlacklisted[sender], 'Address is blacklisted');
        
        // Check if buying or selling
        bool isSell = recipient == _pair; 
        
        // Set buy or sell fees
        setCorrectFees(isSell);
        
        // Check max wallet
        checkMaxWallet(sender, recipient, amount);
        
        // Check if we are in Xmass Mode
        bool xmassMode = inXmassMode();
        
        // Buycooldown 
        checkBuyCooldown(sender, recipient);
        
        // Checks maxTx
        checkTxLimit(sender, amount, recipient, isSell);
        
        // Check if we should do the swapback
        if (shouldSwapBack()) {
            swapBack();
        }
        
        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        
        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount, isSell, xmassMode) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        
        // Dividend tracker
        if (!_isDividendExempt[sender]) {
            try _distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        
        if (!_isDividendExempt[recipient]) {
            try _distributor.setShare(recipient, _balances[recipient]) {} catch {} 
        }
        
        try _distributor.process(_distributorGas) {} catch {}
        
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    // Do a normal transfer
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    // Set the correct fees for buying or selling
    function setCorrectFees(bool isSell) internal {
        if (isSell) {
            _liquidityFee = _liquidityFeeSell;
            _buybackFee = _buybackFeeSell;
            _reflectionFee = _reflectionFeeSell;
            _marketingFee = _marketingFeeSell;
            _devFee = _devFeeSell;
            _totalFee = _totalFeeSell;
        }
        else {
            _liquidityFee = _liquidityFeeBuy;
            _buybackFee = _buybackFeeBuy;
            _reflectionFee = _reflectionFeeBuy;
            _marketingFee = _marketingFeeBuy;
            _devFee = _devFeeBuy;
            _totalFee = _totalFeeBuy;
        }
    }
    
    // Check if we are in Xmass Mode
    function inXmassMode() public view returns (bool){
        if (_xmassModeTriggeredAt.add(_xmassModeDuration) > block.timestamp) {
            return true;
        }
        else {
            return false;
        }
    }
    
    // Check for maxTX
    function checkTxLimit(address sender, uint256 amount, address recipient, bool isSell) internal view {
        if (recipient != owner) {
            if (isSell) {
                require(amount <= _maxSellTxAmount || _isTxLimitExempt[sender] || _isTxLimitExempt[recipient], "TX Limit Exceeded");
            }
            else {
                require(amount <= _maxBuyTxAmount || _isTxLimitExempt[sender] || _isTxLimitExempt[recipient], "TX Limit Exceeded");
            }
        }
    }
    
    // Check buy cooldown
    function checkBuyCooldown(address sender, address recipient) internal {
        if (sender == _pair && _buyCooldownEnabled && !_isTimelockExempt[recipient]) {
            require(_cooldownTimer[recipient] < block.timestamp,"Please wait between two buys");
            _cooldownTimer[recipient] = block.timestamp + _cooldownTimerInterval;
        }
    }
    
    // Check maxWallet
    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if (!authorizations[sender] &&
            recipient != owner &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != _pair &&
            recipient != _marketingFeeReceiver &&
            recipient != _autoLiquidityReceiver &&
            recipient != DEV) {
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
        }
    }
    
    // Check if sender is not feeExempt
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !_isFeeExempt[sender];
    }
    
    // Get total fee's or multiplication of fees
    function getTotalFee(bool selling) public view returns (uint256) {
        if (_launchedAt + _deadBlocks >= block.number) {
            return _feeDenominator.sub(1);
        }
        if (selling && _buybackMultiplierTriggeredAt.add(_buybackMultiplierLength) > block.timestamp) {
            return getMultipliedFee();
        }
        return _totalFee;
    }
    
    // Get a multiplied fee when buybackMultiplier is active
    function getMultipliedFee() public view returns (uint256) {
        uint256 remainingTime = _buybackMultiplierTriggeredAt.add(_buybackMultiplierLength).sub(block.timestamp);
        uint256 feeIncrease = _totalFee.mul(_buybackMultiplierNumerator).div(_buybackMultiplierDenominator).sub(_totalFee);
        return _totalFee.add(feeIncrease.mul(remainingTime).div(_buybackMultiplierLength));
    }
    
    // Take the normal total Fee or the Xmass Fee
    function takeFee(address sender, uint256 amount, bool isSell, bool xmassMode) internal returns (uint256) {
        uint256 feeAmount;
        
        // Check if we are in Xmass Mode
        if (xmassMode) {
            if (isSell) {
                // We are selling so up the selling tax to 30%
                feeAmount = amount.mul(_xmassModeFeeSell).div(_feeDenominator);
            }
            else {
                // We are buying so cut our taxes to 5%
                feeAmount = amount.mul(_xmassModeFeeBuy).div(_feeDenominator);
            }
        }
        else {
            feeAmount = amount.mul(_totalFee).div(_feeDenominator);
        }
        
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        
        return amount.sub(feeAmount);
    }
    
    // Check if we should sell tokens
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != _pair && !_inSwap && _swapEnabled && _balances[address(this)] >= _swapThreshold;
    }
    
    // switch Trading
    function tradingStatus(bool status) public onlyOwner {
        _tradingOpen = status;
        launch();
    }
    
    // Enable Xmass mode
    function enableXmassMode(uint256 durationInSeconds) public authorized {
        _xmassModeTriggeredAt = block.timestamp;
        _xmassModeDuration = durationInSeconds;
    }
    
    // Disable the Xmass mode
    function disableXmassMode() external authorized {
        _xmassModeTriggeredAt = 0;
    }
    
    // Enable/disable cooldown between trades
    function cooldownEnabled(bool status, uint8 interval) public authorized {
        _buyCooldownEnabled = status;
        _cooldownTimerInterval = interval;
    }
    
    // Blacklist/unblacklist an address
    function blacklistAddress(address wallet, bool value) public authorized{
        _isBlacklisted[wallet] = value;
    }
    
    // Main swapback to sell tokens for WBNB
    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(_targetLiquidity, _targetLiquidityDenominator) ? 0 : _liquidityFee;
        uint256 amountToLiquify = _swapThreshold.mul(dynamicLiquidityFee).div(_totalFee).div(2);
        uint256 amountToSwap = _swapThreshold.sub(amountToLiquify);
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        
        uint256 balanceBefore = address(this).balance;
        
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        
        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 totalBNBFee = _totalFee.sub(dynamicLiquidityFee.div(2));
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(_reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(_marketingFee).div(totalBNBFee);
        uint256 amountBNBDev = amountBNB.mul(_devFee).div(totalBNBFee); 
        
        try _distributor.deposit{value: amountBNBReflection}() {} catch {}
        (bool successMarketing, /* bytes memory data */) = payable(_marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        (bool successDev, /* bytes memory data */) = payable(DEV).call{value: amountBNBDev, gas: 30000}(""); 
        require(successMarketing, "marketing receiver rejected ETH transfer");
        require(successDev, "dev receiver rejected ETH transfer");
        
        if (amountToLiquify > 0) {
            _router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                _autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }
    
    // Check if autoBuyback is enabled
    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != _pair &&
            !_inSwap &&
            _autoBuybackEnabled &&
            _autoBuybackBlockLast + _autoBuybackBlockPeriod <= block.number &&
            address(this).balance >= _autoBuybackAmount;
    }
    
    // Trigger a manual buyback
    function triggerManualBuyback(uint256 amount, bool triggerBuybackMultiplier) external authorized {
        uint256 amountWithDecimals = amount * (10 ** 18);
        uint256 amountToBuy = amountWithDecimals.div(100);
        buyTokens(amountToBuy, DEAD);
        if (triggerBuybackMultiplier) {
            _buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(_buybackMultiplierLength);
        }
    }
    
    // Stop the buyback Multiplier
    function clearBuybackMultiplier() external authorized {
        _buybackMultiplierTriggeredAt = 0;
    }
    
    // Trigger an autobuyback
    function triggerAutoBuyback() internal {
        buyTokens(_autoBuybackAmount, DEAD);
        if (_autoBuybackMultiplier) {
            _buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(_buybackMultiplierLength);
        }
        _autoBuybackBlockLast = block.number;
        _autoBuybackAccumulator = _autoBuybackAccumulator.add(_autoBuybackAmount);
        if (_autoBuybackAccumulator > _autoBuybackCap) {
            _autoBuybackEnabled = false;
        }
    }
    
    // Buy amount of tokens with bnb from the contract
    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);
        
        _router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    // Set autobuyback settings
    function setAutoBuybackSettings(bool enabled, uint256 cap, uint256 amount, uint256 period, bool autoBuybackMultiplier) external authorized {
        _autoBuybackEnabled = enabled;
        _autoBuybackCap = cap;
        _autoBuybackAccumulator = 0;
        _autoBuybackAmount = amount;
        _autoBuybackBlockPeriod = period;
        _autoBuybackBlockLast = block.number;
        _autoBuybackMultiplier = autoBuybackMultiplier;
    }

    // Set buybackmultiplier settings
    function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorized {
        require(numerator / denominator <= 2 && numerator > denominator);
        _buybackMultiplierNumerator = numerator;
        _buybackMultiplierDenominator = denominator;
        _buybackMultiplierLength = length;
    }

    // Check when the token is launched
    function launched() internal view returns (bool) {
        return _launchedAt != 0;
    }

    // Set the launchedAt to token launch
    function launch() internal {
        _launchedAt = block.number;
    }

    // Set max buy TX 
    function setBuyTxLimitInPercent(uint256 maxBuyTxPercent) external authorized {
        _maxBuyTxAmount = _totalSupply.mul(maxBuyTxPercent).div(10000);
    }

    // Set max sell TX 
    function setSellTxLimitInPercent(uint256 maxSellTxPercent) external authorized {
        _maxSellTxAmount = _totalSupply.mul(maxSellTxPercent).div(10000);
    }

    // Exempt from dividend
    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != _pair);
        _isDividendExempt[holder] = exempt;
        if (exempt) {
            _distributor.setShare(holder, 0);
        }
        else {
            _distributor.setShare(holder, _balances[holder]);
        }
    }

    // Exempt from fee
    function setIsFeeExempt(address holder, bool exempt) external authorized {
        _isFeeExempt[holder] = exempt;
    }

    // Exempt from max TX
    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        _isTxLimitExempt[holder] = exempt;
    }

    // Exempt from buy CD
    function setIsTimelockExempt(address holder, bool exempt) external authorized {
        _isTimelockExempt[holder] = exempt;
    }

    // Set our buy fees
    function setBuyFees(uint256 liquidityFeeBuy, uint256 buybackFeeBuy, uint256 reflectionFeeBuy, uint256 marketingFeeBuy, uint256 devFeeBuy, uint256 feeDenominator) external authorized {
        _liquidityFeeBuy = liquidityFeeBuy;
        _buybackFeeBuy = buybackFeeBuy;
        _reflectionFeeBuy = reflectionFeeBuy;
        _marketingFeeBuy = marketingFeeBuy;
        _devFeeBuy = devFeeBuy;
        _totalFeeBuy = liquidityFeeBuy.add(buybackFeeBuy).add(reflectionFeeBuy).add(marketingFeeBuy).add(devFeeBuy);
        _feeDenominator = feeDenominator;
    }

    // Set our sell fees
    function setSellFees(uint256 liquidityFeeSell, uint256 buybackFeeSell, uint256 reflectionFeeSell, uint256 marketingFeeSell, uint256 devFeeSell, uint256 feeDenominator) external authorized {
        _liquidityFeeSell = liquidityFeeSell;
        _buybackFeeSell = buybackFeeSell;
        _reflectionFeeSell = reflectionFeeSell;
        _marketingFeeSell = marketingFeeSell;
        _devFeeSell = devFeeSell;
        _totalFeeSell = liquidityFeeSell.add(buybackFeeSell).add(reflectionFeeSell).add(marketingFeeSell).add(devFeeSell);
        _feeDenominator = feeDenominator;
    }
    
    // Set Xmass mode fees
    function setXmassModeFees(uint256 xmassModeFeeBuy, uint256 xmassModeFeeSell) external authorized {
        _xmassModeFeeBuy = xmassModeFeeBuy;
        _xmassModeFeeSell = xmassModeFeeSell;
    }
    
    // Set the marketing and liquidity receivers
    function setFeeReceivers(address autoLiquidityReceiver, address marketingFeeReceiver) external authorized {
        _autoLiquidityReceiver = autoLiquidityReceiver;
        _marketingFeeReceiver = marketingFeeReceiver;
    }

    // Set swapBack settings
    function setSwapBackSettings(bool enabled, uint256 amount) external authorized {
        _swapEnabled = enabled;
        _swapThreshold = _totalSupply * amount / 10000; 
    }

    // Set target liquidity
    function setTargetLiquidity(uint256 target, uint256 denominator) external authorized {
        _targetLiquidity = target;
        _targetLiquidityDenominator = denominator;
    }

    // Send BNB to marketingwallet
    function manualSend() external authorized {
        uint256 contractETHBalance = address(this).balance;
        payable(_marketingFeeReceiver).transfer(contractETHBalance);
    }
    
    // Set criteria for auto distribution
    function setDistributionCriteria(uint256 minPeriod, uint256 minDistribution) external authorized {
        _distributor.setDistributionCriteria(minPeriod, minDistribution);
    }
    
    // Let people claim there dividend
    function claimDividend() external {
        _distributor.claimDividend(msg.sender);
    }
    
    // Check how much earnings are unpaid
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        return _distributor.getUnpaidEarnings(shareholder);
    } 

    // Set gas for distributor
    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        _distributorGas = gas;
    }
    
    // Get the circulatingSupply
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    // Get the liquidity backing
    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(_pair).mul(2)).div(getCirculatingSupply());
    }

    // Get if we are over liquified or not
    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }
    
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
}