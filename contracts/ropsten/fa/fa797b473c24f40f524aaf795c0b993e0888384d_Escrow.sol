/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract IDelegate {
    function transferFrom (address from, address to, uint256 value) external returns (bool){}
    }

  abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}
  contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
    // modifier onlyBuyer() {
    //     require(msg.sender == _buyer, "Only buyer can call this method");
    //     _;
    // }
    // function isBuyer() internal view returns (bool) {
    //   return msg.sender == _buyer;
    // }
    //modifier inState(OrderState expectedState)  { 
        //require(currentState == expectedState); 
        //_;
   // } 
    // modifier onlyCarrier(uint256 orderId){
    //     require(msg.sender == carrierBook[orderId], "Only carrier can call this method");
    //     _;
    // }
    // function isCarrier() internal view returns (bool) {
    //   return msg.sender == _carrier;
    // }
    
  //   modifier payableCheck(){
  //   require(msg.value > 0 ,
  //     "Can not buy tokens,");
  //   _;
  // }
  //   modifier validation(){
  //   require(ready == true, "validation failed");
  //   _;
  // }
  //   function ValidateProduct() public onlySeller(){
  //   ready = !ready;
  // }

  contract Escrow is Ownable{
    enum OrderState { AWAITING_PAYMENT, AWAITING_PICKUP, AWAITING_DELIVERY, COMPLETE }

    struct Product{
      address seller;
      string[] Attributes;
      string[] Value;
      uint temp;
      uint humid; 
    }

    struct Order {
        OrderState orderState;
        address _buyer;
        uint productId;
        bool buyerValidation;
        bool carrierValidation;
    }
    
    struct Payment {
        address _buyer;
        uint value;
    }

    event logOrderCreated(uint OrderId, OrderState orderState, address _buyer, uint productId);
    event PaymentCreation(uint indexed orderId, address indexed buyer, uint value);
    event PaymentCompletion(uint indexed orderId, address indexed buyer, uint value);
    
    address private _owner;
    address _seller;
    uint256 ProductId;
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
    mapping(uint => address) public carrierBook;
    mapping(uint => address[]) public whitelistAddresses;

    // modifier onlySeller(){
    //     require(msg.sender == seller, "Only seller can call this method");
    //     _;
    // }
    // function isSeller() internal view returns (bool) {
    //   return msg.sender == productBook[ProductId].seller;
    // }

    function addProduct(address seller, string[] memory Attributes, string[] memory Value) public returns(bool){
        require(seller != address(0), "Invalid Address");
        require(Attributes.length == Value.length,"Invalid Array");

        ProductId = ProductNum;
        productBook[ProductId] = Product(seller, Attributes, Value, 0, 0);
        ProductNum++;
        return true;
    }
    
    function createOrder(address buyer, uint productId) public returns(bool){
        require(productId != 0, "Invalid Id");
        require(buyer != address(0), "Invalid Address");
        uint orderId = ordersNum;
        ordersNum++;

        orderBook[orderId] = Order(OrderState.AWAITING_PAYMENT, buyer, productId, false, false);
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

    function createPayment(uint256 orderId, address buyer, uint value) external {
        require(orderBook[orderId].orderState == OrderState.AWAITING_PAYMENT, "Already paid");
        PaymentBook[orderId] = Payment(buyer, value);
        delegate.transferFrom(buyer, address(this), value);
        emit PaymentCreation(orderId, buyer, value);
        orderBook[orderId].orderState = OrderState.AWAITING_PICKUP;
    }
    
    function OrderPickupByCarrier(uint256 orderId, address carrier) public returns(bool){
      require(msg.sender == productBook[ProductId].seller, "This is not seller");
      require(orderBook[orderId].orderState == OrderState.AWAITING_PICKUP, "Waiting for order pickup");
      require(orderId != 0, "Invalid orderId");
      require(carrier != address(0), "Invalid Address");
      carrierBook[orderId] = carrier;
      orderBook[orderId].orderState = OrderState.AWAITING_DELIVERY;
      return true; 
    }

    /**
   * @dev modifier to check the whitelist address validations
   */
    modifier checkBlocker(address analyticAddress, uint orderId){
    for(uint i=0; i < whitelistAddresses[orderId].length; i++)
    _;
  }

    function whitelistaddressForSettingOA(address[]  calldata _userAddressArray, uint256 orderId) external onlyOwner returns(bool){
    require(_userAddressArray.length != 0,"Invalid Array");
     whitelistAddresses[orderId] = _userAddressArray;
    return true;
  }
    
    function setOrderAnalytic(uint256 orderId, uint256 temperature, uint256 humidity) external checkBlocker(msg.sender, orderId) returns(bool){
        require(orderId != 0, "Invalid Id");
        require(temperature != 0, "Invalid Temperature");
        require(humidity !=0, "Invalid Humidity");
        uint productId = orderBook[orderId].productId;
        productBook[productId].temp = temperature;
        productBook[productId].humid = humidity;
        return true;
    }
    
    function getOrderAnalyticByproductId(uint productId) public view returns (uint, uint){
      require(productId > 0);
      return (productBook[productId].temp, productBook[productId].humid);
    }

    function getOrderAnalyticByorderId(uint256 orderId) public view returns (uint, uint){
    require(orderId > 0);
    uint productId = orderBook[orderId].productId;
    return (productBook[productId].temp, productBook[productId].humid);
    }
  }