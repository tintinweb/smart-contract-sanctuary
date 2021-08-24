/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 *                                                                                 
 *     ,((*******(((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
 *     ,************((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
 *    (|**************(|((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
 *    |*****************,(((|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||(((||(||||((|
 *    |*******************,*,||(||||||||||||||||||||||||||||||||||||||||||||||||||||((|*(|*****(((((
 *    |**********||*********,.||||||((((|,,,,,,,,,,,,,,,,,,,,*******************|||(,,**********((  
 *    (|**********|||*********..,|,,,,,,,,,*#%&&&&&&&&&%(,,,,,,,,,,,,,,,,,,,,,,|.,,*************((  
 *    ((*******|################(,.#%&&&&&&&&&&&&&&&&&&&&&&&&&&&&#,,,,,,**|*...,***************(((((
 *     ,#****#%%#####################%%%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&|....,#*****************(((((
 *     *#***#(##(######################%%%%%%&&&&&&&&&&&&&&&&&&&&&%||....,.(********|*****|***((((((
 *     *##***(,###|(####################%%%%%%%%&%,(%%%||&&&&%*%###((((,.%*******||||**|*****(|(((((
 *       |#**(,(,####((##################%%%%%%%%#%%%%###%,,%,######((######(***||||||||****|(((((((
 *       ((****,||#*,####((#########((((#########%...........#*##((((############||||||****||(((((((
 *       (((***,*(||||#(,*#####################%&#.............*###((################||***|(((((((((
 *         (****##(|||||||||#%#*,*|#%%%%%%%%|,,#.................#,###(################**|((((((((((
 *       ,,,(****|||||||||||||||****.........,,.....................%*%##((#############|%#(((((((((
 *       ,,,(*****,#||||||||||||#,.....*(|,,.,,,,,,..................,,,#*|%#%%%########%*,((#######
 *     .,,,#&#****%|||||||||#*..,&&&&&&&&&&&&&.&,,.,..................,,,,,,,#(,,|#%%%(|%,,,,#######
 *     .,,,&&&&#****#*|||#...%#&*&&&&&&&&&&&&&&..&,,|................*,,,&&&&&&****|((#&&&,,,#######
 *     .,,&&&&&&&&&#,|*(...|.&&&&&&&&&&&&&&&&&&(..&,,..................%&&&&&&*%**(||&&&&&*,,*,#####
 *    **,*&&&&&&&&&&%|%.....*%###########&&&&&&....(,.................(&&&&&&&(,%|%%&&&&&&&****#####
 *    ***|&&&&&&&&&&&*,.......&%##%#%%%%##%&&&.....|..................&%%#%##%.|(%&&&&&&&&&****#####
 *    ***|&&&&&&&&&&&&#,,,........&#######%,......,%&,...............#%%%%%##,*,&&&&&&&&&&&****%%%%%
 *    ****&&&&&&&&&&&&&***,,,,..............................................,,,,*&&&&&&&&&&****%%%%%
 *     .**&&&&&&&&&&&&&#%*****,,,,.......................................,,,,,,,,&&&&&&&&&|****%%%%%
 *     .**|&&&&&&&&&&&&&##|*******,,,,,,...................,*****||**,,...,|****#&&&&&&&&&***%%%%%%%
 *     .***&&&&&&&&&&&&&&#,,************,((.................%#*********,..,,*||%&&&&&&&&&****%%%%%%%
 *       ***&&&&&&&&&&&&&(.,,,,,**********(...................,#****%#,******(&&&&&&&&&&(****%%%%%%%
 *       ****&&&&&&&&&&#......,,,,,,,******#,,...........,,,,,,,|************(&&&&&&&&&(***%%%%%%%%%
 *         ***&&&&&&&(........,,,,,,,,,*****(,,,,,,,,,,,,,,******************&&&&&&&&&*****%%%%%%%%%
 *         *****&&&(.............,,,,,,,,,****#****************#%**********%&&&&&&&&&****%%%%%%%%%%%
 *           ****,...................,,,,,,,*****|%#*****(%********|%((%&&&&&&&&&&&****(%%%%%%%%%%%%
 *             ****,...................,,,,,,,******|||||(((((((((%&&&&&&&&&&&&&&*****%%%%%%%%%%%%%%
 *              |***** .................,,,,,,,,,,************||||&&&&&&&&&&&&#*|***%%%%%%%%%%%%%%%%
 *                  ****|...................,,,,,,,,,,,,,,,,,,,,,,(&&&&&&&&%*|||%%%%%%%%%%%%%%%%%%%%
 *                    **||||*..................,,,,,,,,,,,,,,,,,,,,%&&&@|||||||%%%%%%%%%%%%%%%%%%%%%
 *                         ||||||................,,,,,,,,,,,,,,,,,,||||||######%%%%%%%%%%%%%%%%%%%%%
 *                             |||||||**,...........,,,,,,,*|||||||||||(((((((((((((((((((((((((((((
 *                                ||||||||||||||||||||||||||||||||,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
 *
 *          _______   __                                                 ______       ______  
 *         /       \ /  |                                               /      \     /      \ 
 *         $$$$$$$  |$$/  _______    ______   __    __   _______       /$$$$$$  |   /$$$$$$  |
 *         $$ |__$$ |/  |/       \  /      \ /  |  /  | /       |      $$ ___$$ |   $$$  \$$ |
 *         $$    $$< $$ |$$$$$$$  |/$$$$$$  |$$ |  $$ |/$$$$$$$/         /   $$<    $$$$  $$ |
 *         $$$$$$$  |$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$      \        _$$$$$  |   $$ $$ $$ |
 *         $$ |__$$ |$$ |$$ |  $$ |$$ \__$$ |$$ \__$$ | $$$$$$  |      /  \__$$ |__ $$ \$$$$ |
 *         $$    $$/ $$ |$$ |  $$ |$$    $$ |$$    $$/ /     $$/       $$    $$//  |$$   $$$/ 
 *         $$$$$$$/  $$/ $$/   $$/  $$$$$$$ | $$$$$$/  $$$$$$$/         $$$$$$/ $$/  $$$$$$/  
 *                                 /  \__$$ |                                                 
 *                                 $$    $$/                                                  
 *                                 $$$$$$/                     
 * 
 *  https://bingus.io/
 *  https://t.me/bingustoken2officialnew
 */

// import "hardhat/console.sol";

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
    TriggerMultiplier,
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
        permissionNameToIndex["TriggerMultiplier"] = uint256(Permission.TriggerMultiplier);
        permissionNameToIndex["AdjustVariables"] = uint256(Permission.AdjustVariables);
        permissionNameToIndex["Authorize"] = uint256(Permission.Authorize);
        permissionNameToIndex["Unauthorize"] = uint256(Permission.Unauthorize);
        permissionNameToIndex["PauseUnpauseContract"] = uint256(Permission.PauseUnpauseContract);
        permissionNameToIndex["BypassPause"] = uint256(Permission.BypassPause);
        permissionNameToIndex["LockPermissions"] = uint256(Permission.LockPermissions);
        permissionNameToIndex["ExcludeInclude"] = uint256(Permission.ExcludeInclude);
        permissionNameToIndex["RescueTokens"] = uint256(Permission.RescueTokens);

        permissionIndexToName[uint256(Permission.ChangeFees)] = "ChangeFees";
        permissionIndexToName[uint256(Permission.TriggerMultiplier)] = "TriggerMultiplier";
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

contract BingusNetwork is IBEP20, Auth {
    using SafeMath for uint256;

    struct FeeReceiver {
        address adr;
        uint96 weight;
    }

    address BUSD = 0xbcca17a1e79Cb6Fcf2A5B7433e6fBCb7408Ca535;
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
    mapping (address => bool) public isTxHookExempt;
    mapping (address => bool) public isWhitelistedForLimitedTrading;

    uint256 liquidityFee = 300;
    uint256 utilityFee = 500;

    uint256 totalBuyFee = 800;
    uint256 totalSellFee = 800;
    uint256 feeDenominator = 10000;

    FeeReceiver[] public feeReceivers;
    uint256 totalWeight;
    bool pushAutomatically = true;
    uint256 pushThreshold = 1 * 10 ** 14; // 200 BUSD //debug

    address public autoLiquidityReceiver;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address pancakeV2BNBPair;
    address[] public pairs;

    uint256 public launchedAt;

    uint256 floppaNumerator = 200;
    uint256 bingusNumerator = 50;
    uint256 feeMultipliersDenominator = 100;
    uint256 feeMultipliersTriggeredAt;
    uint256 feeMultipliersDuration = 30 minutes;

    bool public feesOnNormalTransfers = false;

    bool tradingLimited = true;

    uint public gasPriceLimit = 20 gwei;
    uint highTaxBlocks = 2;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 5000; // 0.02%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        pancakeV2BNBPair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);

        pairs.push(pancakeV2BNBPair);

        address owner_ = msg.sender;

        isFeeExempt[owner_] = true;
        isTxLimitExempt[owner_] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true;
        isWhitelistedForLimitedTrading[owner_] = true;
        isWhitelistedForLimitedTrading[address(this)] = true;

        autoLiquidityReceiver = owner_;

        address[] memory r = new address[](1);
        r[0] = owner_;

        uint96[] memory a = new uint96[](1);
        a[0] = uint96(100);

        setFeeReceivers(r, a);

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

        bool skipTxHook = isTxHookExempt[sender] || isTxHookExempt[recipient];

        if (inSwap) { return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, recipient, amount);
        checkGasPriceLimit();

        if (!skipTxHook && shouldSwapBack()) { swapBack(); }

        uint256 senderBal = _balances[sender];
        uint256 recipientBal = _balances[recipient];

        if (!launched() && recipient == pancakeV2BNBPair) { require(senderBal > 0); launch(); }

        _balances[sender] = senderBal.sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = recipientBal.add(amountReceived);

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
        // console.log("checkGasPriceLimit: tx.gasprice=", tx.gasprice);
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
        return selling ? totalSellFee : totalBuyFee;
    }

    function getFloppaFee() public view returns (uint256) {
        uint256 totalFee = totalSellFee;
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
            uint256 amountBNBToBUSD = amountBNB.sub(amountBNBLiquidity);

            swapToBusd(amountBNBToBUSD);

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

        try router.swapExactETHForTokens{ value: amount }(
            0,
            busdPath,
            address(this),
            block.timestamp
        ) {} catch {}

        return IBEP20(BUSD).balanceOf(address(this)).sub(busdBefore);
    }
    
    function pushFees() public {
        FeeReceiver[] memory receivers = feeReceivers;
        uint _totalWeight = totalWeight;
        uint256 toBeDistributed = IBEP20(BUSD).balanceOf(address(this));

        for (uint256 i = 0; i < receivers.length; i++) {
            FeeReceiver memory receiver = receivers[i];
            uint256 amt = toBeDistributed * receiver.weight / _totalWeight;
            
            try IBEP20(BUSD).transfer(receiver.adr, amt) {
                emit FeesPushed(receiver.adr, amt);
            } catch { }
        }
    }

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

    function launch() internal {
        launchedAt = block.number;
        emit Launched(block.number, block.timestamp);
    }

    function setTxLimit(uint256 amount) external {
        authorizedFor(Permission.AdjustVariables);
        require(amount >= _totalSupply / 2000);
        _maxTxAmount = amount;
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

    function setFees(uint256 _liquidityFee, uint256 _utilityFee, uint256 _feeDenominator, uint256 _totalSellFee) external {
        authorizedFor(Permission.AdjustVariables);

        liquidityFee = _liquidityFee;
        utilityFee = _utilityFee;

        totalBuyFee = _liquidityFee.add(_utilityFee);
        feeDenominator = _feeDenominator;
        totalSellFee = _totalSellFee;

        require(totalBuyFee <= feeDenominator * 15 / 100, "Buy fee too high");
        require(totalSellFee <= feeDenominator * 15 / 100, "Sell fee too high");
        
        require(_liquidityFee <= feeDenominator * 4 / 100, "Liq fee too high");
        require(_utilityFee <= feeDenominator * 12 / 100, "Utility fee too high");
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
    
    function setHighTaxBlocks(uint256 amount) external {
        authorizedFor(Permission.AdjustVariables);
        highTaxBlocks = amount;
    }
    
    function setTradingLimited(bool limited) external {
        authorizedFor(Permission.AdjustVariables);
        tradingLimited = limited;
    }

    function setFeeReceivers(address[] memory receivers, uint96[] memory weights) public {
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

    function rescueStuckBNB(uint256 amount) external {
        authorizedFor(Permission.RescueTokens);
        (bool success,) = payable(msg.sender).call{ value: amount }("");
        require(success, "Failed to send BNB");
    }
    
    event AutoLiquify(uint256 amountBNB, uint256 amountToken);
    event MultipliersActive(uint256 duration);
    event BoughtBack(uint256 amount, address to);
    event Launched(uint256 blockNumber, uint256 timestamp);
    event SwapBackSuccess(uint256 amount);
    event SwapBackFailed(string message);
    event FeesPushed(address recipient, uint256 amount);
}