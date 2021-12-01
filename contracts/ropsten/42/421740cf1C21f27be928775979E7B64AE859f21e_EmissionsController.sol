// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IGovernanceHook } from "../governance/staking/interfaces/IGovernanceHook.sol";
import { IRewardsDistributionRecipient } from "../interfaces/IRewardsDistributionRecipient.sol";
import { IVotes } from "../interfaces/IVotes.sol";
import { ImmutableModule } from "../shared/ImmutableModule.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct HistoricVotes {
    // Number of votes directed to this dial
    uint128 votes;
    // The start of the distribution period in seconds divided by 604,800 seconds in a week
    uint32 epoch;
}

struct DialData {
    // If true, no rewards are distributed to the dial recipient and any votes on this dial are ignored
    bool disabled;
    // If true, `notifyRewardAmount` on the recipient contract is called
    bool notify;
    // Cap on distribution % where 1% = 1
    uint8 cap;
    // Dial rewards that are waiting to be distributed to recipient
    uint96 balance;
    // Account rewards are distributed to
    address recipient;
    // List of weighted votes in each distribution period
    HistoricVotes[] voteHistory;
}

struct Preference {
    // ID of the dial (array position)
    uint8 dialId;
    // % weight applied to this dial, where 200 = 100% and 1 = 0.5%
    uint8 weight;
}

struct VoterPreferences {
    // List of preferences (0 <= n <= 16 preferences).
    // 16 * (8 + 8) = 256 bits = 1 slot
    Preference[16] dialWeights;
    // Total voting power cast by this voter across the staking contracts.
    uint128 votesCast;
    // Last time balance was looked up across all staking contracts
    uint32 lastSourcePoke;
}

struct TopLevelConfig {
    int256 A;
    int256 B;
    int256 C;
    int256 D;
    uint128 EPOCHS;
}

struct EpochHistory {
    // First weekly epoch of this contract.
    uint32 startEpoch;
    // The last weekly epoch to have rewards distributed.
    uint32 lastEpoch;
}

/**
 * @title  EmissionsController
 * @author mStable
 * @notice Allows governors to vote on the weekly distribution of $MTA. Rewards are distributed between
 *         `n` "Dials" proportionately to the % of votes the dial receives. Vote weight derives from multiple
 *         whitelisted "Staking contracts". Voters can distribute their vote across (0 <= n <= 16 dials), at 0.5%
 *         increments in voting weight. Once their preferences are cast, each time their voting weight changes
 *         it is reflected here through a hook.
 * @dev    VERSION: 1.0
 *         DATE:    2021-10-28
 */
contract EmissionsController is IGovernanceHook, Initializable, ImmutableModule {
    using SafeERC20 for IERC20;

    /// @notice Minimum time between distributions.
    uint32 constant DISTRIBUTION_PERIOD = 1 weeks;
    /// @notice Scale of dial weights. 200 = 100%, 2 = 1%, 1 = 0.5%
    uint256 constant SCALE = 200;
    /// @notice Polynomial top level emission function parameters
    int256 immutable A;
    int256 immutable B;
    int256 immutable C;
    int256 immutable D;
    uint128 immutable EPOCHS;

    /// @notice Address of rewards token. ie MTA token
    IERC20 public immutable REWARD_TOKEN;

    /// @notice Epoch history in storage
    ///         An epoch is the number of weeks since 1 Jan 1970. The week starts on Thursday 00:00 UTC.
    ///         epoch = start of the distribution period in seconds divided by 604,800 seconds in a week
    EpochHistory public epochs;

    /// @notice Flags the timestamp that a given staking contract was added
    mapping(address => uint32) public stakingContractAddTime;
    /// @notice List of staking contract addresses.
    IVotes[] public stakingContracts;

    /// @notice List of dial data including votes, rewards balance, recipient contract and disabled flag.
    DialData[] public dials;

    /// @notice Mapping of staker addresses to an list of voter dial weights.
    /// @dev    The sum of the weights for each staker must not be greater than SCALE = 200.
    ///         A user can issue a subset of their voting power. eg only 20% of their voting power.
    ///         A user can not issue more than 100% of their voting power across dials.
    mapping(address => VoterPreferences) public voterPreferences;

    event AddedDial(uint256 indexed dialId, address indexed recipient);
    event UpdatedDial(uint256 indexed dialId, bool disabled);
    event AddStakingContract(address indexed stakingContract);

    event PeriodRewards(uint256[] amounts);
    event DonatedRewards(uint256 indexed dialId, uint256 amount);
    event DistributedReward(uint256 indexed dialId, uint256 amount);

    event PreferencesChanged(address indexed voter, Preference[] preferences);
    event VotesCast(
        address stakingContract,
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event SourcesPoked(address indexed voter, uint256 newVotesCast);

    /***************************************
                    INIT
    ****************************************/

    /**
     * @notice Recipient is a module, governed by mStable governance.
     * @param _nexus        System Nexus that resolves module addresses.
     * @param _rewardToken  Token that rewards are distributed in. eg MTA.
     * @param _config       Arguments for polynomial top level emission function (raw, not scaled).
     */
    constructor(
        address _nexus,
        address _rewardToken,
        TopLevelConfig memory _config
    ) ImmutableModule(_nexus) {
        require(_rewardToken != address(0), "Reward token address is zero");
        REWARD_TOKEN = IERC20(_rewardToken);
        A = _config.A * 1e3;
        B = _config.B * 1e3;
        C = _config.C * 1e3;
        D = _config.D * 1e3;
        EPOCHS = _config.EPOCHS;
    }

    /**
     * @dev Initialisation function to configure the first dials. All recipient contracts with _notifies = true need to
     *      implement the `IRewardsDistributionRecipient` interface.
     * @param _recipients        List of dial contract addresses that can receive rewards.
     * @param _caps              Limit on the percentage of the weekly top line emission the corresponding dial can receive (where 10% = 10 and uncapped = 0).
     * @param _notifies          If true, `notifyRewardAmount` is called in the `distributeRewards` function.
     * @param _stakingContracts  Initial staking contracts used for voting power lookup.
     */
    function initialize(
        address[] memory _recipients,
        uint8[] memory _caps,
        bool[] memory _notifies,
        address[] memory _stakingContracts
    ) external initializer {
        uint256 len = _recipients.length;
        require(_notifies.length == len && _caps.length == len, "Initialize args mismatch");

        // 1.0 - Set the last epoch storage variable to the immutable start epoch
        //       Set the weekly epoch this contract starts distributions which will be 1 - 2 week after deployment.
        uint32 startEpoch = _epoch(block.timestamp) + 1;
        epochs = EpochHistory({ startEpoch: startEpoch, lastEpoch: startEpoch });

        // 2.0 - Add each of the dials
        for (uint256 i = 0; i < len; i++) {
            _addDial(_recipients[i], _caps[i], _notifies[i]);
        }

        // 3.0 - Initialize the staking contracts
        for (uint256 i = 0; i < _stakingContracts.length; i++) {
            _addStakingContract(_stakingContracts[i]);
        }
    }

    /***************************************
                    VIEW
    ****************************************/

    /**
     * @notice Gets the users aggregate voting power across all voting contracts.
     * @dev    Voting power can be from staking or it could be delegated to the account.
     * @param account       For which to fetch voting power.
     * @return votingPower  Units of voting power owned by account.
     */
    function getVotes(address account) public view returns (uint256 votingPower) {
        // For each configured staking contract
        for (uint256 i = 0; i < stakingContracts.length; i++) {
            votingPower += stakingContracts[i].getVotes(account);
        }
    }

    /**
     * @notice Calculates top line distribution amount for the current epoch as per the polynomial.
     *          (f(x)=A*(x/div)^3+B*(x/div)^2+C*(x/div)+D)
     * @dev    Values are effectively scaled to 1e12 to avoid integer overflow on pow.
     * @param epoch              The number of weeks since 1 Jan 1970.
     * @return emissionForEpoch  Units of MTA to be distributed at this epoch.
     */
    function topLineEmission(uint32 epoch) public view returns (uint256 emissionForEpoch) {
        require(
            epochs.startEpoch < epoch && epoch <= epochs.startEpoch + 312,
            "Wrong epoch number"
        );
        // e.g. week 1, A = -166000e12, B = 168479942061125e3, C = -168479942061125e3, D = 166000e12
        // e.g. epochDelta = 1
        uint128 epochDelta = (epoch - epochs.startEpoch);
        // e.g. x = 1e12 / 312 = 3205128205
        int256 x = SafeCast.toInt256((epochDelta * 1e12) / EPOCHS);
        emissionForEpoch =
            SafeCast.toUint256(
                ((A * (x**3)) / 1e36) + // e.g. -166000e12         * (3205128205 ^ 3) / 1e36 = -5465681315
                    ((B * (x**2)) / 1e24) + // e.g.  168479942061125e3 * (3205128205 ^ 2) / 1e24 =  1730768635433
                    ((C * (x)) / 1e12) + // e.g. -168479942061125e3 *  3205128205      / 1e12 = -539999814276877
                    D // e.g.  166000e12
            ) *
            1e6; // e.g. SUM = 165461725488677241 * 1e6 = 165461e18
    }

    /**
     * @notice Gets a dial's recipient address.
     * @param dialId      Dial identifier starting from 0.
     * @return recipient  Address of the recipient account associated with.
     */
    function getDialRecipient(uint256 dialId) public view returns (address recipient) {
        recipient = dials[dialId].recipient;
    }

    /**
     * @notice Gets a dial's weighted votes for each distribution period.
     * @param dialId        Dial identifier starting from 0.
     * @return voteHistory  List of weighted votes with the first distribution at index 0.
     */
    function getDialVoteHistory(uint256 dialId)
        public
        view
        returns (HistoricVotes[] memory voteHistory)
    {
        voteHistory = dials[dialId].voteHistory;
    }

    /**
     * @notice Gets the number of weighted votes for each dial for a given week's distribution.
     *         The weekly rewards does not have to be calculated. When running for the current week it'll return
     *         the weighted votes for the dials as they currently stand.
     * @param epoch      The week of the distribution measured as the number of weeks since 1 Jan 1970.
     * @return dialVotes A list of dials votes for that week. The index of the array is the dialId.
     */
    function getEpochVotes(uint32 epoch) public view returns (uint256[] memory dialVotes) {
        uint256 dialLen = dials.length;
        dialVotes = new uint256[](dialLen);
        require(epoch <= epochs.lastEpoch, "invalid epoch");

        for (uint256 i = 0; i < dialLen; i++) {
            DialData memory dialData = dials[i];

            // If no distributions for this dial yet
            if (dialData.voteHistory.length == 0) {
                continue;
            }
            // If the epoch is before distributions for this dial
            uint256 firstDialEpoch = dialData.voteHistory[0].epoch;
            if (epoch < firstDialEpoch) {
                continue;
            }

            // The following assume rewards were calculated every week
            uint256 voteHistoryIndex = epoch - firstDialEpoch;
            dialVotes[i] = dialData.voteHistory[voteHistoryIndex].votes;
        }
    }

    /**
     * @notice Gets a voter's weights for each dial.
     * @dev    A dial identifier of 255 marks the end  of the array. It should be ignored.
     * @param voter         Address of the voter that has set weights.
     * @return preferences  List of dial identifiers and weights where a weight of 100% = 200.
     */
    function getVoterPreferences(address voter)
        public
        view
        returns (Preference[16] memory preferences)
    {
        preferences = voterPreferences[voter].dialWeights;
    }

    /***************************************
                    ADMIN
    ****************************************/

    /**
     * @notice Adds a new dial that can be voted on to receive weekly rewards. Callable by system governor.
     * @param _recipient  Address of the contract that will receive rewards.
     * @param _cap        Cap where 0 = uncapped and 10 = 10%.
     * @param _notify     If true, `notifyRewardAmount` is called in the `distributeRewards` function.
     */
    function addDial(
        address _recipient,
        uint8 _cap,
        bool _notify
    ) external onlyGovernor {
        _addDial(_recipient, _cap, _notify);
    }

    /**
     * @dev Internal dial addition fn, see parent fn for details.
     */
    function _addDial(
        address _recipient,
        uint8 _cap,
        bool _notify
    ) internal {
        require(_recipient != address(0), "Dial address is zero");
        require(_cap < 100, "Invalid cap");

        uint256 len = dials.length;
        require(len < 254, "Max dial count reached");
        for (uint256 i = 0; i < len; i++) {
            require(dials[i].recipient != _recipient, "Dial already exists");
        }

        dials.push();
        DialData storage newDialData = dials[len];
        newDialData.recipient = _recipient;
        newDialData.notify = _notify;
        newDialData.cap = _cap;
        uint32 currentEpoch = _epoch(block.timestamp);
        if (currentEpoch < epochs.startEpoch) {
            currentEpoch = epochs.startEpoch;
        }
        newDialData.voteHistory.push(HistoricVotes({ votes: 0, epoch: currentEpoch }));

        emit AddedDial(len, _recipient);
    }

    /**
     * @notice Updates a dials recipient contract and/or disabled flag.
     * @param _dialId    Dial identifier which is the index of the dials array.
     * @param _disabled  If true, no rewards will be distributed to this dial.
     */
    function updateDial(uint256 _dialId, bool _disabled) external onlyGovernor {
        require(_dialId < dials.length, "Invalid dial id");

        dials[_dialId].disabled = _disabled;

        emit UpdatedDial(_dialId, _disabled);
    }

    /**
     * @notice Adds a new contract to the list of approved staking contracts.
     * @param _stakingContract Address of the new staking contract
     */
    function addStakingContract(address _stakingContract) external onlyGovernor {
        _addStakingContract(_stakingContract);
    }

    /**
     * @dev Adds a staking contract by setting it's addition time to current timestamp.
     */
    function _addStakingContract(address _stakingContract) internal {
        require(_stakingContract != address(0), "Staking contract address is zero");

        uint256 len = stakingContracts.length;
        for (uint256 i = 0; i < len; i++) {
            require(
                address(stakingContracts[i]) != _stakingContract,
                "StakingContract already exists"
            );
        }

        stakingContractAddTime[_stakingContract] = SafeCast.toUint32(block.timestamp);
        stakingContracts.push(IVotes(_stakingContract));

        emit AddStakingContract(_stakingContract);
    }

    /***************************************
                REWARDS-EXTERNAL
    ****************************************/

    /**
     * @notice Allows arbitrary reward donation to a dial on top of the weekly rewards.
     * @param _dialIds  Dial identifiers that will receive donated rewards.
     * @param _amounts  Units of rewards to be sent to each dial including decimals.
     */
    function donate(uint256[] memory _dialIds, uint256[] memory _amounts) external {
        uint256 dialLen = _dialIds.length;
        require(dialLen > 0 && _amounts.length == dialLen, "Invalid inputs");

        uint256 totalAmount;

        // For each specified dial
        uint256 dialId;
        for (uint256 i = 0; i < dialLen; i++) {
            dialId = _dialIds[i];
            require(dialId < dials.length, "Invalid dial id");

            // Sum the rewards for each dial
            totalAmount += _amounts[i];
            // Add rewards to the dial's rewards balance
            dials[dialId].balance += SafeCast.toUint96(_amounts[i]);

            emit DonatedRewards(dialId, _amounts[i]);
        }

        // Transfer the total donated rewards to this Emissions Controller contract
        REWARD_TOKEN.safeTransferFrom(msg.sender, address(this), totalAmount);
    }

    /**
     * @notice Calculates the rewards to be distributed to each dial for the next weekly period.
     * @dev    Callable once an epoch has fully passed. Top level emission for the epoch is distributed
     *         proportionately to vote count with the following exceptions:
     *          - Disabled dials are ignored and votes not counted.
     *          - Dials with a cap are capped and their votes/emission removed (effectively redistributing rewards).
     */
    function calculateRewards() external {
        // 1 - Calculate amount of rewards to distribute this week
        uint32 epoch = _epoch(block.timestamp);
        require(epoch > epochs.lastEpoch, "Must wait for new period");
        //     Update storage with new last epoch
        epochs.lastEpoch = epoch;
        uint256 emissionForEpoch = topLineEmission(epoch);

        // 2.0 - Calculate the total amount of dial votes ignoring any disabled dials
        uint256 totalDialVotes;
        uint256 dialLen = dials.length;
        uint256[] memory dialVotes = new uint256[](dialLen);
        for (uint256 i = 0; i < dialLen; i++) {
            DialData memory dialData = dials[i];
            if (dialData.disabled) continue;

            // Get the relevant votes for the dial. Possibilities:
            //   - No new votes cast in period, therefore relevant votes are at pos len - 1
            //   - Votes already cast in period, therefore relevant is at pos len - 2
            uint256 end = dialData.voteHistory.length - 1;
            HistoricVotes memory latestVote = dialData.voteHistory[end];
            if (latestVote.epoch < epoch) {
                dialVotes[i] = latestVote.votes;
                totalDialVotes += latestVote.votes;
                // Create a new weighted votes for the current distribution period
                dials[i].voteHistory.push(
                    HistoricVotes({ votes: latestVote.votes, epoch: SafeCast.toUint32(epoch) })
                );
            } else if (latestVote.epoch == epoch && end > 0) {
                uint256 votes = dialData.voteHistory[end - 1].votes;
                dialVotes[i] = votes;
                totalDialVotes += votes;
            }
        }

        // 3.0 - Deal with the capped dials
        uint256[] memory distributionAmounts = new uint256[](dialLen);
        uint256 postCappedVotes = totalDialVotes;
        uint256 postCappedEmission = emissionForEpoch;
        for (uint256 k = 0; k < dialLen; k++) {
            DialData memory dialData = dials[k];
            // 3.1 - If the dial has a cap and isn't disabled, check if it's over the threshold
            if (dialData.cap > 0 && !dialData.disabled) {
                uint256 maxVotes = (dialData.cap * totalDialVotes) / 100;
                // If dial has move votes than its cap
                if (dialVotes[k] > maxVotes) {
                    // Calculate amount of rewards for the dial
                    distributionAmounts[k] = (dialData.cap * emissionForEpoch) / 100;
                    // Add dial rewards to balance in storage.
                    // Is addition and not set as rewards could have been donated.
                    dials[k].balance += SafeCast.toUint96(distributionAmounts[k]);

                    // Remove dial votes from total votes
                    postCappedVotes -= dialVotes[k];
                    // Remove capped rewards from total reward
                    postCappedEmission -= distributionAmounts[k];
                    // Set to zero votes so it'll be skipped in the next loop
                    dialVotes[k] = 0;
                }
            }
        }

        // 4.0 - Calculate the distribution amounts for each dial
        for (uint256 l = 0; l < dialLen; l++) {
            // Skip dial if no votes, disabled or was over cap
            if (dialVotes[l] == 0) {
                continue;
            }

            // Calculate amount of rewards for the dial & set storage
            distributionAmounts[l] = (dialVotes[l] * postCappedEmission) / postCappedVotes;
            dials[l].balance += SafeCast.toUint96(distributionAmounts[l]);
        }

        emit PeriodRewards(distributionAmounts);
    }

    /**
     * @notice Transfers all accrued rewards to dials and notifies them of the amount.
     * @param _dialIds  Dial identifiers for which to distribute rewards.
     */
    function distributeRewards(uint256[] memory _dialIds) external {
        // For each specified dial
        uint256 len = _dialIds.length;
        for (uint256 i = 0; i < len; i++) {
            require(_dialIds[i] < dials.length, "Invalid dial id");
            DialData memory dialData = dials[_dialIds[i]];

            // 1.0 - Get the dial's reward balance
            if (dialData.balance == 0) {
                continue;
            }
            // 2.0 - Reset the balance in storage back to 0
            dials[_dialIds[i]].balance = 0;

            // 3.0 - Send the rewards the to the dial recipient
            REWARD_TOKEN.safeTransfer(dialData.recipient, dialData.balance);

            // 4.0 - Notify the dial of the new rewards if configured to
            //       Only after successful transer tx
            if (dialData.notify) {
                IRewardsDistributionRecipient(dialData.recipient).notifyRewardAmount(
                    dialData.balance
                );
            }

            emit DistributedReward(_dialIds[i], dialData.balance);
        }
    }

    /***************************************
                VOTING-EXTERNAL
    ****************************************/

    /**
     * @notice Re-cast a voters votes by retrieving balance across all staking contracts
     *         and updating `lastSourcePoke`.
     * @dev    This would need to be called if a staking contract was added to the emissions controller
     * when a voter already had voting power in the new staking contract and they had already set voting preferences.
     * @param _voter    Address of the voter for which to re-cast.
     */
    function pokeSources(address _voter) public {
        // Only poke if voter has previously set voting preferences
        if (voterPreferences[_voter].lastSourcePoke > 0) {
            uint256 votesCast = voterPreferences[_voter].votesCast;
            uint256 newVotesCast = getVotes(_voter) - votesCast;
            _moveVotingPower(_voter, newVotesCast, _add);
            voterPreferences[_voter].lastSourcePoke = SafeCast.toUint32(block.timestamp);

            emit SourcesPoked(_voter, newVotesCast);
        }
    }

    /**
     * @notice Allows a staker to cast their voting power across a number of dials.
     * @dev    A staker can proportion their voting power even if they currently have zero voting power.
     *         For example, they have delegated their votes. When they do have voting power (e.g. they undelegate),
     *         their set weights will proportion their voting power.
     * @param _preferences  Structs containing dialId & voting weights, with 0 <= n <= 16 entries.
     */
    function setVoterDialWeights(Preference[] memory _preferences) external {
        require(_preferences.length <= 16, "Max of 16 preferences");

        // 1.0 - Get staker's previous total votes cast
        uint256 votesCast = voterPreferences[msg.sender].votesCast;
        // 1.1 - Adjust dial votes from removed staker votes
        _moveVotingPower(msg.sender, votesCast, _subtract);
        //       Clear the old weights as they will be added back below
        delete voterPreferences[msg.sender];

        // 2.0 - Log new preferences
        uint256 newTotalWeight;
        for (uint256 i = 0; i < _preferences.length; i++) {
            require(_preferences[i].dialId < dials.length, "Invalid dial id");
            require(_preferences[i].weight > 0, "Must give a dial some weight");
            newTotalWeight += _preferences[i].weight;
            //  Add staker's dial weight
            voterPreferences[msg.sender].dialWeights[i] = _preferences[i];
        }
        // 2.1 - In the likely scenario less than 16 preferences are given, add a breaker with max uint
        //       to signal that this is the end of array.
        if (_preferences.length < 16) {
            voterPreferences[msg.sender].dialWeights[_preferences.length] = Preference(255, 0);
        }
        require(newTotalWeight <= SCALE, "Imbalanced weights");

        // Need to set before calling _moveVotingPower for the second time
        voterPreferences[msg.sender].lastSourcePoke = SafeCast.toUint32(block.timestamp);

        // 3.0 - Cast votes on these new preferences
        _moveVotingPower(msg.sender, getVotes(msg.sender), _add);

        emit PreferencesChanged(msg.sender, _preferences);
    }

    /**
     * @notice  Called by the staking contracts when a staker has modified voting power.
     * @dev     This can be called when staking, cooling down for withdraw or delegating.
     * @param from    Account that votes moved from. If a mint the account will be a zero address.
     * @param to      Account that votes moved to. If a burn the account will be a zero address.
     * @param amount  The number of votes moved including the decimal places.
     */
    function moveVotingPowerHook(
        address from,
        address to,
        uint256 amount
    ) external override {
        if (amount > 0) {
            bool votesCast;
            // Require that the caller of this function is a whitelisted staking contract
            uint32 addTime = stakingContractAddTime[msg.sender];
            require(addTime > 0, "Caller must be staking contract");

            // If burning (withdraw) or transferring delegated votes from a staker
            if (from != address(0)) {
                uint32 lastSourcePoke = voterPreferences[from].lastSourcePoke;
                if (lastSourcePoke > addTime) {
                    _moveVotingPower(from, amount, _subtract);
                    votesCast = true;
                } else if (lastSourcePoke > 0) {
                    // If preferences were set before the calling staking contract
                    // was added to the EmissionsController
                    pokeSources(from);
                }
                // Don't need to do anything if staker has not set preferences before.
            }
            // If minting (staking) or transferring delegated votes to a staker
            if (to != address(0)) {
                uint32 lastSourcePoke = voterPreferences[to].lastSourcePoke;
                if (lastSourcePoke > addTime) {
                    _moveVotingPower(to, amount, _add);
                    votesCast = true;
                } else if (lastSourcePoke > 0) {
                    // If preferences were set before the calling staking contract
                    // was added to the EmissionsController
                    pokeSources(to);
                }
                // Don't need to do anything if staker has not set preferences before.
            }

            // Only emit if voting power was moved.
            if (votesCast) {
                emit VotesCast(msg.sender, from, to, amount);
            }
        }
    }

    /***************************************
                VOTING-INTERNAL
    ****************************************/

    /**
     * @dev Internal voting power updater. Adds/subtracts votes across the array of user preferences.
     * @param _voter    Address of the source of movement.
     * @param _amount   Total amount of votes to be added/removed (proportionately across the user preferences).
     * @param _op       Function (either addition or subtraction) that dictates how the `_amount` of votes affects balance.
     */
    function _moveVotingPower(
        address _voter,
        uint256 _amount,
        function(uint256, uint256) pure returns (uint256) _op
    ) internal {
        // 0.0 - Get preferences and epoch data
        VoterPreferences memory preferences = voterPreferences[_voter];

        // 0.1 - If no preferences have been set then there is nothing to do
        // This prevent doing 16 iterations below as dialId 255 will not be set
        if (preferences.lastSourcePoke == 0) return;

        // 0.2 - If in the first launch week
        uint32 currentEpoch = _epoch(block.timestamp);

        // 0.3 - Update the total amount of votes cast by the voter
        voterPreferences[_voter].votesCast = SafeCast.toUint128(
            _op(preferences.votesCast, _amount)
        );

        // 1.0 - Loop through voter preferences until dialId == 255 or until end
        for (uint256 i = 0; i < 16; i++) {
            Preference memory pref = preferences.dialWeights[i];
            if (pref.dialId == 255) break;

            // 1.1 - Scale the vote by dial weight
            //       e.g. 5e17 * 1e18 / 1e18 * 100e18 / 1e18 = 50e18
            uint256 amountToChange = (pref.weight * _amount) / SCALE;

            // 1.2 - Fetch voting history for this dial
            HistoricVotes[] storage voteHistory = dials[pref.dialId].voteHistory;
            uint256 len = voteHistory.length;
            HistoricVotes storage latestHistoricVotes = voteHistory[len - 1];

            // 1.3 - Determine new votes cast for dial
            uint128 newVotes = SafeCast.toUint128(_op(latestHistoricVotes.votes, amountToChange));

            // 1.4 - Update dial vote count. If first vote in new epoch, create new entry
            if (latestHistoricVotes.epoch < currentEpoch) {
                // Add a new weighted votes epoch for the dial
                voteHistory.push(HistoricVotes({ votes: newVotes, epoch: currentEpoch }));
            } else {
                // Epoch already exists for this dial so just update the dial's weighted votes
                latestHistoricVotes.votes = newVotes;
            }
        }
    }

    /**
     * @notice Returns the epoch index the timestamp is on.
     *         This is the number of weeks since 1 Jan 1970. ie the timestamp / 604800 seconds in a week.
     * @dev    Each week starts on Thursday 00:00 UTC.
     * @param timestamp UNIX time in seconds.
     * @return epoch    The number of weeks since 1 Jan 1970.
     */
    function _epoch(uint256 timestamp) internal pure returns (uint32 epoch) {
        epoch = SafeCast.toUint32(timestamp) / DISTRIBUTION_PERIOD;
    }

    /**
     * @dev Simple addition function, used in the `_moveVotingPower` fn.
     */
    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Simple subtraction function, used in the `_moveVotingPower` fn.
     */
    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

interface IGovernanceHook {
    function moveVotingPowerHook(
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardsDistributionRecipient {
    function notifyRewardAmount(uint256 reward) external;

    function getRewardToken() external view returns (IERC20);
}

interface IRewardsRecipientWithPlatformToken {
    function notifyRewardAmount(uint256 reward) external;

    function getRewardToken() external view returns (IERC20);

    function getPlatformToken() external view returns (IERC20);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

interface IVotes {
    function getVotes(address account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { ModuleKeys } from "./ModuleKeys.sol";
import { INexus } from "../interfaces/INexus.sol";

/**
 * @title   ImmutableModule
 * @author  mStable
 * @dev     Subscribes to module updates from a given publisher and reads from its registry.
 *          Contract is used for upgradable proxy contracts.
 */
abstract contract ImmutableModule is ModuleKeys {
    INexus public immutable nexus;

    /**
     * @dev Initialization function for upgradable proxy contracts
     * @param _nexus Nexus contract address
     */
    constructor(address _nexus) {
        require(_nexus != address(0), "Nexus address is zero");
        nexus = INexus(_nexus);
    }

    /**
     * @dev Modifier to allow function calls only from the Governor.
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function _onlyGovernor() internal view {
        require(msg.sender == _governor(), "Only governor can execute");
    }

    /**
     * @dev Modifier to allow function calls only from the Governance.
     *      Governance is either Governor address or Governance address.
     */
    modifier onlyGovernance() {
        require(
            msg.sender == _governor() || msg.sender == _governance(),
            "Only governance can execute"
        );
        _;
    }

    /**
     * @dev Returns Governor address from the Nexus
     * @return Address of Governor Contract
     */
    function _governor() internal view returns (address) {
        return nexus.governor();
    }

    /**
     * @dev Returns Governance Module address from the Nexus
     * @return Address of the Governance (Phase 2)
     */
    function _governance() internal view returns (address) {
        return nexus.getModule(KEY_GOVERNANCE);
    }

    /**
     * @dev Return SavingsManager Module address from the Nexus
     * @return Address of the SavingsManager Module contract
     */
    function _savingsManager() internal view returns (address) {
        return nexus.getModule(KEY_SAVINGS_MANAGER);
    }

    /**
     * @dev Return Recollateraliser Module address from the Nexus
     * @return  Address of the Recollateraliser Module contract (Phase 2)
     */
    function _recollateraliser() internal view returns (address) {
        return nexus.getModule(KEY_RECOLLATERALISER);
    }

    /**
     * @dev Return Liquidator Module address from the Nexus
     * @return  Address of the Liquidator Module contract
     */
    function _liquidator() internal view returns (address) {
        return nexus.getModule(KEY_LIQUIDATOR);
    }

    /**
     * @dev Return ProxyAdmin Module address from the Nexus
     * @return Address of the ProxyAdmin Module contract
     */
    function _proxyAdmin() internal view returns (address) {
        return nexus.getModule(KEY_PROXY_ADMIN);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title  ModuleKeys
 * @author mStable
 * @notice Provides system wide access to the byte32 represntations of system modules
 *         This allows each system module to be able to reference and update one another in a
 *         friendly way
 * @dev    keccak256() values are hardcoded to avoid re-evaluation of the constants at runtime.
 */
contract ModuleKeys {
    // Governance
    // ===========
    // keccak256("Governance");
    bytes32 internal constant KEY_GOVERNANCE =
        0x9409903de1e6fd852dfc61c9dacb48196c48535b60e25abf92acc92dd689078d;
    //keccak256("Staking");
    bytes32 internal constant KEY_STAKING =
        0x1df41cd916959d1163dc8f0671a666ea8a3e434c13e40faef527133b5d167034;
    //keccak256("ProxyAdmin");
    bytes32 internal constant KEY_PROXY_ADMIN =
        0x96ed0203eb7e975a4cbcaa23951943fa35c5d8288117d50c12b3d48b0fab48d1;

    // mStable
    // =======
    // keccak256("OracleHub");
    bytes32 internal constant KEY_ORACLE_HUB =
        0x8ae3a082c61a7379e2280f3356a5131507d9829d222d853bfa7c9fe1200dd040;
    // keccak256("Manager");
    bytes32 internal constant KEY_MANAGER =
        0x6d439300980e333f0256d64be2c9f67e86f4493ce25f82498d6db7f4be3d9e6f;
    //keccak256("Recollateraliser");
    bytes32 internal constant KEY_RECOLLATERALISER =
        0x39e3ed1fc335ce346a8cbe3e64dd525cf22b37f1e2104a755e761c3c1eb4734f;
    //keccak256("MetaToken");
    bytes32 internal constant KEY_META_TOKEN =
        0xea7469b14936af748ee93c53b2fe510b9928edbdccac3963321efca7eb1a57a2;
    // keccak256("SavingsManager");
    bytes32 internal constant KEY_SAVINGS_MANAGER =
        0x12fe936c77a1e196473c4314f3bed8eeac1d757b319abb85bdda70df35511bf1;
    // keccak256("Liquidator");
    bytes32 internal constant KEY_LIQUIDATOR =
        0x1e9cb14d7560734a61fa5ff9273953e971ff3cd9283c03d8346e3264617933d4;
    // keccak256("InterestValidator");
    bytes32 internal constant KEY_INTEREST_VALIDATOR =
        0xc10a28f028c7f7282a03c90608e38a4a646e136e614e4b07d119280c5f7f839f;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title INexus
 * @dev Basic interface for interacting with the Nexus i.e. SystemKernel
 */
interface INexus {
    function governor() external view returns (address);

    function getModule(bytes32 key) external view returns (address);

    function proposeModule(bytes32 _key, address _addr) external;

    function cancelProposedModule(bytes32 _key) external;

    function acceptProposedModule(bytes32 _key) external;

    function acceptProposedModules(bytes32[] calldata _keys) external;

    function requestLockModule(bytes32 _key) external;

    function cancelLockModule(bytes32 _key) external;

    function lockModule(bytes32 _key) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

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