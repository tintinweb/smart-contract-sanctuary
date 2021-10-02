/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/// @author maxdanify
/// @title A simple lottery game
contract Lottery {

    address public organizer;

    // parameters of the lottery
    uint public ticketPrice = 20_000_000_000_000_000;
    uint public lotteryTimeInterval = 1 days;

    // Allowed withdrawals of previous lottery winners
    mapping(address => uint) public pendingReturns;
    uint pendingReturnsTotal = 0;

    // Participants of the current lottery round
    struct Participant {
        uint id;
        uint32 ticketCount;
    }

    address[] participantAddresses;
    mapping(address => Participant) public participants;

    // Current lottery status
    address[] tickets;
    uint32 public ticketCount = 0;
    uint public lotteryEndTime;
    uint public prizePool = 0;
    uint public nextPrizePool = 0;

    modifier isOrganizer() {
        require(msg.sender == organizer, "Caller is not organizer");
        _;
    }

    /// Lottery ends and winner is defined
    event Win(address indexed _winner, uint _prize);

    /// Buy tickets
    event Buy(address indexed _participant, uint32 _amount);

    /// Claim rewards
    event Claim(address indexed _to, uint _amount);

    /// The lottery has not ended yet.
    error LotteryNotYetEnded();

    /**
     * @dev Set contract deployer as organizer
     */
    constructor() {
        organizer = msg.sender;
        lotteryEndTime = block.timestamp + lotteryTimeInterval;
    }

    receive() external payable {}

    /// organizer can set the new ticket price
    function setTicketPrice(uint newPrice) public isOrganizer {
        ticketPrice = newPrice;
    }

    function setLotteryTimeInterval(uint newLotteryTimeInterval) public isOrganizer {
        lotteryTimeInterval = newLotteryTimeInterval;
    }

    function withdrawIncome(address addr) public isOrganizer {
        uint totalReturns = prizePool + pendingReturnsTotal;
        require(address(this).balance - totalReturns > 0);
        payable(addr).transfer(address(this).balance - totalReturns);
    }

    function buy(uint32 ticketsNum) payable public {
        require(msg.value >= ticketsNum * ticketPrice, "Insufficient amount");

        uint addPrizeValue = ticketsNum * ticketPrice;

        // refund excessive values
        if (msg.value > ticketPrice) {
            uint refund = msg.value - addPrizeValue;
            payable(msg.sender).transfer(refund);
        }

        Participant storage person = participants[msg.sender];

        // register new participant if he does not exist
        if (person.id == 0) {
            participantAddresses.push(msg.sender);
            person.id = participantAddresses.length;
            person.ticketCount = 0;
        }

        person.ticketCount += ticketsNum;

        for (uint32 i = 0; i < ticketsNum; i++) {
            tickets.push(msg.sender);
            ticketCount++;
        }

        uint value = addPrizeValue * 9 / 10;
        uint prizeValue = addPrizeValue * 8 / 10;
        prizePool += prizeValue;
        nextPrizePool += value - prizeValue;

        emit Buy(msg.sender, ticketsNum);
    }

    /// called by anyone to end the lottery
    function lotteryEnd() public {
        if (block.timestamp < lotteryEndTime)
            revert LotteryNotYetEnded();

        if (participantAddresses.length > 0) {
            address winner = chooseWinner();
            emit Win(winner, prizePool);
            pendingReturns[winner] += prizePool;
            pendingReturnsTotal += prizePool;

            prizePool = nextPrizePool;
            delete nextPrizePool;
        }

        lotteryEndTime = block.timestamp + lotteryTimeInterval;

        for (uint32 i = 0; i < participantAddresses.length; i++) {
            delete participants[participantAddresses[i]];
        }
        delete participantAddresses;
        delete tickets;
        delete ticketCount;
    }

    /// Withdraw a prize if exists.
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receivin.g call
            // before `send` returns.
            pendingReturns[msg.sender] = 0;
            pendingReturnsTotal -= amount;

            if (!payable(msg.sender).send(amount)) {
                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                pendingReturnsTotal += amount;
                return false;
            }

            emit Claim(msg.sender, amount);
        }
        return true;
    }

    function chooseWinner() private view returns (address) {
        uint luckyTicket = random() % ticketCount;
        return tickets[luckyTicket];
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participantAddresses)));
    }
}