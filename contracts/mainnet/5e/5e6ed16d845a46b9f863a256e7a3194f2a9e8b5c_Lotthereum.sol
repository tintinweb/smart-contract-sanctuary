pragma solidity ^0.4.11;


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


contract Lotthereum is Mortal {
    uint blockPointer;
    uint maxNumberOfBets;
    uint minAmountByBet;
    uint prize;
    uint currentRound;
    bytes32 private hash;

    Round[] private rounds;
    mapping (uint => Bet[]) bets;
    mapping (address => uint) private balances;

    struct Round {
        uint id;
        bool open;
        uint maxNumberOfBets;
        uint minAmountByBet;
        uint blockNumber;
        bytes32 blockHash;
        uint8 number;
        uint prize;
    }

    struct Bet {
        uint id;
        address origin;
        uint amount;
        uint8 bet;
        uint round;
    }

    event RoundOpen(uint indexed id, uint maxNumberOfBets, uint minAmountByBet);
    event RoundClose(uint indexed id, uint8 number, uint blockNumber, bytes32 blockHash);
    event MaxNumberOfBetsChanged(uint maxNumberOfBets);
    event MinAmountByBetChanged(uint minAmountByBet);
    event BetPlaced(address indexed origin, uint roundId, uint betId);
    event RoundWinner(address indexed winnerAddress, uint amount);

    function Lotthereum(uint _blockPointer, uint _maxNumberOfBets, uint _minAmountByBet, uint _prize, bytes32 _hash) {
        blockPointer = _blockPointer;
        maxNumberOfBets = _maxNumberOfBets;
        minAmountByBet = _minAmountByBet;
        prize = _prize;
        hash = _hash;
        currentRound = createRound();
    }

    function createRound() internal returns (uint id) {
        id = rounds.length;
        rounds.length += 1;
        rounds[id].id = id;
        rounds[id].open = false;
        rounds[id].maxNumberOfBets = maxNumberOfBets;
        rounds[id].minAmountByBet = minAmountByBet;
        rounds[id].prize = prize;
        rounds[id].blockNumber = 0;
        rounds[id].blockHash = hash;
        rounds[id].open = true;
        RoundOpen(id, maxNumberOfBets, minAmountByBet);
    }

    function payout() internal {
        for (uint i = 0; i < bets[currentRound].length; i++) {
            if (bets[currentRound][i].bet == rounds[currentRound].number) {
                balances[bets[currentRound][i].origin] += rounds[currentRound].prize;
                RoundWinner(bets[currentRound][i].origin, rounds[currentRound].prize);
            }
        }
    }

    function closeRound() constant internal {
        rounds[currentRound].open = false;
        rounds[currentRound].blockHash = getBlockHash(blockPointer);
        rounds[currentRound].number = getNumber(rounds[currentRound].blockHash);
        payout();
        RoundClose(currentRound, rounds[currentRound].number, rounds[currentRound].blockNumber, rounds[currentRound].blockHash);
        currentRound = createRound();
    }

    function getBlockHash(uint i) constant returns (bytes32 blockHash) {
        if (i > 256) {
            i = 256;
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

    function bet(uint8 bet) public payable returns (bool) {
        if (!rounds[currentRound].open) {
            return false;
        }

        if (msg.value < rounds[currentRound].minAmountByBet) {
            return false;
        }

        uint id = bets[currentRound].length;
        bets[currentRound].length += 1;
        bets[currentRound][id].id = id;
        bets[currentRound][id].round = currentRound;
        bets[currentRound][id].bet = bet;
        bets[currentRound][id].origin = msg.sender;
        bets[currentRound][id].amount = msg.value;
        BetPlaced(msg.sender, currentRound, id);

        if (bets[currentRound].length == rounds[currentRound].maxNumberOfBets) {
            closeRound();
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

    function getCurrentRoundId() constant returns(uint) {
        return currentRound;
    }

    function getRoundOpen(uint id) constant returns(bool) {
        return rounds[id].open;
    }

    function getRoundMaxNumberOfBets(uint id) constant returns(uint) {
        return rounds[id].maxNumberOfBets;
    }

    function getRoundMinAmountByBet(uint id) constant returns(uint) {
        return rounds[id].minAmountByBet;
    }

    function getRoundPrize(uint id) constant returns(uint) {
        return rounds[id].prize;
    }

    function getRoundNumberOfBets(uint id) constant returns(uint) {
        return bets[id].length;
    }

    function getRoundBetOrigin(uint roundId, uint betId) constant returns(address) {
        return bets[roundId][betId].origin;
    }

    function getRoundBetAmount(uint roundId, uint betId) constant returns(uint) {
        return bets[roundId][betId].amount;
    }

    function getRoundBetNumber(uint roundId, uint betId) constant returns(uint) {
        return bets[roundId][betId].bet;
    }

    function getRoundNumber(uint id) constant returns(uint8) {
        return rounds[id].number;
    }

    function getRoundBlockNumber(uint id) constant returns(uint) {
        return rounds[id].blockNumber;
    }

    function getBlockPointer() constant returns(uint) {
        return blockPointer;
    }

    function () payable {
    }
}