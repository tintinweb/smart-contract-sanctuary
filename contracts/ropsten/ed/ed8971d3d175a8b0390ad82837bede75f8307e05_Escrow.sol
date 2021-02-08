/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract IDelegate {
    function transferFrom (address from, address to, uint256 value) external returns (bool){}
    }

contract Escrow {
    enum OrderState { AWAITING_PAYMENT, AWAITING_PICKUP, AWAITING_DELIVERY, COMPLETE }

    struct Product{
      address seller;
      string ProductName;
      uint ProductId;
      uint ProductPrice;
      uint ProductQuantity;
      uint temp;
      uint humid;
    }

    struct Order {
        OrderState orderState;
        address _buyer;
        uint productId;
    }
    
    struct Payment {
        address _buyer;
        uint value;
    }

    event logOrderCreated(uint OrderId, OrderState orderState, address _buyer, uint productId);
    event PaymentCreation(uint indexed orderId, address indexed buyer, uint value);
    event PaymentCompletion(uint indexed orderId, address indexed buyer, uint value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    OrderState public currentState;
    
    address public owner;
    address _seller;
    string _ProductName;
    uint256 ProductId;
    uint _ProductPrice;
    uint _ProductQuantity;
    uint _temp;
    uint _humid;
    uint256 ProductNum=1;
    address _buyer;
    address _carrier;
    bool    private ready = false;  
    uint256 _orderId;
    uint256 _temperature;
    uint256 _humidity;
    uint256 ordersNum=1;
    uint[] public orders;
    mapping(uint => Product) public productBook;
    mapping(uint => Order) public orderBook;
    mapping(uint => Payment) public PaymentBook;


    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call this method");
        _;
    }
    function isOwner() internal view returns (bool) {
      return msg.sender == owner;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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
        require(msg.sender == _seller, "Only seller can call this method");
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
    function ValidateProduct() public onlySeller(){
    ready = !ready;
  }
    function addProduct(address seller, string memory ProductName, uint ProductPrice, uint ProductQuantity, uint temp, uint humid) public returns(bool){
        require(seller != address(0), "Invalid Address");
        require(ProductPrice != 0, "Invalid Price");
        require(ProductQuantity != 0, "Invalid Quantity");
        require(temp != 0, "Invalid temp");
        require(humid != 0, "Invalid humid");
        _seller = seller;
        _ProductName = ProductName;
        _ProductPrice = ProductPrice;
        _ProductQuantity = ProductQuantity;
        _temp = temp;
        _humid = humid;

        ProductId = ProductNum;
        productBook[ProductId] = Product(seller, ProductName, ProductId, ProductPrice, ProductQuantity, temp, humid);
        ProductNum++;
        return true;
    }
    
    function createOrder(address buyer, uint productId) public returns(bool){
        require(productId != 0, "Invalid Id");
        require(buyer != address(0), "Invalid Address");
        uint orderId = ordersNum;
        ordersNum++;

        orderBook[orderId] = Order(OrderState.AWAITING_PAYMENT, buyer, productId);
        orders.push(orderId);

        emit logOrderCreated(
            orderId,
            OrderState.AWAITING_PAYMENT,
            buyer,
            productId
        );
        return true;
    }
    address public delegateContract = 0x34081bAd431893fb9bcCA1f4f7fB151a56ecD368;

    IDelegate delegate = IDelegate(delegateContract);

    function createPayment(uint orderId, address buyer, uint value) external payable payableCheck {
        require(currentState == OrderState.AWAITING_PAYMENT, "Already paid");
        PaymentBook[orderId] = Payment(buyer, value);
        delegate.transferFrom(buyer, address(this), value);
        emit PaymentCreation(orderId, buyer, value);
        currentState = OrderState.AWAITING_PICKUP;
    }
    
    function OrderPickupByCarrier(uint256 orderId, address carrier) public onlySeller returns(bool){
      require(currentState == OrderState.AWAITING_PICKUP, "Waiting for order pickup");
      require(orderId != 0, "Invalid orderId");
      require(carrier != address(0), "Invalid Address");
      _carrier = carrier;
      currentState = OrderState.AWAITING_DELIVERY;
      return true; 
    }

    function setOrderAnalytic(uint256 orderId, uint256 temperature, uint256 humidity) external onlyCarrier returns(bool){
        require(orderId != 0, "Invalid Id");
        require(temperature != 0, "Invalid Temperature");
        require(humidity !=0, "Invalid Humidity");
        _orderId = orderId;
        _temperature = temperature;
        _humidity = humidity;
        return true;
    }
    
    function getOrderAnalytic() public view returns (uint, uint, uint){
    return (_orderId, _temperature, _humidity);
    }

    //function confirmDelivery() onlyBuyer external payable payableCheck{
        //require(currentState == OrderState.AWAITING_DELIVERY, "Cannot confirm delivery");
        //_seller.transfer(address(this).balance);
        //currentState = OrderState.COMPLETE;
    // }

    function getContractETHBalance() public view returns(uint256){
    return(address(this).balance);
    }

    function withdrawETH() external onlyOwner returns(bool){
    msg.sender.transfer(address(this).balance);
    return true;
    }

    function getContractTETHBalance() public view returns(uint256){
    return(address(this).balance);
    }
    function withdrawTETH() external onlyOwner returns(bool){
    msg.sender.transfer(address(this).balance);
    return true;
    }
}