// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ILeveling.sol";
import "./ShopItemFulfilment.sol";
import "./StarlinkComponent.sol";
import "./ILevelingRewards.sol";

contract Leveling is ILeveling, StarlinkComponent, ShopItemFulfilment {
    struct UserInfo {
        uint256 currentBaseXp;
        uint256 starlinkPoints;
        uint256 lastRebaseTime;
        uint256 allowedRestXp;
        uint256 xpBoostStartTime;
        uint256 xpBoostEndTime;
        uint256 staticXpPending;
        uint32 currentLevel;
        bytes32 name;
        uint8 activeXpBoost;
        uint8 nameChangeVouchers;
    }

    uint256 constant public INTERP_PRECISION = 100000;
    uint256 constant public STARLINK_POINTS_LIMIT = 1000000000000 * 10**9 * 10; 
    uint256 constant public STARLINK_POINTS_PRECISION = 10**9;

    mapping(address => UserInfo) public userInfo;
    uint256 public maxLevel;
    ILevelingRewards public levelingRewards;

    event LeveledUp(address indexed user, uint256 newLevel);
    event GainedXp(address user, uint256 amount, uint256 reasonId);
    event NameChanged(address indexed user, bytes32 oldName, bytes32 newName);
    event XpBoostActivated(address user, uint8 rate, uint256 duration);
    event XpBoostDeactivated(address user);
    event GainedRestXp(address user, uint256 amount);
    event SpentRestXp(address user, uint256 amount);

	constructor(IXLD xld, IStarlinkEngine engine, IShop shop) StarlinkComponent(xld, engine) ShopItemFulfilment(shop)  {
		maxLevel = 1337;
	}

    function levelUp() external notPaused notUnauthorizedContract nonReentrant process {
        doLevelUp(msg.sender);
    }

    function redeemNameChangeVoucher(bytes32 newName) external notPaused notUnauthorizedContract nonReentrant process {
        UserInfo storage user = userInfo[msg.sender];
        require(user.nameChangeVouchers > 0, "Starlink: Not enough vouchers");

        user.nameChangeVouchers--;

        emit NameChanged(msg.sender, user.name, newName);
        doChangeName(user, newName);
    }

    function grantStarlinkPoints(address userAddress, uint256 amount) external override onlyAdmins {
        require(amount > 0, "Leveling: Invalid amount");

        UserInfo storage user = userInfo[userAddress];
        rebase(user);

        user.starlinkPoints += amount;
    }

    function spendStarlinkPoints(address userAddress, uint256 amount) external override onlyAdmins {
        require(amount > 0, "Leveling: Invalid amount");
        
        UserInfo storage user = userInfo[userAddress];
        require(user.starlinkPoints >= amount, "Leveling: Excessive amount");

        rebase(user);

        user.starlinkPoints -= amount;
    }

    function levelUp(address userAddress) external override onlyAdmins() {
        doLevelUp(userAddress);
    }

    function changeName(address userAddress, bytes32 newName) external override onlyAdmins {
        UserInfo storage user = userInfo[userAddress];

        emit NameChanged(userAddress, user.name, newName);
        doChangeName(user, newName);
    }

    function setNameChangeVouchers(address userAddress, uint8 amount) external override onlyAdmins {
        UserInfo storage user = userInfo[userAddress];
        user.nameChangeVouchers = amount;
    }

    function increaseNameChangeVouchers(address userAddress, uint8 amount) external override onlyAdmins {
        UserInfo storage user = userInfo[userAddress];
        user.nameChangeVouchers += amount;
    }

    function decreaseNameChangeVouchers(address userAddress, uint8 amount) external override onlyAdmins {
        UserInfo storage user = userInfo[userAddress];
        user.nameChangeVouchers -= amount;
    }

    function grantXp(address userAddress, uint256 amount, uint256 reasonId) external override onlyAdmins {
        UserInfo storage user = userInfo[userAddress];
        rebase(user);

        user.staticXpPending += amount;
        emit GainedXp(userAddress, amount, reasonId);
    }

    function activateXpBoost(address userAddress, uint8 rate, uint256 duration) external override onlyAdmins {
        UserInfo storage user = userInfo[userAddress];
        doActivateXpBoost(user, rate, duration);

        emit XpBoostActivated(userAddress, rate, duration);
    }

    function deactivateXpBoost(address userAddress) external override onlyAdmins {
        UserInfo storage user = userInfo[userAddress];
        rebase(user);

        require(user.xpBoostEndTime > block.timestamp, "Leveling: XP boost not activated");

        user.xpBoostEndTime = block.timestamp;
        emit XpBoostDeactivated(userAddress);
    }

    function grantRestXp(address userAddress, uint256 amount) external override onlyAdmins {
        UserInfo storage user = userInfo[userAddress];
        doGrantRestXp(user, amount);

        emit GainedRestXp(userAddress, amount);
    }

    function spendRestXp(address userAddress, uint256 amount) external override onlyAdmins {
        UserInfo storage user = userInfo[userAddress];
        rebase(user);

        require(user.allowedRestXp >= amount, "Leveling: Insufficient rest XP");

        user.allowedRestXp -= amount;
        emit SpentRestXp(userAddress, amount);
    }

    function currentXpOf(address userAddress) external override view returns(uint256) {
        (uint256 xp, ) = currentXpOf(userInfo[userAddress]);
		return xp;
    }

    function levelOf(address userAddress) external override view returns(uint256) {
        UserInfo storage user = userInfo[userAddress];
        return user.currentLevel;
    }

    function nameOf(address userAddress) external view returns(bytes32) {
        UserInfo storage user = userInfo[userAddress];
        return user.name;
    }

    function timeToLevel(address userAddress, uint256 level) external view returns (uint256) {
        UserInfo storage user = userInfo[userAddress];

		uint256 xpRate = xpRateOf(user);
        if (xpRate == 0) {
            return ~uint256(0);
        }

        uint256 levelXp = xpOfLevel(level);
        (uint256 xp,) = currentXpOf(user);

        if (xp > levelXp) {
            // Is resting
            return 0;
        }
        
		return (levelXp - xp) / xpRate;
	}

    function xpRateOf(address userAddress) external view returns (uint256) {
        UserInfo storage user = userInfo[userAddress];
        return xpRateOf(user);
    }

    function levelProgressOf(address userAddress) external view returns (uint256, uint256) {
        UserInfo storage user = userInfo[userAddress];

		uint256 xpOfCurrentLevel = xpOfLevel(user.currentLevel);
		uint256 xpOfNextLevel = xpOfLevel(user.currentLevel + 1);

		uint256 xpDiffToNextLevel = xpOfNextLevel- xpOfCurrentLevel;
        (uint256 currentXp, ) = currentXpOf(user);
		
		uint256 xpProgress = min(xpDiffToNextLevel, currentXp - xpOfCurrentLevel);

		return (xpProgress, xpDiffToNextLevel);
	}

    /**
     * @notice Returns the amount of XP required for the given level
     */
    function xpOfLevel(uint256 level) public pure override returns (uint256) {
        if (level <= 19) {
            return interpolate(0, 944000 * STARLINK_POINTS_PRECISION, level * INTERP_PRECISION / 19);
        }

        return (944000 * STARLINK_POINTS_PRECISION + (level - 19) * 144000 * STARLINK_POINTS_PRECISION);
    }

    function calculateBaseXpRate(uint256 starlinkPoints) public pure returns (uint256) {
        if (starlinkPoints == 0) {
            return 0;
        }

        uint256 startingRate = getLevelUpRateFromMinutes(129600);

        uint256 lowSweetSpot = getLevelUpRateFromMinutes(5040);
        uint256 lowSweetSpotThreshold = STARLINK_POINTS_LIMIT / 100000;
        if (starlinkPoints <= lowSweetSpotThreshold)
        {
            return startingRate + interpolate(0, lowSweetSpot - startingRate, starlinkPoints * INTERP_PRECISION / lowSweetSpotThreshold);
        }

        uint256 midSweetSpot = getLevelUpRateFromMinutes(2880);
        uint256 midSweetSpotThreshold = STARLINK_POINTS_LIMIT / 10000;
        if (starlinkPoints <= midSweetSpotThreshold)
        {
            return lowSweetSpot + interpolate(0, midSweetSpot - lowSweetSpot, starlinkPoints * INTERP_PRECISION / midSweetSpotThreshold);
        }

        uint256 highSweetSpot = getLevelUpRateFromMinutes(1440);
        uint256 highSweetSpotThreshold = STARLINK_POINTS_LIMIT / 1000;
        if (starlinkPoints <= highSweetSpotThreshold)
        {
            return midSweetSpot + interpolate(0, highSweetSpot - midSweetSpot, starlinkPoints * INTERP_PRECISION / highSweetSpotThreshold);
        }

        uint256 whaleSweetSpot = getLevelUpRateFromMinutes(900);
        uint256 whaleSweetSpotThreshold = STARLINK_POINTS_LIMIT / 100;
        if (starlinkPoints <= whaleSweetSpotThreshold)
        {
            return highSweetSpot + interpolate(0, whaleSweetSpot - highSweetSpot, starlinkPoints * INTERP_PRECISION / whaleSweetSpotThreshold);
        }

        uint256 endingRate = getLevelUpRateFromMinutes(600);
        return (whaleSweetSpot + (endingRate - whaleSweetSpot) * starlinkPoints / STARLINK_POINTS_LIMIT);
    }   

    
    function setMaxLevel(uint256 level) public onlyOwner {
        maxLevel = level;
    }
    
    function starlinkPointsPrecision() external override pure returns(uint256) {
        return STARLINK_POINTS_PRECISION;
    }

    function setLevelingRewards(ILevelingRewards _levelingRewards) public onlyOwner {
        levelingRewards = _levelingRewards;
    }

    function fulfill(uint256 id, uint256, bool, address from, uint256, uint256[] calldata) external override onlyShop notPaused {
        UserInfo storage user = userInfo[from];

        (uint256 typeId, uint256 val1, uint256 val2, uint256 req1,) = shop.itemInfo(id);
        require(user.currentLevel >= req1, "Leveling: Level requirement");

        if (typeId == 0) {
            doActivateXpBoost(user, uint8(val1), val2);
            emit XpBoostActivated(from, uint8(val1), val2);
        } else if (typeId == 1) {
            doGrantRestXp(user, val1);
            emit GainedRestXp(from, val1);
        } else if (typeId == 2) {
            user.nameChangeVouchers += uint8(val1);
        } else {
            revert("Starlink: Invalid type");
        }
    }

    function doLevelUp(address userAddress) private {
        UserInfo storage user = userInfo[userAddress];
        rebase(user);

        require(user.currentLevel < maxLevel, "Leveling: Maximum level reached");

        uint256 nextLevelXp = xpOfLevel(user.currentLevel + 1);
        (uint256 currentXp, ) = currentXpOf(user);

        require(currentXp >= nextLevelXp, "Leveling: Not enough XP for level-up");

        user.currentLevel++;
        emit LeveledUp(userAddress, user.currentLevel);

        if (address(levelingRewards) != address(0) && levelingRewards.unclaimedRewards(userAddress, user.currentLevel) > 0) {
            levelingRewards.claimRewards(userAddress, user.currentLevel);
        }
    }

    function doActivateXpBoost(UserInfo storage user, uint8 rate, uint256 duration) private {
        rebase(user);

        require(user.activeXpBoost == 0 || user.xpBoostEndTime < block.timestamp, "Leveling: Only 1 XP boost can be active at a time");

        user.activeXpBoost = rate;
        user.xpBoostStartTime = block.timestamp;
        user.xpBoostEndTime = block.timestamp + duration;
    }

    
    function doGrantRestXp(UserInfo storage user, uint256 amount) private {
        rebase(user);

        user.allowedRestXp += amount;
    }
    

    function doChangeName(UserInfo storage user, bytes32 newName) private {
        user.name = newName;
    }

    /**
     * @notice Rebase's user's XP. Rebasing means calculating all earned XP since last rebase and applying it to the user's base XP.
     * This also consumes any rest XP used.
     */
    function rebase(UserInfo storage user) private {
        if (user.lastRebaseTime == 0) {
            //First rebase
            user.lastRebaseTime = block.timestamp;
        }

        (uint256 xp, uint256 usedRest) = currentXpOf(user);
        user.currentBaseXp = xp;
        user.allowedRestXp -= usedRest;
        user.staticXpPending = 0;
        user.lastRebaseTime = block.timestamp;
    }


    /**
     * @notice Returns the amount of XP earned since the last rebase. This does NOT take into account level-cap or amount of rest XP.
     */
    function calculateXpSinceLastRebase(UserInfo storage user) private view returns (uint256) {
        uint256 lastXpRebaseTime = user.lastRebaseTime;
        if (lastXpRebaseTime == 0) {
            return 0;
        }

        // Get number of seconds since the last rebase
        uint256 rebaseDuration = block.timestamp - lastXpRebaseTime;
        uint256 xpRate = calculateBaseXpRate(user.starlinkPoints);

        // We know that if there is a boost, it starts/overlaps with lastXpRebaseTime (Since we rebase before boost activation) 
        if (user.activeXpBoost > 0 && user.xpBoostEndTime > lastXpRebaseTime) {
            uint256 boostRate = xpRate * user.activeXpBoost / 100;

            if (user.xpBoostEndTime > block.timestamp) {
                // Boosted for whole duration of rebase
                return boostRate * rebaseDuration + user.staticXpPending;
            }

            uint256 boostPeriod = user.xpBoostEndTime - lastXpRebaseTime;
            uint256 nonBoostPeriod = block.timestamp - user.xpBoostEndTime;

            return xpRate * nonBoostPeriod + boostRate * boostPeriod + user.staticXpPending;
        }

        return xpRate * rebaseDuration + user.staticXpPending;
    }

    function xpRateOf(UserInfo storage user) private view returns(uint256) {
        uint256 baseRate = calculateBaseXpRate(user.starlinkPoints);
        uint256 rate = baseRate;

        uint256 boostEndDate = user.xpBoostEndTime;
		if (boostEndDate > block.timestamp) {
			uint256 xpBoost = user.activeXpBoost;
			rate += baseRate * xpBoost / 100;
		} 

        return rate;
    }

    /**
     * @notice Returns the current EXP of the given user and the amount of used rest EXP
     */
    function currentXpOf(UserInfo storage user) private view returns (uint256, uint256) {
        uint256 xp = user.currentBaseXp + calculateXpSinceLastRebase(user);
        uint256 nextLevelXp = xpOfLevel(user.currentLevel + 1);

        uint256 restXpUsed = 0;
        if (xp > nextLevelXp) {
            uint256 xpWithRest = min(xp, nextLevelXp + user.allowedRestXp);
            restXpUsed = xpWithRest - nextLevelXp;
            xp = xpWithRest;
        }

        return (xp, restXpUsed);
    }
   
    /**
     * @notice Returns the xp rate required to gain a 20+ level within the given amount of minutes
     */
    function getLevelUpRateFromMinutes(uint256 mins) private pure returns (uint256) {
        return 144000 * STARLINK_POINTS_PRECISION / (mins * 60);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
		if (a < b) {
			return a;
		}

		return b;
	}

    /**
     * @notice Performs exponential interpolation. t is a number between 0 and INTERP_PRECISION
     */
	function interpolate(uint256 from, uint256 to, uint256 t) private pure returns (uint256) {
		return from + (to - from) * t**2 / INTERP_PRECISION**2;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ILeveling {

    function grantStarlinkPoints(address userAddress, uint256 amount) external;

    function spendStarlinkPoints(address userAddress, uint256 amount) external;

    function levelUp(address userAddress) external;

    function changeName(address userAddress, bytes32 newName) external;

    function grantXp(address userAddress, uint256 amount, uint256 reasonId) external;
    
    function activateXpBoost(address userAddress, uint8 rate, uint256 duration) external;

    function deactivateXpBoost(address userAddress) external;

    function grantRestXp(address userAddress, uint256 amount) external;

    function spendRestXp(address userAddress, uint256 amount) external;

    function currentXpOf(address userAddress) external view returns(uint256); 

    function xpOfLevel(uint256 level) external pure returns (uint256);

    function levelOf(address userAddress) external view returns(uint256);

    function starlinkPointsPrecision() external pure returns(uint256);

    function setNameChangeVouchers(address userAddress, uint8 amount) external;

    function increaseNameChangeVouchers(address userAddress, uint8 amount) external;

    function decreaseNameChangeVouchers(address userAddress, uint8 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IShopItemFulfilment.sol";
import "./IShop.sol";
import "./base/access/AccessControlled.sol";

abstract contract ShopItemFulfilment is IShopItemFulfilment, AccessControlled {
    IShop public shop;

    constructor(IShop _shop) {
        setShop(_shop);
    }

    modifier onlyShop() {
        require(msg.sender == address(shop), "ShopItemFulfilment: Only shop can call this");
        _;
    }

    function setShop(IShop _shop) public onlyOwner {
         require(address(_shop) != address(0), "ShopItemFulfilment: Invalid address");
         shop = _shop;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./base/token/BEP20/IXLD.sol";
import "./IStarlink.sol";
import "./IStarlinkEngine.sol";
import "./base/access/AccessControlled.sol";
import "./base/token/BEP20/EmergencyWithdrawable.sol";

contract StarlinkComponent is AccessControlled, EmergencyWithdrawable {
    IXLD public xld;
    IStarlinkEngine public engine;
    uint256 processGas = 500000;

    modifier process() {
        if (processGas > 0) {
            engine.addGas(processGas);
        }
        
        _;
    }

    constructor(IXLD _xld, IStarlinkEngine _engine) {
        require(address(_xld) != address(0), "StarlinkComponent: Invalid address");
       
        xld = _xld;
        setEngine(_engine);
    }

    function setProcessGas(uint256 gas) external onlyOwner {
        processGas = gas;
    }

    function setEngine(IStarlinkEngine _engine) public onlyOwner {
        require(address(_engine) != address(0), "StarlinkComponent: Invalid address");

        engine = _engine;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ILevelingRewards {
    function claimRewards(uint256 level) external;

    function claimRewards(address user, uint256 level) external;

    function unclaimedRewards(address user, uint256 level) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IShopItemFulfilment {
    function fulfill(uint256 id, uint256 price, bool xldPayment, address from, uint256 quantity, uint256[] calldata params) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


interface IShop {
    function addItem(uint8 typeId, uint256 val1, uint256 val2, uint112 req1, uint112 req2, uint256 price, uint8 discountRate, bool allowXldPayment, bool allowBnbPayment, bool bulkAllowed, address fulfilment, address fundsReceiver) external;

    function editItem(uint256 id, uint8 typeId, uint256 val1, uint256 val2, uint112 req1, uint112 req2, uint256 price, uint8 discountRate, bool allowXldPayment, bool allowBnbPayment, bool bulkAllowed) external;

    function setFulfilmentSystem(uint256 id, address fulfilment) external;

    function setFundsReceiver(uint256 id, address receiver) external;

    function itemInfo(uint256 id) external view returns(uint256, uint256, uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

/**
 * @dev Contract module that helps prevent calls to a function.
 */
abstract contract AccessControlled {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    address private _owner;
    bool private _isPaused;
    mapping(address => bool) private _admins;
    mapping(address => bool) private _authorizedContracts;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _status = _NOT_ENTERED;
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

        setAdmin(_owner, true);
        setAdmin(address(this), true);
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "AccessControlled: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "AccessControlled: contract not allowed");
        require(msg.sender == tx.origin, "AccessControlled: proxy contract not allowed");
        _;
    }

    modifier notUnauthorizedContract() {
        if (!_authorizedContracts[msg.sender]) {
            require(!_isContract(msg.sender), "AccessControlled: contract not allowed");
            require(msg.sender == tx.origin, "AccessControlled: proxy contract not allowed");
        }
        _;
    }

    modifier isNotUnauthorizedContract(address addr) {
        if (!_authorizedContracts[addr]) {
            require(!_isContract(addr), "AccessControlled: contract not allowed");
        }
        
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "AccessControlled: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by a non-admin account
     */
    modifier onlyAdmins() {
        require(_admins[msg.sender], "AccessControlled: caller does not have permission");
        _;
    }

    modifier notPaused() {
        require(!_isPaused, "AccessControlled: paused");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function setAdmin(address addr, bool _isAdmin) public onlyOwner {
        _admins[addr] = _isAdmin;
    }

    function isAdmin(address addr) public view returns(bool) {
        return _admins[addr];
    }

    function setAuthorizedContract(address addr, bool isAuthorized) public onlyOwner {
        _authorizedContracts[addr] = isAuthorized;
    }

    function pause() public onlyOwner {
        _isPaused = true;
    }

    function unpause() public onlyOwner {
        _isPaused = false;
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IBEP20.sol";

interface IXLD is IBEP20 {
   	function processRewardClaimQueue(uint256 gas) external;

    function calculateRewardCycleExtension(uint256 balance, uint256 amount) external view returns (uint256);

    function claimReward() external;

    function claimReward(address addr) external;

    function isRewardReady(address user) external view returns (bool);

    function isExcludedFromFees(address addr) external view returns(bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function rewardClaimQueueIndex() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IStarlink {
   	function processFunds(uint256 gas) external;

	function xldAddress() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IStarlinkEngine {
    function addGas(uint256 amount) external;

    function donate() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../../../base/access/AccessControlled.sol";
import "./IBEP20.sol";

abstract contract EmergencyWithdrawable is AccessControlled {
    /**
     * @notice Withdraw unexpected tokens sent to the contract
     */
    function withdrawStuckTokens(address token) external onlyOwner {
        uint256 amount = IBEP20(token).balanceOf(address(this));
        IBEP20(token).transfer(msg.sender, amount);
    }
    
    /**
     * @notice Withdraws funds of the contract - only for emergencies
     */
    function emergencyWithdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

