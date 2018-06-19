pragma solidity ^0.4.15;

contract ETHLotteryManagerInterface {
    function register();
}

contract ETHLotteryInterface {
    function accumulate();
}

contract ETHLottery {
    bytes32 public name = &#39;ETHLottery - Last 1 Byte Lottery&#39;;
    address public manager_address;
    address public owner;
    bool public open;
    uint256 public jackpot;
    uint256 public fee;
    uint256 public owner_fee;
    uint256 public create_block;
    uint256 public result_block;
    uint256 public winners_count;
    bytes32 public result_hash;
    bytes1 public result;
    address public accumulated_from;
    address public accumulate_to;

    mapping (bytes1 => address[]) bettings;
    mapping (address => uint256) credits;

    event Balance(uint256 _balance);
    event Result(bytes1 _result);
    event Open(bool _open);
    event Play(address indexed _sender, bytes1 _byte, uint256 _time);
    event Withdraw(address indexed _sender, uint256 _amount, uint256 _time);
    event Destroy();
    event Accumulate(address _accumulate_to, uint256 _amount);

    function ETHLottery(address _manager, uint256 _fee, uint256 _jackpot, uint256 _owner_fee, address _accumulated_from) {
        owner = msg.sender;
        open = true;
        create_block = block.number;
        manager_address = _manager;
        fee = _fee;
        jackpot = _jackpot;
        owner_fee = _owner_fee;
        // accumulate
        if (_accumulated_from != owner) {
            accumulated_from = _accumulated_from;
            ETHLotteryInterface lottery = ETHLotteryInterface(accumulated_from);
            lottery.accumulate();
        }
        // register with manager
        ETHLotteryManagerInterface manager = ETHLotteryManagerInterface(manager_address);
        manager.register();
        Open(open);
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isOriginalOwner() {
        // used tx.origin on purpose instead of
        // msg.sender, as we want to get the original
        // starter of the transaction to be owner
        require(tx.origin == owner);
        _;
    }

    modifier isOpen() {
        require(open);
        _;
    }

    modifier isClosed() {
        require(!open);
        _;
    }

    modifier isPaid() {
        require(msg.value >= fee);
        _;
    }

    modifier hasPrize() {
        require(credits[msg.sender] > 0);
        _;
    }

    modifier isAccumulated() {
        require(result_hash != 0 && winners_count == 0);
        _;
    }

    modifier hasResultHash() {
        require(
            block.number >= result_block &&
            block.number <= result_block + 256 &&
            block.blockhash(result_block) != result_hash
            );
        _;
    }

    function play(bytes1 _byte) payable isOpen isPaid returns (bool) {
        bettings[_byte].push(msg.sender);
        if (this.balance >= jackpot) {
            uint256 owner_fee_amount = (this.balance * owner_fee) / 100;
            // this is the transaction which
            // will generate the block used
            // to count until the 10th in order
            // to get the lottery result.
            if (!owner.send(owner_fee_amount)) {
                return false;
            }
            open = false;
            // block offset hardcoded to 10
            result_block = block.number + 10;
            Open(open);
        }
        Balance(this.balance);
        Play(msg.sender, _byte, now);
        return true;
    }

    // This method is only used if we miss the 256th block
    // containing the result hash, lottery() should be used instead
    // this method as this is duplicated from lottery()
    function manual_lottery(bytes32 _result_hash) isClosed isOwner {
        result_hash = _result_hash;
        result = result_hash[31];
        address[] storage winners = bettings[result];
        winners_count = winners.length;
        if (winners_count > 0) {
            uint256 credit = this.balance / winners_count;
            for (uint256 i = 0; i < winners_count; i++) {
                credits[winners[i]] = credit;
            }
        }
        Result(result);
    }

    function lottery() isClosed hasResultHash isOwner {
        result_hash = block.blockhash(result_block);
        // get last byte (31st) from block hash as result
        result = result_hash[31];
        address[] storage winners = bettings[result];
        winners_count = winners.length;
        if (winners_count > 0) {
            uint256 credit = this.balance / winners_count;
            for (uint256 i = 0; i < winners_count; i++) {
                credits[winners[i]] = credit;
            }
        }
        Result(result);
    }

    function withdraw() isClosed hasPrize returns (bool) {
        uint256 credit = credits[msg.sender];
        // zero credit before send preventing re-entrancy
        // as msg.sender can be a contract and call us back
        credits[msg.sender] = 0;
        if (!msg.sender.send(credit)) {
            // transfer failed, return credit for withdraw
            credits[msg.sender] = credit;
            return false;
        }
        Withdraw(msg.sender, credit, now);
        return true;
    }

    function accumulate() isOriginalOwner isClosed isAccumulated {
        accumulate_to = msg.sender;
        if (msg.sender.send(this.balance)) {
            Accumulate(msg.sender, this.balance);
        }
    }

    function destruct() isClosed isOwner {
        Destroy();
        selfdestruct(owner);
    }
}