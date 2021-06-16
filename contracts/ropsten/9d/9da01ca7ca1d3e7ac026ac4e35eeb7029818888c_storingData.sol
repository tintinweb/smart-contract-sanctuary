/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity ^0.5.0;

contract storingData{
    
    event Added(uint id);
    
    struct orderData{
        string productName;
        uint productPrice;
        address account;
    }
    
    mapping(uint => orderData) allOrders;
    uint orderID = 1001;
    
    function addOrder(string memory _productName, uint _productPrice) public returns(bool) {
        orderData memory newOrder = orderData({productName: _productName, productPrice: _productPrice, account: msg.sender});
        allOrders[orderID] = newOrder;
        orderID = orderID + 1;
        emit Added(orderID - 1);
        return true;
    }
    
    function getName(uint _orderID) public view returns (string memory) {
        return allOrders[_orderID].productName;
    }
    
    function getPrice(uint _orderID) public view returns (uint) {
        return allOrders[_orderID].productPrice;
    }
    
    function getAccount(uint _orderID) public view returns (address) {
        return allOrders[_orderID].account;
    }
    
}