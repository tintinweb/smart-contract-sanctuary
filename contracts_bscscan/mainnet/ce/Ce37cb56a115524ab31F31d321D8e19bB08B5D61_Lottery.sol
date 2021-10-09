/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Lottery on Chains
 * @author maxdanify
 * @notice Contract implements a lottery game with only one winner
 */
contract Lottery {
    // Lottery agent and beneficiary
    address public organizer;

    /// @dev (STARTED) -> closeGame -> (CLOSED) -> endGame -> (STARTED)
    /// @dev Game can be closed only if the time is over,
    /// @dev at this point players can't buy a new tickets
    /// @dev So this time is used to generate a random number,
    /// @dev thereby choose a winner ticket.
    /// @dev Once it is done state changes to CLOSED
    enum GameState {
        STARTED,
        CLOSED
    }
    GameState public state = GameState.STARTED;

    // Contains all game parameters and rules
    struct Game {
        // Ticket price in wei
        uint256 ticketPrice;
        // Game time period
        uint256 gameTime;
        // The percentage of sales returned to the players in the form of prize
        uint256 prizePayout;
        // The money from sales that will be used to pay prize
        uint256 prizePool;
    }

    // Partnership with a lottery
    address public partner;
    // The percentage of sales provided to a lottery partner
    uint256 public commission;

    // Parameters for the current and next games.
    // Organizer can only change the rules for the next game
    // current game rules are immutable
    Game public next;
    Game public current;

    // Allowed withdrawals of previous lottery winners
    mapping(address => uint256) public unclaimedPrizes;
    uint256 unclaimedPrizesTotal = 0;

    // Participant info
    struct Participant {
        // Unique id assigned on first buy
        uint256 id;
        // Number of tickets
        uint32 tickets;
    }

    // Participants of the current game
    address[] participantAddresses;
    mapping(address => Participant) public participants;

    // Sold tickets
    address[] tickets;
    // Number of sold tickets in current game
    uint32 public soldTickets = 0;
    // The date when the current game will end and the new will be started
    uint256 public gameEndDate;

    modifier isOrganizer() {
        require(msg.sender == organizer, "Caller is not organizer");
        _;
    }

    /// Game ends and winner is defined
    event Win(address indexed _winner, uint256 _prize);

    /// Buy tickets
    event Buy(address indexed _participant, uint32 _amount);

    /// Claim rewards
    event Claim(address indexed _to, uint256 _amount);

    /// New partnership is established
    event Partnership(address indexed _partner, uint256 _commission);

    /// The game has not closed yet.
    error GameNotYetClosed();

    /// @dev Set contract deployer as organizer
    constructor() {
        organizer = msg.sender;
        current = Game(10_000_000_000_000_000, 1 days, 90, 0);
        next = current;
        gameEndDate = block.timestamp + current.gameTime;
    }

    receive() external payable {}

    /// @notice organizer can set the new ticket price for the next game
    /// @param _ticketPrice new ticket price in wei
    function setTicketPrice(uint256 _ticketPrice) public isOrganizer {
        next.ticketPrice = _ticketPrice;
    }

    /// @notice organizer can change the time period for the next game
    /// @param _gameTime new time period for next game
    function setGameTime(uint256 _gameTime) public isOrganizer {
        require(_gameTime <= 30 days);
        next.gameTime = _gameTime;
    }

    /// @notice organizer can change the prize payout for the next game
    /// @param _prizePayout new prize payout (% received by players) for next game
    function setPrizePayout(uint256 _prizePayout) public isOrganizer {
        require(_prizePayout <= 100);
        next.prizePayout = _prizePayout;
    }

    /// @notice organizer can set the partner and his commission
    /// @param _partner address
    /// @param _commission partner commission in %
    function setPartner(address _partner, uint256 _commission)
        public
        isOrganizer
    {
        require(_commission <= 100);
        partner = _partner;
        commission = _commission;
        emit Partnership(partner, commission);
    }

    /// @notice organizer can take the profit
    /// @param _address address where to transfer profit
    function withdrawProfit(address _address) public isOrganizer {
        require(profit() > 0);
        payable(_address).transfer(profit());
    }

    /// @return current organizer profit
    function profit() public view returns (uint256) {
        if (address(this).balance - withholdings() < 0) {
            return 0;
        }
        return address(this).balance - withholdings();
    }

    /// @notice Returns the amounts required to be subtracted from a balance
    /// @notice to cover payments
    ///
    /// @return withholdings
    function withholdings() internal view returns (uint256) {
        return current.prizePool + next.prizePool + unclaimedPrizesTotal;
    }

    /// @notice anyone can buy a tickets
    /// @param _amount number of tickets to buy
    function buy(uint32 _amount) public payable {
        require(block.timestamp < gameEndDate, "Game is closed");
        require(
            msg.value >= _amount * current.ticketPrice,
            "Insufficient amount"
        );

        uint256 totalPrice = _amount * current.ticketPrice;

        // refund excessive values
        if (msg.value > totalPrice) {
            uint256 refund = msg.value - totalPrice;
            payable(msg.sender).transfer(refund);
        }

        Participant storage participant = participants[msg.sender];

        // register new participant if he/she does not exist
        if (participant.id == 0) {
            participantAddresses.push(msg.sender);
            participant.id = participantAddresses.length;
            participant.tickets = 0;
        }

        participant.tickets += _amount;

        for (uint32 i = 0; i < _amount; i++) {
            tickets.push(msg.sender);
            soldTickets++;
        }

        uint256 payout = (totalPrice * current.prizePayout) / 100;
        if (partner != address(0)) {
            // partner gets % (commission) of the profit
            uint256 incentives = ((totalPrice - payout) * commission) / 100;
            unclaimedPrizes[partner] += incentives;
            unclaimedPrizesTotal += incentives;
        }

        uint256 nextPayout = (payout * 10) / 100;
        current.prizePool += payout - nextPayout;
        next.prizePool += nextPayout;

        emit Buy(msg.sender, _amount);
    }

    /// @dev this method should be overriden with true RNG implementation
    function closeGame() public virtual {
        require(block.timestamp >= gameEndDate);

        state = GameState.CLOSED;
        endGame();
    }

    /// @notice anyone can end the game, but only if the game is closed
    function endGame() public {
        if (state != GameState.CLOSED) revert GameNotYetClosed();

        if (participantAddresses.length > 0) {
            address winner = draw();
            unclaimedPrizes[winner] += current.prizePool;
            unclaimedPrizesTotal += current.prizePool;

            emit Win(winner, current.prizePool);
        } else {
            next.prizePool += current.prizePool;
        }

        current = next;
        next.prizePool = 0;

        gameEndDate = block.timestamp + current.gameTime;
        state = GameState.STARTED;

        for (uint32 i = 0; i < participantAddresses.length; i++) {
            delete participants[participantAddresses[i]];
        }
        delete participantAddresses;
        // all tickets are burned after game is ended
        delete tickets;
        delete soldTickets;
    }

    /// @notice Players can claim prize if they have a winner tickets
    function claim() public returns (bool) {
        uint256 prize = unclaimedPrizes[msg.sender];
        if (prize > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receivin.g call
            // before `send` returns.
            unclaimedPrizes[msg.sender] = 0;
            unclaimedPrizesTotal -= prize;

            if (!payable(msg.sender).send(prize)) {
                // No need to call throw here, just reset the amount owing
                unclaimedPrizes[msg.sender] = prize;
                unclaimedPrizesTotal += prize;
                return false;
            }

            emit Claim(msg.sender, prize);
        }
        return true;
    }

    /// @notice Select winner
    function draw() internal view returns (address) {
        uint256 luckyTicket = random() % soldTickets;
        return tickets[luckyTicket];
    }

    /// @notice Generate random number
    function random() internal view virtual returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        participantAddresses
                    )
                )
            );
    }
}