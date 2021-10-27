/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

pragma solidity ^0.4.25;

contract SupplyChain {
    
    enum Status { Created, Delivering, Delivered, Accepted, Declined }
    
    Order[] public orders;
    
    struct Order {
        string title;
        string description;
        address supplier;
        address deliveryCompany;
        address customer;
        Status status;
    }
    
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
    
    function createOrder(
        string _title,
        string _description,
        address _deliveryCompany,
        address _customer
    ) public returns (uint256) {
        Order memory order = Order({
           title: _title,
           description: _description,
           supplier: msg.sender,
           deliveryCompany: _deliveryCompany,
           customer: _customer,
           status: Status.Created
        });
        
        uint256  index = orders.length + 1;
        
        orders[index] = order;
        return index;
    }
    
    function startDeliveringOrder (
        uint256 _index
    ) public onlyOrderDeliveryCompany(_index) orderCreated(_index) {
        Order storage order = orders[_index];
        order.status = Status.Delivering;
    }
    
    function stopDeliveringOrder(
        uint256 _index
    ) public onlyOrderDeliveryCompany(_index) orderDelivering(_index) {
        Order storage order = orders[_index];
        order.status = Status.Delivered;
    }
    
    function acceptOrder(
        uint256 _index
    ) public onlyCustomer(_index) orderDelivered(_index) {
        Order storage order = orders[_index];
        order.status = Status.Accepted;
    }
    
    function declineOrder(
        uint256 _index
    ) public onlyCustomer(_index) orderDelivered(_index) {
        Order storage order = orders[_index];
        order.status = Status.Delivered;
    }
    
    
}