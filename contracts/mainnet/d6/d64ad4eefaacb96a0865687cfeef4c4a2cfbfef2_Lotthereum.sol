pragma solidity ^0.4.11;

contract SafeMath {
    function add(uint x, uint y) internal constant returns (uint z) {
        assert((z = x + y) >= x);
    }
 
    function subtract(uint x, uint y) internal constant returns (uint z) {
        assert((z = x - y) <= x);
    }

    function multiply(uint x, uint y) internal constant returns (uint z) {
        z = x * y;
        assert(x == 0 || z / x == y);
        return z;
    }

    function divide(uint x, uint y) internal constant returns (uint z) {
        z = x / y;
        assert(x == ( (y * z) + (x % y) ));
        return z;
    }
    
    function min64(uint64 x, uint64 y) internal constant returns (uint64) {
        return x < y ? x: y;
    }
    
    function max64(uint64 x, uint64 y) internal constant returns (uint64) {
        return x >= y ? x : y;
    }

    function min(uint x, uint y) internal constant returns (uint) {
        return (x <= y) ? x : y;
    }

    function max(uint x, uint y) internal constant returns (uint) {
        return (x >= y) ? x : y;
    }

    function assert(bool assertion) internal {
        if (!assertion) {
            revert();
        }
    }
}


contract Owned {
    address owner;

    modifier onlyowner() {
        if (msg.sender == owner) {
            _;
        }
    }

    function Owned() {
        owner = msg.sender;
    }
}


contract Mortal is Owned {
    
    function kill() {
        if (msg.sender == owner)
            selfdestruct(owner);
    }
}


contract Lotthereum is Mortal, SafeMath {
    Game[] private games;
    mapping (address => uint) private balances;  // balances per address

    struct Game {
        uint id;
        uint pointer;
        uint maxNumberOfBets;
        uint minAmountByBet;
        uint prize;
        uint currentRound;
        Round[] rounds;
    }

    struct Round {
        uint id;
        uint pointer;
        bytes32 hash;
        bool open;
        uint8 number;
        Bet[] bets;
        address[] winners;
    }

    struct Bet {
        uint id;
        address origin;
        uint amount;
        uint8 bet;
        uint round;
    }

    event RoundOpen(
        uint indexed gameId,
        uint indexed roundId
    );
    event RoundClose(
        uint indexed gameId,
        uint indexed roundId,
        uint8 number
    );
    event MaxNumberOfBetsChanged(
        uint maxNumberOfBets
    );
    event MinAmountByBetChanged(
        uint minAmountByBet
    );
    event BetPlaced(
        uint indexed gameId,
        uint indexed roundId,
        address indexed origin,
        uint betId
    );
    event RoundWinner(
        uint indexed gameId,
        uint indexed roundId,
        address indexed winnerAddress,
        uint amount
    );

    function createGame(
        uint pointer,
        uint maxNumberOfBets,
        uint minAmountByBet,
        uint prize
    ) onlyowner returns (uint id) {
        id = games.length;
        games.length += 1;
        games[id].id = id;
        games[id].pointer = pointer;
        games[id].maxNumberOfBets = maxNumberOfBets;
        games[id].minAmountByBet = minAmountByBet;
        games[id].prize = prize;
        games[id].currentRound = createGameRound(id);
    }

    function createGameRound(uint gameId) internal returns (uint id) {
        Game game = games[gameId];
        id = games[gameId].rounds.length;
        game.rounds.length += 1;
        game.rounds[id].id = id;
        game.rounds[id].open = true;
        RoundOpen(gameId, id);
    }

    function payout(uint gameId) internal {
        Game game = games[gameId];
        Round round = game.rounds[game.currentRound];
        Bet[] bets = round.bets;
        address[] winners = round.winners;
        for (uint i = 0; i < bets.length; i++) {
            if (bets[i].bet == round.number) {
                uint id = winners.length;
                winners.length += 1;
                winners[id] = bets[i].origin;
            }
        }

        if (winners.length > 0) {
            uint prize = divide(game.prize, winners.length);
            for (i = 0; i < winners.length; i++) {
                balances[winners[i]] = add(balances[winners[i]], prize);
                RoundWinner(game.id, game.currentRound, winners[i], prize);
            }
        }
    }

    function closeRound(uint gameId) constant internal {
        Game game = games[gameId];
        Round round = game.rounds[game.currentRound];
        round.open = false;
        round.hash = getBlockHash(game.pointer);
        round.number = getNumber(game.rounds[game.currentRound].hash);
        game.pointer = game.rounds[game.currentRound].number;
        payout(gameId);
        RoundClose(game.id, round.id, round.number);
        game.currentRound = createGameRound(game.id);
    }

    function getBlockHash(uint i) constant returns (bytes32 blockHash) {
        if (i > 255) {
            i = 255;
        }
        uint blockNumber = block.number - i;
        blockHash = block.blockhash(blockNumber);
    }

    function getNumber(bytes32 _a) constant returns (uint8) {
        uint8 _b = 1;
        uint8 mint = 0;
        bool decimals = false;
        for (uint i = _a.length - 1; i >= 0; i--) {
            if ((_a[i] >= 48) && (_a[i] <= 57)) {
                if (decimals) {
                    if (_b == 0) {
                        break;
                    } else {
                        _b--;
                    }
                }
                mint *= 10;
                mint += uint8(_a[i]) - 48;
                return mint;
            } else if (_a[i] == 46) {
                decimals = true;
            }
        }
        return mint;
    }

    function placeBet(uint gameId, uint8 bet) public payable returns (bool) {
        Game game = games[gameId];
        Round round = game.rounds[game.currentRound];
        Bet[] bets = round.bets;

        if (!round.open) {
            return false;
        }

        if (msg.value < game.minAmountByBet) {
            return false;
        }

        uint id = bets.length;
        bets.length += 1;
        bets[id].id = id;
        bets[id].round = round.id;
        bets[id].bet = bet;
        bets[id].origin = msg.sender;
        bets[id].amount = msg.value;
        BetPlaced(game.id, round.id, msg.sender, id);

        if (bets.length == game.maxNumberOfBets) {
            closeRound(game.id);
        }

        return true;
    }

    function withdraw() public returns (uint) {
        uint amount = getBalance();
        if (amount > 0) {
            balances[msg.sender] = 0;
            msg.sender.transfer(amount);
            return amount;
        }
        return 0;
    }

    function getBalance() constant returns (uint) {
        uint amount = balances[msg.sender];
        if ((amount > 0) && (amount < this.balance)) {
            return amount;
        }
        return 0;
    }

    function getGames() constant returns(uint[] memory ids) {
        ids = new uint[](games.length);
        for (uint i = 0; i < games.length; i++) {
            ids[i] = games[i].id;
        }
    }

    function getGameCurrentRoundId(uint gameId) constant returns(uint) {
        return games[gameId].currentRound;
    }

    function getGameRoundOpen(uint gameId, uint roundId) constant returns(bool) {
        return games[gameId].rounds[roundId].open;
    }

    function getGameMaxNumberOfBets(uint gameId) constant returns(uint) {
        return games[gameId].maxNumberOfBets;
    }

    function getGameMinAmountByBet(uint gameId) constant returns(uint) {
        return games[gameId].minAmountByBet;
    }

    function getGamePrize(uint gameId) constant returns(uint) {
        return games[gameId].prize;
    }

    function getRoundNumberOfBets(uint gameId, uint roundId) constant returns(uint) {
        return games[gameId].rounds[roundId].bets.length;
    }

    function getRoundBetOrigin(uint gameId, uint roundId, uint betId) constant returns(address) {
        return games[gameId].rounds[roundId].bets[betId].origin;
    }

    function getRoundBetAmount(uint gameId, uint roundId, uint betId) constant returns(uint) {
        return games[gameId].rounds[roundId].bets[betId].amount;
    }

    function getRoundBetNumber(uint gameId, uint roundId, uint betId) constant returns(uint) {
        return games[gameId].rounds[roundId].bets[betId].bet;
    }

    function getRoundNumber(uint gameId, uint roundId) constant returns(uint8) {
        return games[gameId].rounds[roundId].number;
    }

    function getRoundPointer(uint gameId, uint roundId) constant returns(uint) {
        return games[gameId].rounds[roundId].pointer;
    }

    function getPointer(uint gameId) constant returns(uint) {
        return games[gameId].pointer;
    }

    function () payable {
    }
}