pragma solidity 0.6.6;

import "./EglToken.sol";
import "./interfaces/IEglGenesis.sol";
import "./libraries/Math.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title EGL Voting Smart Contract
 * @author Shane van Coller
 */
contract EglContract is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using Math for *;
    using SafeMathUpgradeable for *;
    using SignedSafeMathUpgradeable for int;

    uint8 constant WEEKS_IN_YEAR = 52;
    uint constant DECIMAL_PRECISION = 10**18;

    /* PUBLIC STATE VARIABLES */
    int public desiredEgl;
    int public baselineEgl;
    int public initialEgl;
    int public tallyVotesGasLimit;

    uint public creatorEglsTotal;
    uint public liquidityEglMatchingTotal;

    uint16 public currentEpoch;
    uint public currentEpochStartDate;
    uint public tokensInCirculation;

    uint[52] public voterRewardSums;
    uint[8] public votesTotal;
    uint[8] public voteWeightsSum;
    uint[8] public gasTargetSum;

    mapping(address => Voter) public voters;
    mapping(address => Supporter) public supporters;
    mapping(address => uint) public seeders;

    struct Voter {
        uint8 lockupDuration;
        uint16 voteEpoch;
        uint releaseDate;
        uint tokensLocked;
        uint gasTarget;
    }

    struct Supporter {
        uint32 claimed;
        uint poolTokens;
        uint firstEgl;
        uint lastEgl;
    }

    /* PRIVATE STATE VARIABLES */
    EglToken private eglToken;
    IERC20Upgradeable private balancerPoolToken;
    IEglGenesis private eglGenesis;

    address private creatorRewardsAddress;
    
    int private epochGasLimitSum;
    int private epochVoteCount;
    int private desiredEglThreshold;

    uint24 private votingPauseSeconds;
    uint32 private epochLength;
    uint private firstEpochStartDate;
    uint private latestRewardSwept;
    uint private minLiquidityTokensLockup;
    uint private creatorRewardFirstEpoch;
    uint private remainingPoolReward;
    uint private remainingCreatorReward;
    uint private remainingDaoBalance;
    uint private remainingSeederBalance;
    uint private remainingSupporterBalance;
    uint private remainingBptBalance;
    uint private remainingVoterReward;
    uint private lastSerializedEgl;
    uint private ethEglRatio;
    uint private ethBptRatio;
    uint private voterRewardMultiplier;
    uint private gasTargetTolerance;    
    uint16 private voteThresholdGracePeriod;

    /* EVENTS */
    event Initialized(
        address deployer,
        address eglContract,
        address eglToken,
        address genesisContract,
        address balancerToken,
        uint totalGenesisEth,
        uint ethEglRatio,
        uint ethBptRatio,
        uint minLiquidityTokensLockup,
        uint firstEpochStartDate,
        uint votingPauseSeconds,
        uint epochLength,
        uint date
    );
    event Vote(
        address caller,
        uint16 currentEpoch,
        uint gasTarget,
        uint eglAmount,
        uint8 lockupDuration,
        uint releaseDate,
        uint epochVoteWeightSum,
        uint epochGasTargetSum,
        uint epochVoterRewardSum,
        uint epochTotalVotes,
        uint date
    );
    event ReVote(
        address caller, 
        uint gasTarget, 
        uint eglAmount, 
        uint date
    );
    event Withdraw(
        address caller,
        uint16 currentEpoch,
        uint tokensLocked,
        uint rewardTokens,
        uint gasTarget,
        uint epochVoterRewardSum,
        uint epochTotalVotes,
        uint epochVoteWeightSum,
        uint epochGasTargetSum,
        uint date
    );
    event VotesTallied(
        address caller,
        uint16 currentEpoch,
        int desiredEgl,
        int averageGasTarget,
        uint votingThreshold,
        uint actualVotePercentage,
        int baselineEgl,
        uint tokensInCirculation,
        uint date
    );
    event CreatorRewardsClaimed(
        address caller,
        address creatorRewardAddress,
        uint amountClaimed,
        uint lastSerializedEgl,
        uint remainingCreatorReward,
        uint16 currentEpoch,
        uint date
    );
    event VoteThresholdMet(
        address caller,
        uint16 currentEpoch,
        int desiredEgl,
        uint voteThreshold,
        uint actualVotePercentage,
        int gasLimitSum,
        int voteCount,
        int baselineEgl,
        uint date
    );
    event VoteThresholdFailed(
        address caller,
        uint16 currentEpoch,
        int desiredEgl,
        uint voteThreshold,
        uint actualVotePercentage,
        int baselineEgl,
        int initialEgl,
        uint timeSinceFirstEpoch,
        uint gracePeriodSeconds,
        uint date
    );
    event PoolRewardsSwept(
        address caller, 
        address coinbaseAddress,
        uint blockNumber, 
        int blockGasLimit, 
        uint blockReward, 
        uint date
    );
    event BlockRewardCalculated(
        uint blockNumber, 
        uint16 currentEpoch,
        uint remainingPoolReward,
        int blockGasLimit, 
        int desiredEgl,
        int tallyVotesGasLimit,
        uint proximityRewardPercent,
        uint totalRewardPercent,
        uint blockReward,
        uint date
    );
    event SeedAccountClaimed(
        address seedAddress, 
        uint individualSeedAmount, 
        uint releaseDate,
        uint date
    );
    event VoterRewardCalculated(
        address voter,
        uint16 currentEpoch,
        uint voterReward,
        uint epochVoterReward,
        uint voteWeight,
        uint rewardMultiplier,
        uint weeksDiv,
        uint epochVoterRewardSum,
        uint remainingVoterRewards,
        uint date
    );
    event SupporterTokensClaimed(
        address caller,
        uint amountContributed,
        uint gasTarget,
        uint lockDuration,
        uint ethEglRatio,
        uint ethBptRatio,
        uint bonusEglsReceived,
        uint poolTokensReceived,
        uint remainingSupporterBalance,
        uint remainingBptBalance, 
        uint date
    );
    event PoolTokensWithdrawn(
        address caller, 
        uint currentSerializedEgl, 
        uint poolTokensDue, 
        uint poolTokens, 
        uint firstEgl, 
        uint lastEgl, 
        uint eglReleaseDate,
        uint date
    );  
    event SerializedEglCalculated(
        uint currentEpoch, 
        uint secondsSinceEglStart,
        uint timePassedPercentage, 
        uint serializedEgl,
        uint maxSupply,
        uint date
    );
    event SeedAccountAdded(
        address seedAccount,
        uint seedAmount,
        uint remainingSeederBalance,
        uint date
    );
    
    /**
     * @notice Revert any transactions that attempts to send ETH to the contract directly
     */
    receive() external payable {
        revert("EGL:NO_PAYMENTS");
    }

    /* EXTERNAL FUNCTIONS */
    /**
     * @notice Initialized contract variables and sets up token bucket sizes
     *
     * @param _token Address of the EGL token     
     * @param _poolToken Address of the Balance Pool Token (BPT)
     * @param _genesis Address of the EGL Genesis contract
     * @param _currentEpochStartDate Start date for the first epoch
     * @param _votingPauseSeconds Number of seconds to pause voting before votes are tallied
     * @param _epochLength The length of each epoch in seconds
     * @param _seedAccounts List of accounts to seed with EGL's
     * @param _seedAmounts Amount of EGLS's to seed accounts with
     * @param _creatorRewardsAccount Address that creator rewards get sent to
     */
    function initialize(
        address _token,
        address _poolToken,
        address _genesis,
        uint _currentEpochStartDate,
        uint24 _votingPauseSeconds,
        uint32 _epochLength,
        address[] memory _seedAccounts,
        uint[] memory _seedAmounts,
        address _creatorRewardsAccount
    ) 
        public 
        initializer 
    {
        require(_token != address(0), "EGL:INVALID_EGL_TOKEN_ADDR");
        require(_poolToken != address(0), "EGL:INVALID_BP_TOKEN_ADDR");
        require(_genesis != address(0), "EGL:INVALID_GENESIS_ADDR");

        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();

        eglToken = EglToken(_token);
        balancerPoolToken = IERC20Upgradeable(_poolToken);
        eglGenesis = IEglGenesis(_genesis);        

        creatorEglsTotal = 750000000 ether;
        remainingCreatorReward = creatorEglsTotal;

        liquidityEglMatchingTotal = 750000000 ether;
        remainingPoolReward = 1250000000 ether;        
        remainingDaoBalance = 250000000 ether;
        remainingSeederBalance = 50000000 ether;
        remainingSupporterBalance = 500000000 ether;
        remainingVoterReward = 500000000 ether;
        
        voterRewardMultiplier = 362844.70 ether;

        uint totalGenesisEth = eglGenesis.cumulativeBalance();
        require(totalGenesisEth > 0, "EGL:NO_GENESIS_BALANCE");

        remainingBptBalance = balancerPoolToken.balanceOf(eglGenesis.owner());
        require(remainingBptBalance > 0, "EGL:NO_BPT_BALANCE");
        ethEglRatio = liquidityEglMatchingTotal.mul(DECIMAL_PRECISION)
            .div(totalGenesisEth);
        ethBptRatio = remainingBptBalance.mul(DECIMAL_PRECISION)
            .div(totalGenesisEth);

        creatorRewardFirstEpoch = 10;
        minLiquidityTokensLockup = _epochLength.mul(10);

        firstEpochStartDate = _currentEpochStartDate;
        currentEpochStartDate = _currentEpochStartDate;
        votingPauseSeconds = _votingPauseSeconds;
        epochLength = _epochLength;
        creatorRewardsAddress = _creatorRewardsAccount;
        tokensInCirculation = liquidityEglMatchingTotal;
        tallyVotesGasLimit = int(block.gaslimit);
        
        baselineEgl = int(block.gaslimit);
        initialEgl = baselineEgl;
        desiredEgl = baselineEgl;

        gasTargetTolerance = 4000000;
        desiredEglThreshold = 1000000;
        voteThresholdGracePeriod = 7;

        if (_seedAccounts.length > 0) {
            for (uint8 i = 0; i < _seedAccounts.length; i++) {
                addSeedAccount(_seedAccounts[i], _seedAmounts[i]);
            }
        }
        
        emit Initialized(
            msg.sender,
            address(this),
            address(eglToken),
            address(eglGenesis), 
            address(balancerPoolToken), 
            totalGenesisEth,
            ethEglRatio,
            ethBptRatio,
            minLiquidityTokensLockup,
            firstEpochStartDate,
            votingPauseSeconds,
            epochLength,
            block.timestamp
        );
    }

    /**
    * @notice Allows EGL Genesis contributors to claim their "bonus" EGL's from contributing in Genesis. Bonus EGL's
    * get locked up in a vote right away and can only be withdrawn once all BPT's are available
    *
    * @param _gasTarget desired gas target for initial vote
    * @param _lockupDuration duration to lock tokens for - determines vote multiplier
    */
    function claimSupporterEgls(uint _gasTarget, uint8 _lockupDuration) external whenNotPaused {
        require(remainingSupporterBalance > 0, "EGL:SUPPORTER_EGLS_DEPLETED");
        require(remainingBptBalance > 0, "EGL:BPT_BALANCE_DEPLETED");
        require(
            eglGenesis.canContribute() == false && eglGenesis.canWithdraw() == false, 
            "EGL:GENESIS_LOCKED"
        );
        require(supporters[msg.sender].claimed == 0, "EGL:ALREADY_CLAIMED");

        (uint contributionAmount, uint cumulativeBalance, ,) = eglGenesis.contributors(msg.sender);
        require(contributionAmount > 0, "EGL:NOT_CONTRIBUTED");

        if (block.timestamp > currentEpochStartDate.add(epochLength))
            tallyVotes();
        
        uint serializedEgls = contributionAmount.mul(ethEglRatio).div(DECIMAL_PRECISION);
        uint firstEgl = cumulativeBalance.sub(contributionAmount)
            .mul(ethEglRatio)
            .div(DECIMAL_PRECISION);
        uint lastEgl = firstEgl.add(serializedEgls);
        uint bonusEglsDue = Math.umin(
            _calculateBonusEglsDue(firstEgl, lastEgl), 
            remainingSupporterBalance
        );
        uint poolTokensDue = Math.umin(
            contributionAmount.mul(ethBptRatio).div(DECIMAL_PRECISION),
            remainingBptBalance
        );

        remainingSupporterBalance = remainingSupporterBalance.sub(bonusEglsDue);
        remainingBptBalance = remainingBptBalance.sub(poolTokensDue);
        tokensInCirculation = tokensInCirculation.add(bonusEglsDue);

        Supporter storage _supporter = supporters[msg.sender];        
        _supporter.claimed = 1;
        _supporter.poolTokens = poolTokensDue;
        _supporter.firstEgl = firstEgl;
        _supporter.lastEgl = lastEgl;        
        
        emit SupporterTokensClaimed(
            msg.sender,
            contributionAmount,
            _gasTarget,
            _lockupDuration,
            ethEglRatio,
            ethBptRatio,
            bonusEglsDue,
            poolTokensDue,
            remainingSupporterBalance,
            remainingBptBalance,
            block.timestamp
        );

        _internalVote(
            msg.sender,
            _gasTarget,
            bonusEglsDue,
            _lockupDuration,
            firstEpochStartDate.add(epochLength.mul(WEEKS_IN_YEAR))
        );
    }

    /**
     * @notice Function for seed/signal accounts to claim their EGL's. EGL's get locked up in a vote right away and can 
     * only be withdrawn after the seeder/signal lockup period
     *
     * @param _gasTarget desired gas target for initial vote
     * @param _lockupDuration duration to lock tokens for - determines vote multiplier
     */
    function claimSeederEgls(uint _gasTarget, uint8 _lockupDuration) external whenNotPaused {
        require(seeders[msg.sender] > 0, "EGL:NOT_SEEDER");
        if (block.timestamp > currentEpochStartDate.add(epochLength))
            tallyVotes();
        
        uint seedAmount = seeders[msg.sender];
        delete seeders[msg.sender];

        tokensInCirculation = tokensInCirculation.add(seedAmount);
        uint releaseDate = firstEpochStartDate.add(epochLength.mul(WEEKS_IN_YEAR));
        emit SeedAccountClaimed(msg.sender, seedAmount, releaseDate, block.timestamp);

        _internalVote(
            msg.sender,
            _gasTarget,
            seedAmount,
            _lockupDuration,
            releaseDate
        );
    }

    /**
     * @notice Submit vote to either increase or decrease the desired gas limit
     *
     * @param _gasTarget The votes target gas limit
     * @param _eglAmount Amount of EGL's to vote with
     * @param _lockupDuration Duration to lock the EGL's
     */
    function vote(
        uint _gasTarget,
        uint _eglAmount,
        uint8 _lockupDuration
    ) 
        external 
        whenNotPaused
        nonReentrant 
    {
        require(_eglAmount >= 1 ether, "EGL:AMNT_TOO_LOW");
        require(_eglAmount <= eglToken.balanceOf(msg.sender), "EGL:INSUFFICIENT_EGL_BALANCE");
        require(eglToken.allowance(msg.sender, address(this)) >= _eglAmount, "EGL:INSUFFICIENT_ALLOWANCE");
        if (block.timestamp > currentEpochStartDate.add(epochLength))
            tallyVotes();

        bool success = eglToken.transferFrom(msg.sender, address(this), _eglAmount);
        require(success, "EGL:TOKEN_TRANSFER_FAILED");
        _internalVote(
            msg.sender,
            _gasTarget,
            _eglAmount,
            _lockupDuration,
            0
        );
    }

    /**
     * @notice Re-Vote to change parameters of an existing vote. Will not shorten the time the tokens are 
     * locked up from the original vote 
     *
     * @param _gasTarget The votes target gas limit
     * @param _eglAmount Amount of EGL's to vote with
     * @param _lockupDuration Duration to lock the EGL's
     */
    function reVote(
        uint _gasTarget,
        uint _eglAmount,
        uint8 _lockupDuration
    ) 
        external 
        whenNotPaused
        nonReentrant
    {
        require(voters[msg.sender].tokensLocked > 0, "EGL:NOT_VOTED");
        if (_eglAmount > 0) {
            require(_eglAmount >= 1 ether, "EGL:AMNT_TOO_LOW");
            require(_eglAmount <= eglToken.balanceOf(msg.sender), "EGL:INSUFFICIENT_EGL_BALANCE");
            require(eglToken.allowance(msg.sender, address(this)) >= _eglAmount, "EGL:INSUFFICIENT_ALLOWANCE");
            bool success = eglToken.transferFrom(msg.sender, address(this), _eglAmount);
            require(success, "EGL:TOKEN_TRANSFER_FAILED");
        }
        if (block.timestamp > currentEpochStartDate.add(epochLength))
            tallyVotes();

        uint originalReleaseDate = voters[msg.sender].releaseDate;
        _eglAmount = _eglAmount.add(_internalWithdraw(msg.sender));
        _internalVote(
            msg.sender,
            _gasTarget,
            _eglAmount,
            _lockupDuration,
            originalReleaseDate
        );
        emit ReVote(msg.sender, _gasTarget, _eglAmount, block.timestamp);
    }

    /**
     * @notice Withdraw EGL's once they have matured
     */
    function withdraw() external whenNotPaused {
        require(voters[msg.sender].tokensLocked > 0, "EGL:NOT_VOTED");
        require(block.timestamp > voters[msg.sender].releaseDate, "EGL:NOT_RELEASE_DATE");
        bool success = eglToken.transfer(msg.sender, _internalWithdraw(msg.sender));
        require(success, "EGL:TOKEN_TRANSFER_FAILED");
    }

    /**
     * @notice Send EGL reward to miner of the block. Reward caclulated based on how close the block gas limit
     * is to the desired EGL. The closer it is, the higher the reward
     */
    function sweepPoolRewards() external whenNotPaused {
        require(block.number > latestRewardSwept, "EGL:ALREADY_SWEPT");
        latestRewardSwept = block.number;
        int blockGasLimit = int(block.gaslimit);
        uint blockReward = _calculateBlockReward(blockGasLimit, desiredEgl, tallyVotesGasLimit);
        if (blockReward > 0) {
            remainingPoolReward = remainingPoolReward.sub(blockReward);
            tokensInCirculation = tokensInCirculation.add(blockReward);
            bool success = eglToken.transfer(block.coinbase, Math.umin(eglToken.balanceOf(address(this)), blockReward));
            require(success, "EGL:TOKEN_TRANSFER_FAILED");
        }

        emit PoolRewardsSwept(
            msg.sender, 
            block.coinbase,
            latestRewardSwept, 
            blockGasLimit, 
            blockReward,
            block.timestamp
        );
    }

    /**
     * @notice Allows for the withdrawal of liquidity pool tokens once they have matured
     */
    function withdrawPoolTokens() external whenNotPaused {
        require(supporters[msg.sender].poolTokens > 0, "EGL:NO_POOL_TOKENS");
        require(block.timestamp.sub(firstEpochStartDate) > minLiquidityTokensLockup, "EGL:ALL_TOKENS_LOCKED");

        uint currentSerializedEgl = _calculateSerializedEgl(
            block.timestamp.sub(firstEpochStartDate), 
            liquidityEglMatchingTotal, 
            minLiquidityTokensLockup
        );

        Voter storage _voter = voters[msg.sender];
        Supporter storage _supporter = supporters[msg.sender];
        require(_supporter.firstEgl <= currentSerializedEgl, "EGL:ADDR_TOKENS_LOCKED");

        uint poolTokensDue;
        if (currentSerializedEgl >= _supporter.lastEgl) {
            poolTokensDue = _supporter.poolTokens;
            _supporter.poolTokens = 0;
            
            uint releaseEpoch = _voter.voteEpoch.add(_voter.lockupDuration);
            _voter.releaseDate = releaseEpoch > currentEpoch
                ? block.timestamp.add(releaseEpoch.sub(currentEpoch).mul(epochLength))
                : block.timestamp;

            emit PoolTokensWithdrawn(
                msg.sender, 
                currentSerializedEgl, 
                poolTokensDue, 
                _supporter.poolTokens,
                _supporter.firstEgl, 
                _supporter.lastEgl, 
                _voter.releaseDate,
                block.timestamp
            );
        } else {
            poolTokensDue = _calculateCurrentPoolTokensDue(
                currentSerializedEgl, 
                _supporter.firstEgl, 
                _supporter.lastEgl, 
                _supporter.poolTokens
            );
            _supporter.poolTokens = _supporter.poolTokens.sub(poolTokensDue);
            emit PoolTokensWithdrawn(
                msg.sender,
                currentSerializedEgl,
                poolTokensDue,
                _supporter.poolTokens,
                _supporter.firstEgl,
                _supporter.lastEgl,
                _voter.releaseDate,
                block.timestamp
            );
            _supporter.firstEgl = currentSerializedEgl;
        }        

        bool success = balancerPoolToken.transfer(
            msg.sender, 
            Math.umin(balancerPoolToken.balanceOf(address(this)), poolTokensDue)
        );        
        require(success, "EGL:TOKEN_TRANSFER_FAILED");
    }

    /**
     * @notice Ower only funciton to pause contract
     */
    function pauseEgl() external onlyOwner whenNotPaused {
        _pause();
    }

    /** 
     * @notice Owner only function to unpause contract
     */
    function unpauseEgl() external onlyOwner whenPaused {
        _unpause();
    }

    /* PUBLIC FUNCTIONS */
    /**
     * @notice Tally Votes for the most recent epoch and calculate the new desired EGL amount
     */
    function tallyVotes() public whenNotPaused {
        require(block.timestamp > currentEpochStartDate.add(epochLength), "EGL:VOTE_NOT_ENDED");
        tallyVotesGasLimit = int(block.gaslimit);

        uint votingThreshold = currentEpoch <= voteThresholdGracePeriod
            ? DECIMAL_PRECISION.mul(10)
            : DECIMAL_PRECISION.mul(30);

	    if (currentEpoch >= WEEKS_IN_YEAR) {
            uint actualThreshold = votingThreshold.add(
                (DECIMAL_PRECISION.mul(20).div(WEEKS_IN_YEAR.mul(2)))
                .mul(currentEpoch.sub(WEEKS_IN_YEAR.sub(1)))
            );
            votingThreshold = Math.umin(actualThreshold, 50 * DECIMAL_PRECISION);
        }

        int averageGasTarget = voteWeightsSum[0] > 0
            ? int(gasTargetSum[0].div(voteWeightsSum[0]))
            : 0;
        uint votePercentage = _calculatePercentageOfTokensInCirculation(votesTotal[0]);
        if (votePercentage >= votingThreshold) {
            epochGasLimitSum = epochGasLimitSum.add(int(tallyVotesGasLimit));
            epochVoteCount = epochVoteCount.add(1);
            baselineEgl = epochGasLimitSum.div(epochVoteCount);

            desiredEgl = baselineEgl > averageGasTarget
                ? baselineEgl.sub(baselineEgl.sub(averageGasTarget).min(desiredEglThreshold))
                : baselineEgl.add(averageGasTarget.sub(baselineEgl).min(desiredEglThreshold));

            if (
                desiredEgl >= tallyVotesGasLimit.sub(10000) &&
                desiredEgl <= tallyVotesGasLimit.add(10000)
            ) 
                desiredEgl = tallyVotesGasLimit;

            emit VoteThresholdMet(
                msg.sender,
                currentEpoch,
                desiredEgl,
                votingThreshold,
                votePercentage,
                epochGasLimitSum,
                epochVoteCount,
                baselineEgl,
                block.timestamp
            );
        } else {
            if (block.timestamp.sub(firstEpochStartDate) >= epochLength.mul(voteThresholdGracePeriod))
                desiredEgl = tallyVotesGasLimit.mul(95).div(100);

            emit VoteThresholdFailed(
                msg.sender,
                currentEpoch,
                desiredEgl,
                votingThreshold,
                votePercentage,
                baselineEgl,
                initialEgl,
                block.timestamp.sub(firstEpochStartDate),
                epochLength.mul(6),
                block.timestamp
            );
        }

        // move values 1 slot earlier and put a '0' at the last slot
        for (uint8 i = 0; i < 7; i++) {
            voteWeightsSum[i] = voteWeightsSum[i + 1];
            gasTargetSum[i] = gasTargetSum[i + 1];
            votesTotal[i] = votesTotal[i + 1];
        }
        voteWeightsSum[7] = 0;
        gasTargetSum[7] = 0;
        votesTotal[7] = 0;

        epochGasLimitSum = 0;
        epochVoteCount = 0;

        if (currentEpoch >= creatorRewardFirstEpoch && remainingCreatorReward > 0)
            _issueCreatorRewards(currentEpoch);

        currentEpoch += 1;
        currentEpochStartDate = currentEpochStartDate.add(epochLength);

        emit VotesTallied(
            msg.sender,
            currentEpoch - 1,
            desiredEgl,
            averageGasTarget,
            votingThreshold,
            votePercentage,
            baselineEgl,
            tokensInCirculation,
            block.timestamp
        );
    }

    /**
     * @notice Owner only function to add a seeder account with specified number of EGL's. Amount cannot
     * exceed balance allocated for seed/signal accounts
     *
     * @param _seedAccount Wallet address of seeder
     * @param _seedAmount Amount of EGL's to seed
     */
    function addSeedAccount(address _seedAccount, uint _seedAmount) public onlyOwner {
        require(_seedAmount <= remainingSeederBalance, "EGL:INSUFFICIENT_SEED_BALANCE");
        require(seeders[_seedAccount] == 0, "EGL:ALREADY_SEEDER");
        require(voters[_seedAccount].tokensLocked == 0, "EGL:ALREADY_HAS_VOTE");
        require(eglToken.balanceOf(_seedAccount) == 0, "EGL:ALREADY_HAS_EGLS");
        require(block.timestamp < firstEpochStartDate.add(minLiquidityTokensLockup), "EGL:SEED_PERIOD_PASSED");
        (uint contributorAmount,,,) = eglGenesis.contributors(_seedAccount);
        require(contributorAmount == 0, "EGL:IS_CONTRIBUTOR");
        
        remainingSeederBalance = remainingSeederBalance.sub(_seedAmount);
        remainingDaoBalance = remainingDaoBalance.sub(_seedAmount);
        seeders[_seedAccount] = _seedAmount;
        emit SeedAccountAdded(
            _seedAccount,
            _seedAmount,
            remainingSeederBalance,
            block.timestamp
        );
    }

    /**
     * @notice Do not allow owner to renounce ownership, only transferOwnership
     */
    function renounceOwnership() public override onlyOwner {
        revert("EGL:NO_RENOUNCE_OWNERSHIP");
    }

    /* INTERNAL FUNCTIONS */
    /**
     * @notice Internal function that adds the vote 
     *
     * @param _voter Address the vote should to assigned to
     * @param _gasTarget The target gas limit amount
     * @param _eglAmount Amount of EGL's to vote with
     * @param _lockupDuration Duration to lock the EGL's
     * @param _releaseTime Date the EGL's are available to withdraw
     */
    function _internalVote(
        address _voter,
        uint _gasTarget,
        uint _eglAmount,
        uint8 _lockupDuration,
        uint _releaseTime
    ) internal {
        require(_voter != address(0), "EGL:VOTER_ADDRESS_0");
        require(block.timestamp >= firstEpochStartDate, "EGL:VOTING_NOT_STARTED");
        require(voters[_voter].tokensLocked == 0, "EGL:ALREADY_VOTED");
        require(
            Math.udelta(_gasTarget, block.gaslimit) < gasTargetTolerance,
            "EGL:INVALID_GAS_TARGET"
        );

        require(_lockupDuration >= 1 && _lockupDuration <= 8, "EGL:INVALID_LOCKUP");
        require(block.timestamp < currentEpochStartDate.add(epochLength), "EGL:VOTE_TOO_FAR");
        require(block.timestamp < currentEpochStartDate.add(epochLength).sub(votingPauseSeconds), "EGL:VOTE_TOO_CLOSE");

        epochGasLimitSum = epochGasLimitSum.add(int(block.gaslimit));
        epochVoteCount = epochVoteCount.add(1);

        uint updatedReleaseDate = block.timestamp.add(_lockupDuration.mul(epochLength)).umax(_releaseTime);

        Voter storage voter = voters[_voter];
        voter.voteEpoch = currentEpoch;
        voter.lockupDuration = _lockupDuration;
        voter.releaseDate = updatedReleaseDate;
        voter.tokensLocked = _eglAmount;
        voter.gasTarget = _gasTarget;

        // Add the vote
        uint voteWeight = _eglAmount.mul(_lockupDuration);
        for (uint8 i = 0; i < _lockupDuration; i++) {
            voteWeightsSum[i] = voteWeightsSum[i].add(voteWeight);
            gasTargetSum[i] = gasTargetSum[i].add(_gasTarget.mul(voteWeight));
            if (currentEpoch.add(i) < WEEKS_IN_YEAR)
                voterRewardSums[currentEpoch.add(i)] = voterRewardSums[currentEpoch.add(i)].add(voteWeight);
            votesTotal[i] = votesTotal[i].add(_eglAmount);
        }

        emit Vote(
            _voter,
            currentEpoch,
            _gasTarget,
            _eglAmount,
            _lockupDuration,
            updatedReleaseDate,
            voteWeightsSum[0],
            gasTargetSum[0],
            currentEpoch < WEEKS_IN_YEAR ? voterRewardSums[currentEpoch]: 0,
            votesTotal[0],
            block.timestamp
        );
    }

    /**
     * @notice Internal function that removes the vote from current and future epochs as well as
     * calculates the rewards due for the time the tokens were locked
     *
     * @param _voter Address the voter for be withdrawn for
     * @return totalWithdrawn - The original vote amount + the total reward tokens due
     */
    function _internalWithdraw(address _voter) internal returns (uint totalWithdrawn) {
        require(_voter != address(0), "EGL:VOTER_ADDRESS_0");
        Voter storage voter = voters[_voter];
        uint16 voterEpoch = voter.voteEpoch;
        uint originalEglAmount = voter.tokensLocked;
        uint8 lockupDuration = voter.lockupDuration;
        uint gasTarget = voter.gasTarget;
        delete voters[_voter];

        uint voteWeight = originalEglAmount.mul(lockupDuration);
        uint voterReward = _calculateVoterReward(_voter, currentEpoch, voterEpoch, lockupDuration, voteWeight);        

        // Remove the gas target vote
        uint voterInterval = voterEpoch.add(lockupDuration);
        uint affectedEpochs = currentEpoch < voterInterval ? voterInterval.sub(currentEpoch) : 0;
        for (uint8 i = 0; i < affectedEpochs; i++) {
            voteWeightsSum[i] = voteWeightsSum[i].sub(voteWeight);
            gasTargetSum[i] = gasTargetSum[i].sub(voteWeight.mul(gasTarget));
            if (currentEpoch.add(i) < WEEKS_IN_YEAR) {
                voterRewardSums[currentEpoch.add(i)] = voterRewardSums[currentEpoch.add(i)].sub(voteWeight);
            }
            votesTotal[i] = votesTotal[i].sub(originalEglAmount);
        }
        
        tokensInCirculation = tokensInCirculation.add(voterReward);

        emit Withdraw(
            _voter,
            currentEpoch,
            originalEglAmount,
            voterReward,
            gasTarget,
            currentEpoch < WEEKS_IN_YEAR ? voterRewardSums[currentEpoch]: 0,
            votesTotal[0],
            voteWeightsSum[0],
            gasTargetSum[0],
            block.timestamp
        );
        totalWithdrawn = originalEglAmount.add(voterReward);
    }

    /**
     * @notice Calculates and issues creator reward EGLs' based on the release schedule
     *
     * @param _rewardEpoch The epoch number to calcualte the rewards for
     */
    function _issueCreatorRewards(uint _rewardEpoch) internal {
        uint serializedEgl = _calculateSerializedEgl(
            _rewardEpoch.mul(epochLength), 
            creatorEglsTotal,
            creatorRewardFirstEpoch.mul(epochLength)
        );
        uint creatorRewardForEpoch = serializedEgl > 0
            ? serializedEgl.sub(lastSerializedEgl).umin(remainingCreatorReward)
            : 0;
                
        bool success = eglToken.transfer(creatorRewardsAddress, creatorRewardForEpoch);
        require(success, "EGL:TOKEN_TRANSFER_FAILED");
        remainingCreatorReward = remainingCreatorReward.sub(creatorRewardForEpoch);
        tokensInCirculation = tokensInCirculation.add(creatorRewardForEpoch);

        emit CreatorRewardsClaimed(
            msg.sender,
            creatorRewardsAddress,
            creatorRewardForEpoch,
            lastSerializedEgl,
            remainingCreatorReward,
            currentEpoch,
            block.timestamp
        );
        lastSerializedEgl = serializedEgl;
    }

    /**
     * @notice Calulates the block reward depending on the current blocks gas limit
     *
     * @param _blockGasLimit Gas limit of the currently mined block
     * @param _desiredEgl Current desired EGL value
     * @param _tallyVotesGasLimit Gas limit of the block that contained the tally votes tx
     * @return blockReward The calculated block reward
     */
    function _calculateBlockReward(
        int _blockGasLimit, 
        int _desiredEgl, 
        int _tallyVotesGasLimit
    ) 
        internal 
        returns (uint blockReward) 
    {
        uint totalRewardPercent;
        uint proximityRewardPercent;
        int eglDelta = Math.delta(_tallyVotesGasLimit, _desiredEgl);
        int actualDelta = Math.delta(_tallyVotesGasLimit, _blockGasLimit);
        int ceiling = _desiredEgl.add(10000);
        int floor = _desiredEgl.sub(10000);

        if (_blockGasLimit >= floor && _blockGasLimit <= ceiling) {
            totalRewardPercent = DECIMAL_PRECISION.mul(100);
        } else if (eglDelta > 0 && (
                (
                    _desiredEgl > _tallyVotesGasLimit 
                    && _blockGasLimit > _tallyVotesGasLimit 
                    && _blockGasLimit <= ceiling
                ) || (
                    _desiredEgl < _tallyVotesGasLimit 
                    && _blockGasLimit < _tallyVotesGasLimit 
                    && _blockGasLimit >= floor
                )
            )            
        ) {
            proximityRewardPercent = uint(actualDelta.mul(int(DECIMAL_PRECISION))
                .div(eglDelta))
                .mul(75);                
            totalRewardPercent = proximityRewardPercent.add(DECIMAL_PRECISION.mul(25));
        }

        blockReward = totalRewardPercent.mul(remainingPoolReward.div(2500000))
            .div(DECIMAL_PRECISION)
            .div(100);

        emit BlockRewardCalculated(
            block.number,
            currentEpoch,
            remainingPoolReward,
            _blockGasLimit,
            _desiredEgl,
            _tallyVotesGasLimit,
            proximityRewardPercent,
            totalRewardPercent, 
            blockReward,
            block.timestamp
        );
    }

    /**
     * @notice Calculates the current serialized EGL given a time input
     * 
     * @param _timeSinceOrigin Seconds passed since the first epoch started
     * @param _maxEglSupply The maximum supply of EGL's for the thing we're calculating for
     * @param _timeLocked The minimum lockup period for the thing we're calculating for
     * @return serializedEgl The serialized EGL for the exact second the function was called
     */
    function _calculateSerializedEgl(uint _timeSinceOrigin, uint _maxEglSupply, uint _timeLocked) 
        internal                  
        returns (uint serializedEgl) 
    {
        if (_timeSinceOrigin >= epochLength.mul(WEEKS_IN_YEAR))
            return _maxEglSupply;

        uint timePassedPercentage = _timeSinceOrigin
            .sub(_timeLocked)
            .mul(DECIMAL_PRECISION)
            .div(
                epochLength.mul(WEEKS_IN_YEAR).sub(_timeLocked)
            );

        // Reduced precision so that we don't overflow the uint256 when we raise to 4th power
        serializedEgl = ((timePassedPercentage.div(10**8))**4)
            .mul(_maxEglSupply.div(DECIMAL_PRECISION))
            .mul(10**8)
            .div((10**10)**3);

        emit SerializedEglCalculated(
            currentEpoch, 
            _timeSinceOrigin,
            timePassedPercentage.mul(100), 
            serializedEgl, 
            _maxEglSupply,
            block.timestamp
        );
    }

    /**
     * @notice Calculates the pool tokens due at time of calling
     * 
     * @param _currentEgl The current serialized EGL
     * @param _firstEgl The first serialized EGL of the participant
     * @param _lastEgl The last serialized EGL of the participant
     * @param _totalPoolTokens The total number of pool tokens due to the participant
     * @return poolTokensDue The number of pool tokens due based on the serialized EGL
     */
    function _calculateCurrentPoolTokensDue(
        uint _currentEgl, 
        uint _firstEgl, 
        uint _lastEgl, 
        uint _totalPoolTokens
    ) 
        internal 
        pure
        returns (uint poolTokensDue) 
    {
        require(_firstEgl < _lastEgl, "EGL:INVALID_SERIALIZED_EGLS");

        if (_currentEgl < _firstEgl) 
            return 0;

        uint eglsReleased = (_currentEgl.umin(_lastEgl)).sub(_firstEgl);
        poolTokensDue = _totalPoolTokens
            .mul(eglsReleased)
            .div(
                _lastEgl.sub(_firstEgl)
            );
    }

    /**
     * @notice Calculates bonus EGLs due
     * 
     * @param _firstEgl The first serialized EGL of the participant
     * @param _lastEgl The last serialized EGL of the participant
     * @return bonusEglsDue The number of bonus EGL's due as a result of participating in Genesis
     */
    function _calculateBonusEglsDue(
        uint _firstEgl, 
        uint _lastEgl
    )
        internal    
        pure     
        returns (uint bonusEglsDue)  
    {
        require(_firstEgl < _lastEgl, "EGL:INVALID_SERIALIZED_EGLS");

        bonusEglsDue = (_lastEgl.div(DECIMAL_PRECISION)**4)
            .sub(_firstEgl.div(DECIMAL_PRECISION)**4)
            .mul(DECIMAL_PRECISION)
            .div(
                (81/128)*(10**27)
            );
    }

    /**
     * @notice Calculates voter reward at time of withdrawal
     * 
     * @param _voter The voter to calculate rewards for
     * @param _currentEpoch The current epoch to calculate rewards for
     * @param _voterEpoch The epoch the vote was originally entered
     * @param _lockupDuration The number of epochs the vote is locked up for
     * @param _voteWeight The vote weight for this vote (vote amount * lockup duration)
     * @return rewardsDue The total rewards due for all relevant epochs
     */
    function _calculateVoterReward(
        address _voter,
        uint16 _currentEpoch,
        uint16 _voterEpoch,
        uint8 _lockupDuration,
        uint _voteWeight
    ) 
        internal         
        returns(uint rewardsDue) 
    {
        require(_voter != address(0), "EGL:VOTER_ADDRESS_0");

        uint rewardEpochs = _voterEpoch.add(_lockupDuration).umin(_currentEpoch).umin(WEEKS_IN_YEAR);
        for (uint16 i = _voterEpoch; i < rewardEpochs; i++) {
            uint epochReward = voterRewardSums[i] > 0 
                ? Math.umin(
                    _voteWeight.mul(voterRewardMultiplier)
                        .mul(WEEKS_IN_YEAR.sub(i))
                        .div(voterRewardSums[i]),
                    remainingVoterReward
                )
                : 0;
            rewardsDue = rewardsDue.add(epochReward);
            remainingVoterReward = remainingVoterReward.sub(epochReward);
            emit VoterRewardCalculated(
                _voter,
                _currentEpoch,
                rewardsDue,
                epochReward,
                _voteWeight,
                voterRewardMultiplier,
                WEEKS_IN_YEAR.sub(i),
                voterRewardSums[i],
                remainingVoterReward,
                block.timestamp
            );
        }
    }

    /**
     * @notice Calculates the percentage of tokens in circulation for a given total
     *
     * @param _total The total to calculate the percentage of
     * @return votePercentage The percentage of the total
     */
    function _calculatePercentageOfTokensInCirculation(uint _total) 
        internal 
        view 
        returns (uint votePercentage) 
    {
        votePercentage = tokensInCirculation > 0
            ? _total.mul(DECIMAL_PRECISION).mul(100).div(tokensInCirculation)
            : 0;
    }
}

pragma solidity 0.6.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20CappedUpgradeable.sol";

contract EglToken is Initializable, ContextUpgradeable, ERC20CappedUpgradeable {
    function initialize(
        address initialRecipient, 
        string memory name, 
        string memory symbol, 
        uint256 initialSupply
    ) 
        public 
        initializer 
    {
        require(initialRecipient != address(0), "EGLTOKEN:INVALID_RECIPIENT");

        __ERC20_init(name, symbol);
        __ERC20Capped_init_unchained(initialSupply);

        _mint(initialRecipient, initialSupply);
    }
}

pragma solidity 0.6.6;

interface IEglGenesis {
    function owner() external view returns(address);
    function cumulativeBalance() external view returns(uint);
    function canContribute() external view returns(bool);
    function canWithdraw() external view returns(bool);
    function contributors(address contributor) external view returns(uint, uint, uint, uint);
}

pragma solidity ^0.6.0;

library Math {
    /**
     * @dev Returns max value of 2 unsigned ints
     */
    function umax(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns min value of 2 unsigned ints
     */
    function umin(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns max value of 2 signed ints
     */
    function max(int a, int b) internal pure returns (int) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns min value of 2 signed ints
     */
    function min(int a, int b) internal pure returns (int) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the positive delta between 2 unsigned ints
     */
    function udelta(uint a, uint b) internal pure returns (uint) {
        return a > b ? a - b : b - a;
    } 
    /**
     * @dev Returns the positive delta between 2 signed ints
     */
    function delta(int a, int b) internal pure returns (int) {
        return a > b ? a - b : b - a;
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

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/ContextUpgradeable.sol";
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
library SafeMathUpgradeable {
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

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMathUpgradeable {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


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
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20Upgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20CappedUpgradeable is Initializable, ERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    function __ERC20Capped_init(uint256 cap_) internal initializer {
        __Context_init_unchained();
        __ERC20Capped_init_unchained(cap_);
    }

    function __ERC20Capped_init_unchained(uint256 cap_) internal initializer {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) { // When minting tokens
            require(totalSupply().add(amount) <= _cap, "ERC20Capped: cap exceeded");
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}