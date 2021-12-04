// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SHEESHA.sol";
import "./ISheeshaStaking.sol";
import "./IVesting.sol";

/**
 * @title Sheesha native token staking contract
 * @author Sheesha Finance
 */
contract SHEESHAVault is ISheeshaStaking, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for SHEESHA;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 token;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accSheeshaPerShare;
    }

    uint256 private constant PERCENTAGE_DIVIDER = 1e12;

    SHEESHA public immutable sheesha;
    uint256 public immutable startBlock;
    uint256 public immutable sheeshaPerBlock;

    uint256 public tokenRewards = 100_000_000e18;
    uint256 public totalAllocPoint;
    uint256 public userCount;
    IVesting public vesting;
    PoolInfo[] public poolInfo;
    bool public started;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => address) public userList;
    mapping(address => bool) internal isExisting;

    /**
     * @dev Emitted when a user deposits tokens.
     * @param user Address of user for which deposit was made.
     * @param pid Pool's unique ID.
     * @param amount The amount of deposited tokens.
     */
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    /**
     * @dev Emitted when a user withdraw tokens from staking.
     * @param user Address of user for which deposit was made.
     * @param pid Pool's unique ID.
     * @param amount The amount of deposited tokens.
     */
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /**
     * @dev Emitted when a user withdraw tokens from staking without caring about rewards.
     * @param user Address of user for which deposit was made.
     * @param pid Pool's unique ID.
     * @param amount The amount of deposited tokens.
     */
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    /**
     * @dev Constructor of the contract.
     * @param _sheesha Sheesha native token.
     * @param _startBlock Start block of staking contract.
     * @param _sheeshaPerBlock Amount of Sheesha rewards per block.
     */
    constructor(
        SHEESHA _sheesha,
        uint256 _startBlock,
        uint256 _sheeshaPerBlock
    ) {
        require(address(_sheesha) != address(0), "Sheesha can't be address 0");
        sheesha = _sheesha;
        startBlock = _startBlock;
        sheeshaPerBlock = _sheeshaPerBlock;
    }

    /**
     * @dev Sets the vesting contract to interact with.
     * @param _vesting Address of vesting contract.
     */
    function setVesting(address _vesting) external onlyOwner {
        require(_vesting != address(0), "Wrong vesting address");
        vesting = IVesting(_vesting);
    }

    /**
     * @dev Creates new pool for staking.
     * @param _allocPoint Allocation points of new pool.
     * @param _token Address of pool token.
     * @param _withUpdate Declare if it needed to update all other pools
     */
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate
    ) external onlyOwner {
        require(!started, "Staking is running");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accSheeshaPerShare: 0
            })
        );
        started = true;
    }

    /**
     * @dev Updates allocation points of chosen pool
     * @param _pid Pool's unique ID.
     * @param _allocPoint Desired allocation points of new pool.
     * @param _withUpdate Declare if it needed to update all other pools
     */
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /**
     * @dev Add rewards for Sheesha staking
     * @param _amount Amount of rewards to be added.
     */
    function addRewards(uint256 _amount) external {
        require(_amount > 0, "Invalid amount");
        IERC20(sheesha).safeTransferFrom(msg.sender, address(this), _amount);
        tokenRewards = tokenRewards.add(_amount);
    }

    /**
     * @dev Deposits tokens by user to staking contract.
     * @notice User first need to approve deposited amount of tokens
     * @notice If User has some pending rewards they would be transfered to his wallet
     * @param _pid Pool's unique ID.
     * @param _amount The amount to deposit.
     */
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        _deposit(msg.sender, _pid, _amount);
    }

    /**
     * @dev Deposits tokens for specific user in staking contract.
     * @notice Caller of method first need to approve deposited amount of tokens
     * @notice If User has some pending rewards they would be transfered to his wallet
     * @param _depositFor Address of user for which deposit is created
     * @param _pid Pool's unique ID.
     * @param _amount The amount to deposit.
     */
    function depositFor(
        address _depositFor,
        uint256 _pid,
        uint256 _amount
    ) external override nonReentrant {
        _deposit(_depositFor, _pid, _amount);
    }

    /**
     * @dev Withdraws tokens from staking.
     * @notice Check available amount of tokens from vesting.
     * @notice If amount to withdraw greater than user personal stake
     * takes available amount from vesting to cover difference and updates
     * user info on vesting contract.
     * @notice If User has some pending rewards they would be transfered to his wallet
     * @notice This would take 2% fee which will be burnt for each withdraw.
     * @notice No fee for pending rewards.
     * @param _pid Pool's unique ID.
     * @param _amount The amount to withdraw.
     */
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        (uint256 aLeftover, uint256 unlockedAmount) = vesting
            .calculateAvailableAmountForStaking(msg.sender);
        uint256 userStakeAmount = (user.amount).sub(aLeftover);
        uint256 userAvailableAmount = userStakeAmount.add(unlockedAmount);
        require(userAvailableAmount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user
            .amount
            .mul(pool.accSheeshaPerShare)
            .div(PERCENTAGE_DIVIDER)
            .sub(user.rewardDebt);
        if (pending > 0) {
            safeSheeshaTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            if (userStakeAmount < _amount) {
                uint256 vestingAmount = _amount.sub(userStakeAmount);
                vesting.withdrawFromStaking(msg.sender, vestingAmount);
            }
            user.amount = user.amount.sub(_amount);
            uint256 burnAmount = _amount.mul(2).div(100);
            sheesha.burn(burnAmount);
            pool.token.safeTransfer(msg.sender, _amount.sub(burnAmount));
        }
        user.rewardDebt = user.amount.mul(pool.accSheeshaPerShare).div(
            PERCENTAGE_DIVIDER
        );
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
     * @dev Withdraws all user available amount of tokens without caring about rewards.
     * @notice Withdraw all available amount from vesting and all personal user stakes
     * @notice This would take 2% fee which will be burnt.
     * @param _pid Pool's unique ID.
     */
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        (uint256 aLeftover, uint256 unlockedAmount) = vesting
            .calculateAvailableAmountForStaking(msg.sender);
        if (unlockedAmount > 0) {
            vesting.withdrawFromStaking(msg.sender, unlockedAmount);
        }
        uint256 userStakeAmount = (user.amount).sub(aLeftover);
        uint256 userAvailableAmount = userStakeAmount.add(unlockedAmount);
        uint256 burnAmount = userAvailableAmount.mul(2).div(100);
        uint256 updatedAmount = (user.amount).sub(userAvailableAmount);
        user.amount = updatedAmount;
        sheesha.burn(burnAmount);
        pool.token.safeTransfer(
            msg.sender,
            userAvailableAmount.sub(burnAmount)
        );
        user.rewardDebt = user.amount.mul(pool.accSheeshaPerShare).div(
            PERCENTAGE_DIVIDER
        );
        emit EmergencyWithdraw(msg.sender, _pid, userAvailableAmount);
    }

    /**
     * @dev Used to display user pending rewards on FE
     * @param _pid Pool's unique ID.
     * @param _user Address of user for which dosplay rewards.
     * @return Amount of rewards available
     */
    function pendingSheesha(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSheeshaPerShare = pool.accSheeshaPerShare;
        uint256 tokenSupply;
        if (pool.token.balanceOf(address(this)) >= tokenRewards) {
            tokenSupply = pool.token.balanceOf(address(this)).sub(tokenRewards);
        }
        if (block.number > pool.lastRewardBlock && tokenSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 sheeshaReward = multiplier
                .mul(sheeshaPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accSheeshaPerShare = accSheeshaPerShare.add(
                sheeshaReward.mul(PERCENTAGE_DIVIDER).div(tokenSupply)
            );
        }
        return
            user.amount.mul(accSheeshaPerShare).div(PERCENTAGE_DIVIDER).sub(
                user.rewardDebt
            );
    }

    /**
     * @dev Checks amounts of pools
     * @return Number of pools available
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @dev Updates all available pools accumulated Sheesha per share and last reward block
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;

        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @dev Updates chosen pool accumulated Sheesha per share and last reward block
     */
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 tokenSupply;
        if (pool.token.balanceOf(address(this)) >= tokenRewards) {
            tokenSupply = pool.token.balanceOf(address(this)).sub(tokenRewards);
        }
        if (tokenSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 sheeshaReward = multiplier
            .mul(sheeshaPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        if (sheeshaReward > tokenRewards) {
            sheeshaReward = tokenRewards;
        }
        tokenRewards = tokenRewards.sub(sheeshaReward);
        pool.accSheeshaPerShare = pool.accSheeshaPerShare.add(
            sheeshaReward.mul(PERCENTAGE_DIVIDER).div(tokenSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    /**
     * @dev Returns multiplier according to last reward block and current block
     * @param _from Last reward block
     * @param _to Current block number
     * @return Multiplier according to _from and _to value
     */
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to.sub(_from);
    }

    /**
     * @dev Checks if user was participating in staking
     * @param _who Address of user.
     * @return If user participate in staking
     */
    function isUserExisting(address _who) public view returns (bool) {
        return isExisting[_who];
    }

    /**
     * @dev Internal function is equivalent to deposit(address of _depositFor would be msg.sender)
     * and depositFor(address of user for which deposit is created)
     * @param _depositFor Address of user for which deposit is created
     * @param _pid Pool's unique ID.
     * @param _amount The amount to deposit.
     */
    function _deposit(
        address _depositFor,
        uint256 _pid,
        uint256 _amount
    ) internal {
        if (!isUserExisting(_depositFor)) {
            userList[userCount] = _depositFor;
            userCount++;
            isExisting[_depositFor] = true;
        }
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_depositFor];

        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accSheeshaPerShare)
                .div(PERCENTAGE_DIVIDER)
                .sub(user.rewardDebt);
            if (pending > 0) {
                safeSheeshaTransfer(msg.sender, pending);
            }
        }

        if (_amount > 0) {
            pool.token.safeTransferFrom(msg.sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
        }

        user.rewardDebt = user.amount.mul(pool.accSheeshaPerShare).div(
            PERCENTAGE_DIVIDER
        );
        emit Deposit(_depositFor, _pid, _amount);
    }

    /**
     * @dev Internal function is used for safe transfer of pending rewards
     * @notice If reward amount is greater than contract balance - sends contract balance
     * @param _to Address of rewards receiver.
     * @param _amount Amount of rewards.
     */
    function safeSheeshaTransfer(address _to, uint256 _amount) internal {
        uint256 sheeshaBal = sheesha.balanceOf(address(this));
        if (_amount > sheeshaBal) {
            sheesha.safeTransfer(_to, sheeshaBal);
        } else {
            sheesha.safeTransfer(_to, _amount);
        }
    }
}