// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./AnubisToken.sol";

// MasterChef is the master of ANUBIS. He can make ANUBIS and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once ANUBIS is sufficiently
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
        uint256 rewardLockedUp;  // Reward locked up.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ANUBIS
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accANUBISPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accANUBISPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. ANUBIS to distribute per block.
        uint256 lastRewardBlock;  // Last block number that ANUBIS distribution occurs.
        uint256 accANUBISPerShare;   // Accumulated ANUBIS per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    // The ANUBIS TOKEN!
    AnubisToken public ANUBIS;
    // Dev address.
    address public devAddress;
    // Deposit Fee address
    address public feeAddress;
    // ANUBIS tokens created per block.
    uint256 public ANUBISPerBlock;
  // Initial emission rate: 1 ANUBIS per block.
    uint256 public constant INITIAL_EMISSION_RATE = 10000 finney;
    // Reduce emission every 7200 blocks ~ 6 hours.
    uint256 public constant EMISSION_REDUCTION_PERIOD_BLOCKS = 28800;
    // Emission reduction rate per period in basis points: 3%.
    uint256 public constant EMISSION_REDUCTION_RATE_PER_PERIOD = 300;
    // Last reduction period index
    uint256 public lastReductionPeriodIndex = 0;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when ANUBIS mining starts.
    uint256 public startBlock;
    // Total locked up rewards
    uint256 public totalLockedUpRewards;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);

    constructor(
        AnubisToken _ANUBIS,
        uint256 _startBlock
        ) public {

        ANUBIS = _ANUBIS;
        startBlock = _startBlock;
        ANUBISPerBlock = INITIAL_EMISSION_RATE;
        if(block.number > startBlock){
        uint256 currentIndex = block.number.sub(startBlock).div(EMISSION_REDUCTION_PERIOD_BLOCKS);
        lastReductionPeriodIndex = currentIndex;}
        devAddress = msg.sender;
        feeAddress = msg.sender;

    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }


    mapping(IBEP20 => bool) public poolExistence;
    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        require(_depositFeeBP <= 500, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accANUBISPerShare: 0,
            depositFeeBP: _depositFeeBP
            }));
    }

    // Update the given pool's ANUBIS allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 500, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    // View function to see pending ANUBIS on frontend.
        function pendingANUBIS(uint256 _pid, address _user) external view returns (uint256) {
            PoolInfo storage pool = poolInfo[_pid];
            UserInfo storage user = userInfo[_pid][_user];
            uint256 accANUBISPerShare = pool.accANUBISPerShare;
            uint256 lpSupply = pool.lpToken.balanceOf(address(this));
            if (block.number > pool.lastRewardBlock && lpSupply != 0) {
                uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
                uint256 ANUBISReward = multiplier.mul(ANUBISPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
                accANUBISPerShare = accANUBISPerShare.add(ANUBISReward.mul(1e12).div(lpSupply));
            }
            uint256 pending = user.amount.mul(accANUBISPerShare).div(1e12).sub(user.rewardDebt);
            return pending.add(user.rewardLockedUp);
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
        uint256 ANUBISReward = multiplier.mul(ANUBISPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        ANUBIS.mint(devAddress, ANUBISReward.div(10));
        ANUBIS.mint(address(this), ANUBISReward);
        pool.accANUBISPerShare = pool.accANUBISPerShare.add(ANUBISReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for ANUBIS allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accANUBISPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeANUBISTransfer(msg.sender, pending);
            }
        }

        if (_amount > 0) {
            uint256 before = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 _after = pool.lpToken.balanceOf(address(this));
            _amount = _after.sub(before);

            if (address(pool.lpToken) == address(ANUBIS)) {
                if(ANUBIS.isExcludedFromFees(msg.sender) == false){
                  // MC has reducedtransferTaxRate by default
                  uint256 transferTax = _amount.mul(ANUBIS.reducedtransferTaxRate()).div(10000);
                  _amount = _amount.sub(transferTax);
                }
            }
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accANUBISPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
        updateEmissionRate();
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accANUBISPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeANUBISTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accANUBISPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
        updateEmissionRate();
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


    // Safe ANUBIS transfer function, just in case if rounding error causes pool to not have enough ANUBIS.
    function safeANUBISTransfer(address _to, uint256 _amount) internal {
        uint256 ANUBISBal = ANUBIS.balanceOf(address(this));
        if (_amount > ANUBISBal) {
            ANUBIS.transfer(_to, ANUBISBal);
        } else {
            ANUBIS.transfer(_to, _amount);
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

    // Reduce emission rate by 5% every 7200 blocks ~ 6hours. This function can be called publicly.
    function updateEmissionRate() public {
        if(block.number > startBlock){
          uint256 currentIndex = block.number.sub(startBlock).div(EMISSION_REDUCTION_PERIOD_BLOCKS);
          uint256 newEmissionRate = ANUBISPerBlock;

          if (currentIndex > lastReductionPeriodIndex) {
                    for (uint256 index = lastReductionPeriodIndex; index < currentIndex; ++index) {
                      newEmissionRate = newEmissionRate.mul(1e4 - EMISSION_REDUCTION_RATE_PER_PERIOD).div(1e4);
                    }
                    if (newEmissionRate < ANUBISPerBlock) {

                        massUpdatePools();
                        lastReductionPeriodIndex = currentIndex;
                        uint256 previousEmissionRate = ANUBISPerBlock;
                        ANUBISPerBlock = newEmissionRate;
                        emit EmissionRateUpdated(msg.sender, previousEmissionRate, newEmissionRate);

                    }
                  }
                }
              }
}