/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract Escrow {
    enum OrderState { ORDER_CREATION, AWAITING_PAYMENT, AWAITING_PICKUP, AWAITING_DELIVERY, COMPLETE }

    struct Order {
        OrderState orderState;
        address _seller;
        string orderName;
    }
    
    struct Payment {
        address _buyer;
        uint value;
    }

    event logOrderCreated(uint OrderId, OrderState orderState, address _seller, string orderName);
    event PaymentCreation(uint indexed orderId, address indexed buyer, uint value);
    event PaymentCompletion(uint indexed orderId, address indexed buyer, uint value);

    OrderState public currentState;
    
    address public owner;
    address _seller;
    address _buyer;
    address _carrier;
    bool    private ready = false;  
    uint256 _temperature;
    uint256 _humidity;
    uint256 ordersNum=0;
    uint[] public orders;
    mapping(uint => Order) public orderBook;
    mapping(uint => Payment) public PaymentBook;

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call this method");
        _;
    }
    function isOwner() internal view returns (bool) {
      return msg.sender == owner;
    }
    modifier onlyBuyer() {
        require(msg.sender == _buyer, "Only buyer can call this method");
        _;
    }
    function isBuyer() internal view returns (bool) {
      return msg.sender == _buyer;
    }
    modifier inState(OrderState expectedState)  { 
        require(currentState == expectedState); 
        _;
    } 
    modifier onlyCarrier(){
        require(msg.sender == _carrier, "Only carrier can call this method");
        _;
    }
    function isCarrier() internal view returns (bool) {
      return msg.sender == _carrier;
    }
    modifier onlySeller(){
        require(msg.sender == _seller, "Only buyer can call this method");
        _;
    }
    function isSeller() internal view returns (bool) {
      return msg.sender == _seller;
    }
    modifier payableCheck(){
    require(msg.value > 0 ,
      "Can not buy tokens,");
    _;
  }
    modifier validation(){
    require(ready == true, "validation failed");
    _;
  }
    function ValidateProduct() public onlySeller{
    ready = !ready;
  }
    function addOrder(address seller, address buyer) public validation onlyOwner returns(bool){
        require(seller != address(0), "Invalid Address");
        require(buyer != address(0), "Invalid Address");
        _seller = seller;
        _buyer = buyer;
        return true;
    }
    
    function createOrder(address seller, string memory orderName) public validation onlySeller returns(bool){
        require(seller != address(0), "Invalid Address");
    
        uint orderId = ordersNum;
        ordersNum++;

        orderBook[orderId] = Order(OrderState.ORDER_CREATION, seller, orderName);
        orders.push(orderId);

        emit logOrderCreated(
            orderId,
            OrderState.ORDER_CREATION,
            seller,
            orderName
        );
        return true;
        }

    function setOrderAnalytic(uint256 temperature, uint256 humidity) external validation onlySeller returns(bool){
        require(temperature != 0, "Invalid Temperature");
        require(humidity !=0, "Invalid Humidity");
        _temperature = temperature;
        _humidity = humidity;
        return true;
    }
    
    function getOrderAnalytic() public view returns (uint, uint){
    return (_temperature, _humidity);
    }
    
    function createPayment(uint orderId, address buyer, uint value) onlyBuyer external validation payable payableCheck {
        require(currentState == OrderState.AWAITING_PAYMENT, "Already paid");
        PaymentBook[orderId] = Payment(buyer, value);
        emit PaymentCreation(orderId, buyer, value);
        currentState = OrderState.AWAITING_PICKUP;
    }
    
    function OrderPickupByCarrier(uint256 orderId, address carrier) public validation onlySeller returns(bool){
      require(currentState == OrderState.AWAITING_PICKUP, "Waiting for order pickup");
      require(orderId != 0, "Invalid orderId");
      require(carrier != address(0), "Invalid Address");
      _carrier = carrier;
      currentState = OrderState.AWAITING_DELIVERY;
      return true; 
    }

    function setNewOrderAnalytic(uint256 temperature, uint256 humidity) external validation onlyCarrier returns(bool){
        require(temperature != 0, "Invalid Temperature");
        require(humidity !=0, "Invalid Humidity");
        _temperature = temperature;
        _humidity = humidity;
        return true;
    }
    
    function getNewOrderAnalytic() public view returns (uint, uint){
    return (_temperature, _humidity);
    }

    //function confirmDelivery() onlyBuyer external payable payableCheck{
        //require(currentState == OrderState.AWAITING_DELIVERY, "Cannot confirm delivery");
        //_seller.transfer(address(this).balance);
        //currentState = OrderState.COMPLETE;
    // }
}