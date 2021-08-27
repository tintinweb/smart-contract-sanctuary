// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./SafeBEP20.sol";
import "./RedBerryToken.sol";

// File: contracts\MasterChef.sol
// MasterChef is the master of RedBerry. He can make RedBerry and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once REDB is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 depositeTime; // Token deposit time.
        uint256 totalClaimedAmount; // How many rewards claimed by user.
        uint256 nextHarvestUntil; // When can the user harvest again.
        //
        // We do some fancy math here. Basically, any point in time, the amount of REDBs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRedBerryPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRedBerryPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. REDBs to distribute per block.
        uint256 lastRewardBlock; // Last block number that REDBs distribution occurs.
        uint256 accRedBerryPerShare; // Accumulated REDBs per share, times 1e12. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
        uint256 startBlock; // Pool start block
        uint256 poolLimit; // Pool limit for total deposit
        uint256 poolLimitPerUser; // The pool limit for users
        uint256 totalStaked; // Number of token staked
        uint256 totalUsers; // Total User in this Pool
        uint256 claimedReward; // Total climed reward
        uint256 harvestLockupTime; // Harvest interval in seconds
    }

    // The RedBerry TOKEN!
    RedBerryToken public RedBerry;
    // Dev address.
    address public devaddr;
    // REDB tokens created per block.
    uint256 public redBerryPerBlock;
    // Bonus muliplier for early redBerry makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when REDB mining starts.
    uint256 public startBlock;
    // Max harvest interval: 14 days in Seconds 1209600.
    uint256 public constant MAX_HARVEST_LOCKUP_TIME = 1209600;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRateForAll = 100;
    uint16 public referralCommissionRateForNew = 200;
    uint256 public timeForSetNewCommissionRate = 0;
    // Max referral commission rate: 10%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 1000;

    mapping(address => address) public userReferrers;
    mapping(uint256 => mapping(address => uint256)) public userReferalAmount;
    mapping(uint256 => mapping(address => uint256)) public userReferalClaimedAmount;
    mapping(uint256 => mapping(address => uint256)) public userPoolReferal;
    mapping(address => address[]) private userReferal;
    mapping(IBEP20 => bool) public tokenFarmExists;
    mapping(IBEP20 => uint256) public stakedTokenAmount;
    mapping(uint256 => bool) public poolPause;

    // for white listed user
    mapping(address => bool) public whitelistedUser;
    address[] private whitelistedUserList;

    // IRedBerryReferral public redBerryReferral;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event TokenRecovery(address indexed tokenAddress, uint256 tokenAmount);

    constructor(
        RedBerryToken _redBerry,
        address _devaddr,
        address _feeAddress,
        uint256 _redBerryPerBlock,
        uint256 _startBlock
    ) {
        RedBerry = _redBerry;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        redBerryPerBlock = _redBerryPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function poolInfoReward(uint256 _pid)
        external
        view
        returns (
            uint256 currentRewardBlock,
            uint256 pendingRewardMint,
            uint256 claimedReward,
            uint256 totalReward
        )
    {
        PoolInfo memory pool = poolInfo[_pid];

        uint256 accRedBerryPerShare = pool.accRedBerryPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 redBerryReward = multiplier
                .mul(redBerryPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accRedBerryPerShare = accRedBerryPerShare.add(
                redBerryReward.mul(1e12).div(lpSupply)
            );
        }
        uint256 pending = pool
            .totalStaked
            .mul(accRedBerryPerShare)
            .div(1e12)
            .sub(pool.claimedReward);

        return (
            block.number,
            pending,
            pool.claimedReward,
            pending.add(pool.claimedReward)
        );
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IBEP20 _lpToken,
        uint16 _depositFeeBP,
        bool _withUpdate,
        uint256 _harvestLockupTime,
        uint256 _startBlock
    ) public onlyOwner {
        require(
            _depositFeeBP <= 10000,
            "add: invalid deposit fee basis points"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRedBerryPerShare: 0,
                depositFeeBP: _depositFeeBP,
                startBlock: _startBlock,
                poolLimit: 0,
                poolLimitPerUser: 0,
                totalStaked: 0,
                totalUsers: 0,
                claimedReward: 0,
                harvestLockupTime: _harvestLockupTime
            })
        );
        tokenFarmExists[_lpToken] = true;
    }

    // Update the given pool's harvestLockupTime, Can only be called by the owner.
    function setLockupTime(uint256 _pid, uint256 _harvestLockupTime)
        public
        onlyOwner
    {
        require(
            _harvestLockupTime <= MAX_HARVEST_LOCKUP_TIME,
            "Max Harvest lockup time limit"
        );
        PoolInfo storage pool = poolInfo[_pid];

        pool.harvestLockupTime = _harvestLockupTime;
    }

    // Update the given pool's REDB allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
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
    }

    // Update the given pool's poolLimitPerUser & poolLimit. Can only be called by the owner.
    function setLimit(
        uint256 _pid,
        uint256 _poolLimitPerUser,
        uint256 _poolLimit
    ) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];

        pool.poolLimitPerUser = _poolLimitPerUser;
        pool.poolLimit = _poolLimit;
    }

    function pauseFarm(uint256 _pid) public onlyOwner {
        poolPause[_pid] = true;
    }

    function unpauseFarm(uint256 _pid) public onlyOwner {
        poolPause[_pid] = false;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    // View function to see pending redBerrys on frontend.
    function pendingRedBerry(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRedBerryPerShare = pool.accRedBerryPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 redBerryReward = multiplier
                .mul(redBerryPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accRedBerryPerShare = accRedBerryPerShare.add(
                redBerryReward.mul(1e12).div(lpSupply)
            );
        }
        return
            user.amount.mul(accRedBerryPerShare).div(1e12).sub(user.rewardDebt);
    }

    // View function to see if user can harvest redBerrys.
    function canHarvest(uint256 _pid, address _userAddress)
        public
        view
        returns (bool)
    {
        UserInfo storage user = userInfo[_pid][_userAddress];

        return block.timestamp >= user.nextHarvestUntil;
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
        uint256 redBerryReward = multiplier
            .mul(redBerryPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        RedBerry.mint(devaddr, redBerryReward.div(10));
        RedBerry.mint(address(this), redBerryReward);
        pool.accRedBerryPerShare = pool.accRedBerryPerShare.add(
            redBerryReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for REDB allocation.
    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _referrer
    ) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        require(block.number >= pool.startBlock, "Pool is not started yet");
        if (_amount > 0) {
            require(!poolPause[_pid], "PAUSED");
        }

        if (whitelistedUser[msg.sender] != true) {
            if (pool.poolLimit > 0) {
                require(
                    _amount.add(pool.totalStaked) <= pool.poolLimit,
                    "Pool amount above limit"
                );
            }

            if (pool.poolLimitPerUser > 0) {
                require(
                    _amount.add(user.amount) <= pool.poolLimitPerUser,
                    "User amount above limit"
                );
            }
        }

        if (
            _amount > 0 &&
            _referrer != address(0) &&
            _referrer != msg.sender &&
            user.amount == 0 &&
            _pid != 0
        ) {
            userReferal[_referrer].push(msg.sender);
            userReferrers[msg.sender] = _referrer;
        }
        payOrLockupPendingredb(_pid);
        if (user.amount > 0) {
            uint256 _pendingAmount = 0;
            uint256 pending = user
                .amount
                .mul(pool.accRedBerryPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            uint256 referarBalance = userReferalAmount[_pid][msg.sender];
            if (referarBalance > 0) {
                userReferalClaimedAmount[_pid][
                    msg.sender
                ] = userReferalClaimedAmount[_pid][msg.sender].add(
                    referarBalance
                );
                userReferalAmount[_pid][msg.sender] = 0;
                _pendingAmount = pending.add(referarBalance);
            } else {
                _pendingAmount = pending;
            }
            user.totalClaimedAmount = user.totalClaimedAmount.add(pending);
            if (_pendingAmount > 0) {
                if (canHarvest(_pid, msg.sender)) {
                    pool.claimedReward = pool.claimedReward.add(pending);
                    user.nextHarvestUntil = block.timestamp.add(
                        pool.harvestLockupTime
                    );
                    safeRedBerryTransfer(msg.sender, _pendingAmount);
                }
            }
        } else {
            user.depositeTime = block.timestamp;
            pool.totalUsers += 1;
            user.nextHarvestUntil = block.timestamp.add(pool.harvestLockupTime);
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            if (pool.depositFeeBP > 0 && whitelistedUser[msg.sender] != true) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
                pool.totalStaked = pool.totalStaked.add(_amount).sub(
                    depositFee
                );
            } else {
                user.amount = user.amount.add(_amount);
                pool.totalStaked = pool.totalStaked.add(_amount);
            }
        }
        stakedTokenAmount[pool.lpToken] = stakedTokenAmount[pool.lpToken].add(
            _amount
        );
        user.rewardDebt = user.amount.mul(pool.accRedBerryPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    //claim reward
    function harvest(uint256 _pid) public {
        require(canHarvest(_pid, msg.sender), "Harvest Lock");
        deposit(_pid, 0, address(0));
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        payOrLockupPendingredb(_pid);

        uint256 _pendingAmount = 0;
        uint256 pending = user
            .amount
            .mul(pool.accRedBerryPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
        uint256 referarBalance = userReferalAmount[_pid][msg.sender];
        if (referarBalance > 0) {
            userReferalClaimedAmount[_pid][
                msg.sender
            ] = userReferalClaimedAmount[_pid][msg.sender].add(referarBalance);
            userReferalAmount[_pid][msg.sender] = 0;
            _pendingAmount = pending.add(referarBalance);
        } else {
            _pendingAmount = pending;
        }
        user.totalClaimedAmount = user.totalClaimedAmount.add(pending);
        if (_pendingAmount > 0) {
            if (canHarvest(_pid, msg.sender)) {
                pool.claimedReward = pool.claimedReward.add(pending);
                user.nextHarvestUntil = block.timestamp.add(
                    pool.harvestLockupTime
                );
                safeRedBerryTransfer(msg.sender, _pendingAmount);
            }
        }

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalStaked = pool.totalStaked.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRedBerryPerShare).div(1e12);
        stakedTokenAmount[pool.lpToken] = stakedTokenAmount[pool.lpToken].sub(
            _amount
        );

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.nextHarvestUntil = 0;
        pool.totalStaked = pool.totalStaked.sub(amount);
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        stakedTokenAmount[pool.lpToken] = stakedTokenAmount[pool.lpToken].sub(
            amount
        );
        userReferalAmount[_pid][msg.sender] = 0;
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe redBerry transfer function, just in case if rounding error causes pool to not have enough REDBs.
    function safeRedBerryTransfer(address _to, uint256 _amount) internal {
        uint256 RedBerryBal = RedBerry.balanceOf(address(this));
        if (_amount > RedBerryBal) {
            RedBerry.transfer(_to, _amount);
        } else {
            RedBerry.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    // Update fee address by the previous fee address.
    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }

    // Redberry can set reward per block, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _redBerryPerBlock) public onlyOwner {
        massUpdatePools();
        redBerryPerBlock = _redBerryPerBlock;
    }

    function payOrLockupPendingredb(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 pending = user
            .amount
            .mul(pool.accRedBerryPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
        if (pending > 0) {
            payReferralCommission(msg.sender, pending, user.depositeTime, _pid);
        }
    }

    // Update referral commission rate by the owner for new users
    function setNewReferralCommissionRate(uint16 _commitionRate)
        public
        onlyOwner
    {
        require(
            _commitionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE,
            "setReferralCommissionRate: invalid referral commission rate basis points"
        );
        referralCommissionRateForNew = _commitionRate;
        timeForSetNewCommissionRate = block.timestamp;
    }

    // Update referral commission start time by the owner for new users
    function setTimeForNewReferralCommissionRate(uint256 _time)
        public
        onlyOwner
    {
        timeForSetNewCommissionRate = _time;
    }

    // Update referral commission rate by the owner for all users
    function setAllReferralCommissionRate(uint16 _commitionRate)
        public
        onlyOwner
    {
        require(
            _commitionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE,
            "setReferralCommissionRate: invalid referral commission rate basis points"
        );
        referralCommissionRateForAll = _commitionRate;
    }

    function payReferralCommission(
        address _user,
        uint256 _pending,
        uint256 _depositeTime,
        uint256 _pid
    ) internal {
        uint256 referralCommissionRate;
        if (
            timeForSetNewCommissionRate > 0 &&
            _depositeTime > timeForSetNewCommissionRate
        ) {
            referralCommissionRate = referralCommissionRateForNew;
        } else {
            referralCommissionRate = referralCommissionRateForAll;
        }
        if (referralCommissionRate > 0) {
            address referrer = userReferrers[_user];
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(
                10000
            );
            UserInfo storage user = userInfo[_pid][referrer];

            if (
                referrer != address(0) &&
                commissionAmount > 0 &&
                user.amount > 0
            ) {
                userReferalAmount[_pid][referrer] =
                    userReferalAmount[_pid][referrer] +
                    commissionAmount;
                userPoolReferal[_pid][referrer] =
                    userPoolReferal[_pid][referrer] +
                    commissionAmount;
            }
        }
    }

    // add Whilisted User by the owner, user will be excluded from Pool Limit and Deposit fee.
    function addUsertoWhitelisted(address _address, bool _bool)
        public
        onlyOwner
    {
        whitelistedUser[_address] = _bool;
        if (_bool == true) {
            whitelistedUserList.push(_address);
        } else {
            for (uint256 i = 0; i < whitelistedUserList.length; i++) {
                if (_address == whitelistedUserList[i]) {
                    for (
                        uint256 j = i;
                        j < whitelistedUserList.length - 1;
                        j++
                    ) {
                        whitelistedUserList[j] = whitelistedUserList[j + 1];
                    }
                    whitelistedUserList.pop();
                }
            }
        }
    }

    function whitelistedUsers() public view returns (address[] memory) {
        return whitelistedUserList;
    }

    // check token balance of smart contract
    function checkTokenBalance(IBEP20 _token) public view returns (uint256) {
        return IBEP20(_token).balanceOf(address(this));
    }

    // Recover the wrong token. Can only be called by the owner.
    function recoverWrongToken(IBEP20 _token, uint256 _tokenAmount)
        public
        onlyOwner
    {
        require(
            checkTokenBalance(_token).sub(stakedTokenAmount[_token]) >=
                _tokenAmount,
            "Cannot withdraw Staked tokens"
        );

        IBEP20(_token).transfer(address(msg.sender), _tokenAmount);
        emit TokenRecovery(address(_token), _tokenAmount);
    }

    function userReferalCount(address _address) public view returns (uint256) {
        return userReferal[_address].length;
    }

    function userReferalList(address _address)
        public
        view
        returns (address[] memory)
    {
        return (userReferal[_address]);
    }
}