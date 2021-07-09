/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// Sources flattened with hardhat v2.4.0 https://hardhat.org

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
        returns (bool minterStatus);

    function getBurnerStatus(address burnerAddress)
        external
        view
        returns (bool burnerStatus);
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
        address indexed claimsManager,
        bool indexed status
        );

    event SetStakeTarget(uint256 stakeTarget);

    event SetMaxApr(uint256 maxApr);

    event SetMinApr(uint256 minApr);

    event SetUnstakeWaitPeriod(uint256 unstakeWaitPeriod);

    event SetAprUpdateStep(uint256 aprUpdateStep);

    event SetProposalVotingPowerThreshold(uint256 proposalVotingPowerThreshold);

    event UpdatedLastProposalTimestamp(
        address indexed user,
        uint256 lastProposalTimestamp,
        address votingApp
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
        uint32 fromBlock;
        uint224 value;
    }

    struct AddressCheckpoint {
        uint32 fromBlock;
        address _address;
    }

    struct Reward {
        uint32 atBlock;
        uint224 amount;
        uint256 totalSharesThen;
        uint256 totalStakeThen;
    }

    struct User {
        Checkpoint[] shares;
        Checkpoint[] delegatedTo;
        AddressCheckpoint[] delegates;
        uint256 unstaked;
        uint256 vesting;
        uint256 unstakeAmount;
        uint256 unstakeShares;
        uint256 unstakeScheduledFor;
        uint256 lastDelegationUpdateTimestamp;
        uint256 lastProposalTimestamp;
    }

    struct LockedCalculation {
        uint256 initialIndEpoch;
        uint256 nextIndEpoch;
        uint256 locked;
    }

    /// @notice Length of the epoch in which the staking reward is paid out
    /// once. It is hardcoded as 7 days.
    /// @dev In addition to regulating reward payments, this variable is used
    /// for two additional things:
    /// (1) After a user makes a proposal, they cannot make a second one
    /// before `EPOCH_LENGTH` has passed
    /// (2) After a user updates their delegation status, they have to wait
    /// `EPOCH_LENGTH` before updating it again
    uint256 public constant EPOCH_LENGTH = 1 weeks;

    /// @notice Number of epochs before the staking rewards get unlocked.
    /// Hardcoded as 52 epochs, which approximately corresponds to a year with
    /// an `EPOCH_LENGTH` of 1 week.
    uint256 public constant REWARD_VESTING_PERIOD = 52;

    // All percentage values are represented as 1e18 = 100%
    uint256 internal constant ONE_PERCENT = 1e18 / 100;
    uint256 internal constant HUNDRED_PERCENT = 1e18;

    // To assert that typecasts do not overflow
    uint256 internal constant MAX_UINT32 = 2**32 - 1;
    uint256 internal constant MAX_UINT224 = 2**224 - 1;

    /// @notice Epochs are indexed as `block.timestamp / EPOCH_LENGTH`.
    /// `genesisEpoch` is the index of the epoch in which the pool is deployed.
    /// @dev No reward gets paid and proposals are not allowed in the genesis
    /// epoch
    uint256 public immutable genesisEpoch;

    /// @notice API3 token contract
    IApi3Token public immutable api3Token;

    /// @notice TimelockManager contract
    address public immutable timelockManager;

    /// @notice Address of the primary Agent app of the API3 DAO
    /// @dev Primary Agent can be operated through the primary Api3Voting app.
    /// The primary Api3Voting app requires a higher quorum by default, and the
    /// primary Agent is more privileged.
    address public agentAppPrimary;

    /// @notice Address of the secondary Agent app of the API3 DAO
    /// @dev Secondary Agent can be operated through the secondary Api3Voting
    /// app. The secondary Api3Voting app requires a lower quorum by default,
    /// and the primary Agent is less privileged.
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

    /// @notice Records of rewards paid in each epoch
    /// @dev `.atBlock` of a past epoch's reward record being `0` means no
    /// reward was paid for that epoch
    mapping(uint256 => Reward) public epochIndexToReward;

    /// @notice Epoch index of the most recent reward
    uint256 public epochIndexOfLastReward;

    /// @notice Total number of tokens staked at the pool
    uint256 public totalStake;

    /// @notice Stake target the pool will aim to meet in percentages of the
    /// total token supply. The staking rewards increase if the total staked
    /// amount is below this, and vice versa.
    /// @dev Default value is 50% of the total API3 token supply. This
    /// parameter is governable by the DAO.
    uint256 public stakeTarget = ONE_PERCENT * 50;

    /// @notice Minimum APR (annual percentage rate) the pool will pay as
    /// staking rewards in percentages
    /// @dev Default value is 2.5%. This parameter is governable by the DAO.
    uint256 public minApr = ONE_PERCENT * 25 / 10;

    /// @notice Maximum APR (annual percentage rate) the pool will pay as
    /// staking rewards in percentages
    /// @dev Default value is 75%. This parameter is governable by the DAO.
    uint256 public maxApr = ONE_PERCENT * 75;

    /// @notice Steps in which APR will be updated in percentages
    /// @dev Default value is 1%. This parameter is governable by the DAO.
    uint256 public aprUpdateStep = ONE_PERCENT;

    /// @notice Users need to schedule an unstake and wait for
    /// `unstakeWaitPeriod` before being able to unstake. This is to prevent
    /// the stakers from frontrunning insurance claims by unstaking to evade
    /// them, or repeatedly unstake/stake to work around the proposal spam
    /// protection. The tokens awaiting to be unstaked during this period do
    /// not grant voting power or rewards.
    /// @dev This parameter is governable by the DAO, and the DAO is expected
    /// to set this to a value that is large enough to allow insurance claims
    /// to be resolved.
    uint256 public unstakeWaitPeriod = EPOCH_LENGTH;

    /// @notice Minimum voting power the users must have to be able to make
    /// proposals (in percentages)
    /// @dev Delegations count towards voting power.
    /// Default value is 0.1%. This parameter is governable by the DAO.
    uint256 public proposalVotingPowerThreshold = ONE_PERCENT / 10;

    /// @notice APR that will be paid next epoch
    /// @dev This value will reach an equilibrium based on the stake target.
    /// Every epoch (week), APR/52 of the total staked tokens will be added to
    /// the pool, effectively distributing them to the stakers.
    uint256 public apr = (maxApr + minApr) / 2;

    /// @notice User records
    mapping(address => User) public users;

    // Keeps the total number of shares of the pool
    Checkpoint[] public poolShares;

    // Keeps user states used in `withdrawPrecalculated()` calls
    mapping(address => LockedCalculation) public userToLockedCalculation;

    // Kept to prevent third parties from frontrunning the initialization
    // `setDaoApps()` call and grief the deployment
    address private deployer;

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
    constructor(
        address api3TokenAddress,
        address timelockManagerAddress
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
        deployer = msg.sender;
        api3Token = IApi3Token(api3TokenAddress);
        timelockManager = timelockManagerAddress;
        // Initialize the share price at 1
        updateCheckpointArray(poolShares, 1);
        totalStake = 1;
        // Set the current epoch as the genesis epoch and skip its reward
        // payment
        uint256 currentEpoch = block.timestamp / EPOCH_LENGTH;
        genesisEpoch = currentEpoch;
        epochIndexOfLastReward = currentEpoch;
    }

    /// @notice Called after deployment to set the addresses of the DAO apps
    /// @dev This can also be called later on by the primary Agent to update
    /// all app addresses as a means of an upgrade
    /// @param _agentAppPrimary Address of the primary Agent
    /// @param _agentAppSecondary Address of the secondary Agent
    /// @param _votingAppPrimary Address of the primary Api3Voting app
    /// @param _votingAppSecondary Address of the secondary Api3Voting app
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
                && _agentAppSecondary != address(0)
                && _votingAppPrimary != address(0)
                && _votingAppSecondary != address(0),
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

    /// @notice Called by the primary DAO Agent to set the authorization status
    /// of a claims manager contract
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
        stakeTarget = _stakeTarget;
        emit SetStakeTarget(_stakeTarget);
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
        maxApr = _maxApr;
        emit SetMaxApr(_maxApr);
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
        minApr = _minApr;
        emit SetMinApr(_minApr);
    }

    /// @notice Called by the primary DAO Agent to set the unstake waiting
    /// period
    /// @dev This may want to be increased to provide more time for insurance
    /// claims to be resolved.
    /// Even when the insurance functionality is not implemented, the minimum
    /// valid value is `EPOCH_LENGTH` to prevent users from unstaking,
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
            _unstakeWaitPeriod >= EPOCH_LENGTH,
            "Pool: Period shorter than epoch"
            );
        unstakeWaitPeriod = _unstakeWaitPeriod;
        emit SetUnstakeWaitPeriod(_unstakeWaitPeriod);
    }

    /// @notice Called by the primary DAO Agent to set the APR update steps
    /// @dev aprUpdateStep can be 0% or 100%+.
    /// Only the primary Agent can do this because it is a critical operation.
    /// @param _aprUpdateStep APR update steps
    function setAprUpdateStep(uint256 _aprUpdateStep)
        external
        override
        onlyAgentAppPrimary()
    {
        aprUpdateStep = _aprUpdateStep;
        emit SetAprUpdateStep(_aprUpdateStep);
    }

    /// @notice Called by the primary DAO Agent to set the voting power
    /// threshold for proposals
    /// @dev Only the primary Agent can do this because it is a critical
    /// operation.
    /// @param _proposalVotingPowerThreshold Voting power threshold for
    /// proposals
    function setProposalVotingPowerThreshold(uint256 _proposalVotingPowerThreshold)
        external
        override
        onlyAgentAppPrimary()
    {
        require(
            _proposalVotingPowerThreshold >= ONE_PERCENT / 10
                && _proposalVotingPowerThreshold <= ONE_PERCENT * 10,
            "Pool: Threshold outside limits");
        proposalVotingPowerThreshold = _proposalVotingPowerThreshold;
        emit SetProposalVotingPowerThreshold(_proposalVotingPowerThreshold);
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
            userAddress,
            block.timestamp,
            msg.sender
            );
    }

    /// @notice Called to check if we are in the genesis epoch
    /// @dev Voting apps use this to prevent proposals from being made in the
    /// genesis epoch
    /// @return If the current epoch is the genesis epoch
    function isGenesisEpoch()
        external
        view
        override
        returns (bool)
    {
        return block.timestamp / EPOCH_LENGTH == genesisEpoch;
    }

    /// @notice Called internally to update a checkpoint array by pushing a new
    /// checkpoint
    /// @dev We assume `block.number` will always fit in a uint32 and `value`
    /// will always fit in a uint224. `value` will either be a raw token amount
    /// or a raw pool share amount so this assumption will be correct in
    /// practice with a token with 18 decimals, 1e8 initial total supply and no
    /// hyperinflation.
    /// @param checkpointArray Checkpoint array
    /// @param value Value to be used to create the new checkpoint
    function updateCheckpointArray(
        Checkpoint[] storage checkpointArray,
        uint256 value
        )
        internal
    {
        assert(block.number <= MAX_UINT32);
        assert(value <= MAX_UINT224);
        checkpointArray.push(Checkpoint({
            fromBlock: uint32(block.number),
            value: uint224(value)
            }));
    }

    /// @notice Called internally to update an address-checkpoint array by
    /// pushing a new checkpoint
    /// @dev We assume `block.number` will always fit in a uint32
    /// @param addressCheckpointArray Address-checkpoint array
    /// @param _address Address to be used to create the new checkpoint
    function updateAddressCheckpointArray(
        AddressCheckpoint[] storage addressCheckpointArray,
        address _address
        )
        internal
    {
        assert(block.number <= MAX_UINT32);
        addressCheckpointArray.push(AddressCheckpoint({
            fromBlock: uint32(block.number),
            _address: _address
            }));
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
        returns (uint256);

    function userVotingPower(address userAddress)
        external
        view
        returns (uint256);

    function totalSharesAt(uint256 _block)
        external
        view
        returns (uint256);

    function totalShares()
        external
        view
        returns (uint256);

    function userSharesAt(
        address userAddress,
        uint256 _block
        )
        external
        view
        returns (uint256);

    function userShares(address userAddress)
        external
        view
        returns (uint256);

    function userStake(address userAddress)
        external
        view
        returns (uint256);

    function delegatedToUserAt(
        address userAddress,
        uint256 _block
        )
        external
        view
        returns (uint256);

    function delegatedToUser(address userAddress)
        external
        view
        returns (uint256);

    function userDelegateAt(
        address userAddress,
        uint256 _block
        )
        external
        view
        returns (address);

    function userDelegate(address userAddress)
        external
        view
        returns (address);

    function userLocked(address userAddress)
        external
        view
        returns (uint256);

    function getUser(address userAddress)
        external
        view
        returns (
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

    /// @notice Called to get the total pool shares at a specific block
    /// @dev Total pool shares also corresponds to total voting power
    /// @param _block Block number for which the query is being made for
    /// @return Total pool shares at the block
    function totalSharesAt(uint256 _block)
        public
        view
        override
        returns (uint256)
    {
        return getValueAt(poolShares, _block);
    }

    /// @notice Called to get the current total pool shares
    /// @dev Total pool shares also corresponds to total voting power
    /// @return Current total pool shares
    function totalShares()
        public
        view
        override
        returns (uint256)
    {
        return totalSharesAt(block.number);
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
        return userShares(userAddress) * totalStake / totalShares();
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
        uint256 currentEpoch = block.timestamp / EPOCH_LENGTH;
        uint256 oldestLockedEpoch = getOldestLockedEpoch();
        uint256 indUserShares = _userShares.length;
        for (
                uint256 indEpoch = currentEpoch;
                indEpoch >= oldestLockedEpoch;
                indEpoch--
            )
        {
            // The user has never staked at this point, we can exit early
            if (indUserShares == 0)
            {
                break;
            }
            Reward storage lockedReward = epochIndexToReward[indEpoch];
            if (lockedReward.atBlock != 0)
            {
                for (; indUserShares > 0; indUserShares--)
                {
                    Checkpoint storage userShare = _userShares[indUserShares - 1];
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
    /// @return unstakeAmount Amount scheduled to unstake
    /// @return unstakeShares Shares revoked to unstake
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
            uint256 unstakeAmount,
            uint256 unstakeShares,
            uint256 unstakeScheduledFor,
            uint256 lastDelegationUpdateTimestamp,
            uint256 lastProposalTimestamp
            )
    {
        User storage user = users[userAddress];
        unstaked = user.unstaked;
        vesting = user.vesting;
        unstakeAmount = user.unstakeAmount;
        unstakeShares = user.unstakeShares;
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
        uint min = 0;
        if (
            checkpoints.length > 1024
                && checkpoints[checkpoints.length - 1024].fromBlock < _block
            )
        {
            min = checkpoints.length - 1024;
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
        uint min = 0;
        if (
            checkpoints.length > 1024
                && checkpoints[checkpoints.length - 1024].fromBlock < _block
            )
        {
            min = checkpoints.length - 1024;
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

    /// @notice Called internally to get the index of the oldest epoch whose
    /// reward should be locked in the current epoch
    /// @return oldestLockedEpoch Index of the oldest epoch with locked rewards
    function getOldestLockedEpoch()
        internal
        view
        returns (uint256 oldestLockedEpoch)
    {
        uint256 currentEpoch = block.timestamp / EPOCH_LENGTH;
        oldestLockedEpoch = currentEpoch - REWARD_VESTING_PERIOD + 1;
        if (oldestLockedEpoch < genesisEpoch + 1)
        {
            oldestLockedEpoch = genesisEpoch + 1;
        }
    }
}


// File contracts/interfaces/IRewardUtils.sol

pragma solidity 0.8.4;

interface IRewardUtils is IGetterUtils {
    event MintedReward(
        uint256 indexed epochIndex,
        uint256 amount,
        uint256 newApr,
        uint256 totalStake
        );

    function mintReward()
        external;
}


// File contracts/RewardUtils.sol

pragma solidity 0.8.4;


/// @title Contract that implements reward payments
abstract contract RewardUtils is GetterUtils, IRewardUtils {
    /// @notice Called to mint the staking reward
    /// @dev Skips past epochs for which rewards have not been paid for.
    /// Skips the reward payment if the pool is not authorized to mint tokens.
    /// Neither of these conditions will occur in practice.
    function mintReward()
        public
        override
    {
        uint256 currentEpoch = block.timestamp / EPOCH_LENGTH;
        // This will be skipped in most cases because someone else will have
        // triggered the payment for this epoch
        if (epochIndexOfLastReward < currentEpoch)
        {
            if (api3Token.getMinterStatus(address(this)))
            {
                uint256 rewardAmount = totalStake * apr * EPOCH_LENGTH / 365 days / HUNDRED_PERCENT;
                assert(block.number <= MAX_UINT32);
                assert(rewardAmount <= MAX_UINT224);
                epochIndexToReward[currentEpoch] = Reward({
                    atBlock: uint32(block.number),
                    amount: uint224(rewardAmount),
                    totalSharesThen: totalShares(),
                    totalStakeThen: totalStake
                    });
                api3Token.mint(address(this), rewardAmount);
                totalStake += rewardAmount;
                updateCurrentApr();
                emit MintedReward(
                    currentEpoch,
                    rewardAmount,
                    apr,
                    totalStake
                    );
            }
            epochIndexOfLastReward = currentEpoch;
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
        if (totalStakePercentage > stakeTarget)
        {
            apr = apr > aprUpdateStep ? apr - aprUpdateStep : 0;
        }
        else
        {
            apr += aprUpdateStep;
        }
        if (apr > maxApr) {
            apr = maxApr;
        }
        else if (apr < minApr) {
            apr = minApr;
        }
    }
}


// File contracts/interfaces/IDelegationUtils.sol

pragma solidity 0.8.4;

interface IDelegationUtils is IRewardUtils {
    event Delegated(
        address indexed user,
        address indexed delegate,
        uint256 shares,
        uint256 totalDelegatedTo
        );

    event Undelegated(
        address indexed user,
        address indexed delegate,
        uint256 shares,
        uint256 totalDelegatedTo
        );

    event UpdatedDelegation(
        address indexed user,
        address indexed delegate,
        bool delta,
        uint256 shares,
        uint256 totalDelegatedTo
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
        // Delegating users cannot use their voting power, so we are
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
            user.lastDelegationUpdateTimestamp + EPOCH_LENGTH < block.timestamp,
            "Pool: Updated delegate recently"
            );
        user.lastDelegationUpdateTimestamp = block.timestamp;

        uint256 userShares = userShares(msg.sender);
        require(
            userShares != 0,
            "Pool: Have no shares to delegate"
            );

        address previousDelegate = userDelegate(msg.sender);
        require(
            previousDelegate != delegate,
            "Pool: Already delegated"
            );
        if (previousDelegate != address(0)) {
            // Need to revoke previous delegation
            updateCheckpointArray(
                users[previousDelegate].delegatedTo,
                delegatedToUser(previousDelegate) - userShares
                );
        }

        // Assign the new delegation
        uint256 delegatedToUpdate = delegatedToUser(delegate) + userShares;
        updateCheckpointArray(
            users[delegate].delegatedTo,
            delegatedToUpdate
            );

        // Record the new delegate for the user
        updateAddressCheckpointArray(
            user.delegates,
            delegate
            );
        emit Delegated(
            msg.sender,
            delegate,
            userShares,
            delegatedToUpdate
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
            user.lastDelegationUpdateTimestamp + EPOCH_LENGTH < block.timestamp,
            "Pool: Updated delegate recently"
            );
        user.lastDelegationUpdateTimestamp = block.timestamp;

        uint256 userShares = userShares(msg.sender);
        uint256 delegatedToUpdate = delegatedToUser(previousDelegate) - userShares;
        updateCheckpointArray(
            users[previousDelegate].delegatedTo,
            delegatedToUpdate
            );
        updateAddressCheckpointArray(
            user.delegates,
            address(0)
            );
        emit Undelegated(
            msg.sender,
            previousDelegate,
            userShares,
            delegatedToUpdate
            );
    }

    /// @notice Called internally when the user shares are updated to update
    /// the delegated voting power
    /// @dev User shares only get updated while staking or scheduling unstaking
    /// @param shares Amount of shares that will be added/removed
    /// @param delta Whether the shares will be added/removed (add for `true`,
    /// and vice versa)
    function updateDelegatedVotingPower(
        uint256 shares,
        bool delta
        )
        internal
    {
        address delegate = userDelegate(msg.sender);
        if (delegate == address(0))
        {
            return;
        }
        uint256 currentDelegatedTo = delegatedToUser(delegate);
        uint256 delegatedToUpdate = delta
            ? currentDelegatedTo + shares
            : currentDelegatedTo - shares;
        updateCheckpointArray(
            users[delegate].delegatedTo,
            delegatedToUpdate
            );
        emit UpdatedDelegation(
            msg.sender,
            delegate,
            delta,
            shares,
            delegatedToUpdate
            );
    }
}


// File contracts/interfaces/ITransferUtils.sol

pragma solidity 0.8.4;

interface ITransferUtils is IDelegationUtils{
    event Deposited(
        address indexed user,
        uint256 amount,
        uint256 userUnstaked
        );

    event Withdrawn(
        address indexed user,
        uint256 amount,
        uint256 userUnstaked
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
    /// The method is named `depositRegular()` to prevent potential confusion.
    /// See `deposit()` for more context.
    /// @param amount Amount to be deposited
    function depositRegular(uint256 amount)
        public
        override
    {
        mintReward();
        uint256 unstakedUpdate = users[msg.sender].unstaked + amount;
        users[msg.sender].unstaked = unstakedUpdate;
        // Should never return false because the API3 token uses the
        // OpenZeppelin implementation
        assert(api3Token.transferFrom(msg.sender, address(this), amount));
        emit Deposited(
            msg.sender,
            amount,
            unstakedUpdate
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
    /// tokens calculated and use `withdrawPrecalculated()` to withdraw.
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
        mintReward();
        require(
            noEpochsPerIteration > 0,
            "Pool: Zero iteration window"
            );
        uint256 currentEpoch = block.timestamp / EPOCH_LENGTH;
        LockedCalculation storage lockedCalculation = userToLockedCalculation[userAddress];
        // Reset the state if there was no calculation made in this epoch
        if (lockedCalculation.initialIndEpoch != currentEpoch)
        {
            lockedCalculation.initialIndEpoch = currentEpoch;
            lockedCalculation.nextIndEpoch = currentEpoch;
            lockedCalculation.locked = 0;
        }
        uint256 indEpoch = lockedCalculation.nextIndEpoch;
        uint256 locked = lockedCalculation.locked;
        uint256 oldestLockedEpoch = getOldestLockedEpoch();
        for (; indEpoch >= oldestLockedEpoch; indEpoch--)
        {
            if (lockedCalculation.nextIndEpoch >= indEpoch + noEpochsPerIteration)
            {
                lockedCalculation.nextIndEpoch = indEpoch;
                lockedCalculation.locked = locked;
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
                uint256 userSharesThen = userSharesAt(userAddress, lockedReward.atBlock);
                locked += lockedReward.amount * userSharesThen / lockedReward.totalSharesThen;
            }
        }
        lockedCalculation.nextIndEpoch = indEpoch;
        lockedCalculation.locked = locked;
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
        uint256 currentEpoch = block.timestamp / EPOCH_LENGTH;
        LockedCalculation storage lockedCalculation = userToLockedCalculation[msg.sender];
        require(
            lockedCalculation.initialIndEpoch == currentEpoch,
            "Pool: Calculation not up to date"
            );
        require(
            lockedCalculation.nextIndEpoch < getOldestLockedEpoch(),
            "Pool: Calculation not complete"
            );
        withdraw(amount, lockedCalculation.locked);
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
        require(
            user.unstaked >= amount,
            "Pool: Not enough unstaked funds"
            );
        // Carry on with the withdrawal
        uint256 unstakedUpdate = user.unstaked - amount;
        user.unstaked = unstakedUpdate;
        // Should never return false because the API3 token uses the
        // OpenZeppelin implementation
        assert(api3Token.transfer(msg.sender, amount));
        emit Withdrawn(
            msg.sender,
            amount,
            unstakedUpdate
            );
    }
}


// File contracts/interfaces/IStakeUtils.sol

pragma solidity 0.8.4;

interface IStakeUtils is ITransferUtils{
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 mintedShares,
        uint256 userUnstaked,
        uint256 userShares,
        uint256 totalShares,
        uint256 totalStake
        );

    event ScheduledUnstake(
        address indexed user,
        uint256 amount,
        uint256 shares,
        uint256 scheduledFor,
        uint256 userShares
        );

    event Unstaked(
        address indexed user,
        uint256 amount,
        uint256 userUnstaked,
        uint256 totalShares,
        uint256 totalStake
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
        uint256 userUnstakedUpdate = user.unstaked - amount;
        user.unstaked = userUnstakedUpdate;
        uint256 totalSharesNow = totalShares();
        uint256 sharesToMint = amount * totalSharesNow / totalStake;
        uint256 userSharesUpdate = userShares(msg.sender) + sharesToMint;
        updateCheckpointArray(
            user.shares,
            userSharesUpdate
            );
        uint256 totalSharesUpdate = totalSharesNow + sharesToMint;
        updateCheckpointArray(
            poolShares,
            totalSharesUpdate
            );
        totalStake += amount;
        updateDelegatedVotingPower(sharesToMint, true);
        emit Staked(
            msg.sender,
            amount,
            sharesToMint,
            userUnstakedUpdate,
            userSharesUpdate,
            totalSharesUpdate,
            totalStake
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
    /// scheduled to unstake, or the amount of tokens `shares` corresponds to
    /// at unstaking-time, whichever is smaller. This corresponds to tokens
    /// being scheduled to be unstaked not receiving any rewards, but being
    /// subject to claim payouts.
    /// In the instance that a claim has been paid out before an unstaking is
    /// executed, the user may potentially receive rewards during
    /// `unstakeWaitPeriod` (but not if there has not been a claim payout) but
    /// the amount of tokens that they can unstake will not be able to exceed
    /// the amount they scheduled the unstaking for.
    /// @param amount Amount of tokens scheduled to unstake
    function scheduleUnstake(uint256 amount)
        external
        override
    {
        mintReward();
        uint256 userSharesNow = userShares(msg.sender);
        uint256 totalSharesNow = totalShares();
        uint256 userStaked = userSharesNow * totalStake / totalSharesNow;
        require(
            userStaked >= amount,
            "Pool: Amount exceeds staked"
            );

        User storage user = users[msg.sender];
        require(
            user.unstakeScheduledFor == 0,
            "Pool: Unexecuted unstake exists"
            );

        uint256 sharesToUnstake = amount * totalSharesNow / totalStake;
        // This will only happen if the user wants to schedule an unstake for a
        // few Wei
        require(sharesToUnstake > 0, "Pool: Unstake amount too small");
        uint256 unstakeScheduledFor = block.timestamp + unstakeWaitPeriod;
        user.unstakeScheduledFor = unstakeScheduledFor;
        user.unstakeAmount = amount;
        user.unstakeShares = sharesToUnstake;
        uint256 userSharesUpdate = userSharesNow - sharesToUnstake;
        updateCheckpointArray(
            user.shares,
            userSharesUpdate
            );
        updateDelegatedVotingPower(sharesToUnstake, false);
        emit ScheduledUnstake(
            msg.sender,
            amount,
            sharesToUnstake,
            unstakeScheduledFor,
            userSharesUpdate
            );
    }

    /// @notice Called to execute a pre-scheduled unstake
    /// @dev Anyone can execute a matured unstake. This is to allow the user to
    /// use bots, etc. to execute their unstaking as soon as possible.
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
        uint256 unstakeAmount = user.unstakeAmount;
        uint256 unstakeAmountByShares = user.unstakeShares * totalStake / totalShares;
        // If there was a claim payout in between the scheduling and the actual
        // unstake then the amount might be lower than expected at scheduling
        // time
        if (unstakeAmount > unstakeAmountByShares)
        {
            unstakeAmount = unstakeAmountByShares;
        }
        uint256 userUnstakedUpdate = user.unstaked + unstakeAmount;
        user.unstaked = userUnstakedUpdate;

        uint256 totalSharesUpdate = totalShares - user.unstakeShares;
        updateCheckpointArray(
            poolShares,
            totalSharesUpdate
            );
        totalStake -= unstakeAmount;

        user.unstakeAmount = 0;
        user.unstakeShares = 0;
        user.unstakeScheduledFor = 0;
        emit Unstaked(
            userAddress,
            unstakeAmount,
            userUnstakedUpdate,
            totalSharesUpdate,
            totalStake
            );
        return unstakeAmount;
    }

    /// @notice Convenience method to execute an unstake and withdraw to the
    /// user's wallet in a single transaction
    /// @dev The withdrawal will revert if the user has less than
    /// `unstakeAmount` tokens that are withdrawable
    function unstakeAndWithdraw()
        external
        override
    {
        withdrawRegular(unstake(msg.sender));
    }
}


// File contracts/interfaces/IClaimUtils.sol

pragma solidity 0.8.4;

interface IClaimUtils is IStakeUtils {
    event PaidOutClaim(
        address indexed recipient,
        uint256 amount,
        uint256 totalStake
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
    /// This will revert if the pool does not have enough staked funds.
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
        totalStake -= amount;
        // Should never return false because the API3 token uses the
        // OpenZeppelin implementation
        assert(api3Token.transfer(recipient, amount));
        emit PaidOutClaim(
            recipient,
            amount,
            totalStake
            );
    }
}


// File contracts/interfaces/ITimelockUtils.sol

pragma solidity 0.8.4;

interface ITimelockUtils is IClaimUtils {
    event DepositedByTimelockManager(
        address indexed user,
        uint256 amount,
        uint256 userUnstaked
        );

    event DepositedVesting(
        address indexed user,
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 userUnstaked,
        uint256 userVesting
        );

    event VestedTimelock(
        address indexed user,
        uint256 amount,
        uint256 userVesting
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
/// API3 tokens that are locked under a vesting schedule.
/// This contract keeps its own type definitions, event declarations and state
/// variables for them to be easier to remove for a subDAO where they will
/// likely not be used.
abstract contract TimelockUtils is ClaimUtils, ITimelockUtils {
    struct Timelock {
        uint256 totalAmount;
        uint256 remainingAmount;
        uint256 releaseStart;
        uint256 releaseEnd;
    }

    /// @notice Maps user addresses to timelocks
    /// @dev This implies that a user cannot have multiple timelocks
    /// transferred from the TimelockManager contract. This is acceptable
    /// because TimelockManager is implemented in a way to not allow multiple
    /// timelocks per user.
    mapping(address => Timelock) public userToTimelock;

    /// @notice Called by the TimelockManager contract to deposit tokens on
    /// behalf of a user
    /// @dev This method is only usable by `TimelockManager.sol`.
    /// It is named as `deposit()` and not `depositAsTimelockManager()` for
    /// example, because the TimelockManager is already deployed and expects
    /// the `deposit(address,uint256,address)` interface.
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
        uint256 unstakedUpdate = users[userAddress].unstaked + amount;
        users[userAddress].unstaked = unstakedUpdate;
        // Should never return false because the API3 token uses the
        // OpenZeppelin implementation
        assert(api3Token.transferFrom(source, address(this), amount));
        emit DepositedByTimelockManager(
            userAddress,
            amount,
            unstakedUpdate
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
        uint256 unstakedUpdate = users[userAddress].unstaked + amount;
        users[userAddress].unstaked = unstakedUpdate;
        uint256 vestingUpdate = users[userAddress].vesting + amount;
        users[userAddress].vesting = vestingUpdate;
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
            releaseEnd,
            unstakedUpdate,
            vestingUpdate
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
        uint256 vestingUpdate = user.vesting - newlyUnlocked;
        user.vesting = vestingUpdate;
        timelock.remainingAmount -= newlyUnlocked;
        emit VestedTimelock(
            userAddress,
            newlyUnlocked,
            vestingUpdate
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
    constructor(
        address api3TokenAddress,
        address timelockManagerAddress
        )
        StateUtils(
            api3TokenAddress,
            timelockManagerAddress
            )
    {}
}