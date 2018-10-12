pragma solidity 0.4.24;

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract SafeMath {
    function multiplication(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function division(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function subtraction(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function addition(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

contract LottoEvents {
    event BuyTicket(uint indexed _gameIndex, address indexed from, bytes numbers, uint _prizePool, uint _bonusPool);
    event LockRound(uint indexed _gameIndex, uint _state, uint indexed _blockIndex);
    event DrawRound(uint indexed _gameIndex, uint _state, uint indexed _blockIndex, string _blockHash, uint[] _winNumbers);
    event EndRound(uint indexed _gameIndex, uint _state, uint _jackpot, uint _bonusAvg, address[] _jackpotWinners, address[] _goldKeyWinners, bool _autoStartNext);
    event NewRound(uint indexed _gameIndex, uint _state, uint _initPrizeIn);
    event DumpPrize(uint indexed _gameIndex, uint _jackpot);
    event Transfer(uint indexed _gameIndex, uint value);
    event Activated(uint indexed _gameIndex);
    event Deactivated(uint indexed _gameIndex);
    event SelfDestroy(uint indexed _gameIndex);
}

library LottoModels {

    // data struct hold each ticket info
    struct Ticket {
        uint rId;           // round identity
        address player;     // the buyer
        uint btime;         // buy time
        uint[] numbers;     // buy numbers, idx 0,1,2,3,4 are red balls, idx 5 are blue balls
        bool joinBonus;     // join bonus ?
        bool useGoldKey;    // use gold key ?
    }

    // if round ended, each state is freeze, just for view
    struct Round {
        uint rId;            // current id
        uint stime;          // start time
        uint etime;          // end time
        uint8 state;         // 0: live, 1: locked, 2: drawed, 7: ended

        uint[] winNumbers;   // idx 0,1,2,3,4 are red balls, idx 5 are blue balls
        address[] winners;   // the winner&#39;s addresses

        uint ethIn;          // how much eth in this Round
        uint prizePool;      // how much eth in prize pool, 40% of ethIn add init prize in
        uint bonusPool;      // how much eth in bonus pool, 40% of ethIn
        uint teamFee;        // how much eth to team, 20% of ethIn

        uint btcBlockNoWhenLock; // the btc block no when lock this round
        uint btcBlockNo;         // use for get win numbers, must higer than btcBlockNoWhenLock;
        string btcBlockHash;     // use for get win numbers

        uint bonusAvg;       // average bouns price for players
        uint jackpot;        // the jackpot to pay
        uint genGoldKeys;    // how many gold key gens
    }
}

contract Lottery is Owned, SafeMath, LottoEvents {
    string constant version = "1.0.1";

    uint constant private GOLD_KEY_CAP = 1500 ether;
    uint constant private BUY_LIMIT_CAP = 100;
    uint8 constant private ROUND_STATE_LIVE = 0;
    uint8 constant private ROUND_STATE_LOCKED = 1;
    uint8 constant private ROUND_STATE_DRAWED = 2;
    uint8 constant private ROUND_STATE_ENDED = 7;

    mapping (uint => LottoModels.Round) public rounds;       // all rounds, rid -> round
    mapping (uint => LottoModels.Ticket[]) public tickets;   // all tickets, rid -> ticket array
    mapping (address => uint) public goldKeyRepo;            // all gold key repo, keeper address -> key count
    address[] private goldKeyKeepers;                           // all gold key keepers, just for clear mapping?!

    uint public goldKeyCounter = 0;               // count for gold keys
    uint public unIssuedGoldKeys = 0;             // un issued gold keys
    uint public price = 0.03 ether;               // the price for each bet
    bool public activated = false;                // contract live?
    uint public rId;                              // current round id

    constructor() public {
        rId = 0;
        activated = true;
        internalNewRound(0, 0); // init with prize 0, bonus 0
    }

    // buy ticket
    // WARNING!!!solidity only allow 16 local variables
    function()
        isHuman()
        isActivated()
        public
        payable {

        require(owner != msg.sender, "owner cannot buy.");
        require(address(this) != msg.sender, "contract cannot buy.");
        require(rounds[rId].state == ROUND_STATE_LIVE,  "this round not start yet, please wait.");
        // data format check
        require(msg.data.length > 9,  "data struct not valid");
        require(msg.data.length % 9 == 1, "data struct not valid");
        // price check
        require(uint(msg.data[0]) < BUY_LIMIT_CAP, "out of buy limit one time.");
        require(msg.value == uint(msg.data[0]) * price, "price not right, please check.");


        uint i = 1;
        while(i < msg.data.length) {
            // fill data
            // [0]: how many
            // [1]: how many gold key use?
            // [2]: join bonus?
            // [3-7]: red balls, [8]: blue ball
            uint _times = uint(msg.data[i++]);
            uint _goldKeys = uint(msg.data[i++]);
            bool _joinBonus = uint(msg.data[i++]) > 0;
            uint[] memory _numbers = new uint[](6);
            for(uint j = 0; j < 6; j++) {
                _numbers[j] = uint(msg.data[i++]);
            }

            // every ticket
            for (uint k = 0; k < _times; k++) {
                bool _useGoldKey = false;
                if (_goldKeys > 0 && goldKeyRepo[msg.sender] > 0) { // can use gold key?
                    _goldKeys--; // reduce you keys you want
                    goldKeyRepo[msg.sender]--; // reduce you keys in repo
                    _useGoldKey = true;
                }
                tickets[rId].push(LottoModels.Ticket(rId, msg.sender,  now, _numbers, _joinBonus, _useGoldKey));
            }
        }

        // update round data
        rounds[rId].ethIn = addition(rounds[rId].ethIn, msg.value);
        uint _amount = msg.value * 4 / 10;
        rounds[rId].prizePool = addition(rounds[rId].prizePool, _amount); // 40% for prize
        rounds[rId].bonusPool = addition(rounds[rId].bonusPool, _amount); // 40% for bonus
        rounds[rId].teamFee = addition(rounds[rId].teamFee, division(_amount, 2));   // 20% for team
        // check gen gold key?
        internalIncreaseGoldKeyCounter(_amount);

        emit BuyTicket(rId, msg.sender, msg.data, rounds[rId].prizePool, rounds[rId].bonusPool);
    }


    // core logic
    //
    // 1. lock the round, can&#39;t buy this round
    // 2. on-chain calc win numbuers
    // 3. off-chain calc jackpot, jackpot winners, goldkey winners, average bonus, blue number hits not share bonus.
    // if compute on-chain, out of gas
    // 4. end this round

    // 1. lock the round, can&#39;t buy this round
    function lockRound(uint btcBlockNo)
    isActivated()
    onlyOwner()
    public {
        require(rounds[rId].state == ROUND_STATE_LIVE, "this round not live yet, no need lock");
        rounds[rId].btcBlockNoWhenLock = btcBlockNo;
        rounds[rId].state = ROUND_STATE_LOCKED;
        emit LockRound(rId, ROUND_STATE_LOCKED, btcBlockNo);
    }

    // 2. on-chain calc win numbuers
    function drawRound(
        uint  btcBlockNo,
        string  btcBlockHash
    )
    isActivated()
    onlyOwner()
    public {
        require(rounds[rId].state == ROUND_STATE_LOCKED, "this round not locked yet, please lock it first");
        require(rounds[rId].btcBlockNoWhenLock < btcBlockNo,  "the btc block no should higher than the btc block no when lock this round");

        // calculate winner
        rounds[rId].winNumbers = calcWinNumbers(btcBlockHash);
        rounds[rId].btcBlockHash = btcBlockHash;
        rounds[rId].btcBlockNo = btcBlockNo;
        rounds[rId].state = ROUND_STATE_DRAWED;

        emit DrawRound(rId, ROUND_STATE_DRAWED, btcBlockNo, btcBlockHash, rounds[rId].winNumbers);
    }

    // 3. off-chain calc
    // 4. end this round
    function endRound(
        uint jackpot,
        uint bonusAvg,
        address[] jackpotWinners,
        address[] goldKeyWinners,
        bool autoStartNext
    )
    isActivated()
    onlyOwner()
    public {
        require(rounds[rId].state == ROUND_STATE_DRAWED, "this round not drawed yet, please draw it first");

        // end this round
        rounds[rId].state = ROUND_STATE_ENDED;
        rounds[rId].etime = now;
        rounds[rId].jackpot = jackpot;
        rounds[rId].bonusAvg = bonusAvg;
        rounds[rId].winners = jackpotWinners;

        // if jackpot is this contract addr or owner addr, delete it

        // if have winners, all keys will gone.
        if (jackpotWinners.length > 0 && jackpot > 0) {
            unIssuedGoldKeys = 0; // clear un issued gold keys
            // clear players gold key
            // no direct delete mapping in solidity
            // we give an array to store gold key keepers
            // clearing mapping from key keepers
            // delete keepers
            for (uint i = 0; i < goldKeyKeepers.length; i++) {
                goldKeyRepo[goldKeyKeepers[i]] = 0;
            }
            delete goldKeyKeepers;
        } else {
            // else reward gold keys
            if (unIssuedGoldKeys > 0) {
                for (uint k = 0; k < goldKeyWinners.length; k++) {
                    // update repo
                    address _winner = goldKeyWinners[k];

                    // except this address
                    if (_winner == address(this)) {
                        continue;
                    }

                    goldKeyRepo[_winner]++;

                    // update keepers
                    bool _hasKeeper = false;
                    for (uint j = 0; j < goldKeyKeepers.length; j++) {
                        if (goldKeyKeepers[j] == _winner) {
                            _hasKeeper = true;
                            break;
                        }
                    }
                    if (!_hasKeeper) { // no keeper? push it in.
                        goldKeyKeepers.push(_winner);
                    }

                    unIssuedGoldKeys--;
                    if (unIssuedGoldKeys <= 0) { // no more gold keys, let&#39;s break;
                        break;
                    }

                }
            }
            // move this round gen gold key to un issued gold keys
            unIssuedGoldKeys = addition(unIssuedGoldKeys, rounds[rId].genGoldKeys);
        }

        emit EndRound(rId, ROUND_STATE_ENDED, jackpot, bonusAvg, jackpotWinners, goldKeyWinners, autoStartNext);
        // round ended

        // start next?
        if (autoStartNext) {
            newRound();
        }
    }

    function newRound()
    isActivated()
    onlyOwner()
    public {
        // check this round is ended?
        require(rounds[rId].state == ROUND_STATE_ENDED, "this round not ended yet, please end it first");

        // lets start next round
        // calculate prize to move, (prize pool - jackpot to pay)
        uint _initPrizeIn = subtraction(rounds[rId].prizePool, rounds[rId].jackpot);
        // move bonus pool, if no one share bonus(maybe)
        uint _initBonusIn = rounds[rId].bonusPool;
        if (rounds[rId].bonusAvg > 0) { // if someone share bonus, bonusAvg > 0, move 0
            _initBonusIn = 0;
        }
        // move to new round
        internalNewRound(_initPrizeIn, _initBonusIn);

        emit NewRound(rId, ROUND_STATE_LIVE, _initPrizeIn);
    }

    function internalNewRound(uint _initPrizeIn, uint _initBonusIn) internal {
        rId++;
        rounds[rId].rId = rId;
        rounds[rId].stime = now;
        rounds[rId].state = ROUND_STATE_LIVE;
        rounds[rId].prizePool = _initPrizeIn;
        rounds[rId].bonusPool = _initBonusIn;
    }
    
    function internalIncreaseGoldKeyCounter(uint _amount) internal {
        goldKeyCounter = addition(goldKeyCounter, _amount);
        if (goldKeyCounter >= GOLD_KEY_CAP) {
            rounds[rId].genGoldKeys = addition(rounds[rId].genGoldKeys, 1);
            goldKeyCounter = subtraction(goldKeyCounter, GOLD_KEY_CAP);
        }
    }

    // utils
    function calcWinNumbers(string blockHash)
    public
    pure
    returns (uint[]) {
        bytes32 random = keccak256(bytes(blockHash));
        uint[] memory allRedNumbers = new uint[](40);
        uint[] memory allBlueNumbers = new uint[](10);
        uint[] memory winNumbers = new uint[](6);
        for (uint i = 0; i < 40; i++) {
            allRedNumbers[i] = i + 1;
            if(i < 10) {
                allBlueNumbers[i] = i;
            }
        }
        for (i = 0; i < 5; i++) {
            uint n = 40 - i;
            uint r = (uint(random[i * 4]) + (uint(random[i * 4 + 1]) << 8) + (uint(random[i * 4 + 2]) << 16) + (uint(random[i * 4 + 3]) << 24)) % (n + 1);
            winNumbers[i] = allRedNumbers[r];
            allRedNumbers[r] = allRedNumbers[n - 1];
        }
        uint t = (uint(random[i * 4]) + (uint(random[i * 4 + 1]) << 8) + (uint(random[i * 4 + 2]) << 16) + (uint(random[i * 4 + 3]) << 24)) % 10;
        winNumbers[5] = allBlueNumbers[t];
        return winNumbers;
    }

    // for views
    function getKeys() public view returns(uint) {
        return goldKeyRepo[msg.sender];
    }
    
    function getRoundByRId(uint _rId)
    public
    view
    returns (uint[] res){
        if(_rId > rId) return res;
        res = new uint[](18);
        uint k;
        res[k++] = _rId;
        res[k++] = uint(rounds[_rId].state);
        res[k++] = rounds[_rId].ethIn;
        res[k++] = rounds[_rId].prizePool;
        res[k++] = rounds[_rId].bonusPool;
        res[k++] = rounds[_rId].teamFee;
        if (rounds[_rId].winNumbers.length == 0) {
            for (uint j = 0; j < 6; j++)
                res[k++] = 0;
        } else {
            for (j = 0; j < 6; j++)
                res[k++] = rounds[_rId].winNumbers[j];
        }
        res[k++] = rounds[_rId].bonusAvg;
        res[k++] = rounds[_rId].jackpot;
        res[k++] = rounds[_rId].genGoldKeys;
        res[k++] = rounds[_rId].btcBlockNo;
        res[k++] = rounds[_rId].stime;
        res[k++] = rounds[_rId].etime;
    }

    // --- danger ops ---

    // angel send luck for players
    function dumpPrize()
    isActivated()
    onlyOwner()
    public
    payable {
        require(rounds[rId].state == ROUND_STATE_LIVE, "this round not live yet.");
        rounds[rId].ethIn = addition(rounds[rId].ethIn, msg.value);
        rounds[rId].prizePool = addition(rounds[rId].prizePool, msg.value);
        // check gen gold key?
        internalIncreaseGoldKeyCounter(msg.value);
        emit DumpPrize(rId, msg.value);
    }

    function activate() public onlyOwner {
        activated = true;
        emit Activated(rId);
    }

    function deactivate() public onlyOwner {
        activated = false;
        emit Deactivated(rId);
    }

    function selfDestroy() public onlyOwner {
        selfdestruct(msg.sender);
        emit SelfDestroy(rId);
    }

    function transferToOwner(uint amount) public payable onlyOwner {
        msg.sender.transfer(amount);
        emit Transfer(rId, amount);
    }
    // --- danger ops end ---

    // modifiers
    modifier isActivated() {
        require(activated == true, "its not ready yet.");
        _;
    }

    modifier isHuman() {
        address _addr = msg.sender;
        require (_addr == tx.origin);

        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
}