pragma solidity ^0.4.24;

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



//==============================================================================
//   __|_ _    __|_ _  .
//  _\ | | |_|(_ | _\  .
//==============================================================================
library F3Ddatasets {
    //compressedData key
    // [76-33][32][31][30][29][28-18][17][16-6][5-3][2][1][0]
        // 0 - new player (bool)
        // 1 - joined round (bool)
        // 2 - new  leader (bool)
        // 3-5 - air drop tracker (uint 0-999)
        // 6-16 - round end time
        // 17 - winnerTeam
        // 18 - 28 timestamp
        // 29 - team
        // 30 - 0 = reinvest (round), 1 = buy (round), 2 = buy (ico), 3 = reinvest (ico)
        // 31 - airdrop happened bool
        // 32 - airdrop tier
        // 33 - airdrop amount won
        
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
        uint256 P3DAmount;          // amount distributed to p3d
        uint256 genAmount;          // amount distributed to gen
        uint256 potAmount;          // amount added to pot
    }
    struct Player {
        address addr;   // player address
        bytes32 name;   // player name
        uint256 win;    // winnings vault
        uint256 gen;    // general vault
        uint256 aff;    // affiliate vault
        uint256 lrnd;   // last round played
        uint256 laff;   // last affiliate id used
    }
    struct PlayerRounds {
        uint256 eth;    // eth player has added to round (used for eth limiter)
        uint256 keys;   // keys
        uint256 mask;   // player mask
        uint256 ico;    // ICO phase investment
    }
    struct Round {
        uint256 plyr;   // pID of player in lead
        uint256 team;   // tID of team in lead
        uint256 end;    // time ends/ended
        bool ended;     // has round end function been ran
        uint256 strt;   // time round started
        uint256 keys;   // keys
        uint256 eth;    // total eth in
        uint256 pot;    // eth to pot (during round) / final amount paid to winner (after round ends)
        uint256 mask;   // global mask
        uint256 ico;    // total eth sent in during ICO phase
        uint256 icoGen; // total eth for gen during ICO phase
        uint256 icoAvg; // average key price for ICO phase
    }
    struct TeamFee {
        uint256 gen;    // % of buy in thats paid to key holders of current round
        uint256 p3d;    // % of buy in thats paid to p3d holders
    }
    struct PotSplit {
        uint256 gen;    // % of pot thats paid to key holders of current round
        uint256 p3d;    // % of pot thats paid to p3d holders
    }
}

//==============================================================================
//  |  _      _ _ | _  .
//  |<(/_\/  (_(_||(_  .
//=======/======================================================================
library F3DKeysCalcShort {
    using SafeMath for *;
    /**
     * @dev calculates number of keys received given X eth
     * @param _curEth current amount of eth in contract
     * @param _newEth eth being spent
     * @return amount of ticket purchased
     */
    function keysRec(uint256 _curEth, uint256 _newEth)
        internal
        pure
        returns (uint256)
    {
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }

    /**
     * @dev calculates amount of eth received if you sold X keys
     * @param _curKeys current amount of keys that exist
     * @param _sellKeys amount of keys you wish to sell
     * @return amount of eth received
     */
    function ethRec(uint256 _curKeys, uint256 _sellKeys)
        internal
        pure
        returns (uint256)
    {
        return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }

    /**
     * @dev calculates how many keys would exist with given an amount of eth
     * @param _eth eth "in contract"
     * @return number of keys that would exist
     */
    function keys(uint256 _eth)
        internal
        pure
        returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
    }

    /**
     * @dev calculates how much eth would be in contract given a number of keys
     * @param _keys number of keys "in contract"
     * @return eth that would exists
     */
    function eth(uint256 _keys)
        internal
        pure
        returns(uint256)
    {
        return ((78125000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
    }
}

//==============================================================================
//  . _ _|_ _  _ |` _  _ _  _  .
//  || | | (/_| ~|~(_|(_(/__\  .
//==============================================================================


contract F3Devents {
    // fired whenever a player registers a name
    event onNewName
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        bool isNewPlayer,
        uint256 affiliateID,
        address affiliateAddress,
        bytes32 affiliateName,
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
        uint256 keysBought,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 P3DAmount,
        uint256 genAmount,
        uint256 potAmount,
        uint256 airDropPot
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
        uint256 P3DAmount,
        uint256 genAmount
    );

    // (fomo3d short only) fired whenever a player tries a buy after round timer
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
        uint256 P3DAmount,
        uint256 genAmount
    );

    // (fomo3d short only) fired whenever a player tries a reload after round timer
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
        uint256 P3DAmount,
        uint256 genAmount
    );

    // fired whenever an affiliate is paid
    event onAffiliatePayout
    (
        uint256 indexed affiliateID,
        address affiliateAddress,
        bytes32 affiliateName,
        uint256 indexed roundID,
        uint256 indexed buyerID,
        uint256 amount,
        uint256 timeStamp
    );

    // received pot swap deposit
    event onPotSwapDeposit
    (
        uint256 roundID,
        uint256 amountAddedToPot
    );
}




interface PlayerBookInterface {
    function getPlayerID(address _addr) external returns (uint256);
    function getPlayerName(uint256 _pID) external view returns (bytes32);
    function getPlayerLAff(uint256 _pID) external view returns (uint256);
    function getPlayerAddr(uint256 _pID) external view returns (address);
    function getNameFee() external view returns (uint256);
    function registerNameXIDFromDapp(address _addr, bytes32 _name, uint256 _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXaddrFromDapp(address _addr, bytes32 _name, address _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXnameFromDapp(address _addr, bytes32 _name, bytes32 _affCode, bool _all) external payable returns(bool, uint256);
}



contract modularFast is F3Devents {}


contract FoMo3DFast is modularFast {
    using SafeMath for *;
    using NameFilter for string;
    using F3DKeysCalcShort for uint256;

    PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0x990116637aa0e6fBf1549908C079385a38A1B4bC);

    address private admin = msg.sender;
    string constant public name = "OTION";
    string constant public symbol = "OTION";
    uint256 private rndExtra_ = 30 minutes;     // length of the very first ICO
    uint256 private rndGap_ = 30 minutes;         // length of ICO phase, set to 1 year for EOS.
    uint256 constant private rndInit_ = 888 minutes;                // round timer starts at this
    uint256 constant private rndInc_ = 20 seconds;              // every full key purchased adds this much to the timer
    uint256 constant private rndMax_ = 888 minutes;                // max length a round timer can be
    uint256 public airDropPot_;             // person who gets the airdrop wins part of this pot
    uint256 public airDropTracker_ = 0;     // incremented each time a "qualified" tx occurs.  used to determine winning air drop
    uint256 public rID_;    // round id number / total rounds that have happened
    //****************
    // PLAYER DATA
    //****************
    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping (bytes32 => uint256) public pIDxName_;          // (name => pID) returns player id by name
    mapping (uint256 => F3Ddatasets.Player) public plyr_;   // (pID => data) player data
    // (pID => rID => data) player round data by player id & round id
    mapping (uint256 => mapping (uint256 => F3Ddatasets.PlayerRounds)) public plyrRnds_;
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_; // (pID => name => bool) list of names a player owns.  (used so you can change your display name amongst any name you own)
    //****************
    // ROUND DATA
    //****************
    mapping (uint256 => F3Ddatasets.Round) public round_;   // (rID => data) round data
    mapping (uint256 => mapping(uint256 => uint256)) public rndTmEth_;      // (rID => tID => data) eth in per team, by round id and team id
    //****************
    // TEAM FEE DATA
    //****************
    mapping (uint256 => F3Ddatasets.TeamFee) public fees_;          // (team => fees) fee distribution by team
    mapping (uint256 => F3Ddatasets.PotSplit) public potSplit_;     // (team => fees) pot split distribution by team

    constructor()
        public
    {
    // Team allocation structures
        // 0 = the only team
        

    // Team allocation percentages
        // (F3D, P3D) + (Pot , Referrals, Community)  解读:TeamFee, PotSplit 第一个参数都是分给现在key holder的比例, 第二个是给Pow3D的比例
            // Referrals / Community rewards are mathematically designed to come from the winner&#39;s share of the pot.
        fees_[0] = F3Ddatasets.TeamFee(80,0);   //10% to pot, 8% to aff, 2% to com

        // how to split up the final pot based on which team was picked
        // (F3D, P3D)
        potSplit_[0] = F3Ddatasets.PotSplit(0,0);  //100% to winner
    }
    //==============================================================================
    //     _ _  _  _|. |`. _  _ _  .
    //    | | |(_)(_||~|~|(/_| _\  .  (these are safety checks)
    //==============================================================================
    /**
    * @dev used to make sure no one can interact with contract until it has
    * been activated.
    */
    modifier isActivated() {
        require(activated_ == true, "its not ready yet.  check ?eta in discord");
        _;
    }

    /**
    * @dev prevents contracts from interacting with fomo3d
    */
    modifier isHuman() {
        address _addr = msg.sender;
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
        _;
    }

    //==============================================================================
    //     _    |_ |. _   |`    _  __|_. _  _  _  .
    //    |_)|_||_)||(_  ~|~|_|| |(_ | |(_)| |_\  .  (use these to interact with contract)
    //====|=========================================================================
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
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];

        // buy core
        buyCore(_pID, _eventData_);
    }



    function buyXnameQR(address _realSender)
        isActivated()
        isWithinLimits(msg.value)
        public
        payable
    {
        // set up our tx event data and determine if player is new or not
        F3Ddatasets.EventReturns memory _eventData_ = determinePIDQR(_realSender,_eventData_);

        // fetch player id
        uint256 _pID = pIDxAddr_[_realSender];

        // // manage affiliate residuals
        // uint256 _affID = 1;
        
        // // verify a valid team was selected
        // uint256 _team = 0;

        // buy core
        buyCoreQR(_realSender, _pID, _eventData_);
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
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // setup temp var for player eth
        uint256 _eth;

        // check to see if round has ended and no one has run round end yet
        if (_now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
            // set up our tx event data
            F3Ddatasets.EventReturns memory _eventData_;

            // end the round (distributes pot)
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

            // get their earnings
            _eth = withdrawEarnings(_pID);

            // gib moni
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

            // build event data
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            // fire withdraw and distribute event
            emit F3Devents.onWithdrawAndDistribute
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
                _eventData_.P3DAmount,
                _eventData_.genAmount
            );

        // in any other situation
        } else {
            // get their earnings
            _eth = withdrawEarnings(_pID);

            // gib moni
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

            // fire withdraw event
            emit F3Devents.onWithdraw(_pID, msg.sender, plyr_[_pID].name, _eth, _now);
        }
    }

    /**
    * @dev withdraws all of your earnings.
    * -functionhash- 0x3ccfd60b
    */
    function withdrawQR(address _realSender)
        isActivated()
        payable
        public
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // fetch player ID
        uint256 _pID = pIDxAddr_[_realSender];

        // setup temp var for player eth
        uint256 _eth;

        // check to see if round has ended and no one has run round end yet
        if (_now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
            // set up our tx event data
            F3Ddatasets.EventReturns memory _eventData_;

            // end the round (distributes pot)
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

            // get their earnings
            _eth = withdrawEarnings(_pID);

            // gib moni
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

            // build event data
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            // fire withdraw and distribute event
            emit F3Devents.onWithdrawAndDistribute
            (
                _realSender,
                plyr_[_pID].name,
                _eth,
                _eventData_.compressedData,
                _eventData_.compressedIDs,
                _eventData_.winnerAddr,
                _eventData_.winnerName,
                _eventData_.amountWon,
                _eventData_.newPot,
                _eventData_.P3DAmount,
                _eventData_.genAmount
            );

        // in any other situation
        } else {
            // get their earnings
            _eth = withdrawEarnings(_pID);

            // gib moni
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

            // fire withdraw event
            emit F3Devents.onWithdraw(_pID, _realSender, plyr_[_pID].name, _eth, _now);
        }
    }


    //==============================================================================
    //     _  _ _|__|_ _  _ _  .
    //    (_|(/_ |  | (/_| _\  . (for UI & viewing things on etherscan)
    //=====_|=======================================================================
    /**
    * @dev return the price buyer will pay for next 1 individual key.
    * -functionhash- 0x018a25e8
    * @return price for next key bought (in wei format)
    */
    function getBuyPrice()
        public
        view
        returns(uint256)
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // are we in a round?
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
        else // rounds over.  need price for new round
            return ( 75000000000000 ); // init
    }

    /**
    * @dev returns time left.  dont spam this, you&#39;ll ddos yourself from your node
    * provider
    * -functionhash- 0xc7e284b8
    * @return time left in seconds
    */
    function getTimeLeft()
        public
        view
        returns(uint256)
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        if (_now < round_[_rID].end)
            if (_now > round_[_rID].strt + rndGap_)
                return( (round_[_rID].end).sub(_now) );
            else
                return( (round_[_rID].strt + rndGap_).sub(_now) );
        else
            return(0);
    }

    /**
    * @dev returns player earnings per vaults
    * -functionhash- 0x63066434
    * @return winnings vault
    * @return general vault
    * @return affiliate vault
    */
    function getPlayerVaults(uint256 _pID)
        public
        view
        returns(uint256 ,uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;

        // if round has ended.  but round end has not been run (so contract has not distributed winnings)
        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
            // if player is winner
            if (round_[_rID].plyr == _pID)
            {
                return
                (
                    (plyr_[_pID].win).add(((round_[_rID].pot))),
                    (plyr_[_pID].gen).add(getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)),
                    plyr_[_pID].aff
                );
            // if player is not the winner
            } else {
                return
                (
                    plyr_[_pID].win,
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)  ),
                    plyr_[_pID].aff
                );
            }

        // if round is still going on, or round has ended and round end has been ran
        } else {
            return
            (
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),
                plyr_[_pID].aff
            );
        }
    }

    /**
    * solidity hates stack limits.  this lets us avoid that hate
    */
    function getPlayerVaultsHelper(uint256 _pID, uint256 _rID)
        private
        view
        returns(uint256)
    {
        return(  ((((round_[_rID].mask).add(((((round_[_rID].pot).mul(potSplit_[round_[_rID].team].gen)) / 100).mul(1000000000000000000)) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / 1000000000000000000)  );
    }

    /**
    * @dev returns all current round info needed for front end
    * -functionhash- 0x747dff42
    * @return eth invested during ICO phase
    * @return round id
    * @return total keys for round
    * @return time round ends
    * @return time round started
    * @return current pot
    * @return current team ID & player ID in lead
    * @return current player in leads address
    * @return current player in leads name
    * @return eth in total
    * @return 0
    * @return 0
    * @return 0
    * @return airdrop tracker # & airdrop pot
    */
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;

        return
        (
            round_[_rID].ico,               //0
            _rID,                           //1
            round_[_rID].keys,              //2
            round_[_rID].end,               //3
            round_[_rID].strt,              //4
            round_[_rID].pot,               //5
            (round_[_rID].team + (round_[_rID].plyr * 10)),     //6
            plyr_[round_[_rID].plyr].addr,  //7
            plyr_[round_[_rID].plyr].name,  //8
            rndTmEth_[_rID][0],             //9
            rndTmEth_[_rID][1],             //10
            rndTmEth_[_rID][2],             //11
            rndTmEth_[_rID][3],             //12
            airDropTracker_ + (airDropPot_ * 1000)              //13
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
    * @return affiliate vault
    * @return player round eth
    */
    function getPlayerInfoByAddress(address _addr)
        public
        view
        returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;

        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];

        return
        (
            _pID,                               //0
            plyr_[_pID].name,                   //1
            plyrRnds_[_pID][_rID].keys,         //2
            plyr_[_pID].win,                    //3
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),       //4
            plyr_[_pID].aff,                    //5
            plyrRnds_[_pID][_rID].eth           //6
        );
    }

    //==============================================================================
    //     _ _  _ _   | _  _ . _  .
    //    (_(_)| (/_  |(_)(_||(_  . (this + tools + calcs + modules = our softwares engine)
    //=====================_|=======================================================
    /**
    * @dev logic runs whenever a buy order is executed.  determines how to handle
    * incoming eth depending on if we are in an active round or not
    */
    function buyCore(uint256 _pID, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;
        uint256 _affID = 1;
        uint256 _team = 0;

        // if round is active
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
            // call core
            core(address(0), _rID, _pID, msg.value, _affID, _team, _eventData_);

        // if round is not active
        } else {
            // check to see if end round needs to be ran
            if (_now > round_[_rID].end && round_[_rID].ended == false)
            {
                // end the round (distributes pot) & start new round
                round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                // build event data
                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

                // fire buy and distribute event
                emit F3Devents.onBuyAndDistribute
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
                    _eventData_.P3DAmount,
                    _eventData_.genAmount
                );
            }

            // put eth in players vault
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }

    /**
    * @dev logic runs whenever a buy order is executed.  determines how to handle
    * incoming eth depending on if we are in an active round or not
    */
    function buyCoreQR(address _realSender, uint256 _pID, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;
        uint256 _affID = 1;
        uint256 _team = 0;

        // if round is active
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
            // call core
            core(_realSender,_rID, _pID, msg.value, _affID, _team, _eventData_);

        // if round is not active
        } else {
            // check to see if end round needs to be ran
            if (_now > round_[_rID].end && round_[_rID].ended == false)
            {
                // end the round (distributes pot) & start new round
                round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                // build event data
                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

                // fire buy and distribute event
                emit F3Devents.onBuyAndDistribute
                (
                    _realSender,
                    plyr_[_pID].name,
                    msg.value,
                    _eventData_.compressedData,
                    _eventData_.compressedIDs,
                    _eventData_.winnerAddr,
                    _eventData_.winnerName,
                    _eventData_.amountWon,
                    _eventData_.newPot,
                    _eventData_.P3DAmount,
                    _eventData_.genAmount
                );
            }

            // put eth in players vault
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }

    /**
    * @dev this is the core logic for any buy/reload that happens while a round
    * is live.
    */
    function core(address _realSender, uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        // if player is new to round
        if (plyrRnds_[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);

        // early round eth limiter
        if (round_[_rID].eth < 100000000000000000000 && plyrRnds_[_pID][_rID].eth.add(_eth) > 1000000000000000000)
        {
            uint256 _availableLimit = (1000000000000000000).sub(plyrRnds_[_pID][_rID].eth);
            uint256 _refund = _eth.sub(_availableLimit);
            plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
            _eth = _availableLimit;
        }

        // if eth left is greater than min eth allowed (sorry no pocket lint)
        if (_eth > 1000000000)
        {

            // mint the new keys
            uint256 _keys = (round_[_rID].eth).keysRec(_eth);

            // if they bought at least 1 whole key
            if (_keys >= 1000000000000000000)
            {
                updateTimer(_keys, _rID);

                // set new leaders
                if (round_[_rID].plyr != _pID)
                    round_[_rID].plyr = _pID;
                if (round_[_rID].team != _team)
                    round_[_rID].team = _team;

                // set the new leader bool to true
                _eventData_.compressedData = _eventData_.compressedData + 100;
            }

            // update player
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

            // update round
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndTmEth_[_rID][_team] = _eth.add(rndTmEth_[_rID][_team]);

            // distribute eth
            _eventData_ = distributeExternal(_rID, _pID, _eth, _affID, _team, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _team, _keys, _eventData_);

            // call end tx function to fire end tx event.
            endTxQR(_realSender,_pID, _team, _eth, _keys, _eventData_);
        }
    }


  //==============================================================================
  //     _ _ | _   | _ _|_ _  _ _  .
  //    (_(_||(_|_||(_| | (_)| _\  .
  //==============================================================================
      /**
       * @dev calculates unmasked earnings (just calculates, does not update mask)
       * @return earnings in wei format
       */
      function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast)
          private
          view
          returns(uint256)
      {
          return(  (((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask)  );
      }

      /**
       * @dev returns the amount of keys you would get given an amount of eth.
       * -functionhash- 0xce89c80c
       * @param _rID round ID you want price for
       * @param _eth amount of eth sent in
       * @return keys received
       */
      function calcKeysReceived(uint256 _rID, uint256 _eth)
          public
          view
          returns(uint256)
      {
          // grab time
          uint256 _now = now;

          // are we in a round?
          if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
              return ( (round_[_rID].eth).keysRec(_eth) );
          else // rounds over.  need keys for new round
              return ( (_eth).keys() );
      }

      /**
       * @dev returns current eth price for X keys.
       * -functionhash- 0xcf808000
       * @param _keys number of keys desired (in 18 decimal format)
       * @return amount of eth needed to send
       */
      function iWantXKeys(uint256 _keys)
          public
          view
          returns(uint256)
      {
          // setup local rID
          uint256 _rID = rID_;

          // grab time
          uint256 _now = now;

          // are we in a round?
          if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
              return ( (round_[_rID].keys.add(_keys)).ethRec(_keys) );
          else // rounds over.  need price for new round
              return ( (_keys).eth() );
      }
  //==============================================================================
  //    _|_ _  _ | _  .
  //     | (_)(_)|_\  .
  //==============================================================================
      /**
  	 * @dev receives name/player info from names contract
       */
      function receivePlayerInfo(uint256 _pID, address _addr, bytes32 _name, uint256 _laff)
          external
      {
          require (msg.sender == address(PlayerBook), "your not playerNames contract... hmmm..");
          if (pIDxAddr_[_addr] != _pID)
              pIDxAddr_[_addr] = _pID;
          if (pIDxName_[_name] != _pID)
              pIDxName_[_name] = _pID;
          if (plyr_[_pID].addr != _addr)
              plyr_[_pID].addr = _addr;
          if (plyr_[_pID].name != _name)
              plyr_[_pID].name = _name;
          if (plyr_[_pID].laff != _laff)
              plyr_[_pID].laff = _laff;
          if (plyrNames_[_pID][_name] == false)
              plyrNames_[_pID][_name] = true;
      }

      /**
       * @dev receives entire player name list
       */
      function receivePlayerNameList(uint256 _pID, bytes32 _name)
          external
      {
          require (msg.sender == address(PlayerBook), "your not playerNames contract... hmmm..");
          if(plyrNames_[_pID][_name] == false)
              plyrNames_[_pID][_name] = true;
      }

      /**
       * @dev gets existing or registers new pID.  use this when a player may be new
       * @return pID
       */
      function determinePID(F3Ddatasets.EventReturns memory _eventData_)
          private
          returns (F3Ddatasets.EventReturns)
      {
          uint256 _pID = pIDxAddr_[msg.sender];
          // if player is new to this version of fomo3d
          if (_pID == 0)
          {
              // grab their player ID, name and last aff ID, from player names contract
              _pID = PlayerBook.getPlayerID(msg.sender);
              bytes32 _name = PlayerBook.getPlayerName(_pID);
              uint256 _laff = PlayerBook.getPlayerLAff(_pID);

              // set up player account
              pIDxAddr_[msg.sender] = _pID;
              plyr_[_pID].addr = msg.sender;

              if (_name != "")
              {
                  pIDxName_[_name] = _pID;
                  plyr_[_pID].name = _name;
                  plyrNames_[_pID][_name] = true;
              }

              if (_laff != 0 && _laff != _pID)
                  plyr_[_pID].laff = _laff;

              // set the new player bool to true
              _eventData_.compressedData = _eventData_.compressedData + 1;
          }
          return (_eventData_);
      }


    /**
    * @dev gets existing or registers new pID.  use this when a player may be new
    * @return pID
    */
    function determinePIDQR(address _realSender, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns (F3Ddatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[_realSender];
        // if player is new to this version of fomo3d
        if (_pID == 0)
        {
            // grab their player ID, name and last aff ID, from player names contract
            _pID = PlayerBook.getPlayerID(_realSender);
            bytes32 _name = PlayerBook.getPlayerName(_pID);
            uint256 _laff = PlayerBook.getPlayerLAff(_pID);

            // set up player account
            pIDxAddr_[_realSender] = _pID;
            plyr_[_pID].addr = _realSender;

            if (_name != "")
            {
                pIDxName_[_name] = _pID;
                plyr_[_pID].name = _name;
                plyrNames_[_pID][_name] = true;
            }

            if (_laff != 0 && _laff != _pID)
                plyr_[_pID].laff = _laff;

            // set the new player bool to true
            _eventData_.compressedData = _eventData_.compressedData + 1;
        }
        return (_eventData_);
    }

      /**
       * @dev checks to make sure user picked a valid team.  if not sets team
       * to default (sneks)
       */
      function verifyTeam(uint256 _team)
          private
          pure
          returns (uint256)
      {
          if (_team < 0 || _team > 3)
              return(2);
          else
              return(_team);
      }

      /**
       * @dev decides if round end needs to be run & new round started.  and if
       * player unmasked earnings from previously played rounds need to be moved.
       */
      function managePlayer(uint256 _pID, F3Ddatasets.EventReturns memory _eventData_)
          private
          returns (F3Ddatasets.EventReturns)
      {
          // if player has played a previous round, move their unmasked earnings
          // from that round to gen vault.
          if (plyr_[_pID].lrnd != 0)
              updateGenVault(_pID, plyr_[_pID].lrnd);

          // update player&#39;s last round played
          plyr_[_pID].lrnd = rID_;

          // set the joined round bool to true
          _eventData_.compressedData = _eventData_.compressedData + 10;

          return(_eventData_);
      }

    /**
    * @dev ends the round. manages paying out winner/splitting up pot
    */
    function endRound(F3Ddatasets.EventReturns memory _eventData_)
        private
        returns (F3Ddatasets.EventReturns)
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab our winning player and team id&#39;s
        uint256 _winPID = round_[_rID].plyr;
        uint256 _winTID = round_[_rID].team;

        // grab our pot amount
        uint256 _pot = round_[_rID].pot;

        // calculate our winner share, community rewards, gen share,
        // p3d share, and amount reserved for next pot
        uint256 _win = _pot;
        uint256 _gen = 0;
        uint256 _p3d = 0;
        uint256 _res = 0; // actually 0 eth to the next round

        // calculate ppt for round mask
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);

        // pay our winner
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

        // distribute gen portion to key holders
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

        // prepare event data
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000) + (_winTID * 100000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = plyr_[_winPID].name;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.P3DAmount = _p3d;
        _eventData_.newPot = _res;

        // start next round
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_).add(rndGap_);
        round_[_rID].pot = _res;

        return(_eventData_);
    }

    /**
    * @dev moves any unmasked earnings to gen vault.  updates earnings mask
    */
    function updateGenVault(uint256 _pID, uint256 _rIDlast)
        private
    {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rIDlast);
        if (_earnings > 0)
        {
            // put in gen vault
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
            // zero out their earnings by updating mask
            plyrRnds_[_pID][_rIDlast].mask = _earnings.add(plyrRnds_[_pID][_rIDlast].mask);
        }
    }

    /**
    * @dev updates round timer based on number of whole keys bought.
    */
    function updateTimer(uint256 _keys, uint256 _rID)
        private
    {
        // grab time
        uint256 _now = now;

        // calculate time based on number of keys bought
        uint256 _newTime;
        if (_now > round_[_rID].end && round_[_rID].plyr == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round_[_rID].end);

        // compare to max and set new end time
        if (_newTime < (rndMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = rndMax_.add(_now);
    }


    /**
    * @dev distributes eth based on fees to com, aff, and p3d
    */
    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns(F3Ddatasets.EventReturns)
    {
        // pay 2% out to developers rewards
        uint256 _p3d = _eth / 50;

        // distribute share to running team
        uint256 _aff = _eth.mul(8) / 100;

        // decide what to do with affiliate share of fees
        // affiliate must not be self, and must have a name registered
        plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
        emit F3Devents.onAffiliatePayout(_affID, plyr_[_affID].addr, plyr_[_affID].name, _rID, _pID, _aff, now);

        // pay out p3d
        _p3d = _p3d.add((_eth.mul(fees_[_team].p3d)) / (100));
        if (_p3d > 0)
        {
            // deposit to divies contract
            admin.transfer(_p3d);
            // set up event data
            _eventData_.P3DAmount = _p3d.add(_eventData_.P3DAmount);
        }
        return(_eventData_);
    }

    function potSwap()
        external
        payable
    {
        // setup local rID
        uint256 _rID = rID_ + 1;

        round_[_rID].pot = round_[_rID].pot.add(msg.value);
        emit F3Devents.onPotSwapDeposit(_rID, msg.value);
    }

    /**
    * @dev distributes eth based on fees to gen and pot
    */
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _team, uint256 _keys, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns(F3Ddatasets.EventReturns)
    {
        // calculate gen share
        uint256 _gen = (_eth.mul(fees_[_team].gen)) / 100;

        // distribute 10% to pot
        uint256 _potAmount = _eth / 10;

        // distribute gen share (thats what updateMasks() does) and adjust
        // balances for dust.
        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);

        // add eth to pot
        round_[_rID].pot = _potAmount.add(_dust).add(round_[_rID].pot);

        // set up event data
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _potAmount;

        return(_eventData_);
    }


      /**
       * @dev updates masks for round and player when keys are bought
       * @return dust left over
       */
      function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys)
          private
          returns(uint256)
      {
          /* MASKING NOTES
              earnings masks are a tricky thing for people to wrap their minds around.
              the basic thing to understand here.  is were going to have a global
              tracker based on profit per share for each round, that increases in
              relevant proportion to the increase in share supply.

              the player will have an additional mask that basically says "based
              on the rounds mask, my shares, and how much i&#39;ve already withdrawn,
              how much is still owed to me?"
          */

          // calc profit per key & round mask based on this buy:  (dust goes to pot)
          uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
          round_[_rID].mask = _ppt.add(round_[_rID].mask);

          // calculate player earning from their own buy (only based on the keys
          // they just bought).  & update player earnings mask
          uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
          plyrRnds_[_pID][_rID].mask = (((round_[_rID].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds_[_pID][_rID].mask);

          // calculate & return dust
          return(_gen.sub((_ppt.mul(round_[_rID].keys)) / (1000000000000000000)));
      }

    /**
    * @dev adds up unmasked earnings, & vault earnings, sets them all to 0
    * @return earnings in wei format
    */
    function withdrawEarnings(uint256 _pID)
        private
        returns(uint256)
    {
        // update gen vault
        updateGenVault(_pID, plyr_[_pID].lrnd);

        // from vaults
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
        }

        return(_earnings);
    }

    /**
    * @dev prepares compression data and fires event for buy or reload tx&#39;s
    */
    function endTxQR(address _realSender,uint256 _pID, uint256 _team, uint256 _eth, uint256 _keys, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000) + (_team * 100000000000000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (rID_ * 10000000000000000000000000000000000000000000000000000);

        emit F3Devents.onEndTx
        (
            _eventData_.compressedData,
            _eventData_.compressedIDs,
            plyr_[_pID].name,
            _realSender,
            _eth,
            _keys,
            _eventData_.winnerAddr,
            _eventData_.winnerName,
            _eventData_.amountWon,
            _eventData_.newPot,
            _eventData_.P3DAmount,
            _eventData_.genAmount,
            _eventData_.potAmount,
            airDropPot_
        );
    }

  //==============================================================================
  //    (~ _  _    _._|_    .
  //    _)(/_(_|_|| | | \/  .
  //====================/=========================================================
      /** upon contract deploy, it will be deactivated.  this is a one time
       * use function that will activate the contract.  we do this so devs
       * have time to set things up on the web end                            **/
      bool public activated_ = false;
      function activate()
          public
      {
          // only team just can activate
          require(msg.sender == admin, "only admin can activate");


          // can only be ran once
          require(activated_ == false, "FOMO Short already activated");

          // activate the contract
          activated_ = true;

          // lets start first round
          rID_ = 1;
              round_[1].strt = now + rndExtra_ - rndGap_;
              round_[1].end = now + rndInit_ + rndExtra_;
      }
  }