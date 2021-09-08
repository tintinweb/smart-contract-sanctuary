// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.8.7;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./Owner.sol";
import "./ReentrancyGuard.sol";

contract MasterChef is Owner, ReentrancyGuard {
    using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardLockedUp; // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        //
        // We do some fancy math here. Basically, any point in time, the amount of tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.acctokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `acctokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address lptoken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that tokens distribution occurs.
        uint256 acctokenPerShare; // Accumulated tokens per share, times 1e12. See below.
        uint256 depositFeeBP; // Deposit fee in basis points
        uint256 harvestInterval; // Harvest interval in seconds
        uint256 lpSupply; // To determine more precisely the deposits and avoid the dilution of rewards
    }

    // The token!
    IERC20 public immutable TOKEN;
    // Dev address.
    address public devAddress;
    // Deposit Fee address.
    address public feeAddress;
    // tokens created per block.
    uint256 public tokenPerBlock;
    // Bonus muliplier for early token makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Max harvest interval
    uint256 public immutable MAXIMUM_HARVEST_INTERVAL;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when token mining starts.
    uint256 public immutable startBlock;
    // Total locked up rewards
    uint256 public totalLockedUpRewards;

    // Max deposit fee: 400 = 4%
    uint256 public immutable MAXIMUM_DEPOSIT_FEE;

    // Fee to DEV : 100 = 10%
    uint256 public immutable DEV_FEE;

    address public immutable InformationalFeeContract;

    // Define if MasterChef can mint the token
    bool public immutable isInfinite;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event EmissionRateUpdated(uint256 previousAmount, uint256 newAmount);
    event ReferralCommissionPaid(
        address indexed user,
        address indexed referrer,
        uint256 commissionAmount
    );
    event RewardLockedUp(
        address indexed user,
        uint256 indexed pid,
        uint256 amountLockedUp
    );
    event AddPool(
        uint256 indexed pid,
        uint256 allocPoint,
        address lptokenAddress,
        uint256 depositFeeBP,
        uint256 harvestInterval,
        uint256 lastRewardBlock
    );
    event SetPool(
        uint256 indexed pid,
        uint256 allocPoint,
        uint256 depositFeeBP,
        uint256 harvestInterval
    );
    event SetDevAddress(address previousDevAddress, address newDevAddress);
    event SetFeeAddress(address previousFeeAddress, address newFeeAddress);
    event SetReferralCommissionRate(
        uint256 previousReferralCommissionRate,
        uint256 newReferralCommissionRate
    );
    event SettokenReferral(
        address previoustokenReferral,
        address newtokenReferral
    );

    constructor(
        address _token,
        //uint256 [_startBlock, _tokenPerBlock, _MAXIMUM_HARVEST_INTERVAL, _MAXIMUM_DEPOSIT_FEE, _DEV_FEE]
        uint256[5] memory _MasterChefValues,
        address _InformationalFeeContract,
        bool _isInfinite
    ) {
        TOKEN = IERC20(_token);
        startBlock = _MasterChefValues[0];
        tokenPerBlock = _MasterChefValues[1];
        MAXIMUM_HARVEST_INTERVAL = _MasterChefValues[2];
        MAXIMUM_DEPOSIT_FEE = _MasterChefValues[3];

        DEV_FEE = _MasterChefValues[4];

        InformationalFeeContract = _InformationalFeeContract;

        isInfinite = _isInfinite;

        devAddress = msg.sender;
        feeAddress = msg.sender;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        address _lptoken,
        uint256 _depositFeeBP,
        uint256 _harvestInterval,
        bool _withUpdate
    ) external isOwner {
        require(
            _depositFeeBP <= MAXIMUM_DEPOSIT_FEE,
            "add: invalid deposit fee basis points"
        );
        require(
            _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "add: invalid harvest interval"
        );

        // Test line to ensure the function will fail if the token doesn't exist
        IERC20(_lptoken).balanceOf(address(this));

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lptoken: _lptoken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                acctokenPerShare: 0,
                depositFeeBP: _depositFeeBP,
                harvestInterval: _harvestInterval,
                lpSupply: 0
            })
        );
        uint256 pid = poolInfo.length.sub(1);
        emit AddPool(
            pid,
            _allocPoint,
            _lptoken,
            _depositFeeBP,
            _harvestInterval,
            lastRewardBlock
        );
    }

    // Update the given pool's token allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _depositFeeBP,
        uint256 _harvestInterval,
        bool _withUpdate
    ) external isOwner {
        require(
            _depositFeeBP <= MAXIMUM_DEPOSIT_FEE,
            "set: invalid deposit fee basis points"
        );
        require(
            _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "set: invalid harvest interval"
        );

        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;
        emit SetPool(_pid, _allocPoint, _depositFeeBP, _harvestInterval);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending tokens on frontend.
    function pendingtoken(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 acctokenPerShare = pool.acctokenPerShare;
        if (block.number > pool.lastRewardBlock && pool.lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 tokenReward = multiplier
                .mul(tokenPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            acctokenPerShare = acctokenPerShare.add(
                tokenReward.mul(1e12).div(pool.lpSupply)
            );
        }
        uint256 pending = user.amount.mul(acctokenPerShare).div(1e12).sub(
            user.rewardDebt
        );
        return pending.add(user.rewardLockedUp);
    }

    // View function to see if user can harvest tokens.
    function canHarvest(uint256 _pid, address _user)
        public
        view
        returns (bool)
    {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier
            .mul(tokenPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        if (isInfinite) {
            TOKEN.mint(address(this), tokenReward);
            TOKEN.mint(devAddress, tokenReward.mul(DEV_FEE).div(1000));
        } else {
            TransferHelper.safeTransfer(
                address(TOKEN),
                devAddress,
                tokenReward.mul(DEV_FEE.sub(5)).div(1000)
            );

            TransferHelper.safeTransfer(
                address(TOKEN),
                InformationalFeeContract,
                tokenReward.mul(5).div(1000)
            );
        }
        pool.acctokenPerShare = pool.acctokenPerShare.add(
            tokenReward.mul(1e12).div(pool.lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables of the given pool to be up-to-date (external version w/ non-reentrancy)
    function updatePool(uint256 _pid) external nonReentrant {
        _updatePool(_pid);
    }

    // Deposit LP tokens to MasterChef for token allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        if (!isInfinite && TOKEN.balanceOf(address(this)) == 0) {
            revert("Distribution is over");
        }

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        _updatePool(_pid);

        _payOrLockupPendingtoken(_pid);
        if (_amount > 0) {
            // To handle correctly the transfer tax tokens w/ the pools
            uint256 balanceBefore = IERC20(pool.lptoken).balanceOf(
                address(this)
            );
            TransferHelper.safeTransferFrom(
                pool.lptoken,
                msg.sender,
                address(this),
                _amount
            );
            _amount = IERC20(pool.lptoken).balanceOf(address(this)).sub(
                balanceBefore
            );

            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                TransferHelper.safeTransfer(
                    pool.lptoken,
                    feeAddress,
                    depositFee
                );
                user.amount = user.amount.add(_amount).sub(depositFee);
                pool.lpSupply = pool.lpSupply.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
                pool.lpSupply = pool.lpSupply.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.acctokenPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        _updatePool(_pid);
        _payOrLockupPendingtoken(_pid);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            TransferHelper.safeTransfer(pool.lptoken, msg.sender, _amount);
            pool.lpSupply = pool.lpSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.acctokenPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        pool.lpSupply = pool.lpSupply.sub(user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        TransferHelper.safeTransfer(pool.lptoken, msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay or lockup pending tokens.
    function _payOrLockupPendingtoken(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }

        uint256 pending = user.amount.mul(pool.acctokenPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(
                    user.rewardLockedUp
                );
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(
                    pool.harvestInterval
                );

                // send rewards
                _safetokenTransfer(msg.sender, totalRewards);
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough tokens.
    function _safetokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = TOKEN.balanceOf(address(this));

        if (_amount > tokenBal) {
            if (!isInfinite && tokenPerBlock != 0) {
                _updateEmissionRate(0);
            }
            TransferHelper.safeTransfer(address(TOKEN), _to, tokenBal);
        } else {
            TransferHelper.safeTransfer(address(TOKEN), _to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devAddress) external {
        require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
        require(_devAddress != address(0), "setDevAddress: ZERO");

        address previousDevAddress = devAddress;
        devAddress = _devAddress;
        emit SetDevAddress(previousDevAddress, devAddress);
    }

    function setFeeAddress(address _feeAddress) external {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");

        address previousFeeAddress = feeAddress;
        feeAddress = _feeAddress;
        emit SetFeeAddress(previousFeeAddress, feeAddress);
    }

    // Pancake has to add hidden dummy pools in order to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _tokenPerBlock) external isOwner {
        _updateEmissionRate(_tokenPerBlock);
    }

    function _updateEmissionRate(uint256 _tokenPerBlock) internal {
        massUpdatePools();
        uint256 previoustokenPerBlock = tokenPerBlock;
        tokenPerBlock = _tokenPerBlock;
        emit EmissionRateUpdated(previoustokenPerBlock, tokenPerBlock);
    }
}