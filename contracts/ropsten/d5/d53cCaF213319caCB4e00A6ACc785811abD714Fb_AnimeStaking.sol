// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "IERC20.sol";
import "SafeERC20.sol";
import "EnumerableSet.sol";
import "Ownable.sol";
import "AnimeToken.sol";


// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once ANIME is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract AnimeStaking is Ownable {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ANIMEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accAnimePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accAnimePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. ANIMEs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that ANIMEs distribution occurs.
        uint256 accAnimePerShare; // Accumulated ANIMEs per share, times 1e12. See below.
    }

    // The ANIME TOKEN!
    AnimeToken public anime;

    // Block number when bonus ANIME period ends.
    uint256 public bonusEndBlock;
    // ANIME tokens created per block.
    uint256 public animePerBlock;
    // Bonus muliplier for early ANIME makers.
    uint256 public constant BONUS_MULTIPLIER = 10;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when ANIME mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        AnimeToken _anime,
        uint256 _animePerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) {
        anime = _anime;
        animePerBlock = _animePerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accAnimePerShare: 0
        }));
    }

    // Update the given pool's ANIME allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return (_to - _from) * BONUS_MULTIPLIER;
        } else if (_from >= bonusEndBlock) {
            return _to - _from;
        } else {
            return ((bonusEndBlock - _from) * BONUS_MULTIPLIER) + _to - bonusEndBlock;
        }
    }

    // View function to see pending ANIMEs on frontend.
    function pendingAnime(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accAnimePerShare = pool.accAnimePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 animeReward = multiplier * animePerBlock * pool.allocPoint / totalAllocPoint;
            accAnimePerShare = accAnimePerShare + animeReward * 1e12 / lpSupply;
        }
        return user.amount * accAnimePerShare / 1e12 - user.rewardDebt;
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
        uint256 animeReward = multiplier * animePerBlock * pool.allocPoint / totalAllocPoint;
        anime.mint(address(this), animeReward);
        pool.accAnimePerShare = pool.accAnimePerShare + animeReward * 1e12 / lpSupply;
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for ANIME allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount * pool.accAnimePerShare / 1e12 - user.rewardDebt;
            safeAnimeTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount + _amount;
        user.rewardDebt = user.amount * pool.accAnimePerShare / 1e12;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount * pool.accAnimePerShare / 1e12 - user.rewardDebt;
        safeAnimeTransfer(msg.sender, pending);
        user.amount = user.amount - _amount;
        user.rewardDebt = user.amount * pool.accAnimePerShare / 1e12;
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

    // Safe ANIME transfer function, just in case if rounding error causes pool to not have enough ANIMEs.
    function safeAnimeTransfer(address _to, uint256 _amount) internal {
        uint256 animeBal = anime.balanceOf(address(this));
        if (_amount > animeBal) {
            anime.transfer(_to, animeBal);
        } else {
            anime.transfer(_to, _amount);
        }
    }
}