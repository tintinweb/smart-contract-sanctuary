// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Marketplace {
    address public seller;
    address public buyer;
    mapping (address => uint) public balances;

    event ListItem(address seller, uint price);
    event PurchasedItem(address seller, address buyer, uint price);

    enum StateType {
          ItemAvailable,
          ItemPurchased
    }

    StateType public State;

    constructor() {
        seller = msg.sender;
        State = StateType.ItemAvailable;
    }

    function buy(address _seller, address _buyer, uint price) public payable {
        require(price <= balances[_buyer], "Insufficient balance");
        State = StateType.ItemPurchased;
        balances[_buyer] -= price;
        balances[_seller] += price;

        emit PurchasedItem(_seller, _buyer, msg.value);
    }
}