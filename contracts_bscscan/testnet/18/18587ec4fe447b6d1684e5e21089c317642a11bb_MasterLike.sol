// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./IReferral.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./LikeToken.sol";

// MasterLike is the master of Like. He can make Like and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownersthip
// will be transferred to a governance smart contract once LIKE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterLike is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of LIKE
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accLikePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accLikePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. LIKE to distribute per block.
        uint256 lastRewardBlock; // Last block number that LIKE distribution occurs.
        uint256 accLikePerShare; // Accumulated LIKE per share, times 1e12. See below.
    }

    // The LIKE TOKEN!
    LikeToken public like;
    // LIKE tokens created per block.
    uint256 public likePerBlock;
    // Bonus muliplier for early like makers.
    uint256 public constant BONUS_MULTIPLIER = 1;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when LIKE mining starts.
    uint256 public startBlock;
    // Governance can approve the transfer of the ownership of the LIKE token to a new version of MasterLike.
    bool public ownsLike = true;

    // Referral contract address.
    IReferral public referral;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 200;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event UpdateEmissionRate(address indexed user, uint256 likePerBlock);
    event SafeLikeUpgrade(
        address indexed user,
        address indexed newMasterLike
    );
    event ReferralCommissionPaid(
        address indexed user,
        address indexed referrer,
        uint256 commissionAmount
    );

    constructor(
        LikeToken _like,
        uint256 _likePerBlock,
        uint256 _startBlock
    ) public {
        like = _like;
        likePerBlock = _likePerBlock;
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

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IBEP20 _lpToken,
        bool _withUpdate
    ) public onlyOwner nonDuplicated(_lpToken) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accLikePerShare: 0
            })
        );
    }

    // Update the given pool's LIKE allocation point. Can only be called by the owner.
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

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending LIKE on frontend.
    function pendingLike(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accLikePerShare = pool.accLikePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 likeReward = multiplier
            .mul(likePerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
            accLikePerShare = accLikePerShare.add(
                likeReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accLikePerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 likeReward = multiplier
        .mul(likePerBlock)
        .mul(pool.allocPoint)
        .div(totalAllocPoint);

        // Minting new tokens is not possible after Governance has approved the ownership transfer of the LIKE token
        // Rewards would be stopped. This condition ensures that withdraws don't fail, so funds can always be taken out
        if (ownsLike) {
            like.mint(address(this), likeReward);
        }

        pool.accLikePerShare = pool.accLikePerShare.add(
            likeReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterLike for LIKE allocation.
    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _referrer
    ) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        if (
            _amount > 0 &&
            address(referral) != address(0) &&
            _referrer != address(0) &&
            _referrer != msg.sender
        ) {
            referral.recordReferral(msg.sender, _referrer);
        }

        if (user.amount > 0) {
            uint256 pending = user
            .amount
            .mul(pool.accLikePerShare)
            .div(1e12)
            .sub(user.rewardDebt);
            if (pending > 0) {
                safeLikeTransfer(msg.sender, pending);
                payReferralCommission(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accLikePerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterLike.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accLikePerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (pending > 0 && ownsLike) {
            safeLikeTransfer(msg.sender, pending);
            payReferralCommission(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accLikePerShare).div(1e12);
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

    // Safe like transfer function, just in case if rounding error causes pool to not have enough LIKE.
    function safeLikeTransfer(address _to, uint256 _amount) internal {
        uint256 likeBal = like.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > likeBal) {
            transferSuccess = like.transfer(_to, likeBal);
        } else {
            transferSuccess = like.transfer(_to, _amount);
        }
        require(transferSuccess, "safeLikeTransfer: transfer failed");
    }

    // Updates on emission rates must be approved and executed by Governance
    function updateEmissionRate(uint256 _likePerBlock) public onlyOwner {
        massUpdatePools();
        likePerBlock = _likePerBlock;
        emit UpdateEmissionRate(msg.sender, _likePerBlock);
    }

    // Governance can vote for transferring the ownership of the LIKE token to a new version of MasterLike
    // Existent LPs won't be migrated, is up to the users to move if they agree with the new contract
    // Rewards would be stopped, but withdraws will keep working
    function safeLikeUpgrade(address _newMasterLike) public onlyOwner {
        require(
            address(_newMasterLike) != address(0),
            "safeLikeUpgrade: no new master planet"
        );
        ownsLike = false;
        like.transferOwnership(_newMasterLike);
        emit SafeLikeUpgrade(msg.sender, _newMasterLike);
    }

    // Allows to update the referral contract. It must be approved and executed by Governance
    function setReferral(IReferral _referral) public onlyOwner {
        referral = _referral;
    }

    // Updates must be approved and executed by Governance
    function setReferralCommissionRate(uint16 _referralCommissionRate)
        public
        onlyOwner
    {
        referralCommissionRate = _referralCommissionRate;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(referral) != address(0) && referralCommissionRate > 0) {
            address referrer = referral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(
                10000
            );

            if (referrer != address(0) && commissionAmount > 0) {
                like.mint(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }
}