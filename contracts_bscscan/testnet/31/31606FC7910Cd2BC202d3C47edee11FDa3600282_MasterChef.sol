pragma solidity 0.6.12;

import './SafeMath.sol';
import './IBEP20.sol';
import './SafeBEP20.sol';
import './Ownable.sol';

import "./FeliCatToken.sol";
import "./FeliCatFish.sol";

// import "@nomiclabs/buidler/console.sol";
//SPDX-License-Identifier: UNLICENSED

interface IMigratorChef {
    // Perform LP token migration from legacy PancakeSwap to CakeSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to PancakeSwap LP tokens.
    // CakeSwap must mint EXACTLY the same amount of CakeSwap LP tokens or
    // else something bad will happen. Traditional PancakeSwap does not
    // do that so be careful!
    function migrate(IBEP20 token) external returns (IBEP20);
}

// MasterChef is the master of Cake. He can make Cake and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once CAKE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 firstDepositBlock;
        uint256 lastWithdrawBlock;
        uint256 lockedFeliCatTokenCount;
        //
        // We do some fancy math here. Basically, any point in time, the amount of CAKEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accCakePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accCakePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that CAKEs distribution occurs.
        uint256 accCakePerShare; // Accumulated CAKEs per share, times 1e12. See below.
    }

    // The FeliCat TOKEN!
    FeliCatToken public cake;
    // The Fish TOKEN!
    FeliCatFish public fish;
    // Dev address.
    address public devaddr;
    // CAKE tokens created per block.
    uint256 public cakePerBlock;
    // Bonus muliplier for early cake makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when CAKE mining starts.
    uint256 public startBlock;
    // The rewards max loccked block(30 days, each block 3s)
    // uint256 public rewardsMaxLockedBlock = 864000;
    uint256 public rewardsMaxLockedBlock = 28800;
    // 24 hours block
    // uint256 private oneDay = 28800; 
    uint256 private oneDay = 600; 
    // FeliCat Halving cycle
    // uint256 public feliCatTokenMaxHalvingBlock = 5184000;
    uint256 public feliCatTokenMaxHalvingBlock = 28800;
    uint256 public currentHalvingCycle = 1;
    uint256 public lastHalvingBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        FeliCatToken _cake,
        FeliCatFish _fish,
        address _devaddr,
        uint256 _cakePerBlock,
        uint256 _startBlock
    ) public {
        cake = _cake;
        fish = _fish;
        devaddr = _devaddr;
        cakePerBlock = _cakePerBlock;
        startBlock = _startBlock;
        lastHalvingBlock = _startBlock;
        
        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _cake,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accCakePerShare: 0
        }));

        totalAllocPoint = 1000;

    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accCakePerShare: 0
        }));
        updateStakingPool();
    }

    // Update the given pool's CAKE allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            updateStakingPool();
        }
    }

    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(points);
            poolInfo[0].allocPoint = points;
        }
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IBEP20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IBEP20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending CAKEs on frontend.
    function pendingCake(uint256 _pid, address _user) external view returns (uint256,uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCakePerShare = pool.accCakePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 cakeReward = multiplier.mul(cakePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCakePerShare = accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        }
        return (user.amount.mul(accCakePerShare).div(1e12).sub(user.rewardDebt),user.lockedFeliCatTokenCount);
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
        cakePerBlock =  cake.maxSupply().div(2 ** currentHalvingCycle).div(feliCatTokenMaxHalvingBlock);
        uint256 cakeReward = multiplier.mul(cakePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        cake.mint(devaddr, cakeReward.div(10));
        cake.mint(address(fish), cakeReward);
        pool.accCakePerShare = pool.accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
        if(block.number.sub(lastHalvingBlock) >= feliCatTokenMaxHalvingBlock){
            currentHalvingCycle = currentHalvingCycle.add(1);
            lastHalvingBlock = block.number;
        }
    }

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'deposit CAKE by staking');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
            uint256 canWithdrawAmount = 0;
            if(pending > 0) {
                if(user.lastWithdrawBlock == 0 || block.number.sub(user.firstDepositBlock) < rewardsMaxLockedBlock){
                    if(block.number.sub(user.lastWithdrawBlock) > oneDay){
                        canWithdrawAmount = pending.div(10);
                        user.lockedFeliCatTokenCount = user.lockedFeliCatTokenCount.add(pending.sub(canWithdrawAmount));
                        safeCakeTransfer(msg.sender, canWithdrawAmount);
                    }else{
                        user.lockedFeliCatTokenCount = user.lockedFeliCatTokenCount.add(pending);
                    }
                }else{
                    if(user.lockedFeliCatTokenCount > 0){
                        canWithdrawAmount = user.lockedFeliCatTokenCount;
                        user.lockedFeliCatTokenCount = 0;
                    }
                    safeCakeTransfer(msg.sender, pending.add(canWithdrawAmount));
                }
                user.lastWithdrawBlock = block.number;
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        if(user.firstDepositBlock == 0){
            user.firstDepositBlock = block.number;
        }
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'withdraw CAKE by unstaking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
        uint256 canWithdrawAmount = 0;
        uint256 lockedWithdrawAmount = 0;
        if(user.lastWithdrawBlock == 0 || block.number.sub(user.firstDepositBlock) < rewardsMaxLockedBlock){
            if(block.number.sub(user.lastWithdrawBlock) > oneDay){
                if(user.lockedFeliCatTokenCount > 0){
                    lockedWithdrawAmount = user.lockedFeliCatTokenCount.div(10);
                    user.lockedFeliCatTokenCount = user.lockedFeliCatTokenCount.sub(lockedWithdrawAmount);
                }
                if(pending > 0){
                    canWithdrawAmount = pending.div(10);
                    user.lockedFeliCatTokenCount = user.lockedFeliCatTokenCount.add(pending.sub(canWithdrawAmount));
                }
                if(lockedWithdrawAmount.add(canWithdrawAmount) > 0){
                    safeCakeTransfer(msg.sender, lockedWithdrawAmount.add(canWithdrawAmount));
                }
            }
        }else{
            if(user.lockedFeliCatTokenCount > 0){
                lockedWithdrawAmount = user.lockedFeliCatTokenCount;
                user.lockedFeliCatTokenCount = 0;
            }
            if(pending > 0){
                canWithdrawAmount = pending;
            }
            if(lockedWithdrawAmount.add(canWithdrawAmount) > 0){
                 safeCakeTransfer(msg.sender, canWithdrawAmount.add(lockedWithdrawAmount)); 
            }
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        user.lastWithdrawBlock = block.number;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Stake CAKE tokens to MasterChef
    function enterStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
            uint256 canWithdrawAmount = 0;
            if(pending > 0) {
                if(user.lastWithdrawBlock == 0 || block.number.sub(user.firstDepositBlock) < rewardsMaxLockedBlock){
                    if(block.number.sub(user.lastWithdrawBlock) > oneDay){
                        canWithdrawAmount = pending.div(10);
                        user.lockedFeliCatTokenCount = user.lockedFeliCatTokenCount.add(pending.sub(canWithdrawAmount));
                        safeCakeTransfer(msg.sender, canWithdrawAmount);
                    }else{
                        user.lockedFeliCatTokenCount = user.lockedFeliCatTokenCount.add(pending);
                    }
                }else{
                    if(user.lockedFeliCatTokenCount > 0){
                        canWithdrawAmount = user.lockedFeliCatTokenCount;
                        user.lockedFeliCatTokenCount = 0;
                    }
                    safeCakeTransfer(msg.sender, pending.add(canWithdrawAmount));
                }
                user.lastWithdrawBlock = block.number;
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        if(user.firstDepositBlock == 0){
            user.firstDepositBlock = block.number;
        }
        fish.mint(msg.sender, _amount);
        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw CAKE tokens from STAKING.
    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
        uint256 canWithdrawAmount = 0;
        uint256 lockedWithdrawAmount = 0;
        if(user.lastWithdrawBlock == 0 || block.number.sub(user.firstDepositBlock) < rewardsMaxLockedBlock){
            if(block.number.sub(user.lastWithdrawBlock) > oneDay){
                if(user.lockedFeliCatTokenCount > 0){
                    lockedWithdrawAmount = user.lockedFeliCatTokenCount.div(10);
                    user.lockedFeliCatTokenCount = user.lockedFeliCatTokenCount.sub(lockedWithdrawAmount);
                }
                if(pending > 0){
                    canWithdrawAmount = pending.div(10);
                    user.lockedFeliCatTokenCount = user.lockedFeliCatTokenCount.add(pending.sub(canWithdrawAmount));
                }
                if(lockedWithdrawAmount.add(canWithdrawAmount) > 0){
                    safeCakeTransfer(msg.sender, lockedWithdrawAmount.add(canWithdrawAmount)); 
                }
            }
        }else{
            if(user.lockedFeliCatTokenCount > 0){
                lockedWithdrawAmount = user.lockedFeliCatTokenCount;
                user.lockedFeliCatTokenCount = 0;
            }
            if(pending > 0){
                canWithdrawAmount = pending;
            }
            if(lockedWithdrawAmount.add(canWithdrawAmount) > 0){
                safeCakeTransfer(msg.sender, canWithdrawAmount.add(lockedWithdrawAmount));
            }
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.lastWithdrawBlock = block.number;
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);

        fish.burn(msg.sender, _amount);
        emit Withdraw(msg.sender, 0, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.lockedFeliCatTokenCount = 0;
    }

    // Safe cake transfer function, just in case if rounding error causes pool to not have enough CAKEs.
    function safeCakeTransfer(address _to, uint256 _amount) internal {
        fish.safeCakeTransfer(_to, _amount);
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
    
}