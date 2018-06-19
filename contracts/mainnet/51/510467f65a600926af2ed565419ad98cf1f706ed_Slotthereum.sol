pragma solidity ^0.4.15;

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

    mapping (address => Game[]) private games;      // games per address

    uint private minBetAmount = 10000000000000000;  // minimum amount per bet
    uint private maxBetAmount = 5000000000000000000;  // maximum amount per bet
    uint private pointer = 1;                       // block pointer
    uint private numberOfPlayers = 0;               // number of players

    struct Game {
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
        uint8 mint = 0; // pointer?
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

        if (counter > 9) {
            return false;
        }

        if (counter < 1) {
            return false;
        }

        uint gameId = games[msg.sender].length;
        games[msg.sender].length += 1;
        games[msg.sender][gameId].id = gameId;
        games[msg.sender][gameId].amount = msg.value;
        games[msg.sender][gameId].start = start;
        games[msg.sender][gameId].end = end;
        games[msg.sender][gameId].hash = getBlockHash(pointer);
        games[msg.sender][gameId].number = getNumber(games[msg.sender][gameId].hash);
        // set pointer to number ?

        games[msg.sender][gameId].prize = 1;
        if ((games[msg.sender][gameId].number >= start) && (games[msg.sender][gameId].number <= end)) {
            games[msg.sender][gameId].win = true;
            uint dec = msg.value / 10;
            uint parts = 10 - counter;
            games[msg.sender][gameId].prize = msg.value + dec * parts;
        }

        msg.sender.transfer(games[msg.sender][gameId].prize);

        notify(
            msg.sender,
            gameId,
            start,
            end,
            games[msg.sender][gameId].number,
            msg.value,
            games[msg.sender][gameId].prize,
            games[msg.sender][gameId].win
        );

        return true;
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

    function getGameIds(address player) constant returns(uint[] memory ids) {
        ids = new uint[](games[player].length);
        for (uint i = 0; i < games[player].length; i++) {
            ids[i] = games[player][i].id;
        }
    }

    function getGameAmount(address player, uint gameId) constant returns(uint) {
        return games[player][gameId].amount;
    }

    function getGameStart(address player, uint gameId) constant returns(uint8) {
        return games[player][gameId].start;
    }

    function getGameEnd(address player, uint gameId) constant returns(uint8) {
        return games[player][gameId].end;
    }

    function getGameHash(address player, uint gameId) constant returns(bytes32) {
        return games[player][gameId].hash;
    }

    function getGameNumber(address player, uint gameId) constant returns(uint8) {
        return games[player][gameId].number;
    }

    function getGameWin(address player, uint gameId) constant returns(bool) {
        return games[player][gameId].win;
    }

    function getGamePrize(address player, uint gameId) constant returns(uint) {
        return games[player][gameId].prize;
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