// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import './SafeMath.sol';
import './IERC20.sol';
import './ERC20.sol';
import './Address.sol';
import './SafeERC20.sol';
import './EnumerableSet.sol';
import './Context.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';

abstract contract GuruTOKEN is ERC20 {
    function mint(address _to, uint256 _amount) public virtual;
}

// For interacting with our own strategy
interface IStrategy {
    // Total want tokens managed by stratfegy
    function wantLockedTotal() external view returns (uint256);

    // Sum of all shares of users to wantLockedTotal
    function sharesTotal() external view returns (uint256);

    // Main want token compounding function
    function earn() external;

    // Transfer want tokens GuruFarm -> strategy
    function deposit(address _userAddress, uint256 _wantAmt)
        external
        returns (uint256);

    // Transfer want tokens strategy -> GuruFarm
    function withdraw(address _userAddress, uint256 _wantAmt)
        external
        returns (uint256);

     // Transfer Guru GuruFarm -> strategy//fhxg
    function  enterStakingGuru(address _userAddress, uint256 _wantAmt)
        external
        returns (uint256);

     // Transfer Guru strategy -> GuruFarm
    function  leaveStakingGuru(address _userAddress, uint256 _wantAmt)
        external
        returns (uint256);

}

contract BitGuruFarm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 shares; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 bonusDebt; // bonus debt. //fhxg
        uint256 lastDepositBlock; // Last block number that Deposit  occurs.



        // We do some fancy math here. Basically, any point in time, the amount of Guru
        // entitled to a user but is pending to be distributed is:
        //
        //   amount = user.shares / sharesTotal * wantLockedTotal
        //   pending reward = (amount * pool.accGuruPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws want tokens to a pool. Here's what happens:
        //   1. The pool's `accGuruPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    struct lstUserInfo {
        address addr;
        address aff;//ref
    }

    struct PoolInfo {
        IERC20 want; // Address of the want token.
        uint256 allocPoint; // How many allocation points assigned to this pool. Guru to distribute per block.
        uint256 lastRewardBlock; // Last block number that Guru distribution occurs.
        uint256 accGuruPerShare; // Accumulated Guru per share, times 1e12.
        address strat; // Strategy address that will Guru compound want tokens
    }


    address public constant Guru =    0x6d88d72DdC4FF139aC3b45Fc13242C3c3709F68D;// Guru2Addr

    address public bonusToken = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;//wmatic;


    uint256 public accBonus = 0; // Accumulated  bonus
    uint256 public accAllBonus = 0; // Accumulated  bonus,all.
    uint256 public accBonusPerShare = 0; // Accumulated  bonus pershare in Guru pool
    uint256 public pidBonus = 0; // Accumulated  bonus pershare in Guru pool,




    address public constant buyBackAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public constant ownerGuruReward = 191; // 16%

    uint256 public constant GuruMaxSupply = 880000e18;
    uint256 public GuruPerBlock = 80000000000000000; // Guru tokens created per block
    uint256 public startBlock = 15330618;
    uint256 public halfBlockNum = 4266666 ;


    uint256 public affFactor = 1e17;

   // PoolInfo[] public poolInfo; // Info of each pool.
    uint256 public nPoolId = 0;
    mapping(uint256 => PoolInfo) public poolInfo; //Info of each pool

    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // Info of each user that stakes LP tokens.

    uint256 public uID_ = 0; //ref
    mapping (address => uint256) public uIDxAddr_;
    mapping (uint256 => lstUserInfo) public userInfolst;//ref


    uint256 public totalAllocPoint = 0; // Total allocation points. Must be the sum of all allocation points in all pools.

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event evententerStakingGuru(address indexed user, uint256 indexed pid, uint256 amount);
    event eventleaveStakingGuru(address indexed user, uint256 indexed pid, uint256 amount);

    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );



    //ref
    function determineUID(address _addr,address _aff)
        private
        returns (bool)
    {


        if (uIDxAddr_[_addr] == 0)
        {
            require(_aff != address(0), "zero address");
            uID_++;
            uIDxAddr_[_addr] = uID_;
            userInfolst[uID_].addr = _addr;
            userInfolst[uID_].aff = _aff;

            // set the new player bool to true
            return (true);
        } else {
            return (false);
        }
    }
     function getuID(address _addr)
        public
        returns (uint256)
    {
        return (uIDxAddr_[_addr]);
    }

    function getUserAff(uint256 _uID)
        public
        returns (address)
    {
        return (userInfolst[_uID].aff);
    }
    function getUserAddr(uint256 _uID)
        public
        returns (address)
    {
        return (userInfolst[_uID].addr);
    }
    //ref----


    function poolLength() external view returns (uint256) {

        return nPoolId;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do. (Only if want tokens are stored here.)
    function add(
        uint256 _allocPoint,
        IERC20 _want,
        bool _withUpdate,
        address _strat
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        PoolInfo storage pool = poolInfo[nPoolId];
        pool.want = _want;
        pool.allocPoint = _allocPoint;
        pool.lastRewardBlock = lastRewardBlock;
        pool.accGuruPerShare = 0;
        pool.strat = _strat;
        nPoolId++;

    }

    // Update the given pool's Guru allocation point. Can only be called by the owner.
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

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (IERC20(Guru).totalSupply() >= GuruMaxSupply) {
            return 0;
        }
        return _to.sub(_from);
    }

    // View function to see pending Guru on frontend.
    function pendingGuru(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGuruPerShare = pool.accGuruPerShare;
        uint256 sharesTotal = IStrategy(pool.strat).sharesTotal();
        if (block.number > pool.lastRewardBlock && sharesTotal != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 GuruReward =
                multiplier.mul(GuruPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accGuruPerShare = accGuruPerShare.add(
                GuruReward.mul(1e12).div(sharesTotal)
            );
        }
        return user.shares.mul(accGuruPerShare).div(1e12).sub(user.rewardDebt);
    }

    // View function to see staked Want tokens on frontend.
    function stakedWantTokens(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 sharesTotal = IStrategy(pool.strat).sharesTotal();
        uint256 wantLockedTotal =
            IStrategy(poolInfo[_pid].strat).wantLockedTotal();
        if (sharesTotal == 0) {
            return 0;
        }
        return user.shares.mul(wantLockedTotal).div(sharesTotal);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = nPoolId;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        if (block.number <= pool.lastRewardBlock || pool.allocPoint == 0)
        {
            return;
        }
        uint256 sharesTotal = IStrategy(pool.strat).sharesTotal();
        if (sharesTotal == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        if (multiplier <= 0) {
            return;
        }
        uint256 GuruReward =
            multiplier.mul(GuruPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );

         GuruTOKEN(Guru).mint(
             owner(),
             GuruReward.mul(ownerGuruReward).div(1000)
         );
         GuruTOKEN(Guru).mint(address(this), GuruReward);

        pool.accGuruPerShare = pool.accGuruPerShare.add(
            GuruReward.mul(1e12).div(sharesTotal)
        );
        pool.lastRewardBlock = block.number;
    }

    // Want tokens moved from user -> GuruFarm (Guru allocation) -> Strat (compounding)
    function deposit(uint256 _pid, uint256 _wantAmt,address _aff) public nonReentrant {


        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.want != IERC20(Guru), "!safe");
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.shares > 0) {
            uint256 pending =
                user.shares.mul(pool.accGuruPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            if (pending > 0) {
                //ref
                address userlstaff = getUserAff(getuID(msg.sender));
                if( IERC20(Guru).balanceOf(address(userlstaff))>affFactor )
                {
                    safeGuruTransfer(userlstaff, pending.div(10));
                }
                else
                {
                    safeGuruTransfer(buyBackAddress, pending.div(10));
                }


                //ref--
                safeGuruTransfer(msg.sender, pending.mul(9).div(10));
            }
        }
        if (_wantAmt > 0) {
            uint256 balBefore = pool.want.balanceOf(address(this));
            pool.want.safeTransferFrom(
                address(msg.sender),
                address(this),
                _wantAmt
            );
            _wantAmt  = pool.want.balanceOf(address(this)).sub(balBefore);


            pool.want.safeIncreaseAllowance(pool.strat, _wantAmt);
            uint256 sharesAdded =
                IStrategy(poolInfo[_pid].strat).deposit(msg.sender, _wantAmt);
            user.shares = user.shares.add(sharesAdded);
            determineUID(msg.sender,_aff);
            user.lastDepositBlock =  block.number;

        }
        user.rewardDebt = user.shares.mul(pool.accGuruPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _wantAmt);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _wantAmt) public nonReentrant {

        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        require(pool.want != IERC20(Guru), "!safe");
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 wantLockedTotal =
            IStrategy(poolInfo[_pid].strat).wantLockedTotal();
        uint256 sharesTotal = IStrategy(poolInfo[_pid].strat).sharesTotal();

        require(user.shares > 0, "user.shares is 0");
        require(sharesTotal > 0, "sharesTotal is 0");

        // Withdraw pending Guru
        uint256 pending =
            user.shares.mul(pool.accGuruPerShare).div(1e12).sub(
                user.rewardDebt
            );
        if (pending > 0) {
             //ref
             address userlstaff = getUserAff(getuID(msg.sender));
               if( IERC20(Guru).balanceOf(address(userlstaff))>affFactor)
                {
                    safeGuruTransfer(userlstaff, pending.div(10));
                }
                else
                {
                    safeGuruTransfer(buyBackAddress, pending.div(10));
                }
             safeGuruTransfer(msg.sender, pending.mul(9).div(10));
             //ref--
        }

        // Withdraw want tokens
        uint256 amount = user.shares.mul(wantLockedTotal).div(sharesTotal);
        if (_wantAmt > amount) {
            _wantAmt = amount;
        }
        if (_wantAmt > 0) {
            uint256 sharesRemoved =
                IStrategy(poolInfo[_pid].strat).withdraw(msg.sender, _wantAmt);

            if (sharesRemoved > user.shares) {
                user.shares = 0;
            } else {
                user.shares = user.shares.sub(sharesRemoved);
            }

            uint256 wantBal = IERC20(pool.want).balanceOf(address(this));
            if (wantBal < _wantAmt) {
                _wantAmt = wantBal;
            }
            pool.want.safeTransfer(address(msg.sender), _wantAmt);
        }
        user.rewardDebt = user.shares.mul(pool.accGuruPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _wantAmt);
    }




    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 wantLockedTotal =
            IStrategy(poolInfo[_pid].strat).wantLockedTotal();
        uint256 sharesTotal = IStrategy(poolInfo[_pid].strat).sharesTotal();
        uint256 amount = user.shares.mul(wantLockedTotal).div(sharesTotal);

        IStrategy(poolInfo[_pid].strat).withdraw(msg.sender, amount);

        uint256 wantBal = IERC20(pool.want).balanceOf(address(this));
        if (wantBal < amount) {
                amount = wantBal;
            }

        pool.want.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
        user.shares = 0;
        user.rewardDebt = 0;
        user.bonusDebt = 0;
    }
    // Safe Guru transfer function, just in case if rounding error causes pool to not have enough
    function safeGuruTransfer(address _to, uint256 _GuruAmt) internal {
        uint256 GuruBal = IERC20(Guru).balanceOf(address(this));
        if (_GuruAmt > GuruBal) {
            IERC20(Guru).transfer(_to, GuruBal);
        } else {
            IERC20(Guru).transfer(_to, _GuruAmt);
        }
    }



     function setAccBonus(uint256 _pid,uint256 _bonusAmt) public nonReentrant
     {
        PoolInfo storage poolCall = poolInfo[_pid];
        require(msg.sender == poolCall.strat, "!bonusAddress");
        accBonus = accBonus.add(_bonusAmt);
        accAllBonus = accAllBonus.add(_bonusAmt);

        if(block.number>startBlock+halfBlockNum.mul(9))
        {
            GuruPerBlock = 156250000000000;
        }
        else if(block.number>startBlock+halfBlockNum.mul(8))
        {
            GuruPerBlock = 312500000000000;
        }
        else if(block.number>startBlock+halfBlockNum.mul(7))
        {
            GuruPerBlock = 625000000000000;
        }
        else if(block.number>startBlock+halfBlockNum.mul(6))
        {
            GuruPerBlock = 1250000000000000;
        }
        else if(block.number>startBlock+halfBlockNum.mul(5))
        {
            GuruPerBlock = 2500000000000000;
        }
        else if(block.number>startBlock+halfBlockNum.mul(4))
        {
            GuruPerBlock = 5000000000000000;
        }
         else if(block.number>startBlock+halfBlockNum.mul(3))
        {
            GuruPerBlock = 10000000000000000;
        }
         else if(block.number>startBlock+halfBlockNum.mul(2))
        {
            GuruPerBlock = 20000000000000000;
        }
        else if(block.number>startBlock+halfBlockNum)
        {
            GuruPerBlock = 40000000000000000;
        }


        uint256 sharesTotal = IStrategy(poolInfo[pidBonus].strat).sharesTotal();
        if (sharesTotal == 0) {
            return;
        }
        accBonusPerShare = accBonusPerShare.add(accBonus.mul(1e12).div(sharesTotal));
        accBonus = 0;
     }
     function GetLastDepositBlock (uint256 _pid,address _user)  external
        view
        returns (uint256)
     {

        PoolInfo storage poolCall = poolInfo[_pid];


        if (poolCall.strat == msg.sender)
        {
            UserInfo storage user = userInfo[_pid][_user];
            return user.lastDepositBlock;
        }

        return 0;



     }



      function clsAccBonus() external onlyOwner
     {

        accAllBonus = 0; //when bonusToken changed
        accBonus = 0;
        accBonusPerShare = 0;

     }
     function setbonusPid(
       uint256 _pid
    ) external  onlyOwner {

       pidBonus = _pid;

    }
     function setbonusToken(
        address _token
    ) external onlyOwner {
        require(_token != Guru);
        bonusToken = _token;
    }
    function setAffFactor(
       uint256 _factor
    ) external  onlyOwner {

       affFactor = _factor;

    }
     // View function to see pending Bonus on frontend.
    function pendingBonus(address _user)
        external
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[pidBonus][_user];
        uint256  pending = user.shares.mul(accBonusPerShare).div(1e12).sub(user.bonusDebt);
        if(pending>0){
          uint256 balAmt = IERC20(bonusToken).balanceOf(address(this));
          if (pending > balAmt) {
                    pending = balAmt;
                }

        }

        return pending;
    }

    function enterStakingGuru(uint256 _pid, uint256 _wantAmt,address _aff) external nonReentrant {
        //updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.want == IERC20(Guru), "!safe");
        UserInfo storage user = userInfo[_pid][msg.sender];



        uint256  pending = user.shares.mul(accBonusPerShare).div(1e12).sub(user.bonusDebt);
        if(pending>0){
          uint256 balAmt = IERC20(bonusToken).balanceOf(address(this));
          if (pending > balAmt) {
                    pending = balAmt;
                }
          IERC20(bonusToken).safeTransfer(address(msg.sender), pending);
        }




        if (_wantAmt > 0) {
            uint256 balBefore = pool.want.balanceOf(address(this));
            pool.want.safeTransferFrom(
                address(msg.sender),
                address(this),
                _wantAmt
            );
            _wantAmt  = pool.want.balanceOf(address(this)).sub(balBefore);

            pool.want.safeIncreaseAllowance(pool.strat, _wantAmt);
            uint256 sharesAdded =
                IStrategy(poolInfo[_pid].strat).deposit(msg.sender, _wantAmt);
            user.shares = user.shares.add(sharesAdded);

            determineUID(msg.sender,_aff);
            user.lastDepositBlock =  block.number;
        }
        user.bonusDebt = user.shares.mul(accBonusPerShare).div(1e12);
        emit evententerStakingGuru(msg.sender, _pid, _wantAmt);
    }


    function leaveStakingGuru(uint256 _pid, uint256 _wantAmt) external nonReentrant {
        //updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        require(pool.want == IERC20(Guru), "!safe");
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 wantLockedTotal =
            IStrategy(poolInfo[_pid].strat).wantLockedTotal();
        uint256 sharesTotal = IStrategy(poolInfo[_pid].strat).sharesTotal();

        require(user.shares > 0, "user.shares is 0");
        require(sharesTotal > 0, "sharesTotal is 0");

        uint256  pending = user.shares.mul(accBonusPerShare).div(1e12).sub(user.bonusDebt);

        if(pending>0){
          uint256 balAmt = IERC20(bonusToken).balanceOf(address(this));
          if (pending > balAmt) {
                    pending = balAmt;
                }
          IERC20(bonusToken).safeTransfer(address(msg.sender), pending);
        }

        // Withdraw want tokens
        uint256 amount = user.shares.mul(wantLockedTotal).div(sharesTotal);
        if (_wantAmt > amount) {
            _wantAmt = amount;
        }
        if (_wantAmt > 0) {
            uint256 sharesRemoved =
                IStrategy(poolInfo[_pid].strat).withdraw(msg.sender, _wantAmt);

            if (sharesRemoved > user.shares) {
                user.shares = 0;
            } else {
                user.shares = user.shares.sub(sharesRemoved);
            }

            uint256 wantBal = IERC20(pool.want).balanceOf(address(this));
            if (wantBal < _wantAmt) {
                _wantAmt = wantBal;
            }
            pool.want.safeTransfer(address(msg.sender), _wantAmt);
        }
        user.bonusDebt = user.shares.mul(accBonusPerShare).div(1e12);
        emit eventleaveStakingGuru(msg.sender, _pid, _wantAmt);
    }
}