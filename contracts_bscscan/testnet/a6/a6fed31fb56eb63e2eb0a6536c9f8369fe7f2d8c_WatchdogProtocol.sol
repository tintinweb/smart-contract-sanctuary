/**
 *Submitted for verification at BscScan.com on 2021-08-15
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 *      MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0OxdddxkOKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 *      MMMMMMMMMMMMMMMMMMMMMMMMMMWNX0Oxdoccc:::::cccloxkOKXNWMMMMMMMMMMMMMMMMMMMMMMMMMM
 *      MMMMMMMMMMMMMMMMMMMMWNX0Oxdocc::::::::::::::::::::cloxk0KXWWMMMMMMMMMMMMMMMMMMMM
 *      MMMMMMMMMMMMMMWNX0Oxdocc::::::::::::::::::::::::::::::::cloxk0KNWWMMMMMMMMMMMMMM
 *      MMMMMMMMWNX0Oxdocc::::::::::::::::::::::::::::::::::::::::::::cloxk0KNWWMMMMMMMM
 *      MMMWXKOkdoc:::::::::::::::::::::::::::::::::::::::::::::::::::::::::cloxk0KNWMMM
 *      MW0oc:::::::::::::::::::::::::::::::::::::::::::::::::::::::;:::::::::::::clkNMM
 *      MNx:;;;;;;;;;;;;codo:;::;;;::;;;;;;;;;;;;;;;;;;;;::;;;;;;;:ldxl:;;;;;;;;:;;;l0MM
 *      MNd;;;;;;;;;;;;:xNWNOc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:dKWWKl;;;;;;;;;;;;c0MM
 *      MNd;;;;;;;;;;;;:kWMMWKo:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ckNMMMXo;;;;;;;;;;;;c0MM
 *      MNd;;;;;;;;;;;;:kWMMMMXxc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:oKWMMMMXo;;;;;;;;;;;;c0MM
 *      MNd;;;;;;;;;;;;:kWMMWWMWOl;;;;;;;;;;;;;;;;;;;;;;;;;;;:xXMMWWMMXo;;;;;;;;;;;;c0MM
 *      MNd;;;;;;;;;;;;:kWMNOONMWKd:;;;;;;;;;,,;;;;;;;;;;;;;lOWMWKxKMMXo;;;;;;;;;;;;c0MM
 *      MNd;;;;;;;;;;;,:kWMNx:dXWMNkc;;coddddddddddddddl:,;dKWMNOcc0MMXo,;;;;;,,;;,,c0MM
 *      MNd;,,,,,,,,,,,;kWMNx;;l0WMW0l;l0WMMMMMMMMMMMWXx::kNMMXx:,c0MMXo,,,,,,,,,,,,:0MM
 *      MNd,,,,,,,,,,,,;kWMNx;,,:xXMMXx:cxkkkkkkkkkkkko:l0WMW0l;,,:0MMXl,,,,,,,,,,,,:OMM
 *      MNo,,,,,,,,,,,,;kWMNx,,::;oKWMWOc,,,,,,,,,,,,,;dXMMNk::c;,:0MMXl,,,,,,,,,,,,:OMM
 *      MNo,,,,,,,,,,,,;kWMNd,:OKx:ckNMWKo;,,,,,,,,,,cONMWKo:l0Kd;:OWMKl,,,,,,,,,,,,:OMM
 *      MNo,,,,,,,,,,,,;kWWk::kWMNd,;dXWMNx:,,,,',,,oKWMWOc,:OWMXo;lKWKl,,,,,,,,,,,,:OMM
 *      MNo,,,,,,,,,,,';xNk::kWMWO:,',cOWMW0l,,',,:xNMMXx;,',oXMMXo,lKKl',,,,,,,,,,':OMM
 *      MNo,''''''''''',dk:;kWMWO:''''';xXMMXd;,,cOWMW0l,'''',oXMMXo,lkl'''''''''''':OMM
 *      MNo'''''''''''',:;;xNMWO:''''''',l0WMNOxOXMMNk:''''''',oXMMKl,;;'''''''''''';OMM
 *      MNo'''''''''''''';xNMW0:'''''''''':kNMMMMMWKo;''''''''',oXMMKl'''''''''''''';OMM
 *      MNo''''''''''''',dNMW0:'''''''''''',lk0KK0x:'''''''''''',oXMWKc''''''''''''';OMM
 *      MNo'''''''''''''oXMMKc'''''''''''''''',,,,''''''''''''''',dNMWO:'''''''''''';OMM
 *      MNo'''''''''''''oXMMXd,''''''''''''.''''''.''''''''''''''cOWMWO;'''''''''''.;OMM
 *      MWd'..''........,lKWMWOc'.''''''''...''..'......'..''..;dXMMXx;''...'''.....:KMM
 *      MWO;.............';xNMMXd;...........................'cOWMWOc'.............'oNMM
 *      MMXo'..............'c0WMW0c'........................;xXMWXd,...............;OWMM
 *      MMMKc................,dXMMXx;.....................'l0WMNO:'...............,xNMMM
 *      MMMW0c................':ONMW0l'..................;kNMWKo'................,xNMMMM
 *      MMMMMXo,................,oKWMNk;...............'oKWMNk;.................:OWMMMMM
 *      MMMMMMWOc'................;kNMWKl'............:kNMW0l'................;dXWMMMMMM
 *      MMMMMMMMNOl,...............'l0WMNOc,........;dXMMXx,...............':xKWMMMMMMMM
 *      MMMMMMMMMMW0d:'..............,xXMMNKOkkkkkk0XWMWOc...............,lOXWMMMMMMMMMM
 *      MMMMMMMMMMMMMN0d:'.............:x0NWMMMMMMMWWKkl'.............;lkXWMMMMMMMMMMMMM
 *      MMMMMMMMMMMMMMMMNKxl;............';clloolllc:,............,:dOXWMMMMMMMMMMMMMMMM
 *      MMMMMMMMMMMMMMMMMMMWXOdc,.............................':okKWMMMMMMMMMMMMMMMMMMMM
 *      MMMMMMMMMMMMMMMMMMMMMMMWXko:'......................,cx0NMMMMMMMMMMMMMMMMMMMMMMMM
 *      MMMMMMMMMMMMMMMMMMMMMMMMMMMN0xc,...............':oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMM
 *      MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdlc;,,,,,;:cokKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 *      MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXKKKKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * 
 *     _    _       _       _         _              ______          _                  _ 
 *    | |  | |     | |     | |       | |             | ___ \        | |                | |
 *    | |  | | __ _| |_ ___| |__   __| | ___   __ _  | |_/ / __ ___ | |_ ___   ___ ___ | |
 *    | |/\| |/ _` | __/ __| '_ \ / _` |/ _ \ / _` | |  __/ '__/ _ \| __/ _ \ / __/ _ \| |
 *    \  /\  / (_| | || (__| | | | (_| | (_) | (_| | | |  | | | (_) | || (_) | (_| (_) | |
 *     \/  \/ \__,_|\__\___|_| |_|\__,_|\___/ \__, | \_|  |_|  \___/ \__\___/ \___\___/|_|
 *                                             __/ |                                      
 *                                            |___/                                       
 * 
 *  https://watchdog.finance/
 *  https://t.me/MoonRetriever
 */


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
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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

    PauseUnpauseContract,
    BypassPause,

    AdjustVariables,
    ChangeFees,
    ExcludeInclude,
    Buyback,
    RescueTokens
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

        permissionNameToIndex["ChangeFees"] = uint256(Permission.ChangeFees);
        permissionNameToIndex["Buyback"] = uint256(Permission.Buyback);
        permissionNameToIndex["AdjustVariables"] = uint256(Permission.AdjustVariables);
        permissionNameToIndex["Authorize"] = uint256(Permission.Authorize);
        permissionNameToIndex["Unauthorize"] = uint256(Permission.Unauthorize);
        permissionNameToIndex["PauseUnpauseContract"] = uint256(Permission.PauseUnpauseContract);
        permissionNameToIndex["BypassPause"] = uint256(Permission.BypassPause);
        permissionNameToIndex["LockPermissions"] = uint256(Permission.LockPermissions);
        permissionNameToIndex["ExcludeInclude"] = uint256(Permission.ExcludeInclude);
        permissionNameToIndex["RescueTokens"] = uint256(Permission.RescueTokens);

        permissionIndexToName[uint256(Permission.ChangeFees)] = "ChangeFees";
        permissionIndexToName[uint256(Permission.Buyback)] = "Buyback";
        permissionIndexToName[uint256(Permission.AdjustVariables)] = "AdjustVariables";
        permissionIndexToName[uint256(Permission.Authorize)] = "Authorize";
        permissionIndexToName[uint256(Permission.Unauthorize)] = "Unauthorize";
        permissionIndexToName[uint256(Permission.PauseUnpauseContract)] = "PauseUnpauseContract";
        permissionIndexToName[uint256(Permission.BypassPause)] = "BypassPause";
        permissionIndexToName[uint256(Permission.LockPermissions)] = "LockPermissions";
        permissionIndexToName[uint256(Permission.ExcludeInclude)] = "ExcludeInclude";
        permissionIndexToName[uint256(Permission.RescueTokens)] = "RescueTokens";
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
    function setDistributionSettings(uint256 _minPeriod, uint256 _minDistribution, uint256 maxGas, uint256 _maxIterations) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit(uint256 amount) external;
    function process() external;
    function claimDividend() external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    using SafeMath for uint104;

    address _token;

    struct Share {
        uint256 amount;

        // gas optimization. safe for the entire range of realistic numbers (up to billions of dollars distributed)
        uint104 totalExcluded;
        uint104 totalRealised;
        uint48 lastClaim;
    }

    IBEP20 BUSD = IBEP20(0xbcca17a1e79Cb6Fcf2A5B7433e6fBCb7408Ca535);
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

    uint256 public minPeriod = 1 hours; // min 1 hour delay
    uint256 public minDistribution = 1 * (10 ** 18); // 1 BUSD minimum auto send

    uint256 public maxGas = 500000;
    uint256 public maxIterations = 200; // to control how much gas is spent on just checking for distributions

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
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        _token = msg.sender;
    }

    function setDistributionSettings(uint256 _minPeriod, uint256 _minDistribution, uint256 _maxGas, uint256 _maxIterations) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        maxGas = _maxGas;
        maxIterations = _maxIterations;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        Share memory share = shares[shareholder];

        if (share.amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && share.amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && share.amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(share.amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = uint104(getCumulativeDividends(amount));
    }

    function deposit(uint256 amount) external override onlyToken {
        try BUSD.transferFrom(msg.sender, address(this), amount) { } catch {
            return;
        }

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process() external override onlyToken {
        address[] memory holders = shareholders;
        uint256 shareholderCount = holders.length;

        if (shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 index = currentIndex;
        uint256 gas = maxGas;

        while (gasUsed < gas && iterations < maxIterations && iterations < shareholderCount) {
            if (index >= shareholderCount) {
                index = 0;
            }

            // not updating the local holders variable is fine since it can never do more than a full loop
            if (shouldDistribute(holders[index])) {
                distributeDividend(holders[index]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            index++;
            iterations++;
        }

        currentIndex = index;
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shares[shareholder].lastClaim + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        Share memory share = shares[shareholder];
        if (share.amount == 0) { return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            try BUSD.transfer(shareholder, amount) {
                shares[shareholder].totalRealised = uint104(share.totalRealised.add(amount));
                shares[shareholder].totalExcluded = uint104(getCumulativeDividends(share.amount));
                shares[shareholder].lastClaim = uint48(block.timestamp);
            } catch { }
        }
    }
    
    function claimDividend() external override {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        Share memory share = shares[shareholder];
        if (share.amount == 0) { return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(share.amount);
        uint256 shareholderTotalExcluded = share.totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) { return 0; }

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

contract WatchdogProtocol is IBEP20, Auth {
    using SafeMath for uint256;

    struct FeeReceiver {
        address adr;
        uint96 weight;
    }

    address BUSD = 0xbcca17a1e79Cb6Fcf2A5B7433e6fBCb7408Ca535;
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Watchdog Protocol";
    string constant _symbol = "WATCHDOG";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 10 * 10 ** 6 * (10 ** _decimals); // 10 million
    uint256 public _maxTxAmount = _totalSupply / 1000; // 0.1%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isTxHookExempt;

    uint256 liquidityFee = 200;
    uint256 buybackFee = 150;
    uint256 reflectionFee = 200;
    uint256 utilityFee = 150;

    uint256 totalBuyFee = 700;
    uint256 totalSellFee = 1400;
    uint256 feeDenominator = 10000;

    FeeReceiver[] feeReceivers;
    uint256 totalWeight;
    bool pushAutomatically = true;
    uint256 pushThreshold = 1 * 10 ** 14; // 200 BUSD

    address public autoLiquidityReceiver;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address pancakeV2BNBPair;
    address[] public pairs;

    uint256 public launchedAt;

    uint256 buybackMultiplierNumerator = 150;
    uint256 buybackMultiplierDenominator = 100;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;

    bool public feesOnNormalTransfers = false;

    DividendDistributor distributor;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 5000; // 0.02%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        pancakeV2BNBPair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);

        pairs.push(pancakeV2BNBPair);
        distributor = new DividendDistributor();

        IBEP20(BUSD).approve(address(distributor), ~uint256(0));

        address owner_ = msg.sender;

        isFeeExempt[owner_] = true;
        isTxLimitExempt[owner_] = true;
        isDividendExempt[pancakeV2BNBPair] = true;
        isDividendExempt[address(this)] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = owner_;

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

        bool skipTxHook = isTxHookExempt[sender] || isTxHookExempt[recipient];

        if (inSwap) { return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, amount);

        if (!skipTxHook && shouldSwapBack()) { swapBack(); }

        uint256 senderBal = _balances[sender];
        uint256 recipientBal = _balances[recipient];

        if (!launched() && recipient == pancakeV2BNBPair) { require(senderBal > 0); launch(); }

        _balances[sender] = senderBal.sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = recipientBal.add(amountReceived);

        if (!isDividendExempt[sender]) { try distributor.setShare(sender, senderBal.sub(amount)) {} catch {} }
        if (!isDividendExempt[recipient]) { try distributor.setShare(recipient, recipientBal.add(amountReceived)) {} catch {} }

        if (!skipTxHook) {
            try distributor.process() {} catch {}
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if (isFeeExempt[sender] || isFeeExempt[recipient] || !launched()) return false;

        address[] memory liqPairs = pairs;

        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i] || recipient == liqPairs[i]) return true;
        }

        return feesOnNormalTransfers;
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if (launchedAt + 1 >= block.number) { return feeDenominator.sub(1); }
        if (selling && buybackMultiplierTriggeredAt.add(buybackMultiplierLength) > block.timestamp) { return getMultipliedFee(); }
        return selling ? totalSellFee : totalBuyFee;
    }

    function getMultipliedFee() public view returns (uint256) {
        uint256 totalFee = totalSellFee;
        uint256 remainingTime = buybackMultiplierTriggeredAt.add(buybackMultiplierLength).sub(block.timestamp);
        uint256 feeIncrease = totalFee.mul(buybackMultiplierNumerator).div(buybackMultiplierDenominator).sub(totalFee);
        return totalFee.add(feeIncrease.mul(remainingTime).div(buybackMultiplierLength));
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
        return msg.sender != pancakeV2BNBPair
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
            uint256 amountBNBBuyback = amountBNB.mul(buybackFee).div(totalBNBFee);
            uint256 amountBNBToBUSD = amountBNB.sub(amountBNBLiquidity).sub(amountBNBBuyback);

            uint256 busdDiff = swapToBusd(amountBNBToBUSD);

            uint256 totalFeeBUSD = utilityFee.add(reflectionFee);
            uint256 busdToDistributor = busdDiff.mul(reflectionFee).div(totalFeeBUSD);

            try distributor.deposit(busdToDistributor) {} catch {}

            if (pushAutomatically && IBEP20(BUSD).balanceOf(address(this)) >= pushThreshold) {
                pushFees();
            }

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
            emit SwapBackFailed("SwapBack failed without an error message from pancakeSwap");
        }
    }

    function swapToBusd(uint256 amount) internal returns (uint256 resultingAmt) {
        uint256 busdBefore = IBEP20(BUSD).balanceOf(address(this));

        address[] memory busdPath = new address[](2);
        busdPath[0] = WBNB;
        busdPath[1] = BUSD;

        router.swapExactETHForTokens{ value: amount }(
            0,
            busdPath,
            address(this),
            block.timestamp
        );

        return IBEP20(BUSD).balanceOf(address(this)).sub(busdBefore);
    }
    
    function pushFees() public {
        uint256 toBeDistributed = IBEP20(BUSD).balanceOf(address(this));

        for (uint256 i = 0; i < feeReceivers.length; i++) {
            uint256 amt = toBeDistributed * feeReceivers[i].weight / totalWeight;
            
            try IBEP20(BUSD).transfer(feeReceivers[i].adr, amt) {
                emit FeesPushed(feeReceivers[i].adr, amt);
            } catch {
            }
        }
    }

    function triggerBuyback(uint256 amount, bool triggerBuybackMultiplier) external {
        authorizedFor(Permission.Buyback);

        buyTokens(amount, DEAD);

        if (triggerBuybackMultiplier) {
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }
    
    function clearBuybackMultiplier() external {
        authorizedFor(Permission.Buyback);
        buybackMultiplierTriggeredAt = 0;
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
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

    function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external {
        authorizedFor(Permission.AdjustVariables);
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

    function setTxLimit(uint256 amount) external {
        authorizedFor(Permission.AdjustVariables);
        require(amount >= _totalSupply / 2000);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external {
        authorizedFor(Permission.ExcludeInclude);
        require(holder != address(this) && holder != pancakeV2BNBPair);
        
        isDividendExempt[holder] = exempt;

        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
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

    function setIsTxHookExempt(address holder, bool exempt) external {
        authorizedFor(Permission.ExcludeInclude);
        isTxHookExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _utilityFee, uint256 _feeDenominator, uint256 _totalSellFee) external {
        authorizedFor(Permission.AdjustVariables);

        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        utilityFee = _utilityFee;

        totalBuyFee = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_utilityFee);
        feeDenominator = _feeDenominator;
        totalSellFee = _totalSellFee;

        require(totalBuyFee <= feeDenominator / 10, "Buy fee too high");
        require(totalSellFee <= feeDenominator / 5, "Sell fee too high");
        
        require(_liquidityFee <= feeDenominator * 3 / 100, "Liq fee too high");
        require(_buybackFee <= feeDenominator * 3 / 100, "Buyback fee too high");
        require(_reflectionFee <= feeDenominator * 4 / 100, "Reflection fee too high");
        require(_utilityFee <= feeDenominator / 25, "Utility fee too high");
    }

    function setAutoLiqReceiver(address _autoLiquidityReceiver) external {
        authorizedFor(Permission.AdjustVariables);
        autoLiquidityReceiver = _autoLiquidityReceiver;
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

    function setDistributionSettings(uint256 _minPeriod, uint256 _minDistribution, uint256 _maxGas, uint256 _maxIterations) external {
        authorizedFor(Permission.AdjustVariables);
        
        require(_maxGas <= 1500000);
        distributor.setDistributionSettings(_minPeriod, _minDistribution, _maxGas, _maxIterations);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pancakeV2BNBPair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
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
        authorizedFor(Permission.AdjustVariables);
        launchedAt = launched_;
    }

    function setFeeReceivers(address[] calldata receivers, uint96[] memory weights) external {
        authorizedFor(Permission.AdjustVariables);
        require(receivers.length == weights.length, "Not the same length.");

        delete feeReceivers; // clear the array
        uint256 total = 0;

        for (uint256 i = 0; i < receivers.length; i++) {
            feeReceivers.push(FeeReceiver(receivers[i], weights[i]));
            total += weights[i];
        }

        totalWeight = total;
    }
    
    function setPushSettings(bool auto_, uint256 threshold_) external {
        authorizedFor(Permission.AdjustVariables);
        pushAutomatically = auto_;
        pushThreshold = threshold_;
    }

    function rescueStuckTokens(address tokenAdr, uint256 amount) external {
        authorizedFor(Permission.RescueTokens);
        require(IBEP20(tokenAdr).transfer(msg.sender, amount), "Transfer failed");
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountToken);
    event BuybackMultiplierActive(uint256 duration);
    event BoughtBack(uint256 amount, address to);
    event Launched(uint256 blockNumber, uint256 timestamp);
    event SwapBackSuccess(uint256 amount);
    event SwapBackFailed(string message);
    event FeesPushed(address recipient, uint256 amount);
}