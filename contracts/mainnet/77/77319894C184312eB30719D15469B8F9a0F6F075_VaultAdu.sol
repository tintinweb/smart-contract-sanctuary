// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./OwnableUpgradeSafe.sol";
import "./IERC20.sol";

// Vault distributing fixed per-block reward of ERC20 token equally amongst staked pools
contract VaultAdu is OwnableUpgradeSafe {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many  tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ADUs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws  tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.

    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. ADUs to distribute per block.
        uint256 accRewardPerShare; // Accumulated token underlying units per share, times 1e12. See below.
        uint256 lastRewardBlock;
    }

    // A reward token
    IERC20 public rewardToken;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes  tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    uint256 public contractStartBlock;
    uint256 public epochCalculationStartBlock;
    uint256 public cumulativeRewardsSinceStart;
    uint256 public rewardsInThisEpoch;
    uint public epoch;

    uint256 public rewardPerBlock;

    // Returns average rewards generated since start of this contract
    function averageRewardPerBlockSinceStart() external view returns (uint averagePerBlock) {
        averagePerBlock = cumulativeRewardsSinceStart.add(rewardsInThisEpoch).div(block.number.sub(contractStartBlock));
    }        

    // Returns averge reward in this epoch
    function averageRewardPerBlockEpoch() external view returns (uint256 averagePerBlock) {
        averagePerBlock = rewardsInThisEpoch.div(block.number.sub(epochCalculationStartBlock));
    }

    // For easy graphing historical epoch rewards
    mapping(uint => uint256) public epochRewards;

    // Starts a new calculation epoch
    // Because averge since start will not be accurate
    function startNewEpoch() public {
        require(epochCalculationStartBlock + 50000 < block.number, "New epoch not ready yet"); // About a week
        epochRewards[epoch] = rewardsInThisEpoch;
        cumulativeRewardsSinceStart = cumulativeRewardsSinceStart.add(rewardsInThisEpoch);
        rewardsInThisEpoch = 0;
        epochCalculationStartBlock = block.number;
        ++epoch;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event LogUpdatePool(uint256 indexed pid, uint256 lastRewardBlock, uint256 lpSupply, uint256 accRewardPerShare);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event MigrationWithdraw(address indexed user, address indexed newVault, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);

    function initialize(
        IERC20 _rewardToken,
        uint256 _rewardPerBlock
    ) public initializer {
        OwnableUpgradeSafe.__Ownable_init();
        rewardToken = _rewardToken;
        contractStartBlock = block.number;
        epochCalculationStartBlock = block.number;
        rewardPerBlock = _rewardPerBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new token pool. Can only be called by the owner. 
    // Note contract owner is meant to be a governance contract allowing ADU governance consensus
    function add(uint256 _allocPoint, IERC20 _token) public onlyOwner {
        uint256 length = poolInfo.length;
        uint256 lastRewardBlock = block.number;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token,"Error pool already added");
        }
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                accRewardPerShare: 0,
                lastRewardBlock : lastRewardBlock
            })
        );
    }

    // Update the given pool's ADUs allocation point. Can only be called by the owner.
    // Note contract owner is meant to be a governance contract allowing ADU governance consensus
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // View function to see pending reward tokens on frontend.
    function pendingToken(uint256 _pid, address _user) public view returns (uint256 pending) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        pending = user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt); // return calculated pending reward
    }

    // View function to see pending reward tokens on frontend.
    function pendingTokenActual(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        if (block.number > pool.lastRewardBlock) {
            uint256 lpSupply = pool.token.balanceOf(address(this));
            if (lpSupply > 0) { // avoids division by 0 errors
                uint256 blocks = block.number.sub(pool.lastRewardBlock);
                uint256 aduReward = blocks.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint); // eg. 4blocks * 1e20 * 100allocPoint / 100totalAllocPoint
                //add only diff from last calculation
                accRewardPerShare = pool.accRewardPerShare.add((aduReward.mul(1e12).div(lpSupply)));
            }
        }

        return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt); // return calculated pending reward
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[_pid];

        if (block.number > pool.lastRewardBlock) {
            uint256 lpSupply = pool.token.balanceOf(address(this));
            if (lpSupply > 0) { // avoids division by 0 errors
                uint256 blocks = block.number.sub(pool.lastRewardBlock);
                uint256 aduReward = blocks.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint); // eg. 4blocks * 1e20 * 100allocPoint / 100totalAllocPoint
                pool.accRewardPerShare = pool.accRewardPerShare.add((aduReward.mul(1e12).div(lpSupply)));
            }
            pool.lastRewardBlock = block.number;
            poolInfo[_pid] = pool;
            emit LogUpdatePool(_pid, pool.lastRewardBlock, lpSupply, pool.accRewardPerShare);
        }
    }

    // Deposit LP tokens to Vault for ADU allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        depositFor(_pid, _amount, msg.sender);
    }

    // Deposit LP tokens to Vault for ADU allocation.
    function depositFor(uint256 _pid, uint256 _amount, address _to) public {
        // requires no allowances
        PoolInfo memory pool = updatePool(_pid);
        UserInfo storage user = userInfo[_pid][_to];

        massUpdatePools();
        updateAndPayOutPending(_pid, _to);

        if (_amount > 0) {
            pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount, _to);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        withdrawTo(_pid, _amount, msg.sender);
    }

    function withdrawTo(uint256 _pid, uint256 _amount, address _to) public {
        PoolInfo memory pool = updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];

        massUpdatePools();
        updateAndPayOutPending(_pid, msg.sender);

        if (_amount > 0) {
            pool.token.safeTransfer(_to, _amount);
            user.amount = user.amount.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount, _to);
    }

    function updateAndPayOutPending(uint256 _pid, address _to) internal {
        uint256 pending = pendingToken(_pid, _to);
        if (pending > 0) {
            safeRewardTokenTransfer(_to, pending);
        }
    }

    function harvest(uint256 _pid) public returns (bool success) {
        return harvestTo(_pid, msg.sender);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _to Receiver of ADU rewards.
    /// @return success Returns bool indicating success of rewarder delegate call.
    function harvestTo(uint256 _pid, address _to) public returns (bool success) {
        uint256 _pendingToken = pendingToken(_pid, _to);
        withdrawTo(_pid, 0, _to);
        emit Harvest(msg.sender, _pid, _pendingToken);
        return true;
    }

     // Safe ADU transfer function, just in case if there is no more ADU left.
    function safeRewardTokenTransfer(address _to, uint256 _amount) internal {
        uint256 aduBalance = rewardToken.balanceOf(address(this));
        if (aduBalance > 0){
            if (_amount > aduBalance) {
                rewardToken.transfer(_to, aduBalance);
            } else {
                rewardToken.transfer(_to, _amount);
            }
        }
    }

    function migrateTokensToNewVault(address _newVault) public virtual onlyOwner {
        require(_newVault != address(0), "Vault: new vault is the zero address");
        uint256 rewardTokenBalErc = rewardToken.balanceOf(address(this));
        safeRewardTokenTransfer(_newVault, rewardTokenBalErc);
        emit MigrationWithdraw(msg.sender, _newVault, rewardTokenBalErc);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _to Receiver of the LP tokens.
    function emergencyWithdraw(uint256 _pid, address _to) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        // Note: transfer can fail or succeed if `amount` is zero.
        if (amount > 0) {
            pool.token.safeTransfer(_to, amount);
            user.amount = 0;
            user.rewardDebt = 0;
        }
        emit EmergencyWithdraw(msg.sender, _pid, amount, _to);
    }

    // Function that lets owner/governance contract approve
    // allowance for any 3rd party token inside this contract.
    // This means all future UNI like airdrops are covered.
    // And at the same time allows us to give allowance to strategy contracts.
    function setStrategyContractOrDistributionContractAllowance(address tokenAddress, uint256 _amount, address contractAddress) public onlyOwner {
        require(isContract(contractAddress), "Recipent is not a smart contract");
        require(tokenAddress != address(rewardToken), "Vault token allowance not allowed");
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            require(tokenAddress != address(poolInfo[pid].token), "Vault pool token allowance not allowed");
        }

        IERC20(tokenAddress).approve(contractAddress, _amount);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}