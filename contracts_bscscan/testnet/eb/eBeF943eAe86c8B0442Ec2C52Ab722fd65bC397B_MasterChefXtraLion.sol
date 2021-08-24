pragma solidity 0.6.12;

import 'SafeMath.sol';
import 'IBEP20.sol';
import 'SafeBEP20.sol';
import 'Ownable.sol';
import "ReentrancyGuard.sol";

import "XlionToken.sol";

// import "@nomiclabs/buidler/console.sol";

// MasterChef is the master of Xlion. He can make Xlion and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once XLION is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChefXtraLion is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of XLIONs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accXlionPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accXlionPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. XLIONs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that XLIONs distribution occurs.
        uint256 accXlionPerShare; // Accumulated XLIONs per share, times 1e12. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
    }

    // The XLION TOKEN!
    XlionToken public xlion;
    // Dev address.
    address public devaddr;
    // XLION tokens created per block.
    uint256 public xlionPerBlock;
    // Deposit Fee address
    address public feeAddress;
    // Bonus muliplier for early xlion makers.
    uint256 public BONUS_MULTIPLIER = 1;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when XLION mining starts.
    uint256 public startBlock;

    // Referral Bonus in basis points. Initially set to 2%
    uint256 public refBonusBP = 200;
    // Max deposit fee: 10%.
    uint16 public constant MAXIMUM_DEPOSIT_FEE_BP = 1000;
    // Max referral commission rate: 5%.
    uint16 public constant MAXIMUM_REFERRAL_BP = 500;
    // Referral Mapping
    mapping(address => address) public referrers; // account_address -> referrer_address
    mapping(address => uint256) public referredCount; // referrer_address -> num_of_referred
    // Pool Exists Mapper
    mapping(IBEP20 => bool) public poolExistence;
    // Pool ID Tracker Mapper
    mapping(IBEP20 => uint256) public poolIdForLpAddress;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed _feeAddress);
    event SetDevAddress(address indexed user, address indexed _devAddress);
    event Referral(address indexed _referrer, address indexed _user);
    event ReferralPaid(address indexed _user, address indexed _userTo, uint256 _reward);
    event ReferralBonusBpChanged(uint256 _oldBp, uint256 _newBp);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);

    constructor(
        XlionToken _xlion,
        address _devaddr,
        address _feeAddress,
        uint256 _xlionPerBlock,
        uint256 _startBlock
    ) public {
        xlion = _xlion;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        xlionPerBlock = _xlionPerBlock;
        startBlock = _startBlock;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _xlion,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accXlionPerShare: 0,
            depositFeeBP: 0
        }));

        totalAllocPoint = 1000;

    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Modifier to check Duplicate pools
    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accXlionPerShare: 0,
            depositFeeBP: _depositFeeBP
        }));
    }

    // Update the given pool's XLION allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE_BP, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending XLIONs on frontend.
    function pendingXlion(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accXlionPerShare = pool.accXlionPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 xlionReward = multiplier.mul(xlionPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accXlionPerShare = accXlionPerShare.add(xlionReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accXlionPerShare).div(1e12).sub(user.rewardDebt);
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
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 xlionReward = multiplier.mul(xlionPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        xlion.mint(devaddr, xlionReward.div(10));
        xlion.mint(address(this), xlionReward);
        pool.accXlionPerShare = pool.accXlionPerShare.add(xlionReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for XLION allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accXlionPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeXlionTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                user.amount = user.amount.add(_amount).sub(depositFee);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accXlionPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Deposit LP tokens to MasterChef for XLION allocation with referral.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accXlionPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeXlionTransfer(msg.sender, pending);
                payReferralCommission(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            setReferral(msg.sender, _referrer);
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                user.amount = user.amount.add(_amount).sub(depositFee);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accXlionPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accXlionPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeXlionTransfer(msg.sender, pending);
            payReferralCommission(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accXlionPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe xlion transfer function, just in case if rounding error causes pool to not have enough XLIONs.
    function safeXlionTransfer(address _to, uint256 _amount) internal {
        uint256 xlionBalance = xlion.balanceOf(address(this));
        if (_amount > xlionBalance) {
            xlion.transfer(_to, xlionBalance);
        } else {
            xlion.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(_devaddr != address(0), "dev: invalid address");
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }

    // Update fee address by the previous fee address.
    function setFeeAddress(address _feeAddress) public {
        require(_feeAddress != address(0), "setFeeAddress: invalid address");
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    function updateEmissionRate(uint256 _xlionPerBlock) public onlyOwner {
        require(block.number > startBlock, "updateEmissionRate: Can only be called after mining starts");

        massUpdatePools();

        uint256 previousEmissionRate = xlionPerBlock;
        xlionPerBlock = _xlionPerBlock;

        emit EmissionRateUpdated(msg.sender, previousEmissionRate, xlionPerBlock);
    }

    // Set Referral Address for a user
    function setReferral(address _user, address _referrer) internal {
        if (_referrer == address(_referrer) && referrers[_user] == address(0) && _referrer != address(0) && _referrer != _user) {
            referrers[_user] = _referrer;
            referredCount[_referrer] += 1;
            emit Referral(_user, _referrer);
        }
    }

    // Get Referral Address for a Account
    function getReferral(address _user) public view returns (address) {
        return referrers[_user];
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        address referrer = getReferral(_user);
        if (referrer != address(0) && referrer != _user && refBonusBP > 0) {
            uint256 refBonusEarned = _pending.mul(refBonusBP).div(10000);
            xlion.mint(referrer, refBonusEarned);
            emit ReferralPaid(_user, referrer, refBonusEarned);
        }
    }

    // Referral Bonus in basis points.
    // Initially set to 2%, this this the ability to increase or decrease the Bonus percentage based on
    // community voting and feedback.
    function updateReferralBonusBp(uint256 _newRefBonusBp) public onlyOwner {
        require(_newRefBonusBp <= MAXIMUM_REFERRAL_BP, "updateRefBonusPercent: invalid referral bonus basis points");
        require(_newRefBonusBp != refBonusBP, "updateRefBonusPercent: same bonus bp set");
        uint256 previousRefBonusBP = refBonusBP;
        refBonusBP = _newRefBonusBp;
        emit ReferralBonusBpChanged(previousRefBonusBP, _newRefBonusBp);
    }
}