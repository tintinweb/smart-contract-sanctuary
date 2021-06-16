/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File contracts/auxiliary/interfaces/v0.8.4/IERC20Aux.sol


pragma solidity 0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Aux {
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


// File contracts/auxiliary/interfaces/v0.8.4/IApi3Token.sol

pragma solidity 0.8.4;

interface IApi3Token is IERC20Aux {
    event MinterStatusUpdated(
        address indexed minterAddress,
        bool minterStatus
        );

    event BurnerStatusUpdated(
        address indexed burnerAddress,
        bool burnerStatus
        );

    function updateMinterStatus(
        address minterAddress,
        bool minterStatus
        )
        external;

    function updateBurnerStatus(bool burnerStatus)
        external;

    function mint(
        address account,
        uint256 amount
        )
        external;

    function burn(uint256 amount)
        external;

    function getMinterStatus(address minterAddress)
        external
        view
        returns(bool minterStatus);

    function getBurnerStatus(address burnerAddress)
        external
        view
        returns(bool burnerStatus);
}


// File contracts/interfaces/IStateUtils.sol

pragma solidity 0.8.4;

interface IStateUtils {
    event SetDaoApps(
        address agentAppPrimary,
        address agentAppSecondary,
        address votingAppPrimary,
        address votingAppSecondary
        );

    event SetClaimsManagerStatus(
        address claimsManager,
        bool status
        );

    event SetStakeTarget(
        uint256 oldTarget,
        uint256 newTarget
        );

    event SetMaxApr(
        uint256 oldMaxApr,
        uint256 maxApr
        );

    event SetMinApr(
        uint256 oldMinApr,
        uint256 minApr
        );

    event SetUnstakeWaitPeriod(
        uint256 oldUnstakeWaitPeriod,
        uint256 unstakeWaitPeriod
        );

    event SetAprUpdateStep(
        uint256 oldAprUpdateStep,
        uint256 aprUpdateStep
        );

    event SetProposalVotingPowerThreshold(
        uint256 oldProposalVotingPowerThreshold,
        uint256 proposalVotingPowerThreshold
        );

    event UpdatedLastProposalTimestamp(
        address votingApp,
        address userAddress,
        uint256 lastProposalTimestamp
        );

    function setDaoApps(
        address _agentAppPrimary,
        address _agentAppSecondary,
        address _votingAppPrimary,
        address _votingAppSecondary
        )
        external;

    function setClaimsManagerStatus(
        address claimsManager,
        bool status
        )
        external;

    function setStakeTarget(uint256 _stakeTarget)
        external;

    function setMaxApr(uint256 _maxApr)
        external;

    function setMinApr(uint256 _minApr)
        external;

    function setUnstakeWaitPeriod(uint256 _unstakeWaitPeriod)
        external;

    function setAprUpdateStep(uint256 _aprUpdateStep)
        external;

    function setProposalVotingPowerThreshold(uint256 _proposalVotingPowerThreshold)
        external;

    function updateLastProposalTimestamp(address userAddress)
        external;

    function isGenesisEpoch()
        external
        view
        returns (bool);
}


// File contracts/StateUtils.sol

pragma solidity 0.8.4;


/// @title Contract that keeps state variables
contract StateUtils is IStateUtils {
    struct Checkpoint {
        uint256 fromBlock;
        uint256 value;
    }

    struct AddressCheckpoint {
        uint256 fromBlock;
        address _address;
    }

    struct Reward {
        uint256 atBlock;
        uint256 amount;
        uint256 totalSharesThen;
    }

    struct User {
        Checkpoint[] shares;
        AddressCheckpoint[] delegates;
        Checkpoint[] delegatedTo;
        uint256 unstaked;
        uint256 vesting;
        uint256 unstakeShares;
        uint256 unstakeAmount;
        uint256 unstakeScheduledFor;
        uint256 lastDelegationUpdateTimestamp;
        uint256 lastProposalTimestamp;
    }

    struct LockedCalculationState {
        uint256 initialIndEpoch;
        uint256 nextIndEpoch;
        uint256 locked;
    }

    /// @notice Number of epochs before the staking rewards get unlocked.
    /// Hardcoded as 52 epochs, which corresponds to a year.
    uint256 public constant REWARD_VESTING_PERIOD = 52;

    // All percentage values are represented by multiplying by 1e6
    uint256 internal constant ONE_PERCENT = 1e18 / 100;
    uint256 internal constant HUNDRED_PERCENT = 1e18;

    uint256 internal constant ONE_YEAR_IN_SECONDS = 52 * 7 * 24 * 60 * 60;

    /// @notice API3 token contract
    IApi3Token public api3Token;

    /// @notice TimelockManager contract
    address public timelockManager;

    /// @notice Address of the primary Agent app of the API3 DAO
    /// @dev Primary Agent can be operated through the primary Api3Voting app.
    /// The primary Api3Voting app requires a higher quorum, and the primary
    /// Agent is more privileged.
    address public agentAppPrimary;

    /// @notice Address of the secondary Agent app of the API3 DAO
    /// @dev Secondary Agent can be operated through the secondary Api3Voting
    /// app. The secondary Api3Voting app requires a lower quorum, and the primary
    /// Agent is less privileged.
    address public agentAppSecondary;

    /// @notice Address of the primary Api3Voting app of the API3 DAO
    /// @dev Used to operate the primary Agent
    address public votingAppPrimary;

    /// @notice Address of the secondary Api3Voting app of the API3 DAO
    /// @dev Used to operate the secondary Agent
    address public votingAppSecondary;

    /// @notice Mapping that keeps the claims manager statuses of addresses
    /// @dev A claims manager is a contract that is authorized to pay out
    /// claims from the staking pool, effectively slashing the stakers. The
    /// statuses are kept as a mapping to support multiple claims managers.
    mapping(address => bool) public claimsManagerStatus;

    /// @notice Length of the epoch in which the staking reward is paid out
    /// once. It is hardcoded as 7 days in seconds.
    /// @dev In addition to regulating reward payments, this variable is used
    /// for four additional things:
    /// (1) Once an unstaking scheduling matures, the user has `epochLength`
    /// to execute the unstaking before it expires
    /// (2) After a user makes a proposal, they cannot make a second one
    /// before `epochLength` has passed
    /// (3) After a user updates their delegation status, they have to wait
    /// `epochLength` before updating it again
    uint256 immutable public epochLength;

    /// @notice Epochs are indexed as `block.timestamp / epochLength`.
    /// `genesisEpoch` is the index of the epoch in which the pool is deployed.
    uint256 public immutable genesisEpoch;

    /// @notice Records of rewards paid in each epoch
    /// @dev `.atBlock` of a past epoch's reward record being `0` means no
    /// reward was paid for that block
    mapping(uint256 => Reward) public epochIndexToReward;

    /// @notice Epoch index of the most recent reward payment
    uint256 public epochIndexOfLastRewardPayment;

    /// @notice User records
    mapping(address => User) public users;
    mapping(address => LockedCalculationState) internal userToLockedCalculationState;

    /// @notice Total number of tokens staked at the pool
    uint256 public totalStake;

    /// @notice Stake target the pool will aim to meet in percentages of the
    /// total token supply. The staking rewards increase if the total staked
    /// amount is below this, and vice versa.
    /// @dev Default value is 50% of the total API3 token supply. This
    /// parameter is governable by the DAO.
    uint256 public stakeTarget = 50 * ONE_PERCENT;

    /// @notice Minimum APR (annual percentage rate) the pool will pay as
    /// staking rewards in percentages
    /// @dev Default value is 2.5%. This parameter is governable by the DAO.
    uint256 public minApr = ONE_PERCENT * 25 / 10;

    /// @notice Maximum APR (annual percentage rate) the pool will pay as
    /// staking rewards in percentages
    /// @dev Default value is 75%. This parameter is governable by the DAO.
    uint256 public maxApr = 75 * ONE_PERCENT;

    /// @notice Steps in which APR will be updated in percentages
    /// @dev Default value is 1%. This parameter is governable by the DAO.
    uint256 public aprUpdateStep = ONE_PERCENT;

    /// @notice Users need to schedule an unstake and wait for
    /// `unstakeWaitPeriod` before being able to unstake. This is to prevent
    /// the stakers from frontrunning insurance claims by unstaking to evade
    /// them, or repeatedly unstake/stake to work around the proposal spam
    /// protection.
    /// @dev This parameter is governable by the DAO, and the DAO is expected
    /// to set this to a value that is large enough to allow insurance claims
    /// to be resolved.
    uint256 public unstakeWaitPeriod;

    /// @notice Minimum voting power the users must have to be able to make
    /// proposals (in percentages)
    /// @dev Delegations count towards voting power.
    /// Default value is 0.1%. This parameter is governable by the DAO.
    uint256 public proposalVotingPowerThreshold = ONE_PERCENT / 10;

    /// @notice APR that will be paid next epoch
    /// @dev This value will reach an equilibrium based on the stake target.
    /// Every epoch (week), APR/52 of the total staked tokens will be added to
    /// the pool, effectively distributing them to the stakers.
    uint256 public currentApr = (maxApr + minApr) / 2;

    /// @notice Mapping that keeps the specs of a proposal provided by a user
    /// @dev After making a proposal through the Agent app, the user publishes
    /// the specs of the proposal (target contract address, function,
    /// parameters) at a URL
    mapping(address => mapping(address => mapping(uint256 => string))) public userAddressToVotingAppToProposalIndexToSpecsUrl;

    address private deployer;

    // We keep checkpoints for two most recent blocks at which totalShares has
    // been updated. Note that the indices do not indicate chronological
    // ordering.
    Checkpoint private totalSharesCheckpoint1;
    Checkpoint private totalSharesCheckpoint2;

    /// @dev Reverts if the caller is not an API3 DAO Agent
    modifier onlyAgentApp() {
        require(
            msg.sender == agentAppPrimary || msg.sender == agentAppSecondary,
            "Pool: Caller not agent"
            );
        _;
    }

    /// @dev Reverts if the caller is not the primary API3 DAO Agent
    modifier onlyAgentAppPrimary() {
        require(
            msg.sender == agentAppPrimary,
            "Pool: Caller not primary agent"
            );
        _;
    }

    /// @dev Reverts if the caller is not an API3 DAO Api3Voting app
    modifier onlyVotingApp() {
        require(
            msg.sender == votingAppPrimary || msg.sender == votingAppSecondary,
            "Pool: Caller not voting app"
            );
        _;
    }

    /// @param api3TokenAddress API3 token contract address
    /// @param timelockManagerAddress Timelock manager contract address
    /// @param _epochLength Epoch length in seconds
    constructor(
        address api3TokenAddress,
        address timelockManagerAddress,
        uint256 _epochLength
        )
    {
        require(
            api3TokenAddress != address(0),
            "Pool: Invalid Api3Token"
            );
        require(
            timelockManagerAddress != address(0),
            "Pool: Invalid TimelockManager"
            );
        require(
            _epochLength != 0,
            "Pool: Invalid epoch length"
            );
        epochLength = _epochLength;
        deployer = msg.sender;
        api3Token = IApi3Token(api3TokenAddress);
        timelockManager = timelockManagerAddress;
        // Initialize the share price at 1
        updateTotalShares(1);
        totalStake = 1;
        // Set the current epoch as the genesis epoch and skip its reward
        // payment
        uint256 currentEpoch = block.timestamp / _epochLength;
        genesisEpoch = currentEpoch;
        epochIndexOfLastRewardPayment = currentEpoch;
        // Set the unstake wait period as _epochLength by default
        unstakeWaitPeriod = _epochLength;
    }

    /// @notice Called after deployment to set the addresses of the DAO apps
    /// @dev This can also be called later on by the primary Agent to update
    /// all app addresses as a means of upgrade
    /// @param _agentAppPrimary Address of the primary Agent
    /// @param _agentAppSecondary Address of the secondary Agent
    /// @param _votingAppPrimary Address of the primary Api3Voting
    /// @param _votingAppSecondary Address of the secondary Api3Voting
    function setDaoApps(
        address _agentAppPrimary,
        address _agentAppSecondary,
        address _votingAppPrimary,
        address _votingAppSecondary
        )
        external
        override
    {
        // solhint-disable-next-line reason-string
        require(
            msg.sender == agentAppPrimary
                || (agentAppPrimary == address(0) && msg.sender == deployer),
            "Pool: Caller not primary agent or deployer initializing values"
            );
        require(
            _agentAppPrimary != address(0)
                && _agentAppSecondary  != address(0)
                && _votingAppPrimary  != address(0)
                && _votingAppSecondary  != address(0),
            "Pool: Invalid DAO apps"
            );
        agentAppPrimary = _agentAppPrimary;
        agentAppSecondary = _agentAppSecondary;
        votingAppPrimary = _votingAppPrimary;
        votingAppSecondary = _votingAppSecondary;
        emit SetDaoApps(
            agentAppPrimary,
            agentAppSecondary,
            votingAppPrimary,
            votingAppSecondary
            );
    }

    /// @notice Called by the DAO Agent to set the authorization status of a
    /// claims manager contract
    /// @dev The claims manager is a trusted contract that is allowed to
    /// withdraw as many tokens as it wants from the pool to pay out insurance
    /// claims.
    /// Only the primary Agent can do this because it is a critical operation.
    /// WARNING: A compromised contract being given claims manager status may
    /// result in loss of staked funds. If a proposal has been made to call
    /// this method to set a contract as a claims manager, you are recommended
    /// to review the contract yourself and/or refer to the audit reports to
    /// understand the implications.
    /// @param claimsManager Claims manager contract address
    /// @param status Authorization status
    function setClaimsManagerStatus(
        address claimsManager,
        bool status
        )
        external
        override
        onlyAgentAppPrimary()
    {
        claimsManagerStatus[claimsManager] = status;
        emit SetClaimsManagerStatus(
            claimsManager,
            status
            );
    }

    /// @notice Called by the DAO Agent to set the stake target
    /// @param _stakeTarget Stake target
    function setStakeTarget(uint256 _stakeTarget)
        external
        override
        onlyAgentApp()
    {
        require(
            _stakeTarget <= HUNDRED_PERCENT,
            "Pool: Invalid percentage value"
            );
        uint256 oldStakeTarget = stakeTarget;
        stakeTarget = _stakeTarget;
        emit SetStakeTarget(
            oldStakeTarget,
            stakeTarget
            );
    }

    /// @notice Called by the DAO Agent to set the maximum APR
    /// @param _maxApr Maximum APR
    function setMaxApr(uint256 _maxApr)
        external
        override
        onlyAgentApp()
    {
        require(
            _maxApr >= minApr,
            "Pool: Max APR smaller than min"
            );
        uint256 oldMaxApr = maxApr;
        maxApr = _maxApr;
        emit SetMaxApr(
            oldMaxApr,
            maxApr
            );
    }

    /// @notice Called by the DAO Agent to set the minimum APR
    /// @param _minApr Minimum APR
    function setMinApr(uint256 _minApr)
        external
        override
        onlyAgentApp()
    {
        require(
            _minApr <= maxApr,
            "Pool: Min APR larger than max"
            );
        uint256 oldMinApr = minApr;
        minApr = _minApr;
        emit SetMinApr(
            oldMinApr,
            minApr
            );
    }

    /// @notice Called by the DAO Agent to set the unstake waiting period
    /// @dev This may want to be increased to provide more time for insurance
    /// claims to be resolved.
    /// Even when the insurance functionality is not implemented, the minimum
    /// valid value is `epochLength` to prevent users from unstaking,
    /// withdrawing and staking with another address to work around the
    /// proposal spam protection.
    /// Only the primary Agent can do this because it is a critical operation.
    /// @param _unstakeWaitPeriod Unstake waiting period
    function setUnstakeWaitPeriod(uint256 _unstakeWaitPeriod)
        external
        override
        onlyAgentAppPrimary()
    {
        require(
            _unstakeWaitPeriod >= epochLength,
            "Pool: Period shorter than epoch"
            );
        uint256 oldUnstakeWaitPeriod = unstakeWaitPeriod;
        unstakeWaitPeriod = _unstakeWaitPeriod;
        emit SetUnstakeWaitPeriod(
            oldUnstakeWaitPeriod,
            unstakeWaitPeriod
            );
    }

    /// @notice Called by the DAO Agent to set the APR update steps
    /// @dev aprUpdateStep can be 0% or 100%+
    /// @param _aprUpdateStep APR update steps
    function setAprUpdateStep(uint256 _aprUpdateStep)
        external
        override
        onlyAgentApp()
    {
        uint256 oldAprUpdateStep = aprUpdateStep;
        aprUpdateStep = _aprUpdateStep;
        emit SetAprUpdateStep(
            oldAprUpdateStep,
            aprUpdateStep
            );
    }

    /// @notice Called by the DAO Agent to set the voting power threshold for
    /// proposals
    /// Only the primary Agent can do this because it is a critical operation.
    /// @param _proposalVotingPowerThreshold Voting power threshold for
    /// proposals
    function setProposalVotingPowerThreshold(uint256 _proposalVotingPowerThreshold)
        external
        override
        onlyAgentAppPrimary()
    {
        require(
            _proposalVotingPowerThreshold >= ONE_PERCENT / 10
                && _proposalVotingPowerThreshold <= 10 * ONE_PERCENT,
            "Pool: Threshold outside limits");
        uint256 oldProposalVotingPowerThreshold = proposalVotingPowerThreshold;
        proposalVotingPowerThreshold = _proposalVotingPowerThreshold;
        emit SetProposalVotingPowerThreshold(
            oldProposalVotingPowerThreshold,
            proposalVotingPowerThreshold
            );
    }

    /// @notice Called by a DAO Api3Voting app at proposal creation-time to
    /// update the timestamp of the user's last proposal
    /// @param userAddress User address
    function updateLastProposalTimestamp(address userAddress)
        external
        override
        onlyVotingApp()
    {
        users[userAddress].lastProposalTimestamp = block.timestamp;
        emit UpdatedLastProposalTimestamp(
            msg.sender,
            userAddress,
            block.timestamp
            );
    }

    /// @notice Called to check if we are in the genesis epoch
    /// @dev Voting apps use this to prevent proposals from being made in the
    /// genesis epoch
    function isGenesisEpoch()
        external
        view
        override
        returns (bool)
    {
        return block.timestamp / epochLength == genesisEpoch;
    }

    /// @notice Called internally to update the total shares history
    /// @dev `fromBlock0` and `fromBlock1` will be two different block numbers
    /// when totalShares history was last updated. If one of these
    /// `fromBlock`s match with `block.number`, we simply update the value
    /// (because the history keeps the most recent value from that block). If
    /// not, we can overwrite the older one, as we no longer need it.
    /// @param newTotalShares Total shares value to insert into history
    function updateTotalShares(uint256 newTotalShares)
        internal
    {
        if (block.number == totalSharesCheckpoint1.fromBlock)
        {
            totalSharesCheckpoint1.value = newTotalShares;
        }
        else if (block.number == totalSharesCheckpoint2.fromBlock)
        {
            totalSharesCheckpoint2.value = newTotalShares;
        }
        else {
            if (totalSharesCheckpoint1.fromBlock < totalSharesCheckpoint2.fromBlock)
            {
                totalSharesCheckpoint1.fromBlock = block.number;
                totalSharesCheckpoint1.value = newTotalShares;
            }
            else
            {
                totalSharesCheckpoint2.fromBlock = block.number;
                totalSharesCheckpoint2.value = newTotalShares;
            }
        }
    }

    /// @notice Called internally to get the current total shares
    /// @return Current total shares
    function totalShares()
        internal
        view
        returns (uint256)
    {
        if (totalSharesCheckpoint1.fromBlock < totalSharesCheckpoint2.fromBlock)
        {
            return totalSharesCheckpoint2.value;
        }
        else
        {
            return totalSharesCheckpoint1.value;
        }
    }

    /// @notice Called internally to get the total shares one block ago
    /// @return Total shares one block ago
    function totalSharesOneBlockAgo()
        internal
        view
        returns (uint256)
    {
        if (totalSharesCheckpoint2.fromBlock == block.number)
        {
            return totalSharesCheckpoint1.value;
        }
        else if (totalSharesCheckpoint1.fromBlock == block.number)
        {
            return totalSharesCheckpoint2.value;
        }
        else
        {
            return totalShares();
        }
    }
}


// File contracts/interfaces/IGetterUtils.sol

pragma solidity 0.8.4;

interface IGetterUtils is IStateUtils {
    function userVotingPowerAt(
        address userAddress,
        uint256 _block
        )
        external
        view
        returns(uint256);

    function userVotingPower(address userAddress)
        external
        view
        returns(uint256);

    function totalVotingPowerOneBlockAgo()
        external
        view
        returns(uint256);

    function totalVotingPower()
        external
        view
        returns(uint256);

    function userSharesAt(
        address userAddress,
        uint256 _block
        )
        external
        view
        returns(uint256);

    function userShares(address userAddress)
        external
        view
        returns(uint256);

    function userStake(address userAddress)
        external
        view
        returns(uint256);

    function delegatedToUserAt(
        address userAddress,
        uint256 _block
        )
        external
        view
        returns(uint256);

    function delegatedToUser(address userAddress)
        external
        view
        returns(uint256);

    function userDelegateAt(
        address userAddress,
        uint256 _block
        )
        external
        view
        returns(address);

    function userDelegate(address userAddress)
        external
        view
        returns(address);

    function userLocked(address userAddress)
        external
        view
        returns(uint256);

    function getUser(address userAddress)
        external
        view
        returns(
            uint256 unstaked,
            uint256 vesting,
            uint256 unstakeShares,
            uint256 unstakeAmount,
            uint256 unstakeScheduledFor,
            uint256 lastDelegationUpdateTimestamp,
            uint256 lastProposalTimestamp
            );
}


// File contracts/GetterUtils.sol

pragma solidity 0.8.4;


/// @title Contract that implements getters
abstract contract GetterUtils is StateUtils, IGetterUtils {
    /// @notice Called to get the voting power of a user at a specific block
    /// @param userAddress User address
    /// @param _block Block number for which the query is being made for
    /// @return Voting power of the user at the block
    function userVotingPowerAt(
        address userAddress,
        uint256 _block
        )
        public
        view
        override
        returns (uint256)
    {
        // Users that have a delegate have no voting power
        if (userDelegateAt(userAddress, _block) != address(0))
        {
            return 0;
        }
        return userSharesAt(userAddress, _block)
            + delegatedToUserAt(userAddress, _block);
    }

    /// @notice Called to get the current voting power of a user
    /// @param userAddress User address
    /// @return Current voting power of the user
    function userVotingPower(address userAddress)
        external
        view
        override
        returns (uint256)
    {
        return userVotingPowerAt(userAddress, block.number);
    }

    /// @notice Called to get the total voting power one block ago
    /// @dev This method is meant to be used by the API3 DAO's Api3Voting apps
    /// to get the total voting power at vote creation-time
    /// @return Total voting power one block ago
    function totalVotingPowerOneBlockAgo()
        external
        view
        override
        returns (uint256)
    {
        return totalSharesOneBlockAgo();
    }

    /// @notice Called to get the current total voting power
    /// @return Current total voting power
    function totalVotingPower()
        external
        view
        override
        returns (uint256)
    {
        return totalShares();
    }

    /// @notice Called to get the pool shares of a user at a specific block
    /// @param userAddress User address
    /// @param _block Block number for which the query is being made for
    /// @return Pool shares of the user at the block
    function userSharesAt(
        address userAddress,
        uint256 _block
        )
        public
        view
        override
        returns (uint256)
    {
        return getValueAt(users[userAddress].shares, _block);
    }

    /// @notice Called to get the current pool shares of a user
    /// @param userAddress User address
    /// @return Current pool shares of the user
    function userShares(address userAddress)
        public
        view
        override
        returns (uint256)
    {
        return userSharesAt(userAddress, block.number);
    }

    /// @notice Called to get the current staked tokens of the user
    /// @param userAddress User address
    /// @return Current staked tokens of the user
    function userStake(address userAddress)
        public
        view
        override
        returns (uint256)
    {
        return (userShares(userAddress) * totalStake) / totalShares();
    }

    /// @notice Called to get the voting power delegated to a user at a
    /// specific block
    /// @param userAddress User address
    /// @param _block Block number for which the query is being made for
    /// @return Voting power delegated to the user at the block
    function delegatedToUserAt(
        address userAddress,
        uint256 _block
        )
        public
        view
        override
        returns (uint256)
    {
        return getValueAt(users[userAddress].delegatedTo, _block);
    }

    /// @notice Called to get the current voting power delegated to a user
    /// @param userAddress User address
    /// @return Current voting power delegated to the user
    function delegatedToUser(address userAddress)
        public
        view
        override
        returns (uint256)
    {
        return delegatedToUserAt(userAddress, block.number);
    }

    /// @notice Called to get the delegate of the user at a specific block
    /// @param userAddress User address
    /// @param _block Block number
    /// @return Delegate of the user at the specific block
    function userDelegateAt(
        address userAddress,
        uint256 _block
        )
        public
        view
        override
        returns (address)
    {
        return getAddressAt(users[userAddress].delegates, _block);
    }

    /// @notice Called to get the current delegate of the user
    /// @param userAddress User address
    /// @return Current delegate of the user
    function userDelegate(address userAddress)
        public
        view
        override
        returns (address)
    {
        return userDelegateAt(userAddress, block.number);
    }

    /// @notice Called to get the current locked tokens of the user
    /// @param userAddress User address
    /// @return locked Current locked tokens of the user
    function userLocked(address userAddress)
        public
        view
        override
        returns (uint256 locked)
    {
        Checkpoint[] storage _userShares = users[userAddress].shares;
        uint256 currentEpoch = block.timestamp / epochLength;
        uint256 oldestLockedEpoch = currentEpoch - REWARD_VESTING_PERIOD > genesisEpoch
            ? currentEpoch - REWARD_VESTING_PERIOD + 1
            : genesisEpoch + 1;

        if (_userShares.length == 0)
        {
            return 0;
        }
        uint256 indUserShares = _userShares.length - 1;
        for (
                uint256 indEpoch = currentEpoch;
                indEpoch >= oldestLockedEpoch;
                indEpoch--
            )
        {
            Reward storage lockedReward = epochIndexToReward[indEpoch];
            if (lockedReward.atBlock != 0)
            {
                for (; indUserShares >= 0; indUserShares--)
                {
                    Checkpoint storage userShare = _userShares[indUserShares];
                    if (userShare.fromBlock <= lockedReward.atBlock)
                    {
                        locked += lockedReward.amount * userShare.value / lockedReward.totalSharesThen;
                        break;
                    }
                }
            }
        }
    }

    /// @notice Called to get the details of a user
    /// @param userAddress User address
    /// @return unstaked Amount of unstaked API3 tokens
    /// @return vesting Amount of API3 tokens locked by vesting
    /// @return unstakeShares Shares revoked to unstake
    /// @return unstakeAmount Amount scheduled to unstake
    /// @return unstakeScheduledFor Time unstaking is scheduled for
    /// @return lastDelegationUpdateTimestamp Time of last delegation update
    /// @return lastProposalTimestamp Time when the user made their most
    /// recent proposal
    function getUser(address userAddress)
        external
        view
        override
        returns (
            uint256 unstaked,
            uint256 vesting,
            uint256 unstakeShares,
            uint256 unstakeAmount,
            uint256 unstakeScheduledFor,
            uint256 lastDelegationUpdateTimestamp,
            uint256 lastProposalTimestamp
            )
    {
        User storage user = users[userAddress];
        unstaked = user.unstaked;
        vesting = user.vesting;
        unstakeShares = user.unstakeShares;
        unstakeAmount = user.unstakeAmount;
        unstakeScheduledFor = user.unstakeScheduledFor;
        lastDelegationUpdateTimestamp = user.lastDelegationUpdateTimestamp;
        lastProposalTimestamp = user.lastProposalTimestamp;
    }

    /// @notice Called to get the value of a checkpoint array at a specific
    /// block using binary search
    /// @dev Adapted from
    /// https://github.com/aragon/minime/blob/1d5251fc88eee5024ff318d95bc9f4c5de130430/contracts/MiniMeToken.sol#L431
    /// @param checkpoints Checkpoints array
    /// @param _block Block number for which the query is being made
    /// @return Value of the checkpoint array at the block
    function getValueAt(
        Checkpoint[] storage checkpoints,
        uint256 _block
        )
        internal
        view
        returns (uint256)
    {
        if (checkpoints.length == 0)
            return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length -1].fromBlock)
            return checkpoints[checkpoints.length - 1].value;
        if (_block < checkpoints[0].fromBlock)
            return 0;

        // Limit the search to the last 1024 elements if the value being
        // searched falls within that window
        uint min;
        if (
            checkpoints.length > 1024
                && checkpoints[checkpoints.length - 1024].fromBlock < _block
            )
        {
            min = checkpoints.length - 1024;
        }
        else
        {
            min = 0;
        }

        // Binary search of the value in the array
        uint max = checkpoints.length - 1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return checkpoints[min].value;
    }

    /// @notice Called to get the value of an address-checkpoint array at a
    /// specific block using binary search
    /// @dev Adapted from
    /// https://github.com/aragon/minime/blob/1d5251fc88eee5024ff318d95bc9f4c5de130430/contracts/MiniMeToken.sol#L431
    /// @param checkpoints Address-checkpoint array
    /// @param _block Block number for which the query is being made
    /// @return Value of the address-checkpoint array at the block
    function getAddressAt(
        AddressCheckpoint[] storage checkpoints,
        uint256 _block
        )
        private
        view
        returns (address)
    {
        if (checkpoints.length == 0)
            return address(0);

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length -1].fromBlock)
            return checkpoints[checkpoints.length - 1]._address;
        if (_block < checkpoints[0].fromBlock)
            return address(0);

        // Limit the search to the last 1024 elements if the value being
        // searched falls within that window
        uint min;
        if (
            checkpoints.length > 1024
                && checkpoints[checkpoints.length - 1024].fromBlock < _block
            )
        {
            min = checkpoints.length - 1024;
        }
        else
        {
            min = 0;
        }

        // Binary search of the value in the array
        uint max = checkpoints.length - 1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return checkpoints[min]._address;
    }
}


// File contracts/interfaces/IRewardUtils.sol

pragma solidity 0.8.4;

interface IRewardUtils is IGetterUtils {
    event MintedReward(
        uint256 indexed epoch,
        uint256 rewardAmount,
        uint256 apr
        );

    function mintReward()
        external;
}


// File contracts/RewardUtils.sol

pragma solidity 0.8.4;


/// @title Contract that implements reward payments and locks
abstract contract RewardUtils is GetterUtils, IRewardUtils {
    /// @notice Called to mint the staking reward
    /// @dev Skips past epochs for which rewards have not been paid for.
    /// Skips the reward payment if the pool is not authorized to mint tokens.
    /// Neither of these conditions will occur in practice.
    function mintReward()
        public
        override
    {
        uint256 currentEpoch = block.timestamp / epochLength;
        // This will be skipped in most cases because someone else will have
        // triggered the payment for this epoch
        if (epochIndexOfLastRewardPayment < currentEpoch)
        {
            if (api3Token.getMinterStatus(address(this)))
            {
                uint256 rewardAmount = totalStake * currentApr * epochLength / ONE_YEAR_IN_SECONDS / HUNDRED_PERCENT;
                epochIndexToReward[currentEpoch] = Reward({
                    atBlock: block.number,
                    amount: rewardAmount,
                    totalSharesThen: totalShares()
                    });
                api3Token.mint(address(this), rewardAmount);
                totalStake = totalStake + rewardAmount;
                emit MintedReward(
                    currentEpoch,
                    rewardAmount,
                    currentApr
                    );
                updateCurrentApr();
            }
            epochIndexOfLastRewardPayment = currentEpoch;
        }
    }

    /// @notice Updates the current APR
    /// @dev Called internally after paying out the reward
    function updateCurrentApr()
        internal
    {
        uint256 totalStakePercentage = totalStake
            * HUNDRED_PERCENT
            / api3Token.totalSupply();
        if (totalStakePercentage > stakeTarget) {
            currentApr = currentApr > aprUpdateStep ? currentApr - aprUpdateStep : 0;
        }
        else {
            currentApr += aprUpdateStep;
        }
        if (currentApr > maxApr) {
            currentApr = maxApr;
        }
        else if (currentApr < minApr) {
            currentApr = minApr;
        }
    }
}


// File contracts/interfaces/IDelegationUtils.sol

pragma solidity 0.8.4;

interface IDelegationUtils is IRewardUtils {
    event Delegated(
        address indexed user,
        address indexed delegate
        );

    event Undelegated(
        address indexed user,
        address indexed delegate
        );

    function delegateVotingPower(address delegate) 
        external;

    function undelegateVotingPower()
        external;

    
}


// File contracts/DelegationUtils.sol

pragma solidity 0.8.4;


/// @title Contract that implements voting power delegation
abstract contract DelegationUtils is RewardUtils, IDelegationUtils {
    /// @notice Called by the user to delegate voting power
    /// @param delegate User address the voting power will be delegated to
    function delegateVotingPower(address delegate) 
        external
        override
    {
        mintReward();
        require(
            delegate != address(0) && delegate != msg.sender,
            "Pool: Invalid delegate"
            );
        // Delegating users have cannot use their voting power, so we are
        // verifying that the delegate is not currently delegating. However,
        // the delegate may delegate after they have been delegated to.
        require(
            userDelegate(delegate) == address(0),
            "Pool: Delegate is delegating"
            );
        User storage user = users[msg.sender];
        // Do not allow frequent delegation updates as that can be used to spam
        // proposals
        require(
            user.lastDelegationUpdateTimestamp + epochLength < block.timestamp,
            "Pool: Updated delegate recently"
            );
        user.lastDelegationUpdateTimestamp = block.timestamp;
        
        address previousDelegate = userDelegate(msg.sender);
        require(
            previousDelegate != delegate,
            "Pool: Already delegated"
            );

        uint256 userShares = userShares(msg.sender);
        require(
            userShares != 0,
            "Pool: Have no shares to delegate"
            );
        if (previousDelegate != address(0)) {
            // Need to revoke previous delegation
            users[previousDelegate].delegatedTo.push(Checkpoint({
                fromBlock: block.number,
                value: delegatedToUser(previousDelegate) - userShares
                }));
            emit Undelegated(
                msg.sender,
                previousDelegate
                );
        }
        // Assign the new delegation
        User storage _delegate = users[delegate];
        _delegate.delegatedTo.push(Checkpoint({
            fromBlock: block.number,
            value: delegatedToUser(delegate) + userShares
            }));
        // Record the new delegate for the user
        user.delegates.push(AddressCheckpoint({
            fromBlock: block.number,
            _address: delegate
            }));
        emit Delegated(
            msg.sender,
            delegate
            );
    }

    /// @notice Called by the user to undelegate voting power
    function undelegateVotingPower()
        external
        override
    {
        mintReward();
        User storage user = users[msg.sender];
        address previousDelegate = userDelegate(msg.sender);
        require(
            previousDelegate != address(0),
            "Pool: Not delegated"
            );
        require(
            user.lastDelegationUpdateTimestamp + epochLength < block.timestamp,
            "Pool: Updated delegate recently"
            );

        uint256 userShares = userShares(msg.sender);
        User storage delegate = users[previousDelegate];
        delegate.delegatedTo.push(Checkpoint({
            fromBlock: block.number,
            value: delegatedToUser(previousDelegate) - userShares
            }));
        user.delegates.push(AddressCheckpoint({
            fromBlock: block.number,
            _address: address(0)
            }));
        user.lastDelegationUpdateTimestamp = block.timestamp;
        emit Undelegated(
            msg.sender,
            previousDelegate
            );
    }

    /// @notice Called internally when the user shares are updated to update
    /// the delegated voting power
    /// @dev User shares only get updated while staking or unstaking
    /// @param shares Amount of shares that will be added/removed
    /// @param delta Whether the shares will be added/removed (add for `true`,
    /// and vice versa)
    function updateDelegatedVotingPower(
        uint256 shares,
        bool delta
        )
        internal
    {
        address currentDelegate = userDelegate(msg.sender);
        if (currentDelegate == address(0)) {
            return;
        }

        User storage delegate = users[currentDelegate];
        uint256 currentlyDelegatedTo = delegatedToUser(currentDelegate);
        uint256 newDelegatedTo;
        if (delta) {
            newDelegatedTo = currentlyDelegatedTo + shares;
        } else {
            newDelegatedTo = currentlyDelegatedTo - shares;
        }
        delegate.delegatedTo.push(Checkpoint({
            fromBlock: block.number,
            value: newDelegatedTo
            }));
    }
}


// File contracts/interfaces/ITransferUtils.sol

pragma solidity 0.8.4;

interface ITransferUtils is IDelegationUtils{
    event Deposited(
        address indexed user,
        uint256 amount
        );

    event Withdrawn(
        address indexed user,
        uint256 amount
        );

    event CalculatingUserLocked(
        address indexed user,
        uint256 nextIndEpoch,
        uint256 oldestLockedEpoch
        );

    event CalculatedUserLocked(
        address indexed user,
        uint256 amount
        );

    function depositRegular(uint256 amount)
        external;

    function withdrawRegular(uint256 amount)
        external;

    function precalculateUserLocked(
        address userAddress,
        uint256 noEpochsPerIteration
        )
        external
        returns (bool finished);

    function withdrawPrecalculated(uint256 amount)
        external;
}


// File contracts/TransferUtils.sol

pragma solidity 0.8.4;


/// @title Contract that implements token transfer functionality
abstract contract TransferUtils is DelegationUtils, ITransferUtils {
    /// @notice Called by the user to deposit tokens
    /// @dev The user should approve the pool to spend at least `amount` tokens
    /// before calling this.
    /// The method is named `depositRegular()` to prevent potential confusion
    /// (for example it is difficult to differentiate overloaded functions in
    /// JS). See `deposit()` for more context.
    /// @param amount Amount to be deposited
    function depositRegular(uint256 amount)
        public
        override
    {
        mintReward();
        users[msg.sender].unstaked = users[msg.sender].unstaked + amount;
        // Should never return false because the API3 token uses the
        // OpenZeppelin implementation
        assert(api3Token.transferFrom(msg.sender, address(this), amount));
        emit Deposited(
            msg.sender,
            amount
            );
    }

    /// @notice Called by the user to withdraw tokens to their wallet
    /// @dev The user should call `userLocked()` beforehand to ensure that
    /// they have at least `amount` unlocked tokens to withdraw.
    /// The method is named `withdrawRegular()` to be consistent with the name
    /// `depositRegular()`. See `depositRegular()` for more context.
    /// @param amount Amount to be withdrawn
    function withdrawRegular(uint256 amount)
        public
        override
    {
        mintReward();
        withdraw(amount, userLocked(msg.sender));
    }

    /// @notice Called to calculate the locked tokens of a user by making
    /// multiple transactions
    /// @dev If the user updates their `user.shares` by staking/unstaking too
    /// frequently (50+/week) in the last `REWARD_VESTING_PERIOD`, the
    /// `userLocked()` call gas cost may exceed the block gas limit. In that
    /// case, the user may call this method multiple times to have their locked
    /// tokens calculated.
    /// @param userAddress User address
    /// @param noEpochsPerIteration Number of epochs per iteration
    /// @return finished Calculation has finished in this call
    function precalculateUserLocked(
        address userAddress,
        uint256 noEpochsPerIteration
        )
        external
        override
        returns (bool finished)
    {
        require(
            noEpochsPerIteration > 0,
            "Pool: Zero iteration window"
            );
        mintReward();
        Checkpoint[] storage _userShares = users[userAddress].shares;
        uint256 userSharesLength = _userShares.length;
        require(
            userSharesLength != 0,
            "Pool: User never had shares"
            );
        uint256 currentEpoch = block.timestamp / epochLength;
        LockedCalculationState storage state = userToLockedCalculationState[userAddress];
        // Reset the state if there was no calculation made in this epoch
        if (state.initialIndEpoch != currentEpoch)
        {
            state.initialIndEpoch = currentEpoch;
            state.nextIndEpoch = currentEpoch;
            state.locked = 0;
        }
        uint256 indEpoch = state.nextIndEpoch;
        uint256 locked = state.locked;
        uint256 oldestLockedEpoch = currentEpoch - REWARD_VESTING_PERIOD > genesisEpoch
            ? currentEpoch - REWARD_VESTING_PERIOD + 1
            : genesisEpoch + 1;
        for (; indEpoch >= oldestLockedEpoch; indEpoch--)
        {
            if (state.nextIndEpoch >= indEpoch + noEpochsPerIteration)
            {
                state.nextIndEpoch = indEpoch;
                state.locked = locked;
                emit CalculatingUserLocked(
                    userAddress,
                    indEpoch,
                    oldestLockedEpoch
                    );
                return false;
            }
            Reward storage lockedReward = epochIndexToReward[indEpoch];
            if (lockedReward.atBlock != 0)
            {
                uint256 userSharesThen = getValueAt(_userShares, lockedReward.atBlock);
                locked = locked + (lockedReward.amount * userSharesThen / lockedReward.totalSharesThen);
            }
        }
        state.nextIndEpoch = indEpoch;
        state.locked = locked;
        emit CalculatedUserLocked(userAddress, locked);
        return true;
    }

    /// @notice Called by the user to withdraw after their locked token amount
    /// is calculated with repeated calls to `precalculateUserLocked()`
    /// @dev Only use `precalculateUserLocked()` and this method if
    /// `withdrawRegular()` hits the block gas limit
    /// @param amount Amount to be withdrawn
    function withdrawPrecalculated(uint256 amount)
        external
        override
    {
        mintReward();
        uint256 currentEpoch = block.timestamp / epochLength;
        LockedCalculationState storage state = userToLockedCalculationState[msg.sender];
        require(
            state.initialIndEpoch == currentEpoch,
            "Pool: Locked not precalculated"
            );
        withdraw(amount, state.locked);
    }

    /// @notice Called internally after the amount of locked tokens of the user
    /// is determined
    /// @param amount Amount to be withdrawn
    /// @param userLocked Amount of locked tokens of the user
    function withdraw(
        uint256 amount,
        uint256 userLocked
        )
        private
    {
        User storage user = users[msg.sender];
        // Check if the user has `amount` unlocked tokens to withdraw
        uint256 lockedAndVesting = userLocked + user.vesting;
        uint256 userTotalFunds = user.unstaked + userStake(msg.sender);
        require(
            userTotalFunds >= lockedAndVesting + amount,
            "Pool: Not enough unlocked funds"
            );
        // Carry on with the withdrawal
        require(
            user.unstaked >= amount,
            "Pool: Not enough unstaked funds"
            );
        user.unstaked = user.unstaked - amount;
        // Should never return false because the API3 token uses the
        // OpenZeppelin implementation
        assert(api3Token.transfer(msg.sender, amount));
        emit Withdrawn(
            msg.sender,
            amount
            );
    }
}


// File contracts/interfaces/IStakeUtils.sol

pragma solidity 0.8.4;

interface IStakeUtils is ITransferUtils{
    event Staked(
        address indexed user,
        uint256 amount
        );

    event ScheduledUnstake(
        address indexed user,
        uint256 shares,
        uint256 amount,
        uint256 scheduledFor
        );

    event Unstaked(
        address indexed user,
        uint256 amount
        );

    function stake(uint256 amount)
        external;

    function depositAndStake(uint256 amount)
        external;

    function scheduleUnstake(uint256 amount)
        external;

    function unstake(address userAddress)
        external
        returns (uint256);

    function unstakeAndWithdraw()
        external;
}


// File contracts/StakeUtils.sol

pragma solidity 0.8.4;


/// @title Contract that implements staking functionality
abstract contract StakeUtils is TransferUtils, IStakeUtils {
    /// @notice Called to stake tokens to receive pools in the share
    /// @param amount Amount of tokens to stake
    function stake(uint256 amount)
        public
        override
    {
        mintReward();
        User storage user = users[msg.sender];
        require(
            user.unstaked >= amount,
            "Pool: Amount exceeds unstaked"
            );
        user.unstaked = user.unstaked - amount;
        uint256 totalSharesNow = totalShares();
        uint256 sharesToMint = totalSharesNow * amount / totalStake;
        uint256 userSharesNow = userShares(msg.sender);
        user.shares.push(Checkpoint({
            fromBlock: block.number,
            value: userSharesNow + sharesToMint
            }));
        uint256 totalSharesAfter = totalSharesNow + sharesToMint; 
        updateTotalShares(totalSharesAfter);
        totalStake = totalStake + amount;
        updateDelegatedVotingPower(sharesToMint, true);
        emit Staked(
            msg.sender,
            amount
            );
    }

    /// @notice Convenience method to deposit and stake in a single transaction
    /// @param amount Amount to be deposited and staked
    function depositAndStake(uint256 amount)
        external
        override
    {
        depositRegular(amount);
        stake(amount);
    }

    /// @notice Called by the user to schedule unstaking of their tokens
    /// @dev While scheduling an unstake, `shares` get deducted from the user,
    /// meaning that they will not receive rewards or voting power for them any
    /// longer.
    /// At unstaking-time, the user unstakes either the amount of tokens
    /// `shares` corresponds to at scheduling-time, or the amount of tokens
    /// `shares` corresponds to at unstaking-time, whichever is smaller. This
    /// corresponds to tokens being scheduled to be unstaked not receiving any
    /// rewards, but being subject to claim payouts.
    /// In the instance that a claim has been paid out before an unstaking is
    /// executed, the user may potentially receive rewards during
    /// `unstakeWaitPeriod` (but not if there has not been a claim payout) but
    /// the amount of tokens that they can unstake will not be able to exceed
    /// the amount they scheduled the unstaking for.
    /// @param shares Amount of shares to be revoked to unstake tokens
    function scheduleUnstake(uint256 shares)
        external
        override
    {
        mintReward();
        uint256 userSharesNow = userShares(msg.sender);
        require(
            userSharesNow >= shares,
            "Pool: Amount exceeds user shares"
            );
        User storage user = users[msg.sender];
        require(
            user.unstakeScheduledFor == 0,
            "Pool: Unexecuted unstake exists"
            );
        uint256 amount = (shares * totalStake) / totalShares();
        user.unstakeScheduledFor = block.timestamp + unstakeWaitPeriod;
        user.unstakeAmount = amount;
        user.unstakeShares = shares;
        user.shares.push(
            Checkpoint({fromBlock: block.number, value: userSharesNow - shares})
        );
        updateDelegatedVotingPower(shares, false);
        emit ScheduledUnstake(
            msg.sender,
            shares,
            amount,
            user.unstakeScheduledFor
        );
    }

    /// @notice Called to execute a pre-scheduled unstake
    /// @dev Note that anyone can execute a matured unstake. This is to allow
    /// the user to use bots, etc. to execute their unstaking as soon as
    /// possible.
    /// @param userAddress User address
    /// @return Amount of tokens that are unstaked
    function unstake(address userAddress)
        public
        override
        returns (uint256)
    {
        mintReward();
        User storage user = users[userAddress];
        require(
            user.unstakeScheduledFor != 0,
            "Pool: No unstake scheduled"
            );
        require(
            user.unstakeScheduledFor < block.timestamp,
            "Pool: Unstake not mature yet"
            );
        uint256 totalShares = totalShares();
        uint256 unstakeAmountAtSchedulingTime = user.unstakeAmount;
        uint256 unstakeAmountByShares =
            (user.unstakeShares * totalStake) / totalShares;
        uint256 unstakeAmount =
            unstakeAmountAtSchedulingTime > unstakeAmountByShares
                ? unstakeAmountByShares
                : unstakeAmountAtSchedulingTime;
        unstakeAmount = unstakeAmount < totalStake
            ? unstakeAmount
            : totalStake - 1;
        user.unstaked = user.unstaked + unstakeAmount;

        updateTotalShares(totalShares - user.unstakeShares);
        totalStake = totalStake - unstakeAmount;

        user.unstakeShares = 0;
        user.unstakeAmount = 0;
        user.unstakeScheduledFor = 0;
        emit Unstaked(userAddress, unstakeAmount);
        return unstakeAmount;
    }

    /// @notice Convenience method to execute an unstake and withdraw to the
    /// user's wallet in a single transaction
    /// @dev Note that withdraw may revert because the user may have less than
    /// `unstaked` tokens that are withdrawable
    function unstakeAndWithdraw()
        external
        override
    {
        uint256 unstaked = unstake(msg.sender);
        withdrawRegular(unstaked);
    }
}


// File contracts/interfaces/IClaimUtils.sol

pragma solidity 0.8.4;

interface IClaimUtils is IStakeUtils {
    event PaidOutClaim(
        address indexed recipient,
        uint256 amount
        );

    function payOutClaim(
        address recipient,
        uint256 amount
        )
        external;
}


// File contracts/ClaimUtils.sol

pragma solidity 0.8.4;


/// @title Contract that implements the insurance claim payout functionality
abstract contract ClaimUtils is StakeUtils, IClaimUtils {
    /// @dev Reverts if the caller is not a claims manager
    modifier onlyClaimsManager() {
        require(
            claimsManagerStatus[msg.sender],
            "Pool: Caller not claims manager"
            );
        _;
    }

    /// @notice Called by a claims manager to pay out an insurance claim
    /// @dev The claims manager is a trusted contract that is allowed to
    /// withdraw as many tokens as it wants from the pool to pay out insurance
    /// claims. Any kind of limiting logic (e.g., maximum amount of tokens that
    /// can be withdrawn) is implemented at its end and is out of the scope of
    /// this contract.
    /// This will revert if the pool does not have enough funds.
    /// @param recipient Recipient of the claim
    /// @param amount Amount of tokens that will be paid out
    function payOutClaim(
        address recipient,
        uint256 amount
        )
        external
        override
        onlyClaimsManager()
    {
        mintReward();
        // totalStake should not go lower than 1
        require(
            totalStake > amount,
            "Pool: Amount exceeds total stake"
            );
        totalStake = totalStake - amount;
        // Should never return false because the API3 token uses the
        // OpenZeppelin implementation
        assert(api3Token.transfer(recipient, amount));
        emit PaidOutClaim(
            recipient,
            amount
            );
    }
}


// File contracts/interfaces/ITimelockUtils.sol

pragma solidity 0.8.4;

interface ITimelockUtils is IClaimUtils {
    event DepositedByTimelockManager(
        address indexed user,
        uint256 amount
        );

    event DepositedVesting(
        address indexed user,
        uint256 amount,
        uint256 start,
        uint256 end
        );

    event UpdatedTimelock(
        address indexed user,
        uint256 remainingAmount
        );

    function deposit(
        address source,
        uint256 amount,
        address userAddress
        )
        external;

    function depositWithVesting(
        address source,
        uint256 amount,
        address userAddress,
        uint256 releaseStart,
        uint256 releaseEnd
        )
        external;

    function updateTimelockStatus(address userAddress)
        external;
}


// File contracts/TimelockUtils.sol

pragma solidity 0.8.4;


/// @title Contract that implements vesting functionality
/// @dev The TimelockManager contract interfaces with this contract to transfer
/// API3 tokens that are locked under a vesting schedule
abstract contract TimelockUtils is ClaimUtils, ITimelockUtils {
    struct Timelock
    {
        uint256 totalAmount;
        uint256 remainingAmount;
        uint256 releaseStart;
        uint256 releaseEnd;
    }

    /// @notice Maps user addresses to timelocks
    /// @dev This implies that a user cannot have multiple timelocks
    /// transferrerd from the TimelockManager contract. This is acceptable
    /// because the TimelockManager is implemented in a way to not allow
    /// multiple timelocks per user.
    mapping(address => Timelock) public userToTimelock;

    /// @notice Called by the TimelockManager contract to deposit tokens on
    /// behalf of a user
    /// @dev This method is only usable by `TimelockManager.sol`.
    /// It is named as `deposit()` and not `depositByTimelockManager()` for
    /// example because the TimelockManager is already deployed and expects the
    /// `deposit(address,uint256,address)` interface.
    /// @param source Token transfer source
    /// @param amount Amount to be deposited
    /// @param userAddress User that the tokens will be deposited for
    function deposit(
        address source,
        uint256 amount,
        address userAddress
        )
        external
        override
    {
        require(
            msg.sender == timelockManager,
            "Pool: Caller not TimelockManager"
            );
        users[userAddress].unstaked = users[userAddress].unstaked + amount;
        // Should never return false because the API3 token uses the
        // OpenZeppelin implementation
        assert(api3Token.transferFrom(source, address(this), amount));
        emit DepositedByTimelockManager(
            userAddress,
            amount
            );
    }

    /// @notice Called by the TimelockManager contract to deposit tokens on
    /// behalf of a user on a linear vesting schedule
    /// @dev Refer to `TimelockManager.sol` to see how this is used
    /// @param source Token source
    /// @param amount Token amount
    /// @param userAddress Address of the user who will receive the tokens
    /// @param releaseStart Vesting schedule starting time
    /// @param releaseEnd Vesting schedule ending time
    function depositWithVesting(
        address source,
        uint256 amount,
        address userAddress,
        uint256 releaseStart,
        uint256 releaseEnd
        )
        external
        override
    {
        require(
            msg.sender == timelockManager,
            "Pool: Caller not TimelockManager"
            );
        require(
            userToTimelock[userAddress].remainingAmount == 0,
            "Pool: User has active timelock"
            );
        require(
            releaseEnd > releaseStart,
            "Pool: Timelock start after end"
            );
        require(
            amount != 0,
            "Pool: Timelock amount zero"
            );
        users[userAddress].unstaked = users[userAddress].unstaked + amount;
        users[userAddress].vesting = users[userAddress].vesting + amount;
        userToTimelock[userAddress] = Timelock({
            totalAmount: amount,
            remainingAmount: amount,
            releaseStart: releaseStart,
            releaseEnd: releaseEnd
            });
        // Should never return false because the API3 token uses the
        // OpenZeppelin implementation
        assert(api3Token.transferFrom(source, address(this), amount));
        emit DepositedVesting(
            userAddress,
            amount,
            releaseStart,
            releaseEnd
            );
    }

    /// @notice Called to release tokens vested by the timelock
    /// @param userAddress Address of the user whose timelock status will be
    /// updated
    function updateTimelockStatus(address userAddress)
        external
        override
    {
        Timelock storage timelock = userToTimelock[userAddress];
        require(
            block.timestamp > timelock.releaseStart,
            "Pool: Release not started yet"
            );
        require(
            timelock.remainingAmount > 0,
            "Pool: Timelock already released"
            );
        uint256 totalUnlocked;
        if (block.timestamp >= timelock.releaseEnd)
        {
            totalUnlocked = timelock.totalAmount;
        }
        else
        {
            uint256 passedTime = block.timestamp - timelock.releaseStart;
            uint256 totalTime = timelock.releaseEnd - timelock.releaseStart;
            totalUnlocked = timelock.totalAmount * passedTime / totalTime;
        }
        uint256 previouslyUnlocked = timelock.totalAmount - timelock.remainingAmount;
        uint256 newlyUnlocked = totalUnlocked - previouslyUnlocked;
        User storage user = users[userAddress];
        user.vesting = user.vesting - newlyUnlocked;
        uint256 newRemainingAmount = timelock.remainingAmount - newlyUnlocked;
        userToTimelock[userAddress].remainingAmount = newRemainingAmount;
        emit UpdatedTimelock(
            userAddress,
            newRemainingAmount
            );
    }
}


// File contracts/interfaces/IApi3Pool.sol

pragma solidity 0.8.4;

interface IApi3Pool is ITimelockUtils {
}


// File contracts/Api3Pool.sol

pragma solidity 0.8.4;


/// @title API3 pool contract
/// @notice Users can stake API3 tokens at the pool contract to be granted
/// shares. These shares are exposed to the Aragon-based DAO, giving the user
/// voting power at the DAO. Staking pays out weekly rewards that get unlocked
/// after a year, and staked funds are used to collateralize an insurance
/// product that is outside the scope of this contract.
/// @dev Functionalities of the contract are distributed to files that form a
/// chain of inheritance:
/// (1) Api3Pool.sol
/// (2) TimelockUtils.sol
/// (3) ClaimUtils.sol
/// (4) StakeUtils.sol
/// (5) TransferUtils.sol
/// (6) DelegationUtils.sol
/// (7) RewardUtils.sol
/// (8) GetterUtils.sol
/// (9) StateUtils.sol
contract Api3Pool is TimelockUtils, IApi3Pool {
    /// @param api3TokenAddress API3 token contract address
    /// @param timelockManagerAddress Timelock manager contract address
    /// @param _epochLength Epoch length in seconds
    constructor(
        address api3TokenAddress,
        address timelockManagerAddress,
        uint256 _epochLength
        )
        StateUtils(
            api3TokenAddress,
            timelockManagerAddress,
            _epochLength
            )
    {}
}