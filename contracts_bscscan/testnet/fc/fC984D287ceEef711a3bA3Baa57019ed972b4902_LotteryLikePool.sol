// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/Math.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

import "./LinkedList.sol";
import "./TwoStageOwnable.sol";

contract LotteryLikePool is TwoStageOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using LinkedListLib for LinkedList;

    /// @notice Returns the time (in seconds) the owner has to verify the random seed
    function ownerSubmittingPeriod() public virtual pure returns (uint256) {
        return 1 days;
    }

    /// @notice Returns the time (in seconds) that the participants have to withdraw their rewards after round is closed
    function rewardWithdrawalPeriod() public virtual pure returns (uint256) {
        return 6 days;
    }

    /// @notice Returns duration of one round (in seconds)
    function roundPeriod() public virtual pure returns (uint256) {
        return 1 weeks;
    }

    /// @return Block number in which transaction applies
    /// @dev Method is virtual to override it for tests
    function getBlockNumber() internal virtual view returns (uint256) {
        return block.number;
    }

    /// @return Timestamp of block in which transaction applies
    /// @dev Method is virtual to override it for tests
    function getTimestamp() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    /// @return Hash of specific block
    /// @dev Method is virtual to override it for tests
    function getBlockhash(uint256 blockNumber) internal virtual view returns (bytes32) {
        return blockhash(blockNumber);
    }

    struct ActiveEntryListElement {
        Entry entry;
        LinkedNode linkedNode;
    }

    /// @dev Represents entry (or entries) for a single round
    /// @param active True if entry is active and false otherwise.
    ///     All new entries are active. But entry can be deactivated during result calculation process
    /// @param amount Amount of entries. Equals to paid amount / 1e18
    /// @param from Sum of all previous active entries amounts
    /// @param pointer Pointer in active entries list
    /// @param to The same as `from` but with added amount
    /// @param account Address of entries owner
    struct Entry {
        bool active;
        uint256 amount;
        uint256 from;
        uint256 pointer;
        uint256 to;
        address account;
    }

    /// @dev Represents single participant of a single round
    /// @param active True if account is participant of round
    /// @param rewardPaid True if participant reward paid and false if they are not paid or participant has no rewards
    /// @param winner True if participant is winner
    /// @param entriesCount Sum of participant entries amounts
    /// @param reward Reward amount of participant
    struct RoundParticipant {
        bool active;
        bool rewardPaid;
        bool winner;
        uint256 entriesCount;
        uint256 reward;
    }

    /// @dev Represents common information of round
    /// @param closed True if round is closed and winners are defined
    /// @param closedAt Timestamp (in seconds) of round closing. Equals to `0` if round not closed
    /// @param endsAt Timestamp (in seconds) of round ending. When round ended buying entries for it not possible
    /// @param index Round index
    /// @param nonWithdrawnRewards Sum of rewards that has not been withdrawn.
    ///     Increases on every `increasePool` method call and reduced by method `withdrawRewards`.
    ///     When non withdrawn rewards are reused in other round `nonWithdrawnRewards` will be equals to 0
    ///     (reusing rewards are the same as withdrawing them and increasing pool of another round)
    /// @param totalEntries Sum of entries amounts
    /// @param totalReward Amount of rewards pool. Increases on every `increasePool` call. Never reduced
    /// @param participants Array of participants addresses
    /// @param winners Array of winners addresses
    struct RoundProps {
        bool closed;
        uint256 closedAt;
        uint256 endsAt;
        uint256 index;
        uint256 nonWithdrawnRewards;
        uint256 totalEntries;
        uint256 totalReward;
        address[] participants;
        address[] winners;
    }

    /// @dev Represents technical information about round results calculation process
    /// @param sealedSeedProvided True if sealed seed provided (see method `provideSealedSeed`)
    /// @param activeEntriesAmount Sum of active entries amounts. Reduces by gaps resolving
    /// @param gapPointer Pointer of entry that should be removed from active entries list
    /// @param iteratedEntriesCount Count of iterated entries
    /// @param passedIterationsCount Count of passed iterations
    /// @param seedRevealingBlockNumber Block number after which sealed seed can be revealed.
    ///     Hash of block with this number will be used to generate random seed.
    ///     Sealed seed can not be revealed after `seedRevealingBlockNumber` + 256
    /// @param sealedSeed Sealed seed - hash of original seed
    /// @param seed Seed of round that used to calculate results
    struct RoundCalculation {
        bool sealedSeedProvided;
        uint256 activeEntriesAmount;
        uint256 gapPointer;
        uint256 iteratedEntriesCount;
        uint256 passedIterationsCount;
        uint256 seedRevealingBlockNumber;
        bytes32 sealedSeed;
        bytes32 seed;
    }

    /// @dev Represents full round information
    /// @param props Common properties of round (see `RoundProps` struct for details)
    /// @param calculation Technical information about round results calculation process
    ///     (see `RoundCalculation` struct for details)
    /// @param activeEntries List of active entries. Used in calculation.
    ///     Not moved to `RoundCalculation` structure since linked list has mapping in it
    /// @param entries Array of all entries
    /// @param participants Map of participants. Key is participant address. Value is `RoundParticipant` structure
    struct Round {
        RoundProps props;
        RoundCalculation calculation;
        LinkedList activeEntries;
        Entry[] entries;
        mapping(address => RoundParticipant) participants;
    }

    /// @dev Total amount of tokens that have been spent buying entries but not withdrawn by owner
    uint256 private _totalStaked;

    /// @dev ERC20 staking token address. Used for buying entries
    IERC20 private _stakingToken;

    /// @dev ERC20 jackpot token address. Used for paying rewards
    IERC20 private _jackpotToken;

    /// @dev Rewards dividers for first 5 winners.
    ///     Reward can be calculated using `totalReward/rewardsDivider[winnerIndex]`
    uint256[5] private rewardsDivider = [2, 4, 8, 16, 16];

    /// @dev Array of all rounds. See `Round` structure for details
    Round[] private rounds;

    /// @notice Returns total amount of tokens that have been spent buying entries but not withdrawn by owner
    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    /// @notice Returns address of staking token (this is the one that used for buying entries)
    function stakingToken() public view returns (IERC20) {
        return _stakingToken;
    }

    /// @notice Returns address of jackpot token (this is the one that used for paying rewards)
    function jackpotToken() public view returns (IERC20) {
        return _jackpotToken;
    }

    /// @notice Returns count of already created rounds
    function roundsCount() public view returns (uint256) {
        return rounds.length;
    }

    /// @notice Returns all entries of specific round
    /// @param roundIndex Round index for which entries list should be returned
    function roundEntries(uint256 roundIndex) public view returns (Entry[] memory) {
        return _getRound(roundIndex).entries;
    }

    /// @notice Returns common round information. See struct `RoundProps` for details
    /// @param roundIndex Round index for which information should be returned
    function round(uint256 roundIndex) public view returns (RoundProps memory) {
        return _getRound(roundIndex).props;
    }

    /// @notice Returns information about round calculations. See struct `RoundCalculation` for details
    /// @param roundIndex Round index for which information should be returned
    function roundCalculation(uint256 roundIndex) public view returns (RoundCalculation memory) {
        return _getRound(roundIndex).calculation;
    }

    /// @notice Returns round participant inforation. See struct `RoundParticipant` for details
    /// @param roundIndex Round index for which inforation should be returned
    /// @param account Address of participant for which inforation should be returned
    function roundParticipant(uint256 roundIndex, address account) public view returns (RoundParticipant memory) {
        Round storage round_ = _getRound(roundIndex);
        return round_.participants[account];
    }

    /// @dev Returns list of currently active entries. May changes when calculation in process
    /// @return head Pointer of first active entry
    /// @return last Pointer of last active entry
    /// @return lastAllocation Pointer of last created entry
    /// @return length Count of active entries
    /// @return result Array of active entries and its list's element property
    function activeEntriesList(uint256 roundIndex)
        public
        view
        returns (
            uint256 head,
            uint256 last,
            uint256 lastAllocation,
            uint256 length,
            ActiveEntryListElement[] memory result
        )
    {
        Round storage round_ = _getRound(roundIndex);
        LinkedList storage list = round_.activeEntries;
        head = list.head;
        last = list.last;
        lastAllocation = list.it;
        length = list.length;
        result = new ActiveEntryListElement[](length);
        uint256 it = list.head;
        for (uint256 index = 0; index < length; index += 1) {
            LinkedNode memory node = list.getNode(it);
            result[index] = ActiveEntryListElement({entry: round_.entries[node.value], linkedNode: node});
            it = node.next;
        }
    }

    event EntriesPurchased(
        uint256 indexed roundIndex,
        address indexed purchaser,
        uint256 indexed entryIndex,
        uint256 amount
    );
    event JackpotIncreased(uint256 indexed roundIndex, address indexed payer, uint256 amount);
    event NonWithdrawnRewardsReused(uint256 indexed fromRoundIndex, uint256 indexed inRoundIndex);
    event MissingSeedProvided(uint256 indexed roundIndex, bytes32 seed);
    event NewRoundCreated(uint256 indexed index, uint256 endsAt);
    event SealedSeedProvided(uint256 indexed roundIndex, bytes32 sealedSeed, uint256 revealingBlockNumber);
    event SeedRevealed(uint256 indexed roundIndex, bytes32 revealedSeed, bytes32 savedSeed);
    event StakeWithdrawn(uint256 amount);
    event RewardWithdrawn(uint256 indexed roundIndex, address indexed winner, uint256 amount);
    event RoundClosed(uint256 indexed index);
    event RoundEnded(uint256 indexed index);
    event WinnerDefined(uint256 indexed roundIndex, address indexed account, uint256 rewardAmount);

    /// @param stakingToken_ ERC20 token that will be used to buy entries
    /// @param jackpotToken_ ERC20 token that will be used as rewards of rounds
    /// @param firstRoundEndsAt Timestamp (in seconds) when first created round will ends
    /// @param owner_ Address of owner
    constructor(
        IERC20 stakingToken_,
        IERC20 jackpotToken_,
        uint256 firstRoundEndsAt,
        address owner_
    ) public TwoStageOwnable(owner_) {
        _stakingToken = stakingToken_;
        _jackpotToken = jackpotToken_;
        rounds.push();
        rounds[0].props.endsAt = firstRoundEndsAt;
    }

    /// @notice Calculates specific round results
    /// @param roundIndex Index of round
    /// @param iterableEntries Array of entries indexes that expected to be iterated
    /// @param iterableEntriesOffset Count of skipped iterable entries. Needed to solve race conditions
    /// @param limit Max count of iterations that should be passed in transaction
    function calculateRoundResults(
        uint256 roundIndex,
        uint256[] memory iterableEntries,
        uint256 iterableEntriesOffset,
        uint256 limit
    ) external returns (bool success) {
        require(limit > 0, "Limit not positive");
        Round storage round_ = _getRound(roundIndex);
        require(round_.calculation.seed != bytes32(0), "Seed not revealed");
        require(!round_.props.closed, "Result already has been calculated");
        require(iterableEntriesOffset <= round_.calculation.iteratedEntriesCount, "Gap in iterable entries list");
        if (round_.calculation.gapPointer == 0) {
            // if there is first calculation call
            // or if there is no resolved gap in last iteration of previous calculation
            // then next iterable entries should be provided
            require(
                iterableEntries.length.add(iterableEntriesOffset) > round_.calculation.iteratedEntriesCount,
                "Nothing to calculate"
            );
        }
        _calculateResults(round_, iterableEntries, iterableEntriesOffset, limit);
        return true;
    }

    /// @notice Creates new round
    function createNewRound() public returns (bool success) {
        uint256 timestamp = getTimestamp();
        uint256 roundsCount_ = rounds.length;
        rounds.push();
        Round storage newRound = rounds[roundsCount_];
        Round storage previousRound = rounds[roundsCount_.sub(1)];
        uint256 newRoundEndsAt;
        uint256 roundPeriod_ = roundPeriod();
        if (previousRound.props.endsAt >= timestamp) newRoundEndsAt = previousRound.props.endsAt.add(roundPeriod_);
        else {
            uint256 passedWeeksCount = timestamp.sub(previousRound.props.endsAt).div(roundPeriod_);
            newRoundEndsAt = previousRound.props.endsAt.add(passedWeeksCount.add(1).mul(roundPeriod_));
        }
        newRound.props.endsAt = newRoundEndsAt;
        emit NewRoundCreated(roundsCount_, newRoundEndsAt);
        newRound.props.index = roundsCount_;
        return true;
    }

    /// @notice Method to buy entries. Should approve `amount` * 1e18 of staking token for using by this contract
    /// @param roundIndex Index of round to participate in. Round should not be ended
    /// @param amount Amount of entries to buy
    function buyEntries(uint256 roundIndex, uint256 amount) external onlyPositiveAmount(amount) returns (bool success) {
        _updateRound();
        address participant = msg.sender;
        Round storage round_ = _getRound(roundIndex);
        require(round_.props.endsAt > getTimestamp(), "Round already ended");
        uint256 newTotalAmount = round_.calculation.activeEntriesAmount.add(amount);
        Entry[] storage entries = round_.entries;
        uint256 newEntryIndex = entries.length;
        LinkedList storage roundActiveEntries = round_.activeEntries;
        uint256 pointer = roundActiveEntries.insert(roundActiveEntries.last, newEntryIndex);
        entries.push(
            Entry({
                active: true,
                amount: amount,
                from: round_.calculation.activeEntriesAmount,
                pointer: pointer,
                to: newTotalAmount,
                account: participant
            })
        );
        round_.calculation.activeEntriesAmount = newTotalAmount;
        round_.props.totalEntries = newTotalAmount;
        RoundParticipant storage roundParticipant_ = round_.participants[participant];
        roundParticipant_.entriesCount = roundParticipant_.entriesCount.add(amount);
        if (!roundParticipant_.active) {
            roundParticipant_.active = true;
            round_.props.participants.push(participant);
        }
        uint256 stakeAmount = amount.mul(10**18);
        _totalStaked = _totalStaked.add(stakeAmount);
        emit EntriesPurchased(roundIndex, participant, newEntryIndex, amount);
        _stakingToken.safeTransferFrom(participant, address(this), stakeAmount);
        return true;
    }

    /// @notice Increases round jackpot. Should approve `amount` of jackpot token for using by this contract
    /// @param roundIndex Index of round in which jackpot should be increased. Round should not be ended
    /// @param amount Amount of increasing
    function increaseJackpot(uint256 roundIndex, uint256 amount)
        public
        onlyPositiveAmount(amount)
        returns (bool success)
    {
        _updateRound();
        Round storage round_ = _getRound(roundIndex);
        require(round_.props.endsAt > getTimestamp(), "Round already ended");
        round_.props.totalReward = round_.props.totalReward.add(amount);
        round_.props.nonWithdrawnRewards = round_.props.nonWithdrawnRewards.add(amount);
        emit JackpotIncreased(roundIndex, msg.sender, amount);
        _jackpotToken.safeTransferFrom(msg.sender, address(this), amount);
        return true;
    }

    /// @notice Provides missing seed. Method added to fill case, when owner not provides seed by himself.
    ///     Conditions of successful providing:
    ///      * Seed should not been provided before it;
    ///      * If sealed seed provided by owner then more than 256 blocks should be produced after that;
    ///      * If sealed seed not provided owner submitting period should be ended.
    ///     Sets round seed to hash of previous block. Not the most honest implementation.
    ///     But since this is only a fuse in case the owner does not do his job, that's okay.
    /// @param roundIndex Round index for which missing seed provided
    function provideMissingSeed(uint256 roundIndex) public returns (bool success) {
        Round storage round_ = _getRound(roundIndex);
        uint256 blockNumber = getBlockNumber();
        require(round_.calculation.seed == bytes32(0), "Seed already provided");
        uint256 endsAt = round_.props.endsAt;
        if (round_.calculation.sealedSeedProvided) {
            bool revealingPhase = blockNumber > round_.calculation.seedRevealingBlockNumber;
            bool blockHashable = getBlockhash(round_.calculation.seedRevealingBlockNumber) != bytes32(0);
            require(revealingPhase && !blockHashable, "Less than 256 blocks passed from providing sealed seed");
        } else require(endsAt.add(ownerSubmittingPeriod()) < getTimestamp(), "Owner submitting period not passed");
        round_.calculation.sealedSeedProvided = true;
        bytes32 seed = getBlockhash(blockNumber.sub(1));
        round_.calculation.seed = seed;
        emit MissingSeedProvided(roundIndex, seed);
        return true;
    }

    /// @notice Provides sealed seed for random. Applicable only by contract owner
    /// @param roundIndex Round index for which sealed seed provided
    /// @param sealedSeed Keccak-256 hash of original seed. Original seed should be a random 32 bytes.
    ///     Original seed also should be remembered to provide it in `revealSealedSeed` method
    function provideSealedSeed(uint256 roundIndex, bytes32 sealedSeed) public onlyOwner returns (bool success) {
        Round storage round_ = _getRound(roundIndex);
        require(!round_.calculation.sealedSeedProvided, "Sealed seed already provided");
        require(round_.props.endsAt <= getTimestamp(), "Round not ended");
        round_.calculation.sealedSeedProvided = true;
        round_.calculation.sealedSeed = sealedSeed;
        uint256 revealingBlockNumber = getBlockNumber() + 1;
        round_.calculation.seedRevealingBlockNumber = revealingBlockNumber;
        emit SealedSeedProvided(roundIndex, sealedSeed, revealingBlockNumber);
        return true;
    }

    /// @notice Will reuse non withdrawn rewards as jackpot of the current one.
    ///     "From" round should be closed and reward withdrawal period should be passed.
    ///     Also appicable when round ended but there is no participants in it
    /// @param fromRoundIndex Round from which unwithdrawn rewards should be removed
    /// @param inRoundIndex Current round index
    function reuseNonWithdrawnRewards(uint256 fromRoundIndex, uint256 inRoundIndex) public returns (bool success) {
        _updateRound();
        uint256 timestamp = getTimestamp();
        RoundProps storage fromRoundProps = _getRound(fromRoundIndex).props;
        if (fromRoundProps.participants.length > 0) {
            require(fromRoundProps.closed, "From round not closed");
            uint256 applicableAt = fromRoundProps.closedAt.add(rewardWithdrawalPeriod());
            require(timestamp >= applicableAt, "Users can withdraw their rewards");
        } else require(timestamp >= fromRoundProps.endsAt, "Round not ended");
        uint256 reusedAmount = fromRoundProps.nonWithdrawnRewards;
        require(reusedAmount > 0, "Nothing to reuse");
        RoundProps storage inRoundProps = _getRound(inRoundIndex).props;
        require(timestamp < inRoundProps.endsAt, "In round already ended");
        require(timestamp >= _getRound(inRoundIndex.sub(1)).props.endsAt, "Able to reuse only for current round");
        fromRoundProps.nonWithdrawnRewards = 0;
        inRoundProps.totalReward = inRoundProps.totalReward.add(reusedAmount);
        inRoundProps.nonWithdrawnRewards = inRoundProps.nonWithdrawnRewards.add(reusedAmount);
        emit NonWithdrawnRewardsReused(fromRoundIndex, inRoundIndex);
        return true;
    }

    /// @notice Method to reveal sealed seed. Applicable only by contract owner.
    ///     Before revealing sealed seed it should be provided via `provideSealedSeed` method.
    ///     Applicable only next to 2 blocks after sealed seed has been provided but before next 256 blocks
    /// @param roundIndex Round index for which sealed seed should be revealed
    /// @param seed Original seed. See NatSpec for `provideSealedSeed` method
    function revealSealedSeed(uint256 roundIndex, bytes32 seed) public onlyOwner returns (bool success) {
        Round storage round_ = _getRound(roundIndex);
        require(round_.calculation.seed == bytes32(0), "Seed already revealed");
        require(round_.calculation.sealedSeedProvided, "Sealed seed not provided");
        uint256 seedRevealingBlockNumber = round_.calculation.seedRevealingBlockNumber;
        require(getBlockNumber() > seedRevealingBlockNumber, "Unable to reveal sealed seed on the same block");
        bytes32 revealingBlockHash = getBlockhash(seedRevealingBlockNumber);
        require(revealingBlockHash != bytes32(0), "More than 256 blocks passed from providing sealed seed");
        require(keccak256(abi.encodePacked(msg.sender, seed)) == round_.calculation.sealedSeed, "Invalid seed");
        bytes32 newSeed = keccak256(abi.encodePacked(revealingBlockHash, seed));
        round_.calculation.seed = newSeed;
        emit SeedRevealed(roundIndex, seed, newSeed);
        return true;
    }

    /// @notice Withdraws tokens, that have been spent buying entries. Applicable only by contract owner
    /// @param amount Amount of tokens to withdraw
    function withdrawStake(uint256 amount) external onlyOwner onlyPositiveAmount(amount) returns (bool success) {
        _totalStaked = _totalStaked.sub(amount, "Staking pool is extinguished");
        emit StakeWithdrawn(amount);
        _stakingToken.safeTransfer(owner, amount);
        return true;
    }

    /// @notice Withdraws rewards of specific round
    /// @param roundIndex Round index from which rewards should be withdrawn
    function withdrawRewards(uint256 roundIndex) external returns (bool success) {
        address caller = msg.sender;
        Round storage round_ = _getRound(roundIndex);
        RoundParticipant storage participant = round_.participants[caller];
        require(participant.winner, "Not a round winner");
        require(!participant.rewardPaid, "Round reward already paid");
        uint256 amount = participant.reward;
        require(amount > 0, "Reward amount is equal to zero");
        require(round_.props.nonWithdrawnRewards >= amount, "Reward reused as next jackpot");
        participant.rewardPaid = true;
        round_.props.nonWithdrawnRewards = round_.props.nonWithdrawnRewards.sub(amount);
        emit RewardWithdrawn(roundIndex, caller, amount);
        _jackpotToken.safeTransfer(caller, amount);
        return true;
    }

    /// @dev Creates new round if the last one is ended. Also emits `RoundEnded` event in this case
    function _updateRound() internal {
        uint256 lastRoundIndex = rounds.length.sub(1);
        if (rounds[lastRoundIndex].props.endsAt > getTimestamp()) return;
        emit RoundEnded(lastRoundIndex);
        createNewRound();
    }

    /// @dev Returns round by its index. Result is storage type so it can be modified to modify state.
    ///     Reverts an error when index greater than or equals to round count
    function _getRound(uint256 index) private view returns (Round storage) {
        require(index < rounds.length, "Round not found");
        return rounds[index];
    }

    /// @dev Calculates results of round
    /// @param round_ Storage type of round to calculate
    /// @param iterableEntries Array of entries indexes that expected to be iterated
    /// @param iterableEntriesOffset Number of entries that was skipped in `iterableEntries` array.
    ///     Needed to solve race conditions
    /// @param limit Max count of iteration to calculate
    function _calculateResults(
        Round storage round_,
        uint256[] memory iterableEntries,
        uint256 iterableEntriesOffset,
        uint256 limit
    ) private {
        uint256 passedIterationsCount = round_.calculation.passedIterationsCount;
        round_.calculation.passedIterationsCount = passedIterationsCount.add(1);
        // If previous iteration found entry to be removed
        //      or if it not resolves removing previously found removable entry
        if (round_.calculation.gapPointer > 0) {
            // process entry removing
            _processGap(round_);
            // and start new iteration if limit not reached
            if (limit > 1) _calculateResults(round_, iterableEntries, iterableEntriesOffset, limit - 1);
            return;
        }
        // Generate iteration seed by hashing round seed and iteration index
        uint256 random = uint256(keccak256(abi.encodePacked(round_.calculation.seed, passedIterationsCount)));
        uint256 iteratedEntriesCount = round_.calculation.iteratedEntriesCount;
        // If there is not enough indexes in `iterableEntries` list just finish calculation
        if (iterableEntries.length.add(iterableEntriesOffset) <= iteratedEntriesCount) return;
        // Get random number from 0 inclusive to total round entries exclusive
        random = random.mod(round_.calculation.activeEntriesAmount);
        // Get expected iterable entry
        uint256 potensionalIterableEntryIndex = iterableEntries[iteratedEntriesCount.sub(iterableEntriesOffset)];
        require(potensionalIterableEntryIndex < round_.entries.length, "Invalid iterable entry index");
        Entry storage potensionalIterableEntry = round_.entries[potensionalIterableEntryIndex];
        round_.calculation.iteratedEntriesCount = iteratedEntriesCount.add(1);
        // Expected iterable entry should be active (not removed from active list)
        require(potensionalIterableEntry.active, "Expected iterable entry not active");
        // Check that iterated entry is correct
        require(
            potensionalIterableEntry.from <= random && potensionalIterableEntry.to > random,
            "Invalid expected iterable entry"
        );
        address potensionalWinningAddress = potensionalIterableEntry.account;
        RoundParticipant storage roundParticipant_ = round_.participants[potensionalWinningAddress];
        // If entry owner not a winner
        if (!roundParticipant_.winner) {
            // make it winner
            bool shouldBreak = _processWinner(round_, roundParticipant_, potensionalWinningAddress);
            // and if he is the last winner (5th or no more non winners) just stop calculation
            if (shouldBreak) return;
        } else {
            // otherwise, if he is already winner mark his entry to remove
            round_.calculation.gapPointer = potensionalIterableEntry.pointer;
        }
        // If limit not reached start new iteration
        if (limit > 1) _calculateResults(round_, iterableEntries, iterableEntriesOffset, limit - 1);
    }

    /// @dev Process winner
    /// @param round_ Round in which winner is defined
    /// @param roundParticipant_ Round participant defined as a winner properties
    /// @param potensionalWinningAddress Address of participant
    /// @return shouldBreak True if this is the last round winner
    function _processWinner(
        Round storage round_,
        RoundParticipant storage roundParticipant_,
        address potensionalWinningAddress
    ) private returns (bool shouldBreak) {
        uint256 reward = round_.props.totalReward.div(rewardsDivider[round_.props.winners.length]);
        roundParticipant_.reward = reward;
        roundParticipant_.winner = true;
        round_.props.winners.push(potensionalWinningAddress);
        uint256 newCalculatedWinnersCount = round_.props.winners.length;
        emit WinnerDefined(round_.props.index, potensionalWinningAddress, reward);
        // If this is the last round winner (5th winner or no more non winners)
        if (newCalculatedWinnersCount >= 5 || newCalculatedWinnersCount >= round_.props.participants.length) {
            // close round
            emit RoundClosed(round_.props.index);
            round_.props.closed = true;
            round_.props.closedAt = getTimestamp();
            // and stop results calculations
            return true;
        }
        // else continue results calculation
        return false;
    }

    /// @dev Method to iterate entry removing
    /// @param round_ Round in which some entry should be removed
    function _processGap(Round storage round_) private {
        LinkedList storage list = round_.activeEntries;
        uint256 lastEntryIndex = list.get(list.last);
        Entry storage lastEntry = round_.entries[lastEntryIndex];
        LinkedNode memory gapNode = list.getNode(round_.calculation.gapPointer);
        Entry storage gap = round_.entries[gapNode.value];
        // If entry to remove is the last in active entries list
        if (list.last == round_.calculation.gapPointer) {
            // then just remove it
            round_.calculation.activeEntriesAmount = round_.calculation.activeEntriesAmount.sub(lastEntry.amount);
            list.remove(round_.calculation.gapPointer);
            round_.calculation.gapPointer = 0;
            gap.active = false;
            return;
        }
        RoundParticipant storage lastParticipant = round_.participants[lastEntry.account];
        // If owner of last entry in active entries list is a winner
        if (lastParticipant.winner) {
            // Just remove the last entry and continue processing removing
            round_.calculation.activeEntriesAmount = round_.calculation.activeEntriesAmount.sub(lastEntry.amount);
            list.remove(list.last);
            lastEntry.active = false;
            return;
        }
        // Otherwise we need to move last entry instead of removable entry
        // To do this moved entry amount should be calculated first
        //      that is minimal amount between removable entry amount and last entry remove
        uint256 transferAmount = Math.min(gap.amount, lastEntry.amount);
        round_.calculation.activeEntriesAmount = round_.calculation.activeEntriesAmount.sub(transferAmount);
        if (gapNode.prev > 0) {
            Entry storage prevEntry = round_.entries[list.get(gapNode.prev)];
            if (prevEntry.account == lastEntry.account) {
                // If owner of entry before removable one is the same as owner of last entry
                //      then just move amount from last entry to entry before removable one
                return _processTransitionToPrevGap(round_, prevEntry, gap, lastEntry, transferAmount, list);
            }
        }
        if (gapNode.next > 0 && gapNode.next != list.last) {
            Entry storage nextEntry = round_.entries[list.get(gapNode.next)];
            if (nextEntry.account == lastEntry.account) {
                // If owner of entry after removable one is the same as owner of last entry
                //      then just move amount from last entry to entry after removable one
                return _processTransitionToNextGap(round_, nextEntry, gap, lastEntry, transferAmount, list);
            }
        }
        // If neighboring entries has different owner
        //      just create new entry with this owner before the removable one and reduce removable entry amount
        uint256 newEntryIndex = round_.entries.length;
        uint256 newEntryFrom = gap.from;
        gap.from = gap.from.add(transferAmount);
        gap.amount = gap.amount.sub(transferAmount);
        lastEntry.amount = lastEntry.amount.sub(transferAmount);
        lastEntry.to = lastEntry.to.sub(transferAmount);
        uint256 pointer = list.insert(gapNode.prev, newEntryIndex);
        round_.entries.push(Entry(true, transferAmount, newEntryFrom, pointer, gap.from, lastEntry.account));
        // and remove last and removable entry if its amount is zero
        _finishGapTransfer(round_, gap, lastEntry, list);
    }

    /// @dev Moves entries amount from last entry to the first before removable one
    /// @param round_ Round in which this transition applies
    /// @param prevEntry First entry before removable one
    /// @param gap Removable entry
    /// @param lastEntry Last active entry
    /// @param transferAmount Amount that should be moved
    /// @param list List of active entries
    function _processTransitionToPrevGap(
        Round storage round_,
        Entry storage prevEntry,
        Entry storage gap,
        Entry storage lastEntry,
        uint256 transferAmount,
        LinkedList storage list
    ) private {
        prevEntry.amount = prevEntry.amount.add(transferAmount);
        prevEntry.to = prevEntry.to.add(transferAmount);
        gap.from = prevEntry.to;
        gap.amount = gap.amount.sub(transferAmount);
        lastEntry.to = lastEntry.to.sub(transferAmount);
        lastEntry.amount = lastEntry.amount.sub(transferAmount);
        _finishGapTransfer(round_, gap, lastEntry, list);
    }

    /// @dev Moves entries amount from last entry to the first after removable one
    /// @param round_ Round in which this transition applies
    /// @param nextEntry First entry after removable one
    /// @param gap Removable entry
    /// @param lastEntry Last active entry
    /// @param transferAmount Amount that should be moved
    /// @param list List of active entries
    function _processTransitionToNextGap(
        Round storage round_,
        Entry storage nextEntry,
        Entry storage gap,
        Entry storage lastEntry,
        uint256 transferAmount,
        LinkedList storage list
    ) private {
        nextEntry.amount = nextEntry.amount.add(transferAmount);
        nextEntry.from = nextEntry.from.sub(transferAmount);
        gap.to = nextEntry.from;
        gap.amount = gap.amount.sub(transferAmount);
        lastEntry.to = lastEntry.to.sub(transferAmount);
        lastEntry.amount = lastEntry.amount.sub(transferAmount);
        _finishGapTransfer(round_, gap, lastEntry, list);
    }

    /// @dev Finish iteration of removing entry
    /// @param round_ Round for which iteration was applied
    /// @param gap Removable entry
    /// @param lastEntry Last active entry
    /// @param list List of active entries
    function _finishGapTransfer(
        Round storage round_,
        Entry storage gap,
        Entry storage lastEntry,
        LinkedList storage list
    ) private {
        // If removable entry amount is zero (when its amount fully compensated by creation/transition amounts)
        if (gap.amount == 0) {
            // just remove removable entry
            gap.active = false;
            list.remove(round_.calculation.gapPointer);
            // and stop calculation removing
            round_.calculation.gapPointer = 0;
        }
        // If last entry is empty (fully moved instead of removable one)
        if (lastEntry.amount == 0) {
            // remove it
            lastEntry.active = false;
            list.remove(list.last);
        }
    }

    /// @dev Allows only positive amount (`> 0`)
    /// @param amount Amount to check
    modifier onlyPositiveAmount(uint256 amount) {
        require(amount > 0, "Amount is not positive");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract TwoStageOwnable {
    address public nominatedOwner;
    address public owner;

    event OwnerChanged(address indexed newOwner);
    event OwnerNominated(address indexed nominatedOwner);

    constructor(address owner_) internal {
        require(owner_ != address(0), "Owner cannot be zero address");
        _setOwner(owner_);
    }

    function acceptOwnership() external returns (bool success) {
        require(msg.sender == nominatedOwner, "Not nominated to ownership");
        _setOwner(nominatedOwner);
        nominatedOwner = address(0);
        return true;
    }

    function nominateNewOwner(address owner_) external onlyOwner returns (bool success) {
        _nominateNewOwner(owner_);
        return true;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function _nominateNewOwner(address owner_) internal {
        nominatedOwner = owner_;
        emit OwnerNominated(owner_);
    }

    function _setOwner(address newOwner) internal {
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

struct LinkedNode {
    bool inited;
    uint256 value;
    uint256 prev;
    uint256 next;
}

struct LinkedList {
    uint256 head;
    uint256 last;
    mapping(uint256 => LinkedNode) mem;
    uint256 it;
    uint256 length;
}

library LinkedListLib {
    function insert(
        LinkedList storage self,
        uint256 bearingPointer,
        uint256 value
    ) internal returns (uint256 pointer) {
        LinkedNode storage node = self.mem[bearingPointer];
        require(node.inited || bearingPointer == 0, "LinkedList insert: pointer out of scope");
        self.it += 1;
        LinkedNode storage newNode = self.mem[self.it];
        newNode.inited = true;
        newNode.value = value;
        newNode.prev = bearingPointer;
        newNode.next = bearingPointer == 0 ? self.head : node.next;
        node.next = self.it;
        self.mem[newNode.prev].next = self.it;
        self.mem[newNode.next].prev = self.it;
        if (bearingPointer == 0) self.head = self.it;
        if (bearingPointer == self.last) self.last = self.it;
        self.length += 1;
        return self.it;
    }

    function remove(LinkedList storage self, uint256 pointer) internal {
        LinkedNode storage node = self.mem[pointer];
        require(node.inited, "LinkedList remove: pointer out of scope");
        node.inited = false;
        self.mem[node.prev].next = node.next;
        self.mem[node.next].prev = node.prev;
        if (self.head == pointer) self.head = node.next;
        if (self.last == pointer) self.last = node.prev;
        self.length -= 1;
    }

    function get(LinkedList storage self, uint256 pointer) internal view returns (uint256 value) {
        LinkedNode storage node = self.mem[pointer];
        require(node.inited, "LinkedList get: pointer out of scope");
        return node.value;
    }

    function getNode(LinkedList storage self, uint256 pointer) internal view returns (LinkedNode memory) {
        LinkedNode storage node = self.mem[pointer];
        require(node.inited, "LinkedList getNode: pointer out of scope");
        return node;
    }
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
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}