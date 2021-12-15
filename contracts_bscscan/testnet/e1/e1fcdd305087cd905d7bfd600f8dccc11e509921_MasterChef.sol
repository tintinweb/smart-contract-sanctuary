// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.8.0;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./ICodibnbReferral.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./Codibnb.sol";


// MasterChef is the master of Codibnb. He can make CODIBNB and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once CODIBNB is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;           // How many LP tokens the user has provided.
        uint256 rewardDebt;       // Reward debt. See explanation below.
        uint256 rewardLockedUp;   // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        //
        // We do some fancy math here. Basically, any point in time, the amount of CODIBNB
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accCodibnbPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accCodibnbPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.

    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;             // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. CODIBNB to distribute per block.
        uint256 lastRewardBlock;    // Last block number that CODIBNB distribution occurs.
        uint256 accCodibnbPerShare; // Accumulated CODIBNB per share, times 1e12. See below.
        uint16 depositFeeBP;        // Deposit fee in basis points
        uint256 harvestInterval;    // Harvest interval in seconds
        uint256 totalLp;            // Total Token in Pool
    }

    // The CODIBNB TOKEN!
    Codibnb public codibnb;
    // The operator can only update EmissionRate and AllocPoint to protect tokenomics
    //i.e some wrong setting and a pools get too much allocation accidentally
    address private _operator;
    // Dev address.
    address public devAddress;
    // Deposit Fee address
    address public feeAddress;
    // CODIBNB tokens created per block.
    uint256 public codibnbPerBlock;
    uint256 public constant MAX_CODIBNB_PER_BLOCK = 2000 * 10 ** 18;
    // Bonus multiplier for early codibnb makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Max harvest interval: 14 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when CODIBNB mining starts.
    uint256 public startBlock;
    // Total locked up rewards
    uint256 public totalLockedUpRewards;
    // Total CODIBNB in CODIBNB Pools (can be multiple pools)
    uint256 public totalCodibnbInPools = 0;
    // Codibnb referral contract address.
    ICodibnbReferral public codibnbReferral;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 300;
    // Max referral commission rate: 10%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 500;
    // Maximum deposit fee rate: 10%
    uint16 public constant MAXIMUM_DEPOSIT_FEE_RATE = 400;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    modifier onlyOperator() {
        require(_operator == msg.sender, "Operator: caller is not the operator");
        _;
    }

    constructor(
        Codibnb _codibnb,
        uint256 _codibnbPerBlock
    ) public {
        //StartBlock always many years later from contract construct, will be set later in StartFarming function
        startBlock = block.number + (10 * 365 * 24 * 60 * 60);

        codibnb = _codibnb;
        codibnbPerBlock = _codibnbPerBlock;

        devAddress = msg.sender;
        feeAddress = msg.sender;
        _operator = msg.sender;
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    function transferOperator(address newOperator) public onlyOperator {
        require(newOperator != address(0), "TransferOperator: new operator is the zero address");
        emit OperatorTransferred(_operator, newOperator);
        _operator = newOperator;
    }

    // Set farming start, can call only once
    function startFarming() public onlyOwner {
        require(block.number < startBlock, "Error::Farm started already");

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardBlock = block.number;
        }

        startBlock = block.number;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    //actual Codibnb lef in MasterChef can be used in rewards, must excluding all in codibnb pools
    //this function is for safety check only not used anywhere
    function remainRewards() external view returns (uint256) {
        return codibnb.balanceOf(address(this)).sub(totalCodibnbInPools);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // Can add multiple pool with same lp token without messing up rewards, because each pool's balance is tracked using its own totalLp
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, uint256 _harvestInterval, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE_RATE, "add: deposit fee too high");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
        lpToken : _lpToken,
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accCodibnbPerShare : 0,
        depositFeeBP : _depositFeeBP,
        harvestInterval : _harvestInterval,
        totalLp : 0
        }));
    }

    // Update the given pool's CODIBNB allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, uint256 _harvestInterval, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE_RATE, "set: deposit fee too high");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "set: invalid harvest interval");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending CODIBNB on frontend.
    function pendingCodibnb(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCodibnbPerShare = pool.accCodibnbPerShare;
        uint256 lpSupply = pool.totalLp;

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 codibnbReward = multiplier.mul(codibnbPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCodibnbPerShare = accCodibnbPerShare.add(codibnbReward.mul(1e12).div(lpSupply));
        }
        uint256 pending = user.amount.mul(accCodibnbPerShare).div(1e12).sub(user.rewardDebt);
        return pending.add(user.rewardLockedUp);
    }

    // View function to see if user can harvest CODIBNB.
    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.number >= startBlock && block.timestamp >= user.nextHarvestUntil;
    }

    //this function make sure even thousands of pool gas fee is still low because transfer is just 1 time
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        uint256 totalReward = 0;

        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            if (block.number <= pool.lastRewardBlock) {
                continue;
            }

            if (pool.totalLp == 0 || pool.allocPoint == 0) {
                pool.lastRewardBlock = block.number;
                continue;
            }

            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 codibnbReward = multiplier.mul(codibnbPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

            pool.accCodibnbPerShare = pool.accCodibnbPerShare.add(codibnbReward.mul(1e12).div(pool.totalLp));
            pool.lastRewardBlock = block.number;

            totalReward.add(codibnbReward.div(10));
        }

        safeCodibnbTransfer(devAddress, totalReward);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.totalLp == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 codibnbReward = multiplier.mul(codibnbPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        pool.accCodibnbPerShare = pool.accCodibnbPerShare.add(codibnbReward.mul(1e12).div(pool.totalLp));
        pool.lastRewardBlock = block.number;

        safeCodibnbTransfer(devAddress, codibnbReward.div(10));
    }

    // Deposit LP tokens to MasterChef for CODIBNB allocation.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) public nonReentrant {
        require(block.number >= startBlock, "MasterChef:: Can not deposit before farm start");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (_amount > 0 && address(codibnbReferral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            codibnbReferral.recordReferral(msg.sender, _referrer);
        }
        payOrLockupPendingCodibnb(_pid);
        if (_amount > 0) {
            uint256 beforeDeposit = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 afterDeposit = pool.lpToken.balanceOf(address(this));

            _amount = afterDeposit.sub(beforeDeposit);

            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
                pool.totalLp = pool.totalLp.add(_amount).sub(depositFee);

                if (address(pool.lpToken) == address(codibnb)) {
                    totalCodibnbInPools = totalCodibnbInPools.add(_amount).sub(depositFee);
                }
            } else {
                user.amount = user.amount.add(_amount);
                pool.totalLp = pool.totalLp.add(_amount);

                if (address(pool.lpToken) == address(codibnb)) {
                    totalCodibnbInPools = totalCodibnbInPools.add(_amount);
                }
            }
        }
        user.rewardDebt = user.amount.mul(pool.accCodibnbPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "Withdraw: User amount not enough");
        //this will make sure that user can only withdraw from his pool
        //cannot withdraw more than pool's balance and from MasterChef's token
        require(pool.totalLp >= _amount, "Withdraw: Pool total LP not enough");

        updatePool(_pid);
        payOrLockupPendingCodibnb(_pid);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalLp = pool.totalLp.sub(_amount);
            if (address(pool.lpToken) == address(codibnb)) {
                totalCodibnbInPools = totalCodibnbInPools.sub(_amount);
            }
            pool.lpToken.safeTransfer(address(msg.sender), _amount);

        }
        user.rewardDebt = user.amount.mul(pool.accCodibnbPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;

        require(pool.totalLp >= amount, "EmergencyWithdraw: Pool total LP not enough");

        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        pool.totalLp = pool.totalLp.sub(amount);
        if (address(pool.lpToken) == address(codibnb)) {
            totalCodibnbInPools = totalCodibnbInPools.sub(amount);
        }
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay or lockup pending CODIBNB.
    function payOrLockupPendingCodibnb(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0 && block.number >= startBlock) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }

        uint256 pending = user.amount.mul(pool.accCodibnbPerShare).div(1e12).sub(user.rewardDebt);
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp);
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);

                // send rewards
                safeCodibnbTransfer(msg.sender, totalRewards);
                payReferralCommission(msg.sender, totalRewards);
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    // Safe codibnb transfer function, just in case if rounding error causes pool do not have enough CODIBNB.
    function safeCodibnbTransfer(address _to, uint256 _amount) internal {
        if (codibnb.balanceOf(address(this)) > totalCodibnbInPools) {
            //codibnbBal = total codibnb in MasterChef - total codibnb in codibnb pools, this will make sure that MasterChef never transfer rewards from deposited codibnb pools
            uint256 codibnbBal = codibnb.balanceOf(address(this)).sub(totalCodibnbInPools);
            if (_amount >= codibnbBal) {
                codibnb.transfer(_to, codibnbBal);
            } else if (_amount > 0) {
                codibnb.transfer(_to, _amount);
            }
        }
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devAddress) public {
        require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
        require(_devAddress != address(0), "setDevAddress: ZERO");
        devAddress = _devAddress;
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
    }

    // Update the codibnb referral contract address by the owner
    function setCodibnbReferral(ICodibnbReferral _codibnbReferral) public onlyOwner {
        codibnbReferral = _codibnbReferral;
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) public onlyOperator {
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: referral commission rate too high");
        referralCommissionRate = _referralCommissionRate;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(codibnbReferral) != address(0) && referralCommissionRate > 0) {
            address referrer = codibnbReferral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);

            if (referrer != address(0) && commissionAmount > 0) {
                safeCodibnbTransfer(referrer, commissionAmount);
                codibnbReferral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }

    // Pancake has to add hidden dummy pools in order to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _codibnbPerBlock) public onlyOperator {
        require(_codibnbPerBlock <= MAX_CODIBNB_PER_BLOCK, "CODIBNB per block too high");
        massUpdatePools();

        emit EmissionRateUpdated(msg.sender, codibnbPerBlock, _codibnbPerBlock);
        codibnbPerBlock = _codibnbPerBlock;
    }

    function updateAllocPoint(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOperator {
        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }
}