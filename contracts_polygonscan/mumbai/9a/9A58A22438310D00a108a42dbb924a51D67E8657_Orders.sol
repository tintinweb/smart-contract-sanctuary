/**
 *Submitted for verification at polygonscan.com on 2021-09-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

struct PricingTableItem {
    uint256 minAmount;
    uint256 maxAmount;
    uint256 grade;
    uint256 minTenure;
    uint256 maxTenure;
    uint256 minAdvancedRatio;
    uint256 maxAdvancedRatio;
    uint256 minDiscountRange;
    uint256 maxDiscountRange;
    uint256 minFactoringFee;
    uint256 maxFactoringFee;
    bool actual;
}

interface IPricingTable {
    function getPricingTableItem(uint256 _id)
        external
        view
        returns (PricingTableItem memory);
}


struct OrderItem {
    uint256 amount;
    uint256 status;
    uint256 duration;
    uint256 grade;
    uint256 tenure;
    uint256 pricingId;
    address orderAddress;
}

struct OrderItemFinalOffer {
    uint256 factoringFee;
    uint256 discount;
    uint256 tenure;
    uint256 advancePercentage;
    uint256 reservePercentage;
    uint256 gracePeriod;
    address tokenAddress;
}

struct OrderItemAdvanceAllocated {
    string polytradeInvoiceNo;
    uint256 clientCreateDate;
    uint256 actualAmount;
    uint256 disbursingAdvanceDate;
    uint256 advancedAmount;
    uint256 reserveHeldAmount;
    uint256 dueDate;
    uint256 amountDue;
    uint256 totalFee;
}

struct OrderItemPaymentReceived {
    uint256 paymentDate;
    string paymentRefNo;
    uint256 receivedAmount;
    string appliedToInvoiceRefNo;
    int256 unAppliedOrShortAmount;
}
struct OrderItemRefunded {
    string invoiceRefNo;
    uint256 invoiceAmount;
    uint256 amountReceived;
    uint256 paymentReceivedDate;
    uint256 numberOfLateDays;
    uint256 fee;
    uint256 lateFee;
    uint256 netAmount;
    uint256 dateClosed;
}

interface IOrder {
    function getAmountsForTransfers(uint256 _id)
        external
        returns (
            address _tokenAddress,
            uint256 _amount,
            address _address
        );

    function changeStatusFromTreasury(uint256 _id, uint256 status)
        external
        returns (bool);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract Orders is Ownable, Pausable {
    IPricingTable private _pricingTable;
    mapping(uint256 => OrderItem) private orders;
    mapping(uint256 => OrderItemFinalOffer) private ordersFinalOffers;
    mapping(uint256 => OrderItemAdvanceAllocated)
        private ordersAdvancesAllocated;
    mapping(uint256 => OrderItemPaymentReceived) private ordersPaymentsReceived;
    mapping(uint256 => OrderItemRefunded) private ordersFundsRefunded;
    uint256 private ordersCount;
    address private _treasuryAddress;

    // getter for one order
    function getOneOrder(uint256 _id) external view returns (OrderItem memory) {
        return orders[_id];
    }

    // getter for ordersCount
    function getOrdersCount() external view returns (uint256) {
        return ordersCount;
    }

    // getter for pricing table inctance
    function getPricingTable() public view returns (IPricingTable) {
        return _pricingTable;
    }

    function setNewTreasuryAddress(address _newAddress)
        public
        onlyOwner
        returns (bool)
    {
        require(_newAddress != address(0), "Address cannot be zero");
        emit TreasuryAddressSet(address(_treasuryAddress), _newAddress);
        _treasuryAddress = _newAddress;
        return true;
    }

    // setter for pricing table contract address
    function setPricingTable(address _newPricingTableAddress)
        public
        onlyOwner
        returns (bool)
    {
        require(
            _newPricingTableAddress != address(0),
            "Address cannot be zero"
        );
        emit PricingTableSet(address(_pricingTable), _newPricingTableAddress);
        _pricingTable = IPricingTable(_newPricingTableAddress);
        return true;
    }

    function isInMinMaxRange(
        uint256 _check,
        uint256 _min,
        uint256 _max
    ) private pure returns (bool) {
        return _check <= _max && _check >= _min;
    }

    // check that order's arguments are fit selected pricing table item
    function orderFitsPricingTableItem(
        OrderItem memory order,
        PricingTableItem memory pricing
    ) internal pure returns (bool) {
        return
            isInMinMaxRange(
                order.amount,
                pricing.minAmount,
                pricing.maxAmount
            ) &&
            isInMinMaxRange(
                order.tenure,
                pricing.minTenure,
                pricing.maxTenure
            ) &&
            order.grade == pricing.grade &&
            pricing.actual;
    }

    // check that final offer order's state fits selected pricing table item
    function finalOfferFitsPricingTableItem(
        OrderItemFinalOffer memory order,
        PricingTableItem memory pricing
    ) internal pure returns (bool) {
        return
            isInMinMaxRange(
                order.factoringFee,
                pricing.minFactoringFee,
                pricing.maxFactoringFee
            ) &&
            isInMinMaxRange(
                order.discount,
                pricing.minDiscountRange,
                pricing.maxDiscountRange
            ) &&
            isInMinMaxRange(
                order.tenure,
                pricing.minAdvancedRatio,
                pricing.maxAdvancedRatio
            ) &&
            order.advancePercentage + order.reservePercentage == 100000;
    }

    // check that fund order's state fits selected pricing table item
    function orderFundAllocateFitsPricingTableItem(
        OrderItemAdvanceAllocated memory order,
        PricingTableItem memory pricing
    ) internal pure returns (bool) {
        return
            isInMinMaxRange(
                order.actualAmount,
                pricing.minAmount,
                pricing.maxAmount
            ) &&
            order.clientCreateDate > 0 &&
            order.dueDate > order.clientCreateDate;
        // TODO: what's more to check?
    }

    // check for order state doesn't goes down step-by-step
    function updateOrderStatus(uint256 _orderId, uint256 _newStatus) internal {
        require(
            _newStatus == orders[_orderId].status + 1,
            "Wrong status state"
        );
        orders[_orderId].status = _newStatus;
        emit OrderStatusUpdated(_orderId, _newStatus);
    }

    // create new order
    function newOrder(OrderItem memory _order)
        public
        whenNotPaused
        onlyOwner
        returns (uint256)
    {
        require(
            _order.amount > 0 && _order.status != 1,
            "Wrong order arguments"
        );
        require(
            orderFitsPricingTableItem(
                _order,
                getPricingTable().getPricingTableItem(_order.pricingId)
            ),
            "Not fits to pricing table"
        );
        _order.status = 1;
        orders[ordersCount++] = _order;
        emit NewOrder(ordersCount);
        return ordersCount;
    }

    // new state for order - final offer
    function orderFinalOffer(uint256 _id, OrderItemFinalOffer memory _order)
        public
        whenNotPaused
        onlyOwner
        returns (bool)
    {
        require(
            finalOfferFitsPricingTableItem(
                _order,
                getPricingTable().getPricingTableItem(orders[_id].pricingId)
            ),
            "Not fits to pricing table"
        );
        ordersFinalOffers[_id] = _order;
        updateOrderStatus(_id, 2);
        emit OrderFinalOffer(_id, _order);
        return true;
    }

    // new state for order - fund allocation. after this step Treasury can use order to send advance
    function orderFundAllocate(
        uint256 _id,
        OrderItemAdvanceAllocated memory _order
    ) public whenNotPaused onlyOwner {
        ordersAdvancesAllocated[_id] = _order;
        ordersAdvancesAllocated[_id].disbursingAdvanceDate = block.timestamp;

        require(
            orderFundAllocateFitsPricingTableItem(
                _order,
                getPricingTable().getPricingTableItem(orders[_id].pricingId)
            ),
            "Not fits to pricing table"
        );

        emit OrderFundAllocated(_id, _order);
        updateOrderStatus(_id, 3);
        // We are ready to send assets from treasury
        // now treasury can use order
        // update order's status
    }

    // new state for order - back payment received.
    function orderPaymentReceived(
        uint256 _id,
        OrderItemPaymentReceived memory _order
    ) public whenNotPaused onlyOwner {
        // TODO: may order be paid twice or more? - only one pay for now
        ordersPaymentsReceived[_id] = _order;
        emit OrderPaymentReceived(_id, _order);
        // update order's status
        updateOrderStatus(_id, 5);
    }

    // new state for order - we ready to send trade tokens to user
    function orderReserveFundAllocated(
        uint256 _id,
        OrderItemRefunded memory _order
    ) public whenNotPaused onlyOwner {
        ordersFundsRefunded[_id] = _order;
        emit OrderReserveFundAllocated(_id, _order);
        updateOrderStatus(_id, 6);
    }

    // getter for external calls from treasury
    function getAmountsForTransfers(uint256 _id)
        external
        view
        returns (
            address _tokenAddress,
            uint256 _amount,
            address _address
        )
    {
        return (
            ordersFinalOffers[_id].tokenAddress,
            ordersAdvancesAllocated[_id].advancedAmount * 10**15,
            orders[_id].orderAddress
        );
    }

    // Treasury can move order to new state
    function changeStatusFromTreasury(uint256 _id, uint256 status)
        external
        returns (bool)
    {
        require(msg.sender == _treasuryAddress, "Wrong treasury address");
        updateOrderStatus(_id, status);
        return true;
    }

    //events
    event PricingTableSet(address oldAddress, address newAddress);
    event TreasuryAddressSet(address oldAddress, address newAddress);
    event OrderStatusUpdated(uint256 _id, uint256 newStatus);
    event NewOrder(uint256 _id);
    event OrderFinalOffer(uint256 _id, OrderItemFinalOffer _order);

    event OrderFundAllocated(uint256 _id, OrderItemAdvanceAllocated _order);
    event OrderPaymentReceived(uint256 _id, OrderItemPaymentReceived _order);
    event OrderReserveFundAllocated(uint256 _id, OrderItemRefunded _order);
}