/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.1;

contract LiqsContract {

    uint private _order_length = 0;
    
    address private _owner;
    
    uint private _wbnbRevenue = 0;
    
    mapping(address => mapping(address => uint)) private _orders;
    
    constructor() {
        address creator = msg.sender;
        _owner = creator;
    }

    function getOwner()public view returns(address) {
        return _owner;
    }
    
    function withdrawRevenue() public {
        address payable withdrawer =  payable(msg.sender);
        require(withdrawer == _owner, 'LIQS: Only owner of this contract can withdraw revenue');
        require(_wbnbRevenue > 0, 'LIQS: Revenue empty');
        withdrawer.transfer(_wbnbRevenue);
    }

    
    function getOrder(address tokenAddress) public view returns(uint) {
        return _orders[msg.sender][tokenAddress];
    }
    
    function sumbitOrder(address tokenAddress) public payable {
        uint wbnbAmount = msg.value;
        address buyer = msg.sender;
        uint fee = wbnbAmount / 10;
        uint real = wbnbAmount / 10 * 9;
        _wbnbRevenue += fee;
        _orders[buyer][tokenAddress] += real;
        _order_length = _order_length + 1;
    }
    
    function cancelOrder(address tokenAddress) public {
        address payable canceling = payable(msg.sender);
        uint amountToWithdraw = _orders[canceling][tokenAddress];
        require(amountToWithdraw > 0, "LIQS: Insufficient WBNB funds");
        canceling.transfer(amountToWithdraw);
        _order_length = _order_length - 1;
    }
    
    function tickOffOrder(address ordering,address tokenAddress) public {
        address tickingOff = msg.sender;
        require(tickingOff == _owner, 'LIQS: Only owner of this contract can tick off order');
        require(_orders[ordering][tokenAddress] > 0, 'LIQS: Wrong tick off, no active order with this data');
        _orders[ordering][tokenAddress] = 0; 
    }

    function getOrdersLength() public view returns(uint) {
        return _order_length;
    }
}