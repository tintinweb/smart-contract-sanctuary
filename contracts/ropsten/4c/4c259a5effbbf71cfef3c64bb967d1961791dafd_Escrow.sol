/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract Escrow {
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE }
    
    event PaymentCreation(uint indexed orderId, address indexed buyer, uint value);
    event PaymentCompletion(uint indexed orderId, address indexed buyer, uint value);

    State public currentState;
    
    address public buyer;
    address payable public seller;
    address public carrier;
    address public owner;
    uint256 _temperature;
    uint256 _humidity;
    //mapping(address => uint256) public createPayment;

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
    modifier inState(State expectedState)  { 
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
    
    function createOrder(address _seller, bytes32 orderName) public onlySeller view returns(bool){
        require(_seller != address(0), "Invalid Address");
        require(orderName != "null", "Invalid Name");
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
    
    function createPayment() onlyBuyer external payable {
        require(currentState == State.AWAITING_PAYMENT, "Already paid");
        currentState = State.AWAITING_DELIVERY;
    }
    
    function confirmDelivery() onlyBuyer external {
        require(currentState == State.AWAITING_DELIVERY, "Cannot confirm delivery");
        seller.transfer(address(this).balance);
        currentState = State.COMPLETE;
    }
}