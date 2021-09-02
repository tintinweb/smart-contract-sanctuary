/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

enum Permission {
    Authorize,
    Unauthorize,
    LockPermissions,

    AdjustVariables,
    ExcludeInclude,
    TriggerMultiplier,

    RescueTokens,
    Blacklist,
    LimitTrading,
    Launch
}

/**
 * Allows for contract ownership along with multi-address authorization for different permissions
 */
abstract contract Auth {
    struct PermissionLock {
        bool isLocked;
        uint64 expiryTime;
    }

    address public owner;
    mapping(address => mapping(uint256 => bool)) private authorizations; // uint256 is permission index
    
    uint256 constant NUM_PERMISSIONS = 10; // always has to be adjusted when Permission element is added or removed
    mapping(string => uint256) permissionNameToIndex;
    mapping(uint256 => string) permissionIndexToName;

    mapping(uint256 => PermissionLock) lockedPermissions;

    constructor(address owner_) {
        owner = owner_;
        for (uint256 i; i < NUM_PERMISSIONS; i++) {
            authorizations[owner_][i] = true;
        }

        permissionNameToIndex["TriggerMultiplier"] = uint256(Permission.TriggerMultiplier);
        permissionNameToIndex["AdjustVariables"] = uint256(Permission.AdjustVariables);
        permissionNameToIndex["Authorize"] = uint256(Permission.Authorize);
        permissionNameToIndex["Unauthorize"] = uint256(Permission.Unauthorize);
        permissionNameToIndex["LockPermissions"] = uint256(Permission.LockPermissions);
        permissionNameToIndex["ExcludeInclude"] = uint256(Permission.ExcludeInclude);
        permissionNameToIndex["RescueTokens"] = uint256(Permission.RescueTokens);
        permissionNameToIndex["Blacklist"] = uint256(Permission.Blacklist);
        permissionNameToIndex["LimitTrading"] = uint256(Permission.LimitTrading);
        permissionNameToIndex["Launch"] = uint256(Permission.Launch);

        permissionIndexToName[uint256(Permission.TriggerMultiplier)] = "TriggerMultiplier";
        permissionIndexToName[uint256(Permission.AdjustVariables)] = "AdjustVariables";
        permissionIndexToName[uint256(Permission.Authorize)] = "Authorize";
        permissionIndexToName[uint256(Permission.Unauthorize)] = "Unauthorize";
        permissionIndexToName[uint256(Permission.LockPermissions)] = "LockPermissions";
        permissionIndexToName[uint256(Permission.ExcludeInclude)] = "ExcludeInclude";
        permissionIndexToName[uint256(Permission.RescueTokens)] = "RescueTokens";
        permissionIndexToName[uint256(Permission.Blacklist)] = "Blacklist";
        permissionIndexToName[uint256(Permission.LimitTrading)] = "LimitTrading";
        permissionIndexToName[uint256(Permission.Launch)] = "Launch";
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownership required."); _;
    }

    /**
     * Function to require caller to be authorized
     */
    function authorizedFor(Permission permission) internal view {
        require(!lockedPermissions[uint256(permission)].isLocked, "Permission is locked.");
        require(isAuthorizedFor(msg.sender, permission), string(abi.encodePacked("Not authorized. You need the permission ", permissionIndexToName[uint256(permission)])));
    }

    /**
     * Authorize address for one permission
     */
    function authorizeFor(address adr, string memory permissionName) public {
        authorizedFor(Permission.Authorize);
        uint256 permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = true;
        emit AuthorizedFor(adr, permissionName, permIndex);
    }

    /**
     * Authorize address for multiple permissions
     */
    function authorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public {
        for (uint256 i; i < permissionNames.length; i++) {
            authorizedFor(Permission.Authorize);
            uint256 permIndex = permissionNameToIndex[permissionNames[i]];
            authorizations[adr][permIndex] = true;
            emit AuthorizedFor(adr, permissionNames[i], permIndex);
        }
    }

    /**
     * Remove address' authorization
     */
    function unauthorizeFor(address adr, string memory permissionName) public {
        authorizedFor(Permission.Unauthorize);
        require(adr != owner, "Can't unauthorize owner");

        uint256 permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = false;
        emit UnauthorizedFor(adr, permissionName, permIndex);
    }

    /**
     * Unauthorize address for multiple permissions
     */
    function unauthorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public {
        authorizedFor(Permission.Unauthorize);
        require(adr != owner, "Can't unauthorize owner");

        for (uint256 i; i < permissionNames.length; i++) {
            uint256 permIndex = permissionNameToIndex[permissionNames[i]];
            authorizations[adr][permIndex] = false;
            emit UnauthorizedFor(adr, permissionNames[i], permIndex);
        }
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
    function isAuthorizedFor(address adr, string memory permissionName) public view returns (bool) {
        return authorizations[adr][permissionNameToIndex[permissionName]];
    }

    /**
     * Return address' authorization status
     */
    function isAuthorizedFor(address adr, Permission permission) public view returns (bool) {
        return authorizations[adr][uint256(permission)];
    }

    /**
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public onlyOwner {
        address oldOwner = owner;
        owner = adr;
        for (uint256 i; i < NUM_PERMISSIONS; i++) {
            authorizations[oldOwner][i] = false;
            authorizations[owner][i] = true;
        }
        emit OwnershipTransferred(oldOwner, owner);
    }

    /**
     * Get the index of the permission by its name
     */
    function getPermissionNameToIndex(string memory permissionName) public view returns (uint256) {
        return permissionNameToIndex[permissionName];
    }
    
    /**
     * Get the time the timelock expires
     */
    function getPermissionUnlockTime(string memory permissionName) public view returns (uint256) {
        return lockedPermissions[permissionNameToIndex[permissionName]].expiryTime;
    }

    /**
     * Check if the permission is locked
     */
    function isLocked(string memory permissionName) public view returns (bool) {
        return lockedPermissions[permissionNameToIndex[permissionName]].isLocked;
    }

    /*
     *Locks the permission from being used for the amount of time provided
     */
    function lockPermission(string memory permissionName, uint64 time) public virtual {
        authorizedFor(Permission.LockPermissions);

        uint256 permIndex = permissionNameToIndex[permissionName];
        uint64 expiryTime = uint64(block.timestamp) + time;
        lockedPermissions[permIndex] = PermissionLock(true, expiryTime);
        emit PermissionLocked(permissionName, permIndex, expiryTime);
    }
    
    /*
     * Unlocks the permission if the lock has expired 
     */
    function unlockPermission(string memory permissionName) public virtual {
        require(block.timestamp > getPermissionUnlockTime(permissionName) , "Permission is locked until the expiry time.");
        uint256 permIndex = permissionNameToIndex[permissionName];
        lockedPermissions[permIndex].isLocked = false;
        emit PermissionUnlocked(permissionName, permIndex);
    }

    event PermissionLocked(string permissionName, uint256 permissionIndex, uint64 expiryTime);
    event PermissionUnlocked(string permissionName, uint256 permissionIndex);
    event OwnershipTransferred(address from, address to);
    event AuthorizedFor(address adr, string permissionName, uint256 permissionIndex);
    event UnauthorizedFor(address adr, string permissionName, uint256 permissionIndex);
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

    IBEP20 BUSD = IBEP20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
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
    uint256 public minDistribution = 1 * (10 ** 14); //not sure what to set

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
            BUSD.transfer(shareholder, amount);
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

contract BingusNetwork is IBEP20, Auth {
    using SafeMath for uint256;

    struct FeeReceiver {
        address adr;
        uint96 weight;
    }

    address BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Bingus Network";
    string constant _symbol = "BINGUS";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100 * 10 ** 6 * (10 ** _decimals); // 100 million
    uint256 public _maxTxAmount = _totalSupply / 1000; // 0.1%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public isTxHookExempt;
    mapping (address => bool) public isWhitelistedForLimitedTrading;
    mapping (address => bool) public isBlacklisted;

    uint256 public liquidityFee = 200; // sell = 400
    uint256 public reflectionFee = 300; // sell = 600
    uint256 public utilityFee = 500; // split up across dev (1) /marketing (2), buyback (2) / sell = (2)(4)(4)

    uint256 public totalBuyFee = 1200;
    uint256 public totalSellFee = 1200;
    uint256 public feeDenominator = 10000;
    uint256 public sellFeeIncreaseFactor = 200; // sell fee increase

    //FeeReceiver[] public feeReceivers;
    //uint256 totalWeight;
    bool public pushAutomatically = false;
    uint256 public pushThreshold = 200 * 10 ** 18;

    address public autoLiquidityReceiver;
    address public utilityFeeReceiver;
    
    uint256 public targetLiquidity = 25;
    uint256 public targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public apeswapBNBPair;
    address[] public pairs;

    uint256 public launchedAt;

    uint256 public floppaNumerator = 150;
    uint256 public bingusNumerator = 50;
    uint256 public feeMultipliersDenominator = 100;
    uint256 public feeMultipliersTriggeredAt;
    uint256 public feeMultipliersDuration = 30 minutes;

    bool public feesOnNormalTransfers = false;

    bool public tradingLimited = true;

    uint public gasPriceLimit = 25 gwei;
    uint highTaxBlocks = 2;

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 5000; // 0.02%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        apeswapBNBPair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);

        pairs.push(apeswapBNBPair);

        address owner_ = msg.sender;

        isFeeExempt[owner_] = true;
        isTxLimitExempt[owner_] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[apeswapBNBPair] = true;
        isDividendExempt[DEAD] = true;
        isWhitelistedForLimitedTrading[owner_] = true;
        isWhitelistedForLimitedTrading[address(this)] = true;

        autoLiquidityReceiver = msg.sender;
        utilityFeeReceiver = msg.sender;

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
        return approve(spender, ~uint256(0));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        uint256 senderAllowance = _allowances[sender][msg.sender];

        if (senderAllowance != ~uint256(0)) {
            _allowances[sender][msg.sender] = senderAllowance.sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if (tradingLimited) {
            checkAllowedToTrade(sender, recipient);
        }
        
        require(!isBlacklisted[sender] && !isBlacklisted[recipient] && !isBlacklisted[msg.sender], "Sender or recipient is blacklisted");

        bool skipTxHook = isTxHookExempt[sender] || isTxHookExempt[recipient];

        if (inSwap) { return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, recipient, amount);
        checkGasPriceLimit();

        if (!skipTxHook && shouldSwapBack()) { swapBack(); }

        uint256 senderBal = _balances[sender];
        uint256 recipientBal = _balances[recipient];

        _balances[sender] = senderBal.sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = recipientBal.add(amountReceived);

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

    function checkTxLimit(address sender, address recipient, uint256 amount) public view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded");
    }

    function checkGasPriceLimit() internal view {
        require(tx.gasprice <= gasPriceLimit, "Gas price too high.");
    }

    function checkAllowedToTrade(address sender, address recipient) public view {
        require(isWhitelistedForLimitedTrading[sender] || isWhitelistedForLimitedTrading[recipient], "Not whitelisted while trading is limited.");
    }

    function shouldTakeFee(address sender, address recipient) public view returns (bool) {
        if (isFeeExempt[sender] || isFeeExempt[recipient] || !launched()) return false;

        address[] memory liqPairs = pairs;

        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i] || recipient == liqPairs[i]) return true;
        }

        return feesOnNormalTransfers;
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if (block.number < launchedAt + highTaxBlocks) { return feeDenominator.sub(1); }
        if (selling && feeMultipliersTriggeredAt.add(feeMultipliersDuration) > block.timestamp) { return getFloppaFee(); }
        if (!selling && feeMultipliersTriggeredAt.add(feeMultipliersDuration) > block.timestamp) { return getBingusFee(); }
        return selling ? totalSellFee.mul(sellFeeIncreaseFactor) : totalBuyFee;
    }

    function getFloppaFee() public view returns (uint256) {
        uint256 totalFee = totalSellFee.mul(sellFeeIncreaseFactor);
        uint256 remainingTime = feeMultipliersTriggeredAt.add(feeMultipliersDuration).sub(block.timestamp);
        uint256 feeIncrease = totalFee.mul(floppaNumerator).div(feeMultipliersDenominator).sub(totalFee);
        return totalFee.add(feeIncrease.mul(remainingTime).div(feeMultipliersDuration));
    }

    function getBingusFee() public view returns (uint256) {
        uint256 totalFee = totalBuyFee;
        uint256 remainingTime = feeMultipliersTriggeredAt.add(feeMultipliersDuration).sub(block.timestamp);
        uint256 feeDecrease = totalFee.sub(totalFee.mul(bingusNumerator).div(feeMultipliersDenominator));
        return totalFee.sub(feeDecrease.mul(remainingTime).div(feeMultipliersDuration));
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(isSell(recipient))).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function isSell(address recipient) internal view returns (bool) {
        address[] memory liqPairs = pairs;
        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (recipient == liqPairs[i]) return true;
        }
        return false;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != apeswapBNBPair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalBuyFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        ) {
            uint256 amountBNB = address(this).balance.sub(balanceBefore);
            uint256 totalBNBFee = totalBuyFee.sub(dynamicLiquidityFee.div(2));

            uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
            uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
            uint256 amountBNBUtility = amountBNB.mul(utilityFee).div(totalBNBFee);
     //       uint256 amountBNBToBUSD = amountBNB.sub(amountBNBLiquidity);
            
            try distributor.deposit{value: amountBNBReflection}() {} catch {}
            payable(utilityFeeReceiver).call{value: amountBNBUtility, gas: 30000}("");
             
         //   swapToBusd(amountBNBToBUSD);

         //   if (pushAutomatically && IBEP20(BUSD).balanceOf(address(this)) >= pushThreshold) {
          //      pushFees();
        //    }

            if (amountToLiquify > 0) {
                try router.addLiquidityETH{ value: amountBNBLiquidity }(
                    address(this),
                    amountToLiquify,
                    0,
                    0,
                    autoLiquidityReceiver,
                    block.timestamp
                ) {
                    emit AutoLiquify(amountToLiquify, amountBNBLiquidity);
                } catch {
                    emit AutoLiquify(0, 0);
                }
            }

            emit SwapBackSuccess(amountToSwap);
        } catch Error(string memory e) {
            emit SwapBackFailed(string(abi.encodePacked("SwapBack failed with error ", e)));
        } catch {
            emit SwapBackFailed("SwapBack failed without an error message from ApeSwap");
        }
    }

 //   function swapToBusd(uint256 amount) internal returns (uint256 resultingAmt) {
   //     uint256 busdBefore = IBEP20(BUSD).balanceOf(address(this));
//
//        address[] memory busdPath = new address[](2);
  //      busdPath[0] = WBNB;
//        busdPath[1] = BUSD;

//        try router.swapExactETHForTokens{ value: amount }(
  //          0,
//            busdPath,
  //          address(this),
    //        block.timestamp
      //  ) {} catch {}

        //return IBEP20(BUSD).balanceOf(address(this)).sub(busdBefore);
//    }
    
  //  function pushFees() public {
//        FeeReceiver[] memory receivers = feeReceivers;
 //       uint _totalWeight = totalWeight;
  //      uint256 toBeDistributed = IBEP20(BUSD).balanceOf(address(this));

//        for (uint256 i = 0; i < receivers.length; i++) {
 //           FeeReceiver memory receiver = receivers[i];
  //          uint256 amt = toBeDistributed * receiver.weight / _totalWeight;
            
//            try IBEP20(BUSD).transfer(receiver.adr, amt) {
 //               emit FeesPushed(receiver.adr, amt);
  //          } catch { }
//        }
//    }

    function triggerMultipliers() external {
        authorizedFor(Permission.TriggerMultiplier);
        feeMultipliersTriggeredAt = block.timestamp;
        emit MultipliersActive(feeMultipliersDuration);
    }
    
    function clearMultipliers() external {
        authorizedFor(Permission.TriggerMultiplier);
        feeMultipliersTriggeredAt = 0;
    }

    function setMultiplierSettings(uint256 floppaNum, uint256 bingusNum, uint256 denominator, uint256 length) external {
        authorizedFor(Permission.AdjustVariables);
        require(floppaNum / denominator <= 3 && floppaNum >= denominator);
        require(bingusNum <= denominator);

        floppaNumerator = floppaNum;
        bingusNumerator = bingusNum;
        feeMultipliersDenominator = denominator;
        feeMultipliersDuration = length;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() external {
        authorizedFor(Permission.Launch);
        launchedAt = block.number;
        tradingLimited = false;
        emit Launched(block.number, block.timestamp);
    }

    function setTxLimit(uint256 amount) external {
        authorizedFor(Permission.AdjustVariables);
        require(amount >= _totalSupply / 2000);
        _maxTxAmount = amount;
    }
    
    function setIsDividendExempt(address holder, bool exempt) external {
        authorizedFor(Permission.AdjustVariables);
        require(holder != address(this) && holder != apeswapBNBPair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external {
        authorizedFor(Permission.ExcludeInclude);
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external {
        authorizedFor(Permission.ExcludeInclude);
        isTxLimitExempt[holder] = exempt;
    }

    function setIsWhitelistedForLimitedTrading(address holder, bool whitelisted) external {
        authorizedFor(Permission.ExcludeInclude);
        isWhitelistedForLimitedTrading[holder] = whitelisted;
    }

    function setIsTxHookExempt(address holder, bool exempt) external {
        authorizedFor(Permission.ExcludeInclude);
        isTxHookExempt[holder] = exempt;
    }

    function setIsBlacklisted(address holder, bool blacklisted) external {
        authorizedFor(Permission.Blacklist);
        isBlacklisted[holder] = blacklisted;
    }

    function setFees(uint256 _liquidityFee, uint256 _utilityFee,uint256 _reflectionFee, uint256 _feeDenominator, uint256 _totalSellFee) external {
        authorizedFor(Permission.AdjustVariables);

        liquidityFee = _liquidityFee;
        utilityFee = _utilityFee;
        reflectionFee = _reflectionFee;
        
        totalBuyFee = _liquidityFee.add(_utilityFee).add(_reflectionFee);
        feeDenominator = _feeDenominator;
        totalSellFee = _totalSellFee;

        require(totalBuyFee <= feeDenominator * 15 / 100, "Buy fee too high");
        require(totalSellFee <= feeDenominator * 20 / 100, "Sell fee too high");
        
        require(_liquidityFee <= feeDenominator * 4 / 100, "Liq fee too high");
        require(_utilityFee <= feeDenominator * 12 / 100, "Utility fee too high");
    }

    function setFeeReceiver(address _autoLiquidityReceiver, address _utilityFeeReceiver) external {
        authorizedFor(Permission.AdjustVariables);
        autoLiquidityReceiver = _autoLiquidityReceiver;
        utilityFeeReceiver = _utilityFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external {
        authorizedFor(Permission.AdjustVariables);
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external {
        authorizedFor(Permission.AdjustVariables);
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(apeswapBNBPair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function setApeswapBNBPair(address pair) external {
        authorizedFor(Permission.AdjustVariables);
        apeswapBNBPair = pair;
    }
    
    function setRouter(address router_) external {
        authorizedFor(Permission.AdjustVariables);
        
        _allowances[address(this)][address(router)] = 0;

        router = IDEXRouter(router_);
        _allowances[address(this)][router_] = ~uint256(0);
    }

    function addPair(address pair) external {
        authorizedFor(Permission.AdjustVariables);
        pairs.push(pair);
    }
    
    function removeLastPair() external {
        authorizedFor(Permission.AdjustVariables);
        pairs.pop();
    }
    
    function setFeesOnNormalTransfers(bool _enabled) external {
        authorizedFor(Permission.AdjustVariables);
        feesOnNormalTransfers = _enabled;
    }

    function setLaunchedAt(uint256 launched_) external {
        authorizedFor(Permission.Launch);
        launchedAt = launched_;
    }
    
    function setHighTaxBlocks(uint256 amount) external {
        authorizedFor(Permission.Launch);
        require(amount <= 10, "Number too high");
        highTaxBlocks = amount;
    }
    
    function setTradingLimited(bool limited) external {
        authorizedFor(Permission.LimitTrading);
        tradingLimited = limited;
    }
    
    function setGasPriceLimit(uint limit) external {
        authorizedFor(Permission.Launch);
        require(limit >= 10 gwei, "Limit too low");
        gasPriceLimit = limit;
    }

 //   function setFeeReceivers(address[] memory receivers, uint96[] memory weights) public {
 //       authorizedFor(Permission.AdjustVariables);
  //      require(receivers.length == weights.length, "Not the same length.");

//        delete feeReceivers; // clear the array
 //       uint256 total = 0;

//        for (uint256 i = 0; i < receivers.length; i++) {
 //           feeReceivers.push(FeeReceiver(receivers[i], weights[i]));
  //          total += weights[i];
//        }

  //      totalWeight = total;
//    }
    
    function setPushSettings(bool auto_, uint256 threshold_) external {
        authorizedFor(Permission.AdjustVariables);
        pushAutomatically = auto_;
        pushThreshold = threshold_;
    }

    function rescueStuckTokens(address tokenAdr, uint256 amount) external {
        authorizedFor(Permission.RescueTokens);
        require(IBEP20(tokenAdr).transfer(msg.sender, amount), "Transfer failed");
    }

    function rescueStuckBNB(uint256 amount) external {
        authorizedFor(Permission.RescueTokens);
        (bool success,) = payable(msg.sender).call{ value: amount }("");
        require(success, "Failed to send BNB");
    }
    
    event AutoLiquify(uint256 amountBNB, uint256 amountToken);
    event MultipliersActive(uint256 duration);
    event Launched(uint256 blockNumber, uint256 timestamp);
    event SwapBackSuccess(uint256 amount);
    event SwapBackFailed(string message);
    event FeesPushed(address recipient, uint256 amount);
}