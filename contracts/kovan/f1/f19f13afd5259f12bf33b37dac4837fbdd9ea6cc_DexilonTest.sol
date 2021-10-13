/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract DexilonTest {

    mapping(address => uint256) public addressToAmountFunded;
    mapping(address => uint256) public addressToBalance;
    mapping(address => uint256) public addressToLockedBalance;
    mapping(address => uint256) public addressToBTC;
    mapping(address => uint256) public addressToInverseBTC;
    address[] public funders;
    uint256 public funderCount;
    uint256 public rateETHtoUSD;
    uint256 public rateBTCtoUSD;
    uint8 public decimals;
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
        funderCount = 0;
        decimals = 18;
        rateETHtoUSD = 4000;
        rateBTCtoUSD = 50000;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setNewETHrate(uint256 newETHrate) public onlyOwner {
        rateETHtoUSD = newETHrate;
    }
    
    function setNewBTCrate(uint256 newBTCrate) public onlyOwner {
        rateBTCtoUSD = newBTCrate;
    }

    function deposit() public payable {
        require(
            msg.value >= 1000000000,
            "You need to spend more than 1 Gwei!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        addressToBalance[msg.sender] += msg.value * rateETHtoUSD;
        funders.push(msg.sender);
        funderCount += 1;
    }
    
    function getAllUserBalances(address userAddress) public view 
        returns(
        uint256 balance, 
        uint256 lockedBalance,
        uint256 btcBalance,
        uint256 inverseBtcBalance
        ) {
            balance = addressToBalance[userAddress] / 10**decimals;
            lockedBalance = addressToLockedBalance[userAddress] / 10**decimals;
            btcBalance = addressToBTC[userAddress] / 10**decimals;
            inverseBtcBalance = addressToInverseBTC[userAddress] / 10**decimals;
        }

    function withdrawAll() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function withdraw(uint256 amountUSD) public {
        require(amountUSD * 10**decimals <= (addressToBalance[msg.sender]), 'Insufficient balance!');
        addressToAmountFunded[msg.sender] -= amountUSD * 10**decimals / rateETHtoUSD;
        addressToBalance[msg.sender] -= amountUSD * 10**decimals;
        payable(msg.sender).transfer(amountUSD * 10**decimals / rateETHtoUSD);
    }

    function buyBTC(address maker, address taker, uint256 amount, uint256 rate) public onlyOwner {
        
        uint256 currentBtcRate = rate;
        
        amount = amount * 10**decimals;
        
        // maker sells BTC
        if (addressToBTC[maker] < amount) {
            amount = amount - addressToBTC[maker];
            addressToBTC[maker] = 0;
            addressToInverseBTC[maker] += amount;
            addressToBalance[maker] -= amount * currentBtcRate;
            addressToLockedBalance[maker] += amount * currentBtcRate;
        } else {
            addressToBTC[maker] -= amount;
            addressToBalance[maker] += amount * currentBtcRate;
            addressToLockedBalance[maker] -= amount * currentBtcRate;
        }
        
        // taker buys BTC
        if (addressToInverseBTC[taker] > amount) {
            addressToInverseBTC[taker] -= amount;
            addressToBalance[taker] += amount * currentBtcRate;
            addressToLockedBalance[taker] -= amount * currentBtcRate;
        } else {
            addressToLockedBalance[taker] -= addressToInverseBTC[taker] * currentBtcRate;
            addressToBalance[taker] += addressToInverseBTC[taker] * currentBtcRate;
            amount = amount - addressToInverseBTC[taker];
            addressToInverseBTC[taker] = 0;
            addressToBTC[taker] += amount;
            addressToLockedBalance[taker] += amount * currentBtcRate;
            addressToBalance[taker] -= amount * currentBtcRate;

        }
        
    }
}