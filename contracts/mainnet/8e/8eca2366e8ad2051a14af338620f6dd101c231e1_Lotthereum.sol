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
        id = games[gameId].rounds.length;
        games[gameId].rounds.length += 1;
        games[gameId].rounds[id].id = id;
        games[gameId].rounds[id].open = true;
        RoundOpen(gameId, id);
    }

    function payout(uint gameId) internal {
        address[] winners = games[gameId].rounds[games[gameId].currentRound].winners;
        for (uint i = 0; i < games[gameId].maxNumberOfBets -1; i++) {
            if (games[gameId].rounds[games[gameId].currentRound].bets[i].bet == games[gameId].rounds[games[gameId].currentRound].number) {
                uint id = winners.length;
                winners.length += 1;
                winners[id] = games[gameId].rounds[games[gameId].currentRound].bets[i].origin;
            }
        }

        if (winners.length > 0) {
            uint prize = divide(games[gameId].prize, winners.length);
            for (i = 0; i < winners.length; i++) {
                balances[winners[i]] = add(balances[winners[i]], prize);
                RoundWinner(gameId, games[gameId].currentRound, winners[i], prize);
            }
        }
    }

    function closeRound(uint gameId) constant internal {
        games[gameId].rounds[games[gameId].currentRound].open = false;
        games[gameId].rounds[games[gameId].currentRound].hash = getBlockHash(games[gameId].pointer);
        games[gameId].rounds[games[gameId].currentRound].number = getNumber(games[gameId].rounds[games[gameId].currentRound].hash);
        // games[gameId].pointer = games[gameId].rounds[games[gameId].currentRound].number;
        payout(gameId);
        RoundClose(
            gameId,
            games[gameId].rounds[games[gameId].currentRound].id,
            games[gameId].rounds[games[gameId].currentRound].number
        );
        games[gameId].currentRound = createGameRound(gameId);
    }

    function getBlockHash(uint i) constant returns (bytes32 blockHash) {
        if (i > 255) {
            i = 255;
        }
        blockHash = block.blockhash(block.number - i);
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
        if (!games[gameId].rounds[games[gameId].currentRound].open) {
            return false;
        }

        if (msg.value < games[gameId].minAmountByBet) {
            return false;
        }

        if (games[gameId].rounds[games[gameId].currentRound].bets.length < games[gameId].maxNumberOfBets) {
            uint id = games[gameId].rounds[games[gameId].currentRound].bets.length;
            games[gameId].rounds[games[gameId].currentRound].bets.length += 1;
            games[gameId].rounds[games[gameId].currentRound].bets[id].id = id;
            games[gameId].rounds[games[gameId].currentRound].bets[id].round = games[gameId].rounds[games[gameId].currentRound].id;
            games[gameId].rounds[games[gameId].currentRound].bets[id].bet = bet;
            games[gameId].rounds[games[gameId].currentRound].bets[id].origin = msg.sender;
            games[gameId].rounds[games[gameId].currentRound].bets[id].amount = msg.value;
            BetPlaced(gameId, games[gameId].rounds[games[gameId].currentRound].id, msg.sender, id);
        }

        if (games[gameId].rounds[games[gameId].currentRound].bets.length >= games[gameId].maxNumberOfBets) {
            closeRound(gameId);
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
        if ((balances[msg.sender] > 0) && (balances[msg.sender] < this.balance)) {
            return balances[msg.sender];
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