/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

pragma solidity ^0.4.25;

contract SupplyChain {

    enum Status { Created, Delivering, Delivered, Accepted, Declined }

    Order[] orders;

    struct Order {
        string title;
        string description;
        address supplier;
        address deliveryCompany;
        address customer;
        Status status;
    }

    event OrderCreated(
        uint256 index,
        address indexed supplier,
        address indexed deliveryCompany,
        address indexed customer
    );

    event OrderDelivering(
        uint256 index,
        address indexed supplier,
        address indexed deliveryCompany,
        address indexed customer
    );

    event OrderDelivered(
        uint256 index,
        address indexed supplier,
        address indexed deliveryCompany,
        address indexed customer
    );

    event OrderAccepted(
        uint256 index,
        address indexed supplier,
        address indexed deliveryCompany,
        address indexed customer
    );

    event OrderDeclined(
        uint256 index,
        address indexed supplier,
        address indexed deliveryCompany,
        address indexed customer
    );

    modifier onlyOrderDeliveryCompany(uint256 _index) {
        require(orders[_index].deliveryCompany == msg.sender);
        _;
    }

    modifier onlyCustomer(uint256 _index) {
        require(orders[_index].customer == msg.sender);
        _;
    }

    modifier orderCreated(uint256 _index) {
        require(orders[_index].status == Status.Created);
        _;
    }

    modifier orderDelivering(uint256 _index) {
        require(orders[_index].status == Status.Delivering);
        _;
    }

    modifier orderDelivered(uint256 _index) {
        require(orders[_index].status == Status.Delivered);
        _;
    }

    function getOrder(
        uint256 _index
    ) public view returns(string memory, string memory, address, address, address, Status) {
        Order memory order = orders[_index];
        return (
            order.title,
            order.description,
            order.supplier,
            order.deliveryCompany,
            order.customer,
            order.status
        );
    }

    function createOrder(
        string memory _title,
        string memory _description,
        address _deliveryCompany,
        address _customer
    ) public {
        Order memory order = Order({
            title: _title,
            description: _description,
            supplier: msg.sender,
            deliveryCompany: _deliveryCompany,
            customer: _customer,
            status: Status.Created
        });
        uint256 index = orders.length;
        emit OrderCreated(index, msg.sender, _deliveryCompany, _customer);
        orders.push(order);
    }

    function startDeliveringOrder(
        uint256 _index
    ) public onlyOrderDeliveryCompany(_index) orderCreated(_index) {
        Order storage order = orders[_index];
        emit OrderDelivering(_index, order.supplier, order.deliveryCompany, order.customer);
        order.status = Status.Delivering;
    }

    function stopDeliveringOrder(
        uint256 _index
    ) public onlyOrderDeliveryCompany(_index) orderDelivering(_index) {
        Order storage order = orders[_index];
        emit OrderDelivered(_index, order.supplier, order.deliveryCompany, order.customer);
        order.status = Status.Delivered;
    }

    function acceptOrder(
        uint256 _index
    ) public onlyCustomer(_index) orderDelivered(_index) {
        Order storage order = orders[_index];
        emit OrderAccepted(_index, order.supplier, order.deliveryCompany, order.customer);
        orders[_index].status = Status.Accepted;
    }

    function declineOrder(
        uint256 _index
    ) public onlyCustomer(_index) orderDelivered(_index) {
        Order storage order = orders[_index];
        emit OrderDeclined(_index, order.supplier, order.deliveryCompany, order.customer);
        orders[_index].status = Status.Declined;
    }
}