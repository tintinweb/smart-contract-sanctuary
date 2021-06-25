/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract Shop {
    address payable owner;

    string[] name;
    uint32[] cost;
    
    struct cart {
        uint128 totalCost;
        string[] goodsName;
        uint32[] goodsCount;
    }

    mapping(address => cart) carts;
    
    constructor() {
        owner = payable(msg.sender);
    }
    
    function add(string memory _name, uint32 _cost) public payable {
        require(owner == msg.sender);
        name.push(_name);
        cost.push(_cost);
    }
    function getGoods() public view returns(string[] memory, uint32[] memory) {
        return (name, cost);
    }
    
    function addToCart(string memory _name, uint32 _count) public payable {
        carts[msg.sender].goodsName.push(_name);
        carts[msg.sender].goodsCount.push(_count);
        for(uint i = 0; i < name.length; i++) {
            if(keccak256(bytes(name[i])) == keccak256(bytes(_name))) {
                carts[msg.sender].totalCost += _count * cost[i];
            }
        }
    }
    
    function getCart() public view  returns(string[] memory, uint32[] memory, uint128) {
        return (carts[msg.sender].goodsName, carts[msg.sender].goodsCount, carts[msg.sender].totalCost);
    }
    
    function buy() public payable {
        require(msg.value >= carts[msg.sender].totalCost);
        if(msg.value > uint( carts[msg.sender].totalCost)) {
            payable(msg.sender).transfer(msg.value - uint( carts[msg.sender].totalCost));
        }
        delete carts[msg.sender];
    }
    
    function getBalance() public view returns(uint) {
        require(owner == msg.sender);
        return address(this).balance;
    }
    
    function withdraw(uint _amount) public {
        require(owner == msg.sender && address(this).balance >= _amount);
        owner.transfer(_amount);
    }
}