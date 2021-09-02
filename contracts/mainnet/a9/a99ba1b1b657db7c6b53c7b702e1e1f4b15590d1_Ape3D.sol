pragma solidity ^0.4.24;
import "./safeMath.sol";
import "./NameFilter.sol";

// datasets
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
    //compressedIDs key
    // [77-52][51-26][25-0]
        // 0-25 - pID
        // 26-51 - winPID
        // 52-77 - rID
        
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;         // winner addr
        bytes32 winnerName;         // winner name
        uint256 amountWon;          
        uint256 newPot;
        uint256 genAmount;          
        uint256 potAmount;          // amount added to the pot
    }
    struct Player {
        address addr;               // player addr
        bytes32 name;               
        uint256 names;              
        uint256 win;                // jackpot won
        uint256 gen;                // key reward won
        uint256 aff;                // ref reward
        uint256 lrnd;               // last round played
        uint256 laff;               // last reffer
    }
    struct PlayerRounds {
        uint256 eth;                // Amount of ETH puts into cur round
        uint256 keys;               // # of keys
        uint256 mask;               
    }
    struct Round {
        uint256 plyr;               // round leader's pID
        uint256 end;                // ending time timeStamp
        bool ended;                 // is ended
        uint256 strt;               // starting time
        uint256 keys;               // number of keys
        uint256 eth;                // total eth in
        uint256 pot;                // total jackpot
        uint256 mask;               
    }
}

contract Ape3D {

    using SafeMath for *;
    using NameFilter for string;

    string constant public name = "Ape3D long";           
    string constant public symbol = "A3D";                      // game symbol

    // Game data
    address public devs;                                        // dev addr

    bool public activated_ = false;                             

    uint256 constant private rndInit_ = 24 hours; 
    uint256 constant private rndInc_ = 60 seconds;             
    uint256 constant private rndMax_ = 24 hours;  

    uint256 public rID_;                                        // roundID

    uint256 public registrationFee_ = 10 finney;                // register fee
    
    // player data
    uint256 public pID_;                                        // Total number of players
    mapping(address => uint256) public pIDxAddr_;               //（addr => pID）addr to pID 
    mapping(bytes32 => uint256) public pIDxName_;               //（name => pID）name to pID
    mapping(uint256 => F3Ddatasets.Player) public plyr_;        //（pID => data）pID to player data
    mapping(uint256 => mapping(uint256 => F3Ddatasets.PlayerRounds)) public plyrRnds_;    //（pID => rID => data
    mapping(uint256 => mapping(bytes32 => bool)) public plyrNames_;      

    // round data
    mapping(uint256 => F3Ddatasets.Round) public round_;        //（rID => data） rID to round data
    mapping(uint256 => uint256) public rndEth_;    //（rID  => data） rID to round total eth

    // emit when a player register a name
    event onNewName
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        bool isNewPlayer,
        uint256 affiliateID,
        uint256 amountPaid,
        uint256 timeStamp
    );

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
        uint256 genAmount
    );

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
        uint256 genAmount,
        uint256 potAmount
    );

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

    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timeStamp
    );

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
        uint256 genAmountf
    );

    event onReLoadAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 genAmount
    );

    modifier isActivated() {
        require(activated_ == true, "its not ready yet.  check ?eta in discord");
        _;
    }

    // anti-contract
    modifier isHuman() {
        require(msg.sender == tx.origin);
        _;
    }

    
    modifier onlyDevs()
    {
        require(msg.sender == devs, "msg sender is not a dev");
        _;
    }

    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;    
    }

    function activate()
    public
    onlyDevs
    {
        
        require(activated_ == false, "Ape3D already activated");

        activated_ = true;

        // start the first round
        rID_ = 1;
        round_[1].strt = now;
        round_[1].end = now + rndInit_;
    }

    constructor()
    public
    {
        devs = msg.sender;
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
        F3Ddatasets.EventReturns memory _eventData_ = determinePlayer(_eventData_);

        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];

        buyCore(_pID, plyr_[_pID].laff, _eventData_);
    }

    // assigning a new pID to a new player
    function determinePlayer(F3Ddatasets.EventReturns memory _eventData_)
    private
    returns (F3Ddatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];

        if (_pID == 0)
        {
            // assigning a new pID.
            determinePID(msg.sender);
            _pID = pIDxAddr_[msg.sender];
            bytes32 _name = plyr_[_pID].name;
            uint256 _laff = plyr_[_pID].laff;

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

            // sets "true" for new player
            _eventData_.compressedData = _eventData_.compressedData + 1;
        }
        return (_eventData_);
    }

    // determine player ID
    function determinePID(address _addr)
    private
    returns (bool)
    {
        if (pIDxAddr_[_addr] == 0)
        {
            pID_++;
            pIDxAddr_[_addr] = pID_;
            plyr_[pID_].addr = _addr;

            // return true for new player
            return (true);
        } else {
            return (false);
        }
    }

    // register name using ref's ID
    function registerNameXname(string _nameString, bytes32 _affCode)
    external
    payable
    {
        require(msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        address _addr = msg.sender;

        bytes32 _name = NameFilter.nameFilter(_nameString);

        bool _isNewPlayer = determinePID(_addr);

        uint256 _pID = pIDxAddr_[_addr];

        uint256 _affID = 0;
        if (_affCode != "" && _affCode != _name)
        {
            _affID = pIDxName_[_affCode];

            if (_affID != plyr_[_pID].laff)
            {
                plyr_[_pID].laff = _affID;
            }
        }

        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer);
    }

    // core function for register name
    function registerNameCore(uint256 _pID, address _addr, uint256 _affID, bytes32 _name, bool _isNewPlayer)
    private
    {
        // check if the name is taken
        if (pIDxName_[_name] != 0)
            require(plyrNames_[_pID][_name] == true, "sorry that names already taken");

        // setting up player name and id 
        plyr_[_pID].name = _name;
        pIDxName_[_name] = _pID;
        if (plyrNames_[_pID][_name] == false)
        {
            plyrNames_[_pID][_name] = true;
            plyr_[_pID].names++;
        }

        // register fee sends to dev
        address(devs).transfer(10 finney);

        emit onNewName(_pID, _addr, _name, _isNewPlayer, _affID, msg.value, now);
    }

    // buy key using refs name
    function buyXname(bytes32 _affCode)
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    external
    payable
    {
        F3Ddatasets.EventReturns memory _eventData_ = determinePlayer(_eventData_);

        // getting player's ID
        uint256 _pID = pIDxAddr_[msg.sender];

        uint256 _affID;
        if (_affCode == '' || _affCode == plyr_[_pID].name)
        {
            // use last ref code saved
            _affID = plyr_[_pID].laff;
        } else {
            // getting the ref's pID
            _affID = pIDxName_[_affCode];

            // If the ref's pID is new
            if (_affID != plyr_[_pID].laff)
            {
                // Update
                plyr_[_pID].laff = _affID;
            }
        }

        buyCore(_pID, _affID, _eventData_);
    }

    // use vault to rebuy keys, with name as ref 
    function reLoadXname(bytes32 _affCode, uint256 _eth)
    isActivated()
    isHuman()
    isWithinLimits(_eth)
    external
    {
        F3Ddatasets.EventReturns memory _eventData_;

        // get player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        uint256 _affID;
        if (_affCode == '' || _affCode == plyr_[_pID].name)
        {
            // getting ref pID
            _affID = plyr_[_pID].laff;
        } else {
            // getting ref pID
            _affID = pIDxName_[_affCode];

            // If the ref's pID is new
            if (_affID != plyr_[_pID].laff)
            {
                // Update
                plyr_[_pID].laff = _affID;
            }
        }

        reLoadCore(_pID, _affID, _eth, _eventData_);
    }

    /**
     * @dev logic runs whenever a buy order is executed.  determines how to handle 
     * incoming eth depending on if we are in an active round or not
     */
    function buyCore(uint256 _pID, uint256 _affID, F3Ddatasets.EventReturns memory _eventData_)
    private
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // if round is active
        if (_now > round_[_rID].strt  && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
            // call core
            core(_rID, _pID, msg.value, _affID, _eventData_);
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
                emit onBuyAndDistribute
                (
                    msg.sender,
                    plyr_[_pID].name,
                    msg.value,
                    _eventData_.compressedData,
                    _eventData_.compressedIDs,
                    _eventData_.winnerAddr,
                    _eventData_.winnerName,
                    _eventData_.amountWon,
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
    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _eth, F3Ddatasets.EventReturns memory _eventData_)
    private
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // if round is active
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
            // get earnings from all vaults and return unused to gen vault
            // because we use a custom safemath library.  this will throw if player 
            // tried to spend more eth than they have.
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);

            // call core
            core(_rID, _pID, _eth, _affID, _eventData_);

        // if round is not active and end round needs to be ran   
        } else if (_now > round_[_rID].end && round_[_rID].ended == false) {
            // end the round (distributes pot) & start new round
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

            // build event data
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            // fire buy and distribute event 
            emit onReLoadAndDistribute
            (
                msg.sender,
                plyr_[_pID].name,
                _eventData_.compressedData,
                _eventData_.compressedIDs,
                _eventData_.winnerAddr,
                _eventData_.winnerName,
                _eventData_.amountWon,
                _eventData_.genAmount
            );
        }
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

        // update player's last round played
        plyr_[_pID].lrnd = rID_;

        // set the joined round bool to true
        _eventData_.compressedData = _eventData_.compressedData + 10;

        return (_eventData_);
    }

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

        if (_newTime < (rndMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = rndMax_.add(_now);
    }

    /**
     * @dev this is the core logic for any buy/reload that happens while a round 
     * is live.
     */
    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, F3Ddatasets.EventReturns memory _eventData_)
    private
    {
        // if player is new to round
        if (plyrRnds_[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);

        // if eth left is greater than min eth allowed (sorry no pocket lint)
        if (_eth > 10000000000) //0.00000001eth
        {

            // calculate key received
            uint256 _keys = keysRec(round_[_rID].eth,_eth);

            // at least one key
            if (_keys >= 1000000000000000000)
            {
                updateTimer(_keys, _rID);

                // set new leader
                if (round_[_rID].plyr != _pID)
                    round_[_rID].plyr = _pID;

                // set the new leader bool to true
                _eventData_.compressedData = _eventData_.compressedData + 100;
            }

            // update player
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

            // update round
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndEth_[_rID] = _eth.add(rndEth_[_rID]);

            // distribute eth
            _eventData_ = distributeExternal(_rID, _pID, _eth, _affID, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _keys, _eventData_);

            // call end tx function to fire end tx event.
            endTx(_pID, _eth, _keys, _eventData_);
        }
    }

    function endTx(uint256 _pID, uint256 _eth, uint256 _keys, F3Ddatasets.EventReturns memory _eventData_)
    private
    {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (rID_ * 10000000000000000000000000000000000000000000000000000);

        emit onEndTx
        (
            _eventData_.compressedData,
            _eventData_.compressedIDs,
            plyr_[_pID].name,
            msg.sender,
            _eth,
            _keys,
            _eventData_.winnerAddr,
            _eventData_.winnerName,
            _eventData_.amountWon,
            _eventData_.genAmount,
            _eventData_.potAmount
        );
    }

    /**
     * @dev distributes eth based on fees to dev and aff
     */
    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, F3Ddatasets.EventReturns memory _eventData_)
    private
    returns (F3Ddatasets.EventReturns)
    {
        uint256 _devs = (_eth.mul(3)) / 100;
        address(devs).transfer(_devs);
        _devs = 0;

        // distribute share to affiliate
        uint256 _aff = _eth / 10;

        if (_affID != _pID && plyr_[_affID].name != '') {
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
            emit onAffiliatePayout(_affID, plyr_[_affID].addr, plyr_[_affID].name, _rID, _pID, _aff, now);
        } else {
            _devs = _aff;
        }

        if (_devs > 0)
        {
            address(devs).transfer(_devs);
            _devs = 0;
        }

        return (_eventData_);
    }

    /**
     * @dev distributes eth based on fees to gen and pot
     */
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _keys, F3Ddatasets.EventReturns memory _eventData_)
    private
    returns (F3Ddatasets.EventReturns)
    {
        // calculate gen share
        uint256 _gen = (_eth.mul(67)) / 100;

        // calculate pot
        uint256 _pot = (_eth.mul(20)) / 100;

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
            on the rounds mask, my shares, and how much i've already withdrawn,
            how much is still owed to me?"
        */
        
        // calc profit per key & round mask based on this buy:  (dust goes to pot)
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

        // calculate player earning from their own buy (only based on the keys
        // they just bought).  & update player earnings mask
        uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
        plyrRnds_[_pID][_rID].mask = (((round_[_rID].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds_[_pID][_rID].mask);

        //calculate & return dust
        return (_gen.sub((_ppt.mul(round_[_rID].keys)) / (1000000000000000000)));
    }

    /**
     * @dev ends the round. manages paying out winner/splitting up pot
     */
    function endRound(F3Ddatasets.EventReturns memory _eventData_)
    private
    returns (F3Ddatasets.EventReturns)
    {
        // setup local ID
        uint256 _rID = rID_;

        // grab our winning player and team id's
        uint256 _winPID = round_[_rID].plyr;

        // grab our pot amount
        uint256 _pot = round_[_rID].pot;

        // calculate our winner share, community rewards, gen share, 
        // p3d share, and amount reserved for next pot 
        uint256 _win = (_pot.mul(80)) / 100;

        uint256 _gen = 0;
        uint256 _res = _pot.sub(_win);
        
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

        // prepare event data
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = plyr_[_winPID].name;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.newPot = _res;

        // start next round
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_);
        round_[_rID].pot = _res;

        return (_eventData_);
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
    returns (uint256, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;

        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];

        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
            // if player is a winner
            if (round_[_rID].plyr == _pID)
            {
                return
                (
                _pID, //0
                plyr_[_pID].name, //1
                plyrRnds_[_pID][_rID].keys, //2
                (plyr_[_pID].win).add(((round_[_rID].pot).mul(80)) / 100), //3
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)), //4
                plyr_[_pID].aff, //5
                plyrRnds_[_pID][_rID].eth   //6
                );
            } else {
                return
                (
                _pID, //0
                plyr_[_pID].name, //1
                plyrRnds_[_pID][_rID].keys, //2
                (plyr_[_pID].win), //3
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)), //4
                plyr_[_pID].aff, //5
                plyrRnds_[_pID][_rID].eth   //6
                );
            }
        }
        else{
            return
            (
            _pID, //0
            plyr_[_pID].name, //1
            plyrRnds_[_pID][_rID].keys, //2
            plyr_[_pID].win, //3
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)), //4
            plyr_[_pID].aff, //5
            plyrRnds_[_pID][_rID].eth   //6
            );
        }
    }

    /**
     * @dev returns all current round info needed for front end
     * @return eth invested during ICO phase
     * @return round id 
     * @return total keys for round 
     * @return time round ends
     * @return time round started
     * @return current pot 
     * @return current team ID & player ID in lead 
     * @return current player in leads address 
     * @return current player in leads name
     * @return whales eth in for round
     * @return bears eth in for round
     * @return sneks eth in for round
     * @return bulls eth in for round
     * @return airdrop tracker # & airdrop pot
     */
    function getCurrentRoundInfo()
    public
    view
    returns (uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256)
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
        round_[_rID].plyr, // 5
        plyr_[round_[_rID].plyr].addr, //6
        plyr_[round_[_rID].plyr].name, //7
        round_[_rID].eth //8
        );
    }

    /**
     * @dev returns time left.  dont spam this, you'll ddos yourself from your node
     * provider
     * @return time left in seconds
     */
    function getTimeLeft()
        public
        view
        returns(uint256,uint256,uint256)
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        if (_now < round_[_rID].end)
            return((round_[_rID].end),_now, (round_[_rID].end).sub(_now));
            // return( );
        else
            return(0,0,0);
    }

    /**
     * @dev withdraws all of your earnings.
     */
    function withdraw()
    isActivated()
    isHuman()
    external
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

            // pay the player
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

            // build event data
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            // fire withdraw and distribute event
            emit onWithdrawAndDistribute
            (
                msg.sender,
                plyr_[_pID].name,
                _eth,
                _eventData_.compressedData,
                _eventData_.compressedIDs,
                _eventData_.winnerAddr,
                _eventData_.winnerName,
                _eventData_.amountWon,
                _eventData_.genAmount
            );
        } else {
            // in any other situation
            // get their earnings
            _eth = withdrawEarnings(_pID);

            // pay the player
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

            // fire withdraw event
            emit onWithdraw(_pID, msg.sender, plyr_[_pID].name, _eth, _now);
        }
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

        // from vault
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
        }

        return (_earnings);
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
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) {
            return keysRec(round_[_rID].eth, _eth);
        } else {
            // rounds over.  need keys for new round
            return keys(_eth);
        }
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
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ethRec(round_[_rID].keys + _keys,_keys);
        else // rounds over. need price for new round
            return eth(_keys);
    }

    function keysRec(uint256 _curEth, uint256 _newEth) 
    internal 
    pure 
    returns (uint256) 
    { 
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth))); 
    } 
 
    function keys(uint256 _eth) 
    internal 
    pure 
    returns(uint256) 
    { 
        return (10000*((_eth.mul(1000000000000000000)).sqrt()));
    }

    function ethRec(uint256 _curKeys, uint256 _sellKeys)
    internal
    pure
    returns (uint256)
    {
        return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }

    function eth(uint256 _keys)
    internal
    pure
    returns(uint256)
    {
        return ((10000000000).mul(_keys.sq())) / ((1000000000000000000).sq());
    }
}