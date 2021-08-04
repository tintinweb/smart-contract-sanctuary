// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";

// Inheritancea
interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewards(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

abstract contract RewardsDistributionRecipient {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) virtual external;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }
}

contract StakingRewards is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuardUpgradeSafe {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;                  // obsoleted
    uint256 public rewardsDuration = 60 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) override public rewards;

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;

    /* ========== CONSTRUCTOR ========== */

    //constructor(
    function __StakingRewards_init(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) public virtual initializer {
        __ReentrancyGuard_init_unchained();
        __StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
    }

    function __StakingRewards_init_unchained(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) public virtual initializer {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== VIEWS ========== */

    function totalSupply() virtual override public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) virtual override public view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() override public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() virtual override public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) virtual override public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() virtual override external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) virtual public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        // permit
        IPermit(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function stake(uint256 amount) virtual override public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) virtual override public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() virtual override public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() virtual override public {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) override external onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) virtual {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}

interface IPermit {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

contract StakingPool is Configurable, StakingRewards {
    using Address for address payable;
    
    bytes32 internal constant _ecoAddr_         = 'ecoAddr';
    bytes32 internal constant _ecoRatio_        = 'ecoRatio';
	bytes32 internal constant _allowContract_   = 'allowContract';
	bytes32 internal constant _allowlist_       = 'allowlist';
	bytes32 internal constant _blocklist_       = 'blocklist';
	
	bytes32 internal constant _rewards2Token_   = 'rewards2Token';
	bytes32 internal constant _rewards2Ratio_   = 'rewards2Ratio';
	//bytes32 internal constant _rewards2Span_    = 'rewards2Span';
	bytes32 internal constant _rewards2Begin_   = 'rewards2Begin';

	uint public lep;            // 1: linear, 2: exponential, 3: power
	//uint public period;         // obsolete
	uint public begin;

    mapping (address => uint256) public paid;
    
    address swapFactory;
    address[] pathTVL;
    address[] pathAPY;

    function __StakingPool_init(address _governor, 
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        address _ecoAddr
    ) public virtual initializer {
	    __ReentrancyGuard_init_unchained();
	    __Governable_init_unchained(_governor);
        //__StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
        __StakingPool_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken, _ecoAddr);
    }

    function __StakingPool_init_unchained(address _rewardsDistribution, address _rewardsToken, address _stakingToken, address _ecoAddr) public virtual governance {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        config[_ecoAddr_] = uint(_ecoAddr);
        config[_ecoRatio_] = 0.1 ether;
    }

    function notifyRewardBegin(uint _lep, /*uint _period,*/ uint _span, uint _begin) virtual public governance updateReward(address(0)) {
        lep             = _lep;         // 1: linear, 2: exponential, 3: power
        //period          = _period;
        rewardsDuration = _span;
        begin           = _begin;
        periodFinish    = _begin.add(_span);
    }
    
    function notifyReward2(address _rewards2Token, uint _ratio, /*uint _span,*/ uint _begin) virtual external governance updateReward(address(0)) {
        config[_rewards2Token_] = uint(_rewards2Token);
        config[_rewards2Ratio_] = _ratio;
        //config[_rewards2Span_]  = _span;
        config[_rewards2Begin_] = _begin;
    }

    function rewardDelta() public view returns (uint amt) {
        if(begin == 0 || begin >= now || lastUpdateTime >= now)
            return 0;
            
        amt = Math.min(rewardsToken.allowance(rewardsDistribution, address(this)), rewardsToken.balanceOf(rewardsDistribution)).sub0(rewards[address(0)]);
        
        // calc rewardDelta in period
        if(lep == 3) {                                                              // power
            //uint y = period.mul(1 ether).div(lastUpdateTime.add(rewardsDuration).sub(begin));
            //uint amt1 = amt.mul(1 ether).div(y);
            //uint amt2 = amt1.mul(period).div(now.add(rewardsDuration).sub(begin));
            uint amt2 = amt.mul(lastUpdateTime.add(rewardsDuration).sub(begin)).div(now.add(rewardsDuration).sub(begin));
            amt = amt.sub(amt2);
        } else if(lep == 2) {                                                       // exponential
            if(now.sub(lastUpdateTime) < rewardsDuration)
                amt = amt.mul(now.sub(lastUpdateTime)).div(rewardsDuration);
        }else if(now < periodFinish)                                                // linear
            amt = amt.mul(now.sub(lastUpdateTime)).div(periodFinish.sub(lastUpdateTime));
        else if(lastUpdateTime >= periodFinish)
            amt = 0;
            
        if(config[_ecoAddr_] != 0)
            amt = amt.mul(uint(1e18).sub(config[_ecoRatio_])).div(1 ether);
    }
    
    function rewardPerToken() virtual override public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                rewardDelta().mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) virtual override public view returns (uint256) {
        return Math.min(Math.min(super.earned(account), rewardsToken.allowance(rewardsDistribution, address(this))), rewardsToken.balanceOf(rewardsDistribution));
	}    
	
    modifier updateReward(address account) override {
        rewardPerTokenStored = rewardPerToken();
        uint delta = rewardDelta();
        {
            address addr = address(config[_ecoAddr_]);
            uint ratio = config[_ecoRatio_];
            if(addr != address(0) && ratio != 0) {
                uint d = delta.mul(ratio).div(uint(1e18).sub(ratio));
                rewards[addr] = rewards[addr].add(d);
                delta = delta.add(d);
            }
        }
        rewards[address(0)] = rewards[address(0)].add(delta);
        lastUpdateTime = now;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function getReward() virtual override public {
        getRewardA(msg.sender);
    }
    function getRewardA(address payable acct) virtual public nonReentrant updateReward(acct) {
        require(getConfigA(_blocklist_, acct) == 0, 'In blocklist');
        bool isContract = acct.isContract();
        require(!isContract || config[_allowContract_] != 0 || getConfigA(_allowlist_, acct) != 0, 'No allowContract');

        uint256 reward = rewards[acct];
        if (reward > 0) {
            rewards[acct] = 0;
            rewards[address(0)] = rewards[address(0)].sub0(reward);
            rewardsToken.safeTransferFrom(rewardsDistribution, acct, reward);
            emit RewardPaid(acct, reward);
            
            if(config[_rewards2Token_] != 0 && config[_rewards2Begin_] <= now) {
                uint reward2 = Math.min(reward.mul(config[_rewards2Ratio_]).div(1e18), IERC20(config[_rewards2Token_]).balanceOf(address(this)));
                IERC20(config[_rewards2Token_]).safeTransfer(acct, reward2);
                emit RewardPaid2(acct, reward2);
            }
        }
    }
    event RewardPaid2(address indexed user, uint256 reward2);

    //function compound() virtual public nonReentrant updateReward(msg.sender) {      // only for pool3
    //    require(getConfigA(_blocklist_, msg.sender) == 0, 'In blocklist');
    //    bool isContract = msg.sender.isContract();
    //    require(!isContract || config[_allowContract_] != 0 || getConfigA(_allowlist_, msg.sender) != 0, 'No allowContract');
    //    require(stakingToken == rewardsToken, 'not pool3');
    //
    //    uint reward = rewards[msg.sender];
    //    if (reward > 0) {
    //        rewards[msg.sender] = 0;
    //        rewards[address(0)] = rewards[address(0)].sub0(reward);
    //        rewardsToken.safeTransferFrom(rewardsDistribution, address(this), reward);
    //        emit RewardPaid(msg.sender, reward);
    //        
    //        _totalSupply = _totalSupply.add(reward);
    //        _balances[msg.sender] = _balances[msg.sender].add(reward);
    //        emit Staked(msg.sender, reward);
    //    }
    //}

    function getRewardForDuration() override external view returns (uint256) {
        return rewardsToken.allowance(rewardsDistribution, address(this)).sub0(rewards[address(0)]);
    }
    
    function rewards2Token() virtual external view returns (address) {
        return address(config[_rewards2Token_]);
    }
    
    function rewards2Ratio() virtual external view returns (uint) {
        return config[_rewards2Ratio_];
    }
    
    function setPath(address swapFactory_, address[] memory pathTVL_, address[] memory pathAPY_) virtual external governance {
        uint m = pathTVL_.length;
        uint n = pathAPY_.length;
        require(m > 0 && n > 0 && pathTVL_[m-1] == pathAPY_[n-1]);
        for(uint i=0; i<m-1; i++)
            require(address(0) != IUniswapV2Factory(swapFactory_).getPair(pathTVL_[i], pathTVL_[i+1]));
        for(uint i=0; i<n-1; i++)
            require(address(0) != IUniswapV2Factory(swapFactory_).getPair(pathAPY_[i], pathAPY_[i+1]));
            
        swapFactory = swapFactory_;
        pathTVL = pathTVL_;
        pathAPY = pathAPY_;
    }
    
    function lptValueTotal() virtual public view returns (uint) {
        require(pathTVL.length > 0 && pathTVL[0] != address(stakingToken));
        return IERC20(pathTVL[0]).balanceOf(address(stakingToken)).mul(2);
    }
    
    function lptValue(uint vol) virtual public view returns (uint) {
        return lptValueTotal().mul(vol).div(IERC20(stakingToken).totalSupply());
    }
    
    function swapValue(uint vol, address[] memory path) virtual public view returns (uint v) {
        v = vol;
        for(uint i=0; i<path.length-1; i++) {
            (uint reserve0, uint reserve1,) = IUniswapV2Pair(IUniswapV2Factory(swapFactory).getPair(path[i], path[i+1])).getReserves();
            v =  path[i+1] < path[i] ? v.mul(reserve0) / reserve1 : v.mul(reserve1) / reserve0;
        }
    }
    
    function TVL() virtual public view returns (uint tvl) {
        if(pathTVL[0] != address(stakingToken))
            tvl = lptValueTotal();
        else
            tvl = totalSupply();
        tvl = swapValue(tvl, pathTVL);
    }
    
    function APY() virtual public view returns (uint) {
        uint amt = rewardsToken.allowance(rewardsDistribution, address(this)).sub0(rewards[address(0)]);
        
        if(lep == 3) {                                                              // power
            uint amt2 = amt.mul(365 days).mul(now.add(rewardsDuration).sub(begin)).div(now.add(1).add(rewardsDuration).sub(begin));
            amt = amt.sub(amt2);
        } else if(lep == 2) {                                                       // exponential
            amt = amt.mul(365 days).div(rewardsDuration);
        }else if(now < periodFinish)                                                // linear
            amt = amt.mul(365 days).div(periodFinish.sub(lastUpdateTime));
        else if(lastUpdateTime >= periodFinish)
            amt = 0;
        
        require(address(rewardsToken) == pathAPY[0]);
        amt = swapValue(amt, pathAPY);
        return amt.mul(1e18).div(TVL());
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract EthPool is StakingPool {
    bytes32 internal constant _WETH_			= 'WETH';

    function __EthPool_init(address _governor, 
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        address _ecoAddr,
		address _WETH
    ) public virtual initializer {
	    __ReentrancyGuard_init_unchained();
	    __Governable_init_unchained(_governor);
        //__StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
        __StakingPool_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken, _ecoAddr);
		__EthPool_init_unchained(_WETH);
    }

    function __EthPool_init_unchained(address _WETH) public virtual governance {
        config[_WETH_] = uint(_WETH);
    }

    function stakeEth() virtual public payable nonReentrant updateReward(msg.sender) {
        require(address(stakingToken) == address(config[_WETH_]), 'stakingToken is not WETH');
        uint amount = msg.value;
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        IWETH(address(stakingToken)).deposit{value: amount}();                   //stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdrawEth(uint256 amount) virtual public nonReentrant updateReward(msg.sender) {
        require(address(stakingToken) == address(config[_WETH_]), 'stakingToken is not WETH');
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        IWETH(address(stakingToken)).withdraw(amount);                           //stakingToken.safeTransfer(msg.sender, amount);
        msg.sender.transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exitEth() virtual public {
        withdrawEth(_balances[msg.sender]);
        getReward();
    }
    
    receive () payable external {
        stakeEth();
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

contract DoublePool is StakingPool {
    IStakingRewards public stakingPool2;
    IERC20 public rewardsToken2;
    //uint256 public lastUpdateTime2;                                 // obsoleted
    //uint256 public rewardPerTokenStored2;                           // obsoleted
    mapping(address => uint256) public userRewardPerTokenPaid2;
    mapping(address => uint256) public rewards2;

    function __DoublePool_init(address _governor, address _rewardsDistribution, address _rewardsToken, address _stakingToken, address _ecoAddr, address _stakingPool2, address _rewardsToken2) public initializer {
	    __ReentrancyGuard_init_unchained();
	    __Governable_init_unchained(_governor);
	    //__StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
	    __StakingPool_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken, _ecoAddr);
	    __DoublePool_init_unchained(_stakingPool2, _rewardsToken2);
	}
    
    function __DoublePool_init_unchained(address _stakingPool2, address _rewardsToken2) public governance {
	    stakingPool2 = IStakingRewards(_stakingPool2);
	    rewardsToken2 = IERC20(_rewardsToken2);
	}
    
    function notifyRewardBegin(uint _lep, /*uint _period,*/ uint _span, uint _begin) virtual override public governance updateReward2(address(0)) {
        super.notifyRewardBegin(_lep, /*_period,*/ _span, _begin);
    }
    
    function stake(uint amount) virtual override public updateReward2(msg.sender) {
        super.stake(amount);
        stakingToken.safeApprove(address(stakingPool2), amount);
        stakingPool2.stake(amount);
    }

    function withdraw(uint amount) virtual override public updateReward2(msg.sender) {
        stakingPool2.withdraw(amount);
        super.withdraw(amount);
    }
    
    function getReward2() virtual public nonReentrant updateReward2(msg.sender) {
        uint256 reward2 = rewards2[msg.sender];
        if (reward2 > 0) {
            rewards2[msg.sender] = 0;
            stakingPool2.getReward();
            rewardsToken2.safeTransfer(msg.sender, reward2);
            emit RewardPaid2(msg.sender, reward2);
        }
    }
    event RewardPaid2(address indexed user, uint256 reward2);

    function getDoubleReward() virtual public {
        getReward();
        getReward2();
    }
    
    function exit() override public {
        super.exit();
        getReward2();
    }
    
    function rewardPerToken2() virtual public view returns (uint256) {
        return stakingPool2.rewardPerToken();
    }

    function earned2(address account) virtual public view returns (uint256) {
        return _balances[account].mul(rewardPerToken2().sub(userRewardPerTokenPaid2[account])).div(1e18).add(rewards2[account]);
    }

    modifier updateReward2(address account) virtual {
        if (account != address(0)) {
            rewards2[account] = earned2(account);
            userRewardPerTokenPaid2[account] = rewardPerToken2();
        }
        _;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}


interface IMasterChef {
    function poolInfo(uint pid) external view returns (address lpToken, uint allocPoint, uint lastRewardBlock, uint accCakePerShare);
    function userInfo(uint pid, address user) external view returns (uint amount, uint rewardDebt);
    function pending(uint pid, address user) external view returns (uint);
    function pendingCake(uint pid, address user) external view returns (uint);
    function deposit(uint pid, uint amount) external;
    function withdraw(uint pid, uint amount) external;
}

contract NestMasterChef is StakingPool {
    IERC20 internal constant Cake = IERC20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    
    IMasterChef public stakingPool2;
    IERC20 public rewardsToken2;
    mapping(address => uint256) public userRewardPerTokenPaid2;
    mapping(address => uint256) public rewards2;
    uint public pid2;
    uint internal _rewardPerToken2;

    function __NestMasterChef_init(address _governor, address _rewardsDistribution, address _rewardsToken, address _stakingToken, address _ecoAddr, address _stakingPool2, address _rewardsToken2, uint _pid2) public initializer {
	    __Governable_init_unchained(_governor);
        __ReentrancyGuard_init_unchained();
        //__StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
        __StakingPool_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken, _ecoAddr);
        __NestMasterChef_init_unchained(_stakingPool2, _rewardsToken2, _pid2);
	}

    function __NestMasterChef_init_unchained(address _stakingPool2, address _rewardsToken2, uint _pid2) public governance {
	    stakingPool2 = IMasterChef(_stakingPool2);
	    rewardsToken2 = IERC20(_rewardsToken2);
	    pid2 = _pid2;
    }
    
    function notifyRewardBegin(uint _lep, /*uint _period,*/ uint _span, uint _begin) virtual override public governance updateReward2(address(0)) {
        super.notifyRewardBegin(_lep, /*_period,*/ _span, _begin);
    }
    
    function migrate() virtual public governance updateReward2(address(0)) {
        uint total = stakingToken.balanceOf(address(this));
        stakingToken.approve(address(stakingPool2), total);
        stakingPool2.deposit(pid2, total);
    }        
    
    function stake(uint amount) virtual override public updateReward2(msg.sender) {
        super.stake(amount);
        stakingToken.approve(address(stakingPool2), amount);
        stakingPool2.deposit(pid2, amount);
    }

    function withdraw(uint amount) virtual override public updateReward2(msg.sender) {
        stakingPool2.withdraw(pid2, amount);
        super.withdraw(amount);
    }
    
    function getReward2() virtual public nonReentrant updateReward2(msg.sender) {
        uint256 reward2 = rewards2[msg.sender];
        if (reward2 > 0) {
            rewards2[msg.sender] = 0;
            rewardsToken2.safeTransfer(msg.sender, reward2);
            emit RewardPaid2(msg.sender, reward2);
        }
    }
    event RewardPaid2(address indexed user, uint256 reward2);

    function getDoubleReward() virtual public {
        getReward();
        getReward2();
    }
    
    function exit() virtual override public {
        super.exit();
        getReward2();
    }
    
    function rewardPerToken2() virtual public view returns (uint256) {
        if(_totalSupply == 0)
            return _rewardPerToken2;
        else if(rewardsToken2 == Cake)
            return stakingPool2.pendingCake(pid2, address(this)).mul(1e18).div(_totalSupply).add(_rewardPerToken2);
        else
            return stakingPool2.pending(pid2, address(this)).mul(1e18).div(_totalSupply).add(_rewardPerToken2);
    }

    function earned2(address account) virtual public view returns (uint256) {
        return _balances[account].mul(rewardPerToken2().sub(userRewardPerTokenPaid2[account])).div(1e18).add(rewards2[account]);
    }

    modifier updateReward2(address account) virtual {
        if(_totalSupply > 0) {
            uint delta = rewardsToken2.balanceOf(address(this));
            stakingPool2.deposit(pid2, 0);
            delta = rewardsToken2.balanceOf(address(this)).sub(delta);
            _rewardPerToken2 = delta.mul(1e18).div(_totalSupply).add(_rewardPerToken2);
        }
        
        if (account != address(0)) {
            rewards2[account] = earned2(account);
            userRewardPerTokenPaid2[account] = _rewardPerToken2;
        }
        _;
    }

    uint256[50] private __gap;
}

contract IioPoolV2 is StakingPool {         // support multi IIO at the same time
    //address internal constant HelmetAddress = 0x948d2a81086A075b3130BAc19e4c6DEe1D2E3fE8;
    address internal constant BurnAddress   = 0x000000000000000000000000000000000000dEaD;

    uint private __lastUpdateTime3;                             // obsolete
    IERC20 private __rewardsToken3;                             // obsolete
    mapping(IERC20 => uint) public totalSupply3;                                    // rewardsToken3 => totalSupply3
    mapping(IERC20 => uint) internal _rewardPerToken3;                              // rewardsToken3 => _rewardPerToken3
    mapping(IERC20 => uint) public begin3;                                          // rewardsToken3 => begin3
    mapping(IERC20 => uint) public end3;                                            // rewardsToken3 => end3
    mapping(IERC20 => uint) public claimTime3;                                      // rewardsToken3 => claimTime3
    mapping(IERC20 => uint) public ticketVol3;                                      // rewardsToken3 => ticketVol3
    mapping(IERC20 => IERC20)  public ticketToken3;                                 // rewardsToken3 => ticketToken3
    mapping(IERC20 => address) public ticketRecipient3;                             // rewardsToken3 => ticketRecipient3

    mapping(IERC20 => mapping(address => bool)) public applied3;                    // rewardsToken3 => acct => applied3
    mapping(IERC20 => mapping(address => uint)) public userRewardPerTokenPaid3;     // rewardsToken3 => acct => paid3
    mapping(IERC20 => mapping(address => uint)) public rewards3;                    // rewardsToken3 => acct => rewards3
    
    mapping(IERC20 => uint) public lastUpdateTime3;                                 // rewardsToken3 => lastUpdateTime3
    IERC20[] public all;                                                            // all rewardsToken3
    IERC20[] public active;                                                         // active rewardsToken3
    
    //function setReward3BurnHelmet(IERC20 rewardsToken3_, uint begin3_, uint end3_, uint claimTime3_, uint ticketVol3_) virtual external {
    //    setReward3(rewardsToken3_, begin3_, end3_, claimTime3_, ticketVol3_, IERC20(HelmetAddress), BurnAddress);
    //}
    function setReward3(IERC20 rewardsToken3_, uint begin3_, uint end3_, uint claimTime3_, uint ticketVol3_, IERC20 ticketToken3_, address ticketRecipient3_) virtual public governance {
        lastUpdateTime3     [rewardsToken3_]= begin3_;
        //rewardsToken3       = rewardsToken3_;
        begin3              [rewardsToken3_] = begin3_;
        end3                [rewardsToken3_] = end3_;
        claimTime3          [rewardsToken3_] = claimTime3_;
        ticketVol3          [rewardsToken3_] = ticketVol3_;
        ticketToken3        [rewardsToken3_] = ticketToken3_;
        ticketRecipient3    [rewardsToken3_] = ticketRecipient3_;
        
        uint i=0;
        for(; i<all.length; i++)
            if(all[i] == rewardsToken3_)
                break;
        if(i>=all.length)
            all.push(rewardsToken3_);
            
        i=0;
        for(; i<active.length; i++)
            if(active[i] == rewardsToken3_)
                break;
        if(i>=active.length)
            active.push(rewardsToken3_);
            
        emit SetReward3(rewardsToken3_, begin3_, end3_, claimTime3_, ticketVol3_, ticketToken3_, ticketRecipient3_);
    }
    event SetReward3(IERC20 indexed rewardsToken3_, uint begin3_, uint end3_, uint claimTime3_, uint ticketVol3_, IERC20 indexed ticketToken3_, address indexed ticketRecipient3_);
    
    //function deactive(IERC20 rewardsToken3_) virtual public governance {
    //    for(uint i=0; i<active.length; i++)
    //        if(active[i] == rewardsToken3_) {
    //            active[i] = active[active.length-1];
    //            active.pop();
    //            emit Deactive(rewardsToken3_);
    //            return;
    //        }
    //    revert('not found active rewardsToken3_');
    //}
    //event Deactive(IERC20 indexed rewardsToken3_);

    function applyReward3(IERC20 rewardsToken3_) virtual public updateReward3(rewardsToken3_, msg.sender) {
        //IERC20 rewardsToken3_ = rewardsToken3;                                          // save gas
        require(!applied3[rewardsToken3_][msg.sender], 'applied already');
        require(now < end3[rewardsToken3_], 'expired');
        
        IERC20 ticketToken3_ = ticketToken3[rewardsToken3_];                            // save gas
        if(address(ticketToken3_) != address(0))
            ticketToken3_.safeTransferFrom(msg.sender, ticketRecipient3[rewardsToken3_], ticketVol3[rewardsToken3_]);
        applied3[rewardsToken3_][msg.sender] = true;
        userRewardPerTokenPaid3[rewardsToken3_][msg.sender] = _rewardPerToken3[rewardsToken3_];
        totalSupply3[rewardsToken3_] = totalSupply3[rewardsToken3_].add(_balances[msg.sender]);
        emit ApplyReward3(msg.sender, rewardsToken3_);
    }
    event ApplyReward3(address indexed acct, IERC20 indexed rewardsToken3);
    
    function rewardDelta3(IERC20 rewardsToken3_) virtual public view returns (uint amt) {
        //IERC20 rewardsToken3_ = rewardsToken3;                                          // save gas
        uint lastUpdateTime3_ = lastUpdateTime3[rewardsToken3_];                        // save gas
        if(begin3[rewardsToken3_] == 0 || begin3[rewardsToken3_] >= now || lastUpdateTime3_ >= now)
            return 0;
            
        amt = Math.min(rewardsToken3_.allowance(rewardsDistribution, address(this)), rewardsToken3_.balanceOf(rewardsDistribution)).sub0(rewards3[rewardsToken3_][address(0)]);
        
        uint end3_ = end3[rewardsToken3_];                                              // save gas
        if(now < end3_)
            amt = amt.mul(now.sub(lastUpdateTime3_)).div(end3_.sub(lastUpdateTime3_));
        else if(lastUpdateTime3_ >= end3_)
            amt = 0;
            
        if(config[_ecoAddr_] != 0)
            amt = amt.mul(uint(1e18).sub(config[_ecoRatio_])).div(1 ether);
    }
    
    function rewardPerToken3(IERC20 rewardsToken3_) virtual public view returns (uint) {
        if (totalSupply3[rewardsToken3_] == 0) {
            return _rewardPerToken3[rewardsToken3_];
        }
        return
            _rewardPerToken3[rewardsToken3_].add(
                rewardDelta3(rewardsToken3_).mul(1e18).div(totalSupply3[rewardsToken3_])
            );
    }

    function earned3(IERC20 rewardsToken3_, address account) virtual public view returns (uint) {
        if(!applied3[rewardsToken3_][account])
            return 0;
        return Math.min(rewardsToken3_.balanceOf(rewardsDistribution), _balances[account].mul(rewardPerToken3(rewardsToken3_).sub(userRewardPerTokenPaid3[rewardsToken3_][account])).div(1e18).add(rewards3[rewardsToken3_][account]));
    }

    function _updateReward3(IERC20 rewardsToken3_, address account) virtual internal {
        bool applied3_ = applied3[rewardsToken3_][account];                             // save gas
        if(account == address(0) || applied3_) {
            _rewardPerToken3[rewardsToken3_] = rewardPerToken3(rewardsToken3_);
            uint delta = rewardDelta3(rewardsToken3_);
            {
                address addr = address(config[_ecoAddr_]);
                uint ratio = config[_ecoRatio_];
                if(addr != address(0) && ratio != 0) {
                    uint d = delta.mul(ratio).div(uint(1e18).sub(ratio));
                    rewards3[rewardsToken3_][addr] = rewards3[rewardsToken3_][addr].add(d);
                    delta = delta.add(d);
                }
            }
            rewards3[rewardsToken3_][address(0)] = rewards3[rewardsToken3_][address(0)].add(delta);
            lastUpdateTime3[rewardsToken3_] = Math.max(begin3[rewardsToken3_], Math.min(now, end3[rewardsToken3_]));
        }
        if (account != address(0) && applied3_) {
            rewards3[rewardsToken3_][account] = earned3(rewardsToken3_, account);
            userRewardPerTokenPaid3[rewardsToken3_][account] = _rewardPerToken3[rewardsToken3_];
        }
    }
    
    modifier updateReward3(IERC20 rewardsToken3_, address account) virtual {
        _updateReward3(rewardsToken3_, account);
        _;
    }

    function stake(uint amount) virtual override public {
        super.stake(amount);
        for(uint i=0; i<active.length; i++) {
            IERC20 rewardsToken3_ = active[i];                                          // save gas
            _updateReward3(rewardsToken3_, msg.sender);
            if(applied3[rewardsToken3_][msg.sender])
                totalSupply3[rewardsToken3_] = totalSupply3[rewardsToken3_].add(amount);
        }    
    }

    function withdraw(uint amount) virtual override public {
        for(uint i=0; i<active.length; i++) {
            IERC20 rewardsToken3_ = active[i];                                          // save gas
            _updateReward3(rewardsToken3_, msg.sender);
            if(applied3[rewardsToken3_][msg.sender])
                totalSupply3[rewardsToken3_] = totalSupply3[rewardsToken3_].sub(amount);
        }
        super.withdraw(amount);
    }
    
    function getReward3(IERC20 rewardsToken3_) virtual public nonReentrant updateReward3(rewardsToken3_, msg.sender) {
        require(getConfigA(_blocklist_, msg.sender) == 0, 'In blocklist');
        bool isContract = msg.sender.isContract();
        require(!isContract || config[_allowContract_] != 0 || getConfigA(_allowlist_, msg.sender) != 0, 'No allowContract');

        //IERC20 rewardsToken3_ = rewardsToken3;                                          // save gas
        require(now >= claimTime3[rewardsToken3_], "it's not time yet");
        uint256 reward3 = rewards3[rewardsToken3_][msg.sender];
        if (reward3 > 0) {
            rewards3[rewardsToken3_][msg.sender] = 0;
            rewards3[rewardsToken3_][address(0)] = rewards3[rewardsToken3_][address(0)].sub0(reward3);
            rewardsToken3_.safeTransferFrom(rewardsDistribution, msg.sender, reward3);
            emit RewardPaid3(msg.sender, rewardsToken3_, reward3);
        }
    }
    event RewardPaid3(address indexed user, IERC20 indexed rewardsToken3_, uint256 reward3);
    
    uint[47] private __gap;
}

contract NestMasterChefIioV2 is NestMasterChef, IioPoolV2 {
    function notifyRewardBegin(uint _lep, /*uint _period,*/ uint _span, uint _begin) virtual override(StakingPool, NestMasterChef) public {
        NestMasterChef.notifyRewardBegin(_lep, /*_period,*/ _span, _begin);
    }
    
    function stake(uint amount) virtual override(NestMasterChef, IioPoolV2) public {
        super.stake(amount);
    }

    function withdraw(uint amount) virtual override(NestMasterChef, IioPoolV2) public {
        super.withdraw(amount);
    }
    
    function exit() virtual override(StakingRewards, NestMasterChef) public {
        NestMasterChef.exit();
    }
    
    
    uint[50] private __gap;
}
    
contract BurningPool is StakingPool {
    address internal constant BurnAddress   = 0x000000000000000000000000000000000000dEaD;
    
    function stake(uint256 amount) virtual override public {
        super.stake(amount);
        stakingToken.safeTransfer(BurnAddress, stakingToken.balanceOf(address(this)));
    }

    function withdraw(uint256) virtual override public {
        revert('Burned already, none to withdraw');
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}


contract Mine is Governable {
    using SafeERC20 for IERC20;

    address public reward;

    function __Mine_init(address governor, address reward_) public initializer {
        __Governable_init_unchained(governor);
        __Mine_init_unchained(reward_);
    }
    
    function __Mine_init_unchained(address reward_) public governance {
        reward = reward_;
    }
    
    function approvePool(address pool, uint amount) public governance {
        IERC20(reward).approve(pool, amount);
    }
    
    function approveToken(address token, address pool, uint amount) public governance {
        IERC20(token).approve(pool, amount);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}