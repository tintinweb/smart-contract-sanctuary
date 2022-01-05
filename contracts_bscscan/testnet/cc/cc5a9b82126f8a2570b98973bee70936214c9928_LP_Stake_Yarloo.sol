// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract LP_Stake_Yarloo is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 poolBal;
        uint40 pool_deposit_time;
        uint256 total_deposits;
        uint256 pool_payouts;
        uint256 rewardEarned;
    }

    struct PoolInfo {
        IERC20 lpToken;
        IERC20 rewardToken;
        uint256 poolNumber;
        uint256 poolRewardPercent;
        uint256 poolDays;
        uint256 fullMaturityTime;
        uint256 poolLimit;
        uint256 poolStaked;
        bool active;
    }

    uint256 public tokenDecimal;
    uint256 public totalPools = 0;
    uint256 public totalStaked;

    uint256 public divisorDays = 1 days;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event TokenTransfer(address beneficiary, uint256 amount);
    event PoolTransfer(address beneficiary, uint256 amount);
    event RewardClaimed(address beneficiary, uint256 amount);

    mapping(address => uint256) public balances;

    constructor() {}

    /* Recieve Accidental BNB Transfers */
    receive() external payable {}

    function add(
        IERC20 _lpToken,
        IERC20 _rewardToken,
        uint256 _poolRewardPercent,
        uint256 _poolDays,
        uint256 _fullMaturityTime,
        uint256 _poolLimit
    ) external onlyOwner {
        require(
            isContract(address(_lpToken)),
            "Enter correct LP contract address"
        );
        require(
            isContract(address(_rewardToken)),
            "Enter correct Reward contract address"
        );
        require(
            _lpToken.decimals() == _rewardToken.decimals(),
            "Decimals should be equal"
        );

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                rewardToken: _rewardToken,
                poolNumber: totalPools,
                poolRewardPercent: _poolRewardPercent,
                poolDays: _poolDays,
                fullMaturityTime: _fullMaturityTime,
                poolLimit: _poolLimit * 10**_lpToken.decimals(),
                poolStaked: 0,
                active: true
            })
        );
        totalPools = totalPools + 1;
    }

    function poolActivation(uint256 _poolId, bool status) external onlyOwner {
        PoolInfo storage pool = poolInfo[_poolId];
        pool.active = status;
    }

    /* Stake Token Function */
    function stakePool(uint256 _poolId, uint256 _amount)
        external
        nonReentrant
        returns (bool)
    {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];
        require(pool.active, "Pool not Active");
        require(
            _amount <= IERC20(pool.lpToken).balanceOf(msg.sender),
            "Token Balance of user is less"
        );
        require(pool.poolLimit >= pool.poolStaked + _amount);
        require(user.poolBal == 0, "Already Staked in this Pool");

        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        pool.poolStaked += _amount;
        totalStaked += _amount;
        user.poolBal = _amount;
        user.total_deposits += _amount;
        user.pool_deposit_time = uint40(block.timestamp);
        emit PoolTransfer(msg.sender, _amount);
        return true;
    }

    /* Claims Principal Token and Rewards Collected */
    function claimPool(uint256 _poolId) external nonReentrant returns (bool) {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        require(
            user.poolBal > 0,
            "There is no deposit for this address in Pool"
        );
        uint256 calculatedRewards = rewardsCalculate(_poolId, msg.sender);

        uint256 amount = user.poolBal;
        uint256 totalReward = calculatedRewards;
        user.rewardEarned += totalReward;
        emit RewardClaimed(msg.sender, totalReward);
        uint256 principalLpBalance = user.poolBal;
        user.poolBal = 0;
        user.pool_deposit_time = 0;
        user.pool_payouts += amount;

        pool.lpToken.safeTransfer(
            address(msg.sender),
            principalLpBalance
        );
        pool.rewardToken.safeTransfer(
            address(msg.sender),
            calculatedRewards
        );

        emit TokenTransfer(msg.sender, amount);
        return true;
    }

    function calculateRewards(
        uint256 _poolId,
        uint256 _amount,
        address userAdd
    ) internal view returns (uint256) {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][userAdd];
        return
            (((_amount * pool.poolRewardPercent) / 100) / 360) *
            ((block.timestamp - user.pool_deposit_time) / 1 seconds);
    }

    function rewardsCalculate(uint256 _poolId, address userAddress)
        public
        view
        returns (uint256)
    {
        uint256 rewards;
        UserInfo storage user = userInfo[_poolId][userAddress];

        uint256 max_payout = this.maxPayoutOf(_poolId, user.poolBal);
        uint256 calculatedRewards = calculateRewards(
            _poolId,
            user.poolBal,
            userAddress
        );
        if (user.poolBal > 0) {
            if (calculatedRewards > max_payout) {
                rewards = max_payout;
            } else {
                rewards = calculatedRewards;
            }
        }
        return rewards;
    }

    function maxPayoutOf(uint256 _poolId, uint256 _amount)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_poolId];
        return
            (((_amount * pool.poolRewardPercent) / 100) / 360) * pool.poolDays;
    }

    /* Check Token Balance inside Contract */
    function tokenBalance(address tokenAddr) public view returns (uint256) {
        return IERC20(tokenAddr).balanceOf(address(this));
    }

    /* Check BSC Balance inside Contract */
    function bnbBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function retrieveBnbStuck(address payable wallet)
        public
        nonReentrant
        onlyOwner
        returns (bool)
    {
        wallet.transfer(address(this).balance);
        return true;
    }

    function retrieveBEP20TokenStuck(
        address _tokenAddr,
        uint256 amount,
        address toWallet
    ) public nonReentrant onlyOwner returns (bool) {
        IERC20(_tokenAddr).transfer(toWallet, amount);
        return true;
    }

    /* Maturity Date */
    function maturityDate(uint256 _poolId, address userAdd)
        public
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_poolId][userAdd];
        PoolInfo storage pool = poolInfo[_poolId];

        return (user.pool_deposit_time + pool.fullMaturityTime);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}