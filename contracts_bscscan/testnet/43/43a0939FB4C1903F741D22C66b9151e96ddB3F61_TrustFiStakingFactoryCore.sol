// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./interface/ITrustFiStakingFactory.sol";
import "./interface/ITrustFiStakingFactoryCore.sol";
import "./utils/constant.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


contract TrustFiStakingFactoryCore is ITrustFiStakingFactoryCore {

    /**
        Update the ore pool information

        Action: true(New pool), false(update pool)
        Factory: Indicates the factory contract
        PoolId: indicates the ID of a pool
        Name: indicates the name of the pool
        Token: address of the pledge token contract
        StartBlock: The pool starts to dig blocks high
        Tokens contract address for Mining tokens
        RewardTotal: The total number of rewards for mining
        RewardPerBlock: The number of blocks awarded
        PoolBasicInfos: uint256[]
        Priority: sorting ore pools
        MaxStakeAmount: Maximum amount of pledge
        PoolType: specifies the type of a pool (regular or current). The value is 0,1,2,3
        LockSeconds: specifies the lockout time
     */
    event UpdatePool(
        bool action,
        address factory,
        uint256 poolId,
        string name,
        address indexed token,
        uint256 startBlock,
        address tokens,
        uint256 _rewardTotals,
        uint256 rewardPerBlocks,
        uint256[] poolBasicInfos
    );


    /**
    Closed mine pool
    Factory: Indicates the factory contract
    PoolId: indicates the ID of a pool
    */
    event ClosePool(address factory, uint256 poolId);


    /**
        End of ore pool mining

        Factory: Indicates the factory contract
        PoolId: indicates the ID of a pool
     */
    event EndPool(address factory, uint256 poolId);

    /**
        The pledge

        Factory: Indicates the factory contract
        PoolId: indicates the ID of a pool
        Token: indicates the address of the token contract
        From: pledge transfer address
        Amount: amount pledged
     */
    event Stake(
        address factory,
        uint256 poolId,
        address indexed token,
        address indexed from,
        uint256 amount
    );

    /**
        Calculate the force

        Factory: Indicates the factory contract
        PoolId: indicates the ID of a pool
        Token: indicates the address of the token contract
        TotalPower: Total pool power
        Owner: indicates the user address
        OwnerStakePower: User pledge power
     */
    event UpdatePower(
        address factory,
        uint256 poolId,
        address token,
        uint256 totalPower,
        address indexed owner,
        uint256 ownerStakePower
    );

    /**
        Solution of the pledge

        Factory: Indicates the factory contract
        PoolId: indicates the ID of a pool
        Token: indicates the address of the token contract
        To: address to which pledge is transferred
        Amount: indicates the amount of unpledged pledges
     */
    event UnStake(
        address factory,
        uint256 poolId,
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /**
        Extract the reward

        Factory: Indicates the factory contract
        PoolId: indicates the ID of a pool
        Token: indicates the address of the token contract
        To: award transfer address
        StakeAmount: The amount of rewards
        BenefitAmount: Platform cut
     */
    event WithdrawReward(
        address factory,
        uint256 poolId,
        address indexed token,
        address indexed to,
        uint256 stakeAmount,
        uint256 benefitAmount
    );


    /**
        Pre-unlock procedures cost
        Factory: Indicates the factory contract
        PoolId: indicates the ID of a pool
        Token: indicates the address of the token contract
        To: award transfer address
        FeeAmount: fee for processing
    */
    event UnStateRewardFee(
        address factory,
        uint256 poolId,
        address indexed token,
        address indexed to,
        uint256 feeAmount
    );

    /**
        Mint

        Factory: Indicates the factory contract
        PoolId: indicates the ID of a pool
        Token: indicates the address of the token contract
        Amount: Amount of reward
    */
    event Mint(address factory, uint256 poolId, address indexed token, uint256 amount);

    /**
        Trigger when the bonus per unit of power is 0
        Factory: Indicates the factory contract
        PoolId: indicates the ID of a pool
        RewardTokens: Mining tokens
        RewardPerShares: The number of rewards awarded per unit of calculating power
    */
    event RewardPerShareEvent(address factory, uint256 poolId, address indexed rewardTokens, uint256 rewardPerShares);

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool initialized;
    address internal constant ZERO = address(0);
    address public factory; //Core Contract Manager

    uint256 poolCount; //Mine the number
    uint256[] poolIds; //Ore pool ID
    address internal platform; //Platform, addPool permission
    mapping(uint256 => PoolViewInfo) internal poolViewInfos; //Mineral pool visualization information，poolID->PoolViewInfo
    mapping(uint256 => PoolStakeInfo) internal poolStakeInfos; //Ore pool pledge information，poolID->PoolStakeInfo
    mapping(uint256 => PoolRewardInfo) internal poolRewardInfos; //Mine pool bonus information，poolID->PoolRewardInfo
    mapping(uint256 => mapping(address => UserStakeInfo)) internal userStakeInfos; //User pledges information，poolID->user-UserStakeInfo

    mapping(address => uint256) public tokenPendingRewards; //Number of existing token awards，token-amount
    mapping(address => mapping(address => uint256)) internal userReceiveRewards; //Amount received by user token->user->amount

    //Verifying owner Rights
    modifier onlyFactory() {
        require(factory == msg.sender, "TrustFiStakingCore:FORBIDDEN_CALLER_NOT_FACTORY");
        _;
    }

    //Verifying Platform Rights
    modifier onlyPlatform() {
        require(platform == msg.sender, "TrustFiStakingCore:FORBIDFORBIDDEN_CALLER_NOT_PLATFORM");
        _;
    }

    /**
    @notice clone TrustFiStakingFactoryCore init
    @param _owner TrustFiStakingFactory contract
    @param _platform FactoryCreator platform
    */
    function initialize(address _owner, address _platform) external override {
        require(!initialized,  "TrustFiStakingCore:ALREADY_INITIALIZED!");
        initialized = true;
        factory = _owner;
        platform = _platform;
    }

    /** Get the mining bonus structure */
    function getPoolRewardInfo(uint256 poolId) external view override returns (PoolRewardInfo memory) {
        return poolRewardInfos[poolId];
    }

    /** Obtain user pledge information */
    function getUserStakeInfo(uint256 poolId, address user) external view override returns (UserStakeInfo memory) {
        return userStakeInfos[poolId][user];
    }

    /** Obtain ore pool information */
    function getPoolStakeInfo(uint256 poolId) external view override returns (PoolStakeInfo memory) {
        return poolStakeInfos[poolId];
    }

    /** Obtain ore pool display information */
    function getPoolViewInfo(uint256 poolId) external view override returns (PoolViewInfo memory) {
        return poolViewInfos[poolId];
    }

    /** The pledge */
    function stake(uint256 poolId, uint256 amount, address user) external onlyFactory override {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        UserStakeInfo memory userStakeInfo = userStakeInfos[poolId][user];
        if (0 == userStakeInfo.stakePower) {
            poolStakeInfo.participantCounts = poolStakeInfo.participantCounts.add(1);
        }

        uint256 rewardPerShares = computeReward(poolId); //Calculate unit calculate force reward
        provideReward(poolId, rewardPerShares, user); //Give the sender a payoff

        addPower(poolId, user, amount); //Increase the sender
        setRewardDebt(poolId, rewardPerShares, user); //Reset the sender
        userStakeInfo.lastStakeTime = block.timestamp;
        emit Stake(factory, poolId, poolStakeInfo.token, user, amount);
    }

    /**  pool ID */
    function getPoolIds() external view override returns (uint256[] memory) {
        return poolIds;
    }

    ////////////////////////////////////////////////////////////////////////////////////

    struct addPoolLocalVars {
        uint256 range;
        uint256 poolId;
        uint256 startBlock;
        address token;
        uint256 poolType;
        uint256 currentTime;
        uint256 priority;
        uint256 maxStakeAmount;
        uint256 lockSeconds;
        uint256 userMaxStakeAmount;
        uint256 userMinStakeAmount;
        uint256 feeValue;
        address feeAddress;
        uint256 editFeeValue;
        uint256 closeFeeValue;
    }

    /**
     */
    function addPool(
        uint256 range,
        address stakedToken,
        address feeAddress,
        uint256[] memory poolParams,
        address rewardToken,
        uint256 rewardTotals,
        uint256 rewardPerBlocks,
        string [] memory poolViewParams,
        address commissionToken,
        address [] memory pairs
    ) external override onlyFactory {
        addPoolLocalVars memory vars;
        vars.currentTime = block.timestamp;
        vars.range = range;
        vars.token = stakedToken;
        vars.poolType = poolParams[0];
        vars.startBlock = poolParams[1];
        vars.priority = poolParams[2];
        vars.maxStakeAmount = poolParams[3];
        vars.lockSeconds = poolParams[4];
        vars.userMaxStakeAmount = poolParams[5];
        vars.userMinStakeAmount = poolParams[6];
        vars.feeValue = poolParams[7];
        vars.feeAddress = feeAddress;
        vars.editFeeValue = poolParams[8];
        vars.closeFeeValue = poolParams[9];

        //New mineral pool
        vars.poolId = poolCount.add(vars.range); //Start with 1 w
        poolIds.push(vars.poolId); //ID of all ore pools
        poolCount = poolCount.add(1); //Total number of ore pools

        PoolViewInfo storage poolViewInfo = poolViewInfos[vars.poolId]; //Mineral pool visualization information
        poolViewInfo.token = vars.token; //Ore pool pledge token
        poolViewInfo.name = poolViewParams[0]; //Name of mine pool,
        if (0 < vars.priority) {
            poolViewInfo.priority = vars.priority; //Mine pool priority
        } else {
            poolViewInfo.priority = poolIds.length.mul(100).add(75); //Mine pool priority //TODO
        }

        poolViewInfo.officialSite = poolViewParams[1];
        poolViewInfo.twitter = poolViewParams[2];
        poolViewInfo.telegram = poolViewParams[3];
        poolViewInfo.stakedLogo = poolViewParams[4];
        poolViewInfo.rewardLogo = poolViewParams[5];
        poolViewInfo.stakedPair = pairs[0];
        poolViewInfo.rewardPair = pairs[1];

        /********** Update the pledge information of mine pool *********/
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[vars.poolId];
        poolStakeInfo.startBlock = vars.startBlock; //Start high
        poolStakeInfo.token = vars.token; //Ore pool pledge token
        // poolStakeInfo.amount; //Pool pledge number, do not reset!!
        // poolStakeInfo.participantCounts; //Participate in pledge number of players, do not reset!!
        poolStakeInfo.poolType = BaseStruct.PoolLockType(vars.poolType); //Ore pool type
        poolStakeInfo.lockSeconds = vars.lockSeconds; //Mining lock time
        poolStakeInfo.lastRewardBlock = vars.startBlock - 1;
        // poolStakeInfo.totalPower = 0; //Mine pool finally force, do not reset!!
        poolStakeInfo.maxStakeAmount = vars.maxStakeAmount; //Maximum amount of pledge
        poolStakeInfo.endBlock = 0; //Mining pool end block high
        poolStakeInfo.endTime = 0; //End time of the ore pool
        poolStakeInfo.userMaxStakeAmount = vars.userMaxStakeAmount;//Maximum number of mortgages per user
        poolStakeInfo.userMinStakeAmount = vars.userMinStakeAmount;//Minimum number of mortgages per user
        poolStakeInfo.feeValue = vars.feeValue;//Early unlock fee
        poolStakeInfo.feeAddress = vars.feeAddress;//Minimum number of mortgages per user
        poolStakeInfo.editFeeValue = vars.editFeeValue;//Editing fee
        poolStakeInfo.closeFeeValue = vars.closeFeeValue;//Closing pool charges
        poolStakeInfo.commissionToken =commissionToken;// commissionToken address

        PoolRewardInfo storage _poolRewardInfosStorage = poolRewardInfos[vars.poolId];//Mining currency after restart

        tokenPendingRewards[rewardToken] = tokenPendingRewards[rewardToken].add(rewardTotals);
        require(IERC20(rewardToken).balanceOf(address(this)) >= tokenPendingRewards[rewardToken], "TrustFiStakingCore:BALANCE_INSUFFICIENT"); //Whether the amount of reward is sufficient

        //Added new mining currency
        _poolRewardInfosStorage.token = rewardToken; //Reward token
        _poolRewardInfosStorage.rewardTotal = rewardTotals; //The total reward
        _poolRewardInfosStorage.rewardPerBlock = rewardPerBlocks; //Block rewards, the decreasing mode will decrease proportionally every day
        // poolRewardInfo.rewardProvide //The default is zero
        // poolRewardInfo.rewardPerShare //The default is zero


        sendUpdatePoolEvent(true, vars.poolId);
    }

    function editPool(
        uint256 poolId,
        address stakedToken,
        address feeAddress,
        uint256[] memory poolParams,
        address rewardToken,
        uint256 rewardTotals,
        uint256 rewardPerBlocks,
        string [] memory poolViewParams,
        address [] memory pairs
    ) external override onlyFactory {
        addPoolLocalVars memory vars;
        vars.currentTime = block.timestamp;
        vars.token = stakedToken;
        vars.poolType = poolParams[0];
        vars.startBlock = poolParams[1];
        vars.priority = poolParams[2];
        vars.maxStakeAmount = poolParams[3];
        vars.lockSeconds = poolParams[4];
        vars.userMaxStakeAmount = poolParams[5];
        vars.userMinStakeAmount = poolParams[6];
        vars.feeValue = poolParams[7];
        vars.feeAddress = feeAddress;

        //Edit mine pool
        vars.poolId = poolId;

        PoolViewInfo storage poolViewInfo = poolViewInfos[vars.poolId]; //Mineral pool visualization information
        poolViewInfo.token = vars.token; //Ore pool pledge token
        poolViewInfo.name = poolViewParams[0]; //Ore pool name
        if (0 < vars.priority) {
            poolViewInfo.priority = vars.priority; //Mine pool priority
        }

        poolViewInfo.officialSite = poolViewParams[1];
        poolViewInfo.twitter = poolViewParams[2];
        poolViewInfo.telegram = poolViewParams[3];
        poolViewInfo.stakedLogo = poolViewParams[4];
        poolViewInfo.rewardLogo = poolViewParams[5];
        poolViewInfo.stakedPair = pairs[0];
        poolViewInfo.rewardPair = pairs[1];

        /********** Update the pledge information of mine pool *********/
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[vars.poolId];
        poolStakeInfo.startBlock = vars.startBlock; //Start block
        poolStakeInfo.token = vars.token; //Ore pool pledge token
        // poolStakeInfo.amount; //Pool pledge number, do not reset!!
        // poolStakeInfo.participantCounts; //Participate in pledge number of players, do not reset!!
        poolStakeInfo.poolType = BaseStruct.PoolLockType(vars.poolType); //Ore pool type
        poolStakeInfo.lockSeconds = vars.lockSeconds; //Mining lock time
        poolStakeInfo.lastRewardBlock = vars.startBlock - 1;
        // poolStakeInfo.totalPower = 0; //Mine pool finally force, do not reset!!
        poolStakeInfo.maxStakeAmount = vars.maxStakeAmount; //Maximum amount of pledge
        poolStakeInfo.endBlock = 0; //Mining pool end block high
        poolStakeInfo.endTime = 0; //End time of the ore pool
        poolStakeInfo.userMaxStakeAmount = vars.userMaxStakeAmount;//Maximum number of mortgages per user
        poolStakeInfo.userMinStakeAmount = vars.userMinStakeAmount;//Minimum number of mortgages per user
        poolStakeInfo.feeValue = vars.feeValue;//Early unlock fee
        poolStakeInfo.feeAddress = vars.feeAddress;//Minimum number of mortgages per user

        PoolRewardInfo storage _poolRewardInfosStorage = poolRewardInfos[vars.poolId];//Mining currency after restart

        //Updated existing mining bonus coins
        if (rewardToken == _poolRewardInfosStorage.token) {

            tokenPendingRewards[rewardToken] = tokenPendingRewards[rewardToken].add(rewardTotals).sub(_poolRewardInfosStorage.rewardTotal);
            require(IERC20(rewardToken).balanceOf(address(this)) >= tokenPendingRewards[rewardToken], "TrustFiStakingCore:BALANCE_INSUFFICIENT"); //Whether the amount of reward is sufficient

            _poolRewardInfosStorage.rewardTotal = rewardTotals;
            _poolRewardInfosStorage.rewardPerBlock = rewardPerBlocks;
            _poolRewardInfosStorage.rewardProvide = 0; //Reset paid rewards
            // _poolRewardInfosStorage.rewardPerShare; //Do not reset!!
        }else{
            //The old one minus the quantity first
            tokenPendingRewards[_poolRewardInfosStorage.token] = tokenPendingRewards[_poolRewardInfosStorage.token].sub(_poolRewardInfosStorage.rewardTotal);
            //Add the new quantity
            tokenPendingRewards[rewardToken] = tokenPendingRewards[rewardToken].add(rewardTotals);
            require(IERC20(rewardToken).balanceOf(address(this)) >= tokenPendingRewards[rewardToken], "TrustFiStakingCore:BALANCE_INSUFFICIENT"); //Whether the amount of reward is sufficient

            _poolRewardInfosStorage.token = rewardToken; //Reward token
            _poolRewardInfosStorage.rewardTotal = rewardTotals; //The total reward
            _poolRewardInfosStorage.rewardPerBlock = rewardPerBlocks; //Block rewards, the decreasing mode will decrease proportionally every day
            // poolRewardInfo.rewardProvide //The default is zero
            // poolRewardInfo.rewardPerShare //The default is zero
        }

        sendUpdatePoolEvent(true, vars.poolId);
    }


    function closePool(uint256 poolId) external override onlyFactory {
        /********** Update the pledge information of mine pool *********/
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        poolStakeInfo.endBlock = block.number; //Mining pool end block high
        poolStakeInfo.endTime = block.timestamp; //End time of the ore pool

        emit ClosePool(factory, poolId);
    }

    /**
    Example Modify the name of a mine pool
     */
    function setName(uint256 poolId, string memory name) external override onlyPlatform {
        PoolViewInfo storage poolViewInfo = poolViewInfos[poolId];
        poolViewInfo.name = name;//Example Modify the name of a mine pool
        sendUpdatePoolEvent(false, poolId);//Updated the ore pool information event
    }


    /** Modify the ore pool sorting */
    function setPriority(uint256 poolId, uint256 priority) external override onlyPlatform {
        PoolViewInfo storage poolViewInfo = poolViewInfos[poolId];
        poolViewInfo.priority = priority;//Modify the ore pool sorting
        sendUpdatePoolEvent(false, poolId);//Updated the ore pool information event
    }

    /**
        Factory, used to edit the use of the user to reduce the amount of pledged currency
    */
    function platformSafeTransfer(address token,address to,uint256 amount) external override onlyFactory {
        IERC20(token).safeTransfer(to,amount);
    }

    /**
    Modified mining pool block rewards
     */
    function setRewardPerBlock(
        uint256 poolId,
        address token,
        uint256 rewardPerBlock
    ) external override onlyFactory {
        PoolRewardInfo storage _poolRewardInfos = poolRewardInfos[poolId];
        if (_poolRewardInfos.token == token) {
            _poolRewardInfos.rewardPerBlock = rewardPerBlock; //Modified mining pool block rewards
        }else{
            _poolRewardInfos.token = token; //Reward token
            _poolRewardInfos.rewardPerBlock = rewardPerBlock; //Block reward
        }
        sendUpdatePoolEvent(false, poolId); //Updated the ore pool information event

    }

    /** Modify total pool rewards: Update total rewards, update residual rewards (both rewardTotal and rewardPerBlock are increments, not replacements) */
    function setRewardTotal(
        uint256 poolId,
        address token,
        uint256 rewardTotal
    ) external override onlyFactory {
        // computeReward(poolId);//Calculate unit calculate force reward
        PoolRewardInfo storage _poolRewardInfos = poolRewardInfos[poolId];

        if (_poolRewardInfos.token == token) {
            require(_poolRewardInfos.rewardProvide <= rewardTotal, "TrustFiStakingCore:REWARDTOTAL_LESS_THAN_REWARDPROVIDE");//Whether the new total reward exceeds the reward already paid
            tokenPendingRewards[token] = tokenPendingRewards[token].add(rewardTotal.sub(_poolRewardInfos.rewardTotal));//Increase the difference between old and new, and the new total reward must be greater than the old total reward
            _poolRewardInfos.rewardTotal = rewardTotal;//Modified total pool bonus
        }else{
             //New token of
            tokenPendingRewards[token] = tokenPendingRewards[token].add(rewardTotal);
            _poolRewardInfos.token = token;
            _poolRewardInfos.rewardProvide = 0;
            _poolRewardInfos.rewardPerShare = 0;
            _poolRewardInfos.rewardTotal = rewardTotal;
        }

        require(IERC20(token).balanceOf(address(this)) >= tokenPendingRewards[token], "TrustFiStakingCore:BALANCE_INSUFFICIENT");//Whether the amount of reward is sufficient
        sendUpdatePoolEvent(false, poolId);//Updated the ore pool information event
    }

    function setMaxStakeAmount(uint256 poolId, uint256 maxStakeAmount) external override onlyFactory {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        PoolRewardInfo memory _poolRewardInfos = poolRewardInfos[poolId];

        require(maxStakeAmount <= _poolRewardInfos.rewardTotal, "TrustFiStakingCore:MAX_STAKE_AMOUNT_REACH_CALCULATED_LIMIT");
        poolStakeInfo.maxStakeAmount = maxStakeAmount;
        sendUpdatePoolEvent(false, poolId);//Updated the ore pool information event
    }

    ////////////////////////////////////////////////////////////////////////////////////
    /** Calculate unit calculate force reward */
    function computeReward(uint256 poolId) internal returns (uint256) {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        PoolRewardInfo storage poolRewardInfo = poolRewardInfos[poolId];
        uint256 rewardPerShares;
        address rewardTokens;
        bool rewardPerShareZero;

        if (0 < poolStakeInfo.totalPower) {
            bool finishReward;
            uint256 reward;
            uint256 blockCount;
            bool poolFinished;

            //Mine pool reward issued after a new period
            if (block.number < poolStakeInfo.lastRewardBlock) {
                poolFinished = true;
            } else {
                blockCount = block.number.sub(poolStakeInfo.lastRewardBlock); //Number of blocks to be issued
            }
            reward = blockCount.mul(poolRewardInfo.rewardPerBlock); //Total bonus between snapshots

            if (poolRewardInfo.rewardProvide.add(reward) >= poolRewardInfo.rewardTotal) {
                reward = poolRewardInfo.rewardTotal.sub(poolRewardInfo.rewardProvide); //Reduction exceeds reward
                finishReward = true; //Mining ends Token counting
            }
            poolRewardInfo.rewardProvide = poolRewardInfo.rewardProvide.add(reward); //Update the number of rewards awarded
            poolRewardInfo.rewardPerShare = poolRewardInfo.rewardPerShare.add(reward.mul(1e24).div(poolStakeInfo.totalPower)); //Updated unit power bonus
            if (0 == poolRewardInfo.rewardPerShare) {
                rewardPerShareZero = true;
            }
            rewardPerShares = poolRewardInfo.rewardPerShare;
            rewardTokens = poolRewardInfo.token;
            if (0 < reward) {
                emit Mint(factory, poolId, poolRewardInfo.token, reward); //mint event
            }

            if (!poolFinished) {
                poolStakeInfo.lastRewardBlock = block.number; //Updated the snapshot block height
            }

            if (finishReward && !poolFinished) {
                poolStakeInfo.endBlock = block.number; //Mining end block high
                poolStakeInfo.endTime = block.timestamp; //The end of time
                emit EndPool(factory, poolId); //Mining end event
            }
        } else {
            //At the very beginning
            rewardPerShares = poolRewardInfo.rewardPerShare;

        }

        if (rewardPerShareZero) {
            emit RewardPerShareEvent(factory, poolId, rewardTokens, rewardPerShares);
        }
        return rewardPerShares;
    }    

    /** Increase the work force */
    function addPower(
        uint256 poolId,
        address user,
        uint256 amount
    ) internal {
        uint256 power = amount;
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId]; //Ore pool pledge information
        poolStakeInfo.amount = poolStakeInfo.amount.add(amount); //Update the amount of pledge of mine pool
        poolStakeInfo.totalPower = poolStakeInfo.totalPower.add(power); //Update the pool capacity
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user]; //Sender pledges information
        userStakeInfo.amount = userStakeInfo.amount.add(amount); //Update sender pledge amount
        userStakeInfo.stakePower = userStakeInfo.stakePower.add(power); //Update sender pledge force
        if (0 == userStakeInfo.startBlock) {
            userStakeInfo.startBlock = block.number; //Mining began to block high
        }

        emit UpdatePower(factory, poolId, poolStakeInfo.token, poolStakeInfo.totalPower, user, userStakeInfo.stakePower); //Update power event
    }

    /** Reduce the work force */
    function subPower(
        uint256 poolId,
        address user,
        uint256 amount
    ) internal {
        uint256 power = amount;
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId]; //Ore pool pledge information
        if (poolStakeInfo.amount <= amount) {
            poolStakeInfo.amount = 0; //Reduce the total amount of pledge in the pool
        } else {
            poolStakeInfo.amount = poolStakeInfo.amount.sub(amount); //Reduce the total amount of pledge in the pool
        }
        if (poolStakeInfo.totalPower <= power) {
            poolStakeInfo.totalPower = 0; //Reduce pool load
        } else {
            poolStakeInfo.totalPower = poolStakeInfo.totalPower.sub(power); //Reduce pool load
        }
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user]; //Sender pledges information
        userStakeInfo.amount = userStakeInfo.amount.sub(amount); //Reduce the sender amount
        if (userStakeInfo.stakePower <= power) {
            userStakeInfo.stakePower = 0; //Reduce the sender's pledge force
        } else {
            userStakeInfo.stakePower = userStakeInfo.stakePower.sub(power); //Reduce the sender's pledge force
        }

        emit UpdatePower(factory, poolId, poolStakeInfo.token, poolStakeInfo.totalPower, user, userStakeInfo.stakePower);
    }

    struct baseLocalVars {
        uint256 poolId;
        address user;
        uint256 reward;
        uint256 benefitAmount;
        uint256 remainAmount;
        uint256 newBenefit;
    }

    /** Give the sender a payoff */
    function provideReward(
        uint256 poolId,
        uint256 rewardPerShare,
        address user
    ) internal {
        baseLocalVars memory vars;
        vars.poolId = poolId;
        vars.user = user;

        PoolRewardInfo memory _poolRewardInfos = poolRewardInfos[vars.poolId];//Get a mining bonus token
        UserStakeInfo storage _userStakeInfo = userStakeInfos[vars.poolId][vars.user];
        vars.reward = _userStakeInfo.stakePower.mul(rewardPerShare).sub(_userStakeInfo.stakeRewardDebts).div(1e24); //The pledge to reward
        if (0 < vars.reward) {
            userReceiveRewards[_poolRewardInfos.token][vars.user] = userReceiveRewards[_poolRewardInfos.token][vars.user].add(vars.reward); //Increase rewards already received
            _userStakeInfo.stakeClaimedRewards = _userStakeInfo.stakeClaimedRewards.add(vars.reward);
            tokenPendingRewards[_poolRewardInfos.token] = tokenPendingRewards[_poolRewardInfos.token].sub(vars.reward); //Reduce the total amount of rewards
            IERC20(_poolRewardInfos.token).safeTransfer(vars.user, vars.reward); //Distribution of rewards
            emit WithdrawReward(factory, vars.poolId, _poolRewardInfos.token, vars.user, vars.reward, 0);
        }


    }

    /** Reset the liabilities */
    function setRewardDebt(
        uint256 poolId,
        uint256 rewardPerShares,//Unit calculation force bonus coefficient
        address user
    ) internal {
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user];
        userStakeInfo.stakeRewardDebts = userStakeInfo.stakePower.mul(rewardPerShares); //Reset sender pledge liability
    }

    /** The ore pool information was updated */
    function sendUpdatePoolEvent(bool action, uint256 poolId) internal {
        PoolViewInfo memory poolViewInfo = poolViewInfos[poolId];
        PoolStakeInfo memory poolStakeInfo = poolStakeInfos[poolId];
        PoolRewardInfo memory _poolRewardInfos = poolRewardInfos[poolId];

        address tokens = _poolRewardInfos.token;
        uint256 _rewardTotals = _poolRewardInfos.rewardTotal;
        uint256 rewardPerBlocks = _poolRewardInfos.rewardPerBlock;

        uint256[] memory poolBasicInfos = new uint256[](6);
        poolBasicInfos[0] = poolViewInfo.priority;
        poolBasicInfos[1] = poolStakeInfo.maxStakeAmount;
        poolBasicInfos[2] = uint256(poolStakeInfo.poolType);
        poolBasicInfos[3] = poolStakeInfo.lockSeconds;
        poolBasicInfos[4] = poolStakeInfo.userMaxStakeAmount;
        poolBasicInfos[5] = poolStakeInfo.userMinStakeAmount;

        emit UpdatePool(
            action,
            factory,
            poolId,
            poolViewInfo.name,
            poolStakeInfo.token,
            poolStakeInfo.startBlock,
            tokens,
            _rewardTotals,
            rewardPerBlocks,
            poolBasicInfos
        );
    }

    /**
    unStake
     */
    function _unStake(uint256 poolId, uint256 amount, address user) override onlyFactory external {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        UserStakeInfo memory userStakeInfo = userStakeInfos[poolId][user];

        uint256 rewardPerShares = computeReward(poolId); //Calculate unit calculate force reward coefficient

        provideReward(poolId, rewardPerShares, user); //Give the sender Reward
        subPower(poolId, user, amount); //Reduce the work force

        if (0 != poolStakeInfo.startBlock && 0 == userStakeInfo.stakePower) {
            poolStakeInfo.participantCounts = poolStakeInfo.participantCounts.sub(1);
        }
        setRewardDebt(poolId, rewardPerShares, user); //Reset sender debt

        if (block.number >= poolStakeInfo.startBlock &&  //The mining pool has begun
            poolStakeInfo.lockSeconds != 0 && //The lock time is not 0, which means the lock fee is charged. 0 does not charge the lock fee
            userStakeInfo.lastStakeTime != 0 &&
            block.timestamp < userStakeInfo.lastStakeTime.add(poolStakeInfo.lockSeconds)//The ore pool is in the lock-up stage
                ) {
            //Issue commissions to the project side
            uint256 rewardFee = amount.mul(poolStakeInfo.feeValue).div(100);
            IERC20(poolStakeInfo.token).safeTransfer(poolStakeInfo.feeAddress,rewardFee);
            emit UnStateRewardFee(factory, poolId, poolStakeInfo.token, user, rewardFee);
            IERC20(poolStakeInfo.token).safeTransfer(user, amount.sub(rewardFee)); //Solution of the pledge token
            emit UnStake(factory, poolId, poolStakeInfo.token, user, amount.sub(rewardFee));
        }else{
            IERC20(poolStakeInfo.token).safeTransfer(user, amount); //Solution of the pledge token
            emit UnStake(factory, poolId, poolStakeInfo.token, user, amount);
        }

    }

    function _withdrawReward(uint256 poolId, address user) override onlyFactory external {
        UserStakeInfo memory userStakeInfo = userStakeInfos[poolId][user];
        if (0 == userStakeInfo.startBlock) {
            return; //User not pledge
        }

        uint256 rewardPerShares = computeReward(poolId); //Calculate unit calculate force reward coefficient

        provideReward(poolId, rewardPerShares, user); //Give the sender a payoff
        setRewardDebt(poolId, rewardPerShares, user); //Reset sender debt
    }


    /** Trade pool ID validity */
    function checkPIDValidation(uint256 _poolId) external view override {
        PoolStakeInfo memory poolStakeInfo = this.getPoolStakeInfo(_poolId);
        require((ZERO != poolStakeInfo.token) && (poolStakeInfo.startBlock <= block.number), "TrustFiStaking:POOL_NOT_EXIST_OR_MINT_NOT_START"); //Whether to start mining
    }

    /** Update end time */
    function refresh(uint256 _poolId) external override {
        computeReward(_poolId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import './BaseStruct.sol';
import './ITrustFiStakingFactoryCore.sol';

////////////////////////////////// Mining peripheral contract //////////////////////////////////////////////////
interface ITrustFiStakingFactory is BaseStruct {
    /**
    change OWNER
     */
    function transferOwnership(address owner) external;

    /**
    stake
    */
    function stake(uint256 poolId, uint256 amount) external;

    /**
    Unpledge and withdraw rewards
     */
    function unStake(uint256 poolId, uint256 amount) external;

    /**
    Batch unpledge and extract rewards
     */
    function unStakes(uint256[] memory _poolIds) external;

    /**
    Extract the reward
     */
    function withdrawReward(uint256 poolId) external;

    /**
    Batch extract rewards for platform invocation
     */
    function withdrawRewards2(uint256[] memory _poolIds, address user) external;

    /**
    Rewards to be claimed
     */
    function pendingRewardV3(uint256 poolId, address user) external view returns (address, uint256, uint256);

    /**
    pool ID
     */
    function poolIds() external view returns (uint256[] memory);

    /**
    Scope of pledge quantity
     */
    function stakeRange(uint256 poolId) external view returns (uint256,uint256);

    /**
    User pledge quantity range
    */
    function userStakeRange(uint256 poolId,address user) external view returns (uint256 , uint256 );


    /*
    Pool name, pledge currency, whether invite is enabled, total lock up, number of addresses, type of pool, lock up time, maximum pledge amount, start time, end time, whether to receive rewards during lock up
    */
    function getPoolStakeDetail(uint256 poolId) external view returns (string memory,address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256);

    /**
    Details of user pledge
    */
    function getUserStakeInfo(uint256 poolId, address user) external view returns (uint256, uint256, uint256);

    /**
    Details of User Rewards
    */
    function getUserRewardInfo(uint256 poolId, address user) external view returns (uint256);

    /**
    Get details of mine pool awards
    */
    function getPoolRewardInfoDetail(uint256 poolId) external view returns (address, uint256, uint256, uint256, uint256);

    /**
    Details of mine pool awards
    */
    function getPoolRewardInfo(uint poolId) external view returns (PoolRewardInfo memory);

    /**
    Setting Operation Rights
    */
    function setOperateOwner(address user, bool state) external;

    /**
    create pool
    */
    function addPool(
        uint256 range,
        address stakedToken,
        uint256[] memory poolParams,
        address rewardToken,
        uint256 rewardTotals,
        uint256 rewardPerBlocks,
        string [] memory poolViewParams,
        address feeAddress,
        address commissionToken,
        address [] memory pairs
    ) external;

    /**
    edit pool
    */
    function editPool(
        uint256 poolId,
        address stakedToken,
        uint256[] memory poolParams,
        address rewardToken,
        uint256 rewardTotals,
        uint256 rewardPerBlocks,
        string [] memory poolViewParams,
        address feeAddress,
        address [] memory pairs
    ) external;


    /**
    close pool
    */
    function closePool(uint256 poolId) external;


    /**
        FactoryCreate is used to edit the amount of money a user reduces the amount of money pledged
    */
    function platformSafeTransfer(address token,address to,uint256 amount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import './BaseStruct.sol';
import './ITrustFiStakingFactory.sol';


////////////////////////////////// Mining Core contract //////////////////////////////////////////////////
interface ITrustFiStakingFactoryCore is BaseStruct {
    function initialize(address _owner, address _platform) external;

    function getPoolRewardInfo(uint256 poolId) external view returns (PoolRewardInfo memory);

    function getUserStakeInfo(uint256 poolId, address user) external view returns (UserStakeInfo memory);

    function getPoolStakeInfo(uint256 poolId) external view returns (PoolStakeInfo memory);

    function getPoolViewInfo(uint256 poolId) external view returns (PoolViewInfo memory);

    function stake(uint256 poolId, uint256 amount, address user) external;

    function _unStake(uint256 poolId, uint256 amount, address user) external;

    function _withdrawReward(uint256 poolId, address user) external;

    function getPoolIds() external view returns (uint256[] memory);

    function addPool(
        uint256 range,
        address stakedToken,
        address feeAddress,
        uint256[] memory poolParams,
        address rewardToken,
        uint256 rewardTotals,
        uint256 rewardPerBlocks,
        string [] memory poolViewParams,
        address commissionToken,
        address [] memory pairs
    ) external;

    function editPool(
        uint256 poolId,
        address stakedToken,
        address feeAddress,
        uint256[] memory poolParams,
        address rewardToken,
        uint256 rewardTotals,
        uint256 rewardPerBlocks,
        string [] memory poolViewParams,
        address [] memory pairs
    ) external ;

    function closePool(uint256 poolId) external ;


    /** 
    Modified total pool bonus
    */
    function setRewardTotal(uint256 poolId, address token, uint256 rewardTotal) external;

    /**
    Modified mining pool block rewards
     */
    function setRewardPerBlock(uint256 poolId, address token, uint256 rewardPerBlock) external;

    /**
    Example Modify the name of a mine pool
     */
    function setName(uint256 poolId, string memory name) external;


    /**
    Modify the ore pool sorting
     */
    function setPriority(uint256 poolId, uint256 priority) external;

    /**
    Roll out factoryCore tokens
    */
    function platformSafeTransfer(address token,address to,uint256 amount) external;

    /**
    Modify the maximum amount of pledged pool
     */
    function setMaxStakeAmount(uint256 poolId, uint256 maxStakeAmount) external;

    /**
    Verify the validity of the pool ID
     */
    function checkPIDValidation(uint256 poolId) external view;

    /**
    Refresh the pool to ensure that the end time is set
     */
    function refresh(uint256 _poolId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

library ErrorCode {

    string constant FORBIDDEN = 'FORBIDDEN';
    string constant IDENTICAL_ADDRESSES = 'IDENTICAL_ADDRESSES';
    string constant ZERO_ADDRESS = 'ZERO_ADDRESS';
    string constant INVALID_ADDRESSES = 'INVALID_ADDRESSES';
    string constant BALANCE_INSUFFICIENT = 'BALANCE_INSUFFICIENT';
    string constant REWARDTOTAL_LESS_THAN_REWARDPROVIDE = 'REWARDTOTAL_LESS_THAN_REWARDPROVIDE';
    string constant PARAMETER_TOO_LONG = 'PARAMETER_TOO_LONG';
    string constant REGISTERED = 'REGISTERED';
    string constant MINING_NOT_STARTED = 'MINING_NOT_STARTED';
    string constant END_OF_MINING = 'END_OF_MINING';
    string constant POOL_NOT_EXIST_OR_END_OF_MINING = 'POOL_NOT_EXIST_OR_END_OF_MINING';
    
}

library DefaultSettings {
    uint256 constant EACH_FACTORY_POOL_MAX = 10000; //Each mine pool contract creates a contract upper limit
    uint256 constant SECONDS_PER_DAY = 86400; //Number of seconds a day
    uint256 constant ONEMINUTE = 1 minutes;
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
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface BaseStruct {

    /** There are four types of ore pools */
     enum PoolLockType {
        SINGLE_TOKEN, // Single coin mining
        LP_TOKEN, // lp dig
        SINGLE_TOKEN_FIXED, // single currency regular mining
        LP_TOKEN_FIXED // LP regular mining
    }

    /** Mineral pool visualization information */
    struct PoolViewInfo {
        address token; // Token contract address
        string name; // name
        uint256 priority; // sorting
        string officialSite; // official website (optional)
        string twitter; // Twitter (optional)
        string telegram; // Telegram(optional)
        string stakedLogo; // Staked coin Logo Address (optional)
        string rewardLogo; // Reward coin Logo Address (optional)
        address stakedPair; // stakedPair for calculate APR
        address rewardPair; // rewardPair for calculate APR
    }

    /** Ore pool pledge information */
    struct PoolStakeInfo {
        uint256 startBlock; // Mining starts block high
        address token; // Token contract address, single coin, lp is the same
        uint256 amount; // Pledge quantity, this is TVL
        uint256 participantCounts; // The number of players participating in the pledge
        PoolLockType poolType; // Single coin mining, LP mining, single coin periodic, LP periodic
        uint256 lockSeconds; // The duration of the lock
        uint256 lastRewardBlock; // Finally issue the bonus block height
        uint256 totalPower; // on the whole
        uint256 maxStakeAmount; // Maximum amount of pledge
        uint256 endBlock; // End of mining block high
        uint256 endTime; // Mining end time
        uint256 userMaxStakeAmount; // Maximum number of mortgages per user
        uint256 userMinStakeAmount; // Minimum number of mortgages per user
        uint256 feeValue; // Early unlock fee (10,000 feeValue)
        address feeAddress; // Charge the unlock fee address
        uint256 editFeeValue; // Editing fee
        uint256 closeFeeValue; // Close the pool fee
        address commissionToken;//commissionToken
    }

    /** Mine pool bonus information */
    struct PoolRewardInfo {
        address token; // Mining reward currency :A/B/C
        uint256 rewardTotal; // Total pool reward
        uint256 rewardPerBlock; // Single block reward
        uint256 rewardProvide; // The mine pool has been awarded
        uint256 rewardPerShare; // Unit count power reward
    }

    /** User pledges information */
    struct UserStakeInfo {
        uint256 startBlock; // Pledge start block height
        uint256 amount; // Pledge quantity
        uint256 stakePower; // pledge the power
        uint256 lastStakeTime; // The time of the last mortgage
        uint256 stakeRewardDebts; // Pledge debt
        uint256 stakeClaimedRewards; // Have received pledge reward
    }
}