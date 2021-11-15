// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./access/Ownable.sol";
import "./interfaces/IZombieToken.sol";
import "./interfaces/IUndeadBar.sol";
import "./interfaces/IGraveStakingToken.sol";
import "./interfaces/IRevivedRugNft.sol";
import "./interfaces/IPriceConsumerV3.sol";
import "./libraries/Percentages.sol";

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
    function migrate(IGraveStakingToken token) external returns (IGraveStakingToken);
}

// DrFrankenstein is the master of the Zombie token, tombs & the graves. He can make Zombie & he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract DrFrankenstein is Ownable {
    using Percentages for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 amount;                 // How many LP tokens the user has provided.
        uint256 rewardDebt;             // Reward debt. See explanation below.
        uint256 tokenWithdrawalDate;    // Date user must wait until before early withdrawal fees are lifted.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ZMBEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accZombiePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accZombiePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.

        // User grave info
        uint256 rugDeposited;               // How many rugged tokens the user deposited.
        bool paidUnlockFee;                 // true if user paid the unlock fee.
        uint256  nftRevivalDate;            // Date user must wait until before harvesting their nft.
    }

    // Info of each pool / grave.
    struct PoolInfo {
        // Traditional pool variables
        IGraveStakingToken lpToken;             // Address of LP token contract.
        uint256 allocPoint;                     // How many allocation points assigned to this pool. ZMBEs to distribute per block.
        uint256 lastRewardBlock;                // Last block number that ZMBEs distribution occurs.
        uint256 accZombiePerShare;              // Accumulated ZMBEs per share, times 1e12. See below.
        uint256 minimumStakingTime;             // Duration a user must stake before early withdrawal fee is lifted.
        // Grave variables
        bool isGrave;                           // True if pool is a grave (provides nft rewards).
        bool requiresRug;                       // True if grave require a rugged token deposit before unlocking.
        IGraveStakingToken ruggedToken;         // Address of the grave's rugged token (casted to IGraveStakingToken over IBEP20 to save space).
        address nft;                            // Address of reward nft.
        uint256 unlockFee;                      // Unlock fee (In BUSD, Chainlink Oracle is used to convert fee to current BNB value).
        uint256 minimumStake;                   // Minimum amount of lpTokens required to stake.
        uint256 nftRevivalTime;                 // Duration a user must stake before they can redeem their nft reward.
        uint256 unlocks;                        // Number of times a grave is unlocked
    }

    // The ZMBE TOKEN!
    IZombieToken public zombie;
    // The SYRUP TOKEN!
    IUndeadBar public undead;
    // Dev address.
    address public devaddr;
    // ZMBE tokens created per block.
    uint256 public zombiePerBlock;
    // Bonus multiplier for early zombie makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;
    // Uniswap routerV2
    IUniswapV2Router02 public pancakeswapRouter;
    // Info of each grave.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when CAKE mining starts.
    uint256 public startBlock;

    // Project addresses
    address payable treasury;   // Address of project treasury contract
    address public lpStorage; // Address locked LP is sent to (Allows us to migrate lp if Pancakeswap moves to v3 / we start an AMM)
    address public burnAddr = 0x000000000000000000000000000000000000dEaD; // Burn address

    // Chainlink BNB Price
    IPriceConsumerV3 public priceConsumer;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawEarly(address indexed user, uint256 indexed pid, uint256 amountWithdrawn, uint256 amountLocked);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event ReviveRug(address indexed to, uint date, address nft, uint indexed id);

    constructor(
        IZombieToken _zombie,
        IUndeadBar _undead,
        address _devaddr,
        address payable _treasury,
        address _lpStorage,
        address _pancakeRouter,
        address _firstNft,
        address _priceConsumer,
        uint256 _zombiePerBlock,
        uint256 _startBlock
    ) {
        zombie = _zombie;
        undead = _undead;
        devaddr = _devaddr;
        treasury = _treasury;
        lpStorage = _lpStorage;
        zombiePerBlock = _zombiePerBlock;
        startBlock = _startBlock;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: IGraveStakingToken(address(_zombie)),
            allocPoint: 100,
            lastRewardBlock: startBlock,
            accZombiePerShare: 0,
            minimumStakingTime: 3 days,
            requiresRug: false,
            isGrave: true,
            ruggedToken: IGraveStakingToken(address(0)),
            minimumStake: 5000 * (10 ** 18),
            nft: _firstNft,
            unlockFee: 5 * (10 ** 18),
            nftRevivalTime: 30 days,
            unlocks: 0
        }));

        totalAllocPoint = 100;
        pancakeswapRouter = IUniswapV2Router02(_pancakeRouter);
        priceConsumer = IPriceConsumerV3(_priceConsumer);
    }

    // Ensures a pool / grave is unlocked before a user accesses it.
    modifier isUnlocked(uint _gid) {
        UserInfo memory _user = userInfo[_gid][msg.sender];
        PoolInfo memory _pool = poolInfo[_gid];
        require(_user.rugDeposited > 0 || _pool.requiresRug == false, 'Locked: User has not deposited the required Rugged Token.');
        require(_user.paidUnlockFee == true || _pool.isGrave == false , 'Locked: User has not unlocked pool / grave.');
        _;
    }

    // Ensures a rugged token has been deposited before unlocking accessing grave / pool.
    modifier hasDepositedRug(uint _pid) {
        require(userInfo[_pid][msg.sender].rugDeposited > 0 || poolInfo[_pid].requiresRug == false, 'Grave: User has not deposited the required Rugged Token.');
        _;
    }

    // Ensures user's withdrawal date has passed before withdrawing.
    modifier canWithdraw(uint _pid, uint _amount) {
        uint _withdrawalDate = userInfo[_pid][msg.sender].tokenWithdrawalDate;
        require((block.timestamp >= _withdrawalDate && _withdrawalDate > 0) || _amount == 0, 'Staking: Token is still locked, use #withdrawEarly / #leaveStakingEarly to withdraw funds before the end of your staking period.');
        _;
    }

    // Ensures a pool / grave exists
    modifier poolExists(uint _pid) {
        require(_pid <= poolInfo.length - 1, 'Pool: That pool does not exist.');
        _;
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function addPool(
        uint _allocPoint,
        IGraveStakingToken _lpToken,
        uint _minimumStakingTime,
        bool _withUpdate
    ) public onlyOwner {
        require(address(_lpToken) != address(zombie), 'addGrave: zombie cannot be used as grave lptoken.');
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accZombiePerShare: 0,
            minimumStakingTime: _minimumStakingTime,
            // Null grave variables
            isGrave: false,
            requiresRug: false,
            ruggedToken: IGraveStakingToken(address(0)),
            nft: address(0),
            minimumStake: 0,
            unlockFee: 0,
            nftRevivalTime: 0,
            unlocks: 0
        }));
    }

    // Add a new grave. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    // LP token will be minted & staked in replace of users zombie token, to simulate zombie staking on graves, without messing up rewards.
    function addGrave(
        uint256 _allocPoint,
        IGraveStakingToken _lpToken,
        uint256 _minimumStakingTime,
        IGraveStakingToken _ruggedToken,
        address _nft,
        uint256 _minimumStake,
        uint256 _unlockFee,
        uint256 _nftRevivalTime,
        bool _withUpdate
    ) public onlyOwner {
        require(address(_lpToken) != address(zombie), 'addGrave: zombie cannot be used as grave lptoken.');
        require(_lpToken.getOwner() == address(this), 'addGrave: DrFrankenstein must be lptoken owner.');
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accZombiePerShare: 0,
            minimumStakingTime: _minimumStakingTime,
            // Grave variables
            isGrave: true,
            requiresRug: true,
            ruggedToken: _ruggedToken,
            nft: _nft,
            minimumStake: _minimumStake,
            unlockFee: _unlockFee,
            nftRevivalTime: _nftRevivalTime,
            unlocks: 0
        }));
    }

    // Update the given pool's ZMBE allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = (totalAllocPoint - prevAllocPoint) + _allocPoint;
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
        IGraveStakingToken lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        require(bal == 0 || (lpToken.allowance(address(this), address(migrator)) == 0), 'Migrate: approve from non-zero to non-zero allowance');
        lpToken.approve(address(migrator), bal);
        IGraveStakingToken newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return (_to - _from) * BONUS_MULTIPLIER;
    }

    // View function to see pending ZMBEs on frontend.
    function pendingZombie(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accZombiePerShare = pool.accZombiePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 zombieReward = (multiplier * zombiePerBlock * pool.allocPoint) / totalAllocPoint;
            accZombiePerShare = accZombiePerShare + (zombieReward * 1e12) / lpSupply;
        }
        return ((user.amount * accZombiePerShare) / 1e12) - user.rewardDebt;
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
        uint256 zombieReward = (multiplier * zombiePerBlock * pool.allocPoint) / totalAllocPoint;
        zombie.mint(devaddr, zombieReward / 10);
        zombie.mint(address(undead), zombieReward);
        pool.accZombiePerShare = pool.accZombiePerShare + (zombieReward * 1e12) / lpSupply;
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for ZMBE allocation.
    function deposit(uint256 _pid, uint256 _amount) public isUnlocked(_pid) {
        require (_pid != 0, 'deposit ZMBE by staking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount + _amount >= pool.minimumStake, 'Grave: amount staked must be >= grave minimum stake.');

        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = ((user.amount * pool.accZombiePerShare) / 1e12) - user.rewardDebt;
            if(pending > 0) {
                safeZombieTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            user.tokenWithdrawalDate = block.timestamp + pool.minimumStakingTime;
            if (user.amount < pool.minimumStake) {
                user.nftRevivalDate = block.timestamp + pool.nftRevivalTime;
            }
            if (pool.isGrave == true) {
                pool.lpToken.mint(_amount);
                require(zombie.transferFrom(address(msg.sender), address(this), _amount));
                user.amount = user.amount + _amount;
            } else {
                require(pool.lpToken.transferFrom(address(msg.sender), address(this), _amount));
                user.amount = user.amount + _amount;
            }
        }
        user.rewardDebt = (user.amount * pool.accZombiePerShare) / 1e12;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public canWithdraw(_pid, _amount) {
        require (_pid != 0, 'withdraw ZMBE by unstaking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(
            (user.amount - _amount >= pool.minimumStake) || (user.amount - _amount) == 0,
            'Grave: when withdrawing from graves the remaining balance must be 0 or >= grave minimum stake.'
        );
        uint256 _whaleWithdrawalFee = 0;

        uint amountBasisPointsOfTotalSupply = pool.lpToken.totalSupply().calcBasisPoints(_amount);
        if(amountBasisPointsOfTotalSupply > 500 && pool.isGrave == false) { // tax 8% of on tokens if whale removes > 5% lp supply.
            _whaleWithdrawalFee = _amount.calcPortionFromBasisPoints(800);
            require(pool.lpToken.transfer(lpStorage, _whaleWithdrawalFee)); // Pool: whale tax is added to locked liquidity (burn address)
        }

        uint256 _remainingAmount = _amount;
        _remainingAmount -= _whaleWithdrawalFee;


        updatePool(_pid);
        uint256 pending = ((user.amount * pool.accZombiePerShare) / 1e12) - user.rewardDebt;
        if(pending > 0) {
            safeZombieTransfer(msg.sender, pending);
        }

        // mint nft
        if(pool.isGrave == true && user.amount >= pool.minimumStake && block.timestamp >= user.nftRevivalDate) {
            IRevivedRugNft _nft = IRevivedRugNft(pool.nft);
            uint256 id = _nft.reviveRug(msg.sender);
            user.nftRevivalDate = block.timestamp + pool.nftRevivalTime;
            emit ReviveRug(msg.sender, block.timestamp, pool.nft, id);
        }

        if(_amount > 0) {
            if(pool.isGrave == true) {
                user.amount = user.amount - _amount;
                require(zombie.transfer(msg.sender, _remainingAmount));
                pool.lpToken.burn(_amount);
            } else {
                user.amount = user.amount - _amount;
                require(pool.lpToken.transfer(address(msg.sender), _remainingAmount));
            }
            user.tokenWithdrawalDate = block.timestamp + pool.minimumStakingTime;
        }
        user.rewardDebt = (user.amount * pool.accZombiePerShare) / 1e12;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw from Grave / Tomb before time is up, takes 5% fee
    function withdrawEarly(uint256 _pid, uint256 _amount) public {
        require (_pid != 0, 'withdraw ZMBE by unstaking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(
            (user.amount - _amount >= pool.minimumStake) || (user.amount - _amount) == 0,
            'Grave: when withdrawing from graves the remaining balance must be 0 or >= grave minimum stake.'
        );
        uint256 _earlyWithdrawalFee = _amount.calcPortionFromBasisPoints(500);
        uint256 _burn = _earlyWithdrawalFee.calcPortionFromBasisPoints(5000);   // Half of zombie is burned
        uint256 _toTreasury = _earlyWithdrawalFee - _burn;                      // The rest is sent to the treasury
        uint256 _whaleWithdrawalFee = 0;

        uint amountBasisPointsOfTotalSupply = pool.lpToken.totalSupply().calcBasisPoints(_amount);
        if(amountBasisPointsOfTotalSupply > 500 && pool.isGrave == false) { // tax 8% of on tokens if whale removes > 5% lp supply.
            _whaleWithdrawalFee = _amount.calcPortionFromBasisPoints(800);
            require(pool.lpToken.transfer(lpStorage, _whaleWithdrawalFee)); // Pool: whale tax is added to locked liquidity (burn address)
        }

        uint256 _remainingAmount = _amount;
        _remainingAmount -= _earlyWithdrawalFee;
        _remainingAmount -= _whaleWithdrawalFee;

        updatePool(_pid);
        uint256 pending = ((user.amount * pool.accZombiePerShare) / 1e12) - user.rewardDebt;
        if(pending > 0) {
            safeZombieTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            if(pool.isGrave == true) {
                user.amount = user.amount - _amount;
                require(zombie.transfer(burnAddr, _burn));
                require(zombie.transfer(treasury, _toTreasury));
                require(zombie.transfer(msg.sender, _remainingAmount));
                pool.lpToken.burn(_amount);
            } else {
                user.amount = user.amount - _amount;
                unpairBurnAndTreasureLP(address(pool.lpToken), _earlyWithdrawalFee);    // unpair lps, burn zombie tokens & send any other tokens to the treasury
                require(pool.lpToken.transfer(address(msg.sender), _remainingAmount));       // return the rest of lps to the user
            }
            user.tokenWithdrawalDate = block.timestamp + pool.minimumStakingTime;
        }
        user.rewardDebt = (user.amount * pool.accZombiePerShare) / 1e12;
        emit WithdrawEarly(msg.sender, _pid, _remainingAmount, _earlyWithdrawalFee);
    }

    // Stake ZMBE tokens to MasterChef
    function enterStaking(uint256 _amount) public isUnlocked(0) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount + _amount >= pool.minimumStake, 'Grave: amount staked must be >= grave minimum stake.');

        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = ((user.amount * pool.accZombiePerShare) / 1e12) - user.rewardDebt;
            if(pending > 0) {
                safeZombieTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            if (user.amount < pool.minimumStake) {
                user.nftRevivalDate = block.timestamp + pool.nftRevivalTime;
            }
            require(pool.lpToken.transferFrom(address(msg.sender), address(this), _amount));
            user.amount = user.amount + _amount;
            user.tokenWithdrawalDate = block.timestamp + pool.minimumStakingTime;
        }

        user.rewardDebt = (user.amount * pool.accZombiePerShare) / 1e12;

        undead.mint(msg.sender, _amount);
        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw ZMBE tokens from STAKING.
    function leaveStaking(uint256 _amount) public canWithdraw(0, _amount) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(
            (user.amount - _amount >= pool.minimumStake) || (user.amount - _amount) == 0,
            'Grave: when withdrawing from graves the remaining balance must be 0 or >= grave minimum stake.'
        );

        updatePool(0);
        uint256 pending = ((user.amount * pool.accZombiePerShare) / 1e12) - user.rewardDebt;
        if(pending > 0) {
            safeZombieTransfer(msg.sender, pending);
        }

        // mint nft
        if(pool.isGrave == true && user.amount >= pool.minimumStake && block.timestamp >= user.nftRevivalDate) {
            uint id = IRevivedRugNft(pool.nft).reviveRug(msg.sender);
            user.nftRevivalDate = block.timestamp + pool.nftRevivalTime;
            emit ReviveRug(msg.sender, block.timestamp,  pool.nft, id);
        }

        if(_amount > 0) { // is only true for users who have waited the minimumStakingTime due to modifier
            require(pool.lpToken.transfer(address(msg.sender), _amount));
            user.amount = user.amount - _amount;
            user.tokenWithdrawalDate = block.timestamp + pool.minimumStakingTime;
            if(pool.isGrave == true) {
                user.nftRevivalDate = block.timestamp + pool.nftRevivalTime;
            }
        }

        user.rewardDebt = (user.amount * pool.accZombiePerShare) / 1e12;

        undead.burn(msg.sender, _amount);
        emit Withdraw(msg.sender, 0, _amount);
    }

    function leaveStakingEarly(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(
            user.amount - _amount >= pool.minimumStake || (user.amount - _amount) == 0,
            'withdraw: remaining balance must be 0 or >= the graves minimum stake'
        );

        updatePool(0);
        uint256 pending = ((user.amount * pool.accZombiePerShare) / 1e12) - user.rewardDebt;
        uint256 _earlyWithdrawalFee = _amount.calcPortionFromBasisPoints(500);  // 5% fee to fund project
        uint256 _burn = _earlyWithdrawalFee.calcPortionFromBasisPoints(5000);   // Half of zombie is burned
        uint256 _toTreasury = _earlyWithdrawalFee - _burn;                      // The rest is sent to the treasury
        uint256 _remainingAmount = _amount - _earlyWithdrawalFee;

        if(pending > 0) {
            safeZombieTransfer(msg.sender, pending);
        }

        if(_amount > 0) {
            user.amount = user.amount - _amount;
            user.tokenWithdrawalDate = block.timestamp + pool.minimumStakingTime;
            require(pool.lpToken.transfer(burnAddr, _burn));
            require(pool.lpToken.transfer(treasury, _toTreasury));
            require(pool.lpToken.transfer(address(msg.sender), _remainingAmount));
        }

        user.rewardDebt = (user.amount * pool.accZombiePerShare) / 1e12;
        undead.burn(msg.sender, _amount);
        emit WithdrawEarly(msg.sender, 0, _remainingAmount, _earlyWithdrawalFee);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        uint256 _remaining = _amount;

        // The following fees must still be taken here to prevent #emergencyWithdraw
        // from being used as a method to avoid fees.

        // Send early withdrawal fees to treasury
        if(block.timestamp < user.tokenWithdrawalDate) {
            uint256 _earlyWithdrawalFee = _amount / 20; // 5% of amount
            if(pool.isGrave == true) {
                zombie.transfer(treasury, _earlyWithdrawalFee);
            } else {
                pool.lpToken.transfer(treasury, _earlyWithdrawalFee);
            }
            _remaining -= _earlyWithdrawalFee;
        }

        // Send whale withdrawal fee to treasury
        uint amountBasisPointsOfTotalSupply = pool.lpToken.totalSupply().calcBasisPoints(_amount);
        if(amountBasisPointsOfTotalSupply > 500 && pool.isGrave == false) { // tax 8% of on tokens if whale removes > 5% lp supply.
            uint _whaleWithdrawalFee = _amount.calcPortionFromBasisPoints(800);
            pool.lpToken.transfer(lpStorage, _whaleWithdrawalFee); // whale tax is added to lockedLiquidity
            _remaining -= _whaleWithdrawalFee;
        }

        if(pool.isGrave == true && _pid != 0) {
            pool.lpToken.burn(_amount);
        }

        if(pool.isGrave == true) {
            require(zombie.transfer(address(msg.sender), _remaining));
        } else {
            require(pool.lpToken.transfer(address(msg.sender), _remaining));
        }

        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.tokenWithdrawalDate = block.timestamp + pool.minimumStakingTime;
        user.nftRevivalDate = block.timestamp + pool.nftRevivalTime;
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe zombie transfer function, just in case if rounding error causes pool to not have enough ZMBEs.
    function safeZombieTransfer(address _to, uint256 _amount) internal {
        undead.safeZombieTransfer(_to, _amount);
    }

    // Deposits rug into grave before unlocking
    function depositRug(uint _pid, uint _amount) external poolExists(_pid) {
        require(poolInfo[_pid].isGrave == true, 'Tomb: only graves accept rugged tokens.');
        require(poolInfo[_pid].ruggedToken.transferFrom(msg.sender, treasury, _amount));
        userInfo[_pid][msg.sender].rugDeposited += _amount;
    }

    // Unlocks grave, half of fee is sent to treasury, the rest is used to buyBackAndBurn,
    function unlock(uint _pid) external payable hasDepositedRug(_pid) {
        require(poolInfo[_pid].isGrave == true, 'Tomb: tombs do not require unlocking.');
        require(userInfo[_pid][msg.sender].paidUnlockFee == false, 'Grave: unlock fee is already paid.');
        uint _unlockFeeInBnb = unlockFeeInBnb(_pid);
        require(msg.value >= _unlockFeeInBnb, 'Grave: cannot unlock, insufficient bnb sent.');
        uint _projectFunds = msg.value;
        uint _toTreasury = _projectFunds.calcPortionFromBasisPoints(5000);
        uint _buyBack = _projectFunds - _toTreasury;

        treasury.transfer(_toTreasury);     // half of unlock fee goes to treasury
        buyBackAndBurn(_buyBack);           // the rest is used to buy back and burn zombie token

        poolInfo[_pid].unlocks += 1;
        userInfo[_pid][msg.sender].paidUnlockFee = true;
    }

    // return treasury address
    function getTreasury() public view returns(address) {
        return address(treasury);
    }

    // Allow dev to lift 2% wallet balance limit on the zombie token after launch
    function liftLaunchWhaleDetection() public onlyOwner {
        zombie.liftLaunchWhaleDetection();
    }

    // Allow dev to change the nft rewarded from a grave
    // should only be called on grave's
    function setGraveNft(uint _pid, address nft) public onlyOwner {
        poolInfo[_pid].nft = nft;
    }

    // Allow dev to change the unlock fee of a grave
    // should only be called on grave's
    function setUnlockFee(uint _pid, uint _unlockFee) public onlyOwner {
        poolInfo[_pid].unlockFee = _unlockFee;
    }

    // Warning only call before a grave has users staked in it
    // should only be called on grave's
    function setGraveMinimumStake(uint _pid, uint _minimumStake) public onlyOwner {
        poolInfo[_pid].minimumStake = _minimumStake;
    }

    // Allow dev to change price consumer oracle address
    function setPriceConsumer(IPriceConsumerV3 _priceConsumer) public onlyOwner {
        priceConsumer = _priceConsumer;
    }

    // Allow dev to set router, for when we start an AMM
    function setPancakeRouter(address _pancakeRouter) public onlyOwner {
        pancakeswapRouter = IUniswapV2Router02(_pancakeRouter);
    }

    // Helpers
    function unpairBurnAndTreasureLP(address lpAddress, uint _amount) private {
        // unpair
        IUniswapV2Pair lp = IUniswapV2Pair(lpAddress);
        IGraveStakingToken _token0 = IGraveStakingToken(lp.token0());
        IGraveStakingToken _token1 = IGraveStakingToken(lp.token1());

        uint256 _initialToken0Balance = _token0.balanceOf(address(this));
        uint256 _initialToken1Balance = _token1.balanceOf(address(this));

        // allow pancake router
        lp.approve(address(pancakeswapRouter), _amount);

        // unpair lp
        pancakeswapRouter.removeLiquidity(
            address(_token0),
            address(_token1),
            _amount,
            0,
            0,
            address(this),
            block.timestamp
        );

        uint256 _token0Amount = _token0.balanceOf(address(this)) - _initialToken0Balance;
        uint256 _token1Amount = _token1.balanceOf(address(this)) - _initialToken1Balance;

        // burn zombie token if included in pair
        if(address(_token0) == address(zombie) || address(_token1) == address(zombie)) {
            if(address(_token0) == address(zombie)) {             // if _token0 is ZMBE
                _token0.transfer(burnAddr, _token0Amount);        // burn the unpaired token0
                _token1.transfer(treasury, _token1Amount);          // send the unpaired token1 to treasury
            } else {                                            // else if _token1 is ZMBE
                _token1.transfer(burnAddr, _token1Amount);        // burn the unpaired token1
                _token0.transfer(treasury, _token0Amount);          // send the unpaired token0 to treasury
            }
        } else { // send both tokens to treasury if pair doesnt contain ZMBE token
            _token0.transfer(treasury, _token0Amount);
            _token1.transfer(treasury, _token1Amount);
        }
    }

    // Buys Zombie with BNB
    function swapZombieForBnb(uint256 bnbAmount) private {
        address[] memory path = new address[](2);
        path[0] = pancakeswapRouter.WETH();
        path[1] = address(zombie);

        IGraveStakingToken WBNB = IGraveStakingToken(pancakeswapRouter.WETH());
        WBNB.approve(address(pancakeswapRouter), bnbAmount);

        // make the swap
        pancakeswapRouter.swapExactETHForTokens{value: bnbAmount} (
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    // Buys and burns zombie
    function buyBackAndBurn(uint bnbAmount) private {
        uint256 _initialZombieBalance = zombie.balanceOf(address(this));
        swapZombieForBnb(bnbAmount);
        uint256 _zombieBoughtBack = zombie.balanceOf(address(this)) - _initialZombieBalance;
        zombie.transfer(burnAddr, _zombieBoughtBack); // Send bought zombie to burn address
    }

    // Returns grave unlock fee in bnb
    function unlockFeeInBnb(uint _gid) public view returns(uint) {
        return priceConsumer.usdToBnb(poolInfo[_gid].unlockFee);
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../utils/introspection/IERC165.sol";

/**x
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IGraveStakingToken {

    /**
    * @dev Mints the amount of tokens to the address specified.
    */
    function mint(address _to, uint256 _amount) external;

    /**
    * @dev Mints the amount of tokens to the caller's address.
    */
    function mint(uint _amount) external;

    /**
    * @dev Burns the amount of tokens from the msg.sender.
    */
    function burn(uint256 _amount) external;

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IPriceConsumerV3 {
    function getLatestPrice() external view returns (uint);
    function unlockFeeInBnb(uint) external view returns (uint);
    function usdToBnb(uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '../token/ERC721/ERC721.sol';
import '../access/Ownable.sol';
import '../utils/Counters.sol';


interface IRevivedRugNft {
    function reviveRug(address _to) external returns(uint);
    function owner() external returns(address);
    function ownerOf(uint _id) external returns(address);
    function transferFrom(address _from, address _to, uint _id) external;
    function renounceOwnership() external;
    function baseURI() external returns(string memory);
}

pragma solidity ^0.8.4;

// UndeadBar interface.
interface IUndeadBar {
    function mint(address _to, uint256 _amount) external;
    function burn(address _from ,uint256 _amount) external;
    function safeZombieTransfer(address _to, uint256 _amount) external;
    function delegates(address delegator) external view returns (address);
    function delegate(address delegatee) external;
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
    function getCurrentVotes(address account) external view returns (uint256);
    function getPriorVotes(address account, uint blockNumber) external view returns (uint256);
    function safe32(uint n, string memory errorMessage) external pure returns (uint32);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.8.4;

// ZombieToken interface.
interface IZombieToken {
    function mint(address _to, uint256 _amount) external;
    function delegates(address delegator) external view returns (address);
    function delegate(address delegatee) external;
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
    function transferOwnership(address newOwner) external;
    function getCurrentVotes(address account) external view returns (uint256);
    function getPriorVotes(address account, uint blockNumber) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function liftLaunchWhaleDetection() external;
}

pragma solidity ^0.8.4;

library Percentages {
    // Get value of a percent of a number
    function calcPortionFromBasisPoints(uint _amount, uint _basisPoints) public pure returns(uint) {
        if(_basisPoints == 0 || _amount == 0) {
            return 0;
        } else {
            uint _portion = _amount * _basisPoints / 10000;
            return _portion;
        }
    }

    // Get basis points (percentage) of _portion relative to _amount
    function calcBasisPoints(uint _amount, uint  _portion) public pure returns(uint) {
        if(_portion == 0 || _amount == 0) {
            return 0;
        } else {
            uint _basisPoints = (_portion * 10000) / _amount;
            return _basisPoints;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../../interfaces/IERC721.sol";
import "../../interfaces/IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
        || interfaceId == type(IERC721Metadata).interfaceId
        || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
    private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../../../interfaces/IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns ( bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

function decrement(Counter storage counter) internal {
    uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

