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

    function ownerSubmittingPeriod() public virtual pure returns (uint256) {
        return 1 days;
    }

    function rewardWithdrawalPeriod() public virtual pure returns (uint256) {
        return 6 days;
    }

    function roundPeriod() public virtual pure returns (uint256) {
        return 1 weeks;
    }

    function getBlockNumber() internal virtual view returns (uint256) {
        return block.number;
    }

    function getTimestamp() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    function getBlockhash(uint256 blockNumber) internal virtual view returns (bytes32) {
        return blockhash(blockNumber);
    }

    struct ActiveEntryListElement {
        Entry entry;
        LinkedNode linkedNode;
    }

    struct Entry {
        bool active;
        uint256 amount;
        uint256 from;
        uint256 pointer;
        uint256 to;
        address account;
    }

    struct RoundParticipant {
        bool active;
        bool rewardPaid;
        bool winner;
        uint256 entriesCount;
        uint256 reward;
    }

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

    struct Round {
        RoundProps props;
        RoundCalculation calculation;
        LinkedList activeEntries;
        Entry[] entries;
        mapping(address => RoundParticipant) participants;
    }

    uint256 private _totalStaked;
    IERC20 private _stakingToken;
    IERC20 private _jackpotToken;
    uint256[5] private rewardsDivider = [2, 4, 8, 16, 16];
    Round[] private rounds;

    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    function stakingToken() public view returns (IERC20) {
        return _stakingToken;
    }

    function jackpotToken() public view returns (IERC20) {
        return _jackpotToken;
    }

    function roundsCount() public view returns (uint256) {
        return rounds.length;
    }

    function roundEntries(uint256 roundIndex) public view returns (Entry[] memory) {
        return _getRound(roundIndex).entries;
    }

    function round(uint256 roundIndex) public view returns (RoundProps memory) {
        return _getRound(roundIndex).props;
    }

    function roundCalculation(uint256 roundIndex) public view returns (RoundCalculation memory) {
        return _getRound(roundIndex).calculation;
    }

    function roundParticipant(uint256 roundIndex, address account) public view returns (RoundParticipant memory) {
        Round storage round_ = _getRound(roundIndex);
        return round_.participants[account];
    }

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
            require(
                iterableEntries.length.add(iterableEntriesOffset) > round_.calculation.iteratedEntriesCount,
                "Nothing to calculate"
            );
        }
        _calculateResults(round_, iterableEntries, iterableEntriesOffset, limit);
        return true;
    }

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

    function reuseNonWithdrawnRewards(uint256 fromRoundIndex, uint256 inRoundIndex) public returns (bool success) {
        _updateRound();
        uint256 timestamp = getTimestamp();
        RoundProps storage fromRoundProps = _getRound(fromRoundIndex).props;
        require(fromRoundProps.closed, "From round not closed");
        if (fromRoundProps.participants.length > 0) {
            uint256 applicableAt = fromRoundProps.closedAt.add(rewardWithdrawalPeriod());
            require(timestamp >= applicableAt, "Users can withdraw their rewards");
        }
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

    function withdrawStake(uint256 amount) external onlyOwner onlyPositiveAmount(amount) returns (bool success) {
        _totalStaked = _totalStaked.sub(amount, "Staking pool is extinguished");
        emit StakeWithdrawn(amount);
        _stakingToken.safeTransfer(owner, amount);
        return true;
    }

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

    function _updateRound() internal {
        uint256 lastRoundIndex = rounds.length.sub(1);
        if (rounds[lastRoundIndex].props.endsAt > getTimestamp()) return;
        emit RoundEnded(lastRoundIndex);
        createNewRound();
    }

    function _getRound(uint256 index) private view returns (Round storage) {
        require(index < rounds.length, "Round not found");
        return rounds[index];
    }

    function _calculateResults(
        Round storage round_,
        uint256[] memory iterableEntries,
        uint256 iterableEntriesOffset,
        uint256 limit
    ) private {
        uint256 passedIterationsCount = round_.calculation.passedIterationsCount;
        round_.calculation.passedIterationsCount = passedIterationsCount.add(1);
        if (round_.calculation.gapPointer > 0) {
            _processGap(round_);
            if (limit > 1) _calculateResults(round_, iterableEntries, iterableEntriesOffset, limit - 1);
            return;
        }
        uint256 random = uint256(keccak256(abi.encodePacked(round_.calculation.seed, passedIterationsCount)));
        uint256 iteratedEntriesCount = round_.calculation.iteratedEntriesCount;
        if (iterableEntries.length.add(iterableEntriesOffset) <= iteratedEntriesCount) return;
        random = random.mod(round_.calculation.activeEntriesAmount);
        uint256 potensionalIterableEntryIndex = iterableEntries[iteratedEntriesCount.sub(iterableEntriesOffset)];
        require(potensionalIterableEntryIndex < round_.entries.length, "Invalid iterable entry index");
        Entry storage potensionalIterableEntry = round_.entries[potensionalIterableEntryIndex];
        round_.calculation.iteratedEntriesCount = iteratedEntriesCount.add(1);
        require(potensionalIterableEntry.active, "Expected iterable entry not active");
        require(
            potensionalIterableEntry.from <= random && potensionalIterableEntry.to > random,
            "Invalid expected iterable entry"
        );
        address potensionalWinningAddress = potensionalIterableEntry.account;
        RoundParticipant storage roundParticipant_ = round_.participants[potensionalWinningAddress];
        if (!roundParticipant_.winner) {
            bool shouldBreak = _processWinner(round_, roundParticipant_, potensionalWinningAddress);
            if (shouldBreak) return;
        } else round_.calculation.gapPointer = potensionalIterableEntry.pointer;
        if (limit > 1) _calculateResults(round_, iterableEntries, iterableEntriesOffset, limit - 1);
    }

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
        if (newCalculatedWinnersCount >= 5 || newCalculatedWinnersCount >= round_.props.participants.length) {
            emit RoundClosed(round_.props.index);
            round_.props.closed = true;
            round_.props.closedAt = getTimestamp();
            return true;
        }
        return false;
    }

    function _processGap(Round storage round_) private {
        LinkedList storage list = round_.activeEntries;
        uint256 lastEntryIndex = list.get(list.last);
        Entry storage lastEntry = round_.entries[lastEntryIndex];
        LinkedNode memory gapNode = list.getNode(round_.calculation.gapPointer);
        Entry storage gap = round_.entries[gapNode.value];
        if (list.last == round_.calculation.gapPointer) {
            round_.calculation.activeEntriesAmount = round_.calculation.activeEntriesAmount.sub(lastEntry.amount);
            list.remove(round_.calculation.gapPointer);
            round_.calculation.gapPointer = 0;
            gap.active = false;
            return;
        }
        RoundParticipant storage lastParticipant = round_.participants[lastEntry.account];
        if (lastParticipant.winner) {
            round_.calculation.activeEntriesAmount = round_.calculation.activeEntriesAmount.sub(lastEntry.amount);
            list.remove(list.last);
            lastEntry.active = false;
            return;
        }
        uint256 transferAmount = Math.min(gap.amount, lastEntry.amount);
        round_.calculation.activeEntriesAmount = round_.calculation.activeEntriesAmount.sub(transferAmount);
        if (gapNode.prev > 0) {
            Entry storage prevEntry = round_.entries[list.get(gapNode.prev)];
            if (prevEntry.account == lastEntry.account) {
                return _processTransitionToPrevGap(round_, prevEntry, gap, lastEntry, transferAmount, list);
            }
        }
        if (gapNode.next > 0 && gapNode.next != list.last) {
            Entry storage nextEntry = round_.entries[list.get(gapNode.next)];
            if (nextEntry.account == lastEntry.account) {
                return _processTransitionToNextGap(round_, nextEntry, gap, lastEntry, transferAmount, list);
            }
        }
        uint256 newEntryIndex = round_.entries.length;
        uint256 newEntryFrom = gap.from;
        gap.from = gap.from.add(transferAmount);
        gap.amount = gap.amount.sub(transferAmount);
        lastEntry.amount = lastEntry.amount.sub(transferAmount);
        lastEntry.to = lastEntry.to.sub(transferAmount);
        uint256 pointer = list.insert(gapNode.prev, newEntryIndex);
        round_.entries.push(Entry(true, transferAmount, newEntryFrom, pointer, gap.from, lastEntry.account));
        _finishGapTransfer(round_, gap, lastEntry, list);
    }

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

    function _finishGapTransfer(
        Round storage round_,
        Entry storage gap,
        Entry storage lastEntry,
        LinkedList storage list
    ) private {
        if (gap.amount == 0) {
            gap.active = false;
            list.remove(round_.calculation.gapPointer);
            round_.calculation.gapPointer = 0;
        }
        if (lastEntry.amount == 0) {
            lastEntry.active = false;
            list.remove(list.last);
        }
    }

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
pragma experimental ABIEncoderV2;

import "../LotteryLikePool.sol";

contract MockedLotteryLikePoolTestnet is LotteryLikePool {
    function ownerSubmittingPeriod() public override pure returns (uint256) {
        return 10 minutes;
    }

    function roundPeriod() public override(LotteryLikePool) pure returns (uint256) {
        return 10 minutes;
    }

    function rewardWithdrawalPeriod() public override(LotteryLikePool) pure returns (uint256) {
        return 8 minutes;
    }

    constructor(
        IERC20 stakingToken_,
        IERC20 jackpotToken_,
        uint256 firstRoundEndsAt,
        address owner_
    ) public LotteryLikePool(stakingToken_, jackpotToken_, firstRoundEndsAt, owner_) {}
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