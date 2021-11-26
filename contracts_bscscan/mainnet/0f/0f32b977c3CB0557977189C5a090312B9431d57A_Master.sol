pragma solidity 0.5.8;

import "./ITRC20.sol";
import "./TRC20.sol";
import "./STToken.sol";
import "./Pausable.sol";
import "./Refer.sol";
import "./TransferHelper.sol";


contract Master is Pausable {
    using SafeMath for uint256;

    /////////////////////////////////////////////////////////
    // for testnet
    bool public flagTestNet = false;
    function setTestFlag(bool flag) public returns (bool) {
        flagTestNet = flag;
        return flagTestNet;
    }
    /////////////////////////////////////////////////////////

    struct ReferRecord {
        address addr;
        uint256 amount;
    }

    // 用户的持币挖矿信息
    struct UserInfo {
        uint256 amount;   // staking MOT amount
        uint256 minePoolPower; // mine pool power
        uint256 referPower;  // refer power
        uint256 shares;  // shares
        uint256 rewardDebt;  //
        uint256 totalReward; // stat, total reward
    }

    uint256 internal minePoolID = 1;

    struct UserMinePool {
        uint256 id;
        address owner;
        bytes32 name;
        uint256 amount; // staking ST amount
        uint256 shares; // shares
        uint256 rewardDebt;
        uint256 totalReward; // stat, total reward
    }

    mapping (address => UserMinePool) public userMinePoolInfo;

    struct PoolInfo {
        uint256 weight;
        uint256 lastRewardTime;
        uint256 accSTPerShare;
        uint256 totalShares;
    }
    PoolInfo[] public poolInfo;

    STToken public st;

    address public mot;

    uint256 public stPerSecond = 243055e12; // 21000 ST per day
    uint256 public minStakingMOT = 100e18;
    uint256 public V3PoolMinSTAmount = 3000e18;
    uint256 public V4PoolMinSTAmount = 5000e18;
    uint256 public V5PoolMinSTAmount = 8000e18;
    uint256 private constant ACC_PRECISION = 1e12;

    uint256 public totalPower; // total power

    mapping (address => UserInfo) public userInfo;

    Refer public refer;

    uint256 constant LEVEL_1 = 1;
    uint256 constant LEVEL_2 = 2;
    uint256 constant LEVEL_3 = 3;
    uint256 constant LEVEL_4 = 4;
    uint256 constant LEVEL_5 = 5;

    uint256 constant UPGRADE_REFER_COUNT = 3;

    // address => user level
    mapping (address => uint256) levelMapping;

    // Events
    event UpgradeLevel(address indexed user, uint256 level);
    event Staking(address indexed user, uint256 amount);
    event Unstaking(address indexed user, uint256 amount);
    event StakingGDX(address indexed user, uint amount);
    event UnstakingGDX(address indexed user, uint256 amount);
    event WithdrawReward(address indexed user);
    event WithdrawStakingReward(address indexed user);
    event WithdrawMinePoolReward(address indexed user);

    constructor (
        STToken _st,
        address _mot,
        Refer _refer
    ) public {
        st = _st;
        mot = _mot;
        refer = _refer;

        // staking MOT, 80%
        poolInfo.push(PoolInfo({
            weight:80,
            lastRewardTime:block.timestamp,
            accSTPerShare:0,
            totalShares:0
        }));

        // miner pool, 20%
        poolInfo.push(PoolInfo({
            weight:20,
            lastRewardTime:block.timestamp,
            accSTPerShare:0,
            totalShares:0
        }));
    }

    function massUpdatePools() public {
        updateMOTPool();
        updateSTPool();
    }

    function updateMOTPool() public {
        updatePool(0);
    }

    function updateSTPool() public {
        updatePool(1);
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        uint256 totalSupply = pool.totalShares;
        if (totalSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }

        uint256 secds = block.timestamp.sub(pool.lastRewardTime);
        uint256 stReward = secds.mul(stPerSecond).mul(pool.weight).div(100);
        if (st.totalSupply().add(stReward) >= st.MAX_SUPPLY()) {
            stReward = st.MAX_SUPPLY().sub(st.totalSupply());
        }
        st.mint(address(this), stReward);
        pool.accSTPerShare = pool.accSTPerShare.add(stReward.mul(ACC_PRECISION).div(totalSupply));
        pool.lastRewardTime = block.timestamp;
    }

    function updateUserStakingShares(address _usr) internal {
        UserInfo storage user = userInfo[_usr];
        PoolInfo storage pool = poolInfo[0];

        uint256 preUsrShares = user.shares;

        user.shares = user.amount.add(user.referPower).add(user.minePoolPower);
        user.rewardDebt = user.shares.mul(poolInfo[0].accSTPerShare).div(ACC_PRECISION);
        pool.totalShares = pool.totalShares.add(user.shares).sub(preUsrShares);
    }

    function pendingGDXPool(address owner, uint256 pid) public view returns (uint256 pending) {
        uint256 userShares;
        uint256 userRewardDebt;
        if (0 == pid) {
            userShares = userInfo[owner].shares;
            userRewardDebt = userInfo[owner].rewardDebt;
        } else if (1 == pid) {
            userShares = userMinePoolInfo[owner].shares;
            userRewardDebt = userMinePoolInfo[owner].rewardDebt;
        } else {
            return pending;
        }
        PoolInfo storage pool = poolInfo[pid];
        uint256 accSTPerShare = pool.accSTPerShare;
        uint256 totalShares = pool.totalShares;
        if (block.timestamp > pool.lastRewardTime && totalShares != 0) {
            uint256 secds = block.timestamp.sub(pool.lastRewardTime);
            uint256 stReward = secds.mul(stPerSecond).mul(pool.weight).div(100); // 80% of st per block
            accSTPerShare = accSTPerShare.add(stReward.mul(ACC_PRECISION).div(totalShares));
        }
        pending = userShares.mul(accSTPerShare).div(ACC_PRECISION).sub(userRewardDebt);
    }

    function pendingSTUsr(address owner) public view returns (uint256) {
        // pool 0
        uint256 stakingReward = pendingGDXPool(owner, 0);
        if (userMinePoolInfo[owner].owner == address(0))  { // not mine pool owner
            return stakingReward;
        }

        // pool 1
        uint256 miningPoolReward = pendingGDXPool(owner, 1);
        return stakingReward.add(miningPoolReward);
    }

    // add totalPower
    function addTotalPower(uint256 value) internal {
        totalPower = totalPower.add(value);
    }

    // sub totalPower
    function subTotalPower(uint256 value) internal {
        require(totalPower >= value, "total power < value");
        totalPower = totalPower.sub(value);
    }

    function payStakingReward(address owner) internal {
        UserInfo storage user = userInfo[owner];
        if (user.shares > 0) {
            uint256 reward = user.shares.mul(poolInfo[0].accSTPerShare).div(ACC_PRECISION);
            uint256 pending = reward.sub(user.rewardDebt);
            safeSTTransfer(owner, pending);
            // stat
            user.totalReward = user.totalReward.add(pending);
        }
    }

    function getMinePoolOwnerLevel(address owner) public view returns (uint256 level) {
        uint256 stAmount = userMinePoolInfo[owner].amount;
        level = getLevel(owner);
        if (level == LEVEL_5) {
            if (stAmount >= V5PoolMinSTAmount) {
            } else if (stAmount >= V4PoolMinSTAmount) {
                level = LEVEL_4;
            } else if (stAmount >= V3PoolMinSTAmount) {
                level = LEVEL_3;
            } else {
                level = LEVEL_2;
            }
        } else if (level == LEVEL_4) {
            if (stAmount >= V4PoolMinSTAmount) {
            } else if (stAmount >= V3PoolMinSTAmount) {
                level = LEVEL_3;
            } else {
                level = LEVEL_2;
            }
        } else if (level == LEVEL_3) {
            if (stAmount >= V3PoolMinSTAmount) {
            } else {
                level = LEVEL_2;
            }
        }
    }

    function calcUsrPoolPower(address owner) public view returns (uint256) {
        uint256 poolPower = getUsrStakingPower(owner);
        address[] memory layer1 = getInviteList(owner);
        for (uint256 i = 0; i < layer1.length; i++) {
            address user1 = layer1[i];
            poolPower = poolPower.add(userInfo[user1].amount);
            address[] memory layer2 = getInviteList(user1);
            for (uint256 j = 0; j < layer2.length; j++) {
                address user2 = layer2[j];
                poolPower = poolPower.add(userInfo[user2].amount);
                address[] memory layer3 = getInviteList(user2);
                for (uint256 k = 0; k < layer3.length; k++) {
                    address user3 = layer3[k];
                    poolPower = poolPower.add(userInfo[user3].amount);
                    address[] memory layer4 = getInviteList(user3);
                    for (uint256 l = 0; l < layer4.length; l++) {
                        address user4 = layer4[l];
                        poolPower = poolPower.add(userInfo[user4].amount);
                    }
                }
            }
        }

        uint256 level = getMinePoolOwnerLevel(owner);
        if (level == LEVEL_3) {
            return poolPower.mul(5).div(100);
        } else if (level == LEVEL_4) {
            return poolPower.mul(8).div(100);
        } else if (level == LEVEL_5) {
            return poolPower.mul(10).div(100);
        } else {
            return 0;
        }
    }

    function getLayer1ReferPower(address owner) public view returns (uint256) {
        uint256 referPower;
        address[] memory layer1 = getInviteList(owner);
        for (uint256 i = 0; i < layer1.length; i++) {
            address user1 = layer1[i];
            referPower = referPower.add(userInfo[user1].amount);
        }
        return referPower.mul(20).div(100);
    }

    function getLayer2ReferPower(address owner) public view returns (uint256) {
        uint256 referPower;
        address[] memory layer1 = getInviteList(owner);
        for (uint256 i = 0; i < layer1.length; i++) {
            address user1 = layer1[i];
            referPower = referPower.add(userInfo[user1].amount.mul(20).div(100));
            address[] memory layer2 = getInviteList(user1);
            for (uint256 j = 0; j < layer2.length; j++) {
                address user2 = layer2[j];
                referPower = referPower.add(userInfo[user2].amount.mul(10).div(100));
            }
        }
        return referPower;
    }

    function getLayer3ReferPower(address owner) public view returns (uint256) {
        uint256 referPower;
        address[] memory layer1 = getInviteList(owner);
        for (uint256 i = 0; i < layer1.length; i++) {
            address user1 = layer1[i];
            referPower = referPower.add(userInfo[user1].amount.mul(20).div(100));
            address[] memory layer2 = getInviteList(user1);
            for (uint256 j = 0; j < layer2.length; j++) {
                address user2 = layer2[j];
                referPower = referPower.add(userInfo[user2].amount.mul(10).div(100));
                address[] memory layer3 = getInviteList(user2);
                for (uint256 k = 0; k < layer3.length; k++) {
                    address user3 = layer3[k];
                    referPower = referPower.add(userInfo[user3].amount.mul(4).div(100));
                }
            }
        }
        return referPower;
    }

    function getLayer4ReferPower(address owner) public view returns (uint256) {
        uint256 referPower;
        address[] memory layer1 = getInviteList(owner);
        for (uint256 i = 0; i < layer1.length; i++) {
            address user1 = layer1[i];
            referPower = referPower.add(userInfo[user1].amount.mul(20).div(100));
            address[] memory layer2 = getInviteList(user1);
            for (uint256 j = 0; j < layer2.length; j++) {
                address user2 = layer2[j];
                referPower = referPower.add(userInfo[user2].amount.mul(10).div(100));
                address[] memory layer3 = getInviteList(user2);
                for (uint256 k = 0; k < layer3.length; k++) {
                    address user3 = layer3[k];
                    referPower = referPower.add(userInfo[user3].amount.mul(4).div(100));
                    address[] memory layer4 = getInviteList(user3);
                    for (uint256 l = 0; l < layer4.length; l++) {
                        address user4 = layer4[l];
                        referPower = referPower.add(userInfo[user4].amount.mul(4).div(100));
                    }
                }
            }
        }
        return referPower;
    }

    function calcUsrReferPower(address owner) public view returns (uint256) {
        uint256 level = getLevel(owner);
        if (level == 0) {
            return 0;
        } else if (level == LEVEL_1) {
            return getLayer1ReferPower(owner);
        } else if (level == LEVEL_2) {
            return getLayer2ReferPower(owner);
        } else if (level == LEVEL_3){
            return getLayer3ReferPower(owner);
        } else {
            return getLayer4ReferPower(owner);
        }
    }

    function updateUsrReferPower(address owner) public {
        updateMOTPool();

        UserInfo storage user = userInfo[owner];
        PoolInfo storage pool = poolInfo[0];

        payStakingReward(owner);

        uint256 preReferPower = user.referPower;
        uint256 preUsrShares = user.shares;

        user.referPower = calcUsrReferPower(owner);
        user.shares = user.amount.add(user.referPower).add(user.minePoolPower);
        user.rewardDebt = user.shares.mul(pool.accSTPerShare).div(ACC_PRECISION);
        pool.totalShares = pool.totalShares.add(user.shares).sub(preUsrShares);
        // stat
        totalPower = totalPower.add(user.referPower).sub(preReferPower);
    }

    function updateUsrPoolPower(address owner) public {
        updateMOTPool();

        UserInfo storage user = userInfo[owner];
        PoolInfo storage pool = poolInfo[0];

        payStakingReward(owner);

        uint256 preMinePoolPower = user.minePoolPower;
        uint256 preUsrShares = user.shares;

        user.minePoolPower = calcUsrPoolPower(owner);
        user.shares = user.amount.add(user.referPower).add(user.minePoolPower);
        user.rewardDebt = user.shares.mul(pool.accSTPerShare).div(ACC_PRECISION);
        pool.totalShares = pool.totalShares.add(user.shares).sub(preUsrShares);

        // stat
        totalPower = totalPower.add(user.minePoolPower).sub(preMinePoolPower);
    }

    // MOT mining
    function staking(uint256 _amount, address referrer) public WhenNotPaused {
        address sender = msg.sender;
        require(_amount > 0, "stake amount not good");
        updateMOTPool();

        UserInfo storage user = userInfo[sender];
        PoolInfo storage pool = poolInfo[0];

        payStakingReward(sender);

        // transfer MOT
        TransferHelper.safeTransferFrom(mot, sender, address(this), _amount);

        // update shares
        uint256 preShares = user.shares;
        user.amount = user.amount.add(_amount);
        user.shares = user.amount.add(user.referPower).add(user.minePoolPower);
        user.rewardDebt = user.shares.mul(pool.accSTPerShare).div(ACC_PRECISION);
        pool.totalShares = pool.totalShares.add(user.shares).sub(preShares);
        // stat
        addTotalPower(_amount);

        refer.submitRefer(sender, referrer);

        emit Staking(sender, _amount);
    }

    // unstaking MOT
    function unstaking(uint256 _amount) public {
        address sender = msg.sender;
        UserInfo storage user = userInfo[sender];
        require(user.amount >= _amount, "unstaking amount not good");
        updateMOTPool();

        payStakingReward(sender);

        PoolInfo storage pool = poolInfo[0];

        // transfer MOT
        TransferHelper.safeTransfer(mot, sender, _amount);

        // update shares
        uint256 preShares = user.shares;
        user.amount = user.amount.sub(_amount);
        user.shares = user.amount.add(user.referPower).add(user.minePoolPower);
        user.rewardDebt = user.shares.mul(pool.accSTPerShare).div(ACC_PRECISION);
        // stat
        pool.totalShares = pool.totalShares.add(user.shares).sub(preShares);

        subTotalPower(_amount);

        emit Unstaking(msg.sender, _amount);
    }

    function withdrawStakingReward(address owner) public {
        updateMOTPool();

        // staking reward
        payStakingReward(owner);
        updateUserStakingShares(owner);

        emit WithdrawStakingReward(owner);
    }

    function withdrawMinePoolReward(address owner) public {
        // mine pool reward
        UserMinePool storage minePool = userMinePoolInfo[owner];
        if (minePool.owner == address(0)) {
            return;
        }

        updateSTPool();

        if (minePool.shares > 0) {
            uint256 reward = minePool.shares.mul(poolInfo[1].accSTPerShare).div(ACC_PRECISION);
            uint256 pending = reward.sub(minePool.rewardDebt);
            safeSTTransfer(owner, pending);
            minePool.rewardDebt = minePool.shares.mul(poolInfo[1].accSTPerShare).div(ACC_PRECISION);
            minePool.totalReward = minePool.totalReward.add(pending);
        }

        emit WithdrawMinePoolReward(owner);
    }

    function withdrawReward() public {
        address sender = msg.sender;
        withdrawStakingReward(sender);
        withdrawMinePoolReward(sender);
    }

    function createPool(bytes32 name, uint256 amount) public returns (bool) {
        address sender = msg.sender;
        uint256 level = getLevel(sender) ;
        require(level >= LEVEL_3, "user level not good");

        UserMinePool storage minePool = userMinePoolInfo[sender];
        PoolInfo storage pool = poolInfo[1];
        require(minePool.owner == address(0), "pool already exist");

        if (level == LEVEL_3) {
            require(amount >= V3PoolMinSTAmount, "V3 need 3000 ST");
        }
        if (level == LEVEL_4) {
            require(amount >= V4PoolMinSTAmount, "V4 need 5000 ST");
        }
        if (level == LEVEL_5) {
            require(amount >= V5PoolMinSTAmount, "V5 need 8000 ST");
        }

        updateSTPool();

        // transfer ST
        require(st.transferFrom(sender, address(this), amount), "createPool: transfer failed");

        // creat mine pool
        minePool.id = getNewPoolID();
        minePool.owner = sender;
        minePool.name = name;
        minePool.amount = amount;
        minePool.shares = calcUsrMinePoolShares(sender, amount, false);
        minePool.rewardDebt = minePool.shares.mul(pool.accSTPerShare).div(ACC_PRECISION);
        minePool.totalReward = 0;

        // update pool total shares
        pool.totalShares = pool.totalShares.add(minePool.shares);

        // MOT mining
        updateMOTPool();
        payStakingReward(sender);
        userInfo[sender].minePoolPower = calcUsrPoolPower(sender);
        updateUserStakingShares(sender);
        return true;
    }

    function getNewPoolID() internal returns (uint256 id) {
        id = minePoolID;
        minePoolID = minePoolID.add(1);
    }

    function stakingGDX(uint256 amount) public WhenNotPaused {
        address sender = msg.sender;
        UserMinePool storage minePool = userMinePoolInfo[sender];
        require(minePool.owner != address(0), "no mine pool");

        require(st.transferFrom(sender, address(this), amount), "stakingGDX: transfer failed");

        updateSTPool();
        PoolInfo storage pool = poolInfo[1];

        if (minePool.shares > 0) {
            uint256 reward = minePool.shares.mul(pool.accSTPerShare).div(ACC_PRECISION);
            uint256 pending = reward.sub(minePool.rewardDebt);
            safeSTTransfer(sender, pending);
            // stat
            minePool.totalReward = minePool.totalReward.add(pending);
        }

        uint256 preShares = minePool.shares;
        minePool.amount = minePool.amount.add(amount);
        minePool.shares = calcUsrMinePoolShares(sender, minePool.amount, true);
        minePool.rewardDebt = minePool.shares.mul(pool.accSTPerShare).div(ACC_PRECISION);
        pool.totalShares = pool.totalShares.add(minePool.shares).sub(preShares);

        // update mine pool power
        updateUsrPoolPower(sender);

        emit StakingGDX(sender, amount);
    }

    function calcUsrMinePoolShares(address owner, uint256 amount, bool getPoolLevel) internal view returns (uint256) {
        uint256 level;
        if (getPoolLevel) {
            level = getMinePoolOwnerLevel(owner);
        } else {
            level = getLevel(owner);
        }
        if (LEVEL_5 == level) {
            return amount.mul(10);
        } else if (LEVEL_4 == level) {
            return amount.mul(6);
        } else if (LEVEL_3 == level) {
            return amount.mul(4);
        } else {
            return 0;
        }
    }

    function unstakingGDX(uint256 amount) public {
        address sender = msg.sender;
        UserMinePool storage minePool = userMinePoolInfo[sender];

        require(minePool.owner != address(0), "no mine pool");
        require(minePool.amount >= amount, "unstaking amount too large than user");

        updateSTPool();
        PoolInfo storage pool = poolInfo[1];

        if (minePool.shares > 0) {
            uint256 reward = minePool.shares.mul(pool.accSTPerShare).div(ACC_PRECISION);
            uint256 pending = reward.sub(minePool.rewardDebt);
            safeSTTransfer(sender, pending);
            // stat
            minePool.totalReward = minePool.totalReward.add(pending);
        }

        require(st.transfer(sender, amount), "unstakingGDX: transfer failed");

        uint256 preShares = minePool.shares;
        minePool.amount = minePool.amount.sub(amount);
        minePool.shares = calcUsrMinePoolShares(sender, minePool.amount, true);
        minePool.rewardDebt = minePool.shares.mul(pool.accSTPerShare).div(ACC_PRECISION);
        pool.totalShares = pool.totalShares.add(minePool.shares).sub(preShares);

        // update mine pool power
        updateUsrPoolPower(sender);

        emit UnstakingGDX(sender, amount);
    }

    // get user level
    function getLevel(address owner) public view returns (uint256) {
        return levelMapping[owner];
    }

    // get invite list
    function getInviteList(address usr) public view returns (address[] memory) {
        uint256 referLen = refer.getReferLength(usr);
        address[] memory addrList = new address[](referLen);
        for(uint256 i = 0; i < referLen; i++) {
            addrList[i] = refer.referList(usr, i);
        }
        return addrList;
    }

    function canUpgradeLevel(address owner, uint256 levl) public view returns (bool) {
        ///////////////////////////////////////////
        if (flagTestNet) {
            return true;
        }
        ///////////////////////////////////////////

        address sender = msg.sender;

        if (getLevel(owner) >= levl || levl >= LEVEL_5) {
            return false;
        }

        address[] memory list = getInviteList(sender);
        uint256 cnt = 0;
        for(uint256 i = 0; i < list.length; i++) {
            address addr = list[i];
            uint256 stakingPower = getUsrStakingPower(addr);
            if (getLevel(addr) >= levl.sub(1) && (stakingPower > 0)) {
                cnt++;
            }
        }
        if (cnt < UPGRADE_REFER_COUNT) {
            return false;
        }

        return true;
    }

    function upgradeLevel(address owner, uint256 levl) public {
        ///////////////////////////////////////////
        if (flagTestNet) {
            levelMapping[owner] = levl;
            return;
        }
        ///////////////////////////////////////////

        require(canUpgradeLevel(owner, levl), "can't upgrade");

        levelMapping[owner] = levl;
        updateUsrReferPower(owner);

        emit UpgradeLevel(owner, levl);
    }

    function getTotalPower() public view returns (uint256) {
        return totalPower;
    }

    function getUserMingPoolGDXAmount(address usr) public view returns (uint256) {
        return userMinePoolInfo[usr].amount;
    }

    function getUsrPoolPower(address usr) public view returns (uint256) {
        return userInfo[usr].minePoolPower;
    }

    function getUsrStakingPower(address usr) public view returns (uint256) {
        UserInfo storage info = userInfo[usr];
        if (info.amount >= minStakingMOT) {
            return info.amount;
        }
        return 0;
    }

    function getUsrTotalReward(address owner) public view returns (uint256) {
        return userInfo[owner].totalReward.add(userMinePoolInfo[owner].totalReward);
    }

    function getReferPower(address owner) public view returns (uint256) {
        UserInfo storage info = userInfo[owner];
        if (info.amount >= minStakingMOT) {
            return info.referPower;
        }
        return 0;
    }

    function getReferLength(address owner) public view returns (uint256) {
        return refer.getReferLength(owner);
    }

    function queryUsrStats(address owner) public view returns
           (address inviter, uint256 motAmount, uint256 stAmount, uint256 motBalance, uint256 stBalance,
            uint256 level, uint256 totalReward, uint256 pendingReward, uint256 referPower, uint256 minePoolPower) {
        inviter = refer.getReferrer(owner);
        motAmount = userInfo[owner].amount;
        stAmount = userMinePoolInfo[owner].amount;
        motBalance = ITRC20(mot).balanceOf(owner);
        stBalance = st.balanceOf(owner);
        level = getLevel(owner);
        totalReward = getUsrTotalReward(owner);
        pendingReward = pendingSTUsr(owner);
        referPower = getReferPower(owner);
        minePoolPower = userInfo[owner].minePoolPower;
    }

    function safeSTTransfer(address _to, uint256 _amount) internal {
        uint256 stBalance = st.balanceOf(address(this));
        if (_amount > stBalance) {
            st.transfer(_to, stBalance);
        } else {
            st.transfer(_to, _amount);
        }
    }

    function setMOT(address _mot) public onlyOwner {
        mot = _mot;
    }

    function setRefer(Refer _refer) public onlyOwner {
        refer = _refer;
    }

    function setST(STToken _st) public onlyOwner {
        st = _st;
    }

    function setTotalPower(uint256 value) public onlyOwner {
        totalPower = value;
    }

    function transferSTTokenOwnership(address newOwner) public onlyOwner {
        st.transferOwnership(newOwner);
    }

    function withdrawMOT(uint256 amount) public onlyOwner returns (bool) {
        ITRC20(mot).transfer(msg.sender, amount);
        return true;
    }

    function withdrawST(uint256 amount) public onlyOwner returns (bool) {
        safeSTTransfer(msg.sender, amount);
        return true;
    }
}