pragma solidity ^0.4.18;

interface Game {
    event GameStarted(uint betAmount);
    event NewPlayerAdded(uint numPlayers, uint prizeAmount);
    event GameFinished(address winner);

    function () public payable;                                   //Participate in game. Proxy for play method
    function getPrizeAmount() public constant returns (uint);     //Get potential or actual prize amount
    function getNumWinners() public constant returns(uint, uint);
    function getPlayers() public constant returns(address[]);           //Get full list of players
    function getWinners() public view returns(address[] memory players,
                                                uint[] memory prizes);  //Get winners. Accessable only when finished
    function getStat() public constant returns(uint, uint, uint);       //Short stat on game

    function calcaultePrizes() public returns (uint[]);

    function finish() public;                        //Closes game chooses winner

    function revoke() public;                        //Stop game and return money to players
    // function move(address nextGame);              //Move players bets to another game
}

library TicketLib {
    struct Ticket {
        uint40 block_number;
        uint32 block_time;
        uint prize;
    }
}

contract UnilotPrizeCalculator {
    //Calculation constants
    uint64  constant accuracy                   = 1000000000000000000;
    uint8  constant MAX_X_FOR_Y                = 195;  // 19.5

    uint8  constant minPrizeCoeficent          = 1;
    uint8  constant percentOfWinners           = 5;    // 5%
    uint8  constant percentOfFixedPrizeWinners = 20;   // 20%

    uint8  constant gameCommision              = 0;   // 0%
    uint8  constant bonusGameCommision         = 0;   // 0%
    uint8  constant tokenHolerGameCommision    = 0;    // 0%
    // End Calculation constants

    event Debug(uint);

    function getPrizeAmount(uint totalAmount)
        public
        pure
        returns (uint result)
    {
        uint totalCommision = gameCommision
                            + bonusGameCommision
                            + tokenHolerGameCommision;

        //Calculation is odd on purpose.  It is a sort of ceiling effect to
        // maximize amount of prize
        result = ( totalAmount - ( ( totalAmount * totalCommision) / 100) );

        return result;
    }

    function getNumWinners(uint numPlayers)
        public
        pure
        returns (uint16 numWinners, uint16 numFixedAmountWinners)
    {
        // Calculation is odd on purpose. It is a sort of ceiling effect to
        // maximize number of winners
        uint16 totaNumlWinners = uint16( numPlayers - ( (numPlayers * ( 100 - percentOfWinners ) ) / 100 ) );


        numFixedAmountWinners = uint16( (totaNumlWinners * percentOfFixedPrizeWinners) / 100 );
        numWinners = uint16( totaNumlWinners - numFixedAmountWinners );

        return (numWinners, numFixedAmountWinners);
    }

    function calcaultePrizes(uint bet, uint numPlayers)
        public
        pure
        returns (uint[50] memory prizes)
    {
        var (numWinners, numFixedAmountWinners) = getNumWinners(numPlayers);

        require( uint(numWinners + numFixedAmountWinners) <= prizes.length );

        uint[] memory y = new uint[]((numWinners - 1));
        uint z = 0; // Sum of all Y values

        if ( numWinners == 1 ) {
            prizes[0] = getPrizeAmount(uint(bet*numPlayers));

            return prizes;
        } else if ( numWinners < 1 ) {
            return prizes;
        }

        for (uint i = 0; i < y.length; i++) {
            y[i] = formula( (calculateStep(numWinners) * i) );
            z += y[i];
        }

        bool stop = false;

        for (i = 0; i < 10; i++) {
            uint[5] memory chunk = distributePrizeCalculation(
                i, z, y, numPlayers, bet);

            for ( uint j = 0; j < chunk.length; j++ ) {
                if ( ( (i * chunk.length) + j ) >= ( numWinners + numFixedAmountWinners ) ) {
                    stop = true;
                    break;
                }

                prizes[ (i * chunk.length) + j ] = chunk[j];
            }

            if ( stop ) {
                break;
            }
        }

        return prizes;
    }

    function distributePrizeCalculation (uint chunkNumber, uint z, uint[] memory y, uint totalNumPlayers, uint bet)
        private
        pure
        returns (uint[5] memory prizes)
    {
        var(numWinners, numFixedAmountWinners) = getNumWinners(totalNumPlayers);
        uint prizeAmountForDeligation = getPrizeAmount( (totalNumPlayers * bet) );
        prizeAmountForDeligation -= uint( ( bet * minPrizeCoeficent ) * uint( numWinners + numFixedAmountWinners ) );

        uint mainWinnerBaseAmount = ( (prizeAmountForDeligation * accuracy) / ( ( ( z * accuracy ) / ( 2 * y[0] ) ) + ( 1 * accuracy ) ) );
        uint undeligatedAmount    = prizeAmountForDeligation;

        uint startPoint = chunkNumber * prizes.length;

        for ( uint i = 0; i < prizes.length; i++ ) {
            if ( i >= uint(numWinners + numFixedAmountWinners) ) {
                break;
            }
            prizes[ i ] = (bet * minPrizeCoeficent);
            uint extraPrize = 0;

            if ( i == ( numWinners - 1 ) ) {
                extraPrize = undeligatedAmount;
            } else if ( i == 0 && chunkNumber == 0 ) {
                extraPrize = mainWinnerBaseAmount;
            } else if ( ( startPoint + i ) < numWinners ) {
                extraPrize = ( ( y[ ( startPoint + i ) - 1 ] * (prizeAmountForDeligation - mainWinnerBaseAmount) ) / z);
            }

            prizes[ i ] += extraPrize;
            undeligatedAmount -= extraPrize;
        }

        return prizes;
    }

    function formula(uint x)
        public
        pure
        returns (uint y)
    {
        y = ( (1 * accuracy**2) / (x + (5*accuracy/10))) - ((5 * accuracy) / 100);

        return y;
    }

    function calculateStep(uint numWinners)
        public
        pure
        returns(uint step)
    {
        step = ( MAX_X_FOR_Y * accuracy / 10 ) / numWinners;

        return step;
    }
}

contract BaseUnilotGame is Game {
    enum State {
        ACTIVE,
        ENDED,
        REVOKING,
        REVOKED,
        MOVED
    }

    event PrizeResultCalculated(uint size, uint[] prizes);

    State state;
    address administrator;
    uint bet;

    mapping (address => TicketLib.Ticket) internal tickets;
    address[] internal ticketIndex;

    UnilotPrizeCalculator calculator;

    //Modifiers
    modifier onlyAdministrator() {
        require(msg.sender == administrator);
        _;
    }

    modifier onlyPlayer() {
        require(msg.sender != administrator);
        _;
    }

    modifier validBet() {
        require(msg.value == bet);
        _;
    }

    modifier activeGame() {
        require(state == State.ACTIVE);
        _;
    }

    modifier inactiveGame() {
        require(state != State.ACTIVE);
        _;
    }

    modifier finishedGame() {
        require(state == State.ENDED);
        _;
    }

    //Private methods

    function getState()
        public
        view
        returns(State)
    {
        return state;
    }

    function getBet()
        public
        view
        returns (uint)
    {
        return bet;
    }

    function getPlayers()
        public
        constant
        returns(address[])
    {
        return ticketIndex;
    }

    function getPlayerDetails(address player)
        public
        view
        inactiveGame
        returns (uint, uint, uint)
    {
        TicketLib.Ticket memory ticket = tickets[player];

        return (ticket.block_number, ticket.block_time, ticket.prize);
    }

    function getNumWinners()
        public
        constant
        returns (uint, uint)
    {
        var(numWinners, numFixedAmountWinners) = calculator.getNumWinners(ticketIndex.length);

        return (numWinners, numFixedAmountWinners);
    }

    function getPrizeAmount()
        public
        constant
        returns (uint result)
    {
        uint totalAmount = this.balance;

        if ( state == State.ENDED ) {
            totalAmount = bet * ticketIndex.length;
        }

        result = calculator.getPrizeAmount(totalAmount);

        return result;
    }

    function getStat()
        public
        constant
        returns ( uint, uint, uint )
    {
        var (numWinners, numFixedAmountWinners) = getNumWinners();
        return (ticketIndex.length, getPrizeAmount(), uint(numWinners + numFixedAmountWinners));
    }

    function calcaultePrizes()
        public
        returns(uint[] memory result)
    {
        var(numWinners, numFixedAmountWinners) = getNumWinners();
        uint16 totalNumWinners = uint16( numWinners + numFixedAmountWinners );
        result = new uint[]( totalNumWinners );


        uint[50] memory prizes = calculator.calcaultePrizes(
        bet, ticketIndex.length);

        for (uint16 i = 0; i < totalNumWinners; i++) {
            result[i] = prizes[i];
        }

        return result;
    }

    function revoke()
        public
        onlyAdministrator
        activeGame
    {
        for (uint24 i = 0; i < ticketIndex.length; i++) {
            ticketIndex[i].transfer(bet);
        }

        state = State.REVOKED;
    }
}

contract UnilotTailEther is BaseUnilotGame {

    uint64 winnerIndex;

    //Public methods
    function UnilotTailEther(uint betAmount, address calculatorContractAddress)
        public
    {
        state = State.ACTIVE;
        administrator = msg.sender;
        bet = betAmount;

        calculator = UnilotPrizeCalculator(calculatorContractAddress);

        GameStarted(betAmount);
    }

    function getWinners()
        public
        view
        finishedGame
        returns(address[] memory players, uint[] memory prizes)
    {
        var(numWinners, numFixedAmountWinners) = getNumWinners();
        uint totalNumWinners = numWinners + numFixedAmountWinners;

        players = new address[](totalNumWinners);
        prizes = new uint[](totalNumWinners);

        uint index;

        for (uint i = 0; i < totalNumWinners; i++) {
            if ( i > winnerIndex ) {
                index = ( ( players.length ) - ( i - winnerIndex ) );
            } else {
                index = ( winnerIndex - i );
            }

            players[i] = ticketIndex[index];
            prizes[i] = tickets[players[i]].prize;
        }

        return (players, prizes);
    }

    function ()
        public
        payable
        validBet
        onlyPlayer
    {
        require(tickets[msg.sender].block_number == 0);
        require(ticketIndex.length <= 1000);

        tickets[msg.sender].block_number = uint40(block.number);
        tickets[msg.sender].block_time   = uint32(block.timestamp);

        ticketIndex.push(msg.sender);

        NewPlayerAdded(ticketIndex.length, getPrizeAmount());
    }

    function finish()
        public
        onlyAdministrator
        activeGame
    {
        uint64 max_votes;
        uint64[] memory num_votes = new uint64[](ticketIndex.length);

        for (uint i = 0; i < ticketIndex.length; i++) {
            TicketLib.Ticket memory ticket = tickets[ticketIndex[i]];
            uint64 vote = uint64( ( ( ticket.block_number * ticket.block_time ) + uint( ticketIndex[i]) ) % ticketIndex.length );

            num_votes[vote] += 1;

            if ( num_votes[vote] > max_votes ) {
                max_votes = num_votes[vote];
                winnerIndex = vote;
            }
        }

        uint[] memory prizes = calcaultePrizes();

        uint lastId = winnerIndex;

        for ( i = 0; i < prizes.length; i++ ) {
            tickets[ticketIndex[lastId]].prize = prizes[i];
            ticketIndex[lastId].transfer(prizes[i]);

            if ( lastId <= 0 ) {
                lastId = ticketIndex.length;
            }

            lastId -= 1;
        }

        administrator.transfer(this.balance);

        state = State.ENDED;

        GameFinished(ticketIndex[winnerIndex]);
    }
}

contract UnilotBonusTailEther is BaseUnilotGame {
    mapping (address => TicketLib.Ticket[]) public tickets;
    mapping (address => uint) _prize;

    uint16 numTickets;

    uint64 winnerIndex;

    function UnilotBonusTailEther(address calculatorContractAddress)
        public
        payable
    {
        state = State.ACTIVE;
        administrator = msg.sender;

        calculator = UnilotPrizeCalculator(calculatorContractAddress);

        GameStarted(0);
    }

    function importPlayers(address game, address[] players)
        public
        onlyAdministrator
    {
        UnilotTailEther _game = UnilotTailEther(game);

        for (uint8 i = 0; i < uint8(players.length); i++) {
            TicketLib.Ticket memory ticket;

            var(block_number, block_time, prize) = _game.getPlayerDetails(players[i]);

            if (prize > 0) {
                continue;
            }

            ticket.block_number = uint40(block_number);
            ticket.block_time = uint32(block_time);

            if ( tickets[players[i]].length == 0 ) {
                ticketIndex.push(players[i]);
            }

            tickets[players[i]].push(ticket);
            numTickets++;
        }
    }

    function getPlayerDetails(address player)
        public
        view
        inactiveGame
        returns (uint, uint, uint)
    {
        player;

        return (0, 0, 0);
    }

    function ()
        public
        payable
        onlyAdministrator
    {

    }

    function getPrizeAmount()
        public
        constant
        returns (uint result)
    {
        return this.balance;
    }

    function calcaultePrizes()
        public
        returns(uint[] memory result)
    {
        var(numWinners, numFixedAmountWinners) = getNumWinners();
        uint16 totalNumWinners = uint16( numWinners + numFixedAmountWinners );
        result = new uint[]( totalNumWinners );


        uint[50] memory prizes = calculator.calcaultePrizes(
            getPrizeAmount()/ticketIndex.length, ticketIndex.length);

        for (uint16 i = 0; i < totalNumWinners; i++) {
            result[i] = prizes[i];
        }

        return result;
    }

    function getWinners()
        public
        view
        finishedGame
        returns(address[] memory players, uint[] memory prizes)
    {
        var(numWinners, numFixedAmountWinners) = getNumWinners();
        uint totalNumWinners = numWinners + numFixedAmountWinners;

        players = new address[](totalNumWinners);
        prizes = new uint[](totalNumWinners);

        uint index;

        for (uint i = 0; i < totalNumWinners; i++) {
            if ( i > winnerIndex ) {
                index = ( ( players.length ) - ( i - winnerIndex ) );
            } else {
                index = ( winnerIndex - i );
            }

            players[i] = ticketIndex[index];
            prizes[i] = _prize[players[i]];
        }

        return (players, prizes);
    }

    function finish()
        public
        onlyAdministrator
        activeGame
    {
        uint64 max_votes;
        uint64[] memory num_votes = new uint64[](ticketIndex.length);

        for (uint i = 0; i < ticketIndex.length; i++) {
            for (uint8 j = 0; j < tickets[ticketIndex[i]].length; j++) {
                TicketLib.Ticket memory ticket = tickets[ticketIndex[i]][j];

                uint64 vote = uint64( ( ( ( ticket.block_number * ticket.block_time ) / numTickets ) + (((block.number/2) * now) / (numTickets/2)) + uint( ticketIndex[i]) ) % ticketIndex.length );

                num_votes[vote] += 1;

                if ( num_votes[vote] > max_votes ) {
                    max_votes = num_votes[vote];
                    winnerIndex = vote;
                }
            }
        }

        uint[] memory prizes = calcaultePrizes();

        uint lastId = winnerIndex;

        for ( i = 0; i < prizes.length; i++ ) {
            _prize[ticketIndex[lastId]] = prizes[i];
            ticketIndex[lastId].transfer(prizes[i]);

            if ( lastId <= 0 ) {
                lastId = ticketIndex.length;
            }

            lastId -= 1;
        }

        administrator.transfer(this.balance); //For case of misscalculation

        state = State.ENDED;

        GameFinished(ticketIndex[winnerIndex]);
    }

    function revoke()
        public
        onlyAdministrator
        activeGame
    {
        administrator.transfer(this.balance);

        state = State.REVOKED;
    }
}