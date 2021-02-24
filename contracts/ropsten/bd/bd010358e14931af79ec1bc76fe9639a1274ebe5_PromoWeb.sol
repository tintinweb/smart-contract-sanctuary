/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract IDelegate {

    function transferFrom (address from, address to, uint256 value) external returns (bool){}
    function transfer (address to, uint256 value) external returns (bool){}

    mapping (address => uint256) private _balances;
    
    function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }
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

  contract PromoWeb is Ownable{
    enum OrderState { AWAITING_PAYMENT, AWAITING_PICKUP, AWAITING_DELIVERY, ORDER_COMPLETE, ORDER_DISPUTE }

    struct Product{
      address seller;
      string Attributes;
      string Value;
      uint minTemp;
      uint maxTemp;
      uint minHumid; 
      uint maxHumid; 
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

    uint256 ProductId;
    uint _temp;
    uint _humid;
    uint256 ProductNum=1;
    address _buyer;
    address _carrier;  
    uint256 _orderId;
    uint256 ordersNum=1;
    mapping(uint => Product) public productBook;
    mapping(uint => Order) public orderBook;
    mapping(uint => Payment) public PaymentBook;
    mapping(uint => address) public carrierBook;
    mapping(uint => address[]) private whitelistAddresses;
    

    /**
   * @dev function for adding products
   */
    function addProduct(address seller, string memory Attributes, string memory Value) public returns(bool){
        require(seller != address(0), "Invalid Address");

        ProductId = ProductNum;
        productBook[ProductId] = Product(seller, Attributes, Value, 0, 0, 0, 0);
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
    function checkBlocker(address analyticAddress, uint orderId) internal view returns(bool){
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
    function setOrderAnalytic(uint orderId, uint minTemperature, uint maxTemperature, uint minHumidity, uint maxHumidity) external  returns(bool){
        bool flag = checkBlocker(msg.sender, orderId);
        require(flag == true, "User not whitelisted");
        require(orderId != 0, "Invalid Id");
        require(minTemperature != 0, "Invalid Temperature");
        require(maxTemperature != 0, "Invalid Temperature");
        require(minHumidity !=0, "Invalid Humidity");
        require(maxHumidity !=0, "Invalid Humidity");
        uint productId = orderBook[orderId].productId;
        productBook[productId].minTemp = minTemperature;
        productBook[productId].maxTemp = maxTemperature;
        productBook[productId].minHumid = minHumidity;
        productBook[productId].maxHumid = maxHumidity;
        return true;
    }
    
    function getOrderAnalyticByproductId(uint productId) public view returns (uint, uint, uint, uint){
      require(productId > 0);
      return (productBook[productId].minTemp, productBook[productId].maxTemp, productBook[productId].minHumid, productBook[productId].maxHumid);
    }

    function getOrderAnalyticByorderId(uint orderId) public view returns (uint, uint, uint, uint){
    require(orderId > 0);
    uint productId = orderBook[orderId].productId;
    return (productBook[productId].minTemp, productBook[productId].maxTemp, productBook[productId].minHumid, productBook[productId].maxHumid);
    }

    /**
   * @dev function for delivery confirmation
   */
    function confirmDelivery(uint orderId, uint response) external {
    require(orderBook[orderId].orderState == OrderState.AWAITING_DELIVERY, "Cannot confirm delivery");
    if (msg.sender == orderBook[orderId]._buyer){
    require(orderBook[orderId].buyerValidation != response, "buyer has not recieved order yet");
    orderBook[orderId].buyerValidation = response;
    }
    if (msg.sender == carrierBook[orderId]){
    require(orderBook[orderId].carrierValidation != response, "carrier has not delivered product yet");
    orderBook[orderId].carrierValidation = response;
    }
    uint value = PaymentBook[orderId].value;
    if(orderBook[orderId].buyerValidation  == 1 && orderBook[orderId].carrierValidation == 1){
    uint productId = orderBook[orderId].productId;
    address _seller = productBook[productId].seller;
    delegate.transfer(_seller, value);
    orderBook[orderId].orderState = OrderState.ORDER_COMPLETE;
    emit confirmDeliveryCalled(orderId, orderBook[orderId].buyerValidation, orderBook[orderId].carrierValidation);
    }
    else{
        if (orderBook[orderId].buyerValidation  == 2 || orderBook[orderId].carrierValidation == 2){  
        delegate.transfer(_owner, value);
        orderBook[orderId].orderState = OrderState.ORDER_DISPUTE;
        emit confirmDeliveryCalled(orderId, orderBook[orderId].buyerValidation, orderBook[orderId].carrierValidation);
        }
    else{
        emit confirmDeliveryCalled(orderId, orderBook[orderId].buyerValidation, orderBook[orderId].carrierValidation);
       } 
      }
    }

    /**
   * @dev function to get total ethers in contract
   */
    function getContractETHBalance() public view returns(uint256){
    return(address(this).balance);
    }

    /**
   * @dev function to withdraw total ethers from contract
   */
    function withdrawETH() external onlyOwner returns(bool){
    msg.sender.transfer(address(this).balance);
    return true;
    }

    /**
   * @dev function to get total tethers in contract
   */
    function getContractTETHBalance() public view returns(uint256){
    return(delegate.balanceOf(address(this)));
    }

    /**
   * @dev function to withdraw total tethers from contract
   */
    function withdrawTETH() external onlyOwner returns(bool){
    delegate.transfer(msg.sender, address(this).balance);
    return true;
    }

    receive() external payable{}

  }