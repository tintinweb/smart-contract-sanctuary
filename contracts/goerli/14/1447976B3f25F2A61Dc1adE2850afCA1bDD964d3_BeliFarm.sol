// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./helpers/ERC20.sol";
import "./libraries/Address.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/EnumerableSet.sol";
import "./helpers/Ownable.sol";
import "./helpers/ReentrancyGuard.sol";
import "./interfaces/IVault.sol";
import "./interfaces/ILocker.sol";
import "./interfaces/IReferral.sol";
import "./interfaces/IFeeReceiver.sol";

abstract contract BToken is ERC20 {
    function mint(address _to, uint256 _amount) public virtual;
}

contract BeliFarm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 shares; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardFeeReceiverDebt;
        uint256 rewardEarnDebt;
        uint256 lockedReward;
        uint256 lockedUntil;
        uint256 withdrawalFeeUntil;
        // BELI distribution
        // amount = user.shares / sharesTotal * wantLockedTotal
        // pending reward = (amount * pool.accBELIPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws want tokens to a pool. Here's what happens:
        //   1. The pool's `accBELIPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    struct PoolInfo {
        IERC20 want; // Address of the want token.
        uint256 allocPoint; // How many allocation points assigned to this pool. BELI to distribute per block.
        uint256 lastRewardBlock; // Last block number that BELI distribution occurs.
        uint256 accBELIPerShare; // Accumulated BELI per share, times 1e12. See below.
        address vault; // Vault address that will compound want tokens
        uint256 harvestInterval; // the time user has to wait until they can harvest
        uint256 harvestFeeInterval; // the time user have to wait until they can withdraw without fee
        uint16 harvestFee;
        bool isLpReward; // BELI LP reward
        bool isFeeReceiverReward;
        uint256 accBELIPerShareFromFees; // can be either Beli reward from lpFeeReceiver or feeReceiver
        uint256 lastAccBELIFromFees; // can be either transfer fee reward/LP reward
    }

    uint16 public constant MAX_RATE = 10000; // for locker, harvest fee and commission, read as 100.00%

    IFeeReceiver public feeLpReceiver;
    IFeeReceiver public feeReceiver;
    uint256 public accBeliFromFees;
    uint256 public accBeliLPFromFees;
    uint256 public accWithdrawnBeliFromFees;
    uint256 public accWithdrawnBeliLPRewardFromFees;
    uint256 public lastUpdateBeliFeesBlock;
    uint256 public lastUpdateBeliFeesLPBlock;
    ILocker public locker;
    address public BELI;
    uint16 public lockerRate;
    mapping(address => bool) public vaultExists;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 public constant ownerBELIReward = 138;

    uint256 public constant BELIMaxSupply = 25000000e18; // 25M
    uint256 public BELIPerBlock = 214e16; // BELI tokens created per block, 2.14
    uint256 public constant BELI_PER_BLOCK_UPPER_LIMIT = 10e18;
    uint256 public constant BELI_PER_BLOCK_THRESHOLD = 5e17; // 0.5
    uint256 public startBlock = 13488888;

    IReferral public referral;
    uint16 public referralCommissionRate = 100;
    uint16 public constant HARVEST_FEE_UPPER_LIMIT = 4000; // 40%
    uint256 public constant HARVEST_INTERVAL_UPPER_LIMIT = 86400; // 24 hour
    uint16 public constant REFERRAL_COMMISSION_UPPER_LIMIT = 1000; // 10%

    PoolInfo[] public poolInfo; // Info of each pool.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // Info of each user that stakes LP tokens.
    uint256 public totalAllocPoint = 0; // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalFeeRewardAllocPoint = 0;
    uint256 public totalLpRewardAllocPoint = 0;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdrawEarly(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 newAmount);
    event AllocPointUpdated(uint256 indexed pid, uint256 oldAllocPoint, uint256 newAllocPoint);
    event FeeUpdated(
        uint256 indexed pid,
        uint256 oldHarvestInterval,
        uint256 oldHarvestFeeInterval,
        uint16 oldHarvestFee,
        uint256 newHarvestInterval,
        uint256 newHarvestFeeInterval,
        uint16 newHarvestFee
    );
    event LockerUpdated(ILocker oldLocker, ILocker newLocker);
    event LockerRateUpdated(uint16 oldRate, uint16 newRate);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 amount);
    event ReferralUpdated(IReferral oldReferral, IReferral newReferral);
    event ReferralRateUpdated(uint16 oldRate, uint16 newRate);
    event FeeReceiverUpdated(address indexed oldReceiver, address indexed newReceiver);
    event LPFeeReceiverUpdated(address indexed oldReceiver, address indexed newReceiver);
    event EmissionRateUpdated(uint256 oldRate, uint256 newRate);

    modifier validFee(uint16 _harvestFee) {
        require(_harvestFee <= HARVEST_FEE_UPPER_LIMIT, "harvest fee exceed upper limit");
        _;
    }

    modifier validHarvestInterval(uint256 _harvestInterval) {
        require(_harvestInterval <= HARVEST_INTERVAL_UPPER_LIMIT, "harvest interval exceeded upper limit");
        _;
    }

    constructor(address _beliAddress) public {
        BELI = _beliAddress;
        startBlock = block.number;
        BELIPerBlock = 0;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function setEmissionRate(uint256 _newRate) external onlyOwner returns (uint256) {
        if (BELIPerBlock >= BELI_PER_BLOCK_THRESHOLD) {
            require(_newRate >= BELI_PER_BLOCK_THRESHOLD, "emission must now be higher than 0.5");
        }
        require(_newRate <= BELI_PER_BLOCK_UPPER_LIMIT, 'emission rate too big');
        emit EmissionRateUpdated(BELIPerBlock, _newRate);
        BELIPerBlock = _newRate;
    }

    function setFarmSettings(
        uint16 _lockerRate,
        uint16 _referralCommissionRate,
        ILocker _locker,
        IReferral _referral,
        IFeeReceiver _feeReceiver,
        IFeeReceiver _feeLpReceiver
    ) external onlyOwner {
        if (_lockerRate != lockerRate) {
            require(_lockerRate <= MAX_RATE, "locker rate exceed allowed value");
            emit LockerRateUpdated(lockerRate, _lockerRate);
            lockerRate = _lockerRate;
        }

        if (address(locker) != address(_locker)) {
            emit LockerUpdated(locker, _locker);
            locker = _locker;
        }

        if (referralCommissionRate != _referralCommissionRate) {
            // Max referral commission rate: 10%.
            require(
                _referralCommissionRate <= REFERRAL_COMMISSION_UPPER_LIMIT,
                "commission rate exceed upper limit"
            );
            emit ReferralRateUpdated(referralCommissionRate, _referralCommissionRate);
            referralCommissionRate = _referralCommissionRate;
        }

        if (address(referral) != address(_referral)) {
            emit ReferralUpdated(referral, _referral);
            referral = _referral;
        }

        if (address(feeReceiver) != address(_feeReceiver)) {
            emit FeeReceiverUpdated(address(feeReceiver), address(_feeReceiver));
            feeReceiver = _feeReceiver;
        }

        if (address(feeLpReceiver) != address(_feeLpReceiver)) {
            emit LPFeeReceiverUpdated(address(feeLpReceiver), address(_feeLpReceiver));
            feeLpReceiver = _feeLpReceiver;
        }
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once.
    // Rewards will be messed up if you do. (Only if want tokens are stored here.)
    function add(
        IERC20 _want,
        bool _withUpdate,
        address _vault,
        uint256 _harvestInterval,
        uint256 _harvestFeeInterval,
        uint16 _harvestFee,
        bool _isFeeReceiverReward,
        bool _isLpReward
    )
        public
        onlyOwner
        validFee(_harvestFee)
        validHarvestInterval(_harvestInterval)
    {
        if (_isFeeReceiverReward == true) {
            require(
                _isLpReward == false,
                "transfer fee reward and lp reward is exclusive to each other"
            );
        }
        if (_isLpReward == true) {
            require(
                _isFeeReceiverReward == false,
                "transfer fee reward and lp reward is exclusive to each other"
            );
        }
        if (_withUpdate) {
            massUpdatePools();
        }
        vaultExists[address(_vault)] = true;
        totalAllocPoint = totalAllocPoint.add(0);
        poolInfo.push(
            PoolInfo({
                want: _want,
                allocPoint: 0,
                lastRewardBlock: startBlock,
                accBELIPerShare: 0,
                vault: _vault,
                harvestInterval: _harvestInterval,
                harvestFeeInterval: _harvestFeeInterval,
                harvestFee: _harvestFee,
                accBELIPerShareFromFees: 0,
                lastAccBELIFromFees: 0,
                isLpReward: _isLpReward,
                isFeeReceiverReward: _isFeeReceiverReward
            })
        );
    }

    // Update the given pool's BELI allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _harvestInterval,
        uint256 _harvestFeeInterval,
        uint16 _harvestFee,
        bool _withUpdate
    )
        public
        onlyOwner
        validFee(_harvestFee)
        validHarvestInterval(_harvestInterval)
    {
        PoolInfo storage pool = poolInfo[_pid];
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
            _allocPoint
        );
        if (pool.isLpReward) {
            totalLpRewardAllocPoint = totalLpRewardAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }
        if (pool.isFeeReceiverReward) {
            totalFeeRewardAllocPoint = totalFeeRewardAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }

        emit FeeUpdated(
            _pid,
            pool.harvestInterval,
            pool.harvestFeeInterval,
            pool.harvestFee,
            _harvestInterval,
            _harvestFeeInterval,
            _harvestFee
        );
        pool.harvestInterval = _harvestInterval;
        pool.harvestFeeInterval = _harvestFeeInterval;
        pool.harvestFee = _harvestFee;

        emit AllocPointUpdated(_pid, pool.allocPoint, _allocPoint);
        pool.allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (IERC20(BELI).totalSupply() >= BELIMaxSupply) {
            return 0;
        }
        if (block.number < startBlock) {
            return 0;
        }
        return _to.sub(_from);
    }

    function lockedUntil(uint256 _pid, address _user) external view returns (uint256) {
        return IVault(poolInfo[_pid].vault).lockedUntil(_user);
    }

    /**
     * cannot reuse in transferRewardFromFee due to the fact that pool.lastAccBELIFromFees
     * will be same as accBeliFromFees thanks to necessary updatePool
     */
    function pendingFeeReceiverBeliReward(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 sharesTotal = IVault(pool.vault).sharesTotal();
        uint256 pendingReward = 0;
        if (pool.isFeeReceiverReward) {
            if (pool.allocPoint > 0) {
                uint256 _accBeliFromFees = accBeliFromFees;
                if (block.number > lastUpdateBeliFeesBlock) {
                    uint256 beliReceived = IERC20(BELI).balanceOf(address(feeReceiver)).add(accWithdrawnBeliFromFees);
                    if (beliReceived.sub(_accBeliFromFees) > 0) {
                        _accBeliFromFees = beliReceived;
                    }
                }
                if (pool.lastAccBELIFromFees < _accBeliFromFees && sharesTotal > 0) {
                    uint256 feeReward =
                        _accBeliFromFees.sub(pool.lastAccBELIFromFees).mul(pool.allocPoint).div(totalFeeRewardAllocPoint);
                    uint256 accBELIPerShareFromFees = pool.accBELIPerShareFromFees.add(feeReward.mul(1e12).div(sharesTotal));
                    pendingReward = user.shares.mul(accBELIPerShareFromFees).div(1e12).sub(user.rewardFeeReceiverDebt);
                }
            }
        }
        return pendingReward;
    }

    function pendingFeeReceiverBeliLpReward(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 sharesTotal = IVault(pool.vault).sharesTotal();
        uint256 pendingReward = 0;
        if (pool.isLpReward) {
            if (pool.allocPoint > 0) {
                uint256 _accBeliFromFees = accBeliLPFromFees;
                if (block.number > lastUpdateBeliFeesLPBlock) {
                    uint256 beliReceived = IERC20(BELI).balanceOf(address(feeLpReceiver)).add(accWithdrawnBeliLPRewardFromFees);
                    if (beliReceived.sub(_accBeliFromFees) > 0) {
                        _accBeliFromFees = beliReceived;
                    }
                }
                if (pool.lastAccBELIFromFees < _accBeliFromFees && sharesTotal != 0) {
                    uint256 feeReward =
                        _accBeliFromFees.sub(pool.lastAccBELIFromFees).mul(pool.allocPoint).div(totalLpRewardAllocPoint);
                    uint256 accBELIPerShareFromFees = pool.accBELIPerShareFromFees.add(feeReward.mul(1e12).div(sharesTotal));
                    uint256 pendingFeeReward = user.shares.mul(accBELIPerShareFromFees).div(1e12).sub(user.rewardFeeReceiverDebt);
                    pendingReward = pendingReward.add(pendingFeeReward);
                }
            }
        }
        return pendingReward;
    }

    function pendingLocker(address _user)
        external
        view
        returns (uint256)
    {
        return ILocker(locker).lockOf(_user).sub(ILocker(locker).released(_user));
    }

    function pendingBELI(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBELIPerShare = pool.accBELIPerShare;
        uint256 sharesTotal = IVault(pool.vault).sharesTotal();
        if (block.number > pool.lastRewardBlock && sharesTotal != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 BELIReward =
                multiplier.mul(BELIPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accBELIPerShare = accBELIPerShare.add(
                BELIReward.mul(1e12).div(sharesTotal)
            );
        }
        uint256 pending = user.shares.mul(accBELIPerShare).div(1e12).sub(user.rewardDebt);
        uint256 pendingReward = pending.add(user.lockedReward);
        return pendingReward;
    }

    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.lockedUntil;
    }

    /**
     * @param _amount - pendingBELI
     */
    function harvestFee(uint256 _pid, uint256 _amount) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp >= user.withdrawalFeeUntil) {
            return 0;
        }
        return _amount.mul(pool.harvestFee).div(MAX_RATE);
    }

    function harvestFeeUntil(uint256 _pid) external view returns (uint256) {
        UserInfo storage user = userInfo[_pid][msg.sender];
        return user.withdrawalFeeUntil;
    }

    // View function to see staked Want tokens on frontend.
    function stakedWantTokens(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 sharesTotal = IVault(pool.vault).sharesTotal();
        uint256 wantLockedTotal =
            IVault(poolInfo[_pid].vault).wantLockedTotal();
        if (sharesTotal == 0) {
            return 0;
        }
        return user.shares.mul(wantLockedTotal).div(sharesTotal);
    }

    function vaultWantLockedTotal(uint256 _pid) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return IVault(pool.vault).wantLockedTotal();
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 sharesTotal = IVault(pool.vault).sharesTotal();
        if (sharesTotal == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

        uint256 BELIReward =
            multiplier.mul(BELIPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );

        // fee receiver reward
        if (pool.isFeeReceiverReward) {
            if (block.number > lastUpdateBeliFeesBlock) {
                uint256 beliReceived = IERC20(BELI).balanceOf(address(feeReceiver)).add(accWithdrawnBeliFromFees);
                if (beliReceived.sub(accBeliFromFees) > 0) {
                    accBeliFromFees = beliReceived;
                }
                lastUpdateBeliFeesBlock = block.number;
            }
            if (pool.lastAccBELIFromFees < accBeliFromFees && IVault(pool.vault).sharesTotal() != 0) {
                uint256 beliFeeReward =
                    accBeliFromFees.sub(pool.lastAccBELIFromFees).mul(pool.allocPoint).div(totalFeeRewardAllocPoint);
                pool.accBELIPerShareFromFees = pool.accBELIPerShareFromFees.add(
                    beliFeeReward.mul(1e12).div(IVault(pool.vault).sharesTotal())
                );
                pool.lastAccBELIFromFees = accBeliFromFees;
            }
        }

        // fee receiver (LP) reward
        if (pool.isLpReward) {
            if (block.number > lastUpdateBeliFeesLPBlock) {
                uint256 beliReceived = IERC20(BELI).balanceOf(address(feeLpReceiver)).add(accWithdrawnBeliLPRewardFromFees);
                if (beliReceived.sub(accBeliLPFromFees) > 0) {
                    accBeliLPFromFees = beliReceived;
                }
                lastUpdateBeliFeesLPBlock = block.number;
            }
            if (pool.lastAccBELIFromFees < accBeliLPFromFees && IVault(pool.vault).sharesTotal() != 0) {
                uint256 beliFeeReward =
                    accBeliLPFromFees.sub(pool.lastAccBELIFromFees).mul(pool.allocPoint).div(totalLpRewardAllocPoint);
                pool.accBELIPerShareFromFees = pool.accBELIPerShareFromFees.add(
                    beliFeeReward.mul(1e12).div(IVault(pool.vault).sharesTotal())
                );
                pool.lastAccBELIFromFees = accBeliFromFees;
            }
        }

        BToken(BELI).mint(
            owner(),
            BELIReward.mul(ownerBELIReward).div(1000)
        );
        BToken(BELI).mint(address(this), BELIReward);

        pool.accBELIPerShare = pool.accBELIPerShare.add(
            BELIReward.mul(1e12).div(sharesTotal)
        );
        pool.lastRewardBlock = block.number;
    }

    function transferConvertedEarn(
        uint256 _pid,
        address _user
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        if (user.shares > 0) {
            uint256 amount = _pendingConvertedEarn(_pid, _user);
            if (amount > 0) {
                IVault(pool.vault).transferConvertedEarn(_user, amount);
            }
            user.rewardEarnDebt = user.rewardEarnDebt.add(amount);
        }
    }

    function pendingConvertedEarn(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        return _pendingConvertedEarn(_pid, _user);
    }

    /**
     * @dev return amount of converted earn the user owns
     */
    function _pendingConvertedEarn(
        uint256 _pid,
        address _user
    ) private view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 totalShare = IVault(pool.vault).sharesTotal();
        uint256 amount = 0;
        if (user.shares > 0) {
            uint256 accEarnBELI = IVault(pool.vault).accEarnBELI();
            uint256 accEarnPerShare = IVault(pool.vault).accEarnBELIPerShare();
            uint256 lastAccEarnBELI = IVault(pool.vault).lastAccEarnBELI();
            uint256 reward = accEarnBELI.sub(lastAccEarnBELI);
            accEarnPerShare = accEarnPerShare.add(reward.mul(1e12).div(totalShare));
            amount = user.shares.mul(accEarnPerShare).div(1e12).sub(user.rewardEarnDebt);
        }
        return amount;
    }

    /**
     * @dev handle all BELI reward distribution
     */
    function payOrLockupPendingBELI(uint256 _pid, bool _isWithdrawal) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        // initial state, first time deposit
        if (user.lockedUntil == 0) {
            user.lockedUntil = block.timestamp.add(pool.harvestInterval);
        }

        // initial state, first time deposit
        if (user.withdrawalFeeUntil == 0) {
            user.withdrawalFeeUntil = block.timestamp.add(pool.harvestFeeInterval);
        }

        // pending reward for user
        uint256 pending = user.shares.mul(pool.accBELIPerShare).div(1e12).sub(user.rewardDebt);
        if (pool.isFeeReceiverReward || pool.isLpReward) {
            transferRewardFromFeeReceiver(_pid, msg.sender);
        }

        if (IVault(pool.vault).accEarnBELIPerShare() > 0) {
            transferConvertedEarn(_pid, msg.sender);
        }

        if (_isWithdrawal) {
            uint256 harvestFeeAmount = harvestFee(_pid, pending);
            pending = pending.sub(harvestFeeAmount);
            if (harvestFeeAmount > 0) {
                // harvest fee burn
                safeBELITransfer(BURN_ADDRESS, harvestFeeAmount);
            }
            user.withdrawalFeeUntil = block.timestamp.add(pool.harvestFeeInterval);
        }

        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.lockedReward > 0) {
                uint256 totalRewards = pending.add(user.lockedReward);

                // reset lockup
                user.lockedReward = 0;
                user.lockedUntil = block.timestamp.add(pool.harvestInterval);

                if (address(locker) != address(0)){
                    uint256 startReleaseBlock = ILocker(locker).getStartReleaseBlock();
                    if (lockerRate > 0 && block.number < startReleaseBlock) {
                        uint256 _lockerAmount = totalRewards.mul(lockerRate).div(10000);
                        totalRewards = totalRewards.sub(_lockerAmount);
                        IERC20(BELI).safeIncreaseAllowance(address(locker), _lockerAmount);
                        ILocker(locker).lock(msg.sender, _lockerAmount);
                    }
                }

                // send rewards
                safeBELITransfer(msg.sender, totalRewards);
                payReferralCommission(msg.sender, totalRewards);
            }
        } else if (pending > 0) {
            user.lockedReward = user.lockedReward.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    /**
     * @dev Want tokens moved from user -> BeliFarm (this) -> Strat (compounding)
     */
    function deposit(
        uint256 _pid,
        uint256 _wantAmt,
        address _referrer
    ) public nonReentrant {
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        // only non-zero (harvest) deposit and referrer address beside zero address, burn address or the sender her/himself
        if (_wantAmt > 0 && address(referral) != address(0) && address(referral) != BURN_ADDRESS && _referrer != address(0) && _referrer != BURN_ADDRESS && _referrer != msg.sender) {
            referral.recordReferral(msg.sender, _referrer);
        }

        payOrLockupPendingBELI(_pid, false);

        if (_wantAmt > 0) {
            uint256 preBalance = pool.want.balanceOf(address(this));
            pool.want.safeTransferFrom(
                address(msg.sender),
                address(this),
                _wantAmt
            );
            uint256 postBalance = pool.want.balanceOf(address(this));
            _wantAmt = postBalance.sub(preBalance);

            pool.want.safeIncreaseAllowance(pool.vault, _wantAmt);
            // deposit using vault, deposit fee etc is already handled by vault
            uint256 sharesAdded =
                IVault(poolInfo[_pid].vault).deposit(msg.sender, _wantAmt);
            user.shares = user.shares.add(sharesAdded);
        }
        user.rewardDebt = user.shares.mul(pool.accBELIPerShare).div(1e12);
        user.rewardFeeReceiverDebt = user.shares.mul(pool.accBELIPerShareFromFees).div(1e12);
        emit Deposit(msg.sender, _pid, _wantAmt);
    }

    /**
     * @dev Withdraw LP tokens from MasterChef.
     */
    function withdraw(uint256 _pid, uint256 _wantAmt) public nonReentrant {
        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 wantLockedTotal = IVault(pool.vault).wantLockedTotal();
        uint256 sharesTotal = IVault(pool.vault).sharesTotal();

        require(user.shares > 0, "user.shares is 0");
        require(sharesTotal > 0, "sharesTotal is 0");

        payOrLockupPendingBELI(_pid, true);

        // Withdraw want tokens
        uint256 amount = user.shares.mul(wantLockedTotal).div(sharesTotal);
        if (_wantAmt > amount) {
            _wantAmt = amount;
        }
        if (_wantAmt > 0) {
            uint256 sharesRemoved =
                IVault(pool.vault).withdraw(msg.sender, _wantAmt);

            if (sharesRemoved > user.shares) {
                user.shares = 0;
            } else {
                user.shares = user.shares.sub(sharesRemoved);
            }

            uint256 wantBal = IERC20(pool.want).balanceOf(address(this));
            if (wantBal < _wantAmt) {
                _wantAmt = wantBal;
            }
            pool.want.safeTransfer(address(msg.sender), _wantAmt);
        }
        user.rewardDebt = user.shares.mul(pool.accBELIPerShare).div(1e12);
        user.rewardFeeReceiverDebt = user.shares.mul(pool.accBELIPerShareFromFees).div(1e12);
        emit Withdraw(msg.sender, _pid, _wantAmt);
    }

    function withdrawEarly(uint256 _pid, uint256 _wantAmt) public nonReentrant {
        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 wantLockedTotal = IVault(pool.vault).wantLockedTotal();
        uint256 sharesTotal = IVault(pool.vault).sharesTotal();

        require(user.shares > 0, "user.shares is 0");
        require(sharesTotal > 0, "sharesTotal is 0");

        payOrLockupPendingBELI(_pid, true);

        // Withdraw want tokens
        uint256 amount = user.shares.mul(wantLockedTotal).div(sharesTotal);
        if (_wantAmt > amount) {
            _wantAmt = amount;
        }
        if (_wantAmt > 0) {
            uint256 sharesRemoved =
                IVault(pool.vault).withdrawEarly(msg.sender, _wantAmt);

            if (sharesRemoved > user.shares) {
                user.shares = 0;
            } else {
                user.shares = user.shares.sub(sharesRemoved);
            }

            uint256 wantBal = IERC20(pool.want).balanceOf(address(this));
            if (wantBal < _wantAmt) {
                _wantAmt = wantBal;
            }
            pool.want.safeTransfer(address(msg.sender), _wantAmt);
        }
        user.rewardDebt = user.shares.mul(pool.accBELIPerShare).div(1e12);
        user.rewardFeeReceiverDebt = user.shares.mul(pool.accBELIPerShareFromFees).div(1e12);
        emit Withdraw(msg.sender, _pid, _wantAmt);
    }

    function withdrawAll(uint256 _pid) public nonReentrant {
        withdraw(_pid, uint256(-1));
    }

    /**
     * @dev Withdraw without caring about rewards. EMERGENCY ONLY.
     */
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 wantLockedTotal =
            IVault(pool.vault).wantLockedTotal();
        uint256 sharesTotal = IVault(pool.vault).sharesTotal();
        uint256 amount = user.shares.mul(wantLockedTotal).div(sharesTotal);

        uint256 preBalance = pool.want.balanceOf(address(this));
        IVault(pool.vault).withdraw(msg.sender, amount);
        uint256 postBalance = pool.want.balanceOf(address(this));
        amount = postBalance.sub(preBalance);

        pool.want.safeTransfer(address(msg.sender), amount);
        user.shares = 0;
        user.rewardDebt = 0;
        user.rewardFeeReceiverDebt = 0;
        user.lockedReward = 0;
        user.lockedUntil = 0;
        user.withdrawalFeeUntil = 0;
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /**
     * @dev emergency withdraw which also bypass timelocked withdraw
     * example use case: VaultStakingBELI
     */
    function emergencyWithdrawEarly(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 wantLockedTotal =
            IVault(pool.vault).wantLockedTotal();
        uint256 sharesTotal = IVault(pool.vault).sharesTotal();
        uint256 amount = user.shares.mul(wantLockedTotal).div(sharesTotal);

        uint256 preBalance = pool.want.balanceOf(address(this));
        IVault(pool.vault).withdrawEarly(msg.sender, amount);
        uint256 postBalance = pool.want.balanceOf(address(this));
        amount = postBalance.sub(preBalance);

        pool.want.safeTransfer(address(msg.sender), amount);
        user.shares = 0;
        user.rewardDebt = 0;
        user.rewardFeeReceiverDebt = 0;
        user.lockedReward = 0;
        user.lockedUntil = 0;
        user.withdrawalFeeUntil = 0;
        emit EmergencyWithdrawEarly(msg.sender, _pid, amount);
    }

    /**
     * @dev transfer reward from either lpFeeReceiver or feeReceiver
     */
    function transferRewardFromFeeReceiver(
        uint _pid,
        address _user
    ) private {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 balance;
        uint256 pendingReward;
        if (pool.isFeeReceiverReward) {
            pendingReward = user.shares.mul(pool.accBELIPerShareFromFees).div(1e12).sub(user.rewardFeeReceiverDebt);
            if (pendingReward > 0 && address(feeReceiver) != address(0)) {
                balance = IERC20(BELI).balanceOf(address(feeReceiver));
                if (balance < pendingReward) {
                    pendingReward = balance;
                }
                accWithdrawnBeliFromFees = accWithdrawnBeliFromFees.add(pendingReward);
                if (pendingReward > 0) {
                    IERC20(BELI).safeTransferFrom(address(feeReceiver), _user, pendingReward);
                }
            }
        } else if (pool.isLpReward) {
            pendingReward = user.shares.mul(pool.accBELIPerShareFromFees).div(1e12).sub(user.rewardFeeReceiverDebt);
            if (pendingReward > 0 && address(feeLpReceiver) != address(0)) {
                balance = IERC20(BELI).balanceOf(address(feeLpReceiver));
                if (balance < pendingReward) {
                    pendingReward = balance;
                }
                accWithdrawnBeliLPRewardFromFees = accWithdrawnBeliLPRewardFromFees.add(pendingReward);
                if (pendingReward > 0) {
                    IERC20(BELI).safeTransferFrom(address(feeLpReceiver), _user, pendingReward);
                }
            }
        }
    }

    // Safe BELI transfer function, just in case if rounding error causes pool to not have enough
    function safeBELITransfer(address _to, uint256 _BELIAmt) internal {
        uint256 BELIBal = IERC20(BELI).balanceOf(address(this));
        if (_BELIAmt > BELIBal) {
            IERC20(BELI).transfer(_to, BELIBal);
        } else {
            IERC20(BELI).transfer(_to, _BELIAmt);
        }
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount
    ) public onlyOwner {
        require(_token != BELI, "!safe");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /**
     * @dev Pay referral commission to the referrer who refer this user.
     */
    function payReferralCommission(
        address _user,
        uint256 _pending
    ) internal {
        if (address(referral) != address(0) && referralCommissionRate > 0) {
            address referrer = referral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(MAX_RATE);

            if (referrer != address(0) && referrer != BURN_ADDRESS && commissionAmount > 0) {
                BToken(BELI).mint(referrer, commissionAmount);
                referral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }

    /**
     * @dev mint the share as ERC20 token so it can be transferred to other people
     * does not affect sharesTotal so the share ratio is preserved
     */
    function mintShareToReceipt(
        uint256 _pid,
        uint256 _amount
    ) external nonReentrant {
        updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        require(user.shares > 0, "no share");
        require(_amount > 0, "cannot mint 0 token");
        require(user.shares >= _amount, "not enough share");

        uint256 wantLockedTotal = IVault(pool.vault).wantLockedTotal();
        uint256 sharesTotal = IVault(pool.vault).sharesTotal();

        require(sharesTotal > 0, "sharesTotal is 0");

        payOrLockupPendingBELI(_pid, true);

        uint256 amount = user.shares.mul(wantLockedTotal).div(sharesTotal);
        if (_amount > amount) {
            _amount = amount;
        }

        uint256 sharesRemoved = IVault(pool.vault).mintShareToReceipt(msg.sender, _amount);
        if (sharesRemoved > user.shares) {
            user.shares = 0;
        } else {
            user.shares = user.shares.sub(_amount);
        }
        user.rewardDebt = user.shares.mul(pool.accBELIPerShare).div(1e12);
        user.rewardFeeReceiverDebt = user.shares.mul(pool.accBELIPerShareFromFees).div(1e12);
    }

    /**
     * @dev burn the ERC20 share token (receipt) and return it into user.shares
     * does not affect sharesTotal so the share ratio is preserved
     */
    function burnReceiptForShare(
        uint256 _pid,
        uint256 _amount
    ) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 userBalance = IERC20(pool.vault).balanceOf(msg.sender);
        require(userBalance >= _amount, "insufficient balance");
        UserInfo storage user = userInfo[_pid][msg.sender];
        IVault(pool.vault).burnReceiptForShare(msg.sender, _amount);
        user.shares = user.shares.add(_amount);
        user.rewardDebt = user.shares.mul(pool.accBELIPerShare).div(1e12);
        user.rewardFeeReceiverDebt = user.shares.mul(pool.accBELIPerShareFromFees).div(1e12);
    }
}

pragma solidity ^0.6.12;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Address.sol";
import "../interfaces/IERC20.sol";

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

pragma solidity 0.6.12;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableSet.sol";
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint256(_at(set._inner, index)));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity 0.6.12;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol";
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
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity 0.6.12;

interface IVault {
    // Total want tokens managed by stratfegy
    function wantLockedTotal() external view returns (uint256);

    // Sum of all shares of users to wantLockedTotal
    function sharesTotal() external view returns (uint256);

    function accEarnBELIPerShare() external view returns (uint256);

    function accEarnBELI() external view returns(uint256);

    function lastAccEarnBELI() external view returns(uint256);

    // Main want token compounding function
    function earn() external;

    // Transfer want tokens farm -> strategy
    function deposit(address _userAddress, uint256 _wantAmt)
        external
        returns (uint256);

    // Transfer want tokens strategy -> farm
    function withdraw(address _userAddress, uint256 _wantAmt)
        external
        returns (uint256);

    function withdrawEarly(address _userAddress, uint256 _wantAmt) external returns (uint256);

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;

    function farm() external;

    function pause() external;

    function unpause() external;

    function rebalance(uint256 _borrowRate, uint256 _borrowDepth) external; // Venus

    function deleverageOnce() external;

    function leverageOnce() external;

    function wrapBNB() external; // Specifically for the Venus WBNB vault.

    function setSettings(
        uint256 _entranceFeeFactor,
        uint256 _withdrawFeeFactor,
        uint256 _controllerFee,
        uint256 _buyBackRate,
        uint256 _slippageFactor,
        uint256 _profitToBeli
    ) external;

    // In case new vaults require functions without a timelock as well, hoping to avoid having multiple timelock contracts
    function noTimeLockFunc1() external;

    function noTimeLockFunc2() external;

    function noTimeLockFunc3() external;

    function transferConvertedEarn(address _userAddress, uint256 _amount) external;

    function mintShareToReceipt(address _userAddress, uint256 _amount) external returns (uint256);

    function burnReceiptForShare(address _userAddress, uint256 _amount) external;

    function lockedUntil(address _userAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(address referrer, uint256 commission) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ILocker {
    function totalLock() external view returns (uint256);

    function lockOf(address _account) external view returns (uint256);

    function released(address _account) external view returns (uint256);

    function canUnlockAmount(address _account) external view returns (uint256);

    function lock(address _account, uint256 _amount) external;

    function unlock() external;

    function getStartReleaseBlock() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IFeeReceiver {
  function addRecipient(address _recipient) external;
}

pragma solidity ^0.6.12;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity 0.6.12;

// "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol";
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

    constructor() internal {
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

pragma solidity 0.6.12;

import "./Context.sol";

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity 0.6.12;

import "./Context.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol";

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
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
}

pragma solidity 0.6.12;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}