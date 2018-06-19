pragma solidity ^0.4.15;

contract BTCRelay {
    function getLastBlockHeight() public returns (int);
    function getBlockchainHead() public returns (int);
    function getFeeAmount(int blockHash) public returns (int);
    function getBlockHeader(int blockHash) public returns (bytes32[5]);
    function storeBlockHeader(bytes blockHeader) public returns (int);
}

contract Escrow {
    function deposit(address recipient) payable;
}

contract EthereumLottery {
    uint constant GAS_LIMIT_DEPOSIT = 300000;
    uint constant GAS_LIMIT_BUY = 450000;

    struct Lottery {
        uint jackpot;
        int decidingBlock;
        uint numTickets;
        uint numTicketsSold;
        uint ticketPrice;
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
    address public escrow;

    enum Reason { TicketSaleClosed, TicketAlreadySold, InsufficientGas }
    event PurchaseFailed(address indexed buyer, uint mark, Reason reason);
    event PurchaseSuccessful(address indexed buyer, uint mark);

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
                             address _escrow) {
        owner = msg.sender;
        admin = msg.sender;
        btcRelay = _btcRelay;
        escrow = _escrow;
    }

    function needsInitialization() constant returns (bool) {
        return id == -1 || lotteries[id].finalizationBlock > 0;
    }

    function initLottery(uint _jackpot, uint _numTickets, uint _ticketPrice)
             onlyAdminOrOwner {
        require(needsInitialization());
        require(_numTickets * _ticketPrice > _jackpot);

        id += 1;
        lotteries[id].jackpot = _jackpot;
        lotteries[id].decidingBlock = -1;
        lotteries[id].numTickets = _numTickets;
        lotteries[id].ticketPrice = _ticketPrice;
        lotteries[id].winningTicket = -1;

        lastInitTimestamp = block.timestamp;
        lastSaleTimestamp = 0;
    }

    function buyTickets(uint[] _tickets, uint _mark, bytes _extraData)
             payable afterInitialization {
        if (msg.gas < GAS_LIMIT_BUY) {
            PurchaseFailed(msg.sender, _mark, Reason.InsufficientGas);
            return;
        }

        if (lotteries[id].numTicketsSold == lotteries[id].numTickets) {
            PurchaseFailed(msg.sender, _mark, Reason.TicketSaleClosed);
            return;
        }

        require(_tickets.length > 0);
        require(msg.value == _tickets.length * lotteries[id].ticketPrice);

        for (uint i = 0; i < _tickets.length; i++) {
            uint ticket = _tickets[i];
            require(ticket >= 0);
            require(ticket < lotteries[id].numTickets);

            if (lotteries[id].tickets[ticket] != 0) {
                PurchaseFailed(msg.sender, _mark, Reason.TicketAlreadySold);
                return;
            }
        }

        for (i = 0; i < _tickets.length; i++) {
            ticket = _tickets[i];
            lotteries[id].tickets[ticket] = msg.sender;
            recentActivity[recentActivityIdx] = ticket;

            recentActivityIdx += 1;
            if (recentActivityIdx >= recentActivity.length) {
                recentActivityIdx = 0;
            }
        }

        lotteries[id].numTicketsSold += _tickets.length;
        lastSaleTimestamp = block.timestamp;

        BTCRelay(btcRelay).storeBlockHeader(_extraData);

        PurchaseSuccessful(msg.sender, _mark);
    }

    function needsBlockFinalization()
             afterInitialization constant returns (bool) {
        // Check the timestamp of the latest block known to BTCRelay
        // and require it to be no more than 2 hours older than the
        // timestamp of our block. This should ensure that BTCRelay
        // is reasonably up to date.
        uint btcTimestamp;
        int blockHash = BTCRelay(btcRelay).getBlockchainHead();
        (,btcTimestamp) = getBlockHeader(blockHash);

        uint delta = 0;
        if (btcTimestamp < block.timestamp) {
            delta = block.timestamp - btcTimestamp;
        }

        return delta < 2 * 60 * 60 &&
               lotteries[id].numTicketsSold == lotteries[id].numTickets &&
               lotteries[id].decidingBlock == -1;
    }

    function finalizeBlock()
             afterInitialization {
        require(needsBlockFinalization());

        // At this point we know that the timestamp of the latest block
        // known to BTCRelay is within 2 hours of what the Ethereum network
        // considers &#39;now&#39;. If we assume this to be correct within +/- 3 hours,
        // we can conclude that &#39;out there&#39; in the real world at most 5 hours
        // have passed. Assuming an actual block time of 9 minutes for Bitcoin,
        // we can use the Poisson distribution to calculate, that if we wait for
        // 54 more blocks, then the probability for all of these 54 blocks
        // having already been mined in 5 hours is less than 0.1 %.
        int blockHeight = BTCRelay(btcRelay).getLastBlockHeight();
        lotteries[id].decidingBlock = blockHeight + 54;
    }

    function needsLotteryFinalization()
             afterInitialization constant returns (bool) {
        int blockHeight = BTCRelay(btcRelay).getLastBlockHeight();
        return lotteries[id].decidingBlock != -1 &&
               blockHeight >= lotteries[id].decidingBlock + 6 &&
               lotteries[id].finalizationBlock == 0;
    }

    function finalizeLottery(uint _steps)
             afterInitialization {
        require(needsLotteryFinalization());

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
                bool successful =
                    winner.call.gas(GAS_LIMIT_DEPOSIT).value(value)();
                if (!successful) {
                    Escrow(escrow).deposit.value(value)(winner);
                }
            }

            var _ = admin.call.gas(GAS_LIMIT_DEPOSIT).value(this.balance)();
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
            blockHeight -= 1;
            (blockHash,) = getBlockHeader(blockHash);

            if (blockHeight == lotteries[id].decidingBlock) { break; }
        }

        // Store the progress to pick up from there next time.
        lotteries[id].nearestKnownBlock = blockHeight;
        lotteries[id].nearestKnownBlockHash = blockHash;
    }

    function getBlockHeader(int blockHash)
             internal returns (int prevBlockHash, uint timestamp) {
        // We expect free access to BTCRelay.
        int fee = BTCRelay(btcRelay).getFeeAmount(blockHash);
        require(fee == 0);

        // Code is based on tjade273&#39;s BTCRelayTools.
        bytes32[5] memory blockHeader =
            BTCRelay(btcRelay).getBlockHeader(blockHash);

        prevBlockHash = 0;
        for (uint i = 0; i < 32; i++) {
            uint pos = 68 + i;  // prev. block hash starts at position 68
            byte data = blockHeader[pos / 32][pos % 32];
            prevBlockHash = prevBlockHash | int(data) * int(0x100 ** i);
        }

        timestamp = 0;
        for (i = 0; i < 4; i++) {
            pos = 132 + i;  // timestamp starts at position 132
            data = blockHeader[pos / 32][pos % 32];
            timestamp = timestamp | uint(data) * uint(0x100 ** i);
        }

        return (prevBlockHash, timestamp);
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
                               uint _lastSaleTimestamp, uint _ticketPrice) {
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
}