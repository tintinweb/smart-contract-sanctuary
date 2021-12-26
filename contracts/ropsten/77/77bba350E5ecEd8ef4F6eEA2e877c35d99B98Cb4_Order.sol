// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Order {
    struct ECommerceOrder {
        // More Attributes..
        uint256 ID;
        uint256 amount;
        uint256 deliveryTime;
    }

    uint256 idCounter = 1;

    mapping(uint256 => ECommerceOrder) orders;

    function addNewOrder(uint256 amount, uint256 deliveryTime)
        internal
        returns (uint256)
    {
        orders[idCounter] = ECommerceOrder(idCounter, amount, deliveryTime);
        idCounter++;
        return idCounter;
    }
}