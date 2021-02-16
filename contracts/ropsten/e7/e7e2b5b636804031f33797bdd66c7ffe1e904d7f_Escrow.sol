/**
 *Submitted for verification at Etherscan.io on 2021-02-16
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

  contract Escrow is Ownable{
    enum OrderState { AWAITING_PAYMENT, AWAITING_PICKUP, AWAITING_DELIVERY, COMPLETE, DISPUTE }

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
        uint buyerValidation;
        uint carrierValidation;
    }
    
    struct Payment {
        address _buyer;
        uint value;
    }

    event logOrderCreated(uint indexed OrderId, OrderState orderState, address _buyer, uint indexed productId);
    event PaymentCreation(uint indexed orderId, address buyer, uint value);
    event PaymentCompletion(uint indexed orderId, address buyer, uint value);
    event confirmDeliveryCalled(uint indexed orderId, uint buyerValidation, uint carrierValidation);
    
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

    /**
   * @dev function for adding products
   */
    function addProduct(address seller, string[] memory Attributes, string[] memory Value) public returns(bool){
        require(seller != address(0), "Invalid Address");
        require(Attributes.length == Value.length,"Invalid Array");

        ProductId = ProductNum;
        productBook[ProductId] = Product(seller, Attributes, Value, 0, 0);
        ProductNum++;
        return true;
    }
    
    /**
   * @dev function for creating order
   */
    function createOrder(address buyer, uint productId) public returns(bool){
        require(productId != 0, "Invalid Id");
        require(buyer != address(0), "Invalid Address");
        uint orderId = ordersNum;
        ordersNum++;

        orderBook[orderId] = Order(OrderState.AWAITING_PAYMENT, buyer, productId, 0, 0);
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

    /**
   * @dev function for creating payment for order
   */
    function createPayment(uint orderId, address buyer, uint value) external {
        require(orderBook[orderId].orderState == OrderState.AWAITING_PAYMENT, "Already paid");
        PaymentBook[orderId] = Payment(buyer, value);
        delegate.transferFrom(buyer, address(this), value);
        emit PaymentCreation(orderId, buyer, value);
        orderBook[orderId].orderState = OrderState.AWAITING_PICKUP;
    }
    
    /**
   * @dev function for picking order by carrier
   */
    function OrderPickupByCarrier(uint orderId, address carrier) public returns(bool){
      require(msg.sender == productBook[ProductId].seller, "This is not seller");
      require(orderBook[orderId].orderState == OrderState.AWAITING_PICKUP, "Waiting for order pickup");
      require(orderId != 0, "Invalid orderId");
      require(carrier != address(0), "Invalid Address");
      carrierBook[orderId] = carrier;
      orderBook[orderId].orderState = OrderState.AWAITING_DELIVERY;
      return true; 
    }

    /**
   * @dev function to check the whitelist address validations
   */
    function checkBlocker(address analyticAddress, uint orderId) public view returns(bool){
    for(uint i=0; i < whitelistAddresses[orderId].length; i++){
        if (whitelistAddresses[orderId][i] == analyticAddress){
            return true;
        }
    }
    return false;
  }

    /**
   * @dev function for whitelist addresses
   */
    function whitelistaddressForSettingOA(address[]  calldata _userAddressArray, uint orderId) external onlyOwner returns(bool){
    require(_userAddressArray.length != 0,"Invalid Array");
     whitelistAddresses[orderId] = _userAddressArray;
    return true;
  }
    
    /**
   * @dev function to set order analytic
   */
    function setOrderAnalytic(uint orderId, uint temperature, uint humidity) external  returns(bool){
        bool flag = checkBlocker(msg.sender, orderId);
        require(flag == true, "User not whitelisted");
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

    function getOrderAnalyticByorderId(uint orderId) public view returns (uint, uint){
    require(orderId > 0);
    uint productId = orderBook[orderId].productId;
    return (productBook[productId].temp, productBook[productId].humid);
    }
  }