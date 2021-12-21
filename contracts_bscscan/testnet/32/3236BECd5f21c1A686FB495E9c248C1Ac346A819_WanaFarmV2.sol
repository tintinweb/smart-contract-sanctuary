// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./interfaces/ITokenVault.sol";
import "./interfaces/ITokenFarmV2.sol";
import "./interfaces/ILocker.sol";

import "../BaseFarm.sol";
import "./Locker.sol";

contract WanaFarmV2 is BaseFarm, ReentrancyGuard, Ownable, Initializable, ITokenFarmV2 {
    using SafeERC20 for IERC20;

    bool public isDepositabled = true;
    address public stakeToken;
    address public rewardToken;
    uint256 public rewardPerBlock;
    uint256 public accRewardPerShare;
    uint256 public rewardVestingDuration;
    uint256 public stakingLockDuration;
    address public rewardLocker;
    address public stakeLocker;
    uint256 public stakerCount;
    uint256 public totalStakeAmount;


    // Info of each user that stakes Wana tokens.
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event ClaimedReward(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    modifier mustActive() {
        require(isActive == true, "Farm: Not active");
        _;
    }

    constructor() {}

    function initialize(
        address _stakeToken,
        address _rewardToken,
        uint256 _rewardAmount,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256[4] calldata _rateParameters, // 0: firstCycleRate , 1: initRate, 2: reducingRate, 3: reducingCycle
        uint256[4] calldata _poolCfg // 0: rewardVestingDuration, 1: rewardLockDuration, 2: stakingLockDuration, 3: groupDuration
    ) external initializer {
        require(_stakeToken != address(0), "Farm: Invalid stake token");
        require(_rewardToken != address(0), "Farm: Invalid vault token");
        require(_startBlock > block.number, "Farm: Invalid start block"); // ideally at least 24 hours more to give farmers time
        require(_rateParameters[0] > 0, "Farm: Invalid first cycle rate");
        require(_rateParameters[1] > 0, "Farm: Invalid initial rate");
        require(_rateParameters[2] > 0 && _rateParameters[2] < 100, "Farm: Invalid reducing rate");
        require(_rateParameters[3] > 0, "Farm: Invalid reducing cycle");

        rewardToken = _rewardToken;
        stakeToken = _stakeToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        rewardVestingDuration = _poolCfg[0];
        stakingLockDuration = _poolCfg[2];

        rateConfig.firstCycleRate = _rateParameters[0];
        rateConfig.initRate = _rateParameters[1];
        rateConfig.reducingRate = _rateParameters[2];
        rateConfig.reducingCycle = _rateParameters[3];

        uint256 _lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
        lastRewardBlock = _lastRewardBlock;
        accRewardPerShare = 0;

        Locker _rewardLocker = new Locker(_rewardToken, _poolCfg[0], _poolCfg[1], _poolCfg[3]);
        IERC20(_rewardToken).safeApprove(address(_rewardLocker), type(uint256).max);
        rewardLocker = address(_rewardLocker);
        
        Locker _stakeLocker = new Locker(_stakeToken, 0, _poolCfg[2], _poolCfg[3]);
        IERC20(_stakeToken).safeApprove(address(_stakeLocker), type(uint256).max);
        stakeLocker = address(_stakeLocker);

        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _rewardAmount);
    }

    function pendingReward(address _user) external view override returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 _accRewardPerShare = accRewardPerShare;
        uint256 _tokenSupply = getTotalSupply();
        if (block.number > lastRewardBlock && _tokenSupply != 0 && isActive == true) {
            uint256 _multiplier = getMultiplier(lastRewardBlock, block.number);
            uint256 _tokenReward = _multiplier * rewardPerBlock;
            _accRewardPerShare = _accRewardPerShare + (_tokenReward / _tokenSupply);
        }
        return ((user.amount * _accRewardPerShare) / MAGIC_NUMBER) - user.rewardDebt;
    }

    function updatePool() public mustActive {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 _tokenSupply = getTotalSupply();
        if (_tokenSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 _multiplier = getMultiplier(lastRewardBlock, block.number);
        uint256 _tokenReward = _multiplier * rewardPerBlock;
        accRewardPerShare = accRewardPerShare + (_tokenReward / _tokenSupply);
        lastRewardBlock = block.number;
    }

    function getTotalSupply() public view returns (uint256) {
        return IERC20(stakeToken).balanceOf(stakeLocker);
    }

    function getTokenPerBlock() external view override returns (uint256) {
        return rewardPerBlock;
    }

    function getUserInfo(address _account) external view override returns (uint256 amount, uint256 rewardDebt) {
        return (userInfo[_account].amount, userInfo[_account].rewardDebt);
    }

    function getStakeToken() external view override returns (address) {
        return stakeToken;
    }

    function deposit(uint256 _amount) external override mustActive {
        require(isDepositabled, "FARM: Deposit is temporarily disabled");
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 _pending = ((user.amount * accRewardPerShare) / MAGIC_NUMBER) - user.rewardDebt;
            if (_pending > 0) {
                ILocker(rewardLocker).addLocker(msg.sender, _pending);
            }
        } else if (_amount > 0) {
            stakerCount = stakerCount + 1;
        }
        user.amount = user.amount + _amount;
        user.rewardDebt = (user.amount * accRewardPerShare) / MAGIC_NUMBER;
        totalStakeAmount = totalStakeAmount + _amount;
        if (_amount > 0) {
            IERC20(stakeToken).safeTransferFrom(msg.sender, address(this), _amount);
        }
        ILocker(stakeLocker).addLocker(msg.sender, _amount);
        emit Deposit(msg.sender, _amount);
    }

    function unstake(uint256 _start, uint256 _end) external override nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 _amount = ILocker(stakeLocker).claimTotal(msg.sender, _start, _end);
        require(_amount > 0, "unstake: Unstake amount is not available");
        require(user.amount >= _amount, "unstake: Insufficient amount");
        
        if (isActive == true) {
            updatePool();
        }
        uint256 _pending = ((user.amount * accRewardPerShare) / MAGIC_NUMBER) - user.rewardDebt;
        if (_pending > 0) {
            ILocker(rewardLocker).addLocker(msg.sender, _pending);
        }
        user.amount = user.amount - _amount;
        user.rewardDebt = (user.amount * accRewardPerShare) / MAGIC_NUMBER;
        totalStakeAmount = totalStakeAmount - _amount;
        if (user.amount == 0) {
            stakerCount = stakerCount - 1;
        }
        emit Withdraw(msg.sender, _amount);
    }

    function claimReward(uint256 _start, uint256 _end) external nonReentrant {
        uint256 _amount = ILocker(rewardLocker).claimTotal(msg.sender, _start, _end);
        emit ClaimedReward(msg.sender, _amount);
    }

    function updateReducingRate(uint256 _reducingRate) external onlyOwner mustActive {
        require(_reducingRate > 0 && _reducingRate <= 100, "Farm: Invalid reducing rate");
        rateConfig.reducingRate = _reducingRate;
    }

    function setActive() external onlyOwner {
        isActive = true;
    }

    function changeDepositFlag() external onlyOwner {
        isDepositabled = !isDepositabled;
    }

    function rescueFunds(
        address tokenToRescue,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(tokenToRescue).safeTransfer(to, amount);
    }

    function forceEnd() external onlyOwner mustActive {
        updatePool();
        isActive = false;
    }
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
pragma solidity 0.8.0;

interface ITokenVault {
    function token() external view returns (address);

    function safeTokenTransfer(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenFarmV2 {
    
    function getTokenPerBlock() external view returns (uint256);

    function getUserInfo(address _account) external view returns (uint256 amount, uint256 rewardDebt);

    function deposit(uint256 _amount) external;

    function unstake(uint256 _start, uint256 _end) external;
    
    function pendingReward(address _user) external view returns (uint256);

    function getStakeToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ILocker {
    function addLocker(address _user, uint256 _amount) external;
    function claim(address _user, uint256 _index) external returns (uint256);
    function claimTotal(address _user, uint256 _start, uint256 _end) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract BaseFarm {
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many Wana tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        bool disabled;
    }

    struct LockConfig {
        uint256 groupInHours;
        uint256 lockInHours;
    }

    struct RateConfig {
        uint256 firstCycleRate;
        uint256 initRate;
        uint256 reducingRate; // 95 equivalent to 95%
        uint256 reducingCycle; // 195000 equivalent 195000 block
    }

    struct StakeTokenInfo {
        uint256 amount;
        uint256 startBlock;
        uint256 startTime;
        uint256 lockDuration;
        uint256 unstakeAmount;
        bool isActive;
    }

    struct LockRewardInfo {
        uint256 amount;
        uint256 startBlock;
        uint256 lockDuration;
        uint256 claimedAmount;
        bool isActive;
    }

    uint256 internal MAGIC_NUMBER = 1e12;
    bool public isActive;
    uint256 public startBlock;
    uint256 public lastRewardBlock;
    RateConfig public rateConfig;

    event UserEntered(address indexed _user);
    event UserLeft(address indexed _user);
    
    /**
     * @notice Gets the reward multiplier over the given _fromBlock until _to block
     * @param _fromBlock the start of the period to measure rewards for
     * @param _toBlock the end of the period to measure rewards for
     * @return The weighted multiplier for the given period
     */
    function getMultiplier(uint256 _fromBlock, uint256 _toBlock) public view returns (uint256) {
        return _getMultiplierFromStart(_toBlock) - _getMultiplierFromStart(_fromBlock);
    }

    function _getMultiplierFromStart(uint256 _block) internal view returns (uint256) {
        if (_block <= startBlock) return 0;
        uint256 _difBlocks = _block - startBlock;
        uint256 roundPassed = _difBlocks / rateConfig.reducingCycle;
        if (roundPassed == 0) {
            return _difBlocks * rateConfig.firstCycleRate * MAGIC_NUMBER;
        } else {
            uint256 multiplier = rateConfig.reducingCycle * rateConfig.firstCycleRate * MAGIC_NUMBER;
            uint256 i = 0;
            uint256 X = MAGIC_NUMBER * rateConfig.initRate;
            for (i = 0; i < roundPassed - 1; i++) {
                multiplier += X * rateConfig.reducingCycle;
                X = X * rateConfig.reducingRate/100;
            }
            uint256 Y = _difBlocks % rateConfig.reducingCycle;
            if (Y > 0) {
                multiplier += X * Y;
            }

            return multiplier;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ITokenFarm.sol";
import "./interfaces/ILocker.sol";

// import "hardhat/console.sol";

contract Locker is ReentrancyGuard, ILocker {
    using SafeERC20 for IERC20;
    IERC20 public token;
    uint256 public vestingDuration; // blocks
    uint256 public fullockDuration; // blocks
    uint256 public groupDuration; // blocks
    address public farmAddress;

    struct LockInfo {
        uint256 amount;
        uint256 startTime;
        uint256 startBlock;
        uint256 vestingDuration;
        uint256 fullockDuration;
        uint256 claimedAmount;
        bool isActive;
    }

    event AddedLock(address indexed account, uint256 amount);
    event ClaimedLock(address indexed account, uint256 amount);
    event LockAdded(address indexed user, uint256 indexed index, uint256 startTime, uint256 lockDuration, uint256 amount);
    event LockUpdated(address indexed user, uint256 indexed index, uint256 startTime, uint256 amount);

    // user address => vestingInfo[]
    mapping(address => LockInfo[]) private _userToLockList;
    mapping(address => uint256) private _totalAmount;
    mapping(address => uint256) private _totalClaimedAmount;

    modifier onlyFarm() {
        require(msg.sender == farmAddress, "Locker: You are not farm");
        _;
    }

    constructor(address _token, uint256 _vestingDuration, uint256 _fullockDuration, uint256 _groupDuration) {
        token = IERC20(_token);
        vestingDuration = _vestingDuration;
        fullockDuration = _fullockDuration;
        groupDuration = _groupDuration;
        farmAddress = msg.sender;
    }

    function addLocker(address _user, uint256 _amount) external onlyFarm override {
        if (_amount == 0) return;
        uint256 _index = _userToLockList[_user].length > 0 ? _userToLockList[_user].length - 1 : 0;
        if (_userToLockList[_user].length > 0 && block.number < _userToLockList[_user][_index].startBlock + groupDuration) {
            _userToLockList[_user][_index].startTime = block.timestamp;
            _userToLockList[_user][_index].startBlock = block.number;
            _userToLockList[_user][_index].amount += _amount;
        } else {
            LockInfo memory _info = LockInfo(_amount, block.timestamp, block.number, vestingDuration, fullockDuration, 0, true);
            _userToLockList[_user].push(_info);
        }
        _totalAmount[_user] += _amount;
        token.safeTransferFrom(msg.sender, address(this), _amount);
        emit AddedLock(_user, _amount);
    }

    function claim(address _user, uint256 _index) external onlyFarm override returns (uint256) {
        return _claims(_user, _index, _index);
    }

    function claimTotal(address _user, uint256 _start, uint256 _end) external onlyFarm override returns (uint256) {
        return _claims(_user, _start, _end);
    }

    function _claims(address _user, uint256 _start, uint256 _end) internal returns (uint256 _totalClaimableAmount) {
        if (_userToLockList[_user].length == 0) {
            return _totalClaimableAmount;
        }
        if (_end >= _userToLockList[_user].length) {
            _end = _userToLockList[_user].length - 1;
        }
        if (_start > _end) {
            return _totalClaimableAmount;
        }
        for (uint256 _index = _start; _index <= _end; _index++) {
            uint256 _claimableAmount = _getClaimableAmount(_user, _index);
            if (_claimableAmount > 0) {
                _claim(_user, _index, _claimableAmount, false);
                _totalClaimableAmount += _claimableAmount;
            }
        }
        if (_totalClaimableAmount > 0) {
            token.safeTransfer(_user, _totalClaimableAmount);
            emit ClaimedLock(_user, _totalClaimableAmount);
        }
    }

    function getTotalClaimableAmount(address _user, uint256 _start, uint256 _end)
    external
    view
    returns (uint256 totalClaimableAmount)
    {
        if (_userToLockList[_user].length == 0) {
            return 0;
        }
        if (_end >= _userToLockList[_user].length) {
            _end = _userToLockList[_user].length - 1;
        }
        if (_start > _end) {
            return 0;
        }
        for (uint256 _index = _start; _index <= _end; _index++) {
            totalClaimableAmount = totalClaimableAmount + _getClaimableAmount(_user, _index);
        }
    }

    function getClaimableAmount(address _user, uint256 _index)
    external
    view
    returns (uint256)
    {
        if (_userToLockList[_user].length <= _index) {
            return 0;
        }
        return _getClaimableAmount(_user, _index);
    }

    function getLockerCountByUser(address _user) external view returns (uint256 count) {
        count = _userToLockList[_user].length;
    }

    function getLockerInfo(address _user, uint256 _index)
    external
    view
    returns (LockInfo memory info)
    {
        require(_index < _userToLockList[_user].length, "Locker: Invalid index");
        info = _userToLockList[_user][_index];
    }

    function getTotalAmountLockedByUser(address _user) external view returns (uint256) {
        return _totalAmount[_user] - _totalClaimedAmount[_user];
    }

    function _claim(address _user, uint256 _index, uint256 _claimableAmount, bool _shouldTransfer) internal {
        _userToLockList[_user][_index].claimedAmount += _claimableAmount;
        if (_userToLockList[_user][_index].amount == _userToLockList[_user][_index].claimedAmount) {
            _userToLockList[_user][_index].isActive = false;
        }
        _totalClaimedAmount[_user] += _claimableAmount;
        if (_shouldTransfer) {
            token.safeTransfer(_user, _claimableAmount);
        }
    }

    function _getClaimableAmount(address _user, uint256 _index)
        internal
        view
        returns (uint256 claimableAmount)
    {
        LockInfo memory info = _userToLockList[_user][_index];
        if (block.number <= info.startBlock + info.fullockDuration) return 0;
        if (!info.isActive) return 0;
        uint256 passedBlocks = block.number - info.startBlock;

        uint256 releasedAmount;
        if (passedBlocks >= info.vestingDuration) {
            releasedAmount = info.amount;
        } else {
            releasedAmount = (info.amount * passedBlocks) / info.vestingDuration;
        }

        claimableAmount = 0;
        if (releasedAmount > info.claimedAmount) {
            claimableAmount = releasedAmount - info.claimedAmount;
        }
    }

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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenFarm {
    function getTokenPerBlock() external view returns (uint256);

    function getUserInfo(address _account) external view returns (uint256 amount, uint256 rewardDebt);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function emergencyWithdraw() external;

    function pendingToken(address _user) external view returns (uint256);

    function getToken() external view returns (address);
}