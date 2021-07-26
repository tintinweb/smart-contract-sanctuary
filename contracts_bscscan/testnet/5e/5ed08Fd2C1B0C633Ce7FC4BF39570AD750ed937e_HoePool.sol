// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './IUserManagement.sol';
import './IERC20.sol';
import './Ownable.sol';
import './SafeMath.sol';
import './SafeERC20.sol';

interface IMigratorChef {
    // Perform LP token migration from legacy UniswapV2 to BatsSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // BatsSwap must mint EXACTLY the same amount of BatsSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// MasterChef is the master of Bats. He can make Bats and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Bats is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract HoePool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Batss
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBatsPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBatsPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Batss to distribute per block.
        uint256 lastRewardBlock; // Last block number that Batss distribution occurs.
        uint256 accBatsPerShare; // Accumulated Batss per share, times 1e12. See below.
        uint256 totalAmount;    // Total amount of current pool deposit.
        uint256 taxAmount;
        bool isPair;
    }
    // The h TOKEN!
    IERC20 public hToken;
    // Block number when bonus ends.
    uint256 public bonusEndBlock;
    // tokens created per block.
    uint256 public perBlock;
    // Bonus muliplier for early Bats makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // pid corresponding address
    mapping(address => uint256) public LpOfPid;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when mining starts.
    uint256 public startBlock;
    
    IUserManagement public manager;
    
    bool public paused = false;
    uint public taxRate = 5;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        IERC20  _hToken,
        uint256 _perBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        hToken = _hToken;
        perBlock = _perBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }
    
    modifier notPause() {
        require(paused == false, "Mining has been suspended");
        _;
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }
    
    function setManager(IUserManagement _manager) public onlyOwner {
        manager = _manager;
    }
    
    function setPerBlock(uint256 _newPerBlock) public onlyOwner {
        massUpdatePools();
        perBlock = _newPerBlock;
    }
    
    function updateMultiplier(uint256 multiplierNumber)  public onlyOwner {
        massUpdatePools();
        BONUS_MULTIPLIER = multiplierNumber;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _isPair,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accBatsPerShare: 0,
                totalAmount : 0,
                taxAmount: 0,
                isPair: _isPair
            })
        );
        LpOfPid[address(_lpToken)] = poolLength() - 1;
    }

    // Update the given pool's Bats allocation point. Can only be called by the owner.
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

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    modifier onlyUserExists() {
        require(manager.isUserExists(msg.sender), "only user exists");
        _;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    // View function to see pending Batss on frontend.
    function pendingBats(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBatsPerShare = pool.accBatsPerShare;
        uint256 lpSupply = pool.totalAmount;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 BatsReward =
                multiplier.mul(perBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accBatsPerShare = accBatsPerShare.add(
                BatsReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accBatsPerShare).div(1e12).sub(user.rewardDebt);
    }
    
    // Update reward vairables for all pools. Be careful of gas spending!
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
        uint256 lpSupply = pool.totalAmount;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 batsReward =
            multiplier.mul(perBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        bool minRet = hToken.mint(address(this), batsReward);
        if(minRet){
            pool.accBatsPerShare = pool.accBatsPerShare.add(
                batsReward.mul(1e12).div(lpSupply)
            );
        }
        
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for Bats allocation.
    function deposit(uint256 _pid, uint256 _amount) public notPause onlyUserExists{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accBatsPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            if(address(manager)!=address(0)) manager.harvest(msg.sender, pending);
            safeBatsTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 _taxAmount = _amount.mul(taxRate).div(100);
            user.amount = user.amount.add(_amount).sub(_taxAmount);
            pool.totalAmount = pool.totalAmount.add(_amount).sub(_taxAmount);
            pool.taxAmount = pool.taxAmount.add(_taxAmount);

            if(address(manager)!=address(0)) manager.updateManager(msg.sender, address(pool.lpToken), _amount, pool.isPair);

            emit Deposit(msg.sender, _pid, _amount.sub(_taxAmount));
        }
        user.rewardDebt = user.amount.mul(pool.accBatsPerShare).div(1e12);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public notPause {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pendingAmount =
            user.amount.mul(pool.accBatsPerShare).div(1e12).sub(
                user.rewardDebt
            );
        if (pendingAmount > 0) {
            if(address(manager)!=address(0)) manager.harvest(msg.sender, pendingAmount);
            safeBatsTransfer(msg.sender, pendingAmount);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalAmount = pool.totalAmount.sub(_amount);
            pool.lpToken.safeTransfer(msg.sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBatsPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) public notPause {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(msg.sender, amount);
        pool.totalAmount = pool.totalAmount.sub(amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe Bats transfer function, just in case if rounding error causes pool to not have enough Batss.
    function safeBatsTransfer(address _to, uint256 _amount) internal {
        uint256 hBal = hToken.balanceOf(address(this));
        if (_amount > hBal) {
            hToken.transfer(_to, hBal);
        } else {
            hToken.transfer(_to, _amount);
        }
    }
}