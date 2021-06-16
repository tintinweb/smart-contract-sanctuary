/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity ^0.5.0;

contract NordToken {
    function transfer(address to, uint tokens) public returns (bool success);
}

contract storingData{
    
    event Added(uint id);
    
    struct orderData{
        string productName;
        uint productPrice;
        address account;
    }
    
    mapping(uint => orderData) allOrders;
    NordToken obj = NordToken(0x0794a3A133E1845f354AE7F057f91296E127255d);
    uint orderID = 1001;
    
    function addOrder(address _to, string memory _productName, uint _productPrice) public returns(bool) {
        bool transactionResult = obj.transfer(_to, _productPrice);
        require(transactionResult == true, "Transaction Failed");
        orderData memory newOrder = orderData({productName: _productName, productPrice: _productPrice, account: msg.sender});
        allOrders[orderID] = newOrder;
        orderID = orderID + 1;
        emit Added(orderID - 1);
        return true;
    }
    
    function getName(uint _orderID) public view returns (string memory) {
        require(msg.sender == allOrders[_orderID].account, "This order was not placed by you");
        return allOrders[_orderID].productName;
    }
    
    function getPrice(uint _orderID) public view returns (uint) {
        require(msg.sender == allOrders[_orderID].account, "This order was not placed by you");
        return allOrders[_orderID].productPrice;
    }
    
    function getAccount(uint _orderID) public view returns (address) {
        require(msg.sender == allOrders[_orderID].account, "This order was not placed by you");
        return allOrders[_orderID].account;
    }
    
}