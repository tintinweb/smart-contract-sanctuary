pragma solidity ^0.5.0;

import "./EpochTokenLocker.sol";
import "@gnosis.pm/solidity-data-structures/contracts/libraries/IdToAddressBiMap.sol";
import "@gnosis.pm/solidity-data-structures/contracts/libraries/IterableAppendOnlySet.sol";
import "@gnosis.pm/owl-token/contracts/5/TokenOWL.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "./libraries/TokenConservation.sol";

/** @title BatchExchange - A decentralized exchange for any ERC20 token as a multi-token batch
 *  auction with uniform clearing prices.
 *  For more information visit: <https://github.com/gnosis/dex-contracts>
 *  @author @gnosis/dfusion-team <https://github.com/orgs/gnosis/teams/dfusion-team/members>
 */
contract BatchExchange is Ownable, EpochTokenLocker {
    using SafeCast for uint256;
    using SafeMath for uint128;
    using BytesLib for bytes32;
    using BytesLib for bytes;
    using TokenConservation for int256[];
    using TokenConservation for uint16[];
    using IterableAppendOnlySet for IterableAppendOnlySet.Data;

    /** @dev Maximum number of touched orders in auction (used in submitSolution) */
    uint256 public constant MAX_TOUCHED_ORDERS = 30;

    /** @dev minimum allowed value (in WEI) of any prices or executed trade amounts */
    uint128 public constant AMOUNT_MINIMUM = 10**4;

    /** @dev Numerator or denominator used in orders, which do not track its usedAmount*/
    uint128 public constant UNLIMITED_ORDER_AMOUNT = uint128(-1);

    /** Corresponds to percentage that competing solution must improve on current
     * (p = IMPROVEMENT_DENOMINATOR + 1 / IMPROVEMENT_DENOMINATOR)
     */
    uint256 public constant IMPROVEMENT_DENOMINATOR = 100; // 1%

    /** @dev The number of bytes a single auction element is serialized into */
    uint128 public constant ENCODED_AUCTION_ELEMENT_WIDTH = 112;

    /** @dev maximum number of tokens that can be listed for exchange */
    // solhint-disable-next-line var-name-mixedcase
    uint256 public MAX_TOKENS;

    /** @dev A fixed integer used to evaluate fees as a fraction of trade execution 1/feeDenominator */
    uint128 public feeDenominator = 1000;

    /** @dev Current number of tokens listed/available for exchange */
    uint16 public numTokens;

    /** @dev The feeToken of the exchange will be the OWL Token */
    TokenOWL public feeToken;

    /** @dev mapping of type userAddress -> List[Order] where all the user's orders are stored */
    mapping(address => Order[]) public orders;

    /** @dev mapping of type tokenId -> curentPrice of tokenId */
    mapping(uint16 => uint128) public currentPrices;

    /** @dev Sufficient information for current winning auction solution */
    SolutionData public latestSolution;

    // Iterable set of all users, required to collect auction information
    IterableAppendOnlySet.Data private allUsers;
    IdToAddressBiMap.Data private registeredTokens;

    struct Order {
        uint16 buyToken;
        uint16 sellToken;
        uint32 validFrom; // order is valid from auction collection period: validFrom inclusive
        uint32 validUntil; // order is valid till auction collection period: validUntil inclusive
        uint128 priceNumerator;
        uint128 priceDenominator;
        uint128 usedAmount; // remainingAmount = priceDenominator - usedAmount
    }

    struct TradeData {
        address owner;
        uint128 volume;
        uint16 orderId;
    }

    struct SolutionData {
        uint32 batchId;
        TradeData[] trades;
        uint16[] tokenIdsForPrice;
        address solutionSubmitter;
        uint256 feeReward;
        uint256 objectiveValue;
    }

    event OrderPlacement(
        address indexed owner,
        uint16 index,
        uint16 indexed buyToken,
        uint16 indexed sellToken,
        uint32 validFrom,
        uint32 validUntil,
        uint128 priceNumerator,
        uint128 priceDenominator
    );

    event TokenListing(address token, uint16 id);

    /** @dev Event emitted when an order is cancelled but still valid in the batch that is
     * currently being solved. It remains in storage but will not be tradable in any future
     * batch to be solved.
     */
    event OrderCancellation(address indexed owner, uint16 id);

    /** @dev Event emitted when an order is removed from storage.
     */
    event OrderDeletion(address indexed owner, uint16 id);

    /** @dev Event emitted when a new trade is settled
     */
    event Trade(
        address indexed owner,
        uint16 indexed orderId,
        uint16 indexed sellToken,
        // Solidity only supports three indexed arguments
        uint16 buyToken,
        uint128 executedSellAmount,
        uint128 executedBuyAmount
    );

    /** @dev Event emitted when an already exectued trade gets reverted
     */
    event TradeReversion(
        address indexed owner,
        uint16 indexed orderId,
        uint16 indexed sellToken,
        // Solidity only supports three indexed arguments
        uint16 buyToken,
        uint128 executedSellAmount,
        uint128 executedBuyAmount
    );

    /** @dev Event emitted for each solution that is submitted
     */
    event SolutionSubmission(
        address indexed submitter,
        uint256 utility,
        uint256 disregardedUtility,
        uint256 burntFees,
        uint256 lastAuctionBurntFees,
        uint128[] prices,
        uint16[] tokenIdsForPrice
    );

    /** @dev Constructor determines exchange parameters
     * @param maxTokens The maximum number of tokens that can be listed.
     * @param _feeToken Address of ERC20 fee token.
     */
    constructor(uint256 maxTokens, address _feeToken) public {
        // All solutions for the batches must have normalized prices. The following line sets the
        // price of OWL to 10**18 for all solutions and hence enforces a normalization.
        currentPrices[0] = 1 ether;
        MAX_TOKENS = maxTokens;
        feeToken = TokenOWL(_feeToken);
        // The burn functionallity of OWL requires an approval.
        // In the following line the approval is set for all future burn calls.
        feeToken.approve(address(this), uint256(-1));
        addToken(_feeToken); // feeToken will always have the token index 0
    }

    /** @dev Used to list a new token on the contract: Hence, making it available for exchange in an auction.
     * @param token ERC20 token to be listed.
     *
     * Requirements:
     * - `maxTokens` has not already been reached
     * - `token` has not already been added
     */
    function addToken(address token) public onlyOwner {
        require(numTokens < MAX_TOKENS, "Max tokens reached");
        require(IdToAddressBiMap.insert(registeredTokens, numTokens, token), "Token already registered");
        emit TokenListing(token, numTokens);
        numTokens++;
    }

    /** @dev Used to set new fee denominator value.
     * @param value fee denominator value.
     */
    function setFeeDenominator(uint128 value) public onlyOwner {
        feeDenominator = value;
    }

    /** @dev A user facing function used to place limit sell orders in auction with expiry defined by batchId
     * @param buyToken id of token to be bought
     * @param sellToken id of token to be sold
     * @param validUntil batchId representing order's expiry
     * @param buyAmount relative minimum amount of requested buy amount
     * @param sellAmount maximum amount of sell token to be exchanged
     * @return orderId defined as the index in user's order array
     *
     * Emits an {OrderPlacement} event with all relevant order details.
     */
    function placeOrder(
        uint16 buyToken,
        uint16 sellToken,
        uint32 validUntil,
        uint128 buyAmount,
        uint128 sellAmount
    ) public returns (uint256) {
        return placeOrderInternal(buyToken, sellToken, getCurrentBatchId(), validUntil, buyAmount, sellAmount);
    }

    /** @dev A user facing function used to place limit sell orders in auction with expiry defined by batchId
     * Note that parameters are passed as arrays and the indices correspond to each order.
     * @param buyTokens ids of tokens to be bought
     * @param sellTokens ids of tokens to be sold
     * @param validFroms batchIds representing order's validity start time
     * @param validUntils batchIds representing order's expiry
     * @param buyAmounts relative minimum amount of requested buy amounts
     * @param sellAmounts maximum amounts of sell token to be exchanged
     * @return `orderIds` an array of indices in which `msg.sender`'s orders are included
     *
     * Emits an {OrderPlacement} event with all relevant order details.
     */
    function placeValidFromOrders(
        uint16[] memory buyTokens,
        uint16[] memory sellTokens,
        uint32[] memory validFroms,
        uint32[] memory validUntils,
        uint128[] memory buyAmounts,
        uint128[] memory sellAmounts
    ) public returns (uint16[] memory orderIds) {
        orderIds = new uint16[](buyTokens.length);
        for (uint256 i = 0; i < buyTokens.length; i++) {
            orderIds[i] = placeOrderInternal(
                buyTokens[i],
                sellTokens[i],
                validFroms[i],
                validUntils[i],
                buyAmounts[i],
                sellAmounts[i]
            );
        }
    }

    /** @dev a user facing function used to cancel orders. If the order is valid for the batch that is currently
     * being solved, it sets order expiry to that batchId. Otherwise it removes it from storage. Can be called
     * multiple times (e.g. to eventually free storage once order is expired).
     *
     * @param orderIds referencing the indices of user's orders to be cancelled
     *
     * Emits an {OrderCancellation} or {OrderDeletion} with sender's address and orderId
     */
    function cancelOrders(uint16[] memory orderIds) public {
        uint32 batchIdBeingSolved = getCurrentBatchId() - 1;
        for (uint16 i = 0; i < orderIds.length; i++) {
            if (!checkOrderValidity(orders[msg.sender][orderIds[i]], batchIdBeingSolved)) {
                delete orders[msg.sender][orderIds[i]];
                emit OrderDeletion(msg.sender, orderIds[i]);
            } else {
                orders[msg.sender][orderIds[i]].validUntil = batchIdBeingSolved;
                emit OrderCancellation(msg.sender, orderIds[i]);
            }
        }
    }

    /** @dev A user facing wrapper to cancel and place new orders in the same transaction.
     * @param cancellations indices of orders to be cancelled
     * @param buyTokens ids of tokens to be bought in new orders
     * @param sellTokens ids of tokens to be sold in new orders
     * @param validFroms batchIds representing order's validity start time in new orders
     * @param validUntils batchIds represnnting order's expiry in new orders
     * @param buyAmounts relative minimum amount of requested buy amounts in new orders
     * @param sellAmounts maximum amounts of sell token to be exchanged in new orders
     * @return an array of indices in which `msg.sender`'s new orders are included
     *
     * Emits {OrderCancellation} events for all cancelled orders and {OrderPlacement} events with relevant new order details.
     */
    function replaceOrders(
        uint16[] memory cancellations,
        uint16[] memory buyTokens,
        uint16[] memory sellTokens,
        uint32[] memory validFroms,
        uint32[] memory validUntils,
        uint128[] memory buyAmounts,
        uint128[] memory sellAmounts
    ) public returns (uint16[] memory) {
        cancelOrders(cancellations);
        return placeValidFromOrders(buyTokens, sellTokens, validFroms, validUntils, buyAmounts, sellAmounts);
    }

    /** @dev a solver facing function called for auction settlement
     * @param batchId index of auction solution is referring to
     * @param owners array of addresses corresponding to touched orders
     * @param orderIds array of order indices used in parallel with owners to identify touched order
     * @param buyVolumes executed buy amounts for each order identified by index of owner-orderId arrays
     * @param prices list of prices for touched tokens indexed by next parameter
     * @param tokenIdsForPrice price[i] is the price for the token with tokenID tokenIdsForPrice[i]
     * @return the computed objective value of the solution
     *
     * Requirements:
     * - Solutions for this `batchId` are currently being accepted.
     * - Claimed objetive value is a great enough improvement on the current winning solution
     * - Fee Token price is non-zero
     * - `tokenIdsForPrice` is sorted.
     * - Number of touched orders does not exceed `MAX_TOUCHED_ORDERS`.
     * - Each touched order is valid at current `batchId`.
     * - Each touched order's `executedSellAmount` does not exceed its remaining amount.
     * - Limit Price of each touched order is respected.
     * - Solution's objective evaluation must be positive.
     *
     * Sub Requirements: Those nested within other functions
     * - checkAndOverrideObjectiveValue; Objetive value is a great enough improvement on the current winning solution
     * - checkTokenConservation; for all, non-fee, tokens total amount sold == total amount bought
     */
    function submitSolution(
        uint32 batchId,
        uint256 claimedObjectiveValue,
        address[] memory owners,
        uint16[] memory orderIds,
        uint128[] memory buyVolumes,
        uint128[] memory prices,
        uint16[] memory tokenIdsForPrice
    ) public returns (uint256) {
        require(acceptingSolutions(batchId), "Solutions are no longer accepted for this batch");
        require(
            isObjectiveValueSufficientlyImproved(claimedObjectiveValue),
            "Claimed objective doesn't sufficiently improve current solution"
        );
        require(verifyAmountThreshold(prices), "At least one price lower than AMOUNT_MINIMUM");
        require(tokenIdsForPrice[0] != 0, "Fee token has fixed price!");
        require(tokenIdsForPrice.checkPriceOrdering(), "prices are not ordered by tokenId");
        require(owners.length <= MAX_TOUCHED_ORDERS, "Solution exceeds MAX_TOUCHED_ORDERS");
        // Further assumptions are: owners.length == orderIds.length && owners.length == buyVolumes.length
        // && prices.length == tokenIdsForPrice.length
        // These assumptions are not checked explicitly, as violations of these constraints can not be used
        // to create a beneficial situation
        uint256 lastAuctionBurntFees = burnPreviousAuctionFees();
        undoCurrentSolution();
        updateCurrentPrices(prices, tokenIdsForPrice);
        delete latestSolution.trades;
        int256[] memory tokenConservation = TokenConservation.init(tokenIdsForPrice);
        uint256 utility = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            Order memory order = orders[owners[i]][orderIds[i]];
            require(checkOrderValidity(order, batchId), "Order is invalid");
            (uint128 executedBuyAmount, uint128 executedSellAmount) = getTradedAmounts(buyVolumes[i], order);
            require(executedBuyAmount >= AMOUNT_MINIMUM, "buy amount less than AMOUNT_MINIMUM");
            require(executedSellAmount >= AMOUNT_MINIMUM, "sell amount less than AMOUNT_MINIMUM");
            tokenConservation.updateTokenConservation(
                order.buyToken,
                order.sellToken,
                tokenIdsForPrice,
                executedBuyAmount,
                executedSellAmount
            );
            require(getRemainingAmount(order) >= executedSellAmount, "executedSellAmount bigger than specified in order");
            // Ensure executed price is not lower than the order price:
            //       executedSellAmount / executedBuyAmount <= order.priceDenominator / order.priceNumerator
            require(
                executedSellAmount.mul(order.priceNumerator) <= executedBuyAmount.mul(order.priceDenominator),
                "limit price not satisfied"
            );
            // accumulate utility before updateRemainingOrder, but after limitPrice verified!
            utility = utility.add(evaluateUtility(executedBuyAmount, order));
            updateRemainingOrder(owners[i], orderIds[i], executedSellAmount);
            addBalanceAndBlockWithdrawForThisBatch(owners[i], tokenIdToAddressMap(order.buyToken), executedBuyAmount);
            emit Trade(owners[i], orderIds[i], order.sellToken, order.buyToken, executedSellAmount, executedBuyAmount);
        }
        // Perform all subtractions after additions to avoid negative values
        for (uint256 i = 0; i < owners.length; i++) {
            Order memory order = orders[owners[i]][orderIds[i]];
            (, uint128 executedSellAmount) = getTradedAmounts(buyVolumes[i], order);
            subtractBalance(owners[i], tokenIdToAddressMap(order.sellToken), executedSellAmount);
        }
        uint256 disregardedUtility = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            disregardedUtility = disregardedUtility.add(evaluateDisregardedUtility(orders[owners[i]][orderIds[i]], owners[i]));
        }
        uint256 burntFees = uint256(tokenConservation.feeTokenImbalance()) / 2;
        // burntFees ensures direct trades (when available) yield better solutions than longer rings
        uint256 objectiveValue = utility.add(burntFees).sub(disregardedUtility);
        checkAndOverrideObjectiveValue(objectiveValue);
        grantRewardToSolutionSubmitter(burntFees);
        tokenConservation.checkTokenConservation();
        documentTrades(batchId, owners, orderIds, buyVolumes, tokenIdsForPrice);

        emit SolutionSubmission(
            msg.sender,
            utility,
            disregardedUtility,
            burntFees,
            lastAuctionBurntFees,
            prices,
            tokenIdsForPrice
        );
        return (objectiveValue);
    }

    /**
     * Public View Methods
     */
    /** @dev View returning ID of listed tokens
     * @param addr address of listed token.
     * @return tokenId as stored within the contract.
     */
    function tokenAddressToIdMap(address addr) public view returns (uint16) {
        return IdToAddressBiMap.getId(registeredTokens, addr);
    }

    /** @dev View returning address of listed token by ID
     * @param id tokenId as stored, via BiMap, within the contract.
     * @return address of (listed) token
     */
    function tokenIdToAddressMap(uint16 id) public view returns (address) {
        return IdToAddressBiMap.getAddressAt(registeredTokens, id);
    }

    /** @dev View returning a bool attesting whether token was already added
     * @param addr address of the token to be checked
     * @return bool attesting whether token was already added
     */
    function hasToken(address addr) public view returns (bool) {
        return IdToAddressBiMap.hasAddress(registeredTokens, addr);
    }

    /** @dev View returning all byte-encoded sell orders for specified user
     * @param user address of user whose orders are being queried
     * @param offset uint determining the starting orderIndex
     * @param pageSize uint determining the count of elements to be viewed
     * @return encoded bytes representing all orders
     */
    function getEncodedUserOrdersPaginated(
        address user,
        uint16 offset,
        uint16 pageSize
    ) public view returns (bytes memory elements) {
        for (uint16 i = offset; i < Math.min(orders[user].length, offset + pageSize); i++) {
            elements = elements.concat(
                encodeAuctionElement(user, getBalance(user, tokenIdToAddressMap(orders[user][i].sellToken)), orders[user][i])
            );
        }
        return elements;
    }

    /** @dev View returning all byte-encoded users in paginated form
     * @param previousPageUser address of last user received in last pages (address(0) for first page)
     * @param pageSize uint determining the count of users to be returned per page
     * @return encoded packed bytes of user addresses
     */
    function getUsersPaginated(address previousPageUser, uint16 pageSize) public view returns (bytes memory users) {
        if (allUsers.size == 0) {
            return users;
        }
        uint16 count = 0;
        address current = previousPageUser;
        if (current == address(0)) {
            current = allUsers.first();
            users = users.concat(abi.encodePacked(current));
            count++;
        }
        while (count < pageSize && current != allUsers.last) {
            current = allUsers.next(current);
            users = users.concat(abi.encodePacked(current));
            count++;
        }
        return users;
    }

    /** @dev View returning all byte-encoded sell orders for specified user
     * @param user address of user whose orders are being queried
     * @return encoded bytes representing all orders
     */
    function getEncodedUserOrders(address user) public view returns (bytes memory elements) {
        return getEncodedUserOrdersPaginated(user, 0, uint16(-1));
    }

    /** @dev View returning byte-encoded sell orders in paginated form
     * @param previousPageUser address of last user received in the previous page (address(0) for first page)
     * @param previousPageUserOffset the number of orders received for the last user on the previous page (0 for first page).
     * @param pageSize uint determining the count of orders to be returned per page
     * @return encoded bytes representing a page of orders ordered by (user, index)
     */
    function getEncodedUsersPaginated(
        address previousPageUser,
        uint16 previousPageUserOffset,
        uint16 pageSize
    ) public view returns (bytes memory elements) {
        if (allUsers.size == 0) {
            return elements;
        }
        uint16 currentOffset = previousPageUserOffset;
        address currentUser = previousPageUser;
        if (currentUser == address(0x0)) {
            currentUser = allUsers.first();
        }
        while (elements.length / ENCODED_AUCTION_ELEMENT_WIDTH < pageSize) {
            elements = elements.concat(
                getEncodedUserOrdersPaginated(
                    currentUser,
                    currentOffset,
                    pageSize - uint16(elements.length / ENCODED_AUCTION_ELEMENT_WIDTH)
                )
            );
            if (currentUser == allUsers.last) {
                return elements;
            }
            currentOffset = 0;
            currentUser = allUsers.next(currentUser);
        }
    }

    /** @dev View returning all byte-encoded sell orders
     * @return encoded bytes representing all orders ordered by (user, index)
     */
    function getEncodedOrders() public view returns (bytes memory elements) {
        if (allUsers.size > 0) {
            address user = allUsers.first();
            bool stop = false;
            while (!stop) {
                elements = elements.concat(getEncodedUserOrders(user));
                if (user == allUsers.last) {
                    stop = true;
                } else {
                    user = allUsers.next(user);
                }
            }
        }
        return elements;
    }

    function acceptingSolutions(uint32 batchId) public view returns (bool) {
        return batchId == getCurrentBatchId() - 1 && getSecondsRemainingInBatch() >= 1 minutes;
    }

    /** @dev gets the objective value of currently winning solution.
     * @return objective function evaluation of the currently winning solution, or zero if no solution proposed.
     */
    function getCurrentObjectiveValue() public view returns (uint256) {
        if (latestSolution.batchId == getCurrentBatchId() - 1) {
            return latestSolution.objectiveValue;
        } else {
            return 0;
        }
    }

    /**
     * Private Functions
     */
    function placeOrderInternal(
        uint16 buyToken,
        uint16 sellToken,
        uint32 validFrom,
        uint32 validUntil,
        uint128 buyAmount,
        uint128 sellAmount
    ) private returns (uint16) {
        require(IdToAddressBiMap.hasId(registeredTokens, buyToken), "Buy token must be listed");
        require(IdToAddressBiMap.hasId(registeredTokens, sellToken), "Sell token must be listed");
        require(buyToken != sellToken, "Exchange tokens not distinct");
        require(validFrom >= getCurrentBatchId(), "Orders can't be placed in the past");
        orders[msg.sender].push(
            Order({
                buyToken: buyToken,
                sellToken: sellToken,
                validFrom: validFrom,
                validUntil: validUntil,
                priceNumerator: buyAmount,
                priceDenominator: sellAmount,
                usedAmount: 0
            })
        );
        uint16 orderId = (orders[msg.sender].length - 1).toUint16();
        emit OrderPlacement(msg.sender, orderId, buyToken, sellToken, validFrom, validUntil, buyAmount, sellAmount);
        allUsers.insert(msg.sender);
        return orderId;
    }

    /** @dev called at the end of submitSolution with a value of tokenConservation / 2
     * @param feeReward amount to be rewarded to the solver
     */
    function grantRewardToSolutionSubmitter(uint256 feeReward) private {
        latestSolution.feeReward = feeReward;
        addBalanceAndBlockWithdrawForThisBatch(msg.sender, tokenIdToAddressMap(0), feeReward);
    }

    /** @dev called during solution submission to burn fees from previous auction
     * @return amount of OWL burnt
     */
    function burnPreviousAuctionFees() private returns (uint256) {
        if (!currentBatchHasSolution()) {
            feeToken.burnOWL(address(this), latestSolution.feeReward);
            return latestSolution.feeReward;
        }
        return 0;
    }

    /** @dev Called from within submitSolution to update the token prices.
     * @param prices list of prices for touched tokens only, first price is always fee token price
     * @param tokenIdsForPrice price[i] is the price for the token with tokenID tokenIdsForPrice[i]
     */
    function updateCurrentPrices(uint128[] memory prices, uint16[] memory tokenIdsForPrice) private {
        for (uint256 i = 0; i < latestSolution.tokenIdsForPrice.length; i++) {
            currentPrices[latestSolution.tokenIdsForPrice[i]] = 0;
        }
        for (uint256 i = 0; i < tokenIdsForPrice.length; i++) {
            currentPrices[tokenIdsForPrice[i]] = prices[i];
        }
    }

    /** @dev Updates an order's remaing requested sell amount upon (partial) execution of a standing order
     * @param owner order's corresponding user address
     * @param orderId index of order in list of owner's orders
     * @param executedAmount proportion of order's requested sellAmount that was filled.
     */
    function updateRemainingOrder(
        address owner,
        uint16 orderId,
        uint128 executedAmount
    ) private {
        if (isOrderWithLimitedAmount(orders[owner][orderId])) {
            orders[owner][orderId].usedAmount = orders[owner][orderId].usedAmount.add(executedAmount).toUint128();
        }
    }

    /** @dev The inverse of updateRemainingOrder, called when reverting a solution in favour of a better one.
     * @param owner order's corresponding user address
     * @param orderId index of order in list of owner's orders
     * @param executedAmount proportion of order's requested sellAmount that was filled.
     */
    function revertRemainingOrder(
        address owner,
        uint16 orderId,
        uint128 executedAmount
    ) private {
        if (isOrderWithLimitedAmount(orders[owner][orderId])) {
            orders[owner][orderId].usedAmount = orders[owner][orderId].usedAmount.sub(executedAmount).toUint128();
        }
    }

    /** @dev Checks whether an order is intended to track its usedAmount
     * @param order order under inspection
     * @return true if the given order does track its usedAmount
     */
    function isOrderWithLimitedAmount(Order memory order) private pure returns (bool) {
        return order.priceNumerator != UNLIMITED_ORDER_AMOUNT && order.priceDenominator != UNLIMITED_ORDER_AMOUNT;
    }

    /** @dev This function writes solution information into contract storage
     * @param batchId index of referenced auction
     * @param owners array of addresses corresponding to touched orders
     * @param orderIds array of order indices used in parallel with owners to identify touched order
     * @param volumes executed buy amounts for each order identified by index of owner-orderId arrays
     * @param tokenIdsForPrice price[i] is the price for the token with tokenID tokenIdsForPrice[i]
     */
    function documentTrades(
        uint32 batchId,
        address[] memory owners,
        uint16[] memory orderIds,
        uint128[] memory volumes,
        uint16[] memory tokenIdsForPrice
    ) private {
        latestSolution.batchId = batchId;
        for (uint256 i = 0; i < owners.length; i++) {
            latestSolution.trades.push(TradeData({owner: owners[i], orderId: orderIds[i], volume: volumes[i]}));
        }
        latestSolution.tokenIdsForPrice = tokenIdsForPrice;
        latestSolution.solutionSubmitter = msg.sender;
    }

    /** @dev reverts all relevant contract storage relating to an overwritten auction solution.
     */
    function undoCurrentSolution() private {
        if (currentBatchHasSolution()) {
            for (uint256 i = 0; i < latestSolution.trades.length; i++) {
                address owner = latestSolution.trades[i].owner;
                uint16 orderId = latestSolution.trades[i].orderId;
                Order memory order = orders[owner][orderId];
                (, uint128 sellAmount) = getTradedAmounts(latestSolution.trades[i].volume, order);
                addBalance(owner, tokenIdToAddressMap(order.sellToken), sellAmount);
            }
            for (uint256 i = 0; i < latestSolution.trades.length; i++) {
                address owner = latestSolution.trades[i].owner;
                uint16 orderId = latestSolution.trades[i].orderId;
                Order memory order = orders[owner][orderId];
                (uint128 buyAmount, uint128 sellAmount) = getTradedAmounts(latestSolution.trades[i].volume, order);
                revertRemainingOrder(owner, orderId, sellAmount);
                subtractBalanceUnchecked(owner, tokenIdToAddressMap(order.buyToken), buyAmount);
                emit TradeReversion(owner, orderId, order.sellToken, order.buyToken, sellAmount, buyAmount);
            }
            // subtract granted fees:
            subtractBalanceUnchecked(latestSolution.solutionSubmitter, tokenIdToAddressMap(0), latestSolution.feeReward);
        }
    }

    /** @dev determines if value is better than currently and updates if it is.
     * @param newObjectiveValue proposed value to be updated if a great enough improvement on the current objective value
     */
    function checkAndOverrideObjectiveValue(uint256 newObjectiveValue) private {
        require(
            isObjectiveValueSufficientlyImproved(newObjectiveValue),
            "New objective doesn't sufficiently improve current solution"
        );
        latestSolution.objectiveValue = newObjectiveValue;
    }

    // Private view
    /** @dev Evaluates utility of executed trade
     * @param execBuy represents proportion of order executed (in terms of buy amount)
     * @param order the sell order whose utility is being evaluated
     * @return Utility = ((execBuy * order.sellAmt - execSell * order.buyAmt) * price.buyToken) / order.sellAmt
     */
    function evaluateUtility(uint128 execBuy, Order memory order) private view returns (uint256) {
        // Utility = ((execBuy * order.sellAmt - execSell * order.buyAmt) * price.buyToken) / order.sellAmt
        uint256 execSellTimesBuy = getExecutedSellAmount(execBuy, currentPrices[order.buyToken], currentPrices[order.sellToken])
            .mul(order.priceNumerator);

        uint256 roundedUtility = execBuy.sub(execSellTimesBuy.div(order.priceDenominator)).mul(currentPrices[order.buyToken]);
        uint256 utilityError = execSellTimesBuy.mod(order.priceDenominator).mul(currentPrices[order.buyToken]).div(
            order.priceDenominator
        );
        return roundedUtility.sub(utilityError);
    }

    /** @dev computes a measure of how much of an order was disregarded (only valid when limit price is respected)
     * @param order the sell order whose disregarded utility is being evaluated
     * @param user address of order's owner
     * @return disregardedUtility of the order (after it has been applied)
     * Note that:
     * |disregardedUtility| = (limitTerm * leftoverSellAmount) / order.sellAmount
     * where limitTerm = price.SellToken * order.sellAmt - order.buyAmt * price.buyToken / (1 - phi)
     * and leftoverSellAmount = order.sellAmt - execSellAmt
     * Balances and orders have all been updated so: sellAmount - execSellAmt == remainingAmount(order).
     * For correctness, we take the minimum of this with the user's token balance.
     */
    function evaluateDisregardedUtility(Order memory order, address user) private view returns (uint256) {
        uint256 leftoverSellAmount = Math.min(getRemainingAmount(order), getBalance(user, tokenIdToAddressMap(order.sellToken)));
        uint256 limitTermLeft = currentPrices[order.sellToken].mul(order.priceDenominator);
        uint256 limitTermRight = order.priceNumerator.mul(currentPrices[order.buyToken]).mul(feeDenominator).div(
            feeDenominator - 1
        );
        uint256 limitTerm = 0;
        if (limitTermLeft > limitTermRight) {
            limitTerm = limitTermLeft.sub(limitTermRight);
        }
        return leftoverSellAmount.mul(limitTerm).div(order.priceDenominator);
    }

    /** @dev Evaluates executedBuy amount based on prices and executedBuyAmout (fees included)
     * @param executedBuyAmount amount of buyToken executed for purchase in batch auction
     * @param buyTokenPrice uniform clearing price of buyToken
     * @param sellTokenPrice uniform clearing price of sellToken
     * @return executedSellAmount as expressed in Equation (2)
     * https://github.com/gnosis/dex-contracts/issues/173#issuecomment-526163117
     * execSellAmount * p[sellToken] * (1 - phi) == execBuyAmount * p[buyToken]
     * where phi = 1/FEE_DENOMINATOR
     * Note that: 1 - phi = (FEE_DENOMINATOR - 1) / FEE_DENOMINATOR
     * And so, 1/(1-phi) = FEE_DENOMINATOR / (FEE_DENOMINATOR - 1)
     * execSellAmount = (execBuyAmount * p[buyToken]) / (p[sellToken] * (1 - phi))
     *                = (execBuyAmount * buyTokenPrice / sellTokenPrice) * FEE_DENOMINATOR / (FEE_DENOMINATOR - 1)
     * in order to minimize rounding errors, the order of operations is switched
     *                = ((executedBuyAmount * buyTokenPrice) / (FEE_DENOMINATOR - 1)) * FEE_DENOMINATOR) / sellTokenPrice
     */
    function getExecutedSellAmount(
        uint128 executedBuyAmount,
        uint128 buyTokenPrice,
        uint128 sellTokenPrice
    ) private view returns (uint128) {
        /* solium-disable indentation */
        return
            uint256(executedBuyAmount)
                .mul(buyTokenPrice)
                .div(feeDenominator - 1)
                .mul(feeDenominator)
                .div(sellTokenPrice)
                .toUint128();
        /* solium-enable indentation */
    }

    /** @dev used to determine if solution if first provided in current batch
     * @return true if `latestSolution` is storing a solution for current batch, else false
     */
    function currentBatchHasSolution() private view returns (bool) {
        return latestSolution.batchId == getCurrentBatchId() - 1;
    }

    // Private view
    /** @dev Compute trade execution based on executedBuyAmount and relevant token prices
     * @param executedBuyAmount executed buy amount
     * @param order contains relevant buy-sell token information
     * @return (executedBuyAmount, executedSellAmount)
     */
    function getTradedAmounts(uint128 executedBuyAmount, Order memory order) private view returns (uint128, uint128) {
        uint128 executedSellAmount = getExecutedSellAmount(
            executedBuyAmount,
            currentPrices[order.buyToken],
            currentPrices[order.sellToken]
        );
        return (executedBuyAmount, executedSellAmount);
    }

    /** @dev Checks that the proposed objective value is a significant enough improvement on the latest one
     * @param objectiveValue the proposed objective value to check
     * @return true if the objectiveValue is a significant enough improvement, false otherwise
     */
    function isObjectiveValueSufficientlyImproved(uint256 objectiveValue) private view returns (bool) {
        return (objectiveValue.mul(IMPROVEMENT_DENOMINATOR) > getCurrentObjectiveValue().mul(IMPROVEMENT_DENOMINATOR + 1));
    }

    // Private pure
    /** @dev used to determine if an order is valid for specific auction/batch
     * @param order object whose validity is in question
     * @param batchId auction index of validity
     * @return true if order is valid in auction batchId else false
     */
    function checkOrderValidity(Order memory order, uint32 batchId) private pure returns (bool) {
        return order.validFrom <= batchId && order.validUntil >= batchId;
    }

    /** @dev computes the remaining sell amount for a given order
     * @param order the order for which remaining amount should be calculated
     * @return the remaining sell amount
     */
    function getRemainingAmount(Order memory order) private pure returns (uint128) {
        return order.priceDenominator - order.usedAmount;
    }

    /** @dev called only by getEncodedOrders and used to pack auction info into bytes
     * @param user list of tokenIds
     * @param sellTokenBalance user's account balance of sell token
     * @param order a sell order
     * @return byte encoded, packed, concatenation of relevant order information
     */
    function encodeAuctionElement(
        address user,
        uint256 sellTokenBalance,
        Order memory order
    ) private pure returns (bytes memory element) {
        element = abi.encodePacked(user);
        element = element.concat(abi.encodePacked(sellTokenBalance));
        element = element.concat(abi.encodePacked(order.buyToken));
        element = element.concat(abi.encodePacked(order.sellToken));
        element = element.concat(abi.encodePacked(order.validFrom));
        element = element.concat(abi.encodePacked(order.validUntil));
        element = element.concat(abi.encodePacked(order.priceNumerator));
        element = element.concat(abi.encodePacked(order.priceDenominator));
        element = element.concat(abi.encodePacked(getRemainingAmount(order)));
        return element;
    }

    /** @dev determines if value is better than currently and updates if it is.
     * @param amounts array of values to be verified with AMOUNT_MINIMUM
     */
    function verifyAmountThreshold(uint128[] memory amounts) private pure returns (bool) {
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] < AMOUNT_MINIMUM) {
                return false;
            }
        }
        return true;
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/** @title Epoch Token Locker
 *  EpochTokenLocker saveguards tokens for applications with constant-balances during discrete epochs
 *  It allows to deposit a token which become credited in the next epoch and allows to request a token-withdraw
 *  which becomes claimable after the current epoch has expired.
 *  @author @gnosis/dfusion-team <https://github.com/orgs/gnosis/teams/dfusion-team/members>
 */
contract EpochTokenLocker {
    using SafeMath for uint256;

    /** @dev Number of seconds a batch is lasting*/
    uint32 public constant BATCH_TIME = 300;

    // User => Token => BalanceState
    mapping(address => mapping(address => BalanceState)) private balanceStates;

    // user => token => lastCreditBatchId
    mapping(address => mapping(address => uint32)) public lastCreditBatchId;

    struct BalanceState {
        uint256 balance;
        PendingFlux pendingDeposits; // deposits will be credited in any future epoch, i.e. currentStateIndex > batchId
        PendingFlux pendingWithdraws; // withdraws are allowed in any future epoch, i.e. currentStateIndex > batchId
    }

    struct PendingFlux {
        uint256 amount;
        uint32 batchId;
    }

    event Deposit(address indexed user, address indexed token, uint256 amount, uint32 batchId);

    event WithdrawRequest(address indexed user, address indexed token, uint256 amount, uint32 batchId);

    event Withdraw(address indexed user, address indexed token, uint256 amount);

    /** @dev credits user with deposit amount on next epoch (given by getCurrentBatchId)
     * @param token address of token to be deposited
     * @param amount number of token(s) to be credited to user's account
     *
     * Emits an {Deposit} event with relevent deposit information.
     *
     * Requirements:
     * - token transfer to contract is successfull
     */
    function deposit(address token, uint256 amount) public {
        updateDepositsBalance(msg.sender, token);
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
        // solhint-disable-next-line max-line-length
        balanceStates[msg.sender][token].pendingDeposits.amount = balanceStates[msg.sender][token].pendingDeposits.amount.add(
            amount
        );
        balanceStates[msg.sender][token].pendingDeposits.batchId = getCurrentBatchId();
        emit Deposit(msg.sender, token, amount, getCurrentBatchId());
    }

    /** @dev Signals and initiates user's intent to withdraw.
     * @param token address of token to be withdrawn
     * @param amount number of token(s) to be withdrawn
     *
     * Emits an {WithdrawRequest} event with relevent request information.
     */
    function requestWithdraw(address token, uint256 amount) public {
        requestFutureWithdraw(token, amount, getCurrentBatchId());
    }

    /** @dev Signals and initiates user's intent to withdraw.
     * @param token address of token to be withdrawn
     * @param amount number of token(s) to be withdrawn
     * @param batchId state index at which request is to be made.
     *
     * Emits an {WithdrawRequest} event with relevent request information.
     */
    function requestFutureWithdraw(
        address token,
        uint256 amount,
        uint32 batchId
    ) public {
        // First process pendingWithdraw (if any), as otherwise balances might increase for currentBatchId - 1
        if (hasValidWithdrawRequest(msg.sender, token)) {
            withdraw(msg.sender, token);
        }
        require(batchId >= getCurrentBatchId(), "Request cannot be made in the past");
        balanceStates[msg.sender][token].pendingWithdraws = PendingFlux({amount: amount, batchId: batchId});
        emit WithdrawRequest(msg.sender, token, amount, batchId);
    }

    /** @dev Claims pending withdraw - can be called on behalf of others
     * @param token address of token to be withdrawn
     * @param user address of user who withdraw is being claimed.
     *
     * Emits an {Withdraw} event stating that `user` withdrew `amount` of `token`
     *
     * Requirements:
     * - withdraw was requested in previous epoch
     * - token was received from exchange in current auction batch
     */
    function withdraw(address user, address token) public {
        updateDepositsBalance(user, token); // withdrawn amount may have been deposited in previous epoch
        require(
            balanceStates[user][token].pendingWithdraws.batchId < getCurrentBatchId(),
            "withdraw was not registered previously"
        );
        require(
            lastCreditBatchId[user][token] < getCurrentBatchId(),
            "Withdraw not possible for token that is traded in the current auction"
        );
        uint256 amount = Math.min(balanceStates[user][token].balance, balanceStates[user][token].pendingWithdraws.amount);

        balanceStates[user][token].balance = balanceStates[user][token].balance.sub(amount);
        delete balanceStates[user][token].pendingWithdraws;

        SafeERC20.safeTransfer(IERC20(token), user, amount);
        emit Withdraw(user, token, amount);
    }

    /**
     * Public view functions
     */
    /** @dev getter function used to display pending deposit
     * @param user address of user
     * @param token address of ERC20 token
     * return amount and batchId of deposit's transfer if any (else 0)
     */
    function getPendingDeposit(address user, address token) public view returns (uint256, uint32) {
        PendingFlux memory pendingDeposit = balanceStates[user][token].pendingDeposits;
        return (pendingDeposit.amount, pendingDeposit.batchId);
    }

    /** @dev getter function used to display pending withdraw
     * @param user address of user
     * @param token address of ERC20 token
     * return amount and batchId when withdraw was requested if any (else 0)
     */
    function getPendingWithdraw(address user, address token) public view returns (uint256, uint32) {
        PendingFlux memory pendingWithdraw = balanceStates[user][token].pendingWithdraws;
        return (pendingWithdraw.amount, pendingWithdraw.batchId);
    }

    /** @dev getter function to determine current auction id.
     * return current batchId
     */
    function getCurrentBatchId() public view returns (uint32) {
        // solhint-disable-next-line not-rely-on-time
        return uint32(now / BATCH_TIME);
    }

    /** @dev used to determine how much time is left in a batch
     * return seconds remaining in current batch
     */
    function getSecondsRemainingInBatch() public view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return BATCH_TIME - (now % BATCH_TIME);
    }

    /** @dev fetches and returns user's balance
     * @param user address of user
     * @param token address of ERC20 token
     * return Current `token` balance of `user`'s account
     */
    function getBalance(address user, address token) public view returns (uint256) {
        uint256 balance = balanceStates[user][token].balance;
        if (balanceStates[user][token].pendingDeposits.batchId < getCurrentBatchId()) {
            balance = balance.add(balanceStates[user][token].pendingDeposits.amount);
        }
        if (balanceStates[user][token].pendingWithdraws.batchId < getCurrentBatchId()) {
            balance = balance.sub(Math.min(balanceStates[user][token].pendingWithdraws.amount, balance));
        }
        return balance;
    }

    /** @dev Used to determine if user has a valid pending withdraw request of specific token
     * @param user address of user
     * @param token address of ERC20 token
     * return true if `user` has valid withdraw request for `token`, otherwise false
     */
    function hasValidWithdrawRequest(address user, address token) public view returns (bool) {
        return
            balanceStates[user][token].pendingWithdraws.batchId < getCurrentBatchId() &&
            balanceStates[user][token].pendingWithdraws.batchId > 0;
    }

    /**
     * internal functions
     */
    /**
     * The following function should be used to update any balances within an epoch, which
     * will not be immediately final. E.g. the BatchExchange credits new balances to
     * the buyers in an auction, but as there are might be better solutions, the updates are
     * not final. In order to prevent withdraws from non-final updates, we disallow withdraws
     * by setting lastCreditBatchId to the current batchId and allow only withdraws in batches
     * with a higher batchId.
     */
    function addBalanceAndBlockWithdrawForThisBatch(
        address user,
        address token,
        uint256 amount
    ) internal {
        if (hasValidWithdrawRequest(user, token)) {
            lastCreditBatchId[user][token] = getCurrentBatchId();
        }
        addBalance(user, token, amount);
    }

    function addBalance(
        address user,
        address token,
        uint256 amount
    ) internal {
        updateDepositsBalance(user, token);
        balanceStates[user][token].balance = balanceStates[user][token].balance.add(amount);
    }

    /**
     * The following function should be used to subtract amounts from the current balances state.
     * For the substraction the current withdrawRequests are considered and they are effectively reducing
     * the available balance.
     */
    function subtractBalance(
        address user,
        address token,
        uint256 amount
    ) internal {
        require(amount <= getBalance(user, token), "Amount exceeds user's balance.");
        subtractBalanceUnchecked(user, token, amount);
    }

    /**
     * The following function should be used to substract amounts from the current balance
     * state, if the pending withdrawRequests are not considered and should not effectively reduce
     * the available balance.
     * For example, the reversion of trades from a previous batch-solution do not
     * need to consider withdrawRequests. This is the case as withdraws are blocked for one
     * batch for accounts having credited funds in a previous submission.
     * PendingWithdraws must also be ignored since otherwise for the reversion of trades,
     * a solution reversion could be blocked: A bigger withdrawRequest could set the return value of
     * getBalance(user, token) to zero, although the user was just credited tokens in
     * the last submission. In this situation, during the unwinding of the previous orders,
     * the check `amount <= getBalance(user, token)` would fail and the reversion would be blocked.
     */
    function subtractBalanceUnchecked(
        address user,
        address token,
        uint256 amount
    ) internal {
        updateDepositsBalance(user, token);
        balanceStates[user][token].balance = balanceStates[user][token].balance.sub(amount);
    }

    function updateDepositsBalance(address user, address token) private {
        uint256 batchId = balanceStates[user][token].pendingDeposits.batchId;
        if (batchId > 0 && batchId < getCurrentBatchId()) {
            // batchId > 0 is checked in order save an SSTORE in case there is no pending deposit
            balanceStates[user][token].balance = balanceStates[user][token].balance.add(
                balanceStates[user][token].pendingDeposits.amount
            );
            delete balanceStates[user][token].pendingDeposits;
        }
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/drafts/SignedSafeMath.sol";

/** @title Token Conservation
 *  A library for updating and verifying the tokenConservation contraint for BatchExchange's batch auction
 *  @author @gnosis/dfusion-team <https://github.com/orgs/gnosis/teams/dfusion-team/members>
 */
library TokenConservation {
    using SignedSafeMath for int256;

    /** @dev initialize the token conservation data structure
     * @param tokenIdsForPrice sorted list of tokenIds for which token conservation should be checked
     */
    function init(uint16[] memory tokenIdsForPrice) internal pure returns (int256[] memory) {
        return new int256[](tokenIdsForPrice.length + 1);
    }

    /** @dev returns the token imbalance of the fee token
     * @param self internal datastructure created by TokenConservation.init()
     */
    function feeTokenImbalance(int256[] memory self) internal pure returns (int256) {
        return self[0];
    }

    /** @dev updated token conservation array.
     * @param self internal datastructure created by TokenConservation.init()
     * @param buyToken id of token whose imbalance should be subtracted from
     * @param sellToken id of token whose imbalance should be added to
     * @param tokenIdsForPrice sorted list of tokenIds
     * @param buyAmount amount to be subtracted at `self[buyTokenIndex]`
     * @param sellAmount amount to be added at `self[sellTokenIndex]`
     */
    function updateTokenConservation(
        int256[] memory self,
        uint16 buyToken,
        uint16 sellToken,
        uint16[] memory tokenIdsForPrice,
        uint128 buyAmount,
        uint128 sellAmount
    ) internal pure {
        uint256 buyTokenIndex = findPriceIndex(buyToken, tokenIdsForPrice);
        uint256 sellTokenIndex = findPriceIndex(sellToken, tokenIdsForPrice);
        self[buyTokenIndex] = self[buyTokenIndex].sub(int256(buyAmount));
        self[sellTokenIndex] = self[sellTokenIndex].add(int256(sellAmount));
    }

    /** @dev Ensures all array's elements are zero except the first.
     * @param self internal datastructure created by TokenConservation.init()
     * @return true if all, but first element of self are zero else false
     */
    function checkTokenConservation(int256[] memory self) internal pure {
        require(self[0] > 0, "Token conservation at 0 must be positive.");
        for (uint256 i = 1; i < self.length; i++) {
            require(self[i] == 0, "Token conservation does not hold");
        }
    }

    /** @dev Token ordering is verified by submitSolution. Required because binary search is used to fetch token info.
     * @param tokenIdsForPrice list of tokenIds
     * @return true if tokenIdsForPrice is sorted else false
     */
    function checkPriceOrdering(uint16[] memory tokenIdsForPrice) internal pure returns (bool) {
        for (uint256 i = 1; i < tokenIdsForPrice.length; i++) {
            if (tokenIdsForPrice[i] <= tokenIdsForPrice[i - 1]) {
                return false;
            }
        }
        return true;
    }

    /** @dev implementation of binary search on sorted list returns token id
     * @param tokenId element whose index is to be found
     * @param tokenIdsForPrice list of (sorted) tokenIds for which binary search is applied.
     * @return `index` in `tokenIdsForPrice` where `tokenId` appears (reverts if not found).
     */
    function findPriceIndex(uint16 tokenId, uint16[] memory tokenIdsForPrice) private pure returns (uint256) {
        // Fee token is not included in tokenIdsForPrice
        if (tokenId == 0) {
            return 0;
        }
        // binary search for the other tokens
        uint256 leftValue = 0;
        uint256 rightValue = tokenIdsForPrice.length - 1;
        while (rightValue >= leftValue) {
            uint256 middleValue = (leftValue + rightValue) / 2;
            if (tokenIdsForPrice[middleValue] == tokenId) {
                // shifted one to the right to account for fee token at index 0
                return middleValue + 1;
            } else if (tokenIdsForPrice[middleValue] < tokenId) {
                leftValue = middleValue + 1;
            } else {
                rightValue = middleValue - 1;
            }
        }
        revert("Price not provided for token");
    }
}

pragma solidity ^0.5.2;

import "@gnosis.pm/util-contracts/contracts/Math.sol";
import "@gnosis.pm/util-contracts/contracts/GnosisStandardToken.sol";
import "@gnosis.pm/util-contracts/contracts/Proxy.sol";

contract TokenOWL is Proxied, GnosisStandardToken {
    using GnosisMath for *;

    string public constant name = "OWL Token";
    string public constant symbol = "OWL";
    uint8 public constant decimals = 18;

    struct masterCopyCountdownType {
        address masterCopy;
        uint timeWhenAvailable;
    }

    masterCopyCountdownType masterCopyCountdown;

    address public creator;
    address public minter;

    event Minted(address indexed to, uint256 amount);
    event Burnt(address indexed from, address indexed user, uint256 amount);

    modifier onlyCreator() {
        // R1
        require(msg.sender == creator, "Only the creator can perform the transaction");
        _;
    }
    /// @dev trickers the update process via the proxyMaster for a new address _masterCopy
    /// updating is only possible after 30 days
    function startMasterCopyCountdown(address _masterCopy) public onlyCreator {
        require(address(_masterCopy) != address(0), "The master copy must be a valid address");

        // Update masterCopyCountdown
        masterCopyCountdown.masterCopy = _masterCopy;
        masterCopyCountdown.timeWhenAvailable = now + 30 days;
    }

    /// @dev executes the update process via the proxyMaster for a new address _masterCopy
    function updateMasterCopy() public onlyCreator {
        require(address(masterCopyCountdown.masterCopy) != address(0), "The master copy must be a valid address");
        require(
            block.timestamp >= masterCopyCountdown.timeWhenAvailable,
            "It's not possible to update the master copy during the waiting period"
        );

        // Update masterCopy
        masterCopy = masterCopyCountdown.masterCopy;
    }

    function getMasterCopy() public view returns (address) {
        return masterCopy;
    }

    /// @dev Set minter. Only the creator of this contract can call this.
    /// @param newMinter The new address authorized to mint this token
    function setMinter(address newMinter) public onlyCreator {
        minter = newMinter;
    }

    /// @dev change owner/creator of the contract. Only the creator/owner of this contract can call this.
    /// @param newOwner The new address, which should become the owner
    function setNewOwner(address newOwner) public onlyCreator {
        creator = newOwner;
    }

    /// @dev Mints OWL.
    /// @param to Address to which the minted token will be given
    /// @param amount Amount of OWL to be minted
    function mintOWL(address to, uint amount) public {
        require(minter != address(0), "The minter must be initialized");
        require(msg.sender == minter, "Only the minter can mint OWL");
        balances[to] = balances[to].add(amount);
        totalTokens = totalTokens.add(amount);
        emit Minted(to, amount);
        emit Transfer(address(0), to, amount);
    }

    /// @dev Burns OWL.
    /// @param user Address of OWL owner
    /// @param amount Amount of OWL to be burnt
    function burnOWL(address user, uint amount) public {
        allowances[user][msg.sender] = allowances[user][msg.sender].sub(amount);
        balances[user] = balances[user].sub(amount);
        totalTokens = totalTokens.sub(amount);
        emit Burnt(msg.sender, user, amount);
        emit Transfer(user, address(0), amount);
    }

    function getMasterCopyCountdown() public view returns (address, uint) {
        return (masterCopyCountdown.masterCopy, masterCopyCountdown.timeWhenAvailable);
    }
}

pragma solidity ^0.5.0;


library IdToAddressBiMap {
    struct Data {
        mapping(uint16 => address) idToAddress;
        mapping(address => uint16) addressToId;
    }

    function hasId(Data storage self, uint16 id) public view returns (bool) {
        return self.idToAddress[id + 1] != address(0);
    }

    function hasAddress(Data storage self, address addr) public view returns (bool) {
        return self.addressToId[addr] != 0;
    }

    function getAddressAt(Data storage self, uint16 id) public view returns (address) {
        require(hasId(self, id), "Must have ID to get Address");
        return self.idToAddress[id + 1];
    }

    function getId(Data storage self, address addr) public view returns (uint16) {
        require(hasAddress(self, addr), "Must have Address to get ID");
        return self.addressToId[addr] - 1;
    }

    function insert(Data storage self, uint16 id, address addr) public returns (bool) {
        require(addr != address(0), "Cannot insert zero address");
        require(id != uint16(-1), "Cannot insert max uint16");
        // Ensure bijectivity of the mappings
        if (self.addressToId[addr] != 0 || self.idToAddress[id + 1] != address(0)) {
            return false;
        }
        self.idToAddress[id + 1] = addr;
        self.addressToId[addr] = id + 1;
        return true;
    }

}

pragma solidity ^0.5.0;


library IterableAppendOnlySet {
    struct Data {
        mapping(address => address) nextMap;
        address last;
        uint96 size; // width is chosen to align struct size to full words
    }

    function insert(Data storage self, address value) public returns (bool) {
        if (contains(self, value)) {
            return false;
        }
        self.nextMap[self.last] = value;
        self.last = value;
        self.size += 1;
        return true;
    }

    function contains(Data storage self, address value) public view returns (bool) {
        require(value != address(0), "Inserting address(0) is not supported");
        return self.nextMap[value] != address(0) || (self.last == value);
    }

    function first(Data storage self) public view returns (address) {
        require(self.last != address(0), "Trying to get first from empty set");
        return self.nextMap[address(0)];
    }

    function next(Data storage self, address value) public view returns (address) {
        require(contains(self, value), "Trying to get next of non-existent element");
        require(value != self.last, "Trying to get next of last element");
        return self.nextMap[value];
    }
}

pragma solidity ^0.5.2;
import "./Token.sol";
import "./Math.sol";
import "./Proxy.sol";

/**
 * Deprecated: Use Open Zeppeling one instead
 */
contract StandardTokenData {
    /*
     *  Storage
     */
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    uint totalTokens;
}

/**
 * Deprecated: Use Open Zeppeling one instead
 */
/// @title Standard token contract with overflow protection
contract GnosisStandardToken is Token, StandardTokenData {
    using GnosisMath for *;

    /*
     *  Public functions
     */
    /// @dev Transfers sender's tokens to a given address. Returns success
    /// @param to Address of token receiver
    /// @param value Number of tokens to transfer
    /// @return Was transfer successful?
    function transfer(address to, uint value) public returns (bool) {
        if (!balances[msg.sender].safeToSub(value) || !balances[to].safeToAdd(value)) {
            return false;
        }

        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success
    /// @param from Address from where tokens are withdrawn
    /// @param to Address to where tokens are sent
    /// @param value Number of tokens to transfer
    /// @return Was transfer successful?
    function transferFrom(address from, address to, uint value) public returns (bool) {
        if (!balances[from].safeToSub(value) || !allowances[from][msg.sender].safeToSub(
            value
        ) || !balances[to].safeToAdd(value)) {
            return false;
        }
        balances[from] -= value;
        allowances[from][msg.sender] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    /// @dev Sets approved amount of tokens for spender. Returns success
    /// @param spender Address of allowed account
    /// @param value Number of approved tokens
    /// @return Was approval successful?
    function approve(address spender, uint value) public returns (bool) {
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /// @dev Returns number of allowed tokens for given address
    /// @param owner Address of token owner
    /// @param spender Address of token spender
    /// @return Remaining allowance for spender
    function allowance(address owner, address spender) public view returns (uint) {
        return allowances[owner][spender];
    }

    /// @dev Returns number of tokens owned by given address
    /// @param owner Address of token owner
    /// @return Balance of owner
    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }

    /// @dev Returns total supply of tokens
    /// @return Total supply
    function totalSupply() public view returns (uint) {
        return totalTokens;
    }
}

pragma solidity ^0.5.2;

/// @title Math library - Allows calculation of logarithmic and exponential functions
/// @author Alan Lu - <[email protected]>
/// @author Stefan George - <[email protected]>
library GnosisMath {
    /*
     *  Constants
     */
    // This is equal to 1 in our calculations
    uint public constant ONE = 0x10000000000000000;
    uint public constant LN2 = 0xb17217f7d1cf79ac;
    uint public constant LOG2_E = 0x171547652b82fe177;

    /*
     *  Public functions
     */
    /// @dev Returns natural exponential function value of given x
    /// @param x x
    /// @return e**x
    function exp(int x) public pure returns (uint) {
        // revert if x is > MAX_POWER, where
        // MAX_POWER = int(mp.floor(mp.log(mpf(2**256 - 1) / ONE) * ONE))
        require(x <= 2454971259878909886679);
        // return 0 if exp(x) is tiny, using
        // MIN_POWER = int(mp.floor(mp.log(mpf(1) / ONE) * ONE))
        if (x < -818323753292969962227) return 0;
        // Transform so that e^x -> 2^x
        x = x * int(ONE) / int(LN2);
        // 2^x = 2^whole(x) * 2^frac(x)
        //       ^^^^^^^^^^ is a bit shift
        // so Taylor expand on z = frac(x)
        int shift;
        uint z;
        if (x >= 0) {
            shift = x / int(ONE);
            z = uint(x % int(ONE));
        } else {
            shift = x / int(ONE) - 1;
            z = ONE - uint(-x % int(ONE));
        }
        // 2^x = 1 + (ln 2) x + (ln 2)^2/2! x^2 + ...
        //
        // Can generate the z coefficients using mpmath and the following lines
        // >>> from mpmath import mp
        // >>> mp.dps = 100
        // >>> ONE =  0x10000000000000000
        // >>> print('\n'.join(hex(int(mp.log(2)**i / mp.factorial(i) * ONE)) for i in range(1, 7)))
        // 0xb17217f7d1cf79ab
        // 0x3d7f7bff058b1d50
        // 0xe35846b82505fc5
        // 0x276556df749cee5
        // 0x5761ff9e299cc4
        // 0xa184897c363c3
        uint zpow = z;
        uint result = ONE;
        result += 0xb17217f7d1cf79ab * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x3d7f7bff058b1d50 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xe35846b82505fc5 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x276556df749cee5 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x5761ff9e299cc4 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xa184897c363c3 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xffe5fe2c4586 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x162c0223a5c8 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1b5253d395e * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1e4cf5158b * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1e8cac735 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1c3bd650 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1816193 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x131496 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xe1b7 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x9c7 * zpow / ONE;
        if (shift >= 0) {
            if (result >> (256 - shift) > 0) return (2 ** 256 - 1);
            return result << shift;
        } else return result >> (-shift);
    }

    /// @dev Returns natural logarithm value of given x
    /// @param x x
    /// @return ln(x)
    function ln(uint x) public pure returns (int) {
        require(x > 0);
        // binary search for floor(log2(x))
        int ilog2 = floorLog2(x);
        int z;
        if (ilog2 < 0) z = int(x << uint(-ilog2));
        else z = int(x >> uint(ilog2));
        // z = x * 2^-⌊log₂x⌋
        // so 1 <= z < 2
        // and ln z = ln x - ⌊log₂x⌋/log₂e
        // so just compute ln z using artanh series
        // and calculate ln x from that
        int term = (z - int(ONE)) * int(ONE) / (z + int(ONE));
        int halflnz = term;
        int termpow = term * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 3;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 5;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 7;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 9;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 11;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 13;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 15;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 17;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 19;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 21;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 23;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 25;
        return (ilog2 * int(ONE)) * int(ONE) / int(LOG2_E) + 2 * halflnz;
    }

    /// @dev Returns base 2 logarithm value of given x
    /// @param x x
    /// @return logarithmic value
    function floorLog2(uint x) public pure returns (int lo) {
        lo = -64;
        int hi = 193;
        // I use a shift here instead of / 2 because it floors instead of rounding towards 0
        int mid = (hi + lo) >> 1;
        while ((lo + 1) < hi) {
            if (mid < 0 && x << uint(-mid) < ONE || mid >= 0 && x >> uint(mid) < ONE) hi = mid;
            else lo = mid;
            mid = (hi + lo) >> 1;
        }
    }

    /// @dev Returns maximum of an array
    /// @param nums Numbers to look through
    /// @return Maximum number
    function max(int[] memory nums) public pure returns (int maxNum) {
        require(nums.length > 0);
        maxNum = -2 ** 255;
        for (uint i = 0; i < nums.length; i++) if (nums[i] > maxNum) maxNum = nums[i];
    }

    /// @dev Returns whether an add operation causes an overflow
    /// @param a First addend
    /// @param b Second addend
    /// @return Did no overflow occur?
    function safeToAdd(uint a, uint b) internal pure returns (bool) {
        return a + b >= a;
    }

    /// @dev Returns whether a subtraction operation causes an underflow
    /// @param a Minuend
    /// @param b Subtrahend
    /// @return Did no underflow occur?
    function safeToSub(uint a, uint b) internal pure returns (bool) {
        return a >= b;
    }

    /// @dev Returns whether a multiply operation causes an overflow
    /// @param a First factor
    /// @param b Second factor
    /// @return Did no overflow occur?
    function safeToMul(uint a, uint b) internal pure returns (bool) {
        return b == 0 || a * b / b == a;
    }

    /// @dev Returns sum if no overflow occurred
    /// @param a First addend
    /// @param b Second addend
    /// @return Sum
    function add(uint a, uint b) internal pure returns (uint) {
        require(safeToAdd(a, b));
        return a + b;
    }

    /// @dev Returns difference if no overflow occurred
    /// @param a Minuend
    /// @param b Subtrahend
    /// @return Difference
    function sub(uint a, uint b) internal pure returns (uint) {
        require(safeToSub(a, b));
        return a - b;
    }

    /// @dev Returns product if no overflow occurred
    /// @param a First factor
    /// @param b Second factor
    /// @return Product
    function mul(uint a, uint b) internal pure returns (uint) {
        require(safeToMul(a, b));
        return a * b;
    }

    /// @dev Returns whether an add operation causes an overflow
    /// @param a First addend
    /// @param b Second addend
    /// @return Did no overflow occur?
    function safeToAdd(int a, int b) internal pure returns (bool) {
        return (b >= 0 && a + b >= a) || (b < 0 && a + b < a);
    }

    /// @dev Returns whether a subtraction operation causes an underflow
    /// @param a Minuend
    /// @param b Subtrahend
    /// @return Did no underflow occur?
    function safeToSub(int a, int b) internal pure returns (bool) {
        return (b >= 0 && a - b <= a) || (b < 0 && a - b > a);
    }

    /// @dev Returns whether a multiply operation causes an overflow
    /// @param a First factor
    /// @param b Second factor
    /// @return Did no overflow occur?
    function safeToMul(int a, int b) internal pure returns (bool) {
        return (b == 0) || (a * b / b == a);
    }

    /// @dev Returns sum if no overflow occurred
    /// @param a First addend
    /// @param b Second addend
    /// @return Sum
    function add(int a, int b) internal pure returns (int) {
        require(safeToAdd(a, b));
        return a + b;
    }

    /// @dev Returns difference if no overflow occurred
    /// @param a Minuend
    /// @param b Subtrahend
    /// @return Difference
    function sub(int a, int b) internal pure returns (int) {
        require(safeToSub(a, b));
        return a - b;
    }

    /// @dev Returns product if no overflow occurred
    /// @param a First factor
    /// @param b Second factor
    /// @return Product
    function mul(int a, int b) internal pure returns (int) {
        require(safeToMul(a, b));
        return a * b;
    }
}

pragma solidity ^0.5.2;

/// @title Proxied - indicates that a contract will be proxied. Also defines storage requirements for Proxy.
/// @author Alan Lu - <[email protected]>
contract Proxied {
    address public masterCopy;
}

/// @title Proxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]>
contract Proxy is Proxied {
    /// @dev Constructor function sets address of master copy contract.
    /// @param _masterCopy Master copy address.
    constructor(address _masterCopy) public {
        require(_masterCopy != address(0), "The master copy is required");
        masterCopy = _masterCopy;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    function() external payable {
        address _masterCopy = masterCopy;
        assembly {
            calldatacopy(0, 0, calldatasize)
            let success := delegatecall(not(0), _masterCopy, 0, calldatasize, 0, 0)
            returndatacopy(0, 0, returndatasize)
            switch success
                case 0 {
                    revert(0, returndatasize)
                }
                default {
                    return(0, returndatasize)
                }
        }
    }
}

/// Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
pragma solidity ^0.5.2;

/// @title Abstract token contract - Functions to be implemented by token contracts
contract Token {
    /*
     *  Events
     */
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    /*
     *  Public functions
     */
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    function balanceOf(address owner) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint);
    function totalSupply() public view returns (uint);
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;


/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 *
 * _Available since v2.5.0._
 */
library SafeCast {

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
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
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
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
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
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
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
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
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
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0 <0.7.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes_slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes_slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_start + 2 >= _start, "toUint16_overflow");
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_start + 4 >= _start, "toUint32_overflow");
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_start + 8 >= _start, "toUint64_overflow");
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_start + 12 >= _start, "toUint96_overflow");
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_start + 16 >= _start, "toUint128_overflow");
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_start + 32 >= _start, "toUint256_overflow");
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_start + 32 >= _start, "toBytes32_overflow");
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes_slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "petersburg",
  "libraries": {
    "@gnosis.pm/solidity-data-structures/contracts/libraries/IdToAddressBiMap.sol": {
      "IdToAddressBiMap": "0x5c4C6bf91240A5fdBfB9a1BEd8d43227046e2feA"
    },
    "@gnosis.pm/solidity-data-structures/contracts/libraries/IterableAppendOnlySet.sol": {
      "IterableAppendOnlySet": "0xc3F244bDD41Ac5c0E394bB7113c9A3B93665AA8e"
    }
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}