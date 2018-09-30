pragma solidity ^0.4.24;

// File: contracts/interface/PlayerBookInterface.sol

interface PlayerBookInterface {
    function getPlayerID(address _addr) external returns(uint256);
    function getPlayerName(uint256 _pID) external view returns(bytes32);
    function getPlayerLAff(uint256 _pID) external view returns(uint256);
    function getPlayerAddr(uint256 _pID) external view returns(address);
    function getNameFee() external view returns(uint256);
    function registerNameXIDFromDapp(address _addr, bytes32 _name, uint256 _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXaddrFromDapp(address _addr, bytes32 _name, address _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXnameFromDapp(address _addr, bytes32 _name, bytes32 _affCode, bool _all) external payable returns(bool, uint256);
}

// File: contracts/interface/TeamPerfitForwarderInterface.sol

interface TeamPerfitForwarderInterface {
    function deposit() external payable returns(bool);
    function status() external view returns(address, address);
}

// File: contracts/interface/DRSCoinInterface.sol

interface DRSCoinInterface {
    function mint(address _to, uint256 _amount) external;
    function profitEth() external payable;
}

// File: contracts/library/SafeMath.sol

/**
 * @title SafeMath v0.1.9
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 */
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
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

// File: contracts/library/NameFilter.sol

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

// File: contracts/library/DRSDatasets.sol

// structs ==============================================================================
library DRSDatasets {
    //compressedData key
    // [24-14][13-3][2][1][0]
        // 0 - new player (bool)
        // 1 - joined round (bool)
        // 2 - new  leader (bool)
        // 3-13 - round end time
        // 14 - 24 timestamp

    //compressedIDs key
    // [77-52][51-26][25-0]
        // 0-25 - pID 
        // 26-51 - winPID
        // 52-77 - rID
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;

        address winnerAddr;         // winner address
        bytes32 winnerName;         // winner name
        uint256 amountWon;          // amount won

        uint256 newPot;             // amount in new pot
        uint256 genAmount;          // amount distributed to gen
        uint256 potAmount;          // amount added to pot

        address genAddr;
        uint256 genKeyPrice;
    }

    function setNewPlayerFlag(EventReturns _event) internal pure returns(EventReturns) {
        _event.compressedData = _event.compressedData + 1;
        return _event;
    }

    function setJoinedRoundFlag(EventReturns _event) internal pure returns(EventReturns) {
        _event.compressedData = _event.compressedData + 10;
        return _event;
    }

    function setNewLeaderFlag(EventReturns _event) internal pure returns(EventReturns) {
        _event.compressedData = _event.compressedData + 100;
        return _event;
    }

    function setRoundEndTime(EventReturns _event, uint256 roundEndTime) internal pure returns(EventReturns) {
        _event.compressedData = _event.compressedData + roundEndTime * (10**3);
        return _event;
    }

    function setTimestamp(EventReturns _event, uint256 timestamp) internal pure returns(EventReturns) {
        _event.compressedData = _event.compressedData + timestamp * (10**14);
        return _event;
    }

    function setPID(EventReturns _event, uint256 _pID) internal pure returns(EventReturns) {
        _event.compressedIDs = _event.compressedIDs + _pID;
        return _event;
    }

    function setWinPID(EventReturns _event, uint256 _winPID) internal pure returns(EventReturns) {
        _event.compressedIDs = _event.compressedIDs + (_winPID * (10**26));
        return _event;
    }

    function setRID(EventReturns _event, uint256 _rID) internal pure returns(EventReturns) {
        _event.compressedIDs = _event.compressedIDs + (_rID * (10**52));
        return _event;
    }

    function setWinner(EventReturns _event, address _winnerAddr, bytes32 _winnerName, uint256 _amountWon)
        internal pure returns(EventReturns) {
        _event.winnerAddr = _winnerAddr;
        _event.winnerName = _winnerName;
        _event.amountWon = _amountWon;
        return _event;
    }

    function setGenInfo(EventReturns _event, address _genAddr, uint256 _genKeyPrice)
        internal pure returns(EventReturns) {
        _event.genAddr = _genAddr;
        _event.genKeyPrice = _genKeyPrice;
    }

    function setNewPot(EventReturns _event, uint256 _newPot) internal pure returns(EventReturns) {
        _event.newPot = _newPot;
        return _event;
    }

    function setGenAmount(EventReturns _event, uint256 _genAmount) internal pure returns(EventReturns) {
        _event.genAmount = _genAmount;
        return _event;
    }

    function setPotAmount(EventReturns _event, uint256 _potAmount) internal pure returns(EventReturns) {
        _event.potAmount = _potAmount;
        return _event;
    }

    struct Player {
        address addr;   // player address
        bytes32 name;   // player name
        uint256 win;    // winnings vault
        uint256 gen;    // general vault
        // uint256 aff;    // affiliate vault
        uint256 lrnd;   // last round played
        // uint256 laff;   // last affiliate id used
    }

    struct PlayerRound {
        uint256 eth;    // eth player has added to round (used for eth limiter)
        uint256 keys;   // keys
    }

    struct Round {
        uint256 plyr;   // pID of player in lead

        uint256 end;    // time ends/ended
        bool ended;     // has round end function been ran
        uint256 strt;   // time round started
        uint256 keys;   // keys
        uint256 eth;    // total eth in
        uint256 pot;    // eth to pot (during round) / final amount paid to winner (after round ends)
    }

    struct BuyInfo {
        address addr;   // player address
        bytes32 name;   // player name
        uint256 pid;    // player id
        uint256 keyPrice;
        uint256 keyIndex;
    }
}

// File: contracts/DRSEvents.sol

contract DRSEvents {
    // fired whenever a player registers a name
    event onNewName
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        bool isNewPlayer,
        // uint256 affiliateID,
        // address affiliateAddress,
        // bytes32 affiliateName,
        uint256 amountPaid,
        uint256 timeStamp
    );

    // fired at end of buy or reload
    event onEndTx
    (
        uint256 compressedData,
        uint256 compressedIDs,

        bytes32 playerName,
        address playerAddress,
        uint256 ethIn,
        uint256 keyIndex,

        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,

        uint256 newPot,
        uint256 genAmount,
        uint256 potAmount,

        address genAddr,
        uint256 genKeyPrice
    );

    // fired whenever theres a withdraw
    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timeStamp
    );

    // fired whenever a withdraw forces end round to be ran
    event onWithdrawAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 compressedData,

        uint256 compressedIDs,

        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,

        uint256 newPot,
        uint256 genAmount
    );

    // fired whenever a player tries a buy after round timer
    // hit zero, and causes end round to be ran.
    event onBuyAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 ethIn,
        uint256 compressedData,

        uint256 compressedIDs,

        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,

        uint256 newPot,
        uint256 genAmount
    );

    // fired whenever a player tries a reload after round timer
    // hit zero, and causes end round to be ran.
    event onReLoadAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 compressedData,

        uint256 compressedIDs,

        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,

        uint256 newPot,
        uint256 genAmount
    );

    event onBuyKeyFailure
    (
        uint256 roundID,
        uint256 indexed playerID,
        uint256 amount,
        uint256 keyPrice,
        uint256 timeStamp
    );
}

// File: contracts/ReserveBag.sol

contract ReserveBag is DRSEvents {
    using SafeMath for uint256;
    using NameFilter for string;
    using DRSDatasets for DRSDatasets.EventReturns;

    TeamPerfitForwarderInterface public teamPerfit;
    PlayerBookInterface public playerBook;
    DRSCoinInterface public drsCoin;

    // game settings
    string constant public name = "Reserve Bag";
    string constant public symbol = "RB";

    uint256 constant private initKeyPrice = (10**18);

    uint256 private rndExtra_ = 0;       // length of the very first ICO 
    uint256 private rndGap_ = 0;         // length of ICO phase, set to 1 year for EOS.

    uint256 constant private rndMax_ = 24 hours;                // max length a round timer can be
    // uint256 constant private rndMax_ = 5 seconds;                // max length a round timer can be

    uint256 public rID_;    // round id number / total rounds that have happened

    uint256 public keyPrice = initKeyPrice;
    uint256 public keyBought = 0;

    address public owner;

    uint256 public teamPerfitAmuont = 0;

    uint256 public rewardInternal = 36;
    // uint256 public potRatio = 8;
    uint256 public keyPriceIncreaseRatio = 8;
    uint256 public genRatio = 90;

    uint256 public drsCoinDividendRatio = 40;
    uint256 public teamPerfitRatio = 5;

    uint256 public ethMintDRSCoinRate = 100;

    bool public activated_ = false;

    // PLAYER DATA
    mapping(address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping(bytes32 => uint256) public pIDxName_;          // (name => pID) returns player id by name
    mapping(uint256 => DRSDatasets.Player) public plyr_;   // (pID => data) player data
    mapping(uint256 => mapping(uint256 => DRSDatasets.PlayerRound)) public plyrRnds_;    // (pID => rID => data) player round data by player id & round id
    mapping(uint256 => mapping(bytes32 => bool)) public plyrNames_; // (pID => name => bool) list of names a player owns.  (used so you can change your display name amongst any name you own)

    DRSDatasets.BuyInfo[] buyinfos;
    uint256 private startIndex;
    uint256 private endIndex;

    // ROUND DATA 
    mapping(uint256 => DRSDatasets.Round) public round_;   // (rID => data) round data

    // event Info(uint256 _value);

    constructor(address _teamPerfit, address _playBook, address _drsCoin) public
    {
        owner = msg.sender;

        teamPerfit = TeamPerfitForwarderInterface(_teamPerfit);
        playerBook = PlayerBookInterface(_playBook);
        drsCoin = DRSCoinInterface(_drsCoin);

        startIndex = 0;
        endIndex = 0;
    }

    modifier onlyOwner {
        assert(owner == msg.sender);
        _;
    }

    /**
     * @dev prevents contracts from interacting with ReserveBag 
     */
    modifier isHuman() {
        address _addr = msg.sender;
        require(_addr == tx.origin);

        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    /**
     * @dev sets boundaries for incoming tx 
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000 * (10**18), "no vitalik, no");
        _;
    }

    function pushBuyInfo(DRSDatasets.BuyInfo info) internal {
        if(endIndex == buyinfos.length) {
            buyinfos.push(info);
        } else if(endIndex < buyinfos.length) {
            buyinfos[endIndex] = info;
        } else {
            // cannot happen
            revert();
        }

        endIndex = (endIndex + 1) % (rewardInternal + 1);

        if(endIndex == startIndex) {
            startIndex = (startIndex + 1) % (rewardInternal + 1);
        }
    }

    /**
     * @dev emergency buy uses last stored affiliate ID and team snek
     */
    function()
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        // set up our tx event data and determine if player is new or not
        DRSDatasets.EventReturns memory _eventData_;
        _eventData_ = determinePID(_eventData_);

        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];

        // buy core 
        buyCore(_pID, _eventData_);
    }

    function buyKey()
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        // set up our tx event data and determine if player is new or not
        DRSDatasets.EventReturns memory _eventData_;
        _eventData_ = determinePID(_eventData_);

        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];

        // buy core 
        buyCore(_pID, _eventData_);
    }

    function reLoadXaddr(uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        require(_pID != 0, "reLoadXaddr can not be called by new players");

        // set up our tx event data
        DRSDatasets.EventReturns memory _eventData_;

        // reload core
        reLoadCore(_pID, _eth, _eventData_);
    }

    function withdrawTeamPerfit()
        isActivated()
        onlyOwner()
        public
    {
        if(teamPerfitAmuont > 0) {
            uint256 _perfit = teamPerfitAmuont;

            teamPerfitAmuont = 0;

            owner.transfer(_perfit);
        }
    }

    function getTeamPerfitAmuont() public view returns(uint256) {
        return teamPerfitAmuont;
    }

    /**
     * @dev withdraws all of your earnings.
     * -functionhash- 0x3ccfd60b
     */
    function withdraw()
        isActivated()
        isHuman()
        public
    {
        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        require(_pID != 0, "withdraw can not be called by new players");

        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // setup temp var for player eth
        uint256 _eth;

        // check to see if round has ended and no one has run round end yet
        if(_now > round_[_rID].end && !round_[_rID].ended && round_[_rID].plyr != 0)
        {
            // set up our tx event data
            DRSDatasets.EventReturns memory _eventData_;

            // end the round (distributes pot)
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

            // get their earnings
            _eth = withdrawEarnings(_pID);

            // withdraw eth
            if(_eth > 0) {
                plyr_[_pID].addr.transfer(_eth);    
            }

            // build event data
            _eventData_ = _eventData_.setTimestamp(_now);
            _eventData_ = _eventData_.setPID(_pID);

            // fire withdraw and distribute event
            emit DRSEvents.onWithdrawAndDistribute
            (
                msg.sender,
                plyr_[_pID].name,
                _eth,
                _eventData_.compressedData,
                _eventData_.compressedIDs,

                _eventData_.winnerAddr,
                _eventData_.winnerName,
                _eventData_.amountWon,

                _eventData_.newPot,
                _eventData_.genAmount
            );
        } else {
            // get their earnings
            _eth = withdrawEarnings(_pID);

            // withdraw eth
            if(_eth > 0) {
                plyr_[_pID].addr.transfer(_eth);
            }

            // fire withdraw event
            emit DRSEvents.onWithdraw(_pID, msg.sender, plyr_[_pID].name, _eth, _now);
        }
    }

    function registerName(string _nameString, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, ) = playerBook.registerNameXaddrFromDapp.value(msg.value)(msg.sender, _name, address(0), _all);

        uint256 _pID = pIDxAddr_[_addr];

        emit DRSEvents.onNewName(_pID, _addr, _name, _isNewPlayer, _paid, now);
    }

    /**
     * @dev return the price buyer will pay for next 1 individual key.
     * -functionhash- 0x018a25e8
     * @return price for next key bought (in wei format)
     */
    function getBuyPrice() public view returns(uint256)
    {  
        return keyPrice;
    }

    /**
     * @dev returns time left.  dont spam this, you&#39;ll ddos yourself from your node provider
     * -functionhash- 0xc7e284b8
     * @return time left in seconds
     */
    function getTimeLeft() public view returns(uint256)
    {
        uint256 _rID = rID_;

        uint256 _now = now;

        if(_now < round_[_rID].end)
            if(_now > round_[_rID].strt + rndGap_)
                return (round_[_rID].end).sub(_now);
            else
                return (round_[_rID].strt + rndGap_).sub(_now);
        else
            return 0;
    }

    /**
     * @dev returns player earnings per vaults 
     * -functionhash- 0x63066434
     * @return winnings vault
     * @return general vault
     */
    function getPlayerVaults(uint256 _pID) public view returns(uint256, uint256)
    {
        uint256 _rID = rID_;

        uint256 _now = now;

        // if round has ended.  but round end has not been run (so contract has not distributed winnings)
        if(_now > round_[_rID].end && !round_[_rID].ended && round_[_rID].plyr != 0) {
            // if player is winner 
            if(round_[_rID].plyr == _pID) {
                return
                (
                    (plyr_[_pID].win).add(getWin(round_[_rID].pot)),
                    plyr_[_pID].gen
                );
            }
        }

        return (plyr_[_pID].win, plyr_[_pID].gen);
    }

    /**
     * @dev returns all current round info needed for front end
     * -functionhash- 0x747dff42
     * @return round id 
     * @return total keys for round 
     * @return time round ends
     * @return time round started
     * @return current pot

     * @return key price
     * @return current key

     * @return current player ID in lead
     * @return current player address in leads
     * @return current player name in leads
     */
    function getCurrentRoundInfo() public view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32)
    {
        uint256 _rID = rID_;

        uint256 _winPID = round_[_rID].plyr;

        return
        (
            _rID,                           //0
            round_[_rID].end,               //1
            round_[_rID].strt,              //2
            round_[_rID].pot,               //3

            keyPrice,                       //4
            keyBought.add(1),               //5

            _winPID,                        //6
            plyr_[_winPID].addr,            //7
            plyr_[_winPID].name             //8
        );
    }

    /**
     * @dev returns player info based on address.  if no address is given, it will
     * use msg.sender
     * -functionhash- 0xee0b5d8b
     * @param _addr address of the player you want to lookup
     * @return player ID
     * @return player name
     * @return keys owned (current round)
     * @return winnings vault
     * @return general vault
     * @return player round eth
     */
    function getPlayerInfoByAddress(address _addr) public view
        returns(uint256, bytes32, uint256, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;
        
        if(_addr == address(0)) {
            _addr == msg.sender;
        }

        uint256 _pID = pIDxAddr_[_addr];

        if(_pID == 0) {
            return (0, "", 0, 0, 0, 0);
        }

        return
        (
            _pID,                               //0
            plyr_[_pID].name,                   //1
            plyrRnds_[_pID][_rID].keys,         //2
            plyr_[_pID].win,                    //3
            plyr_[_pID].gen,                    //4
            plyrRnds_[_pID][_rID].eth           //5
        );
    }

    /**
     * @dev logic runs whenever a buy order is executed.  determines how to handle 
     * incoming eth depending on if we are in an active round or not
     */
    function buyCore(uint256 _pID, DRSDatasets.EventReturns memory _eventData_) private
    {
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // if round is active
        if(_now >= round_[_rID].strt.add(rndGap_) && (_now <= round_[_rID].end || round_[_rID].plyr == 0)) {
            // call core
            core(_rID, _pID, msg.value, _eventData_);

        // if round is not active
        } else {
            // check to see if end round needs to be ran
            if(_now > round_[_rID].end && !round_[_rID].ended) {
                // end the round (distributes pot) & start new round
                round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                // build event data
                _eventData_ = _eventData_.setTimestamp(_now);
                _eventData_ = _eventData_.setPID(_pID);

                // fire buy and distribute event
                emit DRSEvents.onBuyAndDistribute
                (
                    msg.sender,
                    plyr_[_pID].name,
                    msg.value,
                    _eventData_.compressedData,
                    _eventData_.compressedIDs,

                    _eventData_.winnerAddr,
                    _eventData_.winnerName,
                    _eventData_.amountWon,

                    _eventData_.newPot,
                    _eventData_.genAmount
                );
            }

            // put eth in players vault 
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }

    /**
     * @dev logic runs whenever a reload order is executed.  determines how to handle
     * incoming eth depending on if we are in an active round or not
     */
    function reLoadCore(uint256 _pID, uint256 _eth, DRSDatasets.EventReturns memory _eventData_) private
    {
        uint256 _rID = rID_;

        uint256 _now = now;

        // if round is active
        if(_now > round_[_rID].strt.add(rndGap_) && (_now <= round_[_rID].end || round_[_rID].plyr == 0)) {
            // get earnings from all vaults and return unused to gen vault
            // because we use a custom safemath library.  this will throw if player
            // tried to spend more eth than they have.
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);

            // call core
            core(_rID, _pID, _eth, _eventData_);

        // if round is not active and end round needs to be ran
        } else {
            // check to see if end round needs to be ran
            if(_now > round_[_rID].end && !round_[_rID].ended) {
                // end the round (distributes pot) & start new round
                round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                // build event data
                _eventData_ = _eventData_.setTimestamp(_now);
                _eventData_ = _eventData_.setPID(_pID);

                // fire buy and distribute event
                emit DRSEvents.onReLoadAndDistribute
                (
                    msg.sender,
                    plyr_[_pID].name,
                    _eventData_.compressedData,
                    _eventData_.compressedIDs,

                    _eventData_.winnerAddr,
                    _eventData_.winnerName,
                    _eventData_.amountWon,

                    _eventData_.newPot,
                    _eventData_.genAmount
                );
            }
        }
    }

    /**
     * @dev this is the core logic for any buy/reload that happens while a round is live.
     */
    function core(uint256 _rID, uint256 _pID, uint256 _eth, DRSDatasets.EventReturns memory _eventData_) private
    {
        if(_eth < keyPrice) {
            plyr_[_pID].gen = plyr_[_pID].gen.add(_eth);
            emit onBuyKeyFailure(_rID, _pID, _eth, keyPrice, now);
            return;
        }

        // if player is new to round
        if(plyrRnds_[_pID][_rID].keys == 0) {
            _eventData_ = managePlayer(_pID, _eventData_);
        }

        // mint the new key
        uint256 _keys = 1;

        uint256 _ethUsed = keyPrice;
        uint256 _ethLeft = _eth.sub(keyPrice);

        updateTimer(_rID);

        // set new leaders
        if(round_[_rID].plyr != _pID) {
            round_[_rID].plyr = _pID;
        }

        // set the new leader bool to true
        _eventData_ = _eventData_.setNewLeaderFlag();

        // update player 
        plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
        plyrRnds_[_pID][_rID].eth = _ethUsed.add(plyrRnds_[_pID][_rID].eth);

        // update round
        round_[_rID].keys = _keys.add(round_[_rID].keys);
        round_[_rID].eth = _ethUsed.add(round_[_rID].eth);

        // distribute eth
        uint256 _ethExt = distributeExternal(_ethUsed);
        _eventData_ = distributeInternal(_rID, _ethUsed, _ethExt, _eventData_);

        bytes32 _name = plyr_[_pID].name;

        pushBuyInfo(DRSDatasets.BuyInfo(msg.sender, _name, _pID, keyPrice, keyBought));

        // key index player bought
        uint256 _keyIndex = keyBought;

        keyBought = keyBought.add(1);
        keyPrice = keyPrice.mul(1000 + keyPriceIncreaseRatio).div(1000);

        if(_ethLeft > 0) {
            plyr_[_pID].gen = _ethLeft.add(plyr_[_pID].gen);
        }

        // call end tx function to fire end tx event.
        endTx(_pID, _ethUsed, _keyIndex, _eventData_);
    }

    /**
     * @dev receives name/player info from names contract 
     */
    function receivePlayerInfo(uint256 _pID, address _addr, bytes32 _name) external
    {
        require(msg.sender == address(playerBook), "your not playerNames contract.");

        if(pIDxAddr_[_addr] != _pID)
            pIDxAddr_[_addr] = _pID;

        if(pIDxName_[_name] != _pID)
            pIDxName_[_name] = _pID;

        if(plyr_[_pID].addr != _addr)
            plyr_[_pID].addr = _addr;

        if(plyr_[_pID].name != _name)
            plyr_[_pID].name = _name;

        if(!plyrNames_[_pID][_name])
            plyrNames_[_pID][_name] = true;
    }

    /**
     * @dev receives entire player name list 
     */
    function receivePlayerNameList(uint256 _pID, bytes32 _name) external
    {
        require(msg.sender == address(playerBook), "your not playerNames contract.");

        if(!plyrNames_[_pID][_name])
            plyrNames_[_pID][_name] = true;
    }

    /**
     * @dev gets existing or registers new pID.  use this when a player may be new
     * @return pID 
     */
    function determinePID(DRSDatasets.EventReturns memory _eventData_) private returns(DRSDatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];

        // if player is new to this version of ReserveBag
        if(_pID == 0)
        {
            // grab their player ID, name from player names contract
            _pID = playerBook.getPlayerID(msg.sender);
            bytes32 _name = playerBook.getPlayerName(_pID);

            // set up player account
            pIDxAddr_[msg.sender] = _pID;
            plyr_[_pID].addr = msg.sender;

            if(_name != "")
            {
                pIDxName_[_name] = _pID;
                plyr_[_pID].name = _name;
                plyrNames_[_pID][_name] = true;
            }

            // set the new player bool to true
            _eventData_ = _eventData_.setNewPlayerFlag();
        }

        return _eventData_;
    }

    function managePlayer(uint256 _pID, DRSDatasets.EventReturns memory _eventData_)
        private
        returns(DRSDatasets.EventReturns)
    {
        // update player&#39;s last round played
        plyr_[_pID].lrnd = rID_;

        // set the joined round bool to true
        _eventData_ = _eventData_.setJoinedRoundFlag();
        
        return _eventData_;
    }

    function getWin(uint256 _pot) private pure returns(uint256) {
        return _pot / 2;
    }

    function getDRSCoinDividend(uint256 _pot) private view returns(uint256) {
        return _pot.mul(drsCoinDividendRatio).div(100);
    }

    function getTeamPerfit(uint256 _pot) private view returns(uint256) {
        return _pot.mul(teamPerfitRatio).div(100);
    }

    function mintDRSCoin() private {
        // empty buyinfos
        if(startIndex == endIndex) {
            return;
        }

        // have one element
        if((startIndex + 1) % (rewardInternal + 1) == endIndex) {
            return;
        }

        // have more than one element
        for(uint256 i = startIndex; (i + 1) % (rewardInternal + 1) != endIndex; i = (i + 1) % (rewardInternal + 1)) {
            drsCoin.mint(buyinfos[i].addr, buyinfos[i].keyPrice.mul(ethMintDRSCoinRate).div(100));
        }
    }

    /**
     * @dev ends the round. manages paying out winner/splitting up pot
     */
    function endRound(DRSDatasets.EventReturns memory _eventData_)
        private
        returns(DRSDatasets.EventReturns)
    {
        uint256 _rID = rID_;

        uint256 _winPID = round_[_rID].plyr;

        uint256 _pot = round_[_rID].pot;

        // eth for last player&#39;s prize
        uint256 _win = getWin(_pot);

        // eth for drsCoin dividend
        uint256 _drsCoinDividend = getDRSCoinDividend(_pot);

        // eth for team perfit
        uint256 _com = getTeamPerfit(_pot);

        // eth put to next round&#39;s pot
        uint256 _newPot = _pot.sub(_win).sub(_drsCoinDividend).sub(_com);

        // deposit team perfit
        depositTeamPerfit(_com);

        // pay our winner
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

        // mint DRSCoin
        mintDRSCoin();

        // distribute eth to drsCoin holders
        drsCoin.profitEth.value(_drsCoinDividend)();

        // prepare event data
        _eventData_ = _eventData_.setRoundEndTime(round_[_rID].end);
        _eventData_ = _eventData_.setWinPID(_winPID);
        _eventData_ = _eventData_.setWinner(plyr_[_winPID].addr, plyr_[_winPID].name, _win);
        _eventData_ = _eventData_.setNewPot(_newPot);

        // start next round
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndMax_).add(rndGap_);

        keyPrice = initKeyPrice;
        keyBought = 0;

        startIndex = 0;
        endIndex = 0;

        // add rest eth to next round&#39;s pot
        round_[_rID].pot = _newPot;

        return _eventData_;
    }

    /**
     * @dev updates round timer based on number of whole keys bought.
     */
    function updateTimer(uint256 _rID) private
    {
        round_[_rID].end = rndMax_.add(now);
    }

    function depositTeamPerfit(uint256 _eth) private {
        if(teamPerfit == address(0)) {
            teamPerfitAmuont = teamPerfitAmuont.add(_eth);
            return;
        }

        bool res = teamPerfit.deposit.value(_eth)();
        if(!res) {
            teamPerfitAmuont = teamPerfitAmuont.add(_eth);
            return;
        }
    }

    /**
     * @dev distributes eth based on fees to team
     */
    function distributeExternal(uint256 _eth) private returns(uint256)
    {
        // pay 2% out to community rewards
        uint256 _com = _eth / 50;

        depositTeamPerfit(_com);

        return _com;
    }

    /**
     * @dev distributes eth based on fees to gen and pot
     */
    function distributeInternal(uint256 _rID, uint256 _eth, uint256 _ethExt, DRSDatasets.EventReturns memory _eventData_)
        private
        returns(DRSDatasets.EventReturns)
    {
        uint256 _gen = 0;
        uint256 _pot = 0;

        if(keyBought < rewardInternal) {
            _gen = 0;
            _pot = _eth.sub(_ethExt);
        } else {
            _gen = _eth.mul(genRatio).div(100);
            _pot = _eth.sub(_ethExt).sub(_gen);

            DRSDatasets.BuyInfo memory info = buyinfos[startIndex];

            uint256 firstPID = info.pid;
            plyr_[firstPID].gen = _gen.add(plyr_[firstPID].gen);

            _eventData_.setGenInfo(info.addr, info.keyPrice);
        }

        if(_pot > 0) {
            round_[_rID].pot = _pot.add(round_[_rID].pot);
        }

        _eventData_.setGenAmount(_gen.add(_eventData_.genAmount));
        _eventData_.setPotAmount(_pot);

        return _eventData_;
    }

    /**
     * @dev adds up unmasked earnings, & vault earnings, sets them all to 0
     * @return earnings in wei format
     */
    function withdrawEarnings(uint256 _pID) private returns(uint256)
    {
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen);
        if(_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
        }

        return _earnings;
    }

    /**
     * @dev prepares compression data and fires event for buy or reload tx&#39;s
     */
    function endTx(uint256 _pID, uint256 _eth, uint256 _keyIndex, DRSDatasets.EventReturns memory _eventData_) private
    {
        _eventData_ = _eventData_.setTimestamp(now);
        _eventData_ = _eventData_.setPID(_pID);
        _eventData_ = _eventData_.setRID(rID_);

        emit DRSEvents.onEndTx
        (
            _eventData_.compressedData,
            _eventData_.compressedIDs,

            plyr_[_pID].name,
            msg.sender,
            _eth,
            _keyIndex,

            _eventData_.winnerAddr,
            _eventData_.winnerName,
            _eventData_.amountWon,

            _eventData_.newPot,
            _eventData_.genAmount,
            _eventData_.potAmount,

            _eventData_.genAddr,
            _eventData_.genKeyPrice
        );
    }

    modifier isActivated() {
        require(activated_, "its not activated yet.");
        _;
    }

    function activate() onlyOwner() public
    {
        // can only be ran once
        require(!activated_, "ReserveBag already activated");

        uint256 _now = now;

        // activate the contract 
        activated_ = true;

        // lets start first round
        rID_ = 1;
        round_[1].strt = _now.add(rndExtra_).sub(rndGap_);
        round_[1].end = _now.add(rndMax_).add(rndExtra_);
    }

    function getActivated() public view returns(bool) {
        return activated_;
    }

    function setTeamPerfitAddress(address _newTeamPerfitAddress) onlyOwner() public {
        teamPerfit = TeamPerfitForwarderInterface(_newTeamPerfitAddress);
    }

    function setPlayerBookAddress(address _newPlayerBookAddress) onlyOwner() public {
        playerBook = PlayerBookInterface(_newPlayerBookAddress);
    }

    function setDRSCoinAddress(address _newDRSCoinAddress) onlyOwner() public {
        drsCoin = DRSCoinInterface(_newDRSCoinAddress);
    }
}