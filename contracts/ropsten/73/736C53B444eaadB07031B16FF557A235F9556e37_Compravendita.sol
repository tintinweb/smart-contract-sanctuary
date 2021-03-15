/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

/*
    Contratto di Compravendita di un bene
    
    SPDX-License-Identifier: UNLICENSED
*/
pragma solidity ^0.7.4;

contract Compravendita
{

    enum State { 
            AWAITING_PAYMENT,
            AWAITING_DELIVERY, 
            AWAITING_CHECK,
            COMPLETE,
            DEPOSIT_REDEEMED
        }
    State public currentState;

    address payable public seller;
    address payable public buyer;
    address public genovaPort;
    address public gammaSRL;

    uint public amount;
    uint public amountDepositDate;
    uint public amountLockedDays;

    modifier isBuyer() {
        require(msg.sender == buyer, "only the buyer can call me");
        _;
    }

    modifier isGenovaPort() {
        require(msg.sender == genovaPort, "access denied");
        _;
    }

    modifier isGammaSRL() {
        require(msg.sender == gammaSRL, "access denied");
        _;
    }

    function getState() public view returns(State) {
        return currentState;
    }

    constructor(
        address payable _seller, address payable _buyer,
        address _genovaPort, address _gammaSRL,
        uint _amount, uint _amountLockedDays)
    {
        seller = _seller;
        buyer = _buyer;
        genovaPort = _genovaPort;
        gammaSRL = _gammaSRL;
        amount = _amount;
        amountLockedDays = _amountLockedDays;
        currentState = State.AWAITING_PAYMENT;
    }

    function buyerDeposit() public payable isBuyer {
        require(currentState == State.AWAITING_PAYMENT);
        require(msg.value == amount, "wrong expected amount");
        currentState = State.AWAITING_DELIVERY;
        amountDepositDate = block.timestamp;
    }

    function deliveryDone() public isGenovaPort {
        require(currentState == State.AWAITING_DELIVERY);
        currentState = State.AWAITING_CHECK;
    }

    function checkDone() public isGammaSRL {
        require(currentState == State.AWAITING_CHECK);
        seller.transfer(address(this).balance);
        currentState = State.COMPLETE;
    }

    function checkFail() public isGammaSRL {
        require(currentState == State.AWAITING_CHECK);
        buyer.transfer(address(this).balance);
        currentState = State.DEPOSIT_REDEEMED;
    }

    function redeemDeposit() public isBuyer {
        require(currentState == State.AWAITING_DELIVERY);
        require(
            block.timestamp > (
                amountDepositDate + (amountLockedDays * 24 * 60 * 60))
                );
        buyer.transfer(address(this).balance);
        currentState = State.DEPOSIT_REDEEMED;
    }
}