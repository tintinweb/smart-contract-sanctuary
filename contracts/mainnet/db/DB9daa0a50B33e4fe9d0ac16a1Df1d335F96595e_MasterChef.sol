// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IMigrator.sol";

import "./ERC20Mintable.sol";

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of BASKETs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBasketPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBasketPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. BASKETs to distribute per block.
        uint256 lastRewardBlock; // Last block number that BASKETs distribution occurs.
        uint256 accBasketPerShare; // Accumulated BASKETs per share, times 1e12. See below.
    }

    // The BASKET TOKEN!
    ERC20 public basket;

    // Div rate
    uint256 public constant divRate = 1e18;

    // Dev fund (10)%
    uint256 public constant devFundRate = 0.1e18;
    // Treasury rate (30)%
    uint256 public constant treasuryRate = 0.3e18;
    // Dev address
    address public devaddr;
    // Treasury address
    address public treasuryaddr;
    // BASKET tokens created per block.
    uint256 public basketPerBlock;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigrator public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BASKET mining starts.
    uint256 public startBlock;

    // Events
    event Recovered(address token, uint256 amount);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        ERC20 _basket,
        address _timelock,
        address _devaddr,
        address _treasuryaddr,
        uint256 _basketPerBlock,
        uint256 _startBlock
    ) {
        basket = _basket;
        devaddr = _devaddr;
        treasuryaddr = _treasuryaddr;
        basketPerBlock = _basketPerBlock;
        startBlock = _startBlock;

        transferOwnership(_timelock);
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
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accBasketPerShare: 0
            })
        );
    }

    // Update the given pool's BASKET allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    // View function to see pending BASKETs on frontend.
    function pendingBasket(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBasketPerShare = pool.accBasketPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 basketReward = multiplier.mul(basketPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accBasketPerShare = accBasketPerShare.add(basketReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accBasketPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 basketReward = multiplier.mul(basketPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        uint256 devAlloc = basketReward.mul(devFundRate).div(divRate);
        uint256 treasuryAlloc = basketReward.mul(treasuryRate).div(divRate);

        uint256 basketWithoutDevAndTreasury = basketReward.sub(devAlloc).sub(treasuryAlloc);

        ERC20Mintable(address(basket)).mint(devaddr, devAlloc);
        ERC20Mintable(address(basket)).mint(treasuryaddr, treasuryAlloc);
        ERC20Mintable(address(basket)).mint(address(this), basketWithoutDevAndTreasury);

        pool.accBasketPerShare = pool.accBasketPerShare.add(basketWithoutDevAndTreasury.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for BASKET allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accBasketPerShare).div(1e12).sub(user.rewardDebt);
            safeBasketTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accBasketPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accBasketPerShare).div(1e12).sub(user.rewardDebt);
        safeBasketTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accBasketPerShare).div(1e12);
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

    // Safe basket transfer function, just in case if rounding error causes pool to not have enough BASKETs.
    function safeBasketTransfer(address _to, uint256 _amount) internal {
        uint256 basketBal = basket.balanceOf(address(this));
        if (_amount > basketBal) {
            basket.transfer(_to, basketBal);
        } else {
            basket.transfer(_to, _amount);
        }
    }

    // **** Custom functions ****

    function setDev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function setTreasury(address _treasury) public {
        require(msg.sender == treasuryaddr, "treasury: wut?");
        treasuryaddr = _treasury;
    }

    function setBasketPerBlock(uint256 _basketPerBlock) public onlyOwner {
        require(_basketPerBlock > 0, "!basketPerBlock-0");
        basketPerBlock = _basketPerBlock;
    }

    function setStartBlock(uint256 _startBlock) public onlyOwner {
        require(block.number < startBlock, "started");
        startBlock = _startBlock;
    }

    // **** Migrate ****

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigrator _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract
    function migrate(uint256 _pid) public onlyOwner {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = IERC20(migrator.migrate(address(lpToken)));
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }
}