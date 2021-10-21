/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.7.0;

/**
 * @title Payments. Management of payments
 * @dev Provide functions for payment and withdraw of funds. Stores payments.
 */
contract Payments {
    address payable owner;

    struct Payment {
        string id;
        uint256 amount;
        uint256 date;
    }

    // Log of payments
    mapping(address=>Payment[]) private payments;

    // Event to notify payments
    event Pay(address, string, uint);

    constructor() public {
        owner = msg.sender;
    }

    // Optional. Fallback function to receive funds
    receive() external payable {
        require (msg.data.length == 0, 'The called function does not exist');
    }

    /**
     * @dev `pay` Payment in wei
     * Emits `Pay` on success with payer account, purchase reference and amount.
     * @param  id Reference of the purchase
     * @param  value Amount in wei of the payment
     */
    function pay(string memory id, uint value) public payable {
        require(msg.value == value, 'The payment does not match the value of the transaction');
        payments[msg.sender].push(Payment(id, msg.value, block.timestamp));
        emit Pay(msg.sender, id, msg.value);
    }

    /**
     * @dev `withdraw` Withdraw funds to the owner of the contract
     */
    function withdraw() public payable {
        require(msg.sender == owner, 'Only owner can withdraw funds');
        owner.transfer(address(this).balance);
    }

    /**
     * @dev `paymentsOf` Number of payments made by an account
     * @param  buyer Account or address
     * @return number of payments
     */
    function paymentsOf(address buyer) public view returns (uint) {
        return payments[buyer].length;
    }

    /**
     * @dev `paymentOfAt` Returns the detail of a payment of an account
     * @param  buyer Account or addres
     * @param  index Index of the payment
     * @return {0: "Purchase reference", 1: "Payment amount", 2: "Payment date"}
     */
    function paymentOfAt(address buyer, uint256 index) public view returns (string memory, uint256 amount, uint256 date) {
        Payment[] memory pays = payments[buyer];
        require(pays.length > index, "Payment does not exist");
        Payment memory payment = pays[index];
        return (payment.id, payment.amount, payment.date);
    }
}