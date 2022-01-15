// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title LOM-Lottery
 * @author Juan Salazar
 * @dev Smart Contrac very Simple for Lottery Projects
 */

contract FastWin {
    event LotteryTicketPurchased(address indexed _purchaser, uint256 _ticketID);

    event LotteryAmountPaid(
        address indexed _winner,
        uint256 _ticketID,
        uint256 _amount
    );

    // Note: prone to change
    uint256 public ticketPrice = 5000000000000000;
    uint256 public ticketMax = 50;

    // Initialize mapping
    address[51] public ticketMapping;
    uint256 public ticketsBought = 0;

    // round ID
    uint256 public roundId = 1;

    // Jackpot
    uint256 public jackpot = 0;

    // Prevent potential locked funds by checking greater than
    modifier allTicketsSold() {
        require(ticketsBought >= ticketMax);
        _;
    }

    /**
     * @dev Purchase ticket and send reward if necessary
     * @param _ticket Ticket number to purchase
     * @return bool Validity of transaction
     */

    function buyTicket(uint256 _ticket) external payable returns (bool) {
        require(
            msg.value == ticketPrice,
            "Incorrect amount sent to LOM contract"
        );
        require(
            _ticket > 0 && _ticket < ticketMax + 1,
            "Incorrect Ticket Number selected"
        );
        require(ticketMapping[_ticket] == address(0));
        require(
            ticketsBought < ticketMax,
            "We have filled all the available tickets"
        );

        // Avoid reentrancy attacks

        // Avoid reentrancy attacks
        address purchaser = msg.sender;
        ticketsBought += 1;
        ticketMapping[_ticket] = purchaser;
        jackpot += ticketPrice;
        emit LotteryTicketPurchased(purchaser, _ticket);

        /** Placing the "burden" of sendReward() on the last ticket
         * buyer is okay, because the refund from destroying the
         * arrays decreases net gas cost
         */
        if (ticketsBought >= ticketMax) {
            sendReward();
        }

        return true;
    }

    /**
     * @dev Send lottery winner their reward
     * @return address of winner
     */
    function sendReward() private allTicketsSold returns (address) {
        uint256 winningNumber = lotteryPicker();
        address winner = ticketMapping[winningNumber];
        // Prevent locked funds by sending to bad address
        require(winner != address(0));
        // Prevent reentrancy
        reset();
        payable(winner).transfer(jackpot);
        emit LotteryAmountPaid(winner, winningNumber, jackpot);
        return winner;
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        ticketMapping
                    )
                )
            );
    }

    /* @return a random number based off of current block information */
    function lotteryPicker() public view allTicketsSold returns (uint256) {
        uint256 index = random() % ticketMapping.length;
        return index;
    }

    /* @dev Reset lottery mapping once a round is finished */
    function reset() private allTicketsSold returns (bool) {
        roundId += 1;
        ticketsBought = 0;
        jackpot = 0;
        for (uint256 x = 0; x < ticketMax + 1; x++) {
            delete ticketMapping[x];
        }
        return true;
    }

    /** @dev Returns ticket map array for front-end access.
     * Using a getter method is ineffective since it allows
     * only element-level access
     */
    function getTicketsPurchased() public view returns (address[51] memory) {
        return ticketMapping;
    }

    function getRoundId() public view returns (uint256) {
        return roundId;
    }

    function getJackpot() public view returns (uint256) {
        return jackpot;
    }
}