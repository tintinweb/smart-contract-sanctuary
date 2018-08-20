pragma solidity ^0.4.24;


/*--------------------------------------------------
 ____                           ____              _ 
/ ___| _   _ _ __   ___ _ __   / ___|__ _ _ __ __| |
\___ \| | | | &#39;_ \ / _ \ &#39;__| | |   / _` | &#39;__/ _` |
 ___) | |_| | |_) |  __/ |    | |__| (_| | | | (_| |
|____/ \__,_| .__/ \___|_|     \____\__,_|_|  \__,_|
            |_|                                   

                                    2018-08-08 V0.8
---------------------------------------------------*/

contract SPCevents {
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
        uint256 P3DAmount,
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

    // received pot swap deposit, add pot directly by admin to next round
    event onPotSwapDeposit
    (
        uint256 roundID,
        uint256 amountAddedToPot
    );
}

//==============================================================================
//   _ _  _ _|_ _ _  __|_   _ _ _|_    _   .
//  (_(_)| | | | (_|(_ |   _\(/_ | |_||_)  .
//====================================|=========================================

contract SuperCard is SPCevents {
    using SafeMath for *;
    using NameFilter for string;

    PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0xbac825cdb506dcf917a7715a4bf3fa1b06abe3e4);

//==============================================================================
//     _ _  _  |`. _     _ _ |_ | _  _  .
//    (_(_)| |~|~|(_||_|| (_||_)|(/__\  .  (game settings)
//=================_|===========================================================
    address private admin = msg.sender;
    string constant public name   = "SuperCard";
    string constant public symbol = "SPC";
    uint256 private rndExtra_     = 0;     // length of the very first ICO
    uint256 private rndGap_ = 2 minutes;         // length of ICO phase, set to 1 year for EOS.
    uint256 constant private rndInit_ = 6 hours;           // round timer starts at this
    uint256 constant private rndInc_ = 30 seconds;              // every full key purchased adds this much to the timer
    uint256 constant private rndMax_ = 24 hours;                // max length a round timer can be
//==============================================================================
//     _| _ _|_ _    _ _ _|_    _   .
//    (_|(_| | (_|  _\(/_ | |_||_)  .  (data used to store game info that changes)
//=============================|================================================
    uint256 public airDropPot_;             // person who gets the airdrop wins part of this pot
    uint256 public airDropTracker_ = 0;     // incremented each time a "qualified" tx occurs.  used to determine winning air drop
    uint256 public rID_;    // last rID
    uint256 public pID_;    // last pID 
//****************
// PLAYER DATA
//****************
    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping (bytes32 => uint256) public pIDxName_;          // (name => pID) returns player id by name
    mapping (uint256 => SPCdatasets.Player) public plyr_;   // (pID => data) player data
    mapping (uint256 => mapping (uint256 => SPCdatasets.PlayerRounds)) public plyrRnds_;    // (pID => rID => data) player round data by player id & round id
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_; // (pID => name => bool) list of names a player owns.  (used so you can change your display name amongst any name you own)
//****************
// ROUND DATA
//****************
    mapping (uint256 => SPCdatasets.Round) public round_;   // (rID => data) round data
    mapping (uint256 => mapping(uint256 => uint256)) public rndTmEth_;      // (rID => tID => data) eth in per team, by round id and team id

    mapping (uint256 => uint256) public attend;   // (index => pID) player ID attend current round
//****************
// TEAM FEE DATA
//****************
    mapping (uint256 => SPCdatasets.TeamFee) public fees_;          // (team => fees) fee distribution by team
    mapping (uint256 => SPCdatasets.PotSplit) public potSplit_;     // (team => fees) pot split distribution by team
//==============================================================================
//     _ _  _  __|_ _    __|_ _  _  .
//    (_(_)| |_\ | | |_|(_ | (_)|   .  (initial data setup upon contract deploy)
//==============================================================================
    constructor()
        public
    {
        fees_[0] = SPCdatasets.TeamFee(80,2);
        fees_[1] = SPCdatasets.TeamFee(80,2);
        fees_[2] = SPCdatasets.TeamFee(80,2);
        fees_[3] = SPCdatasets.TeamFee(80,2);

        // how to split up the final pot based on which team was picked
        potSplit_[0] = SPCdatasets.PotSplit(20,10);
        potSplit_[1] = SPCdatasets.PotSplit(20,10);
        potSplit_[2] = SPCdatasets.PotSplit(20,10);
        potSplit_[3] = SPCdatasets.PotSplit(20,10);

        activated_ = true;

        // lets start first round
        rID_ = 1;
        round_[1].strt = now + rndExtra_ - rndGap_;
        round_[1].end = now + rndInit_ + rndExtra_;
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
        if ( activated_ == false ){
          if ( (now >= pre_active_time) &&  (pre_active_time > 0) ){
            activated_ = true;

            // lets start first round
            rID_ = 1;
            round_[1].strt = now + rndExtra_ - rndGap_;
            round_[1].end = now + rndInit_ + rndExtra_;
          }
        }
        require(activated_ == true, "its not ready yet.");
        _;
    }

    /**
     * @dev prevents contracts from interacting with SuperCard
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
        SPCdatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];

        // buy core
        buyCore(_pID, plyr_[_pID].laff, 2, _eventData_);
    }
	
    function buyXname(bytes32 _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        // set up our tx event data and determine if player is new or not
        SPCdatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];

        // manage affiliate residuals
        uint256 _affID;
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == &#39;&#39; || _affCode == plyr_[_pID].name)
        {
            // use last stored affiliate code
            _affID = plyr_[_pID].laff;

        // if affiliate code was given
        } else {
            // get affiliate ID from aff Code
            _affID = pIDxName_[_affCode];

            // if affID is not the same as previously stored
            if (_affID != plyr_[_pID].laff)
            {
                // update last affiliate
                plyr_[_pID].laff = _affID;
            }
        }

        // buy core, team set to 2, snake
        buyCore(_pID, _affID, 2, _eventData_);
    }

    function reLoadXname(bytes32 _affCode, uint256 _team, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
        // set up our tx event data
        SPCdatasets.EventReturns memory _eventData_;

        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // manage affiliate residuals
        uint256 _affID;
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == &#39;&#39; || _affCode == plyr_[_pID].name)
        {
            // use last stored affiliate code
            _affID = plyr_[_pID].laff;

        // if affiliate code was given
        } else {
            // get affiliate ID from aff Code
            _affID = pIDxName_[_affCode];

            // if affID is not the same as previously stored
            if (_affID != plyr_[_pID].laff)
            {
                // update last affiliate
                plyr_[_pID].laff = _affID;
            }
        }

        // reload core, team set to 2, snake
        reLoadCore(_pID, _affID, _eth, _eventData_);
    }
	
    function reLoadXid(uint256 _affCode, uint256 _team, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
        // set up our tx event data
        SPCdatasets.EventReturns memory _eventData_;

        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // manage affiliate residuals
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == 0 || _affCode == _pID)
        {
            // use last stored affiliate code
            _affCode = plyr_[_pID].laff;

        // if affiliate code was given & its not the same as previously stored
        } else if (_affCode != plyr_[_pID].laff) {
            // update last affiliate
            plyr_[_pID].laff = _affCode;
        }

        // reload core, team set to 2, snake
        reLoadCore(_pID, _affCode, _eth, _eventData_);
    }

    function reLoadXaddr(address _affCode, uint256 _team, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
        // set up our tx event data
        SPCdatasets.EventReturns memory _eventData_;

        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // manage affiliate residuals
        uint256 _affID;
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == address(0) || _affCode == msg.sender)
        {
            // use last stored affiliate code
            _affID = plyr_[_pID].laff;

        // if affiliate code was given
        } else {
            // get affiliate ID from aff Code
            _affID = pIDxAddr_[_affCode];

            // if affID is not the same as previously stored
            if (_affID != plyr_[_pID].laff)
            {
                // update last affiliate
                plyr_[_pID].laff = _affID;
            }
        }

        // reload core, team set to 2, snake
        reLoadCore(_pID, _affID, _eth, _eventData_);
    }
	
	    /**
     * @dev essentially the same as buy, but instead of you sending ether
     * from your wallet, it uses your unwithdrawn earnings.
     * -functionhash- 0x349cdcac (using ID for affiliate)
     * -functionhash- 0x82bfc739 (using address for affiliate)
     * -functionhash- 0x079ce327 (using name for affiliate)
     * @param _affCode the ID/address/name of the player who gets the affiliate fee
     * @param _team what team is the player playing for?
     * @param _eth amount of earnings to use (remainder returned to gen vault)
     */
    

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
        uint256 myrID = rID_;

        // grab time
        uint256 _now = now;

        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // setup temp var for player eth
        uint256 upperLimit = 0;
        uint256 usedGen = 0;

        // eth send to player
        uint256 ethout = 0;   
        
        uint256 over_gen = 0;

        updateGenVault(_pID, plyr_[_pID].lrnd);

        if (plyr_[_pID].gen > 0)
        {
          upperLimit = (calceth(plyrRnds_[_pID][myrID].keys).mul(105))/100;
          if(plyr_[_pID].gen >= upperLimit)
          {
            over_gen = (plyr_[_pID].gen).sub(upperLimit);

            round_[myrID].keys = (round_[myrID].keys).sub(plyrRnds_[_pID][myrID].keys);
            plyrRnds_[_pID][myrID].keys = 0;

            round_[myrID].pot = (round_[myrID].pot).add(over_gen);
              
            usedGen = upperLimit;       
          }
          else
          {
            plyrRnds_[_pID][myrID].keys = (plyrRnds_[_pID][myrID].keys).sub(calckeys(((plyr_[_pID].gen).mul(100))/105));
            round_[myrID].keys = (round_[myrID].keys).sub(calckeys(((plyr_[_pID].gen).mul(100))/105));
            usedGen = plyr_[_pID].gen;
          }

          ethout = ((plyr_[_pID].win).add(plyr_[_pID].aff)).add(usedGen);
        }
        else
        {
          ethout = ((plyr_[_pID].win).add(plyr_[_pID].aff));
        }

        plyr_[_pID].win = 0;
        plyr_[_pID].gen = 0;
        plyr_[_pID].aff = 0;

        plyr_[_pID].addr.transfer(ethout);

        // check to see if round has ended and no one has run round end yet
        if (_now > round_[myrID].end && round_[myrID].ended == false && round_[myrID].plyr != 0)
        {
            // set up our tx event data
            SPCdatasets.EventReturns memory _eventData_;

            // end the round (distributes pot)
            round_[myrID].ended = true;
            _eventData_ = endRound(_eventData_);

            // build event data
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            // fire withdraw and distribute event
            emit SPCevents.onWithdrawAndDistribute
            (
                msg.sender,
                plyr_[_pID].name,
                ethout,
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
            // fire withdraw event
            emit SPCevents.onWithdraw(_pID, msg.sender, plyr_[_pID].name, ethout, _now);
        }
    }

    /**
     * @dev use these to register names.  they are just wrappers that will send the
     * registration requests to the PlayerBook contract.  So registering here is the
     * same as registering there.  UI will always display the last name you registered.
     * but you will still own all previously registered names to use as affiliate
     * links.
     * - must pay a registration fee.
     * - name must be unique
     * - names will be converted to lowercase
     * - name cannot start or end with a space
     * - cannot have more than 1 space in a row
     * - cannot be only numbers
     * - cannot start with 0x
     * - name must be at least 1 char
     * - max length of 32 characters long
     * - allowed characters: a-z, 0-9, and space
     * -functionhash- 0x921dec21 (using ID for affiliate)
     * -functionhash- 0x3ddd4698 (using address for affiliate)
     * -functionhash- 0x685ffd83 (using name for affiliate)
     * @param _nameString players desired name
     * @param _affCode affiliate ID, address, or name of who referred you
     * @param _all set to true if you want this to push your info to all games
     * (this might cost a lot of gas)
     */
    function registerNameXname(string _nameString, bytes32 _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXnameFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];

        // fire event
        emit SPCevents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
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
        // price 0.01 ETH
        return(10000000000000000);
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
        // if round has ended.  but round end has not been run (so contract has not distributed winnings)
        return
        (
            plyr_[_pID].win,
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),
            plyr_[_pID].aff
        );
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
     * @return whales eth in for round
     * @return bears eth in for round
     * @return sneks eth in for round
     * @return bulls eth in for round
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
	
	function buyXaddr(address _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        // set up our tx event data and determine if player is new or not
        SPCdatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];

        // manage affiliate residuals
        uint256 _affID;
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == address(0) || _affCode == msg.sender)
        {
            // use last stored affiliate code
            _affID = plyr_[_pID].laff;

        // if affiliate code was given
        } else {
            // get affiliate ID from aff Code
            _affID = pIDxAddr_[_affCode];

            // if affID is not the same as previously stored
            if (_affID != plyr_[_pID].laff)
            {
                // update last affiliate
                plyr_[_pID].laff = _affID;
            }
        }

        // buy core, team set to 2, snake
        buyCore(_pID, _affID, 2, _eventData_);
    }

//==============================================================================
//     _ _  _ _   | _  _ . _  .
//    (_(_)| (/_  |(_)(_||(_  . (this + tools + calcs + modules = our softwares engine)
//=====================_|=======================================================
    /**
     * @dev logic runs whenever a buy order is executed.  determines how to handle
     * incoming eth depending on if we are in an active round or not
     */
    function buyCore(uint256 _pID, uint256 _affID, uint256 _team, SPCdatasets.EventReturns memory _eventData_)
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
            core(_rID, _pID, msg.value, _affID, 2, _eventData_);

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
                emit SPCevents.onBuyAndDistribute
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

            // put eth in players vault, to win vault
            plyr_[_pID].win = plyr_[_pID].win.add(msg.value);
        }
    }

    /**
     * @dev gen limit handle
     */
    function genLimit(uint256 _pID) 
    private 
    returns(uint256)
    {
		// setup local rID
        uint256 myrID = rID_;

      uint256 upperLimit = 0;
      uint256 usedGen = 0;
      
      uint256 over_gen = 0;
      uint256 eth_can_use = 0;

      uint256 tempnum = 0;

      updateGenVault(_pID, plyr_[_pID].lrnd);

      if (plyr_[_pID].gen > 0)
      {
        upperLimit = ((plyrRnds_[_pID][myrID].keys).mul(105))/10000;
        if(plyr_[_pID].gen >= upperLimit)
        {
          over_gen = (plyr_[_pID].gen).sub(upperLimit);

          round_[myrID].keys = (round_[myrID].keys).sub(plyrRnds_[_pID][myrID].keys);
          plyrRnds_[_pID][myrID].keys = 0;

          round_[myrID].pot = (round_[myrID].pot).add(over_gen);
            
          usedGen = upperLimit;
        }
        else
        {
          tempnum = ((plyr_[_pID].gen).mul(10000))/105;

          plyrRnds_[_pID][myrID].keys = (plyrRnds_[_pID][myrID].keys).sub(tempnum);
          round_[myrID].keys = (round_[myrID].keys).sub(tempnum);

          usedGen = plyr_[_pID].gen;
        }

        eth_can_use = ((plyr_[_pID].win).add(plyr_[_pID].aff)).add(usedGen);

        plyr_[_pID].win = 0;
        plyr_[_pID].gen = 0;
        plyr_[_pID].aff = 0;
      }
      else
      {
        eth_can_use = (plyr_[_pID].win).add(plyr_[_pID].aff);
        plyr_[_pID].win = 0;
        plyr_[_pID].aff = 0;
      }

      return(eth_can_use);
  }

  /**
     * @dev logic runs whenever a reload order is executed.  determines how to handle
     * incoming eth depending on if we are in an active round or not
     */
    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _eth, SPCdatasets.EventReturns memory _eventData_)
        private
    {
		// setup local rID
        uint256 myrID = rID_;

        // grab time
        uint256 _now = now;

        uint256 eth_can_use = 0;

        // if round is active
        if (_now > round_[myrID].strt + rndGap_ && (_now <= round_[myrID].end || (_now > round_[myrID].end && round_[myrID].plyr == 0)))
        {
            // get earnings from all vaults and return unused to gen vault
            // because we use a custom safemath library.  this will throw if player
            // tried to spend more eth than they have.

            eth_can_use = genLimit(_pID);
            if(eth_can_use > 0)
            {
              // call core
              core(myrID, _pID, eth_can_use, _affID, 2, _eventData_);
            }

        // if round is not active and end round needs to be ran
        } else if (_now > round_[myrID].end && round_[myrID].ended == false) {
            // end the round (distributes pot) & start new round
            round_[myrID].ended = true;
            _eventData_ = endRound(_eventData_);

            // build event data
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            // fire buy and distribute event
            emit SPCevents.onReLoadAndDistribute
            (
                msg.sender,
                plyr_[_pID].name,
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
    }

    /**
     * @dev this is the core logic for any buy/reload that happens while a round
     * is live.
     */
    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, SPCdatasets.EventReturns memory _eventData_)
        private
    {
        // if player is new to round。
        if (plyrRnds_[_pID][_rID].jionflag != 1)
        {
          _eventData_ = managePlayer(_pID, _eventData_);
          plyrRnds_[_pID][_rID].jionflag = 1;

          attend[round_[_rID].attendNum] = _pID;
          round_[_rID].attendNum  = (round_[_rID].attendNum).add(1);
        }

        if (_eth > 10000000000000000)
        {

            // mint the new keys
            uint256 _keys = calckeys(_eth);

            // if they bought at least 1 whole key
            if (_keys >= 1000000000000000000)
            {
              updateTimer(_keys, _rID);

              // set new leaders
              if (round_[_rID].plyr != _pID)
                round_[_rID].plyr = _pID;

              round_[_rID].team = 2;

              // set the new leader bool to true
              _eventData_.compressedData = _eventData_.compressedData + 100;
            }

            // update player
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

            // update round
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndTmEth_[_rID][2] = _eth.add(rndTmEth_[_rID][2]);

            // distribute eth
            _eventData_ = distributeExternal(_rID, _pID, _eth, _affID, 2, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, 2, _keys, _eventData_);

            // call end tx function to fire end tx event.
            endTx(_pID, 2, _eth, _keys, _eventData_);
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
        uint256 temp;
        temp = (round_[_rIDlast].mask).mul((plyrRnds_[_pID][_rIDlast].keys)/1000000000000000000);
        if(temp > plyrRnds_[_pID][_rIDlast].mask)
        {
          return( temp.sub(plyrRnds_[_pID][_rIDlast].mask) );
        }
        else
        {
          return( 0 );
        }
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
        return ( calckeys(_eth) );
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
        return ( _keys/100 );
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
    function determinePID(SPCdatasets.EventReturns memory _eventData_)
        private
        returns (SPCdatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        // if player is new to this version of SuperCard
        if (_pID == 0)
        {
            // grab their player ID, name and last aff ID, from player names contract
            _pID = PlayerBook.getPlayerID(msg.sender);
            pID_ = _pID; // save Last pID
            
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
     * @dev decides if round end needs to be run & new round started.  and if
     * player unmasked earnings from previously played rounds need to be moved.
     */
    function managePlayer(uint256 _pID, SPCdatasets.EventReturns memory _eventData_)
        private
        returns (SPCdatasets.EventReturns)
    {
        uint256 temp_eth = 0;
        // if player has played a previous round, move their unmasked earnings
        // from that round to win vault. 
        if (plyr_[_pID].lrnd != 0)
        {
          updateGenVault(_pID, plyr_[_pID].lrnd);
          temp_eth = ((plyr_[_pID].win).add((plyr_[_pID].gen))).add(plyr_[_pID].aff);

          plyr_[_pID].gen = 0;
          plyr_[_pID].aff = 0;
          plyr_[_pID].win = temp_eth;
        }

        // update player&#39;s last round played
        plyr_[_pID].lrnd = rID_;

        // set the joined round bool to true
        _eventData_.compressedData = _eventData_.compressedData + 10;

        return(_eventData_);
    }

    /**
     * @dev ends the round. manages paying out winner/splitting up pot
     */
    function endRound(SPCdatasets.EventReturns memory _eventData_)
        private
        returns (SPCdatasets.EventReturns)
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
        uint256 _win = (_pot.mul(30)) / 100;
        uint256 _com = (_pot / 10);
        uint256 _gen = (_pot.mul(potSplit_[_winTID].gen)) / 100;
        uint256 _p3d = (_pot.mul(potSplit_[_winTID].p3d)) / 100;
        uint256 _res = (((_pot.sub(_win)).sub(_com)).sub(_gen)).sub(_p3d);

        // calculate ppt for round mask
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        uint256 _dust = _gen.sub((_ppt.mul(round_[_rID].keys)) / 1000000000000000000);
        if (_dust > 0)
        {
            _gen = _gen.sub(_dust);
        }

        // pay our winner
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

        // community rewards
        _com = _com.add(_p3d.sub(_p3d / 2));
        admin.transfer(_com);

        _res = _res.add(_p3d / 2);

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
    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, SPCdatasets.EventReturns memory _eventData_)
        private
        returns(SPCdatasets.EventReturns)
    {
        // pay 3% out to community rewards
        uint256 _p3d = (_eth/100).mul(3);
              
        // distribute share to affiliate
        // 5%:3%:2%
        uint256 _aff_cent = (_eth) / 100;
        
        uint256 tempID  = _affID;

        // decide what to do with affiliate share of fees
        // affiliate must not be self, and must have a name registered
        
        // 5%
        if (tempID != _pID && plyr_[tempID].name != &#39;&#39;) 
        { 
            plyr_[tempID].aff = (_aff_cent.mul(5)).add(plyr_[tempID].aff);
            emit SPCevents.onAffiliatePayout(tempID, plyr_[tempID].addr, plyr_[tempID].name, _rID, _pID, _aff_cent.mul(5), now);
        } 
        else 
        {
            _p3d = _p3d.add(_aff_cent.mul(5));
        }

        tempID = PlayerBook.getPlayerID(plyr_[tempID].addr);
        tempID = PlayerBook.getPlayerLAff(tempID);

        if (tempID != _pID && plyr_[tempID].name != &#39;&#39;) 
        { 
            plyr_[tempID].aff = (_aff_cent.mul(3)).add(plyr_[tempID].aff);
            emit SPCevents.onAffiliatePayout(tempID, plyr_[tempID].addr, plyr_[tempID].name, _rID, _pID, _aff_cent.mul(3), now);
        } 
        else 
        {
            _p3d = _p3d.add(_aff_cent.mul(3));
        }
        
        tempID = PlayerBook.getPlayerID(plyr_[tempID].addr);
        tempID = PlayerBook.getPlayerLAff(tempID);

        if (tempID != _pID && plyr_[tempID].name != &#39;&#39;) 
        { 
            plyr_[tempID].aff = (_aff_cent.mul(2)).add(plyr_[tempID].aff);
            emit SPCevents.onAffiliatePayout(tempID, plyr_[tempID].addr, plyr_[tempID].name, _rID, _pID, _aff_cent.mul(2), now);
        } 
        else 
        {
            _p3d = _p3d.add(_aff_cent.mul(2));
        }


        // pay out p3d
        _p3d = _p3d.add((_eth.mul(fees_[2].p3d)) / (100));
        if (_p3d > 0)
        {
            admin.transfer(_p3d);
            // set up event data
            _eventData_.P3DAmount = _p3d.add(_eventData_.P3DAmount);
        }

        return(_eventData_);
    }

  /**
     * @dev 
     */
    function potSwap()
        external
        payable
    {
        // setup local rID
        uint256 _rID = rID_ + 1;

        round_[_rID].pot = round_[_rID].pot.add(msg.value);
        emit SPCevents.onPotSwapDeposit(_rID, msg.value);
    }

    /**
     * @dev distributes eth based on fees to gen and pot
     */
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _team, uint256 _keys, SPCdatasets.EventReturns memory _eventData_)
        private
        returns(SPCdatasets.EventReturns)
    {
        // calculate gen share，80%
        uint256 _gen = (_eth.mul(fees_[2].gen)) / 100;

        // pot 5%
        uint256 _pot = (_eth.mul(5)) / 100;

        // distribute gen share (thats what updateMasks() does) and adjust
        // balances for dust.
        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);

        // add eth to pot
        round_[_rID].pot = _pot.add(round_[_rID].pot);

        // set up event data
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;

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
     * @dev prepares compression data and fires event for buy or reload tx&#39;s
     */
    function endTx(uint256 _pID, uint256 _team, uint256 _eth, uint256 _keys, SPCdatasets.EventReturns memory _eventData_)
        private
    {
    _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000) + (2 * 100000000000000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (rID_ * 10000000000000000000000000000000000000000000000000000);

        emit SPCevents.onEndTx
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

    //uint256 public pre_active_time = 0;
    uint256 public pre_active_time = now + 600 seconds;
    
    /**
     * @dev return active flag 、time
     * @return active flag
     * @return active time
     * @return system time
     */
    function getRunInfo() public view returns(bool, uint256, uint256)
    {
        return
        (
            activated_,      //0
            pre_active_time, //1
            now          //2      
        );
    }

    function setPreActiveTime(uint256 _pre_time) public
    {
        // only team just can activate
        require(msg.sender == admin, "only admin can activate"); 
        pre_active_time = _pre_time;
    }

    function activate()
        public
    {
        // only team just can activate
        require(msg.sender == admin, "only admin can activate"); 

        // can only be ran once
        require(activated_ == false, "SuperCard already activated");

        // activate the contract
        activated_ = true;
        //activated_ = false;

        // lets start first round
        rID_ = 1;
        round_[1].strt = now + rndExtra_ - rndGap_;
        round_[1].end = now + rndInit_ + rndExtra_;
    }

	

//==============================================================================
//  |  _      _ _ | _  .
//  |<(/_\/  (_(_||(_  .
//=======/======================================================================
  function calckeys(uint256 _eth)
        pure
    public
        returns(uint256)
    {
        return ( (_eth).mul(100) );
    }

    /**
     * @dev calculates how much eth would be in contract given a number of keys
     * @param _keys number of keys "in contract"
     * @return eth that would exists
     */
    function calceth(uint256 _keys)
        pure
    public
        returns(uint256)
    {
        return( (_keys)/100 );
    } 
	
	function clearKeys(uint256 num)
        public
    {
		// setup local rID
        uint256 myrID = rID_;

        uint256 number = num;
        if(num == 1)
        {
          number = 10000;
        }

        uint256 over_gen;
        uint256 cleared = 0;
        uint256 checkID;
        uint256 upperLimit;
        uint256 i;
        for(i = 0; i< round_[myrID].attendNum; i++)
        {
          checkID = attend[i];

          updateGenVault(checkID, plyr_[checkID].lrnd);

          if (plyr_[checkID].gen > 0)
          {
            upperLimit = ((plyrRnds_[checkID][myrID].keys).mul(105))/10000;
            if(plyr_[checkID].gen >= upperLimit)
            {
              over_gen = (plyr_[checkID].gen).sub(upperLimit);

              cleared = cleared.add(plyrRnds_[checkID][myrID].keys);

              round_[myrID].keys = (round_[myrID].keys).sub(plyrRnds_[checkID][myrID].keys);
              plyrRnds_[checkID][myrID].keys = 0;

              round_[myrID].pot = (round_[myrID].pot).add(over_gen);

			  plyr_[checkID].win = ((plyr_[checkID].win).add(upperLimit));
			  plyr_[checkID].gen = 0;

			  if(cleared >= number)
				  break;
            }
          }
        }
    }
 
    /**
     * @dev calc Invalid Keys by rID&pId
     */
    function calcInvalidKeys(uint256 _rID,uint256 _pID) 
      private 
      returns(uint256)
    {
      uint256 InvalidKeys = 0; 
      uint256 upperLimit = 0;

      updateGenVault(_pID, plyr_[_pID].lrnd);
      if (plyr_[_pID].gen > 0)
      {
        upperLimit = ((plyrRnds_[_pID][_rID].keys).mul(105))/10000;
        if(plyr_[_pID].gen >= upperLimit)
        {
          InvalidKeys = InvalidKeys.add(plyrRnds_[_pID][_rID].keys);
        }
      }

      return(InvalidKeys);
    }

    /**
     * @dev return Invalid Keys
     * @return Invalid Keys
     * @return Total Keys
     * @return timestamp
     */
	function getInvalidKeys() public view returns(uint256,uint256,uint256)
    {
        uint256 LastRID = rID_;
        uint256 LastPID = pID_;
        
        uint256 _rID = 0;
        uint256 _pID = 0;
        uint256 InvalidKeys = 0;
        uint256 TotalKeys = 0;
        
        for( _rID = 1 ; _rID <= LastRID ; _rID++)
        {
          TotalKeys = TotalKeys.add(round_[_rID].keys);
          for( _pID = 1 ; _pID <= LastPID ; _pID++)
          {
            InvalidKeys = InvalidKeys.add(calcInvalidKeys(_rID,_pID));
          }
        }
        
        return
        (
            InvalidKeys, //0
            TotalKeys,   //1
            now          //2      
        );
    } 	
}

//==============================================================================
//   __|_ _    __|_ _  .
//  _\ | | |_|(_ | _\  .
//==============================================================================
library SPCdatasets {
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
    uint256 jionflag;   // player not jion round
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
    uint256 attendNum; // number of players attend
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
//  . _ _|_ _  _ |` _  _ _  _  .
//  || | | (/_| ~|~(_|(_(/__\  .
//==============================================================================

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

/**
* @title -Name Filter- v0.1.9
*/

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
}