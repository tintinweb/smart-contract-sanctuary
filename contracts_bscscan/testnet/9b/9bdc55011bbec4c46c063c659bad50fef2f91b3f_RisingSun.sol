/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**

 * `````````.```````...`````....````....`````..........`````....````....`````....`````.....````````.
 * ```````...``````...```````..````...````.....-:/+/:-....````...````....`````....````......````````
 * ``````...``````....``````..````...````..-+syyyysyyyso/...````..````...`````....`````.....````````
 * `````....``````...``````...```...```...+yyyyys:.+syyyys:...``...````...`````...`````......```````
 * `````....``````...``````..````..```..`+yyyys/``.`.oyyyys-..```...```...`````....````......```````
 * `````....``````...`````...````..```...yyyy+.`:-.--`:syyy/...``...```....````....``````....```````
 * `````....``````...`````...````..```..`sys:`-:.```-:../sy:...``...```...`````....``````....```````
 * ```````..``````...`````...````...```..:ss+o+///////so+s+...```...```...`````....`````.....```````
 * ```````..``````....`````...````..```...-oyyyyyyyyyyyys/...```...```....`````...``````.....```````
 * ```````..``````....`````...````...````...:+ossyyyso+:....```...``.-:-.`````....``````....````````
 * ````````..``````....`````...``````..````.....-----.....````...`+so//oo:://///-``````.....```````.
 * ````````..```````....`````....`````...```````.....``````....```:-...`.--....-:`````.....````````.
 * :////:-:++-......`.....````....``````.....``````````......````../..`````....``````..../h-``````..
 * mmNNmmmmmmmmmmmmmddhysosyysyysyhddddyo+/-.............`````-/+sydhs/-.--:/+++///:::::+yhyyyhddddm
 * NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmmmdhhhhhysoooo+oshmNNNNNNNNNNmmmNNNNNNmmmmmmmmNNNNNNNNNNN
 * NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
 *
 *                        .---.  _        _              .--.             
 *                        : .; ::_;      :_;            : .--'            
 *                        :   .'.-. .--. .-.,-.,-. .--. `. `. .-..-.,-.,-.
 *                        : :.`.: :`._-.': :: ,. :' .; : _`, :: :; :: ,. :
 *                        :_;:_;:_;`.__.':_;:_;:_;`._. ;`.__.'`.__.':_;:_;
 *                                                 .-. :                  
 *                                                 `._.'                  
 * 
 *  https://risingsun.finance/
 *  https://t.me/risingsun_token
 */

// import "hardhat/console.sol";

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
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

enum Permission {
    ChangeFees,
    Buyback,
    AdjustContractVariables,
    Authorize,
    Unauthorize,
    PauseUnpauseContract,
    BypassPause,
    LockPermissions,
    ExcludeInclude,
    Blacklist
}

/**
 * Allows for contract ownership along with multi-address authorization for different permissions
 */
abstract contract RSunAuth {
    struct PermissionLock {
        bool isLocked;
        uint64 expiryTime;
    }

    address public owner;
    mapping(address => mapping(uint => bool)) private authorizations; // uint is permission index
    
    uint constant NUM_PERMISSIONS = 10; // always has to be adjusted when Permission element is added or removed
    mapping(string => uint) permissionNameToIndex;
    mapping(uint => string) permissionIndexToName;

    mapping(uint => PermissionLock) lockedPermissions;

    constructor(address owner_) {
        owner = owner_;
        for (uint i; i < NUM_PERMISSIONS; i++) {
            authorizations[owner_][i] = true;
        }

        permissionNameToIndex["ChangeFees"] = uint(Permission.ChangeFees);
        permissionNameToIndex["Buyback"] = uint(Permission.Buyback);
        permissionNameToIndex["AdjustContractVariables"] = uint(Permission.AdjustContractVariables);
        permissionNameToIndex["Authorize"] = uint(Permission.Authorize);
        permissionNameToIndex["Unauthorize"] = uint(Permission.Unauthorize);
        permissionNameToIndex["PauseUnpauseContract"] = uint(Permission.PauseUnpauseContract);
        permissionNameToIndex["BypassPause"] = uint(Permission.BypassPause);
        permissionNameToIndex["LockPermissions"] = uint(Permission.LockPermissions);
        permissionNameToIndex["ExcludeInclude"] = uint(Permission.ExcludeInclude);
        permissionNameToIndex["Blacklist"] = uint(Permission.Blacklist);

        permissionIndexToName[uint(Permission.ChangeFees)] = "ChangeFees";
        permissionIndexToName[uint(Permission.Buyback)] = "Buyback";
        permissionIndexToName[uint(Permission.AdjustContractVariables)] = "AdjustContractVariables";
        permissionIndexToName[uint(Permission.Authorize)] = "Authorize";
        permissionIndexToName[uint(Permission.Unauthorize)] = "Unauthorize";
        permissionIndexToName[uint(Permission.PauseUnpauseContract)] = "PauseUnpauseContract";
        permissionIndexToName[uint(Permission.BypassPause)] = "BypassPause";
        permissionIndexToName[uint(Permission.LockPermissions)] = "LockPermissions";
        permissionIndexToName[uint(Permission.ExcludeInclude)] = "ExcludeInclude";
        permissionIndexToName[uint(Permission.Blacklist)] = "Blacklist";
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownership required."); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorizedFor(Permission permission) {
        require(!lockedPermissions[uint(permission)].isLocked, "Permission is locked.");
        require(isAuthorizedFor(msg.sender, permission), string(abi.encodePacked("Not authorized. You need the permission ", permissionIndexToName[uint(permission)]))); _;
    }

    /**
     * Authorize address for one permission
     */
    function authorizeFor(address adr, string memory permissionName) public authorizedFor(Permission.Authorize) {
        uint permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = true;
        emit AuthorizedFor(adr, permissionName, permIndex);
    }

    /**
     * Authorize address for multiple permissions
     */
    function authorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public authorizedFor(Permission.Authorize) {
        for (uint i; i < permissionNames.length; i++) {
            uint permIndex = permissionNameToIndex[permissionNames[i]];
            authorizations[adr][permIndex] = true;
            emit AuthorizedFor(adr, permissionNames[i], permIndex);
        }
    }

    /**
     * Remove address' authorization
     */
    function unauthorizeFor(address adr, string memory permissionName) public authorizedFor(Permission.Unauthorize) {
        require(adr != owner, "Can't unauthorize owner");

        uint permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = false;
        emit UnauthorizedFor(adr, permissionName, permIndex);
    }

    /**
     * Unauthorize address for multiple permissions
     */
    function unauthorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public authorizedFor(Permission.Unauthorize) {
        require(adr != owner, "Can't unauthorize owner");

        for (uint i; i < permissionNames.length; i++) {
            uint permIndex = permissionNameToIndex[permissionNames[i]];
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
        return authorizations[adr][uint(permission)];
    }

    /**
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public onlyOwner {
        address oldOwner = owner;
        owner = adr;
        for (uint i; i < NUM_PERMISSIONS; i++) {
            authorizations[oldOwner][i] = false;
            authorizations[owner][i] = true;
        }
        emit OwnershipTransferred(oldOwner, owner);
    }

    /**
     * Get the index of the permission by its name
     */
    function getPermissionNameToIndex(string memory permissionName) public view returns (uint) {
        return permissionNameToIndex[permissionName];
    }
    
    /**
     * Get the time the timelock expires
     */
    function getPermissionUnlockTime(string memory permissionName) public view returns (uint) {
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
    function lockPermission(string memory permissionName, uint64 time) public virtual authorizedFor(Permission.LockPermissions) {
        uint permIndex = permissionNameToIndex[permissionName];
        uint64 expiryTime = uint64(block.timestamp) + time;
        lockedPermissions[permIndex] = PermissionLock(true, expiryTime);
        emit PermissionLocked(permissionName, permIndex, expiryTime);
    }
    
    /*
     * Unlocks the permission if the lock has expired 
     */
    function unlockPermission(string memory permissionName) public virtual {
        require(block.timestamp > getPermissionUnlockTime(permissionName) , "Permission is locked until the expiry time.");
        uint permIndex = permissionNameToIndex[permissionName];
        lockedPermissions[permIndex].isLocked = false;
        emit PermissionUnlocked(permissionName, permIndex);
    }

    event PermissionLocked(string permissionName, uint permissionIndex, uint64 expiryTime);
    event PermissionUnlocked(string permissionName, uint permissionIndex);
    event OwnershipTransferred(address from, address to);
    event AuthorizedFor(address adr, string permissionName, uint permissionIndex);
    event UnauthorizedFor(address adr, string permissionName, uint permissionIndex);
}


/**
 * Pause and unpause certain functions using modifiers.
 */
abstract contract RSunPausable is RSunAuth {
    bool public paused;

    constructor (bool _paused) { paused = _paused; }

    modifier whenPaused() {
        require(paused || isAuthorizedFor(msg.sender, Permission.BypassPause), "!PAUSED"); _;
    }

    modifier notPaused() {
        require(!paused || isAuthorizedFor(msg.sender, Permission.BypassPause), "PAUSED"); _;
    }

    function pause() external notPaused authorizedFor(Permission.PauseUnpauseContract) {
        paused = true;
        emit Paused();
    }

    function unpause() public whenPaused authorizedFor(Permission.PauseUnpauseContract) {
        _unpause();
    }

    function _unpause() internal {
        paused = false;
        emit Unpaused();
    }

    event Paused();
    event Unpaused();
}

abstract contract DividendDistributor {

    address constant WBNB_ADR = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address constant BUSD_ADR = 0xbcca17a1e79Cb6Fcf2A5B7433e6fBCb7408Ca535;
    IBEP20 busd = IBEP20(BUSD_ADR);
    IDEXRouter router;

    struct Share {
        uint amount;
        uint104 totalExcluded;
        uint104 totalRealised;
        uint48 lastClaim;
    }

    address[] shareholders;
    mapping (address => uint) shareholderIndexes;

    mapping (address => Share) public shares;

    uint public totalShares;
    uint public totalDividends;
    uint public totalDistributed;
    uint public dividendsPerShare;
    uint public dividendsPerShareAccuracyFactor = 10 ** 20;

    uint public minPeriod = 1 minutes;
    uint public minDistribution = 1 * (10 ** 18) / 100000; // 0.00001 busd min reflect

    uint public currentIndex;

    constructor () {
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    }

    function _setDistributionCriteria(uint _minPeriod, uint _minDistribution) internal {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint amount) internal {
        uint shareholderAmount = shares[shareholder].amount; // gas savings
        // console.log("setShare: shareholder =", shareholder);
        // console.log("setShare: amount =", amount);
        // console.log("setShare: shareholderAmount =", shareholderAmount);

        if (shareholderAmount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shareholderAmount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shareholderAmount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares - shareholderAmount + amount;
        shares[shareholder].amount = uint104(amount);
        shares[shareholder].totalExcluded = uint104(getCumulativeDividends(amount));

        // console.log("setShare: totalShares =", totalShares);
        // console.log("setShare: shares[shareholder].amount =", shares[shareholder].amount);
        // console.log("setShare: shares[shareholder].totalExcluded =", shares[shareholder].totalExcluded);
    }

    function deposit(uint bnbAmount) internal returns (bool) {
        uint balanceBefore = busd.balanceOf(address(this));

        // console.log("deposit: bnbAmount =", bnbAmount);
        // console.log("deposit: balanceBefore =", balanceBefore);

        address[] memory path = new address[](2);
        path[0] = WBNB_ADR;
        path[1] = BUSD_ADR;

        try router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: bnbAmount }(
            0,
            path,
            address(this),
            block.timestamp
        ) {
            uint amount = busd.balanceOf(address(this)) - balanceBefore;

            totalDividends += amount;
            dividendsPerShare = dividendsPerShare + (dividendsPerShareAccuracyFactor * amount / totalShares);

            // console.log("deposit: amount =", amount);
            // console.log("deposit: totalDividends =", totalDividends);
            // console.log("deposit: dividendsPerShare =", dividendsPerShare);
            return true;
        } catch {
            // console.log("deposit: swapExactETHForTokensSupportingFeeOnTransferTokens failed");
            return false;
        }
    }

    function process(uint gas) internal {
        uint shareholderCount = shareholders.length;

        // console.log("process: gas =", gas);
        // console.log("process: shareholderCount =", shareholderCount);

        if (shareholderCount == 0) { return; }

        uint gasUsed = 0;
        uint gasLeft = gasleft();

        // console.log("process: gasLeft =", gasLeft);

        uint iterations = 0;
        uint currIndex = currentIndex; // gas savings

        while (gasUsed < gas && iterations < shareholderCount) {
            // console.log("process: in loop: iterations =", iterations);
            // console.log("process: in loop: currIndex =", currIndex);
            // console.log("process: in loop: gasUsed =", gasUsed);
            // console.log("process: in loop: gasLeft =", gasLeft);

            if (currIndex >= shareholderCount) {
                currIndex = 0;
            }

            address currentShareholder = shareholders[currIndex];
            // console.log("process: in loop: currentShareholder =", currentShareholder);
            // console.log("process: in loop: shouldDistribute(currentShareholder) =", shouldDistribute(currentShareholder));

            if (shouldDistribute(currentShareholder)) {
                distributeDividend(currentShareholder);
            }

            gasUsed = gasUsed + gasLeft - gasleft();
            gasLeft = gasleft();
            currIndex++;
            iterations++;
        }

        currentIndex = currIndex;
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shares[shareholder].lastClaim + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal returns (bool success) {
        uint shareholderAmount = shares[shareholder].amount;

        // console.log("distributeDividend: shareholder =", shareholder);
        // console.log("distributeDividend: shareholderAmount =", shareholderAmount);
        if (shareholderAmount == 0) { return true; }

        uint amount = getUnpaidEarnings(shareholder);

        // console.log("distributeDividend: amount =", amount);
        // console.log("distributeDividend: busd.balanceOf(address(this)) =", busd.balanceOf(address(this)));
        
        if (amount > 0 && busd.balanceOf(address(this)) >= amount) {
            try busd.transfer(shareholder, amount) {
                totalDistributed += amount;
                shares[shareholder].lastClaim = uint48(block.timestamp);
                shares[shareholder].totalRealised += uint104(amount);
                shares[shareholder].totalExcluded = uint104(getCumulativeDividends(shareholderAmount));

                // console.log("distributeDividend: shares[shareholder].lastClaim =", shares[shareholder].lastClaim);
                // console.log("distributeDividend: shares[shareholder].totalRealised =", shares[shareholder].totalRealised);
                // console.log("distributeDividend: shares[shareholder].totalExcluded =", shares[shareholder].totalExcluded);

                return true;
            } catch {
                // console.log("distributeDividend: busd.transfer failed");

                return false;
            }
        }

        return true;
    }
    
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint) {
        uint shareholderAmount = shares[shareholder].amount;
        if (shareholderAmount == 0) { return 0; }

        uint shareholderTotalDividends = getCumulativeDividends(shareholderAmount);
        uint shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) { return 0; }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(uint share) internal view returns (uint) {
        return share * dividendsPerShare / dividendsPerShareAccuracyFactor;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        address lastShareholder = shareholders[shareholders.length - 1];
        uint indexShareholder = shareholderIndexes[shareholder];

        shareholders[indexShareholder] = lastShareholder;
        shareholderIndexes[lastShareholder] = indexShareholder;
        shareholders.pop();
    }
}

contract RisingSun is IBEP20, RSunAuth, RSunPausable, DividendDistributor {
    // SafeMath is not necessary since solidity >=0.8.0 checks for overflows/underflows automatically

    address constant DEAD_ADR = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO_ADR = 0x0000000000000000000000000000000000000000;
    uint UINT_MAX = ~uint(0);

    string constant _name = "RisingSun";
    string constant _symbol = "RSUN";
    uint8 constant _decimals = 9;

    uint _totalSupply = 1 * 10 ** 10 * (10 ** _decimals); // 10 billion supply
    uint public _maxTxAmount = _totalSupply / 100; // 1% // debug

    mapping (address => uint) _balances;
    mapping (address => mapping (address => uint)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public isBlacklisted;

    uint liquidityPortion = 150;
    uint buybackPortion = 300;
    uint reflectionPortion = 200;
    uint marketingPortion = 150;
    uint feePortionDenominator = 800;

    uint totalBuyFee = 800;
    uint totalSellFee = 1600;
    uint feeDenominator = 10000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    uint targetLiquidity = 20;
    uint targetLiquidityDenominator = 100;

    address public pancakeV2BnbPair;
    address[] public pairs;

    uint public launchedAt;

    uint buybackMultiplierNumerator = 200;
    uint buybackMultiplierDenominator = 100;
    uint buybackMultiplierTriggeredAt;
    uint buybackMultiplierLength = 30 minutes;

    DividendDistributor distributor;
    uint distributorGas = 500000;

    bool public swapBackEnabled = true;
    uint public swapThreshold = _totalSupply / 50000; // 0.002% // debug
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    bool public feesOnNormalTransfers = false;

    constructor (
        // address _presaler,
        // address _presaleContract
    ) RSunAuth(msg.sender) RSunPausable(false) DividendDistributor() {
        pancakeV2BnbPair = IDEXFactory(router.factory()).createPair(WBNB_ADR, address(this));
        _allowances[address(this)][address(router)] = UINT_MAX;

        pairs.push(pancakeV2BnbPair);

        address _presaler = msg.sender;

        isFeeExempt[_presaler] = true;
        isTxLimitExempt[_presaler] = true;
        // isFeeExempt[_presaleContract] = true;
        // isTxLimitExempt[_presaleContract] = true;
        // isDividendExempt[_presaleContract] = true;
        isDividendExempt[pancakeV2BnbPair] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD_ADR] = true;

        autoLiquidityReceiver = _presaler;
        marketingFeeReceiver = _presaler;

        _balances[_presaler] = _totalSupply;
        emit Transfer(address(0), _presaler, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint) { return _allowances[holder][spender]; }

    function approve(address spender, uint amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, UINT_MAX);
    }

    function transfer(address recipient, uint amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {

        uint senderAllowance = _allowances[sender][msg.sender];
        // console.log("transferFrom: senderAllowance =", senderAllowance);
        require(senderAllowance >= amount, "Insufficient allowance");
        
        if (senderAllowance != UINT_MAX) {
            _allowances[sender][msg.sender] = senderAllowance - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint amount) internal notPaused returns (bool) {
        // console.log("_transferFrom: sender =", sender);
        // console.log("_transferFrom: recipient =", recipient);
        // console.log("_transferFrom: amount =", amount);

        uint senderBalance = _balances[sender];
        uint recipientBalance = _balances[recipient];

        require(senderBalance >= amount, "Insufficient Balance");
        require(!isBlacklisted[sender], "Address is blacklisted");

        // console.log("_transferFrom: senderBalance =", senderBalance);
        // console.log("_transferFrom: recipientBalance =", recipientBalance);
        // console.log("_transferFrom: inSwap =", inSwap);

        if (inSwap) { return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, amount);

        // console.log("_transferFrom: shouldSwapBack() =", shouldSwapBack());

        if (shouldSwapBack()) { swapBack(); }

        // console.log("_transferFrom: launched() =", launched());

        if (!launched() && recipient == pancakeV2BnbPair) { require(senderBalance > 0); launch(); }

        // console.log("_transferFrom: launchedAt =", launchedAt);

        _balances[sender] = senderBalance - amount;

        // console.log("_transferFrom: _balances[sender] =", senderBalance - amount);

        // console.log("_transferFrom: shouldTakeFee(sender, recipient) =", shouldTakeFee(sender, recipient));
        // console.log("_transferFrom: takeFee(sender, recipient, amount) =", takeFee(sender, recipient, amount));

        uint amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = recipientBalance + amountReceived;

        // console.log("_transferFrom: _balances[recipient] =", recipientBalance + amountReceived);
        // console.log("_transferFrom: isDividendExempt[sender] =", isDividendExempt[sender]);
        // console.log("_transferFrom: isDividendExempt[recipient] =", isDividendExempt[recipient]);

        if (!isDividendExempt[sender]) { setShare(sender, senderBalance - amount); }
        if (!isDividendExempt[recipient]) { setShare(recipient, recipientBalance + amountReceived); }

        // console.log("_transferFrom: setShares passed");

        process(distributorGas);

        // console.log("_transferFrom: process passed");

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint amount) internal returns (bool) {
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Insufficient Balance");
        
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if (isFeeExempt[sender] || isFeeExempt[recipient] || !launched()) return false;

        address[] memory liqPairs = pairs;

        for (uint i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i] || recipient == liqPairs[i]) return true;
        }

        return false;
    }

    function takeFee(address sender, address recipient, uint amount) internal returns (uint) {
        uint feeAmount = amount * getTotalFee(isSell(recipient)) / feeDenominator;

        // console.log("takeFee: feeAmount =", amount * getTotalFee(isSell(recipient)) / feeDenominator);

        _balances[address(this)] += feeAmount;
        
        emit Transfer(sender, address(this), feeAmount);
        return amount - feeAmount;
    }
    
    function isSell(address recipient) internal view returns (bool) {
        address[] memory liqPairs = pairs;
        for (uint i = 0; i < liqPairs.length; i++) {
            if (recipient == liqPairs[i]) return true;
        }
        return false;
    }

    function getTotalFee(bool selling) public view returns (uint) {
        if (launchedAt + 1 >= block.number) { return feeDenominator - 1; }
        if (selling) {
            uint bbMultiplierTriggeredAt = buybackMultiplierTriggeredAt; // gas savings
            uint bbMultiplierLength = buybackMultiplierLength;
            
            if (bbMultiplierTriggeredAt + bbMultiplierLength > block.timestamp) { return getMultipliedFee(bbMultiplierTriggeredAt, bbMultiplierLength); }
        }
        return selling ? totalSellFee : totalBuyFee;
    }

    function getMultipliedFee(uint bbMultiplierTriggeredAt, uint bbMultiplierLength) public view returns (uint) {
        uint totalFee = totalSellFee;
        uint remainingTime = bbMultiplierTriggeredAt + bbMultiplierLength - block.timestamp;
        uint feeIncrease = (totalFee * buybackMultiplierNumerator / buybackMultiplierDenominator) - totalFee;
        return totalFee + (feeIncrease * remainingTime / bbMultiplierLength);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pancakeV2BnbPair
            && !inSwap
            && swapBackEnabled
            && _balances[address(this)] >= swapThreshold
            && launched();
    }

    function swapBack() internal swapping {
        uint denominator = feePortionDenominator;

        uint dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityPortion;
        uint tokenAmountToLiq = swapThreshold * dynamicLiquidityFee / denominator / 2;
        uint amountToSwap = swapThreshold - tokenAmountToLiq;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB_ADR;

        uint balanceBefore = address(this).balance;

        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        ) {
            uint amountBNB = address(this).balance - balanceBefore;

            uint totalBNBFee = denominator - dynamicLiquidityFee / 2;

            uint amountBNBLiquidity = amountBNB * dynamicLiquidityFee / totalBNBFee / 2;
            uint amountBNBReflection = amountBNB * reflectionPortion / totalBNBFee;
            uint amountBNBMarketing = amountBNB * marketingPortion / totalBNBFee;

            deposit(amountBNBReflection);
            payable(marketingFeeReceiver).call{ value: amountBNBMarketing }("");

            if (tokenAmountToLiq > 0) {
                try router.addLiquidityETH{ value: amountBNBLiquidity }(
                    address(this),
                    tokenAmountToLiq,
                    0,
                    0,
                    autoLiquidityReceiver,
                    block.timestamp
                ) {
                    emit AutoLiquify(tokenAmountToLiq, amountBNBLiquidity);
                } catch {
                    emit AutoLiquify(0, 0);
                }
            }

            emit SwapBackSuccess(amountToSwap);
        } catch Error(string memory e) {
            emit SwapBackFailed(string(abi.encodePacked("SwapBack failed with error ", e)));
        } catch {
            emit SwapBackFailed("SwapBack failed without an error message from pancakeSwap");
        }
        
    }

    function triggerBuyback(uint amount, bool triggerBuybackMultiplier) external authorizedFor(Permission.Buyback) notPaused {
        buyTokens(amount, DEAD_ADR);
        if (triggerBuybackMultiplier) {
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }

    function clearBuybackMultiplier() external authorizedFor(Permission.AdjustContractVariables) {
        buybackMultiplierTriggeredAt = 0;
    }

    function buyTokens(uint amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB_ADR;
        path[1] = address(this);

        try router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amount }(
            0,
            path,
            to,
            block.timestamp
        ) {
            emit BoughtBack(amount, to);
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("Buyback failed with error ", reason)));
        } catch {
            revert("Buyback failed without an error message from pancakeSwap");
        }
    }

    function setBuybackMultiplierSettings(uint numerator, uint denominator, uint length) external authorizedFor(Permission.AdjustContractVariables) {
        require(numerator / denominator <= 3 && numerator > denominator);
        buybackMultiplierNumerator = numerator;
        buybackMultiplierDenominator = denominator;
        buybackMultiplierLength = length;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
        emit Launched(block.number, block.timestamp);
    }

    function setTxLimit(uint amount) external authorizedFor(Permission.AdjustContractVariables) {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorizedFor(Permission.ExcludeInclude) {
        require(holder != address(this) && holder != pancakeV2BnbPair);
        isDividendExempt[holder] = exempt;
        
        if (exempt) {
            setShare(holder, 0);
        } else {
            setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorizedFor(Permission.ExcludeInclude) {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorizedFor(Permission.ExcludeInclude) {
        isTxLimitExempt[holder] = exempt;
    }

    function setPortions(uint _liquidityPortion, uint _buybackPortion, uint _reflectionPortion, uint _marketingPortion, uint _feePortionDenominator) external authorizedFor(Permission.ChangeFees) {
        liquidityPortion = _liquidityPortion;
        buybackPortion = _buybackPortion;
        reflectionPortion = _reflectionPortion;
        marketingPortion = _marketingPortion;

        feePortionDenominator = _feePortionDenominator;
    }

    function setFees(uint _buyFee, uint _sellFee) external authorizedFor(Permission.ChangeFees) {
        require(_buyFee < feeDenominator / 10, "Buy fee can at most be 10%");
        require(_sellFee < feeDenominator / 5, "Unmultiplied sell fee can at most be 20%");

        totalBuyFee = _buyFee;
        totalSellFee = _sellFee;
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorizedFor(Permission.AdjustContractVariables) {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint _amount) external authorizedFor(Permission.AdjustContractVariables) {
        swapBackEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setFeesOnNormalTransfers(bool _enabled) external authorizedFor(Permission.AdjustContractVariables) {
        feesOnNormalTransfers = _enabled;
    }

    function setTargetLiquidity(uint _target, uint _denominator) external authorizedFor(Permission.AdjustContractVariables) {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint _minPeriod, uint _minDistribution) external authorizedFor(Permission.AdjustContractVariables) {
        _setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint gas) external authorizedFor(Permission.AdjustContractVariables) {
        require(gas <= 1500000);
        distributorGas = gas;
    }

    function addPair(address pair) external authorizedFor(Permission.AdjustContractVariables) {
        pairs.push(pair);
    }
    
    function removeLastPair() external authorizedFor(Permission.AdjustContractVariables) {
        pairs.pop();
    }
    
    function setIsBlacklisted(address adr, bool blacklisted) external authorizedFor(Permission.Blacklist) {
        isBlacklisted[adr] = blacklisted;
    }

    function getCirculatingSupply() public view returns (uint) {
        return _totalSupply - balanceOf(DEAD_ADR) - balanceOf(ZERO_ADR);
    }

    function getLiquidityBacking(uint accuracy) public view returns (uint) {
        return accuracy * balanceOf(pancakeV2BnbPair) * 2 / getCirculatingSupply();
    }

    function isOverLiquified(uint target, uint accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint tokenAmount, uint bnbAmount);
    event BuybackMultiplierActive(uint duration);
    event BoughtBack(uint amount, address to);
    event Launched(uint blockNumber, uint timestamp);
    event SwapBackSuccess(uint amount);
    event SwapBackFailed(string message);
}