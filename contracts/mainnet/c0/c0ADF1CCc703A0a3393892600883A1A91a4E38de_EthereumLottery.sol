pragma solidity ^0.4.13;

contract BTCRelay {
    function getLastBlockHeight() returns (int);
    function getBlockchainHead() returns (int);
    function getFeeAmount(int blockHash) returns (int);
    function getBlockHeader(int blockHash) returns (bytes32[3]);
}

contract PoissonData {
    function lookup(int blocks) constant returns (uint);
}

contract Escrow {
    function deposit(address recipient) payable;
}

contract EthereumLottery {
    uint constant INACTIVITY_TIMEOUT = 2 weeks;
    uint constant GAS_LIMIT = 300000;

    struct Lottery {
        uint jackpot;
        int decidingBlock;
        uint numTickets;
        uint numTicketsSold;
        uint ticketPrice;
        uint cutoffTimestamp;
        int winningTicket;
        address winner;
        uint finalizationBlock;
        address finalizer;
        string message;
        mapping (uint => address) tickets;
        int nearestKnownBlock;
        int nearestKnownBlockHash;
    }

    address public owner;
    address public admin;
    address public proposedOwner;

    int public id = -1;
    uint public lastInitTimestamp;
    uint public lastSaleTimestamp;

    uint public recentActivityIdx;
    uint[1000] public recentActivity;

    mapping (int => Lottery) public lotteries;

    address public btcRelay;
    address public poissonData;
    address public escrow;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdminOrOwner {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

    modifier afterInitialization {
        require(id >= 0);
        _;
    }

    function EthereumLottery(address _btcRelay,
                             address _poissonData,
                             address _escrow) {
        owner = msg.sender;
        admin = msg.sender;
        btcRelay = _btcRelay;
        poissonData = _poissonData;
        escrow = _escrow;
    }

    function needsInitialization() constant returns (bool) {
        return id == -1 || lotteries[id].finalizationBlock > 0;
    }

    function initLottery(uint _jackpot, uint _numTickets,
                         uint _ticketPrice, int _durationInBlocks)
             payable onlyAdminOrOwner {
        require(needsInitialization());
        require(msg.value > 0);
        require(msg.value == _jackpot);
        require(_numTickets * _ticketPrice > _jackpot);

        // Look up precomputed timespan in seconds where the
        // probability for n or more blocks occuring within
        // that timespan is just 1 %. This is based on
        // assuming an actual block time of 9 minutes. We
        // can use this data to figure out for how long it
        // is safe to keep selling tickets.
        uint ticketSaleDuration =
            PoissonData(poissonData).lookup(_durationInBlocks - 1);
        require(ticketSaleDuration > 0);

        id += 1;
        lotteries[id].jackpot = _jackpot;
        lotteries[id].decidingBlock =
            BTCRelay(btcRelay).getLastBlockHeight() + _durationInBlocks;
        lotteries[id].numTickets = _numTickets;
        lotteries[id].ticketPrice = _ticketPrice;
        lotteries[id].cutoffTimestamp = now + ticketSaleDuration;
        lotteries[id].winningTicket = -1;

        lastInitTimestamp = now;
    }

    function buyTickets(uint[] _tickets)
             payable afterInitialization {
        int blockHeight = BTCRelay(btcRelay).getLastBlockHeight();
        require(blockHeight + 1 < lotteries[id].decidingBlock);
        require(now < lotteries[id].cutoffTimestamp);

        require(_tickets.length > 0);
        require(msg.value == _tickets.length * lotteries[id].ticketPrice);

        for (uint i = 0; i < _tickets.length; i++) {
            uint ticket = _tickets[i];
            require(ticket >= 0);
            require(ticket < lotteries[id].numTickets);
            require(lotteries[id].tickets[ticket] == 0);

            lotteries[id].tickets[ticket] = msg.sender;
            recentActivity[recentActivityIdx] = ticket;

            recentActivityIdx += 1;
            if (recentActivityIdx >= recentActivity.length) {
                recentActivityIdx = 0;
            }
        }
        lotteries[id].numTicketsSold += _tickets.length;
        lastSaleTimestamp = now;

        // Maybe shorten ticket sale timespan if we are running ahead.
        int remainingDurationInBlocks =
            lotteries[id].decidingBlock - blockHeight;
        uint ticketSaleDuration =
            PoissonData(poissonData).lookup(remainingDurationInBlocks - 1);
        if (now + ticketSaleDuration < lotteries[id].cutoffTimestamp) {
            lotteries[id].cutoffTimestamp = now + ticketSaleDuration;
        }
    }

    function needsFinalization()
             afterInitialization constant returns (bool) {
        int blockHeight = BTCRelay(btcRelay).getLastBlockHeight();
        return blockHeight >= lotteries[id].decidingBlock + 6 &&
               lotteries[id].finalizationBlock == 0;
    }

    function finalizeLottery(uint _steps)
             afterInitialization {
        require(needsFinalization());

        if (lotteries[id].nearestKnownBlock != lotteries[id].decidingBlock) {
            walkTowardsBlock(_steps);
        } else {
            int winningTicket = lotteries[id].nearestKnownBlockHash %
                                int(lotteries[id].numTickets);
            address winner = lotteries[id].tickets[uint(winningTicket)];

            lotteries[id].winningTicket = winningTicket;
            lotteries[id].winner = winner;
            lotteries[id].finalizationBlock = block.number;
            lotteries[id].finalizer = tx.origin;

            if (winner != 0) {
                uint value = lotteries[id].jackpot;
                bool successful = winner.call.gas(GAS_LIMIT).value(value)();
                if (!successful) {
                    Escrow(escrow).deposit.value(value)(winner);
                }
            }

            var _ = admin.call.gas(GAS_LIMIT).value(this.balance)();
        }
    }

    function walkTowardsBlock(uint _steps) internal {
        int blockHeight;
        int blockHash;
        if (lotteries[id].nearestKnownBlock == 0) {
            blockHeight = BTCRelay(btcRelay).getLastBlockHeight();
            blockHash = BTCRelay(btcRelay).getBlockchainHead();
        } else {
            blockHeight = lotteries[id].nearestKnownBlock;
            blockHash = lotteries[id].nearestKnownBlockHash;
        }

        // Walk only a few steps to keep an upper limit on gas costs.
        for (uint step = 0; step < _steps; step++) {
            // We expect free access to BTCRelay.
            int fee = BTCRelay(btcRelay).getFeeAmount(blockHash);
            require(fee == 0);

            bytes32 blockHeader =
                BTCRelay(btcRelay).getBlockHeader(blockHash)[2];
            bytes32 temp;

            assembly {
                let x := mload(0x40)
                mstore(x, blockHeader)
                temp := mload(add(x, 0x04))
            }

            blockHeight -= 1;
            blockHash = 0;
            for (uint i = 0; i < 32; i++) {
                blockHash = blockHash | int(temp[uint(i)]) * int(256 ** i);
            }

            if (blockHeight == lotteries[id].decidingBlock) { break; }
        }

        // Store the progress to pick up from there next time.
        lotteries[id].nearestKnownBlock = blockHeight;
        lotteries[id].nearestKnownBlockHash = blockHash;
    }

    function getMessageLength(string _message) constant returns (uint) {
        return bytes(_message).length;
    }

    function setMessage(int _id, string _message)
             afterInitialization {
        require(lotteries[_id].winner != 0);
        require(lotteries[_id].winner == msg.sender);
        require(getMessageLength(_message) <= 500);
        lotteries[_id].message = _message;
    }

    function getLotteryDetailsA(int _id)
             constant returns (int _actualId, uint _jackpot,
                               int _decidingBlock,
                               uint _numTickets, uint _numTicketsSold,
                               uint _lastSaleTimestamp, uint _ticketPrice,
                               uint _cutoffTimestamp) {
        if (_id == -1) {
            _actualId = id;
        } else {
            _actualId = _id;
        }
        _jackpot = lotteries[_actualId].jackpot;
        _decidingBlock = lotteries[_actualId].decidingBlock;
        _numTickets = lotteries[_actualId].numTickets;
        _numTicketsSold = lotteries[_actualId].numTicketsSold;
        _lastSaleTimestamp = lastSaleTimestamp;
        _ticketPrice = lotteries[_actualId].ticketPrice;
        _cutoffTimestamp = lotteries[_actualId].cutoffTimestamp;
    }

    function getLotteryDetailsB(int _id)
             constant returns (int _actualId,
                               int _winningTicket, address _winner,
                               uint _finalizationBlock, address _finalizer,
                               string _message,
                               int _prevLottery, int _nextLottery,
                               int _blockHeight) {
        if (_id == -1) {
            _actualId = id;
        } else {
            _actualId = _id;
        }
        _winningTicket = lotteries[_actualId].winningTicket;
        _winner = lotteries[_actualId].winner;
        _finalizationBlock = lotteries[_actualId].finalizationBlock;
        _finalizer = lotteries[_actualId].finalizer;
        _message = lotteries[_actualId].message;

        if (_actualId == 0) {
            _prevLottery = -1;
        } else {
            _prevLottery = _actualId - 1;
        }
        if (_actualId == id) {
            _nextLottery = -1;
        } else {
            _nextLottery = _actualId + 1;
        }

        _blockHeight = BTCRelay(btcRelay).getLastBlockHeight();
    }

    function getTicketDetails(int _id, uint _offset, uint _n, address _addr)
             constant returns (uint8[] details) {
        require(_offset + _n <= lotteries[_id].numTickets);

        details = new uint8[](_n);
        for (uint i = 0; i < _n; i++) {
            address addr = lotteries[_id].tickets[_offset + i];
            if (addr == _addr && _addr != 0) {
                details[i] = 2;
            } else if (addr != 0) {
                details[i] = 1;
            } else {
                details[i] = 0;
            }
        }
    }


    function getTicketOwner(int _id, uint _ticket) constant returns (address) {
        require(_id >= 0);
        return lotteries[_id].tickets[_ticket];
    }

    function getRecentActivity()
             constant returns (int _id, uint _idx, uint[1000] _recentActivity) {
        _id = id;
        _idx = recentActivityIdx;
        for (uint i = 0; i < recentActivity.length; i++) {
            _recentActivity[i] = recentActivity[i];
        }
    }

    function setAdmin(address _admin) onlyOwner {
        admin = _admin;
    }

    function proposeOwner(address _owner) onlyOwner {
        proposedOwner = _owner;
    }

    function acceptOwnership() {
        require(proposedOwner != 0);
        require(msg.sender == proposedOwner);
        owner = proposedOwner;
    }

    function destruct() onlyOwner {
        require(now - lastInitTimestamp > INACTIVITY_TIMEOUT);
        selfdestruct(owner);
    }
}