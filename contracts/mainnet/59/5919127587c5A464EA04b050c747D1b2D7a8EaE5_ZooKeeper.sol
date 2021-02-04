// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./ZooKeeper.sol";

// BambooField allows you to grow your Bamboo! Buy some seeds, and then harvest them for more Bamboo!
//
contract BambooField is ERC20("Seed", "SEED"), Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    // Info of each user that can buy seeds.
    mapping (address => FarmUserInfo) public userInfo;
    BambooToken public bamboo;
    ZooKeeper public zooKeeper;
    // Amount needed to register
    uint256 public registerAmount;
    // Amount locked as collateral
    uint256 public depositPool;
    // Minimum time to harvest. Also min time of lock in the deposit.
    uint256 public minStakeTime;

    struct FarmUserInfo {
        uint256 amount;             // Deposited Amount
        uint poolId;                // Pool ID of active staking LP
        uint256 startTime;          // Timestamp of registration
        bool active;                // Flag for checking if this entry is active.
        uint256 endTime;            // Last timestamp the user can buy seeds. Only used if this is not active
    }

    event RegisterAmountChanged(uint256 amount);
    event StakeTimeChanged(uint256 time);

    constructor(BambooToken _bamboo, ZooKeeper _zoo, uint256 _registerprice, uint256 _minstaketime) {
        bamboo= _bamboo;
        zooKeeper = _zoo;
        registerAmount = _registerprice;
        minStakeTime = _minstaketime;
    }

    // Register a staking pool to the user with a collateral payment
    function register(uint _pid, uint256 _amount) public {
        require( _pid < zooKeeper.getPoolLength() , "register: invalid pool");
        require(_amount > registerAmount, "register: amount should be bigger than registerAmount");
        require(userInfo[msg.sender].amount == 0, "register: already registered");
        // Get the poolId
        uint256 amount = zooKeeper.getLpAmount(_pid, msg.sender);
        require(amount > 0, 'register: no LP on pool');
        uint256 seedAmount = _amount.sub(registerAmount);
        // move the registerAmount
        IERC20(bamboo).safeTransferFrom(address(msg.sender), address(this), registerAmount);
        depositPool = depositPool.add(registerAmount);
        // save user data
        userInfo[msg.sender] = FarmUserInfo(registerAmount, _pid, block.timestamp, true, 0);
        // buy seeds with the rest
        buy(seedAmount);
    }

    // Buy some Seeds with BAMBOO.
    // Requires an active register of LP staking, or endTime still valid.
    function buy(uint256 _amount) public {
        // Checks if user is valid
        if(!userInfo[msg.sender].active) {
            require(userInfo[msg.sender].endTime >= block.timestamp, "buy: invalid user");
        }
        // Gets the amount of usable BAMBOO locked in the contract
        uint256 totalBamboo = bamboo.balanceOf(address(this)).sub(depositPool);
        // Gets the amount of Seeds in existence
        uint256 totalShares = totalSupply();
        // If no Seeds exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalBamboo == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of Seeds the BAMBOO is worth. The ratio will change overtime, as Seeds are burned/minted and BAMBOO is deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalBamboo);
            _mint(msg.sender, what);
        }
        // Lock the BAMBOO in the contract
        IERC20(bamboo).safeTransferFrom(address(msg.sender), address(this), _amount);
    }

    // Harvest your BAMBOO
    // Unlocks the staked + gained BAMBOO and burns Seeds
    function harvest(uint256 _share) public {
        // Checks if time is valid
        require(block.timestamp.sub(userInfo[msg.sender].startTime) >= minStakeTime, "buy: cannot harvest seeds at this time");
        // Gets the amount of Seeds in existence
        uint256 totalShares = totalSupply();
        uint256 totalBamboo = bamboo.balanceOf(address(this)).sub(depositPool);
        // Calculates the amount of BAMBOO the Seeds are worth
        uint256 what = _share.mul(totalBamboo).div(totalShares);
        _burn(msg.sender, _share);
        IERC20(bamboo).safeTransfer(msg.sender, what);
    }

    // Register a staking pool to the user with a collateral payment
    function withdraw() public {
        // Checks if timestamp is valid
        require(block.timestamp.sub(userInfo[msg.sender].startTime) >= minStakeTime, "withdraw: cannot withdraw yet!");
        // Harvest remaining seeds
        uint256 seeds = balanceOf(msg.sender);
        if (seeds>0){
            harvest (seeds);
        }
        uint256 deposit = userInfo[msg.sender].amount;
        // Reset user data
        delete(userInfo[msg.sender]);
        // Return deposit
        IERC20(bamboo).safeTransfer(msg.sender, deposit);
        depositPool = depositPool.sub(deposit);
    }

    // This function will be called from ZooKeeper if LP balance is withdrawn
    function updatePool(address _user) external {
        require(ZooKeeper(msg.sender) == zooKeeper, "updatePool: contract was not ZooKeeper");
        userInfo[_user].active = false;
        // Get 60 days to buy shares if you staked LP at least 60 days
        if(block.timestamp - userInfo[_user].startTime >= 60 days){
            userInfo[_user].endTime = block.timestamp + 60 days;
        }
    }

    // Changes the entry collateral amount.
    function setRegisterAmount(uint256 _amount) external onlyOwner {
        registerAmount = _amount;
        emit RegisterAmountChanged(registerAmount);
    }

    // Changes the min stake time in seconds.
    function setStakeTime(uint256 _mintime) external onlyOwner {
        minStakeTime = _mintime;
        emit StakeTimeChanged(minStakeTime);
    }

    // Check if user is active with an specific pool
    function isActive(address _user, uint _pid) public view returns(bool) {
        return userInfo[_user].active && userInfo[_user].poolId == _pid;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./token/BambooToken.sol";
import "./BambooField.sol";


interface IMigratorKeeper {
    // Perform LP token migration from legacy UniswapV2 to BambooDeFi.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // BambooDeFi must mint EXACTLY the same amount of BambooDeFi LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// ZooKeeper is the master of pandas. He can make Bamboo and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once BAMBOO is sufficiently
// distributed and the community can show to govern itself.
//
contract ZooKeeper is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Total time rewards
    uint256 public constant TIME_REWARDS_LENGTH = 12;

    // Lock times available in seconds for 1 day, 7 days, 15 days, 30 days, 60 days, 90 days, 180 days, 1 year, 2 years, 3 years, 4 years, 5 years
    uint256[TIME_REWARDS_LENGTH] public timeRewards = [1 days, 7 days, 15 days, 30 days, 60 days, 90 days, 180 days, 365 days, 730 days, 1095 days, 1460 days, 1825 days];
    // Lock times saved in a map, for quick validation
    mapping(uint256 => bool) public validTimeRewards;

    // Info of each user.
    struct  LpUserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 lastLpDeposit;   // Last time user made a deposit
        //
        // We do some fancy math here. Basically, any point in time, the amount of BAMBOOs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBambooPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBambooPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    struct  BambooDeposit {
        uint256 amount;             // How many BAMBOO tokens the user has deposited.
        uint256 lockTime;           // Time in seconds that need to pass before this deposit can be withdrawn.
        bool active;                // Flag for checking if this entry is actively staking.
        uint256 totalReward;        // The total reward that will be collected from this deposit.
        uint256 dailyReward;        // The amount of bamboo that could be claimed daily.
        uint256 lastTime;           // Last timestamp when the daily rewards where collected.
    }

    struct BambooUserInfo {
        mapping(uint256 => BambooDeposit) deposits;    // Deposits from the user.
        uint256[] ids;                                  // Active deposits from the user.
        uint256 totalAmount;                            // Total amount of active deposits from the user.
        uint256 lastDeposit;                            // Timestamp of last deposit from user
    }

    struct StakeMultiplierInfo {
        uint256[TIME_REWARDS_LENGTH] multiplierBonus;       // Array of the different multipliers.
        bool registered;                                    // If this amount has been registered
    }

    struct YieldMultiplierInfo {
        uint256 multiplier;                                 // Multiplier value.
        bool registered;                                    // If this amount has been registered
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. BAMBOOs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that BAMBOOs distribution occurs.
        uint256 accBambooPerShare; // Accumulated BAMBOOs per share, times 1e12. See below.
    }

    // The BAMBOO TOKEN
    BambooToken public bamboo;
    // BAMBOO tokens created per block.
    uint256 public bambooPerBlock;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorKeeper public migrator;
    // The BambooField contract. If active, validates the lp staking for additional rewards.
    BambooField public bambooField;
    // If the BambooField is activated. Can be turned off by owner
    bool public isField;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping (address => LpUserInfo)) public userInfo;
    // Info of the additional multipliers for BAMBOO staking
    mapping(uint256 => StakeMultiplierInfo) public stakeMultipliers;
    // Info of the multipliers available for YieldFarming + staking
    mapping(uint256 => YieldMultiplierInfo) public yieldMultipliers;
    // Amounts registered for yield multipliers
    uint256[] public yieldAmounts;
    // Info of each user that stakes BAMBOO.
    mapping(address => BambooUserInfo) public bambooUserInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BAMBOO mining starts.
    uint256 public startBlock;
    // Min time of stake and yield for multiplier rewards
    uint256 public minYieldTime = 7 days;
    uint256 public minStakeTime = 1 days;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event BAMBOODeposit(address indexed user, uint256 amount, uint256 lockTime, uint256 id);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event BAMBOOWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event BAMBOOBonusWithdraw(address indexed user, uint256 indexed pid, uint256 amount, uint256 ndays);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "ZooKeeper: must use EOA");
        _;
    }

    constructor(BambooToken _bamboo, uint256 _bambooPerBlock, uint256 _startBlock) {
        require(_bambooPerBlock > 0, "invalid bamboo per block");
        bamboo = _bamboo;
        bambooPerBlock = _bambooPerBlock;
        startBlock = _startBlock;
        for(uint i=0; i<TIME_REWARDS_LENGTH; i++) {
            validTimeRewards[timeRewards[i]] = true;
        }
    }


    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken) public onlyOwner {
        massUpdatePools();
        checkPoolDuplicate(_lpToken);
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accBambooPerShare: 0
        }));
    }

    // Update the given pool's BAMBOO allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint) public onlyOwner {
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorKeeper _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. We trust that migrator contract is correct.
    function migrate(uint256 _pid) public onlyOwner {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }


    // BambooDeFi setup
    // Add a new row of bamboo staking rewards. E.G. 500 (bamboos) -> [10001 (x1.0001*10000), ... ].
    // Adding an existing amount will repace it. Can only be called by the owner.
    function addStakeMultiplier(uint256 _amount, uint256[TIME_REWARDS_LENGTH] memory _multiplierBonuses) public onlyOwner {
        require(_amount > 0, "addStakeMultiplier: invalid amount");
        // Validate that multipliers are valid
        for(uint i=0; i<TIME_REWARDS_LENGTH; i++){
            require(_multiplierBonuses[i] >= 10000, "addStakeMultiplier: invalid multiplier array");
        }
        uint mLength = _multiplierBonuses.length;
        require(mLength== TIME_REWARDS_LENGTH, "addStakeMultiplier: invalid array length");
        StakeMultiplierInfo memory mInfo = StakeMultiplierInfo({multiplierBonus: _multiplierBonuses, registered:true});
        stakeMultipliers[_amount] = mInfo;
    }


    // Add a new amount for yield farming rewards. E.G. 500 (bamboos) -> 10001 (x1.0001*10000). Adding an existing amount will replace it.
    // Can only be called by the owner.
    function addYieldMultiplier(uint256 _amount, uint256 _multiplierBonus ) public onlyOwner {
        require(_amount > 0, "addYieldMultiplier: invalid amount");
        // 10000 is a x1 multiplier.
        require(_multiplierBonus >= 10000, "addYieldMultiplier: invalid multiplier");
        if(!yieldMultipliers[_amount].registered){
            yieldAmounts.push(_amount);
        }
        YieldMultiplierInfo memory mInfo = YieldMultiplierInfo({multiplier: _multiplierBonus, registered:true});
        yieldMultipliers[_amount] = mInfo;
    }

    // Remove. Will not affect current deposits, since rewards are calculated at deposit time.
    function removeStakeMultiplier(uint256 _amount) public onlyOwner {
        require(stakeMultipliers[_amount].registered, "removeStakeMultiplier: nothing to remove");
        delete(stakeMultipliers[_amount]);
    }

    // Remove yieldMultiplier.
    function removeYieldMultiplier(uint256 _amount) public onlyOwner {
        require(yieldMultipliers[_amount].registered, "removeYieldMultiplier: nothing to remove");
        // Find index
        for(uint i=0; i<yieldAmounts.length; i++) {
            if(yieldAmounts[i] == _amount){
                // Remove
                yieldAmounts[i] = yieldAmounts[yieldAmounts.length -1];
                yieldAmounts.pop();
                break;
            }
        }
        delete(yieldMultipliers[_amount]);
    }

    // Return reward multiplier over the given the time spent staking and the amount locked
    function getStakingMultiplier(uint256 _time, uint256 _amount) public view returns (uint256) {
        uint256 index = getTimeEarned(_time);
        StakeMultiplierInfo storage multiInfo = stakeMultipliers[_amount];
        require(multiInfo.registered, "getStakingMultiplier: invalid amount");
        uint256 res = multiInfo.multiplierBonus[index];
        return res;
    }

    // Returns reward multiplier for yieldFarming + BambooStaking
    function getYieldMultiplier(uint256 _amount) public view returns (uint256) {
        uint256 key=0;
        for(uint i=0; i<yieldAmounts.length; i++) {
            if (_amount >= yieldAmounts[i] ) {
                key = yieldAmounts[i];
            }
        }
        if(key == 0) {
            return 10000;
        }
        else {
            return yieldMultipliers[key].multiplier;
        }
    }

    // Returns the active deposits from a user.
    function getDeposits(address _user) public view returns (uint256[] memory) {
        return bambooUserInfo[_user].ids;
    }

    // Returns the deposit amount and the minimum timestamp where the deposit can be withdrawn.
    function getDepositInfo(address _user, uint256 _id) public view returns (uint256, uint256) {
        BambooDeposit storage _deposit = bambooUserInfo[_user].deposits[_id];
        require(_deposit.active, "deposit does not exist");
        return (_deposit.amount, _id.add(_deposit.lockTime));
    }

    // Returns amount of stake rewards available to claim, and the days that are being accounted.
    function getClaimableBamboo(uint256 _id, address _addr ) public view returns(uint256, uint256) {
        BambooUserInfo storage user = bambooUserInfo[_addr];
        // If it's the last withdraw
        if(block.timestamp >= _id.add(user.deposits[_id].lockTime) ){
            uint pastdays = user.deposits[_id].lastTime.sub(_id).div(1 days);
            uint256 leftToClaim = user.deposits[_id].totalReward.sub(pastdays.mul(user.deposits[_id].dailyReward));
            return (leftToClaim, (user.deposits[_id].lockTime.div(1 days)).sub(pastdays));
        }
        else{
            uint256 ndays = (block.timestamp.sub(user.deposits[_id].lastTime)).div(1 days);
            return (ndays.mul(user.deposits[_id].dailyReward), ndays);
        }
    }


    // View function to see pending BAMBOOs on frontend.
    function pendingBamboo(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        LpUserInfo storage user = userInfo[_pid][_user];
        uint256 bambooUserAmount = bambooUserInfo[_user].totalAmount;
        uint256 accBambooPerShare = pool.accBambooPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 yMultiplier = 10000;
        if (block.timestamp - user.lastLpDeposit > minYieldTime && block.timestamp - bambooUserInfo[_user].lastDeposit > minStakeTime) {
            yMultiplier = getYieldMultiplier(bambooUserAmount);
        }
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = block.number.sub(pool.lastRewardBlock);
            uint256 bambooReward = multiplier.mul(bambooPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accBambooPerShare = accBambooPerShare.add(bambooReward.mul(1e12).div(lpSupply));
        }
        uint256 pending = user.amount.mul(accBambooPerShare).div(1e12).sub(user.rewardDebt);
        return yMultiplier.mul(pending).div(10000);
    }

    // View function to see pending BAMBOOS to claim on staking. Returns total amount of pending bamboo to claim in the future,
    // and the amount available to claim at the moment.
    function pendingStakeBamboo(uint256 _id, address _addr) external view returns (uint256, uint256) {
        BambooUserInfo storage user = bambooUserInfo[_addr];
        require(user.deposits[_id].active, "pendingStakeBamboo: invalid id");
        uint256 claimable;
        uint256 ndays;
        (claimable, ndays) = getClaimableBamboo(_id, _addr);
        if (block.timestamp.sub(user.deposits[_id].lastTime) >= user.deposits[_id].lockTime){
            return (claimable, claimable);
        }
        else{
            uint pastdays = user.deposits[_id].lastTime.sub(_id).div(1 days);
            uint256 leftToClaim = user.deposits[_id].totalReward.sub(pastdays.mul(user.deposits[_id].dailyReward));
            return (leftToClaim, claimable);
        }
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
        uint256 multiplier = block.number.sub(pool.lastRewardBlock);
        uint256 bambooReward = multiplier.mul(bambooPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        bamboo.mint(address(this), bambooReward);
        pool.accBambooPerShare = pool.accBambooPerShare.add(bambooReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit Functions
    // Deposit LP tokens to ZooKeeper for BAMBOO allocation.
    function deposit(uint256 _pid, uint256 _amount) public onlyEOA {
        require ( _pid < poolInfo.length , "deposit: pool exists?");
        PoolInfo storage pool = poolInfo[_pid];
        LpUserInfo storage user = userInfo[_pid][msg.sender];
        uint256 bambooUserAmount = bambooUserInfo[msg.sender].totalAmount;
        updatePool(_pid);
        if (user.amount > 0) {
            // Allocate how much bamboo corresponds to user
            uint256 pending = user.amount.mul(pool.accBambooPerShare).div(1e12).sub(user.rewardDebt);
            // If user has pending rewards from previous blocks
            if (pending > 0) {
                uint256 bonus = mintBonusBamboo(pending, user.lastLpDeposit, bambooUserInfo[msg.sender].lastDeposit, bambooUserAmount);
                safeBambooTransfer(msg.sender, pending.add(bonus));
            }
        }
        // Now take care of the new deposit
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            user.lastLpDeposit = block.timestamp;
        }
        user.rewardDebt = user.amount.mul(pool.accBambooPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Deposit Bamboo to ZooKeeper for additional staking rewards. Bamboos should be approved
    function depositBamboo(uint256 _amount, uint256 _lockTime) public onlyEOA {
        require(stakeMultipliers[_amount].registered, "depositBamboo: invalid amount");
        require(validTimeRewards[_lockTime] , "depositBamboo: invalid lockTime");
        BambooUserInfo storage user = bambooUserInfo[msg.sender];
        require(!user.deposits[block.timestamp].active, "depositBamboo: only 1 deposit per block!");
        if(_amount > 0) {
            IERC20(bamboo).safeTransferFrom(address(msg.sender), address(this), _amount);
            // Calculate the final rewards
            uint256 multiplier = getStakingMultiplier(_lockTime, _amount);
            uint256 pending = (multiplier.mul(_amount).div(10000)).sub(_amount);
            uint totaldays = _lockTime / 1 days;
            BambooDeposit memory depositData = BambooDeposit({
                amount: _amount,
                lockTime: _lockTime,
                active: true,
                totalReward:pending,
                dailyReward:pending.div(totaldays),
                lastTime: block.timestamp
            });
            user.ids.push(block.timestamp);
            user.deposits[block.timestamp] = depositData;
            user.totalAmount = user.totalAmount.add(_amount);
            user.lastDeposit = block.timestamp;
        }
        emit BAMBOODeposit(msg.sender, _amount, _lockTime, block.timestamp);
    }

    // Withdraw Functions

    // Withdraw LP tokens from ZooKeeper.
    function withdraw(uint256 _pid, uint256 _amount) public onlyEOA {
        PoolInfo storage pool = poolInfo[_pid];
        LpUserInfo storage user = userInfo[_pid][msg.sender];
        uint256 bambooUserAmount = bambooUserInfo[msg.sender].totalAmount;
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accBambooPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            uint256 bonus = mintBonusBamboo(pending, user.lastLpDeposit, bambooUserInfo[msg.sender].lastDeposit, bambooUserAmount);
            safeBambooTransfer(msg.sender, pending.add(bonus));
        }
        if(_amount > 0){
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            // Notify the BambooField if active
            if(user.amount == 0 && isField){
                if(bambooField.isActive(msg.sender, _pid)){
                    bambooField.updatePool(msg.sender);
                }
            }
        }
        user.rewardDebt = user.amount.mul(pool.accBambooPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw a Bamboo deposit from ZooKeeper.
    function withdrawBamboo(uint256 _depositId) public onlyEOA {
        BambooUserInfo storage user = bambooUserInfo[msg.sender];
        require(user.deposits[_depositId].active, "withdrawBamboo: invalid id");
        uint256 depositEnd = _depositId.add(user.deposits[_depositId].lockTime) ;
        // Get the depositIndex for deleting it later from the active ids
        uint depositIndex = 0;
        for (uint i=0; i<user.ids.length; i++){
            if (user.ids[i] == _depositId){
                depositIndex = i;
                break;
            }
        }
        require(user.ids[depositIndex] == _depositId, "withdrawBamboo: invalid id");
        // User cannot withdraw before the lockTime
        require(block.timestamp >= depositEnd, "withdrawBamboo: cannot withdraw yet!");
        uint256 amount = user.deposits[_depositId].amount;
        withdrawDailyBamboo(_depositId);
        // Clean up the removed deposit
        user.ids[depositIndex] = user.ids[user.ids.length -1];
        user.ids.pop();
        user.totalAmount = user.totalAmount.sub(user.deposits[_depositId].amount);
        delete user.deposits[_depositId];
        safeBambooTransfer(msg.sender, amount);
        emit BAMBOOWithdraw(msg.sender, _depositId, amount);
    }

    // Withdraw the bonus staking Bamboo available from this deposit.
    function withdrawDailyBamboo(uint256 _depositId) public onlyEOA {
        BambooUserInfo storage user = bambooUserInfo[msg.sender];
        require(user.deposits[_depositId].active, "withdrawDailyBamboo: invalid id");
        uint256 depositEnd = _depositId.add(user.deposits[_depositId].lockTime);
        uint256 amount;
        uint256 ndays;
        (amount, ndays) = getClaimableBamboo(_depositId, msg.sender);
        uint256 newLastTime =  user.deposits[_depositId].lastTime.add(ndays.mul(1 days));
        assert(newLastTime <= depositEnd);
        user.deposits[_depositId].lastTime =  newLastTime;
        // Mint the bonus bamboo
        bamboo.mint(msg.sender, amount);
        emit BAMBOOBonusWithdraw(msg.sender, _depositId, amount, ndays);
    }

    function mintBonusBamboo(uint256 pending, uint256 lastLp, uint256 lastStake, uint256 bambooUserAmount) internal returns (uint256) {
        // Check if user is eligible for a multiplier, depending of last time of lp && bamboo deposit
        if (block.timestamp - lastLp > minYieldTime && block.timestamp - lastStake > minStakeTime && bambooUserAmount > 0) {
            uint256 multiplier = getYieldMultiplier(bambooUserAmount);
            // Pending*multiplier
            uint256 pmul = multiplier.mul(pending).div(10000);
            // Bonus BAMBOO from multiplier
            uint256 bonus = pmul.sub(pending);
            // Mint the bonus
            bamboo.mint(address(this), bonus);
            return bonus;
        }
        return 0;
    }

    // Withdraw LPs without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        LpUserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount=user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // Return the index of the time reward that can be claimed.
    function getTimeEarned(uint256 _time) internal view returns (uint256) {
        require(_time >= timeRewards[0], "getTimeEarned: invalid time");
        uint256 index=0;
        for(uint i=1; i<TIME_REWARDS_LENGTH; i++) {
            if (_time >= timeRewards[i] ) {
                index = i;
            }
            else{
                break;
            }
        }
        return index;
    }

    // Safe bamboo transfer function, just in case if rounding error causes pool to not have enough BAMBOOs.
    function safeBambooTransfer(address _to, uint256 _amount) internal {
        uint256 bambooBal = bamboo.balanceOf(address(this));
        if (_amount > bambooBal) {
            IERC20(bamboo).safeTransfer(_to, bambooBal);
        } else {
            IERC20(bamboo).safeTransfer(_to, _amount);
        }
    }

    function checkPoolDuplicate (IERC20 _lpToken) public view {
         uint256 length = poolInfo.length;
         for(uint256 pid = 0; pid < length ; ++pid) {
            require (poolInfo[pid].lpToken != _lpToken , "add: existing pool?");
        }
    }

    function getPoolLength() public view returns(uint count) {
        return poolInfo.length;
    }

    function getLpAmount(uint _pid, address _user) public view returns(uint256) {
        return userInfo[_pid][_user].amount;
    }

    // Switch BambooField active.
    function switchBamboField(BambooField _bf) public onlyOwner {
        if(isField){
            isField = false;
        }
        else{
            isField = true;
            bambooField = _bf;
        }
    }

    // Claim ownership for token
    function claimToken() public onlyOwner {
        // Bamboo Token should have proposedOwner before this
        bamboo.claimOwnership();
    }

    // Update minYieldTime ans minStakeTime in seconds. If it's too big, would disable yield bonuses.
    function minYield(uint256 _yTime, uint256 _sTime) public onlyOwner {
        minYieldTime = _yTime;
        minStakeTime = _sTime;
    }

    // Change bamboo per block. Affects rewards for all users.
    function changeBambooPerBlock(uint256 _bamboo) public onlyOwner {
        require(_bamboo > 0, "changeBambooPerBlock: invalid amount");
        bambooPerBlock = _bamboo;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Ownable.sol";

//BambooToken with Governance
contract BambooToken is ERC20("BambooDeFi", "BAMBOO"), Ownable {
    using SafeMath for uint256;

    /// @dev A record of each accounts delegate
    mapping(address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint256 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256(
        "Delegation(address delegatee,uint256 nonce,uint256 expiry)"
    );

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    event Minted(
        address indexed minter,
        address indexed receiver,
        uint256 mintAmount
    );
    event Burned(address indexed burner, uint256 burnAmount);

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        emit Minted(owner(), _to, _amount);
    }

    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "BAMBOO::delegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "BAMBOO::delegateBySig: invalid nonce"
        );
        require(block.timestamp <= expiry, "BAMBOO::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256)
    {
        require(
            blockNumber < block.number,
            "BAMBOO::getPriorVotes: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying BAMBOOs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0
                    ? checkpoints[srcRep][srcRepNum - 1].votes
                    : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0
                    ? checkpoints[dstRep][dstRepNum - 1].votes
                    : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint256 blockNumber = block.number;

        if (
            nCheckpoints > 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                blockNumber,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        _moveDelegates(_delegates[from], _delegates[to], amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/GSN/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {proposeOwner/claimOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    address private proposedOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        proposedOwner = address(0);
    }

    /**
     * @dev Proposes a new owner of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function proposeOwner(address _proposedOwner) public onlyOwner {
        require(msg.sender != _proposedOwner, "ERROR_CALLER_ALREADY_OWNER");
        proposedOwner = _proposedOwner;
    }

    /**
     * @dev If the address has been proposed, it can accept the ownership,
     * Can only be called by the current proposed owner.
     */
    function claimOwnership() public {
        require(msg.sender == proposedOwner, "ERROR_NOT_PROPOSED_OWNER");
        emit OwnershipTransferred(_owner, proposedOwner);
        _owner = proposedOwner;
        proposedOwner = address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}