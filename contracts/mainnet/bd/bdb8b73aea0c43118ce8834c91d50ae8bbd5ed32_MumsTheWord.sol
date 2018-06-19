pragma solidity ^0.4.11;

contract MumsTheWord {

    uint32 public lastCreditorPayedOut;
    uint public lastTimeOfNewCredit;
    uint public jackpot;
    address[] public creditorAddresses;
    uint[] public creditorAmounts;
    address public owner;
	uint8 public round;
	
	// eight hours
    uint constant EIGHT_HOURS = 28800;
	uint constant MIN_AMOUNT = 10 ** 16;

    function MumsTheWord() {
        // owner of the contract will provide the initial jackpot!
        jackpot = msg.value;
        owner = msg.sender;
        lastTimeOfNewCredit = now;
    }

    function enter() payable returns (bool) {
        uint amount = msg.value;
        // check if 8h have passed
        if (lastTimeOfNewCredit + EIGHT_HOURS > now) {
            // Return money to sender
            msg.sender.transfer(amount);
            // Sends jackpot to the last player
            creditorAddresses[creditorAddresses.length - 1].transfer(jackpot);
            owner.transfer(this.balance);
            // Reset contract state
            lastCreditorPayedOut = 0;
            lastTimeOfNewCredit = now;
            jackpot = 0;
            creditorAddresses = new address[](0);
            creditorAmounts = new uint[](0);
            round += 1;
            return false;
        } else {
            // the system needs to collect at least 1% of the profit from a crash to stay alive
            if (amount >= MIN_AMOUNT) {
                // the System has received fresh money, it will survive at least 8h more
                lastTimeOfNewCredit = now;
                // register the new creditor and his amount with 10% interest rate
                creditorAddresses.push(msg.sender);
                creditorAmounts.push(amount * 110 / 100);
				
                // 5% fee
                owner.transfer(amount * 5/100);
				
                // 5% are going to the jackpot (will increase the value for the last person standing)
                if (jackpot < 100 ether) {
                    jackpot += amount * 5/100;
                }
				
                // 90% of the money will be used to pay out old creditors
                if (creditorAmounts[lastCreditorPayedOut] <= address(this).balance - jackpot) {
                    creditorAddresses[lastCreditorPayedOut].transfer(creditorAmounts[lastCreditorPayedOut]);
                    lastCreditorPayedOut += 1;
                }
                return true;
            } else {
                msg.sender.transfer(amount);
                return false;
            }
        }
    }

    // fallback function
    function() payable {
        enter();
    }

    function totalDebt() returns (uint debt) {
        for(uint i=lastCreditorPayedOut; i<creditorAmounts.length; i++){
            debt += creditorAmounts[i];
        }
    }

    function totalPayedOut() returns (uint payout) {
        for(uint i=0; i<lastCreditorPayedOut; i++){
            payout += creditorAmounts[i];
        }
    }

    // better don&#39;t do it (unless you want to increase the jackpot)
    function raiseJackpot() payable {
        jackpot += msg.value;
    }

    function getCreditorAddresses() returns (address[]) {
        return creditorAddresses;
    }

    function getCreditorAmounts() returns (uint[]) {
        return creditorAmounts;
    }
}