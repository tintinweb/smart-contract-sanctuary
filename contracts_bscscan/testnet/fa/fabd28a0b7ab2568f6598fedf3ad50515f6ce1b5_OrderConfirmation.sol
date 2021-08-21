/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

// SPDX-License-Identifier: No License
pragma solidity >=0.8.6;
contract OrderConfirmation{
    event OrderConfirmed(address merchant, string indexed stationId, address tokenAddress, uint256 amountDue, address customer, string indexed orderId);
    event PaymentConfirmed(address merchant, string indexed stationId, address tokenAddress, uint256 amountDue, address customer, string indexed orderId);
    function confirmOrder(address merchant, string calldata stationId, address tokenAddress, uint256 amountDue, address customer, string calldata orderId) public{
        emit OrderConfirmed(merchant, stationId, tokenAddress, amountDue, customer, orderId);
    }
    function confirmPayment(address merchant, string calldata stationId, address tokenAddress, uint256 amountDue, address customer, string calldata orderId) public{
        emit PaymentConfirmed(merchant, stationId, tokenAddress, amountDue, customer, orderId);
    }
}