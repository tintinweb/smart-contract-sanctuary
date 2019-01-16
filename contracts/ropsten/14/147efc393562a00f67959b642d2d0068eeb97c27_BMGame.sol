pragma solidity ^0.4.24;



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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
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

library BMKeysCalcLong {
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
library BMDatasets {
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
        uint256 genAmount;          // amount distributed to gen
        uint256 potAmount;          // amount added to pot
    }
    struct Player {
        address addr;   // player address
        uint256 win;    // winnings vault
        uint256 gen;    // general vault
        uint256 lrnd;   // last round played
    }

    struct PlayerRounds {
        uint256 eth;    // eth player has added to round (used for eth limiter)
        uint256 keys;   // keys
        uint256 mask;   // player mask 
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
    }
    struct TeamFee {
        uint256 gen;    // % of buy in thats paid to key holders of current round
    }
    struct PotSplit {
        uint256 gen;    // % of pot thats paid to key holders of current round
    }
}
contract BMEvents {
    
    // fired at end of buy or reload
    event onEndTx
    (
        uint256 compressedData,     
        uint256 compressedIDs,      
        address playerAddress,
        uint256 ethIn,
        uint256 keysBought,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount,
        uint256 potAmount,
        uint256 airDropPot
    );
    
	// fired whenever theres a withdraw
    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        uint256 ethOut,
        uint256 timeStamp
    );
    
    // fired whenever a withdraw forces end round to be ran
    event onWithdrawAndDistribute
    (
        address playerAddress,
        uint256 ethOut,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount
    );
    
    // fired whenever a player tries a buy after round timer 
    // hit zero, and causes end round to be ran.
    event onBuyAndDistribute
    (
        address playerAddress,
        uint256 ethIn,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount
    );
    
    // fired whenever a player tries a reload after round timer 
    // hit zero, and causes end round to be ran.
    event onReLoadAndDistribute
    (
        address playerAddress,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount
    );
}

contract BMGame is BMEvents {
    using SafeMath for *;
    using BMKeysCalcLong for uint256;

    address  public Banker_Address;

    //==============================================================================
    // game settings
    //==============================================================================
    string constant public name = "BiMoney Game";
    string constant public symbol = "BMG";
    uint256 private rndExtra_ = 30;//extSettings.getLongExtra();     // length of the very first ICO
    uint256 private rndGap_ = 30; //extSettings.getLongGap();         // length of ICO phase, set to 1 year for EOS.
    uint256 constant private rndInit_ = 5 minutes;                // round timer starts at this
    uint256 constant private rndInc_ = 10 seconds;              // every full key purchased adds this much to the timer
    uint256 constant private rndMax_ = 10 minutes;                // max length a round timer can be
    //==============================================================================
    // data used to store game info that changes
    //==============================================================================
    uint256 public airDropPot_;             // person who gets the airdrop wins part of this pot
    uint256 public airDropTracker_ = 0;     // incremented each time a "qualified" tx occurs.  used to determine winning air drop
    //****************
    // PLAYER DATA
    //****************
    uint256 public pID_ = 0;                              // total number of players
    mapping(address => uint256) public pIDxAddr_;         // (addr => pID) returns player id by address
    mapping(uint256 => BMDatasets.Player) public plyr_;   // (pID => data) player data
    mapping(uint256 => mapping(uint256 => BMDatasets.PlayerRounds)) public plyrRnds_;    // (pID => rID => data) player round data by player id & round id
    //****************
    // ROUND DATA
    //****************
    uint256 public rID_;                    // round id number / total rounds that have happened
    mapping(uint256 => BMDatasets.Round) public round_;   // (rID => data) round data
    mapping(uint256 => mapping(uint256 => uint256)) public rndTmEth_;      // (rID => tID => data) eth in per team, by round id and team id
    //****************
    // TEAM FEE DATA
    //****************
    mapping(uint256 => BMDatasets.TeamFee) public fees_;          // (team => fees) fee distribution by team
    mapping(uint256 => BMDatasets.PotSplit) public potSplit_;     // (team => fees) pot split distribution by team


    address public owner;

    //==============================================================================
    // (initial data setup upon contract deploy)
    //==============================================================================
    constructor()
    public
    {
        owner = msg.sender;
        // Team allocation structures
        // 0 = whales 2
        // 1 = bears  3
        // 2 = sneks  0
        // 3 = bulls  1

        // Team allocation percentages
        fees_[0] = BMDatasets.TeamFee(70);
        //20% to pot, 5% to com, 5% to air drop pot
        fees_[1] = BMDatasets.TeamFee(55);
        //35% to pot, 5% to com, 5% to air drop pot
        fees_[2] = BMDatasets.TeamFee(40);
        //50% to pot, 5% to com, 5% to air drop pot
        fees_[3] = BMDatasets.TeamFee(30);
        //60% to pot, 5% to com, 5% to air drop pot

        // how to split up the final pot based on which team was picked
        potSplit_[0] = BMDatasets.PotSplit(50);
        //48% to winner, 0% to next round, 2% to com
        potSplit_[1] = BMDatasets.PotSplit(40);
        //48% to winner, 10% to next round, 2% to com
        potSplit_[2] = BMDatasets.PotSplit(25);
        //48% to winner, 25% to next round, 2% to com
        potSplit_[3] = BMDatasets.PotSplit(10);
        //48% to winner, 40% to next round, 2% to com
    }
    
    //==============================================================================
    // (these are safety checks)
    //==============================================================================

    /**
     * @dev used to make sure no one can interact with contract until it has 
     * been activated. 
     */
    modifier isActivated() {
        require(activated_ == true, "its not ready yet.");
        _;
    }

    /**
     * @dev prevents contracts from interacting with bmg 
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
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;
    }

    //==============================================================================
    // (use these to interact with contract)
    //==============================================================================
    /**
     * @dev emergency buy uses team snek
     */
    function()
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    public
    payable
    {
        // set up our tx event data and determine if player is new or not
        BMDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];

        // buy core 
        buyCore(_pID, 2, _eventData_);
    }

    /**
     * @dev converts all incoming ethereum to keys.
     * @param _team what team is the player playing for?
     */
    function buyKey(uint256 _team)
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    public
    payable
    {
        // set up our tx event data and determine if player is new or not
        BMDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];

        // verify a valid team was selected
        _team = verifyTeam(_team);

        // buy core 
        buyCore(_pID, _team, _eventData_);
    }

    /**
     * @dev essentially the same as buy, but instead of you sending ether 
     * from your wallet, it uses your unwithdrawn earnings.
     * @param _team what team is the player playing for?
     * @param _eth amount of earnings to use (remainder returned to gen vault)
     */
    function reLoadKey(uint256 _team, uint256 _eth)
    isActivated()
    isHuman()
    isWithinLimits(_eth)
    public
    {
        // set up our tx event data
        BMDatasets.EventReturns memory _eventData_;

        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // verify a valid team was selected
        _team = verifyTeam(_team);

        // reload core
        reLoadCore(_pID, _team, _eth, _eventData_);
    }

    /**
     * @dev withdraws all of your earnings.
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
            BMDatasets.EventReturns memory _eventData_;

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
            emit BMEvents.onWithdrawAndDistribute
            (
                msg.sender,
                _eth,
                _eventData_.compressedData,
                _eventData_.compressedIDs,
                _eventData_.winnerAddr,
                _eventData_.amountWon,
                _eventData_.newPot,
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
            emit BMEvents.onWithdraw(_pID, msg.sender, _eth, _now);
        }
    }


    //==============================================================================
    // (for UI & viewing things on etherscan)
    //==============================================================================
    /**
     * @dev return the price buyer will pay for next 1 individual key.
     * @return price for next key bought (in wei format)
     */
    function getBuyPrice()
    public
    view
    returns (uint256)
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // are we in a round?
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ((round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000));
        else // rounds over.  need price for new round
            return (75000000000000);
        // init
    }

    /**
     * @dev returns time left.  dont spam this, you&#39;ll ddos yourself from your node 
     * provider
     * @return time left in seconds
     */
    function getTimeLeft()
    public
    view
    returns (uint256)
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        if (_now < round_[_rID].end)
            if (_now > round_[_rID].strt + rndGap_)
                return ((round_[_rID].end).sub(_now));
            else
                return ((round_[_rID].strt + rndGap_).sub(_now));
        else
            return (0);
    }

    /**
     * @dev returns player earnings per vaults 
     * @return winnings vault
     * @return general vault
     */
    function getPlayerVaults(uint256 _pID)
    public
    view
    returns (uint256, uint256)
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
                (plyr_[_pID].win).add(((round_[_rID].pot).mul(48)) / 100),
                (plyr_[_pID].gen).add(getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask))                
                );
                // if player is not the winner
            } else {
                return
                (
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask))
                );
            }

            // if round is still going on, or round has ended and round end has been ran
        } else {
            return
            (
            plyr_[_pID].win,
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd))
            );
        }
    }

    /**
     * solidity hates stack limits.  this lets us avoid that hate 
     */
    function getPlayerVaultsHelper(uint256 _pID, uint256 _rID)
    private
    view
    returns (uint256)
    {
        return (((((round_[_rID].mask).add(((((round_[_rID].pot).mul(potSplit_[round_[_rID].team].gen)) / 100).mul(1000000000000000000)) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / 1000000000000000000));
    }

    /**
     * @dev returns all current round info needed for front end
     * @return round id 
     * @return total keys for round 
     * @return time round ends
     * @return time round started
     * @return current pot 
     * @return current team ID & player ID in lead 
     * @return current player in leads address 
     * @return whales eth in for round
     * @return bears eth in for round
     * @return sneks eth in for round
     * @return bulls eth in for round
     * @return airdrop tracker # & airdrop pot
     */
    function getCurrentRoundInfo()
    public
    view
    returns (uint256, uint256, uint256, uint256, uint256, uint256, address, uint256, uint256, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;

        return
        (
        _rID, //0
        round_[_rID].keys, //1
        round_[_rID].end, //2
        round_[_rID].strt, //3
        round_[_rID].pot, //4
        (round_[_rID].team + (round_[_rID].plyr * 10)), //5
        plyr_[round_[_rID].plyr].addr, //6
        rndTmEth_[_rID][0], //7
        rndTmEth_[_rID][1], //8
        rndTmEth_[_rID][2], //9
        rndTmEth_[_rID][3], //10
        airDropTracker_ + (airDropPot_ * 1000)              //11
        );
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
    returns (uint256, uint256, uint256, uint256, uint256)
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
        _pID, //0
        plyrRnds_[_pID][_rID].keys, //1
        plyr_[_pID].win, //2
        (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)), //3
        plyrRnds_[_pID][_rID].eth           //4
        );
    }

    //==============================================================================
    // (this + tools + calcs + modules = our softwares engine)
    //==============================================================================
    /**
     * @dev logic runs whenever a buy order is executed.  determines how to handle 
     * incoming eth depending on if we are in an active round or not
     */
    function buyCore(uint256 _pID, uint256 _team, BMDatasets.EventReturns memory _eventData_)
    private
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // if round is active
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
            // call core 
            core(_rID, _pID, msg.value, _team, _eventData_);

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
                emit BMEvents.onBuyAndDistribute
                (
                    msg.sender,
                    msg.value,
                    _eventData_.compressedData,
                    _eventData_.compressedIDs,
                    _eventData_.winnerAddr,
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
    function reLoadCore(uint256 _pID, uint256 _team, uint256 _eth, BMDatasets.EventReturns memory _eventData_)
    private
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // if round is active
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
            // get earnings from all vaults and return unused to gen vault
            // because we use a custom safemath library.  this will throw if player 
            // tried to spend more eth than they have.
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);

            // call core 
            core(_rID, _pID, _eth, _team, _eventData_);

            // if round is not active and end round needs to be ran
        } else if (_now > round_[_rID].end && round_[_rID].ended == false) {
            // end the round (distributes pot) & start new round
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

            // build event data
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            // fire buy and distribute event 
            emit BMEvents.onReLoadAndDistribute
            (
                msg.sender,
                _eventData_.compressedData,
                _eventData_.compressedIDs,
                _eventData_.winnerAddr,
                _eventData_.amountWon,
                _eventData_.newPot,
                _eventData_.genAmount
            );
        }
    }

    /**
     * @dev this is the core logic for any buy/reload that happens while a round 
     * is live.
     */
    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _team, BMDatasets.EventReturns memory _eventData_)
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

            // manage airdrops
            if (_eth >= 100000000000000000)
            {
                airDropTracker_++;
                if (airdrop() == true)
                {
                    // gib muni
                    uint256 _prize;
                    if (_eth >= 10000000000000000000)
                    {
                        // calculate prize and give it to winner
                        _prize = ((airDropPot_).mul(75)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);

                        // adjust airDropPot
                        airDropPot_ = (airDropPot_).sub(_prize);

                        // let event know a tier 3 prize was won
                        _eventData_.compressedData += 300000000000000000000000000000000;
                    } else if (_eth >= 1000000000000000000 && _eth < 10000000000000000000) {
                        // calculate prize and give it to winner
                        _prize = ((airDropPot_).mul(50)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);

                        // adjust airDropPot
                        airDropPot_ = (airDropPot_).sub(_prize);

                        // let event know a tier 2 prize was won
                        _eventData_.compressedData += 200000000000000000000000000000000;
                    } else if (_eth >= 100000000000000000 && _eth < 1000000000000000000) {
                        // calculate prize and give it to winner
                        _prize = ((airDropPot_).mul(25)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);

                        // adjust airDropPot
                        airDropPot_ = (airDropPot_).sub(_prize);

                        // let event know a tier 3 prize was won
                        _eventData_.compressedData += 300000000000000000000000000000000;
                    }
                    // set airdrop happened bool to true
                    _eventData_.compressedData += 10000000000000000000000000000000;
                    // let event know how much was won
                    _eventData_.compressedData += _prize * 1000000000000000000000000000000000;

                    // reset air drop tracker
                    airDropTracker_ = 0;
                }
            }

            // store the air drop tracker number (number of buys since last airdrop)
            _eventData_.compressedData = _eventData_.compressedData + (airDropTracker_ * 1000);

            // update player 
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

            // update round
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndTmEth_[_rID][_team] = _eth.add(rndTmEth_[_rID][_team]);

            // distribute eth
            _eventData_ = distribute(_rID, _pID, _eth, _team, _keys, _eventData_);

            // call end tx function to fire end tx event.
            endTx(_pID, _team, _eth, _keys, _eventData_);
        }
    }
    //==============================================================================
    // (calculates)
    //==============================================================================
    /**
     * @dev calculates unmasked earnings (just calculates, does not update mask)
     * @return earnings in wei format
     */
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast)
    private
    view
    returns (uint256)
    {
        return ((((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask));
    }

    /** 
     * @dev returns the amount of keys you would get given an amount of eth. 
     * @param _rID round ID you want price for
     * @param _eth amount of eth sent in 
     * @return keys received 
     */
    function calcKeysReceived(uint256 _rID, uint256 _eth)
    public
    view
    returns (uint256)
    {
        // grab time
        uint256 _now = now;

        // are we in a round?
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ((round_[_rID].eth).keysRec(_eth));
        else // rounds over.  need keys for new round
            return ((_eth).keys());
    }

    /** 
     * @dev returns current eth price for X keys.  
     * @param _keys number of keys desired (in 18 decimal format)
     * @return amount of eth needed to send
     */
    function iWantXKeys(uint256 _keys)
    public
    view
    returns (uint256)
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // are we in a round?
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ((round_[_rID].keys.add(_keys)).ethRec(_keys));
        else // rounds over.  need price for new round
            return ((_keys).eth());
    }

    /**
     * @dev gets existing or registers new pID.  use this when a player may be new
     * @return pID 
     */
    function determinePID(BMDatasets.EventReturns memory _eventData_)
    private
    returns (BMDatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        // if player is new to this version of bmg
        if (_pID == 0)
        {
            pID_++;
            // set up player account 
            pIDxAddr_[msg.sender] = pID_;
            plyr_[pID_].addr = msg.sender;

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
            return (2);
        else
            return (_team);
    }

    /**
     * @dev decides if round end needs to be run & new round started.  and if 
     * player unmasked earnings from previously played rounds need to be moved.
     */
    function managePlayer(uint256 _pID, BMDatasets.EventReturns memory _eventData_)
    private
    returns (BMDatasets.EventReturns)
    {
        // if player has played a previous round, move their unmasked earnings
        // from that round to gen vault.
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);

        // update player&#39;s last round played
        plyr_[_pID].lrnd = rID_;

        // set the joined round bool to true
        _eventData_.compressedData = _eventData_.compressedData + 10;

        return (_eventData_);
    }

    /**
     * @dev ends the round. manages paying out winner/splitting up pot
     */
    function endRound(BMDatasets.EventReturns memory _eventData_)
    private
    returns (BMDatasets.EventReturns)
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab our winning player and team id&#39;s
        uint256 _winPID = round_[_rID].plyr;
        uint256 _winTID = round_[_rID].team;

        // grab our pot amount
        uint256 _pot = round_[_rID].pot;

        // calculate our winner share, community rewards, gen share, 
        // and amount reserved for next pot 
        uint256 _win = (_pot.mul(48)) / 100;
        uint256 _com = (_pot / 50);
        uint256 _gen = (_pot.mul(potSplit_[_winTID].gen)) / 100;
        uint256 _res = (((_pot.sub(_win)).sub(_com)).sub(_gen));

        // calculate ppt for round mask
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        uint256 _dust = _gen.sub((_ppt.mul(round_[_rID].keys)) / 1000000000000000000);
        if (_dust > 0)
        {
            _gen = _gen.sub(_dust);
            _res = _res.add(_dust);
        }

        // pay our winner
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

        // community rewards
        if (!address(Banker_Address).send(_com))
        {
            //if failed add to pot
            _res = _res.add(_com);
            _com = 0;
        }

        // distribute gen portion to key holders
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

        // prepare event data
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000) + (_winTID * 100000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.newPot = _res;

        // start next round
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_).add(rndGap_);
        round_[_rID].pot = _res;

        return (_eventData_);
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
     * @dev generates a random number between 0-99 and checks to see if thats
     * resulted in an airdrop win
     * @return do we have a winner?
     */
    function airdrop()
    private
    view
    returns (bool)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(

                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                (block.gaslimit).add
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
                (block.number)

            )));
        if ((seed - ((seed / 1000) * 1000)) < airDropTracker_)
            return (true);
        else
            return (false);
    }

    /**
     * @dev distributes eth based on fees to gen and pot
     */
    function distribute(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _team, uint256 _keys, BMDatasets.EventReturns memory _eventData_)
    private
    returns (BMDatasets.EventReturns)
    {
        // pay 5% out to community rewards
        uint256 _com = _eth / 20;
        if (!address(Banker_Address).send(_com))
        {
            _com = 0;
        }

        // calculate gen share
        uint256 _gen = (_eth.mul(fees_[_team].gen)) / 100;

        // toss 5% into airdrop pot 
        uint256 _air = (_eth / 20);
        airDropPot_ = airDropPot_.add(_air);

        // calculate pot 
        uint256 _pot = _eth.sub(_com).sub(_air).sub(_gen);

        // distribute gen share (thats what updateMasks() does) and adjust
        // balances for dust.
        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);

        // add eth to pot
        round_[_rID].pot = _pot.add(_dust).add(round_[_rID].pot);

        // set up event data
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;

        return (_eventData_);
    }

    /**
     * @dev updates masks for round and player when keys are bought
     * @return dust left over 
     */
    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys)
    private
    returns (uint256)
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
        return (_gen.sub((_ppt.mul(round_[_rID].keys)) / (1000000000000000000)));
    }

    /**
     * @dev adds up unmasked earnings, & vault earnings, sets them all to 0
     * @return earnings in wei format
     */
    function withdrawEarnings(uint256 _pID)
    private
    returns (uint256)
    {
        // update gen vault
        updateGenVault(_pID, plyr_[_pID].lrnd);

        // from vaults 
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
        }

        return (_earnings);
    }

    /**
     * @dev prepares compression data and fires event for buy or reload tx&#39;s
     */
    function endTx(uint256 _pID, uint256 _team, uint256 _eth, uint256 _keys, BMDatasets.EventReturns memory _eventData_)
    private
    {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000) + (_team * 100000000000000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (rID_ * 10000000000000000000000000000000000000000000000000000);

        emit BMEvents.onEndTx
        (
            _eventData_.compressedData,
            _eventData_.compressedIDs,
            msg.sender,
            _eth,
            _keys,
            _eventData_.winnerAddr,
            _eventData_.amountWon,
            _eventData_.newPot,
            _eventData_.genAmount,
            _eventData_.potAmount,
            airDropPot_
        );
    }

    //==============================================================================
    // (activate)
    //==============================================================================
    /** upon contract deploy, it will be deactivated.  this is a one time
     * use function that will activate the contract.  we do this so devs 
     * have time to set things up on the web end                            **/
    bool public activated_ = false;

    function activate()
    public
    {

        // can only be ran once
        require(msg.sender == owner, &#39;only dev!&#39;);
        require(activated_ == false, "BiMoney Game already activated");

        // activate the contract 
        activated_ = true;

        Banker_Address = msg.sender;

        // lets start first round
        rID_ = 1;
        round_[1].strt = now + rndExtra_ - rndGap_;
        round_[1].end = now + rndInit_ + rndExtra_;
    }


}