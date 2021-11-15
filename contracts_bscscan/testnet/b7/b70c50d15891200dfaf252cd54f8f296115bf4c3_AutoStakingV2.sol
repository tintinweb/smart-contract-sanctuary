// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/IStaking.sol";
import "./Interfaces/IAutoStaking.sol";
import "./MinterV2.sol";

//import "hardhat/console.sol"; //TODO: REMOVE

contract AutoStakingV2 is IAutoStaking, OwnableUpgradeable {
    IERC20 public token;
    IStaking public staking;
    MinterV2 public minter;
    address treasury;

    mapping(address => UserInfo) public userInfo;

    uint256 public totalShares;
    uint256 public lastHarvestedTime;

    event Deposit(address indexed sender, uint256 amount, uint256 shares, uint256 lastDepositedTime);
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);
    event Harvest(address indexed sender, uint256 performanceFee, uint256 callFee);

    uint256 public performanceFee;
    uint256 public callFee;
    uint256 public withdrawFee;
    uint256 public withdrawFeePeriod;

    function getUserInfo(address _user) external view override returns (UserInfo memory) {
        return userInfo[_user];
    }

    function getRewardPerClaim(uint256 _bn) external view override returns(uint256){
        return calculateHarvestTokenRewards(_bn);
    }

    function getStatus(address _user, uint256 _bn) external view override returns (Status memory) {
        (uint256 rpb,) = minter.farm(address(staking));
        revert("1");
        uint256 accMult = minter.accMultiplierForStakings();
        if (accMult != 0)
            rpb = rpb * minter.X() / accMult;

        revert("2");
        uint256 stakingDeposit = staking.getAccDeposit();
        if (stakingDeposit != 0)
            rpb = rpb * availableWithStaking() / stakingDeposit;

        revert("2");
        Status memory status = Status(
            address(token),
            rpb,
            userInfo[_user].shares * getPricePerFullShare(_bn),// / 1e18,
            userInfo[_user].tokensAtLastUserAction,
            performanceFee,
            callFee,
            withdrawFee,
            withdrawFeePeriod,
            calculateHarvestTokenRewards(_bn),
            userInfo[_user].lastDepositedTime + withdrawFeePeriod,
            availableWithStaking()
        );
        return status;
    }

    function initialize(
        IERC20 _token,
        IStaking _staking,
        MinterV2 _minter
    ) external initializer {
        token = _token;
        staking = _staking;
        minter = _minter;

        require(_token.approve(address(_staking), type(uint256).max), "Failed to approve");

        __Ownable_init();

        performanceFee = 200;
        // 2%
        callFee = 25;
        // 0.25%
        withdrawFee = 10;
        // 0.1%
        withdrawFeePeriod = 72 hours;
        // 3 days

        // todo: check divisor

        treasury = owner();
    }

    function potentialReward(address _user) external view override returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (totalShares == 0)
            return 0;
        return (availableWithStaking() * user.shares) / totalShares;
    }

    function deposit(uint256 _amount) external override {
        require(_amount > 0, "Nothing to deposit");

        uint256 pool = availableWithStaking();
        require(token.transferFrom(msg.sender, address(this), _amount), "Failed to transfer");
        uint256 currentShares = 0;
        if (totalShares != 0) {
            currentShares = (_amount * totalShares) / pool;
        } else {
            currentShares = _amount;
        }
        UserInfo storage user = userInfo[msg.sender];

        user.shares = user.shares + currentShares;
        user.lastDepositedTime = block.timestamp;

        totalShares = totalShares + currentShares;

        user.tokensAtLastUserAction = (user.shares * availableWithStaking()) / totalShares;
        user.lastUserActionTime = block.timestamp;

        _earn();

        emit Deposit(msg.sender, _amount, currentShares, block.timestamp);
    }

    function withdrawAll() external override {
        return _withdraw(userInfo[msg.sender].shares);
    }

    function claim() external override {
        return _claim();
    }

    function _claim() internal {
        staking.getReward();

        uint256 availableOnContract = availableOnContract();
        uint256 currentPerformanceFee = (availableOnContract * performanceFee) / 10000;
        require(token.transfer(treasury, currentPerformanceFee), "Failed to transfer to treasury");

        uint256 currentCallFee = (availableOnContract * callFee) / 10000;
        require(token.transfer(msg.sender, currentCallFee), "Failed to transfer to sender");

        _earn();

        lastHarvestedTime = block.timestamp;

        emit Harvest(msg.sender, currentPerformanceFee, currentCallFee);
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount) external override onlyOwner {
        require(_token != address(token), "Token cannot be same as deposit token");

        require(IERC20(_token).transfer(msg.sender, _amount), "Failed to transfer");
    }

    function getPricePerFullShare(uint256 _bn) public view returns (uint256) {
        return totalShares == 0 ? 1e18 : (availableWithCompound(_bn) * 1e18) / totalShares;
    }

    function withdraw(uint256 _shares) external override {
        _claim();
        return _withdraw(_shares);
    }

    function _withdraw(uint256 _shares) internal {
        UserInfo storage user = userInfo[msg.sender];
        require(_shares > 0, "Nothing to withdraw");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");

        uint256 currentAmount = (availableWithStaking() * _shares) / totalShares;
        user.shares = user.shares - _shares;
        totalShares = totalShares - _shares;

        uint256 bal = availableOnContract();
        if (bal < currentAmount) {
            uint256 balWithdraw = currentAmount - bal;
            staking.withdraw(balWithdraw);
            uint256 balAfter = availableOnContract();
            uint256 diff = balAfter - bal;
            if (diff < balWithdraw) {
                currentAmount = bal + diff;
            }
        }

        if (block.timestamp < user.lastDepositedTime + withdrawFeePeriod) {
            uint256 currentWithdrawFee = (currentAmount * withdrawFee) / 10000;
            require(token.transfer(treasury, currentWithdrawFee), "Failed to transfer to treasury");
            currentAmount = currentAmount - currentWithdrawFee;
        }

        if (user.shares > 0) {
            user.tokensAtLastUserAction = (user.shares * availableWithStaking()) / totalShares;
        } else {
            user.tokensAtLastUserAction = 0;
        }

        user.lastUserActionTime = block.timestamp;

        require(token.transfer(msg.sender, currentAmount), "Failed to transfer");

        emit Withdraw(msg.sender, currentAmount, _shares);
    }

    function calculateHarvestTokenRewards(uint256 bn) public view returns (uint256) {
        uint256 amount = staking.pendingReward(address(this), bn);
        amount = amount + availableOnContract();
        uint256 currentCallFee = (amount * callFee) / 10000;

        return currentCallFee;
    }

    function calculateTotalPendingTokenRewards(uint256 bn) public view returns (uint256) {
        uint256 amount = staking.pendingReward(address(this), bn);
        amount = amount + availableOnContract();

        return amount;
    }

    function availableOnContract() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function availableWithStaking() public view returns (uint256) {
        uint256 amount = staking.deposited(address(this));
        return token.balanceOf(address(this)) + amount;
    }

    function availableWithCompound(uint256 _blockNumber) public view returns (uint256) {
        return token.balanceOf(address(this)) + staking.deposited(address(this)) + staking.pendingReward(address(this), _blockNumber);
    }

    function _earn() internal {
        uint256 bal = availableOnContract();
        if (bal > 0) {
            staking.deposit(bal);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IEarning.sol";

interface IStaking is IEarning {
    function compound() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IAutoStaking {
    struct UserInfo {
        uint256 shares; // number of shares for a user
        uint256 lastDepositedTime; // keeps track of deposited time for potential penalty
        uint256 tokensAtLastUserAction; // keeps track of tokens deposited at the last user action
        uint256 lastUserActionTime; // keeps track of the last user action time
    }

    struct Status {
        address token;
        uint256 rewardPerBlock;
        uint256 tokensWithCompounding;
        uint256 tokensAtLastUserAction;
        uint256 performanceFee;
        uint256 callFee;
        uint256 withdrawFee;
        uint256 withdrawFeePeriod;
        uint256 rewardPerClaim;
        uint256 userTimeFeeEnd;
        uint256 accDeposited;
    }

    function getRewardPerClaim(uint256 _bn) external view returns(uint256);

    function getStatus(address _user, uint256 _bn) external view returns (Status memory);

    function getUserInfo(address _user) external view returns (UserInfo memory);

    function potentialReward(address _user) external view returns (uint256);

    function deposit(uint256 _amount) external;

    function withdrawAll() external;

    function claim() external;

    function inCaseTokensGetStuck(address _token, uint256 _amount) external;

    // Calculates the expected harvest reward from third party
    //    function calculateHarvestTokenRewards(uint256 bn) external view returns (uint256);

    // Calculates the total pending rewards that can be restaked
    //    function calculateTotalPendingTokenRewards(uint256 bn) external view returns (uint256);

    //    function getPricePerFullShare() external view returns (uint256);

    function withdraw(uint256 _shares) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./LiquifiV2Token.sol";
import "./Interfaces/IMinter.sol";

contract MinterV2 is IMinter, Initializable, OwnableUpgradeable {
    uint256 public rewardPerBlock;
    LiquifiV2Token public token;

    mapping(address => Farm) public farm;
    mapping(address => bool) public factories;

    IEarning[] staking;
    IEarning[] farming;

    uint256 public mintedToDev;
    address public dev;
    uint256 public devPercentage;

    uint256 public accMultiplierForFarms;
    uint256 public accMultiplierForStakings;

    uint256 accFarmReward;
    uint256 accStakingReward;

    uint256 lastFarmRewardBlock;
    uint256 lastStakingRewardBlock;

    uint256 public X;
    uint256 public Y;

    function initialize(address _token, uint256 _rewardPerBlock) external initializer {
        token = LiquifiV2Token(_token);
        rewardPerBlock = _rewardPerBlock;

        __Ownable_init();
    }

    function getAccumulatedRewardFarm(
        uint256 _lastAccumulatedReward,
        uint256 _blockNumber,
        address _addr
    ) external view returns (uint256, uint256) {
        uint256 _accFarmReward = accFarmReward;
        uint256 pendingReward;
        if (accMultiplierForFarms != 0) _accFarmReward = accFarmReward + (Y * (_blockNumber - lastFarmRewardBlock)) / accMultiplierForFarms;
        pendingReward = (_accFarmReward - _lastAccumulatedReward) * farm[_addr].multiplier;
        return (pendingReward, _accFarmReward);
    }

    function getAccumulatedRewardStaking(
        uint256 _lastAccumulatedReward,
        uint256 blockNumber,
        address _addr
    ) external view returns (uint256, uint256) {
        uint256 _accStakingReward = accStakingReward;
        uint256 pendingReward;

        if (accMultiplierForStakings != 0)
            _accStakingReward = accStakingReward + (X * (blockNumber - lastStakingRewardBlock)) / accMultiplierForStakings;
        pendingReward = (_accStakingReward - _lastAccumulatedReward) * farm[_addr].multiplier;
        return (pendingReward, _accStakingReward);
    }

    function registerFactory(address _factory) external override onlyOwner {
        factories[_factory] = true;
    }

    function getStatus(
        address _farm,
        address _user,
        uint256 _block,
        uint256 _factor,
        uint256 _divisor
    ) internal view returns (FarmInfo memory) {
        FarmInfo memory f;

        f.multiplier = farm[_farm].multiplier;
        if (_divisor != 0) f.rewardPerBlock = (farm[_farm].multiplier * _factor) / _divisor;
        f.token = address(IEarning(_farm).getToken());
        f.accDeposited = IEarning(_farm).getAccDeposit();
        f.deposited = IEarning(_farm).deposited(_user);
        f.earned = IEarning(_farm).pendingReward(_user, _block);
        f.farm = _farm;

        return f;
    }

    function getStatusStaking(address _user, uint256 _block) external view override returns (FarmInfo[] memory) {
        uint256 length = staking.length;

        FarmInfo[] memory f = new FarmInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            f[i] = getStatus(address(staking[i]), _user, _block, X, accMultiplierForStakings);
        }
        return f;
    }

    function getStatusFarms(address _user, uint256 _block) external view override returns (FarmInfo[] memory) {
        uint256 length = farming.length;

        FarmInfo[] memory f = new FarmInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            f[i] = getStatus(address(farming[i]), _user, _block, Y, accMultiplierForFarms);
        }
        return f;
    }

    function getFarms() external view override returns (IEarning[] memory) {
        return farming;
    }

    function getStakings() external view override returns (IEarning[] memory) {
        return staking;
    }

    function registerFarm(address _farm, uint256 _multiplier) external override {
        require(factories[msg.sender] == true, "Only factories can register");
        require(farm[_farm].registered == false, "Farming already registered");

        updateFarming();

        farm[_farm].multiplier = _multiplier;
        farm[_farm].registered = true;
        farming.push(IEarning(_farm));

        accMultiplierForFarms += _multiplier;
    }

    function registerStaking(address _farm, uint256 _multiplier) external override {
        require(factories[msg.sender] == true, "Only factories can register");
        require(farm[_farm].registered == false, "Farming already registered");

        updateStaking();

        farm[_farm].multiplier = _multiplier;
        farm[_farm].registered = true;
        staking.push(IEarning(_farm));

        accMultiplierForStakings += _multiplier;
    }

    function unregisterFarm(address _farm) external override onlyOwner {
        uint256 multiplier = farm[_farm].multiplier;
        require(farm[_farm].registered == true, "not registered");

        updateFarming();

        farm[_farm].multiplier = 0;
        for (uint256 i = 0; i < farming.length; i++)
            if (address(farming[i]) == _farm) {
                farming[i] = farming[farming.length - 1];
                farming.pop();
            }

        farm[_farm].registered = false;
        accMultiplierForFarms -= multiplier;
    }

    function unregisterStaking(address _farm) external override onlyOwner {
        uint256 multiplier = farm[_farm].multiplier;
        require(farm[_farm].registered == true, "not registered");

        updateStaking();

        farm[_farm].multiplier = 0;
        for (uint256 i = 0; i < staking.length; i++)
            if (address(staking[i]) == _farm) {
                staking[i] = staking[staking.length - 1];
                staking.pop();
            }

        farm[_farm].registered = false;
        accMultiplierForStakings -= multiplier;
    }

    function changeMultiplierFarm(address _farm, uint256 _multiplier) external override onlyOwner {
        require(farm[_farm].registered == true, "not registered");

        updateFarming();
        IEarning(_farm).updateState();

        accMultiplierForFarms = accMultiplierForFarms - farm[_farm].multiplier + _multiplier;
        farm[_farm].multiplier = _multiplier;
    }

    function changeMultiplierStaking(address _farm, uint256 _multiplier) external override onlyOwner {
        require(farm[_farm].registered == true, "not registered");

        updateStaking();
        IEarning(_farm).updateState();

        accMultiplierForStakings = accMultiplierForStakings - farm[_farm].multiplier + _multiplier;
        farm[_farm].multiplier = _multiplier;
    }

    function mint(address _to, uint256 _amount) external override {
        require(farm[msg.sender].registered == true, "Not registered");

        mintedToDev += (_amount * devPercentage) / 1000;
        require(token.mint(_to, _amount), "Failed to mint tokens");
    }

    function devPull() external override {
        require(token.mint(dev, mintedToDev), "Failed to transfer to dev");
        mintedToDev = 0;
    }

    function setDev(address _dev) external override onlyOwner {
        dev = _dev;
    }

    function setDevPercentage(uint256 _devPercentage) external override onlyOwner {
        devPercentage = _devPercentage;
    }

    function setXYZ(uint256 _B, uint256 _Z) external override onlyOwner {
        require(_B <= 100, "Bad _B value");
        require(rewardPerBlock >= _Z, "_Z too big");

        updateFarming();
        updateStaking();

        uint256 _X = (_B * (rewardPerBlock - _Z)) / 100;
        uint256 _Y = ((100 - _B) * (rewardPerBlock - _Z)) / 100;

        X = _X;
        Y = _Y;
    }

    function updateStaking() internal {
        if (accMultiplierForStakings != 0)
            accStakingReward = accStakingReward + (X * (block.number - lastStakingRewardBlock)) / accMultiplierForStakings;

        lastStakingRewardBlock = block.number;
    }

    function updateFarming() internal {
        if (accMultiplierForFarms != 0) accFarmReward = accFarmReward + (Y * (block.number - lastFarmRewardBlock)) / accMultiplierForFarms;

        lastFarmRewardBlock = block.number;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IEarning {
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardPending;
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt + user.rewardPending
        //   Whenever a user deposits or withdraws tokens, here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        //        uint256 amountClaimed;
    }

    struct EarningCheckpoint {
        uint256 block;
        uint256 rewardPerBlock;
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Reward(address indexed user, uint256 amount);

    function updateState() external;

    function getLastAccumulatedReward() external view returns (uint256);

    function getAccDeposit() external view returns (uint256);

    function deposited(address _user) external view returns (uint256);

    function pendingReward(address _user, uint256 _block) external view returns (uint256);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function getReward() external;

    function getToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LiquifiV2Token is ERC20, Ownable {
    address public minter;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _minter
    ) ERC20(_tokenName, _tokenSymbol) {
        minter = _minter;
    }

    function mint(address _account, uint256 _amount) external returns (bool) {
        require(msg.sender == minter, "only minter can mint");

        _mint(_account, _amount);
        return true;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IEarning.sol";

interface IMinter {
    struct Farm {
        uint256 multiplier;
        bool registered;
    }

    struct FarmInfo {
        uint256 multiplier; //not needed
        uint256 rewardPerBlock;
        uint256 accDeposited;
        uint256 deposited;
        uint256 earned;
        address token;
        address farm; //address of contract
    }

    function registerFactory(address _factory) external;

    //    function getStatus(address _farm, address _user, uint256 _block) external view returns (FarmInfo memory);

    function getStatusStaking(address _user, uint256 _block) external view returns (FarmInfo[] memory);

    function getStatusFarms(address _user, uint256 _block) external view returns (FarmInfo[] memory);

    function getFarms() external view returns (IEarning[] memory);

    function getStakings() external view returns (IEarning[] memory);

    function registerFarm(address _farm, uint256 _multiplier) external;

    function registerStaking(address _farm, uint256 _multiplier) external;

    function unregisterFarm(address _farm) external;

    function unregisterStaking(address _farm) external;

    function changeMultiplierFarm(address _addr, uint256 _multiplier) external;

    function changeMultiplierStaking(address _addr, uint256 _multiplier) external;

    function mint(address _to, uint256 _amount) external;

    function devPull() external;

    function setDev(address _dev) external;

    function setDevPercentage(uint256 _devPercentage) external;

    function setXYZ(uint256 _B, uint256 _Z) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

