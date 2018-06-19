pragma solidity ^0.4.16;


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


contract Slotthereum is Mortal {

    Game[] public games;                              // games
    uint public numberOfGames = 0;                    // number of games
    uint private minBetAmount = 100000000000000;      // minimum amount per bet
    uint private maxBetAmount = 1000000000000000000;  // maximum amount per bet
    uint8 private pointer = 1;                        // block pointer

    struct Game {
        address player;
        uint id;
        uint amount;
        uint8 start;
        uint8 end;
        bytes32 hash;
        uint8 number;
        bool win;
        uint prize;
    }

    event MinBetAmountChanged(uint amount);
    event MaxBetAmountChanged(uint amount);
    event PointerChanged(uint8 value);

    event GameRoll(
        address indexed player,
        uint indexed gameId,
        uint8 start,
        uint8 end,
        uint amount
    );

    event GameWin(
        address indexed player,
        uint indexed gameId,
        uint8 start,
        uint8 end,
        uint8 number,
        uint amount,
        uint prize
    );

    event GameLoose(
        address indexed player,
        uint indexed gameId,
        uint8 start,
        uint8 end,
        uint8 number,
        uint amount,
        uint prize
    );

    function notify(address player, uint gameId, uint8 start, uint8 end, uint8 number, uint amount, uint prize, bool win) internal {
        if (win) {
            GameWin(
                player,
                gameId,
                start,
                end,
                number,
                amount,
                prize
            );
        } else {
            GameLoose(
                player,
                gameId,
                start,
                end,
                number,
                amount,
                prize
            );
        }
    }

    function getBlockHash(uint i) internal constant returns (bytes32 blockHash) {
        if (i > 255) {
            i = 255;
        }
        if (i < 0) {
            i = 1;
        }
        blockHash = block.blockhash(block.number - i);
    }

    function getNumber(bytes32 _a) internal constant returns (uint8) {
        uint8 mint = pointer;
        for (uint i = 31; i >= 1; i--) {
            if ((uint8(_a[i]) >= 48) && (uint8(_a[i]) <= 57)) {
                return uint8(_a[i]) - 48;
            }
        }
        return mint;
    }

    function placeBet(uint8 start, uint8 end) public payable returns (bool) {
        if (msg.value < minBetAmount) {
            return false;
        }

        if (msg.value > maxBetAmount) {
            return false;
        }

        uint8 counter = end - start + 1;

        if (counter > 7) {
            return false;
        }

        if (counter < 1) {
            return false;
        }

        uint gameId = games.length;
        games.length++;
        numberOfGames++;

        GameRoll(msg.sender, gameId, start, end, msg.value);

        games[gameId].id = gameId;
        games[gameId].player = msg.sender;
        games[gameId].amount = msg.value;
        games[gameId].start = start;
        games[gameId].end = end;
        games[gameId].hash = getBlockHash(pointer);
        games[gameId].number = getNumber(games[gameId].hash);
        pointer = games[gameId].number;

        if ((games[gameId].number >= start) && (games[gameId].number <= end)) {
            games[gameId].win = true;
            uint dec = msg.value / 10;
            uint parts = 10 - counter;
            games[gameId].prize = msg.value + dec * parts;
        } else {
            games[gameId].prize = 1;
        }

        msg.sender.transfer(games[gameId].prize);

        notify(
            msg.sender,
            gameId,
            start,
            end,
            games[gameId].number,
            msg.value,
            games[gameId].prize,
            games[gameId].win
        );

        return true;
    }

    function withdraw(uint amount) onlyowner returns (uint) {
        if (amount <= this.balance) {
            msg.sender.transfer(amount);
            return amount;
        }
        return 0;
    }

    function setMinBetAmount(uint _minBetAmount) onlyowner returns (uint) {
        minBetAmount = _minBetAmount;
        MinBetAmountChanged(minBetAmount);
        return minBetAmount;
    }

    function setMaxBetAmount(uint _maxBetAmount) onlyowner returns (uint) {
        maxBetAmount = _maxBetAmount;
        MaxBetAmountChanged(maxBetAmount);
        return maxBetAmount;
    }

    function setPointer(uint8 _pointer) onlyowner returns (uint) {
        pointer = _pointer;
        PointerChanged(pointer);
        return pointer;
    }

    function getGameIds() constant returns(uint[]) {
        uint[] memory ids = new uint[](games.length);
        for (uint i = 0; i < games.length; i++) {
            ids[i] = games[i].id;
        }
        return ids;
    }

    function getGamePlayer(uint gameId) constant returns(address) {
        return games[gameId].player;
    }

    function getGameAmount(uint gameId) constant returns(uint) {
        return games[gameId].amount;
    }

    function getGameStart(uint gameId) constant returns(uint8) {
        return games[gameId].start;
    }

    function getGameEnd(uint gameId) constant returns(uint8) {
        return games[gameId].end;
    }

    function getGameHash(uint gameId) constant returns(bytes32) {
        return games[gameId].hash;
    }

    function getGameNumber(uint gameId) constant returns(uint8) {
        return games[gameId].number;
    }

    function getGameWin(uint gameId) constant returns(bool) {
        return games[gameId].win;
    }

    function getGamePrize(uint gameId) constant returns(uint) {
        return games[gameId].prize;
    }

    function getMinBetAmount() constant returns(uint) {
        return minBetAmount;
    }

    function getMaxBetAmount() constant returns(uint) {
        return maxBetAmount;
    }

    function () payable {
    }
}