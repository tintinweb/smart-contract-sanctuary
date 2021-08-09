pragma solidity ^0.5.4;

import './IERC20.sol';
import './Ownable.sol';
import './SafeMath.sol';

/**
 * Website: IRDT.io
 **/

contract Farm is Ownable {
    using SafeMath for uint256;

    struct User {
        uint256 startingIntegral;
        address referrer;
        uint256 tokenAmount;   
        uint256 earningAmount;
    }

    struct StakeHistory {
        uint256 joinedTime;
        uint256 joinedAmount;
        uint256 planIndex;
        bool isStake;
    }

    struct Plan {
        address stakingTokenAddress;
        address rewardTokenAddress;
        IERC20 stakingToken;
        IERC20 rewardToken;
        uint256 totalTokenStaked;
        uint256 tokenStaking;
        uint256 remainingRewardAmount;
        uint256 rewardAmount;
        uint256 duration;
        uint256 integralOfRewardPerToken;
        bool referralEnable;
        uint256 referralPercent;
        uint256 startTime;
        uint256 prevTimeStake;
        uint256 idCounter;
        uint256 currentUserCount;
    }


    mapping(uint256 => mapping(address => uint256)) addressToId;
    mapping(uint256 => mapping(uint256 => address)) idToAddress;
    mapping(uint256 => mapping(address => User)) users;
    mapping(address => StakeHistory[]) public history;

    Plan[] plans;

    event AddPlan(address indexed stakingToken, address indexed rewardToken, uint256 rewardAmount, uint256 startTime, uint256 duration, bool referralEnable, uint256 referralPercent);
    event Unstake(uint256 indexed planIndex, address indexed unStaker, uint256 amount);
    event ClaimReward(uint256 indexed planIndex, address indexed unStaker, uint256 reward, uint256 referralReward);
    event UnstakeAndClaimRewards(uint256 indexed planIndex, address indexed unStaker, uint256 reward, uint256 referralReward, uint256 amount);
    event Stake(uint256 indexed planIndex, address indexed staker, uint256 amount, uint256 referrerID);
    event AddStake(uint256 indexed planIndex, address indexed staker, uint256 amount);
    
    /**
     * Add new staking plan 
     *
     * Requirements:
     *
     * - caller should only be owner
     */
    function addPlan(address token, address rewardToken, uint256 rewardAmount, uint256 startTime, uint256 duration, bool referralEnable, uint256 referralPercent, uint256 initialStakingAmount) public onlyOwner {
        Plan memory plan = Plan({
            integralOfRewardPerToken  : 0,
            idCounter : 2,
            stakingTokenAddress : token,
            rewardTokenAddress : rewardToken,
            tokenStaking : initialStakingAmount,
            stakingToken : IERC20(token),
            rewardToken : IERC20(rewardToken),
            remainingRewardAmount : rewardAmount.mul(1e24),
            rewardAmount : rewardAmount,
            duration : duration,
            referralEnable : referralEnable,
            referralPercent : referralPercent,
            startTime: startTime,
            prevTimeStake : startTime,
            totalTokenStaked: initialStakingAmount,
            currentUserCount: 1
        });
        
        
        addressToId[plans.length][msg.sender] = 1;
        idToAddress[plans.length][1] = msg.sender;
        plan.rewardToken.transferFrom(msg.sender, address(this), rewardAmount);
        plan.stakingToken.transferFrom(msg.sender, address(this), initialStakingAmount);

        User memory newUser = User(0, msg.sender, initialStakingAmount, 0);
        users[plans.length][msg.sender] = newUser;
        plans.push(plan);
        history[msg.sender].push(StakeHistory(startTime, initialStakingAmount, plans.length - 1,true));
        emit Stake(plans.length - 1, msg.sender, initialStakingAmount, 1);
        emit AddPlan(token, rewardToken, rewardAmount, startTime, duration, referralEnable, referralPercent);
    }

    /**
     * Stake With Permit in given plan using EIP-2612 permit function
     */
    function stakeWithPermit(uint256 planIndex, uint256 amount, uint256 referrerID, uint256 deadlineRT, uint8 v, bytes32 r, bytes32 s) public returns(uint256 id) {
        plans[planIndex].stakingToken.permit(msg.sender, address(this), amount, deadlineRT, v, r, s);
        return stake(planIndex, amount, referrerID);
    }

    /**
     * Stake in given plan using transferFrom function in stakingToken
     *
     * Requirements:
     *
     * - caller should approve amount before calling this contract
     */
    function stake(uint256 planIndex, uint256 amount, uint256 referrerID) public returns(uint256 id) {
        require(amount > 0, "Cannot stake 0");
        require(users[planIndex][msg.sender].referrer == address(0),"Reentrant is not allowed, use addStake function");
        Plan storage plan = plans[planIndex];
        require(block.timestamp < plan.startTime.add(plan.duration),"Too Late");
        require(block.timestamp > plan.startTime,"Too Early");
        if(plan.idCounter <= referrerID || referrerID == 0)
            referrerID = 1;

        plan.stakingToken.transferFrom(msg.sender, address(this), amount);
        plan.integralOfRewardPerToken = plan.integralOfRewardPerToken.add((block.timestamp.sub(plan.prevTimeStake)).mul(rewardPerToken(planIndex)));
        plan.prevTimeStake = block.timestamp;
        plan.totalTokenStaked = plan.totalTokenStaked.add(amount);
        plan.tokenStaking = plan.tokenStaking.add(amount);
        address referrerAddr = idToAddress[planIndex][referrerID];
        User memory newUser = User(plan.integralOfRewardPerToken, referrerAddr, amount, 0);
        users[planIndex][msg.sender] = newUser;
       
        addressToId[planIndex][msg.sender] = plan.idCounter;
        idToAddress[planIndex][plan.idCounter] = msg.sender;
        plan.idCounter++;
        
        plan.currentUserCount++;
        history[msg.sender].push(StakeHistory(block.timestamp, amount, planIndex,true));

        emit Stake(planIndex, msg.sender, amount, referrerID);
        return(addressToId[planIndex][msg.sender]);
    }

    /**
     * Add to Stake With Permit in given plan using EIP-2612 permit function
     */
    function addStakeWithPermit(uint256 planIndex, uint256 amount, uint256 deadlineRT, uint8 v, bytes32 r, bytes32 s) public returns(uint256 id) {
        require(amount > 0, "Cannot stake 0");
        plans[planIndex].stakingToken.permit(msg.sender, address(this), amount, deadlineRT, v, r, s);
        return addStake(planIndex, amount);
    }
    
    /**
     * Add Stake in given plan using transferFrom function in stakingToken
     *
     * Requirements:
     *
     * - caller should approve amount before calling this contract
     */
    function addStake(uint256 planIndex, uint256 amount) public returns(uint256) {
        require(amount > 0, "Cannot stake 0");
        Plan storage plan = plans[planIndex];
        require(block.timestamp < plan.startTime.add(plan.duration),"Too Late");
        require(block.timestamp > plan.startTime,"Too Early");
        User storage user = users[planIndex][msg.sender];
        require(user.referrer != address(0),"First stake then add");
        calculateReward(planIndex);
        if (user.tokenAmount == 0) {
            plan.currentUserCount++;
        }
        plan.stakingToken.transferFrom(msg.sender, address(this), amount);
        user.tokenAmount = user.tokenAmount.add(amount); 
        plan.tokenStaking = plan.tokenStaking.add(amount);
        plan.totalTokenStaked = plan.totalTokenStaked.add(amount);
        emit AddStake(planIndex, msg.sender, amount);
        history[msg.sender].push(StakeHistory(block.timestamp, amount, planIndex,true));

        return addressToId[planIndex][msg.sender];

    }

    /**
     * UnStake And Claim Rewards from given plan
     */
    function unstakeAndClaimRewards(uint256 planIndex, uint256 unstakeAmount) public returns(uint256 reward, uint256 referralReward, uint256 amount) {
        require(unstakeAmount > 0, "Cannot unstake 0");
        Plan storage plan = plans[planIndex]; 
        User storage user = users[planIndex][msg.sender];
        require(user.tokenAmount > 0,"You don't have any stake amount");
        require(user.tokenAmount >= unstakeAmount,"More than you staking amount");

        calculateReward(planIndex);
        plan.tokenStaking = plan.tokenStaking.sub(unstakeAmount);
        user.tokenAmount = user.tokenAmount.sub(unstakeAmount);
        if(user.earningAmount > 0){
            plan.remainingRewardAmount = plan.remainingRewardAmount.sub(user.earningAmount);
           

            if(plan.referralEnable){
                referralReward = (user.earningAmount.mul(plan.referralPercent)).div(100);
                user.earningAmount = user.earningAmount.sub(referralReward);
                plan.rewardToken.transfer(user.referrer, referralReward.div(1e24));
            }
            reward = user.earningAmount;
            user.earningAmount = 0;

            plan.rewardToken.transfer(msg.sender, reward.div(1e24));
        }
        
        plan.stakingToken.transfer(msg.sender, unstakeAmount);
        amount = unstakeAmount;
        if (user.tokenAmount == 0) {
            plan.currentUserCount--;
        }
        
        history[msg.sender].push(StakeHistory(block.timestamp, unstakeAmount, planIndex,false));
        emit UnstakeAndClaimRewards(planIndex, msg.sender, reward.div(1e24), referralReward.div(1e24), amount);

    }

    /**
     * UnStake from given plan
     * You can still withdraw your reward later using claimReward function
     */
    function unStake(uint256 planIndex, uint256 unstakeAmount) public returns(uint256 amount) {
        require(unstakeAmount > 0, "Cannot unstake 0");
        Plan storage plan = plans[planIndex];
        User storage user = users[planIndex][msg.sender];
        require(user.tokenAmount > 0,"You don't have any stake amount");

        calculateReward(planIndex);
        user.tokenAmount = user.tokenAmount.sub(unstakeAmount);
        plan.tokenStaking = plan.tokenStaking.sub(unstakeAmount);

        plan.stakingToken.transfer(msg.sender, unstakeAmount);
        if (user.tokenAmount == 0) {
            plan.currentUserCount--;
        }
        history[msg.sender].push(StakeHistory(block.timestamp, unstakeAmount, planIndex,false));

        emit Unstake(planIndex, msg.sender, unstakeAmount);
        return unstakeAmount;

    }
    
    /**
     * Cliam reward from given plan
     */
    function claimRewards(uint256 planIndex) public returns(uint256 reward, uint256 referralReward) {
        Plan storage plan = plans[planIndex];
        User storage user = users[planIndex][msg.sender];
        calculateReward(planIndex);
        reward = user.earningAmount;
        if(reward > 0){
            plan.remainingRewardAmount = plan.remainingRewardAmount.sub(reward);
            if(plan.referralEnable){
                referralReward = (reward.mul(plan.referralPercent)).div(100);
                reward = reward.sub(referralReward);
                plan.rewardToken.transfer(user.referrer, referralReward.div(1e24));
            }
            user.earningAmount = 0;
            plan.rewardToken.transfer(msg.sender, reward.div(1e24));
            emit ClaimReward(planIndex, msg.sender, reward.div(1e24), referralReward.div(1e24));
        }
    }

    // private util function to calculate reward
    function calculateReward(uint256 planIndex) private {
        Plan storage plan = plans[planIndex];
        require(block.timestamp >= plan.startTime,"Too Early");
        User storage user = users[planIndex][msg.sender];
        if(user.tokenAmount == 0){
            return ;
        }

        uint256 dur;
        (plan.integralOfRewardPerToken, dur) = getIntegral(planIndex);

        plan.prevTimeStake = plan.prevTimeStake.add(dur);
        uint256 reward = plan.integralOfRewardPerToken.sub(user.startingIntegral).mul(user.tokenAmount);
        user.earningAmount = user.earningAmount.add(reward);
        user.startingIntegral = plan.integralOfRewardPerToken;
    }

    // View function to retrieve plan data
    function getPlanConsts(uint256 planIndex) view public returns (address stakingTokenAddress, address rewardTokenAddress, uint256 rewardAmount, bool referralEnable, uint256 referralPercent, uint256 startTime, uint256 duration){
        Plan memory plan = plans[planIndex];
        return (plan.stakingTokenAddress, plan.rewardTokenAddress, plan.rewardAmount, plan.referralEnable, plan.referralPercent, plan.startTime, plan.duration);
    }

    // View function to retrieve plan data
    function getPlanData(uint256 planIndex) view public returns (uint256 totalTokenStaked ,uint256 tokenStaking , uint256 remainingRewardAmount, uint256 currentUserCount, uint256 idCounter, uint256 integralOfRewardPerToken, uint256 prevTimeStake){
        Plan memory plan = plans[planIndex];
        return (plan.totalTokenStaked, plan.tokenStaking, plan.remainingRewardAmount, plan.currentUserCount, plan.idCounter, plan.integralOfRewardPerToken, plan.prevTimeStake);
    }

    // View function to state of staking and rewarding status
    function getIntegral(uint256 planIndex) public view returns (uint256, uint256) {
        Plan memory plan = plans[planIndex];
        if (block.timestamp < plan.startTime)
            return (0, 0);
        else {
            uint256 dur = block.timestamp.sub(plan.prevTimeStake);
            if(plan.startTime.add(plan.duration) < block.timestamp)
                dur = plan.startTime.add(plan.duration).sub(plan.prevTimeStake);
            return (plan.integralOfRewardPerToken.add((dur).mul(rewardPerToken(planIndex))), dur);
        }
    }

    // View function to get reward per each staking token
    function rewardPerToken(uint256 planIndex) view public returns (uint256) {
        Plan memory plan = plans[planIndex];
        return (plan.rewardAmount.mul(1e24).div(plan.tokenStaking).div(plan.duration));
    }

    // View function to get amount of tokens staked and not unstaked
    function totalSupply(uint256 planIndex) public view returns (uint256) {
        Plan memory plan = plans[planIndex];
        return plan.tokenStaking;
    }

    // View function to retrieve user data
    function getUserData(uint256 planIndex, address account) public view returns (uint256 stakingAmount,address referrer, uint256 earningAmount, uint256 rewardAmount, uint256 startingIntegral) {
        User memory user = users[planIndex][account];
        uint256 reward = 0;
        if (user.tokenAmount != 0) {
            (uint256 integralOfRewardPerToken,) = getIntegral(planIndex);
            reward = (integralOfRewardPerToken.sub(user.startingIntegral)).mul(user.tokenAmount);
        }
        
        return (user.tokenAmount,user.referrer ,user.earningAmount, reward.add(user.earningAmount), user.startingIntegral);
    }

    // View function to retrieve user id in the given plan
    function getID(uint256 planIndex, address addr) view public returns (uint256 id) {
        return addressToId[planIndex][addr];
    }
}