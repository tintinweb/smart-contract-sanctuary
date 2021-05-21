/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
This is a revival/rewrite of the GovernMental contract from 2016. To quote the original, "This is an educational game which 
simulates the finances of a government. In other words: It's a Ponzi scheme." Because of the number of shitcoins and scams 
that we've seen recently, I decided this could be fun.

The rules of the scam, erm, I mean game are quite simple:

    1. You can lend the government money - they promise to pay it back +10% interest. Minimum contribution is 0.003 Ether ($8).
    2. If the government does not receive new money for 12h the system breaks down. 
        The latest creditor saw the crash coming and receives the jackpot. All others will lose their claims.
    3. All incoming money is used in the following way: 
        - 5% to the jackpot, capped at 67558 Ether.
        - 5% goes to the corrupt elite.
        - 90% is used to pay off the other creditors.
    4. Creditors can share an affiliate link. Money deposited this way is distributed as follows: 
        5% go toward the linker directly, 5% to the corrupt elite, 5% into the jackpot (until full). 
        The rest is used for payouts.

This contract is not vulnerable to the same attack the ended GovernMental.
Keep in mind that you may or may not make money off of this. Only invest what you can afford to lose.
*/

/// @title Governmental
contract Governmental {
    /// @notice Used to when the corrupt wish to communicate with the clodpates.
    /// @param timestamp The time of the communication.
    /// @param message The message.
    event MessageFromTheCorrupt(uint256 indexed timestamp, string message);
    event JackpotPaidOut(uint256 timestamp, address user);

    uint32 public nextCreditor; // The first creditor who hasn't yet been paid.
    uint256 public lastInvestment; // The timestamp of the last investment.
    uint256 public totalJackpot; // The amount the last creditor will win.

    address payable[] public creditorAddresses; // A list of creditor addresses.
    uint256[] public creditorAmounts; // A list of amounts owed.
    
    mapping(address => uint256) public clodpates; // Creditors. A clodpate is a dull and stupid person, like you, dear sheep.
    mapping (address=>uint256) public referrals;
    
    address payable public corruptElite; // That's me!

    uint256 public round = 0; // Round counter.
    uint256 constant TWELVE_HOURS = 12 hours; // Twelve hours. If you needed this comment to understand that, you're a clodpate and you should go invest!

    constructor() payable {
        /// The corrupt elite establish a new government.
        /// This is the commitment of the corrupt elite. Everything that cannot be saved from a crash.
        /// Join me, my dear clodpates, and become rich!
        totalJackpot = msg.value;
        corruptElite = payable(msg.sender);
        lastInvestment = block.timestamp;
    }

    /// @notice Lend the government money. We gladly welcome new clodpates.
    function lendMoney(address referrer) public payable {
        uint256 val = msg.value;
        // Check if the system has broken down.
        if (lastInvestment + TWELVE_HOURS <= block.timestamp) {
            emit MessageFromTheCorrupt(
                block.timestamp,
                "This is the end, dear clodpates!"
            );
            payable(msg.sender).transfer(val); // Return the money.

            // Send the jackpot.
            creditorAddresses[creditorAddresses.length - 1].transfer(
                totalJackpot
            );
            corruptElite.transfer(address(this).balance);
            emit JackpotPaidOut(block.timestamp, msg.sender);

            // The system shall rise.
            nextCreditor = 0;
            lastInvestment = block.timestamp;
            totalJackpot = 0;
            creditorAddresses = new address payable[](0);
            creditorAmounts = new uint256[](0);

            round += 1;
        } else {
            // Collect some of the jackpot to restart the system.
            if(val >= 10 ** 18) {
                lastInvestment = block.timestamp;
                
                creditorAddresses.push(payable(msg.sender));
                creditorAmounts.push(val * 110/100);

                // The corrupt elite take 5%
                corruptElite.transfer(val * 5/100);

                // If you are referred by a corrupt official, they get 5%.
                if(referrals[referrer] >= val) {
                    payable(referrer).transfer(val * 5/100);
                }

                referrals[msg.sender] += val * 110/100;
                if(creditorAmounts[nextCreditor] <= address(this).balance - totalJackpot) {
                    creditorAddresses[nextCreditor].transfer(creditorAmounts[nextCreditor]);
                    referrals[creditorAddresses[nextCreditor]] -= creditorAmounts[nextCreditor];
                    nextCreditor += 1;
                }
            } else {
                payable(msg.sender).transfer(val);
            }
        }
    }

    // Invest in the system. Not recommened unless you're trying to build trust.
    function investInSystem() public payable {
        totalJackpot += msg.value;
    }

    // Updates the corrupt elite.
    function updateCorruptElite(address payable _corruptElite) public {
        require(msg.sender == corruptElite, "Lier, scoundrel, usurper");
        corruptElite = _corruptElite;
    }

    // Get the total debt.
    function totalDebt() public view returns (uint256 debt) {
        for(uint i = nextCreditor; i < creditorAmounts.length; i++) {
            debt += creditorAmounts[i];
        }
    }
    
    // Get the total amount paid out.
    function totalPayedOut() public view returns (uint total) {
        for(uint i = 0; i < nextCreditor; i ++) {
            total += creditorAmounts[i];
        }
    }

    // You can also blindly throw money at the contract.
    fallback() external payable {
        lendMoney(address(0));
    }
}