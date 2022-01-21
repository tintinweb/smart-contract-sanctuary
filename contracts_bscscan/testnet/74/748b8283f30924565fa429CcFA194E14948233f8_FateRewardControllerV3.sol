// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../uniswap-v2/interfaces/IUniswapV2Router01.sol";
import "../MockLpToken.sol";
import "../IMockLpTokenFactory.sol";
import "../IFateRewardController.sol";

import "./MembershipWithReward.sol";
import "./IFateRewardControllerV3.sol";

// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once FATE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract FateRewardControllerV3 is IFateRewardControllerV3, MembershipWithReward {
    using SafeERC20 for IERC20;
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 private constant BASIS_POINTS_DIVISOR = 10000;
    uint256 private constant MAX_FEE_BASIS_POINTS = 500; // 5%
    address public fateFeeTo;

    // feeReserves tracks the amount of fees per token
    mapping (address => uint256) public feeReserves;

    // Info of each user.
    struct UserInfoV3 {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lockedRewardDebt; // Reward debt. See explanation below.
        bool isUpdated; // true if the user has been migrated from the v1 controller to v2
        //
        // We do some fancy math here. Basically, any point in time, the amount of FATEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accumulatedFatePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accumulatedFatePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    IERC20 public override fate;

    address public override vault;

    IFateRewardController[] public oldControllers;

    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public override migrator;

    // Info of each pool.
    PoolInfoV3[] public override poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfoV3)) internal _userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public override totalAllocPoint = 0;

    // The block number when FATE mining starts.
    uint256 public override startBlock;

    IMockLpTokenFactory public mockLpTokenFactory;

    // address of FeeTokenConverterToFate contract
    event FateFeeToSet(address _fateFeeTo);

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event ClaimRewards(address indexed user, uint256 indexed pid, uint256 amount);

    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event EmissionScheduleSet(address indexed emissionSchedule);

    event MigratorSet(address indexed migrator);

    event VaultSet(address indexed emissionSchedule);

    event PoolAdded(uint indexed pid, address indexed lpToken, uint allocPoint);

    event PoolAllocPointSet(uint indexed pid, uint allocPoint);

    constructor(
        IERC20 _fate,
        IRewardScheduleV3 _emissionSchedule,
        address _vault,
        IFateRewardController[] memory _oldControllers,
        IMockLpTokenFactory _mockLpTokenFactory,
        address _fateFeeTo
    ) public {
        fate = _fate;
        emissionSchedule = _emissionSchedule;
        vault = _vault;
        oldControllers = _oldControllers;
        mockLpTokenFactory = _mockLpTokenFactory;
        startBlock = _oldControllers[0].startBlock();
        fateFeeTo = _fateFeeTo;
        // inset old controller's pooInfo
        for (uint i = 0; i < _oldControllers[0].poolLength(); i++) {
            (IERC20 lpToken, uint256 allocPoint, ,) = _oldControllers[0].poolInfo(i);
            poolInfo.push(
                PoolInfoV3({
                    lpToken: lpToken,
                    allocPoint: allocPoint,
                    lastRewardBlock: startBlock,
                    accumulatedFatePerShare: 0,
                    accumulatedLockedFatePerShare: 0
                })
            );
            totalAllocPoint = totalAllocPoint.add(allocPoint);
        }
    }

    function setFateFeeTo(address _fateFeeTo) external onlyOwner {
        require(_fateFeeTo != address(0), 'setFateFeeTo: invalid feeTo');
        fateFeeTo = _fateFeeTo;
        emit FateFeeToSet(fateFeeTo);
    }

    function poolLength() public override view returns (uint256) {
        return poolInfo.length;
    }

    function addMany(
        IERC20[] calldata _lpTokens
    ) external onlyOwner {
        uint allocPoint = 0;
        for (uint i = 0; i < _lpTokens.length; i++) {
            bool shouldUpdate = i == _lpTokens.length - 1;
            _add(allocPoint, _lpTokens[i], shouldUpdate);
        }
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        _add(_allocPoint, _lpToken, _withUpdate);
    }

    function getPoolInfoId(address _lpToken) external view returns (uint256) {
        for(uint i = 0; i < poolInfo.length; i++) {
            if(address(poolInfo[i].lpToken) == _lpToken) {
                return i + 1;
            }
        }
        return 0;
    }

    function _add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) internal {
        for (uint i = 0; i < poolInfo.length; i++) {
            require(
                poolInfo[i].lpToken != _lpToken,
                "add: LP token already added"
            );
        }

        if (_withUpdate) {
            massUpdatePools();
        }
        require(
            _lpToken.balanceOf(address(this)) >= 0,
            "add: invalid LP token"
        );

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfoV3({
                lpToken : _lpToken,
                allocPoint : _allocPoint,
                lastRewardBlock : lastRewardBlock,
                accumulatedFatePerShare : 0,
                accumulatedLockedFatePerShare : 0
            })
        );
        emit PoolAdded(poolInfo.length - 1, address(_lpToken), _allocPoint);
    }

    // Update the given pool's FATE allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        _set(_pid, _allocPoint, _withUpdate);
    }

    // Update the given pool's FATE allocation point. Can only be called by the owner.
    function setMany(
        uint256[] calldata _pids,
        uint256[] calldata _allocPoints
    ) external onlyOwner {
        require(
            _pids.length == _allocPoints.length,
            "setMany: invalid length"
        );
        for (uint i = 0; i < _pids.length; i++) {
            _set(_pids[i], _allocPoints[i], i == _pids.length - 1);
        }
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _amountOutMin,
        address _to
    ) external {
        IERC20(_tokenIn).approve(address(this), _amountIn);
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        IUniswapV2Router01(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp
        );
    }


    function _collectSwapFees(address _token, uint256 _amount, uint256 _feeBasisPoints) private returns (uint256) {
        uint256 afterFeeAmount = _amount.mul(BASIS_POINTS_DIVISOR.sub(_feeBasisPoints)).div(BASIS_POINTS_DIVISOR);
        uint256 feeAmount = _amount.sub(afterFeeAmount);
        feeReserves[_token] = feeReserves[_token].add(feeAmount);
//        emit CollectSwapFees(_token, tokenToUsdMin(_token, feeAmount), feeAmount);
        return afterFeeAmount;
    }

    function getFeeReserves(address _token) external view returns (uint256)
    {
        return feeReserves[_token];
    }

    // Update the given pool's FATE allocation point. Can only be called by the owner.
    function setManyWith2dArray(
        uint256[][] calldata _pidsAndAllocPoints
    ) external onlyOwner {
        uint _poolLength = poolInfo.length;
        for (uint i = 0; i < _pidsAndAllocPoints.length; i++) {
            uint[] memory _pidAndAllocPoint = _pidsAndAllocPoints[i];
            require(
                _pidAndAllocPoint.length == 2,
                "setManyWith2dArray: invalid length, expected 2"
            );
            require(
                _pidAndAllocPoint[0] < _poolLength,
                "setManyWith2dArray: invalid pid"
            );
            _set(
                _pidAndAllocPoint[0],
                _pidAndAllocPoint[1],
                /* withUpdate */ i == _pidsAndAllocPoints.length - 1
            );
        }
    }

    function _set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) internal {
        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        emit PoolAllocPointSet(_pid, _allocPoint);
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public override onlyOwner {
        migrator = _migrator;
        emit MigratorSet(address(_migrator));
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public override {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfoV3 storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    function migrate(
        IERC20 token
    ) external override returns (IERC20) {
        IFateRewardController oldController = IFateRewardController(address(0));
        for (uint i = 0; i < oldControllers.length; i++) {
            if (address(oldControllers[i]) == msg.sender) {
                oldController = oldControllers[i];
            }
        }
        require(
            address(oldController) != address(0),
            "migrate: invalid sender"
        );

        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accumulatedFatePerShare;
        uint oldPoolLength = oldController.poolLength();
        for (uint i = 0; i < oldPoolLength; i++) {
            (lpToken, allocPoint, lastRewardBlock, accumulatedFatePerShare) = oldController.poolInfo(poolInfo.length);
            if (address(lpToken) == address(token)) {
                break;
            }
        }

        // transfer all of the tokens from the previous controller to here
        token.approve(address(this), token.balanceOf(msg.sender));
        token.transferFrom(msg.sender, address(this), token.balanceOf(msg.sender));

        poolInfo.push(
            PoolInfoV3({
                lpToken : lpToken,
                allocPoint : allocPoint,
                lastRewardBlock : lastRewardBlock,
                accumulatedFatePerShare : accumulatedFatePerShare,
                accumulatedLockedFatePerShare : 0
            })
        );
        emit PoolAdded(poolInfo.length - 1, address(token), allocPoint);

        uint _totalAllocPoint = 0;
        for (uint i = 0; i < poolInfo.length; i++) {
            _totalAllocPoint = _totalAllocPoint.add(poolInfo[i].allocPoint);
        }
        totalAllocPoint = _totalAllocPoint;

        return IERC20(mockLpTokenFactory.create(address(lpToken), address(this)));
    }

    function userInfo(
        uint _pid,
        address _user
    ) public override view returns (uint amount, uint rewardDebt) {
        UserInfoV3 memory user = _userInfo[_pid][_user];
        return (user.amount, user.rewardDebt);
    }

    function _getUserInfo(
        uint _pid,
        address _user
    ) public view returns (IFateRewardControllerV3.UserInfo memory) {
        UserInfoV3 memory user = _userInfo[_pid][_user];
        return IFateRewardControllerV3.UserInfo(user.amount, user.rewardDebt, user.lockedRewardDebt);
    }

    // View function to see pending FATE tokens on frontend.
    function pendingUnlockedFate(
        uint256 _pid,
        address _user
    )
    public
    override
    view
    returns (uint256)
    {
        PoolInfoV3 storage pool = poolInfo[_pid];
        IFateRewardControllerV3.UserInfo memory user = _getUserInfo(_pid, _user);
        uint256 accumulatedFatePerShare = pool.accumulatedFatePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            (, uint256 unlockedFatePerBlock) = emissionSchedule.getFatePerBlock(
                startBlock,
                pool.lastRewardBlock,
                block.number
            ); // only unlocked Fates
            uint256 unlockedFateReward = unlockedFatePerBlock
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accumulatedFatePerShare = accumulatedFatePerShare
                .add(unlockedFateReward
                .mul(1e12)
                .div(lpSupply)
            );
        }
        return user.amount
            .mul(accumulatedFatePerShare)
            .div(1e12)
            .sub(user.rewardDebt);
    }

    function pendingLockedFate(
        uint256 _pid,
        address _user
    )
    public
    override
    view
    returns (uint256)
    {
        PoolInfoV3 storage pool = poolInfo[_pid];
        IFateRewardControllerV3.UserInfo memory user = _getUserInfo(_pid, _user);
        uint256 accumulatedLockedFatePerShare = pool.accumulatedLockedFatePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            (uint256 lockedFatePerBlock,) = emissionSchedule.getFatePerBlock(
                startBlock,
                pool.lastRewardBlock,
                block.number
            ); // only locked Fates
            uint256 lockedFateReward = lockedFatePerBlock
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accumulatedLockedFatePerShare = accumulatedLockedFatePerShare.add(lockedFateReward.mul(1e12).div(lpSupply));
        }

        uint lockedReward = user.amount.mul(accumulatedLockedFatePerShare).div(1e12).sub(user.lockedRewardDebt);
        return lockedReward.sub(lockedReward.mul(getLockedRewardsFeePercent(_pid, _user)).div(1e18));
    }

    function allPendingUnlockedFate(
        address _user
    )
    external
    override
    view
    returns (uint256)
    {
        uint _pendingFateRewards = 0;
        for (uint i = 0; i < poolInfo.length; i++) {
            _pendingFateRewards = _pendingFateRewards.add(pendingUnlockedFate(i, _user));
        }
        return _pendingFateRewards;
    }

    function allPendingLockedFate(
        address _user
    )
    external
    override
    view
    returns (uint256)
    {
        uint _pendingFateRewards = 0;
        for (uint i = 0; i < poolInfo.length; i++) {
            _pendingFateRewards = _pendingFateRewards.add(pendingLockedFate(i, _user));
        }
        return _pendingFateRewards;
    }

    function allLockedFate(
        address _user
    )
    external
    override
    view
    returns (uint256)
    {
        uint _pendingFateRewards = 0;
        for (uint i = 0; i < poolInfo.length; i++) {
            _pendingFateRewards = _pendingFateRewards.add(pendingLockedFate(i, _user)).add(userLockedRewards[i][_user]);
        }
        return _pendingFateRewards;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function getNewRewardPerBlock(uint pid1) public view returns (uint) {
        (, uint256 fatePerBlock) = emissionSchedule.getFatePerBlock(
            startBlock,
            block.number - 1,
            block.number
        );
        if (pid1 == 0) {
            return fatePerBlock;
        } else {
            return fatePerBlock.mul(poolInfo[pid1 - 1].allocPoint).div(totalAllocPoint);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfoV3 storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        (uint256 lockedFatePerBlock, uint256 unlockedFatePerBlock) = emissionSchedule.getFatePerBlock(
            startBlock,
            pool.lastRewardBlock,
            block.number
        );

        uint256 unlockedFateReward = unlockedFatePerBlock
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        uint256 lockedFateReward = lockedFatePerBlock
            .mul(pool.allocPoint)
            .div(totalAllocPoint);

        if (unlockedFateReward > 0) {
            fate.approve(address(this), unlockedFateReward);
            fate.transferFrom(vault, address(this), unlockedFateReward);
            pool.accumulatedFatePerShare = pool.accumulatedFatePerShare
                .add(unlockedFateReward.mul(1e12).div(lpSupply));
        }
        if (lockedFateReward > 0) {
            pool.accumulatedLockedFatePerShare = pool.accumulatedLockedFatePerShare
                .add(lockedFateReward.mul(1e12).div(lpSupply));
        }
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for FATE allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfoV3 storage pool = poolInfo[_pid];
        IFateRewardControllerV3.UserInfo memory user = _getUserInfo(_pid, msg.sender);
        updatePool(_pid);
        if (user.amount > 0) {
            _claimRewards(_pid, msg.sender, user, pool);
        }
        pool.lpToken.approve(address(this), _amount);
        pool.lpToken.transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        uint userBalance = user.amount.add(_amount);
        _userInfo[_pid][msg.sender] = UserInfoV3({
            amount : userBalance,
            rewardDebt : userBalance.mul(pool.accumulatedFatePerShare).div(1e12),
            lockedRewardDebt : userBalance.mul(pool.accumulatedLockedFatePerShare).div(1e12),
            isUpdated : true
        });

        // record deposit block
        MembershipInfo memory membership = userMembershipInfo[_pid][msg.sender];
        if (
            block.number <= emissionSchedule.epochEndBlock() &&
            membership.firstDepositBlock == 0 // not recorded (or deposited) yet
        ) {
            userMembershipInfo[_pid][msg.sender] = MembershipInfo({
                firstDepositBlock: block.number,
                lastWithdrawBlock:
                    membership.lastWithdrawBlock > 0 ? membership.lastWithdrawBlock : block.number
            });
        }

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfoV3 storage pool = poolInfo[_pid];
        IFateRewardControllerV3.UserInfo memory user = _getUserInfo(_pid, msg.sender);
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);

        _claimRewards(_pid, msg.sender, user, pool);

        uint userBalance = user.amount.sub(_amount);
        _userInfo[_pid][msg.sender] = UserInfoV3({
            amount : userBalance,
            rewardDebt : userBalance.mul(pool.accumulatedFatePerShare).div(1e12),
            lockedRewardDebt : userBalance.mul(pool.accumulatedLockedFatePerShare).div(1e12),
            isUpdated : true
        });

        uint256 withdrawAmount = _reduceWithdrawalForFeesAndUpdateMembershipInfo(
            _pid,
            msg.sender,
            _amount,
            userBalance == 0
        );

        // send Fee to FeeTokenConverterToFate
        if (_amount > withdrawAmount) {
            uint256 feeAmount = _amount.sub(withdrawAmount);
            feeReserves[address(pool.lpToken)] = feeReserves[address(pool.lpToken)].add(feeAmount);
            pool.lpToken.transfer(fateFeeTo, feeAmount);
        }

        pool.lpToken.transfer(msg.sender, withdrawAmount);
        emit Withdraw(msg.sender, _pid, withdrawAmount);
    }

    function withdrawAll() public {
        for (uint i = 0; i < poolInfo.length; i++) {
            (uint amount,) = userInfo(i, msg.sender);
            if (amount > 0) {
                withdraw(i, amount);
            }
        }
    }

    // Reduce LPWithdrawFee and record last withdraw block
    function _reduceWithdrawalForFeesAndUpdateMembershipInfo(
        uint256 _pid,
        address _account,
        uint256 _amount,
        bool _withdrawAll
    ) internal returns (uint256) {
        MembershipInfo memory membership = userMembershipInfo[_pid][_account];
        uint256 firstDepositBlock = membership.firstDepositBlock;

        if (_withdrawAll) {
            // record points earned and do not earn any more
            trackedPoints[_pid][_account] = trackedPoints[_pid][_account]
                .add(_getBlocksOfPeriod(_pid, _account, true).mul(POINTS_PER_BLOCK));

            firstDepositBlock = 0;
        }

        userMembershipInfo[_pid][_account] = MembershipInfo({
            firstDepositBlock: firstDepositBlock,
            lastWithdrawBlock: block.number
        });

        // minus LPWithdrawFee = amount * (1e18 - lpFee) / 1e18 = amount - amount * lpFee / 1e18
        return _amount.sub(_amount.mul(getLPWithdrawFeePercent(_pid, _account)).div(10000));
    }

    function _claimRewards(
        uint256 _pid,
        address _user,
        IFateRewardControllerV3.UserInfo memory user,
        PoolInfoV3 memory pool
    ) internal {
        uint256 pendingUnlocked = user.amount
            .mul(pool.accumulatedFatePerShare)
            .div(1e12)
            .sub(user.rewardDebt);

        uint256 pendingLocked = user.amount
            .mul(pool.accumulatedLockedFatePerShare)
            .div(1e12)
            .sub(user.lockedRewardDebt);

        // implement fee reduction for pendingLocked
        pendingLocked = pendingLocked.sub(pendingLocked.mul(getLockedRewardsFeePercent(_pid, _user)).div(1e18));

        // recorded locked rewards
        userLockedRewards[_pid][_user] = userLockedRewards[_pid][_user].add(pendingLocked);

        _safeFateTransfer(_user, pendingUnlocked);
        emit ClaimRewards(_user, _pid, pendingUnlocked);
    }

    // claim any pending rewards from this pool, from msg.sender
    function claimReward(uint256 _pid) public {
        PoolInfoV3 storage pool = poolInfo[_pid];
        IFateRewardControllerV3.UserInfo memory user = _getUserInfo(_pid, msg.sender);
        updatePool(_pid);
        _claimRewards(_pid, msg.sender, user, pool);

        _userInfo[_pid][msg.sender] = UserInfoV3({
            amount : user.amount,
            rewardDebt : user.amount.mul(pool.accumulatedFatePerShare).div(1e12),
            lockedRewardDebt : user.amount.mul(pool.accumulatedLockedFatePerShare).div(1e12),
            isUpdated : true
        });
    }

    // claim any pending rewards from this pool, from msg.sender
    function claimRewards(uint256[] calldata _pids) external {
        for (uint i = 0; i < _pids.length; i++) {
            claimReward(_pids[i]);
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfoV3 storage pool = poolInfo[_pid];
        IFateRewardControllerV3.UserInfo memory user = _getUserInfo(_pid, msg.sender);
        pool.lpToken.transfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);

        _userInfo[_pid][msg.sender] = UserInfoV3({
            amount : 0,
            rewardDebt : 0,
            lockedRewardDebt : 0,
            isUpdated : true
        });
    }

    // Safe fate transfer function, just in case if rounding error causes pool to not have enough FATEs.
    function _safeFateTransfer(address _to, uint256 _amount) internal {
        uint256 fateBal = fate.balanceOf(address(this));
        if (_amount > fateBal) {
            fate.transfer(_to, fateBal);
        } else {
            fate.transfer(_to, _amount);
        }
    }

    function setEmissionSchedule(
        IRewardScheduleV3 _emissionSchedule
    )
    public
    onlyOwner {
        // pro-rate the pools to the current block, before changing the schedule
        massUpdatePools();
        emissionSchedule = _emissionSchedule;
        emit EmissionScheduleSet(address(_emissionSchedule));
    }

    function setVault(
        address _vault
    )
    public
    override
    onlyOwner {
        // pro-rate the pools to the current block, before changing the schedule
        vault = _vault;
        emit VaultSet(_vault);
    }

    /// @dev calculate Points earned by this user
    function userPoints(uint256 _pid, address _user) external view returns (uint256){
        if (!isFatePool(_pid)) {
            return 0;
        } else {
            return POINTS_PER_BLOCK
                .mul(_getBlocksOfPeriod(_pid, _user, true))
                .add(trackedPoints[_pid][_user]);
        }
    }

    /// @dev check if pool is FatePool or not
    function isFatePool(uint _pid) internal view returns(bool) {
        return _pid < poolInfo.length && address(poolInfo[_pid].lpToken) != address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: GPL-3.0

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockLpToken {

    address internal rewardController;
    address internal lpToken;

    event MockLpTokenCreated(address indexed lpToken);

    constructor(
        address _lpToken,
        address _rewardController
    ) public {
        lpToken = _lpToken;
        rewardController = _rewardController;
        emit MockLpTokenCreated(_lpToken);
    }

    function balanceOf(address) external view returns (uint) {
        return IERC20(lpToken).balanceOf(rewardController);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMockLpTokenFactory {

    function create(
        address _lpToken,
        address _rewardController
    ) external returns (address);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IMigratorChef.sol";
import "./IRewardSchedule.sol";

abstract contract IFateRewardController is Ownable, IMigratorChef {

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of FATEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accumulatedFatePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accumulatedFatePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. FATEs to distribute per block.
        uint256 lastRewardBlock; // Last block number that FATEs distribution occurs.
        uint256 accumulatedFatePerShare; // Accumulated FATEs per share, times 1e12. See below.
    }

    function fate() external virtual view returns (IERC20);
    function vault() external virtual view returns (address);
    function migrator() external virtual view returns (IMigratorChef);
    function poolInfo(uint _pid) external virtual view returns (IERC20 lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accumulatedFatePerShare);
    function userInfo(uint _pid, address _user) external virtual view returns (uint256 amount, uint256 rewardDebt);
    function poolLength() external virtual view returns (uint);
    function startBlock() external virtual view returns (uint);
    function totalAllocPoint() external virtual view returns (uint);
    function pendingFate(uint256 _pid, address _user) external virtual view returns (uint256);

    function setMigrator(IMigratorChef _migrator) external virtual;
    function setVault(address _vault) external virtual;
    function migrate(uint256 _pid) external virtual;

    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) external virtual;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../../libraries/RankedArray.sol";

import "./IRewardScheduleV3.sol";
import "./IFateRewardControllerV3.sol";

abstract contract MembershipWithReward is Ownable {
    using SafeMath for uint256;

    uint256 constant public POINTS_PER_BLOCK = 0.08e18;

    // The emission scheduler that calculates fate per block over a given period
    IRewardScheduleV3 public emissionSchedule;

    struct MembershipInfo {
        uint256 firstDepositBlock; // set when first deposit
        uint256 lastWithdrawBlock; // set when first deposit, updates whenever withdraws
    }

    mapping(address => bool) public isExcludedAddress;

    // pid => address => membershipInfo
    mapping(uint256 => mapping (address => MembershipInfo)) public userMembershipInfo;

    // pid ==> address ==> tracked points
    mapping(uint256 => mapping (address => uint256)) public trackedPoints;

    /// @dev pid => user address => lockedRewards
    mapping(uint256 => mapping (address => uint256)) public userLockedRewards;

    /// @dev data for FateLockedRewardFee
    uint256[] public lockedRewardsPeriodBlocks = [
        30,
        60,
        120,
        3600,
        86400,
        172800,
        259200,
        345600,
        432000,
        518400,
        604800,
        691200,
        777600,
        864000,
        950400,
        1036800,
        1123200,
        1209600,
        1296000,
        1382400,
        1468800,
        1555200
    ];
    uint256[] public lockedRewardsFeePercents = [
        10000,
        9800,
        9700,
        9000,
        8800,
        8800,
        8000,
        7200,
        6300,
        5800,
        5000,
        4500,
        4000,
        3500,
        3000,
        2500,
        2000,
        1500,
        800,
        360,
        180,
        80
    ];

    /// @dev data for LPWithdrawFee
    uint256[] public lpWithdrawPeriodBlocks = [
        30,
        60,
        120,
        3600,
        86400,
        172800,
        259200,
        345600,
        432000,
        518400,
        604800,
        691200,
        777600,
        864000,
        950400,
        1036800,
        1123200,
        1209600,
        1296000,
        1382400,
        1468800,
        1555200
    ];
    uint256[] public lpWithdrawFeePercent = [
        10000,
        8800,
        7200,
        3600,
        1800,
        888,
        888,
        888,
        360,
        360,
        360,
        360,
        180,
        180,
        180,
        180,
        180,
        180,
        180,
        88,
        88,
        18,
        8
    ];

    event LockedRewardsDataSet(uint256[] _lockedRewardsPeriodBlocks, uint256[] _lockedRewardsFeePercents);
    event LPWithdrawDataSet(uint256[] _lpWithdrawPeriodBlocks, uint256[] _lpWithdrawFeePercent);
    event ExcludedAddressSet(address _account, bool _status);

    /// @dev set lockedRewardsPeriodBlocks & lockedRewardsFeePercents
    function setLockedRewardsData(
        uint256[] memory _lockedRewardsPeriodBlocks,
        uint256[] memory _lockedRewardsFeePercents
    ) external onlyOwner {
        require(
            _lockedRewardsPeriodBlocks.length > 0 &&
            _lockedRewardsPeriodBlocks.length == _lockedRewardsFeePercents.length,
            "setLockedRewardsData: invalid input data"
        );
        lockedRewardsPeriodBlocks = _lockedRewardsPeriodBlocks;
        lockedRewardsFeePercents = _lockedRewardsFeePercents;

        emit LockedRewardsDataSet(_lockedRewardsPeriodBlocks, _lockedRewardsFeePercents);
    }

    /// @dev set lpWithdrawPeriodBlocks & lpWithdrawFeePercent
    function setLPWithdrawData(
        uint256[] memory _lpWithdrawPeriodBlocks,
        uint256[] memory _lpWithdrawFeePercent
    ) external onlyOwner {
        require(
            _lpWithdrawPeriodBlocks.length == _lpWithdrawFeePercent.length,
            "setLPWithdrawData: not same length"
        );
        lpWithdrawPeriodBlocks = _lpWithdrawPeriodBlocks;
        lpWithdrawFeePercent = _lpWithdrawFeePercent;

        emit LPWithdrawDataSet(_lpWithdrawPeriodBlocks, _lpWithdrawFeePercent);
    }

    /// @dev set excluded addresses
    function setExcludedAddresses(address[] memory accounts, bool[] memory status) external onlyOwner {
        require(
            accounts.length > 0 &&
            accounts.length == status.length,
            "setExcludedAddresses: invalid data"
        );
        for (uint i = 0; i < accounts.length; i++) {
            isExcludedAddress[accounts[i]] = status[i];
            emit ExcludedAddressSet(accounts[i], status[i]);
        }
    }

    /// @dev calculate index of LockedRewardFee data
    function _getPercentFromBlocks(
        uint256 periodBlocks,
        uint256[] memory blocks,
        uint256[] memory percents
    ) internal pure returns (uint256) {
        if (periodBlocks < blocks[0]) {
            return percents[0];
        } else if (periodBlocks > blocks[blocks.length - 1]) {
            return 0;
        } else {
            for (uint i = 0; i < blocks.length - 1; i++) {
                if (
                    periodBlocks > blocks[i] &&
                    periodBlocks <= blocks[i + 1]
                ) {
                    return percents[i];
                }
            }
            revert("_getPercentFromBlocks: should have returned value");
        }
    }

    function _getBlocksOfPeriod(
        uint256 _pid,
        address _user,
        bool _isDepositPeriod
    ) internal view returns (uint256) {
        uint256 epochEndBlock = emissionSchedule.epochEndBlock();
        uint256 endBlock = block.number > epochEndBlock ? epochEndBlock : block.number;
        uint256 startBlock = _isDepositPeriod ?
            userMembershipInfo[_pid][_user].firstDepositBlock : userMembershipInfo[_pid][_user].lastWithdrawBlock;

        uint256 blocks = 0;
        if (startBlock != 0 && endBlock >= startBlock) {
            blocks = endBlock - startBlock ;
        }
        return blocks;
    }

    /// @dev calculate percent of lockedRewardFee based on their deposit period
    /// when withdraw during epoch, this fee will be reduced from member's lockedRewards
    /// this fee does not work for excluded address and after epoch is ended
    function getLockedRewardsFeePercent(
        uint256 _pid,
        address _caller
    ) public view returns (uint256) {
        if (
            isExcludedAddress[_caller] ||
            block.number > emissionSchedule.epochEndBlock()
        ) {
            return 0;
        } else {
            return _getPercentFromBlocks(
                _getBlocksOfPeriod(
                    _pid,
                    _caller,
                    true
                ),
                lockedRewardsPeriodBlocks,
                lockedRewardsFeePercents
            );
        }
    }

    /// @dev calculate percent of lpWithdrawFee based on their deposit period
    /// when users withdaw during epoch, this fee will be reduced from their withdrawAmount
    /// this fee will be still stored on FateRewardControllerV3 contract
    /// this fee does not work for excluded address and after epoch is ended
    function getLPWithdrawFeePercent(
        uint256 _pid,
        address _caller
    ) public view returns (uint256) {
        if (
            isExcludedAddress[_caller] ||
            block.number > emissionSchedule.epochEndBlock()
        ) {
            return 0;
        } else {
            return _getPercentFromBlocks(
                _getBlocksOfPeriod(
                    _pid,
                    _caller,
                    false
                ),
                lpWithdrawPeriodBlocks,
                lpWithdrawFeePercent
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../IMigratorChef.sol";

abstract contract IFateRewardControllerV3 is Ownable, IMigratorChef {

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lockedRewardDebt; // Locked reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of FATEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accumulatedFatePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accumulatedFatePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfoV3 {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. FATEs to distribute per block.
        uint256 lastRewardBlock; // Last block number that FATEs distribution occurs.
        uint256 accumulatedFatePerShare; // Accumulated FATEs per share, times 1e12. See below.
        uint256 accumulatedLockedFatePerShare; // Accumulated locked FATEs per share, times 1e12. See below.
    }

    function fate() external virtual view returns (IERC20);
    function vault() external virtual view returns (address);
    function migrator() external virtual view returns (IMigratorChef);
    function poolInfo(uint _pid) external virtual view returns (
        IERC20 lpToken,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accumulatedFatePerShare,
        uint256 accumulatedLockedFatePerShare
    );
    function userInfo(uint _pid, address _user) external virtual view returns (uint256 amount, uint256 rewardDebt);
    function poolLength() external virtual view returns (uint);
    function startBlock() external virtual view returns (uint);
    function totalAllocPoint() external virtual view returns (uint);
    function pendingUnlockedFate(uint256 _pid, address _user) external virtual view returns (uint256);
    function pendingLockedFate(uint256 _pid, address _user) external virtual view returns (uint256);
    function allPendingUnlockedFate(address _user) external virtual view returns (uint256);
    function allPendingLockedFate(address _user) external virtual view returns (uint256);
    function allLockedFate(address _user) external virtual view returns (uint256);

    function setMigrator(IMigratorChef _migrator) external virtual;
    function setVault(address _vault) external virtual;
    function migrate(uint256 _pid) external virtual;
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
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

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMigratorChef {
    // Perform LP token migration from legacy UniswapV2 to FATEx DEX.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // FATEx DEX must mint EXACTLY the same amount of FATEx DEX LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardSchedule {

    function getFatePerBlock(
        uint _startBlock,
        uint _fromBlock,
        uint _toBlock
    )
    external
    view
    returns (uint);


    function calculateCurrentIndex(
        uint _startBlock
    )
    external
    view
    returns (uint);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


library RankedArray {
    function quickSort(uint[] memory arr, int left, int right) internal pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j) {
            quickSort(arr, left, j);
        }
        if (i < right) {
            quickSort(arr, i, right);
        }
    }

    function sort(uint[] memory data) internal pure returns (uint[] memory) {
        quickSort(data, int(0), int(data.length - 1));
        return data;
    }

    function getIndex(uint[] memory data, uint num) internal pure returns (uint index) {
        index = data.length;
        for(uint i = 0; i < data.length; i++) {
            if (data[i] == num) {
                index = i;
            }
        }
    }

    function getIndexOfAddressArray(address[] memory data, address addr) internal pure returns (uint256 index) {
        index = data.length;
        for (uint i=0; i < data.length; i++) {
            if (data[i] == addr) index = i;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardScheduleV3 {

    function getFatePerBlock(
        uint _startBlock,
        uint _fromBlock,
        uint _toBlock
    )
    external
    view
    returns (uint lockedFatePerBlock, uint unlockedFatePerBlock);


    function calculateCurrentIndex(
        uint _startBlock
    )
    external
    view
    returns (uint);

    function epochStartBlock() external view returns (uint);
    function epochEndBlock() external view returns (uint);
    function lockedPercent() external view returns (uint);
}