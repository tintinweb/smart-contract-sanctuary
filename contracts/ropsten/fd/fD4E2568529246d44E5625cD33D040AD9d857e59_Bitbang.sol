pragma solidity ^0.4.25;

/* ========================================================================== */
/*   ______   _____  _________  ______        _       ____  _____   ______    */
/*  |_   _ \ |_   _||  _   _  ||_   _ \      / \     |_   \|_   _|.&#39; ___  |   */
/*    | |_) |  | |  |_/ | | \_|  | |_) |    / _ \      |   \ | | / .&#39;   \_|   */
/*    |  __&#39;.  | |      | |      |  __&#39;.   / ___ \     | |\ \| | | |   ____   */
/*   _| |__) |_| |_    _| |_    _| |__) |_/ /   \ \_  _| |_\   |_\ `.___]  |  */
/*  |_______/|_____|  |_____|  |_______/|____| |____||_____|\____|`._____.&#39;   */
/*                                                                            */
/* ========================================================================== */

contract Bitbang {
    /**
     * @dev Bidder.
     */
    struct Bidder {
        uint256 balance;
        uint256[] records;
    }

    /**
     * @dev Record.
     */
    struct Record {
        address addr;
        uint256 round;
        uint256 price;
        uint256 timestamp;
    }

    /**
     * @dev Round.
     */
    struct Round {
        uint256 number;
        uint256 ethAuctioned;
        uint256 minBid;
        uint256 bidIncrement;
        uint256 timeLimit;
        uint256 recordOffset;
        uint256 highestPrice;
    }

    /**
     * @dev owner.
     */
    address public owner;

    /**
     * @dev nextOwner.
     */
    address public nextOwner;

    /**
     * @dev ethAuctioned.
     */
    uint256 public ethAuctioned = 1 ether;

    /**
     * @dev minBid.
     */
    uint256 public minBid = 0.05 ether;

    /**
     * @dev bidIncrement.
     */
    uint256 public bidIncrement = 0.05 ether;

    /**
     * @dev timeLimit.
     */
    uint256 public timeLimit = 1 hours;

    /**
     * @dev bidders.
     */
    mapping(address => Bidder) public bidders;

    /**
     * @dev records.
     */
    Record[] public records;

    /**
     * @dev rounds.
     */
    Round[] public rounds;

    /**
     * @dev libraries.
     */
    using SafeMath for uint256;

    /**
     * @dev events.
     */
    event LogBid(address indexed _sender, uint256 _value);
    event LogHammer(address indexed _sender, uint256 _value);
    event LogWithdraw(address indexed _sender, uint256 _value);
    event LogTransfer(address indexed _sender, uint256 _value);
    event LogFallback(address indexed _sender, uint256 _value);

    /**
     * @dev isOwner.
     */
    modifier isOwner {
        require(msg.sender == owner, "Invalid owner.");
        _;
    }

    /**
     * @dev constructor.
     */
    constructor() public {
        owner = msg.sender;
        createNewRound();
    }

    /**
     * @dev fallback.
     */
    function ()
        external
        payable
    {
        emit LogFallback(msg.sender, msg.value);
    }

    /**
     * @dev kill.
     */
    function kill()
        external
        isOwner
    {
        selfdestruct(owner);
    }

    /**
     * @dev bid.
     */
    function bid(uint256 _price)
        external
        payable
    {
        Bidder storage bidder = bidders[msg.sender];

        Round memory latestRound = rounds[rounds.length - 1];
        require(_price >= latestRound.minBid, "Invalid price");

        uint256 amount = bidder.balance.add(msg.value);
        require(_price <= amount, "Invalid price");

        uint256 remainder = _price.sub(latestRound.minBid)
            .mod(latestRound.bidIncrement);
        require(remainder == 0, "Invalid price");

        if (records.length > latestRound.recordOffset) {
            Record memory latestRecord = records[records.length - 1];
            require(_price > latestRecord.price, "Invalid price");

            uint256 timePeriod = blockTimestamp().sub(latestRecord.timestamp);
            require(timePeriod < timeLimit, "Invalid time");
        }

        uint256 price = _price.sub(msg.value);

        if (price > 0) {
            bidder.balance = bidder.balance.sub(price);
        }

        Record memory record;
        record.price = _price;
        record.addr = msg.sender;
        record.round = rounds.length - 1;
        record.timestamp = blockTimestamp();

        addRecord(record);

        emit LogBid(msg.sender, _price);
    }

    /**
     * @dev withdraw.
     */
    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Invalid amount");

        Bidder storage bidder = bidders[msg.sender];

        uint256 balance = bidder.balance;
        require(_amount <= balance, "Invalid amount");

        bidder.balance = bidder.balance.sub(_amount);
        msg.sender.transfer(_amount);

        emit LogWithdraw(msg.sender, _amount);
    }

    /**
     * @dev hammer.
     */
    function hammer()
        external
        isOwner
    {
        require(records.length > 0, "Invalid round");

        Record storage latestRecord = records[records.length - 1];
        require(latestRecord.round == rounds.length - 1, "Invalid round");

        uint256 timePeriod = blockTimestamp().sub(latestRecord.timestamp);
        require(timePeriod >= timeLimit, "Invalid time");

        Round storage latestRound = rounds[rounds.length - 1];
        latestRound.highestPrice = latestRecord.price;
        Bidder storage bidder = bidders[latestRecord.addr];
        bidder.balance = bidder.balance.add(latestRound.ethAuctioned);

        createNewRound();

        emit LogHammer(latestRecord.addr, latestRecord.price);
    }

    /**
     * @dev transfer.
     */
    function transfer(uint256 _amount)
        external
        isOwner
    {
        require(_amount <= address(this).balance, "Invalid amount");
        owner.transfer(_amount);

        emit LogTransfer(owner, _amount);
    }

    /**
     * @dev getBidder.
     */
    function getBidder(uint256 _from, uint256 _to)
        external
        view
        returns (
            uint256 _balance,
            uint256[] _rounds,
            uint256[] _prices,
            uint256[] _timestamps
        )
    {
        require(_from <= _to, "Invalid from or to");

        uint256 from = _from;
        uint256 to = _to;

        uint256 max = bidder.records.length - 1;

        if (from > max) {
            return;
        }

        if (to > max) {
            to = max;
        }

        Bidder memory bidder = bidders[msg.sender];
        _balance = bidder.balance;

        uint256 length = to - from + 1;
        _rounds = new uint256[](length);
        _prices = new uint256[](length);
        _timestamps = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            Record memory record = records[bidder.records[i]];

            _rounds[i] = record.round;
            _prices[i] = record.price;
            _timestamps[i] = record.timestamp;
        }
    }

    /**
     * @dev getRecords.
     */
    function getRecords(uint256 _round, uint256 _from, uint256 _to)
        external
        view
        returns (
            address[] _addrs,
            uint256[] _prices,
            uint256[] _timestamps
        )
    {
        require(_round < rounds.length, "Invalid round");
        require(_from <= _to, "Invalid from or to");

        Round memory round = rounds[_round];

        uint256 from = round.recordOffset;
        uint256 to;

        if (_round + 1 < rounds.length) {
            round = rounds[_round + 1];
            to = round.recordOffset - 1;
        } else if (records.length > round.recordOffset) {
            to = records.length - 1;
        } else {
            return;
        }

        from += _from;

        if (from > to) {
            return;
        }

        uint256 offset = from - _from + _to;

        if (offset < to) {
            to = offset;
        }

        uint256 length = to - from + 1;
        _addrs = new address[](length);
        _prices = new uint256[](length);
        _timestamps = new uint256[](length);

        uint256 index = 0;

        for (uint256 i = from; i <= to; i++) {
            _addrs[index] = records[i].addr;
            _prices[index] = records[i].price;
            _timestamps[index] = records[i].timestamp;

            index++;
        }
    }

    /**
     * @dev getRounds.
     */
    function getRounds(uint256 _from, uint256 _to)
        external
        view
        returns (
            uint256[] _numbers,
            uint256[] _ethAuctioneds,
            uint256[] _minBids,
            uint256[] _bidIncrements,
            uint256[] _timeLimits,
            uint256[] _highestPrices
        )
    {
        require(_from <= _to, "Invalid from or to");

        uint256 from = _from;
        uint256 to = _to;

        uint256 max = rounds.length - 1;

        if (from > max) {
            return;
        }

        if (to > max) {
            to = max;
        }

        uint256 length = to - from + 1;
        _numbers = new uint256[](length);
        _ethAuctioneds = new uint256[](length);
        _minBids = new uint256[](length);
        _bidIncrements = new uint256[](length);
        _timeLimits = new uint256[](length);
        _highestPrices = new uint256[](length);

        uint256 index = 0;

        for (uint256 i = from; i <= to; i++) {
            _numbers[index] = rounds[i].number;
            _ethAuctioneds[index] = rounds[i].ethAuctioned;
            _minBids[index] = rounds[i].minBid;
            _bidIncrements[index] = rounds[i].bidIncrement;
            _timeLimits[index] = rounds[i].timeLimit;
            _highestPrices[index] = rounds[i].highestPrice;

            index++;
        }
    }

    /**
     * @dev setOptions.
     */
    function setOptions(
        uint256 _ethAuctioned,
        uint256 _minBid,
        uint256 _bidIncrement,
        uint256 _timeLimit
    )
        external
        isOwner
    {
        if (_ethAuctioned != 0) {
            ethAuctioned = _ethAuctioned;
        }

        if (_minBid != 0) {
            minBid = _minBid;
        }

        if (_bidIncrement != 0) {
            bidIncrement = _bidIncrement;
        }

        if (_timeLimit != 0) {
            timeLimit = _timeLimit;
        }
    }

    /**
     * @dev isRoundEnd.
     */
    function isRoundEnd()
        external
        view
        returns (bool)
    {
        if (records.length == 0) {
            return false;
        }

        Record memory latestRecord = records[records.length - 1];

        if (latestRecord.round < rounds.length - 1) {
            return false;
        }

        return blockTimestamp().sub(latestRecord.timestamp) >= timeLimit;
    }

    /**
     * @dev approveOwner.
     */
    function approveOwner(address _nextOwner)
        external
        isOwner
    {
        require(_nextOwner != owner, "Invalid owner.");
        nextOwner = _nextOwner;
    }

    /**
     * @dev acceptOwner.
     */
    function acceptOwner() external {
        require(msg.sender == nextOwner, "Invalid nextOwner.");
        owner = nextOwner;
    }

    /**
     * @dev create.
     */
    function createNewRound() private {
        Round memory newRound;
        newRound.number = rounds.length;
        newRound.ethAuctioned = ethAuctioned;
        newRound.minBid = minBid;
        newRound.bidIncrement = bidIncrement;
        newRound.timeLimit = timeLimit;
        newRound.recordOffset = records.length;
        newRound.highestPrice = 0;

        rounds.push(newRound);
    }

    /**
     * @dev addRecord.
     */
    function addRecord(Record _record) private {
        records.push(_record);

        Bidder storage bidder = bidders[_record.addr];
        bidder.records.push(records.length - 1);

        if (records.length > 2) {
            Record memory frontRecord = records[records.length - 3];

            if (frontRecord.round == rounds.length - 1) {
                Bidder storage frontBidder = bidders[frontRecord.addr];
                frontBidder.balance = frontBidder.balance.add(frontRecord.price);
            }
        }
    }

    /**
     * @dev blockTimestamp.
     */
    function blockTimestamp()
        private
        view
        returns (uint256)
    {
        return block.timestamp;
    }
}

// =============================================================================
// LIBRARY: SAFEMATH
// =============================================================================

/**
 * @title SafeMath
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Invalid mul");

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Invalid div"); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Invalid sub");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Invalid add");

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Invalid mod");

        return a % b;
    }
}