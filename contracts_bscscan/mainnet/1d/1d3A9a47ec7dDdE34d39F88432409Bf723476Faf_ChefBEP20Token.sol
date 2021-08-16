// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./ILocker.sol";
import "./IFarmReferral.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


// BEP20Token Chef is the one who bakes Banh Mi and bring you the most delicious BEP20Token
// We believe that everyone should be able to enjoy this kind of yummy food
// This is a reattempt to make a new Masterchef who named BEP20Token Chef and will make BEP20Token
// for all of us
// God bless this contract
contract ChefBEP20Token is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        address fundedBy; // Funded by address()
        //
        // We do some fancy math here. Basically, any point in time, the amount of BEP20Tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBEP20TokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBEP20TokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User's `amount` gets updated.
        //   3. User's `rewardDebt` gets updated.
        //   4. User's `fundedBy` updated by User address
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. BEP20Tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that BEP20Tokens distribution occurs.
        uint256 accBEP20TokenPerShare; // Accumulated BEP20Tokens per share, times 1e12. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
        ILocker locker; // Locker contract
    }

    // The BEP20Token TOKEN!
    IBEP20 public BEP20Token;
    // Dev address.
    address public devaddr;
    address public fundingaddr;
    // BEP20Token tokens created per block.
    uint256 public BEP20TokenPerBlock;
    // Bonus muliplier for early BEP20Token makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BEP20Token rewarding starts.
    uint256 public startBlock;
    // The block number when BEP20Token rewarding has to end.
    uint256 public finalRewardBlock;
    IFarmReferral public farmReferral;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 100;
    // Max referral commission rate: 10%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 1000;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 goosePerBlock);
    event UpdateFinalBlock(address indexed user, uint256 newFinalBlock);

    constructor(
        IBEP20 _BEP20token,
        address _devaddr,
        address _feeAddress,
        address _fundingaddr,
        uint256 _BEP20TokenPerBlock,
        uint256 _startBlock,
        uint256 _finalRewardBlock
    ) public {
        fundingaddr = _fundingaddr;
        BEP20Token = _BEP20token;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        startBlock= _startBlock;
        BEP20TokenPerBlock = _BEP20TokenPerBlock;
        finalRewardBlock = _finalRewardBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IBEP20 => bool) public poolExistence;
    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }
    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) public onlyOwner {
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: invalid referral commission rate basis points");
        referralCommissionRate = _referralCommissionRate;
    }
    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IBEP20 _lpToken,
        uint16 _depositFeeBP,
        ILocker _locker,
        bool _withUpdate
    ) public onlyOwner nonDuplicated(_lpToken) {
        require(
            _depositFeeBP <= 10000,
            "add: invalid deposit fee basis points"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accBEP20TokenPerShare: 0,
                depositFeeBP: _depositFeeBP,
                locker: _locker
            })
        );
    }

    // Update the given pool's BEP20Token allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        ILocker _locker,
        bool _withUpdate
    ) public onlyOwner {
        require(
            _depositFeeBP <= 10000,
            "set: invalid deposit fee basis points"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].locker = _locker;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to, uint256 _finalRewardBlock)
        public
        pure
        returns (uint256)
    {
        if( _to > _finalRewardBlock)
        {
            return _finalRewardBlock.sub(_from).mul(BONUS_MULTIPLIER);
        }
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending BEP20Tokens on frontend.
    function pendingBEP20Token(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBEP20TokenPerShare = pool.accBEP20TokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && finalRewardBlock > pool.lastRewardBlock  && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number, finalRewardBlock);
            uint256 BEP20TokenReward =
                multiplier.mul(BEP20TokenPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accBEP20TokenPerShare = accBEP20TokenPerShare.add(
                BEP20TokenReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accBEP20TokenPerShare).div(1e12).sub(user.rewardDebt);
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
        if (block.number <= pool.lastRewardBlock || finalRewardBlock <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number, finalRewardBlock);
        uint256 BEP20TokenReward =
            multiplier.mul(BEP20TokenPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        pool.accBEP20TokenPerShare = pool.accBEP20TokenPerShare.add(
            BEP20TokenReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for BEP20Token allocation.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (_amount > 0 && address(farmReferral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            farmReferral.recordReferral(msg.sender, _referrer);
        }
        // Harvest the remaining token before calculate new amount
        _harvest(msg.sender, _pid);
        if (_amount > 0) {
            pool.lpToken.transferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            
            user.amount = user.amount.add(_amount);
            
            if (user.fundedBy == address(0)) user.fundedBy = msg.sender;
        }
        user.rewardDebt = user.amount.mul(pool.accBEP20TokenPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(user.fundedBy == msg.sender, "withdraw:: only funder");
        updatePool(_pid);
        // Effects
        _harvest(msg.sender, _pid);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            uint256 realAmount = _amount;
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.transfer(feeAddress, depositFee);
                realAmount = _amount.sub(depositFee);
            }
            pool.lpToken.transfer(address(msg.sender), realAmount);
        }
        user.rewardDebt = user.amount.mul(pool.accBEP20TokenPerShare).div(1e12);
        if (user.amount == 0) user.fundedBy = address(0);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Harvest BEP20Token earn from the pool.
    function harvest(uint256 _pid) public {
        updatePool(_pid);
        _harvest(msg.sender, _pid);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of BEP20Token rewards.
    function _harvest(address to, uint256 pid)
        internal
    {
        PoolInfo memory pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][to];
        uint256 accumulatedBEP20Token =
            user.amount.mul(pool.accBEP20TokenPerShare).div(1e12);
        uint256 _pendingBEP20Token = accumulatedBEP20Token.sub(user.rewardDebt);
        if (_pendingBEP20Token == 0) {
            return;
        }


        require(
            _pendingBEP20Token <= BEP20Token.balanceOf(fundingaddr),
            "ChefBEP20Token::_harvest:: wtf not enough BEP20Token"
        );

        // Effects
        user.rewardDebt = accumulatedBEP20Token;

        uint256 commissionpaid = payReferralCommission(msg.sender, _pendingBEP20Token);

        safeBEP20TokenTransfer(to, _pendingBEP20Token.sub(commissionpaid));

        emit Harvest(msg.sender, pid, _pendingBEP20Token);
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

    // Safe BEP20Token transfer function, just in case if rounding error causes pool to not have enough BEP20Tokens.
    function safeBEP20TokenTransfer(address _to, uint256 _amount) internal {
        uint256 BEP20TokenBal = BEP20Token.balanceOf(fundingaddr);
        bool transferSuccess = false;
        if (_amount > BEP20TokenBal) {
            transferSuccess = BEP20Token.transferFrom(fundingaddr, _to, BEP20TokenBal);
        } else {
            transferSuccess = BEP20Token.transferFrom(fundingaddr, _to, _amount);
        }
        require(transferSuccess, "safeBEP20TokenTransfer: transfer failed");
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _BEP20TokenPerBlock) public onlyOwner {
        massUpdatePools();
        BEP20TokenPerBlock = _BEP20TokenPerBlock;
        emit UpdateEmissionRate(msg.sender, _BEP20TokenPerBlock);
    }
    
    function updateFinalBlockReward(uint256 _newFinalBlock) public onlyOwner {
        finalRewardBlock = _newFinalBlock;
        emit UpdateEmissionRate(msg.sender, _newFinalBlock);
    }

    // Update the  referral contract address by the owner
    function setFarmReferral(IFarmReferral _farmReferral) public onlyOwner {
        farmReferral = _farmReferral;
    }

    function payReferralCommission(address _user, uint256 _pending) internal returns (uint256 c) {
        if (address(farmReferral) != address(0) && referralCommissionRate > 0) {
            address referrer = farmReferral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);

            if (referrer != address(0) && commissionAmount > 0) {
                safeBEP20TokenTransfer(referrer, commissionAmount);
                farmReferral.recordReferralCommission(referrer, commissionAmount);
                return commissionAmount;
            }
        }
        return 0;
    }
}