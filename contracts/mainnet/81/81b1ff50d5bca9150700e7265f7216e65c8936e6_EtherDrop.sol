pragma solidity ^0.4.20;

/**
 * @author FadyAro
 *
 * 22.07.2018
 *
 *
 */
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is Ownable {

    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused, &#39;Contract Paused!&#39;);
        _;
    }

    modifier whenPaused() {
        require(paused, &#39;Contract Active!&#39;);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract EtherDrop is Pausable {

    uint constant PRICE_WEI = 2e16;

    /*
     * blacklist flag
     */
    uint constant FLAG_BLACKLIST = 1;

    /*
     * subscription queue size: should be power of 10
     */
    uint constant QMAX = 1000;

    /*
     * randomness order construction conform to QMAX
     * e.g. random [0 to 999] is of order 3 => rand = 100*x + 10*y + z
     */
    uint constant DMAX = 3;

    /*
     * this event is when we have a new subscription
     * note that it may be fired sequentially just before => NewWinner
     */
    event NewDropIn(address addr, uint round, uint place, uint value);

    /*
     * this event is when we have a new winner
     * it is as well a new round start => (round + 1)
     */
    event NewWinner(address addr, uint round, uint place, uint value, uint price);

    struct history {

        /*
         * user black listed comment
         */
        uint blacklist;

        /*
         * user rounds subscriptions number
         */
        uint size;

        /*
         * array of subscribed rounds indexes
         */
        uint[] rounds;

        /*
         * array of rounds subscription&#39;s inqueue indexes
         */
        uint[] places;

        /*
         * array of rounds&#39;s ether value subscription >= PRICE
         */
        uint[] values;

        /*
         * array of 0&#39;s initially, update to REWARD PRICE in win situations
         */
        uint[] prices;
    }

    /*
     * active subscription queue
     */
    address[] private _queue;

    /*
     * winners history
     */
    address[] private _winners;

    /*
     * winner comment 32 left
     */
    bytes32[] private _wincomma;

    /*
     * winner comment 32 right
     */
    bytes32[] private _wincommb;

    /*
     * winners positions
     */
    uint[] private _positions;

    /*
     * on which block we got a winner
     */
    uint[] private _blocks;

    /*
     * active round index
     */
    uint public _round;

    /*
     * active round queue pointer
     */
    uint public _counter;

    /*
     * allowed collectibles
     */
    uint private _collectibles = 0;

    /*
     * users history mapping
     */
    mapping(address => history) private _history;

    /**
     * get current round details
     */
    function currentRound() public view returns (uint round, uint counter, uint round_users, uint price) {
        return (_round, _counter, QMAX, PRICE_WEI);
    }

    /**
     * get round stats by index
     */
    function roundStats(uint index) public view returns (uint round, address winner, uint position, uint block_no) {
        return (index, _winners[index], _positions[index], _blocks[index]);
    }

    /**
     *
     * @dev get the total number of user subscriptions
     *
     * @param user the specific user
     *
     * @return user rounds size
     */
    function userRounds(address user) public view returns (uint) {
        return _history[user].size;
    }

    /**
     *
     * @dev get user subscription round number details
     *
     * @param user the specific user
     *
     * @param index the round number
     *
     * @return round no, user placing, user drop, user reward
     */
    function userRound(address user, uint index) public view returns (uint round, uint place, uint value, uint price) {
        history memory h = _history[user];
        return (h.rounds[index], h.places[index], h.values[index], h.prices[index]);
    }

    /**
     * round user subscription
     */
    function() public payable whenNotPaused {
        /*
         * check subscription price
         */
        require(msg.value >= PRICE_WEI, &#39;Insufficient Ether&#39;);

        /*
         * start round ahead: on QUEUE_MAX + 1
         * draw result
         */
        if (_counter == QMAX) {

            uint r = DMAX;

            uint winpos = 0;

            _blocks.push(block.number);

            bytes32 _a = blockhash(block.number - 1);

            for (uint i = 31; i >= 1; i--) {
                if (uint8(_a[i]) >= 48 && uint8(_a[i]) <= 57) {
                    winpos = 10 * winpos + (uint8(_a[i]) - 48);
                    if (--r == 0) break;
                }
            }

            _positions.push(winpos);

            /*
             * post out winner rewards
             */
            uint _reward = (QMAX * PRICE_WEI * 90) / 100;
            address _winner = _queue[winpos];

            _winners.push(_winner);
            _winner.transfer(_reward);

            /*
             * update round history
             */
            history storage h = _history[_winner];
            h.prices[h.size - 1] = _reward;

            /*
             * default winner blank comments
             */
            _wincomma.push(0x0);
            _wincommb.push(0x0);

            /*
             * log the win event: winpos is the proof, history trackable
             */
            emit NewWinner(_winner, _round, winpos, h.values[h.size - 1], _reward);

            /*
             * update collectibles
             */
            _collectibles += address(this).balance - _reward;

            /*
             * reset counter
             */
            _counter = 0;

            /*
             * increment round
             */
            _round++;
        }

        h = _history[msg.sender];

        /*
         * user is not allowed to subscribe twice
         */
        require(h.size == 0 || h.rounds[h.size - 1] != _round, &#39;Already In Round&#39;);

        /*
         * create user subscription: N.B. places[_round] is the result proof
         */
        h.size++;
        h.rounds.push(_round);
        h.places.push(_counter);
        h.values.push(msg.value);
        h.prices.push(0);

        /*
         * initial round is a push, others are &#39;on set&#39; index
         */
        if (_round == 0) {
            _queue.push(msg.sender);
        } else {
            _queue[_counter] = msg.sender;
        }

        /*
         * log subscription
         */
        emit NewDropIn(msg.sender, _round, _counter, msg.value);

        /*
         * increment counter
         */
        _counter++;
    }

    /**
     *
     * @dev let the user comment 64 letters for a winning round
     *
     * @param round the winning round
     *
     * @param a the first 32 letters comment
     *
     * @param b the second 32 letters comment
     *
     * @return user comment
     */
    function comment(uint round, bytes32 a, bytes32 b) whenNotPaused public {

        address winner = _winners[round];

        require(winner == msg.sender, &#39;not a winner&#39;);
        require(_history[winner].blacklist != FLAG_BLACKLIST, &#39;blacklisted&#39;);

        _wincomma[round] = a;
        _wincommb[round] = b;
    }


    /**
     *
     * @dev blacklist a user for its comments behavior
     *
     * @param user address
     *
     */
    function blackList(address user) public onlyOwner {
        history storage h = _history[user];
        if (h.size > 0) {
            h.blacklist = FLAG_BLACKLIST;
        }
    }

    /**
    *
    * @dev get the user win round comment
    *
    * @param round the winning round number
    *
    * @return user comment
    */
    function userComment(uint round) whenNotPaused public view returns (address winner, bytes32 comma, bytes32 commb) {
        if (_history[_winners[round]].blacklist != FLAG_BLACKLIST) {
            return (_winners[round], _wincomma[round], _wincommb[round]);
        } else {
            return (0x0, 0x0, 0x0);
        }
    }

    /*
     * etherdrop team R&D support collectibles
     */
    function collect() public onlyOwner {
        owner.transfer(_collectibles);
    }
}