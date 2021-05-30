/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File contracts/auxiliary/interfaces/v0.8.4/IERC20Aux.sol

// SPDX-License-Identifier: MIT

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

    event PublishedSpecsUrl(
        address indexed votingApp,
        uint256 indexed proposalIndex,
        address userAddress,
        string specsUrl
        );

    event UpdatedLastVoteSnapshotBlock(
        address votingApp,
        uint256 lastVoteSnapshotBlock,
        uint256 lastVoteSnapshotBlockUpdateTimestamp
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

    function updateLastVoteSnapshotBlock(uint256 snapshotBlock)
        external;

    function updateMostRecentProposalTimestamp(address userAddress)
        external;

    function updateMostRecentVoteTimestamp(address userAddress)
        external;
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
        uint256 mostRecentProposalTimestamp;
        uint256 mostRecentVoteTimestamp;
        uint256 mostRecentDelegationTimestamp;
        uint256 mostRecentUndelegationTimestamp;
    }

    /// @notice Length of the epoch in which the staking reward is paid out
    /// once. It is hardcoded as 7 days in seconds.
    /// @dev In addition to regulating reward payments, this variable is used
    /// for four additional things:
    /// (1) Once an unstaking scheduling matures, the user has `EPOCH_LENGTH`
    /// to execute the unstaking before it expires
    /// (2) After a user makes a proposal, they cannot make a second one
    /// before `EPOCH_LENGTH` has passed
    /// (3) After a user updates their delegation status, they have to wait
    /// `EPOCH_LENGTH` before updating it again
    uint256 public constant EPOCH_LENGTH = 7 * 24 * 60 * 60;

    /// @notice Number of epochs before the staking rewards get unlocked.
    /// Hardcoded as 52 epochs, which corresponds to a year.
    uint256 public constant REWARD_VESTING_PERIOD = 52;

    string internal constant ERROR_PERCENTAGE = "API3DAO.StateUtils: Percentage should be between 0 and 100";
    string internal constant ERROR_APR = "API3DAO.StateUtils: Max APR should be bigger than min apr";
    string internal constant ERROR_UNSTAKE_PERIOD = "API3DAO.StateUtils: Should wait for time bigger than EPOCH_LENGTH to unstake";
    string internal constant ERROR_PROPOSAL_THRESHOLD = "API3DAO.StateUtils: Threshold should be lower then 10%";
    string internal constant ERROR_ZERO_ADDRESS = "API3DAO.StateUtils: Addresses should not be 0x00";
    string internal constant ERROR_ONLY_AGENT = "API3DAO.StateUtils: Only Agent app is allowed to execute this function";
    string internal constant ERROR_ONLY_PRIMARY_AGENT = "API3DAO.StateUtils: Only primary Agent app is allowed to execute this function";
    string internal constant ERROR_ONLY_VOTING = "API3DAO.StateUtils: Only Voting app is allowed to execute this function";
    string internal constant ERROR_FREQUENCY = "API3DAO.StateUtils: Try again a week later";
    string internal constant ERROR_DELEGATE = "API3DAO.StateUtils: Cannot delegate to the same address";

    // All percentage values are represented by multiplying by 1e16
    uint256 internal constant HUNDRED_PERCENT = 1e18;
    uint256 internal constant ONE_PERCENT = HUNDRED_PERCENT / 100;

    /// @notice API3 token contract
    IApi3Token public api3Token;

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

    /// @notice Epochs are indexed as `block.timestamp / EPOCH_LENGTH`.
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
    uint256 public minApr = 25 * ONE_PERCENT / 10;

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
    uint256 public currentApr = (maxApr + minApr) / 2;

    // Snapshot block number of the last vote created at one of the DAO
    // Api3Voting apps
    uint256 private lastVoteSnapshotBlock;
    mapping(uint256 => uint256) private snapshotBlockToTimestamp;

    // We keep checkpoints for two most recent blocks at which totalShares has
    // been updated. Note that the indices do not indicate chronological
    // ordering.
    Checkpoint private totalSharesCheckpoint1;
    Checkpoint private totalSharesCheckpoint2;

    /// @dev Reverts if the caller is not an API3 DAO Agent
    modifier onlyAgentApp() {
        require(
            msg.sender == agentAppPrimary || msg.sender == agentAppSecondary,
            ERROR_ONLY_AGENT
            );
        _;
    }

    /// @dev Reverts if the caller is not the primary API3 DAO Agent
    modifier onlyAgentAppPrimary() {
        require(msg.sender == agentAppPrimary, ERROR_ONLY_PRIMARY_AGENT);
        _;
    }

    /// @dev Reverts if the caller is not an API3 DAO Api3Voting app
    modifier onlyVotingApp() {
        require(
            msg.sender == votingAppPrimary || msg.sender == votingAppSecondary,
            ERROR_ONLY_VOTING
            );
        _;
    }

    /// @param api3TokenAddress API3 token contract address
    constructor(address api3TokenAddress)
    {
        api3Token = IApi3Token(api3TokenAddress);
        // Initialize the share price at 1
        updateTotalShares(1);
        totalStake = 1;
        // Set the current epoch as the genesis epoch and skip its reward
        // payment
        uint256 currentEpoch = block.timestamp / EPOCH_LENGTH;
        genesisEpoch = currentEpoch;
        epochIndexOfLastRewardPayment = currentEpoch;
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
        require(
            agentAppPrimary == address(0) || msg.sender == agentAppPrimary,
            ERROR_ONLY_AGENT
            );
        require(
            _agentAppPrimary != address(0)
                && _agentAppSecondary  != address(0)
                && _votingAppPrimary  != address(0)
                && _votingAppSecondary  != address(0),
            ERROR_ZERO_ADDRESS
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
            ERROR_PERCENTAGE);
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
        require(_maxApr >= minApr, ERROR_APR);
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
        require(_minApr <= maxApr, ERROR_APR);
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
        require(_unstakeWaitPeriod >= EPOCH_LENGTH, ERROR_UNSTAKE_PERIOD);
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
    /// @dev Proposal voting power is limited between 0.1% and 10%. 0.1% is to
    /// ensure that no more than 1000 proposals can be made within an epoch
    /// (see `getReceivedDelegationAt()`) and any value above 10% is certainly
    /// an error.
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
            ERROR_PROPOSAL_THRESHOLD);
        uint256 oldProposalVotingPowerThreshold = proposalVotingPowerThreshold;
        proposalVotingPowerThreshold = _proposalVotingPowerThreshold;
        emit SetProposalVotingPowerThreshold(
            oldProposalVotingPowerThreshold,
            proposalVotingPowerThreshold
            );
    }

    /// @notice Called by a DAO Api3Voting app to update the last vote snapshot
    /// block number
    /// @param snapshotBlock Last vote snapshot block number
    function updateLastVoteSnapshotBlock(uint256 snapshotBlock)
        external
        override
        onlyVotingApp()
    {
        lastVoteSnapshotBlock = snapshotBlock;
        snapshotBlockToTimestamp[snapshotBlock] = block.timestamp;
        emit UpdatedLastVoteSnapshotBlock(
            msg.sender,
            snapshotBlock,
            block.timestamp
            );
    }

    /// @notice Called by a DAO Api3Voting app at proposal creation-time to
    /// update the timestamp of the user's most recent proposal
    /// @param userAddress User address
    function updateMostRecentProposalTimestamp(address userAddress)
        external
        override
        onlyVotingApp()
    {
        users[userAddress].mostRecentProposalTimestamp = block.timestamp;
    }

    /// @notice Called by a DAO Api3Voting app at voting-time to update the
    /// timestamp of the user's most recent vote
    /// @param userAddress User address
    function updateMostRecentVoteTimestamp(address userAddress)
        external
        override
        onlyVotingApp()
    {
        users[userAddress].mostRecentVoteTimestamp = block.timestamp;
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

    /// @notice Called internally to update a checkpoint array
    /// @param checkpointArray Checkpoint array to be updated
    /// @param value Value to be updated with
    function updateCheckpointArray(
        Checkpoint[] storage checkpointArray,
        uint256 value
        )
        internal
    {
        if (checkpointArray.length == 0)
        {
            checkpointArray.push(Checkpoint({
                fromBlock: lastVoteSnapshotBlock,
                value: value
                }));
        }
        else
        {
            Checkpoint storage lastElement = checkpointArray[checkpointArray.length - 1];
            if (lastElement.fromBlock < lastVoteSnapshotBlock)
            {
                checkpointArray.push(Checkpoint({
                    fromBlock: lastVoteSnapshotBlock,
                    value: value
                    }));
            }
            else
            {
                lastElement.value = value;
            }
        }
    }

    /// @notice Called internally to update an address checkpoint array
    /// @param addressCheckpointArray Address checkpoint array to be updated
    /// @param _address Address to be updated with
    function updateAddressCheckpointArray(
        AddressCheckpoint[] storage addressCheckpointArray,
        address _address
        )
        internal
    {
        if (addressCheckpointArray.length == 0)
        {
            addressCheckpointArray.push(AddressCheckpoint({
                fromBlock: lastVoteSnapshotBlock,
                _address: _address
                }));
        }
        else
        {
            AddressCheckpoint storage lastElement = addressCheckpointArray[addressCheckpointArray.length - 1];
            if (lastElement.fromBlock < lastVoteSnapshotBlock)
            {
                addressCheckpointArray.push(AddressCheckpoint({
                    fromBlock: lastVoteSnapshotBlock,
                    _address: _address
                    }));
            }
            else
            {
                lastElement._address = _address;
            }
        }
    }
}


// File contracts/interfaces/IGetterUtils.sol
pragma solidity 0.8.4;

interface IGetterUtils is IStateUtils {
    function balanceOfAt(
        address userAddress,
        uint256 _block
        )
        external
        view
        returns(uint256);

    function balanceOf(address userAddress)
        external
        view
        returns(uint256);

    function totalSupplyOneBlockAgo()
        external
        view
        returns(uint256);

    function totalSupply()
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

    function userSharesAtWithBinarySearch(
        address userAddress,
        uint256 _block
        )
        external
        view
        returns(uint256);

    function userStake(address userAddress)
        external
        view
        returns(uint256);

    function getReceivedDelegationAt(
        address userAddress,
        uint256 _block
        )
        external
        view
        returns(uint256);

    function userReceivedDelegation(address userAddress)
        external
        view
        returns(uint256);

    function getUserDelegateAt(
        address userAddress,
        uint256 _block
        )
        external
        view
        returns(address);

    function getUserDelegate(address userAddress)
        external
        view
        returns(address);

    function getUserLocked(address userAddress)
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
            uint256 mostRecentProposalTimestamp,
            uint256 mostRecentVoteTimestamp,
            uint256 mostRecentDelegationTimestamp,
            uint256 mostRecentUndelegationTimestamp
            );
}


// File contracts/GetterUtils.sol

pragma solidity 0.8.4;


/// @title Contract that implements getters
abstract contract GetterUtils is StateUtils, IGetterUtils {

    string private constant CHECKPOINT_NOT_FOUND = "API3DAO.GetterUtils: Value cannot be found after provided checkpoint";

    /// @notice Called to get the voting power of a user at a checkpoint,
    /// closest to the provided block
    /// @dev This method is used to implement the MiniMe interface for the
    /// Api3Voting app
    /// @param userAddress User address
    /// @param _block Block number for which the query is being made for
    /// @return Voting power of the user at the block
    function balanceOfAt(
        address userAddress,
        uint256 _block
        )
        public
        view
        override
        returns(uint256)
    {
        // Users that delegate have no voting power
        if (getUserDelegateAt(userAddress, _block) != address(0))
        {
            return 0;
        }
        uint256 userSharesThen = userSharesAt(userAddress, _block);
        uint256 delegatedToUserThen = getReceivedDelegationAt(userAddress, _block);
        return userSharesThen + delegatedToUserThen;
    }

    /// @notice Called to get the current voting power of a user
    /// @dev This method is used to implement the MiniMe interface for the
    /// Api3Voting app
    /// @param userAddress User address
    /// @return Current voting power of the user
    function balanceOf(address userAddress)
        public
        view
        override
        returns(uint256)
    {
        return balanceOfAt(userAddress, block.number);
    }

    /// @notice Called to get the total voting power one block ago
    /// @dev This method is used to implement the MiniMe interface for the
    /// Api3Voting app
    /// @return Total voting power one block ago
    function totalSupplyOneBlockAgo()
        public
        view
        override
        returns(uint256)
    {
        return totalSharesOneBlockAgo();
    }

    /// @notice Called to get the current total voting power
    /// @dev This method is used to implement the MiniMe interface for the
    /// Aragon Voting app
    /// @return Current total voting power
    function totalSupply()
        public
        view
        override
        returns(uint256)
    {
        return totalShares();
    }

    /// @notice Called to get the pool shares of a user at a checkpoint,
    /// closest to the provided block
    /// @dev Starts from the most recent value in `user.shares` and searches
    /// backwards one element at a time
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
        returns(uint256)
    {
        return getValueAt(users[userAddress].shares, _block, 0);
    }

    /// @notice Called to get the current pool shares of a user
    /// @param userAddress User address
    /// @return Current pool shares of the user
    function userShares(address userAddress)
        public
        view
        override
        returns(uint256)
    {
        return userSharesAt(userAddress, block.number);
    }

    /// @notice Called to get the pool shares of a user at checkpoint,
    /// closest to specific block using binary search
    /// @dev This method is not used by the current iteration of the DAO/pool
    /// and is implemented for future external contracts to use to get the user
    /// shares at an arbitrary block.
    /// @param userAddress User address
    /// @param _block Block number for which the query is being made for
    /// @return Pool shares of the user at the block
    function userSharesAtWithBinarySearch(
        address userAddress,
        uint256 _block
        )
        external
        view
        override
        returns(uint256)
    {
        return getValueAtWithBinarySearch(
            users[userAddress].shares,
            _block,
            0
            );
    }

    /// @notice Called to get the current staked tokens of the user
    /// @param userAddress User address
    /// @return Current staked tokens of the user
    function userStake(address userAddress)
        public
        view
        override
        returns(uint256)
    {
        return userShares(userAddress) * totalStake / totalShares();
    }

    /// @notice Called to get the voting power delegated to a user at a
    /// checkpoint, closest to specific block
    /// @dev `user.delegatedTo` cannot have grown more than 1000 checkpoints
    /// in the last epoch due to `proposalVotingPowerThreshold` having a lower
    /// limit of 0.1%.
    /// @param userAddress User address
    /// @param _block Block number for which the query is being made for
    /// @return Voting power delegated to the user at the block
    function getReceivedDelegationAt(
        address userAddress,
        uint256 _block
        )
        public
        view
        override
        returns(uint256)
    {
        // Binary searching a 1000-long array takes up to 10 storage reads
        // (2^10 = 1024). If we approximate the average number of reads
        // required to be 5 and consider that it is much more likely for the
        // value we are looking for will be at the end of the array (because
        // not many proposals will be made per epoch), it is preferable to do
        // a linear search at the end of the array if possible. Here, the
        // length of "the end of the array" is specified to be 5 (which was the
        // expected number of iterations we will need for a binary search).
        uint256 maximumLengthToLinearSearch = 5;
        // If the value we are looking for is not among the last
        // `maximumLengthToLinearSearch`, we will fall back to binary search.
        // Here, we will only search through the last 1000 checkpoints because
        // `user.delegatedTo` cannot have grown more than 1000 checkpoints in
        // the last epoch due to `proposalVotingPowerThreshold` having a lower
        // limit of 0.1%.
        uint256 maximumLengthToBinarySearch = 1000;
        Checkpoint[] storage delegatedTo = users[userAddress].delegatedTo;
        if (delegatedTo.length < maximumLengthToLinearSearch) {
            return getValueAt(delegatedTo, _block, 0);
        }
        uint256 minimumCheckpointIndexLinearSearch = delegatedTo.length - maximumLengthToLinearSearch;
        if (delegatedTo[minimumCheckpointIndexLinearSearch].fromBlock < _block) {
            return getValueAt(delegatedTo, _block, minimumCheckpointIndexLinearSearch);
        }
        // It is very unlikely for the method to not have returned until here
        // because it means there have been `maximumLengthToLinearSearch`
        // proposals made in the current epoch.
        uint256 minimumCheckpointIndexBinarySearch = delegatedTo.length > maximumLengthToBinarySearch
            ? delegatedTo.length - maximumLengthToBinarySearch
            : 0;
        // The below will revert if the value being searched is not within the
        // last `minimumCheckpointIndexBinarySearch` (which is not possible if
        // `_block` is the snapshot block of an open vote of Api3Voting,
        // because its vote duration is `EPOCH_LENGTH`).
        return getValueAtWithBinarySearch(delegatedTo, _block, minimumCheckpointIndexBinarySearch);
    }

    /// @notice Called to get the current voting power delegated to a user
    /// @param userAddress User address
    /// @return Current voting power delegated to the user
    function userReceivedDelegation(address userAddress)
        public
        view
        override
        returns(uint256)
    {
        return getReceivedDelegationAt(userAddress, block.number);
    }

    /// @notice Called to get the delegate of the user at a checkpoint,
    /// closest to specified block
    /// @dev Starts from the most recent value in `user.delegates` and
    /// searches backwards one element at a time. If `_block` is within
    /// `EPOCH_LENGTH`, this call is guaranteed to find the value among
    /// the last 2 elements because a user cannot update delegate more
    /// frequently than once an `EPOCH_LENGTH`.
    /// @param userAddress User address
    /// @param _block Block number
    /// @return Delegate of the user at the specific block
    function getUserDelegateAt(
        address userAddress,
        uint256 _block
        )
        public
        view
        override
        returns(address)
    {
        AddressCheckpoint[] storage delegates = users[userAddress].delegates;
        for (uint256 i = delegates.length; i > 0; i--)
        {
            if (delegates[i - 1].fromBlock <= _block)
            {
                return delegates[i - 1]._address;
            }
        }
        return address(0);
    }

    /// @notice Called to get the current delegate of the user
    /// @param userAddress User address
    /// @return Current delegate of the user
    function getUserDelegate(address userAddress)
        public
        view
        override
        returns(address)
    {
        return getUserDelegateAt(userAddress, block.number);
    }

    /// @notice Called to get the current locked tokens of the user
    /// @param userAddress User address
    /// @return locked Current locked tokens of the user
    function getUserLocked(address userAddress)
        public
        view
        override
        returns(uint256 locked)
    {
        Checkpoint[] storage _userShares = users[userAddress].shares;
        uint256 currentEpoch = block.timestamp / EPOCH_LENGTH;
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
    /// @return unstakeShares Shares scheduled to unstake
    /// @return unstakeAmount Amount scheduled to unstake
    /// @return unstakeScheduledFor Time unstaking is scheduled for
    /// @return mostRecentProposalTimestamp Time when the user made their most
    /// recent proposal
    /// @return mostRecentVoteTimestamp Time when the user cast their most
    /// recent vote
    /// @return mostRecentDelegationTimestamp Time when the user made their
    /// most recent delegation
    /// @return mostRecentUndelegationTimestamp Time when the user made their
    /// most recent undelegation
    function getUser(address userAddress)
        external
        view
        override
        returns(
            uint256 unstaked,
            uint256 vesting,
            uint256 unstakeShares,
            uint256 unstakeAmount,
            uint256 unstakeScheduledFor,
            uint256 mostRecentProposalTimestamp,
            uint256 mostRecentVoteTimestamp,
            uint256 mostRecentDelegationTimestamp,
            uint256 mostRecentUndelegationTimestamp
            )
    {
        User storage user = users[userAddress];
        unstaked = user.unstaked;
        vesting = user.vesting;
        unstakeShares = user.unstakeShares;
        unstakeAmount = user.unstakeAmount;
        unstakeScheduledFor = user.unstakeScheduledFor;
        mostRecentProposalTimestamp = user.mostRecentProposalTimestamp;
        mostRecentVoteTimestamp = user.mostRecentVoteTimestamp;
        mostRecentDelegationTimestamp = user.mostRecentDelegationTimestamp;
        mostRecentUndelegationTimestamp = user.mostRecentUndelegationTimestamp;
    }

    /// @notice Called to get the value of a checkpoint array closest to
    /// the specific block
    /// @param checkpoints Checkpoints array
    /// @param _block Block number for which the query is being made
    /// @return Value of the checkpoint array at the block
    function getValueAt(
        Checkpoint[] storage checkpoints,
        uint256 _block,
        uint256 minimumCheckpointIndex
        )
        internal
        view
        returns(uint256)
    {
        uint256 i = checkpoints.length;
        for (; i > minimumCheckpointIndex; i--)
        {
            if (checkpoints[i - 1].fromBlock <= _block)
            {
                return checkpoints[i - 1].value;
            }
        }
        // Revert if the value being searched for comes before
        // `minimumCheckpointIndex`
        require(i == 0, CHECKPOINT_NOT_FOUND);
        return 0;
    }

    /// @notice Called to get the value of the checkpoint array  closest to the
    /// specific block
    /// @dev Adapted from
    /// https://github.com/aragon/minime/blob/1d5251fc88eee5024ff318d95bc9f4c5de130430/contracts/MiniMeToken.sol#L431
    /// Allows the caller to specify the portion of the array that will be
    /// searched. This allows us to avoid having to search arrays that can grow
    /// unboundedly.
    /// @param checkpoints Checkpoint array
    /// @param _block Block number for which the query is being made
    /// @param minimumCheckpointIndex Index of the earliest checkpoint that may
    /// be keeping the value we are looking for
    /// @return Value of the checkpoint array at `_block`
    function getValueAtWithBinarySearch(
        Checkpoint[] storage checkpoints,
        uint256 _block,
        uint256 minimumCheckpointIndex
        )
        internal
        view
        returns(uint256)
    {
        if (checkpoints.length == 0)
            return 0;
        assert(checkpoints.length > minimumCheckpointIndex);

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length - 1].fromBlock) {
            return checkpoints[checkpoints.length - 1].value;
        }
        // Revert if the value being searched for comes before
        // `minimumCheckpointIndex`
        if (_block < checkpoints[minimumCheckpointIndex].fromBlock) {
            if (minimumCheckpointIndex == 0) {
                return 0;
            }
            else {
                revert(CHECKPOINT_NOT_FOUND);
            }
        }

        // Binary search of the value in the array
        uint min = minimumCheckpointIndex;
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
}


// File contracts/interfaces/IRewardUtils.sol

pragma solidity 0.8.4;

interface IRewardUtils is IGetterUtils {
    event PaidReward(
        uint256 indexed epoch,
        uint256 rewardAmount,
        uint256 apr
        );

    function payReward()
        external;
}


// File contracts/RewardUtils.sol

pragma solidity 0.8.4;


/// @title Contract that implements reward payments and locks
abstract contract RewardUtils is GetterUtils, IRewardUtils {
    /// @notice Called to pay the reward for the current epoch
    /// @dev Skips past epochs for which rewards have not been paid for.
    /// Skips the reward payment if the pool is not authorized to mint tokens.
    /// Neither of these conditions will occur in practice.
    function payReward()
        public
        override
    {
        uint256 currentEpoch = block.timestamp / EPOCH_LENGTH;
        // This will be skipped in most cases because someone else will have
        // triggered the payment for this epoch
        if (epochIndexOfLastRewardPayment < currentEpoch)
        {
            if (api3Token.getMinterStatus(address(this)))
            {
                updateCurrentApr();
                uint256 rewardAmount = totalStake * currentApr / REWARD_VESTING_PERIOD / HUNDRED_PERCENT;
                epochIndexToReward[currentEpoch] = Reward({
                    atBlock: block.number,
                    amount: rewardAmount,
                    totalSharesThen: totalShares()
                    });
                api3Token.mint(address(this), rewardAmount);
                totalStake = totalStake + rewardAmount;
                emit PaidReward(
                    currentEpoch,
                    rewardAmount,
                    currentApr
                    );
            }
            epochIndexOfLastRewardPayment = currentEpoch;
        }
    }

    /// @notice Updates the current APR
    /// @dev Called internally before paying out the reward
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

    string internal constant ERROR_DELEGATION_BALANCE = "API3DAO.DelegationUtils: Cannot delegate zero shares";
    string internal constant ERROR_DELEGATION_ADRESSES =
    "API3DAO.DelegationUtils: Cannot delegate to yourself or zero address and if you've already delegated";
    string internal constant ERROR_DELEGATED_RECENTLY =
    "API3DAO.DelegationUtils: This address un/delegated less than a week before";
    string internal constant ERROR_ACTIVE_RECENTLY =
    "API3DAO.DelegationUtils: This address voted or made a proposal less than a week before";
    string internal constant ERROR_NOT_DELEGATED =
    "API3DAO.DelegationUtils: This address has not delegated";

    /// @notice Called by the user to delegate voting power
    /// @param delegate User address the voting power will be delegated to
    function delegateVotingPower(address delegate)
        external
        override
    {
        payReward();
        // Delegating users cannot use their voting power, so we verify that
        // the delegate is not currently delegating. However,
        // the delegate may delegate after they have been delegated to.
        require(
            delegate != address(0)
                && delegate != msg.sender
                && getUserDelegate(delegate) == address(0),
                ERROR_DELEGATION_ADRESSES
            );
        User storage user = users[msg.sender];
        // Do not allow frequent delegation updates as that can be used to spam
        // proposals
        require(
            user.mostRecentDelegationTimestamp <= block.timestamp - EPOCH_LENGTH
                && user.mostRecentUndelegationTimestamp <= block.timestamp - EPOCH_LENGTH,
                ERROR_DELEGATED_RECENTLY
            );
        // Do not allow the user to delegate if they have voted or made a proposal
        // in the last epoch to prevent double voting
        require(
            user.mostRecentProposalTimestamp <= block.timestamp - EPOCH_LENGTH
                && user.mostRecentVoteTimestamp <= block.timestamp - EPOCH_LENGTH,
                ERROR_ACTIVE_RECENTLY
            );
        user.mostRecentDelegationTimestamp = block.timestamp;
        uint256 userShares = userShares(msg.sender);
        address userDelegate = getUserDelegate(msg.sender);
        require(userShares > 0, ERROR_DELEGATION_BALANCE );
        require(userDelegate != delegate, ERROR_DELEGATE);

        if (userDelegate != address(0)) {
            // Revoke previous delegation
            updateCheckpointArray(
                users[userDelegate].delegatedTo,
                userReceivedDelegation(userDelegate) - userShares
                );
            emit Undelegated(
                msg.sender,
                userDelegate
            );
        }
        // Assign the new delegation
        User storage _delegate = users[delegate];
        updateCheckpointArray(
            _delegate.delegatedTo,
            userReceivedDelegation(delegate) + userShares
            );
        // Record the new delegate for the user
        updateAddressCheckpointArray(
            user.delegates,
            delegate
            );
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
        payReward();
        User storage user = users[msg.sender];
        address userDelegate = getUserDelegate(msg.sender);
        require(userDelegate != address(0), ERROR_NOT_DELEGATED);
        // Do not allow frequent delegation updates as that can be used to spam
        // proposals
        require(
            user.mostRecentDelegationTimestamp <= block.timestamp - EPOCH_LENGTH
                && user.mostRecentUndelegationTimestamp <= block.timestamp - EPOCH_LENGTH,
            ERROR_DELEGATED_RECENTLY
            );

        uint256 userShares = userShares(msg.sender);
        User storage delegate = users[userDelegate];
        updateCheckpointArray(
            delegate.delegatedTo,
            userReceivedDelegation(userDelegate) - userShares
            );
        updateAddressCheckpointArray(
            user.delegates,
            address(0)
            );
        user.mostRecentUndelegationTimestamp = block.timestamp;
        emit Undelegated(
            msg.sender,
            userDelegate
            );
    }

    /// @notice Called internally when the user shares are updated to update
    /// the delegated voting power
    /// @dev User shares only get updated while staking or scheduling unstaking
    /// @param userAddress Address of the user whose delegated voting power
    /// will be updated
    /// @param shares Amount of shares that will be added/removed
    /// @param delta Whether the shares will be added/removed (add for `true`,
    /// and vice versa)
    function updateDelegatedVotingPower(
        address userAddress,
        uint256 shares,
        bool delta
        )
        internal
    {
        address userDelegate = getUserDelegate(userAddress);
        if (userDelegate == address(0)) {
            return;
        }

        User storage delegate = users[userDelegate];
        uint256 currentlyDelegatedTo = userReceivedDelegation(userDelegate);
        uint256 newDelegatedTo;
        if (delta) {
            newDelegatedTo = currentlyDelegatedTo + shares;
        } else {
            newDelegatedTo = currentlyDelegatedTo > shares
                ? currentlyDelegatedTo - shares
                : 0;
        }
        updateCheckpointArray(
            delegate.delegatedTo,
            newDelegatedTo
            );
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
        address indexed destination,
        uint256 amount
        );

    function deposit(
        address source,
        uint256 amount,
        address userAddress
        )
        external;

    function withdraw(
        address destination,
        uint256 amount
        )
        external;
}


// File contracts/TransferUtils.sol

pragma solidity 0.8.4;


/// @title Contract that implements token transfer functionality
abstract contract TransferUtils is DelegationUtils, ITransferUtils {

    string private constant WRONG_TOTAL_FUNDS =
    "API3DAO.TransferUtils: User total funds should be bigger then locked and amount to withdraw";
    string private constant AMOUNT_TOO_BIG =
    "API3DAO.TransferUtils: Withdrawal amount should be less or equal to the unstaked tokens";

    /// @notice Called to deposit tokens for a user by using `transferFrom()`
    /// @dev This method is used by `TimelockManager.sol`
    /// @param source Token transfer source
    /// @param amount Amount to be deposited
    /// @param userAddress User that the tokens will be deposited for
    function deposit(
        address source,
        uint256 amount,
        address userAddress
        )
        public
        override
    {
        payReward();
        users[userAddress].unstaked = users[userAddress].unstaked + amount;
        api3Token.transferFrom(source, address(this), amount);
        emit Deposited(
            userAddress,
            amount
            );
    }

    /// @notice Called to withdraw tokens
    /// @dev The user should call `getUserLocked()` beforehand to ensure that
    /// they have at least `amount` unlocked tokens to withdraw
    /// @param destination Token transfer destination
    /// @param amount Amount to be withdrawn
    function withdraw(
        address destination,
        uint256 amount
        )
        public
        override
    {
        payReward();
        User storage user = users[msg.sender];
        uint256 userLocked = getUserLocked(msg.sender);
        // Check if the user has `amount` unlocked tokens to withdraw
        uint256 lockedAndVesting = userLocked + user.vesting;
        uint256 userTotalFunds = user.unstaked + userStake(msg.sender);
        require(userTotalFunds >= lockedAndVesting + amount, WRONG_TOTAL_FUNDS);
        // Carry on with the withdrawal
        require(user.unstaked >= amount, AMOUNT_TOO_BIG);
        user.unstaked = user.unstaked - amount;
        api3Token.transfer(destination, amount);
        emit Withdrawn(msg.sender,
            destination,
            amount
            );
    }
}


// File contracts/interfaces/IStakeUtils.sol

pragma solidity 0.8.4;

interface IStakeUtils is ITransferUtils{
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 totalShares
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

    function depositAndStake(
        address source,
        uint256 amount
        )
        external;

    function scheduleUnstake(uint256 shares)
        external;

    function unstake(address userAddress)
        external
        returns(uint256);

    function unstakeAndWithdraw(address destination)
        external;
}


// File contracts/StakeUtils.sol

pragma solidity 0.8.4;


/// @title Contract that implements staking functionality
abstract contract StakeUtils is TransferUtils, IStakeUtils {


    string private constant ERROR_NOT_ENOUGH_FUNDS = "API3DAO.StakeUtils: User don't have enough token to stake/unstake the provided amount";
    string private constant ERROR_NOT_ENOUGH_SHARES = "API3DAO.StakeUtils: User don't have enough pool shares to unstake the provided amount";
    string private constant ERROR_UNSTAKE_TIMING = "API3DAO.StakeUtils: Scheduled unstake has not matured yet";
    string private constant ERROR_STAKING_ADDRESS = "API3DAO.StakeUtils: It is only possible to stake to yourself";
    string private constant ERROR_ALREADY_SCHEDULED = "API3DAO.StakeUtils: User has already scheduled an unstake";
    string private constant ERROR_NO_SCHEDULED = "API3DAO.StakeUtils: User has no scheduled unstake to execute";

    /// @notice Called to stake tokens to receive pools in the share
    /// @param amount Amount of tokens to stake
    function stake(uint256 amount)
        public
        override
    {
        payReward();
        User storage user = users[msg.sender];
        require(user.unstaked >= amount, ERROR_NOT_ENOUGH_FUNDS);
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
        updateDelegatedVotingPower(msg.sender, sharesToMint, true);
        emit Staked(
            msg.sender,
            amount,
            totalSharesAfter
            );
    }

    /// @notice Convenience method to deposit and stake in a single transaction
    /// @dev Due to the `deposit()` interface, `userAddress` can only be the
    /// caller
    /// @param source Token transfer source
    /// @param amount Amount to be deposited and staked
    function depositAndStake(
        address source,
        uint256 amount
        )
        external
        override
    {
        deposit(source, amount, msg.sender);
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
    /// @param shares Amount of shares to be burned to unstake tokens
    function scheduleUnstake(uint256 shares)
        external
        override
    {
        payReward();
        uint256 userSharesNow = userShares(msg.sender);
        require(
            userSharesNow >= shares,
            ERROR_NOT_ENOUGH_SHARES
            );
        User storage user = users[msg.sender];
        require(user.unstakeScheduledFor == 0, ERROR_ALREADY_SCHEDULED);
        uint256 amount = shares * totalStake / totalShares();
        user.unstakeScheduledFor = block.timestamp + unstakeWaitPeriod;
        user.unstakeAmount = amount;
        user.unstakeShares = shares;
        user.shares.push(Checkpoint({
            fromBlock: block.number,
            value: userSharesNow - shares
            }));
        updateDelegatedVotingPower(msg.sender, shares, false);
        emit ScheduledUnstake(
            msg.sender,
            shares,
            amount,
            user.unstakeScheduledFor
            );
    }

    /// @notice Called to execute a pre-scheduled unstake
    /// @dev Anyone can execute a mature scheduled unstake
    /// @param userAddress Address of the user whose scheduled unstaking will
    /// be executed
    /// @return Amount of tokens that are unstaked
    function unstake(address userAddress)
        public
        override
        returns(uint256)
    {
        payReward();
        User storage user = users[userAddress];
        require(user.unstakeScheduledFor != 0, ERROR_NO_SCHEDULED);
        require(user.unstakeScheduledFor < block.timestamp, ERROR_UNSTAKE_TIMING);

        uint256 totalShares = totalShares();
        uint256 unstakeAmountAtSchedulingTime = user.unstakeAmount;
        uint256 unstakeAmountByShares = user.unstakeShares * totalStake / totalShares;
        uint256 unstakeAmount = unstakeAmountAtSchedulingTime > unstakeAmountByShares
            ? unstakeAmountByShares
            : unstakeAmountAtSchedulingTime;
        unstakeAmount = unstakeAmount < totalStake ? unstakeAmount : totalStake - 1;
        user.unstaked = user.unstaked + unstakeAmount;

        updateTotalShares(totalShares - user.unstakeShares);
        totalStake = totalStake - unstakeAmount;

        user.unstakeShares = 0;
        user.unstakeAmount = 0;
        user.unstakeScheduledFor = 0;      
        emit Unstaked(
            userAddress,
            unstakeAmount
            );
        return unstakeAmount;
    }

    /// @notice Convenience method to execute an unstake and withdraw in a
    /// single transaction
    /// @dev Note that withdraw may revert because the user may have less than
    /// `unstaked` tokens that are withdrawable
    /// @param destination Token transfer destination
    function unstakeAndWithdraw(address destination)
        external
        override
    {
        uint256 unstaked = unstake(msg.sender);
        withdraw(destination, unstaked);
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


    string private constant ERROR_CLAIM_AMOUNT = "API3DAO.ClaimUtils: Total stake should be bigger then claim amount";
    string private constant ERROR_CLAIM_MANAGER = "API3DAO.ClaimUtils: Only claim manager is allowed to perform this action";

    /// @dev Reverts if the caller is not a claims manager
    modifier onlyClaimsManager() {
        require(claimsManagerStatus[msg.sender], ERROR_CLAIM_MANAGER);
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
        payReward();
        // totalStake should not go lower than 1
        require(totalStake > amount, ERROR_CLAIM_AMOUNT);
        totalStake = totalStake - amount;
        api3Token.transfer(recipient, amount);
        emit PaidOutClaim(
            recipient,
            amount
            );
    }
}


// File contracts/interfaces/ITimelockUtils.sol

pragma solidity 0.8.4;

interface ITimelockUtils is IClaimUtils {
    event DepositedVesting(
        address indexed user,
        uint256 amount,
        uint256 start,
        uint256 end
        );

    event UpdatedTimelock(
        address indexed user,
        address indexed timelockManagerAddress,
        uint256 remainingAmount
        );

    function depositWithVesting(
        address source,
        uint256 amount,
        address userAddress,
        uint256 releaseStart,
        uint256 releaseEnd
        )
        external;

    function updateTimelockStatus(
        address userAddress,
        address timelockManagerAddress
        )
        external;
}


// File contracts/TimelockUtils.sol

pragma solidity 0.8.4;


/// @title Contract that implements vesting functionality
/// @dev TimelockManager contracts interface with this contract to transfer
/// API3 tokens that are locked under a vesting schedule.
abstract contract TimelockUtils is ClaimUtils, ITimelockUtils {

    string private constant INVALID_TIME_OR_AMOUNT =
    "API3DAO.TimelockUtils: AMOUNT SHOULD BE GREATER THEN 0 AND releaseEnd > releaseStart";
    string private constant ERROR_LOCKED_TOKENS = "API3DAO.TimelockUtils: User shouldn't have timelocked tokens";
    string private constant ERROR_BEFORE_RELEASE = "API3DAO.TimelockUtils: Cannot update status before releaseStart";
    string private constant ERROR_ZERO_AMOUNT = "API3DAO.TimelockUtils: Locked amount should be greater than 0";

    struct Timelock
    {
        uint256 totalAmount;
        uint256 remainingAmount;
        uint256 releaseStart;
        uint256 releaseEnd;
    }

    /// @notice Maps user addresses to TimelockManager contract addresses to
    /// timelocks
    /// @dev This implies that a user cannot have multiple timelocks
    /// transferrerd from the same TimelockManager contract. This is
    /// acceptable, because the TimelockManager is implemented in a way to not
    /// allow multiple timelocks per user.
    mapping(address => mapping(address => Timelock)) public userToDepositorToTimelock;

    /// @notice Called by TimelockManager contracts to deposit tokens on behalf
    /// of a user on a linear vesting schedule
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
        require(userToDepositorToTimelock[userAddress][msg.sender].remainingAmount == 0, ERROR_LOCKED_TOKENS);
        require(
            releaseEnd > releaseStart
                && amount != 0,
            INVALID_TIME_OR_AMOUNT
            );
        users[userAddress].unstaked = users[userAddress].unstaked + amount;
        users[userAddress].vesting = users[userAddress].vesting + amount;
        userToDepositorToTimelock[userAddress][msg.sender] = Timelock({
            totalAmount: amount,
            remainingAmount: amount,
            releaseStart: releaseStart,
            releaseEnd: releaseEnd
            });
        api3Token.transferFrom(source, address(this), amount);
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
    /// @param timelockManagerAddress Address of the TimelockManager that has
    /// created the timelock
    function updateTimelockStatus(
        address userAddress,
        address timelockManagerAddress
        )
        external
        override
    {
        Timelock storage timelock = userToDepositorToTimelock[userAddress][timelockManagerAddress];
        require(block.timestamp > timelock.releaseStart, ERROR_BEFORE_RELEASE);
        require(timelock.remainingAmount > 0, ERROR_ZERO_AMOUNT);
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
        userToDepositorToTimelock[userAddress][timelockManagerAddress].remainingAmount = newRemainingAmount;
        emit UpdatedTimelock(
            userAddress,
            timelockManagerAddress,
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
/// shares. These shares are exposed to the Aragon-based DAO with a
/// pseudo-MiniMe token interface, giving the user voting power at the DAO.
/// Staking pays out weekly rewards that get unlocked after a year, and staked
/// funds are used to collateralize an insurance product that is outside the
/// scope of this contract.
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
    constructor(address api3TokenAddress)
        StateUtils(api3TokenAddress)
    {}
}