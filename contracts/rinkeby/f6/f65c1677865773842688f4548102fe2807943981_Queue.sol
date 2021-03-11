pragma solidity ^0.7.3;

import './interfaces/ITrading.sol';

contract Queue {

    /* ========== STRUCTS ========== */

    struct Order {
        address liquidator; // 20 bytes
        bytes12 symbol; // 12 bytes
        uint64 positionId; // 8 bytes
        uint64 margin; // 8 bytes
    }

    /* ========== STATE VARIABLES ========== */

    // Oracle network primary address
    address public oracle;

    address public trading;

    // ID of the first order in the queue
    uint256 public firstOrderId;

    // ID of the order to be queued next
    uint256 public nextOrderId;

    // The order queue. Maps an order ID to its struct
    mapping(uint256 => Order) private queue;

    address public owner;
    bool private initialized;

    event NewContracts(address oracle, address trading);

    /* ========== INITIALIZER ========== */

    function initialize() public {
        require(!initialized, '!initialized');
        initialized = true;
        owner = msg.sender;
        firstOrderId = 1;
        nextOrderId = 1;
    }

    /* ========== METHODS CALLED BY GOVERNANCE ========== */

    function registerContracts(
        address _oracle,
        address _trading
    ) external onlyOwner {
        oracle = _oracle;
        trading = _trading;
        emit NewContracts(_oracle, _trading);
    }

    /**
     * @notice Update the oracle network primary address.
     * @param _oracle The oracle address
     */

    /* ========== METHODS CALLED EXTERNALLY ========== */

    /**
     * @notice Called by the oracle network to get queued order symbols.
     * @return symbols List of symbols associated with the queued orders
     * @return firstId The (queue) ID of the first order in the queue
     * @return lastId The (queue) ID of the next order in the queue
     */
    function getQueuedOrders() external view returns (
        bytes32[] memory symbols,
        uint256 firstId,
        uint256 lastId
    ) {

        uint256 _queueLength = queueLength();

        // Initialize return arrays
        symbols = new bytes32[](_queueLength);

        if (_queueLength > 0) {

            uint256 mFirstOrderId = firstOrderId;
            uint256 mNextOrderId = nextOrderId;

            for (uint256 i = mFirstOrderId; i < mNextOrderId; i++) {
                symbols[i - mFirstOrderId] = bytes12(queue[i].symbol);
            }

        }

        return (
            symbols,
            firstOrderId,
            nextOrderId
        );

    }

    /**
     * @notice Called by Trading contract to queue an order for processing.
     * @param symbol Unique identifier of the product to trade
     * @param margin Margin associated with the order
     * @param positionId Target position ID if this order is updating an existing position
     * @param liquidator Liquidator's address
     * @return id The newly generated ID of the queued order
     */
    function queueOrder(
        bytes32 symbol,
        uint256 margin,
        uint256 positionId,
        address liquidator
    ) external onlyTrading returns (uint256 id) {

        uint256 mNextOrderId = nextOrderId;
        require(mNextOrderId - firstOrderId < maxQueueSize(), '!full');

        Order storage order = queue[mNextOrderId];
        nextOrderId = mNextOrderId + 1;

        order.symbol = bytes12(symbol);

        // Position update (close or liquidation)
        if (positionId > 0) {
            order.positionId = uint64(positionId);
            if (liquidator != address(0)) {
                order.liquidator = liquidator;
            } else {
                order.margin = uint64(margin);
            }
        }

        return mNextOrderId;

    }

    /**
     * @notice Called by the oracle network to set prices and process orders in the queue.
     * @param prices Array of prices mapping to each order in the queue
     * @param firstId First ID of corresponding order in the queue
     * @param lastId Last ID of corresponding order in the queue
     */
    function setPricesAndProcessQueue(
        uint256[] calldata prices,
        uint256 firstId,
        uint256 lastId
    ) external onlyOracle {

        require(firstId < lastId, '!range');
        require(prices.length > 0 && prices.length == (lastId - firstId), '!incompatible');
        require(firstId == firstOrderId, '!first_id');
        require(lastId <= nextOrderId, '!last_id');
        
        firstOrderId = lastId;

        uint256 i = 0;
        while (firstId < lastId) {

            Order memory order = queue[firstId];
            delete queue[firstId];
            
            processOrder(
                firstId,
                order,
                prices[i]
            );

            i++;
            firstId++;

        }

    }

    /* ========== METHODS CALLED INTERNALLY ========== */

    /**
     * @notice Called internally to process an order.
     * @param id Position ID
     * @param order Order struct
     * @param price Price set by oracle network
     */
    function processOrder(
        uint256 id,
        Order memory order,
        uint256 price
    ) internal {

        if (price != 0) {

            // Price was provided by the oracle network, attempt to execute trade

            try ITrading(trading).processOrder(
                id,
                order.symbol,
                price,
                order.margin,
                order.positionId,
                order.liquidator
            ) {} catch Error(string memory reason) {
                ITrading(trading).cancelOrder(
                    id,
                    order.positionId,
                    order.liquidator,
                    reason
                );
            } catch (bytes memory /*lowLevelData*/) {
                ITrading(trading).cancelOrder(
                    id,
                    order.positionId,
                    order.liquidator,
                    '!failed'
                );
            }

        } else {
            // Market is closed or oracle network price is unavailable
            ITrading(trading).cancelOrder(
                id,
                order.positionId,
                order.liquidator,
                '!unavailable'
            );
        }

    }

    /* Helpers */

    function queueLength() public view returns (uint256 length) {
        return nextOrderId - firstOrderId;
    }

    function processedOrdersCount() external view returns (uint256 count) {
        return firstOrderId;
    }

    function maxQueueSize() internal pure virtual returns (uint256 maxSize) {
        return 60;
    }

    /* Modifiers */

    modifier onlyOwner() {
        require(msg.sender == owner, '!authorized');
        _;
    }

    modifier onlyTrading() {
        require(msg.sender == trading, '!authorized');
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, '!authorized');
        _;
    }

}

pragma solidity ^0.7.3;

interface ITrading {

    function processOrder(uint256 id, bytes32 symbol, uint256 price, uint256 margin, uint256 positionId, address liquidator) external;
    function cancelOrder(uint256 id, uint256 positionId, address liquidator, string calldata reason) external;

}