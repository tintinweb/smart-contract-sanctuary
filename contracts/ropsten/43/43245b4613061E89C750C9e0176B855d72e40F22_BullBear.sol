// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract BullBear {
    using Address for address;

    enum BetDirection {Unknown, Bear, Chop, Bull}
    enum BetDuration {None, OneMinute, FiveMinutes, FifteenMinutes, OneHour, OneDay, OneWeek, OneQuarter}

    struct Bet {
        address oracle;
        BetDuration duration;
        uint startsAt;
        uint total;
        uint remaining;
        mapping(BetDirection => uint) totals;
        mapping(BetDirection => mapping(address => uint)) balances;
        BetDirection outcome;
        address resolver;
    }

    uint public constant BETS_PER_BETTOR = 10;
    uint public constant BETS_PER_INSTRUMENT = 2;

    address public owner;
    address public feeRecipient;
    uint public feeBasispoints;
    string public version;
    mapping(address => uint) public balances;
    mapping(bytes32 => Bet) public bets; // betId => Bet
    mapping(address => bytes32[BETS_PER_BETTOR]) public bettorBets; // account => betIds
    mapping(address => mapping(bytes32 => bool)) public bettorBetsIsOccupied; // account => betId => bool
    mapping(address => mapping(BetDuration => uint[BETS_PER_INSTRUMENT])) public instrumentBets; // oracle => duration => startsAt[]
    mapping(BetDuration => uint) public durations;

    constructor(address _owner, address _feeRecipient, uint _feeBasispoints, string memory _version) {
        owner = _owner;
        feeRecipient = _feeRecipient;
        version = _version;
        feeBasispoints = _feeBasispoints;
        durations[BetDuration.OneMinute] = 1 * 60;
        durations[BetDuration.FiveMinutes] = 5 * 60;
        durations[BetDuration.FifteenMinutes] = 15 * 60;
        durations[BetDuration.OneHour] = 1 * 60 * 60;
        durations[BetDuration.OneDay] = 24 * 60 * 60;
        durations[BetDuration.OneWeek] = 7 * 24 * 60 * 60;
        durations[BetDuration.OneQuarter] = 91 * 24 * 60 * 60;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }

    function getBetId(address oracle, BetDuration duration, uint startsAt) public pure returns (bytes32) {
        return keccak256(abi.encode(oracle, duration, startsAt));
    }

    function resolveThenPlaceBets(
        bytes32[] memory resolveBetIds, uint80[] memory lockedRoundIdsToResolve, uint80[] memory resolvedRoundIdsToResolve,
        address[] memory oraclesToBet, BetDuration[] memory durationsToBet, BetDirection[] memory directionsToBet, uint[] memory sizesToBet
    ) external payable {
        balances[msg.sender] += msg.value;
        resolveBets(resolveBetIds, lockedRoundIdsToResolve, resolvedRoundIdsToResolve);
        placeBets(oraclesToBet, durationsToBet, directionsToBet, sizesToBet);
    }

    function placeBets(
        address[] memory oraclesToBet, BetDuration[] memory durationsToBet, BetDirection[] memory directionsToBet, uint[] memory sizesToBet
    ) private {
        require(
            oraclesToBet.length <= BETS_PER_BETTOR &&
            oraclesToBet.length == durationsToBet.length &&
            oraclesToBet.length == directionsToBet.length &&
            oraclesToBet.length == sizesToBet.length,
            "all to-bet parameter arrays must be of same length"
        );
        for (uint i = 0; i < oraclesToBet.length; i++) _placeBet(oraclesToBet[i], durationsToBet[i], directionsToBet[i], sizesToBet[i]);
    }

    function placeBet(address oracle, BetDuration duration, BetDirection direction, uint size) external payable {
        balances[msg.sender] += msg.value;
        _placeBet(oracle, duration, direction, size);
    }

    function _placeBet(address oracle, BetDuration duration, BetDirection direction, uint size) private {
        require(duration != BetDuration.None, "Invalid bet duration");
        require(direction != BetDirection.Unknown, "Invalid bet direction");
        require(size > 0, "Size must be greater than zero");

        claimResolvedBets();
        require(balances[msg.sender] >= size, "Bet size exceeds available balance");

        uint startsAt = block.timestamp - block.timestamp % durations[duration] + durations[duration];
        bytes32 id = getBetId(oracle, duration, startsAt);
        if (!bettorBetsIsOccupied[msg.sender][id]) {
            uint bettorSlot = getFirstAvailableBetSlotForBettor();
            require(bettorSlot < BETS_PER_BETTOR, "Cannot place a bet; exceeded max allowed unresolved bets per bettor");
            bettorBets[msg.sender][bettorSlot] = id;
            bettorBetsIsOccupied[msg.sender][id] = true;
        }
        uint instrumentSlot = getFirstAvailableBetSlotForInstrument(oracle, duration, startsAt);
        require(instrumentSlot < BETS_PER_INSTRUMENT, "Cannot place a bet; exceeded max allowed bets per instrument");
        balances[msg.sender] -= size;
        Bet storage bet = bets[id];
        if (bet.oracle == address(0x0)) {
            bet.oracle = oracle;
            bet.duration = duration;
            bet.startsAt = startsAt;
        }

        bet.total += size;
        bet.totals[direction] += size;
        bet.balances[direction][msg.sender] += size;
        instrumentBets[oracle][duration][instrumentSlot] = startsAt;
    emit BetPlaced(msg.sender, oracle, symbol(oracle), duration, startsAt, direction, size);
    }
    event BetPlaced(address account, address oracle, string symbol, BetDuration duration, uint startsAt, BetDirection kind, uint size);

    function getFirstAvailableBetSlotForBettor() private view returns (uint) {
        for (uint i = 0; i < BETS_PER_BETTOR; i++) if (bettorBets[msg.sender][i] == 0) return i;
        return BETS_PER_BETTOR;
    }

    function symbol(address oracle) private view returns (string memory) {
        require(oracle.isContract(), "Oracle must be a contract address");
        try AggregatorV3Interface(oracle).description() returns (string memory description) {
            return description;
        } catch (bytes memory) {
            return "Oracle must be an AggregatorV3Interface contract";
        }
    }

    function canPlaceBet(address account) external view returns (bool) {
        return countUnresolvedBetsForBettor(account) < BETS_PER_BETTOR || countResolvableNowBetsForBettor(account) > 0 ;
    }

    function countUnresolvedBetsForBettor(address account) public view returns (uint result) {
        for (uint i = 0; i < BETS_PER_BETTOR; i++) {
            bytes32 id = bettorBets[account][i];
            if (id != 0 && !_isResolvedBet(id)) result += 1;
        }
    }

    function countUnresolvedBetsForInstrument(address oracle, BetDuration duration) external view returns (uint result) {
        for (uint i = 0; i < BETS_PER_INSTRUMENT; i++) {
            bytes32 id = getBetId(oracle, duration, instrumentBets[oracle][duration][i]);
            if (isUnresolvedBet(id)) result += 1;
        }
    }

    function getFirstAvailableBetSlotForInstrument(address oracle, BetDuration duration, uint startsAt) private view returns (uint) {
        for (uint i = 0; i < BETS_PER_INSTRUMENT; i++) {
            uint start = instrumentBets[oracle][duration][i];
            if (start == 0 || start == startsAt) return i;
        }
        return BETS_PER_INSTRUMENT;
    }

    function getStartAtOfUnresolvedBetsForInstrument(address oracle, BetDuration duration) external view returns (uint[BETS_PER_INSTRUMENT] memory result) {
        for (uint i = 0; i < BETS_PER_INSTRUMENT; i++) {
            uint start = instrumentBets[oracle][duration][i];
            bytes32 id = getBetId(oracle, duration, start);
            if (isUnresolvedBet(id)) result[i] = start;
        }
    }

    function countResolvableNowBetsForBettor(address account) private view returns (uint result) {
        for (uint i = 0; i < BETS_PER_BETTOR; i++) {
            bytes32 id = bettorBets[account][i];
            if (isResolvableNowBet(id)) result += 1;
        }
    }

    function resolveBets(
        bytes32[] memory resolveBetIds, uint80[] memory lockedRoundIdsToResolve, uint80[] memory resolvedRoundIdsToResolve
    ) private {
        require(
            resolveBetIds.length <= BETS_PER_BETTOR &&
            resolveBetIds.length == lockedRoundIdsToResolve.length &&
            resolveBetIds.length == resolvedRoundIdsToResolve.length,
            "all to-resolve parameter arrays must be of same length"
        );
        for (uint i = 0; i < resolveBetIds.length; i++) if (isResolvableNowBet(resolveBetIds[i])) resolveBet(resolveBetIds[i], lockedRoundIdsToResolve[i], resolvedRoundIdsToResolve[i]);
    }

    function resolveBet(bytes32 betId, uint80 lockedRoundId, uint80 resolvedRoundId) private {
        Bet storage bet = bets[betId];
        uint endsAt = bet.startsAt + durations[bet.duration];
        require(bet.total > 0, "Bet does not exist");
        require(endsAt < block.timestamp, "Too early to resolve bet");

        // resolve outcome
        AggregatorV3Interface priceFeed = AggregatorV3Interface(bet.oracle);
        (,,,uint latestUpdatedAt,) = priceFeed.latestRoundData();
        uint lockedPrice = getValidRoundPrice(priceFeed, bet.startsAt, lockedRoundId, latestUpdatedAt);
        uint resolvedPrice = getValidRoundPrice(priceFeed, endsAt, resolvedRoundId, latestUpdatedAt);
        bet.outcome = (resolvedPrice == lockedPrice) ?
            BetDirection.Chop :
            (resolvedPrice > lockedPrice) ?
                BetDirection.Bull :
                BetDirection.Bear;
        bet.resolver = msg.sender;
        uint fee = (bet.total * feeBasispoints) / 10000;
        emit BetResolved(bet.resolver, bet.oracle, bet.duration, bet.startsAt, bet.total, bet.totals[BetDirection.Bear], bet.totals[BetDirection.Chop], bet.totals[BetDirection.Bull], bet.outcome, fee, lockedPrice, resolvedPrice);

        // compensate the resolver
        bet.total -= fee;
        bet.remaining = bet.total;
        balances[feeRecipient] += fee;

        tidyUpBetQueuePerInstrument(bet.oracle, bet.duration);

        // if there are no winners, the "house" wins
        if (bet.totals[bet.outcome] == 0) balances[feeRecipient] += bet.total;
    }
    event BetResolved(address resolver, address oracle, BetDuration duration, uint startsAt, uint total, uint Bear, uint Chop, uint Bull, BetDirection outcome, uint fee, uint lockedPrice, uint resolvedPrice);

    function tidyUpBetQueuePerInstrument(address oracle, BetDuration duration) private {
        uint available = 0;
        for (uint i = 0; i < BETS_PER_INSTRUMENT; i++) {
            uint startsAt = instrumentBets[oracle][duration][i];
            if (isUnresolvedBet(getBetId(oracle, duration, startsAt))) {
                if (i > available) {
                    instrumentBets[oracle][duration][available] = startsAt;
                    instrumentBets[oracle][duration][i] = 0;
                }
                available += 1;
            } else instrumentBets[oracle][duration][i] = 0;
        }
    }

    function getValidRoundPrice(AggregatorV3Interface priceFeed, uint boundaryTimestamp, uint80 roundId, uint latestUpdatedAt) private view returns (uint) {
        ( ,int price, , uint thisRoundUpdatedAt, ) = priceFeed.getRoundData(roundId);
        require(thisRoundUpdatedAt <= boundaryTimestamp, "Round timestamp beyond boundary");

        if (thisRoundUpdatedAt == latestUpdatedAt) /* no price change */ return uint(price);

        bool isBoundaryBeforeNextRound = latestUpdatedAt == thisRoundUpdatedAt;
        if (!isBoundaryBeforeNextRound) {
            ( , , , uint nextRoundUpdatedAt, ) = priceFeed.getRoundData(roundId + 1);
            isBoundaryBeforeNextRound = nextRoundUpdatedAt > boundaryTimestamp;
        }
        require(isBoundaryBeforeNextRound, "Stale round id");
        return uint(price);
    }

    function isUnresolvedBet(bytes32 id) public view returns (bool) {
        return bets[id].startsAt != 0 && !_isResolvedBet(id);
    }

    function isResolvableNowBet(bytes32 id) public view returns (bool) {
        return isUnresolvedBet(id) && /* is not open */ bets[id].startsAt + durations[bets[id].duration] <= block.timestamp;
    }

    function isResolvedBet(address oracle, BetDuration duration, uint startsAt) external view returns (bool) {
        return _isResolvedBet(getBetId(oracle, duration, startsAt));
    }

    function _isResolvedBet(bytes32 id) private view returns (bool) {
        return bets[id].outcome != BetDirection.Unknown;
    }

    function claimResolvedBets() private {
        for (uint i = 0; i < BETS_PER_BETTOR; i++) {
            bytes32 id = bettorBets[msg.sender][i];
            if (!_isResolvedBet(id) || id==0) continue;
            claimBet(id);
            bettorBets[msg.sender][i] = 0;
            delete (bettorBetsIsOccupied[msg.sender][id]);
        }
    }

    function claimBet(bytes32 id) private {
        require(_isResolvedBet(id), "Cannot claim unresolved bet");
        Bet storage bet = bets[id];
        uint size = bet.balances[bet.outcome][msg.sender];
        if (size > 0) {
            delete bet.balances[bet.outcome][msg.sender];
            uint winning = size * bet.total / bet.totals[bet.outcome];
            bet.remaining -= winning;
            balances[msg.sender] += winning;
            emit BetClaimed(msg.sender, bet.oracle, bet.duration, bet.startsAt, bet.outcome, winning);
        }
        reclaimBetStorage(id);
    }
    event BetClaimed(address account, address oracle, BetDuration duration, uint startsAt, BetDirection outcome, uint winning);

    function reclaimBetStorage(bytes32 id) private {
        for (uint i = uint(BetDirection.Bear); i <= uint(BetDirection.Bull); ++i) delete bets[id].balances[BetDirection(i)][msg.sender];
        if (bets[id].remaining == 0) {
            delete bets[id];
            // delete does not cascade to mappings
            for (uint i = uint(BetDirection.Bear); i <= uint(BetDirection.Bull); ++i) delete bets[id].totals[BetDirection(i)];
        }
    }

    function getBetTotals(address oracle, BetDuration duration, uint startsAt) external view returns (uint total, uint Bear, uint Chop, uint Bull) {
        Bet storage bet = bets[getBetId(oracle, duration, startsAt)];
        total = bet.total;
        Bear = bet.totals[BetDirection.Bear];
        Chop = bet.totals[BetDirection.Chop];
        Bull = bet.totals[BetDirection.Bull];
    }

    function getBettorBetTotals(address oracle, BetDuration duration, uint startsAt, address account) external view returns (uint Bear, uint Chop, uint Bull) {
        Bet storage bet = bets[getBetId(oracle, duration, startsAt)];
        Bear = bet.balances[BetDirection.Bear][account];
        Chop = bet.balances[BetDirection.Chop][account];
        Bull = bet.balances[BetDirection.Bull][account];
    }

    function getAvailableBalance(address account) external view returns (uint) {
        uint result = balances[account];
        for (uint i = 0; i < BETS_PER_BETTOR; i++) {
            bytes32 id = bettorBets[account][i];
            if (!_isResolvedBet(id) || id == 0) continue;
            Bet storage bet = bets[id];
            uint size = bet.balances[bet.outcome][account];
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

    modifier onlyOwner { require(msg.sender == owner, "invalid sender; must be owner"); _; }

    function changeOwner(address _owner) external onlyOwner {
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }
    event OwnerChanged(address from, address to);

    function changeFeeRecipient(address _feeRecipient) external onlyOwner {
        emit FeeRecipientChanged(feeRecipient, _feeRecipient);
        feeRecipient = _feeRecipient;
    }
    event FeeRecipientChanged(address from, address to);

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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