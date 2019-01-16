pragma solidity ^0.4.24;

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y)
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }

    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }

    /**
     * @dev x to the power of y
     */
    function pwr(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}

library NameFilter {
    /**
     * @dev filters name strings
     * -converts uppercase to lower case.
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
     * -cannot be only numbers
     * -cannot start with 0x
     * -restricts characters to A-Z, a-z, 0-9, and space.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

        //sorry limited to 32 characters
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

        // create a bool to track if we have a non number character
        bool _hasNonNumber;

        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint(_temp[i]) + 32);

                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                    // require character is a space
                    _temp[i] == 0x20 ||
                    // OR lowercase a-z
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    // or 0-9
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");

                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true, "string cannot be only numbers");

        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

library ImkgKeysCalc {
    using SafeMath for *;

    // 根据现有ETH，计算新入X个ETH能购买的Keys数量
    function keysRec(uint256 _curEth, uint256 _newEth)
        internal
        pure
        returns (uint256)
    {
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }

    // 根据当前Keys数量，计算卖出X数量的keys值多少ETH
    function ethRec(uint256 _curKeys, uint256 _sellKeys)
        internal
        pure
        returns (uint256)
    {
        return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }

    // 根据池中ETH数量计算对应的Keys数量
    function keys(uint256 _eth)
        internal
        pure
        returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000000);
    }

    // 根据Keys数量，计算池中ETH的数量
    function eth(uint256 _keys)
        internal
        pure
        returns(uint256)
    {
        return ((78125000000000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000000))) / (2))) / ((1000000000000000000).sq());
    }
}

contract Imkg {
    using SafeMath for *;
    using NameFilter for string;
    using ImkgKeysCalc for uint256;

    //**************
    // EVENTS
    //**************

    // fired player registers a new name
    event onNewNameEvent
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        bool isNewPlayer,
        uint256 amountPaid,
        uint256 timeStamp
    );

    // fired leader sets a new team name
    event onNewTeamNameEvent
    (
        uint256 indexed teamID,
        bytes32 indexed teamName,
        uint256 indexed playerID,
        bytes32 playerName,
        uint256 amountPaid,
        uint256 timeStamp
    );

    // fired when buy the bomb
    event onTxEvent
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 teamID,
        bytes32 teamName,
        uint256 ethIn,
        uint256 keysBought
    );

    // fired a bonus to invitor when a invited pays
    event onAffPayoutEvent
    (
        uint256 indexed affID,
        address affAddress,
        bytes32 affName,
        uint256 indexed roundID,
        uint256 indexed buyerID,
        uint256 amount,
        uint256 timeStamp
    );

    // fired an out event
    event onOutEvent
    (
        uint256 deadCount,
        uint256 liveCount,
        uint256 deadKeys
    );

    // fired end event when game is over
    event onEndRoundEvent
    (
        uint256 winnerTID,  // winner
        bytes32 winnerTName,
        uint256 playersCount,
        uint256 eth    // eth in pot
    );

    // fired when withdraw
    event onWithdrawEvent
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timeStamp
    );

    // fired out initial event
    event onOutInitialEvent
    (
        uint256 outTime
    );

    //**************
    // DATA
    //**************

    // player info
    struct Player {
        address addr;   //  player address
        bytes32 name;
        uint256 gen;    // balance
        uint256 aff;    // balance for invite
        uint256 laff;   // the latest invitor. ID
    }

    // player info in every round
    struct PlayerRounds {
        uint256 eth;    // all eths in current round
        mapping (uint256 => uint256) plyrTmKeys;    // teamid => keys
        bool withdrawn;     // if earnings are withdrawn in current round
    }

    // team info
    struct Team {
        uint256 id;     // team id
        bytes32 name;    // team name
        uint256 keys;   // key s in the team
        uint256 eth;   // eth from the team
        uint256 price;    // price of the last key (only for view)
        uint256 playersCount;   // how many team members
        uint256 leaderID;   // leader pID (leader is always the top 1 player in the team)
        address leaderAddr;  // leader address
        bool dead;  // if team is out
    }

    // round info
    struct Round {
        uint256 start;  // start time
        uint256 state;  // 0:inactive,1:prepare,2:out,3:end
        uint256 eth;    // all eths
        uint256 pot;    // amount of this pot
        uint256 keys;   // all keys
        uint256 team;   // first team ID
        uint256 ethPerKey;  // how many eth per key in Winner Team. (must after the game)
        uint256 lastOutTime;   // the last out emit time
        uint256 deadRate;   // current dead rate (first team all keys * rate = dead line)
        uint256 deadKeys;   // next dead line
        uint256 liveTeams;  // alive teams
        uint256 tID_;    // how many teams in this Round
    }

    //****************
    // GAME SETTINGS
    //****************
    string constant public name = "The King God";
    string constant public symbol = "IMKG";
    address public owner;
    address public cooperator;
    uint256 public minTms_ = 3;    //minimum team number for active limit
    uint256 public maxTms_ = 12;    // maximum team number
    uint256 public roundGap_ = 120;    // round gap: 2 mins
    uint256 public OutGap_ = 600;   // out gap: 12 hours
    uint256 constant private registrationFee_ = 10 finney;    // fee for register a new name

    //****************
    // PLAYER DATA
    //****************
    uint256 public pID_;    // all players
    mapping (address => uint256) public pIDxAddr_;  // (addr => pID) returns player id by address
    mapping (bytes32 => uint256) public pIDxName_;  // (name => pID) returns player id by name
    mapping (uint256 => Player) public plyr_;   // (pID => data) player data

    //****************
    // ROUND DATA
    //****************
    uint256 public rID_;    // current round ID
    mapping (uint256 => Round) public round_;   // round ID => round data

    // Player Rounds
    mapping (uint256 => mapping (uint256 => PlayerRounds)) public plyrRnds_;  // player ID => round ID => player info

    //****************
    // TEAM DATA
    //****************
    mapping (uint256 => mapping (uint256 => Team)) public rndTms_;  // round ID => team ID => team info
    mapping (uint256 => mapping (bytes32 => uint256)) public rndTIDxName_;  // (rID => team name => tID) returns team id by name

    // =============
    // CONSTRUCTOR
    // =============

    constructor() public {
        owner = msg.sender;
        cooperator = address(0x8fccb08b8c4e6f4a3500Af33c45b28BF5290CFbC);
    }

    // =============
    // MODIFIERS
    // =============

    // only developer
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev used to make sure no one can interact with contract until it has
     * been activated.
     */
    modifier isActivated() {
        require(activated_ == true, "its not ready yet.");
        _;
    }

    /**
     * @dev prevents contracts from interacting with imkg
     */
    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }

    /**
     * @dev sets boundaries for incoming tx
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "no less than 1 Gwei");
        require(_eth <= 100000000000000000000000, "no more than 100000 ether");
        _;
    }

    // **************=======
    // PUBLIC INTERACTION
    // **************=======

    /**
     * @dev emergency buy uses last stored affiliate ID and the first team
     */
    function()
        public
        payable
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
    {
        buy(round_[rID_].team, "imkg");
    }

    /**
     * @dev buy function
     * @param _affCode the ID/address/name of the player who gets the affiliate fee
     * @param _team what team is the player playing for
     */
    function buy(uint256 _team, bytes32 _affCode)
        public
        payable
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
    {
        // ensure game has not ended
        require(round_[rID_].state < 3, "This round has ended.");

        // ensure game is in right state
        if (round_[rID_].state == 0){
            require(now >= round_[rID_].start, "This round hasn&#39;t started yet.");
            round_[rID_].state = 1;
        }

        // get player ID if not exists ,create new player
        determinePID(msg.sender);
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _tID;

        // manage affiliate residuals
        // _affCode should be player name.
        uint256 _affID;
        if (_affCode == "" || _affCode == plyr_[_pID].name){
            // use last stored affiliate code
            _affID = plyr_[_pID].laff;
        } else {
            // get affiliate ID from aff Code
            _affID = pIDxName_[_affCode];

            // if affID is not the same as previously stored
            if (_affID != plyr_[_pID].laff){
                // update last affiliate
                plyr_[_pID].laff = _affID;
            }
        }

        // buy info
        if (round_[rID_].state == 1){
            // Check team id
            _tID = determinTID(_team, _pID);

            // Buy
            buyCore(_pID, _affID, _tID, msg.value);

            // if team number is more than minimum team number, then go the out state（state: 2）
            if (round_[rID_].tID_ >= minTms_){
                // go the out state
                round_[rID_].state = 2;

                // out initial
                startOut();
            }

        } else if (round_[rID_].state == 2){
            // if only 1 alive team, go end
            if (round_[rID_].liveTeams == 1){
                endRound();

                // pay back
                refund(_pID, msg.value);

                return;
            }

            // Check team id
            _tID = determinTID(_team, _pID);

            // Buy
            buyCore(_pID, _affID, _tID, msg.value);

            // Out if needed
            if (now > round_[rID_].lastOutTime.add(OutGap_)) {
                out();
            }
        }
    }

    /**
     * @dev withdraws all of your earnings.
     */
    function withdraw()
        public
        isActivated()
        isHuman()
    {
        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // ensure player is effective
        require(_pID != 0, "Please join the game first!");

        // setup temp var for player eth
        uint256 _eth;

        // calculate the remain amount that has not withdrawn
        if (rID_ > 1){
            for (uint256 i = 1; i < rID_; i++) {
                // if has not withdrawn, then withdraw
                if (plyrRnds_[_pID][i].withdrawn == false){
                    if (plyrRnds_[_pID][i].plyrTmKeys[round_[i].team] != 0) {
                        _eth = _eth.add(round_[i].ethPerKey.mul(plyrRnds_[_pID][i].plyrTmKeys[round_[i].team]) / 1000000000000000000);
                    }
                    plyrRnds_[_pID][i].withdrawn = true;
                }
            }
        }

        _eth = _eth.add(plyr_[_pID].gen).add(plyr_[_pID].aff);

        // transfer the balance
        if (_eth > 0) {
            plyr_[_pID].addr.transfer(_eth);
        }

        // clear
        plyr_[_pID].gen = 0;
        plyr_[_pID].aff = 0;

        // Event
        emit onWithdrawEvent(_pID, plyr_[_pID].addr, plyr_[_pID].name, _eth, now);
    }

    /**
     * @dev use these to register names. UI will always display the last name you registered.
     * but you will still own all previously registered names to use as affiliate links.
     * - must pay a registration fee.
     * - name must be unique
     * - name cannot start or end with a space
     * - cannot have more than 1 space in a row
     * - cannot be only numbers
     * - cannot start with 0x
     * - name must be at least 1 char
     * - max length of 32 characters long
     * - allowed characters: a-z, 0-9, and space
     * @param _nameString players desired name
     */
    function registerNameXID(string _nameString)
        public
        payable
        isHuman()
    {
        // make sure name fees paid
        require (msg.value >= registrationFee_, "You have to pay the name fee.(10 finney)");

        // filter name + condition checks
        bytes32 _name = NameFilter.nameFilter(_nameString);

        // set up address
        address _addr = msg.sender;

        // set up our tx event data and determine if player is new or not
        // bool _isNewPlayer = determinePID(_addr);
        bool _isNewPlayer = determinePID(_addr);

        // fetch player id
        uint256 _pID = pIDxAddr_[_addr];

        // ensure the name is not used
        require(pIDxName_[_name] == 0, "sorry that names already taken");

        // add name to player profile, registry, and name book
        plyr_[_pID].name = _name;
        pIDxName_[_name] = _pID;

        // deposit registration fee
        plyr_[1].gen = (msg.value).add(plyr_[1].gen);

        // Event
        emit onNewNameEvent(_pID, _addr, _name, _isNewPlayer, msg.value, now);
    }

    /**
     * @dev use these to register a team names. UI will always display the last name you registered.
     * - only team leader can call this func.
     * - must pay a registration fee.
     * - name must be unique
     * - name cannot start or end with a space
     * - cannot have more than 1 space in a row
     * - cannot be only numbers
     * - cannot start with 0x
     * - name must be at least 1 char
     * - max length of 32 characters long
     * - allowed characters: a-z, 0-9, and space
     */
    function setTeamName(uint256 _tID, string _nameString)
        public
        payable
        isHuman()
    {
        // team should be effective
        require(_tID <= round_[rID_].tID_ && _tID != 0, "There&#39;s no this team.");

        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // must be team leader
        require(_pID == rndTms_[rID_][_tID].leaderID, "Only team leader can change team name. You can invest more money to be the team leader.");

        // need register fee
        require (msg.value >= registrationFee_, "You have to pay the name fee.(10 finney)");

        // filter name + condition checks
        bytes32 _name = NameFilter.nameFilter(_nameString);

        require(rndTIDxName_[rID_][_name] == 0, "sorry that names already taken");

        // add name to team
        rndTms_[rID_][_tID].name = _name;
        rndTIDxName_[rID_][_name] = _tID;

        // deposit registration fee
        plyr_[1].gen = (msg.value).add(plyr_[1].gen);

        // event
        emit onNewTeamNameEvent(_tID, _name, _pID, plyr_[_pID].name, msg.value, now);
    }

    // deposit in the game
    function deposit()
        public
        payable
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
    {
        determinePID(msg.sender);
        uint256 _pID = pIDxAddr_[msg.sender];

        plyr_[_pID].gen = (msg.value).add(plyr_[_pID].gen);
    }

    //**************
    // GETTERS
    //**************

    // check the name
    function checkIfNameValid(string _nameStr)
        public
        view
        returns (bool)
    {
        bytes32 _name = _nameStr.nameFilter();
        if (pIDxName_[_name] == 0)
            return (true);
        else
            return (false);
    }

    /**
     * @dev returns next out time
     * @return next out time
     */
    function getNextOutAfter()
        public
        view
        returns (uint256)
    {
        require(round_[rID_].state == 2, "Not in Out period.");

        uint256 _tNext = round_[rID_].lastOutTime.add(OutGap_);
        uint256 _t = _tNext > now ? _tNext.sub(now) : 0;

        return _t;
    }

    /**
     * @dev returns player info based on address.  if no address is given, it will
     * use msg.sender
     * @param _addr address of the player you want to lookup
     * @return player ID
     * @return player name
     * @return keys owned (current round)
     * @return winnings vault
     * @return general vault
     * @return affiliate vault
	 * @return player round eth
     */
    function getPlayerInfoByAddress(address _addr)
        public
        view
        returns(uint256, address, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];

        return (
            _pID,
            _addr,
            plyr_[_pID].name,
            plyr_[_pID].gen,
            plyr_[_pID].aff,
            plyrRnds_[_pID][rID_].eth,
            getProfit(_pID),
            getPreviousProfit(_pID)
        );
    }

    /**
     * @dev returns _pID player for _tID team at _roundID round all keys
     * - _roundID = 0 then _roundID = current round
     * @return keys
     */
    function getPlayerRoundTeamBought(uint256 _pID, uint256 _roundID, uint256 _tID)
        public
        view
        returns (uint256)
    {
        uint256 _rID = _roundID == 0 ? rID_ : _roundID;
        return plyrRnds_[_pID][_rID].plyrTmKeys[_tID];
    }

    /**
     * @dev returns _pID player at _roundID round all keys
     * - _roundID = 0 then _roundID = current round
     * @return array keysList
     * - keysList[i] :team[i+1] for _pID
     */
    function getPlayerRoundBought(uint256 _pID, uint256 _roundID)
        public
        view
        returns (uint256[])
    {
        uint256 _rID = _roundID == 0 ? rID_ : _roundID;

        // team count
        uint256 _tCount = round_[_rID].tID_;

        // keys for player in every team
        uint256[] memory keysList = new uint256[](_tCount);

        for (uint i = 0; i < _tCount; i++) {
            keysList[i] = plyrRnds_[_pID][_rID].plyrTmKeys[i+1];
        }

        return keysList;
    }

    /**
     * @dev returns _pID player at every round all eths and winnings
     * @return array {ethList, winList}
     */
    function getPlayerRounds(uint256 _pID)
        public
        view
        returns (uint256[], uint256[])
    {
        uint256[] memory _ethList = new uint256[](rID_);
        uint256[] memory _winList = new uint256[](rID_);
        for (uint i=0; i < rID_; i++){
            _ethList[i] = plyrRnds_[_pID][i+1].eth;
            _winList[i] = plyrRnds_[_pID][i+1].plyrTmKeys[round_[i+1].team].mul(round_[i+1].ethPerKey) / 1000000000000000000;
        }

        return (
            _ethList,
            _winList
        );
    }

    /**
     * @dev returns last round info
     * @return round ID
     * @return round state
     * @return round pots
     * @return win team ID
     * @return team name
     * @return team player count
     * @return team number
     */
    function getLastRoundInfo()
        public
        view
        returns (uint256, uint256, uint256, uint256, bytes32, uint256, uint256)
    {
        // last round id
        uint256 _rID = rID_.sub(1);

        // last winner
        uint256 _tID = round_[_rID].team;

        return (
            _rID,
            round_[_rID].state,
            round_[_rID].pot,
            _tID,
            rndTms_[_rID][_tID].name,
            rndTms_[_rID][_tID].playersCount,
            round_[_rID].tID_
        );
    }

    /**
     * @dev returns all current round info needed for front end
     * @return round id
     * @return round state
     * @return current eths
     * @return current pot
     * @return leader team ID
     * @return current price per key
     * @return the last out time
     * @return time out gap
     * @return current dead rate
     * @return current dead keys
     * @return alive teams
     * @return team count
     * @return time round started
     */
    function getCurrentRoundInfo()
        public
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        return (
            rID_,
            round_[rID_].state,
            round_[rID_].eth,
            round_[rID_].pot,
            round_[rID_].keys,
            round_[rID_].team,
            round_[rID_].ethPerKey,
            round_[rID_].lastOutTime,
            OutGap_,
            round_[rID_].deadRate,
            round_[rID_].deadKeys,
            round_[rID_].liveTeams,
            round_[rID_].tID_,
            round_[rID_].start
        );
    }

    /**
     * @dev returns _tID team info
     * @return team id
     * @return team name
     * @return team all keys
     * @return team all eths
     * @return current price per key for this team
     * @return leader player ID
     * @return if team is out
     */
    function getTeamInfoByID(uint256 _tID)
        public
        view
        returns (uint256, bytes32, uint256, uint256, uint256, uint256, bool)
    {
        require(_tID <= round_[rID_].tID_, "There&#39;s no this team.");

        return (
            rndTms_[rID_][_tID].id,
            rndTms_[rID_][_tID].name,
            rndTms_[rID_][_tID].keys,
            rndTms_[rID_][_tID].eth,
            rndTms_[rID_][_tID].price,
            rndTms_[rID_][_tID].leaderID,
            rndTms_[rID_][_tID].dead
        );
    }

    /**
     * @dev returns all team info
     * @return array team ids
     * @return array team names
     * @return array team all keys
     * @return array team all eths
     * @return array current price per key for this team
     * @return array team members
     * @return array if team is out
     */
    function getTeamsInfo()
        public
        view
        returns (uint256[], bytes32[], uint256[], uint256[], uint256[], uint256[], bool[])
    {
        uint256 _tID = round_[rID_].tID_;

        // Lists of Team Info
        uint256[] memory _idList = new uint256[](_tID);
        bytes32[] memory _nameList = new bytes32[](_tID);
        uint256[] memory _keysList = new uint256[](_tID);
        uint256[] memory _ethList = new uint256[](_tID);
        uint256[] memory _priceList = new uint256[](_tID);
        uint256[] memory _membersList = new uint256[](_tID);
        bool[] memory _deadList = new bool[](_tID);

        // Data
        for (uint i = 0; i < _tID; i++) {
            _idList[i] = rndTms_[rID_][i+1].id;
            _nameList[i] = rndTms_[rID_][i+1].name;
            _keysList[i] = rndTms_[rID_][i+1].keys;
            _ethList[i] = rndTms_[rID_][i+1].eth;
            _priceList[i] = rndTms_[rID_][i+1].price;
            _membersList[i] = rndTms_[rID_][i+1].playersCount;
            _deadList[i] = rndTms_[rID_][i+1].dead;
        }

        return (
            _idList,
            _nameList,
            _keysList,
            _ethList,
            _priceList,
            _membersList,
            _deadList
        );
    }

    /**
     * @dev returns all team leaders info
     * @return array team ids
     * @return array team leader ids
     * @return array team leader names
     * @return array team leader address
     */
    function getTeamLeaders()
        public
        view
        returns (uint256[], uint256[], bytes32[], address[])
    {
        uint256 _tID = round_[rID_].tID_;

        // Teams&#39; leaders info
        uint256[] memory _idList = new uint256[](_tID);
        uint256[] memory _leaderIDList = new uint256[](_tID);
        bytes32[] memory _leaderNameList = new bytes32[](_tID);
        address[] memory _leaderAddrList = new address[](_tID);

        // Data
        for (uint i = 0; i < _tID; i++) {
            _idList[i] = rndTms_[rID_][i+1].id;
            _leaderIDList[i] = rndTms_[rID_][i+1].leaderID;
            _leaderNameList[i] = plyr_[_leaderIDList[i]].name;
            _leaderAddrList[i] = rndTms_[rID_][i+1].leaderAddr;
        }

        return (
            _idList,
            _leaderIDList,
            _leaderNameList,
            _leaderAddrList
        );
    }

    /**
     * @dev returns predict the profit for the leader team
     * @return eth
     */
    function getProfit(uint256 _pID)
        public
        view
        returns (uint256)
    {
        // leader team ID
        uint256 _tID = round_[rID_].team;

        // if player not in the leader team
        if (plyrRnds_[_pID][rID_].plyrTmKeys[_tID] == 0){
            return 0;
        }

        // player&#39;s keys in the leader team
        uint256 _keys = plyrRnds_[_pID][rID_].plyrTmKeys[_tID];

        // calculate eth per key
        uint256 _ethPerKey = round_[rID_].pot.mul(1000000000000000000) / rndTms_[rID_][_tID].keys;

        // calculate the win value
        uint256 _value = _keys.mul(_ethPerKey) / 1000000000000000000;

        return _value;
    }

    /**
     * @dev returns the eths that has not withdrawn before current round
     * @return eth
     */
    function getPreviousProfit(uint256 _pID)
        public
        view
        returns (uint256)
    {
        uint256 _eth;

        if (rID_ > 1){
            // calculate the eth that has not withdrawn for the ended round
            for (uint256 i = 1; i < rID_; i++) {
                if (plyrRnds_[_pID][i].withdrawn == false){
                    if (plyrRnds_[_pID][i].plyrTmKeys[round_[i].team] != 0) {
                        _eth = _eth.add(round_[i].ethPerKey.mul(plyrRnds_[_pID][i].plyrTmKeys[round_[i].team]) / 1000000000000000000);
                    }
                }
            }
        } else {
            // if there is not ended round
            _eth = 0;
        }

        return _eth;
    }

    /**
     * @dev returns the next key price for _tID team
     * @return eth
     */
    function getNextKeyPrice(uint256 _tID)
        public
        view
        returns(uint256)
    {
        require(_tID <= round_[rID_].tID_ && _tID != 0, "No this team.");

        return ( (rndTms_[rID_][_tID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
    }

    /**
     * @dev returns the eth for buying _keys keys at _tID team
     * @return eth
     */
    function getEthFromKeys(uint256 _tID, uint256 _keys)
        public
        view
        returns(uint256)
    {
        if (_tID <= round_[rID_].tID_ && _tID != 0){
            // if team is exists
            return ((rndTms_[rID_][_tID].keys.add(_keys)).ethRec(_keys));
        } else {
            // if team is not exists
            return ((uint256(0).add(_keys)).ethRec(_keys));
        }
    }

    /**
     * @dev returns the keys for buying _eth eths at _tID team
     * @return keys
     */
    function getKeysFromEth(uint256 _tID, uint256 _eth)
        public
        view
        returns (uint256)
    {
        if (_tID <= round_[rID_].tID_ && _tID != 0){
            // if team is exists
            return (rndTms_[rID_][_tID].eth).keysRec(_eth);
        } else {
            // if team is not exists
            return (uint256(0).keysRec(_eth));
        }
    }

    // **************============
    //   PRIVATE: CORE GAME LOGIC
    // **************============

    /**
     * @dev logic runs whenever a buy order is executed.  determines how to handle
     * incoming eth depending on if we are in an active round or not
     */
    function buyCore(uint256 _pID, uint256 _affID, uint256 _tID, uint256 _eth)
        private
    {
        uint256 _keys = (rndTms_[rID_][_tID].eth).keysRec(_eth);

        // player
        if (plyrRnds_[_pID][rID_].plyrTmKeys[_tID] == 0){
            rndTms_[rID_][_tID].playersCount++;
        }
        plyrRnds_[_pID][rID_].plyrTmKeys[_tID] = _keys.add(plyrRnds_[_pID][rID_].plyrTmKeys[_tID]);
        plyrRnds_[_pID][rID_].eth = _eth.add(plyrRnds_[_pID][rID_].eth);

        // Team
        rndTms_[rID_][_tID].keys = _keys.add(rndTms_[rID_][_tID].keys);
        rndTms_[rID_][_tID].eth = _eth.add(rndTms_[rID_][_tID].eth);
        rndTms_[rID_][_tID].price = _eth.mul(1000000000000000000) / _keys;
        uint256 _teamLeaderID = rndTms_[rID_][_tID].leaderID;
        // refresh team leader
        if (plyrRnds_[_pID][rID_].plyrTmKeys[_tID] > plyrRnds_[_teamLeaderID][rID_].plyrTmKeys[_tID]){
            rndTms_[rID_][_tID].leaderID = _pID;
            rndTms_[rID_][_tID].leaderAddr = msg.sender;
        }

        // Round
        round_[rID_].keys = _keys.add(round_[rID_].keys);
        round_[rID_].eth = _eth.add(round_[rID_].eth);
        // refresh round leader
        if (rndTms_[rID_][_tID].keys > rndTms_[rID_][round_[rID_].team].keys){
            round_[rID_].team = _tID;
        }

        distribute(rID_, _pID, _eth, _affID);

        // Event
        emit onTxEvent(_pID, msg.sender, plyr_[_pID].name, _tID, rndTms_[rID_][_tID].name, _eth, _keys);
    }

    // distribute eth
    function distribute(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID)
        private
    {
        // [1] com - 3%
        uint256 _com = (_eth.mul(3)) / 100;

        // pay community reward
        plyr_[1].gen = _com.add(plyr_[1].gen);

        // [2] aff - 10%
        uint256 _aff = _eth / 10;

        if (_affID != _pID && plyr_[_affID].name != "") {
            // pay aff
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);

            // Event bonus for invite
            emit onAffPayoutEvent(_affID, plyr_[_affID].addr, plyr_[_affID].name, _rID, _pID, _aff, now);
        } else {
            // if not affiliate, this amount of eth add to the pot
            _aff = 0;
        }

        // [3] pot - 87%
        uint256 _pot = _eth.sub(_aff).sub(_com);

        // update current pot
        round_[_rID].pot = _pot.add(round_[_rID].pot);
    }

    /**
     * @dev ends the round. manages paying out winner/splitting up pot
     */
    function endRound()
        private
    {
        require(round_[rID_].state < 3, "Round only end once.");

        // set round state
        round_[rID_].state = 3;

        // all pot
        uint256 _pot = round_[rID_].pot;

        // Devide Round Pot
        // [1] winner 85%
        uint256 _win = (_pot.mul(85))/100;

        // [2] com 5%
        uint256 _com = (_pot.mul(5))/100;

        // [3] next round 10%
        uint256 _res = (_pot.sub(_win)).sub(_com);

        // win team
        uint256 _tID = round_[rID_].team;
        // ethPerKey (A Full Key = 10**18 keys)
        uint256 _epk = (_win.mul(1000000000000000000)) / (rndTms_[rID_][_tID].keys);

        // if dust
        uint256 _dust = _win.sub((_epk.mul(rndTms_[rID_][_tID].keys)) / 1000000000000000000);
        if (_dust > 0) {
            _win = _win.sub(_dust);
            _res = _res.add(_dust);
        }

        // pay winner team
        round_[rID_].ethPerKey = _epk;

        // pay community reward
        plyr_[1].gen = _com.add(plyr_[1].gen);

        // Event
        emit onEndRoundEvent(_tID, rndTms_[rID_][_tID].name, rndTms_[rID_][_tID].playersCount, _pot);

        // next round
        rID_++;
        round_[rID_].pot = _res;
        round_[rID_].start = now + roundGap_;
    }

    // refund
    function refund(uint256 _pID, uint256 _value)
        private
    {
        plyr_[_pID].gen = _value.add(plyr_[_pID].gen);
    }

    /**
     * @dev create a new team
     * @return team ID
     */
    function createTeam(uint256 _pID, uint256 _eth)
        private
        returns (uint256)
    {
        // maximum team number limit
        require(round_[rID_].tID_ < maxTms_, "The number of teams has reached the maximum limit.");

        // payable should more than 1eth
        require(_eth >= 1000000000000000000, "You need at least 1 eth to create a team, though creating a new team is free.");

        // update data
        round_[rID_].tID_++;
        round_[rID_].liveTeams++;

        // new team ID
        uint256 _tID = round_[rID_].tID_;

        // new team data
        rndTms_[rID_][_tID].id = _tID;
        rndTms_[rID_][_tID].leaderID = _pID;
        rndTms_[rID_][_tID].leaderAddr = plyr_[_pID].addr;
        rndTms_[rID_][_tID].dead = false;

        return _tID;
    }

    // initial the out state
    function startOut()
        private
    {
        round_[rID_].lastOutTime = now;
        round_[rID_].deadRate = 10;     // used by deadRate / 100
        round_[rID_].deadKeys = (rndTms_[rID_][round_[rID_].team].keys.mul(round_[rID_].deadRate)) / 100;
        emit onOutInitialEvent(round_[rID_].lastOutTime);
    }

    // emit out
    function out()
        private
    {
        // current state dead number of the teams
        uint256 _dead = 0;

        // if less than deadKeys ,sorry, your team is out
        for (uint256 i = 1; i <= round_[rID_].tID_; i++) {
            if (rndTms_[rID_][i].keys < round_[rID_].deadKeys && rndTms_[rID_][i].dead == false){
                rndTms_[rID_][i].dead = true;
                round_[rID_].liveTeams--;
                _dead++;
            }
        }

        round_[rID_].lastOutTime = now;

        // if there just 1 alive team
        if (round_[rID_].liveTeams == 1 && round_[rID_].state == 2) {
            endRound();
            return;
        }

        // update the deadRate
        if (round_[rID_].deadRate < 90) {
            round_[rID_].deadRate = round_[rID_].deadRate + 10;
        }

        // update deadKeys
        round_[rID_].deadKeys = ((rndTms_[rID_][round_[rID_].team].keys).mul(round_[rID_].deadRate)) / 100;

        // event
        emit onOutInitialEvent(round_[rID_].lastOutTime);
        emit onOutEvent(_dead, round_[rID_].liveTeams, round_[rID_].deadKeys);
    }

    /**
     * @dev gets existing or registers new pID.  use this when a player may be new
     * @return bool if a new player
     */
    function determinePID(address _addr)
        private
        returns (bool)
    {
        if (pIDxAddr_[_addr] == 0)
        {
            pID_++;
            pIDxAddr_[_addr] = pID_;
            plyr_[pID_].addr = _addr;

            return (true);  // new
        } else {
            return (false);
        }
    }

    /**
     * @dev gets existing a team.  if not, create a new team
     * @return team ID
     */
    function determinTID(uint256 _team, uint256 _pID)
        private
        returns (uint256)
    {
        // ensure the team is alive
        require(rndTms_[rID_][_team].dead == false, "You can not buy a dead team!");

        if (_team <= round_[rID_].tID_ && _team > 0) {
            // if team is existing
            return _team;
        } else {
            // if team is not existing
            return createTeam(_pID, msg.value);
        }
    }

    //**************
    // SECURITY
    //**************

    // active the game
    bool public activated_ = false;
    function activate()
        public
        onlyOwner()
    {
        // can only be ran once
        require(activated_ == false, "it is already activated");

        // activate the contract
        activated_ = true;

        // the first player
        plyr_[1].addr = cooperator;
        plyr_[1].name = "imkg";
        pIDxAddr_[cooperator] = 1;
        pIDxName_["imkg"] = 1;
        pID_ = 1;

        // activate the first game
        rID_ = 1;
        round_[1].start = now;
        round_[1].state = 1;
    }

    //****************************
    // SETTINGS (Only owner)
    //****************************

    /*
      * @dev if timing is up,then msg.sender go this func to end or out this game.
      */
      function timeCountdown()
          public
          isActivated()
          isHuman()
          onlyOwner()
      {
          //state == 2  out state
          if (round_[rID_].state == 2){
              // if alive team = 1, go endRound().
              if (round_[rID_].liveTeams == 1){

                  endRound();
                  return;
              }

              // Out if needed
              if (now > round_[rID_].lastOutTime.add(OutGap_)) {
                  out();
              }
          }
      }


    // set the minimum team number
    function setMinTms(uint256 _tms)
        public
        onlyOwner()
    {
        minTms_ = _tms;
    }

    // set the maximum team number
    function setMaxTms(uint256 _tms)
        public
        onlyOwner()
    {
        maxTms_ = _tms;
    }

    // set the round gap
    function setRoundGap(uint256 _gap)
        public
        onlyOwner()
    {
        roundGap_ = _gap;
    }

    // set the out gap
    function setOutGap(uint256 _gap)
        public
        onlyOwner()
    {
        OutGap_ = _gap;
    }

}   // main contract ends here