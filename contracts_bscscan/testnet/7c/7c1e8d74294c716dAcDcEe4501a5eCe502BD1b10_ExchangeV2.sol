// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";

import "./SafeDecimalMath.sol";
import "./ProxyUtility.sol";

import {Order, OrderQueue, LibOrderQueue} from "./LibOrderQueue.sol";
import {
    UnsettledBuyTrade,
    UnsettledSellTrade,
    UnsettledTrade,
    LibUnsettledBuyTrade,
    LibUnsettledSellTrade
} from "./LibUnsettledTrade.sol";

import "./ExchangeRoles.sol";
import "./StakingV2.sol";

/// @title Tranchess's Exchange Contract
/// @notice A decentralized exchange to match premium-discount orders and clear trades
/// @author Tranchess
contract ExchangeV2 is ExchangeRoles, StakingV2, ProxyUtility {
    /// @dev Reserved storage slots for future base contract upgrades
    uint256[29] private _reservedSlots;

    using SafeDecimalMath for uint256;
    using LibOrderQueue for OrderQueue;
    using SafeERC20 for IERC20;
    using LibUnsettledBuyTrade for UnsettledBuyTrade;
    using LibUnsettledSellTrade for UnsettledSellTrade;

    /// @notice A maker bid order is placed.
    /// @param maker Account placing the order
    /// @param tranche Tranche of the share to buy
    /// @param pdLevel Premium-discount level
    /// @param quoteAmount Amount of quote asset in the order, rounding precision to 18
    ///                    for quote assets with precision other than 18 decimal places
    /// @param version The latest rebalance version when the order is placed
    /// @param orderIndex Index of the order in the order queue
    event BidOrderPlaced(
        address indexed maker,
        uint256 indexed tranche,
        uint256 pdLevel,
        uint256 quoteAmount,
        uint256 version,
        uint256 orderIndex
    );

    /// @notice A maker ask order is placed.
    /// @param maker Account placing the order
    /// @param tranche Tranche of the share to sell
    /// @param pdLevel Premium-discount level
    /// @param baseAmount Amount of base asset in the order
    /// @param version The latest rebalance version when the order is placed
    /// @param orderIndex Index of the order in the order queue
    event AskOrderPlaced(
        address indexed maker,
        uint256 indexed tranche,
        uint256 pdLevel,
        uint256 baseAmount,
        uint256 version,
        uint256 orderIndex
    );

    /// @notice A maker bid order is canceled.
    /// @param maker Account placing the order
    /// @param tranche Tranche of the share
    /// @param pdLevel Premium-discount level
    /// @param quoteAmount Original amount of quote asset in the order, rounding precision to 18
    ///                    for quote assets with precision other than 18 decimal places
    /// @param version The latest rebalance version when the order is placed
    /// @param orderIndex Index of the order in the order queue
    /// @param fillable Unfilled amount when the order is canceled, rounding precision to 18 for
    ///                 quote assets with precision other than 18 decimal places
    event BidOrderCanceled(
        address indexed maker,
        uint256 indexed tranche,
        uint256 pdLevel,
        uint256 quoteAmount,
        uint256 version,
        uint256 orderIndex,
        uint256 fillable
    );

    /// @notice A maker ask order is canceled.
    /// @param maker Account placing the order
    /// @param tranche Tranche of the share to sell
    /// @param pdLevel Premium-discount level
    /// @param baseAmount Original amount of base asset in the order
    /// @param version The latest rebalance version when the order is placed
    /// @param orderIndex Index of the order in the order queue
    /// @param fillable Unfilled amount when the order is canceled
    event AskOrderCanceled(
        address indexed maker,
        uint256 indexed tranche,
        uint256 pdLevel,
        uint256 baseAmount,
        uint256 version,
        uint256 orderIndex,
        uint256 fillable
    );

    /// @notice Matching result of a taker bid order.
    /// @param taker Account placing the order
    /// @param tranche Tranche of the share
    /// @param quoteAmount Matched amount of quote asset, rounding precision to 18 for quote assets
    ///                    with precision other than 18 decimal places
    /// @param version Rebalance version of this trade
    /// @param lastMatchedPDLevel Premium-discount level of the last matched maker order
    /// @param lastMatchedOrderIndex Index of the last matched maker order in its order queue
    /// @param lastMatchedBaseAmount Matched base asset amount of the last matched maker order
    event BuyTrade(
        address indexed taker,
        uint256 indexed tranche,
        uint256 quoteAmount,
        uint256 version,
        uint256 lastMatchedPDLevel,
        uint256 lastMatchedOrderIndex,
        uint256 lastMatchedBaseAmount
    );

    /// @notice Matching result of a taker ask order.
    /// @param taker Account placing the order
    /// @param tranche Tranche of the share
    /// @param baseAmount Matched amount of base asset
    /// @param version Rebalance version of this trade
    /// @param lastMatchedPDLevel Premium-discount level of the last matched maker order
    /// @param lastMatchedOrderIndex Index of the last matched maker order in its order queue
    /// @param lastMatchedQuoteAmount Matched quote asset amount of the last matched maker order,
    ///                               rounding precision to 18 for quote assets with precision
    ///                               other than 18 decimal places
    event SellTrade(
        address indexed taker,
        uint256 indexed tranche,
        uint256 baseAmount,
        uint256 version,
        uint256 lastMatchedPDLevel,
        uint256 lastMatchedOrderIndex,
        uint256 lastMatchedQuoteAmount
    );

    /// @notice Settlement of unsettled trades of maker orders.
    /// @param account Account placing the related maker orders
    /// @param epoch Epoch of the settled trades
    /// @param amountM Amount of Token M added to the account's available balance
    /// @param amountA Amount of Token A added to the account's available balance
    /// @param amountB Amount of Token B added to the account's available balance
    /// @param quoteAmount Amount of quote asset transfered to the account, rounding precision to 18
    ///                    for quote assets with precision other than 18 decimal places
    event MakerSettled(
        address indexed account,
        uint256 epoch,
        uint256 amountM,
        uint256 amountA,
        uint256 amountB,
        uint256 quoteAmount
    );

    /// @notice Settlement of unsettled trades of taker orders.
    /// @param account Account placing the related taker orders
    /// @param epoch Epoch of the settled trades
    /// @param amountM Amount of Token M added to the account's available balance
    /// @param amountA Amount of Token A added to the account's available balance
    /// @param amountB Amount of Token B added to the account's available balance
    /// @param quoteAmount Amount of quote asset transfered to the account, rounding precision to 18
    ///                    for quote assets with precision other than 18 decimal places
    event TakerSettled(
        address indexed account,
        uint256 epoch,
        uint256 amountM,
        uint256 amountA,
        uint256 amountB,
        uint256 quoteAmount
    );

    uint256 private constant EPOCH = 30 minutes; // An exchange epoch is 30 minutes long

    /// @dev Maker reserves 105% of Token M they want to trade, which would stop
    ///      losses for makers when the net asset values turn out volatile
    uint256 private constant MAKER_RESERVE_RATIO_M = 1.05e18;

    /// @dev Maker reserves 100.1% of Token A they want to trade, which would stop
    ///      losses for makers when the net asset values turn out volatile
    uint256 private constant MAKER_RESERVE_RATIO_A = 1.001e18;

    /// @dev Maker reserves 110% of Token B they want to trade, which would stop
    ///      losses for makers when the net asset values turn out volatile
    uint256 private constant MAKER_RESERVE_RATIO_B = 1.1e18;

    /// @dev Premium-discount level ranges from -10% to 10% with 0.25% as step size
    uint256 private constant PD_TICK = 0.0025e18;

    uint256 private constant MIN_PD = 0.9e18;
    uint256 private constant MAX_PD = 1.1e18;
    uint256 private constant PD_START = MIN_PD - PD_TICK;
    uint256 private constant PD_LEVEL_COUNT = (MAX_PD - MIN_PD) / PD_TICK + 1;

    /// @notice Minumum quote amount of maker bid orders with 18 decimal places
    uint256 public immutable minBidAmount;

    /// @notice Minumum base amount of maker ask orders
    uint256 public immutable minAskAmount;

    /// @notice Minumum base or quote amount of maker orders during guarded launch
    uint256 public immutable guardedLaunchMinOrderAmount;

    /// @dev A multipler that normalizes a quote asset balance to 18 decimal places.
    uint256 private immutable _quoteDecimalMultiplier;

    /// @notice Mapping of rebalance version => tranche => an array of order queues
    mapping(uint256 => mapping(uint256 => OrderQueue[PD_LEVEL_COUNT + 1])) public bids;
    mapping(uint256 => mapping(uint256 => OrderQueue[PD_LEVEL_COUNT + 1])) public asks;

    /// @notice Mapping of rebalance version => best bid premium-discount level of the three tranches.
    ///         Zero indicates that there is no bid order.
    mapping(uint256 => uint256[TRANCHE_COUNT]) public bestBids;

    /// @notice Mapping of rebalance version => best ask premium-discount level of the three tranches.
    ///         Zero or `PD_LEVEL_COUNT + 1` indicates that there is no ask order.
    mapping(uint256 => uint256[TRANCHE_COUNT]) public bestAsks;

    /// @notice Mapping of account => tranche => epoch => unsettled trade
    mapping(address => mapping(uint256 => mapping(uint256 => UnsettledTrade)))
        public unsettledTrades;

    /// @dev Mapping of epoch => rebalance version
    mapping(uint256 => uint256) private _epochVersions;

    constructor(
        address fund_,
        address chessSchedule_,
        address chessController_,
        address quoteAssetAddress_,
        uint256 quoteDecimals_,
        address votingEscrow_,
        uint256 minBidAmount_,
        uint256 minAskAmount_,
        uint256 makerRequirement_,
        uint256 guardedLaunchStart_,
        uint256 guardedLaunchMinOrderAmount_
    )
        public
        ExchangeRoles(votingEscrow_, makerRequirement_)
        StakingV2(
            fund_,
            chessSchedule_,
            chessController_,
            quoteAssetAddress_,
            guardedLaunchStart_,
            votingEscrow_
        )
    {
        minBidAmount = minBidAmount_;
        minAskAmount = minAskAmount_;
        guardedLaunchMinOrderAmount = guardedLaunchMinOrderAmount_;
        require(quoteDecimals_ <= 18, "Quote asset decimals larger than 18");
        _quoteDecimalMultiplier = 10**(18 - quoteDecimals_);
    }

    /// @dev Initialize the contract. The contract is designed to be used with OpenZeppelin's
    ///      `TransparentUpgradeableProxy`. This function should be called by the proxy's
    ///      constructor (via the `_data` argument).
    function initialize() external {
        _initializeStaking();
        _initializeV2(msg.sender);
    }

    /// @dev Initialize the part added in V2. If this contract is upgraded from the previous
    ///      version, call `upgradeToAndCall` of the proxy and put a call to this function
    ///      in the `data` argument.
    function initializeV2(address pauser_) external onlyProxyAdmin {
        _initializeV2(pauser_);
    }

    function _initializeV2(address pauser_) private {
        _initializeStakingV2(pauser_);
    }

    /// @notice Return end timestamp of the epoch containing a given timestamp.
    /// @param timestamp Timestamp within a given epoch
    /// @return The closest ending timestamp
    function endOfEpoch(uint256 timestamp) public pure returns (uint256) {
        return (timestamp / EPOCH) * EPOCH + EPOCH;
    }

    function getMakerReserveRatio(uint256 tranche) public pure returns (uint256) {
        if (tranche == TRANCHE_M) {
            return MAKER_RESERVE_RATIO_M;
        } else if (tranche == TRANCHE_A) {
            return MAKER_RESERVE_RATIO_A;
        } else {
            return MAKER_RESERVE_RATIO_B;
        }
    }

    function getBidOrder(
        uint256 version,
        uint256 tranche,
        uint256 pdLevel,
        uint256 index
    )
        external
        view
        returns (
            address maker,
            uint256 amount,
            uint256 fillable
        )
    {
        Order storage order = bids[version][tranche][pdLevel].list[index];
        maker = order.maker;
        amount = order.amount;
        fillable = order.fillable;
    }

    function getAskOrder(
        uint256 version,
        uint256 tranche,
        uint256 pdLevel,
        uint256 index
    )
        external
        view
        returns (
            address maker,
            uint256 amount,
            uint256 fillable
        )
    {
        Order storage order = asks[version][tranche][pdLevel].list[index];
        maker = order.maker;
        amount = order.amount;
        fillable = order.fillable;
    }

    /// @notice Get all tranches' net asset values of a given time
    /// @param timestamp Timestamp of the net asset value
    /// @return estimatedNavM Token M's net asset value
    /// @return estimatedNavA Token A's net asset value
    /// @return estimatedNavB Token B's net asset value
    function estimateNavs(uint256 timestamp)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 price = fund.twapOracle().getTwap(timestamp);
        require(price != 0, "Price is not available");
        return fund.extrapolateNav(timestamp, price);
    }

    /// @notice Place a bid order for makers
    /// @param tranche Tranche of the base asset
    /// @param pdLevel Premium-discount level
    /// @param quoteAmount Quote asset amount with 18 decimal places
    /// @param version Current rebalance version. Revert if it is not the latest version.
    function placeBid(
        uint256 tranche,
        uint256 pdLevel,
        uint256 quoteAmount,
        uint256 version
    ) external onlyMaker whenNotPaused {
        require(block.timestamp >= guardedLaunchStart + 8 days, "Guarded launch: market closed");
        if (block.timestamp < guardedLaunchStart + 4 weeks) {
            require(quoteAmount >= guardedLaunchMinOrderAmount, "Guarded launch: amount too low");
        } else {
            require(quoteAmount >= minBidAmount, "Quote amount too low");
        }
        uint256 bestAsk = bestAsks[version][tranche];
        require(
            pdLevel > 0 && pdLevel < (bestAsk == 0 ? PD_LEVEL_COUNT + 1 : bestAsk),
            "Invalid premium-discount level"
        );
        require(version == _fundRebalanceSize(), "Invalid version");

        uint256 index = bids[version][tranche][pdLevel].append(msg.sender, quoteAmount, version);
        if (bestBids[version][tranche] < pdLevel) {
            bestBids[version][tranche] = pdLevel;
        }

        _transferQuoteFrom(msg.sender, quoteAmount);

        emit BidOrderPlaced(msg.sender, tranche, pdLevel, quoteAmount, version, index);
    }

    /// @notice Place an ask order for makers
    /// @param tranche Tranche of the base asset
    /// @param pdLevel Premium-discount level
    /// @param baseAmount Base asset amount
    /// @param version Current rebalance version. Revert if it is not the latest version.
    function placeAsk(
        uint256 tranche,
        uint256 pdLevel,
        uint256 baseAmount,
        uint256 version
    ) external onlyMaker whenNotPaused {
        require(block.timestamp >= guardedLaunchStart + 8 days, "Guarded launch: market closed");
        if (block.timestamp < guardedLaunchStart + 4 weeks) {
            require(baseAmount >= guardedLaunchMinOrderAmount, "Guarded launch: amount too low");
        } else {
            require(baseAmount >= minAskAmount, "Base amount too low");
        }
        require(
            pdLevel > bestBids[version][tranche] && pdLevel <= PD_LEVEL_COUNT,
            "Invalid premium-discount level"
        );
        require(version == _fundRebalanceSize(), "Invalid version");

        _lock(tranche, msg.sender, baseAmount);
        uint256 index = asks[version][tranche][pdLevel].append(msg.sender, baseAmount, version);
        uint256 oldBestAsk = bestAsks[version][tranche];
        if (oldBestAsk > pdLevel || oldBestAsk == 0) {
            bestAsks[version][tranche] = pdLevel;
        }

        emit AskOrderPlaced(msg.sender, tranche, pdLevel, baseAmount, version, index);
    }

    /// @notice Cancel a bid order
    /// @param version Order's rebalance version
    /// @param tranche Tranche of the order's base asset
    /// @param pdLevel Order's premium-discount level
    /// @param index Order's index in the order queue
    function cancelBid(
        uint256 version,
        uint256 tranche,
        uint256 pdLevel,
        uint256 index
    ) external whenNotPaused {
        OrderQueue storage orderQueue = bids[version][tranche][pdLevel];
        Order storage order = orderQueue.list[index];
        require(order.maker == msg.sender, "Maker address mismatched");

        uint256 fillable = order.fillable;
        emit BidOrderCanceled(msg.sender, tranche, pdLevel, order.amount, version, index, fillable);
        orderQueue.cancel(index);

        // Update bestBid
        if (bestBids[version][tranche] == pdLevel) {
            uint256 newBestBid = pdLevel;
            while (newBestBid > 0 && bids[version][tranche][newBestBid].isEmpty()) {
                newBestBid--;
            }
            bestBids[version][tranche] = newBestBid;
        }

        _transferQuote(msg.sender, fillable);
    }

    /// @notice Cancel an ask order
    /// @param version Order's rebalance version
    /// @param tranche Tranche of the order's base asset
    /// @param pdLevel Order's premium-discount level
    /// @param index Order's index in the order queue
    function cancelAsk(
        uint256 version,
        uint256 tranche,
        uint256 pdLevel,
        uint256 index
    ) external whenNotPaused {
        OrderQueue storage orderQueue = asks[version][tranche][pdLevel];
        Order storage order = orderQueue.list[index];
        require(order.maker == msg.sender, "Maker address mismatched");

        uint256 fillable = order.fillable;
        emit AskOrderCanceled(msg.sender, tranche, pdLevel, order.amount, version, index, fillable);
        orderQueue.cancel(index);

        // Update bestAsk
        if (bestAsks[version][tranche] == pdLevel) {
            uint256 newBestAsk = pdLevel;
            while (newBestAsk <= PD_LEVEL_COUNT && asks[version][tranche][newBestAsk].isEmpty()) {
                newBestAsk++;
            }
            bestAsks[version][tranche] = newBestAsk;
        }

        if (tranche == TRANCHE_M) {
            _rebalanceAndUnlock(msg.sender, fillable, 0, 0, version);
        } else if (tranche == TRANCHE_A) {
            _rebalanceAndUnlock(msg.sender, 0, fillable, 0, version);
        } else {
            _rebalanceAndUnlock(msg.sender, 0, 0, fillable, version);
        }
    }

    /// @notice Buy Token M
    /// @param version Current rebalance version. Revert if it is not the latest version.
    /// @param maxPDLevel Maximal premium-discount level accepted
    /// @param quoteAmount Amount of quote assets (with 18 decimal places) willing to trade
    function buyM(
        uint256 version,
        uint256 maxPDLevel,
        uint256 quoteAmount
    ) external {
        (uint256 estimatedNav, , ) = estimateNavs(endOfEpoch(block.timestamp) - 2 * EPOCH);
        _buy(version, TRANCHE_M, maxPDLevel, estimatedNav, quoteAmount);
    }

    /// @notice Buy Token A
    /// @param version Current rebalance version. Revert if it is not the latest version.
    /// @param maxPDLevel Maximal premium-discount level accepted
    /// @param quoteAmount Amount of quote assets (with 18 decimal places) willing to trade
    function buyA(
        uint256 version,
        uint256 maxPDLevel,
        uint256 quoteAmount
    ) external {
        (, uint256 estimatedNav, ) = estimateNavs(endOfEpoch(block.timestamp) - 2 * EPOCH);
        _buy(version, TRANCHE_A, maxPDLevel, estimatedNav, quoteAmount);
    }

    /// @notice Buy Token B
    /// @param version Current rebalance version. Revert if it is not the latest version.
    /// @param maxPDLevel Maximal premium-discount level accepted
    /// @param quoteAmount Amount of quote assets (with 18 decimal places) willing to trade
    function buyB(
        uint256 version,
        uint256 maxPDLevel,
        uint256 quoteAmount
    ) external {
        (, , uint256 estimatedNav) = estimateNavs(endOfEpoch(block.timestamp) - 2 * EPOCH);
        _buy(version, TRANCHE_B, maxPDLevel, estimatedNav, quoteAmount);
    }

    /// @notice Sell Token M
    /// @param version Current rebalance version. Revert if it is not the latest version.
    /// @param minPDLevel Minimal premium-discount level accepted
    /// @param baseAmount Amount of Token M willing to trade
    function sellM(
        uint256 version,
        uint256 minPDLevel,
        uint256 baseAmount
    ) external {
        (uint256 estimatedNav, , ) = estimateNavs(endOfEpoch(block.timestamp) - 2 * EPOCH);
        _sell(version, TRANCHE_M, minPDLevel, estimatedNav, baseAmount);
    }

    /// @notice Sell Token A
    /// @param version Current rebalance version. Revert if it is not the latest version.
    /// @param minPDLevel Minimal premium-discount level accepted
    /// @param baseAmount Amount of Token A willing to trade
    function sellA(
        uint256 version,
        uint256 minPDLevel,
        uint256 baseAmount
    ) external {
        (, uint256 estimatedNav, ) = estimateNavs(endOfEpoch(block.timestamp) - 2 * EPOCH);
        _sell(version, TRANCHE_A, minPDLevel, estimatedNav, baseAmount);
    }

    /// @notice Sell Token B
    /// @param version Current rebalance version. Revert if it is not the latest version.
    /// @param minPDLevel Minimal premium-discount level accepted
    /// @param baseAmount Amount of Token B willing to trade
    function sellB(
        uint256 version,
        uint256 minPDLevel,
        uint256 baseAmount
    ) external {
        (, , uint256 estimatedNav) = estimateNavs(endOfEpoch(block.timestamp) - 2 * EPOCH);
        _sell(version, TRANCHE_B, minPDLevel, estimatedNav, baseAmount);
    }

    /// @notice Settle trades of a specified epoch for makers
    /// @param account Address of the maker
    /// @param epoch A specified epoch's end timestamp
    /// @return amountM Token M amount added to msg.sender's available balance
    /// @return amountA Token A amount added to msg.sender's available balance
    /// @return amountB Token B amount added to msg.sender's available balance
    /// @return quoteAmount Quote asset amount transfered to msg.sender, rounding precison to 18
    ///                     for quote assets with precision other than 18 decimal places
    function settleMaker(address account, uint256 epoch)
        external
        whenNotPaused
        returns (
            uint256 amountM,
            uint256 amountA,
            uint256 amountB,
            uint256 quoteAmount
        )
    {
        (uint256 estimatedNavM, uint256 estimatedNavA, uint256 estimatedNavB) =
            estimateNavs(epoch.add(EPOCH));

        uint256 quoteAmountM;
        uint256 quoteAmountA;
        uint256 quoteAmountB;
        (amountM, quoteAmountM) = _settleMaker(account, TRANCHE_M, estimatedNavM, epoch);
        (amountA, quoteAmountA) = _settleMaker(account, TRANCHE_A, estimatedNavA, epoch);
        (amountB, quoteAmountB) = _settleMaker(account, TRANCHE_B, estimatedNavB, epoch);

        uint256 version = _epochVersions[epoch];
        (amountM, amountA, amountB) = _rebalanceAndClearTrade(
            account,
            amountM,
            amountA,
            amountB,
            version
        );
        quoteAmount = quoteAmountM.add(quoteAmountA).add(quoteAmountB);
        _transferQuote(account, quoteAmount);

        emit MakerSettled(account, epoch, amountM, amountA, amountB, quoteAmount);
    }

    /// @notice Settle trades of a specified epoch for takers
    /// @param account Address of the maker
    /// @param epoch A specified epoch's end timestamp
    /// @return amountM Token M amount added to msg.sender's available balance
    /// @return amountA Token A amount added to msg.sender's available balance
    /// @return amountB Token B amount added to msg.sender's available balance
    /// @return quoteAmount Quote asset amount transfered to msg.sender, rounding precison to 18
    ///                     for quote assets with precision other than 18 decimal places
    function settleTaker(address account, uint256 epoch)
        external
        whenNotPaused
        returns (
            uint256 amountM,
            uint256 amountA,
            uint256 amountB,
            uint256 quoteAmount
        )
    {
        (uint256 estimatedNavM, uint256 estimatedNavA, uint256 estimatedNavB) =
            estimateNavs(epoch.add(EPOCH));

        uint256 quoteAmountM;
        uint256 quoteAmountA;
        uint256 quoteAmountB;
        (amountM, quoteAmountM) = _settleTaker(account, TRANCHE_M, estimatedNavM, epoch);
        (amountA, quoteAmountA) = _settleTaker(account, TRANCHE_A, estimatedNavA, epoch);
        (amountB, quoteAmountB) = _settleTaker(account, TRANCHE_B, estimatedNavB, epoch);

        uint256 version = _epochVersions[epoch];
        (amountM, amountA, amountB) = _rebalanceAndClearTrade(
            account,
            amountM,
            amountA,
            amountB,
            version
        );
        quoteAmount = quoteAmountM.add(quoteAmountA).add(quoteAmountB);
        _transferQuote(account, quoteAmount);

        emit TakerSettled(account, epoch, amountM, amountA, amountB, quoteAmount);
    }

    /// @dev Buy share
    /// @param version Current rebalance version. Revert if it is not the latest version.
    /// @param tranche Tranche of the base asset
    /// @param maxPDLevel Maximal premium-discount level accepted
    /// @param estimatedNav Estimated net asset value of the base asset
    /// @param quoteAmount Amount of quote assets willing to trade with 18 decimal places
    function _buy(
        uint256 version,
        uint256 tranche,
        uint256 maxPDLevel,
        uint256 estimatedNav,
        uint256 quoteAmount
    ) internal onlyActive whenNotPaused {
        require(maxPDLevel > 0 && maxPDLevel <= PD_LEVEL_COUNT, "Invalid premium-discount level");
        require(version == _fundRebalanceSize(), "Invalid version");
        require(estimatedNav > 0, "Zero estimated NAV");

        UnsettledBuyTrade memory totalTrade;
        uint256 epoch = endOfEpoch(block.timestamp);

        // Record rebalance version in the first transaction in the epoch
        if (_epochVersions[epoch] == 0) {
            _epochVersions[epoch] = version;
        }

        UnsettledBuyTrade memory currentTrade;
        uint256 orderIndex = 0;
        uint256 pdLevel = bestAsks[version][tranche];
        if (pdLevel == 0) {
            // Zero best ask indicates that no ask order is ever placed.
            // We set pdLevel beyond the largest valid level, forcing the following loop
            // to exit immediately.
            pdLevel = PD_LEVEL_COUNT + 1;
        }
        for (; pdLevel <= maxPDLevel; pdLevel++) {
            uint256 price = pdLevel.mul(PD_TICK).add(PD_START).multiplyDecimal(estimatedNav);
            OrderQueue storage orderQueue = asks[version][tranche][pdLevel];
            orderIndex = orderQueue.head;
            while (orderIndex != 0) {
                Order storage order = orderQueue.list[orderIndex];

                // If the order initiator is no longer qualified for maker,
                // we skip the order and the linked-list-based order queue
                // would never traverse the order again
                if (!isMaker(order.maker)) {
                    orderIndex = order.next;
                    continue;
                }

                // Scope to avoid "stack too deep"
                {
                    // Calculate the current trade assuming that the taker would be completely filled.
                    uint256 makerReserveRatio = getMakerReserveRatio(tranche);
                    currentTrade.frozenQuote = quoteAmount.sub(totalTrade.frozenQuote);
                    currentTrade.reservedBase = currentTrade.frozenQuote.mul(makerReserveRatio).div(
                        price
                    );

                    if (currentTrade.reservedBase < order.fillable) {
                        // Taker is completely filled.
                        currentTrade.effectiveQuote = currentTrade.frozenQuote.divideDecimal(
                            pdLevel.mul(PD_TICK).add(PD_START)
                        );
                    } else {
                        // Maker is completely filled. Recalculate the current trade.
                        currentTrade.frozenQuote = order.fillable.mul(price).div(makerReserveRatio);
                        currentTrade.effectiveQuote = order.fillable.mul(estimatedNav).div(
                            makerReserveRatio
                        );
                        currentTrade.reservedBase = order.fillable;
                    }
                }
                totalTrade.frozenQuote = totalTrade.frozenQuote.add(currentTrade.frozenQuote);
                totalTrade.effectiveQuote = totalTrade.effectiveQuote.add(
                    currentTrade.effectiveQuote
                );
                totalTrade.reservedBase = totalTrade.reservedBase.add(currentTrade.reservedBase);
                unsettledTrades[order.maker][tranche][epoch].makerSell.add(currentTrade);

                // There is no need to rebalance for maker; the fact that the order could
                // be filled here indicates that the maker is in the latest version
                _tradeLocked(tranche, order.maker, currentTrade.reservedBase);

                uint256 orderNewFillable = order.fillable.sub(currentTrade.reservedBase);
                if (orderNewFillable > 0) {
                    // Maker is not completely filled. Matching ends here.
                    order.fillable = orderNewFillable;
                    break;
                } else {
                    // Delete the completely filled maker order.
                    orderIndex = orderQueue.fill(orderIndex);
                }
            }

            orderQueue.updateHead(orderIndex);
            if (orderIndex != 0) {
                // This premium-discount level is not completely filled. Matching ends here.
                if (bestAsks[version][tranche] != pdLevel) {
                    bestAsks[version][tranche] = pdLevel;
                }
                break;
            }
        }
        emit BuyTrade(
            msg.sender,
            tranche,
            totalTrade.frozenQuote,
            version,
            pdLevel,
            orderIndex,
            orderIndex == 0 ? 0 : currentTrade.reservedBase
        );
        if (orderIndex == 0) {
            // Matching ends by completely filling all orders at and below the specified
            // premium-discount level `maxPDLevel`.
            // Find the new best ask beyond that level.
            for (; pdLevel <= PD_LEVEL_COUNT; pdLevel++) {
                if (!asks[version][tranche][pdLevel].isEmpty()) {
                    break;
                }
            }
            bestAsks[version][tranche] = pdLevel;
        }

        require(
            totalTrade.frozenQuote > 0,
            "Nothing can be bought at the given premium-discount level"
        );
        unsettledTrades[msg.sender][tranche][epoch].takerBuy.add(totalTrade);
        _transferQuoteFrom(msg.sender, totalTrade.frozenQuote);
    }

    /// @dev Sell share
    /// @param version Current rebalance version. Revert if it is not the latest version.
    /// @param tranche Tranche of the base asset
    /// @param minPDLevel Minimal premium-discount level accepted
    /// @param estimatedNav Estimated net asset value of the base asset
    /// @param baseAmount Amount of base assets willing to trade
    function _sell(
        uint256 version,
        uint256 tranche,
        uint256 minPDLevel,
        uint256 estimatedNav,
        uint256 baseAmount
    ) internal onlyActive whenNotPaused {
        require(minPDLevel > 0 && minPDLevel <= PD_LEVEL_COUNT, "Invalid premium-discount level");
        require(version == _fundRebalanceSize(), "Invalid version");
        require(estimatedNav > 0, "Zero estimated NAV");

        UnsettledSellTrade memory totalTrade;
        uint256 epoch = endOfEpoch(block.timestamp);

        // Record rebalance version in the first transaction in the epoch
        if (_epochVersions[epoch] == 0) {
            _epochVersions[epoch] = version;
        }

        UnsettledSellTrade memory currentTrade;
        uint256 orderIndex;
        uint256 pdLevel = bestBids[version][tranche];
        for (; pdLevel >= minPDLevel; pdLevel--) {
            uint256 price = pdLevel.mul(PD_TICK).add(PD_START).multiplyDecimal(estimatedNav);
            OrderQueue storage orderQueue = bids[version][tranche][pdLevel];
            orderIndex = orderQueue.head;
            while (orderIndex != 0) {
                Order storage order = orderQueue.list[orderIndex];

                // If the order initiator is no longer qualified for maker,
                // we skip the order and the linked-list-based order queue
                // would never traverse the order again
                if (!isMaker(order.maker)) {
                    orderIndex = order.next;
                    continue;
                }

                // Scope to avoid "stack too deep"
                {
                    // Calculate the current trade assuming that the taker would be completely filled.
                    uint256 makerReserveRatio = getMakerReserveRatio(tranche);
                    currentTrade.frozenBase = baseAmount.sub(totalTrade.frozenBase);
                    currentTrade.reservedQuote = currentTrade
                        .frozenBase
                        .multiplyDecimal(makerReserveRatio)
                        .multiplyDecimal(price);

                    if (currentTrade.reservedQuote < order.fillable) {
                        // Taker is completely filled
                        currentTrade.effectiveBase = currentTrade.frozenBase.multiplyDecimal(
                            pdLevel.mul(PD_TICK).add(PD_START)
                        );
                    } else {
                        // Maker is completely filled. Recalculate the current trade.
                        currentTrade.frozenBase = order.fillable.divideDecimal(price).divideDecimal(
                            makerReserveRatio
                        );
                        currentTrade.effectiveBase = order
                            .fillable
                            .divideDecimal(estimatedNav)
                            .divideDecimal(makerReserveRatio);
                        currentTrade.reservedQuote = order.fillable;
                    }
                }
                totalTrade.frozenBase = totalTrade.frozenBase.add(currentTrade.frozenBase);
                totalTrade.effectiveBase = totalTrade.effectiveBase.add(currentTrade.effectiveBase);
                totalTrade.reservedQuote = totalTrade.reservedQuote.add(currentTrade.reservedQuote);
                unsettledTrades[order.maker][tranche][epoch].makerBuy.add(currentTrade);

                uint256 orderNewFillable = order.fillable.sub(currentTrade.reservedQuote);
                if (orderNewFillable > 0) {
                    // Maker is not completely filled. Matching ends here.
                    order.fillable = orderNewFillable;
                    break;
                } else {
                    // Delete the completely filled maker order.
                    orderIndex = orderQueue.fill(orderIndex);
                }
            }

            orderQueue.updateHead(orderIndex);
            if (orderIndex != 0) {
                // This premium-discount level is not completely filled. Matching ends here.
                if (bestBids[version][tranche] != pdLevel) {
                    bestBids[version][tranche] = pdLevel;
                }
                break;
            }
        }
        emit SellTrade(
            msg.sender,
            tranche,
            totalTrade.frozenBase,
            version,
            pdLevel,
            orderIndex,
            orderIndex == 0 ? 0 : currentTrade.reservedQuote
        );
        if (orderIndex == 0) {
            // Matching ends by completely filling all orders at and above the specified
            // premium-discount level `minPDLevel`.
            // Find the new best bid beyond that level.
            for (; pdLevel > 0; pdLevel--) {
                if (!bids[version][tranche][pdLevel].isEmpty()) {
                    break;
                }
            }
            bestBids[version][tranche] = pdLevel;
        }

        require(
            totalTrade.frozenBase > 0,
            "Nothing can be sold at the given premium-discount level"
        );
        _tradeAvailable(tranche, msg.sender, totalTrade.frozenBase);
        unsettledTrades[msg.sender][tranche][epoch].takerSell.add(totalTrade);
    }

    /// @dev Settle both buy and sell trades of a specified epoch for takers
    /// @param account Taker address
    /// @param tranche Tranche of the base asset
    /// @param estimatedNav Estimated net asset value for the base asset
    /// @param epoch The epoch's end timestamp
    function _settleTaker(
        address account,
        uint256 tranche,
        uint256 estimatedNav,
        uint256 epoch
    ) internal returns (uint256 baseAmount, uint256 quoteAmount) {
        UnsettledTrade storage unsettledTrade = unsettledTrades[account][tranche][epoch];

        // Settle buy trade
        UnsettledBuyTrade memory takerBuy = unsettledTrade.takerBuy;
        if (takerBuy.frozenQuote > 0) {
            (uint256 executionQuote, uint256 executionBase) =
                _buyTradeResult(takerBuy, estimatedNav);
            baseAmount = executionBase;
            quoteAmount = takerBuy.frozenQuote.sub(executionQuote);
            delete unsettledTrade.takerBuy;
        }

        // Settle sell trade
        UnsettledSellTrade memory takerSell = unsettledTrade.takerSell;
        if (takerSell.frozenBase > 0) {
            (uint256 executionQuote, uint256 executionBase) =
                _sellTradeResult(takerSell, estimatedNav);
            quoteAmount = quoteAmount.add(executionQuote);
            baseAmount = baseAmount.add(takerSell.frozenBase.sub(executionBase));
            delete unsettledTrade.takerSell;
        }
    }

    /// @dev Settle both buy and sell trades of a specified epoch for makers
    /// @param account Maker address
    /// @param tranche Tranche of the base asset
    /// @param estimatedNav Estimated net asset value for the base asset
    /// @param epoch The epoch's end timestamp
    function _settleMaker(
        address account,
        uint256 tranche,
        uint256 estimatedNav,
        uint256 epoch
    ) internal returns (uint256 baseAmount, uint256 quoteAmount) {
        UnsettledTrade storage unsettledTrade = unsettledTrades[account][tranche][epoch];

        // Settle buy trade
        UnsettledSellTrade memory makerBuy = unsettledTrade.makerBuy;
        if (makerBuy.frozenBase > 0) {
            (uint256 executionQuote, uint256 executionBase) =
                _sellTradeResult(makerBuy, estimatedNav);
            baseAmount = executionBase;
            quoteAmount = makerBuy.reservedQuote.sub(executionQuote);
            delete unsettledTrade.makerBuy;
        }

        // Settle sell trade
        UnsettledBuyTrade memory makerSell = unsettledTrade.makerSell;
        if (makerSell.frozenQuote > 0) {
            (uint256 executionQuote, uint256 executionBase) =
                _buyTradeResult(makerSell, estimatedNav);
            quoteAmount = quoteAmount.add(executionQuote);
            baseAmount = baseAmount.add(makerSell.reservedBase.sub(executionBase));
            delete unsettledTrade.makerSell;
        }
    }

    /// @dev Calculate the result of an unsettled buy trade with a given NAV
    /// @param buyTrade Buy trade result of this particular epoch
    /// @param nav Net asset value for the base asset
    /// @return executionQuote Real amount of quote asset waiting for settlment
    /// @return executionBase Real amount of base asset waiting for settlment
    function _buyTradeResult(UnsettledBuyTrade memory buyTrade, uint256 nav)
        internal
        pure
        returns (uint256 executionQuote, uint256 executionBase)
    {
        uint256 reservedBase = buyTrade.reservedBase;
        uint256 reservedQuote = reservedBase.multiplyDecimal(nav);
        uint256 effectiveQuote = buyTrade.effectiveQuote;
        if (effectiveQuote < reservedQuote) {
            // Reserved base is enough to execute the trade.
            // nav is always positive here
            return (buyTrade.frozenQuote, effectiveQuote.divideDecimal(nav));
        } else {
            // Reserved base is not enough. The trade is partially executed
            // and a fraction of frozenQuote is returned to the taker.
            return (buyTrade.frozenQuote.mul(reservedQuote).div(effectiveQuote), reservedBase);
        }
    }

    /// @dev Calculate the result of an unsettled sell trade with a given NAV
    /// @param sellTrade Sell trade result of this particular epoch
    /// @param nav Net asset value for the base asset
    /// @return executionQuote Real amount of quote asset waiting for settlment
    /// @return executionBase Real amount of base asset waiting for settlment
    function _sellTradeResult(UnsettledSellTrade memory sellTrade, uint256 nav)
        internal
        pure
        returns (uint256 executionQuote, uint256 executionBase)
    {
        uint256 reservedQuote = sellTrade.reservedQuote;
        uint256 effectiveQuote = sellTrade.effectiveBase.multiplyDecimal(nav);
        if (effectiveQuote < reservedQuote) {
            // Reserved quote is enough to execute the trade.
            return (effectiveQuote, sellTrade.frozenBase);
        } else {
            // Reserved quote is not enough. The trade is partially executed
            // and a fraction of frozenBase is returned to the taker.
            return (reservedQuote, sellTrade.frozenBase.mul(reservedQuote).div(effectiveQuote));
        }
    }

    /// @dev Transfer quote asset to an account. Transfered amount is rounded down.
    /// @param account Recipient address
    /// @param amount Amount to transfer with 18 decimal places
    function _transferQuote(address account, uint256 amount) private {
        uint256 amountToTransfer = amount / _quoteDecimalMultiplier;
        if (amountToTransfer == 0) {
            return;
        }
        IERC20(quoteAssetAddress).safeTransfer(account, amountToTransfer);
    }

    /// @dev Transfer quote asset from an account. Transfered amount is rounded up.
    /// @param account Sender address
    /// @param amount Amount to transfer with 18 decimal places
    function _transferQuoteFrom(address account, uint256 amount) private {
        uint256 amountToTransfer =
            amount.add(_quoteDecimalMultiplier - 1) / _quoteDecimalMultiplier;
        IERC20(quoteAssetAddress).safeTransferFrom(account, address(this), amountToTransfer);
    }

    modifier onlyActive() {
        require(fund.isExchangeActive(block.timestamp), "Exchange is inactive");
        _;
    }
}