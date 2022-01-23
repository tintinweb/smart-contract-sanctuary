/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import './Address.sol';
import './Context.sol';
import './IBEP20.sol';
import './SafeBEP20.sol';
import './DefragToken.sol';
import './SafeMath.sol';

interface IMigratorChef {
    // Perform LP token migration from legacy PandefragSwap to defragSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to PandefragSwap LP tokens.
    // defragSwap must mint EXACTLY the same amount of defragSwap LP tokens or
    // else something bad will happen. Traditional PandefragSwap does not
    // do that so be careful!
    function migrate(IBEP20 token) external returns (IBEP20);
}

// MasterChef is the master of defrag. He can make defrag
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once defrag is sufficiently
// distributed and the community can show to govern itself.
contract RewardStake is Ownable {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;
    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of defrags
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accdefragPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accdefragPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. defrags to distribute per block.
        uint256 lastRewardBlock;  // Last block number that defrags distribution occurs.
        uint256 power; // The multilier for determining "staking power"
        uint256 total;           // Total number of tokens staked.
        uint256 accdefragPerShare; // Accumulated defrags per share, times 1e12. See below.
    }

     struct Allocation {
        uint256 start;
        uint256 amount;
    }
    
    // duration time to claim rewards

    uint256 public vestduration;

    // The defrag token
    DefragToken public defrag;

    // defrag tokens created per block.
    uint256 public defragPerBlock;

    // Bonus muliplier for early defrag makers.
    uint256 public BONUS_MULTIPLIER = 1;

    // The amount unclaimed for an address, whether or not vested.
    mapping(address => uint256) public pendingAmount;


    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;


    // The allocations assigned to an address.
    mapping(address => Allocation[]) public userAllocations;

    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The block number when defrag mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event Released(
        address indexed beneficiary,
        uint256 indexed allocationId,
        uint256 amount
    );

    constructor(
        DefragToken _defrag,
        uint256 _defragPerBlock,
        uint256 _startBlock,
        uint256 initduration
    ) {
        defrag = _defrag;
        defragPerBlock = _defragPerBlock;
        startBlock = _startBlock;
        vestduration = initduration;
    }


    function duration(
        uint256 _from,
        uint256 _to
    ) public pure returns (uint256) {
        return _to.sub(_from);
    }



    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken,uint256 _power, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            power: _power,
            total: 0,
            accdefragPerShare: 0
        }));
    }

    // Update the given pool's defrag allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint256 _power, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].power = _power;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

   //change rewardperBlock. Can only be called by the owner
    function setRewardPerBlock(
        uint256 _rewardPerBlock
    ) public onlyOwner {
        defragPerBlock = _rewardPerBlock;
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
        return _to - _from * BONUS_MULTIPLIER;
    }
   
   //change vesting duration. Can only be called by owner.
    function setVestingRules(
        uint256 _duration
    ) public onlyOwner {
        vestduration = _duration;
    }

    // View function to see pending defrags on frontend.
    function pendingdefrag(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accdefragPerShare = pool.accdefragPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 defragReward = multiplier * defragPerBlock * pool.allocPoint / totalAllocPoint;
            accdefragPerShare = accdefragPerShare + defragReward * 1e12 / lpSupply;
        }
        return user.amount * accdefragPerShare / 1e12 - user.rewardDebt;
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
        uint256 lpSupply = pool.total;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 defragReward = multiplier * defragPerBlock * pool.allocPoint / totalAllocPoint;
        pool.accdefragPerShare = pool.accdefragPerShare + defragReward * 1e12 / lpSupply;
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for defrag allocation.
    function deposit(uint256 _pid, uint256 _amount) public {

        require(_amount > 0, "deposit: only non-zero amounts allowed");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        _claim(pool, user, msg.sender);
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        pool.total = pool.total.add(_amount);
        user.rewardDebt = user.amount * pool.accdefragPerShare / 1e12;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {

        require(_amount > 0, "withdraw: only non-zero amounts allowed");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        _claim(pool, user, msg.sender);
        user.amount = user.amount.sub(_amount);
        pool.total = pool.total.sub(_amount);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        user.rewardDebt = user.amount * pool.accdefragPerShare / 1e12;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function claim(
        uint256 _pid,
        address _beneficiary
    ) public {
        // make sure the pool is up-to-date
        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_beneficiary];

        _claim(pool, user, _beneficiary);
    }


     function _claim(
        PoolInfo storage pool,
        UserInfo storage user,
        address to
    ) internal {
        if (user.amount > 0) {
            // calculate the pending reward
            uint256 available = defrag.balanceOf(address(this));
            uint256 pending = user.amount
                .mul(pool.accdefragPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            uint256 _amount = pending > available ? available : pending;
            userAllocations[to].push(Allocation({
            start:      block.timestamp,
            amount:      _amount
           }));         
            emit Claim(to, _amount);
        }
    }



    function claimMultiple(
        uint256[] calldata _pids,
        address _beneficiary
    ) external {
        for (uint256 i = 0; i < _pids.length; i++) {
            claim(_pids[i], _beneficiary);
        }
    }

    
     function release(
        address _beneficiary,
        uint256 _id
    ) public {
        Allocation storage allocation = userAllocations[_beneficiary][_id];
        
        require (block.timestamp >= allocation.start.add(vestduration),"Nothing is vested until after the start time + cliff length.");
        // Calculate the releasable amount.
        uint256 amount = allocation.amount;
        require(amount > 0, "Nothing to release");
       

        // Subtract the amount from the beneficiary's total pending.
        pendingAmount[_beneficiary] = pendingAmount[_beneficiary].sub(amount);

        // Transfer the tokens to the beneficiary.
        safedefragTransfer(_beneficiary, amount);

        emit Released(
            _beneficiary,
            _id,
            amount
        );

    }
   
    function releaseMultiple(
        address _beneficiary,
        uint256[] calldata _ids
    ) external {
        for (uint256 i = 0; i < _ids.length; i++) {
            release(_beneficiary, _ids[i]);
        }
    }
    


    function totalPendingRewards(
        address _beneficiary
    ) public view returns (uint256 total) {
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            total = total.add(pendingRewards(pid, _beneficiary));
        }

        return total;
    }


     function pendingRewards(
        uint256 _pid,
        address _beneficiary
    ) public view returns (uint256 amount) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_beneficiary];
        uint256 accdefragPerShare = pool.accdefragPerShare;
        uint256 tokenSupply = pool.total;
        
        if (block.number > pool.lastRewardBlock && tokenSupply != 0) {
            uint256 reward = duration(pool.lastRewardBlock, block.number)
                .mul(defragPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);

            accdefragPerShare = accdefragPerShare.add(
                reward.mul(1e12).div(tokenSupply)
            );
        }

        return user.amount.mul(accdefragPerShare).div(1e12).sub(user.rewardDebt);
    }

       // Safe defrag transfer function, just in case if rounding error causes pool to not have enough defrags.
    function safedefragTransfer(address _to, uint256 _amount) internal {
        uint256 defragbal = defrag.balanceOf(address(this));
        if (_amount > defragbal) {
            defrag.transfer(_to, defragbal);
        } else {
            defrag.transfer(_to, _amount);
        }
    }
}