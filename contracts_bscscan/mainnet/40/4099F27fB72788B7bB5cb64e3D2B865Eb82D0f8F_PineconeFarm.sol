// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "./helpers/ERC20.sol";
import "./libraries/SafeERC20.sol";
import "./interfaces/IPinecone.sol";
import "./interfaces/IPineconeToken.sol";
import "./interfaces/IWETH.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

struct UserInfo {
    uint256 shares;
    uint256 pending; 
    uint256 rewardPaid;
}

struct UserRewardBNB {
    uint256 shares;
    uint256 pending; 
    uint256 rewardPaid;
    uint256 lastRewardTime;
    uint256 claimed;
}

struct PoolInfo {
    IERC20 want; 
    uint256 allocPCTPoint; 
    uint256 accPCTPerShare; 
    uint256 lastRewardBlock;
    address strat;
}

struct RewardToken {
    uint256 startTime;
    uint256 accAmount;
    uint256 totalAmount;
}

struct CakeRewardToken {
    uint256 startTime;
    uint256 accAmount;
    uint256 totalAmount;
    uint256 accPerShare;
}

contract PineconeFarm is OwnableUpgradeable, ReentrancyGuardUpgradeable, IPineconeTokenCallee {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public PCTPerBlock;
    uint256 public startBlock;
    PoolInfo[] public poolInfo; 
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public totalPCTAllocPoint; // Total allocation points. Must be the sum of all allocation points in all pools.

    RewardToken public pctTokenReward;
    CakeRewardToken public cakeTokenReward;
    mapping(address => UserRewardBNB) public userRewardBNB;

    address public pctAddress; //address of pct token
    address public pctPairAddress; //address of pct-bnb lp token

    mapping(address => bool) minters;
    uint256 public pctPerProfitBNB;
    uint256 public constant teamPCTReward = 250; //20%
    address public devAddress;
    address public teamRewardsAddress;

    uint256 public cakeRewardsStakingPid;

    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint256 public claimCoolDown;
    uint256 public calcDuration;
    uint256 public constant SEC_PER_DAY = 1 days;

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    mapping(address => bool) public whiteListContract;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event WithdrawAll(
        address indexed user, 
        uint256 indexed pid, 
        uint256 amount, 
        uint256 earnedToken0Amt, 
        uint256 earnedToken1Amt
    );

    event Claim(
        address indexed user, 
        uint256 indexed pid, 
        uint256 earnedToken0Amt, 
        uint256 earnedToken1Amt
    );

    event ClaimBNB(
        address indexed user,
        uint256 earnedAmt
    );

    function initialize(
        address _pctAddress
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        pctAddress = _pctAddress;
        pctPairAddress = IPineconeToken(_pctAddress).pctPair();
        PCTPerBlock = 0;
        startBlock = 0;
        totalPCTAllocPoint = 0; 
        pctPerProfitBNB = 4000e18;
        devAddress = 0xc32Eb3766986f5E1E0b7F13b0Fc8eB2613d34720;
        teamRewardsAddress = 0x2F568Ddea18582C3A36BD21514226eD203eF606a;
        calcDuration = 5 days;
        claimCoolDown = 5 days;
    }

    receive() external payable {}
    
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    modifier onlyDev {
        require(devAddress == msg.sender, "caller is not the dev");
        _;
    }

    modifier onlyEOAOrAuthContract {
        if (whiteListContract[msg.sender] == false) {
            require(!isContract(msg.sender), "contract not allowed");
            require(msg.sender == tx.origin, "proxy contract not allowed");
        }
        _;
    }

    // set minter
    function setMinter(
        address _minter,
        bool _canMint
    ) public onlyOwner {

        if (_canMint) {
            minters[_minter] = _canMint;
        } else {
            delete minters[_minter];
        }
    }

    function isMinter(address account) public view returns (bool) {
        if (IPineconeToken(pctAddress).isMinter(address(this)) == false) {
            return false;
        }
        return minters[account];
    }

    modifier onlyMinter {
        require(isMinter(msg.sender) == true, "caller is not the minter");
        _;
    }

    function setAuthContract(address _contract, bool _auth) public onlyDev {
        whiteListContract[_contract] = _auth;
    }

    function setClaimCoolDown(uint256 _duration) public onlyOwner {
        claimCoolDown = _duration;
    }

    function setCalDuration(uint256 _duration) public onlyOwner {
        require(_duration > SEC_PER_DAY, "duration less than 1 days");
        calcDuration = _duration;
    }

    function dailyEarnedAmount(uint256 _pid) public view returns(uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.allocPCTPoint == 0 || totalPCTAllocPoint == 0) {
            return 0;
        } else {

            uint256 earned0 = pctDailyReward().mul(pool.allocPCTPoint).div(totalPCTAllocPoint);
            uint256 earned1 = PCTPerBlock.mul(pool.allocPCTPoint).div(totalPCTAllocPoint).mul(28800);
            return earned0 + earned1;
        }
    }

    function poolInfoOf(uint256 _pid) public view returns(address want, address strat) {
        PoolInfo storage pool = poolInfo[_pid];
        want = address(pool.want);
        strat = pool.strat;
    }

    function userInfoOfPool(uint256 _pid, address _user) external view 
        returns(
            uint256 depositedAt, 
            uint256 depositAmt,
            uint256 balanceValue,
            uint256 earned0Amt,
            uint256 earned1Amt,
            uint256 withdrawbaleAmt
        )
    {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.strat == address(0)) {
            return (0,0,0,0,0,0);
        }

        uint256 pctAmt = pendingPCT(_pid, _user);    
        (depositedAt, depositAmt, balanceValue, earned0Amt, earned1Amt, withdrawbaleAmt) = IPineconeStrategy(pool.strat).userInfoOf(_user, pctAmt);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPCTPoint,
        address _want,
        bool _withUpdate,
        address _strat
    ) public onlyOwner returns (uint256)
    {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number;
        totalPCTAllocPoint = totalPCTAllocPoint.add(_allocPCTPoint);

        poolInfo.push(
            PoolInfo({
                want: IERC20(_want),
                allocPCTPoint: _allocPCTPoint,
                lastRewardBlock: lastRewardBlock,
                accPCTPerShare: 0,
                strat: _strat
            })
        );
        return poolInfo.length - 1;
    }

    // Update the given pool's PCT allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPCTPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalPCTAllocPoint = totalPCTAllocPoint.sub(poolInfo[_pid].allocPCTPoint).add(_allocPCTPoint);
        poolInfo[_pid].allocPCTPoint = _allocPCTPoint;
    }

    // set pctPerProfitBNB
    function setPctPerProfitBNB(uint256 _pctPerProfitBNB) public onlyOwner {
        pctPerProfitBNB = _pctPerProfitBNB;
    }

    function amountPctToMint(uint256 _bnbProfit) public view returns (uint256) {
        return _bnbProfit.mul(pctPerProfitBNB).div(1e18);
    }

    function setDevAddress(address _addr) external {
        require(devAddress == msg.sender, "no auth");
        devAddress = _addr;
    }

    function setTeamRewardsAddress(address _addr) external {
        require(teamRewardsAddress == msg.sender, "no auth");
        teamRewardsAddress = _addr;
    }

    function setPctPerBlock(uint256 _PCTPerBlock, uint256 _startBlock) public onlyOwner {
        if (_startBlock == 0) {
            _startBlock = block.number;
        }
        PCTPerBlock = _PCTPerBlock;
        startBlock = _startBlock;
    }

    function setCakeRewardsPid(
        uint256 _cakeRewardsPid)
    public onlyOwner {
        cakeRewardsStakingPid = _cakeRewardsPid;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (PCTPerBlock == 0) {
            return 0;
        }

        if (IPineconeToken(pctAddress).mintAvailable() == false) {
            return 0;
        }

        if (_from < startBlock) {
            _from = startBlock;
        }

        if (_to < startBlock) {
            _to = startBlock;
        }

        if (_to < _from) {
            _to = _from;
        }

        return _to.sub(_from);
    }

    function pendingPCT(uint256 _pid, address _user)
        public 
        view
        returns (uint256) 
    {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.allocPCTPoint == 0) {
            return 0;
        }

        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPCTPerShare = pool.accPCTPerShare;
        uint256 sharesTotal = IPineconeStrategy(pool.strat).sharesTotal();
        if (block.number > pool.lastRewardBlock && sharesTotal != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 PCTReward = multiplier.mul(PCTPerBlock).mul(pool.allocPCTPoint).div(totalPCTAllocPoint);
            accPCTPerShare = accPCTPerShare.add(PCTReward.mul(1e12).div(sharesTotal));
        }

        uint256 shares = user.shares;
        uint256 pending = user.pending.add(shares.mul(accPCTPerShare).div(1e12).sub(user.rewardPaid));

        return pending;
    }

    function pendingBNB(address _user) public view returns(
        uint256 pending, 
        uint256 lastRewardTime,
        uint256 claimed
    ) {
        UserRewardBNB storage user = userRewardBNB[_user];
        uint256 accPerShare = cakeTokenReward.accPerShare;
        uint256 shares = user.shares;
        pending = user.pending.add(shares.mul(accPerShare).div(1e12).sub(user.rewardPaid));
        PoolInfo storage cakePool = poolInfo[cakeRewardsStakingPid];
        pending = IPineconeStrategy(cakePool.strat).pendingBNB(pending, _user);
        lastRewardTime = user.lastRewardTime;
        claimed = user.claimed;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public 
    {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public 
    {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.allocPCTPoint == 0 || PCTPerBlock == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 sharesTotal = IPineconeStrategy(pool.strat).sharesTotal();
        if (sharesTotal == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        if (multiplier <= 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 PCTReward = multiplier.mul(PCTPerBlock).mul(pool.allocPCTPoint).div(totalPCTAllocPoint);
        
        _mint(address(this), PCTReward);

        _mintForTeam(PCTReward);

        pool.accPCTPerShare = pool.accPCTPerShare.add(PCTReward.mul(1e12).div(sharesTotal));
        pool.lastRewardBlock = block.number;
    }

    function _mint(address _to, uint256 _amount) private {
        if (IPineconeToken(pctAddress).mintAvailable() == false) {
            return;
        }

        IPineconeToken(pctAddress).mint(_to, _amount);
    }

    function deposit(uint256 _pid, uint256 _wantAmt) public payable nonReentrant onlyEOAOrAuthContract {
        require(_wantAmt > 0, "_wantAmt <= 0");
        require(_pid != cakeRewardsStakingPid, "no auth");

        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        if (address(pool.want) == WBNB) {
            require(_wantAmt == msg.value, "_wantAmt != msg.value");
            IWETH(WBNB).deposit{value: msg.value}();
        } else {
            pool.want.safeTransferFrom(
                address(msg.sender),
                address(this),
                _wantAmt
            );
        } 
        pool.want.safeIncreaseAllowance(pool.strat, _wantAmt);
        uint256 sharesAdded = IPineconeStrategy(pool.strat).deposit(_wantAmt, msg.sender);
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 pending = user.shares.mul(pool.accPCTPerShare).div(1e12).sub(user.rewardPaid);
        user.pending = user.pending.add(pending);
        user.shares = user.shares.add(sharesAdded);
        user.rewardPaid = user.shares.mul(pool.accPCTPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _wantAmt);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _wantAmt) public nonReentrant onlyEOAOrAuthContract {
        require(_wantAmt > 0, "_wantAmt <= 0");
        require(_pid != cakeRewardsStakingPid, "no auth");

        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        // Withdraw want tokens
        (uint256 wantAmt, uint256 sharesRemoved) = IPineconeStrategy(pool.strat).withdraw(_wantAmt, msg.sender);
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 pending = user.shares.mul(pool.accPCTPerShare).div(1e12).sub(user.rewardPaid);
        user.pending = user.pending.add(pending);
        user.shares = user.shares.sub(sharesRemoved);
        user.rewardPaid = user.shares.mul(pool.accPCTPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, wantAmt);
    }

    function withdrawAll(uint256 _pid) public nonReentrant onlyEOAOrAuthContract {
        require(_pid != cakeRewardsStakingPid, "no auth");

        updatePool(_pid);
        (uint256 amount, uint256 reward, uint256 rewardPct) = IPineconeStrategy(poolInfo[_pid].strat).withdrawAll(msg.sender);
        uint256 pct = _claimPendingPCT(_pid, msg.sender);
        pct = pct.add(rewardPct);
        UserInfo storage user = userInfo[_pid][msg.sender];
        user.shares = 0;
        user.pending = 0;
        user.rewardPaid = 0;
        emit WithdrawAll(msg.sender, _pid, amount, reward, pct);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant onlyEOAOrAuthContract {
        require(_pid != cakeRewardsStakingPid, "no auth");
        (uint256 amount,,) = IPineconeStrategy(poolInfo[_pid].strat).withdrawAll(msg.sender);
        UserInfo storage user = userInfo[_pid][msg.sender];
        user.shares = 0;
        user.pending = 0;
        user.rewardPaid = 0;
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function claim(uint256 _pid) public nonReentrant onlyEOAOrAuthContract {
        require(_pid != cakeRewardsStakingPid, "no auth");
        _claim(_pid);
    }

    function _claim(uint256 _pid) private {
        updatePool(_pid);
        (uint256 reward, uint256 rewardPct) = IPineconeStrategy(poolInfo[_pid].strat).claim(msg.sender);
        uint256 pct = _claimPendingPCT(_pid, msg.sender);
        pct = pct.add(rewardPct);
        emit Claim(msg.sender, _pid, reward, pct);
    }

    function _claimPendingPCT(uint256 _pid, address _user) private returns(uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.allocPCTPoint == 0) {
            return 0;
        }

        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPCTPerShare = pool.accPCTPerShare;
        uint256 pending = user.shares.mul(accPCTPerShare).div(1e12).sub(user.rewardPaid);
        uint256 amount = user.pending.add(pending);
        user.pending = 0;
        user.rewardPaid = user.shares.mul(accPCTPerShare).div(1e12);
        _safePCTTransfer(_user, amount);
        return amount;
    }

    function claimBNB() public nonReentrant onlyEOAOrAuthContract {
        _claimBNB(msg.sender, msg.sender);
    }

    function _claimBNB(address _user, address _to) private {
        UserRewardBNB storage user = userRewardBNB[_user];
        require(user.shares > 0, "no shares!");
        require(user.lastRewardTime + claimCoolDown <= block.timestamp, "cool down!");
        uint256 accPerShare = cakeTokenReward.accPerShare;
        uint256 pending = user.shares.mul(accPerShare).div(1e12).sub(user.rewardPaid);
        uint256 amount = user.pending.add(pending);
        user.pending = 0;
        user.rewardPaid = user.shares.mul(accPerShare).div(1e12);

        PoolInfo storage cakePool = poolInfo[cakeRewardsStakingPid];
        amount = IPineconeStrategy(cakePool.strat).claimBNB(amount, _to);
        user.claimed = user.claimed.add(amount);
        user.lastRewardTime = block.timestamp;
        emit ClaimBNB(_to, amount);
    }

    function claimPCTPairDustBNB(address _to) public onlyDev {
        _claimBNB(pctPairAddress, _to);
    }

    function claimPCTDustBNB(address _to) public onlyDev {
        _claimBNB(pctAddress, _to);
    }

    function claimDeadDustBNB(address _to) public onlyDev {
        _claimBNB(DEAD, _to);
    }

    // Safe PCT transfer function, just in case if rounding error causes pool to not have enough
    function _safePCTTransfer(address _to, uint256 _PCTAmt) private {
        if (_PCTAmt == 0) return;

        uint256 PCTBal = IERC20(pctAddress).balanceOf(address(this));
        if (PCTBal == 0) return;
        
        if (_PCTAmt > PCTBal) {
            _PCTAmt = PCTBal;
        }
        IERC20(pctAddress).safeTransfer(_to, _PCTAmt);
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount)
        public
        onlyOwner
    {
        require(_token != pctAddress, "!safe");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    function mintForProfit(address _to, uint256 _Profit, bool updatePCTRewards) public onlyMinter returns(uint256) {
        uint256 mintPct = amountPctToMint(_Profit);
        if (mintPct == 0) return 0;
        _mint(_to, mintPct);
        _mintForTeam(mintPct);
        if (_to == address(this) && updatePCTRewards) {
            _updatePCTRewards(mintPct);
        }
        return mintPct;
    }

    function _mintForTeam(uint256 _amount) private {
        uint256 pctForTeam = _amount.mul(teamPCTReward).div(1000);
        _mint(teamRewardsAddress, pctForTeam);
    }

    function stakeRewardsTo(address _to, uint256 _amount) public onlyMinter {
        _stakeRewardsTo(_to, _amount);
    }

    function _stakeRewardsTo(address _to, uint256 _amount) private {
        if (_amount == 0) return;

        if (_to == address(0)) {
            _to = teamRewardsAddress;
        }

        uint256 _pid = cakeRewardsStakingPid;
        PoolInfo storage pool = poolInfo[_pid];
        pool.want.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        pool.want.safeIncreaseAllowance(pool.strat, _amount);
        IPineconeStrategy(pool.strat).deposit(_amount, _to);
        _upateCakeRewards(_amount);
    }

    function pctDailyReward() public view returns(uint256) {
        if (pctTokenReward.startTime == 0) {
            return 0;
        }

        uint256 cap = block.timestamp.sub(pctTokenReward.startTime);
        uint256 rewardAmt = 0;
        if (cap <= SEC_PER_DAY) {
            rewardAmt = pctTokenReward.accAmount;
        } else {
            rewardAmt = pctTokenReward.accAmount.mul(SEC_PER_DAY).div(cap);
        }
        return rewardAmt;
    }

    function cakeDailyReward() public view returns(uint256) {
        if (cakeTokenReward.startTime == 0) {
            return 0;
        }

        uint256 cap = block.timestamp.sub(cakeTokenReward.startTime);
        if (cap <= SEC_PER_DAY) {
            return cakeTokenReward.accAmount;
        } else {
            return cakeTokenReward.accAmount.mul(SEC_PER_DAY).div(cap);
        }
    }

    function _updatePCTRewards(uint256 _amount) private {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePCTRewards(_amount, pid);
        }

        if (pctTokenReward.startTime == 0) {
            pctTokenReward.startTime = block.timestamp;
        } else {
            uint256 cap = block.timestamp.sub(pctTokenReward.startTime);
            if (cap >= calcDuration) {
                pctTokenReward.startTime = block.timestamp;
                pctTokenReward.accAmount = 0;
            }
        }
        pctTokenReward.accAmount = pctTokenReward.accAmount.add(_amount);
        pctTokenReward.totalAmount = pctTokenReward.totalAmount.add(_amount);
    } 

    function _updatePCTRewards(uint256 _amount, uint256 _pid) private {
        if (totalPCTAllocPoint == 0) {
            return;
        }

        PoolInfo storage pool = poolInfo[_pid];
        if (pool.allocPCTPoint == 0) {
            return;
        }

        uint256 sharesTotal = IPineconeStrategy(pool.strat).sharesTotal();
        if (sharesTotal == 0) {
            return;
        }

        uint256 PCTReward = _amount.mul(pool.allocPCTPoint).div(totalPCTAllocPoint);
        pool.accPCTPerShare = pool.accPCTPerShare.add(PCTReward.mul(1e12).div(sharesTotal));
    }

    function _upateCakeRewards(uint256 _amount) private {
        if (cakeTokenReward.startTime == 0) {
            cakeTokenReward.startTime = block.timestamp;
        } else {
            uint256 cap = block.timestamp.sub(cakeTokenReward.startTime);
            if (cap >= calcDuration) {
                cakeTokenReward.startTime = block.timestamp;
                cakeTokenReward.accAmount = 0;
            }
        }
        cakeTokenReward.accAmount = cakeTokenReward.accAmount.add(_amount);
        cakeTokenReward.totalAmount = cakeTokenReward.totalAmount.add(_amount);

        uint256 totalSupply = IERC20(pctAddress).totalSupply();
        cakeTokenReward.accPerShare = cakeTokenReward.accPerShare.add(_amount.mul(1e12).div(totalSupply));
    }

    function mintForPresale(address _to, uint256 _amount) public onlyMinter returns(uint256) {
        require(_amount > 0, "_amount == 0");

        uint256 mintPct = amountPctToMint(_amount);
        if (mintPct == 0) return 0;
        _mint(_to, mintPct);

        uint256 pctForTeam = mintPct.mul(teamPCTReward).div(1000);
        _mint(teamRewardsAddress, pctForTeam);

        return mintPct;
    }

    function stakeForPresale(address _to, uint256 _amount) public onlyMinter {
        _stakeRewardsTo(_to, _amount);
    }

    function transferCallee(address from, address to) override public {
        require(msg.sender == pctAddress, "not PCT!");
        _adjustCakeRewardTo(from);
        _adjustCakeRewardTo(to);
    }

    function _adjustCakeRewardTo(address _user) private {
        if (_user == address(0) || _user == address(this)) return;
        if (isContract(_user)) return;

        if (cakeTokenReward.accPerShare == 0) return;

        uint256 shares = IERC20(pctAddress).balanceOf(_user);
        UserRewardBNB storage user = userRewardBNB[_user];
        if (user.lastRewardTime == 0) {
            user.lastRewardTime = block.timestamp;
        }
        uint256 pending = user.shares.mul(cakeTokenReward.accPerShare).div(1e12).sub(user.rewardPaid);
        user.pending = user.pending.add(pending);
        user.shares = shares;
        user.rewardPaid = user.shares.mul(cakeTokenReward.accPerShare).div(1e12);
    }

    function isContract(address account) public view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function migrateCakeRewardsPool(uint256 fromId, uint toId) public onlyDev {
        PoolInfo storage fromPool = poolInfo[fromId];
        PoolInfo storage toPool = poolInfo[toId];
        (uint256 wantAmt,,) = IPineconeStrategy(fromPool.strat).withdrawAll(address(this));
        _safeApprove(address(toPool.want), toPool.strat);
        IPineconeStrategy(toPool.strat).deposit(wantAmt, address(this));
        cakeRewardsStakingPid = toId;
    }

    function _safeApprove(address token, address spender) internal {
        if (token != address(0) && IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).safeApprove(spender, uint256(~0));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Context.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol";

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
    constructor(string memory name_, string memory symbol_) public {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
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

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Address.sol";
import "../interfaces/IERC20.sol";

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "!safeTransferETH");
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

enum StakeType {
    None,
    Alpaca_Wex,
    Cake_Wex,
    RewardsCake_Wex,
    PCTPair,
    Rabbit_Mdex,
    Cake_Mdex,
    RewardsCake_Mdex
}

interface IPineconeFarm {
    function add(uint256 _allocPCTPoint, address _want, bool _withUpdate, address _strat) external returns(uint256);
    function set(uint256 _pid, uint256 _allocPCTPoint, bool _withUpdate) external;
    function setMinter(address _minter, bool _canMint) external;
    function mintForProfit(address _to, uint256 _cakeProfit, bool _updatePCTRewards) external returns(uint256);
    function stakeRewardsTo(address _to, uint256 _amount) external;
    function setCakeRewardsPid(uint256 _cakeRewardsPid) external;
    function setPctPerBlock(uint256 _PCTPerBlock, uint256 _startBlock) external;
    function amountPctToMint(uint256 _bnbProfit) external view returns (uint256);
    function inCaseTokensGetStuck(address _token, uint256 _amount) external;
    function dailyEarnedAmount(uint256 _pid) external view returns(uint256);
    function pineconeStratAddress(uint256 _pid) external view returns(address);
    function poolInfoOf(uint256 _pid) external view returns(address want, address strat);
    function userInfoOfPool(uint256 _pid, address _user) external view 
        returns(
            uint256 depositedAt, 
            uint256 depositAmt,
            uint256 balanceValue,
            uint256 earned0Amt,
            uint256 earned1Amt,
            uint256 withdrawbaleAmt
        ); 
    function claimBNB() external;
}

interface IPineconeStrategy {
    function earn() external;
    function farm() external;
    function pause() external;
    function unpause() external;
    function sharesTotal() external view returns (uint256);
    function sharesOf(address _user) external view returns(uint256);
    function withdrawableBalanceOf(address _user) external view returns(uint256);
    function deposit(uint256 _wantAmt, address _user) external returns(uint256);
    function depositForPresale(uint256 _wantAmt, address _user) external returns(uint256);
    function withdraw(uint256 _wantAmt, address _user) external returns(uint256, uint256);
    function withdrawAll(address _user) external returns(uint256, uint256, uint256);
    function claim(address _user) external returns(uint256, uint256);
    function claimBNB(uint256 shares, address _user) external returns(uint256);
    function pendingBNB(uint256 _shares, address _user) external view returns(uint256);
    function stakeType() external view returns(StakeType);
    function earned0Address() external view returns(address);
    function earned1Address() external view returns(address);
    function performanceFee(uint256 _profit) external view returns(uint256);
    function stratAddress() external view returns(address);
    function tvl() external view returns(uint256 priceInUsd);
    function farmPid() external view returns(uint256);
    function userInfoOf(address _user, uint256 _addPct) external view 
        returns(
            uint256 depositedAt, 
            uint256 depositAmt,
            uint256 balanceValue,
            uint256 earned0Amt,
            uint256 earned1Amt,
            uint256 withdrawbaleAmt
        ); 
    function inCaseTokensGetStuck(address _token, uint256 _amount) external;
    function stakingToken() external view returns(address);
    function setWithdrawFeeFactor(uint256 _withdrawFeeFactor) external;
}

interface IOwner {
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IPineconeToken {
    function mint(address _to, uint256 _amount) external;
    function mintAvailable() external view returns(bool);
    function pctPair() external view returns(address);
    function isMinter(address _addr) external view returns(bool);
    function addPresaleUser(address _account) external;
    function maxTxAmount() external view returns(uint256);
    function isExcludedFromFee(address _account) external view returns(bool);
    function isPresaleUser(address _account) external view returns(bool);
}

interface IPineconeTokenCallee {
    function transferCallee(address from, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
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

pragma solidity ^0.6.12;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol";
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

