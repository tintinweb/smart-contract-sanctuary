// File: contracts/IRewardDistributionRecipient.sol

pragma solidity ^0.5.0;

contract IRewardDistributionRecipient is Ownable {
    address public rewardDistribution;

    function notifyRewardAmount(uint256 reward) external;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}

// File: contracts/CurveRewards.sol

pragma solidity ^0.5.0;

import "./Team.sol";

contract LPTokenWrapper is Team {
    using SafeERC20 for IERC20;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(address account, uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
    }

    function withdraw(address account, uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
    }
}

contract GAMERTEAMPool is LPTokenWrapper, IRewardDistributionRecipient {
    IERC20 public gamer = IERC20(gamerTokenAddress);
    uint256 public constant DURATION = 7 days;

    uint256 public initreward = 3 * 10**5 * 10**18; // 30w
    uint256 public starttime = 1604289600 + 2 days; // 2020-11-04 04:00:00 (UTC +04:00)
    uint256 public periodFinish;
    uint256 public totalRewardRate;
    uint256 public baseTeamRewardRate;
    uint256 public weightedTeamRewardRate;
    uint256 public teamLeaderRewardRate;
    uint256 public lastUpdateTime;
    uint256 public baseTeamRewardPerTokenStored;
    uint256 public weightedTeamRewardGlobalFactorStored;
    uint256 public teamLeaderRewardPerTokenStored;

    mapping(address => uint256) private userTeamMemberRewardPerTokenPaid;
    mapping(address => uint256) private userTeamLeaderRewardPerTokenPaid;
    mapping(address => uint256) private teamMemberRewards;
    mapping(address => uint256) private teamLeaderRewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event UpdateLeaderThreshold(uint256 oldThreshold, uint256 newThreshold);
    event NewGov(address oldGov, address newGov);
    event NewGamerStakingPool(address oldGamerStakingPool, address newGamerStakingPool);

    constructor() public {
        // Creator of the contract is gov during initialization
        gov = msg.sender;
    }

    modifier updateReward(address account) {
        TeamStructure storage targetTeam = teamsKeyMap[teamRelationship[account]];

        baseTeamRewardPerTokenStored = baseTeamRewardPerToken();
        targetTeam.weightedTeamRewardPerTokenStored = targetTeamWeightedTeamRewardPerToken(account);
        teamLeaderRewardPerTokenStored = teamLeaderRewardPerToken();

        weightedTeamRewardGlobalFactorStored = weightedTeamRewardGlobalFactor();
        targetTeam.lastWeightedTeamRewardGlobalFactor = weightedTeamRewardGlobalFactorStored;
        
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            (uint256 userTotalTeamRewardPerTokenStored, uint256 userTotalTeamMemberRewards) = earnedTeamMemberReward(account);
            (uint256 userTeamLeaderRewardPerTokenStored, uint256 userTeamLeaderRewards) = earnedTeamLeaderReward(account);
            
            userTeamMemberRewardPerTokenPaid[account] = userTotalTeamRewardPerTokenStored;
            userTeamLeaderRewardPerTokenPaid[targetTeam.teamLeader] = userTeamLeaderRewardPerTokenStored;

            teamMemberRewards[account] = userTotalTeamMemberRewards;
            teamLeaderRewards[targetTeam.teamLeader] = userTeamLeaderRewards;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function baseTeamRewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return baseTeamRewardPerTokenStored;
        }
        return
            baseTeamRewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(baseTeamRewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function weightedTeamRewardGlobalFactor() public view returns (uint256) {
        if (totalSupply() == 0) {
            return weightedTeamRewardGlobalFactorStored;
        }
        return
            weightedTeamRewardGlobalFactorStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(weightedTeamRewardRate)
                    .mul(1e36)
                    .div(totalSupply() ** weightedTeamAttenuationIndex)
            );
    }

    function targetTeamWeightedTeamRewardPerToken(address account) public view returns (uint256) {
        TeamStructure storage targetTeam = teamsKeyMap[teamRelationship[account]];
        if (targetTeam.teamTotalStakingAmount == 0) {
            return targetTeam.weightedTeamRewardPerTokenStored;
        }
        return
            targetTeam.weightedTeamRewardPerTokenStored.add(
                weightedTeamRewardGlobalFactor()
                .sub(targetTeam.lastWeightedTeamRewardGlobalFactor)
                .mul(targetTeam.teamTotalStakingAmount).div(1e18));
    }

    function teamLeaderRewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return teamLeaderRewardPerTokenStored;
        }
        return
            teamLeaderRewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(teamLeaderRewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earnedTeamMemberReward(address account) public view returns (uint256, uint256) {
        uint256 userBaseTeamRewardPerTokenStored = baseTeamRewardPerToken();

        uint256 userWeightedTeamRewardPerTokenStored = targetTeamWeightedTeamRewardPerToken(account);

        uint256 userTotalTeamRewardPerTokenStored = userBaseTeamRewardPerTokenStored
                .add(userWeightedTeamRewardPerTokenStored);

        uint256 userTotalTeamMemberReward = balanceOf(account)
                .mul(userTotalTeamRewardPerTokenStored
                .sub(userTeamMemberRewardPerTokenPaid[account]))
                .div(1e18)
                .add(teamMemberRewards[account]);

        return (userTotalTeamRewardPerTokenStored, userTotalTeamMemberReward);
    }

    function earnedTeamLeaderReward(address account) public view returns (uint256, uint256)  {
        uint256 userTeamLeaderRewardPerTokenStored = teamLeaderRewardPerToken();
        TeamStructure storage targetTeam = teamsKeyMap[teamRelationship[account]];
        
        if (!targetTeam.isLeaderValid) {
            return (userTeamLeaderRewardPerTokenStored, teamLeaderRewards[targetTeam.teamLeader]);
        }
        
        uint256 userTotalTeamLeaderReward = targetTeam.teamTotalStakingAmount
                .mul(userTeamLeaderRewardPerTokenStored
                .sub(userTeamLeaderRewardPerTokenPaid[targetTeam.teamLeader]))
                .div(1e18)
                .add(teamLeaderRewards[targetTeam.teamLeader]);
        
        return (userTeamLeaderRewardPerTokenStored, userTotalTeamLeaderReward);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(address account, uint256 amount) public onlyStakingPool onlyInTeam(account) updateReward(account) checkhalve {
        require(amount > 0, "Cannot stake 0");
        _update(account, true, amount);
        super.stake(account, amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(address account, uint256 amount) public onlyStakingPool onlyInTeam(account) updateReward(account) {
        require(amount > 0, "Cannot withdraw 0");
        _update(account, false, amount);
        super.withdraw(account, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public updateReward(msg.sender) checkhalve {
        (, uint256 userTotalTeamMemberRewards) = earnedTeamMemberReward(msg.sender);
        (, uint256 userTeamLeaderRewards) = earnedTeamLeaderReward(msg.sender);

        uint256 userTotalRewards = userTotalTeamMemberRewards + userTeamLeaderRewards;
        
        if (userTotalRewards > 0) {
            teamMemberRewards[msg.sender] = 0;
            teamLeaderRewards[msg.sender] = 0;
            uint256 scalingFactor = GAMER(address(gamer)).gamersScalingFactor();
            uint256 trueReward = userTotalRewards.mul(scalingFactor).div(10**18);
            gamer.safeTransfer(msg.sender, trueReward);
            emit RewardPaid(msg.sender, trueReward);
        }
    }

    function buildTeam(string calldata newTeamName) external onlyFreeMan(msg.sender) checkStart checkhalve returns(bool) {
        require(bytes(newTeamName).length < 12 && bytes(newTeamName).length > 2, "This teamName is not valid");
        uint256 userBalance = GAMER(gamerStakingPool).balanceOfUnderlying(msg.sender);
        require(userBalance >= leaderThreshold, "This user doesn't reach the leader threshold.");
        bytes32 newTeamKey = _generateTeamKey(newTeamName);
        TeamStructure storage targetTeam = teamsKeyMap[newTeamKey];
        require(!targetTeam.isEstablished, "This teamName has been used.");

        teamRelationship[msg.sender] = newTeamKey;
        
        baseTeamRewardPerTokenStored = baseTeamRewardPerToken();
        teamLeaderRewardPerTokenStored = teamLeaderRewardPerToken();
        weightedTeamRewardGlobalFactorStored = weightedTeamRewardGlobalFactor();
        lastUpdateTime = lastTimeRewardApplicable();

        (uint256 memberPerTokenStored, ) = earnedTeamMemberReward(msg.sender);
        (uint256 leaderPerTokenStored, ) = earnedTeamLeaderReward(msg.sender);
        
        userTeamMemberRewardPerTokenPaid[msg.sender] = memberPerTokenStored;
        userTeamLeaderRewardPerTokenPaid[msg.sender] = leaderPerTokenStored;

        teamsKeyMap[newTeamKey]  = TeamStructure({
            teamName: newTeamName,
            teamKey: newTeamKey,
            isLeaderValid: true,
            isEstablished: true,
            teamLeader: msg.sender,
            teamTotalStakingAmount: userBalance,
            weightedTeamRewardPerTokenStored: uint256(0),
            lastWeightedTeamRewardGlobalFactor: weightedTeamRewardGlobalFactorStored
        });

        totalTeamNumber += 1;
        teamList.push(newTeamKey);
        super.stake(msg.sender, userBalance);
        emit BuildTeam(newTeamName);
        return true;
    }

    function joinTeam(string calldata targetTeamName) external onlyFreeMan(msg.sender) checkStart checkhalve returns(bool) {
        uint256 userBalance = GAMER(gamerStakingPool).balanceOfUnderlying(msg.sender);
        require(userBalance != 0, "This user doesn't stake any GAMERs.");

        bytes32 targetTeamKey = _generateTeamKey(targetTeamName);
        TeamStructure storage targetTeam = teamsKeyMap[targetTeamKey];
        require(targetTeam.isEstablished, "This team has not been built.");

        teamRelationship[msg.sender] = targetTeamKey;

        baseTeamRewardPerTokenStored = baseTeamRewardPerToken();
        targetTeam.weightedTeamRewardPerTokenStored = targetTeamWeightedTeamRewardPerToken(targetTeam.teamLeader);
        teamLeaderRewardPerTokenStored = teamLeaderRewardPerToken();

        weightedTeamRewardGlobalFactorStored = weightedTeamRewardGlobalFactor();
        targetTeam.lastWeightedTeamRewardGlobalFactor = weightedTeamRewardGlobalFactorStored;

        lastUpdateTime = lastTimeRewardApplicable();

        (uint256 memberPerTokenStored, ) = earnedTeamMemberReward(msg.sender);
        (uint256 leaderPerTokenStored, uint256 leaderRewards) = earnedTeamLeaderReward(msg.sender);
        
        userTeamMemberRewardPerTokenPaid[msg.sender] = memberPerTokenStored;
        userTeamLeaderRewardPerTokenPaid[targetTeam.teamLeader] = leaderPerTokenStored;
        teamLeaderRewards[targetTeam.teamLeader] = leaderRewards;

        targetTeam.teamTotalStakingAmount = targetTeam.teamTotalStakingAmount.add(userBalance);
        super.stake(msg.sender, userBalance);
        emit JoinTeam(targetTeamName);
        return true; 
    }

    modifier checkhalve() {
        if (block.timestamp >= periodFinish) {
            initreward = initreward.mul(80).div(100);
            uint256 scalingFactor = GAMER(address(gamer)).gamersScalingFactor();
            uint256 newRewards = initreward.mul(scalingFactor).div(10**18);
            gamer.mint(address(this), newRewards);

            totalRewardRate = initreward.div(DURATION);
            baseTeamRewardRate = totalRewardRate.mul(45).div(100);
            weightedTeamRewardRate = totalRewardRate.mul(45).div(100);
            teamLeaderRewardRate = totalRewardRate.mul(10).div(100);

            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(initreward);
        }
        _;
    }

    modifier checkStart(){
        require(block.timestamp >= starttime,"not start");
        _;
    }

    function setGov(address gov_) external onlyGov {
        address oldGov = gov;
        gov = gov_;
        emit NewGov(oldGov, gov_);
    }

    function setGamerStakingPool(address gamerStakingPool_) external onlyGov {
        address oldGamerStakingPool = gamerStakingPool;
        gamerStakingPool = gamerStakingPool_;
        emit NewGamerStakingPool(oldGamerStakingPool, gamerStakingPool_);
    }

    function updateLeaderThreshold(uint256 leaderThreshold_) external onlyGov {
        uint256 oldLeaderThreshold = leaderThreshold;
        leaderThreshold = leaderThreshold_;
        emit UpdateLeaderThreshold(oldLeaderThreshold, leaderThreshold_);
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp > starttime) {
            if (block.timestamp >= periodFinish) {
                totalRewardRate = reward.div(DURATION);
                baseTeamRewardRate = totalRewardRate.mul(45).div(100);
                weightedTeamRewardRate = totalRewardRate.mul(45).div(100);
                teamLeaderRewardRate = totalRewardRate.mul(10).div(100);
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(totalRewardRate);
                totalRewardRate = reward.add(leftover).div(DURATION);
                baseTeamRewardRate = totalRewardRate.mul(45).div(100);
                weightedTeamRewardRate = totalRewardRate.mul(45).div(100);
                teamLeaderRewardRate = totalRewardRate.mul(10).div(100);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(reward);
        } else {
            require(gamer.balanceOf(address(this)) == 0, "already initialized");
            gamer.mint(address(this), initreward);
            totalRewardRate = initreward.div(DURATION);
            baseTeamRewardRate = totalRewardRate.mul(45).div(100);
            weightedTeamRewardRate = totalRewardRate.mul(45).div(100);
            teamLeaderRewardRate = totalRewardRate.mul(10).div(100);
            lastUpdateTime = starttime;
            periodFinish = starttime.add(DURATION);
            emit RewardAdded(initreward);
        }
    }

    // This function allows governance to take unsupported tokens out of the
    // contract, since this one exists longer than the other pools.
    // This is in an effort to make someone whole, should they seriously
    // mess up. There is no guarantee governance will vote to return these.
    // It also allows for removal of airdropped tokens.
    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to)
        external
    {
        // only gov
        require(msg.sender == owner(), "!governance");

        // cant take reward asset
        require(_token != gamer, "gamer");

        // transfer to
        _token.safeTransfer(to, amount);
    }
}
