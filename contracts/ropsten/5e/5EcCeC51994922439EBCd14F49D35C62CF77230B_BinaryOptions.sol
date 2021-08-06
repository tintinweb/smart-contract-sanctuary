/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

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
    using Address for address;

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

    receive() external payable {
        balances[msg.sender] += msg.value;
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
        require(startsAt < block.timestamp + durations[duration], "Can only place a bet within the current duration window");
        require(direction != BetDirection.Unknown, "Invalid bet direction");

        claimResolvedBets();
        require(balances[msg.sender] >= size, "Bet size exceeds available balance");

        uint bettorSlot = getFirstAvailableBetSlotForBettor();
        require(bettorSlot < BET_SLOTS_PER_BETTOR, "Cannot place a bet; exceeded max allowed unresolved bets per bettor");

        uint instrumentSlot = getFirstAvailableBetSlotForInstrument(oracle, duration, startsAt);
        require(instrumentSlot < BET_SLOTS_PER_INSTRUMENT, "Cannot place a bet; exceeded max allowed bets per instrument");
        balances[msg.sender] -= size;
        Bet storage bet = bets[oracle][duration][startsAt];
        bet.total += size;
        bet.totals[direction] += size;
        bet.balances[direction][msg.sender] += size;
        betSlotsPerBettor[msg.sender][bettorSlot] = BetSlot(oracle, duration, startsAt, true);
        betQueuePerInstrument[oracle][duration][instrumentSlot] = startsAt;
        emit BetPlaced(msg.sender, oracle, symbol(oracle), duration, startsAt, direction, size);
    }
    event BetPlaced(address account, address oracle, string symbol, BetDuration duration, uint startsAt, BetDirection kind, uint size);

    function getFirstAvailableBetSlotForBettor() private view returns (uint) {
        for (uint i = 0; i < BET_SLOTS_PER_BETTOR; i++) if (!betSlotsPerBettor[msg.sender][i].occupied) return i;
        return BET_SLOTS_PER_BETTOR;
    }

    function symbol(address oracle) public view returns (string memory) {
        require(oracle.isContract(), "oracle must be a contract address");
        try AggregatorV3Interface(oracle).description() returns (string memory description) {
            return description;
        } catch (bytes memory) {
            return "oracle must be an AggregatorV3Interface contract";
        }
    }

    function countUnresolvedBetsForBettor() public view returns (uint result) {
        for (uint i = 0; i < BET_SLOTS_PER_BETTOR; i++) if (betSlotsPerBettor[msg.sender][i].occupied) result += 1;
    }

    function getFirstAvailableBetSlotForInstrument(address oracle, BetDuration duration, uint startsAt) public view returns (uint) {
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