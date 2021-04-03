// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeSafe.sol";
import "./IXAUToken.sol";
import "./IERC20.sol";

// Vault distributing incoming elastic token rewards equally amongst staked pools
contract Vault is OwnableUpgradeSafe {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many  tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below. // elastic, in token underlying units
        //
        // We do some fancy math here. Basically, any point in time, the amount of reward tokens
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
        IERC20 token; // Address of  token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Reward tokens to distribute per block.
        uint256 accRewardPerShare; // Accumulated token underlying units per share, times 1e12. See below.
        bool withdrawable; // Is this pool withdrawable?
        mapping(address => mapping(address => uint256)) allowance;

    }

    // A reward token
    IXAUToken public rewardToken;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes  tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    //// pending rewards awaiting anyone to massUpdate
    uint256 public pendingRewards;  // elastic, in token underlying units

    uint256 public contractStartBlock;
    uint256 public epochCalculationStartBlock;
    uint256 public cumulativeRewardsSinceStart;  // elastic, in token underlying units
    uint256 public rewardsInThisEpoch;           // elastic, in token underlying units
    uint public epoch;

    // Dev address.
    address public devFeeReceiver;
    uint16 public devFeePercentX100;
    uint256 public pendingDevRewards;  // elastic, in token underlying units

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

    event NewDevFeeReceiver(address oldDevFeeReceiver, address newDevFeeReceiver);
    event NewDevFeePercentX100(uint256 oldDevFeePercentX100, uint256 newDevFeePercentX100);
    
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event MigrationWithdraw(
        address indexed user,
        address indexed newVault,
        uint256 amount
    );
    event Approval(address indexed owner, address indexed spender, uint256 _pid, uint256 value);

    function initialize(
        IXAUToken _rewardToken,
        address _devFeeReceiver, 
        uint16 _devFeePercentX100
    ) public initializer {
        OwnableUpgradeSafe.__Ownable_init();
        devFeePercentX100 = _devFeePercentX100;
        rewardToken = _rewardToken;
        devFeeReceiver = _devFeeReceiver;
        contractStartBlock = block.number;
        epochCalculationStartBlock = block.number;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new token pool. Can only be called by the owner. 
    // Note contract owner is meant to be a governance contract allowing reward token governance consensus
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate,
        bool _withdrawable
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "Error pool already added");
        }

        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                accRewardPerShare: 0,
                withdrawable: _withdrawable
            })
        );
    }

    // Update the given pool's reward tokens allocation point. Can only be called by the owner.
    // Note contract owner is meant to be a governance contract allowing reward token governance consensus
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Update the given pool's ability to withdraw tokens
    // Note contract owner is meant to be a governance contract allowing reward token governance consensus
    function setPoolWithdrawable(
        uint256 _pid,
        bool _withdrawable
    ) public onlyOwner {
        poolInfo[_pid].withdrawable = _withdrawable;
    }

    // Sets the dev fee for this contract
    // Note contract owner is meant to be a governance contract allowing reward token governance consensus
    function setDevFeePercentX100(uint16 _devFeePercentX100) public onlyOwner {
        require(_devFeePercentX100 <= 1000, 'Dev fee clamped at 10%');
        uint256 oldDevFeePercentX100 = devFeePercentX100;
        devFeePercentX100 = _devFeePercentX100;
        emit NewDevFeePercentX100(oldDevFeePercentX100, _devFeePercentX100);
    }

    // Update dev address by the previous dev.
    // Note onlyOwner functions are meant for the governance contract
    // allowing reward token governance token holders to do this functions.
    function setDevFeeReceiver(address _devFeeReceiver) public onlyOwner {
        address oldDevFeeReceiver = devFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
        emit NewDevFeeReceiver(oldDevFeeReceiver, _devFeeReceiver);
    }

    // View function to see pending reward tokens on frontend.
    function pendingToken(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        
        return rewardToken.fromUnderlying(user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt));
    }

    // View function to see pending reward tokens on frontend.
    function pendingTokenActual(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) { // avoids division by 0 errors
            return 0;
        }
        uint256 rewardWhole = pendingRewards // Multiplies pending rewards by allocation point of this pool and then total allocation
            .mul(pool.allocPoint)        // getting the percent of total pending rewards this pool should get
            .div(totalAllocPoint);       // we can do this because pools are only mass updated
        uint256 rewardFee = rewardWhole.mul(devFeePercentX100).div(10000);
        uint256 rewardToDistribute = rewardWhole.sub(rewardFee);
        uint256 accRewardPerShare = pool.accRewardPerShare.add(rewardToDistribute.mul(1e12).div(tokenSupply));

        return rewardToken.fromUnderlying(user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt));
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        uint allRewards;
        for (uint256 pid = 0; pid < length; ++pid) {
            allRewards = allRewards.add(updatePool(pid));
        }

        pendingRewards = pendingRewards.sub(allRewards);
    }

    // Function that adds pending rewards, called by the reward token.
    uint256 private rewardTokenBalance;
    function addPendingRewards(uint256 /* _ */) public {
        uint256 newRewards = rewardToken.balanceOfUnderlying(address(this)).sub(rewardTokenBalance);  // elastic
        
        if (newRewards > 0) {
            rewardTokenBalance = rewardToken.balanceOfUnderlying(address(this)); // If there is no change the balance didn't change  // elastic
            pendingRewards = pendingRewards.add(newRewards);
            rewardsInThisEpoch = rewardsInThisEpoch.add(newRewards);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) internal returns (uint256 rewardWhole) {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) { // avoids division by 0 errors
            return 0;
        }
        rewardWhole = pendingRewards // Multiplies pending rewards by allocation point of this pool and then total allocation
            .mul(pool.allocPoint)        // getting the percent of total pending rewards this pool should get
            .div(totalAllocPoint);       // we can do this because pools are only mass updated
        uint256 rewardFee = rewardWhole.mul(devFeePercentX100).div(10000);
        uint256 rewardToDistribute = rewardWhole.sub(rewardFee);

        pendingDevRewards = pendingDevRewards.add(rewardFee);

        pool.accRewardPerShare = pool.accRewardPerShare.add(
            rewardToDistribute.mul(1e12).div(tokenSupply)
        );
    }

    // Deposit user tokens to vault for reward token allocation.
    function deposit(uint256 _pid, uint256 _amount) public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        massUpdatePools();
        
        // Transfer pending tokens
        // to user
        updateAndPayOutPending(_pid, msg.sender); // https://kovan.etherscan.io/tx/0xbd6a42d7ca389be178a2e825b7a242d60189abcfbea3e4276598c0bb28c143c9 // TODO: INVESTIGATE



        // Transfer in the amounts from user
        // save gas
        if (_amount > 0) {
            pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }

        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Test coverage
    // [x] Does user get the deposited amounts?
    // [x] Does user that its deposited for update correcty?
    // [x] Does the depositor get their tokens decreased
    function depositFor(address _depositFor, uint256 _pid, uint256 _amount) public {
        // requires no allowances
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_depositFor];

        massUpdatePools();
        
        // Transfer pending tokens
        // to user
        updateAndPayOutPending(_pid, _depositFor);  // Update the balances of person that amount is being deposited for

        if (_amount > 0) {
            pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);  // This is depositedFor address
        }

        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);  /// This is deposited for address
        emit Deposit(_depositFor, _pid, _amount);
    }

    // Test coverage
    // [x] Does allowance update correctly?
    function setAllowanceForPoolToken(address spender, uint256 _pid, uint256 value) public {
        PoolInfo storage pool = poolInfo[_pid];
        pool.allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, _pid, value);
    }

    // Test coverage
    // [x] Does allowance decrease?
    // [x] Do oyu need allowance
    // [x] Withdraws to correct address
    function withdrawFrom(address owner, uint256 _pid, uint256 _amount) public {
        
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.allowance[owner][msg.sender] >= _amount, "withdraw: insufficient allowance");
        pool.allowance[owner][msg.sender] = pool.allowance[owner][msg.sender].sub(_amount);
        _withdraw(_pid, _amount, owner, msg.sender);

    }
    
    // Withdraw user tokens from vault
    function withdraw(uint256 _pid, uint256 _amount) public {

        _withdraw(_pid, _amount, msg.sender, msg.sender);

    }
    
    // Low level withdraw function
    function _withdraw(uint256 _pid, uint256 _amount, address from, address to) internal {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.withdrawable, "Withdrawing from this pool is disabled");
        UserInfo storage user = userInfo[_pid][from];
        require(user.amount >= _amount, "withdraw: not good");

        massUpdatePools();
        updateAndPayOutPending(_pid, from); // Update balances of from this is not withdrawal but claiming rewards farmed

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(address(to), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);

        emit Withdraw(to, _pid, _amount);
    }

    function updateAndPayOutPending(uint256 _pid, address from) internal {

        uint256 pending = pendingToken(_pid, from);

        if (pending > 0) {
            safeRewardTokenTransfer(from, pending);
        }
    }

    // Function that lets owner/governance contract approve
    // allowance for any 3rd party token inside this contract.
    // This means all future UNI like airdrops are covered.
    // And at the same time allows us to give allowance to strategy contracts.
    function setStrategyContractOrDistributionContractAllowance(address tokenAddress, uint256 _amount, address contractAddress) public onlyOwner {
        require(isContract(contractAddress), "Recipent is not a smart contract");
        require(tokenAddress != address(rewardToken), "Reward token allowance not allowed");
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            require(tokenAddress != address(poolInfo[pid].token), "Pool token allowance not allowed");
        }

        IERC20(tokenAddress).approve(contractAddress, _amount);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function migrateTokensToNewVault(address _newVault) public virtual onlyOwner {
        require(_newVault != address(0), "Vault: new vault is the zero address");
        uint256 rewardTokenBalErc = rewardToken.balanceOf(address(this));  // elastic
        safeRewardTokenTransfer(_newVault, rewardTokenBalErc);
        emit MigrationWithdraw(msg.sender, _newVault, rewardTokenBalErc);
        rewardTokenBalance = rewardToken.balanceOfUnderlying(address(this));
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    // !Caution this will remove all your pending rewards!
    function emergencyWithdraw(uint256 _pid, address _to) public {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.withdrawable, "Withdrawing from this pool is disabled");
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

    // Safe reward token transfer function, just in case if rounding error causes pool to not have enough reward tokens.
    function safeRewardTokenTransfer(address _to, uint256 _amount) internal {

        uint256 rewardTokenBalErc = rewardToken.balanceOf(address(this));  // elastic
        
        if (_amount > rewardTokenBalErc) {
            rewardToken.transfer(_to, rewardTokenBalErc);  // elastic
            rewardTokenBalance = rewardToken.balanceOfUnderlying(address(this));  // elastic

        } else {
            rewardToken.transfer(_to, _amount);  // elastic
            rewardTokenBalance = rewardToken.balanceOfUnderlying(address(this));  // elastic

        }
        //Avoids possible recursion loop
        // proxy?
        transferDevFee();

    }

    function transferDevFee() public {
        if (pendingDevRewards == 0) return;

        uint256 pendingDevRewardsErc = rewardToken.fromUnderlying(pendingDevRewards);
        uint256 rewardTokenBalErc = rewardToken.balanceOf(address(this));  // elastic
        
        if (pendingDevRewardsErc > rewardTokenBalErc) {

            rewardToken.transfer(devFeeReceiver, rewardTokenBalErc);  // elastic
            rewardTokenBalance = rewardToken.balanceOfUnderlying(address(this));  // elastic

        } else {

            rewardToken.transfer(devFeeReceiver, pendingDevRewardsErc);  // elastic
            rewardTokenBalance = rewardToken.balanceOfUnderlying(address(this));  // elastic

        }

        pendingDevRewards = 0;
    }

}