// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./IEloroReferral.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./EloroToken.sol";

// MasterChef is the master of Eloro. He is leading the exploration into El Dorado. 
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once ELORO is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ELORO
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accEloroPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accEloroPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. ELORO to distribute per block.
        uint256 lastRewardBlock;  // Last block number that ELORO distribution occurs.
        uint256 accEloroPerShare;   // Accumulated ELORO per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    // The ELORO TOKEN!
    EloroToken public eloro;
    // Dev address.
    address public devAddress;
    // Deposit Fee address
    address public feeAddress;
    // ELORO tokens created per block.
    uint256 public eloroPerBlock;
    // Bonus muliplier for early eloro makers.
    uint256 public constant BONUS_MULTIPLIER = 1;

    // Initial emission rate: 1 ELORO per block.
    uint256 public constant INITIAL_EMISSION_RATE = 1 ether;
    // Minimum emission rate: 0.1 ELORO per block.
    uint256 public constant MINIMUM_EMISSION_RATE = 100 finney;
    // Reduce emission every 28,800 blocks ~ 24 hours.
    uint256 public constant EMISSION_REDUCTION_PERIOD_BLOCKS = 28800;
    // Emission reduction rate per period in basis points: 2%.
    uint256 public constant EMISSION_REDUCTION_RATE_PER_PERIOD = 200;
    // Last reduction period index
    uint256 public lastReductionPeriodIndex = 0;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when ELORO mining starts.
    uint256 public startBlock;

    // ELORO referral contract address.
    IEloroReferral public eloroReferral;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 200;
    // Max referral commission rate: 10%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 1000;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);


    constructor(
        EloroToken _eloro,
        uint256 _startBlock,
        uint256 _eloroPerBlock
    ) public {
        eloro = _eloro;
        startBlock = _startBlock;
        eloroPerBlock = _eloroPerBlock;

        devAddress = msg.sender;
        feeAddress = msg.sender;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accEloroPerShare: 0,
            depositFeeBP: _depositFeeBP
        }));
    }

    // Update the given pool's ELORO allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending ELORO on frontend.
    function pendingEloro(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accEloroPerShare = pool.accEloroPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 eloroReward = multiplier.mul(eloroPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accEloroPerShare = accEloroPerShare.add(eloroReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accEloroPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 eloroReward = multiplier.mul(eloroPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        eloro.mint(devAddress, eloroReward.div(10));
        eloro.mint(address(this), eloroReward);
        pool.accEloroPerShare = pool.accEloroPerShare.add(eloroReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for ELORO allocation.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (_amount > 0 && address(eloroReferral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            eloroReferral.recordReferral(msg.sender, _referrer);
        }
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accEloroPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeEloroTransfer(msg.sender, pending);
                payReferralCommission(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (address(pool.lpToken) == address(eloro)) {
                uint256 transferTax = _amount.mul(2).div(100);
                _amount = _amount.sub(transferTax);
            }
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accEloroPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accEloroPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeEloroTransfer(msg.sender, pending);
            payReferralCommission(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accEloroPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe eloro transfer function, just in case if rounding error causes pool to not have enough ELORO.
    function safeEloroTransfer(address _to, uint256 _amount) internal {
        uint256 eloroBal = eloro.balanceOf(address(this));
        if (_amount > eloroBal) {
            eloro.transfer(_to, eloroBal);
        } else {
            eloro.transfer(_to, _amount);
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

    // Reduce emission rate by 2% every 28,800 blocks ~ 24hours. This function can be called publicly.
    function updateEmissionRate() public {
        require(block.number > startBlock, "updateEmissionRate: Can only be called after mining starts");
        require(eloroPerBlock > MINIMUM_EMISSION_RATE, "updateEmissionRate: Emission rate has reached the minimum threshold");

        uint256 currentIndex = block.number.sub(startBlock).div(EMISSION_REDUCTION_PERIOD_BLOCKS);
        if (currentIndex <= lastReductionPeriodIndex) {
            return;
        }

        uint256 newEmissionRate = eloroPerBlock;
        for (uint256 index = lastReductionPeriodIndex; index < currentIndex; ++index) {
            newEmissionRate = newEmissionRate.mul(1e4 - EMISSION_REDUCTION_RATE_PER_PERIOD).div(1e4);
        }

        newEmissionRate = newEmissionRate < MINIMUM_EMISSION_RATE ? MINIMUM_EMISSION_RATE : newEmissionRate;
        if (newEmissionRate >= eloroPerBlock) {
            return;
        }

        massUpdatePools();
        lastReductionPeriodIndex = currentIndex;
        uint256 previousEmissionRate = eloroPerBlock;
        eloroPerBlock = newEmissionRate;
        emit EmissionRateUpdated(msg.sender, previousEmissionRate, newEmissionRate);
    }

    // Update the eloro referral contract address by the owner
    function setEloroReferral(IEloroReferral _eloroReferral) public onlyOwner {
        eloroReferral = _eloroReferral;
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) public onlyOwner {
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: invalid referral commission rate basis points");
        referralCommissionRate = _referralCommissionRate;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(eloroReferral) != address(0) && referralCommissionRate > 0) {
            address referrer = eloroReferral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);

            if (referrer != address(0) && commissionAmount > 0) {
                eloro.mint(referrer, commissionAmount);
                eloroReferral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }
}