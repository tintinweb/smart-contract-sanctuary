// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../common/ArableAccessControl.sol";
import "../interfaces/staking/IStakingRoot.sol";
import "../interfaces/staking/IDStaking.sol";
import "../interfaces/staking/IStaking.sol";
import "../interfaces/common/IArableAccessControl.sol";
import "./DStaking.sol";

/** @title StakingRoot
 * @notice
 */

contract StakingRoot is ArableAccessControl, IStakingRoot {
    using SafeERC20 for IERC20;

    struct DStakingInfo {
        address addr;
        uint256 rewardsAmount;
    }

    address public override stakingOverview;
    address public override stakingLocker;
    address public override assetManager;
    IERC20 public token;

    // address: dStakingCreator
    mapping(address => bool) public isDStakingCreationAllowed;
    mapping(address => bool) public dStakingCreated;

    address public override staking;
    DStakingInfo public stakingInfo;
    mapping(address => bool) public override isDStaking;
    mapping(address => bool) public override isDStakingRemoved;
    DStakingInfo[] public dStakings;
    mapping(address => address) public override dStakingCreators;
    mapping(address => uint256) public dStakingIndex;

    uint256 public override minTokenAmountForDStaker;
    uint256 public dStakingCount;

    uint256 public totalDistributed;
    uint256 public totalReleased;

    uint256 public stakingMultiplier;
    uint256 public constant BASE_MULTIPLIER = 1e2;

    uint256 public constant DSTAKING_LIMIT = 50;

    event DStakingRegistered(address creator, address dStaking, uint256 commissionRate);
    event DStakingRemoved(address dStaking);
    event StakingRewardsClaimed(address beneficiary, uint256 amount);
    event DStakingRewardsClaimed(address beneficiary, uint256 amount);

    modifier onlyStakingOrDStaking(address addr) {
        require(staking == addr || isDStaking[addr], "Not staking or dStaking");

        _;
    }

    modifier onlyDStakingCreator(address dStaking, address addr) {
        require(dStakingCreators[dStaking] == addr, "Not DStaking owner");
        _;
    }

    function initialize(IERC20 _token) external initializer {
        super.__ArableAccessControl_init_unchained();

        require(address(_token) != address(0), "Invalid token");
        token = _token;
        stakingMultiplier = 50;
    }

    function getDStakingInfo(address dStaking) public view returns (DStakingInfo memory) {
        return dStakings[dStakingIndex[dStaking]];
    }

    function registerDStaking(uint256 amount, uint256 commissionRate) external {
        require(amount >= minTokenAmountForDStaker, "Low amount!");
        require(isDStakingCreationAllowed[msg.sender], "Not allowed to register DStaking");
        require(dStakingCount < DSTAKING_LIMIT, "Limit");
        require(!dStakingCreated[msg.sender], "Already created");

        DStaking dStaking = new DStaking();

        address dStakingAddr = address(dStaking);

        isDStaking[dStakingAddr] = true;
        dStakingCreators[dStakingAddr] = msg.sender;
        dStakingIndex[dStakingAddr] = dStakingCount;

        IArableAccessControl(stakingLocker).setOperator(dStakingAddr, true);
        IArableAccessControl(stakingOverview).setOperator(dStakingAddr, true);

        dStaking.initialize(token, this, commissionRate);
        token.safeTransferFrom(msg.sender, address(this), amount);
        token.approve(dStakingAddr, amount);
        dStaking.initDeposit(address(this), msg.sender, amount);

        dStakings.push(DStakingInfo({ addr: dStakingAddr, rewardsAmount: 0 }));

        dStakingCount++;

        dStaking.transferOwnership(msg.sender);

        dStakingCreated[msg.sender] = true;

        emit DStakingRegistered(msg.sender, dStakingAddr, commissionRate);
    }

    function removeDStaking(address dStaking) external onlyDStakingCreator(dStaking, msg.sender) {
        //
        _distributeRewards();

        DStakingInfo memory info = getDStakingInfo(dStaking);
        uint256 curIndex = dStakingIndex[dStaking];

        if (info.rewardsAmount > 0) {
            uint256 claimedAmount = safeTokenTransfer(dStaking, info.rewardsAmount);
            emit DStakingRewardsClaimed(msg.sender, claimedAmount);
            totalReleased = totalReleased + claimedAmount;
        }

        isDStakingRemoved[dStaking] = true;

        if (curIndex == dStakingCount - 1) {
            delete dStakings[curIndex];
            dStakingCount--;
            delete dStakingIndex[dStaking];
        } else {
            dStakingCount--;
            dStakings[curIndex].addr = dStakings[dStakingCount].addr;
            dStakings[curIndex].rewardsAmount = dStakings[dStakingCount].rewardsAmount;
            delete dStakings[dStakingCount];
            dStakingIndex[dStakings[curIndex].addr] = curIndex;
            delete dStakingIndex[dStaking];
        }

        IArableAccessControl(stakingLocker).setOperator(address(staking), false);

        emit DStakingRemoved(dStaking);
    }

    function _distributeRewards() private {
        uint256 pendingRewards = IERC20(token).balanceOf(address(this)) + totalReleased - totalDistributed;

        if (pendingRewards > 0) {
            uint256 totalStaked = 0;
            for (uint256 index = 0; index < dStakingCount; index++) {
                totalStaked = totalStaked + IDStaking(dStakings[index].addr).getTotalDelegatedAmount();
            }
            totalStaked = totalStaked + IStaking(staking).getTotalDelegatedAmount();

            if (totalStaked > 0) {
                for (uint256 index = 0; index < dStakingCount; index++) {
                    uint256 newRewards = (pendingRewards * IDStaking(dStakings[index].addr).getTotalDelegatedAmount()) /
                        totalStaked;
                    dStakings[index].rewardsAmount = dStakings[index].rewardsAmount + newRewards;
                    totalDistributed = totalDistributed + newRewards;
                }

                uint256 stakingRewards = (
                    ((pendingRewards * IStaking(staking).getTotalDelegatedAmount() * stakingMultiplier) / totalStaked)
                ) / BASE_MULTIPLIER;

                stakingInfo.rewardsAmount = stakingInfo.rewardsAmount + stakingRewards;

                totalDistributed = totalDistributed + stakingRewards;
            }
        }
    }

    function distributeRewards() external {
        _distributeRewards();
    }

    function claimRewards() external override onlyStakingOrDStaking(msg.sender) {
        if (msg.sender == staking) {
            uint256 rewards = stakingInfo.rewardsAmount;
            if (rewards > 0) {
                uint256 claimedAmount = safeTokenTransfer(msg.sender, rewards);
                stakingInfo.rewardsAmount = stakingInfo.rewardsAmount - claimedAmount;

                totalReleased = totalReleased + claimedAmount;

                emit StakingRewardsClaimed(msg.sender, claimedAmount);
            }
        } else {
            // dstaking
            uint256 rewards = getDStakingInfo(msg.sender).rewardsAmount;

            if (rewards > 0) {
                uint256 claimedAmount = safeTokenTransfer(msg.sender, rewards);

                dStakings[dStakingIndex[msg.sender]].rewardsAmount =
                    dStakings[dStakingIndex[msg.sender]].rewardsAmount -
                    claimedAmount;

                totalReleased = totalReleased + claimedAmount;

                emit DStakingRewardsClaimed(msg.sender, claimedAmount);
            }
        }
    }

    function safeTokenTransfer(address to, uint256 amount) internal returns (uint256) {
        uint256 bal = token.balanceOf(address(this));

        if (bal >= amount) {
            token.safeTransfer(to, amount);
            return amount;
        } else {
            token.safeTransfer(to, bal);
            return bal;
        }
    }

    function setStaking(address _staking) external onlyOwner {
        require(_staking != address(0), "Invalid");
        if (address(staking) != address(0)) {
            IArableAccessControl(stakingLocker).setOperator(staking, false);
        }
        staking = _staking;
        stakingInfo.addr = _staking;
        IArableAccessControl(stakingLocker).setOperator(staking, true);
    }

    function setStakingOverview(address _stakingOverview) external onlyOwner {
        require(_stakingOverview != address(0), "Invalid");
        stakingOverview = _stakingOverview;
    }

    function setStakingLocker(address _stakingLocker) external onlyOwner {
        require(_stakingLocker != address(0), "Invalid");
        stakingLocker = _stakingLocker;
    }

    function setAssetManager(address _manager) external onlyOwner {
        require(_manager != address(0), "Invalid");
        assetManager = _manager;
    }

    function setStakingMultiplier(uint256 _multiplier) external onlyOwner {
        require(_multiplier < BASE_MULTIPLIER, "Invalid");
        stakingMultiplier = _multiplier;
    }

    function setMinTokenAmountForDStaking(uint256 _minTokenAmountForDStaker) external onlyOwner {
        minTokenAmountForDStaker = _minTokenAmountForDStaker;
    }

    function withdrawTokenFromStaking(
        address _staking,
        uint256 amount,
        address beneficiary
    ) external onlyOwner {
        require(beneficiary != address(0), "Invalid beneficiary");
        IStaking(_staking).withdrawAnyToken(address(token), amount, beneficiary);
    }

    function setDStakingCreationAllowed(address creator, bool allowed) external onlyOwner {
        isDStakingCreationAllowed[creator] = allowed;
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/common/IArableAccessControl.sol";

/** @title ArableAccessControl
 * @notice
 */

contract ArableAccessControl is Initializable, OwnableUpgradeable, IArableAccessControl {
    mapping(address => bool) public isManager;
    mapping(address => bool) public isOperator;

    event ManagerSet(address indexed user, bool set);
    event OperatorSet(address indexed user, bool set);

    function __ArableAccessControl_init_unchained() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    modifier onlyOperatorOrOwner() {
        require(msg.sender == owner() || isOperator[msg.sender], "Not operator or owner");

        _;
    }

    modifier onlyOperator() {
        require(isOperator[msg.sender], "Not operator");

        _;
    }

    modifier onlyManagerOrOwner() {
        require(msg.sender == owner() || isManager[msg.sender], "Not manager or owner");

        _;
    }

    function setManager(address manager, bool set) external override onlyOwner {
        isManager[manager] = set;

        emit ManagerSet(manager, set);
    }

    function setOperator(address operator, bool set) external override onlyManagerOrOwner {
        isOperator[operator] = set;

        emit OperatorSet(operator, set);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStakingRoot {
    function stakingOverview() external view returns (address);

    function stakingLocker() external view returns (address);

    function assetManager() external view returns (address);

    function staking() external view returns (address);

    function isDStaking(address) external view returns (bool);

    function isDStakingRemoved(address) external view returns (bool);

    function dStakingCreators(address) external view returns (address);

    function claimRewards() external;

    function minTokenAmountForDStaker() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDStaking {
    function getTotalDelegatedAmount() external view returns (uint256);

    function getDelegatedAmount(address user) external view returns (uint256);

    function withdrawAnyToken(
        address _token,
        uint256 amount,
        address beneficiary
    ) external;

    function claim() external;

    function undelegate(uint256 amount) external;

    function delegateFor(address beneficiary, uint256 amount) external;

    function delegate(uint256 amount) external;

    function redelegate(address toDStaking, uint256 amount) external;

    function pendingRewards(address _user) external view returns (uint256);

    function initDeposit(
        address creator,
        address beneficiary,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStaking {
    function getDelegatedAmount(address user) external view returns (uint256);

    function getTotalDelegatedAmount() external view returns (uint256);

    function withdrawAnyToken(
        address _token,
        uint256 amount,
        address beneficiary
    ) external;

    function claim() external;

    function undelegate(uint256 amount, bool _withdrawRewards) external;

    function delegate(uint256 amount) external;

    function pendingRewards(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArableAccessControl {
    function setOperator(address operator, bool set) external;

    function setManager(address manager, bool set) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/staking/IDStaking.sol";
import "../interfaces/staking/IStakingRoot.sol";
import "../interfaces/staking/IStakingOverview.sol";
import "../interfaces/staking/IStakingLocker.sol";
import "../interfaces/staking/IAssetManager.sol";

/**
 * @title DStaking
 */

contract DStaking is Initializable, OwnableUpgradeable, IDStaking, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
    }

    struct PoolInfo {
        uint256 accTokenPerShare;
        uint256 delegatedAmount;
        uint256 rewardsAmount;
        uint256 lockupDuration;
    }

    IStakingRoot public stakingRoot;
    IERC20 public token;

    uint256 public totalDistributed;
    uint256 public totalReleased;

    PoolInfo public poolInfo;
    mapping(address => UserInfo) public userInfo;

    uint256 public commissionRate;
    uint256 public commissionReward;
    uint256 public constant COMMION_RATE_MULTIPLIER = 1e3;
    uint256 public lastCommissionRateUpdateTimeStamp;
    uint256 public constant COMMION_RATE_MAX = 200; // max is 20%
    uint256 public constant COMMION_UPDATE_MIN_DURATION = 1 days; // update once once in a day

    uint256 public constant SHARE_MULTIPLIER = 1e12;

    event Delegate(address indexed user, uint256 amount);
    event Undelegate(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event Redelegate(address indexed user, address toDStaking, uint256 amount);
    event CommissionRateUpdated(uint256 commissionRate);
    event CommissionRewardClaimed(uint256 claimedAmount);

    modifier onlyRoot() {
        require(msg.sender == address(stakingRoot), "Not StakingRoot");
        _;
    }

    modifier onlyActiveDStaking(address dStaking) {
        require(stakingRoot.isDStaking(dStaking) && !stakingRoot.isDStakingRemoved(dStaking), "Invalid dStaking");
        _;
    }

    function initialize(
        IERC20 _token,
        IStakingRoot _stakingRoot,
        uint256 _commissionRate
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();

        require(address(_token) != address(0), "Invalid token");
        require(address(_stakingRoot) != address(0), "Invalid stakingRoot");
        token = _token;
        stakingRoot = _stakingRoot;

        require(_commissionRate <= COMMION_RATE_MAX, "Too big commissionRate");

        commissionRate = _commissionRate;
        lastCommissionRateUpdateTimeStamp = block.timestamp;

        poolInfo.lockupDuration = 14 days;
    }

    function stakingCreator() private view returns (address) {
        return stakingRoot.dStakingCreators(address(this));
    }

    function commissionRatedRewards(uint256 amount) private view returns (uint256 rewards, uint256 fee) {
        fee = (amount * commissionRate) / COMMION_RATE_MULTIPLIER;
        rewards = amount - fee;
    }

    function getTotalDistributableRewards() public view returns (uint256) {
        return token.balanceOf(address(this)) + totalReleased - poolInfo.delegatedAmount - totalDistributed;
    }

    /**
     * @notice get Pending Rewards of a user
     *
     * @param _user: User Address
     */
    function pendingRewards(address _user) external view override returns (uint256) {
        require(_user != address(0), "Invalid user address");
        UserInfo storage user = userInfo[_user];
        uint256 accTokenPerShare = poolInfo.accTokenPerShare;
        uint256 delegatedAmount = poolInfo.delegatedAmount;

        uint256 tokenReward = getTotalDistributableRewards();

        if (tokenReward != 0 && delegatedAmount != 0) {
            accTokenPerShare = accTokenPerShare + ((tokenReward * (SHARE_MULTIPLIER)) / (delegatedAmount));
        }
        return (user.amount * accTokenPerShare) / (SHARE_MULTIPLIER) - user.rewardDebt + user.pendingRewards;
    }

    /**
     * @notice updatePool distribute pendingRewards
     *
     */
    function updatePool() internal {
        uint256 delegatedAmount = poolInfo.delegatedAmount;
        if (delegatedAmount == 0) {
            return;
        }
        uint256 tokenReward = getTotalDistributableRewards();
        poolInfo.rewardsAmount = poolInfo.rewardsAmount + tokenReward;
        poolInfo.accTokenPerShare =
            poolInfo.accTokenPerShare +
            ((tokenReward * (SHARE_MULTIPLIER)) / (delegatedAmount));

        totalDistributed = totalDistributed + tokenReward;
    }

    /**
     * @notice delegate token
     *
     * @param depositer: {address}
     * @param amount: {uint256}
     * @param beneficiary: {address}
     */
    function _delegate(
        address depositer,
        uint256 amount,
        address beneficiary
    ) private onlyActiveDStaking(address(this)) {
        updatePool();
        UserInfo storage user = userInfo[beneficiary];

        if (user.amount > 0) {
            uint256 pending = (user.amount * (poolInfo.accTokenPerShare)) / (SHARE_MULTIPLIER) - (user.rewardDebt);
            if (pending > 0) {
                user.pendingRewards = user.pendingRewards + pending;
            }
        }

        if (amount > 0) {
            token.safeTransferFrom(depositer, address(this), amount);
            user.amount = user.amount + amount;
            poolInfo.delegatedAmount = poolInfo.delegatedAmount + amount;
        }

        user.rewardDebt = (user.amount * (poolInfo.accTokenPerShare)) / (SHARE_MULTIPLIER);

        IStakingOverview(IStakingRoot(stakingRoot).stakingOverview()).delegate(beneficiary, amount);

        emit Delegate(beneficiary, amount);
    }

    function initDeposit(
        address creator,
        address beneficiary,
        uint256 amount
    ) external override onlyRoot {
        _delegate(creator, amount, beneficiary);
    }

    function delegateFor(address beneficiary, uint256 amount) external override {
        _delegate(msg.sender, amount, beneficiary);
    }

    /**
     * @notice delegate token
     *
     * @param amount: Amount of token to delegate
     */
    function delegate(uint256 amount) external override {
        _delegate(msg.sender, amount, msg.sender);
    }

    function processRewards(address addr) private {
        UserInfo storage user = userInfo[addr];

        (uint256 amount, ) = commissionRatedRewards(user.pendingRewards);
        uint256 claimedAmount = safeTokenTransfer(addr, amount);

        uint256 total = (claimedAmount * COMMION_RATE_MULTIPLIER) / (COMMION_RATE_MULTIPLIER - commissionRate);
        uint256 fee = total - claimedAmount;

        totalReleased = totalReleased + claimedAmount;
        user.pendingRewards = user.pendingRewards - total;
        poolInfo.rewardsAmount = poolInfo.rewardsAmount - claimedAmount;

        commissionReward = commissionReward + fee;

        emit Claim(addr, total);
    }

    /**
     * @notice redelegate token
     *
     * @param toDStaking: DStaking address
     * @param amount: Amount of token to delegate
     */
    function redelegate(address toDStaking, uint256 amount) external override onlyActiveDStaking(toDStaking) {
        require(amount > 0, "Invalid amount");
        UserInfo storage user = userInfo[msg.sender];

        updatePool();

        if (user.amount > 0) {
            uint256 pending = (user.amount * (poolInfo.accTokenPerShare)) / (SHARE_MULTIPLIER) - user.rewardDebt;
            user.pendingRewards = user.pendingRewards + pending;
        }

        if (amount > 0) {
            user.amount = user.amount - amount;

            token.approve(toDStaking, amount);
            IDStaking(toDStaking).delegateFor(msg.sender, amount);

            emit Redelegate(msg.sender, toDStaking, amount);
        }
    }

    /**
     * @notice undelegate token
     *
     * @param amount: Amount of token to deposit
     */
    function undelegate(uint256 amount) external override nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= amount, "Withdrawing more than you have!");
        updatePool();
        uint256 pending = (user.amount * (poolInfo.accTokenPerShare)) / (SHARE_MULTIPLIER) - (user.rewardDebt);
        if (pending > 0) {
            user.pendingRewards = user.pendingRewards + (pending);
        }
        if (amount > 0) {
            uint256 mimLockAmount = IAssetManager((stakingRoot).assetManager()).getMinimumLockAmount(msg.sender);
            require(user.amount - amount >= mimLockAmount, "Too much");

            // check for owner
            if (stakingCreator() == msg.sender) {
                // creator is trying to undelegate
                if (!stakingRoot.isDStakingRemoved(address(this))) {
                    require(user.amount - amount >= (stakingRoot).minTokenAmountForDStaker(), "Too much");
                }
            }

            address tokenLocker = (stakingRoot).stakingLocker();
            token.approve(tokenLocker, amount);
            IStakingLocker(tokenLocker).lockToken(
                address(token),
                msg.sender,
                amount,
                block.timestamp,
                block.timestamp + poolInfo.lockupDuration
            );
            user.amount = user.amount - amount;
            poolInfo.delegatedAmount = poolInfo.delegatedAmount - amount;

            IStakingOverview(stakingRoot.stakingOverview()).undelegate(msg.sender, amount);
        }
        user.rewardDebt = (user.amount * (poolInfo.accTokenPerShare)) / (SHARE_MULTIPLIER);
        emit Undelegate(msg.sender, amount);
    }

    /**
     * @notice claim rewards
     *
     */
    function claim() external override nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        uint256 pending = (user.amount * (poolInfo.accTokenPerShare)) / (SHARE_MULTIPLIER) - (user.rewardDebt);
        if (pending > 0 || user.pendingRewards > 0) {
            user.pendingRewards = user.pendingRewards + pending;
            processRewards(msg.sender);
        }
        user.rewardDebt = (user.amount * (poolInfo.accTokenPerShare)) / (SHARE_MULTIPLIER);
    }

    function safeTokenTransfer(address to, uint256 amount) internal returns (uint256) {
        if (amount > poolInfo.rewardsAmount) {
            token.safeTransfer(to, poolInfo.rewardsAmount);
            return poolInfo.rewardsAmount;
        } else {
            token.safeTransfer(to, amount);
            return amount;
        }
    }

    function getDelegatedAmount(address user) external view override returns (uint256) {
        return userInfo[user].amount;
    }

    function getTotalDelegatedAmount() external view override returns (uint256) {
        return poolInfo.delegatedAmount;
    }

    function withdrawAnyToken(
        address _token,
        uint256 amount,
        address beneficiary
    ) external override onlyRoot {
        IERC20(_token).safeTransfer(beneficiary, amount);
    }

    function claimRewardsFromRoot() external {
        stakingRoot.claimRewards();
    }

    function setCommissionRate(uint256 _commissionRate) external onlyOwner {
        require(block.timestamp - lastCommissionRateUpdateTimeStamp >= COMMION_UPDATE_MIN_DURATION, "Can't update");
        require(_commissionRate <= COMMION_RATE_MAX, "Too big commissionRate");
        commissionRate = _commissionRate;

        emit CommissionRateUpdated(commissionRate);
    }

    function claimCommissionRewards() external onlyOwner {
        uint256 claimedAmount = safeTokenTransfer(msg.sender, commissionReward);

        commissionReward = commissionReward - claimedAmount;

        totalReleased = totalReleased + claimedAmount;
        poolInfo.rewardsAmount = poolInfo.rewardsAmount - claimedAmount;

        emit CommissionRewardClaimed(claimedAmount);
    }
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

interface IStakingOverview {
    function userDelegated(address) external view returns (uint256);

    function delegate(address, uint256) external;

    function undelegate(address, uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** @title IStakingLocker
 * @notice
 */

interface IStakingLocker {
    function lockToken(
        address token,
        address beneficiary,
        uint256 amount,
        uint256 startTime,
        uint256 unlockTime
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAssetManager {
    function getMinimumLockAmount(address user) external view returns (uint256);
}