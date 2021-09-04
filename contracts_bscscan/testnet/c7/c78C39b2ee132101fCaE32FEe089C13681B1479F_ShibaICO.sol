/*
 *  Crowdsale for CoinPoker Tokens
 *  Author: Justas Kreg?d?
 */
 /*

    SPDX-License-Identifier: Apache-2.0

*/
pragma solidity ^0.6.9;

import {InitializableERC20} from "../InitializableERC20.sol";

import {SafeMath} from "../SafeMath.sol";



contract ShibaICO {
    using SafeMath for uint;
    // The maximum amount of tokens to be sold
    uint constant public maxGoal = 275000000e18; // 275 Milion CoinPoker Tokens
    // There are different prices and amount available in each period
    uint[2] public prices = [4200, 3500]; // 1ETH = 4200CHP, 1ETH = 3500CHP
    uint[2] public amount_stages = [137500000e18, 275000000e18]; // the amount stages for different prices
    // How much has been raised by crowdsale (in ETH)
    uint public amountRaised;
    // The number of tokens already sold
    uint public tokensSold = 0;
    // The start date of the crowdsale
    uint constant public start = 1630628963; // Friday, 19 January 2018 10:00:00 GMT
    // The end date of the crowdsale
    uint constant public end = 1630974563; // Friday, 26 January 2018 10:00:00 GMT
    // The balances (in ETH) of all token holders
    mapping(address => uint) public balances;
    // Indicates if the crowdsale has been ended already
    bool public crowdsaleEnded = false;
    // Tokens will be transfered from this address
    address public tokenOwner;
    // The address of the token contract
    InitializableERC20 public tokenReward;
    // The wallet on which the funds will be stored
    address payable wallet;
    // Notifying transfers and the success of the crowdsale
    event Finalize(address _tokenOwner, uint _amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution, uint _amountRaised);

    // ---- FOR TEST ONLY ----
    uint _current = 0;
    function current() view public returns (uint) {
        // Override not in use
        if(_current == 0) {
            return now;
        }
        return _current;
    }
    function setCurrent(uint __current) public{
        _current = __current;
    }
    //------------------------

    // Constructor/initialization
    constructor (address tokenAddr, address payable walletAddr, address tokenOwnerAddr) public{
        tokenReward = InitializableERC20(tokenAddr);
        wallet = walletAddr;
        tokenOwner = tokenOwnerAddr;
    }

    // Exchange CHP by sending ether to the contract.
    receive() external payable {
        if (msg.sender != wallet) // Do not trigger exchange if the wallet is returning the funds
            exchange(msg.sender);
    }

    // Make an exchangement. Only callable if the crowdsale started and hasn't been ended, also the maxGoal wasn't reached yet.
    // The current token price is looked up by available amount. Bought tokens is transfered to the receiver.
    // The sent value is directly forwarded to a safe wallet.
    function exchange(address receiver) public payable {
        uint amount = msg.value;
        uint price = getPrice();
        uint numTokens = amount.mul(price);

        require(numTokens > 0);
        require(!crowdsaleEnded && current() >= start && current() <= end && tokensSold.add(numTokens) <= maxGoal);

        wallet.transfer(amount);
        balances[receiver] = balances[receiver].add(amount);

        // Calculate how much raised and tokens sold
        amountRaised = amountRaised.add(amount);
        tokensSold = tokensSold.add(numTokens);

        assert(tokenReward.transferFrom(tokenOwner, receiver, numTokens));
        FundTransfer(receiver, amount, true, amountRaised);
    }

    // Manual exchange tokens for BTC,LTC,Fiat contributions.
    // @param receiver who tokens will go to.
    // @param value an amount of tokens.
    function manualExchange (address receiver, uint value) public{
        require(msg.sender == tokenOwner);
        require(tokensSold.add(value) <= maxGoal);
        tokensSold = tokensSold.add(value);
        assert(tokenReward.transferFrom(tokenOwner, receiver, value));
    }

    // Looks up the current token price
    function getPrice() public view returns (uint price) {
        for(uint i = 0; i < amount_stages.length; i++) {
            if(tokensSold < amount_stages[i])
                return prices[i];
        }
        return prices[prices.length-1];
    }

    modifier afterDeadline() { if (current() >= end) _; }

    // Checks if the goal or time limit has been reached and ends the campaign
    function finalize() public afterDeadline {
        require(!crowdsaleEnded);
        Finalize(tokenOwner, amountRaised);
        crowdsaleEnded = true;
    }

    // Allows the funders to withdraw their funds if the goal has not been reached.
    // Only works after funds have been returned from the wallet.
    function safeWithdrawal() public afterDeadline {
        uint amount = balances[msg.sender];
        if (address(this).balance >= amount) {
            balances[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                FundTransfer(msg.sender, amount, false, amountRaised);
            }
        }
    }
}