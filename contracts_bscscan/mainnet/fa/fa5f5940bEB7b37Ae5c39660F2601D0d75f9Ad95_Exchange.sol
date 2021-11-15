// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../utils/SafeDecimalMath.sol";

import {Order, OrderQueue, LibOrderQueue} from "./LibOrderQueue.sol";
import {
    UnsettledBuyTrade,
    UnsettledSellTrade,
    UnsettledTrade,
    LibUnsettledBuyTrade,
    LibUnsettledSellTrade
} from "./LibUnsettledTrade.sol";

import "./ExchangeRoles.sol";
import "./Staking.sol";

/// @title Tranchess's Exchange Contract
/// @notice A decentralized exchange to match premium-discount orders and clear trades
/// @author Tranchess
contract Exchange is ExchangeRoles, Staking {
    /// @dev Reserved storage slots for future base contract upgrades
    uint256[32] private _reservedSlots;

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

    /// @dev Maker reserves 110% of the asset they want to trade, which would stop
    ///      losses for makers when the net asset values turn out volatile
    uint256 private constant MAKER_RESERVE_RATIO = 1.1e18;

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
        Staking(fund_, chessSchedule_, chessController_, quoteAssetAddress_, guardedLaunchStart_)
    {
        minBidAmount = minBidAmount_;
        minAskAmount = minAskAmount_;
        guardedLaunchMinOrderAmount = guardedLaunchMinOrderAmount_;
        require(quoteDecimals_ <= 18, "Quote asset decimals larger than 18");
        _quoteDecimalMultiplier = 10**(18 - quoteDecimals_);
    }

    /// @notice Return end timestamp of the epoch containing a given timestamp.
    /// @param timestamp Timestamp within a given epoch
    /// @return The closest ending timestamp
    function endOfEpoch(uint256 timestamp) public pure returns (uint256) {
        return (timestamp / EPOCH) * EPOCH + EPOCH;
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
    ) external onlyMaker {
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
        require(version == fund.getRebalanceSize(), "Invalid version");

        _transferQuoteFrom(msg.sender, quoteAmount);

        uint256 index = bids[version][tranche][pdLevel].append(msg.sender, quoteAmount, version);
        if (bestBids[version][tranche] < pdLevel) {
            bestBids[version][tranche] = pdLevel;
        }

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
    ) external onlyMaker {
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
        require(version == fund.getRebalanceSize(), "Invalid version");

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
    ) external {
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
    ) external {
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
    ) internal onlyActive {
        require(maxPDLevel > 0 && maxPDLevel <= PD_LEVEL_COUNT, "Invalid premium-discount level");
        require(version == fund.getRebalanceSize(), "Invalid version");
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

                // Calculate the current trade assuming that the taker would be completely filled.
                currentTrade.frozenQuote = quoteAmount.sub(totalTrade.frozenQuote);
                currentTrade.reservedBase = currentTrade.frozenQuote.mul(MAKER_RESERVE_RATIO).div(
                    price
                );

                if (currentTrade.reservedBase < order.fillable) {
                    // Taker is completely filled.
                    currentTrade.effectiveQuote = currentTrade.frozenQuote.divideDecimal(
                        pdLevel.mul(PD_TICK).add(PD_START)
                    );
                } else {
                    // Maker is completely filled. Recalculate the current trade.
                    currentTrade.frozenQuote = order.fillable.mul(price).div(MAKER_RESERVE_RATIO);
                    currentTrade.effectiveQuote = order.fillable.mul(estimatedNav).div(
                        MAKER_RESERVE_RATIO
                    );
                    currentTrade.reservedBase = order.fillable;
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
        _transferQuoteFrom(msg.sender, totalTrade.frozenQuote);
        unsettledTrades[msg.sender][tranche][epoch].takerBuy.add(totalTrade);
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
    ) internal onlyActive {
        require(minPDLevel > 0 && minPDLevel <= PD_LEVEL_COUNT, "Invalid premium-discount level");
        require(version == fund.getRebalanceSize(), "Invalid version");
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

                currentTrade.frozenBase = baseAmount.sub(totalTrade.frozenBase);
                currentTrade.reservedQuote = currentTrade
                    .frozenBase
                    .multiplyDecimal(MAKER_RESERVE_RATIO)
                    .multiplyDecimal(price);

                if (currentTrade.reservedQuote < order.fillable) {
                    // Taker is completely filled
                    currentTrade.effectiveBase = currentTrade.frozenBase.multiplyDecimal(
                        pdLevel.mul(PD_TICK).add(PD_START)
                    );
                } else {
                    // Maker is completely filled. Recalculate the current trade.
                    currentTrade.frozenBase = order.fillable.divideDecimal(price).divideDecimal(
                        MAKER_RESERVE_RATIO
                    );
                    currentTrade.effectiveBase = order
                        .fillable
                        .divideDecimal(estimatedNav)
                        .divideDecimal(MAKER_RESERVE_RATIO);
                    currentTrade.reservedQuote = order.fillable;
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
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

library SafeDecimalMath {
    using SafeMath for uint256;

    /* Number of decimal places in the representations. */
    uint256 private constant decimals = 18;
    uint256 private constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 private constant UNIT = 10**uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 private constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
        10**uint256(highPrecisionDecimals - decimals);

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y).div(UNIT);
    }

    function multiplyDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y).div(PRECISE_UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    function divideDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(PRECISE_UNIT).div(y);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i) internal pure returns (uint256) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i) internal pure returns (uint256) {
        uint256 quotientTimesTen = i.mul(10).div(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen = quotientTimesTen.add(10);
        }

        return quotientTimesTen.div(10);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, and the max value of
     * uint256 on overflow.
     */
    function saturatingMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        return c / a != b ? type(uint256).max : c;
    }

    function saturatingMultiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return saturatingMul(x, y).div(UNIT);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;

/// @notice A maker order
/// @param prev Index of the previous order at the same premium-discount level,
///             or zero if this is the first one
/// @param next Index of the next order at the same premium-discount level,
///             or zero if this is the last one
/// @param maker Account placing this order
/// @param amount Original amount of the order, which is amount of quote asset with 18 decimal places
///               for a bid order, or amount of base asset for an ask order
/// @param version Rebalance version when the order is placed
/// @param fillable Currently fillable amount
struct Order {
    uint256 prev;
    uint256 next;
    address maker;
    uint256 amount;
    uint256 version;
    uint256 fillable;
}

/// @notice A queue of orders with the same premium-discount level.
///
///         An order queue assigns a unique index to each order and stores the orders in a doubly
///         linked list. Orders can be removed from the queue by cancellation, expiration or trade.
/// @param list Mapping of order index => order
/// @param head Index of the first order in the queue, or zero if the queue is empty
/// @param tail Index of the last order in the queue, or zero if the queue is empty
/// @param counter The total number of orders that have been added to the queue, no matter whether
///                they are still active or not
struct OrderQueue {
    mapping(uint256 => Order) list;
    uint256 head;
    uint256 tail;
    uint256 counter;
}

/// @title Tranchess's Exchange Order Queue Contract
/// @notice Order queue struct and implementation using doubly linked list
/// @author Tranchess
library LibOrderQueue {
    function isEmpty(OrderQueue storage queue) internal view returns (bool) {
        return queue.head == 0;
    }

    /// @notice Append a new order to the queue
    /// @param queue Order queue
    /// @param maker Maker address
    /// @param amount Amount to place in the order with 18 decimal places
    /// @param version Current rebalance version
    /// @return Index of the order in the order queue
    function append(
        OrderQueue storage queue,
        address maker,
        uint256 amount,
        uint256 version
    ) internal returns (uint256) {
        uint256 index = queue.counter + 1;
        queue.counter = index;
        uint256 tail = queue.tail;
        queue.list[index] = Order({
            prev: tail,
            next: 0,
            maker: maker,
            amount: amount,
            version: version,
            fillable: amount
        });
        if (tail == 0) {
            // The queue was empty.
            queue.head = index;
        } else {
            // The queue was not empty.
            queue.list[tail].next = index;
        }
        queue.tail = index;
        return index;
    }

    /// @dev Cancel an order from the queue.
    /// @param queue Order queue
    /// @param index Index of the order to be canceled
    function cancel(OrderQueue storage queue, uint256 index) internal {
        uint256 oldHead = queue.head;
        if (index >= oldHead && oldHead > 0) {
            // The order is still active.
            Order storage order = queue.list[index];
            uint256 prev = order.prev;
            uint256 next = order.next;
            if (prev == 0) {
                // This is the first but not the only order.
                queue.head = next;
            } else {
                queue.list[prev].next = next;
            }
            if (next == 0) {
                // This is the last but not the only order.
                queue.tail = prev;
            } else {
                queue.list[next].prev = prev;
            }
        }
        delete queue.list[index];
    }

    /// @dev Remove an order that is completely filled in matching. Links of the previous
    ///      and next order are not updated here. Caller must call `updateHead` after finishing
    ///      the matching on this queue.
    /// @param queue Order queue
    /// @param index Index of the order to be removed
    /// @return nextIndex Index of the next order, or zero if the removed order is the last one
    function fill(OrderQueue storage queue, uint256 index) internal returns (uint256 nextIndex) {
        nextIndex = queue.list[index].next;
        delete queue.list[index];
    }

    /// @dev Update head and tail of the queue. This function should be called after matching
    ///      a taker order with this order queue and all orders before the new head are either
    ///      completely filled or expired.
    /// @param queue Order queue
    /// @param newHead Index of the first order that is still active now,
    ///                or zero if the queue is empty
    function updateHead(OrderQueue storage queue, uint256 newHead) internal {
        queue.head = newHead;
        if (newHead == 0) {
            queue.tail = 0;
        } else {
            queue.list[newHead].prev = 0;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

/// @notice Unsettled trade of a taker buy order or a maker sell order
/// @param frozenQuote Amount of quote assets from the taker
/// @param effectiveQuote Effective amount of quote assets at zero premium-discount
/// @param reservedBase Reserved amount of base assets from the maker
struct UnsettledBuyTrade {
    uint256 frozenQuote;
    uint256 effectiveQuote;
    uint256 reservedBase;
}

/// @notice Unsettled trade of a taker sell order or a maker buy order
/// @param frozenBase Amount of base assets from the taker
/// @param effectiveBase Effective amount of base assets at zero premium-discount
/// @param reservedQuote Reserved amount of quote assets from the maker
struct UnsettledSellTrade {
    uint256 frozenBase;
    uint256 effectiveBase;
    uint256 reservedQuote;
}

/// @notice Unsettled trades of an account in a single epoch
/// @param takerBuy Trade by taker buy orders
/// @param takerSell Trade by taker sell orders
/// @param makerBuy Trade by maker buy orders
/// @param makerSell Trade by maker sell orders
struct UnsettledTrade {
    UnsettledBuyTrade takerBuy;
    UnsettledSellTrade takerSell;
    UnsettledSellTrade makerBuy;
    UnsettledBuyTrade makerSell;
}

library LibUnsettledBuyTrade {
    using SafeMath for uint256;

    /// @dev Accumulate buy trades
    /// @param self Trade to update
    /// @param other New trade to be added to storage
    function add(UnsettledBuyTrade storage self, UnsettledBuyTrade memory other) internal {
        self.frozenQuote = self.frozenQuote.add(other.frozenQuote);
        self.effectiveQuote = self.effectiveQuote.add(other.effectiveQuote);
        self.reservedBase = self.reservedBase.add(other.reservedBase);
    }
}

library LibUnsettledSellTrade {
    using SafeMath for uint256;

    /// @dev Accumulate sell trades
    /// @param self Trade to update
    /// @param other New trade to be added to storage
    function add(UnsettledSellTrade storage self, UnsettledSellTrade memory other) internal {
        self.frozenBase = self.frozenBase.add(other.frozenBase);
        self.effectiveBase = self.effectiveBase.add(other.effectiveBase);
        self.reservedQuote = self.reservedQuote.add(other.reservedQuote);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IVotingEscrow.sol";

/// @title Tranchess's Exchange Role Contract
/// @notice Exchange role management
/// @author Tranchess
abstract contract ExchangeRoles {
    event MakerApplied(address indexed account, uint256 expiration);

    /// @notice Voting Escrow.
    IVotingEscrow public immutable votingEscrow;

    /// @notice Minimum vote-locked governance token balance required to place maker orders.
    uint256 public immutable makerRequirement;

    /// @dev Mapping of account => maker expiration timestamp
    mapping(address => uint256) internal _makerExpiration;

    constructor(address votingEscrow_, uint256 makerRequirement_) public {
        votingEscrow = IVotingEscrow(votingEscrow_);
        makerRequirement = makerRequirement_;
    }

    // ------------------------------ MAKER ------------------------------------
    /// @notice Functions with this modifer can only be invoked by makers
    modifier onlyMaker() {
        require(isMaker(msg.sender), "Only maker");
        _;
    }

    /// @notice Returns maker expiration timestamp of an account.
    ///         When `makerRequirement` is zero, this function always returns
    ///         an extremely large timestamp (2500-01-01 00:00:00 UTC).
    function makerExpiration(address account) external view returns (uint256) {
        return makerRequirement > 0 ? _makerExpiration[account] : 16725225600;
    }

    /// @notice Verify if the account is an active maker or not
    /// @param account Account address to verify
    /// @return True if the account is an active maker; else returns false
    function isMaker(address account) public view returns (bool) {
        return makerRequirement == 0 || _makerExpiration[account] > block.timestamp;
    }

    /// @notice Apply for maker membership
    function applyForMaker() external {
        require(makerRequirement > 0, "No need to apply for maker");
        // The membership will be valid until the current vote-locked governance
        // token balance drop below the requirement.
        uint256 expiration = votingEscrow.getTimestampDropBelow(msg.sender, makerRequirement);
        _makerExpiration[msg.sender] = expiration;
        emit MakerApplied(msg.sender, expiration);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../utils/SafeDecimalMath.sol";
import "../utils/CoreUtility.sol";

import "../interfaces/IFund.sol";
import "../interfaces/IChessSchedule.sol";
import "../interfaces/ITrancheIndex.sol";
import "../interfaces/IPrimaryMarket.sol";

interface IChessController {
    function getFundRelativeWeight(address account, uint256 timestamp)
        external
        view
        returns (uint256);
}

abstract contract Staking is ITrancheIndex, CoreUtility {
    /// @dev Reserved storage slots for future sibling contract upgrades
    uint256[32] private _reservedSlots;

    using Math for uint256;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    event Deposited(uint256 tranche, address account, uint256 amount);
    event Withdrawn(uint256 tranche, address account, uint256 amount);

    uint256 private constant MAX_ITERATIONS = 500;

    uint256 private constant REWARD_WEIGHT_A = 4;
    uint256 private constant REWARD_WEIGHT_B = 2;
    uint256 private constant REWARD_WEIGHT_M = 3;

    IFund public immutable fund;
    IERC20 private immutable tokenM;
    IERC20 private immutable tokenA;
    IERC20 private immutable tokenB;

    /// @notice The Chess release schedule contract.
    IChessSchedule public immutable chessSchedule;

    uint256 public immutable guardedLaunchStart;

    uint256 private _rate;

    /// @notice The controller contract.
    IChessController public immutable chessController;

    /// @notice Quote asset for the exchange. Each exchange only handles one quote asset
    address public immutable quoteAssetAddress;

    /// @dev Total amount of user shares, i.e. sum of all entries in `_availableBalances` and
    ///      `_lockedBalances`. Note that these values can be smaller than the amount of
    ///      share tokens held by this contract, because shares locked in unsettled trades
    ///      are not included in total supplies or any user's balance.
    uint256[TRANCHE_COUNT] private _totalSupplies;

    /// @dev Rebalance version of `_totalSupplies`.
    uint256 private _totalSupplyVersion;

    /// @dev Amount of shares that can be withdrawn or traded by each user.
    mapping(address => uint256[TRANCHE_COUNT]) private _availableBalances;

    /// @dev Amount of shares that are locked in ask orders.
    mapping(address => uint256[TRANCHE_COUNT]) private _lockedBalances;

    /// @dev Rebalance version mapping for `_availableBalances`.
    mapping(address => uint256) private _balanceVersions;

    /// @dev 1e27 * ∫(rate(t) / totalWeight(t) dt) from the latest rebalance till checkpoint.
    uint256 private _invTotalWeightIntegral;

    /// @dev Final `_invTotalWeightIntegral` before each rebalance.
    ///      These values are accessed in a loop in `_userCheckpoint()` with bounds checking.
    ///      So we store them in a fixed-length array, in order to make compiler-generated
    ///      bounds checking on every access cheaper. The actual length of this array is stored in
    ///      `_historicalIntegralSize` and should be explicitly checked when necessary.
    uint256[65535] private _historicalIntegrals;

    /// @dev Actual length of the `_historicalIntegrals` array, which always equals to the number of
    ///      historical rebalances after `checkpoint()` is called.
    uint256 private _historicalIntegralSize;

    /// @dev Timestamp when checkpoint() is called.
    uint256 private _checkpointTimestamp;

    /// @dev Snapshot of `_invTotalWeightIntegral` per user.
    mapping(address => uint256) private _userIntegrals;

    /// @dev Mapping of account => claimable rewards.
    mapping(address => uint256) private _claimableRewards;

    constructor(
        address fund_,
        address chessSchedule_,
        address chessController_,
        address quoteAssetAddress_,
        uint256 guardedLaunchStart_
    ) public {
        fund = IFund(fund_);
        tokenM = IERC20(IFund(fund_).tokenM());
        tokenA = IERC20(IFund(fund_).tokenA());
        tokenB = IERC20(IFund(fund_).tokenB());
        chessSchedule = IChessSchedule(chessSchedule_);
        chessController = IChessController(chessController_);
        quoteAssetAddress = quoteAssetAddress_;
        _checkpointTimestamp = block.timestamp;
        guardedLaunchStart = guardedLaunchStart_;

        _rate = IChessSchedule(chessSchedule_).getRate(block.timestamp);
    }

    /// @notice Return weight of given balance with respect to rewards.
    /// @param amountM Amount of Token M
    /// @param amountA Amount of Token A
    /// @param amountB Amount of Token B
    /// @return Rewarding weight of the balance
    function rewardWeight(
        uint256 amountM,
        uint256 amountA,
        uint256 amountB
    ) public pure returns (uint256) {
        return
            amountM.mul(REWARD_WEIGHT_M).add(amountA.mul(REWARD_WEIGHT_A)).add(
                amountB.mul(REWARD_WEIGHT_B)
            ) / REWARD_WEIGHT_M;
    }

    function totalSupply(uint256 tranche) external view returns (uint256) {
        uint256 totalSupplyM = _totalSupplies[TRANCHE_M];
        uint256 totalSupplyA = _totalSupplies[TRANCHE_A];
        uint256 totalSupplyB = _totalSupplies[TRANCHE_B];

        uint256 version = _totalSupplyVersion;
        uint256 rebalanceSize = fund.getRebalanceSize();
        if (version < rebalanceSize) {
            (totalSupplyM, totalSupplyA, totalSupplyB) = fund.batchRebalance(
                totalSupplyM,
                totalSupplyA,
                totalSupplyB,
                version,
                rebalanceSize
            );
        }

        if (tranche == TRANCHE_M) {
            return totalSupplyM;
        } else if (tranche == TRANCHE_A) {
            return totalSupplyA;
        } else {
            return totalSupplyB;
        }
    }

    function availableBalanceOf(uint256 tranche, address account) external view returns (uint256) {
        uint256 amountM = _availableBalances[account][TRANCHE_M];
        uint256 amountA = _availableBalances[account][TRANCHE_A];
        uint256 amountB = _availableBalances[account][TRANCHE_B];

        if (tranche == TRANCHE_M) {
            if (amountM == 0 && amountA == 0 && amountB == 0) return 0;
        } else if (tranche == TRANCHE_A) {
            if (amountA == 0) return 0;
        } else {
            if (amountB == 0) return 0;
        }

        uint256 version = _balanceVersions[account];
        uint256 rebalanceSize = fund.getRebalanceSize();
        if (version < rebalanceSize) {
            (amountM, amountA, amountB) = fund.batchRebalance(
                amountM,
                amountA,
                amountB,
                version,
                rebalanceSize
            );
        }

        if (tranche == TRANCHE_M) {
            return amountM;
        } else if (tranche == TRANCHE_A) {
            return amountA;
        } else {
            return amountB;
        }
    }

    function lockedBalanceOf(uint256 tranche, address account) external view returns (uint256) {
        uint256 amountM = _lockedBalances[account][TRANCHE_M];
        uint256 amountA = _lockedBalances[account][TRANCHE_A];
        uint256 amountB = _lockedBalances[account][TRANCHE_B];

        if (tranche == TRANCHE_M) {
            if (amountM == 0 && amountA == 0 && amountB == 0) return 0;
        } else if (tranche == TRANCHE_A) {
            if (amountA == 0) return 0;
        } else {
            if (amountB == 0) return 0;
        }

        uint256 version = _balanceVersions[account];
        uint256 rebalanceSize = fund.getRebalanceSize();
        if (version < rebalanceSize) {
            (amountM, amountA, amountB) = fund.batchRebalance(
                amountM,
                amountA,
                amountB,
                version,
                rebalanceSize
            );
        }

        if (tranche == TRANCHE_M) {
            return amountM;
        } else if (tranche == TRANCHE_A) {
            return amountA;
        } else {
            return amountB;
        }
    }

    function balanceVersion(address account) external view returns (uint256) {
        return _balanceVersions[account];
    }

    /// @dev Deposit to get rewards
    /// @param tranche Tranche of the share
    /// @param amount The amount to deposit
    function deposit(uint256 tranche, uint256 amount) public {
        uint256 rebalanceSize = fund.getRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(msg.sender, rebalanceSize);
        if (tranche == TRANCHE_M) {
            tokenM.safeTransferFrom(msg.sender, address(this), amount);
        } else if (tranche == TRANCHE_A) {
            tokenA.safeTransferFrom(msg.sender, address(this), amount);
        } else {
            tokenB.safeTransferFrom(msg.sender, address(this), amount);
        }
        _availableBalances[msg.sender][tranche] = _availableBalances[msg.sender][tranche].add(
            amount
        );
        _totalSupplies[tranche] = _totalSupplies[tranche].add(amount);

        emit Deposited(tranche, msg.sender, amount);
    }

    /// @dev Claim settled Token M from the primary market and deposit to get rewards
    /// @param primaryMarket The primary market to claim shares from
    function claimAndDeposit(address primaryMarket) external {
        (uint256 createdShares, ) = IPrimaryMarket(primaryMarket).claim(msg.sender);
        deposit(TRANCHE_M, createdShares);
    }

    /// @dev Withdraw
    /// @param tranche Tranche of the share
    /// @param amount The amount to deposit
    function withdraw(uint256 tranche, uint256 amount) external {
        uint256 rebalanceSize = fund.getRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(msg.sender, rebalanceSize);
        _availableBalances[msg.sender][tranche] = _availableBalances[msg.sender][tranche].sub(
            amount,
            "Insufficient balance to withdraw"
        );
        _totalSupplies[tranche] = _totalSupplies[tranche].sub(amount);
        if (tranche == TRANCHE_M) {
            tokenM.safeTransfer(msg.sender, amount);
        } else if (tranche == TRANCHE_A) {
            tokenA.safeTransfer(msg.sender, amount);
        } else {
            tokenB.safeTransfer(msg.sender, amount);
        }

        emit Withdrawn(tranche, msg.sender, amount);
    }

    /// @notice Transform share balance to a given rebalance version, or to the latest version
    ///         if `targetVersion` is zero.
    /// @param account Account of the balance to rebalance
    /// @param targetVersion The target rebalance version, or zero for the latest version
    function refreshBalance(address account, uint256 targetVersion) external {
        uint256 rebalanceSize = fund.getRebalanceSize();
        if (targetVersion == 0) {
            targetVersion = rebalanceSize;
        } else {
            require(targetVersion <= rebalanceSize, "Target version out of bound");
        }
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, targetVersion);
    }

    /// @notice Return claimable rewards of an account till now.
    ///
    ///         This function should be call as a "view" function off-chain to get
    ///         the return value, e.g. using `contract.claimableRewards.call(account)` in web3
    ///         or `contract.callStatic.claimableRewards(account)` in ethers.js.
    /// @param account Address of an account
    /// @return Amount of claimable rewards
    function claimableRewards(address account) external returns (uint256) {
        uint256 rebalanceSize = fund.getRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, rebalanceSize);
        return _claimableRewards[account];
    }

    /// @notice Claim the rewards for an account.
    /// @param account Account to claim its rewards
    function claimRewards(address account) external {
        require(
            block.timestamp >= guardedLaunchStart + 15 days,
            "Cannot claim during guarded launch"
        );
        uint256 rebalanceSize = fund.getRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, rebalanceSize);
        _claim(account);
    }

    /// @dev Transfer shares from the sender to the contract internally
    /// @param tranche Tranche of the share
    /// @param sender Sender address
    /// @param amount The amount to transfer
    function _tradeAvailable(
        uint256 tranche,
        address sender,
        uint256 amount
    ) internal {
        uint256 rebalanceSize = fund.getRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(sender, rebalanceSize);
        _availableBalances[sender][tranche] = _availableBalances[sender][tranche].sub(amount);
        _totalSupplies[tranche] = _totalSupplies[tranche].sub(amount);
    }

    function _rebalanceAndClearTrade(
        address account,
        uint256 amountM,
        uint256 amountA,
        uint256 amountB,
        uint256 amountVersion
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rebalanceSize = fund.getRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, rebalanceSize);
        if (amountVersion < rebalanceSize) {
            (amountM, amountA, amountB) = fund.batchRebalance(
                amountM,
                amountA,
                amountB,
                amountVersion,
                rebalanceSize
            );
        }
        uint256[TRANCHE_COUNT] storage available = _availableBalances[account];
        if (amountM > 0) {
            available[TRANCHE_M] = available[TRANCHE_M].add(amountM);
            _totalSupplies[TRANCHE_M] = _totalSupplies[TRANCHE_M].add(amountM);
        }
        if (amountA > 0) {
            available[TRANCHE_A] = available[TRANCHE_A].add(amountA);
            _totalSupplies[TRANCHE_A] = _totalSupplies[TRANCHE_A].add(amountA);
        }
        if (amountB > 0) {
            available[TRANCHE_B] = available[TRANCHE_B].add(amountB);
            _totalSupplies[TRANCHE_B] = _totalSupplies[TRANCHE_B].add(amountB);
        }
        return (amountM, amountA, amountB);
    }

    function _lock(
        uint256 tranche,
        address account,
        uint256 amount
    ) internal {
        uint256 rebalanceSize = fund.getRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, rebalanceSize);
        _availableBalances[account][tranche] = _availableBalances[account][tranche].sub(
            amount,
            "Insufficient balance to lock"
        );
        _lockedBalances[account][tranche] = _lockedBalances[account][tranche].add(amount);
    }

    function _rebalanceAndUnlock(
        address account,
        uint256 amountM,
        uint256 amountA,
        uint256 amountB,
        uint256 amountVersion
    ) internal {
        uint256 rebalanceSize = fund.getRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, rebalanceSize);
        if (amountVersion < rebalanceSize) {
            (amountM, amountA, amountB) = fund.batchRebalance(
                amountM,
                amountA,
                amountB,
                amountVersion,
                rebalanceSize
            );
        }
        uint256[TRANCHE_COUNT] storage available = _availableBalances[account];
        uint256[TRANCHE_COUNT] storage locked = _lockedBalances[account];
        if (amountM > 0) {
            available[TRANCHE_M] = available[TRANCHE_M].add(amountM);
            locked[TRANCHE_M] = locked[TRANCHE_M].sub(amountM);
        }
        if (amountA > 0) {
            available[TRANCHE_A] = available[TRANCHE_A].add(amountA);
            locked[TRANCHE_A] = locked[TRANCHE_A].sub(amountA);
        }
        if (amountB > 0) {
            available[TRANCHE_B] = available[TRANCHE_B].add(amountB);
            locked[TRANCHE_B] = locked[TRANCHE_B].sub(amountB);
        }
    }

    function _tradeLocked(
        uint256 tranche,
        address account,
        uint256 amount
    ) internal {
        uint256 rebalanceSize = fund.getRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, rebalanceSize);
        _lockedBalances[account][tranche] = _lockedBalances[account][tranche].sub(amount);
        _totalSupplies[tranche] = _totalSupplies[tranche].sub(amount);
    }

    /// @dev Transfer claimable rewards to an account. Rewards since the last user checkpoint
    ///      is not included. This function should always be called after `_userCheckpoint()`,
    ///      in order for the user to get all rewards till now.
    /// @param account Address of the account
    function _claim(address account) internal {
        chessSchedule.mint(account, _claimableRewards[account]);
        _claimableRewards[account] = 0;
    }

    /// @dev Transform total supplies to the latest rebalance version and make a global reward checkpoint.
    /// @param rebalanceSize The number of existing rebalances. It must be the same as
    ///                       `fund.getRebalanceSize()`.
    function _checkpoint(uint256 rebalanceSize) private {
        uint256 timestamp = _checkpointTimestamp;
        if (timestamp >= block.timestamp) {
            return;
        }

        uint256 integral = _invTotalWeightIntegral;
        uint256 endWeek = _endOfWeek(timestamp);
        uint256 weeklyPercentage =
            chessController.getFundRelativeWeight(address(this), endWeek - 1 weeks);
        uint256 version = _totalSupplyVersion;
        uint256 rebalanceTimestamp;
        if (version < rebalanceSize) {
            rebalanceTimestamp = fund.getRebalanceTimestamp(version);
        } else {
            rebalanceTimestamp = type(uint256).max;
        }
        uint256 rate = _rate;
        uint256 totalSupplyM = _totalSupplies[TRANCHE_M];
        uint256 totalSupplyA = _totalSupplies[TRANCHE_A];
        uint256 totalSupplyB = _totalSupplies[TRANCHE_B];
        uint256 weight = rewardWeight(totalSupplyM, totalSupplyA, totalSupplyB);
        uint256 timestamp_ = timestamp; // avoid stack too deep

        for (uint256 i = 0; i < MAX_ITERATIONS && timestamp_ < block.timestamp; i++) {
            uint256 endTimestamp = rebalanceTimestamp.min(endWeek).min(block.timestamp);

            if (weight > 0) {
                integral = integral.add(
                    rate
                        .mul(endTimestamp.sub(timestamp_))
                        .multiplyDecimal(weeklyPercentage)
                        .divideDecimalPrecise(weight)
                );
            }

            if (endTimestamp == rebalanceTimestamp) {
                uint256 oldSize = _historicalIntegralSize;
                _historicalIntegrals[oldSize] = integral;
                _historicalIntegralSize = oldSize + 1;

                integral = 0;
                (totalSupplyM, totalSupplyA, totalSupplyB) = fund.doRebalance(
                    totalSupplyM,
                    totalSupplyA,
                    totalSupplyB,
                    version
                );

                version++;
                weight = rewardWeight(totalSupplyM, totalSupplyA, totalSupplyB);

                if (version < rebalanceSize) {
                    rebalanceTimestamp = fund.getRebalanceTimestamp(version);
                } else {
                    rebalanceTimestamp = type(uint256).max;
                }
            }
            if (endTimestamp == endWeek) {
                rate = chessSchedule.getRate(endWeek);
                weeklyPercentage = chessController.getFundRelativeWeight(address(this), endWeek);
                endWeek += 1 weeks;
            }

            timestamp_ = endTimestamp;
        }

        _checkpointTimestamp = block.timestamp;
        _invTotalWeightIntegral = integral;
        if (_rate != rate) {
            _rate = rate;
        }
        if (_totalSupplyVersion != rebalanceSize) {
            _totalSupplies[TRANCHE_M] = totalSupplyM;
            _totalSupplies[TRANCHE_A] = totalSupplyA;
            _totalSupplies[TRANCHE_B] = totalSupplyB;
            _totalSupplyVersion = rebalanceSize;
        }
    }

    /// @dev Transform a user's balance to a given rebalance version and update this user's rewards.
    ///
    ///      In most cases, the target version is the latest version and this function cumulates
    ///      rewards till now. When this function is called from `refreshBalance()`,
    ///      `targetVersion` can be an older version, in which case rewards are cumulated till
    ///      the end of that version (i.e. timestamp of the transaction triggering the rebalance
    ///      with index `targetVersion`).
    ///
    ///      This function should always be called after `_checkpoint()` is called, so that
    ///      the global reward checkpoint is guarenteed up to date.
    /// @param account Account to update
    /// @param targetVersion The target rebalance version
    function _userCheckpoint(address account, uint256 targetVersion) private {
        uint256 oldVersion = _balanceVersions[account];
        if (oldVersion > targetVersion) {
            return;
        }
        uint256 userIntegral = _userIntegrals[account];
        uint256 integral;
        // This scope is to avoid the "stack too deep" error.
        {
            // We assume that this function is always called immediately after `_checkpoint()`,
            // which guarantees that `_historicalIntegralSize` equals to the number of historical
            // rebalances.
            uint256 rebalanceSize = _historicalIntegralSize;
            integral = targetVersion == rebalanceSize
                ? _invTotalWeightIntegral
                : _historicalIntegrals[targetVersion];
        }
        if (userIntegral == integral && oldVersion == targetVersion) {
            // Return immediately when the user's rewards have already been updated to
            // the target version.
            return;
        }

        uint256[TRANCHE_COUNT] storage available = _availableBalances[account];
        uint256[TRANCHE_COUNT] storage locked = _lockedBalances[account];
        uint256 availableM = available[TRANCHE_M];
        uint256 availableA = available[TRANCHE_A];
        uint256 availableB = available[TRANCHE_B];
        uint256 lockedM = locked[TRANCHE_M];
        uint256 lockedA = locked[TRANCHE_A];
        uint256 lockedB = locked[TRANCHE_B];
        uint256 rewards = _claimableRewards[account];
        for (uint256 i = oldVersion; i < targetVersion; i++) {
            uint256 weight =
                rewardWeight(
                    availableM.add(lockedM),
                    availableA.add(lockedA),
                    availableB.add(lockedB)
                );
            rewards = rewards.add(
                weight.multiplyDecimalPrecise(_historicalIntegrals[i].sub(userIntegral))
            );
            if (availableM != 0 || availableA != 0 || availableB != 0) {
                (availableM, availableA, availableB) = fund.doRebalance(
                    availableM,
                    availableA,
                    availableB,
                    i
                );
            }
            if (lockedM != 0 || lockedA != 0 || lockedB != 0) {
                (lockedM, lockedA, lockedB) = fund.doRebalance(lockedM, lockedA, lockedB, i);
            }
            userIntegral = 0;
        }
        uint256 weight =
            rewardWeight(availableM.add(lockedM), availableA.add(lockedA), availableB.add(lockedB));
        rewards = rewards.add(weight.multiplyDecimalPrecise(integral.sub(userIntegral)));
        address account_ = account; // Fix the "stack too deep" error
        _claimableRewards[account_] = rewards;
        _userIntegrals[account_] = integral;

        if (oldVersion < targetVersion) {
            if (available[TRANCHE_M] != availableM) {
                available[TRANCHE_M] = availableM;
            }
            if (available[TRANCHE_A] != availableA) {
                available[TRANCHE_A] = availableA;
            }
            if (available[TRANCHE_B] != availableB) {
                available[TRANCHE_B] = availableB;
            }
            if (locked[TRANCHE_M] != lockedM) {
                locked[TRANCHE_M] = lockedM;
            }
            if (locked[TRANCHE_A] != lockedA) {
                locked[TRANCHE_A] = lockedA;
            }
            if (locked[TRANCHE_B] != lockedB) {
                locked[TRANCHE_B] = lockedB;
            }
            _balanceVersions[account_] = targetVersion;
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
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

interface IVotingEscrow {
    struct LockedBalance {
        uint256 amount;
        uint256 unlockTime;
    }

    function token() external view returns (address);

    function maxTime() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOfAtTimestamp(address account, uint256 timestamp)
        external
        view
        returns (uint256);

    function getTimestampDropBelow(address account, uint256 threshold)
        external
        view
        returns (uint256);

    function getLockedBalance(address account) external view returns (LockedBalance memory);
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
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

abstract contract CoreUtility {
    using SafeMath for uint256;

    /// @dev UTC time of a day when the fund settles.
    uint256 internal constant SETTLEMENT_TIME = 14 hours;

    /// @dev Return end timestamp of the trading week containing a given timestamp.
    ///
    ///      A trading week starts at UTC time `SETTLEMENT_TIME` on a Thursday (inclusive)
    ///      and ends at the same time of the next Thursday (exclusive).
    /// @param timestamp The given timestamp
    /// @return End timestamp of the trading week.
    function _endOfWeek(uint256 timestamp) internal pure returns (uint256) {
        return ((timestamp.add(1 weeks) - SETTLEMENT_TIME) / 1 weeks) * 1 weeks + SETTLEMENT_TIME;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "./ITwapOracle.sol";

interface IFund {
    /// @notice A linear transformation matrix that represents a rebalance.
    ///
    ///         ```
    ///             [ ratioM          0        0 ]
    ///         R = [ ratioA2M  ratioAB        0 ]
    ///             [ ratioB2M        0  ratioAB ]
    ///         ```
    ///
    ///         Amounts of the three tranches `m`, `a` and `b` can be rebalanced by multiplying the matrix:
    ///
    ///         ```
    ///         [ m', a', b' ] = [ m, a, b ] * R
    ///         ```
    struct Rebalance {
        uint256 ratioM;
        uint256 ratioA2M;
        uint256 ratioB2M;
        uint256 ratioAB;
        uint256 timestamp;
    }

    function trancheWeights() external pure returns (uint256 weightA, uint256 weightB);

    function tokenUnderlying() external view returns (address);

    function tokenM() external view returns (address);

    function tokenA() external view returns (address);

    function tokenB() external view returns (address);

    function underlyingDecimalMultiplier() external view returns (uint256);

    function twapOracle() external view returns (ITwapOracle);

    function feeCollector() external view returns (address);

    function endOfDay(uint256 timestamp) external pure returns (uint256);

    function shareTotalSupply(uint256 tranche) external view returns (uint256);

    function shareBalanceOf(uint256 tranche, address account) external view returns (uint256);

    function allShareBalanceOf(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function shareBalanceVersion(address account) external view returns (uint256);

    function shareAllowance(
        uint256 tranche,
        address owner,
        address spender
    ) external view returns (uint256);

    function shareAllowanceVersion(address owner, address spender) external view returns (uint256);

    function getRebalanceSize() external view returns (uint256);

    function getRebalance(uint256 index) external view returns (Rebalance memory);

    function getRebalanceTimestamp(uint256 index) external view returns (uint256);

    function currentDay() external view returns (uint256);

    function fundActivityStartTime() external view returns (uint256);

    function exchangeActivityStartTime() external view returns (uint256);

    function isFundActive(uint256 timestamp) external view returns (bool);

    function isPrimaryMarketActive(address primaryMarket, uint256 timestamp)
        external
        view
        returns (bool);

    function isExchangeActive(uint256 timestamp) external view returns (bool);

    function getTotalShares() external view returns (uint256);

    function extrapolateNav(uint256 timestamp, uint256 price)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function calculateNavB(uint256 navM, uint256 navA) external pure returns (uint256);

    function doRebalance(
        uint256 amountM,
        uint256 amountA,
        uint256 amountB,
        uint256 index
    )
        external
        view
        returns (
            uint256 newAmountM,
            uint256 newAmountA,
            uint256 newAmountB
        );

    function batchRebalance(
        uint256 amountM,
        uint256 amountA,
        uint256 amountB,
        uint256 fromIndex,
        uint256 toIndex
    )
        external
        view
        returns (
            uint256 newAmountM,
            uint256 newAmountA,
            uint256 newAmountB
        );

    function refreshBalance(address account, uint256 targetVersion) external;

    function refreshAllowance(
        address owner,
        address spender,
        uint256 targetVersion
    ) external;

    function mint(
        uint256 tranche,
        address account,
        uint256 amount
    ) external;

    function burn(
        uint256 tranche,
        address account,
        uint256 amount
    ) external;

    function transfer(
        uint256 tranche,
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function transferFrom(
        uint256 tranche,
        address spender,
        address sender,
        address recipient,
        uint256 amount
    ) external returns (uint256 newAllowance);

    function increaseAllowance(
        uint256 tranche,
        address sender,
        address spender,
        uint256 addedValue
    ) external returns (uint256 newAllowance);

    function decreaseAllowance(
        uint256 tranche,
        address sender,
        address spender,
        uint256 subtractedValue
    ) external returns (uint256 newAllowance);

    function approve(
        uint256 tranche,
        address owner,
        address spender,
        uint256 amount
    ) external;

    event RebalanceTriggered(
        uint256 indexed index,
        uint256 indexed day,
        uint256 ratioM,
        uint256 ratioA2M,
        uint256 ratioB2M,
        uint256 ratioAB
    );
    event Settled(uint256 indexed day, uint256 navM, uint256 navA, uint256 navB);
    event InterestRateUpdated(uint256 baseInterestRate, uint256 floatingInterestRate);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;

interface IChessSchedule {
    function getRate(uint256 timestamp) external view returns (uint256);

    function mint(address account, uint256 amount) external;

    function addMinter(address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;

/// @notice Amounts of Token M, A and B are sometimes stored in a `uint256[3]` array. This contract
///         defines index of each tranche in this array.
///
///         Solidity does not allow constants to be defined in interfaces. So this contract follows
///         the naming convention of interfaces but is implemented as an `abstract contract`.
abstract contract ITrancheIndex {
    uint256 internal constant TRANCHE_M = 0;
    uint256 internal constant TRANCHE_A = 1;
    uint256 internal constant TRANCHE_B = 2;

    uint256 internal constant TRANCHE_COUNT = 3;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;

interface IPrimaryMarket {
    function claim(address account)
        external
        returns (uint256 createdShares, uint256 redeemedUnderlying);

    function settle(
        uint256 day,
        uint256 fundTotalShares,
        uint256 fundUnderlying,
        uint256 underlyingPrice,
        uint256 previousNav
    )
        external
        returns (
            uint256 sharesToMint,
            uint256 sharesToBurn,
            uint256 creationUnderlying,
            uint256 redemptionUnderlying,
            uint256 fee
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;

interface ITwapOracle {
    function getTwap(uint256 timestamp) external view returns (uint256);
}

