pragma solidity ^0.4.13;

/*

Monetha Buyer Withdraw Helper Contract
=======================================

Withdraws your allotment of Monetha (MTH) tokens from the Monetha Buyer contract
Author: /u/troythus (aka @troyth)

Note that the Monetha tokens will not be available until after Sept 5, 2017 at 2pm UTC
Any attempts to send ETH to this contract in advance of this time will forfeit that ETH

*/


contract MBInterface {
    // interface to list of balances by investor wallet address
    // solidity compiler automatically generates getter function for public vars
    function balances(address user) returns (uint256 balance);
    // interface to the withdraw function
    function withdraw(address user);
}


contract MonethaBuyerWithdrawHelper{
    // utility contract developer address
    address public owner = 0x570dccd747758603612E79B270E8beD38f935503;
    // address of original Monetha Buyer contract created by cintix
    address MonethaBuyerAddr = 0x820b5D21D1b1125B1aaD51951F6e032A07CaEC65;
    // dynamically calculated minimum fee of 1% to trigger withdraw function on MonethaBuyer contract
    uint256 min_fee;

    // store the amount of ETH donated by supporters
    mapping (address => uint256) public supporterBalances;

    // constructor
    function WithdrawMonethaBuyerUtility(){
    }

    // transfers ETH held by the contract to the owner
    function claim () returns (bool success){
        require(msg.sender == owner);
        if(msg.sender == owner){
            owner.transfer(this.balance);
            return true;
        }
        return false;
    }

    // receives donations in ETH
    function donate() payable {
        //receives donations, logs address of donator and amount given
        supporterBalances[msg.sender] += msg.value;
    }

    // default function called when someone sends ETH to this contract
    // triggers the withdraw function on MonethaBuyer contract with their address
    function () payable {
        // set up interface to Monetha Buyer contract
        MBInterface MB = MBInterface(MonethaBuyerAddr);

        // make sure wallet has not already been withdrawn and did investe in Monetha Buyer
        if(MB.balances(msg.sender) != 0){
            // determine minimum fee as 1% of investment in ETH
            min_fee = MB.balances(msg.sender) / 100;

            // cap to 3 ETH
            if(min_fee > 3000000000000000000){
                min_fee = 3000000000000000000;
            }

            // if min fee sent, call the withdraw function on MonethaBuyer
            if(msg.value >= min_fee){
                MB.withdraw( msg.sender );
            }
        }
    }
}