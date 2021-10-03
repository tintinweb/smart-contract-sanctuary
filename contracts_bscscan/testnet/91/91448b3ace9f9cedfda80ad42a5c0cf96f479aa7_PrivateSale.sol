/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

// Halborn organizes a private party and you should take the tickets here.
contract PrivateSale {

    uint256 public constant TICKET = 0.01 ether;

    mapping(address => uint256) private purchasedTickets;

    error NotEnoughFundsSent();
    modifier enoughFundsSent(uint256 ticketQuantity) {
        if (msg.value < ticketQuantity * TICKET) {
            revert NotEnoughFundsSent();
        }
        _;
    }

    error TicketsWereNotBought();
    modifier ticketsWereBought(uint256 ticketQuantity) {
        if (purchasedTickets[msg.sender] < ticketQuantity) {
            revert TicketsWereNotBought();
        }
        _;
    }

    function buyTickets(uint256 quantity)
        external
        payable
        enoughFundsSent(quantity)
    {
        purchasedTickets[msg.sender] += quantity;
    }

    function getRefund(uint256 quantity)
        external
        payable
        ticketsWereBought(quantity)
    {

        (bool refunded, ) = msg.sender.call{value: quantity * TICKET}("");
        require(refunded, "Ticket refund failed");

        unchecked {
            purchasedTickets[msg.sender] -= quantity;
        }
    }

    receive() external payable {}
}