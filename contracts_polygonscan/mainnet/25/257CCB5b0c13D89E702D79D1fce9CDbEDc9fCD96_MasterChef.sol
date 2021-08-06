// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libs/IERC20.sol";
import "./libs/SafeERC20.sol";
import "./libs/IArcadiumReferral.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./MyFriendsToken.sol";
import "./ArcadiumToken.sol";


// MasterChef is the master of Arcadium. He can make Arcadium and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once ARCADIUM is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdcRewardCurrency;

    // Burn address
    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Founder 1 address
    address public constant FOUNDER1_ADDRESS = 0x3a1D1114269d7a786C154FE5278bF5b1e3e20d31;
    // Founder 2 address
    address public constant FOUNDER2_ADDRESS = 0x30139dfe2D78aFE7fb539e2F2b765d794fe52cB4;

    uint256 constant initialFounderMyFriendsStake = 16250 * (10 ** 18);

    // Must be after startBlock.
    uint256 public immutable founderFinalLockupEndBlock;

    uint256 public totalUSDCCollected = 0;

    uint256 accDepositUSDCRewardPerShare = 0;

    // The MYFRIENDS TOKEN!
    MyFriendsToken public myFriends;
    // The ARCADIUM TOKEN!
    ArcadiumToken public arcadium;
    // Arcadium's trusty utility belt.
    RHCPToolBox public arcadiumToolBox;

    uint256 public arcadiumReleaseGradient;
    uint256 public endArcadiumGradientBlock;
    uint256 public endGoalArcadiumEmission;
    bool public isIncreasingGradient = false;

    // MYFRIENDS tokens created per block.
    uint256 public constant myFriendsPerBlock = 32 * (10 ** 15);

    // The block number when ARCADIUM & MYFRIENDS mining ends.
    uint256 public myFriendsEmmissionEndBlock = type(uint256).max;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 arcadiumRewardDebt;     // Reward debt. See explanation below.
        uint256 myFriendsRewardDebt;     // Reward debt. See explanation below.
        uint256 usdcRewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ARCADIUMs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accArcadiumPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accArcadiumPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. ARCADIUMs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that ARCADIUMs distribution occurs.
        uint256 accArcadiumPerShare;   // Accumulated ARCADIUMs per share, times 1e24. See below.
        uint256 accMyFriendsPerShare;   // Accumulated MYFRIENDSs per share, times 1e24. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint8 tokenType;          // 0=Token, 1=LP Token
        uint256 totalLocked;      // total units locked in the pool
    }

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when normal ARCADIUM mining starts.
    uint256 public startBlock;


    // The last checked balance of ARCADIUM in the burn waller
    uint256 public lastArcadiumBurnBalance = 0;
    // How much of burn do myFriends stakers get out of 10000
    uint256 public myFriendsShareOfBurn = 8197;

    // Arcadium referral contract address.
    IArcadiumReferral arcadiumReferral;
    // Referral commission rate in basis points.
    // This is split into 2 halves 3% for the referrer and 3% for the referee.
    uint16 public constant referralCommissionRate = 600;

    uint256 public gradientEra = 1;

    uint256 public immutable gradient2EndBlock;
    uint256 public constant gradient2EndEmmissions = 692023838 * (10 ** 9);

    uint256 public gradient3EndBlock;
    uint256 public constant gradient3EndEmmissions  = 1384047676 * (10 ** 9);

    uint256 public constant myFriendsPID = 0;

    uint256 public constant maxPools = 69;

    event AddPool(uint256 indexed pid, uint8 tokenType, uint256 allocPoint, address lpToken, uint256 depositFeeBP);
    event SetPool(uint256 indexed pid, uint256 allocPoint, uint256 depositFeeBP);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event GradientUpdated(uint256 newEndGoalArcadiumEmmission, uint256 newEndArcadiumEmmissionBlock);
    event SetArcadiumReferral(address arcadiumAddress);

    constructor(
        MyFriendsToken _myFriends,
        ArcadiumToken _arcadium,
        RHCPToolBox _arcadiumToolBox,
        address _usdcCurrencyAddress,
        uint256 _startBlock,
        uint256 _founderFinalLockupEndBlock,
        uint256 _beginningArcadiumEmission,
        uint256 _endArcadiumEmission,
        uint256 _gradient1EndBlock,
        uint256 _gradient2EndBlock,
        uint256 _gradient3EndBlock
    ) public {
        myFriends = _myFriends;
        arcadium = _arcadium;
        arcadiumToolBox = _arcadiumToolBox;

        startBlock = _startBlock;
        usdcRewardCurrency = IERC20(_usdcCurrencyAddress);

        require(_startBlock < _founderFinalLockupEndBlock, "founder MyFriends lockup block invalid");
        founderFinalLockupEndBlock = _founderFinalLockupEndBlock;

        require(_startBlock < _gradient1EndBlock + 40, "gradient period 1 invalid");
        require(_gradient1EndBlock < _gradient2EndBlock + 40, "gradient period 2 invalid");
        require(_gradient2EndBlock < _gradient3EndBlock + 40, "gradient period 3 invalid");

        require(_beginningArcadiumEmission > 0.166666 ether && _endArcadiumEmission > 0.166666 ether,
            "arcadium emissions too big");

        endArcadiumGradientBlock = _gradient1EndBlock;
        endGoalArcadiumEmission = _endArcadiumEmission;

        gradient2EndBlock = _gradient2EndBlock;
        gradient3EndBlock = _gradient3EndBlock;

        require(endGoalArcadiumEmission < 101 ether, "cannot allow > than 101 ARCADIUM per block");

        arcadiumReleaseGradient = _arcadiumToolBox.calcEmissionGradient(
            block.number, _beginningArcadiumEmission, endArcadiumGradientBlock, endGoalArcadiumEmission);

        add(0, 100, _myFriends, 0, false);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint8 _tokenType, uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        require(poolInfo.length < maxPools,  "too many pools!");
        // Make sure the provided token is ERC20
        _lpToken.balanceOf(address(this));

        require(_depositFeeBP <= 401/*, "add: invalid deposit fee basis points"*/);
        require(_tokenType == 0 || _tokenType == 1, "invalid token type");
        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;

        poolExistence[_lpToken] = true;

        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accArcadiumPerShare: 0,
            accMyFriendsPerShare: 0,
            depositFeeBP: _depositFeeBP,
            tokenType: _tokenType,
            totalLocked: 0
        }));

        emit AddPool(poolInfo.length - 1, _tokenType, _allocPoint, address(_lpToken), _depositFeeBP);
    }

    // Update the given pool's ARCADIUM allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= 401, "bad depositBP");

        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = (totalAllocPoint - poolInfo[_pid].allocPoint) + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        //poolInfo[_pid].tokenType = _tokenType;
        //poolInfo[_pid].totalLocked = poolInfo[_pid].totalLocked;

        emit SetPool(_pid, _allocPoint, _depositFeeBP);
    }

    // View function to see pending USDCs on frontend.
    function pendingUSDC(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[myFriendsPID][_user];

        return ((user.amount * accDepositUSDCRewardPerShare) / (1e24)) - user.usdcRewardDebt;
    }

    // View function to see pending ARCADIUMs on frontend.
    function pendingArcadium(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accArcadiumPerShare = pool.accArcadiumPerShare;

        uint256 lpSupply = pool.totalLocked;
        if (block.number > pool.lastRewardBlock && lpSupply != 0 && totalAllocPoint != 0) {
            uint256 farmingLimitedBlock = block.number <= gradient3EndBlock ? block.number : gradient3EndBlock;
            uint256 release = arcadiumToolBox.getArcadiumRelease(isIncreasingGradient, arcadiumReleaseGradient, endArcadiumGradientBlock, endGoalArcadiumEmission, pool.lastRewardBlock, farmingLimitedBlock);
            uint256 arcadiumReward = (release * pool.allocPoint) / totalAllocPoint;
            accArcadiumPerShare = accArcadiumPerShare + ((arcadiumReward * 1e24) / lpSupply);
        }
        return ((user.amount * accArcadiumPerShare) / 1e24) - user.arcadiumRewardDebt;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMyFriendsMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        // As we set the multiplier to 0 here after myFriendsEmmissionEndBlock
        // deposits aren't blocked after farming ends.
        if (_from > myFriendsEmmissionEndBlock)
            return 0;
        if (_to > myFriendsEmmissionEndBlock)
            return myFriendsEmmissionEndBlock - _from;
        else
            return _to - _from;
    }

    // View function to see pending MyFriends on frontend.
    function pendingMyFriends(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accMyFriendsPerShare = pool.accMyFriendsPerShare;

        uint256 lpSupply = pool.totalLocked;
        if (block.number > pool.lastRewardBlock && lpSupply != 0 && totalAllocPoint > poolInfo[myFriendsPID].allocPoint) {
            uint256 release = getMyFriendsMultiplier(pool.lastRewardBlock, block.number);
            uint256 myFriendsReward = (release * myFriendsPerBlock * pool.allocPoint) / (totalAllocPoint - poolInfo[myFriendsPID].allocPoint);
            accMyFriendsPerShare = accMyFriendsPerShare + ((myFriendsReward * 1e24) / lpSupply);
        }

        return ((user.amount * accMyFriendsPerShare) / 1e24) - user.myFriendsRewardDebt;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        // we only allow maxPools number of pools to be updated
        for (uint256 pid = 0; pid < length && pid < maxPools; ++pid) {
            updatePool(pid);
        }
    }

    // Transfers any excess coins gained through reflection
    // to ARCADIUM and MYFRIENDS
    function skimPool(uint256 poolId) internal {
        PoolInfo storage pool = poolInfo[poolId];
        // cannot skim any tokens we use for staking rewards.
        if (isNativeToken(address(pool.lpToken)))
            return;

        uint256 skim = pool.lpToken.balanceOf(address(this)) > pool.totalLocked ?
            pool.lpToken.balanceOf(address(this)) - pool.totalLocked :
            0;

        if (skim > 1e4) {
            uint256 myFriendsShare = skim / 2;
            uint256 arcadiumShare = skim - myFriendsShare;
            pool.lpToken.safeTransfer(address(myFriends), myFriendsShare);
            pool.lpToken.safeTransfer(address(arcadium), arcadiumShare);
        }
    }

    // Updates arcadium release goal and phase change duration
    function updateArcadiumRelease(uint256 endBlock, uint256 endArcadiumEmission) internal returns (bool) {
        // give some buffer as to stop extrememly large gradients
        if (block.number + 4 >= endBlock)
            return false;

        // this will be called infrequently
        // and deployed on a cheap gas network POLYGON (MATIC)
        // Founders will also be attempting the gradient update
        // at the right time.
        massUpdatePools();

        uint256 currentArcadiumEmission = arcadiumToolBox.getArcadiumEmissionForBlock(block.number,
            isIncreasingGradient, arcadiumReleaseGradient, endArcadiumGradientBlock, endGoalArcadiumEmission);

        isIncreasingGradient = endArcadiumEmission > currentArcadiumEmission;
        arcadiumReleaseGradient = arcadiumToolBox.calcEmissionGradient(block.number,
            currentArcadiumEmission, endBlock, endArcadiumEmission);

        endArcadiumGradientBlock = endBlock;
        endGoalArcadiumEmission = endArcadiumEmission;

        emit GradientUpdated(endGoalArcadiumEmission, endArcadiumGradientBlock);

        return true;
    }

    function autoUpdateArcadiumGradient() internal returns (bool) {
        if (block.number < endArcadiumGradientBlock || gradientEra > 2)
            return false;

        // still need to check if we are too late even though we assert in updateArcadiumRelease
        // as we might need to skip this gradient era and not fail this assert
        if (gradientEra == 1) {
            if (block.number + 4 < gradient2EndBlock &&
                updateArcadiumRelease(gradient2EndBlock, gradient2EndEmmissions)) {
                gradientEra = gradientEra + 1;
                return true;
            }
            // if we missed it skip to the next era anyway
            gradientEra = gradientEra + 1;

        }

        if (gradientEra == 2) {
            if (block.number + 4 < gradient3EndBlock &&
                updateArcadiumRelease(gradient3EndBlock, gradient3EndEmmissions))
                gradientEra = gradientEra + 1;
                return true;
        }

        return false;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock)
            return;

        uint256 lpSupply = pool.totalLocked;
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 farmingLimitedBlock = block.number <= gradient3EndBlock ? block.number : gradient3EndBlock;
        uint256 arcadiumRelease = arcadiumToolBox.getArcadiumRelease(isIncreasingGradient, arcadiumReleaseGradient, endArcadiumGradientBlock, endGoalArcadiumEmission, pool.lastRewardBlock, farmingLimitedBlock);
        uint256 arcadiumReward = (arcadiumRelease * pool.allocPoint) / totalAllocPoint;

        // Arcadium Txn fees ONLY for myFriends stakers.
        if (address(pool.lpToken) == address(myFriends)) {
            uint256 burnBalance = arcadium.balanceOf(BURN_ADDRESS);
            arcadiumReward = arcadiumReward + (((burnBalance - lastArcadiumBurnBalance) * myFriendsShareOfBurn) / 10000);

            lastArcadiumBurnBalance = burnBalance;
        }

        // the end of gradient 3 is the end of arcadium release
        if (arcadiumReward > 0)
            arcadium.mint(address(this), arcadiumReward);

        if (myFriendsEmmissionEndBlock == type(uint256).max && address(pool.lpToken) != address(myFriends) &&
            totalAllocPoint > poolInfo[myFriendsPID].allocPoint) {

            uint256 myFriendsRelease = getMyFriendsMultiplier(pool.lastRewardBlock, block.number);

            if (myFriendsRelease > 0) {
                uint256 myFriendsReward = ((myFriendsRelease * myFriendsPerBlock * pool.allocPoint) / (totalAllocPoint - poolInfo[myFriendsPID].allocPoint));

                // Getting MyFriends allocated specificlly for initial distribution.
                myFriendsReward = myFriends.distribute(address(this), myFriendsReward);
                // once we run out end myfriends emmissions.
                if (myFriendsReward == 0 || myFriends.balanceOf(address(myFriends)) == 0)
                    myFriendsEmmissionEndBlock = block.number;

                pool.accMyFriendsPerShare = pool.accMyFriendsPerShare + ((myFriendsReward * 1e24) / lpSupply);
            }
        }

        pool.accArcadiumPerShare = pool.accArcadiumPerShare + ((arcadiumReward * 1e24) / lpSupply);
        pool.lastRewardBlock = block.number;
    }

    // Return if address is a founder address.
    function isFounder(address addr) public pure returns (bool) {
        return addr == FOUNDER1_ADDRESS || addr == FOUNDER2_ADDRESS;
    }

    // Return if address is a founder address.
    function isNativeToken(address addr) public view returns (bool) {
        return addr == address(myFriends) || addr == address(arcadium);
    }

    // Deposit LP tokens to MasterChef for ARCADIUM allocation.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        // check if we need to update the gradients
        // this will only do useful work a few times in masterChefs life
        // if autoUpdateArcadiumGradient is called we have already called massUpdatePools.
        if (!autoUpdateArcadiumGradient())
            updatePool(_pid);

        if (_amount > 0 && address(arcadiumReferral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            arcadiumReferral.recordReferral(msg.sender, _referrer);
        }

        payOrLockupPendingMyFriendsArcadium(_pid);
        if (address(pool.lpToken) == address(myFriends)) {
            payPendingUSDCReward();
        }
        if (_amount > 0) {
            // Accept the balance of coins we recieve (useful for coins which take fees).
            uint256 previousBalance = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)) - previousBalance;
            require(_amount > 0, "no funds were recieved");

            if (pool.depositFeeBP > 0 && !isNativeToken(address(pool.lpToken))) {
                uint256 depositFee = ((_amount * pool.depositFeeBP) / 10000);
                // For LPs arcadium handles it 100%, destroys and distributes
                uint256 arcadiumDepositFee = pool.tokenType == 1 ? depositFee : ((depositFee * 1e24) / 4) / 1e24;
                pool.lpToken.safeTransfer(address(arcadium), arcadiumDepositFee);
                // arcadium handles all LP type tokens
                arcadium.swapDepositFeeForETH(address(pool.lpToken), pool.tokenType);

                uint256 usdcRecieved = 0;
                if (pool.tokenType == 1) {
                    // make sure we pick up any tokens from destroyed LPs from Arcadium
                    // (not guaranteed to have single sided pools to trigger).
                   usdcRecieved  = myFriends.convertDepositFeesToUSDC(address(pool.lpToken), 1);
                }
                // Lp tokens get liquidated in Arcadium not MyFriends.
                else if (pool.tokenType == 0) {
                    pool.lpToken.safeTransfer(address(myFriends), depositFee - arcadiumDepositFee);
                    usdcRecieved = myFriends.convertDepositFeesToUSDC(address(pool.lpToken), 0);
                }

                // pickup up and usdc that hasn't been collected yet (OTC or from Arcadium).
                usdcRecieved = usdcRecieved + myFriends.convertDepositFeesToUSDC(address(usdcRewardCurrency), 0);

                // MyFriends pool is always pool 0.
                if (poolInfo[myFriendsPID].totalLocked > 0) {
                    accDepositUSDCRewardPerShare = accDepositUSDCRewardPerShare + ((usdcRecieved * 1e24) / poolInfo[myFriendsPID].totalLocked);
                    totalUSDCCollected = totalUSDCCollected + usdcRecieved;
                }

                user.amount = (user.amount + _amount) - depositFee;
                pool.totalLocked = (pool.totalLocked + _amount) - depositFee;
            } else {
                user.amount = user.amount + _amount;

                pool.totalLocked = pool.totalLocked + _amount;
            }
        }

        user.arcadiumRewardDebt = ((user.amount * pool.accArcadiumPerShare) / 1e24);
        user.myFriendsRewardDebt = ((user.amount * pool.accMyFriendsPerShare) / 1e24);

        if (address(pool.lpToken) == address(myFriends))
            user.usdcRewardDebt = ((user.amount * accDepositUSDCRewardPerShare) / 1e24);

        skimPool(_pid);

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Return how much MyFriends should be saked by the founders at any time.
    function getCurrentComplsoryFounderMyFriendsDeposit(uint256 blocknum) public view returns (uint256) {
        // No MyFriends withdrawals before farmining
        if (blocknum < startBlock)
            return type(uint256).max;
        if (blocknum > founderFinalLockupEndBlock)
            return 0;

        uint256 lockupDuration = founderFinalLockupEndBlock - startBlock;
        uint256 currentUpTime = blocknum - startBlock;
        return (((initialFounderMyFriendsStake * (lockupDuration - currentUpTime) * 1e6) / lockupDuration) / 1e6);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        if (address(pool.lpToken) == address(myFriends) && isFounder(msg.sender)) {
            require((user.amount - _amount) >= getCurrentComplsoryFounderMyFriendsDeposit(block.number),
                "founder wallets are locked up");
        }

        updatePool(_pid);
        payOrLockupPendingMyFriendsArcadium(_pid);
        if (address(pool.lpToken) == address(myFriends))
            payPendingUSDCReward();

        if (_amount > 0) {
            user.amount = user.amount - _amount;
            pool.totalLocked = pool.totalLocked - _amount;
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }

        user.arcadiumRewardDebt = ((user.amount * pool.accArcadiumPerShare) / 1e24);
        user.myFriendsRewardDebt = ((user.amount * pool.accMyFriendsPerShare) / 1e24);

        if (address(pool.lpToken) == address(myFriends))
            user.usdcRewardDebt = ((user.amount * accDepositUSDCRewardPerShare) / 1e24);

        skimPool(_pid);

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.arcadiumRewardDebt = 0;
        user.myFriendsRewardDebt = 0;
        user.usdcRewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        // In the case of an accounting error, we choose to let the user emergency withdraw anyway
        if (pool.totalLocked >=  amount)
            pool.totalLocked = pool.totalLocked - amount;
        else
            pool.totalLocked = 0;

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay pending ARCADIUMs & MYFRIENDSs.
    function payOrLockupPendingMyFriendsArcadium(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 arcadiumPending = ((user.amount * pool.accArcadiumPerShare) / 1e24) - user.arcadiumRewardDebt;
        uint256 myFriendsPending = ((user.amount * pool.accMyFriendsPerShare) / 1e24) - user.myFriendsRewardDebt;

        if (arcadiumPending > 0) {
            // send rewards
            if (isFounder(msg.sender)) {
                safeTokenTransfer(address(arcadium), BURN_ADDRESS, arcadiumPending/2);
                arcadiumPending = arcadiumPending - arcadiumPending/2;
            }
            // arcadiumPending can't be zero
            safeTokenTransfer(address(arcadium), msg.sender, arcadiumPending);
            payReferralCommission(msg.sender, arcadiumPending);
        }
        if (myFriendsPending > 0) {
            // send rewards
            if (isFounder(msg.sender))
                safeTokenTransfer(address(myFriends), BURN_ADDRESS, myFriendsPending);
            else
                safeTokenTransfer(address(myFriends), msg.sender, myFriendsPending);
        }
    }

    // Pay pending USDC from the MyFriends staking reward scheme.
    function payPendingUSDCReward() internal {
        UserInfo storage user = userInfo[myFriendsPID][msg.sender];

        uint256 usdcPending = ((user.amount * accDepositUSDCRewardPerShare) / 1e24) - user.usdcRewardDebt;

        if (usdcPending > 0) {
            // send rewards
            myFriends.transferUSDCToUser(msg.sender, usdcPending);
        }
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough ARCADIUMs.
    function safeTokenTransfer(address token, address _to, uint256 _amount) internal {
        uint256 tokenBal = IERC20(token).balanceOf(address(this));
        if (_amount > tokenBal) {
            IERC20(token).safeTransfer(_to, tokenBal);
        } else {
            IERC20(token).safeTransfer(_to, _amount);
        }
    }

    // Update the arcadium referral contract address by the owner
    function setArcadiumReferral(IArcadiumReferral _arcadiumReferral) external onlyOwner {
        require(address(_arcadiumReferral) != address(0), "arcadiumReferral cannot be the 0 address");
        require(address(arcadiumReferral) == address(0), "arcadium referral address already set");
        arcadiumReferral = _arcadiumReferral;

        emit SetArcadiumReferral(address(arcadiumReferral));
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(arcadiumReferral) != address(0) && referralCommissionRate > 0) {
            address referrer = arcadiumReferral.getReferrer(_user);
            uint256 commissionAmount = ((_pending * referralCommissionRate) / 10000);

            if (referrer != address(0) && commissionAmount > 0) {
                arcadium.mint(referrer, commissionAmount / 2);
                arcadium.mint(_user, commissionAmount - (commissionAmount / 2));
                arcadiumReferral.recordReferralCommission(referrer, commissionAmount);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArcadiumReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(address referrer, uint256 commission) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libs/ERC20.sol";
import "./libs/IERC20.sol";

import "./libs/RHCPToolBox.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";


// MyFriendsToken
contract MyFriendsToken is ERC20("MYFRIENDS", "MYFRIENDS") {

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 public constant usdcSwapThreshold = 20 * (10 ** 6);

    // The operator can only update the transfer tax rate
    address private _operator;

    IERC20 public immutable usdcRewardCurrency;

    uint256 usdcRewardBalance = 0;

    RHCPToolBox arcadiumToolBox;

    IUniswapV2Router02 public arcadiumSwapRouter;

    // Events
    event DistributeMyFriends(address recipient, uint256 myFriendsAmount);
    event DepositFeeConvertedToUSDC(address indexed inputToken, uint256 inputAmount, uint256 usdcOutput);
    event USDCTransferredToUser(address recipient, uint256 usdcAmount);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event ArcadiumSwapRouterUpdated(address indexed operator, address indexed router);

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    /**
     * @notice Constructs the ArcadiumToken contract.
     */
    constructor(address _usdcCurrency, RHCPToolBox _arcadiumToolBox) public {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);

        arcadiumToolBox = _arcadiumToolBox;
        usdcRewardCurrency = IERC20(_usdcCurrency);

        // Divvy up myFriends supply.
        _mint(0x3a1D1114269d7a786C154FE5278bF5b1e3e20d31, 80 * (10 ** 3) * (10 ** 18));
        _mint(address(this), 20 * (10 ** 3) * (10 ** 18));
    }

    /// @notice Sends `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function distribute(address _to, uint256 _amount) external onlyOwner returns (uint256){
        uint256 sendAmount = _amount;
        if (balanceOf(address(this)) < _amount)
            sendAmount = balanceOf(address(this));

        if (sendAmount > 0) {
            IERC20(address(this)).transfer(_to, sendAmount);
            emit DistributeMyFriends(_to, sendAmount);
        }

        return sendAmount;
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view returns (address) {
        return _operator;
    }

    // To receive MATIC from arcadiumSwapRouter when swapping
    receive() external payable {}

    /**
     * @dev sell all of a current type of token for usdc.
     * Can only be called by the current operator.
     */
    function convertDepositFeesToUSDC(address token, uint8 tokenType) public onlyOwner returns (uint256) {
        // shouldn't be trying to sell MyFriends
        if (token == address(this))
            return 0;

        // LP tokens aren't destroyed in MyFriends, but this is so MyFriends can process
        // already destroyed LP fees sent to it by the ArcadiumToken contract.
        if (tokenType == 1) {
            return convertDepositFeesToUSDC(IUniswapV2Pair(token).token0(), 0) +
                convertDepositFeesToUSDC(IUniswapV2Pair(token).token1(), 0);
        }

        uint256 totalTokenBalance = IERC20(token).balanceOf(address(this));

        if (token == address(usdcRewardCurrency)) {
            // Incase any usdc has been sent from OTC or otherwise, report that as
            // gained this amount.
            uint256 amountLiquified = totalTokenBalance - usdcRewardBalance;

            usdcRewardBalance = totalTokenBalance;

            return amountLiquified;
        }

        uint256 usdcValue = arcadiumToolBox.getTokenUSDCValue(totalTokenBalance, token, tokenType, false, address(usdcRewardCurrency));

        if (totalTokenBalance == 0)
            return 0;
        if (usdcValue < usdcSwapThreshold)
            return 0;

        // generate the arcadiumSwap pair path of token -> usdc.
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = address(usdcRewardCurrency);

        uint256 usdcPriorBalance = usdcRewardCurrency.balanceOf(address(this));

        require(IERC20(token).approve(address(arcadiumSwapRouter), totalTokenBalance), 'approval failed');

        // make the swap
        arcadiumSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            totalTokenBalance,
            0, // accept any amount of USDC
            path,
            address(this),
            block.timestamp
        );

        uint256 usdcProfit =  usdcRewardCurrency.balanceOf(address(this)) - usdcPriorBalance;

        usdcRewardBalance = usdcRewardBalance + usdcProfit;

        emit DepositFeeConvertedToUSDC(token, totalTokenBalance, usdcProfit);

        return usdcProfit;
    }

    /**
     * @dev send usdc to a user
     * Can only be called by the current operator.
     */
    function transferUSDCToUser(address recipient, uint256 amount) external onlyOwner {
        require(usdcRewardCurrency.balanceOf(address(this)) >= amount, "accounting error, transfering more usdc out than available");
        require(usdcRewardCurrency.transfer(recipient, amount), "transfer failed!");

        usdcRewardBalance = usdcRewardBalance - amount;

        emit USDCTransferredToUser(recipient, amount);
    }

    /**
     * @dev Update the swap router.
     * Can only be called by the current operator.
     */
    function updateArcadiumSwapRouter(address _router) external onlyOperator {
        require(_router != address(0), "updateArcadiumSwapRouter: new _router is the zero address");
        require(address(arcadiumSwapRouter) == address(0), "router already set!");

        arcadiumSwapRouter = IUniswapV2Router02(_router);
        emit ArcadiumSwapRouterUpdated(msg.sender, address(arcadiumSwapRouter));
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) external onlyOperator {
        require(newOperator != address(0), "transferOperator: new operator is the zero address");
        _operator = newOperator;

        emit OperatorTransferred(_operator, newOperator);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libs/ERC20.sol";
import "./libs/IERC20.sol";
import "./libs/SafeERC20.sol";
import "./libs/IWETH.sol";

import "./libs/AddLiquidityHelper.sol";
import "./libs/RHCPToolBox.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

// ArcadiumToken.
contract ArcadiumToken is ERC20("ARCADIUM", "ARCADIUM")  {
    using SafeERC20 for IERC20;

    // Transfer tax rate in basis points. (default 6.66%)
    uint16 public transferTaxRate = 666;
    // Extra transfer tax rate in basis points. (default 2.00%)
    uint16 public extraTransferTaxRate = 200;
    // Burn rate % of transfer tax. (default 54.95% x 6.66% = 3.660336% of total amount).
    uint32 public constant burnRate = 549549549;
    // Max transfer tax rate: 10.01%.
    uint16 public constant MAXIMUM_TRANSFER_TAX_RATE = 1001;
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    address public constant usdcCurrencyAddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    uint256 public constant usdcSwapThreshold = 20 * (10 ** 6);

    // Automatic swap and liquify enabled
    bool public swapAndLiquifyEnabled = true;
    // Min amount to liquify. (default 40 ARCADIUMs)
    uint256 public constant minArcadiumAmountToLiquify = 40 * (10 ** 18);
    // Min amount to liquify. (default 100 MATIC)
    uint256 public constant minMaticAmountToLiquify = 100 *  (10 ** 18);

    IUniswapV2Router02 public arcadiumSwapRouter;
    // The trading pair
    address public arcadiumSwapPair;
    // In swap and liquify
    bool private _inSwapAndLiquify;

    AddLiquidityHelper public immutable addLiquidityHelper;
    RHCPToolBox public immutable arcadiumToolBox;
    IERC20 public immutable usdcRewardCurrency;
    address public immutable myFriends;

    bool public ownershipIsTransferred = false;

    mapping(address => bool) public excludeFromMap;
    mapping(address => bool) public excludeToMap;

    mapping(address => bool) public extraFromMap;
    mapping(address => bool) public extraToMap;

    event SetSwapAndLiquifyEnabled(bool swapAndLiquifyEnabled);
    event TransferFeeChanged(uint256 txnFee, uint256 extraTxnFee);
    event UpdateFeeMaps(address _contract, bool fromExcluded, bool toExcluded, bool fromHasExtra, bool toHasExtra);
    event SetArcadiumRouter(address arcadiumSwapRouter, address arcadiumSwapPair);
    event SetOperator(address operator);

    // The operator can only update the transfer tax rate
    address private _operator;

    modifier onlyOperator() {
        require(_operator == msg.sender, "!operator");
        _;
    }

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    modifier transferTaxFree {
        uint16 _transferTaxRate = transferTaxRate;
        uint16 _extraTransferTaxRate = extraTransferTaxRate;
        transferTaxRate = 0;
        extraTransferTaxRate = 0;
        _;
        transferTaxRate = _transferTaxRate;
        extraTransferTaxRate = _extraTransferTaxRate;
    }

    /**
     * @notice Constructs the ArcadiumToken contract.
     */
    constructor(address _myFriends, AddLiquidityHelper _addLiquidityHelper, RHCPToolBox _arcadiumToolBox) public {
        addLiquidityHelper = _addLiquidityHelper;
        arcadiumToolBox = _arcadiumToolBox;
        myFriends = _myFriends;
        usdcRewardCurrency = IERC20(usdcCurrencyAddress);
        _operator = _msgSender();

        // pre-mint
        _mint(address(0x3a1D1114269d7a786C154FE5278bF5b1e3e20d31), uint256(250000 * (10 ** 18)));
    }

    function transferOwnership(address newOwner) public override onlyOwner  {
        require(!ownershipIsTransferred, "!unset");
        super.transferOwnership(newOwner);
        ownershipIsTransferred = true;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        require(ownershipIsTransferred, "too early!");
        _mint(_to, _amount);
    }

    /// @dev overrides transfer function to meet tokenomics of ARCADIUM
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        bool toFromAddLiquidityHelper = (sender == address(addLiquidityHelper) || recipient == address(addLiquidityHelper));
        // swap and liquify
        if (
            swapAndLiquifyEnabled == true
            && _inSwapAndLiquify == false
            && address(arcadiumSwapRouter) != address(0)
            && !toFromAddLiquidityHelper
            && sender != arcadiumSwapPair
            && sender != owner()
        ) {
            swapAndLiquify();
        }

        if (toFromAddLiquidityHelper ||
            recipient == BURN_ADDRESS || (transferTaxRate == 0 && extraTransferTaxRate == 0) ||
            excludeFromMap[sender] || excludeToMap[recipient]) {
            super._transfer(sender, recipient, amount);
        } else {
            // default tax is 6.66% of every transfer, but extra 2% for dumping tax
            uint256 taxAmount = (amount * (transferTaxRate +
                ((extraFromMap[sender] || extraToMap[recipient]) ? extraTransferTaxRate : 0))) / 10000;

            uint256 burnAmount = (taxAmount * burnRate) / 1000000000;
            uint256 liquidityAmount = taxAmount - burnAmount;

            // default 93.34% of transfer sent to recipient
            uint256 sendAmount = amount - taxAmount;

            require(amount == sendAmount + taxAmount &&
                        taxAmount == burnAmount + liquidityAmount, "sum error");

            super._transfer(sender, BURN_ADDRESS, burnAmount);
            super._transfer(sender, address(this), liquidityAmount);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;
        }
    }

    /// @dev Swap and liquify
    function swapAndLiquify() private lockTheSwap transferTaxFree {
        uint256 contractTokenBalance = ERC20(address(this)).balanceOf(address(this));

        uint256 WETHbalance = IERC20(arcadiumSwapRouter.WETH()).balanceOf(address(this));

        IWETH(arcadiumSwapRouter.WETH()).withdraw(WETHbalance);

        if (address(this).balance >= minMaticAmountToLiquify || contractTokenBalance >= minArcadiumAmountToLiquify) {

            ERC20(address(this)).transfer(address(addLiquidityHelper), ERC20(address(this)).balanceOf(address(this)));
            // send all tokens to add liquidity with, we are refunded any that aren't used.
            addLiquidityHelper.arcadiumETHLiquidityWithBuyBack{value: address(this).balance}(BURN_ADDRESS);
        }
    }

    /**
     * @dev unenchant the lp token into its original components.
     * Can only be called by the current operator.
     */
    function swapLpTokensForFee(address token, uint256 amount) internal {
        require(IERC20(token).approve(address(arcadiumSwapRouter), amount), '!approved');

        IUniswapV2Pair lpToken = IUniswapV2Pair(token);

        uint256 token0BeforeLiquidation = IERC20(lpToken.token0()).balanceOf(address(this));
        uint256 token1BeforeLiquidation = IERC20(lpToken.token1()).balanceOf(address(this));

        // make the swap
        arcadiumSwapRouter.removeLiquidity(
            lpToken.token0(),
            lpToken.token1(),
            amount,
            0,
            0,
            address(this),
            block.timestamp
        );

        uint256 token0FromLiquidation = IERC20(lpToken.token0()).balanceOf(address(this)) - token0BeforeLiquidation;
        uint256 token1FromLiquidation = IERC20(lpToken.token1()).balanceOf(address(this)) - token1BeforeLiquidation;

        address tokenForMyFriendsUSDCReward = lpToken.token0();
        address tokenForArcadiumAMMReward = lpToken.token1();

        // If we already have, usdc, save a swap.
       if (lpToken.token1() == address(usdcRewardCurrency)){

            (tokenForArcadiumAMMReward, tokenForMyFriendsUSDCReward) = (tokenForMyFriendsUSDCReward, tokenForArcadiumAMMReward);
        } else if (lpToken.token0() == arcadiumSwapRouter.WETH()){
            // if one is weth already use the other one for myfriends and
            // the weth for arcadium AMM to save a swap.

            (tokenForArcadiumAMMReward, tokenForMyFriendsUSDCReward) = (tokenForMyFriendsUSDCReward, tokenForArcadiumAMMReward);
        }

        // send myfriends all of 1 half of the LP to be convereted to USDC later.
        IERC20(tokenForMyFriendsUSDCReward).safeTransfer(address(myFriends),
            tokenForMyFriendsUSDCReward == lpToken.token0() ? token0FromLiquidation : token1FromLiquidation);

        // send myfriends 50% share of the other 50% to give myfriends 75% in total.
        IERC20(tokenForArcadiumAMMReward).safeTransfer(address(myFriends),
            (tokenForArcadiumAMMReward == lpToken.token0() ? token0FromLiquidation : token1FromLiquidation)/2);

        swapDepositFeeForTokensInternal(tokenForArcadiumAMMReward, 0, arcadiumSwapRouter.WETH());
    }

    /**
     * @dev sell all of a current type of token for weth, to be used in arcadium liquidity later.
     * Can only be called by the current operator.
     */
    function swapDepositFeeForETH(address token, uint8 tokenType) external onlyOwner {
        uint256 usdcValue = arcadiumToolBox.getTokenUSDCValue(IERC20(token).balanceOf(address(this)), token, tokenType, false, address(usdcRewardCurrency));

        // If arcadium or weth already no need to do anything.
        if (token == address(this) || token == arcadiumSwapRouter.WETH())
            return;

        // only swap if a certain usdc value
        if (usdcValue < usdcSwapThreshold)
            return;

        swapDepositFeeForTokensInternal(token, tokenType, arcadiumSwapRouter.WETH());
    }

    function swapDepositFeeForTokensInternal(address token, uint8 tokenType, address toToken) internal {
        uint256 totalTokenBalance = IERC20(token).balanceOf(address(this));

        // can't trade to arcadium inside of arcadium anyway
        if (token == toToken || totalTokenBalance == 0 || toToken == address(this))
            return;

        if (tokenType == 1) {
            swapLpTokensForFee(token, totalTokenBalance);
            return;
        }

        require(IERC20(token).approve(address(arcadiumSwapRouter), totalTokenBalance), "!approved");

        // generate the arcadiumSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = toToken;

        try
            // make the swap
            arcadiumSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                totalTokenBalance,
                0, // accept any amount of tokens
                path,
                address(this),
                block.timestamp
            )
        { /* suceeded */ } catch { /* failed, but we avoided reverting */ }

        // Unfortunately can't swap directly to arcadium inside of arcadium (Uniswap INVALID_TO Assert, boo).
        // Also dont want to add an extra swap here.
        // Will leave as WETH and make the arcadium Txn AMM utilise available WETH first.
    }

    // To receive ETH from arcadiumSwapRouter when swapping
    receive() external payable {}

    /**
     * @dev Update the swapAndLiquifyEnabled.
     * Can only be called by the current operator.
     */
    function updateSwapAndLiquifyEnabled(bool _enabled) external onlyOperator {
        swapAndLiquifyEnabled = _enabled;

        emit SetSwapAndLiquifyEnabled(swapAndLiquifyEnabled);
    }

    /**
     * @dev Update the transfer tax rate.
     * Can only be called by the current operator.
     */
    function updateTransferTaxRate(uint16 _transferTaxRate, uint16 _extraTransferTaxRate) external onlyOperator {
        require(_transferTaxRate + _extraTransferTaxRate  <= MAXIMUM_TRANSFER_TAX_RATE,
            "!valid");
        transferTaxRate = _transferTaxRate;
        extraTransferTaxRate = _extraTransferTaxRate;

        emit TransferFeeChanged(transferTaxRate, extraTransferTaxRate);
    }

    /**
     * @dev Update the excludeFromMap
     * Can only be called by the current operator.
     */
    function updateFeeMaps(address _contract, bool fromExcluded, bool toExcluded, bool fromHasExtra, bool toHasExtra) external onlyOperator {
        excludeFromMap[_contract] = fromExcluded;
        excludeToMap[_contract] = toExcluded;
        extraFromMap[_contract] = fromHasExtra;
        extraToMap[_contract] = toHasExtra;

        emit UpdateFeeMaps(_contract, fromExcluded, toExcluded, fromHasExtra, toHasExtra);
    }

    /**
     * @dev Update the swap router.
     * Can only be called by the current operator.
     */
    function updateArcadiumSwapRouter(address _router) external onlyOperator {
        require(_router != address(0), "!!0");
        require(address(arcadiumSwapRouter) == address(0), "!unset");

        arcadiumSwapRouter = IUniswapV2Router02(_router);
        arcadiumSwapPair = IUniswapV2Factory(arcadiumSwapRouter.factory()).getPair(address(this), arcadiumSwapRouter.WETH());

        require(address(arcadiumSwapPair) != address(0), "matic pair !exist");

        emit SetArcadiumRouter(address(arcadiumSwapRouter), arcadiumSwapPair);
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view returns (address) {
        return _operator;
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) external onlyOperator {
        require(newOperator != address(0), "!!0");
        _operator = newOperator;

        emit SetOperator(_operator);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

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

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract RHCPToolBox {

    IUniswapV2Router02 public immutable arcadiumSwapRouter;

    uint256 public immutable startBlock;

    /**
     * @notice Constructs the ArcadiumToken contract.
     */
    constructor(uint256 _startBlock, IUniswapV2Router02 _arcadiumSwapRouter) public {
        startBlock = _startBlock;
        arcadiumSwapRouter = _arcadiumSwapRouter;
    }

    function convertToTargetValueFromPair(IUniswapV2Pair pair, uint256 sourceTokenAmount, address targetAddress) public view returns (uint256) {
        require(pair.token0() == targetAddress || pair.token1() == targetAddress, "one of the pairs must be the targetAddress");
        if (sourceTokenAmount == 0)
            return 0;

        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (res0 == 0 || res1 == 0)
            return 0;

        if (pair.token0() == targetAddress)
            return (res0 * sourceTokenAmount) / res1;
        else
            return (res1 * sourceTokenAmount) / res0;
    }

    function getTokenUSDCValue(uint256 tokenBalance, address token, uint8 tokenType, bool viaMaticUSDC, address usdcAddress) external view returns (uint256) {
        require(tokenType == 0 || tokenType == 1, "invalid token type provided");
        if (token == address(usdcAddress))
            return tokenBalance;

        // lp type
        if (tokenType == 1) {
            IUniswapV2Pair lpToken = IUniswapV2Pair(token);
            if (lpToken.totalSupply() == 0)
                return 0;
            // If lp contains usdc, we can take a short-cut
            if (lpToken.token0() == address(usdcAddress)) {
                return (IERC20(lpToken.token0()).balanceOf(address(lpToken)) * tokenBalance * 2) / lpToken.totalSupply();
            } else if (lpToken.token1() == address(usdcAddress)){
                return (IERC20(lpToken.token1()).balanceOf(address(lpToken)) * tokenBalance * 2) / lpToken.totalSupply();
            }
        }

        // Only used for lp type tokens.
        address lpTokenAddress = token;
        // If token0 or token1 is bnb, use that, else use token0.
        if (tokenType == 1) {
            token = IUniswapV2Pair(token).token0() == arcadiumSwapRouter.WETH() ? arcadiumSwapRouter.WETH() :
                        (IUniswapV2Pair(token).token1() == arcadiumSwapRouter.WETH() ? arcadiumSwapRouter.WETH() : IUniswapV2Pair(token).token0());
        }

        // if it is an LP token we work with all of the reserve in the LP address to scale down later.
        uint256 tokenAmount = (tokenType == 1) ? IERC20(token).balanceOf(lpTokenAddress) : tokenBalance;

        uint256 usdcEquivalentAmount = 0;

        if (viaMaticUSDC) {
            uint256 maticAmount = 0;

            if (token == arcadiumSwapRouter.WETH()) {
                maticAmount = tokenAmount;
            } else {

                // As we arent working with usdc at this point (early return), this is okay.
                IUniswapV2Pair maticPair = IUniswapV2Pair(IUniswapV2Factory(arcadiumSwapRouter.factory()).getPair(arcadiumSwapRouter.WETH(), token));

                if (address(maticPair) == address(0))
                    return 0;

                maticAmount = convertToTargetValueFromPair(maticPair, tokenAmount, arcadiumSwapRouter.WETH());
            }

            // As we arent working with usdc at this point (early return), this is okay.
            IUniswapV2Pair usdcmaticPair = IUniswapV2Pair(IUniswapV2Factory(arcadiumSwapRouter.factory()).getPair(arcadiumSwapRouter.WETH(), address(usdcAddress)));

            if (address(usdcmaticPair) == address(0))
                return 0;

            usdcEquivalentAmount = convertToTargetValueFromPair(usdcmaticPair, maticAmount, usdcAddress);
        } else {
            // As we arent working with usdc at this point (early return), this is okay.
            IUniswapV2Pair usdcPair = IUniswapV2Pair(IUniswapV2Factory(arcadiumSwapRouter.factory()).getPair(address(usdcAddress), token));

            if (address(usdcPair) == address(0))
                return 0;

            usdcEquivalentAmount = convertToTargetValueFromPair(usdcPair, tokenAmount, usdcAddress);
        }

        // for the tokenType == 1 path usdcEquivalentAmount is the USDC value of all the tokens in the parent LP contract.

        if (tokenType == 1)
            return (usdcEquivalentAmount * tokenBalance * 2) / IUniswapV2Pair(lpTokenAddress).totalSupply();
        else
            return usdcEquivalentAmount;
    }

    function getArcadiumEmissionForBlock(uint256 _block, bool isIncreasingGradient, uint256 releaseGradient, uint256 gradientEndBlock, uint256 endEmission) public pure returns (uint256) {
        if (_block >= gradientEndBlock)
            return endEmission;

        if (releaseGradient == 0)
            return endEmission;
        uint256 currentArcadiumEmission = endEmission;
        uint256 deltaHeight = (releaseGradient * (gradientEndBlock - _block)) / 1e24;

        if (isIncreasingGradient) {
            // if there is a logical error, we return 0
            if (endEmission >= deltaHeight)
                currentArcadiumEmission = endEmission - deltaHeight;
            else
                currentArcadiumEmission = 0;
        } else
            currentArcadiumEmission = endEmission + deltaHeight;

        return currentArcadiumEmission;
    }

    function calcEmissionGradient(uint256 _block, uint256 currentEmission, uint256 gradientEndBlock, uint256 endEmission) external pure returns (uint256) {
        uint256 arcadiumReleaseGradient;

        // if the gradient is 0 we interpret that as an unchanging 0 gradient.
        if (currentEmission != endEmission && _block < gradientEndBlock) {
            bool isIncreasingGradient = endEmission > currentEmission;
            if (isIncreasingGradient)
                arcadiumReleaseGradient = ((endEmission - currentEmission) * 1e24) / (gradientEndBlock - _block);
            else
                arcadiumReleaseGradient = ((currentEmission - endEmission) * 1e24) / (gradientEndBlock - _block);
        } else
            arcadiumReleaseGradient = 0;

        return arcadiumReleaseGradient;
    }

    // Return if we are in the normal operation era, no promo
    function isFlatEmission(uint256 _gradientEndBlock, uint256 _blocknum) internal pure returns (bool) {
        return _blocknum >= _gradientEndBlock;
    }

    // Return ARCADIUM reward release over the given _from to _to block.
    function getArcadiumRelease(bool isIncreasingGradient, uint256 releaseGradient, uint256 gradientEndBlock, uint256 endEmission, uint256 _from, uint256 _to) external view returns (uint256) {
        if (_to <= _from || _to <= startBlock)
            return 0;
        uint256 clippedFrom = _from < startBlock ? startBlock : _from;
        uint256 totalWidth = _to - clippedFrom;

        if (releaseGradient == 0 || isFlatEmission(gradientEndBlock, clippedFrom))
            return totalWidth * endEmission;

        if (!isFlatEmission(gradientEndBlock, _to)) {
            uint256 heightDelta = releaseGradient * totalWidth;

            uint256 baseEmission;
            if (isIncreasingGradient)
                baseEmission = getArcadiumEmissionForBlock(_from, isIncreasingGradient, releaseGradient, gradientEndBlock, endEmission);
            else
                baseEmission = getArcadiumEmissionForBlock(_to, isIncreasingGradient, releaseGradient, gradientEndBlock, endEmission);
            return totalWidth * baseEmission + (((totalWidth * heightDelta) / 2) / 1e24);
        }

        // Special case when we are transitioning between promo and normal era.
        if (!isFlatEmission(gradientEndBlock, clippedFrom) && isFlatEmission(gradientEndBlock, _to)) {
            uint256 blocksUntilGradientEnd = gradientEndBlock - clippedFrom;
            uint256 heightDelta = releaseGradient * blocksUntilGradientEnd;

            uint256 baseEmission;
            if (isIncreasingGradient)
                baseEmission = getArcadiumEmissionForBlock(_to, isIncreasingGradient, releaseGradient, gradientEndBlock, endEmission);
            else
                baseEmission = getArcadiumEmissionForBlock(_from, isIncreasingGradient, releaseGradient, gradientEndBlock, endEmission);

            return totalWidth * baseEmission - (((blocksUntilGradientEnd * heightDelta) / 2) / 1e24);
        }

        // huh?
        // shouldnt happen, but also don't want to assert false here either.
        return 0;
    }
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeERC20.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


// AddLiquidityHelper, allows anyone to add or remove Arcadium liquidity tax free
// Also allows the Arcadium Token to do buy backs tax free via an external contract.
contract AddLiquidityHelper is ReentrancyGuard, Ownable {
    using SafeERC20 for ERC20;

    address public arcadiumAddress;

    IUniswapV2Router02 public immutable arcadiumSwapRouter;
    // The trading pair
    address public arcadiumSwapPair;

    // To receive ETH when swapping
    receive() external payable {}

    event SetArcadiumAddresses(address arcadiumAddress, address arcadiumSwapPair);

    /**
     * @notice Constructs the AddLiquidityHelper contract.
     */
    constructor(address _router) public  {
        require(_router != address(0), "_router is the zero address");
        arcadiumSwapRouter = IUniswapV2Router02(_router);
    }

    function arcadiumETHLiquidityWithBuyBack(address lpHolder) external payable nonReentrant {
        require(msg.sender == arcadiumAddress, "can only be used by the arcadium token!");

        (uint256 res0, uint256 res1, ) = IUniswapV2Pair(arcadiumSwapPair).getReserves();

        if (res0 != 0 && res1 != 0) {
            // making weth res0
            if (IUniswapV2Pair(arcadiumSwapPair).token0() == arcadiumAddress)
                (res1, res0) = (res0, res1);

            uint256 contractTokenBalance = ERC20(arcadiumAddress).balanceOf(address(this));

            // calculate how much eth is needed to use all of contractTokenBalance
            // also boost precision a tad.
            uint256 totalETHNeeded = (res0 * contractTokenBalance) / res1;

            uint256 existingETH = address(this).balance;

            uint256 unmatchedArcadium = 0;

            if (existingETH < totalETHNeeded) {
                // calculate how much arcadium will match up with our existing eth.
                uint256 matchedArcadium = (res1 * existingETH) / res0;
                if (contractTokenBalance >= matchedArcadium)
                    unmatchedArcadium = contractTokenBalance - matchedArcadium;
            } else if (existingETH > totalETHNeeded) {
                // use excess eth for arcadium buy back
                uint256 excessETH = existingETH - totalETHNeeded;

                if (excessETH / 2 > 0) {
                    // swap half of the excess eth for lp to be balanced
                    swapETHForTokens(excessETH / 2, arcadiumAddress);
                }
            }

            uint256 unmatchedArcadiumToSwap = unmatchedArcadium / 2;

            // swap tokens for ETH
            if (unmatchedArcadiumToSwap > 0)
                swapTokensForEth(arcadiumAddress, unmatchedArcadiumToSwap);

            uint256 arcadiumBalance = ERC20(arcadiumAddress).balanceOf(address(this));

            // approve token transfer to cover all possible scenarios
            ERC20(arcadiumAddress).approve(address(arcadiumSwapRouter), arcadiumBalance);

            // add the liquidity
            arcadiumSwapRouter.addLiquidityETH{value: address(this).balance}(
                arcadiumAddress,
                arcadiumBalance,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                lpHolder,
                block.timestamp
            );

        }

        if (address(this).balance > 0) {
            // not going to require/check return value of this transfer as reverting behaviour is undesirable.
            payable(address(msg.sender)).call{value: address(this).balance}("");
        }

        if (ERC20(arcadiumAddress).balanceOf(address(this)) > 0)
            ERC20(arcadiumAddress).transfer(msg.sender, ERC20(arcadiumAddress).balanceOf(address(this)));
    }

    function addArcadiumETHLiquidity(uint256 nativeAmount) external payable nonReentrant {
        require(msg.value > 0, "!sufficient funds");

        ERC20(arcadiumAddress).safeTransferFrom(msg.sender, address(this), nativeAmount);

        // approve token transfer to cover all possible scenarios
        ERC20(arcadiumAddress).approve(address(arcadiumSwapRouter), nativeAmount);

        // add the liquidity
        arcadiumSwapRouter.addLiquidityETH{value: msg.value}(
            arcadiumAddress,
            nativeAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );

        if (address(this).balance > 0) {
            // not going to require/check return value of this transfer as reverting behaviour is undesirable.
            payable(address(msg.sender)).call{value: address(this).balance}("");
        }

        if (ERC20(arcadiumAddress).balanceOf(address(this)) > 0)
            ERC20(arcadiumAddress).transfer(msg.sender, ERC20(arcadiumAddress).balanceOf(address(this)));
    }

    function addArcadiumLiquidity(address baseTokenAddress, uint256 baseAmount, uint256 nativeAmount) external nonReentrant {
        ERC20(baseTokenAddress).safeTransferFrom(msg.sender, address(this), baseAmount);
        ERC20(arcadiumAddress).safeTransferFrom(msg.sender, address(this), nativeAmount);

        // approve token transfer to cover all possible scenarios
        ERC20(baseTokenAddress).approve(address(arcadiumSwapRouter), baseAmount);
        ERC20(arcadiumAddress).approve(address(arcadiumSwapRouter), nativeAmount);

        // add the liquidity
        arcadiumSwapRouter.addLiquidity(
            baseTokenAddress,
            arcadiumAddress,
            baseAmount,
            nativeAmount ,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );

        if (ERC20(baseTokenAddress).balanceOf(address(this)) > 0)
            ERC20(baseTokenAddress).safeTransfer(msg.sender, ERC20(baseTokenAddress).balanceOf(address(this)));

        if (ERC20(arcadiumAddress).balanceOf(address(this)) > 0)
            ERC20(arcadiumAddress).transfer(msg.sender, ERC20(arcadiumAddress).balanceOf(address(this)));
    }

    function removeArcadiumLiquidity(address baseTokenAddress, uint256 liquidity) external nonReentrant {
        address lpTokenAddress = IUniswapV2Factory(arcadiumSwapRouter.factory()).getPair(baseTokenAddress, arcadiumAddress);
        require(lpTokenAddress != address(0), "pair hasn't been created yet, so can't remove liquidity!");

        ERC20(lpTokenAddress).safeTransferFrom(msg.sender, address(this), liquidity);
        // approve token transfer to cover all possible scenarios
        ERC20(lpTokenAddress).approve(address(arcadiumSwapRouter), liquidity);

        // add the liquidity
        arcadiumSwapRouter.removeLiquidity(
            baseTokenAddress,
            arcadiumAddress,
            liquidity,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );
    }

    /// @dev Swap tokens for eth
    function swapTokensForEth(address saleTokenAddress, uint256 tokenAmount) internal {
        // generate the arcadiumSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = saleTokenAddress;
        path[1] = arcadiumSwapRouter.WETH();

        ERC20(saleTokenAddress).approve(address(arcadiumSwapRouter), tokenAmount);

        // make the swap
        arcadiumSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    function swapETHForTokens(uint256 ethAmount, address wantedTokenAddress) internal {
        require(address(this).balance >= ethAmount, "insufficient matic provided!");
        require(wantedTokenAddress != address(0), "wanted token address can't be the zero address!");

        // generate the arcadiumSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = arcadiumSwapRouter.WETH();
        path[1] = wantedTokenAddress;

        // make the swap
        arcadiumSwapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0,
            path,
            // cannot send tokens to the token contract of the same type as the output token
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev set the arcadium address.
     * Can only be called by the current owner.
     */
    function setArcadiumAddress(address _arcadiumAddress) external onlyOwner {
        require(_arcadiumAddress != address(0), "_arcadiumAddress is the zero address");
        require(arcadiumAddress == address(0), "arcadiumAddress already set!");

        arcadiumAddress = _arcadiumAddress;

        arcadiumSwapPair = IUniswapV2Factory(arcadiumSwapRouter.factory()).getPair(arcadiumAddress, arcadiumSwapRouter.WETH());

        require(address(arcadiumSwapPair) != address(0), "matic pair !exist");

        emit SetArcadiumAddresses(arcadiumAddress, arcadiumSwapPair);
    }
}