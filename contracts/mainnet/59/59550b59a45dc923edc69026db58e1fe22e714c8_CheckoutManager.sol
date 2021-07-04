/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CheckoutManager {

    address public admin;
    
    event BuyItems(string orderId, string buyerId, address buyer, string[] itemIds, uint256[] amounts);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function buyItems(string calldata orderId, string calldata buyerId, string[] calldata itemIds, uint256[] calldata amounts) external payable {
        require(msg.value > 0, "Wrong ETH value!");
        require(itemIds.length > 0, "No items");
        require(itemIds.length == amounts.length, "Items and amounts length should be the same");

        emit BuyItems(orderId, buyerId, msg.sender, itemIds, amounts);
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid address");
        
        admin = _newAdmin;
    }

    function withdraw() external onlyAdmin {
        uint _balance = address(this).balance;
        require(_balance > 0, "Insufficient balance");
        if (!payable(msg.sender).send(_balance)) {
            payable(msg.sender).transfer(_balance);
        }
    }
    
}