/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract Escrow {
    enum OrderState { ORDER_CREATION, AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE }

    struct Order {
        OrderState orderState;
        address _seller;
        bytes32 orderName;
    }
    
    struct Payment {
        address _buyer;
        uint value;
    }

    event logOrderCreated(uint OrderId, OrderState orderState, address _seller, bytes32 orderName);
    event PaymentCreation(uint indexed orderId, address indexed buyer, uint value);
    event PaymentCompletion(uint indexed orderId, address indexed buyer, uint value);

    OrderState public currentState;
    
    address public buyer;
    address payable public seller;
    address public carrier;
    address public owner;
    uint256 _temperature;
    uint256 _humidity;
    uint256 ordersNum=0;
    uint[] public orders;
    mapping(uint => Order) public orderBook;
    mapping(uint => Payment) public PaymentBook;
    mapping (bytes32 => string) orderName;

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call this method");
        _;
    }
    function isOwner() internal view returns (bool) {
      return msg.sender == owner;
    }
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this method");
        _;
    }
    function isBuyer() internal view returns (bool) {
      return msg.sender == buyer;
    }
    modifier inState(OrderState expectedState)  { 
        require(currentState == expectedState); 
        _;
    } 
    modifier onlyCarrier(){
        require(msg.sender == carrier, "Only carrier can call this method");
        _;
    }
    function isCarrier() internal view returns (bool) {
      return msg.sender == carrier;
    }
    modifier onlySeller(){
        require(msg.sender == buyer, "Only buyer can call this method");
        _;
    }
    function isSeller() internal view returns (bool) {
      return msg.sender == seller;
    }
    
    constructor(address _buyer, address payable _seller) {
        buyer = _buyer;
        seller = _seller;
    }
    
    function createOrder(address _seller, bytes32 orderName) public onlySeller returns(bool){
        require(_seller != address(0), "Invalid Address");
        require(orderName != "null", "Invalid Name");
    
        uint orderId = ordersNum;
        ordersNum++;

        orderBook[orderId] = Order(OrderState.ORDER_CREATION, _seller, orderName);
        orders.push(orderId);

        emit logOrderCreated(
            orderId,
            OrderState.ORDER_CREATION,
            _seller,
            orderName
        );
        return true;
        }

    function setOrderAnalytic(uint256 temperature, uint256 humidity) external onlySeller returns(bool){
        require(temperature != 0, "Invalid Temperature");
        require(humidity !=0, "Invalid Humidity");
        _temperature = temperature;
        _humidity = humidity;
        return true;
    }
    
    function getOrderAnalytic() public view returns (uint, uint){
    return (_temperature, _humidity);
    }
    
    function createPayment(uint orderId, address _buyer, uint value) onlyBuyer external payable {
        require(currentState == OrderState.AWAITING_PAYMENT, "Already paid");
        PaymentBook[orderId] = Payment(_buyer, value);
        emit PaymentCreation(orderId, _buyer, value);
        currentState = OrderState.AWAITING_DELIVERY;
    }
    
    function confirmDelivery() onlyBuyer external {
        require(currentState == OrderState.AWAITING_DELIVERY, "Cannot confirm delivery");
        seller.transfer(address(this).balance);
        currentState = OrderState.COMPLETE;
    }
}