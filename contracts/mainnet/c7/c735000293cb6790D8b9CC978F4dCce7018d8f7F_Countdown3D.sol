pragma solidity 0.5.0;

/*
* In Contracts We Trust
*
* Countdown3D is a provably-fair multi tier lottery played using Ether
*
* ======================== *
*     CRYPTO COUNTDOWN     *
*          3 2 1           *
* ======================== *
* [x] Provably Fair
* [x] Open Source
* [x] Multi Tier Rewards
* [x] Battle Tested with the Team Just community!
*
*/

// Invest in Hourglass Contract Interface
// 0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe
interface HourglassInterface {
    // Invest in dividends for bigger better shinier future jackpots
    function buy(address _playerAddress) external payable returns(uint256);
    // Withdraw hourglass dividends to the round pot
    function withdraw() external;
    // Would you look at all those divs
    function dividendsOf(address _playerAddress) external view returns(uint256);
    // Check out that hourglass balance
    function balanceOf(address _playerAddress) external view returns(uint256);
}


contract Countdown3D {

    /* ==== INTERFACE ==== */
    HourglassInterface internal hourglass;

    /* ==== EVENTS ==== */
    // Emit event onBuy
    event OnBuy(address indexed _playerAddress, uint indexed _roundId, uint _tickets, uint _value);
    // Emit event when round is capped
    event OnRoundCap(uint _roundId);
    // Emit event when new round starts
    event OnRoundStart(uint _roundId);

    /* ==== GLOBALS ==== */
    // Crypto Countdown timer
    uint256 constant public COOLDOWN = 7 days;

    // Cost per ticket
    uint256 constant public COST = 0.01 ether;

    // Claim your winnings within 5 rounds
    uint256 constant public EXPIRATION = 5;

    // Minimum number of tickets needed to build a pyramid
    uint256 constant public QUORUM = 21;

    // Maximum tickets an account can hold at any given time
    uint256 constant public TICKET_MAX = 101;

    // The Current Round
    uint256 public currentRoundId;

    // Developers
    address private dev1;
    address private dev2;

    /* ==== STRUCT ==== */
    struct Round {
        // Balance set after the round is capped
        uint256 balance;
        // Block number that caps this round
        uint256 blockCap;
        // Ether claimed from this round
        uint256 claimed;
        // Pot is composed of tickets, donations, unclaimed winnings, percent of previous round, and hourglass dividends
        uint256 pot;
        // Random index from the future
        uint256 random;
        // Timestamp when this round kicks off
        uint256 startTime;
        // Total tickets in this round
        uint256 tickets;
        // Value of a ticket in each winning tier
        mapping (uint256 => uint256) caste;
        // Validate a round to score a reward
        mapping (address => uint256) reward;
    }

    struct Account {
        // Store each round an account holds tickets
        uint256[] roundsActive;
        // Store each round an account holds validation rewards
        uint256[] rewards;
        // Map Round id to ticket sets
        mapping(uint256 => TicketSet[]) ticketSets;
        // Total tickets held by account
        uint256 tickets;
    }

    // A set of tickets
    struct TicketSet {
        // Index of first ticket in set
        uint256 start;
        // Index of last ticket in the set
        uint256 end;
    }

    // Map a round id to a round
    mapping (uint256 => Round) internal rounds;
    // Map an address to an account
    mapping (address => Account) internal accounts;

    /* ==== CONSTRUCTOR ==== */
    constructor(address hourglassAddress, address dev1Address, address dev2Address) public {
        // Set round 0 start time here
        rounds[0].startTime = now + 7 days;
        // Set hourglass interface
        hourglass = HourglassInterface(hourglassAddress);
        // Set dev1
        dev1 = dev1Address;
        // Set dev2
        dev2 = dev2Address;
    }
    /* ==== PUBLIC WRITE ==== */

    // Ether sent directly to contract gets donated to the pot
    function ()
        external
        payable
    {
        // Donate ETH sent directly to contract as long as the sender is not the hourglass contract
        if (msg.sender != address(hourglass)) {
            donateToPot();
        }
    }

    // Buy a ticket or tickets
    function buy()
        public
        payable
    {
        // Current round or next round
        (Round storage round, uint256 roundId) = getRoundInProgress();

        // Calculate number of tickets and any change
        (uint256 tickets, uint256 change) = processTickets();

        // Send change to the round pot
        round.pot = round.pot + change;

        // Allocate tickets to account
        if (tickets > 0) {
            // Give player their tickets
            pushTicketSetToAccount(roundId, tickets);
            // Increment tickets in the round
            round.tickets = round.tickets + tickets;
        }
        // Broadcast an event when a ticket set is purchased
        emit OnBuy(msg.sender, roundId, tickets, msg.value);
    }

    // Support a good cause, invest in dividends
    function donateToDivs()
        public
        payable
    {
        // Buys investment tokens from hourglass contract
        hourglass.buy.value(msg.value)(msg.sender);
    }

    // Support a good cause, donate to the round pot
    function donateToPot()
        public
        payable
    {
        if (msg.value > 0) {
            // Current round or next round
            (Round storage round,) = getRoundInProgress();
            round.pot = round.pot + msg.value;
        }
    }

    // Complete and Secure the round
    function validate()
        public
    {
        // Current Round
        Round storage round = rounds[currentRoundId];

        // First check if round was already validated
        require(round.random == 0);

        // Require minimum number of tickets to build a pyramid
        require(round.tickets >= QUORUM);

        // Require cooldown between rounds
        require(round.startTime + COOLDOWN <= now);

        // If blockcap is not set yet, cap the round
        if (round.blockCap == 0) {
            allocateToPot(round);
            allocateFromPot(round);

            // Set blockcap
            round.blockCap = block.number;
            emit OnRoundCap(currentRoundId);
        } else {
            // Require a future block
            require(block.number > round.blockCap);

            // Get blockhash from the blockcap block
            uint32 blockhash_ = uint32(bytes4(blockhash(round.blockCap)));

            // Confirm blockhash has not expired on network
            if (blockhash_ != 0) {
                closeTheRound(round, blockhash_);
            } else {
                // Cap round again
                round.blockCap = block.number;
                emit OnRoundCap(currentRoundId);
            }
        }
    }

    // Withdraw ticket winnings
    function withdraw()
        public
    {
        // Total amount to withdraw
        uint256 total;
        // Flag to check if account holds current or next round tickets
        bool withholdRounds;
        // Player account
        Account storage account = accounts[msg.sender];
        // Total number of rounds a player holds tickets
        uint256 accountRoundsActiveLength = account.roundsActive.length;

        // Loop through each round the player holds tickets
        for (uint256 i = 0; i < accountRoundsActiveLength; i++) {
            uint256 roundId = account.roundsActive[i];

            // Only check if round was already validated
            if (roundId < currentRoundId) {
                // Get amount won in the round
                (uint256 amount, uint256 totalTickets) = getRoundWinnings(msg.sender, roundId);

                // Subtract tickets from account
                account.tickets = account.tickets - totalTickets;

                // Delete round from player&#39;s account
                delete account.ticketSets[roundId];

                // If the player won during the round
                if (amount > 0) {
                    // Increment amount claimed
                    rounds[roundId].claimed = rounds[roundId].claimed + amount;
                    // Add to total withdraw
                    total = total + amount;
                }
            } else {
                // Flag to check if account holds current or next round tickets
                withholdRounds = true;
            }
        }

        // Delete processed rounds
        sweepRoundsActive(withholdRounds);

        // Last but not least, send ticket winnings
        if (total > 0) {
            msg.sender.transfer(total);
        }
    }

    // Did you validate a round, claim your rewards here
    function claimRewards()
        public
    {
        // Total amount to withdraw
        uint256 total;
        // Player account
        Account storage account = accounts[msg.sender];
        // Total number of rounds with rewards
        uint256 accountRewardsLength = account.rewards.length;

        // Loop through each round the player holds rewards
        for (uint256 i = 0; i < accountRewardsLength; i++) {
            // Round with a reward
            uint256 roundId = account.rewards[i];
            // Get reward amount won in the round
            uint256 amount = getRewardWinnings(msg.sender, roundId);
            // Delete reward from round
            delete rounds[roundId].reward[msg.sender];

            // If player has rewards in the round
            if (amount > 0) {
                // Increment amount claimed
                rounds[roundId].claimed = rounds[roundId].claimed + amount;
                // Add to total withdraw
                total = total + amount;
            }
        }

        // Delete processed rewards
        delete accounts[msg.sender].rewards;

        // Transfer rewards to player
        if (total > 0) {
            msg.sender.transfer(total);
        }
    }

    /* ==== PUBLIC READ ==== */
    // Get global game constants
    function getConfig()
        public
        pure
        returns(uint256 cooldown, uint256 cost, uint256 expiration, uint256 quorum, uint256 ticketMax)
    {
        return(COOLDOWN, COST, EXPIRATION, QUORUM, TICKET_MAX);
    }

    // Get info for a given Round
    function getRound(uint256 roundId)
        public
        view
        returns(
            uint256 balance, 
            uint256 blockCap, 
            uint256 claimed, 
            uint256 pot, 
            uint256 random, 
            uint256 startTime, 
            uint256 tickets)
    {
        Round storage round = rounds[roundId];

        return(round.balance, round.blockCap, round.claimed, round.pot, round.random, round.startTime, round.tickets);
    }

    // Get total number of tickets held by account
    function getTotalTickets(address accountAddress)
        public
        view
        returns(uint256 tickets)
    {
        return accounts[accountAddress].tickets;
    }

    // Get value of ticket held in each winning caste
    function getRoundCasteValues(uint256 roundId)
        public
        view
        returns(uint256 caste0, uint256 caste1, uint256 caste2)
    {
        return(rounds[roundId].caste[0], rounds[roundId].caste[1], rounds[roundId].caste[2]);
    }

    // Get rounds account is active
    function getRoundsActive(address accountAddress)
        public
        view
        returns(uint256[] memory)
    {
        return accounts[accountAddress].roundsActive;
    }

    // Get the rounds an account has unclaimed rewards
    function getRewards(address accountAddress)
        public
        view
        returns(uint256[] memory)
    {
        return accounts[accountAddress].rewards;
    }

    // Get the total number of ticket sets an account holds for a given round
    function getTotalTicketSetsForRound(address accountAddress, uint256 roundId)
        public
        view
        returns(uint256 ticketSets)
    {
        return accounts[accountAddress].ticketSets[roundId].length;
    }

    // Get an account&#39;s individual ticket set from a round
    function getTicketSet(address accountAddress, uint256 roundId, uint256 index)
        public
        view
        returns(uint256 start, uint256 end)
    {
        TicketSet storage ticketSet = accounts[accountAddress].ticketSets[roundId][index];

        // Starting ticket and ending ticket in set
        return (ticketSet.start, ticketSet.end);
    }

    // Get the value of a ticket
    function getTicketValue(uint256 roundId, uint256 ticketIndex)
        public
        view
        returns(uint256 ticketValue)
    {
        // Check if the round expired
        if (currentRoundId > roundId && (currentRoundId - roundId) >= EXPIRATION) {
            return 0;
        }

        Round storage round = rounds[roundId];
        // Set which tier the ticket is in
        uint256 tier = getTier(roundId, ticketIndex);

        // Return ticket value based on tier
        if (tier == 5) {
            return 0;
        } else if (tier == 4) {
            return COST / 2;
        } else if (tier == 3) {
            return COST;
        } else {
            return round.caste[tier];
        }
    }

    // Get which tier a ticket is in
    function getTier(uint256 roundId, uint256 ticketIndex)
        public
        view
        returns(uint256 tier)
    {
        Round storage round = rounds[roundId];
        // Distance from random index
        uint256 distance = Math.distance(round.random, ticketIndex, round.tickets);
        // Tier based on ticket index
        uint256 ticketTier = Caste.tier(distance, round.tickets - 1);

        return ticketTier;
    }

    // Get the amount won in a round
    function getRoundWinnings(address accountAddress, uint256 roundId)
        public
        view
        returns(uint256 totalWinnings, uint256 totalTickets)
    {
        // Player account
        Account storage account = accounts[accountAddress];
        // Ticket sets an account holds in a given round
        TicketSet[] storage ticketSets = account.ticketSets[roundId];

        // Holds total winnings in a round
        uint256 total;
        // Total number of ticket sets
        uint256 ticketSetLength = ticketSets.length;
        // Holds total individual tickets in a round
        uint256 totalTicketsInRound;

        // Check if round expired
        if (currentRoundId > roundId && (currentRoundId - roundId) >= EXPIRATION) {
            // Round expired
            // Loop through each ticket set
            for (uint256 i = 0; i < ticketSetLength; i++) {
                // Calculate the total number of tickets in a set
                uint256 totalTicketsInSet = (ticketSets[i].end - ticketSets[i].start) + 1;
                // Add the total number of tickets to the total number of tickets in the round
                totalTicketsInRound = totalTicketsInRound + totalTicketsInSet;
            }

            // After looping through all of the tickets, return total winnings and total tickets in round
            return (total, totalTicketsInRound);
        }

        // If the round has not expired, Loop through each ticket set
        for (uint256 i = 0; i < ticketSetLength; i++) {
            // Subtract one to get true ticket index
            uint256 startIndex = ticketSets[i].start - 1;
            uint256 endIndex = ticketSets[i].end - 1;
            // Loop through each ticket
            for (uint256 j = startIndex; j <= endIndex; j++) {
                // Add the ticket value to total round winnings
                total = total + getTicketWinnings(roundId, j);
            }
            // Calculate the total number of tickets in a set
            uint256 totalTicketsInSet = (ticketSets[i].end - ticketSets[i].start) + 1;
            // Set the total number of tickets in a round
            totalTicketsInRound = totalTicketsInRound + totalTicketsInSet;
        }
        // After looping through all of the tickets, return total winnings and total tickets in round
        return (total, totalTicketsInRound);
    }

    // Get the value of a reward in a round such as validator reward
    function getRewardWinnings(address accountAddress, uint256 roundId)
        public
        view
        returns(uint256 reward)
    {
        // Check if round expired
        if (currentRoundId > roundId && (currentRoundId - roundId) >= EXPIRATION) {
            // Reward expired
            return 0;
        }
        // Reward did not expire
        return rounds[roundId].reward[accountAddress];
    }

    // Get dividends from hourglass contract
    function getDividends()
        public
        view
        returns(uint256 dividends)
    {
        return hourglass.dividendsOf(address(this));
    }

    // Get total amount of tokens owned by contract
    function getHourglassBalance()
        public
        view
        returns(uint256 hourglassBalance)
    {
        return hourglass.balanceOf(address(this));
    }

    /* ==== PRIVATE ==== */
    // At the end of the round, distribute percentages from the pot
    function allocateFromPot(Round storage round)
        private
    {
        // 75% to winning Castes
        (round.caste[0], round.caste[1], round.caste[2]) = Caste.values((round.tickets - 1), round.pot, COST);

        // 15% to next generation
        rounds[currentRoundId + 1].pot = (round.pot * 15) / 100;

        // 2% to each dev
        uint256 percent2 = (round.pot * 2) / 100;
        round.reward[dev1] = percent2;
        round.reward[dev2] = percent2;

        // Cleanup unclaimed dev rewards
        if (accounts[dev1].rewards.length == TICKET_MAX) {
            delete accounts[dev1].rewards;
        }
        if (accounts[dev2].rewards.length == TICKET_MAX) {
            delete accounts[dev2].rewards;
        }
        // Store round with reward
        accounts[dev1].rewards.push(currentRoundId);
        accounts[dev2].rewards.push(currentRoundId);

        // 5% buys hourglass token
        hourglass.buy.value((round.pot * 5) / 100)(msg.sender);

        // 20% of round pot claimed from 15% to next round and 5% investment in hourglass token
        round.claimed = (round.pot * 20) / 100;
    }

    // At the end of the round, allocate investment dividends and bottom tiers to the pot
    function allocateToPot(Round storage round)
        private
    {
        // Balance is seed pot combined with total tickets
        round.balance = round.pot + (round.tickets * COST);

        // Bottom tiers to the pot
        round.pot = round.pot + Caste.pool(round.tickets - 1, COST);

        // Check investment dividends accrued
        uint256 dividends = getDividends();
        // If there are dividends available
        if (dividends > 0) {
            // Withdraw dividends from hourglass contract
            hourglass.withdraw();
            // Allocate dividends to the round pot
            round.pot = round.pot + dividends;
        }
    }

    // Close the round
    function closeTheRound(Round storage round, uint32 blockhash_)
        private
    {
        // Prevent devs from validating round since they already get a reward
        require(round.reward[msg.sender] == 0);
        // Reward the validator
        round.reward[msg.sender] = round.pot / 100;
        // If validator hits a limit without withdrawing their rewards
        if (accounts[msg.sender].rewards.length == TICKET_MAX) {
            delete accounts[msg.sender].rewards;
        }

        // Store round id validator holds a reward
        accounts[msg.sender].rewards.push(currentRoundId);

        // Set random number
        round.random = Math.random(blockhash_, round.tickets);

        // Set current round id
        currentRoundId = currentRoundId + 1;

        // New Round
        Round storage newRound = rounds[currentRoundId];

        // Set next round start time
        newRound.startTime = now;

        // Start expiring rounds at Round 5
        if (currentRoundId >= EXPIRATION) {
            // Set expired round
            Round storage expired = rounds[currentRoundId - EXPIRATION];
            // Check if expired round has a balance
            if (expired.balance > expired.claimed) {
                // Allocate expired funds to next round
                newRound.pot = newRound.pot + (expired.balance - expired.claimed);
            }
        }

        // Broadcast a new round is starting
        emit OnRoundStart(currentRoundId);
    }

    // Get Current round or next round depending on whether blockcap is set
    function getRoundInProgress()
        private
        view
        returns(Round storage, uint256 roundId)
    {
        // Current Round if blockcap not set yet
        if (rounds[currentRoundId].blockCap == 0) {
            return (rounds[currentRoundId], currentRoundId);
        }
        // Next round if blockcap is set
        return (rounds[currentRoundId + 1], currentRoundId + 1);
    }

    // Get the value of an individual ticket in a given round
    function getTicketWinnings(uint256 roundId, uint256 index)
        private
        view
        returns(uint256 ticketValue)
    {
        Round storage round = rounds[roundId];
        // Set which tier the ticket is in
        uint256 tier = getTier(roundId, index);

        // Return ticket value based on tier
        if (tier == 5) {
            return 0;
        } else if (tier == 4) {
            return COST / 2;
        } else if (tier == 3) {
            return COST;
        } else {
            return round.caste[tier];
        }
    }

    // Calculate total tickets and remainder based on message value
    function processTickets()
        private
        view
        returns(uint256 totalTickets, uint256 totalRemainder)
    {
        // Calculate total tickets based on msg.value and ticket cost
        uint256 tickets = Math.divide(msg.value, COST);
        // Calculate remainder based on msg.value and ticket cost
        uint256 remainder = Math.remainder(msg.value, COST);

        return (tickets, remainder);
    }

    // Stores ticket set in player account
    function pushTicketSetToAccount(uint256 roundId, uint256 tickets)
        private
    {
        // Player account
        Account storage account = accounts[msg.sender];
        // Round to add tickets
        Round storage round = rounds[roundId];

        // Store which rounds the player buys tickets in
        if (account.ticketSets[roundId].length == 0) {
            account.roundsActive.push(roundId);
        }

        // Require existing tickets plus new tickets
        // Is less than maximum allowable tickets an account can hold
        require((account.tickets + tickets) < TICKET_MAX);
        account.tickets = account.tickets + tickets;

        // Store ticket set
        account.ticketSets[roundId].push(TicketSet(round.tickets + 1, round.tickets + tickets));
    }

    // Delete unused state after withdrawing to lower gas cost for the player
    function sweepRoundsActive(bool withholdRounds)
        private
    {
        // Delete any rounds that are not current or next round
        if (withholdRounds != true) {
            // Remove active rounds from player account
            delete accounts[msg.sender].roundsActive;
        } else {
            bool current;
            bool next;
            // Total number of active rounds
            uint256 roundActiveLength = accounts[msg.sender].roundsActive.length;

            // Loop each round account was active
            for (uint256 i = 0; i < roundActiveLength; i++) {
                uint256 roundId = accounts[msg.sender].roundsActive[i];

                // Flag if account has tickets in current round
                if (roundId == currentRoundId) {
                    current = true;
                }
                // Flag if account has tickets in next round
                if (roundId > currentRoundId) {
                    next = true;
                }
            }

            // Remove active rounds from player account
            delete accounts[msg.sender].roundsActive;

            // Add back current round if player holds tickets in current round
            if (current == true) {
                accounts[msg.sender].roundsActive.push(currentRoundId);
            }
            // Add back current round if player holds tickets in next round
            if (next == true) {
                accounts[msg.sender].roundsActive.push(currentRoundId + 1);
            }
        }
    }
}


/**
 * @title Math
 * @dev Math operations with safety checks that throw on error
 */
library Math {
    /**
    * @dev Calculates a distance between start and finish wrapping around total
    */
    function distance(uint256 start, uint256 finish, uint256 total)
        internal
        pure
        returns(uint256)
    {
        if (start < finish) {
            return finish - start;
        }
        if (start > finish) {
            return (total - start) + finish;
        }
        if (start == finish) {
            return 0;
        }
    }

    /**
    * @dev Calculates the quotient between the numerator and denominator.
    */
    function divide(uint256 numerator, uint256 denominator)
        internal
        pure
        returns (uint256)
    {
        // EVM does not allow division by zero
        return numerator / denominator;
    }

    /**
    * @dev Generate random number from blockhash
    */
    function random(uint32 blockhash_, uint256 max)
        internal
        pure
        returns(uint256)
    {
        // encoded blockhash as uint256
        uint256 encodedBlockhash = uint256(keccak256(abi.encodePacked(blockhash_)));
        // random number from 0 to (max - 1)
        return (encodedBlockhash % max);
    }

    /**
    * @dev Calculates the remainder between the numerator and denominator.
    */
    function remainder(uint256 numerator, uint256 denominator)
        internal
        pure
        returns (uint256)
    {
        // EVM does not allow division by zero
        return numerator % denominator;
    }
}


/**
 * @title Caste
 * @dev Caste operations
 */
library Caste {

    /**
    * @dev Calculates amount of ether to transfer to the pot from the caste pool
    * total is 1 less than total number of tickets to take 0 index into account
    */
    function pool(uint256 total, uint256 cost)
        internal
        pure
        returns(uint256)
    {
        uint256 tier4 = ((total * 70) / 100) - ((total * 45) / 100);
        uint256 tier5 = total - ((total * 70) / 100);

        return (tier5 * cost) + ((tier4 * cost) / 2);
    }

    /**
    * @dev Provides the tier based on an index and total in the caste pool
    */
    function tier(uint256 distance, uint256 total)
        internal
        pure
        returns(uint256)
    {
        uint256 percent = (distance * (10**18)) / total;

        if (percent > 700000000000000000) {
            return 5;
        }
        if (percent > 450000000000000000) {
            return 4;
        }
        if (percent > 250000000000000000) {
            return 3;
        }
        if (percent > 100000000000000000) {
            return 2;
        }
        if (percent > 0) {
            return 1;
        }
        if (distance == 0) {
            return 0;
        } else {
            return 1;
        }
    }

    /**
    * @dev Calculates value per winning caste
    */
    function values(uint256 total, uint256 pot, uint256 cost)
        internal
        pure
        returns(uint256, uint256, uint256)
    {
        uint256 percent10 = (total * 10) / 100;
        uint256 percent25 = (total * 25) / 100;
        uint256 caste0 = (pot * 25) / 100;
        uint256 caste1 = cost + (caste0 / percent10);
        uint256 caste2 = cost + (caste0 / (percent25 - percent10));

        return (caste0 + cost, caste1, caste2);
    }
}