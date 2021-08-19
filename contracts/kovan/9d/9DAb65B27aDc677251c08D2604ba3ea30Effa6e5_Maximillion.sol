pragma solidity ^0.5.16;

import "./DEther.sol";

/**
 * @title Decentralized-Bank's Maximillion Contract
 * @author Decentralized-Bank
 */
contract Maximillion {
    /**
     * @notice The default dEther market to repay in
     */
    DEther public dEther;

    /**
     * @notice Construct a Maximillion to repay max in a DEther market
     */
    constructor(DEther dEther_) public {
        dEther = dEther_;
    }

    /**
     * @notice msg.sender sends Ether to repay an account's borrow in the dEther market
     * @dev The provided Ether is applied towards the borrow balance, any excess is refunded
     * @param borrower The address of the borrower account to repay on behalf of
     */
    function repayBehalf(address borrower) public payable {
        repayBehalfExplicit(borrower, dEther);
    }

    /**
     * @notice msg.sender sends Ether to repay an account's borrow in a dEther market
     * @dev The provided Ether is applied towards the borrow balance, any excess is refunded
     * @param borrower The address of the borrower account to repay on behalf of
     * @param dEther_ The address of the dEther contract to repay in
     */
    function repayBehalfExplicit(address borrower, DEther dEther_) public payable {
        uint received = msg.value;
        uint borrows = dEther_.borrowBalanceCurrent(borrower);
        if (received > borrows) {
            dEther_.repayBorrowBehalf.value(borrows)(borrower);
            msg.sender.transfer(received - borrows);
        } else {
            dEther_.repayBorrowBehalf.value(received)(borrower);
        }
    }
}