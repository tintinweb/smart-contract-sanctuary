pragma solidity ^0.5.8;

import './IERC20.sol';
import './SafeMath.sol';
import './Ownable.sol';
import './SafeERC20.sol';
import './KatanaToken.sol';

interface IMigratorChef {
    // Perform LP token migration from legacy UniswapV2 to KatanaSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // KatanaSwap must mint EXACTLY the same amount of KatanaSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// Samurai is the master of Katana.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once KATANA is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract Samurai is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of KATANAs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accKatanaPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. KATANAs to distribute per block.
        uint256 lastRewardBlock; // Last block number that KATANAs distribution occurs.
        uint256 accKatanaPerShare; // Accumulated KATANAs per share, times 1e12. See below.
    }

    // The KATANA TOKEN!
    KatanaToken public katana;
    // Dev address.
    address public devaddr;
    // Block number when bonus KATANA period ends.
    uint256 public bonusEndBlock;
    // KATANA tokens created per block.
    uint256 public katanaPerBlock;
    // Reward distribution end block
    uint256 public rewardsEndBlock;
    // Bonus muliplier for early katana makers.
    uint256 public constant BONUS_MULTIPLIER = 3;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => bool) public lpTokenExistsInPool;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when KATANA mining starts.
    uint256 public startBlock;

    uint256 public blockInAMonth = 97500;
    uint256 public halvePeriod = blockInAMonth;
    uint256 public lastHalveBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event Halve(uint256 newKatanaPerBlock, uint256 nextHalveBlockNumber);

    constructor(
        KatanaToken _katana,
        address _devaddr,
        uint256 _katanaPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _rewardsEndBlock
    ) public {
        katana = _katana;
        devaddr = _devaddr;
        katanaPerBlock = _katanaPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        lastHalveBlock = _startBlock;
        rewardsEndBlock = _rewardsEndBlock;
    }

    function doHalvingCheck(bool _withUpdate) public {
        uint256 blockNumber = min(block.number, rewardsEndBlock);
        bool doHalve = blockNumber > lastHalveBlock + halvePeriod;
        if (!doHalve) {
            return;
        }
        uint256 newKatanaPerBlock = katanaPerBlock.div(2);
        katanaPerBlock = newKatanaPerBlock;
        lastHalveBlock = blockNumber;
        emit Halve(newKatanaPerBlock, blockNumber + halvePeriod);

        if (_withUpdate) {
            massUpdatePools();
        }
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        require(
            !lpTokenExistsInPool[address(_lpToken)],
            'Samurai: LP Token Address already exists in pool'
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 blockNumber = min(block.number, rewardsEndBlock);
        uint256 lastRewardBlock = blockNumber > startBlock
            ? blockNumber
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accKatanaPerShare: 0
            })
        );
        lpTokenExistsInPool[address(_lpToken)] = true;
    }

    function updateLpTokenExists(address _lpTokenAddr, bool _isExists)
        external
        onlyOwner
    {
        lpTokenExistsInPool[_lpTokenAddr] = _isExists;
    }

    // Update the given pool's KATANA allocation point. Can only be called by the owner.
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

    function migrate(uint256 _pid) public onlyOwner {
        require(
            address(migrator) != address(0),
            'Samurai: Address of migrator is null'
        );
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(
            !lpTokenExistsInPool[address(newLpToken)],
            'Samurai: New LP Token Address already exists in pool'
        );
        require(
            bal == newLpToken.balanceOf(address(this)),
            'Samurai: New LP Token balance incorrect'
        );
        pool.lpToken = newLpToken;
        lpTokenExistsInPool[address(newLpToken)] = true;
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

    // View function to see pending KATANAs on frontend.
    function pendingKatana(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accKatanaPerShare = pool.accKatanaPerShare;
        uint256 blockNumber = min(block.number, rewardsEndBlock);
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (blockNumber > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                blockNumber
            );
            uint256 katanaReward = multiplier
                .mul(katanaPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accKatanaPerShare = accKatanaPerShare.add(
                katanaReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accKatanaPerShare).div(1e12).sub(user.rewardDebt);
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
        doHalvingCheck(false);
        PoolInfo storage pool = poolInfo[_pid];
        uint256 blockNumber = min(block.number, rewardsEndBlock);
        if (blockNumber <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = blockNumber;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, blockNumber);
        uint256 katanaReward = multiplier
            .mul(katanaPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        katana.mint(devaddr, katanaReward.div(10));
        katana.mint(address(this), katanaReward);
        pool.accKatanaPerShare = pool.accKatanaPerShare.add(
            katanaReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = blockNumber;
    }

    // Deposit LP tokens to Samurai for KATANA allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accKatanaPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            safeKatanaTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accKatanaPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from Samurai.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(
            user.amount >= _amount,
            'Samurai: Insufficient Amount to withdraw'
        );
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accKatanaPerShare).div(1e12).sub(
            user.rewardDebt
        );
        safeKatanaTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accKatanaPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
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

    // Safe katana transfer function, just in case if rounding error causes pool to not have enough KATANAs.
    function safeKatanaTransfer(address _to, uint256 _amount) internal {
        uint256 katanaBal = katana.balanceOf(address(this));
        if (_amount > katanaBal) {
            katana.transfer(_to, katanaBal);
        } else {
            katana.transfer(_to, _amount);
        }
    }

    function isRewardsActive() public view returns (bool) {
        return rewardsEndBlock > block.number;
    }

    function min(uint256 a, uint256 b) public view returns (uint256) {
        if (a > b) {
            return b;
        }
        return a;
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(
            msg.sender == devaddr,
            'Samurai: Sender is not the developer'
        );
        devaddr = _devaddr;
    }
}
