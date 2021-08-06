/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: contracts/BinaryOptions.sol

pragma solidity ^0.8.6;



contract BinaryOptions {

    enum BetDirection {Unknown, Bear, Chop, Bull}
    enum BetDuration {None, OneMinute, FiveMinutes, FifteenMinutes, OneHour, OneDay, OneWeek, OneQuarter}

    struct Bet {
        uint total;
        uint remaining;
        mapping(BetDirection => uint) totals;
        mapping(BetDirection => mapping(address => uint)) balances;
        BetDirection outcome;
        address resolver;
    }
    struct BetSlot {
        address oracle;
        BetDuration duration;
        uint startsAt;
        bool occupied;
    }

    uint public constant BET_SLOTS_PER_BETTOR = 10;
    uint public constant BET_SLOTS_PER_INSTRUMENT = 2;

    uint public resolvingFeeBasispoints;
    string public version;
    mapping(address => uint) public balances;
    mapping(address => mapping(BetDuration => mapping(uint => Bet))) public bets; // oracle => duration => startsAt => Bet
    mapping(address => BetSlot[BET_SLOTS_PER_BETTOR]) betSlotsPerBettor;
    mapping(address => mapping(BetDuration => uint[BET_SLOTS_PER_INSTRUMENT])) public betQueuePerInstrument; // oracle => duration => startsAt[]
    mapping(BetDuration => uint) public durations;

    constructor(uint _resolvingFeeBasispoints, string memory _version) {
        version = _version;
        resolvingFeeBasispoints = _resolvingFeeBasispoints;
        durations[BetDuration.OneMinute] = 1 * 60 * 1000;
        durations[BetDuration.FiveMinutes] = 5 * 60 * 1000;
        durations[BetDuration.FifteenMinutes] = 15 * 60 * 1000;
        durations[BetDuration.OneHour] = 1 * 60 * 60 * 1000;
        durations[BetDuration.OneDay] = 24 * 60 * 60 * 1000;
        durations[BetDuration.OneWeek] = 7 * 24 * 60 * 60 * 1000;
        durations[BetDuration.OneQuarter] = 91 * 24 * 60 * 60 * 1000;
    }

    function resolveAndPlaceBet(uint80 lockedRoundId, uint80 resolvedRoundId, address oracle, BetDuration duration, uint startsAt, BetDirection direction, uint size) external payable {
        resolveIfPossible(oracle, duration, lockedRoundId, resolvedRoundId);
        placeBet(oracle, duration, startsAt, direction, size);
    }

    function resolveIfPossible(address oracle, BetDuration duration, uint80 lockedRoundId, uint80 resolvedRoundId) private {
        tidyUpBetQueuePerInstrument(oracle, duration);
        uint priorStartsAt = betQueuePerInstrument[oracle][duration][0];
        uint priorEndsAt = priorStartsAt + durations[duration];
        if (isResolvableBet(oracle, duration, priorStartsAt) && priorEndsAt < block.timestamp) resolveBet(oracle, duration, priorStartsAt, lockedRoundId, resolvedRoundId);
    }

    function tidyUpBetQueuePerInstrument(address oracle, BetDuration duration) private {
        uint available = 0;
        for (uint i = 0; i < BET_SLOTS_PER_INSTRUMENT; i++) {
            uint startsAt = betQueuePerInstrument[oracle][duration][i];
            if (isResolvableBet(oracle, duration, startsAt)) {
                if (i > available) {
                    betQueuePerInstrument[oracle][duration][available] = startsAt;
                    betQueuePerInstrument[oracle][duration][i] = 0;
                }
                available += 1;
            } else betQueuePerInstrument[oracle][duration][i] = 0;
        }
    }

    function placeBet(address oracle, BetDuration duration, uint startsAt, BetDirection direction, uint size) public payable {
        balances[msg.sender] += msg.value;
        require(duration != BetDuration.None, "Invalid bet duration");
        require(startsAt > block.timestamp, "Betting for this instrument is closed");
        require(startsAt % durations[duration] == 0, "Invalid start time slot");
        // require(startsAt < block.timestamp + durations[duration], "Cannot place a bet outside of duration window bounds");
        require(direction != BetDirection.Unknown, "Invalid bet direction");

        claimResolvedBets();
        require(balances[msg.sender] >= size, "Bet size exceeds available balance");

        uint bettorSlot = getFirstAvailableBetSlotForBettor();
        // require(bettorSlot < BET_SLOTS_PER_BETTOR, "Cannot place a bet; exceeded max allowed unresolved bets per bettor");

        // uint instrumentSlot = getFirstAvailableBetSlotForInstrument(oracle, duration, startsAt);
        // require(instrumentSlot < BET_SLOTS_PER_INSTRUMENT, "Cannot place a bet; exceeded max allowed bets per instrument");
        // balances[msg.sender] -= size;
        // Bet storage bet = bets[oracle][duration][startsAt];
        // bet.total += size;
        // bet.totals[direction] += size;
        // bet.balances[direction][msg.sender] += size;
        // betSlotsPerBettor[msg.sender][bettorSlot] = BetSlot(oracle, duration, startsAt, true);
        // betQueuePerInstrument[oracle][duration][instrumentSlot] = startsAt;
//        if (betQueuePerInstrument[oracle][duration][instrumentSlot] == startsAt) betQueuePerInstrument[oracle][duration][instrumentSlot] = startsAt;
        // emit BetPlaced(msg.sender, oracle, AggregatorV3Interface(oracle).description(), duration, startsAt, direction, size);
    }
    event BetPlaced(address account, address oracle, string symbol, BetDuration duration, uint startsAt, BetDirection kind, uint size);

    function getFirstAvailableBetSlotForBettor() private view returns (uint) {
        for (uint i = 0; i < BET_SLOTS_PER_BETTOR; i++) if (!betSlotsPerBettor[msg.sender][i].occupied) return i;
        return BET_SLOTS_PER_BETTOR;
    }

    function countUnresolvedBetsForBettor() public view returns (uint result) {
        for (uint i = 0; i < BET_SLOTS_PER_BETTOR; i++) if (betSlotsPerBettor[msg.sender][i].occupied) result += 1;
    }

    function getFirstAvailableBetSlotForInstrument(address oracle, BetDuration duration, uint startsAt) public view returns (uint) {
//        uint first = betQueuePerInstrument[oracle][duration][0];
//        uint second = betQueuePerInstrument[oracle][duration][1];
//        return (first == 0 || first == startsAt) ? 0 : (second == 0 || second == startsAt) ? 1 : 2;
        for (uint i = 0; i < BET_SLOTS_PER_INSTRUMENT; i++) if (betQueuePerInstrument[oracle][duration][i] == 0 || betQueuePerInstrument[oracle][duration][i] == startsAt) return i;
        return BET_SLOTS_PER_INSTRUMENT;
    }

    function countUnresolvedBetsForInstrument(address oracle, BetDuration duration) public view returns (uint result) {
        for (uint i = 0; i < BET_SLOTS_PER_INSTRUMENT; i++) if (isResolvableBet(oracle, duration, betQueuePerInstrument[oracle][duration][i])) result += 1;
    }

    function resolveBet(address oracle, BetDuration duration, uint startsAt, uint80 lockedRoundId, uint80 resolvedRoundId) public {
        Bet storage bet = bets[oracle][duration][startsAt];
        uint endsAt = startsAt + durations[duration];
        require(bet.total > 0, "Bet does not exist");
        require(endsAt < block.timestamp, "Too early to resolve bet");

        // resolve outcome
        AggregatorV3Interface priceFeed = AggregatorV3Interface(oracle);
        (,,,uint latestUpdatedAt,) = priceFeed.latestRoundData();
        uint lockedPrice = getValidRoundPrice(priceFeed, startsAt, lockedRoundId, latestUpdatedAt);
        uint resolvedPrice = getValidRoundPrice(priceFeed, endsAt, resolvedRoundId, latestUpdatedAt);
        bet.outcome = (resolvedPrice == lockedPrice) ?
            BetDirection.Chop :
            (resolvedPrice > lockedPrice) ?
                BetDirection.Bull :
                BetDirection.Bear;
        bet.resolver = msg.sender;
        uint fee = (bet.total * resolvingFeeBasispoints) / 10000;
        emit BetResolved(bet.resolver, oracle, duration, startsAt, bet.outcome, bet.total, fee);

        // compensate the resolver
        bet.total -= fee;
        bet.remaining = bet.total;
        payable(bet.resolver).transfer(fee);

        tidyUpBetQueuePerInstrument(oracle, duration);
    }
    event BetResolved(address resolver, address oracle, BetDuration duration, uint startsAt, BetDirection outcome, uint total, uint fee);

    function getValidRoundPrice(AggregatorV3Interface priceFeed, uint boundaryTimestamp, uint80 roundId, uint latestUpdatedAt) private view returns (uint) {
        (,int price,,uint thisRoundUpdatedAt,) = priceFeed.getRoundData(roundId);
        require(thisRoundUpdatedAt <= boundaryTimestamp, "Invalid round id");

        if (thisRoundUpdatedAt == latestUpdatedAt) /* no price change */ return uint(price);

        bool isBoundaryBeforeNextRound = latestUpdatedAt == thisRoundUpdatedAt;
        if (!isBoundaryBeforeNextRound) {
            (,         ,,uint nextRoundUpdatedAt,) = priceFeed.getRoundData(roundId + 1);
            isBoundaryBeforeNextRound = nextRoundUpdatedAt > boundaryTimestamp;
        }
        require(isBoundaryBeforeNextRound, "Invalid round id");
//        require(latestUpdatedAt == thisRoundUpdatedAt || nextRoundStartedAt > boundaryTimestamp, "Invalid round id");
        return uint(price);
    }

    function isResolvableBet(address oracle, BetDuration duration, uint startsAt) public view returns (bool) {
        return startsAt != 0 && !isResolvedBet(oracle, duration, startsAt);
    }

    function isResolvedBet(address oracle, BetDuration duration, uint startsAt) public view returns (bool) {
        return bets[oracle][duration][startsAt].outcome != BetDirection.Unknown;
    }

    function claimResolvedBets() public {
        for (uint i = 0; i < BET_SLOTS_PER_BETTOR; i++) {
            BetSlot storage slot = betSlotsPerBettor[msg.sender][i];
            if (!isResolvedBet(slot.oracle, slot.duration, slot.startsAt) || !slot.occupied) continue;
            claimBet(slot.oracle, slot.duration, slot.startsAt);
            slot.occupied = false;
        }
    }

    function claimBet(address oracle, BetDuration duration, uint startsAt) public {
        require(isResolvedBet(oracle, duration, startsAt), "Cannot claim unresolved bet");
        Bet storage bet = bets[oracle][duration][startsAt];
        uint size = bet.balances[bet.outcome][msg.sender];
        if (size > 0) {
            delete bet.balances[bet.outcome][msg.sender];
            uint winning = size * bet.total / bet.totals[bet.outcome];
            bet.remaining -= winning;
            balances[msg.sender] += winning;
            emit BetClaimed(msg.sender, oracle, duration, startsAt, bet.outcome, winning);
        }
        reclaimBetStorage(oracle, duration, startsAt);
    }
    event BetClaimed(address account, address oracle, BetDuration duration, uint startsAt, BetDirection outcome, uint winning);

    function reclaimBetStorage(address oracle, BetDuration duration, uint startsAt) private {
        for (uint i = uint(BetDirection.Bear); i <= uint(BetDirection.Bull); ++i) delete bets[oracle][duration][startsAt].balances[BetDirection(i)][msg.sender];
        if (bets[oracle][duration][startsAt].remaining == 0) {
            delete bets[oracle][duration][startsAt]; // delete does not cascade to mappings
            for (uint i = uint(BetDirection.Bear); i <= uint(BetDirection.Bull); ++i) delete bets[oracle][duration][startsAt].totals[BetDirection(i)];
        }
    }

    function getBetTotals(address oracle, BetDuration duration, uint startsAt) external view returns (uint total, uint Bear, uint Chop, uint Bull) {
        Bet storage bet = bets[oracle][duration][startsAt];
        total = bet.total;
        Bear = bet.totals[BetDirection.Bear];
        Chop = bet.totals[BetDirection.Chop];
        Bull = bet.totals[BetDirection.Bull];
    }

    function getAvailableBalance() external view returns (uint) {
        uint result = balances[msg.sender];
        for (uint i = 0; i < BET_SLOTS_PER_BETTOR; i++) {
            BetSlot storage slot = betSlotsPerBettor[msg.sender][i];
            if (!isResolvedBet(slot.oracle, slot.duration, slot.startsAt) || !slot.occupied) continue;
            Bet storage bet = bets[slot.oracle][slot.duration][slot.startsAt];
            uint size = bet.balances[bet.outcome][msg.sender];
            uint winning = size * bet.total / bet.totals[bet.outcome];
            result += winning;
        }
        return result;
    }

    function withdraw(uint amount) external {
        claimResolvedBets();
        require(balances[msg.sender] >= amount, 'Insufficient balance');
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}