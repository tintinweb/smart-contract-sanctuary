// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";

import "./IBEP20.sol";
import "./SafeBEP20.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./IUFFReferral.sol";
import "./TUFFToken.sol";

// MasterChef is the master of UFF. He can make UFF and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once UFF is sufficiently
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
        // We do some fancy math here. Basically, any point in time, the amount of UFFs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accUFFPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accUFFPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. UFF to distribute per block.
        uint256 lastRewardBlock;  // Last block number that UFF distribution occurs.
        uint256 accUffPerShare;   // Accumulated UFF per share, times 1e12. See below.
        uint16 withdrawFeeBP;      // Withdraw fee in basis points
    }

    // The UFF TOKEN!
    UFFToken public uff;
    // UFF tokens created per block.
    uint256 public uffPerBlock;
    // Bonus muliplier for early UFF makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address / Dev Address and BuyBack Wallet
    address public feeAddDev;
    address public feeAddBb;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when UFF mining starts.
    uint256 public startBlock;

    // UFF referral contract address.
    IUFFReferral public uffReferral;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 300;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed user, uint256 uffPerBlock);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);

    constructor(
        UFFToken _uff,
        IUFFReferral _uffReferral,
        address _feeAddDev,
        address _feeAddBb,
        uint256 _uffPerBlock,
        uint256 _startBlock
    ) public {
        uff = _uff;
        uffReferral = _uffReferral;
        feeAddDev = _feeAddDev;
        feeAddBb = _feeAddBb;
        uffPerBlock = _uffPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IBEP20 => bool) public poolExistence;

    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    modifier poolExists(uint256 pid) {
        require(pid < poolInfo.length, "pool inexistent");
        _;
    }

    modifier lpProtection(uint256 pid, uint256 _amount) {
        PoolInfo storage pool = poolInfo[pid];
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 maxWithdraw = lpSupply.mul(1500).div(10000);
        require(_amount < maxWithdraw, "withdraw: _amount is higher than maximum LP withdraw");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _withdrawFeeBP, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        require(_withdrawFeeBP <= 1200, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardBlock : lastRewardBlock,
            accUffPerShare : 0,
            withdrawFeeBP : _withdrawFeeBP
        }));
    }

    // Update the given pool's UFF allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _withdrawFeeBP, bool _withUpdate) public onlyOwner poolExists(_pid) {
        require(_withdrawFeeBP <= 1200, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].withdrawFeeBP = _withdrawFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending UFFs on frontend.
    function pendingUff(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accUffPerShare = pool.accUffPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 uffReward = multiplier.mul(uffPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accUffPerShare = accUffPerShare.add(uffReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accUffPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 uffReward = multiplier.mul(uffPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        uff.mint(feeAddDev, uffReward.mul(1500).div(10000));
        uff.mint(address(this), uffReward);
        pool.accUffPerShare = pool.accUffPerShare.add(uffReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for UFF allocation.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) public nonReentrant poolExists(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        // Record referral if all below applies
        if (_amount > 0 && address(uffReferral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            uffReferral.recordReferral(msg.sender, _referrer);
        }

        // Try to harvest
        if (user.amount > 0) {
            harvest(_pid);
        }

        // Thanks for RugDoc advice
        // Add user.amount
        if (_amount > 0) {
            // LP ammount before
            uint256 before = pool.lpToken.balanceOf(address(this));
            // Transafer from user
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            // LP ammount after
            uint256 _after = pool.lpToken.balanceOf(address(this));
            // Real amount of LP transfer to this address
            _amount = _after.sub(before);
            user.amount = user.amount.add(_amount);
        }

        // Update user reward debt and emit Deposit
        user.rewardDebt = user.amount.mul(pool.accUffPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant poolExists(_pid) lpProtection(_pid, _amount){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: Amount to withdraw higher than LP balance.");
        updatePool(_pid);
        
        // Harvest before withdraw
        harvest(_pid);

        // Withdraw procedure
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            // Remove fee 
            if (pool.withdrawFeeBP > 0) {
                uint256 withdrawFee = _amount.mul(pool.withdrawFeeBP).div(10000);
                uint256 withdrawFeeHalf = withdrawFee.div(2);
                pool.lpToken.safeTransfer(feeAddDev, withdrawFeeHalf);
                pool.lpToken.safeTransfer(feeAddBb, withdrawFeeHalf);
                _amount = _amount.sub(withdrawFee);
                pool.lpToken.safeTransfer(address(msg.sender), _amount);
            }
        }

        user.rewardDebt = user.amount.mul(pool.accUffPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Safe UFF transfer function, just in case if rounding error causes pool to not have enough UFFs.
    function safeUffTransfer(address _to, uint256 _amount) internal {
        uint256 uffBal = uff.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > uffBal) {
            transferSuccess = uff.transfer(_to, uffBal);
        } else {
            transferSuccess = uff.transfer(_to, _amount);
        }
        require(transferSuccess, "safeUffTransfer: transfer failed");
    }

    // Harvest UFFs.
    function harvest(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 pending = user.amount.mul(pool.accUffPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            // send rewards
            safeUffTransfer(msg.sender, pending);
            payReferralCommission(msg.sender, pending);
        }
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(uffReferral) != address(0) && referralCommissionRate > 0) {
            address referrer = uffReferral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);

            if (referrer != address(0) && commissionAmount > 0) {
                uff.mint(referrer, commissionAmount);
                uffReferral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }

    // Pancake has to add hidden dummy pools in order to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _uffPerBlock) public onlyOwner {
        massUpdatePools();
        emit EmissionRateUpdated(msg.sender, _uffPerBlock);
        uffPerBlock = _uffPerBlock;
    }

      // allow owner to finalize the presale once the presale is ended
    function updateUFFOwner(address newOwner) public onlyOwner {
        uff.transferOwnership(newOwner);
    }
}