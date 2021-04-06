// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libraries/IdToAddressBiMap.sol";
import "../libraries/SafeCast.sol";
import "../libraries/IterableOrderedOrderSet.sol";

contract FairSale {
    using SafeERC20 for IERC20;
    using SafeMath for uint64;
    using SafeMath for uint96;
    using SafeMath for uint256;
    using SafeCast for uint256;
    using IterableOrderedOrderSet for IterableOrderedOrderSet.Data;
    using IterableOrderedOrderSet for bytes32;
    using IdToAddressBiMap for IdToAddressBiMap.Data;

    modifier atStageOrderPlacement() {
        require(
            block.timestamp < endDate,
            "no longer in order placement phase"
        );
        _;
    }

    modifier atStageOrderPlacementAndCancelation() {
        require(
            block.timestamp < orderCancellationEndDate,
            "no longer in order placement and cancelation phase"
        );
        _;
    }

    modifier atStageSolutionSubmission() {
        {
            uint256 endDate = endDate;
            require(
                block.timestamp >= endDate && clearingPriceOrder == bytes32(0),
                "Auction not in solution submission phase"
            );
        }
        _;
    }

    modifier atStageFinished() {
        require(clearingPriceOrder != bytes32(0), "Auction not yet finished");
        _;
    }

    event NewOrder(
        uint64 indexed ownerId,
        uint96 orderTokenOut,
        uint96 orderTokenIn
    );
    event CancellationOrder(
        uint64 indexed ownerId,
        uint96 orderTokenOut,
        uint96 orderTokenIn
    );
    event ClaimedFromOrder(
        uint64 indexed ownerId,
        uint96 orderTokenOut,
        uint96 orderTokenIn
    );
    event NewUser(uint64 indexed ownerId, address indexed userAddress);
    event InitializedSale(
        IERC20 indexed _tokenIn,
        IERC20 indexed _tokenOut,
        uint256 orderCancellationEndDate,
        uint256 endDate,
        uint96 _totalTokenOutAmount,
        uint96 _minBidAmountToReceive,
        uint256 minimumBiddingAmountPerOrder,
        uint256 minSellThreshold
    );
    event SaleCleared(
        uint96 auctionedTokens,
        uint96 soldBiddingTokens,
        bytes32 clearingOrder
    );
    event UserRegistration(address indexed user, uint64 ownerId);

    string public constant templateName = "FairSale";
    IERC20 public tokenIn;
    IERC20 public tokenOut;
    uint256 public orderCancellationEndDate;
    uint256 public auctionStartedDate;
    uint256 public endDate;
    bytes32 public initialAuctionOrder;
    uint256 public minimumBiddingAmountPerOrder;
    uint256 public interimSumBidAmount;
    bytes32 public interimOrder;
    bytes32 public clearingPriceOrder;
    uint96 public volumeClearingPriceOrder;
    bool public minSellThresholdNotReached;
    bool public isAtomicClosureAllowed;
    uint256 public feeNumerator;
    uint256 public minSellThreshold;

    IterableOrderedOrderSet.Data internal orders;
    IdToAddressBiMap.Data private registeredUsers;
    uint64 public numUsers;

    constructor() public {}

    /// @dev internal setup function to initialize the template, called by init()
    ///
    /// Warning: In case the auction is expected to raise more than
    /// 2^96 units of the tokenIn, don't start the auction, as
    /// it will not be settlable. This corresponds to about 79
    /// billion DAI.
    ///
    /// Prices between tokenIn and tokenOut are expressed by a
    /// fraction whose components are stored as uint96.
    ///
    /// @param _tokenIn token to make the bid in
    /// @param _tokenOut token to buy
    /// @param _orderCancelationPeriodDuration cancel order is allowed, but only during this duration
    /// @param _duration amount of tokens to be sold
    /// @param _totalTokenOutAmount total amount to sell
    /// @param _minBidAmountToReceive Minimum amount of biding token to receive at final point
    /// @param _minimumBiddingAmountPerOrder to limit number of orders to reduce gas cost for settelment
    /// @param _minSellThreshold for the sale, otherwise sale will not happen
    /// @param _isAtomicClosureAllowed allow atomic closer of the sale
    function initSale(
        IERC20 _tokenIn,
        IERC20 _tokenOut,
        uint256 _orderCancelationPeriodDuration,
        uint256 _duration,
        uint96 _totalTokenOutAmount,
        uint96 _minBidAmountToReceive,
        uint256 _minimumBiddingAmountPerOrder,
        uint256 _minSellThreshold,
        bool _isAtomicClosureAllowed
    ) internal {
        uint64 auctioneerId = getUserId(msg.sender);

        // deposits _totalTokenOutAmount + fees
        _tokenOut.safeTransferFrom(
            msg.sender,
            address(this),
            _totalTokenOutAmount.mul(FEE_DENOMINATOR.add(feeNumerator)).div(
                FEE_DENOMINATOR
            ) //[0]
        );
        require(_totalTokenOutAmount > 0, "cannot auction zero tokens");
        require(
            _minBidAmountToReceive > 0,
            "tokens cannot be auctioned for free"
        );
        require(
            _minimumBiddingAmountPerOrder > 0,
            "minimumBiddingAmountPerOrder is not allowed to be zero"
        );

        orders.initializeEmptyList();

        uint256 cancellationEndDate =
            block.timestamp + _orderCancelationPeriodDuration;

        endDate = block.timestamp + _duration;

        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
        orderCancellationEndDate = cancellationEndDate;
        auctionStartedDate = block.timestamp;

        initialAuctionOrder = IterableOrderedOrderSet.encodeOrder(
            auctioneerId,
            _totalTokenOutAmount,
            _minBidAmountToReceive
        );
        minimumBiddingAmountPerOrder = _minimumBiddingAmountPerOrder;
        interimSumBidAmount = 0;
        interimOrder = IterableOrderedOrderSet.QUEUE_START;
        clearingPriceOrder = bytes32(0);
        volumeClearingPriceOrder = 0;
        minSellThresholdNotReached = false;
        isAtomicClosureAllowed = _isAtomicClosureAllowed;
        minSellThreshold = _minSellThreshold;

        emit InitializedSale(
            _tokenIn,
            _tokenOut,
            orderCancellationEndDate,
            endDate,
            _totalTokenOutAmount,
            _minBidAmountToReceive,
            _minimumBiddingAmountPerOrder,
            _minSellThreshold
        );
    }

    uint256 public constant FEE_DENOMINATOR = 1000;
    uint64 public feeReceiverUserId = 1;

    /// @dev public function to set orders as a list
    /// @param _ordersTokenOut uint96[] a list of orders, the tokenOut part
    /// @param _ordersTokenIn uint96[] a list of orders, the tokenIn part
    /// @param _prevOrders uint96[] a list of previous orders
    /// @return ownerId uint64
    function placeOrders(
        uint96[] memory _ordersTokenOut,
        uint96[] memory _ordersTokenIn,
        bytes32[] memory _prevOrders
    ) public atStageOrderPlacement() returns (uint64 ownerId) {
        return _placeOrders(_ordersTokenOut, _ordersTokenIn, _prevOrders);
    }

    /// @dev internale function to set orders as a list
    /// @param _ordersTokenOut uint96[] a list of orders, the tokenOut part
    /// @param _ordersTokenIn uint96[] a list of orders, the tokenIn part
    /// @param _prevOrders uint96[] a list of previous orders
    function _placeOrders(
        uint96[] memory _ordersTokenOut,
        uint96[] memory _ordersTokenIn,
        bytes32[] memory _prevOrders
    ) internal returns (uint64 ownerId) {
        (, uint96 totalTokenOutAmount, uint96 minAmountToReceive) =
            initialAuctionOrder.decodeOrder();

        uint256 sumOrdersTokenIn = 0;
        ownerId = getUserId(msg.sender);
        for (uint256 i = 0; i < _ordersTokenOut.length; i++) {
            require(
                _ordersTokenOut[i].mul(minAmountToReceive) <
                    totalTokenOutAmount.mul(_ordersTokenIn[i]),
                "limit price not better than mimimal offer"
            );
            // _orders should have a minimum bid size in order to limit the gas
            // required to compute the final price of the auction.
            require(
                _ordersTokenIn[i] > minimumBiddingAmountPerOrder,
                "order too small"
            );
            bool success =
                orders.insert(
                    IterableOrderedOrderSet.encodeOrder(
                        ownerId,
                        _ordersTokenOut[i],
                        _ordersTokenIn[i]
                    ),
                    _prevOrders[i]
                );
            if (success) {
                sumOrdersTokenIn = sumOrdersTokenIn.add(_ordersTokenIn[i]);
                emit NewOrder(ownerId, _ordersTokenOut[i], _ordersTokenIn[i]);
            }
        }
        tokenIn.safeTransferFrom(msg.sender, address(this), sumOrdersTokenIn); //[1]
    }

    /// @dev cancel orders: will widthdraw tokenIn used in the order
    /// @param _orders bytes32[] a list of orders to cancel
    function cancelOrders(bytes32[] memory _orders)
        public
        atStageOrderPlacementAndCancelation()
    {
        uint64 ownerId = getUserId(msg.sender);
        uint256 claimableAmount = 0;
        for (uint256 i = 0; i < _orders.length; i++) {
            // Note: we keep the back pointer of the deleted element so that
            // it can be used as a reference point to insert a new node.
            bool success = orders.removeKeepHistory(_orders[i]);
            if (success) {
                (
                    uint64 ownerIdOfIter,
                    uint96 orderTokenOut,
                    uint96 orderTokenIn
                ) = _orders[i].decodeOrder();
                require(
                    ownerIdOfIter == ownerId,
                    "Only the user can cancel his orders"
                );
                claimableAmount = claimableAmount.add(orderTokenIn);
                emit CancellationOrder(ownerId, orderTokenOut, orderTokenIn);
            }
        }
        tokenIn.safeTransfer(msg.sender, claimableAmount); //[2]
    }

    /// @dev ??? @nicoelzer, where is this used ???
    /// @param iterationSteps uint256
    function precalculateSellAmountSum(uint256 iterationSteps)
        public
        atStageSolutionSubmission()
    {
        (, uint96 totalTokenOutAmount, ) = initialAuctionOrder.decodeOrder();
        uint256 sumBidAmount = interimSumBidAmount;
        bytes32 iterOrder = interimOrder;

        for (uint256 i = 0; i < iterationSteps; i++) {
            iterOrder = orders.next(iterOrder);
            (, , uint96 orderTokenIn) = iterOrder.decodeOrder();
            sumBidAmount = sumBidAmount.add(orderTokenIn);
        }

        require(
            iterOrder != IterableOrderedOrderSet.QUEUE_END,
            "reached end of order list"
        );

        // it is checked that not too many iteration steps were taken:
        // require that the sum of SellAmounts times the price of the last order
        // is not more than initially sold amount
        (, uint96 orderTokenOut, uint96 orderTokenIn) = iterOrder.decodeOrder();
        require(
            sumBidAmount.mul(orderTokenOut) <
                totalTokenOutAmount.mul(orderTokenIn),
            "too many orders summed up"
        );

        interimSumBidAmount = sumBidAmount;
        interimOrder = iterOrder;
    }

    /// @dev function settling the auction and calculating the price if only one bid is made // ??? nico
    /// @param _ordersTokenOut uint96[]  order which is at clearing price
    /// @param _ordersTokenOut uint96[]  order which is at clearing price
    /// @param _prevOrder uint96[]  order which is at clearing price
    function settleAuctionAtomically(
        uint96[] memory _ordersTokenOut,
        uint96[] memory _ordersTokenIn,
        bytes32[] memory _prevOrder
    ) public atStageSolutionSubmission() {
        require(
            isAtomicClosureAllowed,
            "not allowed to settle auction atomically"
        );
        require(
            _ordersTokenOut.length == 1 && _ordersTokenIn.length == 1,
            "Only one order can be placed atomically"
        );
        uint64 ownerId = getUserId(msg.sender);
        require(
            interimOrder.smallerThan(
                IterableOrderedOrderSet.encodeOrder(
                    ownerId,
                    _ordersTokenOut[0],
                    _ordersTokenIn[0]
                )
            ),
            "precalculateSellAmountSum is already too advanced"
        );
        _placeOrders(_ordersTokenOut, _ordersTokenIn, _prevOrder);
        bytes32 _order =
            IterableOrderedOrderSet.encodeOrder(
                ownerId,
                _ordersTokenOut[0],
                _ordersTokenIn[0]
            );
        settleAuction();
    }

    /// @dev function settling the auction and calculating the price
    /// @return clearingOrder bytes32 order which is at clearing price
    function settleAuction()
        public
        atStageSolutionSubmission()
        returns (bytes32 clearingOrder)
    {
        (
            uint64 auctioneerId,
            uint96 fullAuctionAmountToSell,
            uint96 minBidAmountToReceive
        ) = initialAuctionOrder.decodeOrder();

        uint256 currentBidSum = interimSumBidAmount;
        bytes32 currentOrder = interimOrder;
        bytes32 nextOrder = currentOrder;
        uint256 orderTokenOut;
        uint256 orderTokenIn;
        uint96 fillVolumeOfAuctioneerOrder = fullAuctionAmountToSell;
        // Sum order up, until fullAuctionAmountToSell is fully bought or queue end is reached
        do {
            nextOrder = orders.next(nextOrder);
            if (nextOrder == IterableOrderedOrderSet.QUEUE_END) {
                break;
            }
            currentOrder = nextOrder;
            (, orderTokenOut, orderTokenIn) = currentOrder.decodeOrder();
            currentBidSum = currentBidSum.add(orderTokenIn);
        } while (
            currentBidSum.mul(orderTokenOut) <
                fullAuctionAmountToSell.mul(orderTokenIn)
        );

        if (
            currentBidSum > 0 &&
            currentBidSum.mul(orderTokenOut) >=
            fullAuctionAmountToSell.mul(orderTokenIn)
        ) {
            // All considered/summed orders are sufficient to close the auction fully
            // at price between current and previous orders.
            uint256 uncoveredBids =
                currentBidSum.sub(
                    fullAuctionAmountToSell.mul(orderTokenIn).div(orderTokenOut)
                );

            if (orderTokenIn >= uncoveredBids) {
                //[13]
                // Auction fully filled via partial match of currentOrder
                uint256 amountInClearingOrder = orderTokenIn.sub(uncoveredBids);
                volumeClearingPriceOrder = amountInClearingOrder.toUint96();
                currentBidSum = currentBidSum.sub(uncoveredBids);
                clearingOrder = currentOrder;
            } else {
                //[14]
                // Auction fully filled via price strictly between currentOrder and the order
                // immediately before. For a proof
                currentBidSum = currentBidSum.sub(orderTokenIn);
                clearingOrder = IterableOrderedOrderSet.encodeOrder(
                    0,
                    fullAuctionAmountToSell,
                    currentBidSum.toUint96()
                );
            }
        } else {
            // All considered/summed orders are not sufficient to close the auction fully at price of last order //[18]
            // Either a higher price must be used or auction is only partially filled

            if (currentBidSum > minBidAmountToReceive) {
                //[15]
                // Price higher than last order would fill the auction
                clearingOrder = IterableOrderedOrderSet.encodeOrder(
                    0,
                    fullAuctionAmountToSell,
                    currentBidSum.toUint96()
                );
            } else {
                //[16]
                // Even at the initial auction price, the auction is partially filled
                clearingOrder = IterableOrderedOrderSet.encodeOrder(
                    0,
                    fullAuctionAmountToSell,
                    minBidAmountToReceive
                );
                fillVolumeOfAuctioneerOrder = currentBidSum
                    .mul(fullAuctionAmountToSell)
                    .div(minBidAmountToReceive)
                    .toUint96();
            }
        }
        clearingPriceOrder = clearingOrder;

        if (minSellThreshold > currentBidSum) {
            minSellThresholdNotReached = true;
        }
        processFeesAndFunds(
            fillVolumeOfAuctioneerOrder,
            auctioneerId,
            fullAuctionAmountToSell
        );
        emit SaleCleared(
            fillVolumeOfAuctioneerOrder,
            uint96(currentBidSum),
            clearingOrder
        );
        // Gas refunds
        initialAuctionOrder = bytes32(0);
        interimOrder = bytes32(0);
        interimSumBidAmount = uint256(0);
        minimumBiddingAmountPerOrder = uint256(0);
    }

    /// @dev claim the bought tokenOut and get the change back in tokenIn  after sale is over
    /// @param _orders bytes32[] a list of orders to cancel
    /// @return sumTokenOutAmount uint256, sumTokenInAmount uint256
    function claimFromParticipantOrder(bytes32[] memory _orders)
        public
        atStageFinished()
        returns (uint256 sumTokenOutAmount, uint256 sumTokenInAmount)
    {
        for (uint256 i = 0; i < _orders.length; i++) {
            // Note: we don't need to keep any information about the node since
            // no new elements need to be inserted.
            require(orders.remove(_orders[i]), "order is no longer claimable");
        }
        (, uint96 priceNumerator, uint96 priceDenominator) =
            clearingPriceOrder.decodeOrder();
        (uint64 ownerId, , ) = _orders[0].decodeOrder();
        for (uint256 i = 0; i < _orders.length; i++) {
            (uint64 ownerIdOrder, uint96 orderTokenOut, uint96 orderTokenIn) =
                _orders[i].decodeOrder();
            require(
                ownerIdOrder == ownerId,
                "only allowed to claim for same user"
            );
            if (minSellThresholdNotReached) {
                //[10]
                sumTokenInAmount = sumTokenInAmount.add(orderTokenIn);
            } else {
                //[23]
                if (_orders[i] == clearingPriceOrder) {
                    //[25]
                    sumTokenOutAmount = sumTokenOutAmount.add(
                        volumeClearingPriceOrder.mul(priceNumerator).div(
                            priceDenominator
                        )
                    );
                    sumTokenInAmount = sumTokenInAmount.add(
                        orderTokenIn.sub(volumeClearingPriceOrder)
                    );
                } else {
                    if (_orders[i].smallerThan(clearingPriceOrder)) {
                        //[17]
                        sumTokenOutAmount = sumTokenOutAmount.add(
                            orderTokenIn.mul(priceNumerator).div(
                                priceDenominator
                            )
                        );
                    } else {
                        //[24]
                        sumTokenInAmount = sumTokenInAmount.add(orderTokenIn);
                    }
                }
            }
            emit ClaimedFromOrder(ownerId, orderTokenOut, orderTokenIn);
        }
        sendOutTokens(sumTokenOutAmount, sumTokenInAmount, ownerId); //[3]
    }

    /// @dev processes funds and fees after the sale finished
    /// @param fillVolumeOfAuctioneerOrder uint256
    /// @param auctioneerId uint64 id of the address who did initiate the sale
    /// @param fullAuctionAmountToSell uint96
    function processFeesAndFunds(
        uint256 fillVolumeOfAuctioneerOrder,
        uint64 auctioneerId,
        uint96 fullAuctionAmountToSell
    ) internal {
        uint256 feeAmount =
            fullAuctionAmountToSell.mul(feeNumerator).div(FEE_DENOMINATOR); //[20]
        if (minSellThresholdNotReached) {
            sendOutTokens(
                fullAuctionAmountToSell.add(feeAmount),
                0,
                auctioneerId
            ); //[4]
        } else {
            //[11]
            (, uint96 priceNumerator, uint96 priceDenominator) =
                clearingPriceOrder.decodeOrder();
            uint256 unsettledTokens =
                fullAuctionAmountToSell.sub(fillVolumeOfAuctioneerOrder);
            uint256 tokenOutAmount =
                unsettledTokens.add(
                    feeAmount.mul(unsettledTokens).div(fullAuctionAmountToSell)
                );
            uint256 tokenInAmount =
                fillVolumeOfAuctioneerOrder.mul(priceDenominator).div(
                    priceNumerator
                );
            sendOutTokens(tokenOutAmount, tokenInAmount, auctioneerId); //[5]
            sendOutTokens(
                feeAmount.mul(fillVolumeOfAuctioneerOrder).div(
                    fullAuctionAmountToSell
                ),
                0,
                feeReceiverUserId
            ); //[7]
        }
    }

    /// @dev send tokenOut and tokenIn
    /// @param tokenOutAmount uint256 amount of tokenOut to send
    /// @param tokenInAmount uint256 amount of tokenIn to send
    /// @param ownerId uint64 id of address of owner
    function sendOutTokens(
        uint256 tokenOutAmount,
        uint256 tokenInAmount,
        uint64 ownerId
    ) internal {
        address userAddress = registeredUsers.getAddressAt(ownerId);
        if (tokenOutAmount > 0) {
            tokenOut.safeTransfer(userAddress, tokenOutAmount);
        }
        if (tokenInAmount > 0) {
            tokenIn.safeTransfer(userAddress, tokenInAmount);
        }
    }

    /// @dev add address to ownerId/address mapping
    /// @param user address of a account making a bid
    /// @return ownerId uint64 id of address of owner
    function registerUser(address user) public returns (uint64 ownerId) {
        numUsers = numUsers.add(1).toUint64();
        require(
            registeredUsers.insert(numUsers, user),
            "User already registered"
        );
        ownerId = numUsers;
        emit UserRegistration(user, ownerId);
    }

    /// @dev get address from ownerId/address mapping
    /// @param user address
    /// @return ownerId uint64 id of address of owner
    function getUserId(address user) public returns (uint64 ownerId) {
        if (registeredUsers.hasAddress(user)) {
            ownerId = registeredUsers.getId(user);
        } else {
            ownerId = registerUser(user);
            emit NewUser(ownerId, user);
        }
    }

    /// @dev read how much time is left until sale is over
    /// @return uint256 seconds until end
    function getSecondsRemainingInBatch() public view returns (uint256) {
        if (endDate <= block.timestamp) {
            return 0;
        }
        return endDate.sub(block.timestamp);
    }

    /// @dev test if order is present
    /// @param _order bytes32
    /// @return bool
    function containsOrder(bytes32 _order) public view returns (bool) {
        return orders.contains(_order);
    }

    function init(bytes calldata _data) public {
        (
            IERC20 _tokenIn,
            IERC20 _tokenOut,
            uint256 _orderCancelationPeriodDuration,
            uint256 _duration,
            uint96 _totalTokenOutAmount,
            uint96 _minBidAmountToReceive,
            uint256 _minimumBiddingAmountPerOrder,
            uint256 _minSellThreshold,
            bool _isAtomicClosureAllowed
        ) =
            abi.decode(
                _data,
                (
                    IERC20,
                    IERC20,
                    uint256,
                    uint256,
                    uint96,
                    uint96,
                    uint256,
                    uint256,
                    bool
                )
            );

        initSale(
            _tokenIn,
            _tokenOut,
            _orderCancelationPeriodDuration,
            _duration,
            _totalTokenOutAmount,
            _minBidAmountToReceive,
            _minimumBiddingAmountPerOrder,
            _minSellThreshold,
            _isAtomicClosureAllowed
        );
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity ^0.6.0;

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Contract does not have test coverage, as it was nearly copied from:
// https://github.com/gnosis/solidity-data-structures/blob/master/contracts/libraries/IdToAddressBiMap.sol
// The only change is uint16 -> uint64
///////////////////////////////////////////////////////////////////////////////////////////////////////////

library IdToAddressBiMap {
    struct Data {
        mapping(uint64 => address) idToAddress;
        mapping(address => uint64) addressToId;
    }

    function hasId(Data storage self, uint64 id) internal view returns (bool) {
        return self.idToAddress[id + 1] != address(0);
    }

    function hasAddress(Data storage self, address addr)
        internal
        view
        returns (bool)
    {
        return self.addressToId[addr] != 0;
    }

    function getAddressAt(Data storage self, uint64 id)
        internal
        view
        returns (address)
    {
        require(hasId(self, id), "Must have ID to get Address");
        return self.idToAddress[id + 1];
    }

    function getId(Data storage self, address addr)
        internal
        view
        returns (uint64)
    {
        require(hasAddress(self, addr), "Must have Address to get ID");
        return self.addressToId[addr] - 1;
    }

    function insert(
        Data storage self,
        uint64 id,
        address addr
    ) internal returns (bool) {
        require(addr != address(0), "Cannot insert zero address");
        require(id != uint64(-1), "Cannot insert max uint64");
        // Ensure bijectivity of the mappings
        if (
            self.addressToId[addr] != 0 ||
            self.idToAddress[id + 1] != address(0)
        ) {
            return false;
        }
        self.idToAddress[id + 1] = addr;
        self.addressToId[addr] = id + 1;
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Logic was copied and modified from here: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/SafeCast.sol
 */
library SafeCast {
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value < 2**96, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";

library IterableOrderedOrderSet {
    using SafeMath for uint96;
    using IterableOrderedOrderSet for bytes32;

    // represents smallest possible value for an order under comparison of fn smallerThan()
    bytes32 internal constant QUEUE_START =
        0x0000000000000000000000000000000000000000000000000000000000000001;
    // represents highest possible value for an order under comparison of fn smallerThan()
    bytes32 internal constant QUEUE_END =
        0xffffffffffffffffffffffffffffffffffffffff000000000000000000000001;

    /// The struct is used to implement a modified version of a doubly linked
    /// list with sorted elements. The list starts from QUEUE_START to
    /// QUEUE_END, and each node keeps track of its predecessor and successor.
    /// Nodes can be added or removed.
    ///
    /// `next` and `prev` have a different role. The list is supposed to be
    /// traversed with `next`. If `next` is empty, the node is not part of the
    /// list. However, `prev` might be set for elements that are not in the
    /// list, which is why it should not be used for traversing. Having a `prev`
    /// set for elements not in the list is used to keep track of the history of
    /// the position in the list of a removed element.
    struct Data {
        mapping(bytes32 => bytes32) nextMap;
        mapping(bytes32 => bytes32) prevMap;
    }

    struct Order {
        uint64 owner;
        uint96 amountToBuy;
        uint96 amountToBid;
    }

    function initializeEmptyList(Data storage self) internal {
        self.nextMap[QUEUE_START] = QUEUE_END;
        self.prevMap[QUEUE_END] = QUEUE_START;
    }

    function isEmpty(Data storage self) internal view returns (bool) {
        return self.nextMap[QUEUE_START] == QUEUE_END;
    }

    function insert(
        Data storage self,
        bytes32 elementToInsert,
        bytes32 elementBeforeNewOne
    ) internal returns (bool) {
        (, , uint96 denominator) = decodeOrder(elementToInsert);
        require(denominator != uint96(0), "Inserting zero is not supported");
        require(
            elementToInsert != QUEUE_START && elementToInsert != QUEUE_END,
            "Inserting element is not valid"
        );
        if (contains(self, elementToInsert)) {
            return false;
        }
        if (
            elementBeforeNewOne != QUEUE_START &&
            self.prevMap[elementBeforeNewOne] == bytes32(0)
        ) {
            return false;
        }
        if (!elementBeforeNewOne.smallerThan(elementToInsert)) {
            return false;
        }

        // `elementBeforeNewOne` might have been removed during the time it
        // took to the transaction calling this function to be mined, so
        // the new order cannot be appended directly to this. We follow the
        // history of previous links backwards until we find an element in
        // the list from which to start our search.
        // Note that following the link backwards returns elements that are
        // before `elementBeforeNewOne` in sorted order.
        while (self.nextMap[elementBeforeNewOne] == bytes32(0)) {
            elementBeforeNewOne = self.prevMap[elementBeforeNewOne];
        }

        // `elementBeforeNewOne` belongs now to the linked list. We search the
        // largest entry that is smaller than the element to insert.
        bytes32 previous;
        bytes32 current = elementBeforeNewOne;
        do {
            previous = current;
            current = self.nextMap[current];
        } while (current.smallerThan(elementToInsert));
        // Note: previous < elementToInsert < current
        self.nextMap[previous] = elementToInsert;
        self.prevMap[current] = elementToInsert;
        self.prevMap[elementToInsert] = previous;
        self.nextMap[elementToInsert] = current;
        return true;
    }

    /// The element is removed from the linked list, but the node retains
    /// information on which predecessor it had, so that a node in the chain
    /// can be reached by following the predecessor chain of deleted elements.
    function removeKeepHistory(Data storage self, bytes32 elementToRemove)
        internal
        returns (bool)
    {
        if (!contains(self, elementToRemove)) {
            return false;
        }
        bytes32 previousElement = self.prevMap[elementToRemove];
        bytes32 nextElement = self.nextMap[elementToRemove];
        self.nextMap[previousElement] = nextElement;
        self.prevMap[nextElement] = previousElement;
        self.nextMap[elementToRemove] = bytes32(0);
        return true;
    }

    /// Remove an element from the chain, clearing all related storage.
    /// Note that no elements should be inserted using as a reference point a
    /// node deleted after calling `remove`, since an element in the `prev`
    /// chain might be missing.
    function remove(Data storage self, bytes32 elementToRemove)
        internal
        returns (bool)
    {
        bool result = removeKeepHistory(self, elementToRemove);
        if (result) {
            self.prevMap[elementToRemove] = bytes32(0);
        }
        return result;
    }

    function contains(Data storage self, bytes32 value)
        internal
        view
        returns (bool)
    {
        if (value == QUEUE_START) {
            return false;
        }
        // Note: QUEUE_END is not contained in the list since it has no
        // successor.
        return self.nextMap[value] != bytes32(0);
    }

    // @dev orders are ordered by
    // 1. their price - amountToBuy/amountToBid and
    // 2. their userId,
    function smallerThan(bytes32 orderLeft, bytes32 orderRight)
        internal
        pure
        returns (bool)
    {
        (
            uint64 userIdLeft,
            uint96 priceNumeratorLeft,
            uint96 priceDenominatorLeft
        ) = decodeOrder(orderLeft);
        (
            uint64 userIdRight,
            uint96 priceNumeratorRight,
            uint96 priceDenominatorRight
        ) = decodeOrder(orderRight);

        if (
            priceNumeratorLeft.mul(priceDenominatorRight) <
            priceNumeratorRight.mul(priceDenominatorLeft)
        ) return true;
        if (
            priceNumeratorLeft.mul(priceDenominatorRight) >
            priceNumeratorRight.mul(priceDenominatorLeft)
        ) return false;

        require(
            userIdLeft != userIdRight,
            "user is not allowed to place same order twice"
        );
        if (userIdLeft < userIdRight) {
            return true;
        }
        return false;
    }

    function first(Data storage self) internal view returns (bytes32) {
        require(!isEmpty(self), "Trying to get first from empty set");
        return self.nextMap[QUEUE_START];
    }

    function next(Data storage self, bytes32 value)
        internal
        view
        returns (bytes32)
    {
        require(value != QUEUE_END, "Trying to get next of last element");
        bytes32 nextElement = self.nextMap[value];
        require(
            nextElement != bytes32(0),
            "Trying to get next of non-existent element"
        );
        return nextElement;
    }

    function decodeOrder(bytes32 _orderData)
        internal
        pure
        returns (
            uint64 userId,
            uint96 amountToBuy,
            uint96 amountToBid
        )
    {
        // Note: converting to uint discards the binary digits that do not fit
        // the type.
        userId = uint64(uint256(_orderData) >> 192);
        amountToBuy = uint96(uint256(_orderData) >> 96);
        amountToBid = uint96(uint256(_orderData));
    }

    function encodeOrder(
        uint64 userId,
        uint96 amountToBuy,
        uint96 amountToBid
    ) internal pure returns (bytes32) {
        return
            bytes32(
                (uint256(userId) << 192) +
                    (uint256(amountToBuy) << 96) +
                    uint256(amountToBid)
            );
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}