pragma solidity 0.4.18;

// File: contracts/PermissionGroups.sol

contract PermissionGroups {

    address public admin;
    address public pendingAdmin;
    mapping(address=>bool) internal operators;
    mapping(address=>bool) internal alerters;
    address[] internal operatorsGroup;
    address[] internal alertersGroup;
    uint constant internal MAX_GROUP_SIZE = 50;

    function PermissionGroups() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender]);
        _;
    }

    modifier onlyAlerter() {
        require(alerters[msg.sender]);
        _;
    }

    function getOperators () external view returns(address[]) {
        return operatorsGroup;
    }

    function getAlerters () external view returns(address[]) {
        return alertersGroup;
    }

    event TransferAdminPending(address pendingAdmin);

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        TransferAdminPending(pendingAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        TransferAdminPending(newAdmin);
        AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    event AdminClaimed( address newAdmin, address previousAdmin);

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender);
        AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    event AlerterAdded (address newAlerter, bool isAdd);

    function addAlerter(address newAlerter) public onlyAdmin {
        require(!alerters[newAlerter]); // prevent duplicates.
        require(alertersGroup.length < MAX_GROUP_SIZE);

        AlerterAdded(newAlerter, true);
        alerters[newAlerter] = true;
        alertersGroup.push(newAlerter);
    }

    function removeAlerter (address alerter) public onlyAdmin {
        require(alerters[alerter]);
        alerters[alerter] = false;

        for (uint i = 0; i < alertersGroup.length; ++i) {
            if (alertersGroup[i] == alerter) {
                alertersGroup[i] = alertersGroup[alertersGroup.length - 1];
                alertersGroup.length--;
                AlerterAdded(alerter, false);
                break;
            }
        }
    }

    event OperatorAdded(address newOperator, bool isAdd);

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator]); // prevent duplicates.
        require(operatorsGroup.length < MAX_GROUP_SIZE);

        OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    function removeOperator (address operator) public onlyAdmin {
        require(operators[operator]);
        operators[operator] = false;

        for (uint i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.length -= 1;
                OperatorAdded(operator, false);
                break;
            }
        }
    }
}

// File: contracts/permissionless/OrderListInterface.sol

interface OrderListInterface {
    function getOrderDetails(uint32 orderId) public view returns (address, uint128, uint128, uint32, uint32);
    function add(address maker, uint32 orderId, uint128 srcAmount, uint128 dstAmount) public returns (bool);
    function remove(uint32 orderId) public returns (bool);
    function update(uint32 orderId, uint128 srcAmount, uint128 dstAmount) public returns (bool);
    function getFirstOrder() public view returns(uint32 orderId, bool isEmpty);
    function allocateIds(uint32 howMany) public returns(uint32);
    function findPrevOrderId(uint128 srcAmount, uint128 dstAmount) public view returns(uint32);

    function addAfterId(address maker, uint32 orderId, uint128 srcAmount, uint128 dstAmount, uint32 prevId) public
        returns (bool);

    function updateWithPositionHint(uint32 orderId, uint128 srcAmount, uint128 dstAmount, uint32 prevId) public
        returns(bool, uint);
}

// File: contracts/permissionless/OrderList.sol

contract OrderList is PermissionGroups, OrderListInterface {

    struct Order {
        address maker;
        uint32 prevId;
        uint32 nextId;
        uint128 srcAmount;
        uint128 dstAmount;
    }

    mapping (uint32 => Order) public orders;

    // Results of calling updateWithPositionHint.
    uint constant public UPDATE_ONLY_AMOUNTS = 0;
    uint constant public UPDATE_MOVE_ORDER = 1;
    uint constant public UPDATE_FAILED = 2;

    uint32 constant public TAIL_ID = 1;
    uint32 constant public HEAD_ID = 2;

    uint32 public nextFreeId = 3;

    function OrderList(address _admin) public {
        require(_admin != address(0));

        admin = _admin;

        // Initializing a "dummy" order as HEAD.
        orders[HEAD_ID].maker = 0;
        orders[HEAD_ID].prevId = 0;
        orders[HEAD_ID].nextId = TAIL_ID;
        orders[HEAD_ID].srcAmount = 0;
        orders[HEAD_ID].dstAmount = 0;
    }

    function getOrderDetails(uint32 orderId)
        public
        view
        returns (
            address maker,
            uint128 srcAmount,
            uint128 dstAmount,
            uint32 prevId,
            uint32 nextId
        )
    {
        Order storage order = orders[orderId];

        maker = order.maker;
        srcAmount = order.srcAmount;
        dstAmount = order.dstAmount;
        prevId = order.prevId;
        nextId = order.nextId;
    }

    function add(
        address maker,
        uint32 orderId,
        uint128 srcAmount,
        uint128 dstAmount
    )
        public
        onlyAdmin
        returns(bool)
    {
        require(orderId != 0 && orderId != HEAD_ID && orderId != TAIL_ID);

        uint32 prevId = findPrevOrderId(srcAmount, dstAmount);
        return addAfterValidId(maker, orderId, srcAmount, dstAmount, prevId);
    }

    // Returns false if provided with bad hint.
    function addAfterId(
        address maker,
        uint32 orderId,
        uint128 srcAmount,
        uint128 dstAmount,
        uint32 prevId
    )
        public
        onlyAdmin
        returns (bool)
    {
        uint32 nextId = orders[prevId].nextId;
        if (!isRightPosition(srcAmount, dstAmount, prevId, nextId)) {
            return false;
        }
        return addAfterValidId(maker, orderId, srcAmount, dstAmount, prevId);
    }

    function remove(uint32 orderId) public onlyAdmin returns (bool) {
        verifyCanRemoveOrderById(orderId);

        // Disconnect order from list
        Order storage order = orders[orderId];
        orders[order.prevId].nextId = order.nextId;
        orders[order.nextId].prevId = order.prevId;

        // Mark deleted order
        order.prevId = TAIL_ID;
        order.nextId = HEAD_ID;

        return true;
    }

    function update(uint32 orderId, uint128 srcAmount, uint128 dstAmount)
        public
        onlyAdmin
        returns(bool)
    {
        address maker = orders[orderId].maker;
        require(remove(orderId));
        require(add(maker, orderId, srcAmount, dstAmount));

        return true;
    }

    // Returns false if provided with a bad hint.
    function updateWithPositionHint(
        uint32 orderId,
        uint128 updatedSrcAmount,
        uint128 updatedDstAmount,
        uint32 updatedPrevId
    )
        public
        onlyAdmin
        returns (bool, uint)
    {
        require(orderId != 0 && orderId != HEAD_ID && orderId != TAIL_ID);

        // Normal orders usually cannot serve as their own previous order.
        // For further discussion see Heinlein&#39;s &#39;—All You Zombies—&#39;.
        require(orderId != updatedPrevId);

        uint32 nextId;

        // updatedPrevId is the intended prevId of the order, after updating its
        // values.
        // If it is the same as the current prevId of the order, the order does
        // not need to change place in the list, only update its amounts.
        if (orders[orderId].prevId == updatedPrevId) {
            nextId = orders[orderId].nextId;
            if (isRightPosition(
                updatedSrcAmount,
                updatedDstAmount,
                updatedPrevId,
                nextId)
            ) {
                orders[orderId].srcAmount = updatedSrcAmount;
                orders[orderId].dstAmount = updatedDstAmount;
                return (true, UPDATE_ONLY_AMOUNTS);
            }
        } else {
            nextId = orders[updatedPrevId].nextId;
            if (isRightPosition(
                updatedSrcAmount,
                updatedDstAmount,
                updatedPrevId,
                nextId)
            ) {
                // Let&#39;s move the order to the hinted position.
                address maker = orders[orderId].maker;
                require(remove(orderId));
                require(
                    addAfterValidId(
                        maker,
                        orderId,
                        updatedSrcAmount,
                        updatedDstAmount,
                        updatedPrevId
                    )
                );
                return (true, UPDATE_MOVE_ORDER);
            }
        }

        // bad hint.
        return (false, UPDATE_FAILED);
    }

    function allocateIds(uint32 howMany) public onlyAdmin returns(uint32) {
        uint32 firstId = nextFreeId;
        require(nextFreeId + howMany >= nextFreeId);
        nextFreeId += howMany;
        return firstId;
    }

    function compareOrders(
        uint128 srcAmount1,
        uint128 dstAmount1,
        uint128 srcAmount2,
        uint128 dstAmount2
    )
        public
        pure
        returns(int)
    {
        uint256 s1 = srcAmount1;
        uint256 d1 = dstAmount1;
        uint256 s2 = srcAmount2;
        uint256 d2 = dstAmount2;

        if (s2 * d1 < s1 * d2) return -1;
        if (s2 * d1 > s1 * d2) return 1;
        return 0;
    }

    function findPrevOrderId(uint128 srcAmount, uint128 dstAmount)
        public
        view
        returns(uint32)
    {
        uint32 currId = HEAD_ID;
        Order storage curr = orders[currId];

        while (curr.nextId != TAIL_ID) {
            currId = curr.nextId;
            curr = orders[currId];
            int cmp = compareOrders(
                srcAmount,
                dstAmount,
                curr.srcAmount,
                curr.dstAmount
            );

            if (cmp < 0) {
                return curr.prevId;
            }
        }
        return currId;
    }

    function getFirstOrder() public view returns(uint32 orderId, bool isEmpty) {
        return (
            orders[HEAD_ID].nextId,
            orders[HEAD_ID].nextId == TAIL_ID
        );
    }

    function addAfterValidId(
        address maker,
        uint32 orderId,
        uint128 srcAmount,
        uint128 dstAmount,
        uint32 prevId
    )
        private
        returns(bool)
    {
        Order storage prevOrder = orders[prevId];

        // Add new order
        orders[orderId].maker = maker;
        orders[orderId].prevId = prevId;
        orders[orderId].nextId = prevOrder.nextId;
        orders[orderId].srcAmount = srcAmount;
        orders[orderId].dstAmount = dstAmount;

        // Update next order to point back to added order
        uint32 nextOrderId = prevOrder.nextId;
        if (nextOrderId != TAIL_ID) {
            orders[nextOrderId].prevId = orderId;
        }

        // Update previous order to point to added order
        prevOrder.nextId = orderId;

        return true;
    }

    function verifyCanRemoveOrderById(uint32 orderId) private view {
        require(orderId != 0 && orderId != HEAD_ID && orderId != TAIL_ID);

        Order storage order = orders[orderId];

        // Make sure such order exists in mapping.
        require(order.prevId != 0 || order.nextId != 0);
    }

    function isRightPosition(
        uint128 srcAmount,
        uint128 dstAmount,
        uint32 prevId,
        uint32 nextId
    )
        private
        view
        returns (bool)
    {
        if (prevId == TAIL_ID || nextId == HEAD_ID) return false;

        Order storage prev = orders[prevId];

        // Make sure prev order is either HEAD or properly initialised.
        if (prevId != HEAD_ID && (
                prev.prevId == 0 ||
                prev.nextId == 0 ||
                prev.prevId == TAIL_ID ||
                prev.nextId == HEAD_ID)) {
            return false;
        }

        int cmp;
        // Make sure that the new order should be after the provided prevId.
        if (prevId != HEAD_ID) {
            cmp = compareOrders(
                srcAmount,
                dstAmount,
                prev.srcAmount,
                prev.dstAmount
            );
            // new order is better than prev
            if (cmp < 0) return false;
        }

        // Make sure that the new order should be before provided prevId&#39;s next order.
        if (nextId != TAIL_ID) {
            Order storage next = orders[nextId];
            cmp = compareOrders(
                srcAmount,
                dstAmount,
                next.srcAmount,
                next.dstAmount
            );
            // new order is worse than next
            if (cmp > 0) return false;
        }

        return true;
    }
}

// File: contracts/permissionless/OrderListFactory.sol

contract OrderListFactory {
    function newOrdersContract(address admin) public returns(OrderListInterface) {
        OrderList orders = new OrderList(admin);
        return orders;
    }
}