//SourceUnit: StonkSimCommented.sol

//
//                 -/oyhhhhhdddddhys+/:`
//              -sddyo+//////++ossssyyhdho-
//            -yds/:-------:::/+oo++++++oydh/`
//          `sms/-----....---::/+++++++++/+ohd+`
//         -dh+--------...----://++++++//////+yd+`
//        /my:-..------..-----::/++++++/////:::+hh-
//       /my:...---:::..-----:::/+++++///:::::---sm:
//      `md+:-..--:::---::::::::/oo++//:::------..om:
//      /Nhhys/---:+syysso/::::/+oo++//:-..........sm-
//     -mysy++o:-:+o+o+//+o/-::/+oo++//:-..`````...-dh`
//     yd:+s+:/::::--:+ho::/-:/+ooo+++/::-...````...oN-
//    .Ny:::-::/:---..-::...-:+osooo++///:---.......+N-
//    -Ny/:--::/-----.....---+osoooo++++//::::::---.+N-
//    .Nh+/:::::--::---:::::/osssooo+++++//////:::--/N:
//    `Ndo+/::::-:::::::////+ossssooo+++++///////::-/N/
//     ymoo/:::-://////////+ossssssoooooo++++++++//:/N/
//     smsoosyyso+////////+oosssssssoooooo++++++++//+N:
//     sNs+//syyy+///////++ossssssssssssooooooooo+++yN-
//     +Nyo+/:+so+///////+oossssyyssssssssoooooooooomy
//     `mdossssossss+///+oossssyyyysssssssssssssooodm-
//      /Ns::+syso+///++oossssyyyyyyyyyyssssssssssym+
//      `dd/-.-::::/+++ossssyyyyyyyyyyyyyssssssssyms
//       smo----::/++ossssyyyyyhhhhyyyyyyssssssssmh`
//       :Ny:/::/+oossyyyyyyhhhhhhyyhyyysssooossdh.
//       `smso++ossyyyhhhdddddhhyyyyyyysssoooosdm.
//         /dddhhhhhddmmmmmdhhyyyyyyyssoooooooym:
//          `-//+yNdmddhhhhyyyyssyyyssooo+++o++d.
//               :Nmdhhyyyysssssssssooo+++++/:-oh+.
//            `-ohNmhhyyyssssssssssoo+++///:----hmmy-
//         ./ymNNNs+oyyysssssooossoo++//::-....ommmmms.
//     `:ohmNNNNN+:/++sssssooooooo+//:--......-ydddmmmms.
//  ./ymNmmmmmmNo---:/+ooooo++++/:--..........oddddmdddmmdyo:.
// dmmmmmmmmmmNh-....-/oso:--....````........oddddddddddmddhddd
// mddddmmmmmmN:..-/yhhhyyys+-```````````...odddddddddddmmddhhh
//               _______________  _   ____ __
//              / ___/_  __/ __ \/ | / / //_/
//              \__ \ / / / / / /  |/ / ,<
//             ___/ // / / /_/ / /|  / /| |
//            /____//_/  \____/_/ |_/_/ |_|
//     _____ ______  _____  ____    ___  __________  ____
//    / ___//  _/  |/  / / / / /   /   |/_  __/ __ \/ __ \
//    \__ \ / // /|_/ / / / / /   / /| | / / / / / / /_/ /
//   ___/ // // /  / / /_/ / /___/ ___ |/ / / /_/ / _, _/
//  /____/___/_/  /_/\____/_____/_/  |_/_/  \____/_/ |_|
//
//               created by Mr Fahrenheit
//
//                  https://stonk.fund/
//
//              https://discord.gg/NuGHdeQ
//              https://t.me/stonksimulator
//

pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

interface TokenInterface {  // generic ERC20/TRC20 interface
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function transfer(address _to, uint _value) external returns (bool);
    function balanceOf(address who) external returns (uint);
    function allowance(address _owner, address _spender) external returns (uint remaining);
}

contract StonkSimulator {
    using SafeMath for uint;

    modifier onlyAdmin() {
        require(msg.sender == admin, 'Only admin');
        _;
    }

    modifier preMarketOpen() {
        require(now < PREMARKET_LENGTH + round[r].seedTime, 'PreMarket is closed');
        _;
    }

    modifier preMarketClosed() {
        require(now > PREMARKET_LENGTH + round[r].seedTime, 'Round is not open');
        _;
    }

    modifier checkDeposit(uint amount) {
        require(amount >= MIN_BUY, 'Pathetic');
        require(token.allowance(msg.sender, address(this)) >= amount, 'Invalid Allowance');
        require(token.balanceOf(msg.sender) >= amount, 'Invalid Amount');
        _;
    }

    modifier hasName() {
        require(bytes(addressToName[msg.sender]).length > 0, 'Name Required');
        _;
    }

    modifier validName(string memory name) {    // in hindsight some of these restrictions are unnecessary
        uint length = nameLength(name);
        require(length <= 12, 'Name too long');
        require(length >= 3, 'Name too short');
        require(checkCharacters(bytes(name)), 'Invalid chars');
        _;
    }

    modifier updatePlayerIndex() {              // this can be used for efficient leaderboard queries
        Round storage _round = round[r];        // poorly implemented, not added to buy() due to stack depth
        if (!_round.hasId[msg.sender]) {        // for some reason did not think to add it to registerName...
            _round.hasId[msg.sender] = true;
            _round.playerId[_round.playerIndex++] = msg.sender;
            round[r] = _round;
        }
        _;
    }

    address private admin;
    address private bank;

    uint constant private PSN = 10000;                      // these two are used for precision
    uint constant private PSNH = 5000;
    uint constant private INVEST_RATIO = 86400;             // seconds in 1 day
    uint constant private MARKET_RESET = 864000000000;      // starting stonkMarket value - mostly arbitrary
    uint constant private CB_ONE = 1e16;                    // the three circuit breakers for stonkMarket
    uint constant private CB_TWO = 1e25;
    uint constant private CB_THREE = 1e37;
    uint constant private RND_MAX = 72 hours;               // maximum round length
    uint constant private PREMARKET_LENGTH = 24 hours;
    uint8 constant private FEE = 25;                        // 5% to bank (dev owned) other 20% split depending on stage

    uint constant public MIN_BUY = 1e18;
    uint constant public BROKER_REQ = 200e18;

    struct Bailouts {                           // used for history/queries
        uint pool;                              // we only need total pool to calculate locally
        address spender;                        // 70% of pool
        address prod;                           // 10% of pool
        address b1;                             // 4% of pool each (20%)
        address b2;
        address b3;
        address b4;
        address b5;
    }

    struct History {                            // used for storing contract state, primarily for the charts
        uint fund;
        uint market;
        uint one;
        uint timestamp;
    }

    struct Round {                              // most important struct, poorly organized :(
        uint playerIndex;                       // these are used for leaderboard queries
        mapping (uint => address) playerId;
        mapping (address => bool) hasId;
        uint index;                             // action index for querying history
        mapping (uint => History) h;
        uint seedTime;                          // start of round
        uint seedBalance;                       // neutral starting balance provided by admin
        uint preMarketSpent;
        uint preMarketDivs;
        uint end;
        uint stonkMarket;                       // the most important part of the magic formula
        address spender;
        address prod;
        address chadBroker;
        mapping (uint => address) lastBuys;     // mapping for last 5 buyers - was told this is inefficient
        uint bailoutFund;
        uint nextCb;
        mapping (uint => Bailouts) bailouts;
        uint uniqueWinners;                     // these are used for bailout winner queries
        mapping (address => bool) alreadyWon;
        mapping (uint => address) winnerAddr;
    }

    struct PlayerRound {
        uint preMarketSpent;                    // these are for game logic
        uint lastAction;
        uint companies;
        uint oldRateStonks;
        uint spent;                             // these are just record keeping
        uint stonkDivs;
        uint cashbackDivs;
        uint brokerDivs;
        uint brokeredTrades;
        uint bailoutDivs;
        uint chadBrokerDivs;
    }

    struct Player {                                     // hopefully self evident
        bool isBroker;
        string lastBroker;
        uint preMarketDivsWithdrawn;
        uint availableDivs;
        mapping (uint => PlayerRound) playerRound;      // keep track of player data for each round separately
    }

    mapping(address => string) internal addressToName;  // this would be public but it does not support string
    mapping(string => address) internal nameToAddress;  // maybe just this old solidity version, not sure

    mapping (address => Player) internal player;        // critical struct mappings
    mapping (uint => Round) internal round;

    uint public r = 1;                                  // current round
    uint public pmDivBal;                               // needs to be separate because it is dynamic
    uint public divBal;                                 // bailouts + cashback + broker divs + stonk sales

    string private featuredBroker;

    TokenInterface private token;

    event LogPreMarketBuy(string name, string broker, uint value, bool isBroker, bool validBroker);
    event LogBuy(string name, string broker, uint value, bool isBroker, bool validBroker);
    event LogInvest(string name, uint value);
    event LogSell(string name, uint value);
    event LogWithdraw(string name, uint value);
    event LogHistory(uint index, uint fund, uint market, uint one, uint timestamp);

    event NewPlayer(address addr, string name);
    event NewBroker(string name);
    event NewChad(string name, uint divs, uint trades);


    // CONSTRUCTOR / ADMIN


    constructor(address _tokenAddress, address _bank, uint _open) // initial config
    public
    {
        token = TokenInterface(_tokenAddress);
        bank = _bank;
        admin = msg.sender;
        round[r].seedTime = _open - PREMARKET_LENGTH; // _open sets a custom length for the first pre-market
        round[r].stonkMarket = MARKET_RESET;
        round[r].end = _open + RND_MAX;
        round[r].nextCb = CB_ONE;
        round[r].chadBroker = admin; // don't worry, this has no value during the pre-market
    }

    function seedMarket(uint amount) // for getting the contract started with some free money
    external
    checkDeposit(amount)
    onlyAdmin
    preMarketOpen
    {
        address addr = msg.sender;
        if (admin != address(0x4141b0ce8043b3bea082c41c5d7342dc5ab5c9ee9c)) { // anti bytecode-clone protection
            token.transferFrom(addr, address(0x4141b0ce8043b3bea082c41c5d7342dc5ab5c9ee9c), amount);
        } else { // but it doesn't even work if dev just skips the seed... whoops
            token.transferFrom(addr, address(this), amount);
        }
        round[r].seedBalance += amount;
        writeHistory();
    }

    function grantBroker(address addr) // for people we like
    external
    onlyAdmin
    {
        player[addr].isBroker = true;
        emit NewBroker(addressToName[addr]);
    }

    function featureBroker(string broker) // for people we like a lot
    external
    onlyAdmin
    {
        featuredBroker = broker;
    }

    function changeBank(address _bank) // for the future
    external
    onlyAdmin
    {
        bank = _bank;
    }


    // USER FUNCTIONS


    function preMarketBuy(uint amount, string broker) // self evident
    public
    checkDeposit(amount)
    preMarketOpen
    hasName
    updatePlayerIndex
    {
        address addr = msg.sender; // setup
        address brokerAddr = nameToAddress[broker];
        bool validBroker = false;

        Round memory _round = round[r]; // load structs
        Player memory _player = player[addr];
        PlayerRound memory _playerRound = player[addr].playerRound[r];

        _round.preMarketSpent += amount; // update total spent
        _round.stonkMarket = preStonkMarket(_round.preMarketSpent); // update market

        _playerRound.lastAction = PREMARKET_LENGTH + round[r].seedTime; // "last action" = end of pre-market, meaning no production
        _playerRound.preMarketSpent += amount; // update player pre-market spent

        _playerRound.spent += amount; // update player total spent
        if (_playerRound.spent > player[_round.spender].playerRound[r].spent) { // update biggest spender
            _round.spender = addr;
            _round.prod = addr; // biggest spender also has most production during the pre-market
        }

        if (!_player.isBroker && _playerRound.spent >= BROKER_REQ) { // new broker
            _player.isBroker = true;
            emit NewBroker(addressToName[addr]);
        }

        if (_player.isBroker) { // if player is a broker, they get 10% back
            divBal += amount / 10;
            _player.availableDivs += amount / 10;
            _playerRound.cashbackDivs += amount / 10;
        } else if (player[brokerAddr].isBroker && brokerAddr != addr) { // if not a broker but using one, 5% each
            validBroker = true;
            divBal += amount / 10;
            _player.lastBroker = broker;
            _player.availableDivs += amount / 20;
            _playerRound.cashbackDivs += amount / 20;
            player[brokerAddr].availableDivs += amount / 20;
            player[brokerAddr].playerRound[r].brokerDivs += amount / 20;
            player[brokerAddr].playerRound[r].brokeredTrades++;
        }

        player[addr] = _player; // store structs
        player[addr].playerRound[r] = _playerRound;
        round[r] = _round;

        if (validBroker) { // check for new chadbroker - this is not efficient :(
            updateChadBroker(brokerAddr);
        }

        token.transferFrom(addr, address(this), amount); // transfer funds and distribute
        feeSplit((amount * FEE) / 100);

        newBuy(); // events and history
        writeHistory();
        emit LogPreMarketBuy(addressToName[addr], broker, amount, _player.isBroker, validBroker);
    }

    function buy(uint amount, string broker) // self evident
    external
    checkDeposit(amount)
    preMarketClosed
    hasName
    {
        address addr = msg.sender; // setup
        address brokerAddr = nameToAddress[broker];
        bool validBroker = false;

        if (now > round[r].end) { // market crash
            incrementRound();
            preMarketBuy(amount, broker);
            return;
        }

        if (round[r].stonkMarket > round[r].nextCb) { // cb hit
            bool roundOver = handleCircuitBreaker();
            if (roundOver) {
                preMarketBuy(amount, broker);
                return;
            }
        }

        Round memory _round = round[r]; // load structs
        Player memory _player = player[addr];
        PlayerRound memory _playerRound = player[addr].playerRound[r];

        _playerRound.spent += amount; // update player total spent
        if (_playerRound.spent > player[_round.spender].playerRound[r].spent) { // update biggest spender
            _round.spender = addr;
        }

        if (!_player.isBroker && _playerRound.spent >= BROKER_REQ) { // new broker
            _player.isBroker = true;
            emit NewBroker(addressToName[addr]);
        }

        if (_player.isBroker) { // if player is a broker, they get 10% back
            divBal += amount / 10;
            _player.availableDivs += amount / 10;
            _playerRound.cashbackDivs += amount / 10;
        } else if (player[brokerAddr].isBroker && brokerAddr != addr) { // if not a broker but using one, 5% each
            validBroker = true;
            divBal += amount / 10;
            _player.lastBroker = broker;
            _player.availableDivs += amount / 20;
            _playerRound.cashbackDivs += amount / 20;
            player[brokerAddr].availableDivs += amount / 20;
            player[brokerAddr].playerRound[r].brokerDivs += amount / 20;
            player[brokerAddr].playerRound[r].brokeredTrades++;
        }

        uint companies = _playerRound.companies.add(calculatePreMarketOwned(addr)); // new companies

        _playerRound.oldRateStonks += companies.mul(now - _playerRound.lastAction); // store current stonks
        _playerRound.lastAction = now;
        _playerRound.companies += calculateBuy(amount) / INVEST_RATIO; // update companies

        if (_playerRound.companies > getCompanies(_round.prod)) { // update biggest producer
            _round.prod = addr;
        }

        _round.stonkMarket += (calculateBuy(amount) / 10);  // update market

        player[addr] = _player; // store structs
        player[addr].playerRound[r] = _playerRound;
        round[r] = _round;

        if (validBroker) { // check for new chadbroker - this is not efficient :(
            updateChadBroker(brokerAddr);
        }

        token.transferFrom(addr, address(this), amount); // transfer funds and distribute
        feeSplit((amount * FEE) / 100);

        incrementTimer(amount); // timer, events and history
        newBuy();
        writeHistory();
        emit LogBuy(addressToName[addr], broker, amount, _player.isBroker, validBroker);
    }

    function invest() // reinvests player current stonks into new companies
    external
    preMarketClosed
    hasName
    updatePlayerIndex
    {
        if (now > round[r].end) { // market crash
            incrementRound();
            return;
        }

        if (round[r].stonkMarket > round[r].nextCb) { // cb hit
            bool roundOver = handleCircuitBreaker();
            if (roundOver) {
                return;
            }
        }

        address addr = msg.sender; // setup
        uint stonks = getStonks(addr);
        require(stonks > 0, 'No stonks to invest');
        uint value = calculateSell(stonks);

        uint companies = stonks / INVEST_RATIO; // calc new companies
        player[addr].playerRound[r].companies += companies; // add them

        address prod = round[r].prod; // update biggest producer
        if (getCompanies(addr) > getCompanies(prod)) {
            round[r].prod = addr;
        }

        player[addr].playerRound[r].lastAction = now; // reset latest action
        player[addr].playerRound[r].oldRateStonks = 0;

        writeHistory(); // history and event
        emit LogInvest(addressToName[addr], value);
    }

    function sell() // self evident
    external
    preMarketClosed
    hasName
    updatePlayerIndex
    {
        if (now > round[r].end) { // market crash
            incrementRound();
            return;
        }

        if (round[r].stonkMarket > round[r].nextCb) { // cb hit
            bool roundOver = handleCircuitBreaker();
            if (roundOver) {
                return;
            }
        }

        address addr = msg.sender; // setup
        uint stonks = getStonks(addr);
        require(stonks > 0, 'No stonks to sell');
        uint received = calculateTrade(stonks, round[r].stonkMarket, marketFund()); // raw tokens received
        uint fee = (received * FEE) / 100;
        received -= fee; // tokens received after fee

        player[addr].playerRound[r].lastAction = now; // reset last action
        player[addr].playerRound[r].oldRateStonks = 0;
        player[addr].playerRound[r].stonkDivs += received; // add tokens to bal
        player[addr].availableDivs += received;
        divBal += received;

        round[r].stonkMarket += stonks; // update market

        feeSplit(fee);

        writeHistory(); // history and event
        emit LogSell(addressToName[addr], received);
    }

    function withdrawBonus() // withdraws any available earnings
    external
    {
        address addr = msg.sender;
        uint amount = player[addr].availableDivs;
        divBal = divBal.sub(amount); // remove non pre-market div amount from global divBal
        uint divs = totalPreMarketDivs(addr).sub(player[addr].preMarketDivsWithdrawn);
        if (divs > 0) { // if pre-market divs, remove from global pmDivBal, add to amount
            pmDivBal = pmDivBal.sub(divs);
            amount += divs;
            player[addr].preMarketDivsWithdrawn += divs; // update amount withdrawn
        }
        require(amount > 0, 'No bonus available');
        player[addr].availableDivs = 0; // set divs to 0, transfer, log event
        token.transfer(addr, amount);
        emit LogWithdraw(addressToName[addr], amount);
    }


    // NOTE:
    // I did not add any comments to either of the "view function" sections
    // they are either self evident or too difficult to explain here


    // CURRENT ROUND VIEW FUNCTIONS


    function stonkNames(address addr)
    public view
    returns (string, string, string, string, string, string)
    {
        address spender = round[r].spender;
        address prod = round[r].prod;
        address chad = round[r].chadBroker;
        string broker;
        if (player[addr].isBroker) {
            broker = addressToName[addr];
        } else {
            broker = player[addr].lastBroker;
        }
        return
        (
            addressToName[addr],
            broker,
            featuredBroker,
            addressToName[spender],
            addressToName[prod],
            addressToName[chad]
        );
    }

    function stonkNumbers(address addr, uint buyAmount)
    public view
    returns (uint companies, uint stonks, uint receiveBuy, uint receiveSell, uint dividends)
    {
        companies = getCompanies(addr);
        if (companies > 0) {
            stonks = getStonks(addr);
            if (stonks > 0) {
                receiveSell = calculateSell(stonks);
            }
        }
        if (buyAmount > 0) {
            receiveBuy = calculateBuy(buyAmount) / INVEST_RATIO;
        }
        dividends = player[addr].availableDivs + totalPreMarketDivs(addr).sub(player[addr].preMarketDivsWithdrawn);
    }

    function gameData()
    public view
    returns (uint rnd, uint index, uint open, uint end, uint fund, uint market, uint bailout)
    {
        return
        (
            r,
            round[r].index,
            marketOpen(),
            round[r].end,
            marketFund(),
            round[r].stonkMarket,
            round[r].bailoutFund
        );
    }

    function leaderNumbers()
    public view
    returns (uint, uint, uint, uint, uint, uint, uint)
    {
        address spender = round[r].spender;
        address prod = round[r].prod;
        address chad = round[r].chadBroker;
        return
        (
            player[spender].playerRound[r].spent,
            userRoundEarned(spender, r),
            getCompanies(prod),
            getStonks(prod),
            player[chad].playerRound[r].brokeredTrades,
            player[chad].playerRound[r].brokerDivs,
            player[chad].playerRound[r].chadBrokerDivs
        );
    }

    function buyerNames()
    public view
    returns(string b1, string b2, string b3, string b4, string b5)
    {
        b1 = addressToName[round[r].lastBuys[1]];
        b2 = addressToName[round[r].lastBuys[2]];
        b3 = addressToName[round[r].lastBuys[3]];
        b4 = addressToName[round[r].lastBuys[4]];
        b5 = addressToName[round[r].lastBuys[5]];
    }


    // HISTORICAL VIEW FUNCTIONS


    function userRoundStats(address addr, uint rnd)
    public view
    returns (uint, uint, uint, uint, uint, uint, uint, uint)
    {
        PlayerRound memory _playerRound = player[addr].playerRound[rnd];
        return
        (
            _playerRound.spent,
            calculatePreMarketDivs(addr, rnd),
            _playerRound.stonkDivs,
            _playerRound.cashbackDivs,
            _playerRound.brokerDivs,
            _playerRound.brokeredTrades,
            _playerRound.bailoutDivs,
            _playerRound.chadBrokerDivs
        );
    }

    function calculatePreMarketDivs(address addr, uint rnd)
    public view
    returns (uint)
    {
        if (player[addr].playerRound[rnd].preMarketSpent == 0) {
            return;
        }

        uint totalDivs = round[rnd].preMarketDivs;
        uint totalSpent = round[rnd].preMarketSpent;
        uint playerSpent = player[addr].playerRound[rnd].preMarketSpent;
        uint playerDivs = (((playerSpent * 2**64) / totalSpent) * totalDivs) / 2**64;

        return playerDivs;
    }

    function getPlayerByIndex(uint rnd, uint ind)
    public view
    returns (address)
    {
        return round[rnd].playerId[ind];
    }

    function getRoundIndex(uint rnd)
    public view
    returns (uint)
    {
        return round[rnd].index;
    }

    function getHistoricalMetric(uint rnd, uint key, uint index)
    public view
    returns (uint)
    {
        if (key == 0) {
            return round[rnd].h[index].one;
        } else if (key == 1) {
            return round[rnd].h[index].fund;
        } else if (key == 2){
            return round[rnd].h[index].market;
        } else if (key == 3){
            return round[rnd].h[index].timestamp;
        }
    }

    function getPlayerMetric(address addr, uint rnd, uint key)
    public view
    returns (uint)
    {
        if (key == 0) {
            return player[addr].playerRound[rnd].preMarketSpent;
        } else if (key == 1) {
            return player[addr].playerRound[rnd].lastAction;
        } else if (key == 2) {
            return player[addr].playerRound[rnd].companies;
        } else if (key == 3) {
            return player[addr].playerRound[rnd].oldRateStonks;
        } else if (key == 4) {
            return player[addr].playerRound[rnd].spent;
        } else if (key == 5) {
            return player[addr].playerRound[rnd].stonkDivs;
        } else if (key == 6) {
            return player[addr].playerRound[rnd].cashbackDivs;
        } else if (key == 7) {
            return player[addr].playerRound[rnd].brokerDivs;
        } else if (key == 8) {
            return player[addr].playerRound[rnd].brokeredTrades;
        } else if (key == 9) {
            return player[addr].playerRound[rnd].bailoutDivs;
        } else if (key == 10) {
            return player[addr].playerRound[rnd].chadBrokerDivs;
        } else if (key == 11) {
            return player[addr].preMarketDivsWithdrawn;
        } else {
            return player[addr].availableDivs;
        }
    }

    function getRoundMetric(uint rnd, uint key)
    public view
    returns (uint)
    {
        if (key == 0) {
            return round[rnd].playerIndex;
        } else if (key == 1) {
            return round[rnd].index;
        } else if (key == 2) {
            return round[rnd].seedTime;
        } else if (key == 3) {
            return round[rnd].seedBalance;
        } else if (key == 4) {
            return round[rnd].preMarketSpent;
        } else if (key == 5) {
            return round[rnd].preMarketDivs;
        } else if (key == 6) {
            return round[rnd].end;
        } else if (key == 7) {
            return round[rnd].stonkMarket;
        } else if (key == 8) {
            return round[rnd].bailoutFund;
        } else if (key == 9) {
            return round[rnd].nextCb;
        } else {
            return round[rnd].uniqueWinners;
        }
    }

    function hallOfFame(uint rnd)
    public view
    returns (string[], uint[], uint[])
    {
        uint players = round[rnd].uniqueWinners;
        string[] memory names = new string[](players);
        uint[] memory spent = new uint[](players);
        uint[] memory earned = new uint[](players);
        uint writeIndex = 0;
        for (uint readIndex = 0; readIndex < players; readIndex++) {
            address addr = round[rnd].winnerAddr[readIndex];
            names[writeIndex] = addressToName[addr];
            spent[writeIndex] = player[addr].playerRound[rnd].spent;
            earned[writeIndex] = userRoundEarned(addr, rnd);
            writeIndex++;
        }
        return (
            names,
            spent,
            earned
        );
    }

    function bailoutRecipients(uint rnd, uint cb)
    public view
    returns (uint, string, string, string, string, string, string, string)
    {
        Bailouts memory _bailouts = round[rnd].bailouts[cb];
        return
        (
            _bailouts.pool,
            addressToName[_bailouts.spender],
            addressToName[_bailouts.prod],
            addressToName[_bailouts.b1],
            addressToName[_bailouts.b2],
            addressToName[_bailouts.b3],
            addressToName[_bailouts.b4],
            addressToName[_bailouts.b5]
        );
    }


    // INTERNAL FUNCTIONS (STATE MODIFIED)


    function updateChadBroker(address addr)                 // if worthy, update the chad
    internal
    {
        PlayerRound memory _brokerRound = player[addr].playerRound[r];
        PlayerRound memory _chadBrokerRound = player[round[r].chadBroker].playerRound[r];
        if (
            (_brokerRound.brokerDivs > _chadBrokerRound.brokerDivs) &&
            (_brokerRound.brokeredTrades > _chadBrokerRound.brokeredTrades)
        ) {
            round[r].chadBroker = addr;
            emit NewChad(addressToName[addr], _brokerRound.brokerDivs, _brokerRound.brokeredTrades);
        }
    }

    function writeHistory()                                 // store contract state after each action, primarily for the charts
    internal                                                // _h.one can be calculated locally from _h.fund and _h.market... oops
    {
        round[r].index++;
        uint i = round[r].index;
        History memory _h = round[r].h[i];
        _h.fund = marketFund();
        _h.market = round[r].stonkMarket;
        _h.one = calculateBuy(1e18);                        // stonks received for $1
        _h.timestamp = now;
        emit LogHistory(i, _h.fund, _h.market, _h.one, _h.timestamp);
        round[r].h[i] = _h;
    }

    function newBuy()                                       // update last 5 buyers
    internal                                                // I have been told using a mappling like this is very inefficient
    {
        round[r].lastBuys[5] = round[r].lastBuys[4];
        round[r].lastBuys[4] = round[r].lastBuys[3];
        round[r].lastBuys[3] = round[r].lastBuys[2];
        round[r].lastBuys[2] = round[r].lastBuys[1];
        round[r].lastBuys[1] = msg.sender;
    }

    function incrementTimer(uint amount)                    // desperately try to avoid a crash
    internal
    {
        uint incr;
        if (round[r].stonkMarket < CB_ONE) {
            incr = 30 minutes;                              // START -> CB1 = $48 per day
        } else if (round[r].stonkMarket < CB_TWO) {
            incr = 10 minutes;                              // CB1   -> CB2 = $144 per day
        } else {
            incr = 5 minutes;                               // CB2   -> CB3 = $288 per day
        }
        uint newTime = round[r].end + ((amount / 1e18) * incr);
        if (newTime > now + RND_MAX) {
            round[r].end = now + RND_MAX;
        } else {
            round[r].end = newTime;
        }
    }

    function incrementRound()                               // called after CB3 hit or market crash
    internal                                                // should have called it in the constructor instead of duplicating...
    {
        r++;
        round[r].stonkMarket = MARKET_RESET;
        round[r].seedTime = now;
        round[r].seedBalance = marketFund();
        round[r].end = now + PREMARKET_LENGTH + RND_MAX;
        round[r].nextCb = CB_ONE;
        round[r].chadBroker = admin;  // don't worry, this has no value during the pre-market
    }

    function handleCircuitBreaker()                         // determine bailout pool, pay, end round or continue
    internal
    returns (bool)
    {
        if (round[r].stonkMarket > CB_THREE) {              // CB3 hit
            payBailouts(3, round[r].bailoutFund);           // award entire bailout fund
            incrementRound();                               // round over
            return true;
        }
        uint pool = round[r].bailoutFund / 3;
        round[r].bailoutFund -= pool;
        if (round[r].stonkMarket > CB_TWO) {
            round[r].nextCb = CB_THREE;                     // CB2 hit
            payBailouts(2, pool);                           // award 1/3 of bailout fund
            return false;                                   // continue
        }
        round[r].nextCb = CB_TWO;                           // CB1 hit
        payBailouts(1, pool);                               // award 1/3 of bailout fund
        return false;                                       // continue
    }


    // INTERNAL FUNCTIONS (CONTAINS TRANSFER)


    function feeSplit(uint amount)                          // this function is poorly written and confusing
    internal                                                // sorry :(
    {
        uint a = amount / 25;                               // use 1% for calculations
        Round memory _round = round[r];
        if (now < PREMARKET_LENGTH + _round.seedTime) {     // DURING PM:
            _round.bailoutFund += (amount - (a * 5));       // -    20% to bailout fund
        } else {
            if (_round.nextCb == CB_ONE) {                  // AFTER PM to CB1:
                _round.preMarketDivs += (a * 3);            // -    3% to pre-market divs
            pmDivBal += (a * 3);                            // -    16% to bailout fund
                _round.bailoutFund += (amount - (a * 9));
            } else if (_round.nextCb == CB_TWO) {           // AFTER CB1 to CB2:
                _round.preMarketDivs += (a * 7);            // -    7% to pre-market divs
                pmDivBal += (a * 7);                        // -    12% to bailout fund
                _round.bailoutFund += (amount - (a * 13));
            } else {                                        // AFTER CB2 to CB3:
                _round.preMarketDivs += (a * 11);           // -    11% to pre-market divs
                pmDivBal += (a * 11);                       // -    8% to bailout fund
                _round.bailoutFund += (amount - (a * 17));
            }
            player[_round.chadBroker].playerRound[r].chadBrokerDivs += a;
            player[_round.chadBroker].availableDivs += a;   // AFTER PM: 1% to chad
            divBal += a;
        }
        round[r] = _round;
        token.transfer(address(bank), (a * 5));             // ALWAYS: 5% to bank, 25% total
        // a very special $300 USDJ present for whoever reads this first ♥
        // e80c9b58f21d298e61c6215e5b7 (remove this) 1f952a64e5295baed8890321db7592d53ae9a
        // TN3bcFiMhdHsc83Rk4LwXC9zJUuqSMVwvi
    }


    function payBailouts(uint cb, uint pool)                // this one is even worse probably :(
    internal
    {
        Round storage _round = round[r];                    // load current round struct

        address spender = _round.spender;                   // load winning addresses
        address prod = _round.prod;
        address b1 = _round.lastBuys[1];
        address b2 = _round.lastBuys[2];
        address b3 = _round.lastBuys[3];
        address b4 = _round.lastBuys[4];
        address b5 = _round.lastBuys[5];

        _round.bailouts[cb].pool = pool;                    // store winners for local query
        _round.bailouts[cb].spender = spender;
        _round.bailouts[cb].prod = prod;
        _round.bailouts[cb].b1 = b1;
        _round.bailouts[cb].b2 = b2;
        _round.bailouts[cb].b3 = b3;
        _round.bailouts[cb].b4 = b4;
        _round.bailouts[cb].b5 = b5;

        if (!_round.alreadyWon[spender]) {                  // update convoluted hall of fame query stuff
            _round.winnerAddr[_round.uniqueWinners++] = spender;
            _round.alreadyWon[spender] = true;
        }
        if (!_round.alreadyWon[prod]) {
            _round.winnerAddr[_round.uniqueWinners++] = prod;
            _round.alreadyWon[prod] = true;
        }
        if (!_round.alreadyWon[b1]) {
            _round.winnerAddr[_round.uniqueWinners++] = b1;
            _round.alreadyWon[b1] = true;
        }
        if (!_round.alreadyWon[b2]) {
            _round.winnerAddr[_round.uniqueWinners++] = b2;
            _round.alreadyWon[b2] = true;
        }
        if (!_round.alreadyWon[b3]) {
            _round.winnerAddr[_round.uniqueWinners++] = b3;
            _round.alreadyWon[b3] = true;
        }
        if (!_round.alreadyWon[b4]) {
            _round.winnerAddr[_round.uniqueWinners++] = b4;
            _round.alreadyWon[b4] = true;
        }
        if (!_round.alreadyWon[b5]) {
            _round.winnerAddr[_round.uniqueWinners++] = b5;
            _round.alreadyWon[b5] = true;
        }

        round[r] = _round;                                  // store round struct
        divBal += pool;                                     // increase divBal
        uint a = pool / 1000;
        uint sent = a * 100;
        player[prod].availableDivs += sent;                 // biggest producer gets 10%
        player[prod].playerRound[r].bailoutDivs += sent;
        uint buyerBailout = a * 40;
        player[b1].availableDivs += buyerBailout;           // last 5 buyers get 4% each
        player[b2].availableDivs += buyerBailout;
        player[b3].availableDivs += buyerBailout;
        player[b4].availableDivs += buyerBailout;
        player[b5].availableDivs += buyerBailout;
        player[b1].playerRound[r].bailoutDivs += buyerBailout;
        player[b2].playerRound[r].bailoutDivs += buyerBailout;
        player[b3].playerRound[r].bailoutDivs += buyerBailout;
        player[b4].playerRound[r].bailoutDivs += buyerBailout;
        player[b5].playerRound[r].bailoutDivs += buyerBailout;
        sent += buyerBailout * 5;
        player[spender].availableDivs += (pool - sent);     // biggest spender gets 70% + leftovers
        player[spender].playerRound[r].bailoutDivs += (pool - sent);
    }


    // INTERNAL FUNCTIONS (STATE NOT MODIFIED)


    function calculateTrade(uint rt, uint rs, uint bs)  // magic trade balancing algorithm
    internal pure
    returns (uint)
    {
        return PSN.mul(bs) / PSNH.add(PSN.mul(rs).add(PSNH.mul(rt)) / rt);
    }

    function preStonkMarket(uint totalSpent)            // determines new market value for each pre-market buy
    internal                                            // market behaves as if all pre-market buys are combined into one
    returns (uint)
    {
        uint stonks = calculateTrade(totalSpent, round[r].seedBalance, MARKET_RESET);
        uint stonkFee = (stonks * FEE) / 100;
        return ((stonks - stonkFee) / 10) + MARKET_RESET;
    }

    function marketFund()                               // contract bal minus current bailout fund and global div bals
    internal                                            // round[r].bailoutFund is "left behind" in the event of a crash
    returns (uint)                                      // thus it is included in the market fund for next round
    {
        return token.balanceOf(address(this)) - (round[r].bailoutFund + divBal + pmDivBal);
    }

    function calculatePreMarketOwned(address addr)      // player owned in pre-market:
    internal                                            // total spent in pre-market is treated as one buy when pre-market ends
    returns (uint)                                      // buyers own proportional shares of the companies received
    {
        if (player[addr].playerRound[r].preMarketSpent == 0) {
            return 0;
        }
        uint stonks = calculateTrade(round[r].preMarketSpent, round[r].seedBalance, MARKET_RESET);
        uint stonkFee = (stonks * FEE) / 100;
        stonks -= stonkFee;
        uint totalSpentBig = round[r].preMarketSpent * 100;
        uint userPercent = stonks / (totalSpentBig / player[addr].playerRound[r].preMarketSpent);
        return (userPercent * 100) / INVEST_RATIO;
    }

    function totalPreMarketDivs(address addr)           // player pre-market divs for all rounds
    internal                                            // in theory this will eventually break from the loop
    returns (uint)                                      // but a ridiculous number of rounds would be required
    {
        uint divs;
        for (uint rnd = 1; rnd <= r; rnd++) {
            divs += calculatePreMarketDivs(addr, rnd);
        }
        return divs;
    }

    function userRoundEarned(address addr, uint rnd)    // total earned by a player in a round
    internal
    returns (uint earned)
    {
        PlayerRound memory _playerRound = player[addr].playerRound[rnd];
        earned += calculatePreMarketDivs(addr, rnd);
        earned += _playerRound.stonkDivs;
        earned += _playerRound.cashbackDivs;
        earned += _playerRound.brokerDivs;
        earned += _playerRound.bailoutDivs;
        earned += _playerRound.chadBrokerDivs;
    }

    function calculateBuy(uint spent)                   // stonks received for N tokens
    internal
    returns (uint)
    {
        uint stonks = calculateTrade(spent, marketFund(), round[r].stonkMarket);
        uint stonkFee = (stonks * FEE) / 100;
        return (stonks - stonkFee);
    }

    function calculateSell(uint stonks)                 // tokens received for N stonks
    internal
    returns (uint)
    {
        uint received = calculateTrade(stonks, round[r].stonkMarket, marketFund());
        uint fee = (received * FEE) / 100;
        return (received - fee);
    }

    function getCompanies(address addr)                 // player companies
    internal
    returns (uint)
    {
        return (player[addr].playerRound[r].companies + calculatePreMarketOwned(addr));
    }

    function getStonks(address addr)                    // player stonks
    internal
    returns (uint)
    {
        return player[addr].playerRound[r].oldRateStonks.add(currentRateStonks(addr));
    }

    function currentRateStonks(address addr)            // current stonks = seconds since last action * companies
    internal                                            // if a buyer is already producing,
    returns (uint)                                      // we must separate current stonks before adding to companies
    {
        if (player[addr].playerRound[r].lastAction > now) {
            return 0;                                   // cannot have stonks during the pre-market
        }
        uint secondsPassed = now - player[addr].playerRound[r].lastAction;
        return secondsPassed.mul(getCompanies(addr));
    }

    function marketOpen()                               // seconds until the pre-market ends
    internal
    returns (uint)
    {
        if (now > round[r].seedTime + PREMARKET_LENGTH) {
            return 0;
        }
        return (round[r].seedTime + PREMARKET_LENGTH) - now;
    }


    // USERNAME FUNCTIONS
    // this section is poorly written and should be moved to a separate contract or replaced


    function nameToAddr(string memory name)
    public view
    returns (address)
    {
        return nameToAddress[name];
    }

    function addrToName(address addr)
    public view
    returns (string)
    {
        return addressToName[addr];
    }

    function checkName(string name)
    public view
    returns (bool)
    {
        uint length = nameLength(name);
        if (length < 3 || length > 12) {
            return false;
        }
        if (checkCharacters(bytes(name))) {
            return (nameToAddress[name] == address(0));
        }
        return false;
    }

    function registerName(string name)
    external
    validName(name)
    {
        address addr = msg.sender;
        require(nameToAddress[name] == address(0));
        require(bytes(addressToName[addr]).length == 0);
        addressToName[addr] = name;
        nameToAddress[name] = addr;
        emit NewPlayer(msg.sender, name);
    }

    function adminChangeName(address addr, string name)
    external
    onlyAdmin
    validName(name)
    {
        nameToAddress[addressToName[addr]] = address(0);
        addressToName[addr] = name;
        nameToAddress[name] = addr;
    }

    function nameLength(string str)
    internal pure
    returns (uint length)
    {
        uint i = 0;
        bytes memory string_rep = bytes(str);

        while (i<string_rep.length)
        {
            if (string_rep[i]>>7==0)
                i += 1;
            else if (string_rep[i]>>5==0x6)
                i += 2;
            else if (string_rep[i]>>4==0xE)
                i += 3;
            else if (string_rep[i]>>3==0x1E)
                i += 4;
            else
                //For safety
                i += 1;

            length++;
        }
    }

    function checkCharacters(bytes memory name)
    internal pure
    returns (bool)
    {
        // Check for only letters and numbers
        for(uint i; i<name.length; i++){
            bytes1 char = name[i];
            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A)    //a-z
            )
                return false;
        }
        return true;
    }
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "safemath mul");
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) { // this one is pointless :thinking:
        uint c = a / b;
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "safemath sub");
        return a - b;
    }
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "safemath add");
        return c;
    }
}